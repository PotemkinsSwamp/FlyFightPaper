# Studio and Rojo

How the game gets from the files in this repo into Roblox Studio. Moved from the old README (written 2026-10-07).

## The pieces
- **Code** lives only in `src/` in this repo. **Rojo** (a tool that copies files from a folder into Studio) live-syncs
  it into Studio through `serve.project.json` (code only: the full town is too big for a live sync and hangs Studio).
- **One place file:** `D:\FlyFightPaper\FlyFightPaper-WORKING.rbxlx`. Never make numbered copies.
- **Art** reaches the place file through `tools/save_place.py`, which builds `default.project.json` and merges it
  into the working place while keeping the saved art and exact collision shapes.
- **Tuning numbers** live in `config/*.json`; run `python tools/generate_config.py` after editing them.
- Rojo maps: `src/shared` and `src/generated` go to ReplicatedStorage, `src/server` to ServerScriptService,
  `src/client` to StarterPlayerScripts, `tests/` to ServerStorage.

## Open and play
1. Open `D:\FlyFightPaper\FlyFightPaper-WORKING.rbxlx` in Roblox Studio.
2. Start Rojo from the repo folder:

   ```powershell
   & "$env:LOCALAPPDATA\Rojo\bin\rojo.exe" serve serve.project.json --address 127.0.0.1 --port 34872
   ```

3. In Studio's Rojo plugin, connect to localhost on port 34872 and accept the sync.
4. Press Play. Wait for the classroom loading screen, then choose Play or Tutorial.

Mouse movement steers; forward movement is automatic and takeoff is automatic. Left click and right click fire your
two weapon types. Shift uses an equipped booster. Fly toward a desk's approach ring to land. Tab opens the game's
menu; Escape also opens Roblox's menu. The plane stays vulnerable while menus are open.

Studio progress lasts one Play session. The development shop simulates products without Robux.

## Rebuilding the place
After model changes, save the place in Studio first (Ctrl+S, Alan), then:

```powershell
cd D:\FlyFightPaper; python tools/save_place.py
```

Then stop Play, reopen the place and reconnect Rojo. Do not install scripts by hand. See
[Lessons learned](lessons.md#studio-and-the-place-file) for what a rebuild can throw away.

## Claude's test copy
Claude tests in a copy of the place (`FlightTest.rbxlx` in its session scratchpad) so it doesn't interrupt Alan's
Play. Build it with `save_place.py` with `PLACE` pointed at the copy, set HttpEnabled, then push changed `src/`
files in from a localhost file server with one Edit-mode `execute_luau` loop (stop Play first; a push during Play
silently tests old code). Drive the game through player attributes read by `src/client/DevTools.luau`
(`DevView`, `DevCamera`, `DevAutopilot`, `DevAim`, `DevPerf`). Start a match: client RoundAction "mapReady" then
"join"; launch with FlightAction "launch"; FlightAction "mixedBots" for every bot skill. Stop its Play when done.

## Related
- [Tools](tools.md) · [Testing](testing.md) · [Lessons learned](lessons.md)

Back to [HOME](../HOME.md)
