# Create a playlist of files from folder

Param(
    [Alias('P')]  [String] $PathMusic,
    [Alias('Sh')] [switch] $Shuffle,
    [Alias('St')] [Switch] $Stop,
    [Alias('L')]  [Switch] $Loop,
    [Alias('Ft')] [String] $fileType
)

function Start-MediaPlayer {
    Param(
        [Alias('P')]  [String] $Path,
        [Alias('Sh')] [switch] $Shuffle,
        [Alias('St')] [Switch] $Stop,
        [Alias('L')]  [Switch] $Loop,
        [Alias('Ft')] [String] $fileType
    )
 
    If ($Stop.IsPresent) {
        Write-Host "Stoping any Already running instance of Media in background."
        Get-Job MusicPlayer -ErrorAction SilentlyContinue | Remove-Job -Force
    }
    Else {
        # Caches Path for next time in case you don't enter Path to the music directory
        If ($Path) {
            $Path | out-file C:\Temp\Musicplayer.txt
        }
        else {
            If ((Get-Content C:\Temp\Musicplayer.txt -ErrorAction SilentlyContinue).Length -ne 0) {
                Write-Host "You've not provided a music directory, looking for cached information from Previous use."
                $Path = Get-Content C:\Temp\Musicplayer.txt
 
                If (-not (Test-Path $Path)) {
                    Write-Host "Please provide a Path to a music directory.\nFound a cached directory $Path from previous use, but that too isn't accessible!"
                    # Mark Path as Empty string, If Cached Path doesn't exist
                    $Path = ''
                }
            }
            else {
                Write-Host "Please provide a Path to a music directory."
            }
        }
  
        #initialization Script for back ground job
        $init = {
            # Function to calculate duration of song in Seconds
            Function Get-SongDuration($FullName) {
                $Shell = New-Object -COMObject Shell.Application
                $Folder = $shell.Namespace($(Split-Path $FullName))
                $File = $Folder.ParseName($(Split-Path $FullName -Leaf))
                         
                [int]$h, [int]$m, [int]$s = ($Folder.GetDetailsOf($File, 27)).split(":")
                         
                $h * 60 * 60 + $m * 60 + $s
            }
                     
            # Function to Notify Information balloon message in system Tray
            Function Show-NotifyBalloon($Message) {
                [system.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null
                $Global:Balloon = New-Object System.Windows.Forms.NotifyIcon
                $Balloon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon((Get-Process -id $pid | Select-Object -ExpandProperty Path))
                $Balloon.BalloonTipIcon = 'Info'
                $Balloon.BalloonTipText = $Message
                $Balloon.BalloonTipTitle = 'Now Playing'
                $Balloon.Visible = $true
                $Balloon.ShowBalloonTip(1000)
            }
                     
            Function PlayMusic($Path, $Shuffle, $Loop) {
                # Calling required assembly
                Add-Type -AssemblyName PresentationCore
     
                # Instantiate Media Player Class
                $MediaPlayer = New-Object System.Windows.Media.Mediaplayer
                         
                # Crunching the numbers and Information
                $FileList = Get-ChildItem $Path -Recurse -Include *$fileType* | Select-Object fullname, @{n = 'Duration'; e = { get-songduration $_.fullname } }
                $FileCount = $FileList.count
                $TotalPlayDuration = [Math]::Round(($FileList.duration | Measure-Object -Sum).sum / 60)
                         
                # Condition to identifed the Mode chosed by the user
                if ($Shuffle.IsPresent) {
                    $Mode = "Shuffle"
                    $FileList = $FileList | Sort-Object { Get-Random }  # Find the target Music Files and sort them Randomly
                }
                Else {
                    $Mode = "Sequential"
                }
                         
                # Check If user chose to play songs in Loop
                If ($Loop.IsPresent) {
                    $Mode = $Mode + " in Loop"
                    $TotalPlayDuration = "Infinite"
                }
                         
                If ($FileList) {
                    '' | Select-Object @{n = 'TotalSongs'; e = { $FileCount }; }, @{n = 'PlayDuration'; e = { [String]$TotalPlayDuration + " Mins" } }, @{n = 'Mode'; e = { $Mode } }
                }
                else {
                    Write-Host "No music files found in directory $Path."
                }
                         
                Do {
                    $FileList | ForEach-Object {
                        $CurrentSongDuration = New-TimeSpan -Seconds (Get-SongDuration $_.fullname)
                        $Message = "Song : " + $(Split-Path $_.fullname -Leaf) + "`nPlay Duration : $($CurrentSongDuration.Minutes) Mins $($CurrentSongDuration.Seconds) Sec`nMode : $Mode"
                        $MediaPlayer.Open($_.FullName)                  # 1. Open Music file with media player
                        $MediaPlayer.Play()                             # 2. Play the Music File
                        Show-NotifyBalloon ($Message)                   # 3. Show a notification balloon in system tray
                        Start-Sleep -Seconds $_.duration                # 4. Pause the script execution until song completes
                        $MediaPlayer.Stop()                             # 5. Stop the Song
                        $Balloon.Dispose(); $Balloon.visible = $false
                    }
                }While ($Loop) # Play Infinitely If 'Loop' is chosen by user
            }
        }
 
        # Removes any already running Job, and start a new job, that looks like changing the track
        If ($(Get-Job Musicplayer -ErrorAction SilentlyContinue)) {
            Get-Job MusicPlayer -ErrorAction SilentlyContinue | Remove-Job -Force
        }
 
        # Run only if Path was Defined or retrieved from cached information
        If ($Path) {
            Write-Host "Starting a background Job to play Music files"
            Start-Job -Name MusicPlayer -InitializationScript $init -ScriptBlock { playmusic $args[0] $args[1] $args[2] } -ArgumentList $Path, $Shuffle, $Loop | Out-Null
            Start-Sleep -Seconds 3       # Sleep to allow media player some breathing time to load files
            Receive-Job -Name MusicPlayer | Format-Table @{n = 'TotalSongs'; e = { $_.TotalSongs }; alignment = 'left' }, @{n = 'TotalPlayDuration'; e = { $_.PlayDuration }; alignment = 'left' }, @{n = 'Mode'; e = { $_.Mode }; alignment = 'left' } -AutoSize
        }
    }      
}

#Start-MediaPlayer
If ($Stop.IsPresent) {
    Start-MediaPlayer -St $Stop
}
ElseIf ($PathMusic) {
    If ($Shuffle.IsPresent) {
        If ($fileType) {
            Start-MediaPlayer $ -P $PathMusic -Sh $Shuffle -Ft $fileType
        }
        Else {
            Start-MediaPlayer $ -P $PathMusic -Sh $Shuffle -Ft ".flac"
        }
    }
    ElseIf ($Loop.IsPresent) {
        If ($fileType) {
            Start-MediaPlayer -P $PathMusic -L $Loop -Ft $fileType
        }
        Else {
            Start-MediaPlayer -P $PathMusic -L $Loop -Ft ".flac"
        }
    }
    Else {
        Start-MediaPlayer -P $PathMusic -Ft ".flac"
    }
}
Else {
    Start-MediaPlayer -Ft ".flac"
}