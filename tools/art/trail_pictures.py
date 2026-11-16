"""The trails' small pictures, drawn by code. Nothing is uploaded.
    python tools/art/trail_pictures.py        -> assets/fx/trails/<name>.png and .planning/skins/trails/pictures.png
Shapes (star, twinkle, glints, lightning) are drawn by PhotoCraft from lists of points; grainy bands (dust, cloud,
rainbow) are numpy. The rules (docs/plan/SKINS-PLAN.md, "Trails"): white in layers so the game colours them; a frame
sheet is 4 x 4; nothing within 4 px of a picture's edge or of a frame's cell (a band may run off its two ends, where it
repeats); no red drops."""
import json, math, os, random, subprocess
from pathlib import Path
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]; OUT = ROOT / "assets/fx/trails"
PHOTOCRAFT = os.environ.get("PHOTOCRAFT", "D:/ArtCraft/PhotoCraft/photocraft-cli.exe")

def photocraft(size, steps, name):
    """Run PhotoCraft without its window: a see-through canvas, the steps in order, saved as a PNG."""
    cmd = [PHOTOCRAFT, "run", "--new", json.dumps({"width": size[0], "height": size[1], "background": "transparent"})]
    for command, params in steps:
        cmd += ["--cmd", command] + (["--params", json.dumps(params)] if params else [])
    subprocess.run(cmd + ["--out", str(OUT / f"{name}.png")], check=True, capture_output=True)
def poly(points, shade=1.0, alpha=1.0):
    return ("shape.create", {"kind": "path", "fill": [shade, shade, shade, alpha],
                             "path": {"subpaths": [{"closed": True, "knots": [[round(x, 1), round(y, 1)] for x, y in points]}]}})
def glow(radius): return [("layer.mergeVisible", None), ("filter.blur.gaussianBlur", {"radius": radius})]
def finish(name, cells=1, band=False):
    """White under the see-through pixels (no dark rim when Roblox smooths the picture), then the 4 px edge check."""
    path = OUT / f"{name}.png"; a = np.asarray(Image.open(path).convert("RGBA")).copy()
    a[a[..., 3] == 0, :3] = 255
    cell = a.shape[0] // cells
    for i in range(cells):
        for j in range(cells if not band else 1):
            c = a[i * cell:(i + 1) * cell, j * cell:(j + 1) * cell] if not band else a
            edges = [c[:4], c[-4:]] + ([] if band else [c[:, :4], c[:, -4:]])
            assert all(e[..., 3].max() <= 2 for e in edges), f"{name}: paint within 4 px of an edge (cell {i},{j})"
    Image.fromarray(a).save(path)
def tapered(points, w0, w1):
    """A line of points as a closed outline, w0 wide at its start and w1 at its end."""
    left, right = [], []
    for i, (x, y) in enumerate(points):
        ax, ay = points[max(i - 1, 0)]; bx, by = points[min(i + 1, len(points) - 1)]
        n = math.hypot(bx - ax, by - ay) or 1; nx, ny = -(by - ay) / n, (bx - ax) / n
        w = (w0 + (w1 - w0) * i / (len(points) - 1)) / 2
        left.append((x + nx * w, y + ny * w)); right.append((x - nx * w, y - ny * w))
    return left + right[::-1]
def pnoise(h, w, size, seed):
    """Smooth noise 0..1 that repeats at its edges; `size` is the lump size in px."""
    rng = np.random.default_rng(seed); f = np.fft.fft2(rng.standard_normal((h, w)))
    fy, fx = np.fft.fftfreq(h)[:, None], np.fft.fftfreq(w)[None, :]
    n = np.fft.ifft2(f * np.exp(-(fx ** 2 + fy ** 2) * size ** 2 * 6)).real
    return (n - n.min()) / (n.max() - n.min())
