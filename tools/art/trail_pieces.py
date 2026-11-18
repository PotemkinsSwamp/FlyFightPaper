"""The trail pieces as 3D models: each about 1 stud across and one plain shape (the game gives the colour and the foil
or glow). trail_preview.py builds its videos from these. Run alone to write the ones the game uploads, with their
safety sheet:
    blender -b --factory-startup --python tools/art/trail_pieces.py
        -> assets/models/trails/<piece>.fbx and .planning/skins/trails/safety-sheet.png (look at it before any upload)
Name pieces after `--` to write only those (new ones waiting for upload). Only UPLOADED pieces are ever uploaded: the game
makes the plain shapes itself, and draws smoke, sparkle dust and flat squares with Roblox's own particle pictures."""
import math, random, sys
import json
from pathlib import Path
import bpy, bmesh
from mathutils import Vector, noise

ROOT = Path(__file__).resolve().parents[2]
UPLOADED = ("star", "bolt", "curl", "note", "notes", "petal", "dart", "jog")   # dart: Alan picked Mini Paper Planes; its upload waits for his OK on the safety sheet

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
def box(bm, lo, hi, lean=0.0):                                               # a block; lean tips its far end up or down
    v = [bm.verts.new((x, y + lean * (x - lo[0]), z)) for x in (lo[0], hi[0]) for y in (lo[1], hi[1]) for z in (lo[2], hi[2])]
    for f in ((0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)): bm.faces.new([v[i] for i in f])
def blob(bm, at, radii, tilt=0.0):                                           # a squashed ball, turned in its own flat
    c, sn = math.cos(tilt), math.sin(tilt)
    for v in bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0)["verts"]:
        x, y, z = v.co.x * radii[0], v.co.y * radii[1], v.co.z * radii[2]; v.co = (x * c - y * sn + at[0], x * sn + y * c + at[1], z + at[2])
def heart(bm):                                                              # a folded paper heart: facets up to a point each side
    ts = [i * math.tau / 20 for i in range(20)]
    ring = [bm.verts.new((16 * math.sin(t) ** 3 / 32, (13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)) / 32 + 0.08, 0)) for t in ts]
    for z in (0.14, -0.14):
        top = bm.verts.new((0, 0.02, z))
        for i in range(20): bm.faces.new((top, ring[i], ring[(i + 1) % 20]))
def note(bm):                                                               # a single music note: head, stem, flag
    blob(bm, (-0.1, -0.36, 0), (0.2, 0.14, 0.11), 0.45); box(bm, (0.055, -0.36, -0.03), (0.105, 0.47, 0.03)); box(bm, (0.105, 0.30, -0.02), (0.36, 0.47, 0.02), -0.9)
def notes(bm):                                                              # two notes joined by a beam
    blob(bm, (-0.33, -0.36, 0), (0.2, 0.14, 0.11), 0.45); blob(bm, (0.27, -0.26, 0), (0.2, 0.14, 0.11), 0.45)
    box(bm, (-0.175, -0.36, -0.03), (-0.125, 0.40, 0.03)); box(bm, (0.425, -0.26, -0.03), (0.475, 0.50, 0.03)); box(bm, (-0.175, 0.30, -0.03), (0.475, 0.42, 0.03), 0.16)
def petal(bm):                                                              # a folded paper petal: a leaf creased down its middle, a little curled
    xs, ws = (-0.5, -0.25, 0.05, 0.3, 0.45, 0.5), (0, 0.11, 0.21, 0.24, 0.15, 0)   # a teardrop: narrow stem end, wide round tip
    mid = [bm.verts.new((x, 0, 0.3 * x * x)) for x in xs]
    for side in (1, -1):
        edge = [mid[i] if w == 0 else bm.verts.new((x, side * w, 0.3 * x * x + 0.42 * w)) for i, (x, w) in enumerate(zip(xs, ws))]
        for i in range(len(xs) - 1): bm.faces.new(list(dict.fromkeys((mid[i], mid[i + 1], edge[i + 1], edge[i]))))
    bmesh.ops.solidify(bm, geom=bm.faces[:], thickness=0.025)
def curl(bm):                                                               # a curled paper streamer
    rows = []
    for j in range(13):
        u = j / 12; a = u * 1.7 * math.pi; c = Vector((0.34 * math.cos(a), (u - 0.5) * 0.5, 0.34 * math.sin(a)))
        rows.append((bm.verts.new(c + Vector((0, 0.11, 0))), bm.verts.new(c - Vector((0, 0.11, 0)))))
    for a, b in zip(rows, rows[1:]): bm.faces.new((a[0], b[0], b[1], a[1]))
    bmesh.ops.solidify(bm, geom=bm.faces[:], thickness=0.02)
