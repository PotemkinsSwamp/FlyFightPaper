"""Draw the round's report card (docs/plan/REPORT-CARD-PLAN.md, Alan OK'd 2026-11-11) and the red pen ring.

    python tools/art/report_card.py   -> assets/ui/results/ready/report-card.png, red-ring.png

The card is the results page box in RoundEnd.luau (680 x 900 units) at 1024 / 900 pixels a unit (Roblox keeps at most
1024), so a unit there is a known pixel here. Only paper, printing and lines: every word, name, number and grade is
game text. Keep TOP / HEAD / PITCH / COLS / NOTE / BOX in step with RoundEnd's.
"""
import math
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'assets/ui/results/ready'
W, H, S = 680, 900, 1024 / 900
TOP, HEAD, PITCH, ROWS = 190, 46, 58, 6               # the table: head row, then places 1-5 and your own row
COLS = (40, 92, 268, 336, 418, 500, 568, 640)         # place | pupil | folds | assists | crashes | pts | grade
NOTE = (236, 642, 634)                                # the teacher's note line: x from, y, x to
BOX = (500, 50, 640, 172)                             # your place / team score
SEAL = (98, 104, 46)
NAVY, BAND = (38, 58, 116), (214, 224, 242)
rng = np.random.default_rng(11)
px = lambda v: round(v * S)


def paper():
    w, h = px(W), px(H)
    base = np.ones((h, w, 3)) * np.array([247, 239, 216], float)
    grain = Image.fromarray(rng.normal(128, 40, (h, w)).clip(0, 255).astype('uint8')).filter(ImageFilter.GaussianBlur(1.0))
    base += (np.array(grain, float)[..., None] - 128) * 0.10
    yy, xx = np.mgrid[0:h, 0:w]
    edge = np.minimum.reduce([xx, yy, w - xx, h - yy]) / px(40)
    base *= (0.93 + 0.07 * np.clip(edge, 0, 1))[..., None]
    im = Image.fromarray(base.clip(0, 255).astype('uint8')).convert('RGBA')
    mask = Image.new('L', im.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((px(6), px(10), px(W - 6), px(H - 6)), radius=px(10), fill=255)
    im.putalpha(mask)
    return im


def line(d, pts, width, fill=NAVY):
    d.line([(px(x), px(y)) for x, y in pts], fill=fill, width=max(1, round(width * S)))


def card():
    im = paper()
    d = ImageDraw.Draw(im)
    d.rectangle((px(22), px(26), px(W - 22), px(H - 22)), outline=NAVY, width=px(3))
    d.rectangle((px(30), px(34), px(W - 30), px(H - 30)), outline=NAVY, width=px(1))
    cx, cy, r = SEAL  # the school seal: two rings and a paper plane
    d.ellipse((px(cx - r), px(cy - r), px(cx + r), px(cy + r)), outline=NAVY, width=px(3))
    d.ellipse((px(cx - r + 8), px(cy - r + 8), px(cx + r - 8), px(cy + r - 8)), outline=NAVY, width=px(1))
    d.polygon([(px(x), px(y)) for x, y in ((cx - 26, cy + 10), (cx + 28, cy - 16), (cx - 4, cy + 22))], fill=(240, 236, 226), outline=NAVY)
    line(d, ((cx + 28, cy - 16), (cx - 8, cy + 8), (cx - 4, cy + 22)), 2)
    d.rectangle(tuple(px(v) for v in BOX), outline=NAVY, width=px(2))
    bottom = TOP + HEAD + PITCH * ROWS
    d.rectangle((px(COLS[0]), px(TOP), px(COLS[-1]), px(TOP + HEAD)), fill=BAND)
    d.rectangle((px(COLS[0]), px(TOP), px(COLS[-1]), px(bottom)), outline=NAVY, width=px(2))
    for x in COLS[1:-1]:
        line(d, ((x, TOP), (x, bottom)), 1)
    for i in range(ROWS + 1):
        y = TOP + HEAD + i * PITCH
        line(d, ((COLS[0], y), (COLS[-1], y)), 1)
    line(d, ((NOTE[0], NOTE[1]), (NOTE[2], NOTE[1])), 1, (170, 190, 220))
    tape = Image.open(ROOT / 'assets/ui/ingame/ready/tape-label.png').convert('RGBA').resize((px(150), px(28)), Image.LANCZOS)
    layer = Image.new('RGBA', im.size, (0, 0, 0, 0))
    for x, angle in ((26, 45), (W - 26, -45)):  # a short strip across each top corner
        t = tape.rotate(angle, expand=True, resample=Image.BICUBIC)
        layer.paste(t, (round(px(x) - t.width / 2), round(px(26) - t.height / 2)))
    return Image.alpha_composite(im, layer)


def ring():
    """A red pen loop drawn a little more than once round, for the place box and A+ grades."""
    w, h, k = 400, 260, 4
    big = Image.new('RGBA', (w * k, h * k), (0, 0, 0, 0))
    d = ImageDraw.Draw(big)
    pts = []
    for i in range(120):
        a = -2.2 + 1.15 * 2 * math.pi * i / 119
        wob = 1 + 0.05 * math.sin(3 * a) + rng.normal(0, 0.006)
        pts.append((w * k / 2 + (w / 2 - 14) * k * wob * math.cos(a), h * k / 2 + (h / 2 - 14) * k * wob * math.sin(a)))
    d.line(pts, fill=(200, 38, 38, 255), width=9 * k, joint='curve')
    return big.resize((w, h), Image.LANCZOS)


if __name__ == '__main__':
    card().save(OUT / 'report-card.png')
    ring().save(OUT / 'red-ring.png')
