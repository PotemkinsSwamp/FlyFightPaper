"""City play rug: the flat ground of a planned toy town (roads, pavements, grass, water, field lines).
Trees, cars, fountains, benches and the like are 3D toy models; their planned spots go to assets/rug/toy-spots.json.

python tools/rug.py              check the plan against the buildings, draw assets/rug/preview.png
python tools/rug.py --tiles      also draw the 280 tile pictures into assets/rug/tiles/
python tools/rug.py --upload     also upload new tile pictures (records in assets/rug/uploads/, never re-uploaded)
python tools/rug.py --build      also write assets/models/city-rug.rbxmx (needs every tile uploaded)
python tools/rug.py --plan assets/rug/replan-v4.json [--tiles] [--upload] [--build]
    the layout-D town from tools/town_plan.py: draw preview-v4.png, fill-plan-v4.png, toy-spots-v4.json and
    optionally tiles-v4/v4_t*.png, without model reads; upload (Alan runs it) and build city-rug-v4.rbxmx
Buildings come from assets/models/classroom.rbxmx; the check fails if any of them stands on a road.
"""
from pathlib import Path
import argparse
import hashlib
import json
import math
import random
import re
import subprocess
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont
import shapely
import shapely.affinity
from shapely.geometry import shape as shp, Point as SPoint, LineString as SLine, box as sbox
from shapely.ops import unary_union

ROOT = Path(__file__).resolve().parents[1]
RUG = ROOT / "assets" / "rug"
X0, Z0, W, H, TILE, PX = -1000, -700, 20, 14, 100, 1024      # rug corner, tiles across/down, studs and pixels per tile
SS, MARGIN = 2, 24                                          # supersampling, overdraw margin in final pixels
TILE_MESH = "rbxassetid://134870470796084"                  # assets/models/rug-tile: the top face shows the whole picture
CARPET = {k: json.loads((RUG / "carpet" / f"{k}.json").read_text())["response"]["assetId"] for k in ("normal", "roughness", "stitch")}
STITCH = CARPET["stitch"]
C = dict(grass=(112, 158, 82), grass2=(120, 164, 88), grass3=(106, 152, 78), road=(90, 90, 98), walk=(216, 206, 186),
         curb=(238, 232, 218), white=(242, 236, 222), yellow=(234, 188, 66), pave=(226, 214, 192), pave2=(210, 196, 172),
         lot=(200, 192, 178), water=(84, 150, 198), water2=(118, 178, 218), shore=(222, 206, 160), sand=(228, 204, 150),
         soil=(146, 108, 76), wood=(166, 116, 74), wood2=(124, 86, 54), stone=(178, 172, 164), leaf=(70, 124, 64),
         leaf2=(96, 150, 76), pine=(48, 104, 72), pine2=(70, 128, 88), hedge=(74, 126, 66), ink=(58, 56, 64),
         red=(206, 72, 60), blue=(70, 112, 190), orange=(232, 142, 58), green=(84, 150, 92), purple=(140, 98, 170),
         pink=(236, 150, 176), teal=(64, 166, 160), cream=(248, 242, 226), court=(196, 104, 70), field=(104, 162, 84))
# Layout D is printed like a kids' car play-mat (assets/rug/playmat-concept.png, Alan 2026-10-16): lime grass,
# dark slate roads, bold yellow dashes, bright blue water, cream pads and pavements.
PLAYMAT = dict(grass=(95, 182, 36), grass2=(112, 194, 52), hedge=(70, 150, 30), road=(78, 82, 94), walk=(226, 212, 180),
               curb=(242, 234, 214), white=(250, 250, 248), yellow=(246, 206, 22), pave=(234, 218, 182),
               pave2=(212, 194, 158), lot=(236, 221, 184), water=(26, 148, 240), water2=(96, 186, 248),
               shore=(226, 212, 176), stone=(204, 198, 190))
BINDING = (69, 155, 38)                                     # the green fabric edge round the play-mat
FLOWERS = [(250, 230, 110), (250, 250, 248), (238, 120, 150), (190, 120, 220), (250, 150, 80)]


def shade(c, k):
    return tuple(max(0, min(255, int(v * k))) for v in c)


# ---------------------------------------------------------------- street plan (studs; x east, z south, north at the top)
def rounded_rect(x0, z0, x1, z1, r, steps=12):
    pts = []
    for cx, cz, a0 in ((x1 - r, z0 + r, -90), (x1 - r, z1 - r, 0), (x0 + r, z1 - r, 90), (x0 + r, z0 + r, 180)):
        pts += [(cx + r * math.cos(math.radians(a0 + 90 * k / steps)), cz + r * math.sin(math.radians(a0 + 90 * k / steps)))
                for k in range(steps + 1)]
    return pts + [pts[0]]


STREET, BOULEVARD, WALK = 20, 30, 7       # asphalt half widths; pavement beside every road
ROADS = [  # (centre line, asphalt half width): a ring road, two avenues, two streets and two tree-lined boulevards
    (rounded_rect(-930, -630, 930, 630, 150), STREET),
    ([(-930, -330), (930, -330)], STREET), ([(-930, 330), (930, 330)], STREET),
    ([(-480, -630), (-480, 630)], STREET), ([(480, -630), (480, 630)], STREET),
    ([(0, -330), (0, 630)], BOULEVARD), ([(-690, 0), (690, 0)], BOULEVARD),
]
ROUNDABOUT = (0, 0, 78, 44)                # Town Square: centre, asphalt radius, island radius
FANS = [(-780, 0), (780, 0)]               # the lift fans stand in round plazas at the ends of the east-west boulevard
FAN_PLAZA = 92
SETBACK, PAD, GAP = 14, 4, 5               # building front to pavement; paving round a building; clear grass between things


def polyline_points(pts, step):
    """Evenly spaced (x, z, tangent x, tangent z, distance) samples along a polyline."""
    out, travelled = [], 0.0
    for (ax, az), (bx, bz) in zip(pts, pts[1:]):
        length = math.hypot(bx - ax, bz - az)
        if length < 1e-6: continue
        tx, tz = (bx - ax) / length, (bz - az) / length
        s = (step - travelled % step) % step
        while s < length:
            out.append((ax + tx * s, az + tz * s, tx, tz, travelled + s)); s += step
        travelled += length
    return out


def junctions():
    """(x, z, clear radius) where roads cross or a road ends on another."""
    found = {}
    segs = [(i, a, b, half) for i, (pts, half) in enumerate(ROADS) for a, b in zip(pts, pts[1:])]
    for i, (ax, az), (bx, bz), h1 in segs:
        for j, (cx, cz), (dx, dz), h2 in segs:
            if j <= i: continue
            den = (bx - ax) * (dz - cz) - (bz - az) * (dx - cx)
            if abs(den) < 1e-9: continue
            t = ((cx - ax) * (dz - cz) - (cz - az) * (dx - cx)) / den
            u = ((cx - ax) * (bz - az) - (cz - az) * (bx - ax)) / den
            if -1e-6 <= t <= 1 + 1e-6 and -1e-6 <= u <= 1 + 1e-6:
                p = (round(ax + t * (bx - ax)), round(az + t * (bz - az)))
                if math.hypot(*p) > 5: found[p] = max(found.get(p, 0), h1 + WALK + 6, h2 + WALK + 6)
    return [(x, z, d) for (x, z), d in found.items()]


def road_at(x, z, pad=0.0):
    for pts, half in ROADS:
        for (ax, az), (bx, bz) in zip(pts, pts[1:]):
            vx, vz = bx - ax, bz - az
            t = max(0, min(1, ((x - ax) * vx + (z - az) * vz) / (vx * vx + vz * vz or 1)))
            if math.hypot(x - ax - vx * t, z - az - vz * t) <= half + pad: return True
    return math.hypot(x - ROUNDABOUT[0], z - ROUNDABOUT[1]) <= ROUNDABOUT[2] + pad


# ---------------------------------------------------------------- buildings from the room file
SKIP = re.compile(r"^(Floor|Ceiling|Wall|Window|Desk|Pad|Chair|Landing|NeutralDesk|OutsideLawn|CeilingLight|Classroom"
                  r"|ControlZone|HangingPlanet|PlanetThread|Tailwind|Updraft|Chalkboard|Bookshelf|Tree|FanVent)")


def footprints():
    """Ground footprints [x0, z0, x1, z1, names] of everything standing on the rug, merged where they touch."""
    text = (ROOT / "assets/models/classroom.rbxmx").read_text(encoding="utf-8")
    boxes = []
    for chunk in re.split(r"(?=<Item )", text):
        name = re.search(r'<string name="Name">([^<]*)</string>', chunk)
        cf = re.search(r'<CoordinateFrame name="CFrame">(.*?)</CoordinateFrame>', chunk, re.S)
        size = re.search(r'<Vector3 name="size">\s*<X>([^<]+)</X>\s*<Y>([^<]+)</Y>\s*<Z>([^<]+)</Z>', chunk)
        if not (name and cf and size) or SKIP.match(name.group(1)): continue
        v = {k: float(x) for k, x in re.findall(r"<(\w+)>([^<]+)</\1>", cf.group(1))}
        half = [float(size.group(k)) / 2 for k in (1, 2, 3)]
        ext = [sum(abs(v[f"R{r}{c}"]) * half[c] for c in range(3)) for r in range(3)]
        if v["Y"] - ext[1] > 6: continue                      # not standing on the floor
        b = [v["X"] - ext[0], v["Z"] - ext[2], v["X"] + ext[0], v["Z"] + ext[2]]
        if b[2] < X0 or b[0] > -X0 or b[3] < Z0 or b[1] > -Z0: continue
        boxes.append(b + [{name.group(1)}])
    # The town's buildings now stand as toys (toy-placements.json), not as room parts: one footprint per building.
    # The bell tower straddles Town Square on four legs, so it gets no paved lot.
    import json
    homes = {}
    for r in json.loads((ROOT / "assets/rug/toy-placements.json").read_text()):
        home = r.get("building") or (r["toy"].split("/")[0] if "/" in r["toy"] else None)
        if not home or home in ("links", "kit", "bell-tower"): continue
        x, z, R, half = r["cf"][0], r["cf"][2], r["cf"][3:], [s / 2 for s in r["size"]]
        ex, ey, ez = (sum(abs(R[3 * k + c]) * half[c] for c in range(3)) for k in (0, 1, 2))
        if r['cf'][1] - ey > 6: continue                      # upper floors and roofs overhang; the ground floor is the lot
        b = homes.setdefault(home, [x - ex, z - ez, x + ex, z + ez, {"BuildingCollision-" + home}])
        b[:4] = min(b[0], x - ex), min(b[1], z - ez), max(b[2], x + ex), max(b[3], z + ez)
    boxes += homes.values()
    merged = True
    while merged:                                            # union boxes closer than 6 studs
        merged = False
        for i in range(len(boxes)):
            for j in range(i + 1, len(boxes)):
                a, b = boxes[i], boxes[j]
                if a[0] - 6 < b[2] and b[0] - 6 < a[2] and a[1] - 6 < b[3] and b[1] - 6 < a[3]:
                    boxes[i] = [min(a[0], b[0]), min(a[1], b[1]), max(a[2], b[2]), max(a[3], b[3]), a[4] | b[4]]
                    del boxes[j]; merged = True; break
            if merged: break
    return boxes


def kind_of(names):
    if any(n.startswith(("CardboardSquare", "BookTower", "OpenBook", "BuildingCollision")) for n in names): return "building"
    if any(n.startswith("FanBase") for n in names): return "fan"
    if any(n.startswith("BridgeBook") for n in names): return "bridge"
    return "toy"


