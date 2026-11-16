"""A trail as a 3D video, before any upload:
    blender -b --factory-startup --python tools/art/trail_preview.py -- <id> [frame ...]
        -> .planning/skins/trails/<id>.mp4, or <id>-f<frame>.png stills when frames are given
Plays config/trails.json in a 3D scene: the real starter plane (plane_assembly.py) flies a weaving path over a floor
with boxes, at its normal speed, then boosting. First shot: the game's own chase camera (24 studs behind, 6 above,
70 degrees). Second shot: from another plane flying alongside. Pieces are 3D models built here (star, flake, puff, bolt),
scattered at random sizes round the path and tumbling; a ribbon is a real strip that turns as it is laid.
It imitates the game's drawing; the real look is confirmed in Studio after upload."""
import sys, os, json, math, random, subprocess, tempfile, shutil, bpy, bmesh
import numpy as np
from mathutils import Vector, Matrix, Quaternion, noise
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__))); import plane_assembly as pa

ARGS = sys.argv[sys.argv.index("--") + 1:]; TRAIL = ARGS[0]; STILLS = [int(a) for a in ARGS[1:]]
CFG = json.load(open(pa.ROOT / "config/trails.json")); SPEC = CFG["trails"][TRAIL]; LIFE = CFG["life"]
OUT = pa.ROOT / ".planning/skins/trails"; FPS, SECONDS, SUB, NORMAL, BOOST, CUT = 24, 8.0, 4, 105.0, 150.0, 4.4
rng = random.Random(7)

def smooth(x): x = min(max(x, 0.0), 1.0); return x * x * (3 - 2 * x)
def speed(t): return NORMAL + (BOOST - NORMAL) * (smooth((t - 1.8) / 0.5) - smooth((t - 3.4) / 0.6) + smooth((t - 5.9) / 0.5) - smooth((t - 7.2) / 0.6))
def growth(v): return 1 + (CFG["fast_growth"] - 1) * min(max((v / NORMAL - 1) / (CFG["fast_at"] - 1), 0), 1)
def path(s): return Vector((16 * math.sin(s / 75), s, 46 + 6 * math.sin(s / 105 + 1)))
def frame_at(s, v):
    """The plane's place and its right, nose and up directions at distance s along the path, banked into its turn."""
    p, nose = path(s), (path(s + 1) - path(s - 1)).normalized()
    side = (path(s + 6) - 2 * p + path(s - 6)) / 36                          # how hard the path bends, a stud
    right = nose.cross(Vector((0, 0, 1))).normalized(); bank = math.atan(side.dot(right) * v * v / 196.2) * 2.2
    q = Quaternion(nose, bank); right = q @ right
    return p, right, nose, right.cross(nose).normalized()
def lin(c): return tuple(((x / 255 + 0.055) / 1.055) ** 2.4 if x > 10 else x / 255 / 12.92 for x in c) + (1.0,)

# ---- the 3D pieces: each about 1 stud across, sized by the trail ----------------------------------------------------
def mesh(name, build, smooth_shade=False):
    bm = bmesh.new(); build(bm); bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    for f in me.polygons: f.use_smooth = smooth_shade
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
MODELS = {"star": (star, False), "flake": (flake, False), "puff": (puff, True), "bolt": (bolt, False)}

def look(kind):
    """A material that takes each piece's own colour: crinkled foil, matte cotton or a light."""
    m = bpy.data.materials.new(kind); m.use_nodes = True; nt = m.node_tree; b = nt.nodes["Principled BSDF"]; own = nt.nodes.new("ShaderNodeObjectInfo")
    nt.links.new(own.outputs["Color"], b.inputs["Base Color"]); nt.links.new(own.outputs["Color"], b.inputs["Emission Color"])
    if kind == "foil":
        b.inputs["Metallic"].default_value, b.inputs["Roughness"].default_value, b.inputs["Emission Strength"].default_value = 0.4, 0.32, 0.1
        n, bump = nt.nodes.new("ShaderNodeTexNoise"), nt.nodes.new("ShaderNodeBump"); n.inputs["Scale"].default_value = 7; n.inputs["Detail"].default_value = 6; bump.inputs["Strength"].default_value = 0.7
        nt.links.new(n.outputs["Fac"], bump.inputs["Height"]); nt.links.new(bump.outputs["Normal"], b.inputs["Normal"])
    elif kind == "glow": b.inputs["Emission Strength"].default_value = 9
    else:                                                                    # cotton: soft, a little fluffy
        b.inputs["Roughness"].default_value, b.inputs["Emission Strength"].default_value = 1.0, 0.05
        n, bump = nt.nodes.new("ShaderNodeTexNoise"), nt.nodes.new("ShaderNodeBump"); n.inputs["Scale"].default_value = 5; n.inputs["Detail"].default_value = 8; bump.inputs["Strength"].default_value = 0.5
        nt.links.new(n.outputs["Fac"], bump.inputs["Height"]); nt.links.new(bump.outputs["Normal"], b.inputs["Normal"])
    return m

