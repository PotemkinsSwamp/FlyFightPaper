# Why Play takes minutes, and how Roblox games stay fast (research, 2026-10-11)

Research only. No code, art, place file or Studio setting was changed for this report.

## Plain-English summary (for Alan)

**The main cause is our own code, not the amount of building detail.** Every time the game starts (every Play in
Studio, and on a real server every time a server opens), a server script called `HitShapes` asks Roblox to work out
the most expensive kind of collision shape ("precise convex decomposition", Roblox's slowest and most accurate
option) for **357 different meshes at the same time**: all 292 building pieces (about 1.06 million triangles) plus
the trees, houses and classroom props. Then it makes **1,028 invisible copies** of those pieces to carry the shapes.
In Studio the "server" and your game window are the same program on your PC, so this heavy job starves everything
else, including the step that opens your game view.

Why I think so:
- It ignores the collision setting on the parts. That is why setting every town mesh to Box (the cheapest
  collision) did not help: this script builds its own precise shapes regardless.
- Your A/B tests match it: remove the 292 building pieces (most of that work) and Play drops to ~29 s; remove the
  whole town and it drops to ~10 s. Removing only the building textures did not help.
- Studio's own logs show Play starting in **2-8 s on every run from Oct 7 to Oct 10**, then **70-300+ s from
  Oct 11**, right after the 23 detailed Meshy buildings went in on Oct 10. The script existed before; it only became
  expensive when the meshes did.
- The logs also show it is not "too many objects to send": once your game view finally starts joining, the server
  packs up the whole world in half a second and the join finishes in ~4 s. The minutes are spent waiting *before*
  that, with Studio's threads crawling (plugin loads that take a fraction of a second each are 5-20 s apart).

**Second problem (smaller, certain):** the loading screen asks Roblox to preload 444 mesh ids as if they were
pictures. Roblox only accepts picture ids that way, so all 444 fail on every join (that is the "503 failed" you saw)
and the loading screen waits on them. Roblox's docs also say not to preload the whole world, and that building
textures (SurfaceAppearance) cannot be preloaded at all; Roblox streams them in by itself.

**Third (less certain):** Studio is short of breathing room. During Play it keeps three copies of the game in one
program (the edit copy, the server copy and your game copy), loads ~40 built-in plugins into each, and the log shows
only ~4.6 GB of free memory left on your PC at those moments (Blender, Chrome and Claude were open). One 3-minute
stall happened before any of our scripts had even started, so something in Studio itself (leftover work from the
previous test, recomputing collision after edits, or Studio converting newly uploaded textures on your PC) is also
eating time. A simple test next session will separate these.

**How detailed Roblox games load in a second:** they do expensive work once, in Studio, and save the result in the
place (collision shapes are stored in the place file; textures are converted by Roblox's servers); they reuse the
same meshes and textures many times (Roblox draws identical mesh + identical texture copies together); they let
Roblox stream the world and the textures in by distance and screen size; and they only preload the loading screen and
the first area. None of that needs lower detail.

**What fixes it without touching building detail (expected gain):**
1. **Work out the building collision once in Studio and save it, instead of on every start.** Same exact shapes,
   zero start-up cost. Expected: Play back to roughly 10-15 s (your "town removed" A/B was ~10 s); a real server
   would have exact collision from the first second instead of after a minute or more. Small code change plus a
   one-time "bake" in Studio.
2. **Stop the art rebuild from throwing that saved work away.** Today every `save_place.py` rebuild replaces the
   whole town with a freshly written file that has no collision data, so Studio must recompute it. Medium effort.
3. **Fix the loading screen** to preload only the loading-screen and menu pictures. Expected: ~4-5 s off every
   join, no more 444 failures. Small effort.

Then, later and with your OK where marked: give Studio room while testing (close Blender/Chrome), group the town
into one model per building, and consider Roblox's newer streaming + "SLIM" distant-building system (needs the place
saved to Roblox privately, which is your call). Texture packing tweaks (our texture sheets are ~45 % empty space) can
cut texture memory at the *same* sharpness, but only after measuring.

Next session's first job is one decisive test: start Play with the `HitShapes` building step switched off in a test
copy (no art change). If Play drops to ~10-15 s, cause #1 is confirmed and fix #1 goes in.

