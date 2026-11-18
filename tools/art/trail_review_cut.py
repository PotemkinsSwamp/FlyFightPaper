"""Assemble the five pairs rendered with trail_preview.py -- <trail>:A and :B."""
from pathlib import Path
import subprocess
import tempfile

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / ".planning/skins/trails/legendary-review"
PAIRS = [
    ("smoke_bomb", "Ninja", "Brushed silver", "Polished edges"),
    ("backfire", "Hot Rod", "Blue-core flame", "Flame pinstripes"),
    ("silver_chaff", "Stealth", "Violet sweep", "Twin reflections"),
    ("photo_finish", "Race Car", "Burnout", "Twin tire tracks"),
    ("water_spray", "Shark Jet", "Bite in the spray", "Trailing teeth"),
]


def ffmpeg(*args):
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", *map(str, args)], check=True)


def captions(path, skin, a, b):
    sheet = Image.new("RGB", (1920, 80), (242, 232, 213))
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.truetype("trebucbd.ttf", 34)
    for index, (letter, name) in enumerate((("A", a), ("B", b))):
        center = (480 + 960 * index, 40)
        label = f"{skin}   {letter} / {name}"
        left, top, right, bottom = draw.textbbox(center, label, font=font, anchor="mm")
        assert left >= index * 960 + 32 and right <= (index + 1) * 960 - 32 and top >= 8 and bottom <= 72
        draw.text(center, label, font=font, anchor="mm", fill=(42, 32, 28))
    draw.line((960, 12, 960, 68), fill=(178, 162, 140), width=2)
    sheet.save(path)


def main():
    with tempfile.TemporaryDirectory() as work:
        work = Path(work)
        sequence = []
        for trail, skin, a, b in PAIRS:
            strip = work / "captions.png"
            captions(strip, skin, a, b)
            output = OUTPUT / f"{trail}-comparison.mp4"
            ffmpeg("-i", OUTPUT / f"{trail}-A.mp4", "-i", OUTPUT / f"{trail}-B.mp4",
                   "-loop", 1, "-framerate", 24, "-i", strip,
                   "-filter_complex", "[0:v]scale=960:540[a];[1:v]scale=960:540[b];[a][b]hstack=shortest=1[views];[2:v][views]vstack=shortest=1",
                   "-c:v", "libx264", "-crf", 17, "-pix_fmt", "yuv420p", "-movflags", "+faststart", output)
            sequence.append(f"file '{output.as_posix()}'\n")
        playlist = work / "pairs.txt"
        playlist.write_text("".join(sequence), encoding="utf-8")
        ffmpeg("-f", "concat", "-safe", 0, "-i", playlist, "-c", "copy", "-movflags", "+faststart",
               OUTPUT / "legendary-comparison.mp4")


if __name__ == "__main__":
    main()
