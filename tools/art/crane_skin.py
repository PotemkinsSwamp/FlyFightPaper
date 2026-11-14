"""Origami Crane, the first Mythical skin (Alan's pick, 2026-11-13; concept .planning/skins/concepts/crane-2.png).
Builds the crane, paints its pictures, fits it to real planes the way the game will, and renders previews. Blender:

    D:/Blender/blender.exe -b --factory-startup --python tools/art/crane_skin.py -- OUTDIR [--quick] [--no-render] [--scene-only]

How it fits any plane (docs/plan/SKINS-PLAN.md "Mythical: a whole new shape"): the crane is scaled evenly to the
plane's length (s = length / 16) and its joints (a Bone each in Roblox) are placed from the real plane: the beak at the
nose tip, the tail tip over the real tail's top back corner, the body on the real body (width capped), its keel on the
real body's bottom and back over the booster spot. The wings keep their own shape (a little bigger or smaller to suit
the real wing) and rise in a V from the body's sides. Guns hang under the wings (Alan: nothing on top of a Mythical).
Pictures: one 1024 set (colour, normal, roughness, metalness), painted from the crane's own 3D shape: deep blue paper,
silver foil on every fold and paper edge, silver seigaiha waves, a cherry blossom sprig on each wing (no white areas).
Writes into OUTDIR: crane-*.png, crane.blend (rest pose), renders, crane-report.json.
"""
import bpy, bmesh, sys, os, math, json
import numpy as np
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import plane_assembly as pa

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = os.path.abspath(ARGS[0] if ARGS else "crane-out")
QUICK, RENDER, SCENE_ONLY = "--quick" in ARGS, "--no-render" not in ARGS, "--scene-only" in ARGS
os.makedirs(OUT, exist_ok=True)
TEX = 1024
BUILDS = {  # name: loadout (weapons and boosters stay visible)
    "starter": dict(body="body_standard", nose="nose_0", wings="wings_0", tail="tail_0",
                    weapon_mounts=["pellet", "thumbtack", "pellet", False], utility=None),
    "heavy": dict(body="body_heavy", nose="nose_3", wings="wings_4", tail="tail_3",
                  weapon_mounts=["pellet", "pellet", "eraser", "eraser"], utility="boost_band"),
    "swept": dict(body="body_standard_mk2", nose="nose_1", wings="wings_1", tail="tail_1",
                  weapon_mounts=["staple", "staple", False, False], utility="boost_twin"),
}
GAP = 70.0  # studs between the builds in the scene

def to_bl(p, dx=0.0): return Vector((p[0] + dx, -p[2], p[1]))   # Roblox frame (x right, y up, -z forward) -> Blender
def lerp(a, b, t): return a + (b - a) * t

# ---------------------------------------------------------------- the real plane
def material(name, rgb=(0.8, 0.8, 0.8), alpha=1.0, image=None, tint=None, rough=0.8):
    m = bpy.data.materials.new(name); m.use_nodes = True
    nt = m.node_tree; b = nt.nodes["Principled BSDF"]
    b.inputs["Roughness"].default_value = rough; b.inputs["Alpha"].default_value = alpha
    if image and os.path.exists(image):
        tex = nt.nodes.new("ShaderNodeTexImage"); tex.image = bpy.data.images.load(image, check_existing=True)
        out = tex.outputs["Color"]
        if tint:
            mix = nt.nodes.new("ShaderNodeMix"); mix.data_type = "RGBA"; mix.blend_type = "MULTIPLY"
            mix.inputs["Factor"].default_value = 1.0; nt.links.new(out, mix.inputs["A"])
            mix.inputs["B"].default_value = (*tint, 1); out = mix.outputs["Result"]
        nt.links.new(out, b.inputs["Base Color"])
    else:
        b.inputs["Base Color"].default_value = (*rgb, 1)
    return m

HITBOX = None
def import_piece(piece, dx):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=piece["fbx"])
    new = [o for o in bpy.data.objects if o not in before]
    meshes = [o for o in new if o.type == "MESH"]
    for o in bpy.data.objects: o.select_set(o in meshes)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.parent_clear(type="CLEAR_KEEP_TRANSFORM")
    for o in new:
        if o.type != "MESH": bpy.data.objects.remove(o)
    if len(meshes) > 1: bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    me = obj.data
    raw = np.array([(v.co.x, v.co.z, -v.co.y) for v in me.vertices])
    lo, hi = raw.min(0), raw.max(0)
    world = np.array(piece["centre"]) + (raw - (lo + hi) / 2) * np.array(piece["size"]) / np.maximum(hi - lo, 1e-6)
    for v, w in zip(me.vertices, world): v.co = to_bl(w, dx)
    obj.name = piece["name"]
    return obj, world

def build_plane(loadout, dx):
    info = {}; pieces = pa.assemble(loadout, info)
    pts = {"nose": [], "tail": [], "wings": [], "body": []}
    real, extras, guns = [], [], {}
    for p in pieces:
        if not p["fbx"] or not os.path.exists(p["fbx"]): continue
        if "sticker" in p["name"]: continue
        obj, world = import_piece(p, dx)
        obj.data.materials.clear()
        if p["slot"] in pts:
            if p["slot"] in ("nose", "tail") or not any(k in p["name"] for k in ("accent", "tape")): pts[p["slot"]].append(world)
            obj.data.materials.append(HITBOX); real.append(obj)
        else:
            kind = p["name"].split("-")[1] if p["slot"] == "booster" else None
            if p["slot"] == "weapon":
                folder = os.path.dirname(os.path.dirname(p["fbx"]))
                img = next((os.path.join(folder, f) for f in ("color.png", "meshy-base_color.png") if os.path.exists(os.path.join(folder, f))), None)
                m = material("W-" + p["name"], image=img if obj.data.uv_layers else None, rgb=(0.7, 0.7, 0.7), rough=0.5)
                guns.setdefault(p["name"].split("-")[0], []).append((obj, world))
            else:  # booster: blue team paper, dark card, yellow tape (Aircraft.paint)
                tint = {"paper": (0.066, 0.216, 0.672), "cardboard": (0.026, 0.1, 0.4), "tape": (1, 0.66, 0.007)}.get(kind)
                m = material("B-" + p["name"], image=os.path.join(pa.PLANES, "paper-set", p["name"] + "-color.png"), tint=tint)
            obj.data.materials.append(m); extras.append(obj)
    pts = {k: np.concatenate(v) for k, v in pts.items()}
    return dict(real=real, extras=extras, guns=guns, o=outline(pts, info), dx=dx)

