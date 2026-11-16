"""A trail as a 3D video, before any upload:
    blender -b --factory-startup --python tools/art/trail_preview.py -- <id> [frame ...]
        -> .planning/skins/trails/<id>.mp4, or <id>-f<frame>.png stills when frames are given
Plays config/trails.json in a 3D scene: the real starter plane (plane_assembly.py) flies a weaving path over a floor
with boxes, at its normal speed, then boosting. First shot: the game's own chase camera (24 studs behind, 6 above,
70 degrees). Second shot: from another plane flying alongside. Pieces are the 3D models of trail_pieces.py (star, flake,
shard, spark, puff, bolt; soft is a smoke card facing the camera), scattered at random sizes round the path and tumbling; a
ribbon is a strip laid along the path, or several thin strands wound round each other.
It imitates the game's drawing; the real look is confirmed in Studio after upload."""
import sys, os, json, math, random, subprocess, tempfile, shutil, bpy
import numpy as np
from mathutils import Vector, Matrix, Quaternion
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__))); import plane_assembly as pa, trail_pieces

ARGS = sys.argv[sys.argv.index("--") + 1:]; TRAIL = ARGS[0]; STILLS = [int(a) for a in ARGS[1:]]
CFG = json.load(open(pa.ROOT / "config/trails.json")); LIFE = CFG["life"]
SPEC = CFG["trails"].get(TRAIL) or json.load(open(pa.ROOT / "tools/art/trail_drafts.json"))["trails"][TRAIL]   # drafts: not in the game yet
CARDS = ("soft", "square")                                                    # flat cards that face the camera (particles in the game)
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

def look(kind):
    """A material that takes each piece's own colour and see-through share: crinkled foil, cotton, soft smoke or a light."""
    m = bpy.data.materials.new(kind); m.use_nodes = True; nt = m.node_tree; b = nt.nodes["Principled BSDF"]; own = nt.nodes.new("ShaderNodeObjectInfo")
    m.surface_render_method = "DITHERED"; nt.links.new(own.outputs["Alpha"], b.inputs["Alpha"])
    nt.links.new(own.outputs["Color"], b.inputs["Base Color"]); nt.links.new(own.outputs["Color"], b.inputs["Emission Color"])
    def bumpy(scale, strength):
        n, bump = nt.nodes.new("ShaderNodeTexNoise"), nt.nodes.new("ShaderNodeBump"); n.inputs["Scale"].default_value = scale; n.inputs["Detail"].default_value = 7; bump.inputs["Strength"].default_value = strength
        nt.links.new(n.outputs["Fac"], bump.inputs["Height"]); nt.links.new(bump.outputs["Normal"], b.inputs["Normal"])
    if kind == "foil":
        b.inputs["Metallic"].default_value, b.inputs["Roughness"].default_value, b.inputs["Emission Strength"].default_value = 0.4, 0.32, 0.1; bumpy(7, 0.7)
    elif kind == "glow": b.inputs["Emission Strength"].default_value = 9
    elif kind == "soft":                                                     # a round patch, lumpy at its rim, fading to nothing
        b.inputs["Roughness"].default_value, b.inputs["Emission Strength"].default_value = 1.0, 0.35
        tc, ln, n = nt.nodes.new("ShaderNodeTexCoord"), nt.nodes.new("ShaderNodeVectorMath"), nt.nodes.new("ShaderNodeTexNoise")   # the card's own -0.5..0.5
        ln.operation = "LENGTH"; n.noise_dimensions = "4D"; n.inputs["Scale"].default_value = 3.2; n.inputs["Detail"].default_value = 5
        w = nt.nodes.new("ShaderNodeMath"); w.operation = "MULTIPLY"; w.inputs[1].default_value = 40; nt.links.new(own.outputs["Random"], w.inputs[0]); nt.links.new(w.outputs[0], n.inputs["W"])
        nt.links.new(tc.outputs["Object"], ln.inputs[0]); nt.links.new(tc.outputs["Object"], n.inputs["Vector"])
        lump = nt.nodes.new("ShaderNodeMath"); lump.operation = "MULTIPLY_ADD"; lump.inputs[1].default_value = 0.3; nt.links.new(n.outputs["Fac"], lump.inputs[0]); nt.links.new(ln.outputs["Value"], lump.inputs[2])
        rim = nt.nodes.new("ShaderNodeMapRange"); rim.interpolation_type = "SMOOTHSTEP"; rim.inputs["From Min"].default_value, rim.inputs["From Max"].default_value = 0.2, 0.58
        rim.inputs["To Min"].default_value, rim.inputs["To Max"].default_value = 0.9, 0.0; nt.links.new(lump.outputs[0], rim.inputs["Value"])
        al = nt.nodes.new("ShaderNodeMath"); al.operation = "MULTIPLY"; nt.links.new(rim.outputs["Result"], al.inputs[0]); nt.links.new(own.outputs["Alpha"], al.inputs[1]); nt.links.new(al.outputs[0], b.inputs["Alpha"])
    elif kind == "paper": b.inputs["Roughness"].default_value, b.inputs["Emission Strength"].default_value = 0.85, 0.12   # crisp folds
    elif kind == "bright": b.inputs["Roughness"].default_value, b.inputs["Emission Strength"].default_value = 0.35, 0.9   # a lit block that still shades
    elif kind == "glass":                                                    # a goo bubble: shiny, partly see-through
        b.inputs["Roughness"].default_value, b.inputs["Emission Strength"].default_value = 0.06, 0.3
        al = nt.nodes.new("ShaderNodeMath"); al.operation = "MULTIPLY"; al.inputs[1].default_value = 0.62; nt.links.new(own.outputs["Alpha"], al.inputs[0]); nt.links.new(al.outputs[0], b.inputs["Alpha"])
    else: b.inputs["Roughness"].default_value, b.inputs["Emission Strength"].default_value = 1.0, 0.05; bumpy(5, 0.5)   # cotton
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
sc.render.engine = "BLENDER_EEVEE"; sc.view_settings.view_transform = "Standard"; sc.render.resolution_x, sc.render.resolution_y = 1280, 720; sc.eevee.taa_render_samples = 24
w = bpy.data.worlds.new("w"); sc.world = w; w.use_nodes = True; w.node_tree.nodes["Background"].inputs[0].default_value = lin((150, 190, 228)); w.node_tree.nodes["Background"].inputs[1].default_value = 0.9
sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN")); sun.data.energy = 2.6; sun.rotation_euler = (0.75, 0, 0.5); sc.collection.objects.link(sun)
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera = cam; cam.data.clip_end = 3000; cam.data.sensor_fit = "VERTICAL"
def aim(eye, target, fov):
    cam.matrix_world = Matrix.Translation(eye) @ (target - eye).to_track_quat("-Z", "Y").to_matrix().to_4x4(); cam.data.angle_y = math.radians(fov)

