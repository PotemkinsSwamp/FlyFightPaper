"""The trails' ribbon pictures, drawn by code. Nothing is uploaded.
    python tools/art/trail_pictures.py        -> assets/fx/trails/<name>.png
A ribbon picture is a 512 x 64 strip spanning the whole trail; it is see-through near its long edges (no paint within
4 px of them, or a hard line shows). The trails' pieces are 3D models, built in trail_preview.py."""
from pathlib import Path
import numpy as np
from PIL import Image

OUT = Path(__file__).resolve().parents[2] / "assets/fx/trails"

def pnoise(h, w, size, seed):
    """Smooth noise 0..1 that repeats at its edges; `size` is the lump size in px."""
    rng = np.random.default_rng(seed); f = np.fft.fft2(rng.standard_normal((h, w)))
    fy, fx = np.fft.fftfreq(h)[:, None], np.fft.fftfreq(w)[None, :]
    n = np.fft.ifft2(f * np.exp(-(fx ** 2 + fy ** 2) * size ** 2 * 6)).real
    return (n - n.min()) / (n.max() - n.min())
def step(lo, hi, x): t = np.clip((x - lo) / (hi - lo), 0, 1); return t * t * (3 - 2 * t)
def band(name, rgb, alpha):
    """Save a strip: colour (h, w, 3) and coverage 0..1, faded to nothing at its long edges."""
    h, w = alpha.shape; v = np.abs(np.arange(h) + 0.5 - h / 2) / (h / 2)
    alpha = alpha * step(1.0, 0.72, v)[:, None]; alpha[:4] = alpha[-4:] = 0
    Image.fromarray(np.dstack([rgb, alpha * 255]).round().astype(np.uint8)).save(OUT / f"{name}.png")

def rainbow():
    """Holo Rainbow's ribbon: six bands across it in the Holographic skin's colours, streaked along its length."""
    cols = np.array([[int(h[i:i + 2], 16) for i in (1, 3, 5)] for h in ("#FF4AC8", "#FF9A4A", "#FFE04A", "#4CF0A0", "#32C8FF", "#7A5CFF")], float)
    v = (np.arange(64) + 0.5 - 8) / 48 * 6                                             # 6 bands between rows 8 and 56
    pos = np.clip(v[:, None] + (pnoise(64, 512, 30, 41) - 0.5) * 0.5, 0, 5.999)
    i = np.floor(pos).astype(int); f = step(0.78, 1.0, pos - i)[..., None]             # bands bleed a little at their joins
    rgb = cols[i] * (1 - f) + cols[np.minimum(i + 1, 5)] * f
    streak = np.tile(pnoise(64, 8, 3, 42).mean(1, keepdims=True), (1, 512)) * 0.5 + pnoise(64, 512, 40, 43) * 0.5
    band("trail-rainbow", np.clip(rgb * (0.9 + 0.2 * streak[..., None]), 0, 255), np.full((64, 512), 0.96))

if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True); rainbow(); print(OUT / "trail-rainbow.png")
