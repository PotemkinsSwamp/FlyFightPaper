"""Assemble the five pairs rendered with trail_preview.py -- <trail>:A and :B."""
from pathlib import Path
import subprocess
import sys
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


def compare_pair(first, second, label, left, right, output, strip):
    captions(strip, label, left, right)
    ffmpeg("-i", first, "-i", second, "-loop", 1, "-framerate", 24, "-i", strip,
           "-filter_complex", "[0:v]scale=960:540[a];[1:v]scale=960:540[b];[a][b]hstack=shortest=1[views];[2:v][views]vstack=shortest=1",
           "-c:v", "libx264", "-crf", 17, "-pix_fmt", "yuv420p", "-movflags", "+faststart", output)


def main():
    with tempfile.TemporaryDirectory() as work:
        work = Path(work)
        strip = work / "captions.png"
        if sys.argv[1:] == ["continuity"]:
            pairs = (
                ("Race Car", "Steel grains", "Grinding sparks", "photo_finish-scrape", "photo_finish-grind"),
                ("Stealth", "Air pockets", "Continuous wake", "silver_chaff-cloak", "silver_chaff-stream"),
            )
            segments = []
            for skin, old, new, first, second in pairs:
                segment = work / (first + ".mp4")
                compare_pair(OUTPUT/(first+".mp4"), OUTPUT/(second+".mp4"), skin, old, new, segment, strip)
                segments.append(f"file '{segment.as_posix()}'\n")
            playlist = work / "shots.txt"
            playlist.write_text("".join(segments), encoding="utf-8")
            ffmpeg("-f", "concat", "-safe", 0, "-i", playlist, "-c", "copy", "-movflags", "+faststart",
                   OUTPUT / "sparks-and-cloak-comparison.mp4")
            return
        if sys.argv[1:] == ["shark"]:
            compare_pair(OUTPUT/"water_spray-breakers.mp4",OUTPUT/"water_spray-jet.mp4","Shark Jet",
                         "Breaking wave","Rolling jet",OUTPUT/"shark-wake.mp4",strip)
            return
        if sys.argv[1:] == ["sparks"]:
            compare_pair(OUTPUT/"photo_finish-scrape.mp4", OUTPUT/"photo_finish-skip.mp4", "Race Car",
                         "Steel shower", "Skipping sparks", OUTPUT/"racing-sparks.mp4", strip)
            return
        sequence = []
        for trail, skin, a, b in PAIRS:
            output = OUTPUT / f"{trail}-comparison.mp4"
            compare_pair(OUTPUT / f"{trail}-A.mp4", OUTPUT / f"{trail}-B.mp4", skin, a, b, output, strip)
            sequence.append(f"file '{output.as_posix()}'\n")
        playlist = work / "pairs.txt"
        playlist.write_text("".join(sequence), encoding="utf-8")
        ffmpeg("-f", "concat", "-safe", 0, "-i", playlist, "-c", "copy", "-movflags", "+faststart",
               OUTPUT / "legendary-comparison.mp4")


if __name__ == "__main__":
    main()
