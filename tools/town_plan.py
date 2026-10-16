"""Plans the town on layout D (Alan 2026-10-15, docs/decisions/2026-10-15-town-replan-v3.md): Manhattan-style long
blocks with a diagonal Broadway through the bell tower's crossing, a river across the south with a riverside drive,
a small park in the north-west, the two fans in round plazas at the ends of the main boulevard (which swings round
them in a U), a monorail LOOP (above the river, up the ring road at the east and west edges, back above an avenue) through two stations.
Places the 46 buildings once each (real sizes from each model's parts.json), five gates over streets/the river, a
parking lot per block with a driveway to the road (no footpaths: Alan 2026-10-16), ruler bridges roof to roof, and
checks every fly-through hole keeps an open approach.

  python tools/town_plan.py              -> assets/rug/replan-v4-preview.png, replan-v4.md (list), replan-v4.json
Broadway skips the two blocks next to the bell tower so no road meets its legs (Alan 2026-10-16, "version 2").
                                            (everything the rug and the placement step need)
"""
import json, math, random
from pathlib import Path
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.path import Path as MPath
from matplotlib.patches import PathPatch, Rectangle
from shapely.geometry import LineString, MultiLineString, Point, Polygon, box, mapping
from shapely.ops import unary_union, nearest_points, polylabel
from shapely import affinity, prepare

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/rug"
W = json.loads((ROOT / "config/gameplay.json").read_text(encoding="utf-8"))["world"]
rows = json.loads((ROOT / "assets/rug/toy-placements.json").read_text())

RUG = box(-1000, -700, 1000, 700)             # today's rug size (Alan: the wider v3 rug made the town sparse)
ST, AV, BV, WALK, SETBACK, GAP = 20, 26, 30, 7, 6, 20
MESHY = 35

# ---- streets (studs; north is -z). Half widths: street 20, avenue 26, boulevard 30.
rz = lambda x: 300 + 150 * math.exp(-(x / 650) ** 2)            # river centre line
river_line = LineString([(x, rz(x)) for x in range(-1100, 1101, 50)])
RIVER = river_line.buffer(55).intersection(RUG)
FAN_R, FANS = 130, [("west fan", -600, 0), ("east fan", 600, 0)]
R_U = FAN_R + BV + WALK + 8


def u_round(cx):        # the boulevard swings south round a fan plaza
    return [(cx + R_U * math.cos(t), R_U * math.sin(t)) for t in [math.pi - i * math.pi / 24 for i in range(25)]]


bk = 640 / 950
broadway = MultiLineString([[(-950, -640), (-400, -400 * bk)], [(400, 400 * bk), (950, 640)]])
BELL_YAW = 0
LEGS = affinity.rotate(unary_union([box(x, z, x + 40, z + 40) for x in (-105, 65) for z in (-105, 65)]), BELL_YAW,
                       origin=(0, 0))
ROADS = [(LineString([(-950, -640), (950, -640), (950, 640), (-950, 640), (-950, -640)]), ST, "ring road"),
         (LineString([(-950, -320), (950, -320)]), AV, "monorail avenue"),
         (LineString([(-950, 0)] + u_round(-600) + u_round(600) + [(950, 0)]), BV, "main boulevard"),
         (broadway, AV, "Broadway"),
         (river_line.offset_curve(-(55 + ST + WALK)).intersection(box(-950, -700, 950, 700)), ST, "riverside drive")] + \
        [(LineString([(x, -640), (x, 640)]), BV if x == 0 else ST, f"street x={x}") for x in (-400, 0, 400)]
ROAD = unary_union([g.buffer(w, cap_style="flat", join_style="mitre") for g, w, _ in ROADS]).intersection(RUG)
CENTRES = unary_union([g for g, _, _ in ROADS])
assert not ROAD.intersects(LEGS), "a road runs into a bell tower leg"
# Central Park: only the big piece north-east of Broadway (Alan 2026-10-16: the sliver across the road is town again)
PARK = max(box(-800 + ST, -640 + ST, -400 - ST, -320 - AV).difference(ROAD.buffer(WALK)).geoms, key=lambda g: g.area)
_pc = polylabel(PARK, 1)                                      # the middle of the park, as far from its edges as can be
_pr = .55 * PARK.exterior.distance(_pc)
POND = Polygon([(_pc.x + _pr * (1 + .16 * math.sin(2 * t + .7) + .09 * math.sin(3 * t + 2.1)) * math.cos(t) * 1.25,
                 _pc.y + _pr * (1 + .16 * math.sin(2 * t + .7) + .09 * math.sin(3 * t + 2.1)) * math.sin(t) * .85)
                for t in [i * math.pi / 36 for i in range(72)]])   # a natural, lumpy pond, longer than it is wide
