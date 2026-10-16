"""Cut plane pieces into a left and a right half at the plane's centre line (x = 0).

Run: D:/Blender/blender.exe -b --factory-startup --python-exit-code 1 --python tools/art/split_halves.py
Reads the FBX files listed in planes/classic/parts.json and planes/set/parts.json; writes <stem>-L.fbx and
<stem>-R.fbx beside each one (existing halves are kept as they are) and planes/halves.json (the same export records as
parts.json, one per half).
Why: wings (Alan, 2026-10-12): a wing is one sheet through the body, so on the wide cardboard bodies its root hid inside
the box and the wing looked sunk in. With halves, Aircraft.luau slides each half out to the body's own side.
Body, nose, tail and booster paper/cardboard/tube (Alan, 2026-10-13): free-for-all planes are red on the left and blue
on the right all the way down the middle; stripes and tape stay whole (white/yellow either side).
"""
import json
from pathlib import Path

import bmesh, bpy

ROOT = Path(__file__).resolve().parents[2]
PLANES = ROOT / "assets/models/planes"
FBX = dict(global_scale=.01, apply_unit_scale=False, apply_scale_options="FBX_SCALE_NONE", axis_forward="-Z", axis_up="Y",
           bake_space_transform=True, use_triangles=True, mesh_smooth_type="FACE", add_leaf_bones=False, bake_anim=False,
           path_mode="STRIP", embed_textures=False, object_types={"MESH"}, use_selection=True)


def load(path):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=str(path), global_scale=100, axis_forward="-Z", axis_up="Y", bake_space_transform=True)
    obj = [o for o in bpy.context.scene.objects if o.type == "MESH"][0]
    obj.data.transform(obj.matrix_world); obj.matrix_world.identity()
    return obj


def bounds(obj):
    xs = [[v.co[i] for v in obj.data.vertices] for i in range(3)]
    return [min(a) for a in xs], [max(a) for a in xs]


def half(obj, side, fill):
    """Keep x <= 0 (left, side -1) or x >= 0 (right, side 1). A closed solid gets its cut face filled so each half
    stays solid (hit shapes, loose remains); wings stay open like their uploaded halves."""
    bm = bmesh.new(); bm.from_mesh(obj.data)
    closed = fill and all(e.is_manifold for e in bm.edges)
    bmesh.ops.bisect_plane(bm, geom=bm.verts[:] + bm.edges[:] + bm.faces[:], plane_co=(0, 0, 0), plane_no=(side, 0, 0),
                                 clear_outer=False, clear_inner=True)
    if closed:
        # The whole piece was closed, so every open edge now is on the cut (some lie on old edges at x = 0).
        bmesh.ops.holes_fill(bm, edges=[e for e in bm.edges if e.is_boundary], sides=0)
        bmesh.ops.triangulate(bm, faces=bm.faces[:])
    bm.to_mesh(obj.data); bm.free()
    return closed


def wanted(e):
    if e["part"].startswith("wings"): return "sticker" not in e["region"]
    return e["part"].startswith(("body", "nose", "tail", "boost")) and e["region"] in ("paper", "cardboard", "tube")


records = []
for folder in ("classic", "set"):
    manifest = json.loads((PLANES / folder / "parts.json").read_text(encoding="utf-8"))
    for e in manifest["exports"]:
        if not wanted(e): continue
        source = PLANES / folder / e["file"]
        whole = bounds(load(source))
        # Blender frame after this import: X right, Y back (-Roblox Z), Z up; the FBX export flips it back.
        assert abs(whole[0][0] + e["size"][0] / 2) < .01 and abs(whole[1][0] - e["size"][0] / 2) < .01, (e["object"], whole)
        for side, tag in ((-1, "L"), (1, "R")):
            obj = load(source); closed = half(obj, side, not e["part"].startswith("wings"))
            lo, hi = bounds(obj)
            centre = [(lo[i] + hi[i]) / 2 for i in range(3)]
            for v in obj.data.vertices: v.co.x -= centre[0]   # each half's file is centred on its own box, like every part
            bpy.ops.object.select_all(action="DESELECT"); obj.select_set(True); bpy.context.view_layer.objects.active = obj
            name = f"{e['object']}-{tag}"
            if not (PLANES / folder / f"{name}.fbx").exists():   # uploaded halves keep their files byte for byte
                bpy.ops.export_scene.fbx(filepath=str(PLANES / folder / f"{name}.fbx"), **FBX)
            record = dict(e, file=f"{name}.fbx", object=name, side=tag, size=[round(hi[0] - lo[0], 6), e["size"][1], e["size"][2]],
                          triangles=sum(len(p.vertices) - 2 for p in obj.data.polygons))
            record["center_offset_from_slot"] = [round(e["center_offset_from_slot"][0] + centre[0], 6)] + e["center_offset_from_slot"][1:]
            record["bbox_center"] = [round(e["bbox_center"][0] + centre[0], 6)] + e["bbox_center"][1:]
            for key in ("bbox_min", "bbox_max", "slot_local_bbox_min", "slot_local_bbox_max", "fbx_local_bbox_min", "fbx_local_bbox_max"):
                record.pop(key, None)
            records.append(record)
            print("HALF", name, "filled" if closed else "open", record["size"], record["center_offset_from_slot"])

(PLANES / "halves.json").write_text(json.dumps({"from": "tools/art/split_halves.py", "exports": records}, indent=1) + "\n")
print("wrote", len(records), "halves")
