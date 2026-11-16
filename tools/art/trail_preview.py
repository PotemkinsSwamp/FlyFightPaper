"""A trail as a video, before any upload:
    python tools/art/trail_preview.py <id> [...]      -> .planning/skins/trails/<id>.mp4 (and <id>-frame.png)
Plays config/trails.json the way the game will, seen from above (Roblox turns ribbons and pieces to face the camera, so
every view shows them like this): a plane at its normal speed, then boosting, then back. Top: the whole trail, as other
players see it. Bottom: close up, about the size of your own view. Dark strips slide past so the trail is seen on light
and on dark. It imitates Roblox; the real look is confirmed in Studio after upload."""
import sys, json, math, random, subprocess
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]; PICS = ROOT / "assets/fx/trails"; OUT = ROOT / ".planning/skins/trails"
CFG = json.loads((ROOT / "config/trails.json").read_text()); W, H, FPS, SUB, SECONDS = 1280, 720, 24, 4, 9.0
NORMAL, BOOST, TAIL = 105.0, 150.0, -8.35                         # studs a second; the tail, studs behind the plane's middle
PANELS = [(0, 6.4, 0.84, "the whole trail, as other players see it"), (H // 2, 22.0, 0.66, "close up: about the size of your own view")]
SKY, DARK = np.array([139, 182, 224.0]), np.array([44, 54, 88.0])

def speed(t): return NORMAL + (BOOST - NORMAL) * (smooth((t - 3.0) / 0.6) - smooth((t - 6.0) / 0.8))
def smooth(x): x = min(max(x, 0.0), 1.0); return x * x * (3 - 2 * x)
def growth(v): return 1 + (CFG["fast_growth"] - 1) * min(max((v / NORMAL - 1) / (CFG["fast_at"] - 1), 0), 1)
def weave(t): return 4.5 * math.sin(t * 2.1) + 1.5 * math.sin(t * 3.7 + 1)
def picture(name): return np.asarray(Image.open(PICS / f"{name}.png").convert("RGBA"), float) / 255
def lerp(pair, k): return pair[0] + (pair[1] - pair[0]) * k
def blend(dst, rgb, a, glow):
    """Roblox's LightEmission: 0 lays paint over what is behind, 1 adds light to it."""
    dst *= 1 - a[..., None] * (1 - glow); dst += rgb * a[..., None]

def ribbon(frame, y0, scale, r, hist, t, px):
    """One ribbon in one panel: for every screen column behind the tail, which moment of the past it is, then the picture."""
    tex = picture(r["picture"]); th, tw = tex.shape[:2]; life = CFG["life"]
    ages = np.linspace(0, life, 240); when = t - ages
    wx = np.interp(when, hist[0], hist[1]); wy = np.interp(when, hist[0], hist[2]); g = np.interp(when, hist[0], hist[3])
    sx = px - (hist[1][-1] - wx) * scale                           # screen x of each past tail point (falls with age)
    cols = np.arange(max(0, int(sx[-1])), min(W, int(sx[0]) + 1))
    if len(cols) < 2: return
    age = np.interp(cols, sx[::-1], ages[::-1]); k = age / life
    yc = y0 + H / 4 - np.interp(cols, sx[::-1], wy[::-1]) * scale
    half = CFG["width"] * r["width"] * lerp(r["taper"], k) * np.interp(cols, sx[::-1], g[::-1]) * scale / 2
    world = np.interp(cols, sx[::-1], wx[::-1])
    u = k if r["mode"] == "stretch" else (world / r["repeat"]) % 1 if r["mode"] == "static" else ((hist[1][-1] - world) / r["repeat"]) % 1
    rows = np.arange(y0, y0 + H // 2)[:, None]; v = (rows - yc[None, :]) / np.maximum(half[None, :], 1e-3)
    inside = np.abs(v) < 1
    fy = np.clip((v * 0.5 + 0.5) * th - 0.5, 0, th - 1.001); fx = np.broadcast_to((u * tw - 0.5)[None, :], fy.shape)   # smoothed, as Roblox does
    iy, ix = fy.astype(int), np.floor(fx).astype(int); ky, kx = (fy - iy)[..., None], (fx - ix)[..., None]
    at = (lambda yy, xx: tex[yy, np.clip(xx, 0, tw - 1)]) if r["mode"] == "stretch" else (lambda yy, xx: tex[yy, xx % tw])
    s = (at(iy, ix) * (1 - kx) + at(iy, ix + 1) * kx) * (1 - ky) + (at(iy + 1, ix) * (1 - kx) + at(iy + 1, ix + 1) * kx) * ky
    a = s[..., 3] * inside * (1 - lerp(r["fade"], k))[None, :]
    a *= np.clip(half[None, :] / 0.75, 0, 1)                       # thinner than a pixel and a half: it fades out, as on a real screen
    rgb = s[..., :3] * np.array(r.get("color", [255, 255, 255]), float) * np.interp(cols, sx[::-1], g[::-1])[None, :, None] ** 0.5
    blend(frame[y0:y0 + H // 2, cols[0]:cols[-1] + 1], rgb, a, r.get("glow", 0))

def sprite(tex, p, piece, t):
    """A piece's picture now: its frame of the sheet (or two cross-fading), sized, turned."""
    n = piece.get("grid", 1); cell = tex.shape[0] // n; age = t - p["born"]; k = age / p["life"]
    def frame(i): i %= n * n; return tex[(i // n) * cell:(i // n + 1) * cell, (i % n) * cell:(i % n + 1) * cell]
    if piece.get("frames") == "random":
        step = age * piece["fps"]; i = int(step); pick = lambda j: random.Random(p["id"] * 977 + j).randrange(n * n)
        img = frame(pick(i)) * (1 - (step - i)) + frame(pick(i + 1)) * (step - i)
    else: img = frame(int(k * n * n) if piece.get("frames") == "once" else 0)
    return img, k

def pieces(frame, y0, scale, piece, alive, t, px, here):
    tex = picture(piece["picture"])
    for p in alive:
        img, k = sprite(tex, p, piece, t); size = lerp(piece["size"], k) * p["g"] * scale
        if size < 1.5: continue
        age = t - p["born"]; x = px - (here[0] - (p["x"] + p["vx"] * age)) * scale
        y = y0 + H / 4 - (p["y"] + p["vy"] * age + 0.5 * piece.get("rise", 0) * age * age) * scale
        im = Image.fromarray((img * 255).astype(np.uint8), "RGBA").resize((max(2, round(size)),) * 2, Image.BILINEAR)
        if p["rot"] or p["spin"]: im = im.rotate(p["rot"] + p["spin"] * age, Image.BILINEAR, expand=True)
        s = np.asarray(im, float) / 255; h, w = s.shape[:2]; x0, yy = round(x - w / 2), round(y - h / 2)
        ax, ay, bx, by = max(x0, 0), max(yy, y0), min(x0 + w, W), min(yy + h, y0 + H // 2)
        if ax >= bx or ay >= by: continue
        s = s[ay - yy:by - yy, ax - x0:bx - x0]; a = s[..., 3] * (1 - lerp(piece["fade"], k)) * min(1, k / 0.08)
        blend(frame[ay:by, ax:bx], s[..., :3] * np.array(p["color"], float) * p["g"] ** 0.5, a, piece.get("glow", 0))

def plane(frame, y0, scale, px, y):
    """Our plane from above, in plain cream paper: only there to give the trail something to come from."""
    d = Image.new("RGBA", (W, H // 2)); dr = ImageDraw.Draw(d); cy = H / 4 - y * scale
    P = lambda pts: [(px + (x - TAIL) * scale, cy + z * scale) for x, z in pts]
    dr.polygon(P([(8.3, 0), (-5.6, 6.2), (-7.2, 6.0), (-6.3, 1.5), (-8.35, 1.3), (-8.35, -1.3), (-6.3, -1.5), (-7.2, -6.0), (-5.6, -6.2)]), (238, 226, 205, 255), (150, 132, 108, 255))
    dr.polygon(P([(8.3, 0), (-8.35, 1.3), (-8.35, -1.3)]), (250, 242, 226, 255), (150, 132, 108, 255))
    for z in (-2.3, 2.3): dr.rectangle(P([(-8.9, z - 0.55), (-6.6, z + 0.55)]), (112, 116, 128, 255))
    s = np.asarray(d, float) / 255; blend(frame[y0:y0 + H // 2], s[..., :3] * 255, s[..., 3], 0)

def video(trail):
    spec = CFG["trails"][trail]; rng = random.Random(7); font = ImageFont.truetype("arialbd.ttf", 22); small = ImageFont.truetype("arial.ttf", 18)
    hist = [[], [], [], []]; x = 0.0; alive = [[] for _ in spec.get("pieces", [])]; owed = [0.0] * len(alive); nid = 0
    OUT.mkdir(parents=True, exist_ok=True); dest = OUT / f"{trail}.mp4"
    ff = subprocess.Popen(["ffmpeg", "-y", "-loglevel", "error", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}", "-r", str(FPS), "-i", "-",
                           "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "18", str(dest)], stdin=subprocess.PIPE)
    for n in range(int((SECONDS + CFG["life"]) * FPS * SUB)):       # one second of run-up so the video opens with a full trail
        t = n / (FPS * SUB) - CFG["life"]; v = speed(t); dt = 1 / (FPS * SUB); x += v * dt; y = weave(t); g = growth(v)
        for h, value in zip(hist, (t, x, y, g)): h.append(value)
        for i, piece in enumerate(spec.get("pieces", [])):
            alive[i] = [p for p in alive[i] if t - p["born"] < p["life"]]
            owed[i] += piece["rate"] * v / NORMAL * dt
            while owed[i] >= 1:
                owed[i] -= 1; nid += 1; a, d = rng.uniform(0, math.tau), rng.uniform(0, piece.get("drift", 0))
                alive[i].append({"id": nid, "born": t, "life": rng.uniform(*piece["life"]), "x": x, "y": y, "vx": d * math.cos(a), "vy": d * math.sin(a), "g": g,
                                 "rot": rng.uniform(0, 360) if piece.get("turn") else 0, "spin": rng.uniform(-1, 1) * piece.get("spin", 0), "color": rng.choice(piece["colors"])})
        if t < 0 or n % SUB: continue
        frame = np.empty((H, W, 3)); arrays = [np.array(h) for h in hist]
        for y0, scale, at, label in PANELS:
            px = W * at; world = x - (px - np.arange(W)) / scale
            strip = np.clip(1.5 - np.abs((world % 230) - 60) / 22, 0, 1)                # a dark strip 60 studs wide every 230
            frame[y0:y0 + H // 2] = (SKY * (1 - strip[:, None]) + DARK * strip[:, None])[None]
            for r in spec.get("ribbons", []): ribbon(frame, y0, scale, r, arrays, t, px)
            for piece, live in zip(spec.get("pieces", []), alive): pieces(frame, y0, scale, piece, live, t, px, (x, y))
            plane(frame, y0, scale, px, y)
        im = Image.fromarray(np.clip(frame, 0, 255).astype(np.uint8)); dr = ImageDraw.Draw(im)
        dr.line([(0, H // 2), (W, H // 2)], (255, 255, 255), 3)
        for y0, scale, at, label in PANELS: dr.text((18, y0 + 12), label, (255, 255, 255), small, stroke_width=2, stroke_fill=(30, 36, 60))
        name = trail.replace("_", " ").title(); boost = 3.0 <= t < 6.4
        dr.text((18, H - 40), f"{name}: {'BOOST' if boost else 'normal speed'}", (255, 232, 90) if boost else (255, 255, 255), font, stroke_width=2, stroke_fill=(30, 36, 60))
        ff.stdin.write(im.tobytes())
        if abs(t - 4.6) < 0.5 / FPS: im.save(OUT / f"{trail}-frame.png")
    ff.stdin.close(); ff.wait(); print(dest)

if __name__ == "__main__":
    for trail in sys.argv[1:] or CFG["trails"]: video(trail)