def outline(pts, info):
    """The plane's points the crane's joints move to (Roblox frame)."""
    nose, tail, body, wings = pts["nose"], pts["tail"], pts["body"], pts["wings"]
    zN = nose[:, 2].min(); tip = nose[nose[:, 2] < zN + 0.6]
    side = wings[wings[:, 0] > 0]; ax = np.abs(side[:, 0])
    xo, xi = ax.max(), ax.min()
    inner = side[ax < xi + 0.6]
    return dict(zN=zN, yN=tip[:, 1].mean(), zT=tail[:, 2].max(), yT=tail[:, 1].max(),
                bw=np.abs(body[:, 0]).max(), by0=body[:, 1].min(), by1=body[:, 1].max(),
                bz0=body[:, 2].min(), bz1=body[:, 2].max(), wy=float(np.median(wings[:, 1])), xo=xo,
                LI=inner[:, 2].min(), TI=inner[:, 2].max(), boost_y=info["booster"][0], boost_z=info["booster"][2])

# ---------------------------------------------------------------- the crane
RISE = math.radians(32)        # how steeply the wings rise from the body (the V seen from behind)
C0, R0, SW = 6.0, 7.0, 0.8     # the wing's own shape, in s: root length, length out to the tip, how far back the tip sits
HC = 0.07                      # the wing's fold line stands this far (s) off the paper
SHEETS = ("wing", "wflap", "flap")   # thin paper (given real thickness); the rest are closed folded points

def wing_tri(u, w):
    """Which of the wing's four faces holds wing point (u, w), and the fold's height there."""
    Fl, Ft, Fm, T = (0, -C0 / 2), (0, C0 / 2), (0, -0.3), (R0, SW); Cm = (R0 * 0.4, -0.3 + (SW + 0.3) * 0.4)
    for a, b, c in ((Fl, Fm, Cm), (Fl, Cm, T), (Fm, Ft, Cm), (Cm, Ft, T)):
        den = (b[1] - c[1]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[1] - c[1])
        l0 = ((b[1] - c[1]) * (u - c[0]) + (c[0] - b[0]) * (w - c[1])) / den
        l1 = ((c[1] - a[1]) * (u - c[0]) + (a[0] - c[0]) * (w - c[1])) / den
        l2 = 1 - l0 - l1
        if min(l0, l1, l2) >= -1e-6: return HC * sum(l for l, q in zip((l0, l1, l2), (a, b, c)) if q == Cm)
    return 0.0

