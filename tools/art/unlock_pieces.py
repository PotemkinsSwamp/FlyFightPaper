"""The unlock backpack's pictures (docs/plan/UNLOCK-PLAN.md), from assets/ui/unlock/source into assets/ui/unlock/ready.

- sheet.png, tape-title.png, pull.png: the concept pieces cut to what shows and sized for upload.
- sheet-tapes.png: the sheet's red and blue top tapes on their own, drawn over the LEVEL strip (Alan 2026-11-11: the
  strip must look taped down, not floating).
- bag-closed.png, bag-open.png: both backpacks cut to the bag.
- unzip-1.png, unzip-2.png: 12 in-between pictures of the zipper's part of the bag (2 x 3 on each sheet). A real
  zipper: shut tight at the pull, gaping only along the stretch the pull has passed (widest in its middle, shut at both
  ends), the gap growing with that stretch (Alan 2026-11-11: opening from the wrong end looked very bad).
- button-cream.png: the Hangar's green taped button with its paper made cream (Later, Skip, arrows).
Prints the numbers UnlockMoment.luau needs (where the frames sit on the bag, the pull's path).
"""
from pathlib import Path
import numpy as np
from PIL import Image
from scipy.ndimage import (binary_closing, binary_fill_holes, binary_opening, gaussian_filter, map_coordinates,
                           median_filter)

ROOT = Path(__file__).resolve().parents[2]
SRC, READY = ROOT / 'assets/ui/unlock/source', ROOT / 'assets/ui/unlock/ready'
CX, CY = 1030.0, 1100.0              # the bag's middle in the 2048 pictures; rays from here find the zipper
TA, T0, TL = 22.0, 32.0, 165.0       # angle where the open gap shuts on the right; the closed pull; the open pull
BOX = (300, 380, 1760, 1180)         # the part of the bag a frame redraws
BAG = (248, 114, 1794, 1878)         # the bag's own extent in the 2048 pictures
FRAMES, FW, FH = 12, 512, 280

def rgba(name):
    return np.array(Image.open(SRC / name).convert('RGBA')).astype(float)

def solid_box(im):
    return im.getchannel('A').point(lambda v: 255 if v > 128 else 0).getbbox()

def fit(im, longest):
    s = longest / max(im.size)
    return im.resize((round(im.width * s), round(im.height * s)), Image.LANCZOS) if s < 1 else im

# --- the zipper's track, ray by ray -------------------------------------------------------------------------------
def yellow(a):
    r, g, b, al = (a[..., k] for k in range(4))
    return (r > 180) & (g > 130) & (b < 120) & (r - b > 90) & (al > 128)

def runs(mask, theta):
    t = np.radians(theta); rs = np.arange(250, 1000)
    xs = (CX + rs * np.cos(t)).astype(int); ys = (CY - rs * np.sin(t)).astype(int)
    ok = (xs >= 0) & (xs < 2048) & (ys >= 0) & (ys < 2048)
    v = np.zeros(len(rs), bool); v[ok] = mask[ys[ok], xs[ok]]
    out, start = [], None
    for i, on in enumerate(np.append(v, False)):
        if on and start is None: start = i
        if not on and start is not None:
            if i - start >= 4 and rs[start] < 715: out.append((rs[start], rs[i - 1]))  # past 715: the handle
            start = None
    return out

def track(mask, angles, pick):
    v = np.array([pick(r) if r else np.nan for r in (runs(mask, a) for a in angles)], float)
    ok = ~np.isnan(v)
    return median_filter(np.interp(angles, angles[ok], v[ok]), size=17, mode='nearest')