# ---- the scene -----------------------------------------------------------------------------------------------------
sc = bpy.context.scene
for o in list(bpy.data.objects): bpy.data.objects.remove(o)
def to_bl(p): return Vector((p[0], -p[2], p[1]))                              # Roblox (x right, y up, nose -z) -> Blender (nose +y)
def paper(name):
    m = bpy.data.materials.new(name); m.use_nodes = True; b = m.node_tree.nodes["Principled BSDF"]; b.inputs["Roughness"].default_value = 0.8
    img = pa.PLANES / "paper-set" / (name + "-color.png")
    if img.exists():
        t = m.node_tree.nodes.new("ShaderNodeTexImage"); t.image = bpy.data.images.load(str(img)); m.node_tree.links.new(t.outputs["Color"], b.inputs["Base Color"])
    else:                                                                    # the starter's plain pieces: cream paper, a blue accent
        b.inputs["Base Color"].default_value = lin(next((c for word, c in (("accent", (70, 128, 214)), ("cardboard", (196, 160, 110)), ("elastic", (60, 60, 70))) if word in name), (238, 226, 205)))
    return m
rig = bpy.data.objects.new("plane", None); sc.collection.objects.link(rig); pts = []
for piece in pa.assemble(dict(body="body_standard", nose="nose_0", wings="wings_0", tail="tail_0", weapon_mounts=[], utility="boost_twin")):
    if not piece["fbx"] or not os.path.exists(piece["fbx"]) or "sticker" in piece["name"]: continue
    before = set(bpy.data.objects); bpy.ops.import_scene.fbx(filepath=piece["fbx"])
    new = [o for o in bpy.data.objects if o not in before]; meshes = [o for o in new if o.type == "MESH"]
    for o in bpy.data.objects: o.select_set(o in meshes)
    bpy.context.view_layer.objects.active = meshes[0]; bpy.ops.object.parent_clear(type="CLEAR_KEEP_TRANSFORM")
    for o in new:
        if o.type != "MESH": bpy.data.objects.remove(o)
    if len(meshes) > 1: bpy.ops.object.join()
    ob = bpy.context.view_layer.objects.active; bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    raw = np.array([(v.co.x, v.co.z, -v.co.y) for v in ob.data.vertices]); lo, hi = raw.min(0), raw.max(0)
    world = np.array(piece["centre"]) + (raw - (lo + hi) / 2) * np.array(piece["size"]) / np.maximum(hi - lo, 1e-6)
    for v, w in zip(ob.data.vertices, world): v.co = to_bl(w)
    ob.data.materials.clear(); ob.data.materials.append(paper(piece["name"])); ob.parent = rig
    if piece["slot"] in ("body", "nose", "wings", "tail"): pts.append(world)
P = np.concatenate(pts); MID = to_bl((P.min(0) + P.max(0)) / 2); LENGTH = P[:, 2].max() - P[:, 2].min()
for ob in rig.children: ob.location = -MID                                    # the rig's origin is the plane's middle
TAIL = Vector((0, -LENGTH / 2, 0))

def flat(color, rough=0.9):
    m = bpy.data.materials.new("flat"); m.use_nodes = True; b = m.node_tree.nodes["Principled BSDF"]; b.inputs["Base Color"].default_value = lin(color); b.inputs["Roughness"].default_value = rough; return m
bpy.ops.mesh.primitive_plane_add(size=6000, location=(0, 1500, 0)); floor = bpy.context.object; fm = flat((150, 160, 150)); floor.data.materials.append(fm)
ck = fm.node_tree.nodes.new("ShaderNodeTexChecker"); ck.inputs["Scale"].default_value = 150; ck.inputs["Color1"].default_value = lin((132, 150, 140)); ck.inputs["Color2"].default_value = lin((164, 176, 162))
fm.node_tree.links.new(ck.outputs["Color"], fm.node_tree.nodes["Principled BSDF"].inputs["Base Color"])
r3 = random.Random(11)
for i in range(46):                                                           # boxes each side of the path: something for the trail to pass
    w, d, h = r3.uniform(18, 42), r3.uniform(18, 42), r3.uniform(14, 62); side = 1 if i % 2 else -1
    bpy.ops.mesh.primitive_cube_add(size=1, location=(side * r3.uniform(46, 150), i * 34 - 200 + r3.uniform(-10, 10), h / 2))
    box = bpy.context.object; box.scale = (w, d, h)
    box.data.materials.append(flat(r3.choice([(214, 178, 128), (226, 196, 150), (70, 128, 214), (214, 78, 72), (240, 225, 208), (63, 160, 90), (52, 60, 96)])))