def crane(o):
    """Crane corners (Roblox frame) placed from the plane outline `o`: faces, part per face, joint per corner."""
    s = (o["zT"] - o["zN"]) / 16.0
    V, F, P, J = [], [], [], []
    def v(p, joint): V.append(np.array(p, float)); J.append(joint); return len(V) - 1
    def tri(part, a, b, c): F.append((a, b, c)); P.append(part)
    def poly(part, ids):
        for i in range(1, len(ids) - 1): tri(part, ids[0], ids[i], ids[i + 1])
    unit = lambda a: a / np.linalg.norm(a)
    wy = o["wy"]; cw = min(max(0.95 * o["bw"], 0.9 * s), 1.7 * s); ky = min(o["by0"], o["boost_y"])
    zF, zB = o["bz0"] + 0.2 * s, o["bz1"] - 0.2 * s; blen = zB - zF
    # wings keep their own shape (scaled evenly, a little bigger or smaller to suit the real wing) and hinge on the body
    run = (o["xo"] + 0.3 * s - cw) / math.cos(RISE) / s; chord = (o["TI"] - o["LI"]) / s
    k = min(max(math.sqrt(run / R0 * chord / C0), 0.85), 1.2, 0.9 * blen / (C0 * s)); ks = k * s
    zc = min(max((o["LI"] + o["TI"]) / 2, zF + 0.06 * blen + C0 * ks / 2), zB - 0.04 * blen - C0 * ks / 2)
    z1, z2 = zc - C0 * ks / 2, zc + C0 * ks / 2; zm = (z1 + z2) / 2
    # body: six-sided from above (pointed front and back, straight sides the wings hinge on), a raised back,
    # and a keel ridge on the real body's bottom that reaches back over the booster spot
    pF, pB = np.array((0, wy - 0.12 * s, zF)), np.array((0, wy - 0.05 * s, zB))
    pP = np.array((0, wy + 0.9 * s, zm + 0.1 * s))
    pK1 = np.array((0, ky - 0.35 * s, lerp(zF, zB, 0.3))); pK2 = np.array((0, ky, min(max(lerp(zF, zB, 0.62), o["boost_z"]), zB - 0.4 * s)))
    cen = (pF + pB + pP + pK1 + pK2) / 5
    Fr, Bk, Pk, K1, K2 = v(pF, "BodyFront"), v(pB, "BodyBack"), v(pP, "Back"), v(pK1, "Keel"), v(pK2, "KeelBack")
    def flap(part, pts, joint, out, lift=0.045):  # a second paper layer lying on a face
        n = unit(np.cross(pts[1] - pts[0], pts[2] - pts[0])); n = n if n @ out > 0 else -n
        poly(part, [v(q + n * lift * s, joint) for q in pts])
    for sx in (-1, 1):
        LR = "LR"[sx > 0]; pMf, pMb = np.array((sx * cw, wy, z1)), np.array((sx * cw, wy, z2))
        Mf, Mb = v(pMf, "BodySideFront" + LR), v(pMb, "BodySideBack" + LR)
        tri("body", Fr, Mf, Pk); tri("body", Mf, Mb, Pk); tri("body", Mb, Bk, Pk)
        tri("body", Fr, K1, Mf); tri("body", Mf, K1, K2); tri("body", Mf, K2, Mb); tri("body", Mb, K2, Bk)
        # layered flaps: two on the back, one on the breast, one on the flank, one by the tail
        mid = lerp(pMf, pMb, 0.5)
        flap("flap", [lerp(pMf, pMb, 0.04), lerp(pMf, pMb, 0.96), lerp(mid, pP, 0.72)], "Back", pP - cen)
        flap("flap", [lerp(pMf, pMb, 0.22), lerp(pMf, pMb, 0.78), lerp(mid, pP, 0.5)], "Back", pP - cen, 0.1)
        flap("flap", [lerp(pF, pMf, 0.06), lerp(pF, pMf, 0.94), lerp(pF, pP, 0.6) * 0.6 + pMf * 0.4], "BodyFront", pP - cen)
        flap("flap", [lerp(pMb, pB, 0.06), lerp(pMb, pB, 0.94), lerp(pB, pP, 0.55) * 0.6 + pMb * 0.4], "BodyBack", pP - cen)
        flap("flap", [lerp(pF, pK1, 0.08), lerp(pF, pK1, 0.92), lerp(pF, pMf, 0.75) * 0.75 + pK1 * 0.25], "BodyFront", pMf - cen)
        flap("flap", [lerp(pMf, pMb, 0.1), lerp(pMf, pMb, 0.9), lerp(pK1, pK2, 0.5) * 0.7 + mid * 0.3], "Keel", pMf - cen)
        flap("flap", [lerp(pB, pK2, 0.08), lerp(pB, pK2, 0.92), lerp(pB, pMb, 0.7) * 0.75 + pK2 * 0.25], "BodyBack", pMb - cen)
    # folded points: a ridge on top and two lower corners, tapering; a "crimp" is one piece tucked into the next
    def section(r, h, w, joint, lean=None):
        top = r if lean is None else r + lean
        return [v(top, joint), v(r + (-w / 2, -h, 0), joint), v(r + (w / 2, -h, 0), joint)]
    def blade(part, a, b, cap=True):
        for i, j in ((0, 1), (2, 0), (1, 2)): tri(part, a[i], a[j], b[j]); tri(part, a[i], b[j], b[i])
        if cap: tri(part, b[0], b[1], b[2])
    def spike(part, a, tip):
        for i, j in ((0, 1), (2, 0), (1, 2)): tri(part, a[i], a[j], tip)
    step = np.array((0, -0.1 * s, 0))
    # neck: stretched forward along the real nose, crimped once, then the head folded back down through its tip
    N0 = np.array((0, wy - 0.3 * s, zF + 0.5 * s)); Hr = np.array((0, o["yN"] + 0.8 * s, o["zN"] + 1.5 * s))
    fwd = unit(Hr - N0); Rn = lambda t: lerp(N0, Hr, t)
    blade("neck1", section(Rn(0), 0.9 * s, 0.4 * s, "BodyFront"), section(Rn(0.56), 0.6 * s, 0.28 * s, "Neck", fwd * 0.3 * s))
    blade("neck2", section(Rn(0.48) + step, 0.52 * s, 0.22 * s, "Neck"),
          section(Hr + step * 0.6 - fwd * 0.15 * s, 0.48 * s, 0.19 * s, "Head", fwd * 0.45 * s))
    # the head: a blade tucked into the neck's open tip, pointing down and forward (the neck's own tip is the crest)
    hb = Hr + step - fwd * 0.2 * s
    head = [v(hb + (0, -0.03 * s, 0) + fwd * 0.2 * s, "Head"), v(hb + (-0.07 * s, -0.58 * s, 0), "Head"), v(hb + (0.07 * s, -0.58 * s, 0), "Head")]
    spike("head", head, v((0, o["yN"] - 0.75 * s, o["zN"] + 0.25 * s), "Beak")); bq = V[-1]
    for sx, j in ((-1, 1), (1, 2)):   # a cheek layer on each side of the head
        flap("flap", [lerp(V[head[0]], V[head[j]], 0.12), lerp(V[head[0]], V[head[j]], 0.95),
                      lerp(V[head[j]], bq, 0.5) * 0.7 + lerp(V[head[0]], bq, 0.5) * 0.3], "Head", np.array((sx, 0.0, 0.0)), 0.03)
    # tail: rising to over the real tail's top back corner, crimped once
    T0 = np.array((0, wy - 0.25 * s, zB - 0.6 * s)); Tt = np.array((0, max(o["yT"], wy + 1.3 * s) + 0.5 * s, o["zT"] + 0.7 * s))
    bwd = unit(Tt - T0); Rt = lambda t: lerp(T0, Tt, t)
    blade("tail1", section(Rt(0), 0.9 * s, 0.38 * s, "BodyBack"), section(Rt(0.42), 0.6 * s, 0.26 * s, "Tail", bwd * 0.3 * s))
    spike("tail2", section(Rt(0.33) + step, 0.46 * s, 0.19 * s, "Tail"), v(Tt, "TailTip"))
    # wings
    panels = {}
    for sx in (-1, 1):
        LR = "LR"[sx > 0]
        def at(u, w, h=0.0):  # wing point: u out along the wing, w back along the root, h up off the paper (all in s)
            u, w, h = u * ks, w * ks, h * s
            return np.array((sx * (cw * 0.97 + u * math.cos(RISE) - h * math.sin(RISE)), wy + 0.02 * s + u * math.sin(RISE) + h * math.cos(RISE), zc + w))
        Fl, Ft, Fm, T = v(at(0, -C0 / 2), "WingRootFront" + LR), v(at(0, C0 / 2), "WingRootBack" + LR), v(at(0, -0.3), "WingRoot" + LR), v(at(R0, SW), "WingTip" + LR)
        Cm = v(at(R0 * 0.4, -0.3 + (SW + 0.3) * 0.4, HC), "WingFold" + LR)
        for a, b, c in ((Fl, Fm, Cm), (Fl, Cm, T), (Fm, Ft, Cm), (Cm, Ft, T)): tri("wing", a, b, c)
        def layer(pts, lift):  # a folded-over layer on the wing
            poly("wflap", [v(at(u, w, wing_tri(u, w) + lift), "WingRoot" + LR) for u, w in pts])
        layer([(0.03, -2.75), (0.03, -0.55), (2.5, -0.8)], 0.06)          # big root flap, front half
        layer([(0.06, -2.3), (0.06, -1.05), (1.45, -1.5)], 0.12)          # a smaller one on top of it
        layer([(0.03, 1.95), (0.03, 2.9), (1.45, 2.55)], 0.06)            # root flap by the tail
        layer([(2.7, -1.5), (6.8, 0.66), (2.7, -0.95)], 0.06)             # hem along the leading edge
        panels[sx] = dict(o=at(0, 0), eu=unit(at(1, 0) - at(0, 0)), ew=np.array((0, 0, 1.0)), ks=ks)
    return dict(V=np.array(V), F=F, P=P, J=J, s=s, cw=cw, panels=panels, head=Hr, zc=zc, ks=ks,
                small=[(Rn(0.3) + (0, -0.42 * s, 0), 0.2 * s, 0.3), (Rt(0.2) + (0, -0.36 * s, 0), 0.2 * s, 1.0), (Rt(0.62) + (0, -0.17 * s, 0), 0.11 * s, 0.2)])

