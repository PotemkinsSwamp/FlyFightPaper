"""Place the 3D toys on the town rug: one uploaded mesh per toy, cheap copies at every spot in assets/rug/toy-spots.json.

  python tools/town_toys.py upload NAME...   upload each toy's FBX and maps (records in assets/models/toys/NAME/upload.json)
  python tools/town_toys.py build            write assets/models/city-toys.rbxmx from the upload records
  python tools/town_toys.py build v4         the new town: toy-spots-v4.json -> assets/models/city-toys-v4.rbxmx
  python tools/town_toys.py rearm FOLDER PREFIX...  archive a hero piece's old maps on Roblox and forget them (hero re-uploads)
  python tools/town_toys.py hero FOLDER       upload a hero building's pieces (FOLDER/parts/*.fbx + maps from tools/art/hero.py)
  python tools/town_toys.py stand FOLDER X Z ANGLE   add the hero's pieces to toy-placements.json, base centre at X, Z
  python tools/town_toys.py kit NAME X Z ANGLE     stand a kit recipe, replacing its earlier placement
  python tools/town_toys.py readlua FOLDER     Luau to run in Studio: reads each uploaded piece's MeshId and size
  python tools/town_toys.py meshes FOLDER JSON  store that Luau's result in the pieces' upload.json
  python tools/town_toys.py placelua FOLDER    Luau to run in Studio: stands the building's pieces in CityToys
  python tools/town_toys.py drop X Z R NAME... remove NAMEs and BuildingCollision boxes within R of X, Z from classroom.rbxmx
  python tools/town_toys.py pull FILE        keep hand edits made in Studio: FILE is the JSON dump of every CityToys part
                                             (name, colour map id, CFrame components, size, solid); saved as
                                             assets/rug/toy-placements.json, which `build` then uses instead of the spots
  python tools/town_toys.py packs PLACE...   collect the TexturePack id Studio made for each set of maps in saved places
                                             into assets/models/texture-packs.json, which `build` writes into every toy

Studio only shows a SurfaceAppearance's maps once it has packed them into a TexturePack asset. A toy written without
one makes Studio upload a pack per toy on the next Play; with ~1,100 toys Roblox rate-limits that (HTTP 429) and the
toys stay grey. So known packs are kept in texture-packs.json and written back on every build.

After `upload`, the MeshId and MeshPart size of each FBX model are read in Studio (LoadAsset) and added to its
upload.json as "mesh" and "initial"; "studs" is the FBX's real size (Roblox caps imported meshes at 2048, so initial
is not a fixed multiple of it).
"""
import json, math, random, re, subprocess, sys, tempfile, time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TOYS = ROOT / "assets/models/toys"
SPOTS = json.loads((ROOT / "assets/rug/toy-spots.json").read_text())
CREATOR = "52064999"
FRONT = -math.pi / 2        # turn that points a toy's front (Blender -Y) along a spot's angle (goals checked by Alan)

# spot kind -> [(toy, colour map, weight)], and the scale rule (spot radius / the toy's own radius)
CHOICES = {
    "tree": [("tree-lollipop", "color", 5), ("tree-lollipop", "color-autumn", 1), ("tree-bushy", "color", 6)],
    "bush": [("tree-bushy", "color", 1)],          # a bushy tree shrunk to a bush (eraser park)
    "car": [("car-hatchback", "color", 1), ("car-sedan", "color", 1), ("car-taxi", "color", 1), ("car-van", "color", 1)],
    "stall": [("stall", f"color-{i}", 1) for i in range(6)],
    "house": [("house", f"color-{i}", 1) for i in range(3)],
    "crop": [("crop-row", f"color-{i}", 1) for i in range(3)],
}
RADIUS = {"tree": 10, "pine": 9, "bush": 10}  # canopy radius the model is built at
# Everything else is scaled evenly so its longest footprint side fits its rug spot (studs); fountains use the spot's r.
FIT = {"house": 30, "stall": 22, "playground": 50, "picnic": 12, "goal": 24, "pool": 44, "hay-bale": 8, "footbridge": 34,
       "boathouse": 30, "barn": 44, "petrol-station": 60, "fire-station": 50, "plane": 26, "hangar": 40, "terminal": 40,
       "fire-truck": 22, "car-hatchback": 15, "car-sedan": 15.5, "car-taxi": 15.5, "car-van": 16, "bench": 10, "ducks": 20, "crop-row": 20}
# Planes crash into these (like buildings); small toys stay see-through to flight so they cost nothing.
SOLID = {"tree", "pine", "house", "stall", "boathouse", "barn", "petrol_station", "fire_station", "hangar", "terminal", "fountain",
         "monorail-pylon"}