---

## How this was researched

- Read: `tools/town_toys.py`, `tools/save_place.py`, `tools/art/hero.py` (settings), `default.project.json`,
  `src/server/HitShapes.luau`, `src/server/FlightService.luau`, `src/client/Loading.luau`,
  `src/shared/NativeAssets.luau`, and counted what is inside `FlyFightPaper-WORKING.rbxlx` (read-only).
- Read Studio's own logs in `%LOCALAPPDATA%\Roblox\logs` (read-only): the Play-start waypoints
  (`PSMStartPlaySolo` ... `PSMClientLoadingFinished`, `PlaySoloPlayableTotalTime`), asset errors and timings.
- Roblox Creator Docs, DevForum announcements and staff replies first, then general game-dev sources (list at end).

### Facts measured from our files and logs

| What | Number |
|---|---|
| Instances saved in the place file | 5,394 (1,990 MeshParts, 1,601 SurfaceAppearances, 1,313 Parts) |
| Unique MeshIds in the place | 584 |
| Unique texture maps referenced | 1,552 (649 unique texture packs; every SurfaceAppearance has a pack) |
| MeshParts `HitShapes.exactRoom` processes | 1,028 visible solid MeshParts, **357 unique meshes**, 292 of them building pieces |
| Building pieces | 280 with stats: 1.06 M triangles, mean 3.8 k, max 11.4 k per piece |
| UV coverage of building texture sheets | mean 55 % (min 27 %): ~45 % of each 1024 map is unused |
| Collision data in the saved place | present for every MeshPart (`PhysicalConfigData`); absent in `city-toys.rbxmx` |
| Play start, Oct 7-10 (47 runs) | 2.0-7.9 s |
| Play start, Oct 11 (23 runs) | 4-620 s, typically 70-215 s |
| Join snapshot once the client finally connects | 0.49 s to serialize; join done in ~4 s |
| Free RAM reported by Studio at Play | ~4.6-4.9 GB of 32 GB |
| Preload failures per Play | 444 unique mesh ids rejected as `AssetDelivery403IncorrectAssetType` ("Asset type does not match requested type") |
| Textures still being converted by Roblox | 4-390 ids per session logged as `AcrBeingGenerated` (newly uploaded textures) |

