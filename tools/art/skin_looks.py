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


def item(cls, name, body=""):
    return f'<Item class="{cls}"><Properties><string name="Name">{escape(name)}</string>{body}</Properties>'


out = ['<?xml version="1.0" encoding="utf-8"?>\n<roblox version="4">', item("Folder", "SkinLooks")]
count = 0
for skin in looks["skins"]:
    if not skin.get("picture"):
        continue
    out.append(item("Folder", skin["id"]))
    for name, ids in sorted(pieces.items()):
        maps = (f'<Content name="ColorMap"><url>rbxassetid://{skin["picture"]}</url></Content>'
                f'<Content name="NormalMap"><url>rbxassetid://{ids["normal"]}</url></Content>')
        out.append(item("SurfaceAppearance", name, maps) + "</Item>")
        count += 1
    out.append("</Item>")
for sid, shape in sorted(shapes.items()):
    pics = shape["pictures"]
    maps = "".join(f'<Content name="{key}"><url>rbxassetid://{pics[k]}</url></Content>'
                   for key, k in (("ColorMap", "color"), ("NormalMap", "normal"), ("RoughnessMap", "roughness")))
    out.append(item("Folder", sid) + item("SurfaceAppearance", "Shape", maps) + "</Item></Item>")
    count += 1
out.append("</Item>\n</roblox>\n")
(ROOT / "assets/models/planes/skin-looks.rbxmx").write_text("\n".join(out), encoding="utf-8")
print("skin-looks.rbxmx:", count, "looks")