sc.render.engine = "BLENDER_EEVEE"; sc.view_settings.view_transform = "Standard"; sc.render.resolution_x, sc.render.resolution_y = 1280, 720; sc.eevee.taa_render_samples = 12
w = bpy.data.worlds.new("w"); sc.world = w; w.use_nodes = True; w.node_tree.nodes["Background"].inputs[0].default_value = lin((150, 190, 228)); w.node_tree.nodes["Background"].inputs[1].default_value = 0.9
sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN")); sun.data.energy = 2.6; sun.rotation_euler = (0.75, 0, 0.5); sc.collection.objects.link(sun)
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera = cam; cam.data.clip_end = 3000; cam.data.sensor_fit = "VERTICAL"
def aim(eye, target, fov):
    cam.matrix_world = Matrix.Translation(eye) @ (target - eye).to_track_quat("-Z", "Y").to_matrix().to_4x4(); cam.data.angle_y = math.radians(fov)

# ---- the trail's parts ---------------------------------------------------------------------------------------------
N = 56
def ribbon_object(r):
    me = bpy.data.meshes.new("ribbon"); me.from_pydata([(0, 0, 0)] * (2 * N + 2), [], [(2 * i, 2 * i + 1, 2 * i + 3, 2 * i + 2) for i in range(N)])
    uv = me.uv_layers.new(); me.attributes.new("fade", "FLOAT", "POINT")
    m = bpy.data.materials.new("ribbon"); m.use_nodes = True; nt = m.node_tree; b = nt.nodes["Principled BSDF"]; m.surface_render_method = "BLENDED"; m.use_backface_culling = False
    t = nt.nodes.new("ShaderNodeTexImage"); t.image = bpy.data.images.load(str(pa.ROOT / "assets/fx/trails" / (r["picture"] + ".png"))); fade = nt.nodes.new("ShaderNodeAttribute"); fade.attribute_name = "fade"
    mul = nt.nodes.new("ShaderNodeMath"); mul.operation = "MULTIPLY"; nt.links.new(t.outputs["Alpha"], mul.inputs[0]); nt.links.new(fade.outputs["Fac"], mul.inputs[1]); nt.links.new(mul.outputs[0], b.inputs["Alpha"])
    nt.links.new(t.outputs["Color"], b.inputs["Base Color"]); nt.links.new(t.outputs["Color"], b.inputs["Emission Color"]); b.inputs["Emission Strength"].default_value = 0.35
    if r.get("look") == "foil": b.inputs["Metallic"].default_value, b.inputs["Roughness"].default_value = 0.55, 0.3
    me.materials.append(m); ob = bpy.data.objects.new("ribbon", me); sc.collection.objects.link(ob); return ob, uv
ribbons = [(r,) + ribbon_object(r) for r in SPEC.get("ribbons", [])]
looks, pools = {}, []
for piece in SPEC.get("pieces", []):
    build, smooth_shade = MODELS[piece["model"]]; me = mesh(piece["model"], build, smooth_shade)
    me.materials.append(looks.setdefault(piece["look"], look(piece["look"]))); pool = []
    for _ in range(int(piece["rate"] * 1.6 * piece["life"][1]) + 6):
        ob = bpy.data.objects.new(piece["model"], me); sc.collection.objects.link(ob); pool.append(ob)
    pools.append(pool)

hist = []; alive = [[] for _ in pools]; owed = [0.0] * len(pools); s = 0.0
def past(t):
    """The tail's place, right and up directions and growth at an earlier moment."""
    i = min(max(int((t - hist[0][0]) * FPS * SUB), 0), len(hist) - 1); return hist[i]
