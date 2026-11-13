"""The shop window's pictures (docs/plan/SHOP-SCREEN-PLAN.md): assets/ui/shop/raw -> assets/ui/shop/source.

raw/ holds Codex's pieces of the approved concept (.planning/shop-concept/shop2-a.png, shop2-b.png), each alone on a
see-through background with no words. This trims each to what shows and splits the four pieces drawn wider than one
Roblox picture can hold sharply (window 2x2, title bar / featured card / free-gift card in halves), then
`python tools/ui_pieces.py shop --keep-size --upload` uploads source/ as is. Two pieces are made here, not drawn:
gift-white (the white gift-box drawing off the purple gift button) and ticks (three of the rays' strokes). The Paper
jar's two drawings (jar-full, and jar-empty: the same jar edited empty) are cut with one shared box so they line up.
To swap a picture: replace it in raw/, run this, delete its uploads/<name>.json, upload, paste the id in UIAssets.shop.
"""
from pathlib import Path
import numpy as np
from PIL import Image
from scipy.ndimage import binary_opening

ROOT = Path(__file__).resolve().parents[2]
RAW, SOURCE = ROOT / 'assets/ui/shop/raw', ROOT / 'assets/ui/shop/source'
SPLIT = {'window': (2, 2), 'titlebar': (2, 1), 'card-featured': (2, 1), 'card-free': (2, 1)}  # name: (columns, rows)


def trimmed(im):
    box = im.getchannel('A').getbbox()
    return im.crop(box) if box else im


def gift_white(button):
    a = np.array(button).astype(int)
    lo, hi = a[..., :3].min(axis=2), a[..., :3].max(axis=2)
    keep = binary_opening((lo > 185) & (hi - lo < 60), iterations=2)  # opening drops the paper's stray white specks
    a[..., 3] = np.where(keep, a[..., 3], 0)
    return trimmed(Image.fromarray(a.astype(np.uint8), 'RGBA'))


def jars(full, empty):
    """Drop the faint haze round the drawings, then cut both with one box (their solid parts and 4 px)."""
    clean = []
    for im in (full, empty):
        a = np.array(im)
        a[..., 3] = np.where(a[..., 3] < 16, 0, a[..., 3])
        clean.append(Image.fromarray(a, 'RGBA'))
    boxes = [im.getchannel('A').point(lambda v: 255 if v > 128 else 0).getbbox() for im in clean]
    box = (min(b[0] for b in boxes) - 4, min(b[1] for b in boxes) - 4, max(b[2] for b in boxes) + 4, max(b[3] for b in boxes) + 4)
    return [im.crop(box) for im in clean]


def main():
    SOURCE.mkdir(parents=True, exist_ok=True)
    for old in SOURCE.glob('*.png'):
        old.unlink()
    for path in sorted(RAW.glob('*.png')):
        if path.stem.startswith('jar-'):
            continue
        im = trimmed(Image.open(path).convert('RGBA'))
        cols, rows = SPLIT.get(path.stem, (1, 1))
        for r in range(rows):
            for c in range(cols):
                box = (im.width * c // cols, im.height * r // rows, im.width * (c + 1) // cols, im.height * (r + 1) // rows)
                name = path.stem if cols * rows == 1 else f'{path.stem}-{r * cols + c + 1}'
                im.crop(box).save(SOURCE / f'{name}.png')
    for name, im in zip(('jar-full', 'jar-empty'), jars(*(Image.open(RAW / f'{n}.png').convert('RGBA') for n in ('jar-full', 'jar-empty')))):
        im.save(SOURCE / f'{name}.png')
    gift_white(Image.open(RAW / 'gift-button.png').convert('RGBA')).save(SOURCE / 'gift-white.png')
    trimmed(Image.open(RAW / 'rays.png').convert('RGBA').crop((255, 0, 770, 195))).save(SOURCE / 'ticks.png')
    for p in sorted(SOURCE.glob('*.png')):
        print(p.stem, Image.open(p).size)


if __name__ == '__main__':
    main()