# ---------------------------------------------------------------- drawing in world coordinates
class Pen:
    def __init__(self, img, ox, oz, s):
        self.img, self.d, self.ox, self.oz, self.s = img, ImageDraw.Draw(img), ox, oz, s
        self.view = (ox, oz, ox + img.size[0] / s, oz + img.size[1] / s)

    def P(self, x, z):
        return ((x - self.ox) * self.s, (z - self.oz) * self.s)

    def sees(self, x0, z0, x1, z1):
        v = self.view
        return x1 >= v[0] and x0 <= v[2] and z1 >= v[1] and z0 <= v[3]

    def px(self, w):
        return max(1, round(w * self.s))

    def circle(self, x, z, r, fill=None, outline=None, w=0.0):
        self.ellipse(x, z, r, r, fill, outline, w)

    def ellipse(self, x, z, rx, rz, fill=None, outline=None, w=0.0):
        if rx <= 0 or rz <= 0 or not self.sees(x - rx, z - rz, x + rx, z + rz): return
        self.d.ellipse([self.P(x - rx, z - rz), self.P(x + rx, z + rz)], fill=fill, outline=outline,
                       width=self.px(w) if outline else 0)

    def poly(self, pts, fill=None, outline=None, w=0.0):
        xs, zs = [p[0] for p in pts], [p[1] for p in pts]
        if not self.sees(min(xs), min(zs), max(xs), max(zs)): return
        self.d.polygon([self.P(*p) for p in pts], fill=fill)
        if outline: self.line(pts + [pts[0]], w, outline)

    def area(self, g, fill):
        """Fill a shapely (multi)polygon, holes included."""
        for poly in getattr(g, "geoms", [g]):
            if poly.is_empty or poly.geom_type != "Polygon" or not self.sees(*poly.bounds): continue
            if not poly.interiors: self.d.polygon([self.P(*q) for q in poly.exterior.coords], fill=fill); continue
            mask = Image.new("L", self.img.size, 0); m = ImageDraw.Draw(mask)
            m.polygon([self.P(*q) for q in poly.exterior.coords], fill=255)
            for ring in poly.interiors: m.polygon([self.P(*q) for q in ring.coords], fill=0)
            self.img.paste(fill, (0, 0, *self.img.size), mask)

    def rect(self, x0, z0, x1, z1, fill=None, r=0.0, outline=None, w=0.0):
        if not self.sees(x0, z0, x1, z1): return
        self.d.rounded_rectangle([self.P(x0, z0), self.P(x1, z1)], radius=r * self.s, fill=fill, outline=outline,
                                 width=self.px(w) if outline else 0)

    def line(self, pts, w, fill, caps=True):
        for (ax, az), (bx, bz) in zip(pts, pts[1:]):
            if self.sees(min(ax, bx) - w, min(az, bz) - w, max(ax, bx) + w, max(az, bz) + w):
                self.d.line([self.P(ax, az), self.P(bx, bz)], fill=fill, width=self.px(w))
        for i, (x, z) in enumerate(pts):
            if caps or 0 < i < len(pts) - 1: self.circle(x, z, w / 2, fill)

    def text(self, x, z, s, size, fill):
        if not self.sees(x - size * len(s), z - size, x + size * len(s), z + size): return
        self.d.text(self.P(x, z), s, fill=fill, font=ImageFont.truetype("arialbd.ttf", max(4, round(size * self.s))), anchor="mm")


def box(cx, cz, w, l, angle=0.0, chamfer=0.0):
    """Corners of an l (along `angle`, radians) by w rectangle centred on (cx, cz), optionally chamfered."""
    ca, sa = math.cos(angle), math.sin(angle)
    hw, hl, c = w / 2, l / 2, chamfer
    local = [(-hl, -hw), (hl, -hw), (hl, hw), (-hl, hw)] if c <= 0 else [
        (-hl + c, -hw), (hl - c, -hw), (hl, -hw + c), (hl, hw - c), (hl - c, hw), (-hl + c, hw), (-hl, hw - c), (-hl, -hw + c)]
    return [(cx + u * ca - v * sa, cz + u * sa + v * ca) for u, v in local]


def local(cx, cz, angle, u, v):
    return cx + u * math.cos(angle) - v * math.sin(angle), cz + u * math.sin(angle) + v * math.cos(angle)


# ---------------------------------------------------------------- flat things printed on the rug (3D things become toy models)
def flowers(p, x, z, rx, rz, seed, soil=True):
    rng = random.Random(seed)
    if soil: p.ellipse(x, z, rx + 1, rz + 1, shade(C["soil"], .85)); p.ellipse(x, z, rx, rz, C["soil"])
    for _ in range(int(rx * rz / 6) + 3):
        a, d = rng.uniform(0, 6.3), math.sqrt(rng.random()) * .85
        fx, fz = x + math.cos(a) * rx * d, z + math.sin(a) * rz * d
        p.circle(fx, fz, 1.6, shade(C["leaf2"], .9)); p.circle(fx, fz, 1.0, rng.choice(FLOWERS))


def manhole(p, x, z):
    p.circle(x, z, 2.6, (70, 70, 76)); p.circle(x, z, 2.1, (104, 104, 110))
    for k in (-1.2, 0, 1.2): p.line([(x - 1.6, z + k), (x + 1.6, z + k)], .3, (70, 70, 76), caps=False)


def pond(p, x, z, rx, rz, seed):
    rng = random.Random(seed)
    p.ellipse(x, z, rx + 5, rz + 5, C["shore"]); p.ellipse(x, z, rx, rz, C["water"])
    for k in (.8, .55, .3): p.ellipse(x - rx * .1, z - rz * .1, rx * k, rz * k, outline=C["water2"], w=.6)
    for _ in range(5):                                                                 # lily pads
        a, d = rng.uniform(0, 6.3), rng.uniform(.4, .8)
        lx, lz = x + math.cos(a) * rx * d, z + math.sin(a) * rz * d
        p.circle(lx, lz, 3, (80, 150, 80)); p.poly([(lx, lz), (lx + 3, lz - 1), (lx + 3, lz + 1)], C["water"])


def parking(p, x0, z0, x1, z1, along_x=True):
    """Empty bays (the cars will be toys); returns the bay centres and headings."""
    if p: p.rect(x0 - 1.5, z0 - 1.5, x1 + 1.5, z1 + 1.5, C["curb"], 3); p.rect(x0, z0, x1, z1, C["road"], 2)
    bays = []
    if along_x:
        mid = (z0 + z1) / 2
        for x in np.arange(x0 + 3, x1 - 11, 11):
            if p: p.line([(x, z0 + 2), (x, mid - 6)], .9, C["white"], caps=False); p.line([(x, mid + 6), (x, z1 - 2)], .9, C["white"], caps=False)
            bays += [(x + 5.5, (z0 + mid - 4) / 2, -math.pi / 2), (x + 5.5, (mid + 4 + z1) / 2, math.pi / 2)]
        if p: p.line([(x0 + 4, mid), (x1 - 4, mid)], .9, C["yellow"], caps=False)
    else:
        mid = (x0 + x1) / 2
        for z in np.arange(z0 + 3, z1 - 11, 11):
            if p: p.line([(x0 + 2, z), (mid - 6, z)], .9, C["white"], caps=False); p.line([(mid + 6, z), (x1 - 2, z)], .9, C["white"], caps=False)
            bays += [((x0 + mid - 4) / 2, z + 5.5, 0), ((mid + 4 + x1) / 2, z + 5.5, math.pi)]
        if p: p.line([(mid, z0 + 4), (mid, z1 - 4)], .9, C["yellow"], caps=False)
    return bays


def sandpit(p, x0, z0, x1, z1):
    p.rect(x0 - 2, z0 - 2, x1 + 2, z1 + 2, C["wood"], 8); p.rect(x0, z0, x1, z1, C["sand"], 7)


def pitch(p, x0, z0, x1, z1):
    p.rect(x0 - 4, z0 - 4, x1 + 4, z1 + 4, (196, 104, 70), 6)                       # running track
    for k in (1.5, 3): p.rect(x0 - 4 + k, z0 - 4 + k, x1 + 4 - k, z1 + 4 - k, None, 6 - k, C["white"], .4)
    p.rect(x0, z0, x1, z1, C["field"])
    n = 8
    for k in range(n):
        if k % 2: p.rect(x0 + (x1 - x0) * k / n, z0, x0 + (x1 - x0) * (k + 1) / n, z1, shade(C["field"], 1.08))
    lw, white, mx, mz, h = .8, C["white"], (x0 + x1) / 2, (z0 + z1) / 2, z1 - z0
    p.rect(x0 + 3, z0 + 3, x1 - 3, z1 - 3, None, 0, white, lw)
    p.line([(mx, z0 + 3), (mx, z1 - 3)], lw, white); p.circle(mx, mz, h * .16, None, white, lw); p.circle(mx, mz, 1, white)
    for side in (-1, 1):
        gx = mx + side * ((x1 - x0) / 2 - 3)
        p.rect(min(gx, gx - side * 22), mz - h * .3, max(gx, gx - side * 22), mz + h * .3, None, 0, white, lw)
        p.rect(min(gx, gx - side * 8), mz - h * .14, max(gx, gx - side * 8), mz + h * .14, None, 0, white, lw)


def court(p, x, z, w, l, kind):
    col = {"tennis": (70, 130, 170), "basket": C["court"]}[kind]
    p.rect(x - l / 2 - 4, z - w / 2 - 4, x + l / 2 + 4, z + w / 2 + 4, shade(col, .82), 2)
    p.rect(x - l / 2, z - w / 2, x + l / 2, z + w / 2, col, 1)
    white = C["white"]
    p.rect(x - l / 2 + 1.5, z - w / 2 + 1.5, x + l / 2 - 1.5, z + w / 2 - 1.5, None, 0, white, .6)
    if kind == "tennis":
        for u in (-.3, .3): p.line([(x + l * u, z - w / 2 + 5), (x + l * u, z + w / 2 - 5)], .5, white)
        p.line([(x - l * .3, z), (x + l * .3, z)], .5, white); p.line([(x, z - w / 2 + 1.5), (x, z + w / 2 - 1.5)], .5, white)
        for v in (-1, 1): p.line([(x - l / 2 + 1.5, z + v * (w / 2 - 5)), (x + l / 2 - 1.5, z + v * (w / 2 - 5))], .5, white)
    else:
        p.line([(x, z - w / 2 + 1.5), (x, z + w / 2 - 1.5)], .6, white); p.circle(x, z, w * .16, None, white, .6)
        for side in (-1, 1):
            ex = x + side * (l / 2 - 1.5)
            p.rect(min(ex, ex - side * 14), z - 6, max(ex, ex - side * 14), z + 6, shade(col, .9), 0, white, .6)


def runway(p, x0, x1, z, half):
    p.rect(x0 - 3, z - half - 3, x1 + 3, z + half + 3, C["walk"], 4)
    p.rect(x0, z - half, x1, z + half, (78, 80, 88), 2)
    for xx in np.arange(x0 + 34, x1 - 34, 16): p.line([(xx, z), (xx + 8, z)], 1.2, C["white"], caps=False)
    for end, sign in ((x0, 1), (x1, -1)):
        for k in range(-half + 4, half - 3, 4): p.line([(end + sign * 3, z + k), (end + sign * 13, z + k)], 2, C["white"], caps=False)
        p.text(end + sign * 22, z, "09" if sign > 0 else "27", 9, C["white"])


def crops(p, x0, z0, x1, z1, seed):
    """Ploughed fields in three shades of soil."""
    p.rect(x0, z0, x1, z1, C["wood"], 2)
    soils = [(150, 112, 78), (166, 124, 84), (138, 104, 72)]
    fw = (x1 - x0) / 3
    for k in range(3):
        soil = soils[(k + seed) % 3]
        fx0, fx1 = x0 + k * fw + 1.5, x0 + (k + 1) * fw - 1.5
        p.rect(fx0, z0 + 1.5, fx1, z1 - 1.5, soil)
        for zz in np.arange(z0 + 4, z1 - 2, 4.5): p.line([(fx0 + 1, zz), (fx1 - 1, zz)], 1.6, shade(soil, .82), caps=False)


def plot(p, x0, z0, x1, z1, path_end):
    """A garden plot for a toy house: lawn, a paved pad and a path to the road."""
    cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
    p.rect(x0, z0, x1, z1, C["grass2"], 2)
    p.line([(cx, cz), path_end], 6, C["pave"], caps=False)
    p.rect(cx - (x1 - x0) * .3, cz - (z1 - z0) * .3, cx + (x1 - x0) * .3, cz + (z1 - z0) * .3, C["pave"], 1.5)


def pad(p, x0, z0, x1, z1, col=None):
    """A paved pad where a building or toy will stand."""
    col = col or C["lot"]
    p.rect(x0 - 1.5, z0 - 1.5, x1 + 1.5, z1 + 1.5, C["curb"], 5); p.rect(x0, z0, x1, z1, col, 4)
    for k in np.arange(x0 + 6, x1 - 2, 7): p.line([(k, z0 + 2), (k, z1 - 2)], .35, shade(col, .92), caps=False)
    for k in np.arange(z0 + 6, z1 - 2, 7): p.line([(x0 + 2, k), (x1 - 2, k)], .35, shade(col, .92), caps=False)


def plaza_circle(p, x, z, r):
    p.circle(x, z, r + 1.5, C["curb"]); p.circle(x, z, r, C["pave"])
    for k in range(int(r / 8)): p.circle(x, z, r - 8 * k - 4, None, C["pave2"], .45)
    for a in range(0, 360, 15):
        a0 = math.radians(a)
        p.line([(x + math.cos(a0) * min(10, r / 3), z + math.sin(a0) * min(10, r / 3)), (x + math.cos(a0) * (r - 1), z + math.sin(a0) * (r - 1))], .35, C["pave2"], caps=False)


