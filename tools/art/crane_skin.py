"""Origami Crane, the first Mythical skin (Alan's pick, 2026-11-13; concept .planning/skins/concepts/crane-2.png).
Builds the crane, paints its pictures, fits it to real planes the way the game will, and renders previews. Blender:

    D:/Blender/blender.exe -b --factory-startup --python tools/art/crane_skin.py -- OUTDIR [--quick] [--no-render] [--scene-only]

How it fits any plane (docs/plan/SKINS-PLAN.md "Mythical: a whole new shape"): every corner of the crane belongs to
one joint (JOINTS below; a Bone each in Roblox). The crane is scaled evenly to the plane's length (s = length / 16), and
each joint is placed from the real plane: the beak on the nose tip, the tail tip over the real tail's top back corner,
the wing roots on the body, the shoulders on the real leading edge, the wingtips just past the real wingtips, the body
sides and keel on the real body's sides and bottom. Head, neck and tail cross-sections keep their size (they scale
with s only). The wings sit at the real wing's height so guns on or under the wing still touch it.
Pictures: one 1024 set (colour, normal, roughness), painted from the crane's own 3D shape: deep blue paper, silver
foil on every fold edge, silver seigaiha waves near the body and cherry blossom sprigs on the wings (no white areas).
Writes into OUTDIR: crane-color/normal/roughness.png, crane.blend (rest pose), renders, crane-report.json.
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
    real, extras = [], []
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
            else:  # booster: blue team paper, dark card, yellow tape (Aircraft.paint)
                tint = {"paper": (0.066, 0.216, 0.672), "cardboard": (0.026, 0.1, 0.4), "tape": (1, 0.66, 0.007)}.get(kind)
                m = material("B-" + p["name"], image=os.path.join(pa.PLANES, "paper-set", p["name"] + "-color.png"), tint=tint)
            obj.data.materials.append(m); extras.append(obj)
    pts = {k: np.concatenate(v) for k, v in pts.items()}
    return real, extras, outline(pts, info)

def outline(pts, info):
    """The plane's points the crane's joints move to (Roblox frame)."""
    nose, tail, body, wings = pts["nose"], pts["tail"], pts["body"], pts["wings"]
    zN = nose[:, 2].min(); tip = nose[nose[:, 2] < zN + 0.6]
    side = wings[wings[:, 0] > 0]; ax = np.abs(side[:, 0])
    xo, xi = ax.max(), ax.min()
    outer, inner = side[ax > xo - 0.6], side[ax < xi + 0.6]
    return dict(zN=zN, yN=tip[:, 1].mean(), zT=tail[:, 2].max(), yT=tail[:, 1].max(),
                bw=np.abs(body[:, 0]).max(), by0=body[:, 1].min(), by1=body[:, 1].max(),
                wy=float(np.median(wings[:, 1])), xo=xo, xi=xi,
                LO=outer[:, 2].min(), TO=outer[:, 2].max(), LI=inner[:, 2].min(), TI=inner[:, 2].max(),
                fold=info["mounts"][1][0] + 0.9 * info["factor"],  # the outer gun spot plus room for a gun
                boost_y=info["booster"][0], boost_z=info["booster"][2])

# ---------------------------------------------------------------- the crane
FOLD_UP = math.radians(50)  # the wingtips fold up past the outer gun spot, and reach at least 2.6 s out

def crane(o):
    """Crane corners (Roblox frame) placed from the plane outline `o`: faces, part per face, joint per corner."""
    s = (o["zT"] - o["zN"]) / 16.0
    V, F, P, J = [], [], [], []
    def v(p, joint): V.append(np.array(p, float)); J.append(joint); return len(V) - 1
    def f(part, *ids): F.append(ids); P.append(part)
    wy = o["wy"]; cw = max(0.6 * s, 0.95 * o["bw"])
    lead = lambda x: o["LI"] + (o["LO"] - o["LI"]) * (x - o["xi"]) / max(o["xo"] - o["xi"], 1e-6)
    trail = lambda x: o["TI"] + (o["TO"] - o["TI"]) * (x - o["xi"]) / max(o["xo"] - o["xi"], 1e-6)
    zf, zb = o["LI"], o["TI"]; zm = zf + 0.42 * (zb - zf)
    up = np.array((0, 1.0, 0))
    # body: a diamond seen from above with a raised back and a keel on the real body's bottom
    Fr = v((0, wy - 0.1 * s, zf - 0.5 * s), "BodyFront"); Bk = v((0, wy, zb + 0.4 * s), "BodyBack")
    Pk = v((0, max(wy + 0.95 * s, o["by1"]), zm + 0.3 * s), "Back")
    # the keel is a ridge on the real body's bottom, reaching back over the booster spot so a booster hangs from it
    kb = max(zm + 0.25 * (zb - zf), o["boost_z"]); ky = min(o["by0"], o["boost_y"])
    K1 = v((0, ky, zm - 0.1 * (zb - zf)), "Keel"); K2 = v((0, ky, kb), "KeelBack")
    Ms, Qs = {}, {}
    for sx in (-1, 1):
        Ms[sx] = v((sx * cw, wy, zm), "BodySide" + "LR"[sx > 0])
        Qs[sx] = v((sx * cw * 0.6, (wy + ky) / 2, zm), "BodySide" + "LR"[sx > 0])
        M, Q = Ms[sx], Qs[sx]
        f("body", Fr, M, Pk); f("body", Pk, M, Bk); f("body", Fr, Q, M); f("body", M, Q, Bk)
        f("body", Fr, K1, Q); f("body", Q, K1, K2); f("body", Q, K2, Bk)
    # neck: a thin three-sided point rising forward from inside the body's front to the head
    n0 = [v((0, wy + 0.1 * s, zf + 0.2 * s), "BodyFront"), v((-0.28 * s, wy - 0.55 * s, zf + 0.5 * s), "BodyFront"),
          v((0.28 * s, wy - 0.55 * s, zf + 0.5 * s), "BodyFront")]
    H = np.array((0, wy + 1.5 * s, o["zN"] + 1.5 * s))
    n1 = [v(H + (0, 0.2 * s, 0), "Head"), v(H + (-0.1 * s, -0.12 * s, 0.05 * s), "Head"), v(H + (0.1 * s, -0.12 * s, 0.05 * s), "Head")]
    for a, b in ((0, 1), (2, 0), (1, 2)):
        f("neck", n0[a], n0[b], n1[b]); f("neck", n0[a], n1[b], n1[a])
    # head: the inside-reverse fold, a crest then a beak pointing forward and down, level with the nose tip
    Ht = v(H + (0, 0.45 * s, -0.3 * s), "Head"); Bq = v((0, H[1] - 0.75 * s, o["zN"]), "Beak")
    f("head", n1[0], n1[1], Ht); f("head", n1[0], Ht, n1[2]); f("head", Ht, n1[1], Bq); f("head", n1[2], Ht, Bq); f("head", n1[1], n1[2], Bq)
    # tail: a thin point rising from inside the body's back to over the real tail's top back corner
    t0 = [v((0, wy + 0.1 * s, zb - 0.2 * s), "BodyBack"), v((-0.22 * s, wy - 0.6 * s, zb - 0.6 * s), "BodyBack"),
          v((0.22 * s, wy - 0.6 * s, zb - 0.6 * s), "BodyBack")]
    Tt = v((0, max(o["yT"], wy + 1.2 * s) + 0.15 * s, o["zT"] + 0.2 * s), "TailTip")
    f("tail", t0[0], t0[1], Tt); f("tail", t0[2], t0[0], Tt); f("tail", t0[1], t0[2], Tt)
    # wings: root on the body, flat at the real wing's height out past the outer gun spot (guns on or under the
    # wing still touch it), then the tip folds up. One raised crease runs from the body to the fold.
    top, side_fl, stems = [], [], []
    for sx in (-1, 1):
        LR = "LR"[sx > 0]; M = Ms[sx]
        xf = min(max(o["fold"], cw + 0.4 * (o["xo"] - cw)), o["xo"] - 0.3 * s)
        xm = cw + 0.5 * (xf - cw)
        Wf = v(lerp(V[Fr], V[M], 0.4), "WingRootFront" + LR); Wb = v(lerp(V[M], V[Bk], 0.65), "WingRootBack" + LR)
        Mw = v(V[M] + (0, 0.02 * s, 0), "BodySide" + LR)
        S = v((sx * xm, wy + 0.03 * s, lead(xm) - 0.1 * s), "Shoulder" + LR)
        R = v((sx * xm, wy - 0.02 * s, trail(xm) + 0.05 * s), "WingBack" + LR)
        Fl = v((sx * xf, wy, lead(xf) - 0.05 * s), "FoldFront" + LR); Ft = v((sx * xf, wy, trail(xf)), "FoldBack" + LR)
        Fm = v(lerp(V[Fl], V[Ft], 0.45), "FoldFront" + LR)
        reach = max(o["xo"] + 0.3 * s - xf, 2.6 * s)
        T = v((sx * (xf + reach * math.cos(FOLD_UP)), wy + reach * math.sin(FOLD_UP), lerp(o["LO"], o["TO"], 0.6)), "WingTip" + LR)
        C = v(lerp(V[Mw], V[Fm], 0.5) + up * 0.14 * s, "Crease" + LR)
        f("wing", Mw, C, S); f("wing", Mw, S, Wf); f("wing", C, Fl, S); f("wing", C, Fm, Fl)
        f("wing", Mw, Wb, R); f("wing", Mw, R, C); f("wing", C, R, Ft); f("wing", C, Ft, Fm)
        f("wing", Fl, Fm, T); f("wing", Fm, Ft, T)
        # a second paper layer on the wing root (the folded flap of a real crane)
        nrm = np.cross(V[S] - V[Mw], V[Wf] - V[Mw]); nrm = nrm / np.linalg.norm(nrm) * (1 if nrm[1] > 0 else -1)
        a = v(V[Wf] + nrm * 0.04 * s, "WingRootFront" + LR); b = v(lerp(V[Wf], V[S], 0.75) + nrm * 0.04 * s, "Shoulder" + LR)
        c = v(lerp(V[Mw], V[S], 0.5) + nrm * 0.04 * s, "Shoulder" + LR)
        f("flap", a, b, c)
        # cherry blossom sprig on the wing (painted, top view): along the crease, towards the fold
        Mp, Fp, Sp, Rp = V[Mw], V[Fm], V[S], V[R]; across = (Sp - Rp) / max(np.linalg.norm(Sp - Rp), 1e-6) * s
        pts = [lerp(Mp, Fp, 0.6) + across * 0.55, lerp(Mp, Fp, 0.8) - across * 0.35, lerp(Mp, Fp, 0.98) + across * 0.25]
        top += [(q, r * s, 0.7 * k + (0.3 if sx > 0 else 1.1)) for k, (q, r) in enumerate(zip(pts, (0.62, 0.78, 0.5)))]
        stems.append([lerp(Mp, Fp, 0.42) - across * 0.15] + pts + [lerp(V[Fm], V[T], 0.5)])
    # small blossoms on the body sides, the tail and the neck (side view)
    side_fl += [(np.array((0, (wy + ky) / 2 + 0.1 * s, zm - 0.45 * s)), 0.42 * s, 0.4), (lerp(V[t0[0]], V[Tt], 0.55), 0.2 * s, 1.0),
                (lerp(V[n0[0]], H, 0.55), 0.18 * s, 0.2)]
    return dict(V=np.array(V), F=F, P=P, J=J, s=s, cw=cw, fold=xf, top=top, side=side_fl, stems=stems)

def orient(c):
    """Outward faces for closed parts, upward for paper sheets (wings, flap)."""
    V, F = c["V"], c["F"]
    groups = {}
    for i, (ids, part) in enumerate(zip(F, c["P"])): groups.setdefault("neckhead" if part in ("neck", "head") else part, []).append(i)
    for part, idx in groups.items():
        cen = V[sorted({j for i in idx for j in F[i]})].mean(0)
        for i in idx:
            a, b, d = V[list(F[i])]; n = np.cross(b - a, d - a); fc = (a + b + d) / 3
            flip = n[1] < 0 if part in ("wing", "flap") else np.dot(n, fc - cen) < 0
            if flip: F[i] = (F[i][0], F[i][2], F[i][1])
    return c

def crane_object(c, name, dx, uvs=None):
    """Mesh object for crane `c` (with loop UVs from the rest pose); wings and flap get real paper thickness."""
    me = bpy.data.meshes.new(name); me.from_pydata([to_bl(p, dx) for p in c["V"]], [], c["F"]); me.update()
    if uvs is not None:
        layer = me.uv_layers.new(name="UVMap")
        for poly in me.polygons:
            for k, li in enumerate(poly.loop_indices): layer.data[li].uv = uvs[poly.index][k]
    ob = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(ob)
    return ob

def thicken(ob, c):
    """Split the paper sheets off, give them thickness, join back. Returns the finished object."""
    sheet = {i for i, p in enumerate(c["P"]) if p in ("wing", "flap")}
    bm = bmesh.new(); bm.from_mesh(ob.data); bm.faces.ensure_lookup_table()
    other = bm.copy(); other.faces.ensure_lookup_table()
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.index not in sheet], context="FACES")
    bmesh.ops.delete(other, geom=[f for f in other.faces if f.index in sheet], context="FACES")
    me2 = bpy.data.meshes.new(ob.name + "-sheet"); bm.to_mesh(me2); other.to_mesh(ob.data)
    sh = bpy.data.objects.new(ob.name + "-sheet", me2); bpy.context.scene.collection.objects.link(sh)
    mod = sh.modifiers.new("Paper", "SOLIDIFY"); mod.thickness = 0.06 * c["s"]; mod.offset = 0; mod.use_rim = True
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
    bpy.ops.uv.smart_project(angle_limit=math.radians(12), island_margin=0.025, area_weight=0.0, correct_aspect=True)
    bpy.ops.object.mode_set(mode="OBJECT")
    layer = ob.data.uv_layers.active
    return [[tuple(layer.data[li].uv) for li in p.loop_indices] for p in ob.data.polygons]

# ---------------------------------------------------------------- the pictures
BLUE = np.array((0.09, 0.15, 0.56)); INK = np.array((0.69, 0.74, 0.83)); FOIL = np.array((0.77, 0.81, 0.89))
PETAL = np.array((0.42, 0.5, 0.76)); DEEP = np.array((0.09, 0.14, 0.45))

def smooth(x, a, b): t = np.clip((x - a) / (b - a), 0, 1); return t * t * (3 - 2 * t)

def seigaiha(u, v, rc, w):
    """Silver wave scales: rows rc/2 apart, each row's circles 2rc apart; lower rows drawn over upper ones."""
    dy, hit, dist = rc / 2, np.zeros(u.shape, bool), np.zeros(u.shape)
    r0 = np.floor((v - rc) / dy)
    for k in range(0, 4):
        r = r0 + k; off = np.mod(r, 2) * rc
        j = np.round((u - off) / (2 * rc)); d = np.hypot(u - (j * 2 * rc + off), v - r * dy)
        new = (~hit) & (d < rc); dist[new] = d[new]; hit |= new
    ring = np.abs(np.mod(dist + rc / 8, rc / 4) - rc / 8)
    return hit * smooth(-ring, -w, -w * 0.4) * (dist > rc * 0.12) + hit * (dist < rc * 0.12)