def wing_under(c, x, z):
    """Height of the wing's underside over plane spot (x, z), and that spot moved (if needed) to be under the wing."""
    ks = c["ks"]; u = min(max((abs(x) - c["cw"] * 0.97) / (ks * math.cos(RISE)), 0.25), R0 - 1.2)
    w = min(max((z - c["zc"]) / ks, -C0 / 2 + u * (SW + C0 / 2) / R0 + 0.9), C0 / 2 - u * (C0 / 2 - SW) / R0 - 0.9)
    xx = c["cw"] * 0.97 + u * ks * math.cos(RISE)
    return math.copysign(xx, x), c["panels"][1]["o"][1] + u * ks * math.sin(RISE) - 0.035 * c["s"], c["zc"] + w * ks

def orient(c):
    """Outward faces for the closed parts, upward for the wings (so their paper thickens evenly)."""
    V, F = c["V"], c["F"]
    groups = {}
    for i, part in enumerate(c["P"]): groups.setdefault(part, []).append(i)
    for part, idx in groups.items():
        if part in ("flap", "wflap"): continue
        cen = V[sorted({j for i in idx for j in F[i]})].mean(0)
        for i in idx:
            a, b, d = V[list(F[i])]; n = np.cross(b - a, d - a); fc = (a + b + d) / 3
            if (n[1] < 0) if part == "wing" else (np.dot(n, fc - cen) < 0): F[i] = (F[i][0], F[i][2], F[i][1])
    return c

def crane_object(c, name, dx, uvs=None):
    me = bpy.data.meshes.new(name); me.from_pydata([to_bl(p, dx) for p in c["V"]], [], c["F"]); me.update()
    if uvs is not None:
        layer = me.uv_layers.new(name="UVMap")
        for poly in me.polygons:
            for k, li in enumerate(poly.loop_indices): layer.data[li].uv = uvs[poly.index][k]
    ob = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(ob)
    return ob

def thicken(ob, c):
    """Split the paper sheets off, give them thickness, join back. Returns the finished object."""
    sheet = {i for i, p in enumerate(c["P"]) if p in SHEETS}
    bm = bmesh.new(); bm.from_mesh(ob.data); bm.faces.ensure_lookup_table()
    other = bm.copy(); other.faces.ensure_lookup_table()
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.index not in sheet], context="FACES")
    bmesh.ops.delete(other, geom=[f for f in other.faces if f.index in sheet], context="FACES")
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me2 = bpy.data.meshes.new(ob.name + "-sheet"); bm.to_mesh(me2); other.to_mesh(ob.data)
    sh = bpy.data.objects.new(ob.name + "-sheet", me2); bpy.context.scene.collection.objects.link(sh)
    mod = sh.modifiers.new("Paper", "SOLIDIFY"); mod.thickness = 0.045 * c["s"]; mod.offset = 0; mod.use_rim = True
    for o in bpy.data.objects: o.select_set(o in (ob, sh))
    bpy.context.view_layer.objects.active = sh; bpy.ops.object.modifier_apply(modifier="Paper")
    bpy.context.view_layer.objects.active = ob; bpy.ops.object.join()
    bpy.ops.object.mode_set(mode="EDIT"); bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.quads_convert_to_tris(); bpy.ops.object.mode_set(mode="OBJECT")
    for p in ob.data.polygons: p.use_smooth = False
    return ob

def unwrap(ob):
    for o in bpy.data.objects: o.select_set(o is ob)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.mode_set(mode="EDIT"); bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(12), island_margin=0.012, area_weight=0.0, correct_aspect=True)
    bpy.ops.object.mode_set(mode="OBJECT")
    layer = ob.data.uv_layers.active
    return [[tuple(layer.data[li].uv) for li in p.loop_indices] for p in ob.data.polygons]