FLAT_FILE = ROOT / "assets/models/flat-maps.json"     # "key value" -> the shared tiny map's asset id


def send(path, key, name, out):
    """Upload one file and return its asset id. Bump and shine maps go up at half size (no visible difference in
    close-ups, Alan 2026-10-25); a flat one (one value all over) becomes the shared tiny map of that value, uploaded
    once. Colour maps and models go up as they are."""
    from PIL import Image, ImageStat
    flats = json.loads(FLAT_FILE.read_text()) if FLAT_FILE.exists() else {}
    tmp = value = None
    if key in ("normal", "roughness", "metalness"):
        im = Image.open(path); w, h = im.size
        stat = ImageStat.Stat(im.resize((max(1, w // 8), max(1, h // 8)), Image.BILINEAR))
        if max(stat.stddev) < 3:
            value = f"{key} {','.join(str(round(m)) for m in stat.mean)}"
            if value in flats: return flats[value]
            im = Image.new(im.mode, (16, 16), tuple(round(m) for m in stat.mean))
        else:
            im = im.resize((w // 2, h // 2), Image.LANCZOS)
        tmp = Path(tempfile.gettempdir()) / f"ffp-map{path.suffix}"; im.save(tmp); path = tmp
    out.unlink(missing_ok=True)
    subprocess.run([sys.executable, str(ROOT / "tools/upload_texture.py"), str(path), "--creator", CREATOR,
                    "--name", name, "--output", str(out)] + (["--model"] if key == "model" else []), check=True)
    asset = json.loads(out.read_text())["response"]["assetId"]; out.unlink()
    if tmp: tmp.unlink()
    if value:
        flats[value] = asset; FLAT_FILE.write_text(json.dumps(dict(sorted(flats.items())), indent=0) + "\n")
    return asset


def upload(names):
    for name in names:
        d = TOYS / name; record = d / "upload.json"
        rec = json.loads(record.read_text()) if record.exists() else {}
        files = [(d / f"{name}.fbx", "model")] + [(p, p.stem) for p in sorted(d.glob("*.png"))
                                                    if p.stem.startswith(("color", "normal", "roughness", "metalness"))]
        for path, key in files:
            if key in rec: continue
            rec[key] = send(path, key, f"FlyFightPaper toy {name} {key}", d / f"upload-{key}.json")
            record.write_text(json.dumps(rec, indent=2) + "\n")
        print(name, rec)


def place(x, z, angle, size):
    """CFrame components standing a toy of this size on the rug at x, z, turned by angle about the vertical."""
    c, s = math.cos(angle), math.sin(angle)
    return [x, 0.6 + size[1] / 2, z, c, 0, s, 0, 1, 0, -s, 0, c]


def part(name, rec, color, cf, size, solid):
    sx, sy, sz = size
    rot = "".join(f"<R{i // 3}{i % 3}>{v:.4f}</R{i // 3}{i % 3}>" for i, v in enumerate(cf[3:]))
    flag = lambda b: "true" if b else "false"
    return (f'<Item class="MeshPart"><Properties><string name="Name">{name}</string>'
            f'<Content name="MeshId"><url>rbxassetid://{rec["mesh"]}</url></Content>'
            f'<Vector3 name="InitialSize"><X>{rec["initial"][0]}</X><Y>{rec["initial"][1]}</Y><Z>{rec["initial"][2]}</Z></Vector3>'
            f'<bool name="Anchored">true</bool><bool name="CanCollide">{flag(solid)}</bool><bool name="CanQuery">{flag(solid)}</bool>'
            '<bool name="CanTouch">false</bool><bool name="CastShadow">true</bool>'
            # Exact shape for solid toys (save_place.py reuses the one Studio saved); see-through ones get Box so
            # Studio never computes a mesh shape for them.
            f'<token name="CollisionFidelity">{3 if solid else 2}</token>'
            '<token name="RenderFidelity">0</token>'
            f'<Vector3 name="size"><X>{sx:.3f}</X><Y>{sy:.3f}</Y><Z>{sz:.3f}</Z></Vector3>'
            f'<CoordinateFrame name="CFrame"><X>{cf[0]}</X><Y>{cf[1]:.3f}</Y><Z>{cf[2]}</Z>{rot}</CoordinateFrame>'
            '</Properties><Item class="SurfaceAppearance"><Properties><string name="Name">Paint</string>'
            f'<Content name="ColorMap"><url>rbxassetid://{rec[color]}</url></Content>'
            f'<Content name="NormalMap"><url>rbxassetid://{rec["normal"]}</url></Content>'
            f'<Content name="RoughnessMap"><url>rbxassetid://{rec["roughness"]}</url></Content>'
            + (f'<Content name="MetalnessMap"><url>rbxassetid://{rec["metalness"]}</url></Content>' if "metalness" in rec else "")
            + (f'<Content name="TexturePack"><url>{pack}</url></Content>' if (pack := PACKS.get(pack_key(
                rec[color], rec["normal"], rec["roughness"], rec.get("metalness", "")))) else "") +
            '</Properties></Item></Item>')


def thread(cf, size):
    rot = "".join(f"<R{i // 3}{i % 3}>{v}</R{i // 3}{i % 3}>" for i, v in enumerate(cf[3:]))
    return ('<Item class="Part"><Properties><string name="Name">thread</string><token name="shape">2</token>'
            '<bool name="Anchored">true</bool><bool name="CanCollide">false</bool><bool name="CanQuery">false</bool>'
            '<bool name="CanTouch">false</bool><bool name="CastShadow">false</bool><token name="Material">1312</token>'
            '<Color3uint8 name="Color3uint8">4294309365</Color3uint8>'
            f'<Vector3 name="size"><X>{size[0]}</X><Y>{size[1]}</Y><Z>{size[2]}</Z></Vector3>'
            f'<CoordinateFrame name="CFrame"><X>{cf[0]}</X><Y>{cf[1]}</Y><Z>{cf[2]}</Z>{rot}</CoordinateFrame>'
            '</Properties></Item>')


PACKS_FILE = ROOT / "assets/models/texture-packs.json"
PACKS = json.loads(PACKS_FILE.read_text()) if PACKS_FILE.exists() else {}


def pack_key(*maps):
    """colour|normal|roughness|metalness asset ids (no rbxassetid:// prefix; empty when a map is unused)."""
    return "|".join(re.sub(r"\D", "", str(m)) for m in maps)


def packs(*places):
    found = 0
    for place in places:
        text = Path(place).read_text(encoding="utf-8", errors="replace")
        for block in re.findall(r'<Item class="SurfaceAppearance".*?</Item>', text, re.S):
            maps = dict(re.findall(r'name="(\w+Map)(?:Content)?">\s*<ur[il]>([^<]*)', block))
            pack = re.search(r'name="TexturePack(?:Content)?">\s*<ur[il]>(rbxassetid://\d+)', block)
            if pack and maps.get("ColorMap"):
                PACKS[pack_key(*(maps.get(k, "") for k in ("ColorMap", "NormalMap", "RoughnessMap", "MetalnessMap")))] = pack[1]
                found += 1
    PACKS_FILE.write_text(json.dumps(dict(sorted(PACKS.items())), indent=0) + "\n")
    print("read", found, "packs;", len(PACKS), "known")


PLACEMENTS = ROOT / "assets/rug/toy-placements.json"


def records():
    recs = {p.parent.name: json.loads(p.read_text()) for p in TOYS.glob("*/upload.json")}
    for p in (ROOT / "assets/models").glob("*/parts/*.upload.json"):    # hero building pieces, named "folder/piece"
        recs[f"{p.parent.parent.name}/{p.name.removesuffix('.upload.json')}"] = json.loads(p.read_text())
    return recs


def hero(folder):
    for fbx in sorted((ROOT / folder / "parts").glob("*.fbx")):
        record = fbx.with_suffix(".upload.json")
        rec = json.loads(record.read_text()) if record.exists() else {}
        maps = [(k, fbx.with_name(f"{fbx.stem}-{k}.png")) for k in ("color", "normal", "roughness", "metalness")
                if k != "metalness" or fbx.with_name(f"{fbx.stem}-{k}.png").exists()]   # metalness: materials.py
        maps += [(p.stem[len(fbx.stem) + 1:], p) for p in sorted(fbx.parent.glob(f"{fbx.stem}-color-*.png"))]
        for key, path in [("model", fbx)] + maps:
            if key in rec: continue
            rec[key] = send(path, key, f"FFP tower part {fbx.stem.split('-')[0]} {key}", fbx.with_name("upload-tmp.json"))
            record.write_text(json.dumps(rec, indent=2) + "\n")
        print(fbx.stem, rec)


def stand(folder, x, z, angle):
    """Pieces share the building's base centre; a MeshPart sits at its own box centre, so offset each piece.
    Blender (x, y, z) shows up in Roblox as (-x, z, y) (front -Y faces local -Z, see FRONT)."""
    rows = json.loads(PLACEMENTS.read_text())
    name = Path(folder).name
    rows = [r for r in rows if not r["toy"].startswith(name + "/")]
    a = FRONT - float(angle); c, s = math.cos(a), math.sin(a)
    for piece in json.loads((ROOT / folder / "parts.json").read_text())["pieces"]:   # MeshIds can come later: build skips unread pieces
        (x0, y0, z0), (x1, y1, z1) = piece["bounding_box"]["min"], piece["bounding_box"]["max"]
        ox, oy, oz = -(x0 + x1) / 2, (z0 + z1) / 2, (y0 + y1) / 2
        size = [x1 - x0, z1 - z0, y1 - y0]
        cf = [float(x) + c * ox + s * oz, 0.6 + oy, float(z) - s * ox + c * oz, c, 0, s, 0, 1, 0, -s, 0, c]
        rows.append(dict(toy=f"{name}/{piece['prefix']}", color="color", cf=cf, size=size, solid=True))
    PLACEMENTS.write_text(json.dumps(rows, indent=0) + "\n")
    print("stood", name, "at", x, z)


def kit(name, x, z, angle):
    """Fixed pieces, base centre on the rug. Blender yaw becomes positive Roblox yaw
    under stand()'s (-x, z, y) conversion. Offsets use only the building's turn."""
    assert name and Path(name).name == name, "NAME must be a building name"
    recipe = json.loads((ROOT / "assets/models/kit/buildings" / f"{name}.json").read_text())
    rows = json.loads(PLACEMENTS.read_text())
    x, z = float(x), float(z)
    a = FRONT - float(angle); c, s = math.cos(a), math.sin(a)
    w, d = recipe["footprint"]
    extras = {p["piece"] for p in recipe["pieces"] if not p["piece"].startswith("kit/")}
    # ponytail: only replaces what stands on this footprint, so one recipe can stand in several places; moving a
    # building leaves its old copy (delete those rows by hand).
    def earlier(row):
        if row.get("building") != name and not row["toy"].startswith("kit/") and row["toy"] not in extras: return False
        dx, dz = row["cf"][0] - x, row["cf"][2] - z
        # Undo the building turn, then test in Blender footprint axes.
        return abs(c * dx - s * dz) <= w / 2 + .01 and abs(s * dx + c * dz) <= d / 2 + .01
    rows = [row for row in rows if not earlier(row)]
    recs = records()
    for piece in recipe["pieces"]:
        toy, color = piece["piece"], piece["color"]
        rec = recs[toy]
        assert all(k in rec for k in ("mesh", "initial", color, "normal", "roughness")), f"{toy}: upload/read its MeshId in Studio first"
        ox, oy, oz = -piece["offset"][0], piece["offset"][2], piece["offset"][1]
        pc, ps = math.cos(a + piece["yaw"]), math.sin(a + piece["yaw"])
        sx, sy, sz = piece["size"]
        cf = [x + c * ox + s * oz, .6 + oy, z - s * ox + c * oz,
              pc, 0, ps, 0, 1, 0, -ps, 0, pc]
        rows.append(dict(toy=toy, color=color, cf=cf, size=[sx, sz, sy], solid=True, building=name))
    PLACEMENTS.write_text(json.dumps(rows, indent=0) + "\n")
    print("stood kit", name, "at", x, z, "with", len(recipe["pieces"]), "pieces")


def pull(dump):
    """Studio's toys -> toy-placements.json. Colour maps are stored by name, so re-uploaded maps still match."""
    names = {(toy, str(v)): k for toy, rec in records().items() for k, v in rec.items() if k.startswith("color")}
    rows = [dict(toy=r["n"], color=names[(r["n"], r["c"])], cf=r["cf"], size=r["s"], solid=r["solid"])
            for r in json.loads(Path(dump).read_text())]
    PLACEMENTS.write_text(json.dumps(rows, indent=0) + "\n")
    print("kept", len(rows), "toys from Studio in", PLACEMENTS.name)


def lamp_light(height_studs, scale):
    """A switched-off warm light at the lamp's bulb, for future dark/weather events (Alan 2026-10-16)."""
    bulb = json.loads((TOYS / "street-lamp" / "light.json").read_text())["bulb_blender_studs"]
    y = bulb[2] * scale - height_studs / 2        # ponytail: height only; the bulb is ~2 studs off the part's centre
    return ('<Item class="Attachment"><Properties><string name="Name">Bulb</string>'          # sideways, harmless
            f'<CoordinateFrame name="CFrame"><X>0</X><Y>{y:.3f}</Y><Z>0</Z><R00>1</R00><R01>0</R01><R02>0</R02>'
            '<R10>0</R10><R11>1</R11><R12>0</R12><R20>0</R20><R21>0</R21><R22>1</R22></CoordinateFrame></Properties>'
            '<Item class="PointLight"><Properties><bool name="Enabled">false</bool><float name="Brightness">2</float>'
            '<float name="Range">28</float><Color3 name="Color"><R>1</R><G>0.86</G><B>0.6</B></Color3>'
            '<bool name="Shadows">false</bool></Properties></Item></Item>')


def build(plan=None):
    """`build`: today's town (Alan's hand-placed toy-placements.json, else toy-spots.json) -> city-toys.rbxmx.
    `build v4`: the new town's plan (toy-spots-v4.json from tools/rug.py --plan) -> city-toys-v4.rbxmx."""
    recs = records()
    items, missing = [], set()
    spots = json.loads((ROOT / "assets/rug/toy-spots-v4.json").read_text()) if plan == "v4" else SPOTS
    if plan != "v4" and PLACEMENTS.exists():     # Alan's hand-edited town wins over the generated spots
        for t in json.loads(PLACEMENTS.read_text()):
            if t["toy"] == "thread":             # plain string holding a ceiling piece (city_links.py)
                items.append(thread(t["cf"], t["size"])); continue
            rec = recs.get(t["toy"])
            if not rec or "mesh" not in rec:     # re-baked and not uploaded yet
                missing.add(t["toy"].split("/")[0]); continue
            items.append(part(t["toy"], rec, t["color"], t["cf"], t["size"], t["solid"]))
        return write(items, missing)
    rng = random.Random(7)                       # same town every build
    for spot in spots:
        kind = spot["kind"]
        options = CHOICES.get(kind) or [({"pine": "tree-pine", "lamp": "street-lamp"}.get(kind, kind.replace("_", "-")), "color", 1)]
        if kind in ("stall", "house", "crop"):
            toy, color, _ = options[spot.get("color", rng.randrange(len(options))) % len(options)]
        else:
            toy, color, _ = rng.choices(options, [w for *_, w in options])[0]
        rec = recs.get(toy)
        if not rec or "mesh" not in rec or color not in rec:
            missing.add(toy); continue
        round_thing = kind in RADIUS
        footprint = max(rec["studs"][0], rec["studs"][2])
        if round_thing: scale = spot["r"] / RADIUS[kind] * rng.uniform(.9, 1.1)
        elif kind == "fountain": scale = 2 * spot["r"] / footprint
        else: scale = FIT[toy] / footprint if toy in FIT else 1
        angle = rng.uniform(0, 2 * math.pi) if round_thing or kind == "fountain" else -spot.get("angle", 0) + FRONT
        size = spot.get("size") or [v * scale for v in rec["studs"]]
        item = part(toy, rec, color, place(spot["x"], spot["z"], angle, size), size, solid=kind in SOLID)
        if toy == "street-lamp":
            item = item[:-len("</Item>")] + lamp_light(size[1], scale) + "</Item>"
        items.append(item)
    if plan == "v4":
        items += monorail_beams(recs, missing) + monorail_train(recs, missing) + buildings_v4(recs, missing)
    write(items, missing, "city-toys-v4.rbxmx" if plan == "v4" else "city-toys.rbxmx")


def monorail_beams(recs, missing):
    """Beam pieces along the monorail line, each stretched to its stretch of track (+1 so the joints overlap) and laid
    on the pillars' T-caps; the pillars are spots like any toy. Solid: planes crash into the track."""
    beam, pylon = recs.get("monorail-beam"), recs.get("monorail-pylon")
    if not (beam and "mesh" in beam and pylon and "mesh" in pylon):
        missing.add("monorail-beam"); return []
    line = json.loads((ROOT / "assets/rug/replan-v4.json").read_text())["monorail"]["line"]["coordinates"]
    out = []
    for (x0, z0), (x1, z1) in zip(line, line[1:]):
        k = max(1, round(math.hypot(x1 - x0, z1 - z0) / beam["studs"][2]))   # long straights: pieces near the
        for i in range(k):                                                   # model's own length, ends unstretched
            ax, az, bx, bz = x0 + (x1 - x0) * i / k, z0 + (z1 - z0) * i / k, x0 + (x1 - x0) * (i + 1) / k, z0 + (z1 - z0) * (i + 1) / k
            size = [beam["studs"][0], beam["studs"][1], math.hypot(bx - ax, bz - az) + 1]
            cf = place((ax + bx) / 2, (az + bz) / 2, -math.atan2(bz - az, bx - ax) + FRONT, size)
            cf[1] += pylon["studs"][1]
            out.append(part("monorail-beam", beam, "color", cf, size, solid=True))
    return out

# Pieces in toy-placements.json that belong to the classroom, not today's town: kept by `build v4` (desks and their
# service pieces, ceiling fly-throughs, room furniture, the schoolyard set, the bell tower clock, the floor fans).
CLASSROOM_PIECES = {"backpack-cubby", "basketball-hoop", "bulletin-board", "cardboard-tube", "ceiling-light",
                    "ceiling-ring", "classroom-bookshelf", "classroom-door", "clock-face", "clock-hour", "clock-minute",
                    "crawl-tunnel", "cubby-shelf", "desk-hangar", "desk-runway-droop", "fence-panel", "floor-fan",
                    "floor-fan-blades", "jungle-gym", "landing-ring", "merry-go-round", "monkey-bars", "paper-bunting",
                    "paper-chain", "runway-light", "runway-light-tip", "saturn", "school-chair", "school-desk", "seesaw",
                    "slide", "spring-rider", "swing-set", "thread", "tire-swing"}

def buildings_v4(recs, missing):
    """The new town's 45 buildings at the plan's centres and turns (replan-v4.json), each from its pieces like
    `stand`; the bell tower keeps today's hand-placed pieces (same spot in both towns)."""
    plan = json.loads((ROOT / "assets/rug/replan-v4.json").read_text())
    out = []
    room = json.loads((ROOT / "config/gameplay.json").read_text())["world"]
    def outside(cf):                                 # the schoolyard past the windows (trees, houses, benches) stays too
        return abs(cf[0]) > room["width_studs"] / 2 or abs(cf[2]) > room["depth_studs"] / 2
    for r in json.loads(PLACEMENTS.read_text()):     # the classroom's own pieces and the bell tower stay as placed
        root = r["toy"].split("/")[0]
        if root not in CLASSROOM_PIECES and root != "bell-tower" and not outside(r["cf"]): continue
        if root == "thread":
            out.append(thread(r["cf"], r["size"])); continue
        cf = list(r["cf"])
        if root.startswith("floor-fan"):            # the two fans move to the new fan plazas (x +/-780 -> +/-600)
            fan = next(f for f in plan["fans"] if (f["x"] > 0) == (cf[0] > 0))
            cf[0] += fan["x"] - math.copysign(780, cf[0])
        out.append(part(r["toy"], recs[r["toy"]], r["color"], cf, r["size"], r["solid"]))
    for b in plan["buildings"]:
        name, k = b["name"], b["scale"]
        x, z = b["centre"]
        a = FRONT - (math.radians(b["yaw"]) - math.pi / 2)    # plan front (sin yaw, -cos yaw) -> stand's angle
        c, s = math.cos(a), math.sin(a)
        for piece in json.loads((ROOT / "assets/models" / name / "parts.json").read_text())["pieces"]:
            rec = recs.get(f"{name}/{piece['prefix']}")
            if not rec or "mesh" not in rec:
                missing.add(name); continue
            (x0, y0, z0), (x1, y1, z1) = piece["bounding_box"]["min"], piece["bounding_box"]["max"]
            ox, oy, oz = -(x0 + x1) / 2 * k, (z0 + z1) / 2 * k, (y0 + y1) / 2 * k
            size = [(x1 - x0) * k, (z1 - z0) * k, (y1 - y0) * k]
            cf = [x + c * ox + s * oz, 0.6 + oy, z - s * ox + c * oz, c, 0, s, 0, 1, 0, -s, 0, c]
            see_through = any(piece["label"].startswith(n) for n in WALLS.get(name, ((), []))[0])
            out.append(part(f"{name}/{piece['prefix']}", rec, "color", cf, size, solid=not see_through))
        for i, ((x0, y0, z0), (x1, y1, z1)) in enumerate(WALLS.get(name, ((), []))[1]):
            ox, oy, oz = -(x0 + x1) / 2 * k, (z0 + z1) / 2 * k, (y0 + y1) / 2 * k
            cf = [x + c * ox + s * oz, 0.6 + oy, z - s * ox + c * oz, c, 0, s, 0, 1, 0, -s, 0, c]
            out.append(wall(f"{name}/wall-{i + 1}", cf, [(x1 - x0) * k, (z1 - z0) * k, (y1 - y0) * k]))
    return out

# Pieces whose exact shape Studio gets wrong, flown as plain invisible walls instead (Blender studs, building's own
# frame): (labels made see-through, wall boxes). The lunch tin's west half shape filled a wedge of the track tunnel
# (2026-10-17), so the tin is its floor, roof, and long walls round the three windows; the ends stay open.
_TIN = [((-85, -40, 103), (85, 40, 120)), ((-85, -40, 162), (85, 40, 167))]
for _y0, _y1 in ((-40, -31), (31, 40)):
    _TIN += [((-85, _y0, 120), (85, _y1, 124.4)), ((-85, _y0, 155.6), (85, _y1, 162))]
    _TIN += [((a, _y0, 124.4), (b, _y1, 155.6)) for a, b in ((-85, -75.6), (-28.4, -23.6), (23.6, 28.4), (75.6, 85))]
WALLS = {"monorail-station-south": (("rounded-red-lunch-tin-half",), _TIN)}

def wall(name, cf, size):
    """An invisible solid box: planes and bots hit it like the building it stands in for."""
    rot = "".join(f"<R{i // 3}{i % 3}>{v:.4f}</R{i // 3}{i % 3}>" for i, v in enumerate(cf[3:]))
    return (f'<Item class="Part"><Properties><string name="Name">{name}</string><bool name="Anchored">true</bool>'
            '<bool name="CanCollide">true</bool><bool name="CanQuery">true</bool><bool name="CanTouch">false</bool>'
            '<bool name="CastShadow">false</bool><float name="Transparency">1</float>'
            f'<Vector3 name="size"><X>{size[0]:.3f}</X><Y>{size[1]:.3f}</Y><Z>{size[2]:.3f}</Z></Vector3>'
            f'<CoordinateFrame name="CFrame"><X>{cf[0]}</X><Y>{cf[1]:.3f}</Y><Z>{cf[2]}</Z>{rot}</CoordinateFrame>'
            '</Properties></Item>')

def monorail_train(recs, missing):
    """The train's three cars (car-1..car-3 in a MonorailTrain model), parked at the track start; each client moves
    them (src/client/TrainMotion.luau). See-through to flight: the server judges hits (src/shared/MonorailRules.luau)."""
    cars = json.loads((ROOT / "config/gameplay.json").read_text())["world"]["monorail"]["cars"]
    if not all(recs.get(c["model"], {}).get("mesh") for c in cars):
        missing.add("monorail-car"); return []
    x, z = json.loads((ROOT / "config/monorail-track.json").read_text())["line"][0]
    inner = "".join(part(f"car-{i}", recs[c["model"]], "color", place(x, z, 0, c["size"]), c["size"], solid=False)
                    for i, c in enumerate(cars, 1))
    return ['<Item class="Model"><Properties><string name="Name">MonorailTrain</string></Properties>' + inner + "</Item>"]

def readlua(folder):
    """Luau for Studio's execute_luau: LoadAsset each uploaded piece, return its MeshId and size as JSON for `meshes`."""
    ids = {p.name.removesuffix(".upload.json"): json.loads(p.read_text())["model"] for p in (ROOT / folder / "parts").glob("*.upload.json")}
    print("local H,I,o=game:GetService('HttpService'),game:GetService('InsertService'),{} for k,id in pairs(H:JSONDecode('"
          + json.dumps(ids) + "')) do local m=I:LoadAsset(id) local p=m:FindFirstChildWhichIsA('MeshPart',true) "
          "o[k]={mesh=p.MeshId:match('%d+'),initial={p.Size.X,p.Size.Y,p.Size.Z}} m:Destroy() end return H:JSONEncode(o)")


def meshes(folder, result):
    """Write `readlua`'s JSON (a file, or the text itself) into each piece's upload.json."""
    data = json.loads(Path(result).read_text() if Path(result).exists() else result)
    for k, v in data.items():
        record = ROOT / folder / "parts" / f"{k}.upload.json"
        rec = json.loads(record.read_text()); rec.update(v)
        record.write_text(json.dumps(rec, indent=2) + "\n")
    print("read", len(data), "pieces")


def placelua(folder):
    """Luau that stands this building's toy-placements rows in the open place's CityToys (Rojo doesn't sync it)."""
    name, recs = Path(folder).name, records()
    rows = [dict(n=r["toy"], m=recs[r["toy"]]["mesh"], c=[recs[r["toy"]].get(k, "") for k in (r["color"], "normal", "roughness", "metalness")],
                 cf=r["cf"], s=r["size"]) for r in json.loads(PLACEMENTS.read_text()) if r["toy"].startswith(name + "/")]
    print("local H,A=game:GetService('HttpService'),game:GetService('AssetService') "
          "local T=workspace:FindFirstChild('CityToys',true) for _,c in ipairs(T:GetChildren()) do "
          f"if c.Name:sub(1,{len(name) + 1})=='{name}/' then c:Destroy() end end for _,r in ipairs(H:JSONDecode('"
          + json.dumps(rows) + "')) do local p=A:CreateMeshPartAsync('rbxassetid://'..r.m) p.Name=r.n "
          "p.Anchored=true p.CanTouch=false p.Size=Vector3.new(unpack(r.s)) p.CFrame=CFrame.new(unpack(r.cf)) "
          "local s=Instance.new('SurfaceAppearance') s.Name='Paint' s.ColorMap='rbxassetid://'..r.c[1] "
          "s.NormalMap='rbxassetid://'..r.c[2] s.RoughnessMap='rbxassetid://'..r.c[3] if r.c[4]~='' then s.MetalnessMap='rbxassetid://'..r.c[4] end s.Parent=p p.Parent=T end "
          f"return #T:GetChildren()")


def drop(x, z, r, *names, path=ROOT / "assets/models/classroom.rbxmx"):
    """Remove old buildings from classroom.rbxmx: these names and BuildingCollision boxes within r of x, z (r 0: names anywhere)."""
    text, out, i, gone = path.read_text(encoding="utf-8"), [], 0, []
    for m in re.finditer(r'\n\s*<Item class="[^"]+" referent="[^"]*">', text):
        if m.start() < i: continue
        depth, j = 0, m.start()
        for t in re.finditer(r"<Item |</Item>", text[m.start():]):
            depth += 1 if t.group() == "<Item " else -1
            if depth == 0: j = m.start() + t.end(); break
        block = text[m.start():j]
        nm = re.search(r'<string name="Name">([^<]*)<', block).group(1)
        pos = re.search(r'name="CFrame">\s*<X>([^<]+)</X>\s*<Y>[^<]+</Y>\s*<Z>([^<]+)</Z>', block)
        near = pos and math.hypot(float(pos[1]) - float(x), float(pos[2]) - float(z)) <= float(r)
        if (nm in names and (near or float(r) == 0)) or (nm.startswith("BuildingCollision") and near):
            out.append(text[i:m.start()]); i = j; gone.append(nm)
    path.write_text("".join(out) + text[i:], encoding="utf-8")
    print("dropped", len(gone), sorted(set(n.rstrip("0123456789_") for n in gone)))


def write(items, missing, name="city-toys.rbxmx"):
    xml = ('<roblox version="4"><Item class="Model"><Properties><string name="Name">CityToys</string></Properties>'
           + "".join(items) + "</Item></roblox>")
    (ROOT / "assets/models" / name).write_text(xml)
    print("wrote", name, "with", len(items), "toys;", "not ready (no upload or no mesh id yet):", sorted(missing) or "none")


def rearm(folder, *prefixes):
    """Take a hero piece's old maps off Roblox (archive) and forget them, so `hero` uploads the current PNGs.
    For maps that must not stay online (the bell tower legs got the account banned, 2026-10-12)."""
    import requests
    env = {k.strip(): v.strip().strip('"').strip("'") for k, _, v in
           (l.partition("=") for l in (ROOT / ".env").read_text().splitlines()) if _}
    session = requests.Session(); session.headers["x-api-key"] = env["ROBLOX_API"]
    for prefix in prefixes:
        record = next((ROOT / folder / "parts").glob(f"{prefix}-*.upload.json"))
        rec = json.loads(record.read_text())
        for key in [k for k in rec if k not in ("model", "mesh", "initial")]:
            r = session.post(f"https://apis.roblox.com/assets/v1/assets/{rec[key]}:archive", timeout=30)
            if not r.ok and r.status_code != 404:    # 404: Roblox already removed it
                raise SystemExit(f"{record.name} {key}: HTTP {r.status_code} {r.text[:200]}")
            print(record.name, key, rec.pop(key), r.status_code)
            record.write_text(json.dumps(rec, indent=2) + "\n")
            time.sleep(2)                            # slowly: 429s otherwise


if __name__ == "__main__":
    cmd, *args = sys.argv[1:]
    {"upload": lambda: upload(args), "pull": lambda: pull(*args), "build": lambda: build(*args), "hero": lambda: hero(*args),
     "stand": lambda: stand(*args), "kit": lambda: kit(*args), "readlua": lambda: readlua(*args),
     "meshes": lambda: meshes(*args), "placelua": lambda: placelua(*args), "drop": lambda: drop(*args),
     "packs": lambda: packs(*args), "rearm": lambda: rearm(*args)}[cmd]()
