"""Connected city plan: ruler bridges between close neighbours, the big bell tower and fly-through ceiling pieces.

python tools/city_links.py dump STUDIO_ID PARTS.tsv   save every visible town part's box from open Studio
python tools/city_links.py check PARTS.tsv            check the plan against the town, draw assets/rug/connected-city-preview.png
python tools/city_links.py roofs PARTS.tsv STUDIO_ID  lay each ruler roof to roof in open Studio -> bridge-roofs.json
python tools/city_links.py place                      write the pieces into assets/rug/toy-placements.json (then build);
                                                      resets every bridge, so it undoes Alan's hand edits made in Studio
python tools/city_links.py clocks                     (re)write only the bell tower's clock rows
Rules (Alan, .planning/briefs/2026-10-11-connected-city-kit.md): buildings stay put; a bridge joins two close buildings
at a height both reach; legs stand on grass or roofs, never streets; nothing overlaps; ceiling pieces are fly-through.
"""
from pathlib import Path
import sys

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, str(Path(__file__).parent))
from rug import RUG, Pen, road_at, WALK  # noqa: E402

CEILING = 620
BRIDGE_W, SECTION = 30, 60          # ruler deck width; one repeating ruler section (a tape strip hides each joint)
BRIDGES = [  # (label, building a, building b): a ruler laid roof to roof, resting on both (Alan, 2026-10-12)
    ("B1", "book-stack-garden", "pencil-cup-tower"),
    ("B2", "tube-tower", "pencil-cup-tower"),
    ("B3", "eraser-hall", "banner-tower"),
    ("B4", "book-stack-lookout", "crayon-box-tower"),
    ("B5", "book-apartments", "book-stack-spire"),
    ("B6", "glue-tower", "sharpener-tower"),
    ("B7", "sharpener-tower", "brick-water-tower"),
    ("B8", "notebook-tower", "stapler-offices"),
]
ROOT = Path(__file__).parents[1]
ROOFS = ROOT / "assets/rug/bridge-roofs.json"   # roof heights where each ruler lands (`roofs`)
LAND = 8                            # each end rests this far in from the roof edge
BELL = dict(x=0, z=0, leg=36, span=170, top=430, arch=150, belfry=(280, 370))   # four legs round Town Square
RINGS = [(x, 450, -330, "x") for x in (120, 270, 420)] + [(x, 440, 330, "x") for x in (600, 860)] + \
        [(-480, 460, z, "z") for z in (-180, -60)]           # (x, centre height, z, flying direction); 60 across inside
TUBES = [(-330, 470, 330, "x", 200), (480, 470, 60, "z", 200), (-700, 470, 0, "x", 200)]   # hanging cardboard tubes
CHAINS = [((-110, -200), (110, -200), 450), ((-110, 200), (110, 200), 450), ((-480, -600), (-480, -380), 470),
          ((200, 0), (420, 0), 450)]                          # paper chains (one 220-long piece): ends at the ceiling, lowest point here
RING_R, TUBE_R = 40, 35                                       # outer radii (holes 60 and 62 across; wingspan is 7)


def load(path):
    parts = []
    for line in open(path, encoding="utf-8"):
        tag, name, solid, *v = line.rstrip("\n").split("\t")
        x0, x1, z0, z1, y0, y1 = map(float, v)
        parts.append(dict(tag=tag, name=name, building=name.split("/")[0], solid=solid == "1",
                          box=(x0, x1, z0, z1, y0, y1)))
    return parts


def footprint(parts, building):
    bs = [p["box"] for p in parts if p["building"] == building]
    return (min(b[0] for b in bs), max(b[1] for b in bs), min(b[2] for b in bs), max(b[3] for b in bs),
            min(b[4] for b in bs), max(b[5] for b in bs))


