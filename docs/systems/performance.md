# Performance

## What the player sees
The game should run at a steady 60 frames per second with 12 planes in the match, with no buildings popping in, and
Play should start in seconds, not minutes.

## Where it stands (2026-10-27)
Loading (details: [load plan](../plan/LOAD-PLAN.md)): real PC cold join Skip 5.3 s, all 16.3 s; phone fresh join
all ~58 s (target 30 s). Menus are 46 files (shrunk to drawn size, packed in sheets, `first/UISheets`); the loading
screen's art preloads alone and at real size first. Everything downloads from one queue, 8 at a time (Studio cold
56.5 s -> 30.0 s). Next: phone check, the checked repacked town, a shared cork board.
The minutes-long Play start was fixed (2026-10-11) by computing exact building collision once in Studio and saving
it in the place. Alan saw the frame rate drop inside the chalk cloud; the cloud was made cheaper. A full 12-plane
frame-rate check on Alan's PC is still due before release (Stage 11).
30-minute 12-plane run in Studio (2026-10-17): server steady at 60 steps/s, 3 rounds cycled cleanly, the piece
count returns to the same level every round (no build-up); memory crept about 1.7 MB a minute (3,156 -> 3,203 MB,
Studio counts plugins and the client too). Check the live server's memory in the F9 console on a long session.

**Phones (Alan's real phone, 2026-10-25): far too slow to load.** Menus showed their words but no paper art, and
the town took minutes. Cause: the place holds about 4,500 separate assets (~900 meshes, ~3,500 texture maps:
colour, normal, roughness, metalness, texture packs; counted in the place file) and StreamingEnabled is off, so a
phone asks for all of it at once and the menu pictures wait behind it. Almost nothing is reused: 924 of 983 colour
maps and 814 of 921 meshes are used by one piece only (fast mobile games reuse a small kit of pieces and shared
textures many times); 2,015 of 2,441 SurfaceAppearances carry a texture pack and separate maps. First fix: the loading screen now loads the
menus' ~176 pictures before anything else, then waits for the whole town, and prints its timings (phone: type
/console in chat). Alan's phone (republished): it waits, but the loading screen showed only plain words: its art and
font queued behind the town. So a ReplicatedFirst script now asks for those before the town arrives. Then every town bump/shine map went up at half size and flat ones were shared (46% fewer town picture pixels, every piece packed). Then menus first (2026-10-25): StreamingEnabled is on and the room and rug (`Arena`, `CityRug`) are
`PersistentPerPlayer`: the server sends them to a player only when their menu pictures are in (`sendTown`, or after
30 s), and they never stream out. Planes, speed pick-ups and the Range stage are `Persistent` (everyone gets them,
as before). The menus work while the town arrives; Play, Fly and Training wait for it. Loading order (Alan 2026-10-25):
the loading screen's own art (it shows only once that is in), then every menu's pictures in the order a player meets
them, then the town's parts; Skip appears only then, with a note that grey buildings fill in. After Skip: the training
range, the plane pieces, then the town's pictures. Each file is its own request, many side by side (a list is fetched
one file after another, slow on a phone); see lessons. The rest is the [load plan](../plan/LOAD-PLAN.md).

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
| `src/client/Loading.luau` | Loading screen: every menu's pictures, then asks for the town; Skip once the town's parts are in; then range, planes and town pictures; `Loading.town` holds Play until the town's parts are in |
| `src/server/LoadLog.luau` | Load recorder: each join's load times and device, newest 50 kept in a DataStore; read in Studio with `require(game.ServerScriptService.FlyFightPaper.LoadLog).recent()` (Server VM, during Play) |
| `src/first/LoadingFirst.client.luau` | Runs before the game arrives (ReplicatedFirst): asks for the loading screen's pictures and font, all at once; the screen shows when they are in |
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
