"""Export the four approved Legendary hulls together, keeping their original flat UV sheets.
Run Blender --background --python tools/art/export_legendary_hulls.py from any directory.
"""
from pathlib import Path

import bpy
import numpy as np
from mathutils import Matrix

ROOT = Path(__file__).resolve().parents[2]
SKINS = ROOT / ".planning/skins"
ROUNDS = {"shark_jet": ("shark", "chin-13"), "hot_rod": ("hot_rod", "whole-06"),
          "race_car": ("race_car", "whole-09"), "stealth": ("stealth", "whole-06")}
OUT = ROOT / "assets/models/planes/legendary-hulls.fbx"
# Same units, nose direction and Open Cloud half-turn compensation as Ninja.
length = 8.4
to_fbx = Matrix(((0, -length, 0, 0), (length, 0, 0, -length/2),
                 (0, 0, length, 0), (0, 0, 0, 1)))
bpy.ops.wm.read_factory_settings(use_empty=True)
for i, (name, (folder, version)) in enumerate(ROUNDS.items()):
    build = SKINS / folder / "build" / version
    with bpy.data.libraries.load(str(build / "model.blend")) as (available, selected):
        selected.objects = ["skin"]
    obj = selected.objects[0]
    mesh = obj.data
    ref = np.load(build / "mesh.npz")
    assert np.allclose(ref["V"], [v.co[:] for v in mesh.vertices])
    assert np.array_equal(ref["T"], [p.vertices[:] for p in mesh.polygons])
    uv = np.asarray([loop.uv[:] for loop in mesh.uv_layers.active.data]).reshape(-1, 3, 2)
    assert np.allclose(uv, np.load(SKINS / "safety" / (folder + "-uv.npy")))
    mesh.materials.clear()
    mesh.transform(to_fbx)
    obj.name = mesh.name = name
    obj.matrix_world = Matrix.Translation((12*i, 0, 0))
    bpy.context.scene.collection.objects.link(obj)
bpy.ops.export_scene.fbx(filepath=str(OUT), object_types={"MESH"}, global_scale=.01,
    apply_unit_scale=False, apply_scale_options="FBX_SCALE_NONE", axis_forward="-Z", axis_up="Y",
    use_mesh_modifiers=False, use_triangles=True, mesh_smooth_type="FACE", bake_anim=False,
    path_mode="STRIP", embed_textures=False)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=str(OUT), global_scale=100)
assert {o.name for o in bpy.context.scene.objects} == set(ROUNDS)
assert not any(img.filepath for img in bpy.data.images)
for obj in bpy.context.scene.objects:
    folder, version = ROUNDS[obj.name]
    ref = np.load(SKINS / folder / "build" / version / "mesh.npz")
    assert len(obj.data.polygons) == len(ref["T"]) and obj.data.uv_layers.active
print("Verified four UV-mapped hulls with no bundled images", OUT)
