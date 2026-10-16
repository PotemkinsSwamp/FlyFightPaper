"""Cut a box out of a finished hero building's pieces, keep their textures, and close the cut with flat walls.

Blender -b --factory-startup --python-exit-code 1 --python tools/art/cut_piece.py --
    assets/models/gateway-towers --box -42 -60 -1 42 60 9.9

The box is in the building's Blender frame (studs, base centre, front -Y). Every piece of parts.json it touches is
cut along the box's x sides, loses the faces inside, and gets a wall on each cut side, coloured from the texture
just inside the cut, so the textures need no new upload; only the changed meshes do. parts.json gets the new boxes.
First use: the gateway towers' raised floor under the arch, cut off the street (Alan 2026-10-16).
"""
import argparse
import json
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).parent))
import hero  # noqa: E402


def cut(obj, box):
    x0, y0, z0, x1, y1, z1 = box
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    for x in (x0, x1):
        geom = bm.verts[:] + bm.edges[:] + bm.faces[:]
        bmesh.ops.bisect_plane(bm, geom=geom, plane_co=(x, 0, 0), plane_no=(1, 0, 0))
    uv = bm.loops.layers.uv.active
    gone = [f for f in bm.faces if x0 < f.calc_center_median().x < x1 and y0 < f.calc_center_median().y < y1
            and z0 < f.calc_center_median().z < z1]
    if not gone:
        bm.free()
        return False
    top = max(gone, key=lambda f: f.calc_center_median().z)            # the cut floor's top: its colour paints the walls
    paint = sum((l[uv].uv for l in top.loops), Vector((0, 0))) / len(top.loops)
    material = top.material_index
    lo = min(v.co.y for f in gone for v in f.verts)
    hi = max(v.co.y for f in gone for v in f.verts)
    height = max(v.co.z for f in gone for v in f.verts)
    bmesh.ops.delete(bm, geom=gone, context="FACES")
    xs = [v.co.x for v in bm.verts]
    for x, inward in ((x0, 1), (x1, -1)):
        if not (min(xs) - .01 <= x <= max(xs) + .01):
            continue
        corners = [(x, lo, 0), (x, hi, 0), (x, hi, height), (x, lo, height)]
        face = bm.faces.new([bm.verts.new(c) for c in (corners if inward < 0 else corners[::-1])])
        face.material_index = material
        for loop in face.loops:
            loop[uv].uv = paint
    bm.to_mesh(obj.data)
    bm.free()
    return True


def main():
    argv = sys.argv[sys.argv.index("--") + 1:]
    parser = argparse.ArgumentParser()
    parser.add_argument("folder", type=Path)
    parser.add_argument("--box", type=float, nargs=6, required=True)
    args = parser.parse_args(argv)
    spec_path = args.folder / "parts.json"
    spec = json.loads(spec_path.read_text())
    for piece in spec["pieces"]:
        path = args.folder / "parts" / (piece["prefix"] + ".fbx")
        bpy.ops.wm.read_factory_settings(use_empty=True)
        bpy.ops.import_scene.fbx(filepath=str(path), use_custom_normals=True)
        obj = next(o for o in bpy.data.objects if o.type == "MESH")
        hero.active(obj)
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        if not cut(obj, args.box):
            continue
        hero.active(obj)
        bpy.ops.export_scene.fbx(filepath=str(path), use_selection=True, object_types={"MESH"},
                                 apply_unit_scale=False, global_scale=1, axis_forward="-Z", axis_up="Y",
                                 bake_space_transform=False, mesh_smooth_type="OFF", path_mode="AUTO",
                                 embed_textures=False, add_leaf_bones=False)
        (lo, hi) = hero.bounds(obj)
        piece["bounding_box"] = {"min": [round(float(v), 5) for v in lo], "max": [round(float(v), 5) for v in hi]}
        obj.data.calc_loop_triangles()
        piece["triangles"] = len(obj.data.loop_triangles)
        print("CUT", piece["prefix"], piece["bounding_box"], piece["triangles"], flush=True)
    spec_path.write_bytes((json.dumps(spec, indent=2) + "\n").encode())


main()
