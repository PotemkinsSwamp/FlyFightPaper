"""The Common skins' printed sheets, drawn in code (Alan picked this way over TextureCraft, 2026-11-16):
    python tools/art/skin_sheets.py [id ...]      -> assets/models/planes/skins/<id>.png (1024, no empty texels)
One picture a skin in the assets/models/planes/skin-sheet layout: TOP (x across, z along, nose up), SIDE (y across,
z along) and FRONT (x across, y up). A design is written against the plane's own studs (X right, Y up, Z back from the
nose) so stripes and rows line up between the views, drawn 3 times too big and shrunk (smooth edges), with a faint paper
grain. Look at each on real planes with skin_preview.py, and at the sheet itself before any upload (lessons.md).
Designs follow the approved concepts (.planning/skins/concepts/common-1.png, common-2.png)."""
import sys, colorsys
from pathlib import Path
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]; OUT = ROOT / "assets/models/planes/skins"
N, SS = 1024, 3
K = 40.42007641175244; X0, Y0, Z0 = -8.65, -2.27, -9.506416; X1, Y1, Z1 = 8.65, 4.47, 7.9000005   # skin-sheet/layout.json
py, px = (np.mgrid[0:N * SS, 0:N * SS] + 0.5) / SS                           # sheet pixels (float), supersampled
SPLIT_X, SPLIT_Y = 24 + K * (X1 - X0), 24 + K * (Z1 - Z0)                    # the middle of the gaps between the views
TOP, SIDE = (px < SPLIT_X) & (py < SPLIT_Y), (px >= SPLIT_X) & (py < SPLIT_Y); FRONT = py >= SPLIT_Y
X = np.where(SIDE, 1.4, (px - 16) / K + X0)                                  # SIDE has no x: the body's side
Z = np.where(FRONT, Z0, (py - 16) / K + Z0)                                  # FRONT has no z: the nose
Y = np.where(SIDE, (px - 32 - K * (X1 - X0)) / K + Y0, np.where(FRONT, Y1 - (py - 32 - K * (Z1 - Z0)) / K, 1.0))
U = np.where(SIDE, (Y - Y0) * 1.3, np.abs(X))                                # "how far out from the middle": |x| seen from above, height on the side

def rgb(h): return np.array([int(h[i:i + 2], 16) for i in (1, 3, 5)]) / 255.0
def noise(cell, seed, octaves=3):
    """Smooth blotches about `cell` sheet pixels wide, 0..1."""
    rng, out, amp, total = np.random.default_rng(seed), 0, 1.0, 0
    for o in range(octaves):
        g = max(2, int(N / cell * 2 ** o) + 2)
        a = Image.fromarray((rng.random((g, g)) * 255).astype(np.uint8)).resize((N * SS, N * SS), Image.BICUBIC)
        out, total, amp = out + amp * np.asarray(a, float) / 255, total + amp, amp / 2
    return out / total
def pick(mask, a, b): return np.where(mask[..., None], a, b)
def finish(col, name):
    grain = 1 + 0.035 * (noise(3, 99, 1) - 0.5) + 0.03 * (noise(60, 98, 2) - 0.5)   # paper: fine tooth and soft blotches
    out = (np.clip(col * grain[..., None], 0, 1)).reshape(N, SS, N, SS, 3).mean((1, 3))
    OUT.mkdir(parents=True, exist_ok=True); Image.fromarray((out * 255 + 0.5).astype(np.uint8)).save(OUT / (name + ".png")); print(name)