# ---------------------------------------------------------------- the pictures
BLUE = np.array((0.075, 0.15, 0.6)); BLUE2 = np.array((0.12, 0.25, 0.78)); INK = np.array((0.72, 0.76, 0.85))
FOIL = np.array((0.8, 0.83, 0.9)); PETAL = np.array((0.62, 0.68, 0.84)); DEEP = np.array((0.07, 0.11, 0.42))

def smooth(x, a, b): t = np.clip((x - a) / (b - a), 0, 1); return t * t * (3 - 2 * t)
def line(d, w): return smooth(-d, -w, -w * 0.45)   # 1 on a line of half-width w, soft edge

def seigaiha(u, v, rc, w):
    """Silver wave scales: rows rc/2 apart, each row's circles 2rc apart; lower rows drawn over upper ones."""
    dy, hit, dist = rc / 2, np.zeros(u.shape, bool), np.zeros(u.shape)
    r0 = np.floor((v - rc) / dy)
    for k in range(0, 4):
        r = r0 + k; off = np.mod(r, 2) * rc
        j = np.round((u - off) / (2 * rc)); d = np.hypot(u - (j * 2 * rc + off), v - r * dy)
        new = (~hit) & (d < rc); dist[new] = d[new]; hit |= new
    ring = np.abs(np.mod(dist + rc / 8, rc / 4) - rc / 8)
    return hit * line(ring, w) * (dist > rc * 0.14) + hit * (dist < rc * 0.14)

def blossom(u, v, cu, cv, rf, rot):
    """Five notched petals with a vein each, stamens and a centre: (outline, petal fill, dark detail)."""
    du, dv = u - cu, v - cv; rho = np.hypot(du, dv); th = np.arctan2(dv, du) - rot
    ph = np.abs(np.cos(2.5 * th)); edge = rf * (0.42 + 0.58 * ph ** 0.45) - rf * 0.15 * np.exp(-((1 - ph) / 0.006))
    fill = (rho < edge).astype(float)
    outline = line(np.abs(rho - edge), rf * 0.07)
    between = line(rho * ph / 2.5, rf * 0.03) * (rho > rf * 0.2) * fill        # the gaps between petals
    vein = line(rho * np.abs(np.sin(np.mod(th + np.pi / 5, 2 * np.pi / 5) - np.pi / 5)), rf * 0.022) * (rho > rf * 0.3) * (rho < rf * 0.78) * fill
    stamen = np.zeros_like(rho)
    for a in np.arange(10) * np.pi / 5 + 0.2:
        ex, ey = rf * 0.36 * np.cos(rot + a), rf * 0.36 * np.sin(rot + a)
        stamen = np.maximum(stamen, line(seg_dist(du, dv, np.zeros(2), np.array((ex, ey))), rf * 0.018))
        stamen = np.maximum(stamen, line(np.hypot(du - ex, dv - ey), rf * 0.05))
    dark = np.clip(between + vein * 0.6 + stamen + line(rho, rf * 0.13), 0, 1)
    return outline, fill, dark

def seg_dist(u, v, a, b):
    ab = b - a; t = np.clip(((u - a[0]) * ab[0] + (v - a[1]) * ab[1]) / max(ab @ ab, 1e-9), 0, 1)
    return np.hypot(u - (a[0] + t * ab[0]), v - (a[1] + t * ab[1]))

def noise3(p, freqs, seed):
    rng = np.random.default_rng(seed); out = np.zeros(p.shape[:-1])
    for fq in freqs:
        for _ in range(3):
            d = rng.normal(size=3); d /= np.linalg.norm(d)
            out += np.sin(p @ d * fq + rng.uniform(0, 6.28)) / len(freqs) / 3
    return out

def basis(n):
    """Two directions in a face's own plane (forward-ish first), so its pattern is never stretched."""
    ref = np.array((0, 0, 1.0)) if abs(n[2]) < 0.9 else np.array((1.0, 0, 0))
    e1 = ref - n * (ref @ n); e1 /= np.linalg.norm(e1)
    return e1, np.cross(n, e1)

# the blossom sprig on each wing's back half, in wing coordinates (u out, w back; see crane())
SPRIG = [(1.05, 1.3, 0.86, 0.3), (2.75, 1.15, 0.74, 1.0), (4.15, 0.98, 0.5, 0.1), (1.9, 2.02, 0.36, 0.7), (5.15, 0.95, 0.3, 0.5)]
STEMS = [[(0.0, 1.62), (1.05, 1.3), (2.75, 1.15), (4.15, 0.98), (5.15, 0.95), (6.0, 0.9)], [(1.35, 1.3), (1.9, 2.02)],
         [(3.1, 1.12), (3.45, 1.62)], [(4.4, 0.98), (4.75, 1.3)], [(2.1, 1.2), (2.3, 0.62)]]
BUDS = [(3.45, 1.62), (4.75, 1.3), (2.3, 0.62), (6.0, 0.9)]