assert POND.buffer(10).within(PARK)
ROAD_BRIDGES = unary_union([p for p in ROAD.buffer(WALK).intersection(RIVER).geoms if p.area > 100])          # every street crossing the river does it on a bridge
k = 640 / 950
PLAZAS = [Point(0, 0).buffer(150)] + [Point(x, z).buffer(FAN_R) for _, x, z in FANS] + \
         [Point(z / k, z).buffer(70) for z in (-320,)]       # bell square, fan plazas, Broadway corners
ERASER_PARK = Point(-215, 225).buffer(90)                    # fountain park with the chalk eraser (easter egg)
CLEAR = [Point(1060, -100).buffer(130), ERASER_PARK] + \
        [box(x - 120, -185, x + 120, 185) for x in W["neutral_desk_x_positions"]]   # duct vent, eraser park, side desks
LOW = unary_union([box(x - 85, 405, x + 85, 700) for x in W["desk_x_positions"]] +
                  [box(x - 85, -700, x + 85, -405) for x in W["desk_x_positions"]])   # desk landing paths: low only
LOW_H = 80

# ---- monorail loop (Alan 2026-10-16): above the river, up the ring road's OUTER pavement at the east and west edges (no
# buildings out there), back along the MIDDLE of the monorail avenue, straight through both stations' track tunnels.
# Corners are arcs (the train can't turn square) that stay over the junctions, never cutting into a block.
MX = 950 + ST + WALK / 2
MONO_CORNER = 100
MONO = LineString(Polygon([(-MX + 2 * MX * i / 38, rz(-MX + 2 * MX * i / 38)) for i in range(39)] + [(MX, -320), (-MX, -320)])
                  .buffer(-MONO_CORNER, quad_segs=15).buffer(MONO_CORNER, quad_segs=15).exterior.simplify(.3))
MONO_TOP = 125

# ---- buildings. Real sizes from parts.json; NEW: maker, fly-through (kind, floor, top, width), look.
NEW = {
    "porthole-book-tower": ("M", ("hole", 150, 215, 55), "book stack, round porthole straight through"),
    "tissue-box-tower": ("M", None, "three big tissue boxes, a tissue on top"),
    "tape-roll-tower": ("M", ("hole", 190, 250, 50), "cardboard tower topped by a tape roll you fly through"),
    "juice-carton-tower": ("M", None, "three big juice cartons, a bendy straw"),
    "cereal-box-tower": ("M", None, "plain cardboard cereal box, open flaps"),
    "paint-jar-tower": ("M", None, "three big poster-paint tubs, drips"),
    "egg-carton-market": ("M", None, "egg-carton market hall"),
    "pencil-case-bridge": ("M", None, "Pencil-Case Bridge (gate)"),
    "sticky-note-tower": ("B", None, "stacked sticky-note pads"),
    "pencil-pillar-tower": ("B", None, "boxes held by pencil columns"),
    "ring-binder-tower": ("B", ("crown", 245, 295, 45), "one big binder, metal rings on the roof to fly through"),
    "jenga-tower": ("B", None, "wooden block tower"),
    "stacking-cup-tower": ("B", None, "big toy stacking cups"),
    "log-cabin-tower": ("B", None, "toy-log cabin tower"),
    "ruler-stilt-tower": ("B", ("hole", 70, 120, 40), "box rooms on ruler stilts, open middle to fly through"),
    "pencil-tin-tower": ("B", None, "one big pencil tin, lid as a canopy"),
    "abacus-hall": ("B", ("slot", 10, 60, 30), "two houses joined by an abacus; fly between the rods"),
    "chalk-box-depot": ("B", None, "box of chalk, chalk columns"),
    "shoebox-hall": ("B", None, "shoebox, lid propped as an awning"),
    "block-arch": ("B", None, "wooden block arch (gate)"),
    "monorail-station-north": ("B", None, "cardboard station, monorail through its top floor (gate)"),
    "monorail-station-south": ("B", None, "lunch-tin station on toy-brick legs (gate)"),
}
FALLBACK = {"egg-carton-market": (120, 70, 55)}                 # not baked yet: the plan's size
SIZES = {}
for parts in sorted((ROOT / "assets/models").glob("*/parts.json")):
    name = parts.parent.name
    if name == "bell-tower": continue
    if name not in NEW and not any(r["toy"].startswith(name + "/") for r in rows): continue
    p = json.loads(parts.read_text())["pieces"]
    xs = [v for q in p for v in (q["bounding_box"]["min"][0], q["bounding_box"]["max"][0])]
    ys = [v for q in p for v in (q["bounding_box"]["min"][1], q["bounding_box"]["max"][1])]
    SIZES[name] = (max(xs) - min(xs), max(ys) - min(ys), max(q["bounding_box"]["max"][2] for q in p))
