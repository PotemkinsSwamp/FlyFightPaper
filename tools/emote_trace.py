"""Traces a reference video for an emote into the rows of numbers its cut is posed from (docs/workshop/emote-making.md):

  python tools/emote_trace.py VIDEO.mp4 [--check=OUT_DIR] [--step=0.2]

The video is one of ours from Gemini (Alan runs the prompt): a plain grey mannequin on a lighter grey room, fixed
camera straight on, feet on one spot, a white thing in its right hand (Toy Pilot's paper plane). Per frame it finds
the figure (darker than the room), the white thing (brighter), the head and the trunk (what is left when thin parts
are worn away), the right hand (the arm's pixels touching the white thing, or the highest bit of an arm once the
thing has left the top of the picture) and the far end of the left arm. Prints a Luau table, a row every STEP
seconds: { right, up, lean, shift, left }: the right hand from the right shoulder in arm lengths (to the figure's
right, up), the trunk's lean in degrees (to its right), the hips' shift in body heights (to its right), the left
arm's angle out from hanging in degrees. The figure's right is the picture's left. --check saves six frames with
the found points circled: look at them before trusting the numbers.
"""
import os, subprocess, sys, tempfile
import numpy as np
from PIL import Image, ImageDraw

video = sys.argv[1]
check = next((a[8:] for a in sys.argv if a.startswith("--check=")), None)
STEP = float(next((a[7:] for a in sys.argv if a.startswith("--step=")), 0.2))
frames = tempfile.mkdtemp(prefix="emote_trace_")
subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", video, os.path.join(frames, "f%04d.png")], check=True)
fps = eval(subprocess.run(["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries", "stream=r_frame_rate", "-of", "csv=p=0", video],
                          capture_output=True, text=True).stdout.strip())
names = sorted(os.listdir(frames))


def lit(name):
    rgb = np.asarray(Image.open(os.path.join(frames, name)).convert("RGB")).astype(np.int16)
    grey = rgb.mean(axis=2)
    return rgb, grey, np.median(grey, axis=1, keepdims=True)


def worn(mask, r):  # a square of half-size r worn off every edge: thin arms, legs and the neck go
    m = mask.copy()
    for d in range(1, r + 1):
        m[:, d:] &= mask[:, :-d]; m[:, :-d] &= mask[:, d:]
    n = m.copy()
    for d in range(1, r + 1):
        n[d:, :] &= m[:-d, :]; n[:-d, :] &= m[d:, :]
    return n


high, wide = lit(names[0])[1].shape
scale = high / 360  # the pixel sizes below were set on a 640 x 360 video
px = lambda v: max(int(round(v * scale)), 1)
# the room is brighter in the middle: how much, across, from the rows over the figure's head
glow = np.median(np.concatenate([(lambda g, b: (g - b)[:px(50)])(*lit(n)[1:]) for n in names[::10]]), axis=0)
rows, half = [], 0
for i, name in enumerate(names):
    rgb, grey, back = lit(name)
    back = back + glow
    figure = grey < back - 9
    figure[:, :wide // 4] = False; figure[:, wide * 3 // 4:] = False
    thing = (grey > back + 12) & (grey > 222)
    thing[high * 2 // 3:, :] = False  # the floor's sheen
    ys, xs = np.nonzero(thing)
    row = {"t": i / fps, "thing": int(len(xs))}
    body = worn(figure, px(11))
    thick = np.zeros_like(body)
    ys, xs = np.nonzero(body)
    for dy in range(-px(14), px(14) + 1, 2):
        for dx in range(-px(14), px(14) + 1, 2):
            thick[np.clip(ys + dy, 0, high - 1), np.clip(xs + dx, 0, wide - 1)] = True
    thin = figure & ~thick  # the arms (and legs)
    bottom, top = np.nonzero(figure)[0].max(), ys.min()
    hy, hx = np.nonzero(body[top:top + px(16)])
    row["head"] = [hx.mean(), top + px(11) + hy.mean()]
    row["feet"] = bottom
    if i == 0: half = (bottom - top) // 2  # the hips' height over the feet, from the first frame (standing straight)
    row["hips"] = [np.nonzero(body[bottom - half - px(12):bottom - half + px(12)])[1].mean(), float(bottom - half)]
    ty, tx = np.nonzero(thin[: bottom - half + px(15)])
    row["hand"] = None
    if row["thing"] > px(40):
        py, pxs = np.nonzero(thing)
        near = np.zeros(len(tx), bool)
        for x, y in zip(pxs[::3], py[::3]):
            near |= (tx - x) ** 2 + (ty - y) ** 2 < px(10) ** 2
        if near.sum() > 8: row["hand"] = [tx[near].mean(), ty[near].mean()]
    row["armTop"] = [tx[ty <= ty.min() + px(8)].mean(), ty.min() + px(4)]
    row["left"] = [float(tx.max()), ty[tx >= tx.max() - 3].mean()]
    rows.append(row)
    if check and i in {int(len(names) * k / 6) for k in range(6)}:
        picture = Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8))
        draw = ImageDraw.Draw(picture)
        for key, colour in (("head", "blue"), ("hips", "green"), ("left", "orange"), ("hand", "magenta"), ("armTop", "cyan")):
            if row[key]: draw.ellipse([row[key][0] - 4, row[key][1] - 4, row[key][0] + 4, row[key][1] + 4], outline=colour, width=2)
        os.makedirs(check, exist_ok=True)
        picture.save(os.path.join(check, f"trace_{i:04d}.jpg"))