# ---- the trail's parts ---------------------------------------------------------------------------------------------
N = 56
def mix(pair, k): return pair[0] + (pair[1] - pair[0]) * k
def ribbon_object(r, j):
    me = bpy.data.meshes.new("ribbon"); me.from_pydata([(0, 0, 0)] * (2 * N + 2), [], [(2 * i, 2 * i + 1, 2 * i + 3, 2 * i + 2) for i in range(N)])
    uv = me.uv_layers.new(); me.attributes.new("fade", "FLOAT", "POINT")
    m = bpy.data.materials.new("ribbon"); m.use_nodes = True; nt = m.node_tree; b = nt.nodes["Principled BSDF"]; m.surface_render_method = "BLENDED"; m.use_backface_culling = False
    fade = nt.nodes.new("ShaderNodeAttribute"); fade.attribute_name = "fade"
    if "picture" in r:
        t = nt.nodes.new("ShaderNodeTexImage"); t.image = bpy.data.images.load(str(pa.ROOT / "assets/fx/trails" / (r["picture"] + ".png")))
        mul = nt.nodes.new("ShaderNodeMath"); mul.operation = "MULTIPLY"; nt.links.new(t.outputs["Alpha"], mul.inputs[0]); nt.links.new(fade.outputs["Fac"], mul.inputs[1]); nt.links.new(mul.outputs[0], b.inputs["Alpha"])
        nt.links.new(t.outputs["Color"], b.inputs["Base Color"]); nt.links.new(t.outputs["Color"], b.inputs["Emission Color"]); b.inputs["Emission Strength"].default_value = 0.35
    else:                                                                    # a strand: one plain glowing colour
        b.inputs["Base Color"].default_value = b.inputs["Emission Color"].default_value = lin(r["colors"][j]); b.inputs["Emission Strength"].default_value = 1.6; nt.links.new(fade.outputs["Fac"], b.inputs["Alpha"])
    if r.get("look") == "foil": b.inputs["Metallic"].default_value, b.inputs["Roughness"].default_value = 0.55, 0.3
    me.materials.append(m); ob = bpy.data.objects.new("ribbon", me); sc.collection.objects.link(ob); return ob, uv
