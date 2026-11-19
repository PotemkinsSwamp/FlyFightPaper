"""The hidden hit copies of the whole-shape Legendaries (Alan 2026-11-18): the drawn skin minus its extras, every tall fin
cut flat where a normal plane's tail fin ends (0.10 of the length above the skin's body top), the cut capped. Body,
wings, nose and tail count; the Race Car's spoiler and the Shark's top fin don't; the Ninja's scarf never did.
One FBX, one mesh per skin (named by skin id), in Roblox's axes and already turned half round as the Dragon's
roblox_fbx.py does (Open Cloud turns every FBX 180 degrees). Picture of what is cut: .planning/skins/hit-trim-preview.jpg.
    D:/Blender/blender.exe -b --factory-startup --python tools/art/skin_hit_hulls.py -- OUT.fbx
Writes OUT.fbx and OUT.json (each mesh's box in the skin's own frame, studs, nose to -z: config/skin-shapes.json's
pieces.hullHit min/max). Then upload with tools/upload_texture.py --model, read the MeshIds with LoadAsset, measure each
hull's area with tools/plane_areas.lua (BODY = the skin id) and write both into config/skin-shapes.json.
"""
import json, os, sys
import bpy, bmesh
import numpy as np

LONG = 8.4  # studs: the starter plane's length, the size every whole skin was uploaded at
FIN = 0.10  # a normal tail fin stands 0.10 of the plane's length above its body's top
B = ".planning/skins"
SKINS = {  # id: (built model with mesh.npz, parts left out whole)
    "hot_rod": (B + "/hot_rod/build/whole-06", []),
    "race_car": (B + "/race_car/build/whole-09", ["board", "end_plate", "strut"]),
    "stealth": (B + "/stealth/build/whole-06", []),
    "shark_jet": (B + "/shark/build/chin-13", ["back_fin"]),
    "ninja": (B + "/ninja/build/whole-09", ["knot", "ribbon_upper", "ribbon_lower"]),
}

out = os.path.abspath(sys.argv[sys.argv.index("--") + 1])
root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
for o in list(bpy.data.objects):
    bpy.data.objects.remove(o)
made, boxes = [], {}
for skin, (folder, extras) in SKINS.items():
    d = np.load(os.path.join(root, folder, "mesh.npz"), allow_pickle=True)
    V, T, part, names = d["V"], d["T"], d["part"], list(d["names"])
    keep = [i for i, n in enumerate(names) if n not in extras]
    T = T[np.isin(part, keep)]
    length = np.ptp(V[np.unique(T)][:, 0])
    cut = V[np.unique(T[part[np.isin(part, keep)] == names.index("body")])][:, 2].max() + FIN * length
    bm = bmesh.new()
    verts = [bm.verts.new(v) for v in V]
    for t in T:
        bm.faces.new([verts[i] for i in t])
    bmesh.ops.remove_doubles(bm, verts=bm.verts[:], dist=1e-7)
    for v in [v for v in bm.verts if not v.link_faces]:
        bm.verts.remove(v)
    bmesh.ops.bisect_plane(bm, geom=bm.verts[:] + bm.edges[:] + bm.faces[:], plane_co=(0, 0, cut), plane_no=(0, 0, 1), clear_outer=True)
    bmesh.ops.holes_fill(bm, edges=[e for e in bm.edges if e.is_boundary], sides=0)
    bmesh.ops.triangulate(bm, faces=bm.faces[:])
    P = np.array([v.co[:] for v in bm.verts])
    assert P[:, 2].max() <= cut + 1e-6, skin
    # Skin frame (x nose to tail 0..1, y side, z up) -> Roblox (x = y, y = z, z = x - 0.5) -> half turn -> Blender.
    for v in bm.verts:
        x, y, z = v.co
        v.co = (-y * LONG, (x - 0.5) * LONG, z * LONG)
    game = np.stack([P[:, 1], P[:, 2], P[:, 0] - 0.5], 1) * LONG
    boxes[skin] = {"min": game.min(0).round(6).tolist(), "max": game.max(0).round(6).tolist(), "triangles": len(bm.faces),
                   "cut_studs": round(cut * LONG, 4)}
    me = bpy.data.meshes.new(skin)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(skin, me)
    bpy.context.scene.collection.objects.link(ob)
    me.materials.append(bpy.data.materials.new(skin))
    made.append(ob)

bpy.ops.object.select_all(action="DESELECT")
for o in made:
    o.select_set(True)
want = sum(len(o.data.polygons) for o in made)
bpy.ops.export_scene.fbx(filepath=out, use_selection=True, object_types={"MESH"}, global_scale=.01, apply_unit_scale=False,
                         apply_scale_options="FBX_SCALE_NONE", axis_forward="-Z", axis_up="Y", bake_space_transform=True,
                         use_mesh_modifiers=True, use_triangles=True, mesh_smooth_type="FACE", add_leaf_bones=False,
                         bake_anim=False, path_mode="STRIP", embed_textures=False, use_custom_props=False)
before = set(bpy.data.objects)
bpy.ops.import_scene.fbx(filepath=out, global_scale=100)
back = [x for x in set(bpy.data.objects) - before if x.type == "MESH"]
got = sum(len(x.data.polygons) for x in back)
assert got == want and sorted(x.name.split(".")[0] for x in back) == sorted(SKINS), (got, want, [x.name for x in back])
json.dump(boxes, open(out[:-4] + ".json", "w"), indent=1)
print("HULLS", out, {k: (v["triangles"], v["min"], v["max"]) for k, v in boxes.items()})