def ends(parts, a, b):
    """Where a ruler from a to b lands: the axis it runs along, its line across, and the facing roof edges."""
    A, B = footprint(parts, a), footprint(parts, b)
    along_x = not max(A[0], B[0]) < min(A[1], B[1])          # sharing x means it runs north-south (along z)
    i, j = (0, 1) if along_x else (2, 3)                       # footprint indices along the run
    k, l = (2, 3) if along_x else (0, 1)
    mid = (max(A[k], B[k]) + min(A[l], B[l])) / 2
    if A[j] < B[i]: return along_x, mid, (A[j], A[i], -1), (B[i], B[j], 1)   # (facing edge, far edge, inward sign)
    return along_x, mid, (A[i], A[j], 1), (B[j], B[i], -1)


ROOF_LUA = r"""
-- Lay each ruler roof to roof: rest one end LAND in from a's edge, then slide the other end inward on b's roof until
-- the gap is a whole number of SECTIONs, so both ends touch a roof. Returns the section/tape rows and anything hit.
local H = game:GetService("HttpService")
local T = workspace.Arena.CityToys
local out, report = {}, {}
local function partsOf(name)
  local l = {} for _, p in T:GetChildren() do if p.Name:sub(1, #name + 1) == name .. "/" then table.insert(l, p) end end return l
end
for _, b in H:JSONDecode(SPECS) do
  local function point(u, w) if b.along_x then return Vector3.new(u, 0, w) end return Vector3.new(w, 0, u) end
  local function roof(list, u)
    local params = RaycastParams.new() params.FilterType = Enum.RaycastFilterType.Include params.FilterDescendantsInstances = list
    local best
    for _, dw in {-12, 0, 12} do
      local p = point(u, b.mid + dw)
      local hit = workspace:Raycast(Vector3.new(p.X, 700, p.Z), Vector3.new(0, -720, 0), params)
      if hit and (not best or hit.Position.Y > best) then best = hit.Position.Y end
    end
    return best
  end
  local A, B = partsOf(b.a), partsOf(b.b)
  local function land(list, e, floor)                -- step in from LAND until the hit is roof-high (edges step back)
    local u = e[1] + e[3] * LAND
    while (roof(list, u) or 0) < floor and math.abs(u - e[2]) > 10 do u += e[3] end
    return u, point(u, b.mid) + Vector3.new(0, (roof(list, u) or 0) + 3, 0)
  end
  local ua, pa = land(A, b.ea, b.fa)
  local ub, pb = land(B, b.eb, b.fb)
  local n = math.ceil((pb - pa).Magnitude / SECTION)
  while true do                                      -- step b's end inward until the ruler is n sections long
    local h = roof(B, ub)
    if h and h >= b.fb then pb = point(ub, b.mid) + Vector3.new(0, h + 3, 0) end
    if (pb - pa).Magnitude >= n * SECTION or math.abs(ub - b.eb[2]) < 10 then break end
    ub += b.eb[3]
  end
  if (pb - pa).Magnitude < n * SECTION - 1 then table.insert(report, string.format("%s: %.0f short of a whole ruler; the end overhangs %s", b.label, n * SECTION - (pb - pa).Magnitude, b.b)) end
  local d = (pb - pa).Unit
  local up = (Vector3.yAxis - d * d.Y).Unit
  local function cf(at) return {CFrame.fromMatrix(at, d, up):GetComponents()} end
  local probe = Instance.new("Part") probe.Anchored = true probe.Size = Vector3.new(SECTION - 2, 4, 28)
  local params = OverlapParams.new() params.FilterType = Enum.RaycastFilterType.Exclude
  local skip = {} for _, p in A do table.insert(skip, p) end for _, p in B do table.insert(skip, p) end
  params.FilterDescendantsInstances = skip
  for i = 0, n - 1 do
    local at = pa + d * (SECTION * (i + .5))
    table.insert(out, {toy = "ruler-section", cf = cf(at), size = {60, 6, 30}})
    probe.CFrame = CFrame.fromMatrix(at, d, up)
    for _, p in workspace:GetPartsInPart(probe, params) do
      if p.CanCollide and p.Parent == T and p.Name ~= "ruler-section" and p.Name ~= "ruler-tape" then table.insert(report, b.label .. " hits " .. p.Name) end
    end
    if i > 0 then table.insert(out, {toy = "ruler-tape", cf = cf(pa + d * (SECTION * i)), size = {10, 8, 32}}) end
  end
  probe:Destroy()
  table.insert(report, string.format("%s: %d sections, ends at %.0f and %.0f high, slope %.0f deg", b.label, n, pa.Y - 3, pb.Y - 3, math.deg(math.asin(math.abs(d.Y)))))
end
return H:JSONEncode({rows = out, report = report})
"""