def toy_pad(p, x0, z0, x1, z1, seed):
    """A mown lawn edged with stones and a few flowers for a giant toy to stand on."""
    p.rect(x0 - 1.5, z0 - 1.5, x1 + 1.5, z1 + 1.5, C["stone"], 6); p.rect(x0, z0, x1, z1, C["grass2"], 5)
    for k, z in enumerate(np.arange(z0 + 2, z1 - 2, 8)):
        if k % 2: p.rect(x0 + 2, z, x1 - 2, min(z + 8, z1 - 2), shade(C["grass2"], 1.05))
    rng = random.Random(seed)
    for x, z in ((x0 + 5, z0 + 5), (x1 - 5, z0 + 5), (x0 + 5, z1 - 5), (x1 - 5, z1 - 5)):
        flowers(p, x, z, 3, 3, rng.randrange(9999), soil=False)


def road_in_plaza(x, z):
    return any(math.hypot(x - fx, z - fz) < FAN_PLAZA + 8 for fx, fz in FANS)


# ---------------------------------------------------------------- the town
PLAZAS = [(-142, -596, 142, -362)]          # buildings inside these stand on the plaza, not on a lot of their own


class Town:
    def __init__(self):
        self.ops, self.toys = [], []           # toys: where 3D toy models (trees, cars, fountains...) will stand
        self.free = Image.new("L", (4 * -2 * X0, 4 * -2 * Z0), 255)    # 4 px per stud; 0 = something is there
        self.fd = ImageDraw.Draw(self.free)
        self.junctions = junctions()
        self.structures = [(b[:4], kind_of(b[4])) for b in footprints()]
        self.checking, self.clashes = False, []        # placed things must not overlap roads or each other
        self.needs = []                                # things that need a driveway or footpath
        self.seed = 0

    def nseed(self):
        self.seed += 1; return self.seed

    def toy(self, kind, x, z, **extra):
        # angle: the toy's front points along (cos angle, sin angle) in x, z
        self.toys.append(dict(kind=kind, x=round(x, 1), z=round(z, 1), **{k: round(v, 2) for k, v in extra.items()}))

    def add(self, fn, occupy=None, label="", access=None):
        """Queue a drawing step; `occupy` is an (x, z, r) circle or (x0, z0, x1, z1, 'rect') box that is its alone.
        `access` ("drive" or "foot") asks for a driveway or footpath from it to the nearest pavement."""
        self.ops.append(fn)
        if occupy is None: return
        if len(occupy) == 5: x0, z0, x1, z1 = occupy[:4]
        else: x0, z0, x1, z1 = occupy[0] - occupy[2], occupy[1] - occupy[2], occupy[0] + occupy[2], occupy[1] + occupy[2]
        if access: self.needs.append(((x0, z0, x1, z1), access, label))
        def stamp(g):
            b = [int((x0 - g - X0) * 4), int((z0 - g - Z0) * 4), int((x1 + g - X0) * 4) + 1, int((z1 + g - Z0) * 4) + 1]
            shape = Image.new("L", (b[2] - b[0], b[3] - b[1]), 0)
            (ImageDraw.Draw(shape).rectangle if len(occupy) == 5 else ImageDraw.Draw(shape).ellipse)([0, 0, shape.size[0] - 1, shape.size[1] - 1], fill=255)
            return b, shape
        if self.checking:                                   # keep GAP studs of clear grass round everything
            b, shape = stamp(GAP)
            overlap = ((np.asarray(shape) > 0) & (np.asarray(self.free.crop(b)) == 0)).sum() / 16      # square studs
            if overlap > 2: self.clashes.append((label, round(overlap), [round(v) for v in (x0, z0, x1, z1)]))
        b, shape = stamp(0)
        self.free.paste(0, b[:2], mask=shape)

    def is_free(self, x, z, r):
        if not (X0 + 5 < x - r and x + r < -X0 - 5 and Z0 + 5 < z - r and z + r < -Z0 - 5): return False
        return np.asarray(self.free.crop((int((x - X0 - r) * 4), int((z - Z0 - r) * 4), int((x - X0 + r) * 4) + 1, int((z - Z0 + r) * 4) + 1))).min() > 0

    def occupy_line(self, pts, half, caps=True):
        for (ax, az), (bx, bz) in zip(pts, pts[1:]):
            self.fd.line([((ax - X0) * 4, (az - Z0) * 4), ((bx - X0) * 4, (bz - Z0) * 4)], fill=0, width=int(half * 8))
        for x, z in (pts if caps else pts[1:-1]):
            self.fd.ellipse([(x - X0 - half) * 4, (z - Z0 - half) * 4, (x - X0 + half) * 4, (z - Z0 + half) * 4], fill=0)

    def crop_rows(self, x0, z0, x1, z1, seed):
        """Toy crop rows on a ploughed field (see crops()): one crop per strip, rows between the furrow lines."""
        fw = (x1 - x0) / 3
        for k in range(3):
            fx0, fx1 = x0 + k * fw + 3, x0 + (k + 1) * fw - 3
            n = max(1, round((fx1 - fx0) / 20))
            for zz in np.arange(z0 + 6.25, z1 - 4, 9):
                for i in range(n): self.toy("crop", fx0 + (i + .5) * (fx1 - fx0) / n, zz, angle=math.pi / 2, color=(k + seed) % 3)

    def parking(self, x0, z0, x1, z1, along_x=True, label=""):
        self.add(lambda p: parking(p, x0, z0, x1, z1, along_x), occupy=(x0 - 2, z0 - 2, x1 + 2, z1 + 2, "rect"), label=label, access="drive")
        for x, z, a in parking(None, x0, z0, x1, z1, along_x)[::3]: self.toy("car", x, z, angle=a)

    # -------------------------------------------------- layers
    def ground(self):
        rng = random.Random(5)
        blobs = [(rng.uniform(X0, -X0), rng.uniform(Z0, -Z0), rng.uniform(30, 90), rng.choice([C["grass2"], C["grass3"]])) for _ in range(420)]
        g = np.random.default_rng(6)
        tufts = np.stack([g.uniform(X0, -X0, 60000), g.uniform(Z0, -Z0, 60000)], 1)
        daisies = np.stack([g.uniform(X0, -X0, 5000), g.uniform(Z0, -Z0, 5000)], 1)
        def ground(p):
            p.rect(X0 - 50, Z0 - 50, -X0 + 50, -Z0 + 50, C["grass"])
            for x, z, r, c in blobs: p.circle(x, z, r, c)
            v = p.view
            for pts, col, daisy in ((tufts, shade(C["grass"], .84), False), (daisies, (250, 250, 240), True)):
                for x, z in pts[(pts[:, 0] > v[0] - 2) & (pts[:, 0] < v[2] + 2) & (pts[:, 1] > v[1] - 2) & (pts[:, 1] < v[3] + 2)]:
                    if daisy: p.circle(x, z, .45, col); p.circle(x, z, .18, (240, 200, 80))
                    else: p.line([(x, z), (x + .7, z - 1.5)], .4, col, caps=False); p.line([(x + .6, z), (x + 1.6, z - 1.2)], .4, col, caps=False)
        self.ops.append(ground)

    def roads(self):
        for k, (pts, half) in enumerate(ROADS): self.occupy_line(pts, half + WALK, caps=k == 0)   # only the ring has round ends
        x, z, r, _ = ROUNDABOUT
        self.add(lambda p: None, occupy=(x, z, r + WALK))
        def roads(p):
            for k, (pts, half) in enumerate(ROADS): p.line(pts, 2 * (half + WALK), C["walk"], caps=k == 0)
            p.circle(x, z, r + WALK, C["walk"])
            for k, (pts, half) in enumerate(ROADS):                                     # paving joints on the pavements
                for sx, sz, tx, tz, s in polyline_points(pts, 6):
                    for side in (-1, 1):
                        a, b = half + 1.5, half + WALK
                        p.line([(sx - tz * side * a, sz + tx * side * a), (sx - tz * side * b, sz + tx * side * b)], .35, shade(C["walk"], .9), caps=False)
            for k, (pts, half) in enumerate(ROADS): p.line(pts, 2 * (half + 1.3), C["curb"], caps=k == 0)
            p.circle(x, z, r + 1.3, C["curb"])
            for k, (pts, half) in enumerate(ROADS): p.line(pts, 2 * half, C["road"], caps=k == 0)
            p.circle(x, z, r, C["road"])
        self.ops.append(roads)

    def markings(self):
        J = self.junctions
        def near(x, z, extra):
            return any(math.hypot(x - jx, z - jz) < d + extra for jx, jz, d in J) or math.hypot(x, z) < ROUNDABOUT[2] + WALK + extra
        dashes, edges, medians, zebras, stops = [], [], [], [], []
        for pts, half in ROADS:
            for x, z, tx, tz, s in polyline_points(pts, 13):
                if near(x, z, 6) or road_in_plaza(x, z): continue
                if half == BOULEVARD: medians.append((x, z, tx, tz))
                elif int(s / 13) % 2 == 0: dashes.append((x, z, tx, tz))
                for side in (-1, 1): edges.append((x - tz * side * (half - 3), z + tx * side * (half - 3), tx, tz))
            for jx, jz, d in J + [(0, 0, ROUNDABOUT[2] + WALK + 6)]:
                for x, z, tx, tz, s in polyline_points(pts, 1):
                    if abs(math.hypot(x - jx, z - jz) - d) < .5 and abs((x - jx) * tx + (z - jz) * tz) > d * .9:
                        zebras.append((x, z, tx, tz, half)); stops.append((x, z, tx, tz, half, jx, jz))
        def markings(p):
            for x, z, tx, tz in dashes: p.line([(x - tx * 3.4, z - tz * 3.4), (x + tx * 3.4, z + tz * 3.4)], 1.5, C["yellow"], caps=False)
            for x, z, tx, tz in edges: p.line([(x - tx * 6.6, z - tz * 6.6), (x + tx * 6.6, z + tz * 6.6)], 1.0, C["white"], caps=False)
            for x, z, tx, tz in medians:
                p.line([(x - tx * 6.7, z - tz * 6.7), (x + tx * 6.7, z + tz * 6.7)], 10, C["curb"], caps=False)
                p.line([(x - tx * 6.7, z - tz * 6.7), (x + tx * 6.7, z + tz * 6.7)], 8, C["grass2"], caps=False)
            for x, z, tx, tz, half in zebras:
                for k in range(-int(half) + 3, int(half) - 2, 5):
                    if half == BOULEVARD and abs(k + 1.3) < 6: continue                  # no stripes on the median
                    cx, cz = x - tz * (k + 1.3), z + tx * (k + 1.3)
                    p.line([(cx - tx * 4, cz - tz * 4), (cx + tx * 4, cz + tz * 4)], 2.6, C["white"], caps=False)
            for x, z, tx, tz, half, jx, jz in stops:                                    # stop line on the lane coming in
                away = 1 if (x - jx) * tx + (z - jz) * tz > 0 else -1
                sx, sz = x + tx * away * 6.5, z + tz * away * 6.5
                rx, rz = -tz * away, tx * away
                p.line([(sx - rx * 1, sz - rz * 1), (sx - rx * (half - 3), sz - rz * (half - 3))], 1.6, C["white"], caps=False)
            x, z, r, island = ROUNDABOUT
            for a in range(0, 360, 12):
                a0 = math.radians(a)
                p.line([(x + math.cos(a0) * (r - 17), z + math.sin(a0) * (r - 17)), (x + math.cos(a0 + .1) * (r - 17), z + math.sin(a0 + .1) * (r - 17))], 1.2, C["white"], caps=False)
            p.circle(x, z, island + 3, C["curb"]); p.circle(x, z, island, C["grass2"])
            flowers(p, x, z, island - 3, island - 3, 77)
            plaza_circle(p, x, z, island - 12)
        self.ops.append(markings)
        self.toy("fountain", 0, 0, r=ROUNDABOUT[3] - 14)
        for pts, half in ROADS:                                                          # manholes and drains are flat
            for x, z, tx, tz, s in polyline_points(pts, 61):
                if any(math.hypot(x - jx, z - jz) < d + 4 for jx, jz, d in J) or road_in_plaza(x, z) or math.hypot(x, z) < 100: continue
                side = 1 if int(s / 61) % 2 else -1
                self.ops.append(lambda p, x=x - tz * side * 9, z=z + tx * side * 9: manhole(p, x, z))
                for sd in (-1, 1):
                    dx, dz = x - tz * sd * (half - 1.2) + tx * 20, z + tx * sd * (half - 1.2) + tz * 20
                    self.ops.append(lambda p, dx=dx, dz=dz, a=math.atan2(tz, tx): p.poly(box(dx, dz, 1.6, 4.5, a), (66, 66, 72)))

    def lots(self):
        for (x0, z0, x1, z1), kind in self.structures:
            if kind == "building":
                if any(a <= x0 and b <= z0 and x1 <= c and z1 <= d for a, b, c, d in PLAZAS): continue
                b = (x0 - PAD, z0 - PAD, x1 + PAD, z1 + PAD)
                self.add(lambda p, b=b: pad(p, *b), occupy=b + ("rect",), label="building lot", access="drive")
            elif kind == "toy" and max(x1 - x0, z1 - z0) <= 50:         # small pillars just stand on the grass
                self.add(lambda p: None, occupy=(x0, z0, x1, z1, "rect"), label="pillar")
            elif kind == "toy":
                b = (x0 - PAD, z0 - PAD, x1 + PAD, z1 + PAD)
                self.add(lambda p, b=b, s=self.nseed(): toy_pad(p, *b, s), occupy=(b[0] - 2, b[1] - 2, b[2] + 2, b[3] + 2, "rect"), label="toy lawn", access="foot")

    def connect(self):
        """Give everything that asked for one a straight driveway or footpath to the nearest pavement, never across
        anything else. Anything left without a way in is reported as a clash."""
        for (x0, z0, x1, z1), kind, label in self.needs:
            hw = 7 if kind == "drive" else 3
            best = None
            for dx, dz in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                for f in (.5, .3, .7, .15, .85):
                    sx = x1 if dx > 0 else x0 if dx < 0 else x0 + (x1 - x0) * f
                    sz = z1 if dz > 0 else z0 if dz < 0 else z0 + (z1 - z0) * f
                    if dx and not (z0 + hw <= sz <= z1 - hw) or dz and not (x0 + hw <= sx <= x1 - hw): continue
                    for step in range(1, 160):
                        x, z = sx + dx * step, sz + dz * step
                        if road_at(x, z, WALK - .5):
                            if best is None or step < best[0]: best = (step, [(sx, sz), (x, z)])
                            break
                        if step > hw + 1 and not road_at(x, z, WALK + hw + 2) and not self.is_free(x, z, hw + 1): break
                    if best and best[0] < 4: break
            if not best:
                self.clashes.append((label + " has no way in", 0, [round(v) for v in (x0, z0, x1, z1)])); continue
            pts = best[1]
            if kind == "drive": self.ops.append(lambda p, pts=pts: (p.line(pts, 17, C["curb"], caps=False), p.line(pts, 14, C["lot"], caps=False)))
            else: self.ops.append(lambda p, pts=pts: (p.line(pts, 8, C["curb"], caps=False), p.line(pts, 6, C["pave"], caps=False)))
            self.occupy_line(pts, hw + 2, caps=False)

    def fans(self):
        for fx, fz in FANS:
            def fan_plaza(p, fx=fx, fz=fz):
                plaza_circle(p, fx, fz, FAN_PLAZA)
                p.circle(fx, fz, 88, None, (120, 200, 210), 1.2)                            # wind circle around the fan
            self.ops.append(fan_plaza)                                                      # opens onto the boulevard and ring on purpose
            self.add(lambda p: None, occupy=(fx, fz, FAN_PLAZA + 2))
            for a in range(30, 360, 60):
                a0 = math.radians(a)
                self.toy("bench", fx + math.cos(a0) * (FAN_PLAZA - 8), fz + math.sin(a0) * (FAN_PLAZA - 8), angle=a0 + math.pi)

    # -------------------------------------------------- the blocks (see the street plan above)
    # Town-planning rules, checked by add(): every building faces a street with its front SETBACK studs behind the
    # pavement (a shared build-to line, so a street's buildings line up), neighbours stand SETBACK apart, and no two
    # painted things come closer than GAP. Gardens, car parks and play areas sit behind the buildings.
    def design(self):
        add, toy = self.add, self.toy
        # North edge: a creek under the Pencil-Case Bridge.
        creek = [(-700, -675), (-640, -682), (-560, -676), (-470, -684), (-380, -677), (-300, -683), (-230, -676)]
        def creek_draw(p):
            p.line(creek, 30, C["shore"]); p.line(creek, 22, C["water"])
            for x, z in creek[1:-1:2]: p.line([(x - 18, z - 2), (x + 18, z + 2)], 1, C["water2"], caps=False)
        self.ops.append(creek_draw); self.occupy_line(creek, 16)
        for x in (-640, -300): toy("footbridge", x, -679, angle=math.pi / 2)
        # NW: cardboard block and book tower face the north street; three house plots face the ring road behind them.
        for x in (-690, -620, -550):
            add(lambda p, x=x: plot(p, x - 26, -589, x + 26, -545, (x, -603)), occupy=(x - 26, -589, x + 26, -545, "rect"), label="NW house plot")
            toy("house", x, -567, angle=-math.pi / 2)
        # Civic block: City Hall on a paved square at the end of the boulevard; a brick-park and a pond park each side.
        def civic(p):
            p.rect(-151.5, -590.5, 151.5, -369.5, C["curb"], 10); p.rect(-150, -589, 150, -371, C["pave"], 9)
            for k in range(-146, 150, 8): p.line([(k, -587), (k, -373)], .35, C["pave2"], caps=False)
            for k in range(-585, -373, 8): p.line([(-148, k), (148, k)], .35, C["pave2"], caps=False)
            for x in (-112, 112):
                for z in (-545, -420):
                    p.rect(x - 16, z - 22, x + 16, z + 22, C["curb"], 4); p.rect(x - 14, z - 20, x + 14, z + 20, C["grass2"], 3)
                    flowers(p, x, z, 10, 15, int(x * z) % 97)
            plaza_circle(p, 0, -394, 14)
        add(civic, occupy=(-150, -589, 150, -371, "rect"), label="civic square", access="foot")
        toy("fountain", 0, -394, r=12)
        for x in (-60, -32, 32, 60): toy("bench", x, -380, angle=-math.pi / 2)
        for x in (-140, 140): toy("flagpole", x, -380)
        add(lambda p: flowers(p, -400, -392, 40, 14, 8), occupy=(-441, -407, -359, -377, "rect"), label="west park flower bed")
        add(lambda p: pond(p, 300, -470, 95, 62, 3), occupy=(200, -537, 400, -403, "rect"), label="pond", access="foot")
        toy("boathouse", 385, -470, angle=math.pi); toy("ducks", 300, -470)
        add(lambda p: sandpit(p, 175, -589, 285, -551), occupy=(173, -591, 287, -549, "rect"), label="park sandpit", access="foot")
        toy("playground", 230, -570)
        # NE: two buildings face the north street; their car park is behind.
        self.parking(521, -589, 760, -540, label="NE car park")
        # W: book tower faces the street; a cul-de-sac of five house plots off the west avenue.
        lane = [(-507, -175), (-640, -175)]
        def culdesac(p):
            p.line(lane, 30, C["walk"], caps=False); p.circle(-660, -175, 30, C["walk"])
            p.line(lane, 26, C["curb"], caps=False); p.circle(-660, -175, 26, C["curb"])
            p.line(lane, 22, C["road"], caps=False); p.circle(-660, -175, 22, C["road"])
            p.circle(-660, -175, 8, C["grass2"])
            for xx in np.arange(-630, -515, 13): p.line([(xx, -175), (xx + 6, -175)], 1.2, C["white"], caps=False)
        add(culdesac, occupy=(-660, -175, 30), label="cul-de-sac")
        self.occupy_line(lane, 15)
        toy("tree", -660, -175, r=6)
        for x in (-552, -612):
            for side in (-1, 1):
                z = -175 + side * 50
                add(lambda p, x=x, z=z, side=side: plot(p, x - 24, z - 18, x + 24, z + 18, (x, z - side * 18)),
                    occupy=(x - 24, z - 18, x + 24, z + 18, "rect"), label="cul-de-sac plot")
                toy("house", x, z, angle=-side * math.pi / 2)
        add(lambda p: plot(p, -740, -197, -700, -153, (-700, -175)), occupy=(-740, -197, -700, -153, "rect"), label="cul-de-sac end plot")
        toy("house", -720, -175)
        # Centre west (school block): gable house on the boulevard, glue bottle on the street, courts and a sandpit.
        add(lambda p: sandpit(p, -439, -289, -355, -205), occupy=(-441, -291, -353, -203, "rect"), label="school sandpit", access="foot")
        toy("playground", -397, -247)
        add(lambda p: court(p, -190, -73, 36, 64, "basket"), occupy=(-226, -95, -154, -51, "rect"), label="basketball", access="foot")
        add(lambda p: court(p, -200, -175, 30, 54, "tennis"), occupy=(-231, -194, -169, -156, "rect"), label="tennis west", access="foot")
        # Centre east: market square on the north street, a car park on the boulevard.
        def market(p):
            p.rect(178.5, -290.5, 440.5, -167.5, C["curb"], 8); p.rect(180, -289, 439, -169, C["pave"], 7)
            for k in range(186, 439, 10): p.line([(k, -287), (k, -171)], .35, C["pave2"], caps=False)
            plaza_circle(p, 310, -229, 14)
        add(market, occupy=(180, -289, 439, -169, "rect"), label="market", access="foot")
        for i, x in enumerate(range(205, 430, 32)): toy("stall", x, -270, color=i % 6, angle=math.pi / 2); toy("stall", x, -188, color=(i + 3) % 6, angle=-math.pi / 2)
        toy("fountain", 310, -229, r=12)
        self.parking(198, -105, 439, -51, label="boulevard car park")
        # East: the airport under the ruler bridge.
        def airport(p):
            runway(p, 524, 886, -124, 16)
            p.rect(519.5, -290.5, 661.5, -247.5, C["curb"], 5); p.rect(521, -289, 660, -249, C["pave2"], 4)     # apron
            for x in (600, 636): p.circle(x, -269, 14, None, C["yellow"], .8)                                  # plane stands
            p.line([(560, -249), (560, -140)], 12, C["walk"], caps=False); p.line([(560, -249), (560, -140)], 10, (84, 86, 94), caps=False)
            p.line([(560, -249), (560, -140)], .6, C["yellow"], caps=False)
            p.rect(795.5, -290.5, 890.5, -253.5, C["curb"], 4); p.rect(797, -289, 889, -255, C["pave2"], 3)   # hangars
            p.circle(840, -180, 12, C["walk"]); p.circle(840, -180, 10, (84, 86, 94)); p.text(840, -180, "H", 9, C["white"])
        add(airport, occupy=(521, -143, 889, -105, "rect"), label="runway")
        add(lambda p: None, occupy=(521, -289, 660, -249, "rect"), label="apron", access="drive")
        add(lambda p: None, occupy=(797, -289, 889, -255, "rect"), label="hangar apron", access="drive")
        add(lambda p: None, occupy=(554, -243, 566, -149, "rect"), label="taxiway")
        add(lambda p: None, occupy=(828, -192, 852, -168, "rect"), label="helipad", access="foot")
        toy("terminal", 545, -275, angle=math.pi / 2); toy("plane", 600, -269, angle=math.pi / 2); toy("plane", 636, -269, angle=math.pi / 2)
        for x in (820, 866): toy("hangar", x, -272, angle=math.pi / 2)
        # West lower: tube tower on the south street; pine woods round a pond by the windows.
        add(lambda p: pond(p, -830, 190, 50, 36, 5), occupy=(-885, 149, -775, 231, "rect"), label="woods pond", access="foot")
        toy("picnic", -760, 262)
        # Library block: the open book faces the boulevard; ploughed allotments west, a garden east.
        def garden(p):
            p.rect(-216, 51, -100, 289, C["grass3"], 8); p.rect(-212, 55, -104, 285, C["grass2"], 6)
            for a, b in (((-212, 170), (-104, 170)), ((-158, 55), (-158, 285))): p.line([a, b], 10, C["pave"], caps=False)
            plaza_circle(p, -158, 170, 28)
            for x in (-190, -126):
                for z in (100, 240): p.ellipse(x, z, 12, 32, C["curb"]); flowers(p, x, z, 10, 30, int(x * z) % 91)
        add(garden, occupy=(-216, 51, -100, 289, "rect"), label="library garden", access="foot")
        toy("fountain", -158, 170, r=20)
        for z in (130, 210): toy("bench", -166, z, angle=0); toy("bench", -150, z, angle=math.pi)
        add(lambda p: crops(p, -439, 51, -364, 156, 1), occupy=(-439, 51, -364, 156, "rect"), label="allotment north", access="foot")
        self.crop_rows(-439, 51, -364, 156, 1)
        add(lambda p: crops(p, -439, 184, -364, 289, 2), occupy=(-439, 184, -364, 289, "rect"), label="allotment south", access="foot")
        self.crop_rows(-439, 184, -364, 289, 2)
        # Sports block: book tower and football pitch face the south street; tennis on the boulevard.
        add(lambda p: pitch(p, 253, 171, 433, 285), occupy=(249, 167, 437, 289, "rect"), label="pitch", access="foot")
        for side in (-1, 1): toy("goal", 343 + side * 91, 228, angle=0 if side < 0 else math.pi)     # mouth on the goal line, net behind it
        add(lambda p: court(p, 370, 70, 30, 54, "tennis"), occupy=(339, 51, 401, 89, "rect"), label="tennis east", access="foot")
        # East lower: the arch and a toy-brick stack face the south street; a petrol station on the boulevard.
        add(lambda p: pad(p, 521, 51, 595, 119), occupy=(519, 49, 597, 121, "rect"), label="petrol pad", access="drive")
        toy("petrol_station", 558, 85, angle=-math.pi / 2)
        # South-west: book tower, toy-brick stack and pencil cup in a row on the south street; the ring's curve stays green.
        # South centre-west: book tower and gateway on the street; four house plots face the ring road.
        for x in (-290, -228, -166, -104):
            add(lambda p, x=x: plot(p, x - 26, 545, x + 26, 589, (x, 603)), occupy=(x - 26, 545, x + 26, 589, "rect"), label="south house plot")
            toy("house", x, 567, angle=math.pi / 2)
        # South centre-east: skyscraper, pool deck and car park line the street; fire station, car park, brick stack on the ring.
        add(lambda p: pad(p, 144, 371, 262, 439, (236, 230, 216)), occupy=(142, 369, 264, 441, "rect"), label="pool deck", access="foot")
        toy("pool", 203, 405)
        self.parking(276, 371, 439, 440, label="street car park")
        add(lambda p: pad(p, 205, 523, 271, 589), occupy=(203, 521, 273, 591, "rect"), label="fire station pad")
        self.ops.append(lambda p: p.rect(218, 589, 258, 604, C["lot"]))
        toy("fire_station", 238, 548, angle=math.pi / 2); toy("fire_truck", 238, 578, angle=math.pi / 2)
        self.parking(51, 535, 191, 589, label="ring car park")
        # South-east: two book towers and a barn pad on the street; ploughed fields behind.
        add(lambda p: pad(p, 779, 371, 833, 415, (190, 160, 120)), occupy=(777, 369, 835, 417, "rect"), label="barn pad", access="drive")
        toy("barn", 806, 393, angle=-math.pi / 2); toy("hay_bale", 806, 440)
        add(lambda p: crops(p, 521, 500, 760, 589, 0), occupy=(521, 500, 760, 589, "rect"), label="farm fields", access="drive")
        self.crop_rows(521, 500, 760, 589, 0)

    def spots(self):
        """Where 3D toy trees and cars will go. Nothing is painted for them."""
        rng = random.Random(99)
        for _ in range(60000):
            x, z = rng.uniform(X0, -X0), rng.uniform(Z0, -Z0)
            r = rng.choice([8, 10, 12, 14, 16])
            if not self.is_free(x, z, r + 6): continue
            self.add(lambda p: None, occupy=(x, z, r + 6))
            self.toy("pine" if x < -500 and 30 < z < 320 else "tree", x, z, r=r)
        J = self.junctions
        for pts, half in ROADS:
            for x, z, tx, tz, s in polyline_points(pts, 38):
                if rng.random() > .3 or any(math.hypot(x - jx, z - jz) < d + 14 for jx, jz, d in J) or math.hypot(x, z) < 110 or road_in_plaza(x, z): continue
                way = rng.choice((-1, 1))
                off = (half - 10) if half == STREET else 17
                self.toy("car", x - tz * way * off, z + tx * way * off, angle=math.atan2(tz, tx) + (0 if way > 0 else math.pi))

    def render(self, pen):
        for op in self.ops: op(pen)


