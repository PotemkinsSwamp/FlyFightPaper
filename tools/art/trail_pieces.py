"""The trail pieces as 3D models: each about 1 stud across and one plain shape (the game gives the colour and the foil
or glow). trail_preview.py builds its videos from these. Run alone to write the ones the game uploads, with their
safety sheet:
    blender -b --factory-startup --python tools/art/trail_pieces.py
        -> assets/models/trails/<piece>.fbx and .planning/skins/trails/safety-sheet.png (look at it before any upload)
Only the star and the bolt are uploaded: the game draws flakes as plain thin blocks, and smoke and sparkle dust with
Roblox's own particle pictures."""
import math, random, sys
from pathlib import Path
import bpy, bmesh
from mathutils import Vector, noise

ROOT = Path(__file__).resolve().parents[2]
UPLOADED = ("star", "bolt")

def mesh(name, smooth_shade=None):
    build, smooth_default = MODELS[name]
    bm = bmesh.new(); build(bm); bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    for f in me.polygons: f.use_smooth = smooth_default if smooth_shade is None else smooth_shade
    return me
def star(bm):                                                                # a folded foil star: ten ridges up to a point each side
    ring = [bm.verts.new((r * math.sin(i * math.pi / 5), r * math.cos(i * math.pi / 5), 0)) for i, r in enumerate([0.5, 0.2] * 5)]
    for z in (0.15, -0.15):
        top = bm.verts.new((0, 0, z))
        for i in range(10): bm.faces.new((top, ring[i], ring[(i + 1) % 10]))
def flake(bm):                                                               # a thin diamond of foil
    pts = [bm.verts.new(p) for p in ((0.5, 0, 0), (0, 0.3, 0), (-0.5, 0, 0), (0, -0.3, 0), (0, 0, 0.035), (0, 0, -0.035))]
    for z in (4, 5):
        for i in range(4): bm.faces.new((pts[z], pts[i], pts[(i + 1) % 4]))
def puff(bm):                                                                # a lumpy cotton ball
    bmesh.ops.create_icosphere(bm, subdivisions=2, radius=0.5)
    for v in bm.verts: v.co *= 1 + 0.22 * noise.noise(v.co * 2.3)
def bolt(bm):                                                                # a small jagged lightning fork, thick to thin
    r2 = random.Random(3); pts = [Vector((-0.5 + i / 6, r2.uniform(-0.13, 0.13) if 0 < i < 6 else 0, r2.uniform(-0.06, 0.06))) for i in range(7)]
    def limb(line, w0):
        rings = []
        for i, p in enumerate(line):
            w = w0 * (1 - 0.8 * i / (len(line) - 1))
            rings.append([bm.verts.new(p + Vector((0, a * w, b * w))) for a, b in ((1, 1), (-1, 1), (-1, -1), (1, -1))])
        for a, b in zip(rings, rings[1:]):
            for i in range(4): bm.faces.new((a[i], a[(i + 1) % 4], b[(i + 1) % 4], b[i]))
        bm.faces.new(rings[0]); bm.faces.new(rings[-1])
    limb(pts, 0.05); limb([pts[3], pts[3] + Vector((0.14, 0.2, 0.05)), pts[3] + Vector((0.3, 0.28, -0.04))], 0.032)
def shard(bm):                                                              # a long foil crystal
    pts = [bm.verts.new(q) for q in ((0.5, 0, 0), (-0.5, 0, 0), (0, 0.17, 0.1), (0, -0.17, 0.1), (0, 0, -0.19))]
    for a, b in ((2, 3), (3, 4), (4, 2)): bm.faces.new((pts[0], pts[a], pts[b])); bm.faces.new((pts[1], pts[b], pts[a]))
