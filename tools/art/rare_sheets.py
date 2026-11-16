"""The Rare skins' pictures, drawn in code like the Commons (skin_sheets.py):
    python tools/art/rare_sheets.py [id ...]      -> assets/models/planes/skins/<id>.png and <id>-<layer>.png
A Rare is a still sheet (<id>.png, what a far-away plane wears) plus moving layers: see-through pictures that the game
slides, turns and places over the sheet (config/skin-motion.json; skins plan, "Moving Rares"). <...>-glow.png marks what
glows (white = full); with none, a glowing layer glows by its own red. A sliding layer repeats inside its own picture
(a Decal's picture smears past its edge, lessons.md), a placed one keeps a see-through border. Colour is kept under
see-through pixels so edges get no dark fringe. Watch them move on real planes with skin_motion.py before any upload."""
import sys
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage, special
sys.path.insert(0, str(Path(__file__).resolve().parent)); import skin_sheets as S
from skin_sheets import N, SS, K, px, py, rgb, noise, OUT

def step(a, b, x): t = np.clip((x - a) / (b - a), 0, 1); return t * t * (3 - 2 * t)
def mix(a, b, t): return a + (b - a) * t[..., None]
def ramp(t, stops):
    xs = [p for p, _ in stops]; cs = np.array([rgb(h) for _, h in stops])
    return np.stack([np.interp(t, xs, cs[:, i]) for i in range(3)], -1)
def save(name, col, alpha=None):
    """col: h x w x 3 or h x w, 0..1; a picture drawn SS times too big (the sheet's own grid) is shrunk first."""
    def fit(a): return a.reshape(N, SS, N, SS, -1).mean((1, 3)).squeeze() if a.shape[0] == N * SS else a
    col = np.clip(fit(np.asarray(col, np.float32)), 0, 1)
    if alpha is not None: col = np.dstack((col, np.clip(fit(np.asarray(alpha, np.float32)), 0, 1)))
    OUT.mkdir(parents=True, exist_ok=True); Image.fromarray((col * 255 + 0.5).astype(np.uint8)).save(OUT / (name + ".png")); print(name, col.shape)
def tnoise(h, w, size, seed, stretch=(1.0, 1.0), octaves=3):
    """Smooth noise that repeats at the picture's edges, spread evenly over 0..1 (a threshold is a share of the area).
    Blobs about `size` px wide; stretch = (down, across) makes them longer that way."""
    rng, out = np.random.default_rng(seed), 0
    fy, fx = np.fft.fftfreq(h)[:, None], np.fft.rfftfreq(w)[None, :]
    for o in range(octaves):
        s = size / 2 ** o
        n = np.fft.irfft2(np.fft.rfft2(rng.standard_normal((h, w))) * np.exp(-((fy * s * stretch[0]) ** 2 + (fx * s * stretch[1]) ** 2) * 4), s=(h, w))
        out = out + n / n.std() / 2 ** o
    return 0.5 + 0.5 * special.erf(out / out.std() / np.sqrt(2))
def voronoi(x, y, cell, seed):
    """Cracked-mud cells about `cell` px wide: (distance to the nearest seed, to the next nearest, the cell's number)."""
    g = int(N / cell) + 4; pts = np.random.default_rng(seed).random((g, g, 2)) * 0.8 + 0.1
    gx, gy = (x / cell).astype(np.float32), (y / cell).astype(np.float32); ix, iy = np.floor(gx).astype(int), np.floor(gy).astype(int)
    d1 = np.full(gx.shape, 9e9, np.float32); d2 = d1.copy(); cid = np.zeros(gx.shape, np.int32)
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            cx, cy = (ix + dx + 1) % g, (iy + dy + 1) % g; p = pts[cy, cx]
            d = np.hypot(gx - (ix + dx + p[..., 0]), gy - (iy + dy + p[..., 1])).astype(np.float32)
            near = d < d1; d2 = np.where(near, d1, np.minimum(d2, d)); cid = np.where(near, cy * g + cx, cid); d1 = np.where(near, d, d1)
    return d1, d2, cid