def check(town):
    bad = []
    for (x0, z0, x1, z1), kind in town.structures:
        if kind == "bridge": continue
        if any(road_at(x, z) for x in np.linspace(x0, x1, 12) for z in np.linspace(z0, z1, 12)):
            bad.append(((x0, z0, x1, z1), kind))
    for b, kind in bad: print("ON A ROAD:", kind, [round(v) for v in b])
    for label, area, b in town.clashes: print(f"OVERLAP: {label} at {b} covers {area} square studs of a road or something else")
    return not bad and not town.clashes


def build_town():
    t = Town()
    t.ground(); t.roads(); t.fans(); t.checking = True; t.lots(); t.design(); t.checking = False; t.connect()
    t.markings(); t.spots()
    return t


PAD_SKIP = {"abacus-hall": ("5-", "6-", "7-")}       # no lot under a fly-through middle (Alan 2026-10-16)


def ground_pad(b):
    """Where a building really meets the rug: its pieces that start at the ground (parts.json boxes, turned and placed
    like tools/town_toys.py buildings_v4 does), less any PAD_SKIP pieces. Gates stand on legs either side of a street."""
    a, k, (x, z) = -math.radians(b["yaw"]), b["scale"], b["centre"]
    c, s = math.cos(a), math.sin(a)
    boxes = []
    for piece in json.loads((ROOT / "assets/models" / b["name"] / "parts.json").read_text())["pieces"]:
        (x0, y0, z0), (x1, y1, _) = piece["bounding_box"]["min"], piece["bounding_box"]["max"]
        if z0 > 2 or piece["prefix"].startswith(PAD_SKIP.get(b["name"], ())): continue
        corners = [(-bx * k, by * k) for bx, by in ((x0, y0), (x1, y0), (x1, y1), (x0, y1))]   # Blender x, y -> local
        boxes.append(shapely.Polygon([(x + c * ox + s * oz, z - s * ox + c * oz) for ox, oz in corners]))
    return unary_union(boxes)