Where the minutes go (Studio log of 2026-10-11 19:00Z, sessions #2-#13): the stall moves around. Session #8:
server finished starting at 19:10:47, the client copy did not even begin loading until 19:14:00, then joined in 4 s.
Session #11: client loaded in 1.2 s, but loading Studio's built-in plugins into the game view then took over two
minutes (each plugin <1 s, with 2-20 s gaps between them). Session #13: stuck 185 s before the server had loaded,
while a Studio auto-save waited 162 s (the actual file write took 0.1 s). This pattern (whole program starved,
whatever step happens to be running waits) fits heavy background work using the CPU, not a slow network or too many
instances. Studio's hang monitor fired 56 times and the GPU reported 100 ms frames during these windows.

---

## Findings by question

### 1. What Play-solo does between "server ran" and "client loading finished", and what scales it

What Play does (from the log and Roblox's docs): Studio makes a server copy of the place and runs server scripts
(`PSMServerLoadedCB`, `PSMServerRanCB`), creates a client copy that connects to that server over a local network
connection, receives the "join snapshot" of everything replicated (all of Workspace, because StreamingEnabled is off),
then loads Studio's plugins into the play views. Server and client run in separate copies on separate threads but in
one Studio process ([Accurate Play Solo](https://devforum.roblox.com/t/accurate-play-solo/172867); our log shows
both in one file and one process). So "the server's scripts add CPU work locally" during Studio tests
([DevForum](https://devforum.roblox.com/t/studio-runs-the-game-better/1646802)).

What scales the cost, item by item:

- **Collision shapes (biggest, ours).** Roblox: PreciseConvexDecomposition "has the most expensive performance cost
  and takes longer for the engine to compute" ([Meshes](https://create.roblox.com/docs/parts/meshes);
  [CollisionFidelity](https://create.roblox.com/docs/reference/engine/enums/CollisionFidelity); original
  [announcement](https://devforum.roblox.com/t/529077) warns it "may take longer to compute"). Cost grows with
  triangles and unique meshes. `src/server/HitShapes.luau:11-20,61-83` runs `AssetService:CreateMeshPartAsync(...,
  {CollisionFidelity=PreciseConvexDecomposition})` once per unique mesh, all 357 spawned at once at server start
  (called from `src/server/FlightService.luau:23`), then clones 1,028 invisible parts into `Arena.ExactCollision`.
  The originals keep their own collision data too (Roblox: turning collision off "still" keeps "the collision
  geometry ... stored in memory", [Improve performance](https://create.roblox.com/docs/performance-optimization/improve)).
  Studio also recomputes collision whenever a part has none saved or its CollisionFidelity changes (your 215-part
  change: 301 s).
- **Instance count:** not the bottleneck here. 5,394 saved instances; the join snapshot took 0.49 s. (The ~51,000
  "instances in Play" figure most likely counts Studio's own UI/plugin objects and the 1,028 runtime copies; recount
  with `#workspace:GetDescendants()` to be sure.)
- **Unique MeshIds and triangles:** matter mostly through the collision work above (one decomposition per unique
  mesh, cost rising with triangles), and for first-time download. Rendering is fine (60 Hz in game).
- **SurfaceAppearance / TexturePack:** your A/B says not the Play-start cause now that every SurfaceAppearance has a
  pack. They do cost Studio CPU right after new uploads: a Roblox engineer says "Studio performs transcoding locally
  if the backend hasn't finished" ([DevForum](https://devforum.roblox.com/t/strange-texture-bug-in-studio-texture-streaming-issue/4156521)),
  and our logs show textures still in that state (`AcrBeingGenerated`). Missing packs make Studio upload packs and hit
  rate limits (HTTP 429), which `tools/town_toys.py` already works around with `texture-packs.json`.
- **RenderFidelity LOD:** Automatic LOD uses distance bands (<250, 250-500, >500 studs)
  ([Meshes](https://create.roblox.com/docs/parts/meshes); [LOD announcement](https://devforum.roblox.com/t/levels-of-detail-for-mesh-parts/280769)).
  No sign in the logs that LOD building is part of Play start (uncertain; MicroProfiler would show it).
- **Mesh download/decode:** cached after first fetch; a first-run cost, not a repeat one.
- **Parts made with CreateMeshPartAsync in Edit:** once saved they are ordinary MeshParts with stored collision.
  The repeat cost comes from calling it at runtime.
- **rbxlx vs rbxl:** affects opening/saving the file (20 MB of XML), not Play start; Play copies the open game in
  memory (the auto-save file write took 109 ms).

### 2. How big detailed Roblox games load in seconds

- **Do expensive work once and save it.** Collision geometry is stored in the place file (our saved place has
  `PhysicalConfigData` for every MeshPart), so a server loads it instead of computing it. Other engines do the same:
  Unity tells developers to "prebake collision meshes" so they aren't "generated at runtime"
  ([Unity physics guide](https://unity.com/how-to/enhanced-physics-performance-smooth-gameplay)).
- **Reuse meshes and textures.** Roblox draws "multiple meshes with the same MeshContent ... in a single draw call"
  when their SurfaceAppearances match; duplicates with different ids break this
  ([Improve performance](https://create.roblox.com/docs/performance-optimization/improve);
  [Design for performance](https://create.roblox.com/docs/performance-optimization/design)). Big games build from
  kits and trim sheets: one texture holding many reusable strips, mapped onto many models
  ([Roblox trim textures guide](https://devforum.roblox.com/t/3171223)). Our toys already do this (967 toys, ~60 meshes);
  our buildings do not (every piece has its own 4 maps).
- **Let Roblox stream.** Instance streaming lets "players start playing in one part of the world while more of the
  world loads in the background"; models can be Atomic (whole building at once), Persistent, etc.
  ([Instance streaming](https://create.roblox.com/docs/workspace/streaming)). Texture streaming (rolled out to all
  clients March 2026) loads "baseline quality textures first in order of importance" and raises quality as memory
  allows; Roblox's city template went from 20.6 s to 3.0 s to baseline textures and 280 to 155 MB texture memory
  ([Introducing Texture Streaming](https://devforum.roblox.com/t/introducing-texture-streaming/4144855)). It
  supports SurfaceAppearance and MeshPart.
- **SLIM for distant buildings.** A Model set to `LevelOfDetail = SLIM` gets a cloud-made merged version with several
  levels of detail; close up the real parts render, far away the merged one, so distant buildings stay visible with
  fewer draw calls ([SLIM](https://create.roblox.com/docs/workspace/streaming/slim)). Needs StreamingEnabled, the place
  saved to Roblox (not a local file) and Team Create.
- **Preload only the first screen.** "Only preload essential assets, not the entire Workspace"
  ([ContentProvider](https://create.roblox.com/docs/reference/engine/classes/ContentProvider)).
- How many unique textures do they keep? Roblox gives no number. Its advice: most images at most 512, minor ones
  under 256, one texture tinted with `SurfaceAppearance.Color` instead of colour copies, trim/sprite sheets
  ([Improve performance](https://create.roblox.com/docs/performance-optimization/improve)). The texture-streaming
  team now says creators can use more unique textures, and that atlases are fine when their parts are seen together
  ([Texture Streaming](https://devforum.roblox.com/t/introducing-texture-streaming/4144855)), which fits "one sheet
  per building".

### 3. Texture and mesh memory

- Texture memory depends on pixel count, not file size; Roblox converts every image to a fixed format, so compressing
  PNGs saves nothing ([Improve performance](https://create.roblox.com/docs/performance-optimization/improve)).
- SurfaceAppearance maps are baked into one "texture pack" per set of maps when published; the pack holds "the
  compressed runtime texture data" ([SurfaceAppearance](https://create.roblox.com/docs/reference/engine/classes/SurfaceAppearance)).
  The cloud keeps originals and makes per-platform compressed mip levels on first request
  ([Texture Streaming](https://devforum.roblox.com/t/introducing-texture-streaming/4144855)).
- Our cost, estimated: ~1,061 building maps at 1024x1024. With GPU compression and mipmaps that is roughly 0.7-1.4 MB
  each, about **0.75-1.5 GB if every map loaded at full size** (estimate; the exact format is not documented).
  Texture streaming now caps this to the device's budget, so phones get blurrier, not crashes. Measure
  `GraphicsTexture` before deciding anything.
- Meshes are small by comparison: 1.06 M triangles is roughly 40-60 MB with LODs (estimate). Roblox caps a single mesh
  at 20,000 triangles ([Specifications](https://create.roblox.com/docs/art/modeling/specifications)); our pieces
  peak at 11.4 k.
- Collision memory: "Box has the lowest memory overhead, and Default and Precise are generally more expensive"
  ([Improve performance](https://create.roblox.com/docs/performance-optimization/improve)). We currently hold Hull
  data on the originals plus precise data on 1,028 copies.
- Per-device quality: SurfaceAppearance "depends on the user's device and graphics quality level"
  ([SurfaceAppearance](https://create.roblox.com/docs/reference/engine/classes/SurfaceAppearance)).

### 4. Published game vs Studio: what players would really pay

On Roblox, the server loads the published place and runs server scripts on Roblox's machine; each client receives a
copy of the runtime world by replication ([Client-server runtime](https://create.roblox.com/docs/projects/client-server)),
then downloads meshes and texture packs from Roblox's servers and keeps them in a disk cache; textures stream in by
importance. So:

| Cost | Studio Play | Real player |
|---|---|---|
| `HitShapes` precise collision for 357 meshes | Yes, on your PC, starves everything | On Roblox's server at every server start: exact collision missing for the first minute(s), server CPU busy; not on the player's PC |
| 1,028 invisible copies with precise collision data | Built and replicated | Replicated to every player: bigger join, more memory |
| Loading screen preloading 444 meshes as pictures | ~4.6 s, all fail | Same wait on every join |
| Three game copies + ~40 plugins per copy in one program | Yes | No |
| Studio converting new textures locally, recomputing collision after edits | Yes | No (Roblox's servers convert textures) |
| First-time download of meshes/textures | Once per machine | Once per device, then cached; streaming shows low-res first |

### 5. Why Studio is heavy even while editing

Measured: ~50-60 % CPU idle in Edit, 3.3 GB working set / 5.4 GB private, ~4.6 GB free RAM system-wide at Play.
Likely contributors, most likely first (each needs the test in the plan below):
- **Background work left from earlier steps:** recomputing collision after property edits, local texture conversion
  for new uploads (staff quote above), and possibly precise-collision jobs from a stopped Play still finishing
  (unconfirmed). Session #13 stalled before our scripts ran, so something like this is real.
- **Drawing the town in the edit view:** ~1 M triangles, 1,600 SurfaceAppearances, Future lighting with shadows, at
  Studio's edit quality. Studio's Editor Quality Level is in Studio Settings > Rendering
  ([RenderSettings](https://create.roblox.com/docs/reference/engine/classes/RenderSettings)); lowering it only
  changes Studio's edit view, not the game.
- **Script Analysis / new Luau type solver:** a known 2026 Studio bug leaks ~1 GB/min while idle with Script
  Analysis on (versions 0.730-0.734; we are on 0.742, so check, don't assume)
  ([DevForum](https://devforum.roblox.com/t/studio-leaks-1-gbmin-of-memory-while-idle-when-script-analysis-is-enabled-grows-to-100-gb-then-crashes/4743637)).
- **Plugins polling** (Rojo live sync, Studio MCP), and a flat `CityToys` folder of ~1,300 children in the Explorer.
- Others report the same class of problem: 5-minute playtests in big places with no clear cause
  ([DevForum](https://devforum.roblox.com/t/studio-taking-5min-on-average-to-start-a-playtest-in-large-places/4049685)),
  assets failing to load after many playtests in an hour (HTTP 429)
  ([DevForum](https://devforum.roblox.com/t/animations-meshes-other-assets-refuse-to-load-in-during-play-sessions/4749275)),
  meshes stuck at low LOD after Play/Stop until restart
  ([DevForum](https://devforum.roblox.com/t/mesh-lod-stays-degraded-in-edit-mode-after-stopping-a-play-solo-session-until-studio-is-restarted/4751716)).
  Restarting Studio between long test sessions is a cheap habit.

### Anti-patterns found in our repo (file:line)

1. `src/server/HitShapes.luau:61-83` + `src/server/FlightService.luau:23`: precise collision computed at every server
   start for every unique solid mesh, 357 jobs at once, plus 1,028 duplicate parts. Ignores each part's
   CollisionFidelity. (Plane hit shapes in the same file, ~20 small aircraft meshes, are a fine use.)
2. `tools/save_place.py:32-35` replaces the whole `Arena` (classroom, `CityToys`, decor, schoolyard) with Rojo's
   build on every run, and `tools/town_toys.py:76-100` writes MeshParts with no collision data. Every rebuild throws
   away what Studio computed and saved.
3. `src/client/Loading.luau:52-80`: collects every MeshId/TextureID in the room and passes them to `PreloadAsync` as
   strings. Strings must be pictures; meshes fail; SurfaceAppearances can't be preloaded at all; the docs say not to
   preload the whole world.
4. `default.project.json:46`: `StreamingEnabled false` and one flat `CityToys` model: no per-building grouping, so no
   Atomic streaming or SLIM later.
5. Building textures (`tools/art/hero.py:25`, `SIZE = 1024`): 4 private 1024 maps per piece with 55 % average UV
   coverage, so ~45 % of texture memory is empty padding.

---

## Ranked fix list (all keep building detail the same)

| # | Fix | Expected gain | Effort | How to measure |
|---|---|---|---|---|
| 1 | **Bake building collision once in Studio; delete the runtime `exactRoom` copies.** Set each solid building/toy MeshPart's CollisionFidelity in Edit (PreciseConvexDecomposition where you want "collides by what is drawn"; Default/Hull where a box-ish shape is enough), let Studio compute it once, save. Keep `HitShapes` for plane hitboxes only. `FlightHUD.luau:331` reads the `Solid` attribute the copies set; give the real parts that attribute instead. | Play start from 30-300 s to ~10-15 s (A/B: town removed ~10 s). Live servers: exact collision from second one; smaller joins | Small code + one-time Studio bake (may take minutes once; then never again) | Test T1, then `PlaySoloPlayableTotalTime` ×3, `PhysicsCollision` memory |
| 2 | **Keep Studio-computed data through rebuilds.** After baking, export the town from Studio as `.rbxm` (we have `tools/studio_export.lua`) and point Rojo at that, or harvest the collision data back into the build the way texture packs already are. | No collision recompute after every art rebuild (your 301 s case) | Medium | Rebuild, open, Play: no recompute stall; `PhysicalConfigData` present in the built file |
| 3 | **Loading screen preloads only its own pictures and the menu/hangar UI**; meshes and building textures load and stream by themselves. | ~4-5 s off every join; 0 failed preloads | Small | `LoadTimes` attribute (`preloaded` lap), count of `IncorrectAssetType` lines in the log = 0 |
| 4 | **Give Studio room while testing:** close Blender/Chrome during Play tests (aim >8 GB free), restart Studio every few hours, try Script Analysis off at launch, lower Editor Quality Level for editing only. | Less variance; size unknown until T5 | None | Task Manager idle CPU/RAM, Play times |
| 5 | **One Model per building** (16 pieces each) and per toy block; later StreamingEnabled with Atomic buildings and **SLIM**. **Needs Alan:** SLIM requires saving the place to Roblox (privately) and Team Create; streaming must not make buildings pop (AGENTS target). | Faster joins and less memory on weak devices; fewer draw calls far away | Medium | Join time in a private test server, `GraphicsTexture`/`GraphicsMeshParts` |
| 6 | **Texture packing at equal sharpness:** tighter UV packing (55 % to ~80 % coverage) and/or one sheet set per building instead of 16 small ones (pieces are always seen together). | Up to ~30-40 % less texture memory at the same pixels-per-stud; ~16x fewer texture assets | High (hero.py re-bake + re-upload) | Only after `GraphicsTexture` shows it matters |
| 7 | Binary `.rbxl` working file instead of `.rbxlx` (**Alan's call**, AGENTS names the `.rbxlx`). | Faster open/save only | Small | Studio open time |

Skipped on purpose: lowering triangle counts, texture resolution or RenderFidelity (Alan: keep detail; also
`no-quality-cuts-for-fps`).

## Measurement plan for the next session

Set-up for every test: fresh Studio start, Blender and Chrome closed, note free RAM, wait 1 min idle, then Play.
Read `PlaySoloPlayableTotalTime` and the `PSM...` waypoints from the newest `%LOCALAPPDATA%\Roblox\logs\*Studio*_last.log`,
and the `LoadTimes` attribute on Workspace. Run each case 3 times (single runs vary from 4 s to 300 s).

- **T0 baseline:** as is, 3 Plays.
- **T1 decisive (no art change):** in a test copy, skip `HitShapes.exactRoom(self.room)` (`FlightService.luau:23`),
  3 Plays. Expect ~10-15 s if cause #1 is right. Planes will collide with the parts' own Hull shapes meanwhile.
- **T2 MicroProfiler during a slow start:** Ctrl+F6, Ctrl+P to pause, Dump to file
  ([MicroProfiler](https://create.roblox.com/docs/studio/microprofiler)). Look for physics/collision work on worker
  threads and what the render thread waits on.
- **T3 memory in Play:** F9 Developer Console, Memory, PlaceMemory: `GraphicsTexture`, `GraphicsMeshParts`,
  `PhysicsCollision`, `PhysicsParts` ([Memory usage](https://create.roblox.com/docs/studio/optimization/memory-usage));
  or in the command bar `game:GetService("Stats"):GetMemoryUsageMbForTag(Enum.DeveloperMemoryTag.GraphicsTexture)`.
  Record with and without T1.
- **T4 loading fix:** after fix 3, `IncorrectAssetType` lines per Play should be 0 and the `preloaded` lap < 1 s.
- **T5 Studio idle:** Edit-only idle CPU for 2 min after a fresh start (no Play); again after one Play/Stop; again
  with Rojo stopped, with Script Analysis off at launch, and with Editor Quality Level lowered. MicroProfiler in Edit
  shows which thread is busy.
- **T6 player-like:** Test tab "Server & Clients" with 2 clients to see server cost separately from the client.

## Uncertain points (said plainly)

- I have not proven `exactRoom` is the whole story; T1 decides it. One stall (session #13) happened before our
  scripts ran, so Studio-side background work is a real second cause of unknown size.
- Whether Roblox computes precise decomposition on worker threads (starving the CPU) or holds a lock is not
  documented; the log only shows the whole program starved.
- Texture and mesh memory figures above are estimates; Roblox does not publish its exact GPU formats.

## Sources

Roblox (official):
- [Improve performance](https://create.roblox.com/docs/performance-optimization/improve) ·
  [Design for performance](https://create.roblox.com/docs/performance-optimization/design)
- [Meshes](https://create.roblox.com/docs/parts/meshes) ·
  [CollisionFidelity](https://create.roblox.com/docs/reference/engine/enums/CollisionFidelity) ·
  [AssetService](https://create.roblox.com/docs/reference/engine/classes/AssetService) ·
  [Mesh specifications](https://create.roblox.com/docs/art/modeling/specifications)
- [ContentProvider / PreloadAsync](https://create.roblox.com/docs/reference/engine/classes/ContentProvider) ·
  [SurfaceAppearance](https://create.roblox.com/docs/reference/engine/classes/SurfaceAppearance)
- [Instance streaming](https://create.roblox.com/docs/workspace/streaming) ·
  [SLIM](https://create.roblox.com/docs/workspace/streaming/slim) ·
  [Client-server runtime](https://create.roblox.com/docs/projects/client-server)
- [MicroProfiler](https://create.roblox.com/docs/studio/microprofiler) ·
  [Memory usage](https://create.roblox.com/docs/studio/optimization/memory-usage) ·
  [RenderSettings](https://create.roblox.com/docs/reference/engine/classes/RenderSettings)

Roblox DevForum (announcements and staff replies):
- [Introducing Texture Streaming](https://devforum.roblox.com/t/introducing-texture-streaming/4144855)
- [Staff: Studio transcodes locally until the backend finishes](https://devforum.roblox.com/t/strange-texture-bug-in-studio-texture-streaming-issue/4156521)
- [PreciseConvexDecomposition announcement](https://devforum.roblox.com/t/529077)
- [Levels of Detail for Mesh Parts](https://devforum.roblox.com/t/levels-of-detail-for-mesh-parts/280769)
- [Accurate Play Solo](https://devforum.roblox.com/t/accurate-play-solo/172867)

Community reports (leads, not official):
- [5-minute playtests in large places](https://devforum.roblox.com/t/studio-taking-5min-on-average-to-start-a-playtest-in-large-places/4049685)
- [Assets refuse to load during play sessions (429)](https://devforum.roblox.com/t/animations-meshes-other-assets-refuse-to-load-in-during-play-sessions/4749275)
- [Mesh LOD degraded after Play Solo](https://devforum.roblox.com/t/mesh-lod-stays-degraded-in-edit-mode-after-stopping-a-play-solo-session-until-studio-is-restarted/4751716)
- [Script Analysis idle memory leak](https://devforum.roblox.com/t/studio-leaks-1-gbmin-of-memory-while-idle-when-script-analysis-is-enabled-grows-to-100-gb-then-crashes/4743637)
- [Studio runs the game better? (server runs on your PC in tests)](https://devforum.roblox.com/t/studio-runs-the-game-better/1646802)
- [Does Roblox use mesh instancing?](https://devforum.roblox.com/t/does-roblox-use-mesh-instancing/399564)
- [Trim textures on Roblox](https://devforum.roblox.com/t/3171223)

General game development:
- [Unity: enhanced physics performance (prebake collision meshes)](https://unity.com/how-to/enhanced-physics-performance-smooth-gameplay)
- [Unity PlayerSettings (bakeCollisionMeshes)](https://docs.unity3d.com/ScriptReference/PlayerSettings.html)
- [Polycount trim-sheet discussions](https://polycount.com/discussions/tagged/trim-sheet/p1)