def block(x, y, z):                                                         # plain blocks: the game draws these itself, no upload
    def build(bm):
        for v in bmesh.ops.create_cube(bm, size=1.0)["verts"]: v.co = (v.co.x * x, v.co.y * y, v.co.z * z)
    return build
def ball(bm): bmesh.ops.create_icosphere(bm, subdivisions=3, radius=0.5)
def droplet(bm):
    for vertex in bmesh.ops.create_icosphere(bm, subdivisions=2, radius=0.5)["verts"]:
        x, y, z = vertex.co
        width = 0.61 + 0.52 * x
        vertex.co = (x, y * width, z * width + 0.14 * max(0, -x))
def jog(bm):                                                                # a circuit-board trace: straight, a 45-degree step sideways, straight, a pad at each end
    box(bm, (-0.5, -0.115, -0.015), (-0.12, -0.085, 0.015)); box(bm, (-0.12, -0.115, -0.015), (0.12, -0.085, 0.015), 0.2 / 0.24); box(bm, (0.12, 0.085, -0.015), (0.5, 0.115, 0.015))
    box(bm, (-0.33, -0.085, -0.015), (-0.30, 0.07, 0.015))                    # a short branch to a third pad: reads as a circuit, never as a bare zigzag
    for x, y in ((-0.5, -0.1), (0.5, 0.1), (-0.315, 0.1)): box(bm, (x - 0.045, y - 0.045, -0.02), (x + 0.045, y + 0.045, 0.02))
def dart(bm):                                                               # a tiny folded paper plane, nose along +x
    nose, back = bm.verts.new((0.5, 0, 0)), bm.verts.new((-0.5, 0, 0)); bm.faces.new((nose, bm.verts.new((-0.5, 0, -0.17)), back))   # the keel you hold
    for side in (1, -1): bm.faces.new((nose, bm.verts.new((-0.5, side * 0.05, 0.0)), bm.verts.new((-0.5, side * 0.37, 0.04))))       # a wing each side
    bmesh.ops.solidify(bm, geom=bm.faces[:], thickness=0.02)
def ninja_star(bm):
    """Four-point cartoon emblem with a punched centre and a contrasting silver border."""
    def ring(radii, z):
        return [bm.verts.new((r * math.cos(i * math.tau / 8),
                              r * math.sin(i * math.tau / 8), z)) for i, r in enumerate(radii)]
    outlines = []
    for sign in (1, -1):
        hole = ring([0.076] * 8, sign * 0.037)
        inset = ring([0.39, 0.15] * 4, sign * 0.037)
        rim = ring([0.50, 0.19] * 4, sign * 0.021)
        for i in range(8):
            j = (i + 1) % 8
            bm.faces.new((hole[i], hole[j], inset[j], inset[i]))
            bm.faces.new((inset[i], inset[j], rim[j], rim[i])).material_index = 1
        outlines.append((hole, rim))
    for top, bottom in zip(*outlines):
        for i in range(8):
            j = (i + 1) % 8
            bm.faces.new((top[i], top[j], bottom[j], bottom[i])).material_index = 1

def racing_flag(bm):
    """One curled sheet. Each face is a whole check, readable on either side."""
    rows = []
    for j in range(4):
        row = []
        for i in range(5):
            u, v = i / 4, j / 3
            row.append(bm.verts.new((-0.40 + u * 0.91, -0.12 + v * 0.56 + 0.06 * u,
                                     u * 0.14 * math.sin(u * math.tau + v * 0.65))))
        rows.append(row)
    for j in range(3):
        for i in range(4):
            bm.faces.new((rows[j][i], rows[j][i + 1], rows[j + 1][i + 1],
                          rows[j + 1][i])).material_index = (i + j) % 2
    box(bm, (-0.45, -0.52, -0.026), (-0.40, 0.46, 0.026))

def flame_tongue(bm):
    """A curved lick of fire, with the narrow end pointing away from the nozzle."""
    rings = []
    for x, radius, curl in ((-0.50, 0.012, 0.14), (-0.27, 0.10, 0.04),
                            (-0.05, 0.17, -0.04), (0.21, 0.20, 0), (0.48, 0.06, 0.01)):
        rings.append([bm.verts.new((x, radius * math.cos(i * math.tau / 7),
                                    curl + radius * math.sin(i * math.tau / 7))) for i in range(7)])
    for left, right in zip(rings, rings[1:]):
        for i in range(7):
            j = (i + 1) % 7
            bm.faces.new((left[i], left[j], right[j], right[i]))
    bm.faces.new(rings[0])
    bm.faces.new(rings[-1])

