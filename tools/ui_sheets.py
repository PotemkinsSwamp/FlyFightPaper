"""Menus before Skip in fewer, smaller files (docs/plan/LOAD-PLAN.md): each piece shrunk to the size it is drawn at,
then the small ones packed into a few 1024 sheets.

    python tools/ui_sheets.py            # build assets/ui/sheets/ready/ + layout.json + contact.png + compare.png (look first)
    python tools/ui_sheets.py --upload   # upload them (Alan's go), then write src/first/UISheets.luau

Shrinking: sizes.json holds each piece's largest drawn size on a 1080-tall screen (measured 2026-10-25 in Studio Play
from every label's AbsoluteSize, menus opened with the DevScreen attribute). A piece keeps ROOM x that: 1.0, sharp on
phones and 1080p screens, a little soft on 1440p ones (Alan 2026-10-25: everything faster), shrunk only when that
saves 15% or more. Packing: each piece's edge pixels are repeated PAD px
outwards so a shrunk drawing never picks up a neighbour. Not packed: the loading screen's own pieces (LoadingFirst
fetches them first, alone; they still shrink, as files of their own). Left alone: background tiles (drawn full size),
9-slice pieces (their SliceCenter is in the piece's own pixels) and the guide-line dash (a Beam texture, not a label).
In the game, first/LoadingFirst points every label showing a changed piece at its new file and spot (ImageRectOffset/Size).
"""
from pathlib import Path
import json, re, subprocess, sys
from PIL import Image
import rectpack  # pip package (free)

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/ui/sheets"
SIZE, PAD, ROOM = 1024, 8, 1.0
MENUS = ("mainmenu", "results", "tutorial", "trainingboard", "hangar", "settings", "ingame", "hud", "deskMenu", "hangarShelf")
FIRST = {"mainmenu/title", "mainmenu/plane", "results/xp-card", "results/xp-bar-fill", "results/xp-bar-frame"}  # loading screen
ALONE = {"ingame/tape-label", "hangarshelf/outline", "tutorial/frame-box", "tutorial/tag", "tutorial/dash"}  # 9-slice, Beam


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
            if not png.stem.startswith("bg-") and key not in ALONE:
                chosen[asset] = (png, key)
    return chosen


def shrunk(png, key, sizes):
    piece = Image.open(png).convert("RGBA")
    if key in sizes:
        w, h = sizes[key]
        scale = min(1.0, max(w * ROOM / piece.width, h * ROOM / piece.height))
        if scale < 0.85:
            return piece.resize((max(8, round(piece.width * scale)), max(8, round(piece.height * scale))), Image.LANCZOS), True
    return piece, False