class PlanTown:
    """Layout D, printed flat. assets/rug/replan-v4.json (written by tools/town_plan.py) is the only layout source:
    roads, river, parks, plazas, buildings, lots and driveways are its shapes; this only paints them and plans
    the small 3D toys (trees, lamps, parked cars, monorail pylons, the toy sites' toys)."""
    def __init__(self, plan):
        self.plan = plan
        self.bounds = tuple(plan["rug"])
        self.x0, self.z0 = self.bounds[:2]
        self.width = math.ceil((self.bounds[2] - self.bounds[0]) / TILE)
        self.height = math.ceil((self.bounds[3] - self.bounds[1]) / TILE)
        self.walk = plan["walk"]
        rug = sbox(*self.bounds)
        self.lines = [(shp(r["line"]), r["half_width"]) for r in plan["roads"]]
        self.road = unary_union([g.buffer(h, cap_style="flat", join_style="mitre") for g, h in self.lines]).intersection(rug)
        self.paved = self.road.buffer(self.walk, join_style="mitre").intersection(rug)        # asphalt and pavements
        self.river = shp(plan["river"])
        self.legs = shp(plan["bell_tower"]["legs"])
        self.buildings = [(b["name"], shp(b["footprint"]), b) for b in plan["buildings"]]
        self.lots = [shp(l) for l in plan["lots"]]
        self.drives = [shp(d) for d in plan["driveways"]]
        self.circles = [(c.centroid.x, c.centroid.y, math.sqrt(c.area / math.pi)) for c in map(shp, plan["plazas"])]
        self.park, self.pond, self.eraser = shp(plan["park"]), shp(plan["pond"]), shp(plan["eraser_park"])
        self.fans = [(f["x"], f["z"]) for f in plan["fans"]]
        bell = plan["bell_tower"]                      # the square tower stands on a square pad just bigger than it
        self.bell_pad = shapely.affinity.rotate(sbox(-bell["size"] / 2 - 6, -bell["size"] / 2 - 6, bell["size"] / 2 + 6,
                                                     bell["size"] / 2 + 6), bell["yaw"], origin=(0, 0)).buffer(0)
        self.circles = [c for c in self.circles if min(math.dist(c[:2], f) for f in self.fans + [(bell["x"], bell["z"])]) > 5]
        self.site_list = [(t["name"], shp(t["footprint"]), tuple(t["front"])) for t in plan["sites"]]
        self.ops, self.toys = [], []

    def ground(self):
        x0, z0, x1, z1 = self.bounds          # flat grass: round shade patches read as printed trees (Alan 2026-10-16)
        g = np.random.default_rng(6)
        tufts = np.stack([g.uniform(x0, x1, 60000), g.uniform(z0, z1, 60000)], 1)
        def draw(p):
            p.rect(x0 - 50, z0 - 50, x1 + 50, z1 + 50, C["grass"])
            v = p.view
            pts, col = tufts, shade(C["grass"], .88)
            for x, z in pts[(pts[:, 0] > v[0] - 2) & (pts[:, 0] < v[2] + 2) & (pts[:, 1] > v[1] - 2) & (pts[:, 1] < v[3] + 2)]:
                p.line([(x, z), (x + .7, z - 1.5)], .4, col, caps=False); p.line([(x + .6, z), (x + 1.6, z - 1.2)], .4, col, caps=False)
        self.ops.append(draw)

    def parks(self):
        ec, er = self.eraser.centroid, math.sqrt(self.eraser.area / math.pi)
        # The eraser park's toys (Alan 2026-10-16: "needs a fountain, benches, bushes"): the fountain in the middle
        # basin, a bench facing it in three quarters beside the ring path, bushes round the edge between the paths. The
        # fourth quarter (around 315 degrees) is where the eraser lies (assets/models/toys/chalk-eraser).
        self.toy("fountain", ec.x, ec.y, 14, 15)
        for a in (45, 135, 225):
            t = math.radians(a)
            self.toy("bench", ec.x + math.cos(t) * er * .7, ec.y + math.sin(t) * er * .7, 5, 5, t + math.pi)
        for a in range(10, 360, 20):
            if min(abs(a - s) for s in (0, 90, 180, 270, 360)) > 12 and not 280 < a < 350:
                t = math.radians(a)
                self.toy("bush", ec.x + math.cos(t) * er * .9, ec.y + math.sin(t) * er * .9, 4.5, 12)
        def draw(p):
            p.area(self.park.buffer(1.5), C["hedge"]); p.area(self.park, shade(C["grass"], .93))
            p.area(self.pond.buffer(5), C["shore"]); p.area(self.pond, C["water"])
            for k in (8, 18, 28): p.area(self.pond.buffer(-k).boundary.buffer(.3), C["water2"])
            rng = random.Random(3); c = self.pond.centroid
            for _ in range(7):                                                   # lily pads
                lx, lz = c.x + rng.uniform(-40, 40), c.y + rng.uniform(-20, 20)
                if self.pond.buffer(-6).contains(SPoint(lx, lz)): p.circle(lx, lz, 3, (80, 150, 80))
            p.circle(ec.x, ec.y, er, C["grass2"]); p.circle(ec.x, ec.y, er * .62, None, C["pave"], 5)    # ring path
            for a in (0, 90, 180, 270):
                t = math.radians(a)
                p.line([(ec.x + math.cos(t) * 22, ec.y + math.sin(t) * 22), (ec.x + math.cos(t) * er, ec.y + math.sin(t) * er)], 5, C["pave"])
            plaza_circle(p, ec.x, ec.y, 24); p.circle(ec.x, ec.y, 16, C["stone"]); p.circle(ec.x, ec.y, 14, C["water"])
            for k, (fx, fz) in enumerate(((ec.x - er * .45, ec.y - er * .45), (ec.x + er * .45, ec.y + er * .45))):
                flowers(p, fx, fz, 7, 5, 40 + k)
        self.ops.append(draw)

    def plazas(self):
        for x, z, r in self.circles: self.ops.append(lambda p, x=x, z=z, r=r: plaza_circle(p, x, z, r))
        grid = unary_union([shapely.affinity.rotate(SLine([(k, -150), (k, 150)]), a + self.plan["bell_tower"]["yaw"], origin=(0, 0))
                            for k in range(-150, 151, 12) for a in (0, 90)]).intersection(self.bell_pad).buffer(.35)
        self.ops.append(lambda p: (p.area(self.bell_pad.buffer(1.5, join_style="mitre"), C["curb"]), p.area(self.bell_pad, C["pave"]),
                                   p.area(grid, C["pave2"])))                    # square paving slabs
        for x, z in self.fans:                                    # the round fan is 170 across: a round pad just bigger
            self.ops.append(lambda p, x=x, z=z: plaza_circle(p, x, z, 92))

    def river_and_pads(self):
        def draw(p):
            p.area(self.river.buffer(4), C["shore"]); p.area(self.river, C["water"])
            for k in (12, 26):                                                    # current lines
                p.area(self.river.buffer(-k).boundary.buffer(.4), C["water2"])
            for name, fp, b in self.buildings:                                   # paved pads; a gate's only under its legs
                g = fp.buffer(1.5, join_style="mitre")
                if b["gate"] or name in PAD_SKIP:
                    g = ground_pad(b).buffer(1.5, join_style="mitre").difference(self.paved).difference(self.river.buffer(4))
                p.area(g, C["lot"])
        self.ops.append(draw)

    def parking_lots(self):
        bays = []
        for lot in self.lots:
            c = list(lot.exterior.coords)
            e1, e2 = (c[0], c[1]), (c[1], c[2])
            (a, b), (_, d) = (e1, e2) if math.dist(*e1) >= math.dist(*e2) else (e2, (c[2], c[3]))
            L, Wd = math.dist(a, b), math.dist(b, d)
            ux, uz = (b[0] - a[0]) / L, (b[1] - a[1]) / L
            vx, vz = (d[0] - b[0]) / Wd, (d[1] - b[1]) / Wd                      # across the lot
            stalls = []
            for k in np.arange(4, L - 10, 11):
                for side in (0, 1):
                    s0, s1 = (2, Wd / 2 - 6) if side == 0 else (Wd / 2 + 6, Wd - 2)
                    ox, oz = a[0] + ux * k, a[1] + uz * k
                    stalls.append([(ox + vx * s0, oz + vz * s0), (ox + vx * s1, oz + vz * s1)])
                    cx, cz = ox + ux * 5.5 + vx * (s0 + s1) / 2, oz + uz * 5.5 + vz * (s0 + s1) / 2
                    bays.append((cx, cz, math.atan2(vz, vx)))
            def draw(p, lot=lot, stalls=stalls, a=a, b=b, vx=vx, vz=vz, Wd=Wd):
                p.area(lot.buffer(1.5, join_style="mitre"), C["curb"]); p.area(lot, C["road"])
                for seg in stalls: p.line(seg, .9, C["white"], caps=False)
                m = (vx * Wd / 2, vz * Wd / 2)
                p.line([(a[0] + m[0], a[1] + m[1]), (b[0] + m[0], b[1] + m[1])], .9, C["yellow"], caps=False)
            self.ops.append(draw)
        def draw(p):
            for d in self.drives: p.line(list(d.coords), 13, C["curb"], caps=False); p.line(list(d.coords), 10, C["road"], caps=False)
        self.ops.insert(len(self.ops) - len(self.lots), draw)                    # driveways under the lots
        rng = random.Random(8)
        for x, z, angle in bays:
            if rng.random() < .45: self.toy("car", x, z, 8, 7, angle)

    def sites(self):
        """Toy sites with their own ground: a fenced building site with a crane, a fire station forecourt, a petrol
        station forecourt; each with a short apron out to its street."""
        for name, poly, (nx, nz) in self.site_list:
            c = poly.centroid
            front = max(poly.exterior.coords[:-1], key=lambda q: (q[0] - c.x) * nx + (q[1] - c.y) * nz)
            depth = max((q[0] - c.x) * nx + (q[1] - c.y) * nz for q in poly.exterior.coords) * 2
            fx, fz = c.x + nx * depth / 2, c.y + nz * depth / 2                    # middle of the street side
            rx, rz = self.road.boundary.interpolate(self.road.boundary.project(SPoint(fx, fz))).coords[0]
            face = math.atan2(nz, nx)
            def site_point(a, b, fx=fx, fz=fz, nx=nx, nz=nz):                    # a: in from the street side, b: across
                return fx - nx * a - nz * b, fz - nz * a + nx * b
            def draw(p, name=name, site_point=site_point, poly=poly, c=c, fx=fx, fz=fz, rx=rx, rz=rz, nx=nx, nz=nz, depth=depth):
                p.line([(fx, fz), (rx, rz)], 18, C["curb"], caps=False); p.line([(fx, fz), (rx, rz)], 15, C["lot"], caps=False)
                if name == "building site":                                       # packed dirt, tyre tracks, a dug pit
                    dirt = (198, 164, 116)                                         # (the fence is 3D toys now)
                    p.area(poly, dirt)
                    for k in (-.25, .25):
                        p.line([(c.x - nz * depth * k - nx * depth * .45, c.y + nx * depth * k - nz * depth * .45),
                                (c.x - nz * depth * k + nx * depth * .45, c.y + nx * depth * k + nz * depth * .45)], 3, shade(dirt, .86), caps=False)
                    pit = [site_point(a, b) for a, b in ((13, -23), (39, -23), (39, -43), (13, -43))]
                    p.poly(pit, shade(dirt, .78)); p.poly([site_point(a, b) for a, b in ((15, -25), (37, -25), (37, -41), (15, -41))], shade(dirt, .64))
                else:
                    p.area(poly, C["lot"])
                    if name == "fire station":                                    # red-hatched forecourt
                        for k in np.arange(-20, 21, 6):
                            p.line([(fx - nx * 6 - nz * k, fz - nz * 6 + nx * k), (fx - nx * 18 - nz * k, fz - nz * 18 + nx * k)], 1.6, C["red"], caps=False)
                    else:                                                         # two pump islands
                        for k in (-14, 14):
                            p.poly(box(c.x + nx * 6 - nz * k, c.y + nz * 6 + nx * k, 4, 16, face), C["stone"], C["curb"], .6)
            self.ops.append(draw)
            back = (c.x - nx * depth * .25, c.y - nz * depth * .25)
            if name == "building site":                                           # the layout Alan checked (2026-10-16)
                width = max(abs((q[0] - c.x) * -nz + (q[1] - c.y) * nx) for q in poly.exterior.coords) * 2
                def put(kind, a, b, r, height, angle=face):
                    self.toy(kind, *site_point(a, b), r, height, angle)
                cx, cz = site_point(66, 35); bx, bz = site_point(60, -25)
                put("crane", 66, 35, 11, 80, math.atan2(bz - cz, bx - cx))         # jib over the half-built tower
                put("site-building", 60, -25, 18, 43)
                put("digger", 26, -33, 8, 14); put("dump-truck", 21, -3, 8, 11)
                put("site-cabin", 14, 37, 7, 7.4); put("site-toilet", 25, 38, 3, 7.6)
                put("sand-pile", 36, 35, 6, 4.6); put("gravel-pile", 44, 15, 6, 4.7)
                put("plank-stack", 28, 19, 4, 2.5); put("brick-stack", 39, 3, 4, 3.6); put("pipe-stack", 54, 4, 4, 3)
                put("cement-mixer", 32, -15, 3.5, 7.1)
                for b in (-17.5, 17.5): put("barrier", 1.5, b, 5, 5.5)
                for b in (-10, 10): put("cone", -4, b, 2, 5.3)
                half = width / 2 - 1                                              # hoarding panels meeting at the corners
                n = round(2 * half / 10.4); step = 2 * half / n
                for b in -half + step / 2 + np.arange(n) * step:
                    if abs(b) > 23: put("site-fence", 1, b, 5, 5.9)               # gate gap on the street side
                    put("site-fence", depth - 1, b, 5, 5.9, face + math.pi)
                n = round((depth - 2) / 10.4); step = (depth - 2) / n
                for a in 1 + step / 2 + np.arange(n) * step:
                    for side in (-1, 1): put("site-fence", a, side * half, 5, 5.9, face + side * math.pi / 2)
            elif name == "fire station":
                self.toy("fire_station", *back, 26, 38, face); self.toy("fire_truck", c.x + nx * depth * .3, c.y + nz * depth * .3, 8, 10, face)
            else:
                self.toy("petrol_station", *back, 30, 34, face)

    def streets(self):
        rails = [g.boundary.difference(self.river.boundary.buffer(1)) for g in map(shp, [self.plan["road_bridges"]])]
        def draw(p):
            p.area(self.paved, C["walk"]); p.area(self.road.buffer(1.3, join_style="mitre"), C["curb"]); p.area(self.road, C["road"])
            for r in rails:
                for seg in getattr(r, "geoms", [r]): p.line(list(seg.coords), 1.6, C["wood2"])
        self.ops.append(draw)

    def in_square(self, x, z, pad=0):
        return any(math.hypot(x - cx, z - cz) < r + pad for cx, cz, r in self.circles)

    def markings(self):
        dashes, crossings = [], []
        for i, (g, half) in enumerate(self.lines):
            others = [(o, h) for j, (o, h) in enumerate(self.lines) if j != i]
            for line in getattr(g, "geoms", [g]):
                for x, z, tx, tz, dist in polyline_points(list(line.coords), 17):
                    if int(dist / 17) % 2: continue
                    pt = SPoint(x, z)
                    if any(pt.distance(o) < h + self.walk + 22 for o, h in others): continue
                    dashes.append([(x - tx * 8.5, z - tz * 8.5), (x + tx * 8.5, z + tz * 8.5)])
            beside = unary_union([o.buffer(h + self.walk, cap_style="flat", join_style="mitre") for o, h in others])
            mine = []
            for o, h in others:                                                   # a zebra on each arm of each junction,
                hit = g.intersection(o)                                           # just clear of the crossing street
                for j in getattr(hit, "geoms", [hit]):
                    if j.is_empty or j.geom_type != "Point": continue
                    for line in getattr(g, "geoms", [g]):
                        if line.distance(j) > 1: continue
                        t0 = line.project(j)
                        for sign in (-1, 1):
                            for d in range(4, 120, 2):
                                t = t0 + sign * d
                                if not 1 < t < line.length - 1: break
                                a, b = line.interpolate(t - 1), line.interpolate(t + 1)
                                tx, tz = b.x - a.x, b.y - a.y; n = math.hypot(tx, tz) or 1; tx, tz = tx / n, tz / n
                                c = line.interpolate(t)
                                seg = SLine([(c.x + tz * half, c.y - tx * half), (c.x - tz * half, c.y + tx * half)])
                                if seg.buffer(7.5, cap_style="flat").intersects(beside): continue
                                if self.road.buffer(.5).contains(seg) and all(math.dist((c.x, c.y), m) > 12 for m in mine):
                                    crossings.append((c.x, c.y, tx, tz, half)); mine.append((c.x, c.y))
                                break
        dashes = [d for d in dashes if all(math.dist(((d[0][0] + d[1][0]) / 2, (d[0][1] + d[1][1]) / 2), c[:2]) > 17
                                           for c in crossings)]                 # no dash running into a zebra
        def draw(p):
            for seg in dashes: p.line(seg, 3.5, C["yellow"], caps=False)
            for x, z, tx, tz, half in crossings:
                for k in np.arange(-half + 3.5, half - 2, 6.5):
                    cx, cz = x - tz * (k + 1.5), z + tx * (k + 1.5)
                    p.line([(cx - tx * 7, cz - tz * 7), (cx + tx * 7, cz + tz * 7)], 3.5, C["white"], caps=False)
        self.crossings = crossings
        self.ops.append(draw)

    def toy(self, kind, x, z, r, height, angle=0.0):
        self.toys.append(dict(kind=kind, x=round(float(x), 3), z=round(float(z), 3), r=float(r), height=float(height),
                              angle=round(float(angle), 5)))

    def spots(self):
        mono = self.plan["monorail"]; line = shp(mono["line"])
        solid = unary_union([fp for _, fp, _ in self.buildings])
        pylons = []
        def median(pt):                                   # on a road's centre line, clear of junctions and zebras
            on = [i for i, (g, _) in enumerate(self.lines) if g.distance(pt) < 1]
            return on and all(g.distance(pt) > h + self.walk + 10 for i, (g, h) in enumerate(self.lines) if i not in on)                 and all(math.dist((pt.x, pt.y), c[:2]) > 30 for c in self.crossings)
        for x, z in mono["pylons"]:     # on the pavement under the track, in the river, or in a road's middle (Alan 2026-10-16)
            t0 = line.project(SPoint(x, z))
            for t in [t0 + k * sign for k in range(0, 60, 4) for sign in (1, -1)]:
                pt = line.interpolate(t)
                if (self.road.distance(pt) > 2 or median(pt)) and pt.distance(solid) > 6: break
            else: continue
            a, b = line.interpolate(t), line.interpolate(min(line.length, t + 1))
            self.toy("monorail-pylon", pt.x, pt.y, 3, mono["track_top"], math.atan2(b.y - a.y, b.x - a.x))
            pylons.append(pt)
        for g, half in self.lines:                                                # street lamps on the pavements
            for line in getattr(g, "geoms", [g]):
                for x, z, tx, tz, _ in polyline_points(list(line.coords), 95):
                    for side in (-1, 1):
                        off = half + self.walk / 2
                        px, pz = x - tz * side * off, z + tx * side * off
                        pt = SPoint(px, pz)
                        if self.road.distance(pt) < 2 or not self.paved.contains(pt) or pt.distance(solid) < 4: continue
                        if self.in_square(px, pz) or self.river.contains(pt) or any(pt.distance(q) < 10 for q in pylons): continue
                        self.toy("lamp", px, pz, 1.2, 38, math.atan2(tz, tx) + side * math.pi / 2)
        keep = unary_union([self.paved.buffer(4), self.river.buffer(8), solid.buffer(8)] + [l.buffer(5) for l in self.lots] +
                           [d.buffer(9) for d in self.drives] + [q.buffer(6) for _, q, _ in self.site_list] +
                           [SPoint(x, z).buffer(r + 4) for x, z, r in self.circles] + [self.pond.buffer(8), self.eraser] +
                           [self.bell_pad.buffer(6)] +
                           [SPoint(x, z).buffer(100) for x, z in self.fans] + [shp(c) for c in self.plan["clear"]])
        rng = np.random.default_rng(99)
        x0, z0, x1, z1 = self.bounds
        pts = np.stack([rng.uniform(x0 + 12, x1 - 12, 9000), rng.uniform(z0 + 12, z1 - 12, 9000)], 1)
        radii = rng.choice([8, 10, 12, 14], 9000)
        room = shapely.distance(keep, shapely.points(pts))
        taken = []
        for (x, z), r, d in zip(pts, radii, room):
            if d < r or any((x - tx) ** 2 + (z - tz) ** 2 < (r + tr + 6) ** 2 for tx, tz, tr in taken[-400:]): continue
            taken.append((x, z, r))
            self.toy("pine" if self.park.contains(SPoint(x, z)) and rng.random() < .5 else "tree", x, z, r, 2.5 * r)

    def transport(self):
        """Alan 2026-10-16: four bus stops (one per quarter of town, on a straight bit of main street) each with a
        bus beside it; the tugboat and three paper boats on the river; two rowing boats on the pond."""
        solid = unary_union([fp for _, fp, _ in self.buildings] + [q for _, q, _ in self.site_list])
        stops = []
        for qx, qz in ((-1, -1), (1, -1), (-1, 1), (1, 1)):
            best = None
            for i, (g, half) in enumerate(self.lines):
                others = [o.buffer(h + self.walk + 40) for j, (o, h) in enumerate(self.lines) if j != i]
                for line in getattr(g, "geoms", [g]):
                    for x, z, tx, tz, dist in polyline_points(list(line.coords), 10):
                        a, b = line.interpolate(max(0, dist - 42)), line.interpolate(min(line.length, dist + 42))
                        if SLine([(a.x, a.y), (b.x, b.y)]).distance(SPoint(x, z)) > .5 or a.distance(b) < 83: continue   # bend
                        for side in (-1, 1):
                            nx, nz = -tz * side, tx * side                                  # out from the road
                            sx, sz = x + nx * (half + self.walk / 2 + 1.5), z + nz * (half + self.walk / 2 + 1.5)
                            if sx * qx < 150 or sz * qz < 100: continue
                            stop = shapely.affinity.rotate(sbox(sx - 7.5, sz - 3.6, sx + 7.5, sz + 3.6), math.degrees(math.atan2(tz, tx)), origin=(sx, sz))
                            if any(o.intersects(stop) for o in others) or stop.distance(solid) < 5 or stop.distance(self.river) < 15: continue
                            if self.in_square(sx, sz, 12) or any(math.dist((x, z), q[:2]) < 45 for q in self.crossings): continue
                            score = math.dist((sx, sz), (qx * 520, qz * 330))
                            if best is None or score < best[0]:
                                best = (score, sx, sz, nx, nz, tx, tz, half)
            if best:
                _, sx, sz, nx, nz, tx, tz, half = best
                stops.append((sx, sz))
                self.toy("bus-stop", sx, sz, 8, 10.4, math.atan2(-nz, -nx))               # open side faces the road
                bx, bz = sx - nx * (half + self.walk / 2 + 1.5 - half / 2), sz - nz * (half + self.walk / 2 + 1.5 - half / 2)
                self.toy("bus", bx, bz, 14, 11.2, math.atan2(tz, tx))
        self.toys = [t for t in self.toys if t["kind"] not in ("lamp", "tree", "pine") or
                     all(math.dist((t["x"], t["z"]), q) > 12 + t["r"] for q in stops)]
        x0, z0, x1, z1 = self.river.bounds                                                # boats on the river's middle line
        def river_mid(x):
            cut = self.river.intersection(SLine([(x, z0 - 1), (x, z1 + 1)]))
            return None if cut.is_empty else (cut.bounds[1] + cut.bounds[3]) / 2
        for kind, x, size in (("tugboat", -700, 20), ("paper-boat", -230, 10), ("paper-boat", 240, 10), ("paper-boat", 700, 10)):
            for dx in sorted(range(-200, 201, 10), key=abs):                               # nearest clear water to x
                z = river_mid(x + dx)
                if z is not None and self.road.distance(SPoint(x + dx, z)) > size + 6:
                    z2 = river_mid(x + dx + 5) or z
                    self.toy(kind, x + dx, z, size, 16.5 if kind == "tugboat" else 8.2, math.atan2(z2 - z, 5)); break
        c = self.pond.centroid
        for k, (ox, oz, turn) in enumerate(((-28, 6, .6), (26, -4, -.9))):
            self.toy("rowing-boat", c.x + ox, c.y + oz, 8, 3.5, turn)

    def check(self):
        bad = [f"Building on asphalt: {n}" for n, fp, b in self.buildings if not b["gate"] and fp.intersects(self.road)]
        if self.legs.intersects(self.road): bad.append("A road runs into a bell tower leg")
        for t in self.toys:
            if t["kind"] in ("tree", "pine", "car") and self.road.contains(SPoint(t["x"], t["z"])): bad.append(f"Toy on asphalt: {t}")
        counts = {k: sum(t["kind"] == k for t in self.toys) for k in sorted({t["kind"] for t in self.toys})}
        print(len(self.buildings), "buildings,", len(self.lots), "lots,", len(self.crossings), "crosswalks, toys:", counts)
        for message in bad: print("FAILED:", message)
        print("v4 rug checks", "FAILED" if bad else "passed")
        return not bad

    def render(self, pen):
        for op in self.ops: op(pen)


