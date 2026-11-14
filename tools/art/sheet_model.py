"""Model sheet -> Blender model coloured by projecting the sheet's own views: the shape-skin method Alan agreed on
2026-11-14 (docs/decisions/2026-11-14-shape-skin-model-sheets.md). The body is a loft through the sheet's outlines
(side view: top and bottom, top/bottom views: width); parts that stick out (horns, fins) are simple tubes or plates
from measured numbers. Every texel is painted from the SIDE, TOP, BOTTOM or FRONT view that faces it best and can see
it (a depth test per view, so a horn never paints its picture onto the head under it). Bumps come from the art's own
lines (dark line = groove) as a normal map; glow colours (eyes) become an emissive mask.

    python tools/art/sheet_model.py SPEC.json          (runs Blender, then writes the review picture)

SPEC (lengths in units of the skin's whole length: nose tip 0 -> tail tip 1; x along, y across, z up; picture
points in sheet pixels):
  sheet, out (folder), views {side, top, bottom, front, three_quarter: [x0, y0, x1, y1]},
  body {from, to, stations, sides, round (2 ellipse, 1 diamond, 3+ boxier), mid (0..1, where the widest line sits
        between bottom and top), smooth (bool), bridge_top [[a, b]], bridge_width [[a, b]]  (spans where a horn,
        fin or wing joins: the outline is bridged straight across)},
  parts [{name, spine [[x, y, z], ...], radius [r, ...] (one per spine point; or [w, t] pairs for a flat blade),
          sides, mirror}],
  glow [[r, g, b, tolerance]] (sheet colours that glow), tex (texture size), camera {yaw, pitch} (three-quarter view,
  degrees: yaw 0 = from the side, 90 = from the front; pitch above level), front_scale (optional px per length).
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
            a = sheet.crop(tuple(spec["views"][view])); b = Image.open(r).convert("RGB")
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

def view_mask(v):
    x0, y0, x1, y1 = spec["views"][v]; m = np.zeros_like(MASK); m[y0:y1, x0:x1] = MASK[y0:y1, x0:x1]; return m

# ---- each view's frame: nose tip and length in pixels from the outline (side, top, bottom); front by height
FR = {}
for v in ("side", "top", "bottom"):
    m = view_mask(v); ys, xs = np.nonzero(m)
    nose_x, tail_x = xs.min(), xs.max(); nose_y = ys[xs <= nose_x + 2].mean()
    FR[v] = dict(x=float(nose_x), y=float(nose_y), L=float(tail_x - nose_x), m=m)
mside = FR["side"]["m"]; ys, xs = np.nonzero(mside)
Z_MAX = (FR["side"]["y"] - ys.min()) / FR["side"]["L"]; Z_MIN = (FR["side"]["y"] - ys.max()) / FR["side"]["L"]
mf = view_mask("front"); ys, xs = np.nonzero(mf)
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

def bridge(X, arr, spans):
    arr = arr.copy()
    for a, b in spans:
        k = (X > a) & (X < b); ia, ib = np.argmin(abs(X - a)), np.argmin(abs(X - b))
        arr[k] = np.interp(X[k], [X[ia], X[ib]], [arr[ia], arr[ib]])
    return arr

def smooth1(a, n=2):
    k = np.ones(2 * n + 1) / (2 * n + 1); p = np.pad(a, n, mode="edge"); return np.convolve(p, k, "valid")

B = spec["body"]; NS, NK = B["stations"], B["sides"]
X = np.linspace(max(B["from"], 0.002), B["to"], NS)
zt, zb = runs_profile("side", X, 0)
wt_hi, wt_lo = runs_profile("top", X, 0); wt = np.maximum(abs(wt_hi), abs(wt_lo))
wb_hi, wb_lo = runs_profile("bottom", X, 0); wb = np.maximum(abs(wb_hi), abs(wb_lo))
zt = smooth1(bridge(X, zt, B.get("bridge_top", []))); zb = smooth1(zb)
wt = smooth1(bridge(X, wt, B.get("bridge_width", []))); wb = smooth1(bridge(X, wb, B.get("bridge_width", [])))
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

for p in spec.get("parts", []): tube(p["name"], p["spine"], p["radius"], p.get("sides", 6), p.get("mirror", True))

me = bpy.data.meshes.new("skin"); me.from_pydata(V, [], Fc); me.update()
ob = bpy.data.objects.new("skin", me); bpy.context.scene.collection.objects.link(ob)
bm = bmesh.new(); bm.from_mesh(me); bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
bmesh.ops.triangulate(bm, faces=bm.faces); bm.to_mesh(me); bm.free()
for poly in me.polygons: poly.use_smooth = bool(B.get("smooth", False))
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
    s = SHEET
    return (s[y0, x0] * (1 - fx) * (1 - fy) + s[y0, x0 + 1] * fx * (1 - fy) + s[y0 + 1, x0] * (1 - fx) * fy + s[y0 + 1, x0 + 1] * fx * fy)

DIRS = {"side": np.array((0, 1, 0)), "top": np.array((0, 0, 1)), "bottom": np.array((0, 0, -1)), "front": np.array((-1, 0, 0))}
col = np.zeros((TEX, TEX, 3)); wsum = np.zeros((TEX, TEX)); done = np.zeros((TEX, TEX), bool)
for fi, t in enumerate(Tri):
    r = raster(np.column_stack([UV[fi][:, 0], 1 - UV[fi][:, 1]]) * TEX, TEX, TEX)   # picture rows run down, UV v runs up
    if r is None: continue
    ys_, xs_, L = r; P = L @ Vn[t]; N = L @ VN[t] if B.get("smooth") else np.repeat([np.cross(Vn[t[1]] - Vn[t[0]], Vn[t[2]] - Vn[t[0]])], len(L), 0)
    N = N / np.maximum(np.linalg.norm(N, axis=1, keepdims=True), 1e-9)
    flip = P[:, 1] < 0; Pm = P.copy(); Pm[flip, 1] *= -1; Nm = N.copy(); Nm[flip, 1] *= -1   # the far side uses the mirror
    acc = np.zeros((len(L), 3)); ws = np.zeros(len(L))
    for v, dvec in DIRS.items():
        w = np.maximum(Nm @ dvec, 0) ** 4
        pic, dep = to_pic(v, Pm); xi = np.clip(pic[:, 0].astype(int), 0, W_ - 1); yi = np.clip(pic[:, 1].astype(int), 0, H_ - 1)
        seen = dep >= ZBUF[v][yi, xi] - 0.006
        inside = view_mask(v)[yi, xi] if v == "front" else FR[v]["m"][yi, xi]
        w = w * seen * inside; acc += sample(pic) * w[:, None]; ws += w
    ok = ws > 1e-6
    col[ys_[ok], xs_[ok]] = acc[ok] / ws[ok, None]; done[ys_[ok], xs_[ok]] = True
for _ in range(TEX // 64):                                            # fill gaps and pad islands from their neighbours
    acc = np.zeros_like(col); cnt = np.zeros((TEX, TEX))
    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        sd = np.roll(done, (dy, dx), (0, 1)); acc += np.roll(col, (dy, dx), (0, 1)) * sd[..., None]; cnt += sd
    grow = (~done) & (cnt > 0); col[grow] = acc[grow] / cnt[grow, None]; done |= grow
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
w.node_tree.nodes["Background"].inputs[1].default_value = 1.0
sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN")); sun.data.energy = 1.5
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
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, "model.blend"))
print("triangles", len(Tri), "out", OUT)
