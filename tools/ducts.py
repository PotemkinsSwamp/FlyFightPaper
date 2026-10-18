"""Builds the escape ducts above the drop ceiling as assets/models/ducts.model.json (Rojo model file).

Reads config/gameplay.json world.ducts. The model holds the ceiling too (with the vent holes cut out), so
classroom.rbxmx has no ceiling of its own. Run: python tools/ducts.py
"""
import json
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
cfg = json.loads((ROOT / "config/gameplay.json").read_text(encoding="utf-8"))["world"]
D = cfg["ducts"]
HALF_X, HALF_Z = cfg["width_studs"] / 2, cfg["depth_studs"] / 2
FLOOR, H, W, R, V, T = D["floor_y"], D["height"], D["width"], D["room"], D["vent"], D["wall"]
ROOMS = {name: tuple(at) for name, at in D["rooms"].items()}
LINKS = [tuple(link) for link in D["links"]]
PIPE = tuple(D["pipe"]["link"])
VENTS = {ROOMS[name] for name in D["vents"]}
# The classroom's ceiling lights (classroom.rbxmx "CeilingLight", 150 x 40): ducts over them glow from below.
LIGHTS = [(x, z) for x in (-750, 0, 750) for z in (-550, 200, 700)]

CEILING = [0.941, 0.910, 0.831]   # the old ceiling slabs' colour
# Galvanised sheet metal, kept dark (no duct part casts shadows, so the dark comes from the colours).
STEEL, DARK, RIB = [0.36, 0.37, 0.39], [0.25, 0.26, 0.28], [0.50, 0.51, 0.53]
CREASE, RIVET, LIGHT_STEEL = [0.43, 0.44, 0.46], [0.62, 0.63, 0.65], [0.62, 0.63, 0.65]
PIPE_STEEL = [0.66, 0.67, 0.70]
GLOW = [1.0, 0.86, 0.62]
TOP, MID = FLOOR + H, FLOOR + H / 2
parts = []


def part(name, size, pos, color=STEEL, material="Metal", solid=True, rot=None, children=None, attributes=None, shape=None):
    rot = rot or [[1, 0, 0], [0, 1, 0], [0, 0, 1]]
    props = {"Size": [round(s, 3) for s in size], "Anchored": True, "Color": color, "Material": material,
             "CFrame": {"CFrame": {"position": [round(p, 3) for p in pos], "orientation": [[round(v, 5) for v in row] for row in rot]}},
             "CanCollide": solid, "CanQuery": solid, "CanTouch": False, "CastShadow": False,   # like the old ceiling
             "TopSurface": "Smooth", "BottomSurface": "Smooth"}
    if shape:
        props["Shape"] = shape
    item = {"name": name, "className": "Part", "properties": props}
    if children:
        item["children"] = children
    if attributes:
        item["attributes"] = attributes
    parts.append(item)


