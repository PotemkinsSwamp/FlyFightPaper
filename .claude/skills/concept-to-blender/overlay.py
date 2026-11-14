"""Lay a Blender model over its concept picture: same camera reading, same scale, one anchor spot pinned to its pixel.
Writes OUT-overlay.png (model see-through on the concept) and OUT-model.png (model alone, same framing). Fast (EEVEE).

    D:/Blender/blender.exe -b FILE.blend --python .claude/skills/concept-to-blender/overlay.py -- \
        --object NAME --concept PICTURE.png --anchor-world X Y Z --anchor-px PX PY --px-per-unit N \
        --yaw 47 --pitch 25 --facing left --out OUT

The model must point along Blender +Y with +Z up. yaw, pitch, facing: the same camera reading as measure.py.
anchor-world: a spot on the model (Blender units); anchor-px: where that spot is in the concept; px-per-unit: concept
pixels per Blender unit (from the measured reference length).
"""
import bpy, sys, os, math, argparse
import numpy as np
from mathutils import Vector

ap = argparse.ArgumentParser()
ap.add_argument("--object", required=True); ap.add_argument("--concept", required=True); ap.add_argument("--out", required=True)
ap.add_argument("--anchor-world", nargs=3, type=float, required=True); ap.add_argument("--anchor-px", nargs=2, type=float, required=True)
ap.add_argument("--px-per-unit", type=float, required=True); ap.add_argument("--yaw", type=float, required=True)
ap.add_argument("--pitch", type=float, required=True); ap.add_argument("--facing", default="left")
a = ap.parse_args(sys.argv[sys.argv.index("--") + 1:]); a.concept, a.out = os.path.abspath(a.concept), os.path.abspath(a.out)

scene = bpy.context.scene
for o in bpy.data.objects: o.hide_render = o.name != a.object
concept = bpy.data.images.load(a.concept); W, H = concept.size
yaw, pitch = math.radians(a.yaw), math.radians(a.pitch); side = -1 if a.facing == "left" else 1
d = Vector((side * math.cos(yaw) * math.cos(pitch), math.sin(yaw) * math.cos(pitch), math.sin(pitch)))   # model -> camera
right = (-d).cross(Vector((0, 0, 1))).normalized(); up = right.cross(-d)
target = Vector(a.anchor_world) + right * ((W / 2 - a.anchor_px[0]) / a.px_per_unit) + up * ((a.anchor_px[1] - H / 2) / a.px_per_unit)

world = bpy.data.worlds.new("OverlaySky"); scene.world = world; world.use_nodes = True
world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.36, 0.55, 0.85, 1)
sun = bpy.data.objects.new("OverlaySun", bpy.data.lights.new("OverlaySun", "SUN")); scene.collection.objects.link(sun)
sun.data.energy = 3.5; sun.rotation_euler = (math.radians(50), math.radians(-10), math.radians(215))
cam = bpy.data.objects.new("OverlayCam", bpy.data.cameras.new("OverlayCam")); scene.collection.objects.link(cam); scene.camera = cam
cam.data.type = "ORTHO"; cam.data.ortho_scale = W / a.px_per_unit; cam.data.clip_end = 1000
cam.location = target + d * 200; cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
scene.render.engine = "BLENDER_EEVEE" if "BLENDER_EEVEE" in {e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items} else "BLENDER_EEVEE_NEXT"
scene.view_settings.view_transform = "Standard"; scene.render.film_transparent = True
scene.render.resolution_x, scene.render.resolution_y, scene.render.resolution_percentage = W, H, 100
scene.render.filepath = a.out + "-model.png"; bpy.ops.render.render(write_still=True)

model = bpy.data.images.load(a.out + "-model.png")
m = np.array(model.pixels[:]).reshape(H, W, 4); c = np.array(concept.pixels[:]).reshape(H, W, -1)[..., :3]
mix = np.ones((H, W, 4)); alpha = m[..., 3:4] * 0.55; mix[..., :3] = c * (1 - alpha) + m[..., :3] * alpha
out = bpy.data.images.new("Overlay", W, H); out.pixels.foreach_set(mix.astype(np.float32).ravel())
out.filepath_raw = a.out + "-overlay.png"; out.file_format = "PNG"; out.save()
print("OVERLAY DONE", a.out + "-overlay.png")