def roofs(parts, studio):
    """Measure the roofs in open Studio and store every bridge's ruler rows in ROOFS."""
    import json, os, subprocess, tempfile
    specs = []
    for label, a, b in BRIDGES:
        along_x, mid, ea, eb = ends(parts, a, b)
        floor = lambda n: min(p["box"][4] for p in parts if p["building"] == n and "roof" in p["name"].split("/")[-1])
        specs.append(dict(label=label, a=a, b=b, along_x=along_x, mid=mid, ea=ea, eb=eb, fa=floor(a), fb=floor(b)))
    code = Path(tempfile.gettempdir()) / "city_links_roofs.lua"
    code.write_text(f"local SPECS, LAND, SECTION = [==[{json.dumps(specs)}]==], {LAND}, {SECTION}\n" + ROOF_LUA, encoding="utf-8")
    text = subprocess.run([sys.executable, str(Path(__file__).parent / "studio_cli.py"), "execute_luau",
                           json.dumps(dict(studio_id=studio, datamodel_type="Edit", code=str(code)))],
                          capture_output=True, text=True, env=dict(os.environ, FULL="1"), check=True).stdout
    result = json.loads(text)
    ROOFS.write_text(json.dumps(result["rows"], indent=0) + "\n")
    print("\n".join(result["report"]))


def hits(box, parts, skip=(), margin=0):
    x0, x1, z0, z1, y0, y1 = box
    return sorted({p["name"] for p in parts if p["building"] not in skip and p["tag"] == "toy" and p["solid"]
                   and p["box"][0] < x1 + margin and p["box"][1] > x0 - margin and p["box"][2] < z1 + margin
                   and p["box"][3] > z0 - margin and p["box"][4] < y1 + margin and p["box"][5] > y0 - margin})


def ceiling_boxes():
    for x, y, z, d in RINGS:
        yield f"ring {x},{z}", (x - 8, x + 8, z - RING_R, z + RING_R, y - RING_R, CEILING) if d == "x" else \
            (x - RING_R, x + RING_R, z - 8, z + 8, y - RING_R, CEILING)
    for x, y, z, d, l in TUBES:
        yield f"tube {x},{z}", (x - l / 2, x + l / 2, z - TUBE_R, z + TUBE_R, y - TUBE_R, CEILING) if d == "x" else \
            (x - TUBE_R, x + TUBE_R, z - l / 2, z + l / 2, y - TUBE_R, CEILING)
    for (ax, az), (bx, bz), y in CHAINS:
        yield f"chain {ax},{az}", (min(ax, bx), max(ax, bx), min(az, bz) - 6, max(az, bz) + 6, y - 6, CEILING)


