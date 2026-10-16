"""Draw the fan-wind particle pictures (Alan picked the white swirls, assets/references/world-pieces/fan-wind.png):
  python tools/art/wind_sprites.py  -> assets/fx/wind-swirl.png (a curling white wind line), assets/fx/paper-bit.png
Plain shapes on transparency, so nothing for image moderation to misread."""
import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

OUT = Path(__file__).resolve().parents[2] / "assets/fx"
W, H, S = 256, 512, 4                      # drawn 4x bigger, then shrunk for smooth edges


def swirl():
    im = Image.new("RGBA", (W * S, H * S), (255, 255, 255, 0)); d = ImageDraw.Draw(im)
    pts, n = [], 900
    for i in range(n):                      # a wavy line rising, then curling into a small spiral at the top
        t = i / (n - 1)
        if t < .75:
            u = t / .75
            x, y = .5 + .18 * math.sin(u * 2 * math.pi), .96 - .66 * u
        else:
            u = (t - .75) / .25                 # spiral: start heading up-left, wind inward
            r = .16 * (1 - .65 * u); a = math.pi * (0 + 1.7 * u)
            x, y = .5 + .16 - r * math.cos(a), .30 - r * math.sin(a) * 1.1 + 0
        pts.append((x * W * S, y * H * S))
    for i, (x, y) in enumerate(pts):        # round dabs: tapered, smooth edges
        t = i / n
        r = (1.5 + 6 * math.sin(math.pi * min(1, t * 1.15))) * S
        d.ellipse([x - r, y - r, x + r, y + r], fill=(255, 255, 255, 255))
    glow = im.filter(ImageFilter.GaussianBlur(6 * S)); glow.putalpha(glow.getchannel("A").point(lambda v: v // 2))
    out = Image.alpha_composite(glow, im).resize((W, H), Image.LANCZOS)
    out.save(OUT / "wind-swirl.png")


def paper_bit():
    im = Image.new("RGBA", (64 * S, 64 * S), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    d.polygon([(8 * S, 10 * S), (56 * S, 6 * S), (54 * S, 56 * S), (10 * S, 58 * S)], fill=(246, 236, 214, 255))
    d.line([(8 * S, 10 * S), (54 * S, 56 * S)], fill=(225, 210, 182, 255), width=2 * S)   # a fold line
    im.resize((64, 64), Image.LANCZOS).save(OUT / "paper-bit.png")


OUT.mkdir(parents=True, exist_ok=True); swirl(); paper_bit(); print("wrote", OUT)
