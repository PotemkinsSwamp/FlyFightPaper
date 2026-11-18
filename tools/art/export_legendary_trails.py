"""Export the meshes shown in the approved Legendary trail videos, plus a rigged wake.
Run Blender in background with this script after python tools/art/trail_atlas.py.
The FBX carries UVs but no references to texture files. Roblox receives the atlas separately.
"""
from pathlib import Path
from math import cos, sin, tau, exp
import json
import sys

import bpy
from mathutils import Matrix, Vector

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
OUT = ROOT / "assets/models/trails"
sys.path.insert(0,str(HERE))
import trail_pieces
from trail_atlas import NAMES as TILES

NAMES = ("ninja_star","forked_flame","wavelet","upper_jaw","lower_jaw","tread_shred","droplet")
# Open Cloud rotates the FBX half a turn. Authoring (x,y,z) becomes Roblox (x,z,-y).
HALF = Matrix.Rotation(3.141592653589793,4,"Z")
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
def add(name,data):
    obj = bpy.data.objects.new(name,data)
    scene.collection.objects.link(obj)
    return obj

def set_uvs(name,mesh):
    low = [min(v.co[i] for v in mesh.vertices) for i in range(3)]
    high = [max(v.co[i] for v in mesh.vertices) for i in range(3)]
    uvs = mesh.uv_layers.new(name="UVMap").data
    for face in mesh.polygons:
        material = face.material_index
        for loop in face.loop_indices:
            idx=mesh.loops[loop].vertex_index
            v=mesh.vertices[idx].co
            x,y,z=[(v[i]-low[i])/max(.001,high[i]-low[i]) for i in range(3)]
            def field(key):
                return mesh.attributes[key].data[idx].value
            u,w=x,y
            if name=="ninja_star":
                tile="rim" if material else "steel"
            elif name=="forked_flame":
                tile="flame_hot" if material else "flame"
                u,w=0.5+0.5*field("flame_width"),field("flame_length")
            elif name=="wavelet":
                tile="wave"
                u,w=y,field("foam")
            elif name in ("upper_jaw","lower_jaw"):
                tile=("gum","gum_inner","enamel","root","palate")[material]
                if tile=="enamel":
                    u,w=field("enamel_ridge"),field("enamel_tip")
            elif name=="tread_shred":
                tile="tread" if material else "rubber"
            else:
                tile="white"
            slot=TILES.index(tile)
            # Five padded texels on each side prevent a neighbour showing under mip filtering.
            uvs[loop].uv=((slot%4+.02+.96*u)/4,1-(slot//4+.02+.96*w)/4)
        face.material_index=0

bounds={}
meshes=[]
def record(name,mesh):
    points=[(v.co.x,v.co.z,-v.co.y) for v in mesh.vertices]
    bounds[name]={key:[round(fn(p[i] for p in points),6) for i in range(3)]
                  for key,fn in (("min",min),("max",max))}
    mesh.transform(HALF)
for i,name in enumerate(NAMES):
    mesh=trail_pieces.mesh(name)
    set_uvs(name,mesh)
    record(name,mesh)
    obj=add(name,mesh)
    obj.location.x = 2.4*i
    meshes.append(obj)

# The approved Stream.pose surface frozen at its neutral phase. Thirteen local
# bone stations drive the path in the game, with smooth interpolation in between.
length=80.0
rings,sides=78,28
points=[]
faces=[]
for i in range(rings):
    k=i/(rings-1)
    phase=k*22
    width=max(.012,(.48+2.25*(1-exp(-16*k)))*(1-k**2.4))
    height=width*(.41+.12*sin(phase))
    for j in range(sides):
        a=tau*j/sides
        fold=1+.21*cos(3*a+phase)+.14*sin(2*a-phase*.65)
        points.append((width*(cos(a)*fold+.17*sin(phase*.74)),-k*length,
                       height*(sin(a)*fold+.35*cos(2*a+phase)+.31*cos(phase))))
        if i:
            b=i*sides+j
            c=i*sides+(j+1)%sides
            faces.append((b-sides,c-sides,c,b))
faces.extend([tuple(range(sides-1,-1,-1)),tuple(range((rings-1)*sides,rings*sides))])
mesh=bpy.data.meshes.new("cloak_stream")
mesh.from_pydata(points,[],faces)
mesh.update()
for p in mesh.polygons: p.use_smooth=True
record("cloak_stream",mesh)
obj=add("cloak_stream",mesh)
meshes.append(obj)
rig=add("wake_skeleton",bpy.data.armatures.new("Wake bones"))
obj.parent=rig
bpy.context.view_layer.objects.active=rig
rig.select_set(True)
bpy.ops.object.mode_set(mode="EDIT")
names=[]
for i in range(13):
    name=f"wake_{i:02d}"
    names.append(name)
    bone=rig.data.edit_bones.new(name)
    bone.head=(0,i*length/12,0)
    bone.tail=(0,i*length/12+1,0)
bpy.ops.object.mode_set(mode="OBJECT")
groups=[obj.vertex_groups.new(name=n) for n in names]
for i in range(rings):
    pos=i*12/(rings-1)
    k=int(pos)
    ids=list(range(i*sides,(i+1)*sides))
    groups[k].add(ids,1-(pos-k),"REPLACE")
    if pos>k: groups[k+1].add(ids,pos-k,"REPLACE")
obj.modifiers.new("Wake bend","ARMATURE").object=rig
# Rack the ordinary pieces beside the wake; pivot offsets are recorded in original author units.
rig.location.x=-7
meta={"basis":"Blender (x,y,z) to intended Roblox (x,z,-y)",
      "wakeLength":length,"wakeBones":names,"bounds":bounds}
(OUT/"legendary-pieces.json").write_text(json.dumps(meta,indent=2)+"\n")
fbx=OUT/"legendary-trails.fbx"
bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.fbx(filepath=str(fbx),use_selection=True,object_types={"MESH","ARMATURE"},
    global_scale=.01,apply_unit_scale=False,apply_scale_options="FBX_SCALE_NONE",axis_forward="-Z",axis_up="Y",
    bake_space_transform=False,use_mesh_modifiers=False,use_triangles=True,mesh_smooth_type="FACE",
    add_leaf_bones=False,bake_anim=False,path_mode="STRIP",embed_textures=False,use_custom_props=False)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=str(fbx),global_scale=100)
rest={o.name:o for o in bpy.context.scene.objects if o.type=="MESH"}
assert set(rest)==set(bounds)
for name in NAMES: assert rest[name].data.uv_layers.active
assert not [im for im in bpy.data.images if im.filepath]
wake=rest["cloak_stream"]
arm=wake.find_armature()
assert arm and set(arm.data.bones.keys())==set(names)
assert all(abs(sum(g.weight for g in v.groups)-1)<.00001 for v in wake.data.vertices)
print("Verified",list(rest),"and 13 weighted stations")
