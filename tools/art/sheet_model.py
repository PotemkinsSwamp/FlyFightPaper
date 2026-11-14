"""Model sheet -> Blender model built from measured pieces (docs/decisions/2026-11-14-shape-skin-model-sheets.md). The
body is a loft through the sheet's outlines (side view: top and bottom, top/bottom views: width); parts that stick out
are tubes (horns) or faceted blades from measured numbers. A piece with a `color` is painted plainly (blades get dark
facet-edge lines) and lit flat, so its facets show like the sheet's plates; a body with `colors` gets scales and an
underside band. Anything without its own colour is painted by projecting the sheet: each spot from ONE view, the SIDE,
TOP, BOTTOM or FRONT view that faces it best and can see it (a depth test per view, so a horn never paints its picture
onto the head under it). That works on smooth bodies with art on their sides (the Shark), not on a crest of blades
(the Dragon: Alan, 2026-11-14, "unusable"). Bumps come from the colours' own lines (dark line = groove) as a normal map;
glow colours (eyes) become an emissive mask.

    python tools/art/sheet_model.py SPEC.json          (runs Blender, then writes the review picture)

SPEC (lengths in units of the skin's whole length: nose tip 0 -> tail tip 1; x along, y across, z up; picture
points in sheet pixels):
  sheet, out (folder), views {side, top, bottom, front, three_quarter: [x0, y0, x1, y1]}, review {view: box}
  (optional tighter crops of the sheet for review.jpg, e.g. just the head),
  body {from, to, stations, sides, round (2 ellipse, 1 diamond, 3+ boxier), mid (0..1, where the widest line sits
        between bottom and top), smooth (bool), top_line [[x, z], ...], width_line [[x, half width], ...]  (where a
        horn, crest, fin or wing joins, the drawn outline is not the body: over the line's span the body follows these
        points instead), crown [a, b]  (over this span two ridges, up and out at 45 degrees, reach the DRAWN outline's
        top (side view) and width (top view): a crest of blades on a head, as a V seen from the front),
        colors {scales, under, under_share, scale}  (optional: see body_paint)},
  parts [{name (unique), color [r, g, b] (optional), mirror (default true), and either
          spine [[x, y, z], ...], radius [r, ...] (one per spine point; or [across, up] pairs), sides   (a tube), or
          kind "blade", base [x, y, z], tip [x, y, z], width, thick, facing [x, y, z] (optional; default: out from
          the head's middle line)}],
  sun, ambient (optional render light strengths, default 1.5 and 1.0: plain-colour pieces want about 3.5 and 0.45),
  glow [[r, g, b, tolerance]] (sheet colours that glow), tex (texture size), camera {yaw, pitch} (three-quarter view,
  degrees: yaw 0 = from the side, 90 = from the front; pitch above level), front_scale (optional px per length),
  paint (optional list of the views to paint from, default all four: leave out one drawn unlike the others).
"""
import json, math, os, subprocess, sys

BLENDER = "D:/Blender/blender.exe"
HERE = os.path.abspath(__file__)

# ------------------------------------------------------------------ plain-Python side: run Blender, then compose
if __name__ == "__main__" and "bpy" not in sys.modules:
    try:
        import bpy  # noqa: F401  (inside Blender the import works and we fall through)
    except ImportError:
        from PIL import Image, ImageDraw, ImageFont
        spec_path = os.path.abspath(sys.argv[1]); spec = json.load(open(spec_path, encoding="utf-8"))
        subprocess.run([BLENDER, "-b", "--factory-startup", "--python", HERE, "--", spec_path], check=True)
        out = spec["out"]; sheet = Image.open(spec["sheet"]).convert("RGB")
        F = ImageFont.truetype("C:/Windows/Fonts/segoeuib.ttf", 30)
        rows = []
        for view in ("three_quarter", "side", "top", "front", "bottom"):
            r = os.path.join(out, "render-%s.png" % view)
            if not os.path.exists(r): continue
            a = sheet.crop(tuple(spec.get("review", {}).get(view, spec["views"][view]))); b = Image.open(r).convert("RGB")
            h = 360; a = a.resize((round(a.width * h / a.height), h)); b = b.resize((round(b.width * h / b.height), h))
            rows.append((view, a, b))
        W = 40 + max(a.width + b.width for _, a, b in rows) + 80; H = sum(420 for _ in rows) + 40
        im = Image.new("RGB", (W, H), (238, 233, 221)); d = ImageDraw.Draw(im); y = 20
        for view, a, b in rows:
            d.text((40, y), "%s: sheet (left), model (right)" % view.replace("_", "-"), font=F, fill=(30, 30, 34))
            im.paste(a, (40, y + 45)); im.paste(b, (40 + a.width + 40, y + 45)); y += 420
        im.save(os.path.join(out, "review.jpg"), quality=92); print(os.path.join(out, "review.jpg"), im.size)
        sys.exit(0)

