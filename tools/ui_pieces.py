"""Prepare and upload one menu screen's art pieces, then print the Luau ids.

    python tools/ui_pieces.py mainmenu            # prepare only (writes assets/ui/<screen>/ready/)
    python tools/ui_pieces.py mainmenu --upload   # also upload new pieces through tools/upload_texture.py

Pieces come from assets/ui/<screen>/source/*.png. background.png is cut into a 2x2 grid (bg-1..bg-4);
every other piece is trimmed to its visible pixels. Everything is shrunk to Roblox's 1024-pixel image limit.
Upload records go to assets/ui/<screen>/uploads/<piece>.json; existing records are reused, never re-uploaded.
"""
from pathlib import Path
import json
import subprocess
import sys
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
CREATOR = "52064999"
LIMIT = 1024


def shrink(image):
    scale = min(1.0, LIMIT / max(image.size))
    return image if scale == 1.0 else image.resize((round(image.width * scale), round(image.height * scale)), Image.LANCZOS)


def prepare(screen):
    source, ready = ROOT / "assets/ui" / screen / "source", ROOT / "assets/ui" / screen / "ready"
    ready.mkdir(parents=True, exist_ok=True)
    names = []
    for path in sorted(source.glob("*.png")):
        image = Image.open(path).convert("RGBA")
        if path.stem == "background":
            image = image.resize((1920, 1080), Image.LANCZOS)
            for i in range(4):
                x, y = (i % 2) * 960, (i // 2) * 540
                image.crop((x, y, x + 960, y + 540)).save(ready / f"bg-{i + 1}.png")
                names.append(f"bg-{i + 1}")
        else:
            box = image.getchannel("A").getbbox()
            shrink(image.crop(box) if box else image).save(ready / f"{path.stem}.png")
            names.append(path.stem)
    return ready, names


def upload(screen, ready, names):
    records = ROOT / "assets/ui" / screen / "uploads"
    records.mkdir(parents=True, exist_ok=True)
    ids = {}
    for name in names:
        record = records / f"{name}.json"
        if not record.exists():
            subprocess.run([sys.executable, str(ROOT / "tools/upload_texture.py"), str(ready / f"{name}.png"),
                            "--creator", CREATOR, "--name", f"FlyFightPaper {screen} {name}", "--output", str(record)])
        if not record.exists():
            continue  # the upload itself failed (the uploader printed why); the next run tries it again
        # ponytail: a piece Roblox is still processing gets an empty id here; check its saved operation later.
        operation = json.loads(record.read_text())
        ids[name] = operation.get("response", {}).get("assetId", "")
    return ids


if __name__ == "__main__":
    screen = sys.argv[1]
    ready, names = prepare(screen)
    for name in names:
        print(name, Image.open(ready / f"{name}.png").size)
    if "--upload" in sys.argv:
        for name, asset in upload(screen, ready, names).items():
            print(f'{name} = "rbxassetid://{asset}"')
