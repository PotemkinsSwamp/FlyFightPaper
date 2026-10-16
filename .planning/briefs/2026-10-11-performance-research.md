# Research job: why the classroom is so heavy, and how Roblox games stay fast (2026-10-11)

Alan: "Something is really unoptimized. Other Roblox games are far more detailed and load in a second. Find out how
Roblox developers, game development in general and the Roblox engine handle this, and how it's loaded into player
games. Make the models work; do NOT lower building detail." Write the answer down; nothing gets changed yet.

## What we measured (2026-10-11, Alan's PC: 32 GB RAM, plays AAA games fine)
- Studio Play start (log `PlaySoloPlayableTotalTime`): 68-85 s last night, 4 s once today, then 32-301 s. Almost all
  of it is between Roblox's waypoints `PSMServerRanCB` and `PSMClientLoadingFinished`. Our own client loading screen
  then takes ~4.6 s (it preloads ~1,250 asset ids; 503 report "failed" in Studio).
- A/B in Studio (not saved): town models (Arena.CityToys) removed -> ~10 s. Only the 292 building pieces removed ->
  ~29 s. Building SurfaceAppearances removed (meshes kept) -> 138 s (no help). Changing CollisionFidelity on 215
  parts -> 301 s (recompute), all town meshes Box -> still 163-215 s.
- Studio sits at ~50-60 % CPU even idle in Edit; Studio process 3.3 GB working set / 5.4 GB private; free RAM fell
  to 3.2 GB of 32 GB (Claude, Blender, Chrome also large). Runtime is fine once in: 60 Hz client and server.
- `workspace.StreamingEnabled = false`. Place file 20 MB (rbxlx), ~51,000 instances in Play.

## The content
- 23 "hero" buildings from Meshy, each cut by `tools/art/hero.py` into 16 MeshParts (292 pieces, ~1.06 M triangles;
  pieces up to ~12-20 k tris; baked at `--detail 2.5`). Every piece has its OWN 1024x1024 colour, normal, roughness
  and often metalness map (SurfaceAppearance) -> 1,061 unique textures for buildings.
- 967 small toy MeshParts (trees, cars, crops...) sharing ~60 meshes / 188 textures (~0.17 M tris).
- Town file built by `tools/town_toys.py build` into `assets/models/city-toys.rbxmx` (XML, no PhysicsData /
  no saved collision, TexturePack ids added from a harvested list). Pieces are also placed live in Studio with
  `AssetService:CreateMeshPartAsync`. RenderFidelity Automatic; CollisionFidelity Hull/Box.
- Classroom (`classroom.rbxmx`, ~800 KB), schoolyard (rbxm, huge houses/trees at 1 ft = 50 studs), decor rbxm.

## Questions to answer (with sources: Roblox docs/DevForum/Roblox engineers' posts first, then general gamedev)
1. What does the Studio Play-solo start actually do between server-ran and client-loading-finished, and what
   scales its cost: instance count, unique MeshIds, triangles, SurfaceAppearance/TexturePack, collision/PhysicsData,
   RenderFidelity LOD generation, mesh asset download/decode, CreateMeshPartAsync-made parts, rbxlx vs rbxl?
2. How do big detailed Roblox games load in seconds? (StreamingEnabled + ModelStreamingMode, asset reuse and
   instancing, texture atlases/trim sheets/MaterialVariants vs per-object baked textures, mesh LOD, packages,
   how many unique textures/meshes they keep, Content streaming of textures by distance.)
3. Roblox texture memory: how SurfaceAppearance maps are stored/compressed/streamed, per-device texture quality,
   and the cost of 1,000+ unique 1024 maps. Same for meshes (vertex memory, LOD).
4. How published games load for players (server start, join, what's downloaded, caching) vs Studio, so we know
   which of our costs players would really pay.
5. Studio idle CPU/RAM: what makes Studio itself heavy at edit time (rendering quality level, Explorer with 1,000+
   children, plugins, live Rojo, background collision/pack work) and how devs keep it light.
6. Concrete fixes for OUR setup that keep building detail the same, ranked by expected gain and effort, each with
   how to measure it (MicroProfiler, Developer Console Memory tab, Studio log timings, `Stats` service).

## Rules
- Read the repo files named above to spot anti-patterns; don't edit any code or assets, don't touch Studio.
- Write the report to `docs/PERFORMANCE-RESEARCH-2026-10-11.md`: plain English summary first (Alan reads it),
  then findings with source links, then the ranked fix list and a measurement plan for the next session.