def butterfly(bm):                                                          # a folded paper butterfly, wings up in a V, head along +x
    wing = ((0.12, 0.02), (0.38, 0.30), (0.30, 0.48), (0.05, 0.36), (-0.08, 0.42), (-0.30, 0.34), (-0.34, 0.14), (-0.12, 0.02))
    for side in (1, -1): bm.faces.new([bm.verts.new((x, side * y, 0.7 * y)) for x, y in wing])
    bmesh.ops.solidify(bm, geom=bm.faces[:], thickness=0.02); box(bm, (-0.25, -0.025, -0.03), (0.28, 0.025, 0.03))
MODELS = {"jog": (jog, False), "dart": (dart, False), "butterfly": (butterfly, False), "trace": (block(1, 0.02, 0.02), False), "board": (block(1, 0.55, 0.03), False), "chip": (block(1, 0.6, 0.22), False),
          "heart": (heart, False), "note": (note, False), "notes": (notes, False), "petal": (petal, False), "curl": (curl, False), "ball": (ball, True),
          "cube": (block(1, 1, 1), False), "bar": (block(1, 0.045, 0.045), False), "strip": (block(1, 0.36, 0.02), False), "square": (soft, False),
          "star": (star, False), "flake": (flake, False), "puff": (puff, True), "bolt": (bolt, False), "shard": (shard, False), "spark": (spark, False), "soft": (soft, False)}

MODELS.update(ninja_star=(ninja_star, False), racing_flag=(racing_flag, False), droplet=(droplet, True),
              flame_tongue=(flame_tongue, True))

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
    names = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else list(UPLOADED)
    legendary = names == ["legendary"]
    if legendary:
        drafts = json.loads((ROOT / "tools/art/trail_drafts.json").read_text(encoding="utf-8"))
        names = ["ninja_star", "droplet", "flame_tongue", "racing_flag"]
        styles = {p["model"]: p for trail in drafts["trails"].values() if "preview_skin" in trail
                  for p in trail["pieces"] if p["model"] in names}
    else:
        assert all(n in UPLOADED for n in names), "unknown trail piece"
    for row, name in enumerate(names):
        me = mesh(name)
        if legendary:
            # One mesh and one material. Preserve the checks and star border as corner colours.
            style = styles[name]
            paint = me.color_attributes.new(name="Color", type="BYTE_COLOR", domain="CORNER")
            for face in me.polygons:
                rgb = style["accent"] if face.material_index else style["colors"][0]
                # Water and flame take their changing colour from the trail at runtime.
                if "accent" not in style:
                    rgb = (255, 255, 255)
                for loop in face.loop_indices:
                    paint.data[loop].color_srgb = (*[c / 255 for c in rgb], 1)
                face.material_index = 0
        me.materials.append(grey)
        one = bpy.data.objects.new(name, me); sc.collection.objects.link(one)           # the upload: this one model, nothing else
        for o in bpy.data.objects: o.select_set(o is one)
        bpy.ops.export_scene.fbx(filepath=str(out / (name + ".fbx")), use_selection=True, object_types={"MESH"}, mesh_smooth_type="FACE")
        one.location = (0, -1.6 * row, 0); label("%s: %d triangles" % (name, sum(len(p.vertices) - 2 for p in me.polygons)), 0, -1.6 * row - 0.78)
        for col, (word, turn) in enumerate(views[1:], 1):
            ob = bpy.data.objects.new(name, me); ob.location = (1.5 * col, -1.6 * row, 0); ob.rotation_euler = turn; sc.collection.objects.link(ob)
            label(word, 1.5 * col, -1.6 * row - 0.78)
    label("Legendary trail pieces" if legendary else "Trail pieces to upload (plain shapes, no pictures on them)", 3.0, 0.85, 0.16)
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); cam.data.type, cam.data.ortho_scale, cam.location = "ORTHO", 8.2, (3.0, 0.85 - 0.8 * len(names), 10); cam.data.sensor_fit = "HORIZONTAL"
    sc.collection.objects.link(cam); sc.camera = cam
    sc.render.engine = "BLENDER_WORKBENCH"; sh = sc.display.shading; sh.light, sh.color_type, sh.show_object_outline, sh.show_cavity, sh.show_shadows = "STUDIO", "MATERIAL", True, True, False
    sc.world = bpy.data.worlds.new("w"); sc.world.color = (1, 1, 1); sc.render.film_transparent = False; sc.view_settings.view_transform = "Standard"
    if legendary:
        sh.color_type = "VERTEX"
    sheet = "legendary-pieces.png" if legendary else "safety-sheet.png"
    sc.render.resolution_x, sc.render.resolution_y = 1640, int(200 * (1.6 * len(names) + 0.6)); sc.render.filepath = str(ROOT / ".planning/skins/trails" / sheet)
    bpy.ops.render.render(write_still=True); print("DONE", ", ".join(names))
