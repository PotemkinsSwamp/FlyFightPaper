"""Write assets/models/planes/skin-looks.rbxmx: for every skin with a picture, one SurfaceAppearance per printed-sheet
piece copy (ColorMap = the skin's picture, NormalMap = that piece's creases).

Run: python tools/art/skin_looks.py   (after a skin gets a picture in config/looks.json, the copies change, or a shape skin gets pictures in config/skin-shapes.json)
Why a file and not runtime: a script can't set a SurfaceAppearance's maps, and AssetService's runtime builder only
takes pictures loaded into memory (about 4 MB each), too heavy for phones. Rojo syncs this file into
ReplicatedStorage.FlyFightPaper.Assets.SkinLooks; src/client/PlaneLooks.luau clones from it.
"""
import json
from pathlib import Path
from xml.sax.saxutils import escape

ROOT = Path(__file__).resolve().parents[1].parent
looks = json.loads((ROOT / "config/looks.json").read_text())
pieces = json.loads((ROOT / "config/skin-pieces.json").read_text())["pieces"]
shapes = json.loads((ROOT / "config/skin-shapes.json").read_text())["shapes"]  # shape skins: one look, folder <id>/Shape
motion = json.loads((ROOT / "config/skin-motion.json").read_text())["skins"]    # Rares: the still sheet may glow too
pictures = json.loads((ROOT / "config/skin-pictures.json").read_text())["pictures"]


def item(cls, name, body=""):
    return f'<Item class="{cls}"><Properties><string name="Name">{escape(name)}</string>{body}</Properties>'


out = ['<?xml version="1.0" encoding="utf-8"?>\n<roblox version="4">', item("Folder", "SkinLooks")]
count = 0
# One folder per skin: a shape skin with a printed sheet (the crane) keeps its Shape look and its sheet copies together
# (two folders of one name hid the Shape look and the crane drew grey, 2026-11-14).
folders = {}
for skin in looks["skins"]:
    if not skin.get("picture"):
        continue
    glow, mask = motion.get(skin["id"], {}).get("glow"), pictures.get(skin["id"] + "-glow")
    for name, ids in sorted(pieces.items()):
        maps = (f'<Content name="ColorMap"><url>rbxassetid://{skin["picture"]}</url></Content>'
                f'<Content name="NormalMap"><url>rbxassetid://{ids["normal"]}</url></Content>')
        if glow and mask:  # which bits of the sheet glow, its colour and resting strength (PlaneLooks makes it breathe)
            maps += (f'<Content name="EmissiveMaskContent"><uri>rbxassetid://{mask}</uri></Content>'
                     f'<float name="EmissiveStrength">{glow["strength"]}</float>'
                     f'<Color3 name="EmissiveTint"><R>{glow["tint"][0]}</R><G>{glow["tint"][1]}</G><B>{glow["tint"][2]}</B></Color3>')
        folders.setdefault(skin["id"], []).append(item("SurfaceAppearance", name, maps) + "</Item>")
    # A Rare's moving layers, made ahead too (folder <id>/Layers, one Decal a layer): a game script may not set a Decal's
    # glow picture (EmissiveMaskContent needs plugin rights; found in Play 2026-11-16). PlaneLooks clones and moves them.
    decals = []
    for i, layer in enumerate(motion.get(skin["id"], {}).get("layers", []), 1):
        key = f'{skin["id"]}-{layer["name"]}'
        body = (f'<token name="Face">1</token><int name="ZIndex">{i}</int>'  # Face 1 = Top: the only face that draws on a mesh
                f'<Content name="ColorMapContent"><uri>rbxassetid://{pictures[key]}</uri></Content>')
        if layer.get("glow"):  # no glow picture: it glows by its own red
            tint = layer["glow"]["tint"]
            body += (f'<Content name="EmissiveMaskContent"><uri>rbxassetid://{pictures.get(key + "-glow", pictures[key])}</uri></Content>'
                     f'<Color3 name="EmissiveTint"><R>{tint[0]}</R><G>{tint[1]}</G><B>{tint[2]}</B></Color3>')
        decals.append(item("Decal", layer["name"], body) + "</Item>")
    if decals:
        folders[skin["id"]].append(item("Folder", "Layers") + "\n".join(decals) + "</Item>")
for sid, shape in sorted(shapes.items()):
    pics = shape["pictures"]
    maps = "".join(f'<Content name="{key}"><url>rbxassetid://{pics[k]}</url></Content>'
                   for key, k in (("ColorMap", "color"), ("NormalMap", "normal"), ("RoughnessMap", "roughness"),
                                  ("MetalnessMap", "metalness")) if k in pics)
    if "glow" in pics:  # the Dragon's eye: a glow picture, its colour and strength (Studio saves it as a Content <uri>)
        tint, strength = shape["glow"]["tint"], shape["glow"]["strength"]
        maps += (f'<Content name="EmissiveMaskContent"><uri>rbxassetid://{pics["glow"]}</uri></Content>'
                 f'<float name="EmissiveStrength">{strength}</float>'
                 f'<Color3 name="EmissiveTint"><R>{tint[0]}</R><G>{tint[1]}</G><B>{tint[2]}</B></Color3>')
    folders.setdefault(sid, []).append(item("SurfaceAppearance", "Shape", maps) + "</Item>")
    if shape.get("layers"):
        decals = []
        for name, image in shape["layers"].items():
            uri = f"<uri>rbxassetid://{image}</uri>"
            maps = (f'<Content name="ColorMapContent">{uri}</Content>'
                    f'<Content name="EmissiveMaskContent">{uri}</Content>'
                    '<token name="Face">1</token>')
            decals.append(item("Decal", name, maps) + "</Item>")
        folders[sid].append(item("Folder", "Layers") + "".join(decals) + "</Item>")
for sid, items in folders.items():
    out.append(item("Folder", sid) + "\n".join(items) + "</Item>")
    count += len(items)
out.append("</Item>\n</roblox>\n")
(ROOT / "assets/models/planes/skin-looks.rbxmx").write_text("\n".join(out), encoding="utf-8")
print("skin-looks.rbxmx:", count, "looks")
