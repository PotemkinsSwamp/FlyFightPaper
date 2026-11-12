"""Design checks for a screenshot or two colours (design-theory skill).

  python .claude/skills/design-theory/contrast.py 240,225,208 219,210,231   -> contrast ratio (WCAG)
  python .claude/skills/design-theory/contrast.py shot.png                  -> shot-grey.png and shot-squint.png
  python .claude/skills/design-theory/contrast.py shot.png 120,80 400,210   -> ratio between the colours at two pixels

Grey = value only (does it still read without colour?). Squint = grey and blurred (what pops first?).
"""
import sys
from pathlib import Path


def luminance(rgb):
    def lin(c):
        c /= 255
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b = (lin(c) for c in rgb[:3])
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def ratio(a, b):
    hi, lo = sorted((luminance(a), luminance(b)), reverse=True)
    return (hi + 0.05) / (lo + 0.05)


def nums(text):
    return tuple(int(v) for v in text.split(","))


def main(args):
    if args[0].lower().endswith((".png", ".jpg", ".jpeg")):
        from PIL import Image, ImageFilter
        shot = Image.open(args[0]).convert("RGB")
        if len(args) == 3:
            a, b = shot.getpixel(nums(args[1])), shot.getpixel(nums(args[2]))
            print(f"{a} vs {b}: {ratio(a, b):.1f}:1")
            return
        path = Path(args[0])
        grey = shot.convert("L")
        grey.save(path.with_name(path.stem + "-grey.png"))
        grey.filter(ImageFilter.GaussianBlur(max(shot.size) / 150)).save(path.with_name(path.stem + "-squint.png"))
        print("wrote", path.stem + "-grey.png and", path.stem + "-squint.png")
    else:
        print(f"{ratio(nums(args[0]), nums(args[1])):.1f}:1  (body text needs 4.5, big text and shapes 3)")


if __name__ == "__main__":
    assert round(ratio((0, 0, 0), (255, 255, 255)), 1) == 21.0 and ratio((9, 9, 9), (9, 9, 9)) == 1
    main(sys.argv[1:] or ["0,0,0", "255,255,255"])
