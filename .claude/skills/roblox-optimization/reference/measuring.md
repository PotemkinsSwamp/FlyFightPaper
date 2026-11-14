# Measuring: proof before and after

Every change gets a number before and after, taken the same way. Keys verified on
[Identify](https://create.roblox.com/docs/performance-optimization/identify) (2026-11-13); on laptops add Fn; on
Mac use Cmd/Opt.

## Tools
| Tool | Open | Shows |
|---|---|---|
| MicroProfiler | Ctrl+Alt+F6 (pause Ctrl+P) | Every frame's time split by job; 16.67 ms = 60 FPS |
| Performance Stats bar | Ctrl+Alt+F7, or client Settings | FPS, CPU, GPU, memory, network, ping |
| Debug Stats overlays | Shift+Ctrl+F1..F5 (Stats, Render, Network, Physics, Summary); Shift+F5 summary in a client | Draw calls and triangles ("Draw (scene)"), network, physics |
| Developer Console | F9, or `/console` in chat | Log, Memory, Luau Heap (snapshots + compare), Script Profiler, MicroProfiler (server recording), Server Jobs, Server Stats |
| Script Profiler | Dev Console or Studio | Per-function CPU, 1 kHz / 10 kHz, Client or Server, JSON export; `<native>` marks native code |
| Scene Analysis | Studio: Window > Performance | Treemap of memory, instances, triangles, draw calls (full release 2026-07-10) |
| Stats service | scripts | `FrameTime`, `RenderCPUFrameTime`, `RenderGPUFrameTime`, `HeartbeatTime`, `PhysicsStepTime`, `SceneDrawcallCount`, `SceneTriangleCount`, `ShadowsDrawcallCount`, `UI2DDrawcallCount`, `InstanceCount`, `MovingPrimitivesCount`, `ContactsCount`, `DataReceiveKbps`, `DataSendKbps`, `GetTotalMemoryUsageMb()`, `GetMemoryUsageMbForTag()` |
| Creator Hub Performance | Creations > game > Monitoring > Performance | Live FPS, crash rate, out-of-memory exits, memory by device, server CPU/memory by age; needs 100+ daily players |
| Client CPU time by category | Creator Hub analytics | Scripts / networking / physics / animation per frame by device (from 2026-06) |

`Stats.HeartbeatTimeMs` and `PhysicsStepTimeMs` are deprecated (use the names above); units of the new ones are not
documented: print once to check.

## Reading the MicroProfiler ([tag table](https://create.roblox.com/docs/performance-optimization/microprofiler/tag-table))
- Frame colour: **orange** = worker threads (scripts, physics, animation) are the bottleneck; **blue** = main render
  thread; **red** = GPU (GPU wait over 2.5 ms: too much geometry, textures, effects).
- `Prepare` = gathering render data (many property changes) · `Perform` = issuing draws (scene complexity) ·
  `Present/waitUntilCompleted` often = GPU-bound · `ShadowMapSystem` = shadows · `physicsStepped`, `worldStep`,
  `stepWorldThrottled` (overloaded) = physics · `gameStepped`, `stepHumanoid`, `stepAnimation` · `Heartbeat` = your
  connections · `GC` = garbage collection (temporary tables) · `updateInvalidatedFastClusters` over 4 ms = too many
  avatar/part changes · `Replicator/ProcessPackets` = network.
- Name your own code: `debug.profilebegin("Bots")` … `debug.profileend()`.
- **Dumps:** "Dump N frames" saves an HTML file to `%LOCALAPPDATA%\Roblox\logs`. Open in a browser: X = X-Ray
  (allocations), Export > CPU/Memory flame graph, drag a second dump on to get a **diff flame graph** (before vs
  after). [Staff post](https://devforum.roblox.com/t/3226910) (2024-10). Server: Dev Console > MicroProfiler >
  Server > "Begin server recording". Phone: turn MicroProfiler on in the phone's Settings, open the shown address
  in a PC browser on the same Wi-Fi.

## A fair test (our protocol)
1. Same build, same camera spots (save fixed viewpoints), same graphics: Settings > Graphics Mode Manual, quality
   max (otherwise the frame-rate manager changes detail mid-test). Then repeat at low quality for phones.
2. Window in front and drawing (a Studio window behind others reads ~15 FPS and means nothing).
3. Warm up: wait until streaming and texture sharpening settle (textures start low-res on purpose).
4. Average 10+ seconds; also note the slowest 5% of frames (hitches matter more than the average).
5. Log: FPS, frame ms, draw calls, triangles, shadow draw calls, memory, and a screenshot from each spot. The
   screenshot proves the look didn't change.
6. Studio skews results (server + client + plugins in one program): confirm big wins in a real client, and phone
   wins on a real phone. Studio's device emulator checks layout only, not speed or memory.
7. First join vs later joins differ (cached downloads): test both for loading.
8. Phones: play 10-15 minutes and watch for a steady FPS decline (heat throttling).
9. Server: Dev Console Server Jobs "Steps Per Sec" near 60; memory flat over a long session (rising = leak).

## Phones and low-end devices
- Pick a baseline phone (2-4 GB Android is the common case) and check every big change on it.
- Phone CPU is roughly 3-4× slower than a desktop for the same work (community estimate): a 4 ms script on PC is
  12-16 ms on a phone.
- Frame-rate caps: phones 60; Windows players can raise it (60/120/144/240, since 2024-05-30): always use delta
  time.
- Roblox lowers quality on its own on weak devices: shadows go below level 4, draw distance shrinks (never under 500
  studs), Future lighting may drop. You don't need to build your own low-detail mode; make the base cheaper.
