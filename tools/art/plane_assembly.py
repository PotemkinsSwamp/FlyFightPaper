"""Where every piece of a built plane sits, worked out offline the way the game builds it (src/shared/Aircraft.luau
`Aircraft.build`), from assets/models/planes/pieces.rbxmx and config/catalog.json. No Studio needed.

    python tools/art/plane_assembly.py body_standard nose_0 wings_0 tail_0 [weapons=pellet,thumbtack,pellet] [boost=boost_band]

`assemble(loadout)` returns pieces: {name, slot, fbx, centre, size} in the plane's own frame (studs, Roblox axes:
x right, y up, -z forward), plus the plane's points a skin fits to. Used by the Mythical skin scripts in Blender
(tools/art/crane_skin.py), which place each FBX by its centre and size (lesson "Putting a whole plane together in
Blender"). Keep in step with Aircraft.luau if the build rules change.
"""
import base64
import json
import struct
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PLANES = ROOT / "assets/models/planes"
FBX_DIRS = [PLANES / "paper-set", PLANES / "paper-sample"]
WEAPON_DIRS = {"pellet": "pellet", "staple": "staple", "rubber": "gatling-b", "paperclip": "paperclip", "eraser": "eraser",
               "pencil": "pencil-b", "popper": "popper", "thumbtack": "thumbtack", "crayon": "crayon", "spitball": "spitball"}
ROOT_UNDER = {"wings_0": .78, "wings_1": .78, "wings_2": .78, "wings_3": .78, "wings_4": .67, "wings_5": .81}  # Aircraft.luau
NEIGHBOUR_GAP = .1


def _attrs(blob):
    """Roblox AttributesSerialize: only the string values the plane pieces use."""
    raw, out, i = base64.b64decode(blob), {}, 4
    for _ in range(struct.unpack_from("<I", raw, 0)[0]):
        n = struct.unpack_from("<I", raw, i)[0]; name = raw[i + 4:i + 4 + n].decode(); i += 4 + n
        kind = raw[i]; i += 1
        if kind != 2: raise ValueError(f"attribute {name}: type {kind} not handled")
        n = struct.unpack_from("<I", raw, i)[0]; out[name] = raw[i + 4:i + 4 + n].decode(); i += 4 + n
    return out


def _vec(s): return tuple(float(v) for v in s.split(",")) if s else None


def _load():
    models = {}
    for item in ET.parse(PLANES / "pieces.rbxmx").getroot().iter("Item"):
        if item.get("class") != "Model": continue
        props = item.find("Properties"); blob = props.find("BinaryString[@name='AttributesSerialize']")
        parts = []
        for child in item.findall("Item"):
            if child.get("class") != "MeshPart": continue
            p = child.find("Properties"); cf = p.find("CoordinateFrame[@name='CFrame']"); sz = p.find("Vector3[@name='size']")
            parts.append((p.find("string[@name='Name']").text, tuple(float(cf.find(a).text) for a in "XYZ"),
                          tuple(float(sz.find(a).text) for a in "XYZ")))
        models[item.get("referent")] = (_attrs(blob.text) if blob is not None and blob.text else {}, parts)
    catalog = {}
    def walk(o):
        if isinstance(o, dict):
            if "id" in o and "slot" in o: catalog[o["id"]] = o
            for v in o.values(): walk(v)
        elif isinstance(o, list):
            for v in o: walk(v)
    walk(json.load(open(ROOT / "config/catalog.json")))
    return models, catalog


def _fbx(name, weapon=None):
    if weapon: return ROOT / "assets/models/toys" / f"weapon-{WEAPON_DIRS[weapon]}" / "parts" / f"{name}.fbx"
    for d in FBX_DIRS:
        if (d / f"{name}.fbx").exists(): return d / f"{name}.fbx"
    return None


def add(a, b): return tuple(x + y for x, y in zip(a, b))
def sub(a, b): return tuple(x - y for x, y in zip(a, b))
def mul(a, k): return tuple(x * k for x in a)


