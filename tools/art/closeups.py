"""Close-up sheet of a baked hero building, to catch Meshy's melted bits before upload (Alan, 2026-10-10).
Blender -b FOLDER/hero.blend --python tools/art/closeups.py -- FOLDER   ->  FOLDER/renders/closeups.jpg
Six perspective views a plane would see at ~1/3 building height away (four corners low and high), plus two looking
down at the roof, where planes see gaps the side views miss."""
import sys, math
from pathlib import Path
import bpy
from mathutils import Vector

folder = Path(sys.argv[sys.argv.index("--") + 1]).resolve()
scene = bpy.context.scene
meshes = [o for o in scene.objects if o.type == "MESH" and not o.hide_render]
corners = [o.matrix_world @ Vector(c) for o in meshes for c in o.bound_box]
top = max(c.z for c in corners)
reach = max(Vector((c.x, c.y)).length for c in corners)   # wide, low buildings need the camera outside their walls
scene.render.engine = "BLENDER_EEVEE"
scene.render.resolution_x, scene.render.resolution_y = 800, 800
scene.render.image_settings.file_format = "PNG"
camera = bpy.data.objects.new("Close-up camera", bpy.data.cameras.new("Close-up camera"))
scene.collection.objects.link(camera)
scene.camera = camera
camera.data.lens = 35
camera.data.clip_end = top * 20
shots = []
for k, (angle, level, rise) in enumerate([(-60, .25, .15), (-120, .25, .15), (-60, .7, .15), (-120, .7, .15),
                                          (60, .45, .15), (120, .45, .15), (-45, .85, 3), (135, .85, 3)]):
    target = Vector((0, 0, top * level))
    t = math.radians(angle)
    camera.location = target + Vector((math.cos(t), math.sin(t), rise)).normalized() * ((reach + top * .35) if rise < 1 else reach * 2.6)
    camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()
    path = folder / "renders" / f"closeup-{k}.png"
    scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)
    shots.append(path)
sheet = bpy.data.images.new("sheet", 3200, 1600)
import numpy as np
pixels = np.zeros((1600, 3200, 4), np.float32)
for k, path in enumerate(shots):
    img = bpy.data.images.load(str(path))
    p = np.array(img.pixels[:], np.float32).reshape(800, 800, 4)
    row, col = 1 - k // 4, k % 4
    pixels[row * 800:(row + 1) * 800, col * 800:(col + 1) * 800] = p
    path.unlink()
sheet.pixels = pixels.ravel()
sheet.filepath_raw = str(folder / "renders" / "closeups.png")
sheet.file_format = "PNG"
sheet.save()
