# Codex job: classroom bookshelf + ceiling light in tools/art/toys.py (2026-10-11)

The classroom still has two things made of plain Roblox blocks: two bookshelves on the east wall (36 coloured boxes
each) and nine ceiling lights (flat glowing slabs). Replace them with real toys, in the same style and pipeline as the
existing ones in `tools/art/toys.py` (SPECS entry, builder function, bake, export, checks; see school-desk and
cubby-shelf). Studs, Z up, front faces -Y, origin at base centre. Art target:
`assets/references/classroom-city-approved-v1.png` (warm, sunlit, chunky toy look).

## 1. classroom-bookshelf (exact 300 wide (X) x 85 deep (Y) x 260 tall (Z))
- Warm light-wood bookcase, open front (-Y), back panel, 5 shelves (bottom one raised ~10 off the floor).
- Shelves filled with chunky colourful books of different heights and thicknesses (some leaning, one small stack lying
  flat per shelf), plus 2-3 small extras (a globe, a pencil pot, a toy dinosaur) so it reads as a classroom shelf.
- Nothing may stick out past the 300 x 85 x 260 box. Budget about 9000 triangles.

## 2. ceiling-light (exact 150 (X) x 40 (Y) x 8 (Z))
- Classroom fluorescent panel seen from below: white painted metal frame ~3 wide, frosted milky diffuser with a fine
  square grid (egg-crate louvre) inset 2. Top face flat (it sits against the ceiling). Budget about 1500 triangles.
- The diffuser gets its own material slot named `Glow` so the game can make only that part bright.

## Rules
- Bake and export each one with toys.py as usual and look at each render yourself (bookshelf from the front and 3/4;
  light from below). Fix anything that looks wrong (max 3 tries each). Do not lower texture size (no quality cuts).
- No uploads, no Roblox Studio, no git commits. Do not touch other toys' folders or files under assets/models/ other
  than the two new toy folders. Never read or print .env. Another Codex job is re-baking buildings in
  assets/models/_rebake/: do not touch that folder.
- Report: function names added, sizes and triangle counts from the checks, render paths, anything still wrong.
