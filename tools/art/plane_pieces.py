"""Write assets/models/planes/pieces.rbxmx: every plane part and booster, the weapons and the team stickers.

Run: python tools/art/plane_pieces.py
Reads planes/classic/parts.json + planes/set/parts.json (sizes, slot pivots), planes/stickers/stickers.json and
planes/uploads.json (MeshIds).
Models are named after the catalog part id; children are MeshParts named after their FBX stem, positioned in the
assembled plane frame. Weapons (launcher_<catalog id>) come from tools/art/weapons.py (assets/models/toys/weapon-*/
pieces.json + upload.json), placed relative to the left slot's centre; each piece carries a Role attribute (and Pivot/
Axis for moving parts) for the firing animations. Aircraft.luau clones them.
"""
import base64
import json
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PLANES = ROOT / "assets/models/planes"
OUT = PLANES / "pieces.rbxmx"

PARTS = {"body_standard": ["body-paper"], "nose_0": ["nose-paper", "nose-accent"],
         "wings_0": ["wings-paper", "wings-accent", "wings-sticker-left", "wings-sticker-right"],
         "tail_0": ["tail-paper", "tail-accent"]}
# catalog weapon id -> assets/models/toys/weapon-<folder>
WEAPONS = {"pellet": "pellet", "staple": "staple", "rubber": "gatling-b", "paperclip": "paperclip",
           "eraser": "eraser", "pencil": "pencil-b"}
TUBE_TOP = .41     # a hanging weapon's top sits where plane A's pellet tube top was, just under the wing
WING_TOP = .63     # a weapon mounted on top (the paperclip rails) sits on the wing's upper face
BODY_EDGE = 1.32   # body half-width + a little: weapons on the body-side slot (x 1.76) are pushed out past it
MATERIALS = {"SmoothPlastic": 272, "Metal": 1088}

parts = json.loads((PLANES / "classic/parts.json").read_text(encoding="utf-8"))
stickers = json.loads((PLANES / "stickers/stickers.json").read_text(encoding="utf-8"))
meshes = json.loads((PLANES / "uploads.json").read_text(encoding="utf-8"))["meshes"]
exports = {e["object"]: e for e in parts["exports"]}
# The other parts and boosters (tools/art/plane_set.py): same frame and slot pivots; added once their meshes are read.
SET = json.loads((PLANES / "set/parts.json").read_text(encoding="utf-8"))
BOOSTER_DROP = {b: str(round(v[1] - SET["booster_body_pivots"]["body_standard"][1], 6)) for b, v in SET["booster_body_pivots"].items()}
for e in SET["exports"]:
    exports[e["object"]] = e
    if e["object"] in meshes: PARTS.setdefault(e["part"], []).append(e["object"])
# Left/right halves (tools/art/split_halves.py, named <stem>-L/-R): wings so a wide body slides them out to its sides;
# body, nose, tail and booster so a free-for-all plane is red on the left and blue on the right.
for e in json.loads((PLANES / "halves.json").read_text(encoding="utf-8"))["exports"]:
    exports[e["object"]] = e
for part, stems in PARTS.items():
    PARTS[part] = [h for s in stems for h in ((s + "-L", s + "-R") if s + "-L" in exports else (s,))]
# Team sticker spots on the other wings (Alan, 2026-10-13: every plane shows its team mark). Each is a flat, clear
# patch of paper on the wing's top, found by casting rays down onto the wing meshes in Blender (the same search put
# Classic's spot within .04 studs of its modelled one). Swept Wings' band is too narrow for a full sticker: 75%.
# They reuse Classic's placeholder meshes; Aircraft.paint swaps in the team's square/circle at the placeholder's size.
STICKER_SPOTS = {"wings_1": (2.5, .0345, -.6, .75), "wings_2": (3.2, .0424, 1.2, 1), "wings_3": (3.2, .0493, 1.2, 1),
                 "wings_4": (3.2, .0526, 1.2, 1), "wings_5": (2.9, .0447, .1, 1)}
for wing, (x, y, z, scale) in STICKER_SPOTS.items():
    for side, sign in (("left", -1), ("right", 1)):
        model = exports[f"wings-sticker-{side}"]
        exports[f"{wing}-sticker-{side}"] = dict(model, center_offset_from_slot=[sign * x, y, z], mesh=meshes[model["object"]],
                                                 size=[round(model["size"][0] * scale, 4), model["size"][1], round(model["size"][2] * scale, 4)])
        PARTS[wing].append(f"{wing}-sticker-{side}")


