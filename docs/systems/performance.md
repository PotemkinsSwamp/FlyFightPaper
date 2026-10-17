# Performance

## What the player sees
The game should run at a steady 60 frames per second with 12 planes in the match, with no buildings popping in, and
Play should start in seconds, not minutes.

## Where it stands (2026-10-15)
The minutes-long Play start was fixed (2026-10-11) by computing exact building collision once in Studio and saving
it in the place. Alan saw the frame rate drop inside the chalk cloud; the cloud was made cheaper. A full 12-plane
frame-rate check on Alan's PC is still due before release (Stage 11).
30-minute 12-plane run in Studio (2026-10-17): server steady at 60 steps/s, 3 rounds cycled cleanly, the piece
count returns to the same level every round (no build-up); memory crept about 1.7 MB a minute (3,156 -> 3,203 MB,
Studio counts plugins and the client too). Check the live server's memory in the F9 console on a long session.

## Rules
- Target: steady 60 FPS on Alan's PC in a 12-plane match, no pop-in (set in [AGENTS.md](../../AGENTS.md)).
- Never trade looks for frame rate: see the decision below.
- Stage 4g numbers: 60 FPS, slowest 5% of frames under 20 ms, under 1M triangles, under 1,000 draw calls.
- Measure first, in front-window Studio Play at the highest graphics level. A Studio window behind other windows
  reads about 15 FPS and does not count.
- Things that keep Play fast, and how they break, are in [Lessons learned](../workshop/lessons.md#studio-and-the-place-file).

## Code
| File | What it does |
|---|---|
| `src/client/DevTools.luau` | Studio only: F8 photo viewpoints, F6 live camera, F9 performance overlay, F7 test autopilot (`DevAutopilot` routes: `loop`, `hug`; through the ceiling ducts `duct`, `fan`, `branch`) |
| `src/shared/NativeAssets.luau` | Counts map assets so loading knows when it is done |
| `src/client/Loading.luau` | Loading screen and what it preloads |
| `src/client/Options.luau` | Graphics quality setting |
| `src/server/Bootstrap.server.luau` | Server frame-time readout in Studio |

## Tuning numbers
None in config; graphics options are in Settings.

## Related
- [Never trade looks for frame rate](../decisions/2026-10-10-no-quality-cuts-for-fps.md)
- [Performance research 2026-10-11](../research/PERFORMANCE-RESEARCH-2026-10-11.md)
- [Testing](../workshop/testing.md)
- [Milestones, Stage 4g and 11](../plan/MILESTONES.md)

Back to [HOME](../HOME.md)