def step(lo, hi, x): t = np.clip((x - lo) / (hi - lo), 0, 1); return t * t * (3 - 2 * t)
def band(name, rgb, alpha):
    """A 512 x 64 strip: colour (h, w, 3 or a single colour) and coverage 0..1, see-through near its long edges."""
    h, w = alpha.shape; v = np.abs(np.arange(h) + 0.5 - h / 2) / (h / 2)
    alpha = alpha * step(1.0, 0.72, v)[:, None]; alpha[:4] = alpha[-4:] = 0
    img = np.dstack([np.broadcast_to(np.asarray(rgb, float), (h, w, 3)), alpha * 255])
    Image.fromarray(img.round().astype(np.uint8)).save(OUT / f"{name}.png"); finish(name, band=True)

def star():
    """Gold Stars: a folded foil star, ten facets light and dark; the game tints it gold."""
    rng = random.Random(5); c, steps = (64, 64), []
    tips = [(64 + (r + rng.uniform(-1.5, 1.5)) * math.sin(i * math.pi / 5), 64 - (r + rng.uniform(-1.5, 1.5)) * math.cos(i * math.pi / 5))
            for i, r in enumerate([54, 23] * 5)]
    for i in range(10): steps.append(poly([c, tips[i], tips[(i + 1) % 10]], 1.0 if i % 2 == 0 else 0.72))
    photocraft((128, 128), steps, "trail-star"); finish("trail-star")