def blossom(u, v, cu, cv, rf, rot, w):
    """Five-petal cherry blossom: returns (outline ink, petal fill, centre)."""
    du, dv = u - cu, v - cv; rho = np.hypot(du, dv); th = np.arctan2(dv, du) - rot
    ph = np.abs(np.cos(2.5 * th)); edge = rf * (0.5 + 0.5 * ph ** 0.5) - rf * 0.16 * np.exp(-((1 - ph) / 0.004))
    line = smooth(-np.abs(rho - edge), -w, -w * 0.4)
    fill = (rho < edge).astype(float)
    centre = smooth(-rho, -rf * 0.16, -rf * 0.1) + sum(smooth(-np.hypot(du - rf * 0.32 * np.cos(rot + a), dv - rf * 0.32 * np.sin(rot + a)), -rf * 0.06, -rf * 0.03)
                                                     for a in np.arange(5) * 2 * np.pi / 5 + np.pi / 5)
    return line, fill, np.clip(centre, 0, 1)

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

def shade(P3, n, part, d, c):
    """Colour, roughness, height for points P3 (rest pose) on a face with normal n; d = distance to its folds."""
    s = c["s"]; topview = abs(n[1]) > 0.6
    e1, e2 = basis(n); u2, v2 = P3 @ e1, P3 @ e2
    mott = noise3(P3 / s, (0.7, 1.6, 3.1), 3); grain = noise3(P3 / s, (19.0, 37.0), 5)
    col = BLUE[None, None] * (1 + 0.09 * mott + 0.04 * grain)[..., None]
    ink = np.zeros(P3.shape[:-1]); fill = np.zeros_like(ink); dot = np.zeros_like(ink)
    span = (np.abs(P3[..., 0]) - c["cw"]) / max(c["fold"] - c["cw"], 1e-6)
    if part in ("wing", "body", "flap"):
        waves = seigaiha(u2, v2, 0.62 * s, 0.022 * s) * 0.8
        if part != "body": waves = waves * (1 - smooth(span, 0.3, 0.45))
        ink = np.maximum(ink, waves)
    flowers = []
    if topview and part in ("wing", "flap"):
        flowers = c["top"]
        br = np.full(ink.shape, 1e9)
        for stem in c["stems"]:
            for a, b in zip(stem, stem[1:]): br = np.minimum(br, seg_dist(u2, v2, np.array((a @ e1, a @ e2)), np.array((b @ e1, b @ e2))))
        ink = np.maximum(ink, smooth(-br, -0.05 * s, -0.025 * s))
    elif not topview and part in ("body", "tail", "neck"):
        flowers = c["side"]
    for q, rf, rot in flowers:
        qu, qv = q @ e1, q @ e2
        ln, fl, ct = blossom(u2, v2, qu, qv, rf, rot, 0.04 * s)
        fill = np.maximum(fill, fl * (1 - ln)); ink = np.maximum(ink, ln); dot = np.maximum(dot, ct)
    col = col * (1 - fill[..., None]) + PETAL * fill[..., None]
    col = col * (1 - dot[..., None]) + DEEP * dot[..., None]
    col = col * (1 - ink[..., None]) + INK * ink[..., None]
    foil = smooth(-d, -0.05 * s, -0.03 * s); shadow = smooth(-d, -0.16 * s, -0.05 * s) * (1 - foil)
    col = col * (1 - 0.18 * shadow[..., None])
    col = col * (1 - foil[..., None]) + FOIL * foil[..., None]
    rough = 0.72 - 0.38 * np.maximum(ink, fill * 0.5) - 0.5 * foil + 0.04 * grain
    height = 0.45 * ink + 0.25 * fill + 0.35 * foil - 0.5 * smooth(-d, -0.12 * s, 0) + 0.06 * grain + 0.03 * mott
    return col, rough, height