ribbons = [(r, j) + ribbon_object(r, j) for r in SPEC.get("ribbons", []) for j in range(r.get("strands", 1))]
looks, pools, lamps = {}, [], []
for piece in SPEC.get("pieces", []):
    me = trail_pieces.mesh(piece["model"])
    me.materials.append(looks.setdefault(piece["look"], look(piece["look"]))); pool = []
    for _ in range(int(piece["rate"] * 1.6 * piece["life"][1]) + 6):
        ob = bpy.data.objects.new(piece["model"], me); sc.collection.objects.link(ob); pool.append(ob)
    pools.append(pool); mine = []
    for _ in range(8 if piece.get("light") else 0):                          # lightning lights the cloud round it
        lamp = bpy.data.objects.new("flash", bpy.data.lights.new("flash", "POINT")); lamp.data.color = lin(piece["colors"][0])[:3]; lamp.data.use_shadow = False; lamp.data.shadow_soft_size = 1.5
        sc.collection.objects.link(lamp); mine.append(lamp)
    lamps.append(mine)

hist = []; alive = [[] for _ in pools]; owed = [0.0] * len(pools); s = 0.0
def past(t):
    """The tail's place, right and up directions and growth at an earlier moment."""
    i = min(max(int((t - hist[0][0]) * FPS * SUB), 0), len(hist) - 1); return hist[i]
