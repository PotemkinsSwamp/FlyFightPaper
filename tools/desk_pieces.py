"""Desk pieces on every pilot desk: the drooping cardboard runway, the paper-chain landing ring, runway lights.

  python tools/desk_pieces.py place     write their rows into assets/rug/toy-placements.json (then town_toys.py build)
  python tools/desk_pieces.py lua       Luau for Studio's execute_luau: stands them live in CityToys to look at
  python tools/desk_pieces.py drop      remove the old flat pads, runway tape and post rings from the place sources

Slots match FlightService: a desk's `home` faces the room (-Z local); neutral desks hold two slots at +-48.
Sizes are the Blender sizes in each toy's checks.json (x, z, y -> Roblox x, y, z); Roblox centres a mesh on its box.
"""
import json, math, re, sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import town_toys

ROOT = Path(__file__).resolve().parents[1]
CLASSROOM = ROOT / "assets/models/classroom.rbxmx"
DECOR = ROOT / "assets/models/classroom-decor.rbxmx"
SERVICE = json.loads((ROOT / "config/gameplay.json").read_text())["service"]
TOYS = ("desk-runway-droop", "landing-ring", "runway-light", "runway-light-tip")
TURN = math.pi       # uploaded FBX arrive turned 180 degrees about Y (memory: roblox-mesh-import-gotchas)
RUNWAY = (100, 37.168, 224.649)   # droop: pad 100 wide at the back, runway 88 wide, bend at 216 from the back edge
BEND, TOP = 216, 0.5              # Blender: desk front at y 216; top face lifted 0.5 off the desk so they never flicker
LIGHT = 2                         # the 3-stud model read as a pin on a 330-stud desk


def desks():
    """(name, x, y, z, yaw, size) for every pilot desk in classroom.rbxmx."""
    text = CLASSROOM.read_text(encoding="utf-8")
    for m in re.finditer(r'<string name="Name">((?:DeskNorth|DeskSouth|NeutralDesk)\d+)</string>', text):
        block = text[text.rfind("<Item", 0, m.start()):text.find("</Item>", m.start())]
        cf = [float(v) for v in re.findall(r"<(?:X|Y|Z|R\d\d)>([^<]+)<", re.search(r'name="CFrame">(.*?)</Coordinate', block, re.S)[1])]
        size = [float(v) for v in re.findall(r"<[XYZ]>([^<]+)<", re.search(r'name="size">(.*?)</Vector3>', block, re.S)[1])]
        yaw = math.atan2(cf[5], cf[3])   # R02, R00 of a turn about Y
        yield m[1], cf[0], cf[1], cf[2], yaw, size


def slots():
    """(x, top, z, yaw, depth, width) per landing slot, yaw turning local -Z toward the room like the server's home."""
    for name, x, y, z, yaw, size in desks():
        top = y + size[1] / 2
        if name.startswith("Neutral"):
            for side in (-48, 48):
                yield x + side * math.cos(yaw), top, z - side * math.sin(yaw), yaw, size[2], 0.94
        else:
            yield x, top, z, math.pi if "North" in name else 0.0, size[2], 1.0


def frame(x, y, z, yaw, local, turn=TURN):
    """CFrame components for a point given in slot-local studs, the mesh turned by `turn` about Y."""
    c, s = math.cos(yaw), math.sin(yaw)
    lx, ly, lz = local
    wx, wz = x + c * lx + s * lz, z - s * lx + c * lz
    a = yaw + turn
    ca, sa = math.cos(a), math.sin(a)
    return [round(wx, 3), round(y + ly, 3), round(wz, 3), ca, 0, sa, 0, 1, 0, -sa, 0, ca]


def rows():
    out = []
    for x, top, z, yaw, depth, width in slots():
        back = depth / 2
        stretch = depth / BEND                      # the bend sits on the desk's own front edge
        length = RUNWAY[2] * stretch
        size = [RUNWAY[0] * width, RUNWAY[1], length]
        out.append(dict(toy="desk-runway-droop", color="color", cf=frame(x, top, z, yaw, (0, TOP - RUNWAY[1] / 2, back - length / 2)), size=size, solid=False))
        ring = (0, SERVICE["approach_up_studs"] + 2.8, -SERVICE["approach_out_studs"])
        out.append(dict(toy="landing-ring", color="color", cf=frame(x, top, z, yaw, ring), size=[74, 74, 8], solid=False))
        edge = 44 * width + 1.5 * LIGHT + 1
        for k in range(4):                          # evenly from just past the pad (86) to near the desk front
            along = 100 + k * (depth - 124) / 3
            for side in (-edge, edge):
                out.append(dict(toy="runway-light", color="color", cf=frame(x, top, z, yaw, (side, 1.55 * LIGHT, back - along)), size=[3 * LIGHT, 3.1 * LIGHT, 3 * LIGHT], solid=False))
                out.append(dict(toy="runway-light-tip", color="color", cf=frame(x, top, z, yaw, (side, 3.55 * LIGHT, back - along)), size=[0.675 * LIGHT, 0.9 * LIGHT, 0.675 * LIGHT], solid=False))
    return out


def place():
    path = town_toys.PLACEMENTS
    kept = [r for r in json.loads(path.read_text()) if r["toy"] not in TOYS]
    new = rows()
    path.write_text(json.dumps(kept + new, indent=0) + "\n")
    print("placed", len(new), "desk pieces;", len(kept), "other toys kept")


def lua():
    recs = town_toys.records()
    data = [dict(n=r["toy"], m=recs[r["toy"]]["mesh"], c=[recs[r["toy"]][k] for k in ("color", "normal", "roughness")], cf=r["cf"], s=r["size"]) for r in rows()]
    print("local H,A=game:GetService('HttpService'),game:GetService('AssetService') local T=workspace:FindFirstChild('CityToys',true) "
          "local names={} for _,n in ipairs(H:JSONDecode('" + json.dumps(list(TOYS)) + "')) do names[n]=true end "
          "for _,c in ipairs(T:GetChildren()) do if names[c.Name] then c:Destroy() end end local meshes={} "
          "for i,r in ipairs(H:JSONDecode('" + json.dumps(data) + "')) do meshes[r.m]=meshes[r.m] or A:CreateMeshPartAsync('rbxassetid://'..r.m) "
          "local p=meshes[r.m]:Clone() p.Name=r.n p.Anchored=true p.CanCollide=false p.CanQuery=false p.CanTouch=false "
          "p.Size=Vector3.new(unpack(r.s)) p.CFrame=CFrame.new(unpack(r.cf)) local s=Instance.new('SurfaceAppearance') s.Name='Paint' "
          "s.ColorMap='rbxassetid://'..r.c[1] s.NormalMap='rbxassetid://'..r.c[2] s.RoughnessMap='rbxassetid://'..r.c[3] s.Parent=p p.Parent=T "
          "if i%40==0 then task.wait() end end return #T:GetChildren()")


def drop():
    """Old pieces: flat pads, tape lines, the 12-post rings (classroom.rbxmx) and neutral pads (classroom-decor.rbxmx)."""
    for path in (CLASSROOM, DECOR):
        text = path.read_text(encoding="utf-8")
        names = set(re.findall(r'<string name="Name">((?:Pad(?:North|South)\d+|PadSide|RunwayTape|Landing\w*Segment\d+))</string>', text))
        if names:
            town_toys.drop(0, 0, 0, *names, path=path)


if __name__ == "__main__":
    {"place": place, "lua": lua, "drop": drop}[sys.argv[1]]()
