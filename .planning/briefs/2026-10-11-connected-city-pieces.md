# Codex job: five connected-city kit pieces in tools/art/toys.py (2026-10-11)

Alan wants a more connected toy city: ruler sky bridges between neighbouring buildings and fly-through things hanging
from the classroom ceiling. Plan and rules: `.planning/briefs/2026-10-11-connected-city-kit.md`; layout
`assets/rug/connected-city-preview.png`. Make once, place many: each piece below is built once and repeated in game.
Same style and pipeline as the existing toys in `tools/art/toys.py` (SPECS entry, builder function, bake, export,
checks; see ruler-bridge, saturn, ceiling-light). Studs, Z up, front faces -Y, origin at base centre. Art target:
`assets/references/classroom-city-approved-v1.png` (warm, sunlit, chunky toy look, bright red/blue/yellow/green).
Planes are tiny (wingspan 7) and fly through the holes, so holes must be truly open (no faces across them).

## 1. ruler-section (exact 60 (X) x 30 (Y) x 6 (Z))
- One piece of a wide school ruler used as a bridge deck. Warm ruler yellow-wood (kit colour 225,184,114), tick marks
  along both long edges on the top AND bottom faces, a few printed numbers, softly rounded long edges.
- It repeats end to end along X: the ends are flat and the tick pattern must continue across the joint (its period
  divides 60). Budget about 600 triangles.

## 2. ruler-tape (exact 10 (X) x 32 (Y) x 8 (Z))
- A strip of masking tape wrapped round the joint of two ruler sections: a hollow sleeve, 1 thick, whose inside is
  exactly 30 (Y) x 6 (Z) so it slides over the deck. Off-white/cream tape (231,209,172), slightly wrinkled ends, a hint
  of see-through. Budget about 300 triangles.

## 3. ceiling-ring (exact 80 (X) x 8 (Y) x 86 (Z))
- A hoop hanging from a thread that planes fly through along Y: outer diameter 80, hole 60 across (open), 8 deep.
  Make it a kid's craft hoop: a wooden embroidery hoop wrapped in spiralling strips of coloured paper and tape, with a
  small loop at the top centre (Z 80..86) where the thread ties on. Budget about 2000 triangles.

## 4. cardboard-tube (exact 70 (X) x 200 (Y) x 76 (Z))
- A big hanging kraft-cardboard tube (paper-towel roll style) that planes fly through along Y: outer diameter 70, wall
  4 (hole 62, open at both ends, inner surface visible and slightly darker). Spiral seam, a few painted kid stripes or
  stickers, torn-tape patches. Two small hanger loops on top (Z 70..76) at Y = -70 and +70. Budget about 2500 triangles.

## 5. paper-chain (exact 220 (X) x 12 (Y) x 176 (Z))
- A classroom paper-chain garland hung between two ceiling points: about 26 interlocking construction-paper loops in
  repeating red, yellow, blue, green, orange, purple, hanging in a sag (catenary). Both end loops are at the top
  (Z 164..176, X = -110 and +110); the lowest loop sits at the bottom (Z 0..12) in the middle. Budget about 6000 triangles.

## Rules
- Bake and export each one with toys.py as usual and look at each render yourself (ring and tube straight down the
  hole so the opening is visible; chain from the side; ruler with two sections plus tape side by side in a test render).
  Fix anything that looks wrong (max 3 tries each). Do not lower texture size (no quality cuts).
- No uploads, no Roblox Studio, no git commits. Only add SPECS entries/builders in tools/art/toys.py and write the five
  new toy folders under assets/models/toys/. Do not touch other toys' folders. Never read or print .env.
- Report: function names added, sizes and triangle counts from the checks, render paths, anything still wrong.