def rnd(): return Vector((rng.gauss(0, 1), rng.gauss(0, 1), rng.gauss(0, 1))).normalized()
work = tempfile.mkdtemp(prefix="trail-")
for n in range(int((SECONDS + LIFE + 0.2) * FPS * SUB)):
    t = n / (FPS * SUB) - LIFE - 0.2; v = speed(t); s += v / (FPS * SUB); g = growth(v)
    p, right, nose, up = frame_at(s, v); tail = p + right * TAIL.x + nose * TAIL.y + up * TAIL.z
    hist.append((t, tail, right, up, g))
    for i, piece in enumerate(SPEC.get("pieces", [])):
        alive[i] = [q for q in alive[i] if t - q["born"] < q["life"]]; owed[i] += piece["rate"] * v / NORMAL / (FPS * SUB)
        while owed[i] >= 1:
            owed[i] -= 1; a, rad = rng.uniform(0, math.tau), piece["spread"] * math.sqrt(rng.random()); ox, oy = math.cos(a) * rad, math.sin(a) * rad
            if piece.get("lattice"): ox, oy = round(ox / piece["lattice"]) * piece["lattice"], round(oy / piece["lattice"]) * piece["lattice"]   # on a grid: pieces line up
            axes = rng.choices(((nose, up, right), (right, nose, up), (up, right, nose)), piece.get("axes", (5, 3, 2)))[0]   # a grid piece's long side: along the path, across, up (`axes`: how often each)
            alive[i].append(dict(born=t, life=rng.uniform(*piece["life"]), at=tail + right * ox + up * oy, right=right, grid=Matrix(axes).transposed().to_quaternion(), vel=rnd() * rng.uniform(0, piece["drift"]), g=g, seed=rng.random(),
                                 size=piece["size"][0] + (piece["size"][1] - piece["size"][0]) * rng.random() ** 2, axis=rnd(), dir=(nose + rnd() * 0.45).normalized(),
                                 turn=rng.uniform(0, math.tau), spin=math.radians(piece.get("spin", 0)) * rng.uniform(0.5, 1) * rng.choice((-1, 1)), color=lin(rng.choice(piece["colors"]))))
    f = n // SUB - int((LIFE + 0.2) * FPS)
    if n % SUB or f < 0 or (STILLS and f not in STILLS): continue
    rig.matrix_world = Matrix(((right.x, nose.x, up.x, p.x), (right.y, nose.y, up.y, p.y), (right.z, nose.z, up.z, p.z), (0, 0, 0, 1)))
    if f / FPS < CUT: eye, target, fov = p - nose * 24 + Vector((0, 0, 6)), p + nose * 60, 70      # shot 1: the game's chase camera
    else:                                                                    # shot 2: another player flying alongside, looking across
        side = nose.cross(Vector((0, 0, 1))).normalized(); eye, target, fov = p + side * 40 + nose * 4 + Vector((0, 0, 7)), p - nose * 24, 50
    aim(eye, target, fov); facing = cam.matrix_world.to_quaternion()
    for r, j, ob, uv in ribbons:                                             # a strip: one cross-line for each moment of the last second
        co, fade, mids, wide = [], [], [], []; strands = r.get("strands", 1)
        for i in range(N + 1):
            k = i / N; te, c, rt, u_, gg = past(t - k * LIFE); ang = math.tau * (r.get("twist", 0) * te + j / strands); out = rt * math.cos(ang) + u_ * math.sin(ang)
            if strands > 1: mids.append(c + out * (r["radius"] * mix(r["taper"], k) * gg)); wide.append(r["width"] * mix(r["taper"], k) * gg / 2)
            else: edge = out * (CFG["width"] * r["width"] * mix(r["taper"], k) * gg / 2); co += [c + edge, c - edge]
            fade += [1 - mix(r["fade"], k)] * 2
        for i, c in enumerate(mids):                                         # a strand faces the camera, so it reads as a round cord
            edge = (mids[min(i + 1, N)] - mids[max(i - 1, 0)]).cross(c - eye).normalized() * wide[i]; co += [c + edge, c - edge]
        ob.data.vertices.foreach_set("co", [x for vv in co for x in vv]); ob.data.attributes["fade"].data.foreach_set("value", fade)
        for poly in ob.data.polygons:
            for li, vi in zip(poly.loop_indices, poly.vertices): uv.data[li].uv = (vi // 2 / N, vi % 2)
        ob.data.update()
    for piece, pool, live, mine in zip(SPEC.get("pieces", []), pools, alive, lamps):
        lit = 0
        for ob, q in zip(pool, live + [None] * len(pool)):
            if q is None: ob.scale = (0, 0, 0); continue
            age = t - q["born"]; k = age / q["life"]; grow = CFG["grow_in"]
            size = q["size"] * q["g"] * smooth(k / grow) * (1 + (piece["shrink"] - 1) * max(0, (k - grow) / (1 - grow)) ** 1.5)
            if piece.get("flash") and not (k < 0.3 or 0.42 < k < 0.7): size = 0   # lightning: on, off, on, gone
            if piece.get("twinkle"): size *= 0.3 + 0.7 * random.Random(int(q["seed"] * 1e6) + int(t * piece["twinkle"])).random()
            at = q["at"] + q["vel"] * age + Vector((0, 0, 0.5 * piece.get("rise", 0) * age * age))
            if piece.get("jump"): at = at + q["right"] * (piece["jump"] * random.Random(int(q["seed"] * 1e6) + int(t * 8)).randint(-2, 2) / 2)   # snaps sideways 8 times a second
            if piece["model"] in CARDS: turn = facing @ Quaternion((0, 0, 1), (q["turn"] if piece.get("spin") else 0) + q["spin"] * age)
            elif piece.get("align") == "grid": turn = q["grid"]                 # square to the plane as it was when the piece left
            elif piece.get("upright"): turn = Quaternion((0, 0, 1), q["turn"] + q["spin"] * age) @ Quaternion((1, 0, 0), math.pi / 2 + (q["seed"] - 0.5) * 0.5)   # stands up, turning like a sign
            elif piece.get("align"): turn = Vector((1, 0, 0)).rotation_difference(q["dir"]) @ Quaternion((1, 0, 0), q["turn"])
            else: turn = Quaternion(q["axis"], q["turn"] + q["spin"] * age)
            ob.matrix_world = Matrix.Translation(at) @ turn.to_matrix().to_4x4() @ Matrix.Diagonal((size, size, size, 1))
            color = q["color"]
            if piece.get("rainbow"):                                         # the colour runs through the list along the stream, `rainbow` times over
                runs = float(piece["rainbow"]); cols = piece["colors"] + piece["colors"][:1] * (runs > 1); x = (k * runs % 1 if runs > 1 else min(k, 1)) * (len(cols) - 1)
                i = min(int(x), len(cols) - 2); c0, c1 = lin(cols[i]), lin(cols[i + 1]); color = tuple(a + (b - a) * (x - i) for a, b in zip(c0, c1))
            gone = piece.get("vanish", 0); ob.color = tuple(color[:3]) + ((1 - smooth((k - (1 - gone)) / gone)) if gone else 1.0,)
            if mine and size > 0 and lit < len(mine): mine[lit].location = at; mine[lit].data.energy = piece["light"]; lit += 1
        for lamp in mine[lit:]: lamp.data.energy = 0
    sc.render.filepath = os.path.join(work, "f%04d.png" % f) if not STILLS else str(OUT / ("%s-f%03d.png" % (TRAIL, f))); bpy.ops.render.render(write_still=True)
if not STILLS:
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-framerate", str(FPS), "-i", os.path.join(work, "f%04d.png"), "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "18", str(OUT / (TRAIL + ".mp4"))], check=True)
shutil.rmtree(work, ignore_errors=True); print("DONE", TRAIL)