# ------------------------------------------------------------------ Blender side
import bmesh, bpy
import numpy as np
from mathutils import Vector

spec = json.load(open(sys.argv[sys.argv.index("--") + 1], encoding="utf-8"))
OUT = os.path.abspath(spec["out"]); os.makedirs(OUT, exist_ok=True); TEX = spec.get("tex", 1024)
for o in list(bpy.data.objects): bpy.data.objects.remove(o)        # the factory scene's cube would hide the model

def load_rgb(path):
    img = bpy.data.images.load(os.path.abspath(path)); w, h = img.size
    px = np.empty(w * h * 4, np.float32); img.pixels.foreach_get(px)
    return px.reshape(h, w, 4)[::-1, :, :3].copy()          # rows from the top, sRGB 0..1

SHEET = load_rgb(spec["sheet"])
BG = np.median(np.concatenate([SHEET[:20, :20].reshape(-1, 3), SHEET[:20, -20:].reshape(-1, 3)]), 0)
MASK = np.abs(SHEET - BG).sum(-1) > 0.12

def grow(img, done, steps):
    """Spread colours from the done pixels into their empty neighbours, one pixel per step (in place)."""
    for _ in range(steps):
        acc = np.zeros_like(img); cnt = np.zeros(done.shape)
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            sd = np.roll(done, (dy, dx), (0, 1)); acc += np.roll(img, (dy, dx), (0, 1)) * sd[..., None]; cnt += sd
        g = (~done) & (cnt > 0); img[g] = acc[g] / cnt[g, None]; done |= g

def view_mask(v):
    """The view's outline with its holes filled: background is only what the box edge reaches through
    background-grey pixels (cream bellies and white teeth are close to the grey and would leave holes)."""
    x0, y0, x1, y1 = spec["views"][v]; bgc = ~MASK[y0:y1, x0:x1]; reach = np.zeros_like(bgc)
    for s in (np.s_[0, :], np.s_[-1, :], np.s_[:, 0], np.s_[:, -1]): reach[s] = bgc[s]
    while True:
        g = reach.copy(); g[1:] |= reach[:-1]; g[:-1] |= reach[1:]; g[:, 1:] |= reach[:, :-1]; g[:, :-1] |= reach[:, 1:]
        g &= bgc
        if (g == reach).all(): break
        reach = g
    m = np.zeros_like(MASK); m[y0:y1, x0:x1] = ~reach; return m

VM = {v: view_mask(v) for v in ("side", "top", "bottom", "front")}
SB = SHEET.copy(); inside = np.logical_or.reduce(list(VM.values()))
for _ in range(3):                 # skip the thin white halo the sheets draw round every shape
    inside = inside & np.roll(inside, 1, 0) & np.roll(inside, -1, 0) & np.roll(inside, 1, 1) & np.roll(inside, -1, 1)
grow(SB, inside, 16)               # colours run past each outline: a model edge a pixel out never gets grey or halo

