"""One white construction-paper card cut out neatly with scissors (Alan 2026-11-18: neat, clean, flat; a child cut it, so
not perfect): long straight snips with tiny turns where they meet, now and then a small over-cut; fine paper grain and
fibres, no crumples. White, so the game tints it (ImageColor3); its shadow is black, which a tint leaves black.
    python tools/art/cut_paper.py assets/ui/mainmenu/ready/card-white.png 1004 154 47   (the Missions cards)"""
import sys, numpy as np
from PIL import Image, ImageDraw, ImageFilter
out, W, H, seed = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4])
rng = np.random.default_rng(seed)
SS, M = 4, 7  # supersampling; margin for the shadow
def edge(a, b, n_min, n_max, wobble):
    """Points from a to b in a few straight snips, each turning a little from the last."""
    a, b = np.array(a, float), np.array(b, float)
    n = rng.integers(n_min, n_max + 1)
    cuts = np.sort(rng.uniform(0.12, 0.88, n - 1)) if n > 1 else np.array([])
    ts = np.concatenate([[0], cuts, [1]])
    d = b - a; normal = np.array([-d[1], d[0]]) / np.linalg.norm(d)
    offs = np.concatenate([[0], rng.normal(0, wobble, n - 1), [0]])
    pts = []
    for i, t in enumerate(ts):
        p = a + d * t + normal * offs[i]
        if 0 < i < len(ts) - 1:
            step = normal * rng.uniform(-1.5, 1.5)  # the next snip starts a hair off the last one
            pts += [p, p + step]
        else:
            pts.append(p)
    return pts
# Corners a little off square; long edges in 4-7 snips, short ones in 1-2.
c = [(M + rng.uniform(0, 9), M + rng.uniform(0, 4)), (W - M - rng.uniform(0, 9), M + rng.uniform(0, 4)),
     (W - M - rng.uniform(0, 9), H - M - 2 - rng.uniform(0, 4)), (M + rng.uniform(0, 9), H - M - 2 - rng.uniform(0, 4))]
poly = edge(c[0], c[1], 4, 6, 5) + edge(c[1], c[2], 1, 2, 1.5)[1:] + edge(c[2], c[3], 4, 6, 5)[1:] + edge(c[3], c[0], 1, 2, 1.5)[1:-1]
# Two corners snipped off at an angle, the way scissors round a corner in one cut.
for k in rng.choice(4, 2, replace=False):
    i = int(np.argmin([(q[0] - c[k][0]) ** 2 + (q[1] - c[k][1]) ** 2 for q in poly]))
    a = np.array(poly[i - 1]) - np.array(poly[i]); b = np.array(poly[(i + 1) % len(poly)]) - np.array(poly[i])
    cut = rng.uniform(4, 8)
    poly[i:i + 1] = [tuple(np.array(poly[i]) + a / np.linalg.norm(a) * cut), tuple(np.array(poly[i]) + b / np.linalg.norm(b) * cut * rng.uniform(0.7, 1.3))]
mask = Image.new("L", (W * SS, H * SS), 0)
ImageDraw.Draw(mask).polygon([(x * SS, y * SS) for x, y in poly], fill=255)
# Two small over-cuts: where a snip went a little too far into the paper.
d = ImageDraw.Draw(mask)
for _ in range(2):
    top = rng.random() < 0.5
    x = rng.uniform(0.15, 0.85) * W
    y = (M + 1.5) if top else (H - M - 3.5)
    depth = rng.uniform(2.5, 4) * (1 if top else -1)
    d.polygon([((x - 4) * SS, y * SS), ((x + 3) * SS, (y + depth * 0.3) * SS), ((x + 6) * SS, (y + depth) * SS), ((x + 5) * SS, y * SS)], fill=0)
mask = np.asarray(mask.resize((W, H), Image.LANCZOS)).astype(float) / 255
# Construction paper: flat, matte, fine grain and short fibres, a faint blotchiness; no folds.
def noise(sigma, amp):
    n = Image.fromarray(((rng.standard_normal((H, W)) * 40) + 128).clip(0, 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(sigma))
    n = np.asarray(n).astype(float) - 128
    return n / (n.std() + 1e-6) * amp
v = 246 + noise(0.6, 5.5) + noise(3, 2.4) + noise(30, 2.6)
fib = Image.new("L", (W, H), 128); fd = ImageDraw.Draw(fib)
for _ in range(W * H // 500):
    x, y, a, L = rng.uniform(0, W), rng.uniform(0, H), rng.uniform(0, np.pi), rng.uniform(4, 14)
    fd.line([(x, y), (x + np.cos(a) * L, y + np.sin(a) * L)], fill=int(128 + rng.choice([-1, 1, 1]) * rng.uniform(10, 22)), width=1)
v += (np.asarray(fib.filter(ImageFilter.GaussianBlur(0.5))).astype(float) - 128) * 0.8
# The cut edge catches a little light (a thin lighter rim).
inner = np.asarray(Image.fromarray((mask * 255).astype(np.uint8)).filter(ImageFilter.MinFilter(5))).astype(float) / 255
v += (mask - inner).clip(0, 1) * 9
# Soft black shadow down and to the right, under the paper.
sh = Image.fromarray((mask * 255).astype(np.uint8)).transform((W, H), Image.AFFINE, (1, 0, -2, 0, 1, -3)).filter(ImageFilter.GaussianBlur(2.5))
sh = np.asarray(sh).astype(float) / 255 * 0.32
alpha = mask + sh * (1 - mask)
rgb = np.where(alpha > 0, v * mask / np.maximum(alpha, 1e-6), 0)  # the paper's colour where it covers; the shadow black
img = np.dstack([rgb.clip(0, 255)] * 3 + [alpha * 255]).astype(np.uint8)
Image.fromarray(img, "RGBA").save(out)
print(out, W, "x", H)