def dots(h, w, n, seed, sigma, squash=1.0):
    """n soft dots (peak 1) scattered on a h x w picture that repeats at its edges; squash < 1 flattens them (for a
    layer the game stretches back)."""
    rng = np.random.default_rng(seed); a = np.zeros((h, w), np.float32)
    a[rng.integers(0, h, n), rng.integers(0, w, n)] = 1
    return np.clip(ndimage.gaussian_filter(a, (sigma * squash, sigma), mode="wrap") * 2 * np.pi * sigma * sigma * squash, 0, 1)

def lava():
    """Black cracked rock over molten orange (concept rare-1). The rock is a top layer with see-through cracks; the
    molten layer flows under it."""
    wx, wy = px + 34 * (noise(80, 31, 2) - 0.5), py + 34 * (noise(80, 32, 2) - 0.5)       # the cracks wander
    d1, d2, cid = voronoi(wx, wy, 92, 33); e = d2 - d1                                     # 0 on a crack's middle line
    width = 0.035 + 0.11 * noise(170, 34, 2) ** 1.5                                        # hairline to wide
    crack = 1 - step(width * 0.55, width, e)
    heat = np.exp(-np.maximum(e - width, 0) / 0.10)                                        # the rock's edge, warmed
    plate = ((cid.astype(np.int64) * 2654435761) % 1000 / 1000.0).astype(np.float32)
    rock = rgb("#2E2725") * (0.7 + 0.6 * plate)[..., None] * (0.8 + 0.4 * noise(10, 35, 2))[..., None] * (0.85 + 0.3 * noise(60, 36, 2))[..., None]
    rock = mix(rock, rgb("#0C0908"), 0.6 * step(0.5, 1.0, heat)); rock = mix(rock, rgb("#A3220A"), 0.5 * heat ** 2)
    still = ramp(np.clip((0.7 * noise(64, 53, 2) + 0.3 * noise(22, 54, 2) - 0.5) * 2.4 + 0.5, 0, 1),
                 [(0, "#B8240A"), (0.35, "#F2560C"), (0.65, "#FF9A1A"), (0.85, "#FFD23A"), (1, "#FFF3B0")])
    save("lava", mix(rock, still, crack)); save("lava-glow", np.clip(crack + 0.25 * heat ** 2, 0, 1)); save("lava-rock", rock, 1 - crack)
    m = 0.6 * tnoise(256, N, 46, 51, (0.7, 1.5)) + 0.4 * tnoise(256, N, 18, 52)           # one 256 px repeat; blobs lie across the flow so the eye sees them travel
    flow = ramp(np.clip((m - 0.5) * 1.7 + 0.5, 0, 1), [(0, "#8E1606"), (0.3, "#D93A08"), (0.55, "#FF7A12"), (0.8, "#FFC830"), (1, "#FFF6C0")])
    save("lava-flow", np.tile(flow, (4, 1, 1)))

def planet(size, r, bands, seed, ring=None, tilt=0.35):
    """A shaded planet r px across its middle on a size x size see-through picture: banded, lit from the upper left,
    with an optional ring (inner, outer as multiples of r, colour)."""
    y, x = (np.mgrid[0:size, 0:size] + 0.5 - size / 2) / r; rho2 = x * x + y * y; rng = np.random.default_rng(seed)
    nz = np.sqrt(np.clip(1 - rho2, 0, 1)); lat = y + 0.12 * np.sin(x * 5 + rng.random() * 6) * nz + 0.5 * (tnoise(size, size, r * 0.6, seed, (0.5, 3.0)) - 0.5) * 0.35
    col = ramp(np.clip(lat * 0.5 + 0.5, 0, 1), [(i / (len(bands) - 1), h) for i, h in enumerate(bands)])
    light = np.clip(-0.55 * x - 0.6 * y + 0.58 * nz, 0, 1); col = col * (0.32 + 0.85 * light)[..., None] + 0.25 * (light[..., None] ** 8)
    a = step(1.0, 1.0 - 2.5 / r, np.sqrt(rho2))
    if ring:
        ry = y / tilt; rr = np.sqrt(x * x + ry * ry); ra = step(ring[0], ring[0] + 0.08, rr) * (1 - step(ring[1] - 0.08, ring[1], rr)) * (0.55 + 0.45 * np.sin(rr * 26) ** 2)
        ra = np.where((y < 0) & (rho2 < 1), 0, ra)                                         # the far half passes behind the planet
        col = mix(col, np.broadcast_to(rgb(ring[2]), col.shape) * (0.75 + 0.25 * light)[..., None], ra * np.where(a > 0, 1, 1)); a = np.maximum(a * (1 - ra) + ra, ra * 0.92)
    return np.clip(col, 0, 1), a