def shade(P3, n, part, d, c, fi):
    """Colour, roughness, height and metal for points P3 (rest pose) on a face with normal n; d = distance to its folds."""
    s = c["s"]; e1, e2 = basis(n)
    mott = noise3(P3 / s, (0.6, 1.3, 2.9), 3); grain = noise3(P3 / s, (23.0, 41.0), 5)
    tone = 0.5 + 0.5 * mott + (((fi * 7919) % 13) / 13 - 0.5) * 0.35 + (0.35 if part in ("flap", "wflap") else 0)
    col = lerp(BLUE, BLUE2, np.clip(tone, 0, 1)[..., None]) * (1 + 0.05 * grain)[..., None]
    ink = np.zeros(P3.shape[:-1]); fill = np.zeros_like(ink); dark = np.zeros_like(ink)
    if part == "wing":
        pn = c["panels"][1 if P3[..., 0].mean() > 0 else -1]; q = P3 - pn["o"]
        u, w = (q @ pn["eu"]) / pn["ks"], (q @ pn["ew"]) / pn["ks"]
        front = smooth(-0.3 + u * (SW + 0.3) / R0 - w, 0.05, 0.3)        # ahead of the wing's fold line: waves
        ink = seigaiha(w, -u, 1.05, 0.045) * 0.75 * front
        br = np.full(ink.shape, 1e9)
        for st in STEMS:
            for a, b in zip(st, st[1:]): br = np.minimum(br, seg_dist(u, w, np.array(a), np.array(b)))
        ink = np.maximum(ink, line(br, 0.055))
        for bu, bw_ in BUDS: ink = np.maximum(ink, line(np.hypot(u - bu, w - bw_), 0.13))
        for fu, fw, rf, rot in SPRIG:
            ln, fl, dk = blossom(u, w, fu, fw, rf, rot)
            ink = np.where(fl > 0, ln, np.maximum(ink, ln)); fill = np.maximum(fill, fl); dark = np.where(fl > 0, dk, dark)
    elif part in ("body", "flap", "wflap"):
        u2, v2 = P3 @ e1 / s, P3 @ e2 / s
        patch = smooth(noise3(P3 / s, (0.55, 0.9), 11) + (0.25 if part == "body" else -0.05), -0.08, 0.12)
        ink = seigaiha(u2, v2, 1.05, 0.045) * 0.75 * patch
    else:
        u2, v2 = P3 @ e1, P3 @ e2
        for q, rf, rot in c["small"]:
            ln, fl, dk = blossom(u2, v2, q @ e1, q @ e2, rf, rot)
            ink = np.maximum(ink, ln); fill = np.maximum(fill, fl); dark = np.maximum(dark, dk * fl)
        if part == "head":   # silver beak tip
            ink = np.maximum(ink, smooth(-np.linalg.norm(P3 - c["V"][c["beak"]], axis=-1), -1.0 * s, -0.75 * s))
    col = lerp(col, PETAL * (1 + 0.06 * mott)[..., None], fill[..., None])
    col = lerp(col, DEEP, (dark * fill)[..., None] * 0.85)
    col = lerp(col, INK, ink[..., None])
    foil = line(d, 0.045 * s); shadow = smooth(-d, -0.2 * s, -0.045 * s) * (1 - foil)
    col = col * (1 - 0.22 * shadow[..., None])
    col = lerp(col, FOIL, foil[..., None])
    metal = np.clip(np.maximum(np.maximum(ink, fill * (1 - dark)), foil), 0, 1)
    rough = 0.6 - 0.3 * metal + 0.05 * grain
    height = 0.4 * ink + 0.22 * fill - 0.15 * dark * fill + 0.4 * foil - 0.45 * smooth(-d, -0.1 * s, 0) + 0.07 * grain + 0.04 * mott
    return col, rough, height, metal

def paint(c, uvs):
    V, F = c["V"], c["F"]
    col = np.zeros((TEX, TEX, 3)); rough = np.zeros((TEX, TEX)); height = np.zeros((TEX, TEX)); metal = np.zeros((TEX, TEX))
    done = np.zeros((TEX, TEX), bool)
    # fold edges: shared by two faces at an angle, or the paper's outer edge
    normals = []
    for ids in F:
        a, b, d = V[list(ids)]; n = np.cross(b - a, d - a); normals.append(n / np.linalg.norm(n))
    edges = {}
    for i, ids in enumerate(F):
        for k in range(3): edges.setdefault(frozenset((ids[(k + 1) % 3], ids[(k + 2) % 3])), []).append(i)
    def fold(i, k):
        fs = edges[frozenset((F[i][(k + 1) % 3], F[i][(k + 2) % 3]))]
        if len(fs) == 1: return True
        return any(np.degrees(np.arccos(np.clip(abs(normals[i] @ normals[j]), -1, 1))) > 1.5 for j in fs if j != i)
    for i, ids in enumerate(F):
        p = V[list(ids)]; uv = np.array(uvs[i]) * TEX
        x0, y0 = np.maximum(np.floor(uv.min(0) - 2).astype(int), 0); x1, y1 = np.minimum(np.ceil(uv.max(0) + 2).astype(int), TEX)
        xs, ys = np.meshgrid(np.arange(x0, x1) + 0.5, np.arange(y0, y1) + 0.5)
        a, b, d = uv; den = (b[1] - d[1]) * (a[0] - d[0]) + (d[0] - b[0]) * (a[1] - d[1])
        if abs(den) < 1e-9: continue
        l0 = ((b[1] - d[1]) * (xs - d[0]) + (d[0] - b[0]) * (ys - d[1])) / den
        l1 = ((d[1] - a[1]) * (xs - d[0]) + (a[0] - d[0]) * (ys - d[1])) / den
        L = np.stack([l0, l1, 1 - l0 - l1], -1)
        hpx = [abs(den) / max(np.linalg.norm(uv[(k + 2) % 3] - uv[(k + 1) % 3]), 1e-9) for k in range(3)]
        inside = np.all(L >= -np.array([1.5 / h for h in hpx]), -1)
        if not inside.any(): continue
        P3 = L @ p
        a3 = np.linalg.norm(np.cross(p[1] - p[0], p[2] - p[0]))
        dist = np.full(l0.shape, 1e9)
        for k in range(3):
            if fold(i, k): dist = np.minimum(dist, np.maximum(L[..., k], 0) * a3 / np.linalg.norm(p[(k + 2) % 3] - p[(k + 1) % 3]))
        part = c["P"][i]; part = {"neck1": "neck", "neck2": "neck", "tail1": "tail", "tail2": "tail"}.get(part, part)
        cc, rr, hh, mm = shade(P3, normals[i], part, dist, c, i)
        sl = (slice(y0, y1), slice(x0, x1)); m = inside & ~done[sl]
        col[sl][m] = cc[m]; rough[sl][m] = rr[m]; height[sl][m] = hh[m]; metal[sl][m] = mm[m]; done[sl] |= inside
    # a short bleed of each island's paint, then plain blue paper between islands (no black gaps: lessons, uploads)
    for _ in range(4):
        acc = np.zeros_like(col); accr = np.zeros_like(rough); acch = np.zeros_like(height); accm = np.zeros_like(metal); cnt = np.zeros_like(rough)
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            sd = np.roll(done, (dy, dx), (0, 1)).astype(float)
            acc += np.roll(col, (dy, dx), (0, 1)) * sd[..., None]; accr += np.roll(rough, (dy, dx), (0, 1)) * sd
            acch += np.roll(height, (dy, dx), (0, 1)) * sd; accm += np.roll(metal, (dy, dx), (0, 1)) * sd; cnt += sd
        grow = (~done) & (cnt > 0)
        col[grow] = acc[grow] / cnt[grow, None]; rough[grow] = accr[grow] / cnt[grow]; height[grow] = acch[grow] / cnt[grow]
        metal[grow] = accm[grow] / cnt[grow]; done |= grow
    col[~done] = lerp(BLUE, BLUE2, 0.5); rough[~done] = 0.6
    gy, gx = np.gradient(height); k = 6.0
    nrm = np.stack([-gx * k, -gy * k, np.ones_like(gx)], -1); nrm /= np.linalg.norm(nrm, axis=-1, keepdims=True)
    return dict(color=np.clip(col, 0, 1), roughness=np.clip(rough, 0.05, 1), normal=nrm * 0.5 + 0.5, metalness=np.clip(metal, 0, 1))

