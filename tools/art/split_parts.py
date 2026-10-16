"""Cut a baked toy's moving bits into their own mesh (same UVs, so the same uploaded maps fit both).

& 'D:/Blender/blender.exe' -b assets/models/toys/floor-fan/floor-fan.blend --python tools/art/split_parts.py -- floor-fan floor-fan-blades 18 28

Loose parts lying wholly between Z_MIN and Z_MAX (studs, Z up) move to NEW; both meshes are re-exported as FBX with
toys.py's settings. NEW/checks.json records size_xyz and "axis": the Blender XY point the part turns about, measured
from its bounding-box centre (Roblox centres a MeshPart on its bounds, so the spinner needs this offset).
Run it again after toys.py rebuilds the toy, which puts the parts back in one mesh.
"""
import json, sys
from pathlib import Path
import bmesh, bpy

name, new, zmin, zmax = sys.argv[sys.argv.index("--") + 1:]
zmin, zmax = float(zmin), float(zmax)
toys = Path(__file__).resolve().parents[2] / "assets/models/toys"
obj = bpy.data.objects[name]

bm = bmesh.new(); bm.from_mesh(obj.data)
seen, moving = set(), []
for f in bm.faces:
    if f in seen: continue
    part, stack = [], [f]
    seen.add(f)
    while stack:
        g = stack.pop(); part.append(g)
        for e in g.edges:
            for h in e.link_faces:
                if h not in seen: seen.add(h); stack.append(h)
    zs = [v.co.z for g in part for v in g.verts]
    if min(zs) >= zmin and max(zs) <= zmax: moving += part
for f in bm.faces: f.select = f in set(moving)
bm.to_mesh(obj.data); bm.free()
assert moving, "nothing in that height band"

bpy.context.view_layer.objects.active = obj
bpy.ops.object.mode_set(mode="EDIT"); bpy.ops.mesh.separate(type="SELECTED"); bpy.ops.object.mode_set(mode="OBJECT")
part = next(o for o in bpy.context.scene.objects if o.type == "MESH" and o is not obj); part.name = new


def export(o, path):
    bpy.ops.object.select_all(action="DESELECT"); o.select_set(True)
    path.parent.mkdir(exist_ok=True)
    bpy.ops.export_scene.fbx(filepath=str(path), use_selection=True, object_types={"MESH"}, apply_unit_scale=False,
                             global_scale=1, axis_forward="-Z", axis_up="Y", bake_space_transform=False,
                             mesh_smooth_type="OFF", path_mode="AUTO", embed_textures=False, add_leaf_bones=False)


export(obj, toys / name / f"{name}.fbx")
export(part, toys / new / f"{new}.fbx")
vs = [part.matrix_world @ v.co for v in part.data.vertices]
lo = [min(v[i] for v in vs) for i in range(3)]; hi = [max(v[i] for v in vs) for i in range(3)]
mid = [(a + b) / 2 for a, b in zip(lo, hi)]
(toys / new / "checks.json").write_text(json.dumps({
    "toy": new, "cut_from": name, "triangles": len(part.data.polygons), "lowest_z": round(lo[2], 3),
    "size_xyz": [round(b - a, 3) for a, b in zip(lo, hi)], "axis": [round(-mid[0], 3), round(-mid[1], 3)]}, indent=2))
print("moved", len(moving), "faces; body", len(obj.data.polygons), "faces")
