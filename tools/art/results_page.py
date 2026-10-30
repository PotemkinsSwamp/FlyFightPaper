"""Draw the results card's notebook page (Alan 2026-10-29: a page made to fit, not a small card stretched; it must
read as loose-leaf torn from a notebook: binder holes, a frayed torn edge, taped up, not pinned).

    python tools/art/results_page.py     -> assets/ui/results/source/notebook-page.png

The picture is the card box in RoundEnd.luau (680 x 900 units) at 1.024 pixels a unit, so a unit there is a known
pixel here. Paper grain: the old index card's real paper photo with its printed lines taken out, mirrored to fill.
Ruled lines sit under the six rows (places 1-5 and your own row), the red line under the heads, the red margin
between the place column and the names; the level part below is plain paper. Masking tape (the game's tape-label
piece) at the top corners. Keep the numbers in step with RoundEnd's ROW_TOP / ROW_PITCH and its columns.
"""
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
W, H, S = 680, 900, 1.024
PAPER_BOX = (10, 20, 670, 890)  # the sheet inside the card box; tape reaches past it
HEAD_LINE, ROW_TOP, ROW_PITCH, ROWS, MARGIN = 190, 190, 72, 6, 120
HOLES_X, HOLES_Y, HOLE_R = 40, (94, 455, 816), 12  # three binder holes, 4.25" apart on an 8" x 10.5" sheet
BLUE, RED = (110, 150, 205), (215, 95, 95)
rng = np.random.default_rng(29)
w, h = round(W * S), round(H * S)
px = lambda v: round(v * S)

# Real paper grain: the index card's paper (x 120-1000, y 95-420 in its photo) with its ruled rows replaced by the
# rows just above them, stacked mirrored to fill the page.
card = np.array(Image.open(ROOT / "assets/ui/ingame/source/index-card.png").convert("RGB"), float)[95:420, 120:1000]
tint = card[..., 2] - card[..., 0]  # blue ink lifts blue over red; red ink the other way
row = np.abs(tint - np.median(tint)).mean(axis=1)
ink = row > np.median(row) + 3 * np.std(row[row < np.percentile(row, 80)])
ink = np.convolve(ink, np.ones(7), "same") > 0  # the line and three rows either side (its soft print edge)
clean = card.copy()
for y in np.where(ink)[0]:
    src = y - 1
    while src > 0 and ink[src]: src -= 1
    clean[y] = clean[src]
tile = np.concatenate([clean, clean[::-1]], axis=0)
grain = np.concatenate([tile] * (h // tile.shape[0] + 1), axis=0)[:h]
grain = np.concatenate([grain, grain[:, ::-1]], axis=1)[:, :w]
paper = Image.fromarray(np.clip(grain * 1.03, 0, 255).astype(np.uint8), "RGB").convert("RGBA")

draw = ImageDraw.Draw(paper)
def across(at, colour, width):
    draw.line([(px(PAPER_BOX[0]), px(at)), (px(PAPER_BOX[2]), px(at))], fill=colour + (190,), width=width)
across(HEAD_LINE, RED, 3)
for i in range(1, ROWS + 1):
    across(ROW_TOP + i * ROW_PITCH, BLUE, 2)
draw.line([(px(MARGIN), px(PAPER_BOX[1])), (px(MARGIN), px(PAPER_BOX[3]))], fill=RED + (160,), width=2)
paper = paper.filter(ImageFilter.GaussianBlur(0.4))

# The sheet's outline: a frayed torn edge down the left (torn out of a notebook: small ragged tabs), the other edges
# straight with a slight wobble; then the three binder holes punched through.
x0, y0, x1, y1 = (px(v) for v in PAPER_BOX)
left = []
y = y0
while y < y1:
    left.append((x0 + rng.uniform(0, px(9)) + (px(4) if rng.random() < 0.25 else 0), y))
    y += rng.uniform(2, 7)
left.append((x0 + px(4), y1))
outline = [(x0 + px(3), y0)] + [(x, y0 + rng.uniform(-1, 1)) for x in np.linspace(x0 + px(20), x1, 12)]
outline += [(x1 + rng.uniform(-1, 1), y) for y in np.linspace(y0, y1, 14)]
outline += [(x, y1 + rng.uniform(-1, 1)) for x in np.linspace(x1, x0 + px(20), 12)] + left[::-1]
mask = Image.new("L", (w, h), 0)
md = ImageDraw.Draw(mask)
md.polygon(outline, fill=255)
for hy in HOLES_Y:
    md.ellipse([px(HOLES_X - HOLE_R), px(hy - HOLE_R), px(HOLES_X + HOLE_R), px(hy + HOLE_R)], fill=0)
mask = mask.filter(ImageFilter.GaussianBlur(0.5))
paper.putalpha(mask)
# A faint grey rim inside each hole and along the torn edge, where the paper fibres show.
rim = Image.new("L", (w, h), 0)
rd = ImageDraw.Draw(rim)
for hy in HOLES_Y:
    rd.ellipse([px(HOLES_X - HOLE_R) - 2, px(hy - HOLE_R) - 2, px(HOLES_X + HOLE_R) + 2, px(hy + HOLE_R) + 2], outline=90, width=2)
rd.line(left, fill=60, width=2)
shade = Image.new("RGBA", (w, h), (120, 110, 95, 255))
shade.putalpha(Image.fromarray(np.minimum(np.array(rim), np.array(mask)).astype(np.uint8)))
paper.alpha_composite(shade.filter(ImageFilter.GaussianBlur(0.8)))

# A soft shadow under the sheet, then the sheet.
page = Image.new("RGBA", (w, h), (0, 0, 0, 0))
shadow = Image.new("RGBA", (w, h), (40, 30, 20, 0))
shadow.putalpha(mask.point(lambda a: a * 0.35).filter(ImageFilter.GaussianBlur(5)))
page.alpha_composite(shadow, (2, 4))
page.alpha_composite(paper)

# Masking tape over the top corners: the tape strip's two torn ends joined, about 180 x 52 units, tilted.
strip = Image.open(ROOT / "assets/ui/ingame/source/tape-label.png").convert("RGBA")
strip = strip.crop(strip.getchannel("A").getbbox())
cut = strip.width // 4
tape = Image.new("RGBA", (cut * 2, strip.height))
tape.paste(strip.crop((0, 0, cut, strip.height)), (0, 0))
tape.paste(strip.crop((strip.width - cut, 0, strip.width, strip.height)), (cut, 0))
tape = tape.resize((px(180), px(52)), Image.LANCZOS)
for cx, cy, turn in ((px(60), px(36), 38), (w - px(60), px(36), -38)):
    piece = tape.rotate(turn, expand=True, resample=Image.BICUBIC)
    piece.putalpha(piece.getchannel("A").point(lambda a: a * 0.92))
    layer = Image.new("RGBA", (w, h))
    layer.paste(piece, (cx - piece.width // 2, cy - piece.height // 2), piece)  # may hang past the box's edge
    page.alpha_composite(layer)

# ui_pieces.py trims each piece to its visible pixels; two nearly clear corner pixels keep the whole card box.
page.putpixel((0, 0), (0, 0, 0, 1))
page.putpixel((w - 1, h - 1), (0, 0, 0, 1))
out = ROOT / "assets/ui/results/source/notebook-page.png"
page.save(out)
print(out, page.size, "ruled rows removed from the grain photo:", int(ink.sum()))