def save_png(arr, name, srgb):
    img = bpy.data.images.new(name, TEX, TEX, alpha=False)
    img.colorspace_settings.name = "sRGB" if srgb else "Non-Color"
    rgba = np.ones((TEX, TEX, 4)); rgba[..., :3] = arr if arr.ndim == 3 else arr[..., None]
    img.pixels.foreach_set(rgba.astype(np.float32).ravel())
    path = os.path.join(OUT, name + ".png"); img.filepath_raw = path; img.file_format = "PNG"; img.save()
    return path

def crane_material(paths):
    m = bpy.data.materials.new("Crane"); m.use_nodes = True; nt = m.node_tree; b = nt.nodes["Principled BSDF"]
    def tex(path, nc):
        t = nt.nodes.new("ShaderNodeTexImage"); t.image = bpy.data.images.load(path, check_existing=True)
        if nc: t.image.colorspace_settings.name = "Non-Color"
        return t
    nt.links.new(tex(paths["color"], False).outputs["Color"], b.inputs["Base Color"])
    nt.links.new(tex(paths["roughness"], True).outputs["Color"], b.inputs["Roughness"])
    nt.links.new(tex(paths["metalness"], True).outputs["Color"], b.inputs["Metallic"])
    nm = nt.nodes.new("ShaderNodeNormalMap"); nt.links.new(tex(paths["normal"], True).outputs["Color"], nm.inputs["Color"])
    nt.links.new(nm.outputs["Normal"], b.inputs["Normal"])
    return m

def hang_guns(plane, c):
    """Mythical rule (Alan, 2026-11-13): guns hang under the skin so they never hide it. Each gun keeps its spot
    seen from above (moved only if that spot is not under the wing), rolls with the wing and hangs by its top."""
    moves = {}
    for slot, group in plane["guns"].items():
        pts = np.concatenate([w for _, w in group]); lo, hi = pts.min(0), pts.max(0)
        top = np.array(((lo[0] + hi[0]) / 2, hi[1], (lo[2] + hi[2]) / 2))
        x, y, z = wing_under(c, top[0], top[2]); roll = math.copysign(RISE, x)
        cs, sn = math.cos(roll), math.sin(roll)
        for ob, _ in group:
            for vert in ob.data.vertices:   # Blender: x right, y forward, z up
                rx, rz = vert.co.x - plane["dx"] - top[0], vert.co.z - top[1]
                vert.co.x = plane["dx"] + x + rx * cs - rz * sn; vert.co.z = y + rx * sn + rz * cs; vert.co.y += -(z - top[2])
        moves[slot] = [round(float(a), 2) for a in (x - top[0], y - top[1], z - top[2])]
    return moves

# ---------------------------------------------------------------- run
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
HITBOX = material("Hitbox", (0.9, 0.12, 0.1), alpha=0.55)
planes = {name: build_plane(lo, i * GAP) for i, (name, lo) in enumerate(BUILDS.items())}

rest = orient(crane(planes["starter"]["o"])); rest["beak"] = rest["J"].index("Beak")
rest_ob = crane_object(rest, "CraneRest", -GAP * 2)
uvs = unwrap(rest_ob)
maps = paint(rest, uvs)
paths = {k: save_png(a, "crane-" + k, k == "color") for k, a in maps.items()}
mat = crane_material(paths)
report = {"joints": sorted(set(rest["J"])), "builds": {}}
cranes, fits = {}, {}
for i, name in enumerate(BUILDS):
    c = crane(planes[name]["o"]); c["F"] = rest["F"]  # same faces as the rest pose, only the joints move
    ob = thicken(crane_object(c, "Crane-" + name, i * GAP, uvs), c)
    ob.data.materials.append(mat); cranes[name] = ob; fits[name] = c
    report["builds"][name] = dict(triangles=len(ob.data.polygons), scale=round(c["s"], 3), wing_size=round(c["ks"] / c["s"], 2),
                                  guns_moved=hang_guns(planes[name], c),
                                  outline={k: round(float(v), 2) for k, v in planes[name]["o"].items()})
bpy.data.objects.remove(rest_ob)
rest_final = thicken(crane_object(rest, "CraneRestPose", -GAP * 2, uvs), rest); rest_final.data.materials.append(mat)
rest_final.hide_render = True
report["triangles"] = len(rest_final.data.polygons)
json.dump(report, open(os.path.join(OUT, "crane-report.json"), "w"), indent=1)
print("TRIANGLES", report["triangles"])
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, "crane.blend"))