def main():
    closed, opened = rgba('backpack-closed.png'), rgba('backpack-open.png')
    angles = np.arange(-15, 195.01, 0.25)
    cm, om = yellow(closed), yellow(opened)
    ro_c = track(cm, angles, lambda rs: max(r[1] for r in rs))   # outer edge of the track, closed
    in_c = track(cm, angles, lambda rs: min(r[0] for r in rs))   # inner edge, closed
    pull = (angles > -1) & (angles < 36)                          # the closed picture's own pull hangs here
    in_c[pull] = np.interp(angles[pull], angles[~pull], in_c[~pull])
    ro_o = track(om, angles, lambda rs: max(r[1] for r in rs))   # outer edge of the upper teeth, open
    in_o = track(om, angles, lambda rs: min(r[0] for r in rs))   # far side of the lower teeth, open
    f = lambda tab, th: np.interp(th, angles, tab)

    x0, y0, x1, y1 = BOX
    ys, xs = np.mgrid[y0:y1, x0:x1].astype(float)
    th = np.degrees(np.arctan2(CY - ys, xs - CX)); th = np.where(th < -90, th + 360, th)
    r = np.hypot(xs - CX, ys - CY)
    delta = f(ro_c, th) - r                       # depth inside the track's outer edge
    w = f(ro_c, th) - f(in_c, th)                 # the closed track's width
    tail = th < TA

    def frame(p):
        ts = T0 + (TL - T0) * p                   # the pull's angle
        g = (ts - TA) / (TL - TA)                 # how far the gap has grown
        opening = (th >= TA) & (th <= ts)
        src = np.where(opening, TA + (th - TA) * (TL - TA) / max(ts - TA, 1e-3), th)
        hs = f(ro_o, src) - f(in_o, src)          # the open picture's gap depth there
        hd = w + g * np.maximum(hs - w, 0)        # this frame's gap depth (teeth kept, gap scaled)
        dsrc = np.where(delta <= hd, delta * np.maximum(hs, 1) / np.maximum(hd, 1), delta + (hs - hd))
        dsrc = np.where((delta < 0) | tail, delta, dsrc)
        rsrc = f(ro_o, src) - dsrc
        sx = CX + rsrc * np.cos(np.radians(src)); sy = CY - rsrc * np.sin(np.radians(src))
        warped = np.stack([map_coordinates(opened[..., k], [sy, sx], order=1, mode='nearest') for k in range(4)], -1)
        depth = np.where(th < 40, 230, np.maximum(hs, w) + 90)   # how deep it redraws (clear of the pocket)
        use = (opening | tail) * np.clip((depth - delta) / 40, 0, 1) * np.clip((delta + 8) / 8, 0, 1)
        use = use * (th > -12) * (th < 190)
        out = closed[y0:y1, x0:x1] * (1 - use[..., None]) + warped * use[..., None]
        return Image.fromarray(np.clip(out, 0, 255).astype('uint8'), 'RGBA')

    READY.mkdir(parents=True, exist_ok=True)
    for sheet_no in range(2):
        sheet = Image.new('RGBA', (FW * 2, FH * 3), (0, 0, 0, 0))
        for k in range(6):
            n = sheet_no * 6 + k + 1
            sheet.paste(frame(n / (FRAMES + 1)).resize((FW, FH), Image.LANCZOS), ((k % 2) * FW, (k // 2) * FH))
        sheet.save(READY / f'unzip-{sheet_no + 1}.png')

    bw, bh = BAG[2] - BAG[0], BAG[3] - BAG[1]
    for name, pic in (('bag-closed', 'backpack-closed.png'), ('bag-open', 'backpack-open.png')):
        fit(Image.open(SRC / pic).convert('RGBA').crop(BAG), 1024).save(READY / f'{name}.png')

    # The sheet, cut to the paper; its two top tapes on their own picture at the same scale and width.
    im = Image.open(SRC / 'sheet.png').convert('RGBA'); box = solid_box(im)
    sheet = im.crop(box); fit(sheet, 1024).save(READY / 'sheet.png')
    a = np.array(sheet).astype(int); r_, g_, b_, al = (a[..., k] for k in range(4)); H = 300
    mask = np.zeros(r_.shape, bool)
    mask[:H, :400] = ((b_ > r_ + 40) & (b_ > 120) & (al > 20))[:H, :400]
    mask[:H, -330:] = ((r_ > g_ + 55) & (r_ > b_ + 30) & (al > 20))[:H, -330:]
    mask = binary_fill_holes(binary_closing(binary_opening(mask, iterations=2), iterations=6))
    a[..., 3] = (al * np.clip(gaussian_filter(mask.astype(float), 1.0) * 1.4, 0, 1)).astype(int)
    tapes = Image.fromarray(a[:H].astype('uint8'), 'RGBA')
    tapes.resize((1024, round(H * 1024 / sheet.width)), Image.LANCZOS).save(READY / 'sheet-tapes.png')

    tape = Image.open(SRC / 'tape-title.png').convert('RGBA'); fit(tape.crop(solid_box(tape)), 1024).save(READY / 'tape-title.png')
    p = Image.open(SRC / 'zipper-pull-lifted.png').convert('RGBA'); fit(p.crop(solid_box(p)), 512).save(READY / 'pull.png')

    green = np.array(Image.open(ROOT / 'assets/ui/hangar/source/button-green.png').convert('RGBA')).astype(float)
    r_, g_, b_ = green[..., 0], green[..., 1], green[..., 2]
    paper = (g_ > r_ + 15) & (g_ > b_ + 15); lum = (0.3 * r_ + 0.59 * g_ + 0.11 * b_) / 160
    for k, c in enumerate((255, 244, 220)): green[..., k] = np.where(paper, np.clip(c * lum, 0, 255), green[..., k])
    Image.fromarray(green.astype('uint8'), 'RGBA').save(READY / 'button-cream.png')

    # Numbers for the game, as shares of the bag picture (0-1 across and down).
    print('sheet', sheet.size, 'tapes height share', round(H / sheet.height, 4))
    print('frames box', [round((BOX[0] - BAG[0]) / bw, 4), round((BOX[1] - BAG[1]) / bh, 4),
                         round((BOX[2] - BOX[0]) / bw, 4), round((BOX[3] - BOX[1]) / bh, 4)])
    pts = []
    for k in range(25):
        ts = T0 + (TL - T0) * k / 24
        rr = f(ro_c, ts) - (f(ro_c, ts) - f(in_c, ts)) / 2
        pts.append('{%.4f, %.4f}' % ((CX + rr * np.cos(np.radians(ts)) - BAG[0]) / bw, (CY - rr * np.sin(np.radians(ts)) - BAG[1]) / bh))
    print('pull path', ', '.join(pts))

if __name__ == '__main__':
    main()