def paint(c, uvs):
    V, F = c["V"], c["F"]
    col = np.zeros((TEX, TEX, 3)); rough = np.zeros((TEX, TEX)); height = np.zeros((TEX, TEX)); done = np.zeros((TEX, TEX), bool)
    # fold edges: shared by two faces at an angle, or the paper's outer edge
    normals = []
    for ids in F:
        a, b, d = V[list(ids)]; n = np.cross(b - a, d - a); normals.append(n / np.linalg.norm(n))
    edges = {}
    for i, ids in enumerate(F):
        for k in range(3): edges.setdefault(frozenset((ids[(k + 1) % 3], ids[(k + 2) % 3])), []).append(i)
    def fold(i, k):
        e = frozenset((F[i][(k + 1) % 3], F[i][(k + 2) % 3])); fs = edges[e]
        if len(fs) == 1: return True
        return any(np.degrees(np.arccos(np.clip(normals[i] @ normals[j], -1, 1))) > 10 for j in fs if j != i)
    for i, ids in enumerate(F):
        p = V[list(ids)]; uv = np.array(uvs[i]) * TEX
        x0, y0 = np.maximum(np.floor(uv.min(0) - 2).astype(int), 0); x1, y1 = np.minimum(np.ceil(uv.max(0) + 2).astype(int), TEX)
        xs, ys = np.meshgrid(np.arange(x0, x1) + 0.5, np.arange(y0, y1) + 0.5)
        a, b, d = uv; den = (b[1] - d[1]) * (a[0] - d[0]) + (d[0] - b[0]) * (a[1] - d[1])
        if abs(den) < 1e-9: continue
        l0 = ((b[1] - d[1]) * (xs - d[0]) + (d[0] - b[0]) * (ys - d[1])) / den
        l1 = ((d[1] - a[1]) * (xs - d[0]) + (a[0] - d[0]) * (ys - d[1])) / den
        L = np.stack([l0, l1, 1 - l0 - l1], -1)
        area2 = abs(den); hpx = [area2 / max(np.linalg.norm(uv[(k + 2) % 3] - uv[(k + 1) % 3]), 1e-9) for k in range(3)]
        inside = np.all(L >= -np.array([1.5 / h for h in hpx]), -1)
        if not inside.any(): continue
        P3 = L @ p
        a3 = np.linalg.norm(np.cross(p[1] - p[0], p[2] - p[0]))
        dist = np.full(l0.shape, 1e9)
        for k in range(3):
            if fold(i, k): dist = np.minimum(dist, np.maximum(L[..., k], 0) * a3 / np.linalg.norm(p[(k + 2) % 3] - p[(k + 1) % 3]))
        cc, rr, hh = shade(P3, normals[i], c["P"][i], dist, c)
        sl = (slice(y0, y1), slice(x0, x1)); m = inside & ~done[sl]
        col[sl][m] = cc[m]; rough[sl][m] = rr[m]; height[sl][m] = hh[m]; done[sl] |= inside
    # fill the space between islands with the nearest island's paint (no black gaps: lessons, uploads)
    for _ in range(4):
        if done.all(): break
        acc = np.zeros_like(col); accr = np.zeros_like(rough); acch = np.zeros_like(height); cnt = np.zeros_like(rough)
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            sd = np.roll(done, (dy, dx), (0, 1)).astype(float)
            acc += np.roll(col, (dy, dx), (0, 1)) * sd[..., None]; accr += np.roll(rough, (dy, dx), (0, 1)) * sd
            acch += np.roll(height, (dy, dx), (0, 1)) * sd; cnt += sd
        grow = (~done) & (cnt > 0)
        col[grow] = acc[grow] / cnt[grow, None]; rough[grow] = accr[grow] / cnt[grow]; height[grow] = acch[grow] / cnt[grow]; done |= grow
    col[~done] = BLUE; rough[~done] = 0.72
    gy, gx = np.gradient(height); k = 6.0
    nrm = np.stack([-gx * k, -gy * k, np.ones_like(gx)], -1); nrm /= np.linalg.norm(nrm, axis=-1, keepdims=True)
    return np.clip(col, 0, 1), np.clip(rough, 0.05, 1), nrm * 0.5 + 0.5

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
    nm = nt.nodes.new("ShaderNodeNormalMap"); nt.links.new(tex(paths["normal"], True).outputs["Color"], nm.inputs["Color"])
    nt.links.new(nm.outputs["Normal"], b.inputs["Normal"])
    return m