def orbit(size, bodies):
    """Planets set round the middle of a see-through picture the game turns: (distance from the middle as a share of
    half the picture, angle, planet(...) arguments)."""
    col, alpha = np.zeros((size, size, 3), np.float32), np.zeros((size, size), np.float32); col[:] = rgb("#30205A")
    for dist, ang, r, bands, seed, ring in bodies:
        box = int(r * (2 * (ring[1] if ring else 1)) + 8) // 2 * 2; c, a = planet(box, r, bands, seed, ring)
        cx, cy = int(size / 2 + dist * size / 2 * np.cos(ang) - box / 2), int(size / 2 + dist * size / 2 * np.sin(ang) - box / 2)
        sl = (slice(cy, cy + box), slice(cx, cx + box)); col[sl] = mix(col[sl], c, a); alpha[sl] = np.maximum(alpha[sl], a)
    return col, alpha

def galaxy():
    """Deep space with purple and blue clouds (concept rare-1) and still stars; drifting stars, two rings of orbiting
    planets and a comet are layers (Alan 2026-11-16: "Everything should move, like planets orbit ... comets ... stars
    twinkle")."""
    a, b, c = noise(300, 41, 4), noise(190, 42, 4), noise(120, 43, 3)
    col = np.broadcast_to(rgb("#0B0A2C"), px.shape + (3,))
    col = mix(col, rgb("#2A1F8C"), step(0.40, 0.62, a)); col = mix(col, rgb("#7B2BD0"), 0.85 * step(0.50, 0.70, b))
    col = mix(col, rgb("#2B7BEA"), 0.6 * step(0.55, 0.72, c) * step(0.35, 0.6, a)); col = mix(col, rgb("#E55AD0"), 0.8 * step(0.66, 0.80, b) * step(0.45, 0.6, c))
    small, big = dots(N, N, 520, 44, 0.9), dots(N, N, 60, 45, 1.7); still = np.clip(small * 0.9 + big, 0, 1)
    stars = np.kron(still, np.ones((SS, SS), np.float32)); save("galaxy", mix(col, rgb("#F4F6FF"), stars)); save("galaxy-glow", still)
    # Drifting stars: one 512 px repeat, flattened by half because the game shows half the picture over the whole sheet.
    s1, s2, s3 = dots(512, N, 150, 46, 1.3, 0.5), dots(512, N, 46, 47, 2.3, 0.5), dots(512, N, 18, 48, 3.2, 0.5)
    rng = np.random.default_rng(49); spark = np.zeros((512, N), np.float32); spark[rng.integers(0, 512, 16), rng.integers(0, N, 16)] = 1
    cross = np.clip(ndimage.gaussian_filter(spark, (0.5, 11), mode="wrap") * 28 + ndimage.gaussian_filter(spark, (5.5, 1.0), mode="wrap") * 28, 0, 1)
    al = np.clip(s1 + s2 + s3 + cross, 0, 1); tint = (np.clip(s2, 0, 1)[..., None] * rgb("#9CC8FF") + np.clip(s3, 0, 1)[..., None] * rgb("#FFC8F0") + (1 - np.clip(s2 + s3, 0, 1))[..., None] * rgb("#FFFFFF"))
    save("galaxy-stars", np.tile(tint, (2, 1, 1)), np.tile(al, (2, 1)))
    jup, ice, teal, red = ("#F6D8A8", "#E08A3C", "#F2C48A", "#B85A2A", "#F0D2A0", "#D0763A"), ("#DFF8FF", "#7FD8F2", "#3FA8E0", "#BFF0FF"), ("#B8FFF0", "#2FD6C0", "#12908C", "#7FF0DC", "#1AA89C"), ("#FFB090", "#E8482C", "#A8241C", "#F0703C")
    save("galaxy-planets-a", *orbit(768, [(0.74, 0.3, 66, jup, 61, None), (0.80, 0.3 + np.pi * 1.1, 38, ice, 62, None)]))
    save("galaxy-planets-b", *orbit(1024, [(0.74, 2.0, 76, teal, 63, (1.35, 1.62, "#FFE08A")), (0.70, 2.0 + np.pi * 0.85, 34, red, 64, None)]))
    h, w = 800, 240; y, x = np.mgrid[0:h, 0:w] + 0.5; x = (x - w / 2) / (w / 2); t = (y - 70) / (h - 90)   # head near the top, tail down
    head = np.exp(-(x * x * (w / 2) ** 2 + (y - 70) ** 2) / (2 * 15.0 ** 2)); halo = np.exp(-(x * x * (w / 2) ** 2 + (y - 70) ** 2) / (2 * 36.0 ** 2))
    tail = np.where(t > 0, np.exp(-(x / (0.16 + 0.5 * np.clip(t, 0, 1))) ** 2 * 2.2) * (1 - np.clip(t, 0, 1)) ** 1.6, 0) * (0.75 + 0.25 * tnoise(h, w, 30, 65, (6, 0.6)))
    al = np.clip(head * 1.4 + halo * 0.55 + tail * 0.85, 0, 1) * step(1.0, 0.86, np.abs(x)) * step(h, h - 30, y) * step(0, 16, y)
    save("galaxy-comet", ramp(np.clip(head * 1.6 + tail * 0.35 + halo * 0.3, 0, 1), [(0, "#4A7BFF"), (0.35, "#7FD8FF"), (0.7, "#DFF6FF"), (1, "#FFFFFF")]), al)

