"""A moving Rare skin as a video on real planes, before any upload:
    python tools/art/skin_motion.py <id> [seconds]      -> .planning/skins/rares/<id>.mp4
Plays config/skin-motion.json the way the game will: every frame, each layer picture (rare_sheets.py) is slid, turned or
placed over the still sheet and its glow added, giving one colour sheet and one glow sheet; skin_preview.py (FRAMES=1)
renders them on three builds (starter from behind, blunt nose from the front, tube body from above) and ffmpeg joins the
frames. A layer's picture smears past its own edge like a Roblox Decal's does. No soft halo is drawn (the game adds one
on High graphics only). Nothing is uploaded."""
import sys, json, math, os, subprocess, shutil, tempfile
from pathlib import Path
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]; SKINS = ROOT / "assets/models/planes/skins"; N, FPS = 1024, 24
SPEC = json.loads((ROOT / "config/skin-motion.json").read_text()); ST = SPEC["studs"]
BLENDER = os.environ.get("BLENDER", "D:/Blender/blender.exe")

def uv(x, z): return ST["u0"] + ST["per"] * x, ST["v0"] + ST["per"] * z            # plane studs (from above) -> sheet
def since(ev, t):
    """(which event is playing, seconds since it began) for a schedule {loop, at: [start, ...]}; (None, 0) between events."""
    tt = t % ev["loop"]; best = None
    for i, start in enumerate(ev["at"]):
        if tt >= start and (best is None or start > ev["at"][best]): best = i
    return (best, tt - ev["at"][best]) if best is not None else (None, 0.0)
def flicker(ev, t):
    """0..1: a lightning double flash from each event (on, off, on, fade), or fully on for `hold` seconds."""
    i, s = since(ev, t)
    if i is None: return 0.0
    if "hold" in ev: return 1.0 if s < ev["hold"] else 0.0
    return 1.0 if s < 0.07 else 0.12 if s < 0.13 else 1.0 if s < 0.27 else max(0.0, 1 - (s - 0.27) / 0.35)
def glow(g, t):
    """A glow's strength at time t: steady, breathing between `low` of it and all of it, or flashing from `floor`."""
    if not g: return 0.0
    p, f = g.get("pulse"), g.get("flash"); s = g["strength"]
    if p: s *= p["low"] + (1 - p["low"]) * (0.5 - 0.5 * math.cos(2 * math.pi * (t / p["period"] + p.get("phase", 0))))
    if f: s *= f.get("floor", 0) + (1 - f.get("floor", 0)) * flicker(f, t)
    return s
def placed(cx, cz, w, h, du, dv):
    """Sheet -> picture for a picture w x h studs centred at (cx, cz), its top pointing along (du, dv)."""
    c, n = uv(cx, cz), math.hypot(du, dv) or 1; du, dv = du / n, dv / n; w, h = w * ST["per"], h * ST["per"]
    eu, ev = (-dv / w, du / w), (-du / h, -dv / h)                                 # picture right, picture down
    return [[eu[0], eu[1], 0.5 - eu[0] * c[0] - eu[1] * c[1]], [ev[0], ev[1], 0.5 - ev[0] * c[0] - ev[1] * c[1]]]
def state(layer, t):
    """Where a layer is at time t: (sheet -> picture map, how solid 0..1, glow strength). The game's copy must agree."""
    k, g = layer["kind"], glow(layer.get("glow"), t)
    if k == "still": return [[1, 0, 0], [0, 1, 0]], 1.0, g
    if k == "slide":
        f = (t / layer["period"]) % 1; z, a, tr = layer["zoom"], layer["at"], layer["travel"]; wob = layer.get("wobble")
        s = math.sin(2 * math.pi * t / wob["period"]) if wob else 0
        return [[z[0], 0, a[0] + tr[0] * f + (wob["amount"][0] * s if wob else 0)], [0, z[1], a[1] + tr[1] * f + (wob["amount"][1] * s if wob else 0)]], 1.0, g
    if k == "spin":
        a = 2 * math.pi * ((t / layer["period"] + layer.get("phase", 0)) % 1)
        return placed(*layer["centre"], layer["size"], layer["size"], math.sin(a), -math.cos(a)), 1.0, g
    if k == "pass":                                                                # a sprite crossing along a path, now and then
        tt = t % layer["loop"]
        for i, start in enumerate(layer["at"]):
            f = (tt - start) / layer["time"]
            if 0 <= f < 1:
                x0, z0, x1, z1 = layer["paths"][i % len(layer["paths"])]
                return placed(x0 + (x1 - x0) * f, z0 + (z1 - z0) * f, *layer["size"], x1 - x0, z1 - z0), min(1, f / 0.12, (1 - f) / 0.12), g
        return None, 0.0, 0.0
    if k == "flash":                                                               # a sprite that flickers at one of its spots (lightning)
        i, s = since(layer, t); f = flicker(layer, t)
        if i is None or f <= 0: return None, 0.0, 0.0
        x, z, turn = layer["spots"][i % len(layer["spots"])]; a = math.radians(turn)
        return placed(x, z, *layer["size"], math.sin(a), -math.cos(a)), f, g * f
    if k == "snap":                                                                # the whole layer jumps into view, shifted, for a moment (glitch)
        i, s = since(layer, t)
        if i is None or s >= layer["hold"]: return None, 0.0, 0.0
        sx, sy = layer["shifts"][i % len(layer["shifts"])]
        return [[1, 0, sx], [0, 1, sy]], 1.0, g
    if k == "slam":                                                                # a word slams in big, squashes, shakes, holds, fades (comic)
        i, s = since(layer, t); hit, hold = 0.14, layer["hold"]
        if i is None or s >= hit + hold + 0.3: return None, 0.0, 0.0
        size = 1 + 1.9 * (1 - s / hit) ** 2 if s < hit else 1 - 0.13 * math.sin(math.pi * min(1, (s - hit) / 0.16)) * (1 if s < hit + 0.16 else 0)
        shake = 0.28 * math.sin((s - hit) * 70) * max(0, 1 - (s - hit) / 0.3) if s >= hit else 0
        a = math.radians(layer.get("turn", 0)); solid = min(1, s / 0.05) if s < hit + hold else max(0, 1 - (s - hit - hold) / 0.3)
        return placed(layer["centre"][0] + shake, layer["centre"][1], layer["size"][0] * size, layer["size"][1] * size, math.sin(a), -math.cos(a)), solid, g * (math.exp(-(s - hit) / 0.22) if s >= hit else 0)
    raise ValueError(k)