# ---------------------------------------------------------------- run
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
HITBOX = material("Hitbox", (0.9, 0.12, 0.1), alpha=0.55)
planes = {}
for i, (name, lo) in enumerate(BUILDS.items()):
    planes[name] = build_plane(lo, i * GAP)

rest = orient(crane(planes["starter"][2]))
rest_ob = crane_object(rest, "CraneRest", -GAP * 2)
uvs = unwrap(rest_ob)
col, rough, nrm = paint(rest, uvs)
paths = dict(color=save_png(col, "crane-color", True), normal=save_png(nrm, "crane-normal", False),
             roughness=save_png(rough, "crane-roughness", False))
mat = crane_material(paths)
report = {"joints": sorted(set(rest["J"])), "builds": {}}
cranes = {}
for i, name in enumerate(BUILDS):
    c = orient(crane(planes[name][2])); c["F"] = rest["F"]  # same faces as the rest pose, only the joints move
    ob = thicken(crane_object(c, "Crane-" + name, i * GAP, uvs), c)
    ob.data.materials.append(mat); cranes[name] = ob
    report["builds"][name] = dict(triangles=len(ob.data.polygons), scale=round(c["s"], 3),
                                  outline={k: round(float(v), 2) for k, v in planes[name][2].items()})
bpy.data.objects.remove(rest_ob)
rest_final = thicken(crane_object(rest, "CraneRestPose", -GAP * 2, uvs), rest); rest_final.data.materials.append(mat)
rest_final.hide_render = True
report["triangles"] = len(rest_final.data.polygons)
json.dump(report, open(os.path.join(OUT, "crane-report.json"), "w"), indent=1)
print("TRIANGLES", report["triangles"])
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, "crane.blend"))

