"""A picture of the Weekly missions tab as a player would see it (explanation only, not game art)."""
import glob, random, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont
R = "D:/FlyFightPaper/"
OUT = sys.argv[1]
FONT = glob.glob("C:/Users/gutie/AppData/Local/Roblox/Versions/*/content/fonts/Kalam-Regular.ttf")[0]
def f(n): return ImageFont.truetype(FONT, n)
INK = (40, 30, 24)
W, H = 1920, 1080
rnd = random.Random(3)

# background: the real corkboard from a Shop screenshot, stretched and softened
shot = Image.open(R + ".planning/skins/chest-shop-style/odds.png").convert("RGB")
bg = shot.resize((W, int(shot.height * W / shot.width * 1.44))).crop((0, 0, W, H)).filter(ImageFilter.GaussianBlur(3))
page = bg.convert("RGBA")

# the notebook sheet: cream paper, blue rules, red margin, punched holes, a ragged edge
x0, y0, x1, y1 = 250, 60, 1670, 1040
sheet = Image.new("RGBA", (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(sheet)
pts = []
for x in range(x0, x1 + 1, 14): pts.append((x, y0 + rnd.uniform(-3, 3)))
for y in range(y0, y1 + 1, 14): pts.append((x1 + rnd.uniform(-3, 3), y))
for x in range(x1, x0 - 1, -14): pts.append((x, y1 + rnd.uniform(-3, 3)))
for y in range(y1, y0 - 1, -14): pts.append((x0 + rnd.uniform(-3, 3), y))
d.polygon(pts, fill=(240, 226, 208, 255))
noise = (np.random.default_rng(1).normal(0, 3.2, (H, W))).astype(int)
a = np.asarray(sheet).astype(int); a[..., :3] = np.clip(a[..., :3] + noise[..., None], 0, 255); sheet = Image.fromarray(a.astype(np.uint8), "RGBA"); d = ImageDraw.Draw(sheet)
for y in range(y0 + 150, y1 - 10, 40): d.line([(x0 + 6, y), (x1 - 6, y)], fill=(150, 185, 215, 255), width=2)
for x in (x0 + 150, x0 + 158): d.line([(x, y0 + 4), (x, y1 - 4)], fill=(222, 120, 120, 255), width=2)
shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0)); ImageDraw.Draw(shadow).polygon([(p[0] + 10, p[1] + 14) for p in pts], fill=(0, 0, 0, 110))
page.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(14))); page.alpha_composite(sheet)
d = ImageDraw.Draw(page)
for y in range(y0 + 70, y1 - 40, 105): d.ellipse([x0 + 34, y, x0 + 70, y + 30], fill=(44, 36, 30, 255))
# real pieces from the game's art: the tape at the top and the red close button
tape = shot.crop((795, 30, 1135, 104)).convert("RGBA"); page.alpha_composite(tape, (790, 30))
close = shot.crop((1428, 98, 1490, 160)).convert("RGBA"); page.alpha_composite(close, (1570, 100))

def text(xy, s, size, fill=INK, anchor="la", bold=True):
    d.text(xy, s, font=f(size), fill=fill, anchor=anchor, stroke_width=1 if bold else 0, stroke_fill=fill)
def width(s, size): return d.textlength(s, font=f(size))

# title and the two tabs (Weekly picked)
text((x0 + 200, 118), "Missions", 64)
def tab(x, label, on):
    w = width(label, 40) + 60
    d.rounded_rectangle([x, 128, x + w, 190], 12, fill=(255, 214, 92, 255) if on else (226, 210, 190, 255), outline=INK, width=3)
    text((x + w / 2, 160), label, 40, INK if on else (110, 96, 84), "mm")
    return x + w + 18
nx = tab(800, "Daily", False); tab(nx, "Weekly", True)
text((x1 - 52, 238), "New missions in 3 days 14 h", 30, (90, 74, 62), "rs", bold=False)