def load(name):
    p = SKINS / (name + ".png"); return Image.open(p) if p.exists() else None
def sample(img, m):
    """The picture as the sheet sees it through map m (bilinear; outside its edge shows nothing: placed pictures keep a
    see-through border and sliding ones never leave their picture)."""
    w, h = img.size
    return np.asarray(img.transform((N, N), Image.AFFINE, (m[0][0] * w / N, m[0][1] * w / N, m[0][2] * w, m[1][0] * h / N, m[1][1] * h / N, m[1][2] * h), Image.BILINEAR), np.float32) / 255
def frames(skin, seconds, out):
    spec = SPEC["skins"][skin]; base = np.asarray(load(skin).convert("RGB"), np.float32) / 255
    bmask = load(skin + "-glow"); bmask = np.asarray(bmask.convert("L"), np.float32)[..., None] / 255 if bmask else base[..., :1]
    pics = [(l, load(skin + "-" + l["name"]).convert("RGBA"), load(skin + "-" + l["name"] + "-glow")) for l in spec["layers"]]
    for i in range(int(seconds * FPS)):
        t = i / FPS; col = base.copy(); em = base * bmask * np.array(spec.get("glow", {}).get("tint", (0, 0, 0)), np.float32) * glow(spec.get("glow"), t)
        for layer, pic, mask in pics:
            m, solid, g = state(layer, t)
            if m is None or solid <= 0: continue
            s = sample(pic, m); a = s[..., 3:] * solid; rgbv = s[..., :3]
            mk = sample(mask.convert("RGBA"), m)[..., :1] if mask else rgbv[..., :1]
            col = col * (1 - a) + rgbv * a
            em = em * (1 - a) + (rgbv * mk * np.array(layer["glow"]["tint"], np.float32) * g * a if layer.get("glow") else 0)
        Image.fromarray((np.clip(col, 0, 1) * 255 + 0.5).astype(np.uint8)).save(out / ("c%04d.png" % i), compress_level=1)
        Image.fromarray((np.clip(em, 0, 1) * 255 + 0.5).astype(np.uint8)).save(out / ("e%04d.png" % i), compress_level=1)
    return int(seconds * FPS)

if __name__ == "__main__":
    skin = sys.argv[1]; seconds = float(sys.argv[2]) if len(sys.argv) > 2 else SPEC["skins"][skin].get("seconds", 8)
    for l in SPEC["skins"][skin]["layers"]:                                        # every loop ends where it starts
        if l["kind"] == "slide": assert state(l, 0)[0] != state(l, l["period"] / 2)[0] and np.allclose(state(l, 0)[0], state(l, l["period"])[0]), l["name"]
    work = Path(tempfile.mkdtemp(prefix="skinmotion-")); out = ROOT / ".planning/skins/rares"; out.mkdir(parents=True, exist_ok=True)
    n = frames(skin, seconds, work); print(n, "sheets in", work)
    if os.environ.get("SHEETS_ONLY"): sys.exit()
    env = dict(os.environ, FRAMES="1", MORE="1", ONLY="starter,blunt,heavy2")
    subprocess.run([BLENDER, "-b", "--factory-startup", "--python", str(Path(__file__).with_name("skin_preview.py")), "--", str(work), str(work)], check=True, env=env, stdout=subprocess.DEVNULL)
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-framerate", str(FPS), "-i", str(work / "f%04d.png"), "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "18", str(out / (skin + ".mp4"))], check=True)
    shutil.copy(work / ("f%04d.png" % (n // 3)), out / (skin + "-frame.png")); shutil.rmtree(work); print(out / (skin + ".mp4"))
