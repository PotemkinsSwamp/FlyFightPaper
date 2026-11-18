"""Build the Ninja's reusable scarf rig and blade shine from the approved Blender model.
Run Blender in background with --python tools/art/ninja_motion.py. Pass -- render for the MP4.
"""
from math import cos, sin, pi, exp
from pathlib import Path
import subprocess
import sys
import tempfile

import bpy
import numpy as np
from mathutils import Vector, Quaternion

ROOT = Path(__file__).resolve().parents[2]
BUILD = ROOT / ".planning/skins/ninja/build/tail-10"
OUTPUT = ROOT / ".planning/skins/motion/ninja"
RIG = ROOT / "assets/models/ninja/ninja-motion.blend"
FPS = 24
FRAMES = 144

bpy.ops.wm.open_mainfile(filepath=str(BUILD / "model.blend"))
scene = bpy.context.scene
skin = scene.objects["skin"]
mesh = np.load(BUILD / "mesh.npz")
assert np.allclose(mesh["V"], [v.co[:] for v in skin.data.vertices])
assert np.array_equal(mesh["T"], [p.vertices[:] for p in skin.data.polygons])

def empty(name):
    obj = bpy.data.objects.new(name, None)
    scene.collection.objects.link(obj)
    obj.empty_display_size = 0.04
    return obj

def part_faces(name):
    index = list(mesh["names"]).index(name)
    return np.flatnonzero(mesh["part"] == index)

