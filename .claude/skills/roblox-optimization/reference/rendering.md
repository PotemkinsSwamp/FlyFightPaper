# Rendering: drawing more for less

Rendering cost shows as blue frames in the MicroProfiler (main render thread slow: `Prepare`, `Perform`) or red
frames (GPU slow, GPU wait over 2.5 ms; `Perform/Present/waitUntilCompleted` frequent = too much drawn). Count draw
calls and triangles with the Render / Summary debug overlays (Shift+Ctrl+F2 / F5; Shift+F5 in a client) or from a
script with `Stats.SceneDrawcallCount`, `SceneTriangleCount`, `ShadowsDrawcallCount`, `ShadowsTriangleCount`,
`UI2DDrawcallCount`. Roblox's own illustrative low-end budget: under ~1,000 draw calls and ~1,000,000 triangles in a
busy view ([Design](https://create.roblox.com/docs/performance-optimization/design), not a hard rule).

Tags: **keeps** = look unchanged, **adds** = more detail for the same cost, **maybe** = can change the look
(screenshot before/after; if anything visible changes, it belongs in [costs-detail.md](costs-detail.md)).

## 1. Instancing: the biggest free lever (keeps / adds)
- **Same mesh + same SurfaceAppearance = one draw call for all copies.** Official rule: meshes with the same
  MeshContent batch when their SurfaceAppearances are identical (if present), otherwise their TextureContent, and
  only when neither exists, their Material. Position, size, rotation and colour can differ (2018 staff list: CFrame,
  Size, Color, Reflectance don't break a batch). So 500 copies of one rock cost about one rock; 500 unique rocks
  cost 500. Spend the saving on more props.
  *Draw calls at a fixed camera spot before/after.*
  [Improve](https://create.roblox.com/docs/performance-optimization/improve) (current, verified 2026-11-13);
  [Part instancing, staff](https://devforum.roblox.com/t/part-instancing-pre-release-announcement/130333) (2018). High.
- **Upload each mesh once and duplicate it in Studio.** Importing a whole map as one FBX gives identical meshes
  different MeshIds (the importer doesn't de-duplicate), and they stop batching and load twice. Same for materials:
  two imports of "the same" material make two SurfaceAppearance assets; re-point copies to one. Packages keep one
  id. *Memory tab `GraphicsMeshParts`, `HttpCache`; the docs give a script that lists MeshParts by MeshId.* High.
- **Get colour variety from tint, not new textures.** `SurfaceAppearance.Color` tints a shared colour map "without
  affecting performance"; plain meshes use `Part.Color`. One texture, many looks. Caution: a different tint is a
  different SurfaceAppearance instance; check the draw-call count once. High (doc) / check batching.
- **Keep the batch together:** changing a Union's material or colour from a script breaks its instancing; partial
  transparency (anything but 0 or 1) takes a part out of batching and adds overdraw. High.
- Outdated: "meshes don't instance" (changed 2017-10); "instancing only within a 128×64×128 cluster" (changed
  2018-07); "texture doesn't matter for instancing" (2025 forum claim, contradicted by the docs).

## 2. Mesh detail by distance (keeps / maybe)
- **Mesh streaming + cloud LODs (`Workspace.MeshStreamingAndImprovedLoDs`), opt-in since 2026-04-27.** A new cloud
  simplifier keeps silhouettes, UVs and normals better than the old one, and each mesh streams the detail level it
  needs. Staff example: ~1.08 M → ~403 k triangles on the first frame, ~681 k → ~244 k later, "nearly identical"
  look. When Enabled, `RenderFidelity` is ignored (and will be removed). Needs a published place.
  **Status (checked 2026-11-13):** the planned "default in ~July 2026" switch was not found; 2026-08 reports of
  meshes stuck at the lowest detail on PC clients, low-RAM phones showing low detail at ~3 studs, and a community
  map where triangles went *up* (112 k → 269 k). Staff fixes rolling out 2026-08. Re-read the
  [announcement](https://devforum.roblox.com/t/introducing-mesh-streaming-and-improved-cloud-lods-in-published-experiences-opt-in-phase/4601232)
  before enabling; test in a published client on PC and a phone; compare screenshots. High (exists), medium (stability). **maybe**
- **Until then: `RenderFidelity = Automatic`** (the default): full triangles under ~250 studs, fewer beyond
  (thresholds are tuned by Roblox, don't design to them). `Precise` = always full: hero meshes only.
  `Performance` also drops detail when FPS falls and has damaged UVs on some meshes (Hitchhiker's thread, 2025-01):
  needs a screenshot check. [Meshes](https://create.roblox.com/docs/parts/meshes). High. **maybe**
- **A box is a Part, not a MeshPart** (same render cost, extra download). A shape built in Blender beats the same
  shape made of many Parts or a Union (fewer triangles, one draw call). Unions do get LOD and instancing since
  2017-18 ("unions are always bad" is outdated) but carry hidden triangles and can't occlude. SpecialMesh: no
  RenderFidelity, slow to move; replace with MeshPart. Medium-high. **keeps**
- **Bake static part clusters into one mesh per material** (export, rebuild in Blender, re-import): same look,
  fewer instances and draw calls. Medium. **keeps**

## 3. Far models: SLIM (adds versus empty or blocky horizons)
- **`Model.LevelOfDetail = SLIM` on static world models** (buildings, scenery). A cloud service merges a model's
  parts into fewer pieces, removes hidden geometry and builds lighter versions with lower-res textures; near the
  camera the real parts stay; the whole model switches together (no per-part pop). Roblox example: a car 112 meshes +
  24 textures → 1 mesh + 4 textures; a scene 20 M → 3.35 M triangles, 2,402 → 1,454 draw calls (with streaming).
  `Workspace.EnableSLIMAvatars` does the same for distant R15 players.
  **Needs:** StreamingEnabled, the place saved to Roblox (not a local file), Team Create on; first build takes 1-2
  min. **Limits:** no runtime-changed or animated models, no Humanoids, unions may render wrong, coplanar faces can
  flicker (offset ~0.01 stud), UVs can shift (put important surfaces on SurfaceAppearance). The docs don't say beta
  or released; 2025 beta testers reported FPS drops and extra draw calls on some maps. Replaces the older
  `StreamingMesh` imposters (blockier).
  *Dev Console > DebugVisualizations > `SlimTintMode`; Studio Visualization `TranscoderStatus`; draw calls/triangles
  at fixed spots; screenshots far and near.* [SLIM docs](https://create.roblox.com/docs/workspace/streaming/slim);
  [Roblox newsroom](https://about.roblox.com/newsroom/2025/12/introducing-roblox-slim-scalable-lightweight-interactive-models) (2025-12-05). High (docs), medium (maturity). **maybe** (far look)

## 4. Occlusion culling (keeps; free since 2025)
- **Roblox skips drawing things hidden behind opaque objects**, on all platforms since 2025-01-27, terrain since
  2025-06-23. Helps most in cities and interiors, little in open arenas. Only *known fully opaque*, reasonably simple
  objects that are big on screen hide others: detailed meshes, small parts, alpha cut-outs, transparent parts and
  CSG don't occlude. Avatars, lights, VFX, UI and the shadow pass aren't culled.
  **So:** make big walls, floors and ceilings plain opaque pieces (Transparency 0, simple geometry), and keep
  detail behind them: it costs nothing while hidden. Old tricks like hollowing rooms or hiding interiors by script
  matter less now.
  *Draw calls/triangles with a big wall in view vs not; wireframe view.*
  [Occlusion culling live](https://devforum.roblox.com/t/occlusion-culling-now-live-in-roblox-client/3300953) (Roblox rendering team, 2024-12 to 2025-06). High. **keeps**

## 5. Textures and SurfaceAppearance (keeps / adds)
- **Texture streaming is automatic (clients from 2025-12-12; low-end Android 2026-03).** Cheap low-res versions load
  first, then sharper ones by distance and screen size within the device's memory budget. Roblox's Modern City
  test: baseline quality 20.6 s → 3.0 s, texture memory 280 → 155 MB, download 236 → 110 MB. Covers MeshPart,
  SurfaceAppearance, Texture, Decal, MaterialVariant, Beam, ParticleEmitter. **Not yet:** UI images, SurfaceGui,
  Terrain, Sky, built-in materials. Phones under 3.5 GB RAM don't get 4K.
  [Texture streaming](https://devforum.roblox.com/t/introducing-texture-streaming/4144855) (staff, 2025-12, updated 2026-03). High.
  **What it changes:** "shrink every texture to save memory" is much less true for streamed types: memory follows
  what's on screen. 4K textures (upload up to 8K, shown up to 4K when the device and view justify it) since
  2026-02 ([4K rendering](https://devforum.roblox.com/t/4k-texture-rendering/4316229)). So hero surfaces can be
  sharper than before. Still budget the unsupported types (UI, Sky, Terrain) by hand. **adds**
- **Atlas caveat under streaming:** a shared atlas streams at the sharpest level any user of it needs, so a big
  atlas covering many objects stays sharp (and big) everywhere. Unique, evenly-dense textures per object stream
  better; trim sheets (tiling strips shared by many meshes) still win. High (staff note).
- **Memory is pixels, not file size:** 1024² costs 4× 512². Compressing the PNG or dropping alpha saves nothing:
  Roblox converts to its own format. Official guide for non-hero art: most images ≤512, minor ones ≤256; texel
  density guide 256 for a 5-stud object, 512 for 10, 1024 for 20.
  [Texture specs](https://create.roblox.com/docs/art/modeling/texture-specifications). High.
  Lowering a texture someone can see is a detail cut: see [costs-detail.md](costs-detail.md).
- **Built-in materials cost much less memory than custom textures:** use them where they genuinely look right, and
  spend memory on what players look at. High. **keeps** (where it looks the same)
- **Alpha cut-outs instead of geometry:** `SurfaceAppearance.AlphaMode = Transparency` with
  `MeshPart.Transparency = 0` gives lace, leaves, netting, paper edges "without the performance impact of an
  intricate mesh" ([SurfaceAppearance](https://create.roblox.com/docs/art/modeling/surface-appearance)). Note cut-outs
  can't occlude. High. **adds**
- **Bake decals into the colour map** (decals and Texture objects each add draw calls). **Bake soft shading/ambient
  occlusion into textures** instead of extra lights: standard practice, fits a painted look. Medium. **keeps/adds**
- **Vertex colours** are effectively free and show in Roblox (community + this project's own tests). Medium. **adds**

## 6. Lights and shadows
- **Shadows cost geometry × shadow-casting lights.** Turn off `CastShadow` on small, thin, far, dark or moving parts
  whose shadow you can't see, and `Light.Shadows` on lights that don't need it. Docs warn it "might result in visual
  artifacts" on shadows: always screenshot. Below graphics level 4 Roblox switches shadows off anyway; occlusion
  culling doesn't skip the shadow pass. *Stats `ShadowsDrawcallCount`; MicroProfiler `ShadowMapSystem`.*
  [Improve](https://create.roblox.com/docs/performance-optimization/improve). High. **maybe**
- **Many unshadowed accent lights + a few shadowed key lights** under Future lighting: a 2020 staff benchmark had
  1,000 non-shadow lights ~0.5 ms vs shadow-map updates 10-15 ms in heavy scenes (old hardware; direction still
  holds). Short `Range`/`Angle`; lights in rooms nobody sees can be disabled. Medium. **keeps**
- Future lighting on Android needs Vulkan and quality 4+; Roblox lowers it automatically on weak phones (2024-10).
- `Lighting.PrioritizeLightingQuality`: true keeps advanced shading close to the camera, false favours view distance.

## 7. Effects, Highlights, UI
- **Particles: cost is overdraw** = how many semi-transparent pixels pile up (rate × size × lifetime × overlap). Big
  particles close to the camera are worst (a forum test: aura 240 → 60 FPS up close). Fewer, fuller particles or a
  flipbook texture beat many faint puffs; same look for less. Medium-high. **keeps** if redesigned to look the same.
- **Beams keep their segment count at every quality level** (docs; a 2024 forum post says otherwise): budget them.
- **`Highlight`: hard cap of 31 active per client** (extras silently don't draw; disabled ones still hold a slot).
  Each highlighted object is drawn again plus a screen effect; on phones the cost grows with screen area covered.
  One Highlight on a Model covers all its parts. [Highlighting](https://create.roblox.com/docs/effects/highlighting). High.
- **Audio:** keep `SoundService.AcousticSimulationEnabled` off (the default) unless the game needs sound bouncing off
  walls; testers reported a real CPU cost (2026 beta). Load sounds when needed. Medium. **keeps**
- **Post effects** (Bloom, DepthOfField, SunRays, Atmosphere): no official per-effect numbers; Roblox scales them by
  quality level. Measure GPU time on and off. Low-medium.
- **UI:** sprite sheets (`ImageRectOffset`/`ImageRectSize`) instead of many small images; keep siblings that use
  the same image next to each other in draw order (batching). CanvasGroups cost texture memory each; don't use many
  small ones. `ClipsDescendants` supports rotated items since 2026 (no need for CanvasGroup just to clip). UI images
  aren't texture-streamed. *Stats `UI2DDrawcallCount`.* Medium.

## 8. Graphics quality levels (what Roblox does by itself)
- Higher levels raise render distance, shading, geometry and texture detail, particle limits, trail fidelity and
  post-effect quality; shadows off below 4; draw distance at least 500 studs even at the lowest; specifics are
  device-dependent and not documented per level. **Don't branch your visuals on `SavedQualityLevel`** (it reads
  "Automatic" in auto mode and fights the engine's own scaling;
  [Design](https://create.roblox.com/docs/performance-optimization/design)). If a game must adapt, adapt to
  measured frame time, and only with the owner's OK if it changes the look.
- Measure with Graphics Mode set to Manual and quality at max, or the frame-rate manager changes detail mid-test.

## Folklore and outdated
| Claim | Truth (date) |
|---|---|
| "Roblox has no occlusion culling" | Live everywhere since 2025-01-27. |
| "Max texture is 1024" | 4K shown since 2026-02 (budgeted by texture streaming). |
| "Shrink every texture for memory" | Streamed types now follow screen need (2025-12); UI/Sky/Terrain still don't. |
| "Tune RenderFidelity per part" | Ignored when mesh streaming is enabled (2026 opt-in). |
| "StreamingMesh for far models" | SLIM replaces it (2025-12). |
| "Unions have no LOD / never instance" | Changed 2017-18; still avoid for other reasons. |
| "SurfaceAppearance is bad on mobile, use Textures" | Unmeasured personal claim (2025). |
| "DoubleSided is expensive", "75k parts max" | Unsourced. |
| "Hollow out terrain to save memory" | Staff (2021): filled terrain is cheaper; one test 19 MB filled vs 228 MB hollow. |
