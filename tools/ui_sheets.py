"""Pack the menus' small pieces into a few 1024 sheets: fewer files before Skip, same pixels (docs/plan/LOAD-PLAN.md).

    python tools/ui_sheets.py            # build assets/ui/sheets/ready/sheet-N.png + layout.json + contact.png (look first)
    python tools/ui_sheets.py --upload   # upload the sheets (Alan's go), then write src/first/UISheets.luau

Each piece is copied in pixel for pixel, with its edge pixels repeated PAD px outwards so a shrunk drawing never picks
up a neighbour. Left out: background tiles (already full files), the loading screen's own pieces (LoadingFirst fetches
them first, alone), pieces drawn with 9-slice (their SliceCenter is in the piece's own pixels) and pieces too big.
In the game, first/LoadingFirst points every label showing a packed piece at its sheet (ImageRectOffset/Size).
"""
from pathlib import Path
import json, re, subprocess, sys
from PIL import Image
import rectpack  # pip package (free)

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/ui/sheets"
SIZE, PAD = 1024, 8
MENUS = ("mainmenu", "results", "tutorial", "trainingboard", "hangar", "settings", "ingame", "hud", "deskMenu", "hangarShelf")
SKIP = {"mainmenu/title", "mainmenu/plane", "results/xp-card", "results/xp-bar-fill", "results/xp-bar-frame",  # loading screen
        "ingame/tape-label", "hangarshelf/outline", "tutorial/frame-box", "tutorial/tag"}  # 9-slice


def pieces():
    files = {}
    for record in ROOT.glob("assets/ui/*/uploads/*.json"):
        files[json.loads(record.read_text())["response"]["assetId"]] = record.parent.parent / "ready" / (record.stem + ".png")
    text = (ROOT / "src/first/UIAssets.luau").read_text(encoding="utf-8")
    chosen = {}
    for block in re.split(r"\n\t(?=\w+ = \{)", text):
        name = re.match(r"(\w+) = \{", block)
        if not name or name.group(1) not in MENUS:
            continue
        for asset in re.findall(r"rbxassetid://(\d+)", block):
            png = files[asset]
            key = f"{png.parent.parent.name}/{png.stem}"
            w, h = Image.open(png).size
            if not png.stem.startswith("bg-") and key not in SKIP and max(w, h) + 2 * PAD <= SIZE:
                chosen[asset] = png
    return chosen


def build():
    chosen = pieces()
    packer = rectpack.newPacker(rotation=False, pack_algo=rectpack.MaxRectsBssf, sort_algo=rectpack.SORT_AREA)
    for asset, png in chosen.items():
        w, h = Image.open(png).size
        packer.add_rect(w + 2 * PAD, h + 2 * PAD, asset)
    for _ in range(len(chosen)):
        packer.add_bin(SIZE, SIZE)
    packer.pack()
    assert sum(len(b) for b in packer) == len(chosen), "a piece didn't fit"
    (OUT / "ready").mkdir(parents=True, exist_ok=True)
    layout, thumbs = {}, []
    for n, sheet_bin in enumerate(packer, 1):
        sheet = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        for r in sheet_bin:
            piece = Image.open(chosen[r.rid]).convert("RGBA")
            w, h = piece.size
            x, y = r.x + PAD, r.y + PAD
            # Edge pixels repeated outwards: stretch the piece over the padded box, then the exact piece on top.
            sheet.paste(piece.resize((w + 2 * PAD, h + 2 * PAD), Image.NEAREST), (r.x, r.y))
            sheet.paste(piece.crop((0, 0, w, 1)).resize((w, PAD)), (x, r.y))
            sheet.paste(piece.crop((0, h - 1, w, h)).resize((w, PAD)), (x, y + h))
            sheet.paste(piece.crop((0, 0, 1, h)).resize((PAD, h)), (r.x, y))
            sheet.paste(piece.crop((w - 1, 0, w, h)).resize((PAD, h)), (x + w, y))
            sheet.paste(piece, (x, y))
            assert sheet.crop((x, y, x + w, y + h)).tobytes() == piece.tobytes()  # pixel for pixel
            layout[r.rid] = {"sheet": n, "x": x, "y": y, "w": w, "h": h, "piece": chosen[r.rid].relative_to(ROOT).as_posix()}
        sheet.save(OUT / "ready" / f"sheet-{n}.png", optimize=True)
        thumbs.append(sheet)
    (OUT / "layout.json").write_text(json.dumps(layout, indent=1), encoding="utf-8")
    # Contact sheet on grey (see-through shows): look at every sheet before any upload (lessons: moderation).
    cols = 4
    contact = Image.new("RGB", (cols * 520, -(-len(thumbs) // cols) * 520), (128, 128, 128))
    for i, sheet in enumerate(thumbs):
        contact.paste(sheet.resize((512, 512)), (i % cols * 520 + 4, i // cols * 520 + 4), sheet.resize((512, 512)))
    contact.save(OUT / "contact.png")
    print(f"{len(chosen)} pieces -> {len(thumbs)} sheets in {OUT / 'ready'}")


def upload():
    layout = json.loads((OUT / "layout.json").read_text())
    ids = {}
    (OUT / "uploads").mkdir(exist_ok=True)
    for n in sorted({p["sheet"] for p in layout.values()}):
        record = OUT / "uploads" / f"sheet-{n}.json"
        if not record.exists():
            subprocess.run([sys.executable, str(ROOT / "tools/upload_texture.py"), str(OUT / "ready" / f"sheet-{n}.png"),
                            "--creator", "52064999", "--name", f"FlyFightPaper menu sheet {n}", "--output", str(record)], check=True)
        ids[n] = json.loads(record.read_text())["response"]["assetId"]
    lines = ["-- Menu sheets (tools/ui_sheets.py writes this file): piece id -> {sheet id, x, y, w, h}. first/LoadingFirst",
             "-- draws each packed piece from its sheet, so the menus are a few files, not a hundred.", "return {"]
    for asset, p in sorted(layout.items(), key=lambda kv: (kv[1]["sheet"], kv[0])):
        lines.append(f'\t["rbxassetid://{asset}"] = {{ "rbxassetid://{ids[p["sheet"]]}", {p["x"]}, {p["y"]}, {p["w"]}, {p["h"]} }}, -- {p["piece"]}')
    (ROOT / "src/first/UISheets.luau").write_text("\n".join(lines + ["}", ""]), encoding="utf-8")
    print("wrote src/first/UISheets.luau")


if __name__ == "__main__":
    upload() if "--upload" in sys.argv else build()