# ---- each view's frame: nose tip and length in pixels from the outline (side, top, bottom); front by height
FR = {}
for v in ("side", "top", "bottom"):
    m = VM[v]; ys, xs = np.nonzero(m)
    nose_x, tail_x = xs.min(), xs.max(); nose_y = ys[xs <= nose_x + 2].mean()
    FR[v] = dict(x=float(nose_x), y=float(nose_y), L=float(tail_x - nose_x), m=m)
mside = FR["side"]["m"]; ys, xs = np.nonzero(mside)
Z_MAX = (FR["side"]["y"] - ys.min()) / FR["side"]["L"]; Z_MIN = (FR["side"]["y"] - ys.max()) / FR["side"]["L"]
mf = VM["front"]; ys, xs = np.nonzero(mf)
SF = spec.get("front_scale") or (ys.max() - ys.min()) / (Z_MAX - Z_MIN)
FR["front"] = dict(x=(xs.min() + xs.max()) / 2.0, y=ys.max() + Z_MIN * SF, L=SF, m=mf)

def to_pic(v, P):
    """Model points (n, 3) -> picture pixels (n, 2) and depth towards the viewer (n,)."""
    f = FR[v]; X, Y, Z = P[:, 0], P[:, 1], P[:, 2]
    if v == "side": return np.stack([f["x"] + X * f["L"], f["y"] - Z * f["L"]], 1), Y
    if v == "top": return np.stack([f["x"] + X * f["L"], f["y"] + Y * f["L"]], 1), Z
    if v == "bottom": return np.stack([f["x"] + X * f["L"], f["y"] - Y * f["L"]], 1), -Z
    return np.stack([f["x"] + Y * f["L"], f["y"] - Z * f["L"]], 1), -X        # front: seen from the nose

# ---- outline profiles along the body
def runs_profile(v, X, axis):
    """For each station: the extent of the biggest outline run in that picture column (model units)."""
    f = FR[v]; lo, hi = [], []
    for x in X:
        col = f["m"][:, int(round(f["x"] + x * f["L"]))]; idx = np.nonzero(col)[0]
        if len(idx) == 0: lo.append(np.nan); hi.append(np.nan); continue
        cuts = np.split(idx, np.nonzero(np.diff(idx) > 1)[0] + 1); r = max(cuts, key=len)
        lo.append(r.min()); hi.append(r.max())
    lo, hi = np.array(lo, float), np.array(hi, float)
    return (f["y"] - lo) / f["L"], (f["y"] - hi) / f["L"]       # picture rows -> up (side) / across (top, bottom)

def line(X, arr, pts):
    """Over the span of pts ([[x, value], ...]) the profile follows the points instead of the drawn outline."""
    if not pts: return arr
    p = np.array(pts, float); k = (X >= p[0, 0]) & (X <= p[-1, 0]); arr = arr.copy()
    arr[k] = np.interp(X[k], p[:, 0], p[:, 1]); return arr

def smooth1(a, n=2):
    k = np.ones(2 * n + 1) / (2 * n + 1); p = np.pad(a, n, mode="edge"); return np.convolve(p, k, "valid")

B = spec["body"]; NS, NK = B["stations"], B["sides"]
X = np.linspace(max(B["from"], 0.002), B["to"], NS)
zt0, zb = runs_profile("side", X, 0)                               # the outline as drawn (horns, crest and all)
wt_hi, wt_lo = runs_profile("top", X, 0); wt0 = np.maximum(abs(wt_hi), abs(wt_lo))
wb_hi, wb_lo = runs_profile("bottom", X, 0); wb = np.maximum(abs(wb_hi), abs(wb_lo))
zt = smooth1(line(X, zt0, B.get("top_line"))); zb = smooth1(zb)
wt = smooth1(line(X, wt0, B.get("width_line"))); wb = smooth1(line(X, wb, B.get("width_line")))
zc, wc = smooth1(zt0, 1), smooth1(wt0, 1); CR = B.get("crown")
zm = zb + B.get("mid", 0.5) * (zt - zb); R = B.get("round", 2.0)

