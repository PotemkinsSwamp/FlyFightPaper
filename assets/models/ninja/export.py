"""Export the approved Ninja from its resting pose. Run with Blender --background --python export.py.
The visual body carries the scarf bones. hullHit is the rigid collision mesh.
"""
import json
from pathlib import Path

import bpy
import numpy as np
from mathutils import Matrix, Vector
from mathutils.kdtree import KDTree

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
BUILD = ROOT / ".planning/skins/ninja/build/tail-10"
WORK = ROOT / ".planning/skins/ninja/roblox"
WORK.mkdir(exist_ok=True, parents=True)
OUT = HERE / "ninja.fbx"
LENGTH = 8.4
# Same half-turn compensation, FBX axes and units as the Dragon.
TO_EXPORT = Matrix(((0,-LENGTH,0,0),(LENGTH,0,0,-LENGTH/2),(0,0,LENGTH,0),(0,0,0,1)))
TO_GAME = Matrix(((0,LENGTH,0,0),(0,0,LENGTH,0),(LENGTH,0,0,-LENGTH/2),(0,0,0,1)))

bpy.ops.wm.open_mainfile(filepath=str(HERE / "ninja-motion.blend"))
source = bpy.data.objects["skin"]
skeleton = bpy.data.objects["Scarf rig"]
a = np.load(BUILD / "mesh.npz")
verts, tris, labels = a["V"], a["T"], a["names"][a["part"]]
assert np.array_equal(tris, [p.vertices[:] for p in source.data.polygons])
assert np.allclose(verts, [v.co[:] for v in source.data.vertices])
uv_layer = source.data.uv_layers.active.data
uv = np.array([[uv_layer[i].uv[:] for i in p.loop_indices] for p in source.data.polygons])
export_v = np.array([TO_EXPORT @ Vector(v) for v in verts])
game_v = np.array([TO_GAME @ Vector(v) for v in verts])
plate = labels == "plate"
scarf = np.isin(labels, ["ribbon_lower", "ribbon_upper"])
left = verts[tris].mean(axis=1)[:,1] < 0
masks = dict(body=~plate, bladeL=plate & left, bladeR=plate & ~left, hullHit=~scarf)

arm = bpy.data.objects.new("NinjaRig", skeleton.data.copy())
arm.data.transform(TO_EXPORT)
arm.data.pose_position = "REST"
bpy.context.scene.collection.objects.link(arm)
objects = {}
bounds = {}
for name, mask in masks.items():
    ids, compact = np.unique(tris[mask], return_inverse=True)
    geo = bpy.data.meshes.new(name)
    geo.from_pydata(export_v[ids].tolist(), [], compact.reshape(-1,3).tolist())
    geo.update()
    uvs = geo.uv_layers.new(name="UVMap").data
    for poly, original in zip(geo.polygons, np.flatnonzero(mask)):
        poly.use_smooth = source.data.polygons[int(original)].use_smooth
        for loop, texcoord in zip(poly.loop_indices, uv[original]):
            uvs[loop].uv = texcoord
    obj = bpy.data.objects.new(name, geo)
    bpy.context.scene.collection.objects.link(obj)
    objects[name] = obj
    bounds[name] = {"min":game_v[ids].min(0).round(6).tolist(), "max":game_v[ids].max(0).round(6).tolist()}
    if name == "body":
        groups = [obj.vertex_groups.new(name=g.name) for g in source.vertex_groups]
        for i, src in enumerate(ids):
            for weight in source.data.vertices[int(src)].groups:
                groups[weight.group].add([i], weight.weight, "REPLACE")
        obj.parent = arm
        obj.modifiers.new("Scarf", "ARMATURE").object = arm

bpy.ops.object.select_all(action="DESELECT")
for obj in [arm,*objects.values()]:
    obj.select_set(True)
bpy.context.view_layer.objects.active = arm
bpy.ops.export_scene.fbx(filepath=str(OUT), use_selection=True, object_types={"MESH","ARMATURE"},
    global_scale=.01, apply_unit_scale=False, apply_scale_options="FBX_SCALE_NONE",
    axis_forward="-Z", axis_up="Y", bake_space_transform=False, use_mesh_modifiers=False,
    use_triangles=True, mesh_smooth_type="FACE", add_leaf_bones=False, bake_anim=False,
    path_mode="STRIP", embed_textures=False, use_custom_props=False)
bones = {}
for bone in skeleton.data.bones:
    frame = TO_GAME @ bone.matrix_local
    rot = frame.to_quaternion().to_matrix()
    bones[bone.name] = {"parent":bone.parent.name if bone.parent else None,
                        "origin":list(frame.translation), "rotation":[list(r) for r in rot]}

# Remove source and exported objects to ensure exact names in the roundtrip.
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=str(OUT), global_scale=100)
imported = {o.name:o for o in bpy.context.scene.objects if o.type=="MESH"}
assert set(imported)==set(masks), set(imported)
for name,obj in imported.items():
    # FBX may reorder faces and vertices. Match faces in space and verify their UV corners.
    assert len(obj.data.polygons) == np.count_nonzero(masks[name])
    original_verts=export_v[tris[masks[name]]]
    centers=original_verts.mean(axis=1)
    search=KDTree(len(centers))
    for k,c in enumerate(centers): search.insert(c,k)
    search.balance()
    original_uv=uv[masks[name]]
    layer=obj.data.uv_layers.active.data
    for poly in obj.data.polygons:
        points=np.array([obj.matrix_world @ obj.data.vertices[i].co for i in poly.vertices])
        matches=search.find_range(points.mean(axis=0),1e-4)
        actual_uv=np.array([layer[i].uv for i in poly.loop_indices])
        def agrees(match):
            tri=original_verts[match[1]]
            distance=np.linalg.norm(points[:,None]-tri,axis=2)
            idx=distance.argmin(axis=1)
            return distance.min(axis=1).max()<1e-4 and np.allclose(actual_uv,original_uv[match[1]][idx],atol=1e-5)
        assert any(agrees(m) for m in matches), (name,poly.index,points)
body=imported["body"]
rig=body.find_armature()
assert rig and set(rig.data.bones.keys())==set(bones)
assert all(not obj.animation_data for obj in bpy.context.scene.objects)
assert not [i for i in bpy.data.images if i.filepath]
assert all(abs(sum(g.weight for g in v.groups)-1)<1e-5 for v in body.data.vertices)
test_bone=rig.pose.bones["ribbon_lower_3"]
test_bone.rotation_mode="XYZ"
test_bone.rotation_euler.x=0.3
bpy.context.view_layer.update()
moved=body.evaluated_get(bpy.context.evaluated_depsgraph_get())
delta=np.linalg.norm(np.array([v.co[:] for v in moved.data.vertices])-np.array([v.co[:] for v in body.data.vertices]),axis=1)
assert (delta>0.001).sum()>20
assert max(d for d,v in zip(delta,body.data.vertices) if any(body.vertex_groups[g.group].name=="Plane" and g.weight>.99 for g in v.groups))<1e-4
(WORK/"geometry.json").write_text(json.dumps({"pieces":bounds,"bones":bones},indent=2))
print("Verified four meshes, UVs, armature deformation, rigid vertices and texture-free export:", OUT)