# The moving plane and delayed samples share one flight action. Editing its keys
# updates the scarf in Blender without baking it again or enabling Python drivers.
plane = empty("Flight path")
position = Vector((0, 0, 0))
heading = 0
camera = scene.camera
camera.data.type = "PERSP"
camera.data.lens = 43
camera.data.clip_end = 100
for frame in range(1, FRAMES + 1):
    t = (frame - 1) / FPS
    bank = 0.62 * exp(-((t - 1.65) / 0.53)**2) - 0.64 * exp(-((t - 3.0) / 0.57)**2)
    speed = 1.4 + 2.9 * exp(-((t - 4.8) / 0.84)**4)
    heading += bank * 1.15 / FPS
    yaw = Quaternion((0, 0, 1), heading)
    position += yaw @ Vector((-speed / FPS, 0, 0))
    plane.location = position
    plane.rotation_euler = (bank, 0, heading)
    plane.keyframe_insert(data_path="location", frame=frame)
    plane.keyframe_insert(data_path="rotation_euler", frame=frame)
    # A level chase camera leaves the bank visible. Ease toward the blade side on boost.
    angle = 0.39 + 0.54 * exp(-((t - 4.8) / 1.35)**4)
    camera.location = position + yaw @ Vector((0.68 + 2.12*cos(angle), -2.12*sin(angle), 1.19))
    target = position + yaw @ Vector((0.80, -0.04, -0.045))
    camera.rotation_euler = (target-camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.keyframe_insert(data_path="location", frame=frame)
    camera.keyframe_insert(data_path="rotation_euler", frame=frame)

action = plane.animation_data.action
slot = plane.animation_data.action_slot
action.name = "Flight path - cruise, banks, boost"
def delayed_sample(delay):
    ghost = empty(f"Flight {delay} frames ago")
    track = ghost.animation_data_create().nla_tracks.new()
    strip = track.strips.new("Same flight, delayed", 1 + delay, action)
    strip.action_slot = slot
    strip.extrapolation = "HOLD"
    sensor = empty(f"Local turn over {delay} frames")
    sensor.parent = plane
    sensor.constraints.new("COPY_TRANSFORMS").target = ghost
    return ghost, sensor

armature = bpy.data.armatures.new("Ninja scarf")
rig = bpy.data.objects.new("Scarf rig", armature)
scene.collection.objects.link(rig)
rig.parent = plane
skin.parent = rig
bpy.context.view_layer.objects.active = rig
rig.select_set(True)
bpy.ops.object.mode_set(mode="EDIT")
root = armature.edit_bones.new("Plane")
root.head, root.tail = (0, 0, 0), (0.1, 0, 0)
chains = {}
rings_by_tail = {}
for tail in ("ribbon_upper", "ribbon_lower"):
    rings = np.unique(mesh["T"][part_faces(tail)]).reshape(16, 4)
    rings_by_tail[tail] = rings
    centers = mesh["V"][rings].mean(axis=1)
    chain = []
    for j in range(5):
        bone = armature.edit_bones.new(f"{tail}_{j+1}")
        bone.head, bone.tail = centers[3*j], centers[3*j+3]
        bone.parent = armature.edit_bones[chain[-1]] if chain else root
        bone.use_connect = bool(chain)
        chain.append(bone.name)
    chains[tail] = chain
bpy.ops.object.mode_set(mode="OBJECT")
groups = {b.name: skin.vertex_groups.new(name=b.name) for b in armature.bones}
fixed = set(range(len(skin.data.vertices)))
for tail, rings in rings_by_tail.items():
    chain = chains[tail]
    for i, ring in enumerate(rings):
        u = min(4, max(0, i / 3 - 0.5))
        joint = int(u)
        ids = ring.tolist()
        if i == 0:
            continue  # The four vertices embedded in the knot always follow the plane.
        fixed.difference_update(ids)
        groups[chain[joint]].add(ids, 1 - (u - joint), "REPLACE")
        if u > joint:
            groups[chain[joint+1]].add(ids, u - joint, "REPLACE")
groups["Plane"].add(sorted(fixed), 1.0, "REPLACE")
skin.modifiers.new("Flowing scarf", "ARMATURE").object = rig

def angle_driver(bone, axis, formula, ghost, sensor):
    driver = bone.driver_add("rotation_euler", axis).driver
    distance = driver.variables.new()
    distance.name, distance.type = "travel", "LOC_DIFF"
    distance.targets[0].id, distance.targets[1].id = plane, ghost
    for name, channel in (("turn", "ROT_Z"), ("roll", "ROT_X")):
        var = driver.variables.new()
        var.name, var.type = name, "TRANSFORMS"
        target = var.targets[0]
        target.id, target.transform_type, target.transform_space = sensor, channel, "LOCAL_SPACE"
    driver.expression = formula

for j in range(5):
    delay = j + 2
    ghost, sensor = delayed_sample(delay)
    for index, chain in enumerate(chains.values()):
        bone = rig.pose.bones[chain[j]]
        bone.rotation_mode = "XYZ"
        phase = round(j * 1.13 + index * 0.58, 3)
        # Actual travel over the sampling interval controls flutter amplitude.
        # At speed the broad ripples flatten. Delayed relative roll/yaw bends the ends into turns.
        speed = f"(travel*{FPS/delay:.4f})"
        wind = f"(min(1,{speed})/(1+0.55*{speed}))"
        # Slightly different resting curves keep the free ends apart in a reversal.
        clearance = 0.06 if index == 0 else -0.06
        angle_driver(bone, 0, f"{wind}*0.272*sin(frame*0.36-{phase})-0.232*roll+({clearance})", ghost, sensor)
        angle_driver(bone, 2, f"{wind}*0.16*sin(frame*0.31-{phase})+0.352*turn", ghost, sensor)

# Duplicate just the material for the measured metal faces. A diagonal band
# travels over their original paint in local coordinates, even as the plane turns.
metal = skin.data.materials[0].copy()
metal.name = "Wing blades - passing reflection"
skin.data.materials.append(metal)
for i in part_faces("plate"):
    skin.data.polygons[int(i)].material_index = 1
tree = metal.node_tree
shader = tree.nodes["Principled BSDF"]
def math_node(op, a, b):
    n = tree.nodes.new("ShaderNodeMath")
    n.operation = op
    for inp, value in zip(n.inputs, (a,b)):
        if isinstance(value, (int,float)):
            inp.default_value = value
        else:
            tree.links.new(value, inp)
    return n.outputs[0]
coords = tree.nodes.new("ShaderNodeTexCoord")
xyz = tree.nodes.new("ShaderNodeSeparateXYZ")
tree.links.new(coords.outputs["Object"], xyz.inputs[0])
span = math_node("ADD", xyz.outputs["X"], math_node("MULTIPLY", xyz.outputs["Y"], 0.28))
sweep = tree.nodes.new("ShaderNodeValue").outputs[0]
sweep.driver_add("default_value").driver.expression = "0.34+((frame+7)%44)*0.034"
band = math_node("ABSOLUTE", math_node("SUBTRACT",span,sweep), 0)
pulse = math_node("MAXIMUM", 0, math_node("SUBTRACT",1,math_node("MULTIPLY",band,32)))
original = shader.inputs["Base Color"].links[0].from_socket
mix = tree.nodes.new("ShaderNodeMixRGB")
tree.links.new(pulse, mix.inputs[0])
tree.links.new(original, mix.inputs[1])
mix.inputs[2].default_value = (0.94, 0.98, 1, 1)
tree.links.new(mix.outputs[0],shader.inputs["Base Color"])
tree.links.new(mix.outputs[0],shader.inputs["Emission Color"])
tree.links.new(pulse,shader.inputs["Emission Strength"])

scene.frame_start, scene.frame_end, scene.render.fps = 1, FRAMES, FPS
world_mix = next(n for n in scene.world.node_tree.nodes if n.type == "MIX_SHADER")
backdrop = world_mix.inputs[2].links[0].from_node
backdrop.inputs["Color"].default_value = (0.36, 0.48, 0.60, 1)
for name,frame in (("Cruise",1),("Bank",32),("Reverse bank",62),("Boost",99)):
    scene.timeline_markers.new(name,frame=frame)
scene.render.resolution_x, scene.render.resolution_y, scene.render.resolution_percentage = 1280,720,100
scene.eevee.taa_render_samples = 8
scene.frame_set(1)
RIG.parent.mkdir(exist_ok=True, parents=True)
OUTPUT.mkdir(exist_ok=True, parents=True)
bpy.ops.file.pack_all()
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(RIG), compress=True)
if "--" in sys.argv and "render" in sys.argv[sys.argv.index("--")+1:]:
    with tempfile.TemporaryDirectory(dir=OUTPUT) as folder:
        scene.render.image_settings.file_format = "PNG"
        scene.render.filepath = folder + "/frame-"
        bpy.ops.render.render(animation=True)
        subprocess.run(["ffmpeg","-y","-loglevel","error","-framerate",str(FPS),"-i",
                        folder+"/frame-%04d.png","-c:v","libx264","-crf","17","-pix_fmt","yuv420p",
                        "-movflags","+faststart",str(OUTPUT/"ninja-flight.mp4")],check=True)
        scene.frame_set(46)
        skin.modifiers["Flowing scarf"].show_render = False
        for i in part_faces("plate"):
            skin.data.polygons[int(i)].material_index = 0
        scene.render.filepath = folder + "/original.png"
        bpy.ops.render.render(write_still=True)
        subprocess.run(["ffmpeg","-y","-loglevel","error","-i",scene.render.filepath,
                        "-i",folder+"/frame-0046.png","-filter_complex","hstack",
                        "-frames:v","1",str(OUTPUT/"before-and-after.jpg")],check=True)
