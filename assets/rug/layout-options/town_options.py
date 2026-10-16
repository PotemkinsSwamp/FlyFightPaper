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
    for x, z, r in squares: poly(Point(x, z).buffer(r), fc="#e3d6bd", ec="#a89878", zorder=5)
    for x in W["desk_x_positions"]:
        for s in (-1, 1):
            z0, z1 = (405, 700) if s > 0 else (-700, -405)
            ax.add_patch(Rectangle((x - 85, z0), 170, z1 - z0, fc="none", ec="#2e7d32", ls=":", lw=1.2, zorder=7))
    ax.add_patch(Rectangle((-105, -105), 210, 210, fc="#f2c94c", ec="k", zorder=8))
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

# ---- A: Manhattan + Broadway. Long east-west blocks, a diagonal Broadway through the bell tower square with small
# squares where it crosses avenues, a Central Park, the monorail looping above two avenues round the park.
AVS = [-470, -235, 0, 235, 470]
STS = [-1000, -500, 0, 500, 1000]
k = 640 / 1180
broadway = LineString([(-1180, -640), (1180, 640)])
park = box(-1000 + ST, -470 + AV, -500 - ST, 0 - BV)
roadsA = ring + [(LineString([(-1180, z), (1180, z)]), BV if z == 0 else AV) for z in AVS] \
    + [(LineString([(x, -640), (x, 640)]), BV if x == 0 else ST) for x in STS] + [(broadway, AV)]
sqA = [(z / k, z, 70) for z in AVS if z] + [(0, 0, 150)]
fansA = [(-470 / k, -470), (470 / k, 470)]
draw("option-a-manhattan", "Option A: Manhattan + Broadway",
     roadsA, sqA, parks=[park], water=[Point(-750, -235).buffer(70)], fans=fansA,
     mono=[(-500, -235), (1000, -235), (1000, 235), (-500, 235)], mono_closed=True,
     stations=[(250, -235, 90), (-250, 235, 90)],
     notes="Long blocks (500 x 235) like Manhattan; Broadway cuts diagonally through the bell tower square, with small "
           "squares where it crosses each avenue (fans on two of them, mirror images). Central Park in the north-west. "
           "The monorail loops above two avenues and two streets, round the park's edge, through two stations.")

# ---- B: Seattle. Two street grids meeting at an angle along a seam through the bell tower square (like downtown
# Seattle meeting the Denny grid); one straight monorail line above an avenue from a waterfront station to the
# bell tower; a bay along the south-west edge with piers.
seam_a = math.radians(32)
half_ne = Polygon([(-1500 * math.cos(seam_a), -1500 * math.sin(seam_a)), (1500 * math.cos(seam_a), 1500 * math.sin(seam_a)),
                   (1500, -1500), (-1500, -1500)]).intersection(RUG)
half_sw = RUG.difference(half_ne)
bay = Polygon([(-1240, 520), (-300, 600), (100, 700), (-1240, 700)])
straight = [LineString([(-1300, z), (1300, z)]) for z in (-450, -200, 200, 450)] + \
           [LineString([(x, -800), (x, 800)]) for x in (-750, -400, 400, 750, 1050)]
rot = [affinity.rotate(LineString([(-1600, z), (1600, z)]), -32, origin=(0, 0)) for z in (-260, -50, 160, 370, 580)] + \
      [affinity.rotate(LineString([(x, -1600), (x, 1600)]), -32, origin=(0, 0)) for x in (-900, -620, -340, -60, 220)]
seam = LineString([(-1500 * math.cos(seam_a), -1500 * math.sin(seam_a)), (1500 * math.cos(seam_a), 1500 * math.sin(seam_a))])
roadsB = ring + [(g, ST) for g in lines_in(half_ne, straight)] + [(g, ST) for g in lines_in(half_sw.difference(bay), rot)] \
    + [(seam.intersection(RUG), BV)]
monoB0, monoB1 = (-760, 470), (-120, 70)
monoB = [monoB0, monoB1]
draw("option-b-seattle", "Option B: Seattle (two grids meeting at an angle)",
     roadsB, [(0, 0, 160), (-600, 520, 80)], parks=[Point(0, 0).buffer(260).difference(Point(0, 0).buffer(160)).intersection(half_ne)],
     water=[bay.intersection(RUG)], fans=[(520, -330), (-520, 330)], mono=monoB,
     stations=[(monoB0[0], monoB0[1], -32), (-260, 158, -32)],
     notes="The bell tower is 'Seattle Center': a park ring round it on the seam where two street grids meet (triangle "
           "blocks along the seam). Downtown's grid is turned 32 degrees. One straight monorail line (two tracks, the "
           "train runs back and forth) above a downtown avenue from the waterfront station to the bell tower station. "
           "A bay with piers on the south-west edge replaces the farm.")

# ---- C: River town (Wuppertal's hanging monorail runs above its river). A river curves across the south; the old
# town wraps round the bell tower north of it with avenues spreading out over bridges; the monorail rides above the
# river from end to end.
riv = LineString([(-1300, 260)] + [(x, 250 + 210 * math.exp(-(x / 650) ** 2)) for x in range(-1200, 1201, 100)] + [(1300, 260)])
river = riv.buffer(55).intersection(RUG)
radials = [affinity.rotate(LineString([(160, 0), (1500, 0)]), a, origin=(0, 0)) for a in (-150, -90, -30, 30, 90, 150)]
ringC = Point(0, 0).buffer(430).exterior
south = [LineString([(x, 330), (x, 700)]) for x in (-900, -450, 450, 900)] + [LineString([(-1240, 600), (1240, 600)])]
northS = [LineString([(-1240, -420), (1240, -420)])]
roadsC = ring + [(g.intersection(RUG), AV) for g in radials] + [(ringC, AV)] + [(g, ST) for g in south + northS] \
    + [(LineString([(-1240, 150), (-500, 150)]), ST), (LineString([(500, 150), (1240, 150)]), ST)]
monoC = [(x, 250 + 210 * math.exp(-(x / 650) ** 2)) for x in range(-1100, 1101, 100)]
draw("option-c-river", "Option C: River town (monorail above the river)",
     roadsC, [(0, 0, 160)], parks=[Point(-780, -170).buffer(110), Point(780, -170).buffer(110)], water=[river],
     fans=[(-640, -330), (640, -330)], mono=monoC,
     stations=[(-600, monoC[5][1], 0), (600, monoC[17][1], 0)],
     notes="A river curves across the south. The old town wraps round the bell tower: six avenues spread out from its "
           "square, a ring road, smaller streets between; avenues cross the river on bridges. The monorail runs above "
           "the river from end to end (planes fly under it along the water), stations near two bridges.")
print("written", sorted(p.name for p in OUT.glob("*.png")))
