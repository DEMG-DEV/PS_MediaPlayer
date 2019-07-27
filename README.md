# PS_MediaPlayer
A PowerShell Media Player.

This Music player only takes **7.67KB**.

In RAM like you supposed id between **20MB** and **30MB**.

## How to Run
- Play secuencial playlist of your folder.
```
./PlayMusic.ps1 -P "C:\Path_To_Your_Music"
```

- If you specified a file type the script try to find a "*.flac" files
```
./PlayMusic.ps1 -P "C:\Path_To_Your_Music" -Ft ".flac"
```
or:
```
./PlayMusic.ps1 -P "C:\Path_To_Your_Music" -Ft ".mp3"
```

- Play Shuffle playlist of your folder.
```
./PlayMusic.ps1 -P "C:\Path_To_Your_Music" -Shuffle
```

- Play infinite loop playlist of your folder.
```
./PlayMusic.ps1 -P "C:\Path_To_Your_Music" -Loop
```

- Stop playlist of your folder.
```
./PlayMusic.ps1 -Stop
```

- If you specified a folder the script try to run the previous folder you played.
```
./PlayMusic.ps1
```