if RENDER:
    world = bpy.data.worlds.new("Sky"); scene.world = world; world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.5, 0.66, 0.82, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.9
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN")); scene.collection.objects.link(sun)
    sun.data.energy = 3.2; sun.data.angle = math.radians(3); sun.rotation_euler = (math.radians(38), math.radians(-18), math.radians(35))
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); scene.collection.objects.link(cam); scene.camera = cam
    target = bpy.data.objects.new("T", None); scene.collection.objects.link(target)
    con = cam.constraints.new("TRACK_TO"); con.target = target; con.track_axis = "TRACK_NEGATIVE_Z"; con.up_axis = "UP_Y"
    scene.render.engine = "CYCLES"; scene.cycles.device = "CPU"; scene.cycles.samples = 12 if QUICK else 40
    scene.cycles.use_denoising = True
    scene.view_settings.view_transform = "Standard"
    scene.render.resolution_x, scene.render.resolution_y = (960, 540) if QUICK else (1600, 900)
    for i, name in enumerate([] if SCENE_ONLY else BUILDS):
        o = planes[name][2]; L = o["zT"] - o["zN"]; span = 2 * o["xo"]
        cx = i * GAP; c3 = Vector((cx, -(o["zN"] + o["zT"]) / 2, o["wy"]))
        everything = [ob for n2 in BUILDS for ob in planes[n2][0] + planes[n2][1]] + list(cranes.values())
        for ghost in (False, True):
            for ob in everything:
                mine = ob in planes[name][0] + planes[name][1] or ob is cranes[name]
                ob.hide_render = not mine or (ob in planes[name][0] and not ghost)
            cranes[name].color = (1, 1, 1, 1)
            views = {"three-quarter": (c3 + Vector((-0.95, 1.05, 0.62)) * L * 1.05, c3, None, 35),
                     "top": (c3 + Vector((0, 0, 60)), c3 + Vector((0, 0.01, 0)), max(L * 16 / 9, span) * 1.08, None),
                     "side": (c3 + Vector((-60, 0, 0)), c3 + Vector((0, 0, 0.1)) * L, L * 1.15, None),
                     "behind": (c3 + Vector((0.35, -1.25, 0.42)) * L, c3 + Vector((0, 0, 0.3)) * L * 0.1, None, 35),
                     "close-up": (c3 + Vector((-0.42, 0.62, 0.3)) * L, c3 + Vector((0, 0.18, 0.02)) * L, None, 50)}
            if ghost: views = {"top": views["top"]}
            for vname, (loc, at, ortho, lens) in views.items():
                cam.location, target.location = loc, at
                cam.data.type = "ORTHO" if ortho else "PERSP"
                if ortho: cam.data.ortho_scale = ortho
                else: cam.data.lens = lens
                cam.data.clip_end = 500
                if ghost:  # see the red hitbox through the crane
                    mat.node_tree.nodes["Principled BSDF"].inputs["Alpha"].default_value = 0.35
                else:
                    mat.node_tree.nodes["Principled BSDF"].inputs["Alpha"].default_value = 1.0
                scene.render.filepath = os.path.join(OUT, f"{name}-{'hitbox-' if ghost else ''}{vname}.png")
                bpy.ops.render.render(write_still=True)
    # in the town (mock-up): transparent renders in warm classroom light, put over an in-game picture afterwards
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.95, 0.86, 0.7, 1)
    sun.data.color = (1, 0.93, 0.82); scene.render.film_transparent = True
    mat.node_tree.nodes["Principled BSDF"].inputs["Alpha"].default_value = 1.0
    for i, (name, vname, off, look) in enumerate((("starter", "scene-chase", (0.0, -2.1, 0.75), (0, 0.15, 0.1)),
                                                  ("heavy", "scene-bot", (-1.6, 1.1, 0.35), (0, 0, 0)))):
        o = planes[name][2]; L = o["zT"] - o["zN"]; cx = list(BUILDS).index(name) * GAP
        c3 = Vector((cx, -(o["zN"] + o["zT"]) / 2, o["wy"]))
        for ob in [ob for n2 in BUILDS for ob in planes[n2][0] + planes[n2][1]] + list(cranes.values()):
            ob.hide_render = not (ob in planes[name][1] or ob is cranes[name])
        cam.data.type = "PERSP"; cam.data.lens = 40
        cam.location, target.location = c3 + Vector(off) * L, c3 + Vector(look) * L
        scene.render.filepath = os.path.join(OUT, f"{vname}.png"); bpy.ops.render.render(write_still=True)
print("done")
