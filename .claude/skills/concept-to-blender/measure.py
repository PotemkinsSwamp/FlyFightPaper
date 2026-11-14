"""Marked-up measuring sheet of a concept picture: every line is one measurement, given as a share of one reference
length (the body), corrected for the picture's camera angle. Also samples the concept's colours.

    python .claude/skills/concept-to-blender/measure.py SPEC.json      (example: crane-measure.json, beside this file)

SPEC: image, out, title, crop [x0, y0, x1, y1], zoom, camera {yaw, pitch} (degrees: yaw 0 = pure side view, 90 = from
the front; pitch = above level), facing ("left" or "right": which way the nose points in the picture),
ref {a, b, studs, what}, lines [{tag, what, a, b, spot, old?}] (a, b: picture pixels; spot: where the tag sits; old: the
last build's size in studs), colours {name: [x, y]}, notes [lines of text].
Lines are read as lying in the model's middle plane (nose-tail-up); a width across can only be read from visible top
faces, so say so in its "what".
"""
import json, math, sys
from PIL import Image, ImageDraw, ImageFont

spec = json.load(open(sys.argv[1], encoding="utf-8"))
yaw, pitch = (math.radians(spec["camera"][k]) for k in ("yaw", "pitch"))
FW = ((-1 if spec.get("facing", "left") == "left" else 1) * math.cos(yaw), math.sin(yaw) * math.sin(pitch))  # forward, per unit
UPY = -math.cos(pitch)                                                                                      # up, per unit
def true_len(a, b):
    """Length and angle above level of picture line a-b, in the model's middle plane."""
    dx, dy = b[0] - a[0], b[1] - a[1]; f = dx / FW[0]; u = (dy - f * FW[1]) / UPY
    return math.hypot(f, u), math.degrees(math.atan2(u, abs(f)))

BG, INK, RED = (238, 233, 221), (30, 30, 34), (180, 30, 30)
F = lambda n, b=False: ImageFont.truetype("C:/Windows/Fonts/segoeui%s.ttf" % ("b" if b else ""), n)
PALETTE = [(255, 70, 60), (255, 150, 30), (255, 255, 255), (120, 255, 90), (255, 90, 230), (70, 235, 255), (255, 190, 220), (200, 170, 255), (160, 110, 60), (150, 150, 150)]
src = Image.open(spec["image"]).convert("RGB")
x0, y0, x1, y1 = spec["crop"]; K = spec.get("zoom", 2)
im = src.crop((x0, y0, x1, y1)).resize(((x1 - x0) * K, (y1 - y0) * K), Image.LANCZOS); d = ImageDraw.Draw(im)
P = lambda p: ((p[0] - x0) * K, (p[1] - y0) * K)
ref = spec["ref"]; ref_len = true_len(ref["a"], ref["b"])[0]
rows = [dict(tag="1", what=ref["what"], a=ref["a"], b=ref["b"], spot=ref["spot"], col=(255, 221, 51))]
rows += [dict(l, col=PALETTE[i % len(PALETTE)]) for i, l in enumerate(spec["lines"])]
for r in rows:
    a, b, s = P(r["a"]), P(r["b"]), P(r["spot"]); mid = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
    d.line([s, mid], fill=(0, 0, 0), width=3); d.line([a, b], fill=(0, 0, 0), width=11); d.line([a, b], fill=r["col"], width=6)
    for q in (a, b): d.ellipse([q[0] - 8, q[1] - 8, q[0] + 8, q[1] + 8], fill=r["col"], outline=(0, 0, 0), width=2)
    d.ellipse([s[0] - 26, s[1] - 26, s[0] + 26, s[1] + 26], fill=r["col"], outline=(0, 0, 0), width=3)
    d.text(s, r["tag"], font=F(34, True), fill=(0, 0, 0), anchor="mm")
    r["len"], r["angle"] = true_len(r["a"], r["b"]); r["share"] = r["len"] / ref_len
    print("%-3s share %.3f  angle %+4.0f  %s" % (r["tag"], r["share"], r["angle"], r["what"]))
colours = {}
for name, (cx, cy) in spec.get("colours", {}).items():
    px = [src.getpixel((cx + i, cy + j)) for i in range(-3, 4) for j in range(-3, 4)]
    colours[name] = tuple(round(sum(p[k] for p in px) / len(px)) for k in range(3)); print("colour", name, colours[name])

M, RH = 60, 58; notes = spec.get("notes", [])
W = im.width + 2 * M; top = 150
H = top + im.height + 50 + RH * (len(rows) + 1) + (130 if colours else 0) + 50 * len(notes) + 70
sheet = Image.new("RGB", (W, H), BG); s = ImageDraw.Draw(sheet)
s.text((M, 40), spec["title"], font=F(56, True), fill=INK); sheet.paste(im, (M, top))
y = top + im.height + 40; cx = [M, M + 110, W - 900, W - 650, W - 360]
has_old = any("old" in r for r in rows)
for x, t in zip(cx, ("", "What", "Share of line 1", "Studs", "Last build had" if has_old else "")): s.text((x, y), t, font=F(32, True), fill=INK)
for r in rows:
    y += RH
    s.rounded_rectangle([cx[0], y + 2, cx[0] + 48, y + 48], 22, fill=r["col"], outline=(0, 0, 0), width=2)
    s.text((cx[0] + 24, y + 24), r["tag"], font=F(28, True), fill=(0, 0, 0), anchor="mm")
    s.text((cx[1], y + 3), r["what"], font=F(31), fill=INK); s.text((cx[2], y + 3), "%.2f" % r["share"], font=F(31), fill=INK)
    s.text((cx[3], y + 3), "%.1f" % (r["share"] * ref["studs"]), font=F(31), fill=INK)
    if "old" in r: s.text((cx[4], y + 3), "%.2g" % r["old"], font=F(31, True), fill=RED)
y += RH + 20
if colours:
    x = M
    for name, c in colours.items():
        s.rectangle([x, y, x + 90, y + 70], fill=c, outline=(0, 0, 0), width=2); s.text((x + 104, y + 14), name, font=F(30), fill=INK)
        x += 124 + int(s.textlength(name, font=F(30))) + 30
    y += 110
for line in notes: s.text((M, y), line, font=F(33), fill=INK); y += 50
sheet.save(spec["out"], quality=92); print(spec["out"], sheet.size)