SIZES.update({n: s for n, s in FALLBACK.items() if n not in SIZES})

# gates: (name, x, z, the way you fly through it = the street's direction in degrees, opening height)
GATES = [("monorail-station-north", 200, -320, 0, 80), ("monorail-station-south", 0, rz(0), 90, 80),
         ("block-arch", 400, -480, 90, 86), ("pencil-case-bridge", -400, 160, 90, 95), ("gateway-towers", 0, 230, 90, 136)]


def rect(cx, cz, w, d, yaw):
    """A building's footprint: width w along its front, depth d; yaw turns its front (model -y) to (sin, -cos)."""
    return affinity.rotate(box(cx - w / 2, cz - d / 2, cx + w / 2, cz + d / 2), yaw, origin=(cx, cz))


placed = []          # dicts: name, poly, yaw, h, scale, gate
for name, x, z, through, top in GATES:
    w, d, h = SIZES[name]
    yaw = through - 90         # the model's depth axis (front to back) runs along the street
    placed.append(dict(name=name, poly=rect(x, z, w, d, yaw), yaw=yaw, h=h, scale=1, gate=True, x=x, z=z, top=top))

# ---- blocks: what's left between streets, river, park, plazas and clear zones after the walk and the setback
BLOCKS = RUG.difference(ROAD.buffer(WALK + SETBACK)).difference(RIVER.buffer(SETBACK)).difference(PARK.buffer(SETBACK))
BLOCKS = BLOCKS.difference(unary_union(PLAZAS + CLEAR).buffer(SETBACK))
blocks = sorted([b for b in getattr(BLOCKS, "geoms", [BLOCKS]) if b.area > 5000 and
                 b.area > .3 * b.minimum_rotated_rectangle.area], key=lambda b: b.centroid.distance(Point(0, 0)))
for b in blocks: prepare(b)

APPROACH = 200
lanes = []


def target(r): return max(55, 345 - .36 * r)


def band(p):
    r = p.centroid.distance(Point(0, 0))
    return "downtown" if r < 400 else "midtown" if r < 700 else "outer"


def lane_of(name, poly, yaw):
    kind, bot, top, hw = NEW[name][1]
    c = poly.centroid; fx, fz = math.sin(math.radians(yaw)), -math.cos(math.radians(yaw))
    L = max(SIZES[name][:2]) / 2 + APPROACH
    return LineString([(c.x - fx * L, c.y - fz * L), (c.x + fx * L, c.y + fz * L)]).buffer(hw / 2, cap_style="flat"), bot, top


def near(o, cx, cz, rad):          # cheap test before the exact gap check
    return math.hypot(o["x"] - cx, o["z"] - cz) < rad + o["rad"] + GAP


# every 8 studs along every block edge: a front spot, facing out of the block (over the street, river or plaza)
fronts = []
for i, b in enumerate(blocks):
    ring_ = b.exterior
    for t in range(0, int(ring_.length), 8):
        p, a, c = ring_.interpolate(t), ring_.interpolate(t - 4), ring_.interpolate(t + 4)
        tx, tz = c.x - a.x, c.y - a.y; n = math.hypot(tx, tz) or 1
        nx, nz = -tz / n, tx / n
        if b.contains(Point(p.x + nx * 3, p.y + nz * 3)): nx, nz = -nx, -nz
        fronts.append((i, p.x, p.y, nx, nz))

# ---- buildings, hardest (biggest footprint) first. Each tries every front spot, front parallel to the edge or turned
# 90 degrees, and takes the free spot whose distance from the bell tower best fits the town's height curve (345 at the
# centre stepping down to ~55 at the edge), snug against its neighbours so the block's space isn't wasted.
for o in placed: o["rad"] = math.hypot(*SIZES[o["name"]][:2]) / 2; o["blk"] = None