def build():
    sizes = json.loads((OUT / "sizes.json").read_text())
    (OUT / "ready").mkdir(parents=True, exist_ok=True)
    for old in [*(OUT / "ready").glob("*.png"), *(OUT / "uploads").glob("*.json")]:
        old.unlink()  # a new build is new files: its old upload records stay in git history
    images, layout, packed = {}, {}, {}
    packer = rectpack.newPacker(rotation=False, pack_algo=rectpack.MaxRectsBssf, sort_algo=rectpack.SORT_AREA)
    for asset, (png, key) in pieces().items():
        piece, smaller = shrunk(png, key, sizes)
        images[asset] = piece
        if key not in FIRST and max(piece.size) + 2 * PAD <= SIZE:
            packed[asset] = png
            packer.add_rect(piece.width + 2 * PAD, piece.height + 2 * PAD, asset)
        elif smaller:  # a file of its own, just smaller
            name = key.replace("/", "-")
            piece.save(OUT / "ready" / f"{name}.png", optimize=True)
            layout[asset] = {"file": name, "x": 0, "y": 0, "w": piece.width, "h": piece.height, "piece": png.relative_to(ROOT).as_posix()}
    for _ in range(len(packed)):
        packer.add_bin(SIZE, SIZE)
    packer.pack()
    assert sum(len(b) for b in packer) == len(packed), "a piece didn't fit"
    thumbs = []
    for n, sheet_bin in enumerate(packer, 1):
        sheet = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        for r in sheet_bin:
            piece = images[r.rid]
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
            layout[r.rid] = {"file": f"sheet-{n}", "x": x, "y": y, "w": w, "h": h, "piece": packed[r.rid].relative_to(ROOT).as_posix()}
        sheet.save(OUT / "ready" / f"sheet-{n}.png", optimize=True)
        thumbs.append(sheet)
    (OUT / "layout.json").write_text(json.dumps(layout, indent=1), encoding="utf-8")
    # Contact sheet on grey (see-through shows): look at every sheet before any upload (lessons: moderation).
    cols = 4
    contact = Image.new("RGB", (cols * 520, -(-len(thumbs) // cols) * 520), (128, 128, 128))
    for i, sheet in enumerate(thumbs):
        contact.paste(sheet.resize((512, 512)), (i % cols * 520 + 4, i // cols * 520 + 4), sheet.resize((512, 512)))
    contact.save(OUT / "contact.png")
    compare(sizes, images)
    singles = sum(not p["file"].startswith("sheet") for p in layout.values())
    print(f"{len(layout)} pieces -> {len(thumbs)} sheets + {singles} smaller files of their own in {OUT / 'ready'}")


def compare(sizes, images):
    """compare.png: the most-shrunk pieces drawn at their screen size (1080 and 1440 tall), old file left, new right."""
    rows = []
    for asset, (png, key) in pieces().items():
        old = Image.open(png).convert("RGBA")
        if key in sizes and images[asset].size != old.size:
            rows.append((images[asset].width / old.width, key, old, images[asset]))
    tiles = []
    for _, key, old, new in sorted(rows)[:8]:
        w, h = sizes[key]
        for f in (1.0, 1.33):
            size = (max(1, round(w * f)), max(1, round(h * f)))
            pair = Image.new("RGBA", (size[0] * 2 + 30, size[1] + 10), (205, 180, 140, 255))
            pair.alpha_composite(old.resize(size, Image.BILINEAR), (5, 5))
            pair.alpha_composite(new.resize(size, Image.BILINEAR), (size[0] + 25, 5))
            tiles.append(pair)
    sheet = Image.new("RGBA", (max(t.width for t in tiles) * 2 + 30, sum(max(a.height, b.height) + 4 for a, b in zip(tiles[::2], tiles[1::2])) + 20), (90, 90, 90, 255))
    y = 10
    for a, b in zip(tiles[::2], tiles[1::2]):
        sheet.alpha_composite(a, (10, y))
        sheet.alpha_composite(b, (a.width + 20, y))
        y += max(a.height, b.height) + 4
    sheet.save(OUT / "compare.png")


def upload():
    layout = json.loads((OUT / "layout.json").read_text())
    ids = {}
    (OUT / "uploads").mkdir(exist_ok=True)
    for name in sorted({p["file"] for p in layout.values()}):
        record = OUT / "uploads" / f"{name}.json"
        if not record.exists():
            subprocess.run([sys.executable, str(ROOT / "tools/upload_texture.py"), str(OUT / "ready" / f"{name}.png"),
                            "--creator", "52064999", "--name", f"FlyFightPaper menu {name}", "--output", str(record)], check=True)
        ids[name] = json.loads(record.read_text())["response"]["assetId"]
    lines = ["-- Menu sheets (tools/ui_sheets.py writes this file): piece id -> {file id, x, y, w, h}. first/LoadingFirst draws",
             "-- each changed piece from its new file (a sheet, or a smaller copy), so the menus are fewer, smaller files.", "return {"]
    for asset, p in sorted(layout.items(), key=lambda kv: (kv[1]["file"], kv[0])):
        lines.append(f'\t["rbxassetid://{asset}"] = {{ "rbxassetid://{ids[p["file"]]}", {p["x"]}, {p["y"]}, {p["w"]}, {p["h"]} }}, -- {p["piece"]}')
    (ROOT / "src/first/UISheets.luau").write_text("\n".join(lines + ["}", ""]), encoding="utf-8")
    print("wrote src/first/UISheets.luau")


if __name__ == "__main__":
    upload() if "--upload" in sys.argv else build()