def attributes(**values):
    """Roblox AttributesSerialize blob for string attributes."""
    blob = struct.pack("<I", len(values))
    for key, value in values.items():
        k, v = key.encode(), value.encode()
        blob += struct.pack("<I", len(k)) + k + b"\x02" + struct.pack("<I", len(v)) + v
    return base64.b64encode(blob).decode()


def mesh_part(name, size, position, color, region=None, mesh=None, attrs=None, material="SmoothPlastic", paint=""):
    r, g, b = color
    x, y, z = position
    sx, sy, sz = size
    xml = f"""    <Item class="MeshPart" referent="{name}">
      <Properties>
        <string name="Name">{name}</string>
"""
    if region or attrs:
        xml += f'        <BinaryString name="AttributesSerialize">{attributes(**(attrs or dict(Region=region)))}</BinaryString>\n'
    xml += f"""        <bool name="Anchored">true</bool>
        <bool name="CanCollide">false</bool>
        <bool name="CanTouch">false</bool>
        <bool name="CanQuery">false</bool>
        <bool name="CastShadow">true</bool>
        <token name="CollisionFidelity">2</token>
        <token name="RenderFidelity">0</token>
        <token name="Material">{MATERIALS[material]}</token>
        <Color3uint8 name="Color3uint8">{0xFF000000 | r << 16 | g << 8 | b}</Color3uint8>
        <Content name="MeshId">
          <url>rbxassetid://{mesh or meshes[name]}</url>
        </Content>
        <Vector3 name="size">
          <X>{sx}</X>
          <Y>{sy}</Y>
          <Z>{sz}</Z>
        </Vector3>
        <CoordinateFrame name="CFrame">
          <X>{x}</X>
          <Y>{y}</Y>
          <Z>{z}</Z>
          <R00>-1</R00>
          <R01>0</R01>
          <R02>0</R02>
          <R10>0</R10>
          <R11>1</R11>
          <R12>0</R12>
          <R20>0</R20>
          <R21>0</R21>
          <R22>-1</R22>
        </CoordinateFrame>
        <Vector3 name="InitialSize">
          <X>{sx}</X>
          <Y>{sy}</Y>
          <Z>{sz}</Z>
        </Vector3>
      </Properties>{paint}
    </Item>
"""
    return xml


def container(cls, name, children, attrs=None):
    blob = f'\n      <BinaryString name="AttributesSerialize">{attributes(**attrs)}</BinaryString>' if attrs else ""
    return f"""  <Item class="{cls}" referent="{name}">
    <Properties>
      <string name="Name">{name}</string>{blob}
    </Properties>
{children}  </Item>
"""


def piece(stem):
    e = exports[stem]
    position = [round(e["slot_pivot"][i] + e["center_offset_from_slot"][i], 6) for i in range(3)]
    return mesh_part(stem, e["size"], position, e["suggested_color3_255"], e["region"], mesh=e.get("mesh"))


def weapon(folder):
    d = ROOT / "assets/models/toys" / f"weapon-{folder}"
    man = json.loads((d / "pieces.json").read_text(encoding="utf-8"))
    up = json.loads((d / "upload.json").read_text(encoding="utf-8"))
    mount = man["mount"]["point"]
    top = man["mount"]["side"] == "top"
    lift = (TUBE_TOP if top else WING_TOP) - mount[1]
    out = -max(0, BODY_EDGE - (1.76 - man["size"][0] / 2))      # left slot: outward is -X
    shift = [out - mount[0], lift, -mount[2]]
    paint = (f"""<Item class="SurfaceAppearance"><Properties><string name="Name">Paint</string>
        <Content name="ColorMap"><url>rbxassetid://{up['color']}</url></Content>
        <Content name="NormalMap"><url>rbxassetid://{up['normal']}</url></Content>
        <Content name="RoughnessMap"><url>rbxassetid://{up['roughness']}</url></Content></Properties></Item>"""
             if "color" in up else "")
    xml = ""
    for row in man["pieces"]:
        at = lambda v: [round(v[i] + shift[i], 4) for i in range(3)]
        attrs = dict(Role=row["role"])
        for key in ("pivot", "axis"):
            if key in row: attrs[key.title()] = ",".join(str(v) for v in (at(row[key]) if key == "pivot" else row[key]))
        xml += mesh_part(row["piece"], row["size"], at(row["centre"]), row.get("color", [255, 255, 255]), attrs=attrs,
                         mesh=up["meshes"][row["piece"]]["mesh"], material=row.get("material", "SmoothPlastic"),
                         paint=paint if row["textured"] else "")
    # Shots leave from the front of what the weapon fires (or spins), in the left slot's frame.
    shot = next((r for r in man["pieces"] if r["role"] in ("fire", "drop", "spin")), None)
    muzzle = at([shot["centre"][0], shot["centre"][1], -man["size"][2] / 2] if shot else [0, 0, -man["size"][2] / 2])
    return xml, ",".join(str(v) for v in muzzle)