def room_for(name):     # how many spots it could take in an empty town: the fussiest buildings choose first
    w, d, h = SIZES[name]; k = 0
    for i, fx_, fz_, nx, nz in fronts[::3]:
        yaw = math.degrees(math.atan2(nx, -nz))
        for deep, yy in ((d, yaw), (w, yaw + 90)):
            poly = rect(fx_ - nx * (deep / 2 + .5), fz_ - nz * (deep / 2 + .5), w, d, yy)
            k += blocks[i].contains(poly.buffer(-.5)) and not (h > LOW_H and poly.intersects(LOW)) and                 all(poly.distance(o["poly"]) >= GAP for o in placed)
    return k


rooms = {n: room_for(n) for n in SIZES if n not in {g[0] for g in GATES}}
order = sorted(rooms, key=lambda n: (rooms[n] >= 100, -SIZES[n][2] if rooms[n] >= 100 else rooms[n]))   # then tallest first
print("fussiest first:", [(n, rooms[n]) for n in order[:5]])
GATES_PLACED = list(placed)


def place_all(seed):
    """One greedy pass. A seed > 0 nudges the scores a little so the next pass tries a different packing."""
    rnd = random.Random(seed)
    placed, lanes, unplaced = list(GATES_PLACED), [], []
    for name in order:
        w0, d0, h0 = SIZES[name]
        best = None
        # on the street first, then set back inside the block, then a little closer to its neighbours; only then may
        # one of today's buildings shrink a little
        tries = [(g, inset, 1) for g in (GAP, GAP - 4) for inset in (0, 45, 90, 135)] + \
            ([] if name in NEW else [(GAP - 4, 0, .85), (GAP - 4, 0, .8)])
        for gap, inset, scale in tries:
            w, d, h = w0 * scale, d0 * scale, h0 * scale
            rad = math.hypot(w, d) / 2
            cands = []
            for i, fx_, fz_, nx, nz in fronts:
                yaw = math.degrees(math.atan2(nx, -nz))
                if abs(yaw - 90 * round(yaw / 90)) < 15: yaw = 90 * round(yaw / 90)    # square to the grid on gentle curves
                for deep, yy in ((d, yaw), (w, yaw + 90)):       # front on the street, or turned with its side on it
                    cx, cz = fx_ - nx * (deep / 2 + .5 + inset), fz_ - nz * (deep / 2 + .5 + inset)
                    cands.append((abs(h - target(math.hypot(cx, cz))) + 60 * (1 - scale) + (seed and rnd.random() * 12), i, cx, cz, deep, yy, nx, nz))
            cands.sort(key=lambda c: c[0])
            for fit, i, cx, cz, deep, yy, nx, nz in cands:
                if best and fit >= best[0]: break
                poly = rect(cx, cz, w, d, yy)
                if not blocks[i].contains(poly.buffer(-.5)): continue
                if h > LOW_H and poly.intersects(LOW): continue
                close = [o for o in placed if near(o, cx, cz, rad)]
                dists = [poly.distance(o["poly"]) for o in close]
                if any(x < gap for x in dists): continue
                if any(h > bot and poly.intersects(l) for l, bot, top, _ in lanes): continue
                lane = None
                if name in NEW and NEW[name][1]:
                    l, bot, top = lane_of(name, poly, yy)
                    if any(o["h"] > bot and l.intersects(o["poly"]) for o in placed): continue
                    lane = (l, bot, top, name)
                snug = min([x - gap for o, x in zip(close, dists) if o["blk"] == i] + [60])
                score = fit + snug
                if not best or score < best[0]:
                    best = (score, poly, yy, h, scale, i, lane, (cx + nx * deep / 2, cz + nz * deep / 2), cx, cz, rad)
            if best: break
        if not best: unplaced.append(name); continue
        score, poly, yy, h, scale, i, lane, door, cx, cz, rad = best
        placed.append(dict(name=name, poly=poly, yaw=yy, h=h, scale=scale, gate=False, blk=i, door=door, x=cx, z=cz, rad=rad))
        if lane: lanes.append(lane)
    scaled = sum(o["scale"] != 1 for o in placed)
    curve = sum(abs(o["h"] - target(math.hypot(o["x"], o["z"]))) for o in placed if not o["gate"])
    return len(unplaced), scaled, curve, placed, lanes, unplaced


