# Codex job: backpack cubby in tools/art/toys.py (2026-10-11)

Alan: the window wall has nothing on it. Under the windows go two long, low backpack cubbies (one each side of the
middle side desk). Add one toy to `tools/art/toys.py` in the same style and pipeline as the existing ones (SPECS
entry, builder, bake, export, checks; see cubby-shelf and classroom-bookshelf). Studs, Z up, front faces -Y, origin at
base centre. Art target: `assets/references/classroom-city-approved-v1.png` (warm, chunky toy look).

## backpack-cubby (exact 700 wide (X) x 60 deep (Y) x 140 tall (Z))
- Warm light-wood low cubby unit, open front (-Y), back panel, 2 rows x 7 open compartments, a top surface.
- Most compartments hold a chunky kid backpack (bright colours: red, blue, green, yellow, purple, orange, pink; some
  with a front pocket, zip line, a keyring toy), a few hold a lunchbox or a rolled-up jacket, one or two are empty.
- A small name label strip under each top-row compartment (blank coloured tags, no text).
- Nothing may stick out past the 700 x 60 x 140 box. Budget about 9000 triangles.

## Rules
- Bake and export with toys.py as usual and look at the renders yourself (front and 3/4). Fix anything wrong (max 3
  tries). Do not lower texture size (no quality cuts).
- No uploads, no Roblox Studio, no git commits. Only touch the new toy folder and toys.py. Never read or print .env.
  Another Codex job works in assets/models/_rebake/: do not touch it.
- Report: function names, size and triangle count from the checks, render paths, anything still wrong.