# Wing attachment points (Alan, 2026-10-13; Aircraft.wingFit), right side, assembled frame before scale. Measured in
# Blender by casting rays at the meshes: a body's points are the front and back ends of its flat side wall at mid
# height; a wing's are its root's front and back corners just outside the centre saddle (x 1.32, root middle y .83).
# Only the cardboard box has points so far (Alan: the other bodies attach fine as they are).
# Swept Wings' root is only 3.4 long, so its back point sits 5.6 behind the front (the box wall's length): it keeps its
# size instead of growing 1.6x.
WING_WALLS = {"body_heavy": ((2.6, .62, -1.92), (2.6, .62, 3.68))}
ROOTS = {"wings_0": 4.56, "wings_1": 3.42, "wings_2": 4.15, "wings_3": 5.12, "wings_4": 4.35, "wings_5": 4.46}
point = lambda v: ",".join(str(n) for n in v)
ATTACH = {model: dict(WingFront=point(front), WingBack=point(back)) for model, (front, back) in WING_WALLS.items()}
# Under-wing gun pairs (Alan, 2026-10-13: same spot on every wing): 0.8 behind the wing's own leading edge at x 3.7
# and 5.2 (one fixed spot left swept wings' guns in mid-air), hung as far below the wing as on Classic.
# Measured per wing: (leading edge z, underside y) at x 3.7 and 5.2.
EDGES = {"wings_0": ((.29, .816), (1.85, .839)), "wings_1": ((.67, .815), (2.47, .838)), "wings_2": ((-2.03, .81), (-1.92, .829)),
         "wings_3": ((.66, .816), (2.44, .839)), "wings_4": ((-1.78, .709), (-1.52, .734)), "wings_5": ((-1.85, .736), (-1.65, .759))}
CLASSIC_UNDER = (.816, .839)
for model, back in ROOTS.items():
    ATTACH[model] = dict(RootFront=point((1.32, .83, -2.18)), RootBack=point((1.32, .83, back)))
    for pair, (x, (edge, under)) in enumerate(zip((3.7, 5.2), EDGES[model]), 1):
        ATTACH[model][f"Mount{pair}"] = point((x, round(.38 + under - CLASSIC_UNDER[pair - 1], 3), round(edge + .8, 3)))
for model, drop in BOOSTER_DROP.items(): ATTACH.setdefault(model, {})["BoosterDrop"] = drop
# Body models also carry how far below the standard spot their booster hangs (boosters are placed for the standard body).
body = "".join(container("Model", model, "".join(piece(s) for s in stems), ATTACH.get(model)) for model, stems in PARTS.items())
for cid, folder in WEAPONS.items():
    xml, muzzle = weapon(folder)
    body += container("Model", f"launcher_{cid}", xml, dict(Muzzle=muzzle))
sticker_parts = "".join(mesh_part(e["object"], e["size"], (0, 0, 0), e["default_color3_255"]) for e in stickers["exports"])
body += container("Folder", "Stickers", sticker_parts)

xml = "<?xml version='1.0' encoding='utf-8'?>\n<roblox version=\"4\">\n" + container("Folder", "AircraftPieces", body) + "</roblox>\n"
with open(OUT, "w", encoding="utf-8", newline="\r\n") as f:
    f.write(xml)
print(f"wrote {OUT.relative_to(ROOT)}: models {', '.join(list(PARTS) + ['launcher_' + w for w in WEAPONS])}, stickers {', '.join(e['object'] for e in stickers['exports'])}")