def carbon_fiber():
    """Dark 2/2 twill weave of 8 px strands, light one way and dark the other; a thin red pinstripe down the middle."""
    W = 8.0; i, j = np.floor(px / W), np.floor(py / W); fx, fy = px / W - i, py / W - j
    warp = ((i + j) % 4) < 2
    across, along = np.where(warp, fx, fy), np.where(warp, fy, fx)
    run = np.where(warp, (i + j) % 4 + along, (i + j) % 4 - 2 + along) / 2
    v = np.sin(np.pi * across) ** 0.6 * (0.55 + 0.45 * np.sin(np.pi * np.clip(run, 0, 1))) * (0.94 + 0.06 * np.sin(across * W * 2.4 * np.pi))
    g = np.where(warp, 0.16, 0.07) + np.where(warp, 0.34, 0.15) * v
    col = np.stack((g * 0.97, g * 0.99, g * 1.06), -1)
    d = np.where(SIDE, 99, np.abs(X)) * K                                     # px from the middle line
    return pick(d < 4, pick(d < 2.6, rgb("#F53D38"), rgb("#4D050A")), col)

def racing_stripe():
    """Racing red with two wide cream stripes down the middle that run up and over the body's ridge and the tail fin
    (Alan 2026-11-16: the ridge cut each stripe in half). The ridge's steep sides take the SIDE picture: every body's
    crest is at y 1.40 (slim 1.24) and its side walls stop at 0.95 to 1.0, so SIDE is cream from y 0.97 up, with the
    red line between the stripes on the crest (body and nose only: fins are taller). Measured from the sheet copies
    (.planning/skins/tests/faces/faces.py)."""
    red = rgb("#C9202B") * (0.94 + 0.12 * noise(140, 3, 2))[..., None]
    cream, edge = rgb("#F2E6CC"), rgb("#7A0F18")
    d = np.abs(X)                                                             # TOP and FRONT: cream out to 0.75 studs each side
    flat = pick(d < 0.07, red, pick(d < 0.75, cream, pick(d < 0.81, edge, red)))
    crest = (Y > 1.31) & (Z < 4.5)
    side = pick(crest, red, pick(Y > 0.97, cream, red))                       # no line at the ridge's foot: one unbroken stripe a side
    return pick(SIDE, side, flat)

