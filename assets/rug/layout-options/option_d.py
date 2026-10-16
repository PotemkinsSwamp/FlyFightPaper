"""Three street-layout sketches for Alan to pick (2026-10-15). Throwaway: the pick feeds tools/town_plan.py."""
import json, math
from pathlib import Path
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle, Polygon as MPoly, Circle
from shapely.geometry import LineString, Polygon, Point, box
from shapely.ops import unary_union
from shapely import affinity

ROOT = Path("D:/FlyFightPaper")
OUT = ROOT / "assets/rug/layout-options"; OUT.mkdir(exist_ok=True)
W = json.loads((ROOT / "config/gameplay.json").read_text(encoding="utf-8"))["world"]
RUG = box(-1240, -700, 1240, 700)
ST, AV, BV = 20, 26, 30          # street, avenue, boulevard half widths
FAN = 85


def lines_in(region, pts_list):
    return [LineString(p).intersection(region) for p in pts_list]


def draw(name, title, roads, squares=(), parks=(), water=(), fans=(), mono=None, mono_closed=False, stations=(),
         notes=""):
    fig, ax = plt.subplots(figsize=(16, 9.6))
    ax.add_patch(Rectangle((-1400, -1100), 2800, 2200, fc="#d9b98c"))
    dw, dd = W["desk_size"][0], W["desk_size"][2]
    for x in W["desk_x_positions"]:
        for z in W["desk_z_positions"]:
            ax.add_patch(Rectangle((x - dw / 2, z - dd / 2), dw, dd, fc="#b07a46", ec="k"))
    for x in W["neutral_desk_x_positions"]:
        ax.add_patch(Rectangle((x - 105, -165), 210, 330, fc="#b07a46", ec="k", zorder=6))

    def poly(g, **kw):
        for p in getattr(g, "geoms", [g]):
            if p.is_empty or p.geom_type != "Polygon": continue
            from matplotlib.path import Path as MPath
            from matplotlib.patches import PathPatch
            path = MPath.make_compound_path(*[MPath(list(r.coords), closed=True) for r in [p.exterior, *p.interiors]])
            ax.add_patch(PathPatch(path, **({"ec": "none"} | kw)))   # holes stay holes
    poly(RUG, fc="#7d7d84", ec="#557a3a", lw=2)                                             # roads
    road = unary_union([g.buffer(w, cap_style="flat", join_style="mitre") for g, w in roads]).intersection(RUG)
    poly(RUG.difference(road), fc="#d8d2c4", zorder=2)                                        # pavements
    poly(RUG.difference(road.buffer(7, join_style="mitre")), fc="#8fbf6a", zorder=3)          # blocks
    for p in parks: poly(p, fc="#5f9e47", ec="#3d6b2c", zorder=4)
    for p in water: poly(p, fc="#5b9bd5", ec="#2d6aa0", zorder=4)
    for x, z, r in squares: poly(Point(x, z).buffer(r).difference(road.buffer(7)), fc="#e3d6bd", ec="#a89878", zorder=5)   # roads run through squares
    for x in W["desk_x_positions"]:
        for s in (-1, 1):
            z0, z1 = (405, 700) if s > 0 else (-700, -405)
            ax.add_patch(Rectangle((x - 85, z0), 170, z1 - z0, fc="none", ec="#2e7d32", ls=":", lw=1.2, zorder=7))
    ax.add_patch(Rectangle((-105, -105), 210, 210, fc="none", ec="#b8860b", ls="--", lw=2, zorder=8))   # tower over the crossing
    for lx, lz in ((-105, -105), (65, -105), (-105, 65), (65, 65)):                                       # its four legs
        ax.add_patch(Rectangle((lx, lz), 40, 40, fc="#f2c94c", ec="k", zorder=8))
    ax.text(0, 0, "BELL\nTOWER\n430", fontsize=8, ha="center", va="center", zorder=9, weight="bold")
    for x, z in fans:
        ax.add_patch(Rectangle((x - FAN, z - FAN), 2 * FAN, 2 * FAN, fc="#b3e5fc", ec="#0277bd", lw=2.5, zorder=8))
        ax.text(x, z, f"FAN\n{math.hypot(x, z):.0f}", fontsize=8, ha="center", va="center", color="#01579b", zorder=9)
    if mono:
        xs, zs = zip(*(list(mono) + ([mono[0]] if mono_closed else [])))
        ax.plot(xs, zs, color="#6a1b9a", lw=6, zorder=10, solid_capstyle="round")
        ax.plot(xs, zs, color="#e1bee7", lw=1.5, ls="--", zorder=11)
    for x, z, a in stations:
        r = affinity.rotate(box(x - 85, z - 35, x + 85, z + 35), a, origin=(x, z))
        poly(r, fc="#9c27b0", ec="k", zorder=12, alpha=.9)
        ax.text(x, z, "STN", fontsize=7, ha="center", va="center", color="w", zorder=13)
    ax.set_xlim(-1420, 1420); ax.set_ylim(1120, -1120); ax.set_aspect("equal"); ax.set_xticks([]); ax.set_yticks([])
    ax.set_title(title, fontsize=13, weight="bold")
    fig.text(.5, .04, notes + "\nGrey = roads, cream = pavements and squares, dark green = parks, blue = water, purple = "
             "monorail and stations, light blue = fans (number = distance from the bell tower), dotted green = desk "
             "landing paths (low buildings only).", ha="center", fontsize=9.5, wrap=True)
    fig.savefig(OUT / f"{name}.png", dpi=70, bbox_inches="tight")



