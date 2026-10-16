# Working in Studio

Open `D:\FlyFightPaper\FlyFightPaper-WORKING.rbxlx`.
From PowerShell in `D:\FlyFightPaper`, start Rojo:

```powershell
& "$env:LOCALAPPDATA\Rojo\bin\rojo.exe" serve default.project.json --address 127.0.0.1
```

In Studio, open Plugins > Rojo and connect to localhost, port 34872.
Accept the sync, then press Play. Stop Play before changing source and save the place after meaningful changes.

`src/shared` and `src/generated` sync to ReplicatedStorage/FlyFightPaper.
`src/server` syncs to ServerScriptService/FlyFightPaper.
`src/client` syncs to StarterPlayer/StarterPlayerScripts/FlyFightPaper.
The grey-box room and paper-plane template are native Roblox models in assets/models.
Detailed art source files stay in assets for M4. Their retired Luau loaders and geometry tables are removed.
Tests sync to ServerStorage/FlyFightPaperTests and run only when requested in Studio.
Saved art banks stay dormant on the server during M1. Never replace the working place with a source-only Rojo build.

Edit scripts in this repository. Rojo updates Studio; do not paste replacement scripts into the place.
