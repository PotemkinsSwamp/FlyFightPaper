# Memory, instance streaming and loading

Memory is what crashes phones. Roblox publishes no phone limit; its docs say over half of players are on modest
devices and ~60% of Android players have 2-4 GB RAM, and Roblox can't use all of it (community reports: ~800 MB
usable on a 2 GB phone; a studio saw 10-15% Android crashes at 1.2-1.4 GB average use). Phones under 3.5 GB RAM are
Roblox's own "low-end" cut-off (no 4K, 1K avatar textures).
[Test on hardware](https://create.roblox.com/docs/performance-optimization/test-on-hardware). High (Roblox numbers), medium (MB figures).

## Reading the Memory tab (Developer Console, F9 or `/console` in chat)
Definitions from [Memory usage](https://create.roblox.com/docs/studio/optimization/memory-usage); the "if high"
advice is ours.

| Category | What it is | If high |
|---|---|---|
| CoreMemory / CoreScriptMemory | Roblox's own | watch only |
| PlaceMemory | your world | the main target |
| PlaceScriptMemory, LuaHeap | your scripts' data | Luau Heap tab: two snapshots, compare; leaks ([luau.md](luau.md)) |
| Instances, Signals | instance count, connections | stream, destroy unused, disconnect |
| GraphicsTexture | textures | reuse ids, tint, trim sheets; streaming handles most |
| GraphicsMeshParts / GraphicsParts / GraphicsSolidModels | mesh and part render data | reuse meshes, streaming, SLIM |
| HttpCache | downloaded files | duplicate asset ids, oversized images |
| PhysicsCollision / PhysicsParts | collision shapes | Box/Hull on decor ([physics](physics-and-networking.md)) |
| GraphicsParticles | emitters | fewer emitters |
| Sounds / StreamingSounds | loaded / streamed audio | load sounds when needed |
| Gui, Animation, Navigation, Terrain* | as named | destroy hidden UI, fewer loaded animations, less terrain |
| UntrackedMemory | can't be attributed | find by A/B testing changes |

Scripts can read the same with `Stats:GetTotalMemoryUsageMb()` and `Stats:GetMemoryUsageMbForTag(Enum.DeveloperMemoryTag.X)`.
Studio's own numbers are far higher than a phone's (it runs server and client in one program) and the device
emulator is "not accurate for memory": measure on a real phone. Studio's **Scene Analysis** tool (full release
2026-07-10) shows script, instance, audio, animation memory and triangle/draw-call composition as a treemap
([Scene Analysis](https://devforum.roblox.com/t/full-release-scene-analysis-tool/4620678)).

## Instance streaming (lets a bigger, more detailed world fit on a phone)
Roblox staff (2023-07-11): games using streaming had ~2× the instances, joins ~20% faster and about half the
out-of-memory crashes. [Streaming by default](https://devforum.roblox.com/t/streaming-enabled-by-default-for-all-templates/2462204). High. **keeps** (with SLIM or a generous radius; otherwise far things vanish).

Settings the [streaming docs](https://create.roblox.com/docs/workspace/streaming) recommend (verified 2026-11-13):
- `StreamingEnabled` on (can't be changed by script).
- `StreamingMinRadius` 64 (always loaded, loads first), `StreamingTargetRadius` 1024 (keep it bigger than min;
  equal values cause pauses). Raise target only as far as a low-end phone's memory allows.
- `StreamOutBehavior = Opportunistic` (recommended; default is still LowMemory, which only unloads under memory
  pressure). Opportunistic can reload areas a player keeps commuting between: use a replication focus there.
- `ModelStreamingBehavior = Improved` (since 2023-11): models arrive when needed and leave with their last part;
  fewer WaitForChild problems.
- `StreamingIntegrityMode = PauseOutsideLoadedArea`; hide or restyle the default pause with
  `GuiService:SetGameplayPausedNotificationEnabled(false)` and `Player.GameplayPaused`.
- `PredictiveStreamingMode` (opt-in): preloads likely next areas; skipped on weak devices.

Per-model `ModelStreamingMode`:
- **Nonatomic** (default) for scenery. **Atomic** for models a script reads as a unit (only the model needs
  WaitForChild). **Persistent** only for small must-always-exist pieces: never unloads, is sent before
  `Workspace.PersistentLoaded`, adds to every player's join and memory. **PersistentPerPlayer** +
  `Model:AddPersistentPlayer()` for per-player things. Using Persistent "to fix streaming bugs" cancels the benefit:
  code around streaming instead (CollectionService `GetInstanceAddedSignal`, `IsDescendantOf(workspace)` checks).
- Anchored scenery streams part by part; moving assemblies stream whole: keep moving assemblies small.
- `Player:AddReplicationFocus(part)` keeps a second area loaded (a camera far from the player); each moving focus
  costs the server about a player's worth (9 moving foci ≈ 10 players). (2025-08-19). High.
- `Player:RequestStreamAroundAsync(pos)` before teleports and respawns.
- Only Workspace streams: everything in ReplicatedStorage and ReplicatedFirst goes to every client at join. Keep
  them lean; server-only things in ServerStorage. High.

## Loading time
- **Measure it:** no built-in timer. A ReplicatedFirst LocalScript with `os.clock()` and `game.Loaded`; Studio
  Settings > Network > "Print Join Size Breakdown" lists the 20 biggest instances sent at join.
  [Identify](https://create.roblox.com/docs/performance-optimization/identify). High.
- **Preload only what's shown first** (loading-screen art, first menu, spawn area) with `ContentProvider:PreloadAsync`.
  It's a priority hint: preloading the whole Workspace "significantly increases load time"; one report: ~70,000
  assets stalled after ~3,000. Offer Skip if you must preload a lot. Mesh ids passed as images fail (Fly Fight
  Paper, 2026-10). [Load times](https://create.roblox.com/docs/projects/performance-optimization/load-times). High.
- **Custom loading screen in ReplicatedFirst**, call `ReplicatedFirst:RemoveDefaultLoadingScreen()` once it shows;
  `game.Loaded` means initial replication is done, not that pictures have downloaded. Medium.
- **Defer what isn't needed in the first minute** (shop panels, rarely used data); spread start-up work over frames.
- **Fewer, reused asset ids load faster** than many unique ones (each id is a download). Free-model scripts can
  spawn thousands of instances at join: read them. High.

## EditableImage / EditableMesh (not a free source of detail)
- Client memory budget is low, device-dependent and unpublished; creation returns `nil` when it's used up (always
  check). Community reports ~8 EditableMeshes per client; a 1024² EditableImage ≈ 4 MB (4 bytes a pixel). Never
  texture-streamed. Destroy when done; don't rewrite whole images every frame.
  [Improvements](https://devforum.roblox.com/t/editablemesh-and-editableimage-improvements/3818624) (staff, 2025-07-16). Medium.

## Outdated
| Claim | Truth (date) |
|---|---|
| "Streaming is off by default" | On for new templates since 2023-07. |
| "Use StreamingMesh for far models" | SLIM replaces it (2025-12). |
| "Persistent fixes streaming bugs" | Overuse cancels streaming; code for it. |
| "PreloadAsync everything for a smooth start" | Slower; preload the first view only. |