def check(parts):
    problems, rows = [], []
    for label, a, b in BRIDGES:
        along_x, mid, ea, eb = ends(parts, a, b)
        rows.append((label, along_x, mid, ea, eb))
    L, s = BELL["leg"], BELL["span"] / 2
    for sx in (-1, 1):
        for sz in (-1, 1):
            cx, cz = BELL["x"] + sx * s, BELL["z"] + sz * s
            leg = (cx - L / 2, cx + L / 2, cz - L / 2, cz + L / 2, 0, BELL["top"])
            if any(road_at(x, z, WALK) for x in (leg[0], leg[1]) for z in (leg[2], leg[3])):
                problems.append(f"bell tower leg at {cx},{cz} stands on a street")
            hit = hits(leg, parts, ("fountain",))
            if moved := [h for h in hit if h.startswith("tree")]: print(f"bell tower leg {cx},{cz}: move {moved}")
            if hit := [h for h in hit if not h.startswith("tree")]: problems.append(f"bell tower leg {cx},{cz} hits {hit[:4]}")
    for name, box in ceiling_boxes():
        if hit := hits(box, parts, margin=60): problems.append(f"{name}: within 60 of {hit[:4]}")
        near = [p["name"] for p in parts if p["tag"] in ("decor", "high") and "Thread" not in p["name"]
                and p["box"][0] < box[1] + 40 and p["box"][1] > box[0] - 40 and p["box"][2] < box[3] + 40
                and p["box"][3] > box[2] - 40 and p["box"][4] < box[5] and p["box"][5] > box[4]]
        if near: problems.append(f"{name}: within 40 of hanging {sorted(set(near))[:3]}")
    return problems, rows


