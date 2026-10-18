"""Turns a Meshy text-to-motion clip (SMPL skeleton, T-pose rest) into Roblox R15 joint poses.

  D:/Blender/blender.exe -b --python tools/meshy_to_r15.py -- assets/animations/meshy/NAME.fbx [STEP]

Writes assets/animations/meshy/NAME.r15.json: {"fps", "frames": [{"t", "poses": {Part: [x,y,z, qx,qy,qz,qw]}}]},
one keyframe every STEP source frames (default 2, so 15 a second). tools/r15_keyframes.luau builds the Roblox
KeyframeSequence from it.

How: every R15 part follows one SMPL bone's turn away from its rest pose, measured in the world, so bone roll and the
spine/collar bones in between don't matter. R15 rests with arms down and SMPL with arms out, so each limb first turns
from the R15 rest direction to the SMPL rest direction (shortest turn). A joint's pose is the child part's turn seen
from its parent part. The hips also rise and dip with the clip (scaled to R15 leg length) but stay over the same spot:
the clips wander a few studs, which would walk a winner off their desk.
"""
import bpy, json, sys
from mathutils import Matrix, Vector

src = sys.argv[-1] if not sys.argv[-1].isdigit() else sys.argv[-2]
step = int(sys.argv[-1]) if sys.argv[-1].isdigit() else 2
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=src)
arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
scene = bpy.context.scene
first, last = (int(v) for v in arm.animation_data.action.frame_range)

# R15 part -> (SMPL bone, R15 parent part, bone whose head the limb points at in rest, R15 rest direction)
DOWN, UP = Vector((0, 0, -1)), Vector((0, 0, 1))
PARTS = {
    "LowerTorso": ("Pelvis", None, None, None),
    "UpperTorso": ("Spine3", "LowerTorso", None, None),
    "Head": ("Head", "UpperTorso", None, None),
    "LeftUpperArm": ("L_Shoulder", "UpperTorso", "L_Elbow", DOWN),
    "LeftLowerArm": ("L_Elbow", "LeftUpperArm", "L_Wrist", DOWN),
    "LeftHand": ("L_Wrist", "LeftLowerArm", "L_Middle1", DOWN),
    "RightUpperArm": ("R_Shoulder", "UpperTorso", "R_Elbow", DOWN),
    "RightLowerArm": ("R_Elbow", "RightUpperArm", "R_Wrist", DOWN),
    "RightHand": ("R_Wrist", "RightLowerArm", "R_Middle1", DOWN),
    "LeftUpperLeg": ("L_Hip", "LowerTorso", "L_Knee", DOWN),
    "LeftLowerLeg": ("L_Knee", "LeftUpperLeg", "L_Ankle", DOWN),
    "LeftFoot": ("L_Ankle", "LeftLowerLeg", None, None),
    "RightUpperLeg": ("R_Hip", "LowerTorso", "R_Knee", DOWN),
    "RightLowerLeg": ("R_Knee", "RightUpperLeg", "R_Ankle", DOWN),
    "RightFoot": ("R_Ankle", "RightLowerLeg", None, None),
}
# Blender world (Z up, the clip faces -Y, its left is +X) -> Roblox character space (Y up, faces -Z, right is +X).
M = Matrix(((-1, 0, 0), (0, 0, 1), (0, 1, 0)))


def world_rest(name):
    return (arm.matrix_world @ arm.data.bones[name].matrix_local).to_3x3().normalized()


def world_head_rest(name):
    return arm.matrix_world @ arm.data.bones[name].head_local


# The turn that takes each R15 rest part to the matching SMPL rest bone (limbs only).
fix = {}
for part, (bone, _, toward, rest_dir) in PARTS.items():
    if toward:
        smpl_dir = (world_head_rest(toward) - world_head_rest(bone)).normalized()
        fix[part] = rest_dir.rotation_difference(smpl_dir).to_matrix()
    else:
        fix[part] = Matrix.Identity(3)

scene.frame_set(first)
hip_start = arm.matrix_world @ arm.pose.bones["Pelvis"].head
smpl_leg = (world_head_rest("L_Hip") - world_head_rest("L_Ankle")).length
STUDS_PER_UNIT = 2.0 / smpl_leg  # an R15 leg (hip to ankle) is about 2 studs at scale 1

frames = []
for f in range(first, last + 1, step):
    scene.frame_set(f)
    turn = {}
    for part, (bone, *_rest) in PARTS.items():
        now = (arm.matrix_world @ arm.pose.bones[bone].matrix).to_3x3().normalized()
        world = now @ world_rest(bone).inverted() @ fix[part]  # R15 rest -> now, in Blender world
        turn[part] = M @ world @ M.transposed()                  # same turn in Roblox space
    poses = {}
    for part, (bone, parent, *_rest) in PARTS.items():
        local = turn[part] if parent is None else turn[parent].transposed() @ turn[part]
        q = local.to_quaternion()
        pos = Vector((0, 0, 0))
        if parent is None:
            pos = M @ ((arm.matrix_world @ arm.pose.bones["Pelvis"].head) - hip_start) * STUDS_PER_UNIT
            pos.x = pos.z = 0
        poses[part] = [round(v, 4) for v in (pos.x, pos.y, pos.z, q.x, q.y, q.z, q.w)]
    frames.append({"t": round((f - first) / scene.render.fps, 4), "poses": poses})

out = src[:-4] + ".r15.json"
with open(out, "w") as fh:
    json.dump({"fps": scene.render.fps / step, "frames": frames}, fh, separators=(",", ":"))
print("WROTE", out, len(frames), "keyframes")