def box(name, x0, x1, y0, y1, z0, z1, **kw):
    if x1 - x0 > 0.01 and z1 - z0 > 0.01 and y1 - y0 > 0.01:
        part(name, [x1 - x0, y1 - y0, z1 - z0], [(x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2], **kw)


def axes(x, z):
    """Rotation whose local X and Z point along unit vectors x and z (rows, as part() wants)."""
    y = [z[1] * x[2] - z[2] * x[1], z[2] * x[0] - z[0] * x[2], z[0] * x[1] - z[1] * x[0]]
    return [[x[i], y[i], z[i]] for i in range(3)]


def mat_mul(a, b):
    return [[sum(a[i][k] * b[k][j] for k in range(3)) for j in range(3)] for i in range(3)]


def apply(m, v):
    return [sum(m[i][k] * v[k] for k in range(3)) for i in range(3)]


def rz(t):
    return [[math.cos(t), -math.sin(t), 0], [math.sin(t), math.cos(t), 0], [0, 0, 1]]


def rx(t):
    return [[1, 0, 0], [0, math.cos(t), -math.sin(t)], [0, math.sin(t), math.cos(t)]]


# CFrame.lookAt(at, at + look), up = +Y, as rotations (columns: right, up, back) -- the same as DuctRules.fanFrame.
LOOK_X = [[0, 0, -1], [0, 1, 0], [1, 0, 0]]
LOOK_Z = [[-1, 0, 0], [0, 1, 0], [0, 0, -1]]


def ring(name, frame, at, radius, count, size, **kw):
    """`count` pieces round a circle in `frame`'s X-Y plane, each with its Y facing the middle."""
    for k in range(count):
        t = k * 2 * math.pi / count
        offset = apply(frame, apply(rz(t), [radius, 0, 0]))
        part(name, [2 * math.pi * radius / count * 1.1, size[0], size[1]], [at[i] + offset[i] for i in range(3)],
             rot=mat_mul(frame, rz(t - math.pi / 2)), **kw)


holes = [(x - V / 2, x + V / 2, z - V / 2, z + V / 2) for x, z in VENTS]


def floor_plate(x0, x1, z0, z1):
    """Metal floor over the ceiling, with any vent hole inside it left open."""
    for hx0, hx1, hz0, hz1 in holes:
        if x0 <= hx0 and hx1 <= x1 and z0 <= hz0 and hz1 <= z1:
            box("DuctFloor", x0, x1, FLOOR, FLOOR + 1, z0, hz0, color=DARK)
            box("DuctFloor", x0, x1, FLOOR, FLOOR + 1, hz1, z1, color=DARK)
            box("DuctFloor", x0, hx0, FLOOR, FLOOR + 1, hz0, hz1, color=DARK)
            box("DuctFloor", hx1, x1, FLOOR, FLOOR + 1, hz0, hz1, color=DARK)
            return
    box("DuctFloor", x0, x1, FLOOR, FLOOR + 1, z0, z1, color=DARK)


def across(along_x, c, lo, hi, y0, y1, a0, a1, **kw):
    """A box in a duct: `a0..a1` along it, `lo..hi` across it from its middle line `c`."""
    name = kw.pop("name")
    if along_x:
        box(name, a0, a1, y0, y1, c + lo, c + hi, **kw)
    else:
        box(name, c + lo, c + hi, y0, y1, a0, a1, **kw)


def plate(along_x, a, c, wide, tall, name, thick=6, color=DARK):
    """A wall across the duct at `a` with a hole `wide` x `tall` in its middle."""
    for lo, hi, y0, y1 in ((-W / 2, -wide / 2, FLOOR, TOP), (wide / 2, W / 2, FLOOR, TOP),
                           (-wide / 2, wide / 2, FLOOR, MID - tall / 2), (-wide / 2, wide / 2, MID + tall / 2, TOP)):
        across(along_x, c, lo, hi, y0, y1, a - thick / 2, a + thick / 2, name=name, color=color)


def link_line(a, b):
    """(along x?, the line's fixed coordinate, start, end) for the duct between two rooms, start < end."""
    (ax, az), (bx, bz) = ROOMS[a], ROOMS[b]
    along_x = az == bz
    assert along_x or ax == bx, f"link {a}-{b} is not straight"
    s0, s1 = sorted((ax, bx) if along_x else (az, bz))
    return along_x, (az if along_x else ax), s0, s1


# Rooms: walls with openings toward their ducts (a round pipe's mouth where the pipe starts), a roof, a floor.
D_PIPE = D["pipe"]["diameter"]
room_sides = {}
for name, (x, z) in ROOMS.items():
    r = R / 2
    sides = room_sides[name] = {}
    for a, b in LINKS:
        if name in (a, b):
            ox, oz = ROOMS[b if name == a else a]
            side = ("+" if (ox > x or oz > z) else "-") + ("x" if oz == z else "z")
            sides[side] = "pipe" if {a, b} == set(PIPE) else "duct"
    for side in ("-x", "+x", "-z", "+z"):
        sign = 1 if side[0] == "+" else -1
        runs_x = side[1] == "z"   # the wall on a z side runs along x
        at = (z if runs_x else x) + sign * (r + T / 2)
        c = z if side[1] == "x" else x
        kind = sides.get(side)
        if kind == "pipe":   # a wall with the pipe's square mouth in the middle of the duct's width
            plate(not runs_x, at, c, D_PIPE, D_PIPE, "DuctWall", thick=T, color=STEEL)
        gaps = [(-r - T, -W / 2), (W / 2, r + T)] if kind else [(-r - T, r + T)]
        for lo, hi in gaps:
            across(not runs_x, c, lo, hi, FLOOR, TOP, at - T / 2, at + T / 2, name="DuctWall")
    box("DuctRoof", x - r - T, x + r + T, TOP, TOP + T, z - r - T, z + r + T)
    floor_plate(x - r, x + r, z - r, z + r)


def light_slots(along_x, c, s0, s1):
    """Where this duct passes over a classroom ceiling light, its glow shows up through a floor grille."""
    for lx, lz in LIGHTS:
        a, cross = (lx, lz) if along_x else (lz, lx)
        half_a = 75 if along_x else 20
        if s0 < a - half_a and a + half_a < s1 and abs(cross - c) < W / 2:
            light = {"name": "Glow", "className": "SurfaceLight",
                     "properties": {"Face": "Top", "Range": 60, "Brightness": 4, "Angle": 100, "Color": GLOW, "Shadows": False}}
            box("LightGrille", lx - 75, lx + 75, FLOOR + 1, FLOOR + 1.3, lz - 20, lz + 20, color=GLOW, material="Neon",
                solid=False, children=[light])
            for k in range(-3, 4):   # dark slats across the glow, like a grille
                box("GrilleSlat", lx + k * 20 - 2, lx + k * 20 + 2, FLOOR + 1, FLOOR + 2, lz - 22, lz + 22, color=DARK, solid=False)


def at3(along_x, a, y, cross):
    """World position `a` along a duct, `cross` from its middle line (the caller adds c)."""
    return [a, y, cross] if along_x else [cross, y, a]


def rivets(along_x, c, at, step=20):
    """A row of rivet heads down each wall band and across the roof band."""
    for y in range(int(FLOOR + 12), int(TOP - 6), step):
        for side in (-1, 1):
            part("Rivet", [1.6, 1.6, 1.6], at3(along_x, at, y, c + side * (W / 2 - 3)), color=RIVET, solid=False, shape="Ball")
    for x in range(int(-W / 2 + 12), int(W / 2 - 6), step):
        part("Rivet", [1.6, 1.6, 1.6], at3(along_x, at, TOP - 3, c + x), color=RIVET, solid=False, shape="Ball")


def xface(centre, u, v, lu, lv, normal):
    """The shallow X pressed into a sheet of a real duct to stiffen it: the sheet is `lu` along u by `lv` along v."""
    if min(lu, lv) < 30:
        return
    d = math.hypot(lu, lv)
    for sign in (-1, 1):
        x = [(u[i] * lu + sign * v[i] * lv) / d for i in range(3)]
        part("DuctCrease", [d, 1.2, 0.6], centre, rot=axes(x, normal), color=CREASE, solid=False)


def creases(along_x, c, a0, a1):
    """An X on each of a duct sheet's walls, roof and floor."""
    along = [1, 0, 0] if along_x else [0, 0, 1]
    side = [0, 0, 1] if along_x else [1, 0, 0]
    mid = (a0 + a1) / 2
    for cross in (c - W / 2 + 0.4, c + W / 2 - 0.4):
        xface(at3(along_x, mid, MID, cross), along, [0, 1, 0], a1 - a0, H, side)
    for y in (TOP - 0.4, FLOOR + 1.3):
        xface(at3(along_x, mid, y, c), along, side, a1 - a0, W, [0, 1, 0])


# Rooms' sheets: an X on each piece of wall beside the duct mouths and on the roof, bands at the corners, mouths and top.
for name, (x, z) in ROOMS.items():
    r = R / 2
    for side, kind in [(sd, room_sides[name].get(sd)) for sd in ("-x", "+x", "-z", "+z")]:
        sign = 1 if side[0] == "+" else -1
        runs_x = side[1] == "z"
        wall = (z if runs_x else x) + sign * (r - 0.4)
        c = x if runs_x else z
        u, normal = ([1, 0, 0], [0, 0, 1]) if runs_x else ([0, 0, 1], [1, 0, 0])
        pieces = [(-r, -W / 2), (W / 2, r)] if kind else [(-r, r)]
        for lo, hi in pieces:
            mid = c + (lo + hi) / 2
            xface([mid, MID, wall] if runs_x else [wall, MID, mid], u, [0, 1, 0], hi - lo, H, normal)
        edges = {-r, r} | ({-W / 2, W / 2} if kind else set())
        for e in edges:   # vertical bands
            lo, hi = sorted((wall, wall - sign * 3))
            if runs_x:
                box("DuctRib", c + e - 3, c + e + 3, FLOOR, TOP, lo, hi, color=RIB, solid=False)
            else:
                box("DuctRib", lo, hi, FLOOR, TOP, c + e - 3, c + e + 3, color=RIB, solid=False)
        lo, hi = sorted((wall, wall - sign * 3))
        if runs_x:
            box("DuctRib", c - r, c + r, TOP - 4, TOP, lo, hi, color=RIB, solid=False)
        else:
            box("DuctRib", lo, hi, TOP - 4, TOP, c - r, c + r, color=RIB, solid=False)
    xface([x, TOP - 0.4, z], [1, 0, 0], [0, 0, 1], R, R, [0, 1, 0])


def pipe(along_x, c, s0, s1):
    """A round pipe `diameter` across the whole way between the two rooms: 16 staves, a flange at each mouth."""
    radius = D_PIPE / 2
    frame = LOOK_X if along_x else LOOK_Z
    middle = [(s0 + s1) / 2, MID, c] if along_x else [c, MID, (s0 + s1) / 2]
    ring("Pipe", frame, middle, radius + 1, 16, (2, s1 - s0), color=PIPE_STEEL)
    for a in (s0 - 2, s1 + 2):
        ring("PipeFlange", frame, [a, MID, c] if along_x else [c, MID, a], radius + 4, 16, (6, 4), color=PIPE_STEEL,
             solid=False)
    for k in range(1, int((s1 - s0) // 60)):   # band clamps round the outside, like hung plumbing
        a = s0 + k * 60
        ring("PipeBand", frame, [a, MID, c] if along_x else [c, MID, a], radius + 2.6, 16, (1.2, 3), color=RIB,
             solid=False)


for a, b in LINKS:
    along_x, c, s0, s1 = link_line(a, b)
    s0, s1 = s0 + R / 2 + T, s1 - R / 2 - T   # between the rooms' walls
    if {a, b} == set(PIPE):
        pipe(along_x, c, s0 - T, s1 + T)   # through the rooms' walls
        continue
    for lo, hi in ((-W / 2 - T, -W / 2), (W / 2, W / 2 + T)):
        across(along_x, c, lo, hi, FLOOR, TOP, s0, s1, name="DuctWall")
    across(along_x, c, -W / 2 - T, W / 2 + T, TOP, TOP + T, s0, s1, name="DuctRoof")
    if along_x:
        floor_plate(s0, s1, c - W / 2, c + W / 2)
    else:
        floor_plate(c - W / 2, c + W / 2, s0, s1)
    joints = [s0 + k * 100 - ((s1 - s0) % 100) / 2 - 50 for k in range(1, int((s1 - s0) // 100) + 1)]
    for at in joints:   # riveted joint bands between the metal sheets (not solid)
        for lo, hi, y0, y1 in ((-W / 2, -W / 2 + 3, FLOOR, TOP), (W / 2 - 3, W / 2, FLOOR, TOP), (-W / 2, W / 2, TOP - 3, TOP),
                               (-W / 2, W / 2, FLOOR + 1, FLOOR + 1.6)):
            across(along_x, c, lo, hi, y0, y1, at - 3, at + 3, name="DuctRib", color=RIB, solid=False)
        rivets(along_x, c, at)
    for a0, a1 in zip([s0] + joints, joints + [s1]):
        creases(along_x, c, a0, a1)
    light_slots(along_x, c, s0, s1)


def fan(frame, at, reach, hub, width, blades, attributes):
    """Blades placed at turn 0 (blade k at k/blades of a turn) in `frame`'s X-Y plane; the client spins them."""
    length = reach - hub - width / 2   # a rounded tip (a disc) makes up the rest of the reach
    for k in range(blades):
        t = k * 2 * math.pi / blades
        rot = mat_mul(mat_mul(frame, rz(t)), rx(0.35))   # a little twist, like a real blade
        offset = apply(frame, apply(rz(t), [hub + length / 2, 0, 0]))
        part("DuctFanBlade", [length, width, 2], [at[i] + offset[i] for i in range(3)], rot=rot, solid=False,
             color=LIGHT_STEEL, attributes=attributes)
        tip = apply(frame, apply(rz(t), [reach - width / 2, 0, 0]))
        part("DuctFanBlade", [2, width, width], [at[i] + tip[i] for i in range(3)], rot=mat_mul(rot, [[0, 0, 1], [0, 1, 0], [-1, 0, 0]]),
             solid=False, color=LIGHT_STEEL, shape="Cylinder", attributes=attributes)
    hub_rot = mat_mul(frame, [[0, 0, 1], [0, 1, 0], [-1, 0, 0]])   # the cylinder's length (its X) along the axis
    part("DuctFanHub", [8, hub * 2, hub * 2], at, rot=hub_rot, solid=False, color=[0.75, 0.16, 0.12],
         material="SmoothPlastic", shape="Cylinder")


def motor(frame, at, back, reach):
    """The fan's motor behind its hub, held by four arms out to a ring past the blades' reach."""
    axis = apply(frame, [0, 0, back])
    hub_rot = mat_mul(frame, [[0, 0, 1], [0, 1, 0], [-1, 0, 0]])
    centre = [at[i] + axis[i] * 18 for i in range(3)]
    part("FanMotor", [26, 22, 22], centre, rot=hub_rot, solid=False, color=DARK, shape="Cylinder")
    part("FanMotor", [4, 26, 26], [centre[i] + axis[i] * 13 for i in range(3)], rot=hub_rot, solid=False, color=RIB, shape="Cylinder")
    for k in range(4):
        t = math.pi / 4 + k * math.pi / 2
        mid = apply(frame, apply(rz(t), [(11 + reach + 6) / 2, 0, 0]))
        part("FanArm", [reach + 6 - 11, 3, 3], [centre[i] + mid[i] for i in range(3)], rot=mat_mul(frame, rz(t)), solid=False, color=RIB)
    ring("FanArm", frame, centre, reach + 6, 24, (3, 3), color=RIB, solid=False)


F = D["fans"]
for i, (x, z, axis, flow) in enumerate(F["spots"], start=1):
    along_x = axis == "x"
    fan(LOOK_X if along_x else LOOK_Z, [x, MID, z], F["reach"], F["hub_radius"], F["blade_width"], F["blades"],
        {"DuctFan": i})
    motor(LOOK_X if along_x else LOOK_Z, [x, MID, z], -flow, F["reach"])   # downstream of the blades
    # a plate across the duct with a round housing, on the side the air comes from (against the air you meet the
    # blades just after it); the housing's thick ring fills the plate's square hole round the blades' circle
    at = (x if along_x else z) - 6 * flow
    hole = F["opening"] / 2
    # The plate fills above and below the blades' circle; the housing ring fills its sides. The ring is thinner
    # toward the top and bottom so it never pokes through the duct floor (the classroom ceiling, Alan 2026-10-18)
    # or roof: each piece's corners stay half a stud inside.
    plate(along_x, at, z if along_x else x, W, hole * 2, "FanPlate")
    frame = LOOK_X if along_x else LOOK_Z
    centre = [at, MID, z] if along_x else [x, MID, at]
    length = 2 * math.pi * (hole + 16) / 24 * 1.1
    for k in range(24):
        t = k * 2 * math.pi / 24
        s, c = abs(math.sin(t)), abs(math.cos(t))
        thick = 32 if s < 1e-6 else min(32, (H / 2 - 0.5 - length / 2 * c) / s - hole)
        offset = apply(frame, apply(rz(t), [hole + thick / 2, 0, 0]))
        part("FanHousing", [length, thick, 10], [centre[i] + offset[i] for i in range(3)],
             rot=mat_mul(frame, rz(t - math.pi / 2)), color=STEEL)

# The blower: a big fan on its room's far wall, facing down its duct (the client spins it).
bl = D["blower"]
bx, bz = ROOMS[bl["room"]]
ox, oz = ROOMS[bl["link"][1] if bl["link"][0] == bl["room"] else bl["link"][0]]
out = (1 if ox > bx else -1, 0) if oz == bz else (0, 1 if oz > bz else -1)
wall = [bx - out[0] * (R / 2 - 14), MID, bz - out[1] * (R / 2 - 14)]
blow = LOOK_X if out[0] else LOOK_Z
fan(blow, wall, 62, 14, 20, 5, {"Blower": True})
ring("BlowerRing", blow, wall, 66, 16, (6, 16), color=DARK, solid=False)

# The drop ceiling, cut round the vent holes. Cells between every edge, joined along x (never across x = 0:
# a part can be at most 2048 long).
xs = sorted({-HALF_X, 0, HALF_X} | {h[0] for h in holes} | {h[1] for h in holes})
zs = sorted({-HALF_Z, HALF_Z} | {h[2] for h in holes} | {h[3] for h in holes})
for z0, z1 in zip(zs, zs[1:]):
    run = None
    for x0, x1 in zip(xs, xs[1:]):
        hole = any(h[0] <= x0 and x1 <= h[1] and h[2] <= z0 and z1 <= h[3] for h in holes)
        if run is not None and (hole or x0 == 0):
            box("Ceiling", run, x0, FLOOR - 8, FLOOR, z0, z1, color=CEILING, material="Plastic")
            run = None
        if not hole and run is None:
            run = x0
    if run is not None:
        box("Ceiling", run, xs[-1], FLOOR - 8, FLOOR, z0, z1, color=CEILING, material="Plastic")

# Vent grilles under the holes: a metal frame on the ceiling and the grille hanging open from one edge (config
# vent_hinge: the side no bot route crosses). Solid: planes fly through the gaps between its bars or clip them.
for name in sorted(D["vents"]):
    x, z = ROOMS[name]
    y, h, b = FLOOR - 8, V / 2, 10
    box("VentFrame", x - h - b, x + h + b, y - 3, y, z - h - b, z - h, color=LIGHT_STEEL)
    box("VentFrame", x - h - b, x + h + b, y - 3, y, z + h, z + h + b, color=LIGHT_STEEL)
    box("VentFrame", x - h - b, x - h, y - 3, y, z - h, z + h, color=LIGHT_STEEL)
    box("VentFrame", x + h, x + h + b, y - 3, y, z - h, z + h, color=LIGHT_STEEL)
    hinge = D["vent_hinge"][name]
    s, on_x = (1 if hinge[0] == "+" else -1), hinge[1] == "x"
    swing = math.radians(70)

    def spot(d, side=0):
        """`d` down the grille from its hinge, `side` along the hinge from the middle."""
        a, y2 = s * (h - d * math.cos(swing)), y - 3 - d * math.sin(swing)
        return [x + a, y2, z + side] if on_x else [x + side, y2, z + a]
    for k in range(9):
        d = (k + 0.5) / 9 * V    # bars 20 apart: 18-stud gaps a plane can fly through
        part("VentGrille", [2, 2, V] if on_x else [V, 2, 2], spot(d), color=LIGHT_STEEL)
    for side in (-1, 1):
        part("VentGrille", [V, 3, 3] if on_x else [3, 3, V], spot(h, side * (h - 1.5)), color=LIGHT_STEEL,
             rot=rz(swing * s) if on_x else rx(-swing * s))

# Things lost up here: free Creator Store meshes (scripts removed; asset ids, never geometry). Not solid.
# kind: (mesh id, texture id, the mesh's own size, longest side in studs, colour)
PROPS = {
    "spider": (2571839300, None, (0.0163, 0.0098, 0.0196), 22, [0.07, 0.07, 0.07]),
    "spiders": (4894846584, 4894847666, (4.044, 1.7559, 1.6094), 48, None),
    "web": (18471600785, 18471609622, (0.9926, 0.9964, 0.0419), 70, None),   # flat, anchored in its -X +Y corner
    "screwdriver": (12292994045, 12293012548, (3.7244, 0.4748, 0.4748), 45, None),
    "wrench": (473315979, 473316678, (3.0471, 12.6212, 0.5725), 45, None),
    "flashlight": (115955313, 115955343, (0.7903, 0.7894, 2.4998), 42, None),
    "duck": (9419831, 9419827, (0.972, 1.0353, 1.4014), 36, None),
    "car": (3215707736, None, (26.5511, 18.9787, 50), 60, None),
}


def prop(kind, pos, rot=None, color=None, children=(), longest=None):
    mesh, texture, native, usual, tint = PROPS[kind]
    s = (longest or usual) / max(native)
    look = {"MeshType": "FileMesh", "MeshId": f"rbxassetid://{mesh}", "Scale": [s, s, s]}
    if texture:
        look["TextureId"] = f"rbxassetid://{texture}"
    part("Prop_" + kind, [n * s for n in native], pos, color=color or tint or [1, 1, 1], material="Plastic",
         solid=False, rot=rot, children=[{"name": "Mesh", "className": "SpecialMesh", "properties": look}, *children])


def ry(t):
    return [[math.cos(t), 0, math.sin(t)], [0, 1, 0], [-math.sin(t), 0, math.cos(t)]]


def on_floor(kind, room, dx, dz, yaw, lay=False, tilt=0, **kw):
    """Lying on a room's floor, `dx, dz` from its middle (the corners past the duct mouths are out of the way)."""
    x, z = ROOMS[room]
    rot = mat_mul(ry(math.radians(yaw)), rx(math.pi / 2) if lay else rx(math.radians(tilt)))
    native, longest = PROPS[kind][2], PROPS[kind][3]
    tall = sum(abs(rot[1][j]) * native[j] * longest / max(native) for j in range(3))
    prop(kind, [x + dx, FLOOR + 1 + tall / 2, z + dz], rot=rot, **kw)


def web(along_x, a, cross, side, size=70):
    """A cobweb across the corner where a wall (at `cross`, on the +1/-1 `side` of the space) meets the roof."""
    yaw = (90 if side > 0 else -90) if along_x else (180 if side > 0 else 0)
    centre = cross - side * size / 2
    prop("web", at3(along_x, a, TOP - size / 2, centre), rot=ry(math.radians(yaw)), longest=size)


def spider(along_x, a, y, cross, side, turn=0):
    """A plastic spider stuck on a wall (at `cross`, on the `side` of the space), legs flat on it."""
    tilt = (rx(-math.pi / 2 * side) if along_x else rz(math.pi / 2 * side))
    prop("spider", at3(along_x, a, y, cross - side * 4), rot=mat_mul(tilt, ry(turn)))


# Toys and tools dropped in the rooms' corners.
on_floor("car", "C", 88, -84, 35, color=[0.62, 0.1, 0.08])
on_floor("car", "P", -84, 86, 160, color=[0.15, 0.35, 0.8])
on_floor("duck", "K", 86, -90, 210)
on_floor("spiders", "E", -88, -86, 20)
on_floor("wrench", "N", -86, 90, 70, lay=True)
on_floor("screwdriver", "F", 90, 90, 15)
on_floor("screwdriver", "B", -88, 92, 120)
on_floor("duck", "M", -104, 104, 40)
on_floor("wrench", "J", 104, -104, 150, lay=True)
beam = {"name": "Beam", "className": "SpotLight", "properties": {"Face": "Front", "Range": 160, "Brightness": 6, "Angle": 60,
        "Color": [1.0, 0.93, 0.78], "Shadows": False}}
on_floor("flashlight", "G", 86, -82, 125, tilt=-10, children=[beam])   # someone's torch, still on

# Cobwebs in the ducts' upper corners and the rooms', a spider on the wall near most of them.
for i, (a, b) in enumerate(LINKS):
    if {a, b} == set(PIPE) or i % 2:
        continue
    along_x, c, s0, s1 = link_line(a, b)
    s0 += R / 2 + T
    side = 1 if i % 4 == 0 else -1
    web(along_x, s0 + 40, c + side * W / 2, side)
    spider(along_x, s0 + 75, TOP - 50, c + side * W / 2, side, turn=i)
for k, (name, (x, z)) in enumerate(sorted(ROOMS.items())):
    side = 1 if k % 2 else -1
    web(False, z - side * 90, x + side * R / 2, side, size=90)   # on the room's east or west wall, near a corner
    if k % 3 == 0:
        spider(False, z - side * 60, FLOOR + 40, x + side * R / 2, side, turn=k)

# Dust bunnies along the walls, a few lost marbles, a bouncy ball (plain shapes; seeded, so every build is the same).
luck = random.Random(7)
MARBLES = [[0.15, 0.45, 0.9], [0.9, 0.25, 0.2], [0.2, 0.75, 0.35], [0.95, 0.75, 0.15]]


def ball(name, at, size, color, material):
    part(name, [size] * 3, at, color=color, material=material, solid=False, shape="Ball")


for a, b in LINKS:
    if {a, b} == set(PIPE):
        continue
    along_x, c, s0, s1 = link_line(a, b)
    s0, s1 = s0 + R / 2 + T, s1 - R / 2 - T
    for _ in range(2):
        a0, side = luck.uniform(s0 + 20, s1 - 20), luck.choice((-1, 1))
        for _ in range(luck.randint(3, 5)):
            size = luck.uniform(5, 11)
            ball("DustBunny", at3(along_x, a0 + luck.uniform(-9, 9), FLOOR + 1 + size * 0.35,
                                  c + side * (W / 2 - 8 - luck.uniform(0, 8))), size, [0.72, 0.7, 0.68], "Fabric")
    if luck.random() < 0.5:
        ball("Marble", at3(along_x, luck.uniform(s0, s1), FLOOR + 4, c + luck.uniform(-35, 35)), 6, luck.choice(MARBLES), "Glass")
x, z = ROOMS["N"]
ball("BouncyBall", [x + 92, FLOOR + 11, z - 88], 20, [0.85, 0.2, 0.6], "SmoothPlastic")

model = {"className": "Model", "children": parts}
path = ROOT / "assets/models/ducts.model.json"
path.write_text(json.dumps(model, separators=(",", ":")), encoding="utf-8")
print(f"{len(parts)} parts -> {path.relative_to(ROOT)}")