def draw(parts, rows):
    s, pad = 1.5, 360
    base = Image.open(RUG / "preview.png").convert("RGB").resize((3000, 2100), Image.LANCZOS)
    img = Image.new("RGB", (3000 + 2 * 0, 2100 + pad), (250, 247, 238))
    img.paste(Image.blend(base, Image.new("RGB", base.size, (255, 255, 255)), 0.35), (0, 0))
    p = Pen(img, -1000, -700, s)
    d = ImageDraw.Draw(img)
    font = lambda n: ImageFont.truetype("arialbd.ttf", n)
    ink, bridge_c, bell_c, sky_c, old_c = (40, 40, 48), (232, 176, 40), (196, 70, 52), (40, 110, 210), (150, 110, 190)
    for q in parts:                                           # everything already on the rug
        x0, x1, z0, z1, y0, y1 = q["box"]
        if q["name"].startswith("tree"): p.circle((x0 + x1) / 2, (z0 + z1) / 2, 7, fill=(84, 130, 70))
        elif q["tag"] == "toy" and q["solid"] and "/" in q["name"] and q["building"] != "kit":
            p.rect(x0, z0, x1, z1, fill=(172, 164, 156))
    seen = set()
    for q in parts:                                           # building names and roof heights
        b = q["building"]
        if "/" in q["name"] and b not in seen and b != "kit":
            seen.add(b)
            f = footprint(parts, b)
            p.rect(f[0], f[2], f[1], f[3], outline=ink, w=2)
            p.text((f[0] + f[1]) / 2, (f[2] + f[3]) / 2 - 8, b.replace("-", " "), 9, ink)
            p.text((f[0] + f[1]) / 2, (f[2] + f[3]) / 2 + 8, f"roof {f[5]:.0f}", 9, (90, 90, 96))
    for q in parts:                                           # things hanging from the ceiling today
        x0, x1, z0, z1, y0, y1 = q["box"]
        if q["tag"] == "decor" and "Thread" not in q["name"] and x1 - x0 > 40 and q["name"] != "Ball":
            p.ellipse((x0 + x1) / 2, (z0 + z1) / 2, (x1 - x0) / 2, (z1 - z0) / 2, outline=old_c, w=3)
    for label, along_x, mid, ea, eb in rows:                  # ruler bridges, roof to roof
        u0, u1 = ea[0] + ea[2] * LAND, eb[0] + eb[2] * LAND
        box = (u0, mid - BRIDGE_W / 2, u1, mid + BRIDGE_W / 2) if along_x else (mid - BRIDGE_W / 2, u0, mid + BRIDGE_W / 2, u1)
        x0, z0, x1, z1 = min(box[0], box[2]), min(box[1], box[3]), max(box[0], box[2]), max(box[1], box[3])
        p.rect(x0, z0, x1, z1, fill=bridge_c, outline=ink, w=1.5)
        p.text((x0 + x1) / 2 + (0 if along_x else 30), (z0 + z1) / 2 + (24 if along_x else 0), label, 12, (150, 90, 0))
    L, h = BELL["leg"], BELL["span"] / 2                      # bell tower: four legs, the top drawn see-through
    p.rect(-h - L / 2, -h - L / 2, h + L / 2, h + L / 2, outline=bell_c, w=5)
    for sx in (-1, 1):
        for sz in (-1, 1):
            p.rect(sx * h - L / 2, sz * h - L / 2, sx * h + L / 2, sz * h + L / 2, fill=bell_c)
    p.text(0, -h - 40, "BELL TOWER 430", 18, bell_c)
    for x, y, z, dr in RINGS:                                 # ceiling rings (seen from above: a thin bar)
        if dr == "x": p.rect(x - 5, z - RING_R, x + 5, z + RING_R, fill=sky_c)
        else: p.rect(x - RING_R, z - 5, x + RING_R, z + 5, fill=sky_c)
        p.text(x + (0 if dr == "x" else 0), z + RING_R + 14, f"ring {y}", 10, sky_c)
    for x, y, z, dr, l in TUBES:
        box = (x - l / 2, z - TUBE_R, x + l / 2, z + TUBE_R) if dr == "x" else (x - TUBE_R, z - l / 2, x + TUBE_R, z + l / 2)
        p.rect(*box, r=TUBE_R, outline=sky_c, w=6)
        p.text(x, z, f"tube {y}", 11, sky_c)
    for (ax, az), (bx, bz), y in CHAINS:
        p.line([(ax, az), (bx, bz)], 6, sky_c)
        for k in range(9): p.circle(ax + (bx - ax) * k / 8, az + (bz - az) * k / 8, 8, outline=sky_c, w=3)
        p.text((ax + bx) / 2, (az + bz) / 2 - 20, f"chain {y}", 10, sky_c)
    y0, col = 2100 + 24, 40                                   # key
    key = [(bridge_c, "Ruler bridges (yellow): B1-B8, each a ruler laid from roof to roof, resting on both (sloped where the "
                      "roofs differ)."),
           (bell_c, "Big bell tower (red): four legs on the grass corners of Town Square, open arch over both "
                    "boulevards and the fountain; open belfry with a bell at 280-370; spire tip 430 (ceiling 620)."),
           (sky_c, "Ceiling pieces (blue): rings, hanging cardboard tubes and paper chains to fly through or under, "
                   "number = height of the middle. All hang well above the roofs."),
           (old_c, "Purple circles: planets and paper cranes already hanging (they stay)."),
           ((172, 164, 156), "Grey: buildings already placed, with their roof heights; green dots: trees. No building moves (4 small trees step aside for the tower legs).")]
    for c, text in key:
        d.rectangle([col, y0 + 6, col + 34, y0 + 34], fill=c)
        d.text((col + 50, y0 + 4), text, fill=ink, font=font(28))
        y0 += 64
    out = RUG / "connected-city-preview.png"
    img.save(out)
    return out