def build_plan(plan):
    C.update(PLAYMAT)                       # ponytail: global palette swap; the old Town never runs in the same process
    town = PlanTown(plan)
    town.ground(); town.parks(); town.plazas(); town.river_and_pads(); town.parking_lots(); town.sites(); town.streets()
    town.markings(); town.spots(); town.transport()
    return town


def grain(img, i, j, x0=X0, z0=Z0, width=W, weave=False):
    """Close-up texture by material: speckled asphalt, grass blades, uneven paving; plus a faint printed-fabric grain."""
    a = np.asarray(img).astype(np.float32)
    rng = np.random.default_rng(j * width + i)
    yy, xx = np.mgrid[0:PX, 0:PX].astype(np.float32)
    wx, wz = x0 + (i + xx / PX) * TILE, z0 + (j + yy / PX) * TILE                     # world studs, continuous across tiles
    slow = np.sin(wx * .061 + np.sin(wz * .043) * 2) + np.sin(wz * .057 + np.sin(wx * .037) * 2)
    def near(col, tol):
        return (np.abs(a - np.array(col, np.float32)).max(-1) < tol)[..., None]
    road, walk = near(C["road"], 9), near(C["walk"], 9) | near(C["pave"], 9) | near(C["lot"], 9)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    grassy = ((g > r + 18) & (g > b + 30))[..., None]
    speck = rng.random(a.shape[:2])
    a += road * ((speck > .82) * 9 - (speck < .14) * 7 + slow * 3)[..., None]
    blades = rng.standard_normal((PX // 4, PX)).repeat(4, 0) * .5 + rng.standard_normal((PX, PX)) * .5
    a += grassy * (blades * 7 + slow * 3)[..., None]
    a += walk * ((speck - .5) * 6 + slow * 1.5)[..., None]
    a += rng.integers(-3, 4, size=a.shape[:2])[..., None]
    if weave:                     # play-mat: woven loops (0.6 studs, continuous across tiles) and fibre fuzz on print edges
        a += (np.sin(wx * 10.5) * np.sin(wz * 10.5) * 5)[..., None]
        fy = np.clip(yy.astype(int) + rng.integers(-2, 3, a.shape[:2]), 0, PX - 1)
        fx = np.clip(xx.astype(int) + rng.integers(-2, 3, a.shape[:2]), 0, PX - 1)
        a = a[fy, fx]
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))