# ponytail: 8 nudged passes, keep the one with fewest left out, then fewest shrunk, then best height curve
*_, placed, lanes, unplaced = min((place_all(s) for s in range(8)), key=lambda r: r[:3])

# ---- parking lots after the buildings: one per block that has buildings, in the space they left, on the street edge
# (short driveway) and as near the block's buildings as possible
LOT_SIZES = [(140, 60), (120, 56), (110, 60), (100, 50), (90, 50), (80, 50), (60, 40)]   # mixed, some wide
lot_rng = random.Random(3)
lots, drives = [], []
lot_of_blk = {}
for i, b in enumerate(blocks):
    mine = [o for o in placed if o["blk"] == i]
    if not mine: continue
    room = b.difference(unary_union([o["poly"].buffer(10) for o in placed]))
    mx, mz = sum(o["x"] for o in mine) / len(mine), sum(o["z"] for o in mine) / len(mine)
    best = None
    for lw, ld in LOT_SIZES[lot_rng.randrange(4):]:          # each block aims for its own size, then smaller
        for j, fx_, fz_, nx, nz in fronts:
            if j != i: continue
            yaw = math.degrees(math.atan2(nx, -nz))
            if abs(yaw - 90 * round(yaw / 90)) > 20: continue           # lots sit square to the street grid
            yaw = 90 * round(yaw / 90)
            for deep, yy in ((ld, yaw), (lw, yaw + 90)):
                cx, cz = fx_ - nx * (deep / 2 + .5), fz_ - nz * (deep / 2 + .5)
                cost = math.hypot(cx - mx, cz - mz)
                if best and cost >= best[0]: continue
                lot = rect(cx, cz, lw, ld, yy)
                if not room.contains(lot): continue
                road_pt = nearest_points(Point(fx_, fz_), CENTRES)[1]
                drive = LineString([lot.centroid, road_pt])
                if drive.intersects(RIVER) or any(drive.intersects(o["poly"]) for o in placed): continue
                best = (cost, lot, drive)
        if best: break
    if best:
        lots.append(best[1]); drives.append((best[2], b)); lot_of_blk[i] = best[1]

# ---- toy sites with their own ground (Alan 2026-10-16): each on a street front in its own block, square to the grid,
# clear of buildings, lots and driveways, spread apart. (name, width along the street, depth, tallest toy on it)
SITES = [("building site", 100, 80, 80),   # crane at most 80 tall: free ground is all desk-landing zone
          ("fire station", 70, 56, 40), ("petrol station", 80, 56, 30)]
sites = []
taken = unary_union([o["poly"].buffer(12) for o in placed] + [l.buffer(8) for l in lots] + [d.buffer(8) for d, _ in drives])
for name, sw, sd, sh in SITES:
    best = None
    for i, fx_, fz_, nx, nz in fronts:
        if any(st["blk"] == i for st in sites): continue
        yaw = math.degrees(math.atan2(nx, -nz))
        if abs(yaw - 90 * round(yaw / 90)) > 20: continue
        yaw = 90 * round(yaw / 90)
        for inset in (0, 40):
            cx, cz = fx_ - nx * (sd / 2 + .5 + inset), fz_ - nz * (sd / 2 + .5 + inset)
            spread = min([Point(cx, cz).distance(st["poly"]) for st in sites] + [700])
            score = -spread + abs(math.hypot(cx, cz) - 550) * .3 + inset
            if best and score >= best[0]: continue
            poly = rect(cx, cz, sw, sd, yaw)
            if not blocks[i].contains(poly) or poly.intersects(taken): continue
            if sh > LOW_H and poly.intersects(LOW): continue
            if any(sh > bot and poly.intersects(l) for l, bot, top, _ in lanes): continue
            best = (score, dict(name=name, poly=poly, yaw=yaw, blk=i, front=(nx, nz)))
    assert best, f"no room for the {name}"
    sites.append(best[1]); taken = taken.union(best[1]["poly"].buffer(12))
print("toy sites:", [(st["name"], round(st["poly"].centroid.x), round(st["poly"].centroid.y)) for st in sites])

# ---- ruler bridges roof to roof (tall neighbours, similar heights, nothing taller in between)
NO_BRIDGE = {"ring-binder-tower", "pencil-pillar-tower", "clock-tower", "book-stack-spire", "sharpener-tower",
             "crayon-box-tower", "tape-roll-tower", "glue-tower", "stacking-cup-tower", "tissue-box-tower"}
