The active classroom is `classroom.rbxmx`. Aircraft and equipment use the native models in
`aircraft/` and `equipment/`. Their Blender sources, exported FBX files and 1024-pixel family
atlases are kept beside them. `assets.json` identifies the uploaded Roblox meshes and textures.
Roblox accepted both model uploads on October 7, 2026. Alan has not approved their appearance.
No Meshy generation credits were used.

The aircraft reuse the retained airframe and wings sources. Equipment reuses the retained
weapon/ammunition, pellet launcher and booster sources. Other retained art folders are source
material, not runtime loaders. Nothing generates the city from Luau geometry.

Rojo live sync does create new MeshParts with their meshes and SurfaceAppearances (checked 2026-10-09:
all 798 rug toys arrived in WORKING). If a changed mesh ever fails to show, run `python tools/save_place.py`,
then reopen `FlyFightPaper-WORKING.rbxlx` and reconnect Rojo.
The build preserves saved native art and includes scripts only from Rojo's build output.
See [Rojo's sync limitations](https://rojo.space/docs/v7/sync-details/).

Three retained tower families now have their original finished Blender files and plain
`tower.fbx` exports alongside the 1024 atlases. Their meshes have 9,134, 8,317 and
9,248 triangles. No newly generated replacement was needed.

`tools/art/fit_classroom_collisions.py` runs in Blender to fit native box colliders to
those retained meshes. It updates `classroom.rbxmx` offline. The ground arch, raised
underbridge and crossing belfry passages remain open. These are approximate collision
boxes with a four-stud source sampling grid; visual flight inspection is still required.

`classroom/structures.blend` recovers the six other retained building meshes directly
from Roblox's editable-mesh API, preserving their actual vertices, corner normals and
UVs. Plain FBX exports and five 1024-pixel family atlases are beside it. `assets.json`
records the new texture IDs. Roblox successfully loaded all five at 1024 by 1024.
The existing uploaded geometry is reused; no paid generation or replacement mesh upload.

The collision tool also reads that Blender source and intersects three mesh silhouettes
to preserve openings along either horizontal axis. The nine building families currently
use 759 anchored native boxes. Seven ground, bridge and upper passages passed native
sphere sweeps. Approximate edge fit, performance and all visible routes still need play.

The recovered source names describe their actual shapes: cardboard arch, tube tower,
cardboard skyscraper, upper gateway, gable house and toy-brick tower. The old saved
bank had misleading tunnel/gallery names. These are the same retained native meshes.

The chalkboard uses `classroom-chalkboard391-v2-fight.png`, centered without stretching
inside the retained wide board and baked into `classroom/chalkboard-atlas.png`.
The older drawing and the opaque text cover are removed. Smaller existing palette
and pencil-case textures stay below 1024 pixels rather than being enlarged for no gain.