chests = Image.open(R + "assets/ui/hangarshelf/chests/classroom-chests.png").convert("RGBA")
def chest(i, size):
    c = chests.crop(((i % 2) * 512, (i // 2) * 512, (i % 2) * 512 + 512, (i // 2) * 512 + 512)); return c.resize((size, size), Image.LANCZOS)

ROWS = [
    ("Play 3 matches", 3, 3, "3 / 3", ("chest", 1, "Sticker chest"), "claim"),
    ("Get 40 folds with the Thumbtack", 17, 40, "17 / 40", ("paper", "1,500 Paper"), None),
    ("Earn 600 points in the zone (Airspace Control)", 250, 600, "250 / 600", ("paper", "1,500 Paper"), None),
    ("Finish all 3 daily missions on 5 days", 2, 5, "2 / 5 days", ("chest", 2, "Blue Ribbon chest"), "days"),
]
top, rowh = 252, 190
boxes = []
def note(name, box): boxes.append((name, box))
for k, (words, have, need, count, reward, extra) in enumerate(ROWS):
    y = top + k * rowh
    card = [x0 + 190, y, x1 - 40, y + rowh - 22]
    done = have >= need
    d.rounded_rectangle([card[0] + 5, card[1] + 7, card[2] + 5, card[3] + 7], 16, fill=(0, 0, 0, 40))
    d.rounded_rectangle(card, 16, fill=(250, 241, 226, 255) if not done else (236, 248, 222, 255), outline=(120, 100, 84, 255), width=2)
    text((card[0] + 30, y + 20), words, 40); note("title%d" % k, d.textbbox((card[0] + 30, y + 20), words, font=f(40), stroke_width=1))
    bx0, by0, bx1, by1 = card[0] + 30, y + 104, card[0] + 400, y + 140
    if extra == "days":   # seven little day boxes instead of a bar
        for i, (day, state) in enumerate(zip("MTWTFSS", ["done", "done", "missed", "today", "", "", ""])):
            bx = bx0 + i * 56
            d.rounded_rectangle([bx, by0 - 8, bx + 52, by1 + 8], 8, fill={"done": (120, 200, 110, 255), "missed": (222, 210, 196, 255), "today": (255, 236, 160, 255)}.get(state, (245, 236, 222, 255)), outline=INK, width=4 if state == "today" else 2)
            if state == "done": d.line([(bx + 13, by0 + 18), (bx + 23, by0 + 29), (bx + 40, by0 + 4)], fill=INK, width=5, joint="curve")
            else: text((bx + 26, by0 + 18), day, 28, INK if state != "missed" else (150, 135, 120), "mm")
        text((bx0 + 7 * 56 + 4, by0 + 18), count, 30, INK, "lm"); note("count%d" % k, d.textbbox((bx0 + 7 * 56 + 4, by0 + 18), count, font=f(30), anchor="lm"))
    else:
        d.rounded_rectangle([bx0, by0, bx1, by1], 14, fill=(233, 220, 202, 255), outline=INK, width=3)
        fw = int((bx1 - bx0 - 6) * have / need)
        if fw > 20: d.rounded_rectangle([bx0 + 3, by0 + 3, bx0 + 3 + fw, by1 - 3], 11, fill=(96, 190, 96, 255) if done else (110, 175, 235, 255))
        text((bx1 + 16, (by0 + by1) / 2 + 2), count, 30, INK, "lm")
    rx = card[0] + 625
    text((rx, y + 80), "Reward", 24, (110, 96, 84), bold=False)
    if reward[0] == "chest":
        page.alpha_composite(chest(reward[1], 64), (int(rx - 4), int(y + 104)))
        text((rx + 70, y + 136), reward[2], 30, INK, "lm"); note("reward%d" % k, d.textbbox((rx + 70, y + 136), reward[2], font=f(30), anchor="lm", stroke_width=1))
    else:
        d.rounded_rectangle([rx, y + 110, rx + 210, y + 160], 12, fill=(92, 62, 40, 255), outline=(50, 34, 22, 255), width=2)
        text((rx + 105, y + 135), reward[1], 32, (255, 236, 196), "mm"); note("reward%d" % k, [rx, y + 110, rx + 210, y + 160])
    bx = card[2] - 214
    note("button%d" % k, [bx, y + 40, bx + 190, y + 124])
    if extra == "claim":
        d.rounded_rectangle([bx + 4, y + 46, bx + 194, y + 130], 16, fill=(30, 110, 40, 255))
        d.rounded_rectangle([bx, y + 40, bx + 190, y + 124], 16, fill=(78, 196, 70, 255), outline=INK, width=3)
        d.text((bx + 95, y + 82), "Claim!", font=f(44), fill=(255, 255, 255), anchor="mm", stroke_width=3, stroke_fill=INK)
    else:
        d.rounded_rectangle([bx, y + 40, bx + 190, y + 124], 16, fill=(226, 216, 204, 255), outline=(150, 135, 120, 255), width=3)
        text((bx + 95, y + 82), "Not yet", 34, (130, 116, 102), "mm", bold=False)
# words must not run into the reward or button columns
for name, (a0, a1, a2, a3) in boxes:
    for other, (b0, b1, b2, b3) in boxes:
        if name < other and name[-1] == other[-1] and a0 < b2 and b0 < a2 and a1 < b3 and b1 < a3: print("OVERLAP", name, other)
page.convert("RGB").save(OUT, quality=92)
print(OUT)
