# Codex job: four classroom toys in tools/art/toys.py (2026-10-11)

Alan wants real desks and decorations in the classroom, moving it toward
`assets/references/classroom-city-approved-v1.png`. Today the desks are plain boxes. Add four toys to
`tools/art/toys.py` in the same style and pipeline as the existing ones (SPECS entry, builder function, bake, export,
checks). Studs, Z up, front faces -Y, origin at base centre, like the others.

## 1. school-desk (exact 330 x 210 x 108; X width, Y depth, Z height)
- These are gameplay desks: planes land on the top. The top must be exactly 330 x 210, 12 thick, top face at Z=108.
  Light wood with rounded edges and a pencil groove near the -Y edge.
- Under the top: a grey metal tube frame and four legs to Z=0, inset ~15 from the corners. Open space under the desk
  (no solid block): planes will fly under it.
- An open book cubby hanging under the top on the +Y half (the pupil's side), open toward +Y, with 2-3 coloured books
  and a notebook inside.
- Budget about 4000 triangles.

## 2. school-chair (110 x 100 seat, seat top at Z=90)
- Moulded bright-blue plastic seat and a backrest on the +Y edge rising to about Z=200, grey metal tube legs to Z=0.
  Classic school chair. Budget about 2500 triangles.

## 3. paper-bunting (about 300 long, hangs from both ends)
- A thin string sagging ~30 in the middle, with 9 paper triangle pennants (about 26 wide, 32 tall) alternating red,
  yellow, blue, green, with paper texture on both faces (like the pencil pennant material). Ends at X=+-150, Z=0 is the
  string's end height (pennants hang below it). Budget about 1500 triangles.

## 4. saturn (planet about 60 across, ring about 140 across)
- A toy painted planet: pale yellow/tan banded ball, tilted ~20 degrees flat ring (cream and tan bands), and a short
  thread loop on top for hanging. Budget about 2500 triangles.

## Rules
- Bake and export each one with toys.py as usual and look at each render yourself. Fix anything that looks wrong
  (max 3 tries each). Do not lower texture size (Alan's rule: no quality cuts).
- No uploads, no Roblox Studio, no git commits. Do not touch other toys' output folders or files under
  assets/models/ other than the four new toy folders. Never read or print .env.
- Report: what you added to toys.py (function names), sizes and triangle counts from the checks, render paths, and
  anything that still looks wrong.