if RENDER:
    world = bpy.data.worlds.new("Sky"); scene.world = world; world.use_nodes = True; wn = world.node_tree
    tc = wn.nodes.new("ShaderNodeTexCoord"); sep = wn.nodes.new("ShaderNodeSeparateXYZ"); ramp = wn.nodes.new("ShaderNodeValToRGB")
    wn.links.new(tc.outputs["Generated"], sep.inputs[0]); wn.links.new(sep.outputs["Z"], ramp.inputs[0])
    ramp.color_ramp.elements[0].position = 0.0; ramp.color_ramp.elements[0].color = (0.56, 0.7, 0.86, 1)
    ramp.color_ramp.elements[1].position = 0.7; ramp.color_ramp.elements[1].color = (0.25, 0.45, 0.82, 1)
    wn.links.new(ramp.outputs["Color"], wn.nodes["Background"].inputs["Color"])
    wn.nodes["Background"].inputs["Strength"].default_value = 0.9
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN")); scene.collection.objects.link(sun)
    sun.data.energy = 3.0; sun.data.angle = math.radians(3); sun.rotation_euler = (math.radians(42), math.radians(-14), math.radians(40))
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); scene.collection.objects.link(cam); scene.camera = cam
    target = bpy.data.objects.new("T", None); scene.collection.objects.link(target)
    con = cam.constraints.new("TRACK_TO"); con.target = target; con.track_axis = "TRACK_NEGATIVE_Z"; con.up_axis = "UP_Y"
    scene.render.engine = "CYCLES"; scene.cycles.device = "CPU"; scene.cycles.samples = 12 if QUICK else 32
    scene.cycles.use_denoising = True
    scene.view_settings.view_transform = "Standard"
    scene.render.resolution_x, scene.render.resolution_y = (960, 540) if QUICK else (1600, 900)
    cam.data.clip_end = 500
    everything = [ob for p in planes.values() for ob in p["real"] + p["extras"]] + list(cranes.values())
    alpha = mat.node_tree.nodes["Principled BSDF"].inputs["Alpha"]
    def shoot(name, vname, loc, at, ortho=None, lens=35, ghost=False):
        for ob in everything:
            mine = ob in planes[name]["real"] + planes[name]["extras"] or ob is cranes[name]
            ob.hide_render = not mine or (ob in planes[name]["real"] and not ghost)
        alpha.default_value = 0.35 if ghost else 1.0
        cam.location, target.location = loc, at
        cam.data.type = "ORTHO" if ortho else "PERSP"
        if ortho: cam.data.ortho_scale = ortho
        else: cam.data.lens = lens
        scene.render.filepath = os.path.join(OUT, f"{name}-{vname}.png"); bpy.ops.render.render(write_still=True)
    for i, name in enumerate([] if SCENE_ONLY else BUILDS):
        o, c = planes[name]["o"], fits[name]; L = o["zT"] - o["zN"]; span = 2 * abs(c["V"][c["J"].index("WingTipR")][0])
        E = max(L, span); c3 = Vector((i * GAP, -(o["zN"] + o["zT"]) / 2, o["wy"] + 0.08 * L))
        head = to_bl(c["head"], i * GAP); wing = to_bl(c["panels"][-1]["o"] + c["panels"][-1]["eu"] * 2.6 * c["ks"], i * GAP)
        shoot(name, "concept-angle", c3 + Vector((-0.8, 0.95, -0.2)) * E * 1.05, c3, lens=38)
        shoot(name, "behind", c3 + Vector((0.3, -1.3, 0.45)) * E, c3)
        shoot(name, "side", c3 + Vector((-60, 0, 0)), c3, ortho=L * 1.15)
        shoot(name, "top", c3 + Vector((0, 0, 60)), c3 + Vector((0, 0.01, 0)), ortho=max(L * 16 / 9, span) * 1.08)
        shoot(name, "close-head", head + Vector((-0.4, 0.16, 0.1)) * L, head + Vector((0, -0.05, -0.03)) * L, lens=50)
        shoot(name, "close-wing", wing + Vector((-0.28, 0.3, 0.32)) * L, wing, lens=50)
        shoot(name, "hitbox-top", c3 + Vector((0, 0, 60)), c3 + Vector((0, 0.01, 0)), ortho=max(L * 16 / 9, span) * 1.08, ghost=True)
        if not QUICK: shoot(name, "hitbox-behind", c3 + Vector((0.3, -1.3, 0.45)) * E, c3, ghost=True)
    # in the town (mock-up): transparent renders in warm classroom light, put over an in-game picture afterwards
    wn.nodes["Background"].inputs["Strength"].default_value = 0.75
    ramp.color_ramp.elements[0].color = (0.95, 0.86, 0.7, 1); ramp.color_ramp.elements[1].color = (0.9, 0.84, 0.72, 1)
    sun.data.color = (1, 0.93, 0.82); scene.render.film_transparent = True
    for name, vname, off, look in (("starter", "scene-chase", (0.0, -2.1, 0.75), (0, 0.15, 0.1)), ("swept", "scene-bot", (-1.6, 1.1, 0.2), (0, 0, 0))):
        o = planes[name]["o"]; L = o["zT"] - o["zN"]
        c3 = Vector((list(BUILDS).index(name) * GAP, -(o["zN"] + o["zT"]) / 2, o["wy"]))
        for ob in everything: ob.hide_render = not (ob in planes[name]["extras"] or ob is cranes[name])
        alpha.default_value = 1.0; cam.data.type = "PERSP"; cam.data.lens = 40
        cam.location, target.location = c3 + Vector(off) * L, c3 + Vector(look) * L
        scene.render.filepath = os.path.join(OUT, f"{vname}.png"); bpy.ops.render.render(write_still=True)
print("done")