NO_SPAN = unary_union([ROAD.buffer(WALK), RIVER, MONO.buffer(15)])
cands = []
tall = [o for o in placed if not o["gate"] and o["h"] >= 120 and o["name"] not in NO_BRIDGE]
for i, a in enumerate(tall):
    for b in tall[i + 1:]:
        if abs(a["h"] - b["h"]) > 80: continue
        pa, pb = nearest_points(a["poly"], b["poly"]); span = LineString([pa, pb])
        if not 40 <= span.length <= 240: continue
        deck = min(a["h"], b["h"]); strip = span.buffer(15, cap_style="flat")
        if any(o["h"] > deck - 10 and strip.intersects(o["poly"]) for o in placed if o is not a and o is not b): continue
        if strip.intersects(NO_SPAN): continue           # never over roads, the monorail or water (Alan 2026-10-15)
        if any(strip.intersects(l) and bot - 10 < deck < top + 30 for l, bot, top, _ in lanes): continue
        cands.append((0, span.length, a["name"], b["name"], span, deck))
cands.sort(key=lambda c: c[:2])
bridges, count = [], {}
for _, _, a, b, span, deck in cands:
    if count.get(a, 0) >= 2 or count.get(b, 0) >= 2 or len(bridges) >= 10: continue
    if any(span.buffer(25).intersects(s) for _, _, s, _ in bridges): continue
    bridges.append((a, b, span, deck)); count[a] = count.get(a, 0) + 1; count[b] = count.get(b, 0) + 1

# ---- monorail clearance (Alan 2026-10-16): the train (11.4 wide, its floor 4.5 under the track top) never touches a
# building; only buildings low enough to pass under may sit beneath it. Each station's track tunnel (62 wide, 100-142
# up) must carry the line straight down its middle: north's runs front to back, south's (to be rebuilt) end to end.
TRAIN_HALF, MONO_CLEARANCE, TUNNEL_HALF = 5.7, 6, 31
UNDER = MONO_TOP - 4.5 - MONO_CLEARANCE
TUNNEL = {"monorail-station-north": "depth", "monorail-station-south": "width"}
for o in placed:
    gap = o["poly"].distance(MONO)
    if o["name"] in TUNNEL:
        yaw = math.radians(o["yaw"]); depth = (math.sin(yaw), -math.cos(yaw)); axis = depth if TUNNEL[o["name"]] == "depth" else (-depth[1], depth[0])
        c, L = o["poly"].centroid, max(SIZES[o["name"]][:2])
        tunnel = LineString([(c.x - axis[0] * L, c.y - axis[1] * L), (c.x + axis[0] * L, c.y + axis[1] * L)])
        inside = MONO.intersection(o["poly"])
        off = max(tunnel.distance(Point(q)) for g in getattr(inside, "geoms", [inside]) for q in g.coords)
        assert off <= TUNNEL_HALF - TRAIN_HALF - 2, (o["name"], "monorail misses its track tunnel by", round(off, 1))
    elif o["h"] > UNDER:
        assert gap >= TRAIN_HALF + MONO_CLEARANCE, (o["name"], "monorail train too close:", round(gap, 1))

# ---- monorail pylons every ~100 studs, evenly round the loop
pylons = [MONO.interpolate(MONO.length * i / round(MONO.length / 100)) for i in range(round(MONO.length / 100))]

# ---- report
names = [o["name"] for o in placed]
missing = sorted(set(SIZES) - set(names))
print(len(placed) + 1, "buildings (incl. bell tower);", len(lots), "parking lots; missing:", missing)
print("fly-throughs:", [l[3] for l in lanes], "| bridges:", [(a, b, round(d)) for a, b, _, d in bridges])

# ---- the list
num = {"bell-tower": 1}
for o in sorted(placed, key=lambda o: (not o["gate"], -o["h"])): num[o["name"]] = len(num) + 1
md = ["# Town plan v4 (layout D): every building (written by tools/town_plan.py)", "",
      f"{len(num)} buildings, {len(lots)} parking lots, {len(bridges)} ruler bridges, monorail loop "
      f"{MONO.length:.0f} studs with {len(pylons)} pylons. Missing: {', '.join(missing) or 'none'}.", "",
      "| # | Building | Height | Where | Made by | Note |", "|---|---|---|---|---|---|",
      "| 1 | bell-tower | 430 | centre, over the crossing | have it | roads run under it |"]