def squash(a):
    """A picture that repeats top to bottom, flattened to half its height and stacked twice: the game shows half of it
    over the whole sheet and slides it by the other half."""
    a = np.asarray(a, np.float32); b = a.reshape(a.shape[0] // 2, 2, *a.shape[1:]).mean(1); return np.concatenate((b, b))

def slime():
    """Bright toxic goo creeping over dark paper (concept rare-1). The goo and its paper are one solid sliding layer;
    the still sheet is the same picture where the slide starts."""
    g = 0.55 * tnoise(N, N, 84, 71, (3.4, 0.75)) + 0.45 * tnoise(N, N, 40, 72, (2.0, 0.9))    # long thin runs down the plane
    body, h = step(0.49, 0.53, g), step(0.49, 0.78, g)                                     # where the goo is, how thick
    gy, gx = np.gradient(ndimage.gaussian_filter(h, 2.5, mode="wrap")); shine = np.clip((-gx - gy) * 30, 0, 1) ** 1.5
    bub = dots(N, N, 110, 73, 3.4) * step(0.3, 0.6, h)
    goo = mix(ramp(h, [(0, "#1F7A0C"), (0.3, "#4FC212"), (0.75, "#86EE22"), (1, "#B4FF45")]), rgb("#F1FFC2"), np.clip(shine * 0.85 + bub * 0.9, 0, 1))
    ground = mix(rgb("#252C24") * (0.8 + 0.4 * tnoise(N, N, 40, 74))[..., None], rgb("#0E120D"), 0.7 * step(0.43, 0.49, g))   # the goo's shadow
    col, gl = mix(ground, goo, body), np.clip(bub + 0.5 * shine + 0.15, 0, 1) * body
    save("slime", col); save("slime-glow", gl); save("slime-goo", squash(col)); save("slime-goo-glow", squash(gl))

def holographic():
    """Crinkled silver foil with pastel facets (concept rare-2); rainbow bands and a glint line slide over it."""
    d1, d2, cid = voronoi(px + 22 * (noise(60, 81, 2) - 0.5), py + 22 * (noise(60, 82, 2) - 0.5), 54, 83)
    k = cid.astype(np.int64) * 2654435761; facet = (k % 1000 / 1000.0).astype(np.float32); edge = np.exp(-(d2 - d1) / 0.05)
    pal = np.array([rgb(h) for h in ("#C9B8F0", "#B4E2F2", "#F2C2E0", "#C4F0D6", "#D6D8E8")])[(k // 1000) % 5]
    still = np.stack([np.interp((px * 0.9 + py) / 300 % 1, [0, 0.25, 0.5, 0.75, 1], c) for c in np.array([rgb(h) for h in ("#FF9AD8", "#9AD8FF", "#B8FFC8", "#FFF0A0", "#FF9AD8")]).T], -1)
    col = mix(rgb("#B4BACC") * 0.45 + pal * 0.55, still, np.full(px.shape, 0.35)) * (0.72 + 0.26 * facet + 0.12 * edge)[..., None]
    save("holographic", col)
    y, x = np.mgrid[0:256, 0:N] + 0.5; t = tnoise(256, N, 90, 85)
    hue = (y / 256 + 1.6 * x / N + 0.5 * (t - 0.5)) % 1                                    # slanted bands, one 256 px repeat
    band = np.stack([np.interp(hue, [0, 0.2, 0.4, 0.6, 0.8, 1], c) for c in np.array([rgb(h) for h in ("#FF6AD0", "#8A7CFF", "#5AD8FF", "#7CFFB8", "#FFF07A", "#FF6AD0")]).T], -1)
    save("holographic-rainbow", np.tile(band, (4, 1, 1)), np.tile(0.5 + 0.3 * tnoise(256, N, 60, 86), (4, 1)))
    y, x = np.mgrid[0:N, 0:N] + 0.5; d = y - (N * 0.5 + 0.10 * (x - N / 2))               # one slanted bright line in the middle of the picture
    save("holographic-glint", np.ones((N, N, 3), np.float32), np.clip(np.exp(-(d / 5.0) ** 2) + 0.35 * np.exp(-(d / 16.0) ** 2), 0, 1) * 0.95)

def glitch():
    """Dark navy with broken bars of red, cyan and violet (concept rare-2). Bars are flat and never touch the bar above
    or below (no shape can build up: lessons.md, hooked-cross scan). The layer that snaps in holds colour ghosts, torn
    slabs and bright lines."""
    rng = np.random.default_rng(91); kind = np.zeros((N, N), np.int8); y = 0
    while y < N - 30:
        y += int(rng.integers(5, 26)); bar = int(rng.integers(6, 24)); x = int(rng.integers(0, 60))
        while x < N:
            ln = int(rng.integers(18, 240)); kind[y:y + bar, x:x + ln] = rng.choice([1, 1, 2, 2, 3]); x += ln + int(rng.integers(20, 200))
        y += bar
    pal = np.array([rgb("#15123A"), rgb("#FF2A6D"), rgb("#19E6FF"), rgb("#8A4DFF")]); col = pal[kind]
    col = np.where((kind == 0)[..., None], col * (0.8 + 0.4 * tnoise(N, N, 200, 92))[..., None], col); col[3::4] *= 0.84   # faint screen lines
    on = kind > 0; save("glitch", col); save("glitch-glow", on.astype(np.float32))
    lay = np.zeros((N, N, 4), np.float32); lay[..., :3] = rgb("#15123A")
    for dx, c in ((12, "#19E6FF"), (-12, "#FF2A6D")):
        ghost = np.roll(on, dx, 1) & ~on; lay[ghost, :3] = rgb(c); lay[ghost, 3] = 0.85
    for _ in range(5):                                                                     # torn slabs: the picture slid sideways
        y0, tall, dx = int(rng.integers(40, N - 90)), int(rng.integers(18, 56)), int(rng.choice([-1, 1]) * rng.integers(28, 80))
        lay[y0:y0 + tall, :, :3] = np.roll(col[y0:y0 + tall], dx, 1); lay[y0:y0 + tall, :, 3] = 1
    for _ in range(7):
        y0, x0 = int(rng.integers(20, N - 20)), int(rng.integers(0, N - 300)); lay[y0:y0 + 2, x0:x0 + int(rng.integers(150, 600))] = (1, 1, 1, 0.9)
    lay[:4, :, 3] = lay[-4:, :, 3] = 0; lay[:, :4, 3] = lay[:, -4:, 3] = 0                  # a see-through rim: the shifted layer smears nothing
    save("glitch-snap", lay[..., :3], lay[..., 3])

def bolt(seed, w=420, h=840, Q=2):
    """A forked lightning bolt, top to bottom of a see-through picture: white core, blue-violet glow."""
    from PIL import ImageDraw
    rng = np.random.default_rng(seed); im = Image.new("L", (w * Q, h * Q), 0); d = ImageDraw.Draw(im)
    def run(x, y, lean, steps, width):
        pts = [(x, y)]
        for _ in range(steps):
            x = float(np.clip(x + (lean + rng.uniform(-42, 42)) * Q, 40 * Q, (w - 40) * Q)); y += rng.uniform(30, 58) * Q
            if y > (h - 40) * Q: break
            pts.append((x, y))
        d.line(pts, fill=255, width=int(width * Q), joint="curve"); return pts
    main = run(w * Q / 2, 30 * Q, 0, 40, 5)
    for i in rng.choice(np.arange(2, len(main) - 3), 4, replace=False): run(*main[i], rng.choice([-1, 1]) * rng.uniform(30, 55), int(rng.integers(3, 7)), 3)
    c = np.asarray(im, np.float32) / 255; mid, far = np.clip(ndimage.gaussian_filter(c, 3 * Q) * 2.4, 0, 1), np.clip(ndimage.gaussian_filter(c, 11 * Q) * 7, 0, 1)
    al, v = np.clip(c + 0.85 * mid + 0.55 * far, 0, 1), np.clip(c + 0.7 * mid + 0.25 * far, 0, 1)
    yy, xx = np.mgrid[0:h * Q, 0:w * Q]; al *= step(0, 24 * Q, np.minimum(np.minimum(xx, w * Q - xx), np.minimum(yy, h * Q - yy)))
    small = lambda a: a.reshape(h, Q, w, Q, -1).mean((1, 3)).squeeze()
    return small(ramp(v, [(0, "#5A6CFF"), (0.5, "#B8C8FF"), (1, "#FFFFFF")])), small(al)

def thunderstorm():
    """Dark blue-violet storm clouds (concept rare-2); lighter wisps roll back over them and a bolt flashes on the wings,
    lighting the clouds' pale edges."""
    a, b = noise(230, 101, 4), noise(95, 102, 3); c = np.clip((0.6 * a + 0.4 * (1 - np.abs(b - 0.5) * 2) - 0.5) * 2.6 + 0.2, 0, 1)   # billows
    save("thunderstorm", ramp(c, [(0, "#10142E"), (0.4, "#232A5C"), (0.65, "#3B3F8E"), (0.85, "#6A63C0"), (1, "#A9A6E8")])); save("thunderstorm-glow", step(0.5, 0.95, c))
    t = tnoise(N, N, 150, 103, (1.0, 1.7)); save("thunderstorm-clouds", squash(ramp(t, [(0, "#5A60A8"), (1, "#B8BCF2")])), squash(0.6 * step(0.52, 0.86, t)))
    save("thunderstorm-bolt", *bolt(104))

def circuit_board():
    """Dark green board with gold and cyan lines (concept rare-2). The lines are see-through cuts in the board layer; a
    solid layer under it carries the light that runs along them. Lines only run straight down the plane or at 45
    degrees, in bundles (no square corners, no crossings: lessons.md, hooked-cross scan)."""
    from PIL import ImageDraw
    Q, rng = 2, np.random.default_rng(111); im = Image.new("L", (N * Q, N * Q), 0); d = ImageDraw.Draw(im); holes = []
    def pad(x, y, r=9): d.ellipse([(x - r) * Q, (y - r) * Q, (x + r) * Q, (y + r) * Q], fill=255); holes.append((x, y))
    for x0 in np.arange(30, N, 84) + rng.integers(-18, 18, len(np.arange(30, N, 84))):
        mid, y = [(float(x0), -10.0)], -10.0; x = float(x0)
        while y < N + 10:                                                                  # the bundle's middle line: runs and 45-degree jogs
            y += float(rng.integers(70, 260)); mid.append((x, y)); k = float(rng.choice([-1, 1]) * rng.integers(1, 4) * 13); x += k; y += abs(k); mid.append((x, y))
        for i in range(int(rng.integers(2, 5))):
            a, b = (0, len(mid)) if rng.random() < 0.45 else sorted(rng.choice(np.arange(0, len(mid), 2), 2, replace=False) + np.array([0, 2]))
            pts = [(px_ + i * 13, py_) for px_, py_ in mid[a:b]]
            if len(pts) < 2: continue
            d.line([(u * Q, v * Q) for u, v in pts], fill=255, width=5 * Q, joint="curve")
            if a > 0: pad(*pts[0])
            if b < len(mid): pad(*pts[-1])
    for _ in range(46): pad(float(rng.integers(20, N - 20)), float(rng.integers(20, N - 20)), 7)
    line = np.asarray(im.resize((N, N), Image.BOX), np.float32) / 255; yy, xx = np.mgrid[0:N, 0:N] + 0.5
    for x, y in holes: line = np.where((xx - x) ** 2 + (yy - y) ** 2 < 3.4 ** 2, 0, line)   # the pad's drilled middle is board again
    board = mix(rgb("#0F4A33") * (0.85 + 0.3 * tnoise(N, N, 50, 112))[..., None], rgb("#23795A"), np.clip(ndimage.maximum_filter(line, 7) - line, 0, 1) * 0.8)
    alpha, led = 1 - line, np.zeros((N, N), np.float32)
    for _ in range(5):                                                                     # chips: dark blocks with silver feet down both sides
        x, y, w, h = int(rng.integers(60, N - 140)), int(rng.integers(60, N - 180)), int(rng.integers(44, 70)), int(rng.integers(70, 120))
        board[y:y + h, x - 7:x + w + 7][4::12] = rgb("#C8CCD0"); board[y:y + h, x - 7:x + w + 7][5::12] = rgb("#C8CCD0"); alpha[y:y + h, x - 7:x + w + 7][4::12] = 1; alpha[y:y + h, x - 7:x + w + 7][5::12] = 1
        board[y:y + h, x:x + w] = rgb("#16181C") * (0.9 + 0.2 * rng.random()); alpha[y:y + h, x:x + w] = 1
    for _ in range(18):                                                                    # small lights
        x, y = rng.integers(30, N - 30, 2); spot = (xx - x) ** 2 + (yy - y) ** 2 < 5.5 ** 2
        board[spot] = rgb(rng.choice(["#FF4A3A", "#4AFF6A", "#FFC83A"])); alpha[spot] = 1; led[spot] = 1
    ph = np.repeat(rng.random(N // 22 + 1), 22)[:N]                                        # every line its own timing
    glow = np.exp(-((ph[None, :] - (np.arange(N)[:, None] + 0.5) / N) % 1.0) / 0.10)       # bright head running to the tail, fading behind it
    cyan = (tnoise(8, N, 260, 113)[0] > 0.62)[None, :, None]
    pulse = mix(np.where(cyan, rgb("#1C98A0"), rgb("#B08A22")) + np.zeros((N, N, 3)), np.where(cyan, rgb("#9FFBFF"), rgb("#FFE680")) + np.zeros((N, N, 3)), glow)
    save("circuit_board", mix(pulse, board, alpha)); save("circuit_board-glow", np.clip((0.25 + 0.75 * glow) * (1 - alpha) + led, 0, 1))
    save("circuit_board-board", board, alpha); save("circuit_board-board-glow", led)
    save("circuit_board-pulse", squash(pulse)); save("circuit_board-pulse-glow", squash(0.25 + 0.75 * glow))

def word(name, text, burst, fill, seed, w=640, h=440, Q=2):
    """A comic sound word on a spiky burst, black outlines, see-through round it (Alan 2026-11-16: onomatopoeias that slam)."""
    import math
    from PIL import ImageDraw, ImageFont
    rng = np.random.default_rng(seed); im = Image.new("RGBA", (w * Q, h * Q), (0, 0, 0, 0)); n = 15
    pts = [(w * Q / 2 + (0.47 if i % 2 == 0 else 0.31 + 0.05 * rng.random()) * w * Q * math.cos(math.pi * i / n), h * Q / 2 + (0.47 if i % 2 == 0 else 0.31 + 0.05 * rng.random()) * h * Q * math.sin(math.pi * i / n)) for i in range(2 * n)]
    ImageDraw.Draw(im).polygon(pts, fill=burst, outline=(0, 0, 0, 255), width=9 * Q)
    t = Image.new("RGBA", (w * Q, h * Q), (0, 0, 0, 0))
    ImageDraw.Draw(t).text((w * Q / 2, h * Q / 2), text, font=ImageFont.truetype("impact.ttf", 150 * Q), fill=fill, anchor="mm", stroke_width=9 * Q, stroke_fill=(0, 0, 0, 255))
    t = t.transform(t.size, Image.AFFINE, (1, 0.2, -0.2 * h * Q / 2, 0, 1, 0), Image.BICUBIC).rotate(7, Image.BICUBIC)   # leaning forward and up
    im.alpha_composite(t); im.resize((w, h), Image.LANCZOS).save(OUT / (name + ".png")); print(name)

def comic_book():
    """Red, yellow and blue fields of printed dots split by jagged black lines (concept rare-3); speed lines and three
    slamming sound words are layers."""
    X, Z = S.X, S.Z; zig = 1.3 * (np.abs(((X * 0.55 - Z * 0.22) % 2.0) - 1.0) - 0.5)       # a sawtooth edge
    f = (Z * 0.55 + X * 0.38 + zig) / 5.2; band = np.floor(f).astype(int) % 3; edge = np.abs(f - np.round(f)) * 5.2 < 0.2
    gx, gy = (px + py) / 17.0, (px - py) / 17.0; r = np.hypot(gx % 1 - 0.5, gy % 1 - 0.5)
    dot = r < 0.2 + 0.24 * noise(260, 121, 2)                                              # dots swell and shrink across the sheet
    flat = np.array([rgb("#E5261F"), rgb("#FFD21A"), rgb("#1E6FE6")])[band]; ink = np.array([rgb("#A8120E"), rgb("#FF9A1A"), rgb("#7FC0FF")])[band]
    save("comic_book", np.where(edge[..., None], rgb("#0B0B0E"), np.where(dot[..., None], ink, flat)))
    from PIL import ImageDraw
    Q, rng = 4, np.random.default_rng(122); im = Image.new("LA", (N * Q, 256 * Q), (255, 0)); d = ImageDraw.Draw(im)
    for _ in range(26):                                                                    # thin streaks, sharp end to the tail; one 256 px repeat
        x, y, ln, wd, ink_ = rng.integers(10, N - 10), rng.integers(0, 256), rng.integers(80, 215), rng.uniform(2.0, 4.5), (255 if rng.random() < 0.7 else 0)
        for wrap in (-256, 0, 256): d.polygon([((x - wd / 2) * Q, (y + wrap) * Q), ((x + wd / 2) * Q, (y + wrap) * Q), (x * Q, (y + wrap + ln) * Q)], fill=(ink_, 235))
    a = np.asarray(im.resize((N, 256), Image.BOX), np.float32) / 255
    save("comic_book-lines", np.tile(np.repeat(a[..., :1], 3, 2), (4, 1, 1)), np.tile(a[..., 1], (4, 1)))
    word("comic_book-pow", "POW!", "#FFE11A", "#E5261F", 123); word("comic_book-slam", "SLAM!", "#FFF4D0", "#1E6FE6", 124); word("comic_book-zap", "ZAP!", "#E5261F", "#FFE11A", 125)

SKINS = dict(lava=lava, galaxy=galaxy, slime=slime, holographic=holographic, glitch=glitch, thunderstorm=thunderstorm,
             circuit_board=circuit_board, comic_book=comic_book)
if __name__ == "__main__":
    for name in sys.argv[1:] or SKINS: SKINS[name]()
