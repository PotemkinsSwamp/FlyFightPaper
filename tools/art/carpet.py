"""The one shared carpet normal + roughness map every rug tile wears (one 100-stud tile = one 1024 picture).
Woven loops (160 per tile, ~0.6 studs) and fibre fuzz; seamless across tiles (4D noise on a torus), no large tilts
that would shade tiles unevenly.

D:/Blender/blender.exe -b --python tools/art/carpet.py   ->  assets/rug/carpet/normal.png, roughness.png
"""
from pathlib import Path
import math
import bpy

OUT = Path(__file__).resolve().parents[2] / "assets" / "rug" / "carpet"
SIZE, LOOPS = 1024, 160

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.render.engine = "CYCLES"
scene.cycles.device = "CPU"
scene.cycles.samples = 8
bpy.ops.mesh.primitive_plane_add(size=2)
plane = bpy.context.active_object

mat = bpy.data.materials.new("Carpet")
plane.data.materials.append(mat)
nt = mat.node_tree
N, L = nt.nodes, nt.links
bsdf = N["Principled BSDF"]
uv = N.new("ShaderNodeTexCoord").outputs["UV"]
sep = N.new("ShaderNodeSeparateXYZ"); L.new(uv, sep.inputs[0])


def math_node(op, a, b=None):
    n = N.new("ShaderNodeMath"); n.operation = op
    for k, v in enumerate((a, b)):
        if v is None: continue
        if isinstance(v, (int, float)): n.inputs[k].default_value = v
        else: L.new(v, n.inputs[k])
    return n.outputs[0]


def wave(axis):                                   # sin(2*pi*LOOPS*u): whole loops per tile, so it tiles
    return math_node("SINE", math_node("MULTIPLY", sep.outputs[axis], 2 * math.pi * LOOPS))


def ring(axis, r=1.0):                            # (cos, sin) of 2*pi*u: a circle, so noise wraps at the tile edge
    a = math_node("MULTIPLY", sep.outputs[axis], 2 * math.pi)
    return math_node("MULTIPLY", math_node("COSINE", a), r), math_node("MULTIPLY", math_node("SINE", a), r)


cu, su = ring(0); cv, sv = ring(1)
xyz = N.new("ShaderNodeCombineXYZ")
for k, s in enumerate((cu, su, cv)): L.new(s, xyz.inputs[k])


def noise(scale, detail):
    n = N.new("ShaderNodeTexNoise"); n.noise_dimensions = "4D"
    n.inputs["Scale"].default_value = scale; n.inputs["Detail"].default_value = detail
    L.new(xyz.outputs[0], n.inputs["Vector"]); L.new(sv, n.inputs["W"])
    return n.outputs["Fac"]


weave = math_node("MULTIPLY", wave(0), wave(1))                    # little bumps in a woven grid
fuzz = noise(50, 4)                                                # fibre fuzz, a few pixels across
swirl = noise(5, 2)                                                # gentle pile direction changes, ~4 studs
height = math_node("ADD", math_node("MULTIPLY", weave, .45), math_node("ADD", math_node("MULTIPLY", fuzz, .9),
                                                                         math_node("MULTIPLY", swirl, .25)))
bump = N.new("ShaderNodeBump"); bump.inputs["Strength"].default_value = .35; bump.inputs["Distance"].default_value = .002
L.new(height, bump.inputs["Height"]); L.new(bump.outputs[0], bsdf.inputs["Normal"])
rough = N.new("ShaderNodeMapRange")                                # matte felt: 0.82..0.97
rough.inputs["To Min"].default_value, rough.inputs["To Max"].default_value = .82, .97
L.new(fuzz, rough.inputs["Value"]); L.new(rough.outputs[0], bsdf.inputs["Roughness"])

for kind in ("NORMAL", "ROUGHNESS"):
    img = bpy.data.images.new(kind, SIZE, SIZE)
    img.colorspace_settings.name = "Non-Color"
    node = N.new("ShaderNodeTexImage"); node.image = img
    N.active = node
    plane.select_set(True); bpy.context.view_layer.objects.active = plane
    bpy.ops.object.bake(type=kind, margin=0)
    img.filepath_raw = str(OUT / f"{kind.lower()}.png"); img.file_format = "PNG"; img.save()
    N.remove(node)
    print("baked", img.filepath_raw)