for o in sorted(placed, key=lambda o: num[o["name"]]):
    mk = NEW.get(o["name"], ("have",))[0]
    note = NEW[o["name"]][2] if o["name"] in NEW else ("today's building" + (f", scaled {o['scale']}" if o["scale"] != 1 else ""))
    md.append(f"| {num[o['name']]} | {o['name']} | {round(o['h'])} | {'gate' if o['gate'] else band(o['poly'])} | "
              f"{ {'M': 'Meshy', 'B': 'Blender'}.get(mk, 'have it') } | {note} |")
(OUT / "replan-v4.md").write_text("\n".join(md) + "\n", encoding="utf-8")

# ---- data for the rug and the placement step
geo = lambda g: mapping(g)
(OUT / "replan-v4.json").write_text(json.dumps({
    "rug": RUG.bounds, "walk": WALK, "setback": SETBACK,
    "roads": [{"name": n, "half_width": w, "line": geo(g)} for g, w, n in ROADS],
    "river": geo(RIVER), "park": geo(PARK), "pond": geo(POND), "road_bridges": geo(ROAD_BRIDGES), "plazas": [geo(p) for p in PLAZAS], "clear": [geo(c) for c in CLEAR], "eraser_park": geo(ERASER_PARK),
    "low": geo(LOW), "fans": [{"name": n, "x": x, "z": z, "radius": FAN_R} for n, x, z in FANS],
    "bell_tower": {"x": 0, "z": 0, "size": 210, "height": 430, "yaw": BELL_YAW, "legs": geo(LEGS)},
    "buildings": [{"name": o["name"], "number": num[o["name"]], "footprint": geo(o["poly"]), "yaw": round(o["yaw"], 2),
                   "height": round(o["h"], 1), "scale": o["scale"], "gate": o["gate"],
                   "centre": [round(o["poly"].centroid.x, 1), round(o["poly"].centroid.y, 1)]} for o in placed],
    "lots": [geo(l) for l in lots], "driveways": [geo(d) for d, _ in drives],
    "sites": [{"name": st["name"], "footprint": geo(st["poly"]), "yaw": st["yaw"], "front": st["front"]} for st in sites],
    "bridges": [{"a": a, "b": b, "line": geo(s), "deck": d} for a, b, s, d in bridges],
    "monorail": {"line": geo(MONO), "track_top": MONO_TOP, "pylons": [[round(p.x, 1), round(p.y, 1)] for p in pylons]},
}, indent=1), encoding="utf-8")
# the moving train's track for the game (src/generated/MonorailTrack.luau via tools/generate_config.py)
(ROOT / "config/monorail-track.json").write_bytes((json.dumps({
    "_comment": "Written by tools/town_plan.py from the town plan; do not edit. The monorail loop's centre line (x, z) "
                "on the rug and the track's top above the rug (studs). The train runs along it (src/shared/MonorailRules.luau).",
    "track_top": MONO_TOP, "line": [[round(x, 2), round(z, 2)] for x, z in MONO.coords]}, indent=1) + "\n").encode())

# ---- picture
fig, (ax, side) = plt.subplots(1, 2, figsize=(22, 11), gridspec_kw={"width_ratios": [3.2, 1]})


def poly(g, **kw):
    for p in getattr(g, "geoms", [g]):
        if p.is_empty or p.geom_type != "Polygon": continue
        path = MPath.make_compound_path(*[MPath(list(r.coords), closed=True) for r in [p.exterior, *p.interiors]])
        ax.add_patch(PathPatch(path, **({"ec": "none"} | kw)))


ax.add_patch(Rectangle((-1400, -1100), 2800, 2200, fc="#d9b98c"))
dw, dd = W["desk_size"][0], W["desk_size"][2]
for x in W["desk_x_positions"]:
    for z in W["desk_z_positions"]:
        ax.add_patch(Rectangle((x - dw / 2, z - dd / 2), dw, dd, fc="#b07a46", ec="k"))
for x in W["neutral_desk_x_positions"]:
    ax.add_patch(Rectangle((x - 105, -165), 210, 330, fc="#b07a46", ec="k", zorder=9))