def eight_bit():
    """Chunky pixels: navy with clusters of bright blocks."""
    B = 20; gi, gj = (px // B).astype(int), (py // B).astype(int); g = N // B + 2
    rng = np.random.default_rng(8)
    def field(cell):                                                         # blotchy random field per block
        lo = rng.random((g // cell + 2, g // cell + 2)); f = np.kron(lo, np.ones((cell, cell)))[:g, :g]
        return 0.6 * f + 0.4 * rng.random((g, g))
    on, hue = field(3) > 0.56, (field(2) * 6).astype(int) % 6
    # Safety (lessons.md, the 2026-10-12 bans): random blocks must never come near a hooked cross. Every 5 x 5 window,
    # bright against navy and colour by colour, must differ from it (and its mirror) in at least 5 blocks; reseed if not.
    S = np.array([[1, 0, 1, 1, 1], [1, 0, 1, 0, 0], [1, 1, 1, 1, 1], [0, 0, 1, 0, 1], [1, 1, 1, 0, 1]], bool)
    for mask in [on] + [on & (hue == k) for k in range(6)]:
        win = np.lib.stride_tricks.sliding_window_view(mask, (5, 5))
        assert max((win == p).sum((2, 3)).max() for p in (S, S[:, ::-1])) <= 20, "8-Bit: a block shape too close to a hooked cross; change the seed"
    pal = np.array([rgb(h) for h in ("#FF2FB0", "#19D3FF", "#FFE52A", "#FF8A1E", "#8B3DFF", "#3BE05A")])
    cell = np.where(on[..., None], pal[hue], rgb("#1A1A4A") * (0.85 + 0.3 * rng.random((g, g, 1))))
    col = cell[gj, gi]
    edge = (np.minimum(px % B, B - px % B) < 0.8) | (np.minimum(py % B, B - py % B) < 0.8)   # a thin dark line between blocks
    return np.where(edge[..., None], col * 0.72, col)

def neon_grid():
    """Near-black with glowing cyan grid lines every 1.2 studs."""
    S = 1.2
    def line(c): d = np.abs((c / S + 0.5) % 1 - 0.5) * S * K; return np.clip(1.15 * np.exp(-(d / 1.6) ** 2) + 0.5 * np.exp(-d / 6.0), 0, 1)
    a, b = np.where(SIDE, Y, X), np.where(FRONT, Y, Z)
    glow = np.clip(np.maximum(line(a), line(b)) + 0.5 * line(a) * line(b), 0, 1)[..., None]
    return rgb("#070B16") * (1 - glow) + (rgb("#19F0E0") * (1 - glow ** 6 * 0.5) + glow ** 6 * 0.5) * glow

def flame_decals():
    """Deep blue with hot-rod flames licking back from the nose: red outside, orange, a yellow heart."""
    sway = U + 0.35 * np.sin(Z * 0.8 + U * 0.7)
    s = (sway / 2.4 + 0.5) % 1
    tongue = (1 - np.abs(2 * s - 1)) ** 0.75                                 # 0 between tongues, 1 at a tongue's middle
    length = 1.5 + 9.0 * tongue ** 0.9 + 3.0 * np.exp(-U / 3.0) + 0.8 * np.sin(sway * 5.3)   # short between tongues: the blue shows well forward
    def inside(k, back): return Z < Z0 + 1.5 + k * length - back
    col = np.broadcast_to(rgb("#1B2260"), px.shape + (3,)) * (0.9 + 0.2 * noise(120, 5, 2))[..., None]
    for k, back, c in ((1.0, -0.22, "#5A0A10"), (1.0, 0, "#E8361C"), (0.74, 0.5, "#F7861C"), (0.5, 1.1, "#FFD43A")):
        col = pick(inside(k, back) & ~FRONT, rgb(c), col)                    # FRONT is mostly back-facing edges (wing and booster ends): they stay blue
    return col

def tie_dye():
    """A rainbow spiral from the middle of the plane, soft and blotchy like dyed cloth."""
    dx, dy, dz = np.where(SIDE, 1.4, X), np.where(TOP, 0.0, (Y - 1.0) * 1.5), Z + 1.0
    r, ang = np.sqrt(dx * dx + dy * dy + dz * dz), np.arctan2(dz, np.where(SIDE, 1.4 + (Y - 1.0) * 1.5, dx))
    h = (ang / (2 * np.pi) + 0.11 * r + 0.16 * (noise(90, 11, 3) - 0.5)) % 1.0
    h = (np.floor(h * 6) + np.clip(((h * 6) % 1 - 0.5) * 2.2 + 0.5, 0, 1)) / 6 % 1.0      # six bands with soft bleeding edges
    v = 0.86 + 0.14 * noise(40, 12, 2); s = 0.78 + 0.2 * noise(70, 13, 2)
    i = (h * 6).astype(int) % 6; f = h * 6 - np.floor(h * 6); p, q, t = v * (1 - s), v * (1 - s * f), v * (1 - s * (1 - f))
    return np.stack([np.choose(i, c) for c in ((v, q, p, p, t, v), (t, v, v, q, p, p), (p, p, t, v, v, q))], -1)

def jungle_camo():
    """Four-colour jungle camouflage: fresh leaf green, deep green, bark brown, near-black blobs with hard edges."""
    a, b, c = noise(150, 21, 3), noise(110, 22, 3), noise(80, 23, 2)
    col = np.broadcast_to(rgb("#5FA83A"), px.shape + (3,))
    col = pick(a > 0.54, rgb("#2C6B32"), col); col = pick(b > 0.6, rgb("#6E4B2C"), col)
    return pick(c > 0.68, rgb("#1C2B1E"), col)

SKINS = dict(carbon_fiber=carbon_fiber, racing_stripe=racing_stripe, eight_bit=eight_bit, neon_grid=neon_grid,
             flame_decals=flame_decals, tie_dye=tie_dye, jungle_camo=jungle_camo)
if __name__ == "__main__":
    for name in sys.argv[1:] or SKINS: finish(SKINS[name](), name)