def assemble(loadout, info=None):
    """Pieces of the built plane; `info` (a dict) also gets the right wing's gun spots and the body's factor."""
    models, catalog = _load()
    body_id, wings_id = loadout["body"], loadout["wings"]
    factor = catalog[body_id]["visual_scale"] / 2
    battrs, wattrs = models[body_id][0], models[wings_id][0]
    bf, bb, wf, wb = (_vec(battrs.get("WingFront")), _vec(battrs.get("WingBack")), _vec(wattrs.get("RootFront")),
                      _vec(wattrs.get("RootBack")))
    mounts = [_vec(wattrs.get("Mount1")), _vec(wattrs.get("Mount2"))]
    if bf and bb and wf and wb:
        scale = sum(v * v for v in sub(bb, bf)) ** .5 / sum(v * v for v in sub(wb, wf)) ** .5; frm, to = wf, bf
    else:
        scale, frm, to = 1.0, (0, 0, 0), (catalog[body_id].get("wing_shift") or 0, 0, 0)

    def fit_point(p):
        side = -1 if p[0] < 0 else 1
        q = add(to, mul(sub((side * p[0], p[1], p[2]), frm), scale))
        return (side * q[0], q[1], q[2])

    pieces = []
    def put(name, slot, fbx, centre, size): pieces.append(dict(name=name, slot=slot, fbx=str(fbx) if fbx else None, centre=centre, size=size))
    for slot in ("body", "nose", "wings", "tail"):
        for name, pos, size in models[loadout[slot]][1]:
            if slot == "wings": put(name, slot, _fbx(name), mul(fit_point(pos), factor), mul(size, factor * scale))
            else: put(name, slot, _fbx(name), mul(pos, factor), mul(size, factor))

    def top_of(look): return max([p[1] + s[1] / 2 for _, p, s in models["launcher_" + look][1]] + [0])

    def mount(slot, wid):
        pair, side = (slot - 1) // 2, -1 if slot % 2 == 1 else 1
        under = ROOT_UNDER.get(wings_id)
        body_y = under - top_of(wid) if (under and wid and wid != "pellet") else .08
        wing = mounts[pair - 1] if pair > 0 else None
        at = (side * 1.76, body_y, -1.3134) if pair == 0 else (side * wing[0], wing[1], wing[2]) if wing else (side * (3.7 + (pair - 1) * 1.5), .38, -.6)
        return mul(fit_point(at), factor)

    if info is not None:  # booster spot (top y, front z, back z), whether one is fitted or not
        drop = float(battrs.get("BoosterDrop") or 0)
        bb = [(p[1] + s[1] / 2, p[2] - s[2] / 2, p[2] + s[2] / 2) for _, p, s in models["boost_band"][1]]
        info.update(mounts=[mount(4, None), mount(6, None)], factor=factor, wing_scale=scale,
                    booster=((max(b[0] for b in bb) + drop) * factor, min(b[1] for b in bb) * factor, max(b[2] for b in bb) * factor))
    weapons = loadout.get("weapon_mounts") or []
    def extent(wid):
        ps = models["launcher_" + wid][1]
        return min([p[0] - s[0] / 2 for _, p, s in ps] + [0]), max([p[0] + s[0] / 2 for _, p, s in ps] + [0])
    shrinks = {}
    for slot, wid in enumerate(weapons, 1):
        outer = weapons[slot + 1] if slot + 1 < len(weapons) else None
        if wid and outer:
            spacing = abs(mount(slot + 2, None)[0] - mount(slot, None)[0]) / factor
            need = (-extent(wid)[0] + extent(outer)[1]) * scale
            k = min(1, (spacing - NEIGHBOUR_GAP) / max(need, 1e-6))
            shrinks[slot] = min(shrinks.get(slot, 1), k); shrinks[slot + 2] = min(shrinks.get(slot + 2, 1), k)
    for slot, wid in enumerate(weapons, 1):
        if not wid: continue
        side, shrink = (1 if slot % 2 == 1 else -1), shrinks.get(slot, 1)
        for name, at, size in models["launcher_" + wid][1]:
            y = at[1] + (top_of(wid) - at[1]) * (1 - shrink)
            centre = add(mount(slot, wid), mul((side * at[0] * shrink, y, at[2] * shrink), factor * scale))
            put(f"Mount{slot}-{name}", "weapon", _fbx(name, wid), centre, mul(size, factor * shrink * scale))
    boost = loadout.get("utility")
    if boost:
        drop = float(battrs.get("BoosterDrop") or 0)
        for name, pos, size in models[boost][1]:
            put(name, "booster", _fbx(name), mul(add(pos, (0, drop, 0)), factor), mul(size, factor))
    return pieces


def outline(pieces):
    """The points a Mythical skin's joints move to: nose tip, tail end, body box, wing corners seen from above."""
    def box(slot):
        ps = [p for p in pieces if p["slot"] == slot]
        lo = tuple(min(p["centre"][i] - p["size"][i] / 2 for p in ps) for i in range(3))
        hi = tuple(max(p["centre"][i] + p["size"][i] / 2 for p in ps) for i in range(3))
        return lo, hi
    return {s: box(s) for s in ("body", "nose", "wings", "tail") if any(p["slot"] == s for p in pieces)}


if __name__ == "__main__":
    a = sys.argv[1:]
    lo = dict(body=a[0], nose=a[1], wings=a[2], tail=a[3])
    for extra in a[4:]:
        k, v = extra.split("=")
        if k == "weapons": lo["weapon_mounts"] = [w or False for w in v.split(",")]
        if k == "boost": lo["utility"] = v
    ps = assemble(lo)
    for p in ps: print(f"{p['name']:32} {p['slot']:8} {'ok ' if p['fbx'] and Path(p['fbx']).exists() else 'MISSING'} "
                       f"c={tuple(round(v, 2) for v in p['centre'])} s={tuple(round(v, 2) for v in p['size'])}")
    print(outline(ps))