def place():
    """Every kit piece as a toy-placements row (MeshPart box centre + rotation); earlier rows from here are replaced."""
    import json
    flat, turned = [1, 0, 0, 0, 1, 0, 0, 0, 1], [0, 0, 1, 0, 1, 0, -1, 0, 0]   # turned: piece X runs along world Z
    upright = [0, -1, 0, 1, 0, 0, 0, 0, 1]                                        # a Part cylinder standing up
    rows = []
    def row(toy, x, y, z, rot, size, solid=True):
        rows.append(dict(toy=toy, color="color", cf=[x, y, z] + rot, size=size, solid=solid, building="links"))
    def thread(x, z, bottom):
        row("thread", x, (bottom + CEILING) / 2, z, upright, [CEILING - bottom, .6, .6], solid=False)
    for r in json.loads(ROOFS.read_text()):                  # measured in Studio by `roofs`
        rows.append(dict(toy=r["toy"], color="color", cf=r["cf"], size=r["size"], solid=True, building="links"))
    for x, y, z, d in RINGS:                  # hole centre is 3 below the box centre (hanger loop on top)
        row("ceiling-ring", x, y + 3, z, turned if d == "x" else flat, [80, 86, 8])
        thread(x, z, y + 46)
    for x, y, z, d, l in TUBES:
        row("cardboard-tube", x, y + 3, z, turned if d == "x" else flat, [70, 76, 200])
        for k in (-70, 70): thread(x + (k if d == "x" else 0), z + (k if d == "z" else 0), y + 41)
    for (ax, az), (bx, bz), y in CHAINS:
        row("paper-chain", (ax + bx) / 2, CEILING - 88, (az + bz) / 2, flat if az == bz else turned, [220, 176, 12])
    rows += clocks()
    path = RUG / "toy-placements.json"
    kept = [r for r in json.loads(path.read_text()) if r.get("building") != "links"]
    path.write_text(json.dumps(kept + rows, indent=0) + "\n")
    print("placed", len(rows), "connected-city pieces")


def clocks():
    """The bell tower's 4 clocks (face + hands at 12; TowerClock.luau turns the hands). The tower stands at BELL x, z
    unturned, which maps Blender (x, y, z) to Roblox (-y, z + .6, -x) (town_toys.stand)."""
    import json
    check = json.loads((ROOT / "assets/models/bell-tower/clock/checks.json").read_text())
    rows = []
    for spot in check["clock_positions"]:
        (x, y, z), (dx, dy, _) = spot["centre"], spot["outward"]
        at = (BELL["x"] - y, z + .6, BELL["z"] - x)
        out = (-dy, 0, -dx)                                    # horizontal, so lookAt's right = (-out.z, 0, out.x)
        rot = [-out[2], 0, -out[0], 0, 1, 0, out[0], 0, -out[2]]   # columns right, up, -out (CFrame.lookAt)
        for mesh in check["meshes"]:
            bx, by, bz = mesh["box_centre"]
            lx, ly, lz = -bx, bz, by                           # Blender offset -> part-local offset
            pos = [at[i] + rot[3 * i] * lx + rot[3 * i + 1] * ly + rot[3 * i + 2] * lz for i in range(3)]
            sx, sy, sz = mesh["size_xyz"]
            rows.append(dict(toy=mesh["label"], color="color", cf=pos + rot, size=[sx, sz, sy],
                             solid=mesh["label"] == "clock-face", building="links"))
    return rows


def lua():
    """Luau that stands the placed pieces in the open place's CityToys (Rojo doesn't sync it), replacing earlier ones."""
    import json
    sys.path.insert(0, str(Path(__file__).parent))
    from town_toys import records
    recs, out = records(), []
    for r in json.loads((RUG / "toy-placements.json").read_text()):
        if r.get("building") != "links": continue
        rec = recs.get(r["toy"], {})
        row = dict(n=r["toy"], cf=r["cf"], s=r["size"], solid=r["solid"])
        if rec: row.update(m=rec["mesh"], c=[rec[k] for k in ("color", "normal", "roughness")])   # Roblox's JSONDecode rejects null
        out.append(row)
    names = sorted({r["n"] for r in out})
    return ("local H,A=game:GetService('HttpService'),game:GetService('AssetService') local T=workspace.Arena.CityToys "
            f"local old={{}} for _,n in ipairs(H:JSONDecode('{json.dumps(names)}')) do old[n]=true end "
            "for _,c in ipairs(T:GetChildren()) do if old[c.Name] then c:Destroy() end end "
            f"local n=0 for _,r in ipairs(H:JSONDecode('{json.dumps(out)}')) do local p if r.n=='thread' then "
            "p=Instance.new('Part') p.Shape=Enum.PartType.Cylinder p.Material=Enum.Material.Fabric "
            "p.Color=Color3.fromRGB(245,245,245) p.CastShadow=false else "
            "p=A:CreateMeshPartAsync('rbxassetid://'..r.m,{CollisionFidelity=Enum.CollisionFidelity.PreciseConvexDecomposition}) "
            "local s=Instance.new('SurfaceAppearance') s.Name='Paint' s.ColorMap='rbxassetid://'..r.c[1] "
            "s.NormalMap='rbxassetid://'..r.c[2] s.RoughnessMap='rbxassetid://'..r.c[3] s.Parent=p end "
            "p.Name=r.n p.Anchored=true p.CanCollide=r.solid p.CanQuery=r.solid p.CanTouch=false "
            "p.Size=Vector3.new(unpack(r.s)) p.CFrame=CFrame.new(unpack(r.cf)) p.Parent=T n+=1 end return n")


