# Sources (researched 2026-11-13)

Official Roblox docs carry no dates (read as current on 2026-11-13). Re-check anything marked "in flux" before
relying on it: Roblox changes fast.

## Official docs (create.roblox.com)
- [Improve performance](https://create.roblox.com/docs/performance-optimization/improve): instancing rule, textures, shadows, physics, network, leaks
- [Design for performance](https://create.roblox.com/docs/performance-optimization/design): budgets (example ~1,000 draw calls, ~1 M triangles), quality levels, reuse
- [Identify performance issues](https://create.roblox.com/docs/performance-optimization/identify): tools, keys, server memory formula, load-time measuring
- [Test on hardware](https://create.roblox.com/docs/performance-optimization/test-on-hardware): device mix, phones, throttling
- [Load times](https://create.roblox.com/docs/projects/performance-optimization/load-times) · [Memory](https://create.roblox.com/docs/projects/performance-optimization/memory)
- [MicroProfiler](https://create.roblox.com/docs/studio/microprofiler) · [Tag table](https://create.roblox.com/docs/performance-optimization/microprofiler/tag-table) · [Task scheduler](https://create.roblox.com/docs/performance-optimization/microprofiler/task-scheduler)
- [Developer Console](https://create.roblox.com/docs/studio/developer-console) · [Memory usage](https://create.roblox.com/docs/studio/optimization/memory-usage) · [Script Profiler](https://create.roblox.com/docs/studio/optimization/scriptprofiler)
- [Stats class](https://create.roblox.com/docs/reference/engine/classes/Stats) · [Performance dashboard](https://create.roblox.com/docs/production/analytics/performance)
- [Instance streaming](https://create.roblox.com/docs/workspace/streaming) · [SLIM](https://create.roblox.com/docs/workspace/streaming/slim)
- [Meshes](https://create.roblox.com/docs/parts/meshes) · [SurfaceAppearance](https://create.roblox.com/docs/art/modeling/surface-appearance) · [Texture specifications](https://create.roblox.com/docs/art/modeling/texture-specifications) · [Highlighting](https://create.roblox.com/docs/effects/highlighting)
- [Collisions](https://create.roblox.com/docs/workspace/collisions) · [Network ownership](https://create.roblox.com/docs/physics/network-ownership) · [Remote events](https://create.roblox.com/docs/scripting/events/remote) · [Server authority](https://create.roblox.com/docs/projects/server-authority)
- [Native code generation](https://create.roblox.com/docs/luau/native-code-gen) · [Multithreading](https://create.roblox.com/docs/scripting/multithreading) · [buffer](https://create.roblox.com/docs/reference/engine/libraries/buffer) · [task](https://create.roblox.com/docs/reference/engine/libraries/task)
- [Luau performance guide](https://luau.org/performance) (Luau team)

## Roblox staff announcements (DevForum and newsroom)
| Date | Post | Used for |
|---|---|---|
| 2018 | [Part instancing pre-release](https://devforum.roblox.com/t/part-instancing-pre-release-announcement/130333) | what breaks batching |
| 2020 | [Future is Bright phase 3](https://devforum.roblox.com/t/future-is-bright-phase-3-released/878634) | light vs shadow cost |
| 2021 | [Task library](https://devforum.roblox.com/t/task-library-now-available/1387845) | task.wait |
| 2021-02 | [Heightmaps (hollow terrain staff replies)](https://devforum.roblox.com/t/heightmaps-go-to-new-altitudes/1025033) | don't hollow terrain |
| 2022-01 | [CanQuery](https://devforum.roblox.com/t/new-part-collision-property-canquery-now-available/1452707) | collision flags |
| 2023-03-01 | [Model LOD improvements](https://devforum.roblox.com/t/improvements-to-model-level-of-detail-lod/2204938) | StreamingMesh (superseded) |
| 2023-07-06 | [Adaptive stepping default (reverted)](https://devforum.roblox.com/t/physicssteppingmethod-now-set-to-adaptive-as-default/2455212) | physics stepping |
| 2023-07-11 | [Streaming on by default for templates](https://devforum.roblox.com/t/streaming-enabled-by-default-for-all-templates/2462204) | streaming stats |
| 2023 | [SharedTable best practices](https://devforum.roblox.com/t/sharedtable-best-practices/2574316) | 10× slower |
| 2023-11-13 | [Upgrades to model streaming](https://devforum.roblox.com/t/upgrades-to-model-streaming/2699921) | Improved streaming |
| 2023-11-29 | [UnreliableRemoteEvents](https://devforum.roblox.com/t/introducing-unreliableremoteevents/2724155) | 1,000-byte limit (2025-03-12) |
| 2023-24 | [Luau buffer type](https://devforum.roblox.com/t/introducing-luau-buffer-type-beta/2724894) | buffers |
| 2024-05-08 | [Native code gen update](https://devforum.roblox.com/t/luau-native-code-generation-preview-update/2961746) | native on servers |
| 2024-05-30 | [Maximum framerate setting](https://devforum.roblox.com/t/introducing-the-maximum-framerate-setting/2995965) | FPS cap |
| 2024-10 | [MicroProfiler web features](https://devforum.roblox.com/t/3226910) | dumps, diff flame graph |
| 2024-10-29 | [Future lighting on Android](https://devforum.roblox.com/t/future-is-bright-on-android-is-fully-rolled-out-client-beta/3235808) | phones |
| 2024-12 to 2025-06 | [Occlusion culling live](https://devforum.roblox.com/t/occlusion-culling-now-live-in-roblox-client/3300953) | culling rules |
| 2025-07-16 | [EditableMesh/Image improvements](https://devforum.roblox.com/t/editablemesh-and-editableimage-improvements/3818624) | budgets |
| 2025-08-19 | [Multiple replication foci](https://devforum.roblox.com/t/new-instance-streaming-feature-multiple-replication-foci/3848736) | foci cost |
| 2025-10-30 | [SLIM client beta](https://devforum.roblox.com/t/client-beta-introducing-scalable-lightweight-interactive-models-slim/4034709) | SLIM issues |
| 2025-11 | [More server CPU](https://devforum.roblox.com/t/launching-even-more-server-cpu/4044040) | server CPU |
| 2025-12-05 | [SLIM newsroom](https://about.roblox.com/newsroom/2025/12/introducing-roblox-slim-scalable-lightweight-interactive-models) | SLIM numbers |
| 2025-12 / 2026-03 | [Texture streaming](https://devforum.roblox.com/t/introducing-texture-streaming/4144855) | texture memory numbers |
| 2026-02 | [4K texture rendering](https://devforum.roblox.com/t/4k-texture-rendering/4316229) · [2K avatar textures](https://devforum.roblox.com/t/higher-texture-resolutions-for-platform-avatars-layered-clothing-and-rigid-accessories/4358444) | 4K, 3.5 GB cut-off |
| 2026-04-27 | [Mesh streaming + cloud LODs (opt-in)](https://devforum.roblox.com/t/introducing-mesh-streaming-and-improved-cloud-lods-in-published-experiences-opt-in-phase/4601232) | in flux |
| 2026-04/06 | [New spatial query filters](https://devforum.roblox.com/t/new-spatial-query-filters/4563575) | IncludeInstances |
| 2026-06 to 08 | [Physics replication improvements](https://devforum.roblox.com/t/upcoming-improvements-to-physics-replication/4675512) | in flux |
| 2026-07-10 | [Scene Analysis full release](https://devforum.roblox.com/t/full-release-scene-analysis-tool/4620678) | measuring |
| 2026-07-14 | [Client CPU time by category](https://devforum.roblox.com/t/analytics-break-down-your-client-cpu-time-by-category/4737435) | analytics |

## Community (experienced developers; medium confidence unless measured)
- [The Hitchhiker's Guide to Optimization](https://devforum.roblox.com/t/the-hitchhikers-guide-to-optimization-optimize-your-game-using-just-one-post-instead-of-many/3358345) (2025-01, 37 posts): about half sound; replies dispute hollow terrain, Persistent-as-a-fix, "instances don't matter", SurfaceAppearance-vs-Texture
- [The Definitive Tutorial to Game Optimization](https://devforum.roblox.com/t/the-definitive-tutorial-to-game-optimization-everything-you-need-to-know/4629258) (WoloPoints, 2026-05, ~7 posts, no staff, no corrections): accurate basic survey, ~90% overlaps this skill; added: properties before parenting, server-moved bandwidth test, ~80 KB/s, acoustic simulation, Motor6D.Transform. Its "docs say FindFirstChild 20% slower" figure isn't on the docs page; its SLIM numbers are Roblox's own
- [Real world building and scripting optimization](https://devforum.roblox.com/t/real-world-building-and-scripting-optimization-for-roblox/3127146) (MrChickenRocket, 2024-09): budgets, baking, client-side movement
- [RemoteEvents, replication and physics explained](https://devforum.roblox.com/t/in-depth-explanation-of-robloxs-remoteevents-instance-replication-and-physics-replication-w-sources/1847340) (2022-23): byte costs
- [RTS with 200+ units](https://devforum.roblox.com/t/how-we-are-developing-an-rts-game-with-good-performance-for-more-than-200-units/3281168) (2024): BulkMoveTo, packing
- [Native type hints benchmark](https://devforum.roblox.com/t/optimizing-native-code-performance-with-type-hints-and-magic/4247690) (2026-01)
- [Parallel Luau overhead test](https://devforum.roblox.com/t/using-parallel-lua-to-speed-up-computations/3238248) (2024)
- [ParticleEmitter performance](https://devforum.roblox.com/t/improve-the-performance-of-particleemitters/3547121) (2025-03)
- [Spatial query cost](https://devforum.roblox.com/t/how-expensive-are-the-spatial-querying-methods/4149745) (2025)
- [Bandwidth guide](https://devforum.roblox.com/t/the-bandwith-art-learning-how-to-optimize-and-improve-your-game-network-performance/3865361) (2025) · [Total Data KB/s observations](https://devforum.roblox.com/t/what-should-the-total-data-kbs-be-for-a-project/3737312) (2025-06)
- [Native on clients request](https://devforum.roblox.com/t/enable-native-for-clients/3170510) (2024-26): client status