def twinkle():
    """A four-point glint in 16 sizes (the game shows the frames in a random order, cross-fading: a twinkle)."""
    def glint(cx, cy, L):
        pts = []
        for k in range(8):
            r = L if k % 2 == 0 else L * 0.13; a = k * math.pi / 4
            pts.append((cx + r * math.sin(a), cy - r * math.cos(a)))
        return pts
    sizes = [20 * (0.25 + 0.75 * math.sin(math.pi * (k + 0.5) / 16) ** 1.5) for k in range(16)]
    cells = [(32 + 64 * (k % 4), 32 + 64 * (k // 4), s) for k, s in enumerate(sizes)]
    steps = [poly(glint(x, y, s), alpha=0.7) for x, y, s in cells] + glow(2.5) + [poly(glint(x, y, s * 0.82)) for x, y, s in cells]
    photocraft((256, 256), steps, "trail-twinkle"); finish("trail-twinkle", 4)
def glints():
    """Holo Rainbow's shine: slanted soft bars, stamped along the ribbon (the strip repeats end to end)."""
    def bar(x, w): return [(x, 54), (x + 22, 10), (x + 22 + w, 10), (x + w, 54)]
    steps = [poly(bar(x, w), alpha=a) for x, w, a in ((30, 16, 0.85), (64, 5, 0.6), (150, 9, 0.7), (196, 4, 0.5))] + glow(2)
    photocraft((256, 64), steps, "trail-glints"); finish("trail-glints", band=True)
def bolt():
    """Storm Sparks: two small lightning forks, each growing, flashing twice and thinning away (16 frames, played once)."""
    def fork(seed):
        rng = random.Random(seed); main = [(-42 + 12 * i, rng.uniform(-9, 9) if 0 < i < 7 else 0) for i in range(8)]
        k = rng.choice((2, 3)); s = rng.choice((-1, 1)); x, y = main[k]
        return main, [(x, y)] + [(x + 9 * j + rng.uniform(-2, 2), y + s * (8 * j + rng.uniform(-3, 3))) for j in (1, 2, 3)]
    # per frame: how much of the fork is drawn, its thickness, how solid, how much glow
    life = [(0.45, 2.2, 0.9, 0.3), (0.8, 3, 1, 0.5), (1, 4.5, 1, 1), (1, 2.2, 0.55, 0.25), (1, 4.2, 1, 0.9), (1, 3, 0.8, 0.5), (1, 2, 0.55, 0.25), (1, 1.4, 0.3, 0.1)]
    cores, halos = [], []
    for k in range(16):
        (main, branch), (grow, thick, solid, halo) = fork(11 + k // 8), life[k % 8]
        cx, cy = 64 + 128 * (k % 4), 64 + 128 * (k // 4)
        for line, scale in ((main, 1.0), (branch, 0.6)):
            n = max(2, round(len(line) * grow)); pts = [(cx + x, cy + y) for x, y in line[:n]]
            if line is branch and grow < 0.8: continue
            cores.append(poly(tapered(pts, thick * scale, 0.8), alpha=solid))
            halos.append(poly(tapered(pts, thick * scale * 1.8 + 2, 2), alpha=halo * 0.5))
    photocraft((512, 512), halos + glow(4) + cores, "trail-bolt"); finish("trail-bolt", 4)
def dust():
    """A soft band of fine specks: Gold Stars' thin gold dust (and later Stardust, Chalk Dust)."""
    specks = step(0.62, 0.8, pnoise(64, 512, 2.2, 21)); haze = pnoise(64, 512, 14, 22)
    band("trail-dust", (255, 255, 255), np.clip(0.14 * haze + 0.9 * specks, 0, 1))
def cloud():
    """Storm Sparks' cloud wisp: lumpy and soft, stamped where the plane flew."""
    v = (np.arange(64) + 0.5 - 32) / 32; dome = (1 - v ** 2)[:, None]                 # full in the middle, puffy at the edges
    lumps = 0.6 * pnoise(64, 512, 16, 31) + 0.4 * pnoise(64, 512, 8, 32)
    band("trail-cloud", (255, 255, 255), step(0.2, 0.62, dome * 0.85 + (lumps - 0.5) * 1.1) * (0.8 + 0.2 * pnoise(64, 512, 10, 33)))
def rainbow():
    """Holo Rainbow's ribbon: six marker bands across it in the Holographic skin's colours, streaked along its length."""
    cols = np.array([[int(h[i:i + 2], 16) for i in (1, 3, 5)] for h in ("#FF4AC8", "#FF9A4A", "#FFE04A", "#4CF0A0", "#32C8FF", "#7A5CFF")], float)
    v = (np.arange(64) + 0.5 - 8) / 48 * 6                                             # 6 bands between rows 8 and 56
    wob = (pnoise(64, 512, 30, 41) - 0.5) * 0.5; pos = np.clip(v[:, None] + wob, 0, 5.999)
    i = np.floor(pos).astype(int); f = step(0.78, 1.0, pos - i)[..., None]             # bands bleed a little at their joins
    rgb = cols[i] * (1 - f) + cols[np.minimum(i + 1, 5)] * f
    streak = np.tile(pnoise(64, 8, 3, 42).mean(1, keepdims=True), (1, 512)) * 0.5 + pnoise(64, 512, 40, 43) * 0.5
    rgb = np.clip(rgb * (0.9 + 0.2 * streak[..., None]), 0, 255)
    band("trail-rainbow", rgb, np.full((64, 512), 0.96))

PICTURES = [star, twinkle, glints, bolt, dust, cloud, rainbow]
def sheet():
    """Every picture on a mid-blue and a dark backing, tinted the way its trail tints it: the look before any upload."""
    tints = {"trail-star": (255, 205, 50), "trail-dust": (255, 215, 90), "trail-cloud": (150, 150, 228), "trail-bolt": (255, 246, 190)}
    files = sorted(OUT.glob("*.png")); w = 540; rows = []
    for f in files:
        im = Image.open(f).convert("RGBA"); t = tints.get(f.stem)
        if t: im = Image.merge("RGBA", [c.point(lambda v, k=k: v * k // 255) for c, k in zip(im.split()[:3], t)] + [im.split()[3]])
        im = im.resize((w - 28, round(im.height * (w - 28) / im.width)), Image.LANCZOS)
        row = Image.new("RGBA", (w * 2, im.height + 28), (120, 160, 210, 255)); row.paste((34, 42, 70, 255), (w, 0, w * 2, row.height))
        row.alpha_composite(im, (14, 14)); row.alpha_composite(im, (w + 14, 14)); rows.append(row)
    out = Image.new("RGB", (w * 2, sum(r.height for r in rows))); y = 0
    for r in rows: out.paste(r.convert("RGB"), (0, y)); y += r.height
    dest = ROOT / ".planning/skins/trails/pictures.png"; dest.parent.mkdir(parents=True, exist_ok=True); out.save(dest); print(dest)

if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    for draw in PICTURES: draw(); print(draw.__name__)
    sheet()