def draw_tile(town, i, j):
    s = PX * SS / TILE
    m = MARGIN * SS
    img = Image.new("RGB", (PX * SS + 2 * m, PX * SS + 2 * m))
    x0, z0, width = (town.x0, town.z0, town.width) if isinstance(town, PlanTown) else (X0, Z0, W)
    town.render(Pen(img, x0 + i * TILE - m / s, z0 + j * TILE - m / s, s))
    img = img.resize((PX + 2 * MARGIN, PX + 2 * MARGIN), Image.LANCZOS).crop((MARGIN, MARGIN, MARGIN + PX, MARGIN + PX))
    return grain(img, i, j, x0, z0, width, weave=isinstance(town, PlanTown))


def upload(names, folder=RUG / "tiles"):
    records = RUG / "uploads"; records.mkdir(exist_ok=True); ids = {}
    for name in names:
        record = records / f"{name}.json"
        if not record.exists():
            subprocess.run([sys.executable, str(ROOT / "tools/upload_texture.py"), str(folder / f"{name}.png"),
                            "--creator", "52064999", "--name", f"FlyFightPaper rug {name}", "--output", str(record)], check=True)
        ids[name] = json.loads(record.read_text())["response"]["assetId"]
    return ids


def upload_carpet():
    """Re-upload a shared carpet map whenever its picture changed (the record keeps the picture's hash)."""
    for k in ("normal", "roughness"):
        png, record = RUG / "carpet" / f"{k}.png", RUG / "carpet" / f"{k}.json"
        sha = hashlib.sha256(png.read_bytes()).hexdigest()
        if json.loads(record.read_text()).get("sha256") != sha:
            new = record.with_suffix(".new.json")                 # the old record stays until the new upload lands
            subprocess.run([sys.executable, str(ROOT / "tools/upload_texture.py"), str(png), "--creator", "52064999",
                            "--name", f"FlyFightPaper rug carpet {k}", "--output", str(new)], check=True)
            r = json.loads(new.read_text()); r["sha256"] = sha; record.write_text(json.dumps(r, indent=2)); new.unlink()
        CARPET[k] = json.loads(record.read_text())["response"]["assetId"]


def tile_part(name, x, z, color_id):
    # Turned half a circle: the tile mesh shows the picture's top edge toward +Z, and the pictures are drawn north-up.
    return (f'<Item class="MeshPart"><Properties><string name="Name">{name}</string>'
            f'<Content name="MeshId"><url>{TILE_MESH}</url></Content>'
            '<Vector3 name="InitialSize"><X>2048</X><Y>20.48</Y><Z>2048</Z></Vector3>'
            '<bool name="Anchored">true</bool><bool name="CanCollide">false</bool><bool name="CanQuery">false</bool>'
            '<bool name="CanTouch">false</bool><bool name="CastShadow">false</bool><token name="CollisionFidelity">2</token>'
            '<token name="RenderFidelity">1</token><token name="Material">1056</token>'
            f'<Vector3 name="size"><X>{TILE}</X><Y>0.6</Y><Z>{TILE}</Z></Vector3>'
            f'<CoordinateFrame name="CFrame"><X>{x}</X><Y>0.3</Y><Z>{z}</Z><R00>-1</R00><R01>0</R01><R02>0</R02>'
            '<R10>0</R10><R11>1</R11><R12>0</R12><R20>0</R20><R21>0</R21><R22>-1</R22></CoordinateFrame>'
            '</Properties><Item class="SurfaceAppearance"><Properties><string name="Name">Carpet</string>'
            '<token name="AlphaMode">0</token>'
            f'<Content name="ColorMap"><url>rbxassetid://{color_id}</url></Content>'
            f'<Content name="NormalMap"><url>rbxassetid://{CARPET["normal"]}</url></Content>'
            f'<Content name="RoughnessMap"><url>rbxassetid://{CARPET["roughness"]}</url></Content>'
            '</Properties></Item></Item>')