DUMP = r"""
local out = {}
local function add(p, tag)
  local cf, s = p.CFrame, p.Size
  local function half(axis) return math.abs(cf.RightVector[axis])*s.X/2 + math.abs(cf.UpVector[axis])*s.Y/2 + math.abs(cf.LookVector[axis])*s.Z/2 end
  local P, hx, hy, hz = cf.Position, half("X"), half("Y"), half("Z")
  if math.abs(P.X) < 1000 and math.abs(P.Z) < 720 and s.Magnitude < 1500 then
    table.insert(out, string.format("%s\t%s\t%d\t%.0f\t%.0f\t%.0f\t%.0f\t%.0f\t%.0f", tag, p.Name, p.CanCollide and 1 or 0,
      P.X-hx, P.X+hx, P.Z-hz, P.Z+hz, P.Y-hy, P.Y+hy))
  end
end
for _, p in workspace.Arena.CityToys:GetDescendants() do if p:IsA("BasePart") and p.Transparency < 1 then add(p, "toy") end end
for _, p in workspace.Arena:GetChildren() do if p:IsA("BasePart") and p.Transparency < 1 and p.Position.Y > 300 then add(p, "high") end end
for _, p in workspace.Arena.ClassroomDecor:GetDescendants() do
  if p:IsA("BasePart") and p.Transparency < 1 and p.Position.Y > 300 then add(p, "decor") end
end
return table.concat(out, "\n")
"""


if __name__ == "__main__":
    cmd, *args = sys.argv[1:]
    if cmd == "dump":
        import json, os, subprocess, tempfile
        code = Path(tempfile.gettempdir()) / "city_links_dump.lua"
        code.write_text(DUMP, encoding="utf-8")
        text = subprocess.run([sys.executable, str(Path(__file__).parent / "studio_cli.py"), "execute_luau",
                               json.dumps(dict(studio_id=args[0], datamodel_type="Edit", code=str(code)))],
                              capture_output=True, text=True, env=dict(os.environ, FULL="1"), check=True).stdout
        Path(args[1]).write_text(text, encoding="utf-8")
        sys.exit(print(len(text.splitlines()), "parts"))
    if cmd == "lua": sys.exit(print(lua()))
    if cmd == "place": sys.exit(place())
    if cmd == "clocks":
        import json
        CLOCK = {"clock-face", "clock-hour", "clock-minute"}
        path = RUG / "toy-placements.json"
        rows = [r for r in json.loads(path.read_text()) if r["toy"] not in CLOCK] + clocks()
        path.write_text(json.dumps(rows, indent=0) + "\n")
        sys.exit(print("clock rows:", sum(r["toy"] in CLOCK for r in rows)))
    parts = load(args[0])
    if cmd == "roofs": sys.exit(roofs(parts, args[1]))
    problems, rows = check(parts)
    print("\n".join(problems) or "no problems")
    print(draw(parts, rows))