def spark(bm):                                                              # a tiny six-point glint
    for axis in range(3):
        for sign in (1, -1):
            a, b = (axis + 1) % 3, (axis + 2) % 3; base = []
            for da, db in ((1, 0), (0, 1), (-1, 0), (0, -1)):
                q = [0, 0, 0]; q[a], q[b] = 0.06 * da, 0.06 * db; base.append(bm.verts.new(q))
            tip = [0, 0, 0]; tip[axis] = 0.5 * sign; top = bm.verts.new(tip)
            for i in range(4): bm.faces.new((top, base[i], base[(i + 1) % 4]))
def soft(bm):                                                               # a card that always faces the camera: soft smoke
    bm.faces.new([bm.verts.new(q) for q in ((-0.5, -0.5, 0), (0.5, -0.5, 0), (0.5, 0.5, 0), (-0.5, 0.5, 0))])
MODELS = {"star": (star, False), "flake": (flake, False), "puff": (puff, True), "bolt": (bolt, False), "shard": (shard, False), "spark": (spark, False), "soft": (soft, False)}

if __name__ == "__main__":
    sc = bpy.context.scene
    for o in list(bpy.data.objects): bpy.data.objects.remove(o)
    out = ROOT / "assets/models/trails"; out.mkdir(parents=True, exist_ok=True)
    grey = bpy.data.materials.new("grey"); grey.diffuse_color = (0.55, 0.57, 0.62, 1)
    views = (("flat side", (0, 0, 0)), ("edge on", (math.pi / 2, 0, 0)), ("end on", (0, math.pi / 2, 0)), ("turned", (0.95, 0.3, 0.6)), ("turned back", (-2.2, 0.5, 2.0)))
    def label(text, x, y, size=0.11):
        cu = bpy.data.curves.new("t", "FONT"); cu.body, cu.size, cu.align_x = text, size, "CENTER"
        ob = bpy.data.objects.new("t", cu); ob.location = (x, y, 0); sc.collection.objects.link(ob)
        ink = bpy.data.materials.get("ink") or bpy.data.materials.new("ink"); ink.diffuse_color = (0.05, 0.05, 0.08, 1); cu.materials.append(ink)
    for row, name in enumerate(UPLOADED):
        me = mesh(name); me.materials.append(grey)
        one = bpy.data.objects.new(name, me); sc.collection.objects.link(one)           # the upload: this one model, nothing else
        for o in bpy.data.objects: o.select_set(o is one)
        bpy.ops.export_scene.fbx(filepath=str(out / (name + ".fbx")), use_selection=True, object_types={"MESH"}, mesh_smooth_type="FACE")
        one.location = (0, -1.6 * row, 0); label("%s: %d triangles" % (name, sum(len(p.vertices) - 2 for p in me.polygons)), 0, -1.6 * row - 0.78)
        for col, (word, turn) in enumerate(views[1:], 1):
            ob = bpy.data.objects.new(name, me); ob.location = (1.5 * col, -1.6 * row, 0); ob.rotation_euler = turn; sc.collection.objects.link(ob)
            label(word, 1.5 * col, -1.6 * row - 0.78)
    label("Trail pieces to upload (plain shapes, no pictures on them)", 3.0, 0.85, 0.16)
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); cam.data.type, cam.data.ortho_scale, cam.location = "ORTHO", 8.2, (3.0, -0.75, 10)
    sc.collection.objects.link(cam); sc.camera = cam
    sc.render.engine = "BLENDER_WORKBENCH"; sh = sc.display.shading; sh.light, sh.color_type, sh.show_object_outline, sh.show_cavity, sh.show_shadows = "STUDIO", "MATERIAL", True, True, False
    sc.world = bpy.data.worlds.new("w"); sc.world.color = (1, 1, 1); sc.render.film_transparent = False; sc.view_settings.view_transform = "Standard"
    sc.render.resolution_x, sc.render.resolution_y = 1640, 760; sc.render.filepath = str(ROOT / ".planning/skins/trails/safety-sheet.png")
    bpy.ops.render.render(write_still=True); print("DONE", ", ".join(UPLOADED))