def border_part(name, x, z, length, turned):
    """Navy fabric binding round the rug's edge with two rows of white stitches; long side along x (or z when turned)."""
    r = "<R00>0</R00><R01>0</R01><R02>1</R02><R10>0</R10><R11>1</R11><R12>0</R12><R20>-1</R20><R21>0</R21><R22>0</R22>" if turned else         "<R00>1</R00><R01>0</R01><R02>0</R02><R10>0</R10><R11>1</R11><R12>0</R12><R20>0</R20><R21>0</R21><R22>1</R22>"
    return (f'<Item class="Part"><Properties><string name="Name">{name}</string><bool name="Anchored">true</bool>'
            '<bool name="CanCollide">false</bool><bool name="CanQuery">false</bool><bool name="CanTouch">false</bool>'
            '<bool name="CastShadow">false</bool><token name="Material">1056</token>'
            '<token name="TopSurface">0</token><token name="BottomSurface">0</token>'
            f'<Color3uint8 name="Color3uint8">{0xFF000000 | 44 << 16 | 62 << 8 | 120}</Color3uint8>'
            f'<Vector3 name="size"><X>{length}</X><Y>1.4</Y><Z>12</Z></Vector3>'
            f'<CoordinateFrame name="CFrame"><X>{x}</X><Y>0.5</Y><Z>{z}</Z>{r}</CoordinateFrame></Properties>'
            '<Item class="Texture"><Properties><string name="Name">Stitches</string><token name="Face">1</token>'
            f'<Content name="Texture"><url>rbxassetid://{STITCH}</url></Content>'
            '<float name="StudsPerTileU">6</float><float name="StudsPerTileV">12</float></Properties></Item></Item>')


def binding_parts():
    """The play-mat's green stitched edge (Alan 2026-10-16): a 3-tall band 16 wide (2 of it over the rug), a round
    roll along its outer side, round corners; the stitch picture in two rows on top."""
    green = f'<Color3uint8 name="Color3uint8">{0xFF000000 | BINDING[0] << 16 | BINDING[1] << 8 | BINDING[2]}</Color3uint8>'
    flat, turn = ("<R00>1</R00><R01>0</R01><R02>0</R02><R10>0</R10><R11>1</R11><R12>0</R12><R20>0</R20><R21>0</R21><R22>1</R22>",
                  "<R00>0</R00><R01>0</R01><R02>1</R02><R10>0</R10><R11>1</R11><R12>0</R12><R20>-1</R20><R21>0</R21><R22>0</R22>")
    up = "<R00>0</R00><R01>-1</R01><R02>0</R02><R10>1</R10><R11>0</R11><R12>0</R12><R20>0</R20><R21>0</R21><R22>1</R22>"
    def part(name, shape, size, pos, r, stitches=False):
        return (f'<Item class="Part"><Properties><string name="Name">{name}</string><bool name="Anchored">true</bool>'
                '<bool name="CanCollide">false</bool><bool name="CanQuery">false</bool><bool name="CanTouch">false</bool>'
                f'<bool name="CastShadow">false</bool><token name="Material">1056</token><token name="shape">{shape}</token>'
                f'<token name="TopSurface">0</token><token name="BottomSurface">0</token>{green}'
                f'<Vector3 name="size"><X>{size[0]}</X><Y>{size[1]}</Y><Z>{size[2]}</Z></Vector3>'
                f'<CoordinateFrame name="CFrame"><X>{pos[0]}</X><Y>{pos[1]}</Y><Z>{pos[2]}</Z>{r}</CoordinateFrame></Properties>'
                + ('<Item class="Texture"><Properties><string name="Name">Stitches</string><token name="Face">1</token>'
                   f'<Content name="Texture"><url>rbxassetid://{STITCH}</url></Content>'
                   '<float name="StudsPerTileU">6</float><float name="StudsPerTileV">14.5</float></Properties></Item>'
                   if stitches else '') + '</Item>')
    hx, hz, band, H3 = -X0, -Z0, 14.5, 3                    # band runs from 2 studs inside the rug edge to 12.5 outside
    items = []
    for sign in (-1, 1):
        zc, xc = sign * (hz + 12.5 - band / 2), sign * (hx + 12.5 - band / 2)
        items += [part("RugBinding", 1, (2 * hx - 4, H3, band), (0, H3 / 2, zc), flat, True),
                  part("RugBinding", 1, (2 * hz - 4, H3, band), (xc, H3 / 2, 0), turn, True),
                  part("RugBindingRoll", 2, (2 * hx - 4, H3, H3), (0, H3 / 2, sign * (hz + 12.5)), flat),
                  part("RugBindingRoll", 2, (2 * hz - 4, H3, H3), (sign * (hx + 12.5), H3 / 2, 0), turn)]
    for sx in (-1, 1):
        for sz in (-1, 1):                                  # round corners centred 2 studs inside the rug corner
            items.append(part("RugBindingCorner", 2, (H3, 32, 32), (sx * (hx - 2), H3 / 2, sz * (hz - 2)), up))
    return items


def build(ids):
    items = [tile_part(f"Rug{i}_{j}", X0 + TILE * (i + .5), Z0 + TILE * (j + .5), ids[f"t{i:02d}_{j:02d}"]) for j in range(H) for i in range(W)]
    items += [border_part("RugBorder", 0, z, 2 * -X0 + 24, False) for z in (Z0 - 6, -Z0 + 6)]
    items += [border_part("RugBorder", x, 0, 2 * -Z0, True) for x in (X0 - 6, -X0 + 6)]
    xml = ('<roblox version="4"><Item class="Model"><Properties><string name="Name">CityRug</string></Properties>'
           + "".join(items) + "</Item></roblox>")
    (ROOT / "assets/models/city-rug.rbxmx").write_text(xml)
    print("wrote assets/models/city-rug.rbxmx with", len(items), "parts")


def fill_plan(img, toys, s):
    """The preview with every planned 3D toy marked: trees as canopies, cars as blocks, other toys as labelled tags."""
    img = img.copy(); d = ImageDraw.Draw(img)
    P = lambda x, z: ((x - X0) * s, (z - Z0) * s)
    font = ImageFont.truetype("arialbd.ttf", 18)
    for t in toys:
        x, z = P(t["x"], t["z"])
        if t["kind"] in ("tree", "pine"):
            r = t.get("r", 8) * s
            d.ellipse([x - r, z - r, x + r, z + r], fill=(46, 100, 60) if t["kind"] == "pine" else (60, 120, 56), outline=(30, 70, 40), width=2)
        elif t["kind"] == "car":
            a = t.get("angle", 0)
            d.polygon([(x + math.cos(a) * u * s - math.sin(a) * v * s, z + math.sin(a) * u * s + math.cos(a) * v * s)
                       for u, v in ((-7, -3.5), (7, -3.5), (7, 3.5), (-7, 3.5))], fill=(214, 70, 60))
        else:
            d.rounded_rectangle([x - 9, z - 9, x + 9, z + 9], 4, fill=(250, 200, 60), outline=(60, 50, 40), width=2)
            d.text((x + 12, z), t["kind"].replace("_", " "), fill=(30, 30, 30), font=font, anchor="lm", stroke_width=3, stroke_fill=(255, 255, 255))
    return img


def plan_fill(img, town, s):
    """Model annotations for review only (buildings, fans, monorail, toys); the printable preview and tiles never have them."""
    img = img.copy()
    p = Pen(img, *town.bounds[:2], s)
    p.line(list(shp(town.plan["monorail"]["line"]).coords), 2, C["purple"])
    for name, fp, b in town.buildings:
        p.area(fp.boundary.buffer(.6), C["orange"] if b["gate"] else C["ink"])
        p.circle(*b["centre"], 9, C["cream"], C["ink"], .6)
        p.text(*b["centre"], str(b["number"]), 9, C["ink"])
    p.area(town.legs, C["yellow"]); p.text(0, 0, "1", 12, C["ink"])
    for x, z in town.fans:
        p.rect(x - 85, z - 85, x + 85, z + 85, outline=C["teal"], w=2); p.text(x, z, "FAN", 12, C["ink"])
    for t in town.toys:
        x, z, kind = t["x"], t["z"], t["kind"]
        if kind in ("tree", "pine"): p.circle(x, z, 3, C["pine"], C["cream"], .6)     # a spot marker, not a printed tree
        elif kind == "car": p.poly(box(x, z, 7, 14, t["angle"]), C["red"], C["ink"], .5)
        elif kind == "lamp": p.circle(x, z, 2, C["yellow"], C["ink"], .4)
        elif kind == "monorail-pylon": p.circle(x, z, 3.5, C["purple"], C["cream"], .6)
        else: p.rect(x - 5, z - 5, x + 5, z + 5, C["yellow"], 2, C["ink"], .6); p.text(x, z - 11, kind.replace("_", " ").upper(), 6, C["ink"])
    return img


def plan_main(args):
    town = build_plan(json.loads(args.plan.read_text(encoding="utf-8")))
    if not town.check(): raise SystemExit(1)
    if town.bounds != (X0, Z0, -X0, -Z0) or (town.width, town.height) != (W, H):
        raise SystemExit("Expected today's rug: 2000 x 1400, covered by 20 x 14 tiles")
    x0, z0, x1, z1 = town.bounds
    s = 2
    img = Image.new("RGB", (int(x1 - x0) * s, int(z1 - z0) * s))
    town.render(Pen(img, x0, z0, s))
    img.resize((int(x1 - x0), int(z1 - z0)), Image.Resampling.LANCZOS).save(RUG / "preview-v4.png")
    plan_fill(img, town, s).resize((int(x1 - x0), int(z1 - z0)), Image.Resampling.LANCZOS).save(RUG / "fill-plan-v4.png")
    (RUG / "toy-spots-v4.json").write_text(json.dumps(town.toys, indent=1) + "\n", encoding="utf-8")
    print("Saved preview-v4.png, fill-plan-v4.png and toy-spots-v4.json")
    if args.tiles:
        tiles = RUG / "tiles-v4"
        tiles.mkdir(exist_ok=True)
        for j in range(town.height):
            for i in range(town.width):
                name = f"v4_t{i:02d}_{j:02d}"
                if args.only and name not in args.only: continue
                draw_tile(town, i, j).save(tiles / f"{name}.png", optimize=True)
            print("v4 tile row", j, "drawn", flush=True)
    if args.upload or args.build:                           # Alan runs the uploads; records in uploads/, never re-uploaded
        upload_carpet()
        names = [f"v4_t{i:02d}_{j:02d}" for j in range(H) for i in range(W)]
        ids = upload(names, RUG / "tiles-v4")
        if args.build:                                      # its own file: it goes in with the new town, not before
            items = [tile_part(f"Rug{i}_{j}", X0 + TILE * (i + .5), Z0 + TILE * (j + .5), ids[f"v4_t{i:02d}_{j:02d}"])
                     for j in range(H) for i in range(W)] + binding_parts()
            (ROOT / "assets/models/city-rug-v4.rbxmx").write_text('<roblox version="4"><Item class="Model"><Properties>'
                '<string name="Name">CityRug</string></Properties>' + "".join(items) + "</Item></roblox>")
            print("wrote assets/models/city-rug-v4.rbxmx with", len(items), "parts")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--plan", type=Path)
    parser.add_argument("--tiles", action="store_true")
    parser.add_argument("--upload", action="store_true")
    parser.add_argument("--build", action="store_true")
    parser.add_argument("--only", action="append", default=[])
    args = parser.parse_args()
    if args.plan:
        plan_main(args)
        return
    town = build_town()
    ok = check(town)
    print(len(town.structures), "structures on the rug,", len(town.junctions), "junctions,", len(town.ops), "drawing steps,",
          "plan OK" if ok else "PLAN HAS CLASHES")
    if not ok: sys.exit(1)
    (RUG / "toy-spots.json").write_text(json.dumps(town.toys, indent=0))
    print(len(town.toys), "spots saved for 3D toys")
    s = 2
    img = Image.new("RGB", (-2 * X0 * s, -2 * Z0 * s))
    town.render(Pen(img, X0, Z0, s))
    img.resize((-2 * X0, -2 * Z0), Image.LANCZOS).save(RUG / "preview.png")
    fill_plan(img, town.toys, s).resize((-2 * X0, -2 * Z0), Image.LANCZOS).save(RUG / "fill-plan.png")
    if any(a in sys.argv for a in ("--tiles", "--upload", "--build")):
        tiles = RUG / "tiles"; tiles.mkdir(exist_ok=True)
        only = [a.split("=")[1] for a in sys.argv if a.startswith("--only=")]
        for j in range(H):
            for i in range(W):
                name = f"t{i:02d}_{j:02d}"
                if only and name not in only: continue
                draw_tile(town, i, j).save(tiles / f"{name}.png", optimize=True)
            print("row", j, "drawn", flush=True)
    if "--upload" in sys.argv or "--build" in sys.argv:
        ids = upload([f"t{i:02d}_{j:02d}" for j in range(H) for i in range(W)])
        if "--build" in sys.argv: build(ids)


if __name__ == "__main__":
    main()