work = tempfile.mkdtemp(prefix="trail-")
for n in range(int((SECONDS + LIFE + 0.2) * FPS * SUB)):
    t = n / (FPS * SUB) - LIFE - 0.2; v = speed(t); s += v / (FPS * SUB); g = growth(v)
    p, right, nose, up = frame_at(s, v); tail = p + right * TAIL.x + nose * TAIL.y + up * TAIL.z
    hist.append((t, tail, right, up, g))
    for i, piece in enumerate(SPEC.get("pieces", [])):
        alive[i] = [q for q in alive[i] if t - q["born"] < q["life"]]; owed[i] += piece["rate"] * v / NORMAL / (FPS * SUB)
        while owed[i] >= 1:
            owed[i] -= 1; a, rad = rng.uniform(0, math.tau), piece["spread"] * math.sqrt(rng.random()); d = Vector((rng.gauss(0, 1), rng.gauss(0, 1), rng.gauss(0, 1))).normalized()
            alive[i].append(dict(born=t, life=rng.uniform(*piece["life"]), at=tail + (right * math.cos(a) + up * math.sin(a)) * rad, vel=d * rng.uniform(0, piece["drift"]), g=g,
                                 size=piece["size"][0] + (piece["size"][1] - piece["size"][0]) * rng.random() ** 2, axis=Vector((rng.gauss(0, 1), rng.gauss(0, 1), rng.gauss(0, 1))).normalized(),
                                 turn=rng.uniform(0, math.tau), spin=math.radians(piece.get("spin", 0)) * rng.uniform(0.5, 1) * rng.choice((-1, 1)), color=lin(rng.choice(piece["colors"]))))
    f = n // SUB - int((LIFE + 0.2) * FPS)
    if n % SUB or f < 0 or (STILLS and f not in STILLS): continue
    rig.matrix_world = Matrix(((right.x, nose.x, up.x, p.x), (right.y, nose.y, up.y, p.y), (right.z, nose.z, up.z, p.z), (0, 0, 0, 1)))
    for r, ob, uv in ribbons:                                                # the strip: one cross-line for each moment of the last second
        co, fade, us = [], [], []
        for i in range(N + 1):
            k = i / N; te, c, rt, u_, gg = past(t - k * LIFE); ang = math.tau * r.get("twist", 0) * te
            edge = (rt * math.cos(ang) + u_ * math.sin(ang)) * (CFG["width"] * r["width"] * (r["taper"][0] + (r["taper"][1] - r["taper"][0]) * k) * gg / 2)
            co += [c + edge, c - edge]; fade += [1 - (r["fade"][0] + (r["fade"][1] - r["fade"][0]) * k)] * 2; us.append(k)
        ob.data.vertices.foreach_set("co", [x for vv in co for x in vv]); ob.data.attributes["fade"].data.foreach_set("value", fade)
        for poly in ob.data.polygons:
            for li, vi in zip(poly.loop_indices, poly.vertices): uv.data[li].uv = (us[vi // 2], vi % 2)
        ob.data.update()
    for piece, pool, live in zip(SPEC.get("pieces", []), pools, alive):
        for ob, q in zip(pool, live + [None] * len(pool)):
            if q is None: ob.scale = (0, 0, 0); continue
            age = t - q["born"]; k = age / q["life"]; grow = CFG["grow_in"]; size = q["size"] * q["g"] * smooth(k / grow) * (1 + (piece["shrink"] - 1) * max(0, (k - grow) / (1 - grow)) ** 1.5)
            if piece.get("flash") and not (k < 0.3 or 0.42 < k < 0.7): size = 0   # lightning: on, off, on, gone
            at = q["at"] + q["vel"] * age + Vector((0, 0, 0.5 * piece.get("rise", 0) * age * age))
            ob.matrix_world = Matrix.Translation(at) @ Quaternion(q["axis"], q["turn"] + q["spin"] * age).to_matrix().to_4x4() @ Matrix.Diagonal((size, size, size, 1)); ob.color = q["color"]
    if f / FPS < CUT:                                                         # shot 1: the game's chase camera
        aim(p - nose * 24 + Vector((0, 0, 6)), p + nose * 60, 70)
    else:                                                                    # shot 2: another player flying alongside, looking across
        side = nose.cross(Vector((0, 0, 1))).normalized(); aim(p + side * 40 + nose * 4 + Vector((0, 0, 7)), p - nose * 24, 50)
    sc.render.filepath = os.path.join(work, "f%04d.png" % f) if not STILLS else str(OUT / ("%s-f%03d.png" % (TRAIL, f))); bpy.ops.render.render(write_still=True)
if not STILLS:
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-framerate", str(FPS), "-i", os.path.join(work, "f%04d.png"), "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "18", str(OUT / (TRAIL + ".mp4"))], check=True)
shutil.rmtree(work, ignore_errors=True); print("DONE", TRAIL)