V, Fc, PART = [], [], []
def sp(c, e): return np.sign(c) * abs(c) ** (2.0 / e)
rings = []
if B["from"] <= 0.002: V.append((0.0, 0.0, float(zm[0]))); tip = 0
for i, x in enumerate(X):
    ring = []
    for j in range(NK):
        th = math.pi / 2 + 2 * math.pi * j / NK; c, s = math.cos(th), math.sin(th)
        y = (wt[i] if s >= 0 else wb[i]) * sp(c, R)
        z = zm[i] + sp(s, R) * ((zt[i] - zm[i]) if s >= 0 else (zm[i] - zb[i]))
        f = min(x - CR[0], CR[1] - x) / 0.04 if CR else 0                  # fades in and out over 0.04, no step
        if f > 0 and j in (NK // 8, NK - NK // 8):     # the crest's two ridges, up and out (split into a top ridge for
            f = min(f, 1.0)                           # height and a side one for width was worse: it smeared the eye)
            y = math.copysign(abs(y) + f * max(wc[i] - abs(y), 0), y); z += f * max(zc[i] - z, 0)
        ring.append(len(V)); V.append((float(x), float(y), float(z)))
    rings.append(ring)
if B["from"] <= 0.002:
    for j in range(NK): Fc.append((tip, rings[0][(j + 1) % NK], rings[0][j])); PART.append("body")
for a, b in zip(rings, rings[1:]):
    for j in range(NK): Fc.append((a[j], a[(j + 1) % NK], b[(j + 1) % NK], b[j])); PART.append("body")
Fc.append(tuple(rings[-1])); PART.append("body")                 # cap the back (the head test stops at the neck)

def tube(name, spine, radius, sides, mirror):
    for sgn in ((1, -1) if mirror else (1,)):
        pts = [np.array((p[0], p[1] * sgn, p[2])) for p in spine]; rs = []
        for k, p in enumerate(pts):
            t = (pts[min(k + 1, len(pts) - 1)] - pts[max(k - 1, 0)]); t /= np.linalg.norm(t)
            u = np.cross(t, (0, 0, 1)); u = u / np.linalg.norm(u) if np.linalg.norm(u) > 1e-6 else np.array((0, 1, 0))
            w = np.cross(u, t); r = radius[k]; ry, rz = (r, r) if np.isscalar(r) else r
            ring = []
            for j in range(sides):
                th = 2 * math.pi * j / sides; q = p + u * ry * math.cos(th) + w * rz * math.sin(th)
                ring.append(len(V)); V.append(tuple(map(float, q)))
            rs.append(ring)
        for a, b in zip(rs, rs[1:]):
            for j in range(sides):
                f = (a[j], a[(j + 1) % sides], b[(j + 1) % sides], b[j]); Fc.append(f if sgn > 0 else f[::-1]); PART.append(name)
        Fc.append(tuple(rs[0][::-1]) if sgn > 0 else tuple(rs[0])); PART.append(name)
        Fc.append(tuple(rs[-1]) if sgn > 0 else tuple(rs[-1][::-1])); PART.append(name)

def blade(name, base, tip, width, thick, facing, mirror):
    """A faceted leaf-shaped plate (a crest blade, a cheek guard, an eye): a ridge down the middle, widest a third of
    the way from the base. It lies with its face out from the head's middle line, or towards `facing`."""
    for sgn in ((1, -1) if mirror else (1,)):
        b, t = np.array(base, float), np.array(tip, float); b[1] *= sgn; t[1] *= sgn
        ax = t - b; L = np.linalg.norm(ax); ax /= L; c = (b + t) / 2
        n = np.array(facing, float) * (1, sgn, 1) if facing else np.array((0, c[1], c[2] - np.interp(c[0], X, zm)))
        n -= ax * (n @ ax); n /= np.linalg.norm(n); w = np.cross(ax, n); m = b + ax * L * 0.35
        ids = []
        for q in (b, m + w * width / 2, t, m - w * width / 2, m + n * thick, m - n * thick * 0.4):
            ids.append(len(V)); V.append(tuple(map(float, q)))
        B_, R, T, Lf, up, dn = ids
        for f in ((B_, R, up), (R, T, up), (T, Lf, up), (Lf, B_, up), (R, B_, dn), (T, R, dn), (Lf, T, dn), (B_, Lf, dn)):
            Fc.append(f); PART.append(name)

for p in spec.get("parts", []):
    if p.get("kind") == "blade":
        blade(p["name"], p["base"], p["tip"], p["width"], p.get("thick", p["width"] * 0.25), p.get("facing"), p.get("mirror", True))
    else: tube(p["name"], p["spine"], p["radius"], p.get("sides", 6), p.get("mirror", True))
PSPEC = {p["name"]: p for p in spec.get("parts", [])}; PNAMES = ["body"] + list(PSPEC)

me = bpy.data.meshes.new("skin"); me.from_pydata(V, [], Fc); me.update()
for poly, nm in zip(me.polygons, PART): poly.material_index = PNAMES.index(nm)    # survives triangulating: the part
ob = bpy.data.objects.new("skin", me); bpy.context.scene.collection.objects.link(ob)
bm = bmesh.new(); bm.from_mesh(me); bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
bmesh.ops.triangulate(bm, faces=bm.faces); bm.to_mesh(me); bm.free()
for poly in me.polygons:      # pieces with a plain colour are faceted (flat lit facets, like the sheets' gold plates)
    nm = PNAMES[poly.material_index]
    poly.use_smooth = bool(B.get("smooth", False)) if nm == "body" else not PSPEC[nm].get("color")
TPART = np.array([p.material_index for p in me.polygons])
for poly in me.polygons: poly.material_index = 0                                  # one material, one texture
for o in bpy.data.objects: o.select_set(o is ob)
bpy.context.view_layer.objects.active = ob
bpy.ops.object.mode_set(mode="EDIT"); bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.uv.smart_project(angle_limit=math.radians(40), island_margin=0.01, area_weight=0.0, correct_aspect=True)
bpy.ops.object.mode_set(mode="OBJECT")
Vn = np.array([v.co[:] for v in me.vertices]); Tri = np.array([p.vertices[:] for p in me.polygons])
UV = np.array([[me.uv_layers.active.data[li].uv[:] for li in p.loop_indices] for p in me.polygons])
VN = np.array([v.normal[:] for v in me.vertices])

# ---- painting
def raster(tri2, W, H):
    """Pixels inside triangle tri2 (3, 2) on a W x H grid: (ys, xs, barycentric (n, 3))."""
    x0, y0 = np.maximum(np.floor(tri2.min(0) - 1).astype(int), 0); x1, y1 = np.minimum(np.ceil(tri2.max(0) + 1).astype(int), (W, H))
    if x1 <= x0 or y1 <= y0: return None
    xs, ys = np.meshgrid(np.arange(x0, x1) + 0.5, np.arange(y0, y1) + 0.5)
    a, b, c = tri2; den = (b[1] - c[1]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[1] - c[1])
    if abs(den) < 1e-12: return None
    l0 = ((b[1] - c[1]) * (xs - c[0]) + (c[0] - b[0]) * (ys - c[1])) / den
    l1 = ((c[1] - a[1]) * (xs - c[0]) + (a[0] - c[0]) * (ys - c[1])) / den
    L = np.stack([l0, l1, 1 - l0 - l1], -1); k = np.all(L >= -0.02, -1)
    if not k.any(): return None
    return (ys[k] - 0.5).astype(int), (xs[k] - 0.5).astype(int), L[k]

H_, W_ = MASK.shape
ZBUF = {}
for v in ("side", "top", "bottom", "front"):
    zb_ = np.full((H_, W_), -1e9)
    pic, dep = to_pic(v, Vn)
    for t in Tri:
        r = raster(pic[t], W_, H_)
        if r is None: continue
        ys_, xs_, L = r; d = L @ dep[t]; np.maximum.at(zb_, (ys_, xs_), d)
    ZBUF[v] = zb_

def sample(pic):
    x = np.clip(pic[:, 0] - 0.5, 0, W_ - 1.001); y = np.clip(pic[:, 1] - 0.5, 0, H_ - 1.001)
    x0, y0 = x.astype(int), y.astype(int); fx, fy = (x - x0)[:, None], (y - y0)[:, None]
    s = SB
    return (s[y0, x0] * (1 - fx) * (1 - fy) + s[y0, x0 + 1] * fx * (1 - fy) + s[y0 + 1, x0] * (1 - fx) * fy + s[y0 + 1, x0 + 1] * fx * fy)

def body_paint(P):
    """body.colors {scales [r, g, b], under [r, g, b], under_share (0..1 of the height from the bottom), scale (size)}:
    overlapping round scales in rows (each covers the front of the one behind, so its rounded back edge shows, with a
    dark rim), and a plain band underneath (jaw, belly) below under_share of the local height."""
    C = B["colors"]; x, y, z = P.T; s = C.get("scale", 0.02)
    top, bot, mid, w = (np.interp(x, X, a) for a in (zt, zb, zm, wt))
    u = x / s; v = np.arctan2(np.abs(y), z - mid) * (w + (top - bot) / 2) / 2 / s     # along, and round from the top
    best_d = np.ones(len(u)); best_cu = np.full(len(u), np.inf); j0 = np.floor(v + 0.5)
    for dj in (-1, 0, 1):
        j = j0 + dj; off = 0.5 * (j % 2)
        for di in (-1, 0, 1):
            cu = np.floor(u - off) + di + 0.5 + off; d = np.hypot((u - cu) / 0.9, (v - j) / 0.7)
            k = (d < 1) & (cu < best_cu); best_d[k] = d[k]; best_cu[k] = cu[k]
    g = np.array(C["scales"]) / 255.0 * (0.7 + 0.5 * (1 - best_d[:, None]))
    g[best_d > 0.82] *= 0.55
    h = (z - bot) / np.maximum(top - bot, 1e-6); sh = C.get("under_share", 0.4)
    g[h < sh] = np.array(C["under"]) / 255.0; g[abs(h - sh) < 0.03] *= 0.6       # the band, with a line on its edge
    return g

# Each spot is painted from ONE view (blending many views per texel mixed the mouth into the belly): the view its smooth
# normal faces best, the side preferred until it clearly points up, down or forward (about 60 degrees). Views are only
# cross-faded in a thin BAND where two nearly tie, so the switch is a soft line, not a sawtooth. A view that can't see
# the face (most of 4 inner points behind something nearer than SEE_TOL) is skipped for the whole face.
DIRS = {"side": np.array((0, 1, 0)), "top": np.array((0, 0, 1)), "bottom": np.array((0, 0, -1)), "front": np.array((-1, 0, 0))}
DIRS = {v: DIRS[v] for v in spec.get("paint", DIRS)}             # a view drawn unlike the others can be left out
BIAS = {"side": 0.25}; SEE_TOL = 0.012; BAND = 0.08
INNER = np.array([[4, 1, 1], [1, 4, 1], [1, 1, 4], [2, 2, 2]]) / 6.0
col = np.zeros((TEX, TEX, 3)); done = np.zeros((TEX, TEX), bool)
for fi, t in enumerate(Tri):
    r = raster(np.column_stack([UV[fi][:, 0], 1 - UV[fi][:, 1]]) * TEX, TEX, TEX)   # picture rows run down, UV v runs up
    if r is None: continue
    ys_, xs_, L = r; Pt = Vn[t].copy(); Nt = VN[t].copy(); fn = np.cross(Pt[1] - Pt[0], Pt[2] - Pt[0])
    if Pt[:, 1].mean() < 0: Pt[:, 1] *= -1; Nt[:, 1] *= -1; fn[1] *= -1      # the far side uses the mirror
    nm = PNAMES[TPART[fi]]
    if nm != "body" and PSPEC[nm].get("color"):                                # a measured piece: its own colour
        c = np.repeat([np.array(PSPEC[nm]["color"]) / 255.0], len(L), 0)
        if PSPEC[nm].get("kind") == "blade":                     # dark lines on its facet edges, like the sheets' plates
            t2 = np.column_stack([UV[fi][:, 0], 1 - UV[fi][:, 1]]) * TEX
            e = np.linalg.norm(t2[[1, 2, 0]] - t2[[2, 0, 1]], axis=1)          # the edge facing each corner
            a2 = abs(np.cross(t2[1] - t2[0], t2[2] - t2[0])); d = (L * (a2 / np.maximum(e, 1e-9))).min(1)
            c *= 0.45 + 0.55 * np.clip((d - 0.5) / 1.5, 0, 1)[:, None]                 # soft-edged, not jagged
        col[ys_, xs_] = c; done[ys_, xs_] = True; continue
    if nm == "body" and "colors" in B:                                          # the body's own scales and underside
        col[ys_, xs_] = body_paint(L @ Pt); done[ys_, xs_] = True; continue
    seen, drawn = [], []
    for v in DIRS:
        pic, dep = to_pic(v, INNER @ Pt)
        xi = np.clip(pic[:, 0].astype(int), 0, W_ - 1); yi = np.clip(pic[:, 1].astype(int), 0, H_ - 1)
        if VM[v][yi, xi].sum() < 3: continue          # the view doesn't draw anything there (horns seen from below)
        drawn.append(v)
        if fn @ DIRS[v] > 0 and (dep >= ZBUF[v][yi, xi] - SEE_TOL).sum() >= 3: seen.append(v)
    seen = seen or [max(drawn or DIRS, key=lambda v: fn @ DIRS[v])]
    N = L @ Nt; N /= np.maximum(np.linalg.norm(N, axis=1, keepdims=True), 1e-9); P = L @ Pt
    S = np.stack([N @ DIRS[v] + BIAS.get(v, 0) for v in seen], 1)
    Wt = np.clip((S - S.max(1, keepdims=True) + BAND) / BAND, 0, 1)
    acc = sum(sample(to_pic(v, P)[0]) * Wt[:, k:k + 1] for k, v in enumerate(seen))
    col[ys_, xs_] = acc / Wt.sum(1, keepdims=True); done[ys_, xs_] = True
grow(col, done, TEX // 64)                                           # fill gaps and pad islands from their neighbours
col[~done] = col[done].mean(0)

def box(a, r):
    c = np.cumsum(np.cumsum(np.pad(a, ((r + 1, r), (r + 1, r)), mode="edge"), 0), 1)
    return (c[2 * r + 1:, 2 * r + 1:] - c[:-2 * r - 1, 2 * r + 1:] - c[2 * r + 1:, :-2 * r - 1] + c[:-2 * r - 1, :-2 * r - 1]) / (2 * r + 1) ** 2
lum = col @ np.array((0.299, 0.587, 0.114)); height = box(lum, 1) - box(lum, 8)    # lines darker than around = grooves
gy, gx = np.gradient(height); k = spec.get("bump", 8.0)
nrm = np.stack([-gx * k, gy * k, np.ones_like(gx)], -1); nrm /= np.linalg.norm(nrm, axis=-1, keepdims=True)
glow = np.zeros((TEX, TEX))
for r_, g_, b_, tol in spec.get("glow", []):
    glow = np.maximum(glow, np.clip(1 - np.abs(col * 255 - (r_, g_, b_)).sum(-1) / tol, 0, 1))

def save(arr, name, srgb):
    a = np.atleast_3d(arr); a = np.repeat(a, 3, 2) if a.shape[2] == 1 else a
    img = bpy.data.images.new(name, TEX, TEX, alpha=False); img.colorspace_settings.name = "sRGB" if srgb else "Non-Color"
    px = np.concatenate([a[::-1], np.ones((TEX, TEX, 1))], -1).astype(np.float32).ravel(); img.pixels.foreach_set(px)
    img.filepath_raw = os.path.join(OUT, name + ".png"); img.file_format = "PNG"; img.save(); return img
ic = save(col, "skin-color", True); inn = save(nrm * 0.5 + 0.5, "skin-normal", False); ig = save(glow, "skin-glow", False)

mat = bpy.data.materials.new("skin"); mat.use_nodes = True; nt = mat.node_tree; bsdf = nt.nodes["Principled BSDF"]
tc = nt.nodes.new("ShaderNodeTexImage"); tc.image = ic; tn = nt.nodes.new("ShaderNodeTexImage"); tn.image = inn
tg = nt.nodes.new("ShaderNodeTexImage"); tg.image = ig; nm = nt.nodes.new("ShaderNodeNormalMap")
nt.links.new(tc.outputs[0], bsdf.inputs["Base Color"]); nt.links.new(tn.outputs[0], nm.inputs["Color"])
nt.links.new(nm.outputs[0], bsdf.inputs["Normal"]); nt.links.new(tc.outputs[0], bsdf.inputs["Emission Color"])
nt.links.new(tg.outputs[0], bsdf.inputs["Emission Strength"]); bsdf.inputs["Roughness"].default_value = 0.85
ob.data.materials.append(mat)

# ---- renders: the four flat views and the three-quarter view, on the sheet's grey
sc = bpy.context.scene; sc.render.engine = "BLENDER_EEVEE"; sc.render.film_transparent = False
sc.view_settings.view_transform = "Standard"
w = bpy.data.worlds.new("w"); sc.world = w; w.use_nodes = True; w.node_tree.nodes["Background"].inputs[0].default_value = (*BG ** 2.2, 1)
wn = w.node_tree; wn.nodes["Background"].inputs[1].default_value = spec.get("ambient", 1.0)  # fill light on the model
cb = wn.nodes.new("ShaderNodeBackground"); cb.inputs[0].default_value = (*BG ** 2.2, 1)   # what the camera sees behind:
lp = wn.nodes.new("ShaderNodeLightPath"); mx = wn.nodes.new("ShaderNodeMixShader")       # always the sheet's grey
wn.links.new(lp.outputs["Is Camera Ray"], mx.inputs[0]); wn.links.new(wn.nodes["Background"].outputs[0], mx.inputs[1])
wn.links.new(cb.outputs[0], mx.inputs[2]); wn.links.new(mx.outputs[0], wn.nodes["World Output"].inputs[0])
sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN")); sun.data.energy = spec.get("sun", 1.5)
sun.rotation_euler = (math.radians(35), 0, math.radians(30)); sc.collection.objects.link(sun)
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera = cam
lo, hi = Vn.min(0), Vn.max(0); ctr = (lo + hi) / 2; size = float(max(hi - lo))
def shoot(name, d, euler=None, ortho=True, res=(1200, 700)):
    """Camera on side d of the model; the flat views are turned like the sheet's (nose left, seen from the left)."""
    d = Vector(d).normalized(); cam.location = Vector(ctr) + d * size * 4
    cam.rotation_euler = euler if euler else (-d).to_track_quat("-Z", "Y").to_euler()
    cam.data.type = "ORTHO" if ortho else "PERSP"; cam.data.ortho_scale = size * 1.15; cam.data.lens = 85
    sc.render.resolution_x, sc.render.resolution_y = res; sc.render.filepath = os.path.join(OUT, "render-%s.png" % name)
    bpy.ops.render.render(write_still=True)
h = math.pi / 2
shoot("side", (0, -1, 0), (h, 0, 0)); shoot("top", (0, 0, 1), (0, 0, 0)); shoot("bottom", (0, 0, -1), (2 * h, 0, 0))
shoot("front", (-1, 0, 0), (h, 0, -h))
yaw, pitch = (math.radians(spec["camera"][k]) for k in ("yaw", "pitch"))
shoot("three_quarter", (-math.sin(yaw) * math.cos(pitch), -math.cos(yaw) * math.cos(pitch), math.sin(pitch)), ortho=False)
shoot("chase", (0.82, -0.3, 0.48), ortho=False)               # behind and above, where the game's camera mostly looks from
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, "model.blend"))
print("triangles", len(Tri), "out", OUT)