poly(RUG, fc="#7d7d84")
poly(RUG.difference(ROAD), fc="#d8d2c4", zorder=2)
poly(RUG.difference(ROAD.buffer(WALK)), fc="#8fbf6a", zorder=3)
poly(PARK, fc="#5f9e47", zorder=4); poly(POND, fc="#5b9bd5", zorder=4)
poly(RIVER, fc="#5b9bd5", zorder=4)
poly(ROAD_BRIDGES, fc="#d8d2c4", ec="#6b4f2a", lw=1.2, zorder=5); poly(ROAD.intersection(RIVER), fc="#7d7d84", zorder=5)
for p in PLAZAS: poly(p.difference(ROAD.buffer(WALK)), fc="#e3d6bd", zorder=4)
poly(ERASER_PARK, fc="#5f9e47", zorder=4); poly(Point(-215, 225).buffer(22), fc="#5b9bd5", zorder=5)
ax.add_patch(Rectangle((-205, 255), 50, 22, angle=-20, fc="#2b2b2b", ec="#f0f0f0", lw=1, zorder=9))
ax.text(-215, 300, "ERASER", fontsize=6.5, ha="center", va="center", weight="bold", color="w", zorder=12)
poly(LOW, fc="none", ec="#2e7d32", ls=":", lw=1.2, zorder=5)
for l in lots: poly(l, fc="#55555c", ec="w", lw=.6, zorder=6)
for d, _ in drives: ax.plot(*d.xy, color="#55555c", lw=4, zorder=6)
for st in sites:
    poly(st["poly"], fc="#c9a46a", ec="#7a4b1e", lw=1.2, zorder=6)
    ax.text(st["poly"].centroid.x, st["poly"].centroid.y, st["name"].upper(), fontsize=5.5, ha="center", va="center", zorder=12)
for l, bot, top, owner in lanes: poly(l, fc="#39c6ff", alpha=.3, zorder=5)
cmap = plt.get_cmap("plasma")
for o in placed:
    poly(o["poly"], fc=cmap(min(1, o["h"] / 345)), ec="#00e5ff" if o["name"] in NEW else "k", lw=1.6, zorder=8,
         hatch="//" if o["gate"] else None)
    c = o["poly"].centroid
    ax.text(c.x, c.y, str(num[o["name"]]), fontsize=7, ha="center", va="center", weight="bold", zorder=12,
            color="w", bbox=dict(fc="k", ec="none", pad=.6, alpha=.6))
for a, b, s, d in bridges: ax.plot(*s.xy, color="#f2b632", lw=5, zorder=10, solid_capstyle="butt")
ax.plot(*MONO.xy, color="#6a1b9a", lw=5, zorder=11); ax.plot(*MONO.xy, color="#e1bee7", lw=1.2, ls="--", zorder=11)
for p in pylons: ax.plot(p.x, p.y, "o", ms=3.5, color="#6a1b9a", zorder=11)
for n, x, z in FANS:
    ax.add_patch(Rectangle((x - 85, z - 85), 170, 170, fc="#b3e5fc", ec="#0277bd", lw=2.5, zorder=9))
    ax.text(x, z, "FAN", fontsize=8, ha="center", va="center", color="#01579b", zorder=10, weight="bold")
poly(rect(0, 0, 210, 210, BELL_YAW), fc="none", ec="#b8860b", ls="--", lw=2, zorder=9)
poly(LEGS, fc="#f2c94c", ec="k", zorder=9)
ax.text(0, 0, "1", fontsize=9, ha="center", va="center", weight="bold", zorder=12)
ax.set_xlim(-1420, 1420); ax.set_ylim(1120, -1120); ax.set_aspect("equal"); ax.set_xticks([]); ax.set_yticks([])
ax.set_title(f"Town plan v4 (layout D): {len(num)} buildings, {len(lots)} parking lots. Colour = height; cyan outline = "
             "new; hatched = gate over a street/river; dark grey = parking lots and driveways; blue "
             "strips = fly-through approaches; yellow = ruler bridges; purple = monorail loop and pylons", fontsize=9.5)
side.axis("off")
side.text(0, 1, "\n".join(f"{n:2d} {nm} {round(next((o['h'] for o in placed if o['name'] == nm), 430))}"
                          for nm, n in sorted(num.items(), key=lambda kv: kv[1])), fontsize=8.4, va="top", family="monospace")
fig.savefig(OUT / "replan-v4-preview.png", dpi=72, bbox_inches="tight")
print("wrote replan-v4-preview.png, replan-v4.md, replan-v4.json")