t = np.array([r["t"] for r in rows])
head = np.array([r["head"] for r in rows]); hips = np.array([r["hips"] for r in rows])
start = t < 0.5  # standing straight
height = rows[0]["feet"] - (head[0][1] - px(22))
trunk = hips[0][1] - head[0][1]
ACROSS, DOWN = 25 / 128 * trunk, 44 / 128 * trunk  # a shoulder from the head's middle (measured on Toy Pilot's first frame)


def joined(points):  # gaps filled in a straight line
    points = np.array([[np.nan, np.nan] if p is None else p for p in points], float)
    ok = ~np.isnan(points[:, 0])
    return np.stack([np.interp(t, t[ok], points[ok, k]) for k in range(2)], axis=1)


def smooth(a, width=5):
    pad = np.pad(a, ((width // 2, width // 2),) + ((0, 0),) * (a.ndim - 1), mode="edge")
    return np.stack([pad[i:i + width].mean(axis=0) for i in range(len(a))])


end = t[-1]
hand = joined([r["hand"] if r["hand"] else ([r["armTop"][0], r["armTop"][1] + px(8)] if r["t"] > 0.69 * end else None) for r in rows])
left = np.array([r["left"] for r in rows])
lean = np.arctan2(head[:, 0] - hips[:, 0], hips[:, 1] - head[:, 1])  # + to the picture's right
lean -= lean[start].mean()
cos, sin = np.cos(lean), np.sin(lean)
arm = hand - (head + np.stack([-ACROSS * cos - DOWN * sin, -ACROSS * sin + DOWN * cos], axis=1))
reach = np.hypot(arm[:, 0], arm[:, 1])
arm_length = np.percentile(reach, 97)
left_arm = left - (head + np.stack([ACROSS * cos - DOWN * sin, ACROSS * sin + DOWN * cos], axis=1))
left_angle = np.degrees(np.arctan2(left_arm[:, 0], left_arm[:, 1]))  # 0 hanging, 90 straight out
# while the right arm is over on the left the two can't be told apart, and a fist on the hip shows its elbow: from
# the first crossing on, the left arm's angle runs in a straight line to 30 (the cut puts the fist on the hip itself)
crossed = np.nonzero((hand[:, 0] > head[:, 0] - px(10)) & (t > end / 2))[0]
if len(crossed):
    ok = t < t[crossed[0]] - 0.1
    left_angle = np.interp(t, np.append(t[ok], [t[crossed[-1]] + 0.3, end + 1]), np.append(left_angle[ok], [30, 30]))
data = smooth(np.stack([-arm[:, 0] / arm_length, -arm[:, 1] / arm_length, -np.degrees(lean), -(hips[:, 0] - hips[start, 0].mean()) / height, left_angle], axis=1))
data[t >= 0.78 * end] = data[t >= 0.8 * end].mean(axis=0)  # the held ending: one pose (the cut adds its own sway)
data = smooth(data)
print(f"-- {len(rows)} frames at {fps:g} a second; body {height:.0f} px tall, arm {arm_length:.0f} px, trunk {trunk:.0f} px; white thing lost in {sum(r['thing'] <= px(40) for r in rows)} frames")
out = ["{ %.2f, %.2f, %.0f, %.3f, %.0f }" % tuple(data[min(int(round(k * STEP * fps)), len(rows) - 1)]) for k in range(int(round(end / STEP)) + 1)]
for k in range(0, len(out), 6):
    print("\t" + ", ".join(out[k:k + 6]) + ",")
