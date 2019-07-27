# PS_MediaPlayer
A PowerShell Media Player.

## How to Run
- Play secuencial playlist of your folder.
```
./PlayMusic.ps1 -P "C:\Path_To_Your_Music"
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
