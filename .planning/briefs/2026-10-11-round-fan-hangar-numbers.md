# Codex job: round floor fan + big painted hangar numbers (2026-10-11)

Alan looked at both in Studio. Two fixes in `tools/art/toys.py` (only this file and the two toy folders below).
Build each with:
`& 'D:/Blender/blender.exe' -b --factory-startup --threads 4 --python-exit-code 1 --python tools/art/toys.py -- NAME`
Look at every render yourself (render.png, close-ups) before reporting. No uploads, no Studio, no git commits,
never read or print `.env`.

## 1. floor-fan: make it ROUND (Alan: "the fan models need to be circular so they fit on the rug cleanly")
The fan stands on a round rug plaza: painted wind circle radius 88 studs, benches at radius ~79-89. So:
- Outer footprint a circle, **diameter 156 studs** (radius 78), height stays 36, base on z=0, front (switch) at -Y.
- Same parts and colours as now (`floor_fan()` ~line 3625): chunky bright blue frame, but a round ring (rounded
  tube-like rim) instead of the square `rounded_ring`; dark round rear tray; small rubber feet on the circle;
  motor; the 5 swept ivory blades (scale to the new radius, tips clear the rim by ~6 studs); centre cap; chrome
  concentric grille rings + straight wires clipped to the inner radius; orange switch on the rim.
- Keep the blades + centre cap as separate loose parts lying wholly between z=18 and z=28 and NOTHING else in that
  band (they get cut out by `tools/art/split_parts.py` to spin in game). Keep the motor below z=17, grille above 33.
- Update SPECS (`"floor-fan": (3500, (160, 160, 36))` -> 156) and the floor-fan checks so they pass.
- Then run: `& 'D:/Blender/blender.exe' -b assets/models/toys/floor-fan/floor-fan.blend --python-exit-code 1 --python tools/art/split_parts.py -- floor-fan floor-fan-blades 18 28`
  and report its output plus `assets/models/toys/floor-fan-blades/checks.json`.

## 2. desk-hangar: 12 numbered colour variants, numbers big and in the cardstock style
Alan: "the numbers on the hangars are way too small, you can't read them, they also don't match the look."
Players see hangars from above and from the room side while flying. Today the hangar (`desk_hangar()` ~line 3667)
has a tiny 14x12 red patch with a 5x7 pixel-font "1". Replace it:
- Remove the small red patch box.
- Paint a **big hand-drawn number on the roof crown**, readable from above and from the entrance side: glyph height
  ~28-32 studs across the curved top, centred, reading upright when viewed from the entrance (-Y) side. Style: thick
  red crayon/marker strokes (same red as the striped edging, (214,57,45)), slightly uneven like a kid painted it on
  cardstock, with a thin cream outline so it reads on the ivory card. Also a smaller copy (~14 studs) on the front
  arch face above the opening.
- Use a rounded, friendly font rendered into the atlas (e.g. PIL with a bold rounded TTF from C:/Windows/Fonts, or
  hand-drawn strokes) - NOT the 5x7 pixel glyphs.
- One mesh, **12 colour maps**: `color-1.png` ... `color-12.png` with numbers 1-12 (two digits must fit and stay
  readable), and `color.png` = number 1. Normal/roughness maps shared. Follow how `stall` makes `color-N` variants
  (~line 4838-4860) but numbered 1-12.
- Keep the geometry, size (110 x 70 x 50) and the entrance-ray check as they are.

## Report
Files changed, triangle counts, renders looked at (attach paths: render.png and a contact sheet of the 12 hangar
numbers seen from above at 45 degrees), split_parts output, anything still wrong.