ring = [(LineString([(-1180, -640), (1180, -640), (1180, 640), (-1180, 640), (-1180, -640)]), ST)]
rz = lambda x: 300 + 150 * math.exp(-(x / 650) ** 2)
riv = LineString([(x, rz(x)) for x in range(-1300, 1301, 50)])
river = riv.buffer(55).intersection(RUG)
bank = riv.parallel_offset(85, "left")                       # riverside drive on the north bank
k = 640 / 1180
broadway = LineString([(-1180, -640), (1180, 640)])
R = 130 + BV + 7 + 8                     # plaza radius + boulevard half width + pavement + a gap


def u_round(cx):                         # the boulevard swings south round a fan plaza in a U
    return [(cx + R * math.cos(t), R * math.sin(t)) for t in [math.pi - i * math.pi / 24 for i in range(25)]]


blvd = LineString([(-1180, 0)] + u_round(-750) + u_round(750) + [(1180, 0)])
roads = ring + [(LineString([(-1180, z), (1180, z)]), AV) for z in (-470, -235)] + [(blvd, BV)] \
    + [(LineString([(x, -640), (x, 640)]), BV if x == 0 else ST) for x in (-1000, -500, 0, 500, 1000)] \
    + [(broadway, AV), (bank.intersection(RUG), ST), (LineString([(-1180, 560), (1180, 560)]), ST)]
park = box(-1000 + ST, -470 + AV, -500 - ST, -235 - AV)
fans = [(-750, 0), (750, 0)]                                    # round plazas on the boulevard, east and west
loop = [(x, rz(x)) for x in range(-1000, 1001, 50)] + [(1000, -235), (-1000, -235)]
stations = [(250, -235, 90), (-500, rz(-500), 0)]
# rough lot count: every block's street fronts hold one 110-wide building per 170 studs
road = unary_union([g.buffer(w, cap_style="flat", join_style="mitre") for g, w in roads]).intersection(RUG)
blocks = RUG.difference(road.buffer(7 + 14)).difference(river.buffer(10)).difference(park).difference(Point(0, 0).buffer(150))
lots = 0
for b in getattr(blocks, "geoms", [blocks]):
    if b.area < 8000: continue
    r = b.minimum_rotated_rectangle; xs = list(r.exterior.coords)
    s1, s2 = sorted([LineString(xs[0:2]).length, LineString(xs[1:3]).length])
    if s1 < 90: continue
    lots += max(1, int(s2 // 170)) * (2 if s1 > 230 else 1)
print("rough building lots:", lots)
draw("option-d-manhattan-river", "Option D: Manhattan + Broadway on a river (A + C), monorail loop",
     roads, [(z / k, z, 70) for z in (-470, -235)] + [(0, 0, 150), (-750, 0, 130), (750, 0, 130)], parks=[park], water=[river], fans=fans,
     mono=loop, mono_closed=True, stations=stations,
     notes=f"A's long blocks and diagonal Broadway (squares where it crosses the avenues) north of C's river; a riverside "
           f"drive on the north bank, bridges where streets cross. The monorail is a loop: above the river (fly under it "
           f"along the water), north up the outer streets, back above an avenue, through two stations. Fans in round plazas on the main boulevard, far east and far west, the same "
           f"distance from the bell tower. Room for about {lots} buildings (we have 46).")
