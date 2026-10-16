# Codex job: landing ring, speed bolt, runway lights, cardboard runway (2026-10-12)

Alan picked these from `assets/references/world-pieces/`: landing ring = the PAPER CHAIN (rings.png, left), power-up
= the folded yellow LIGHTNING BOLT (powerup.png, top left), and the cardboard pad + drawn runway (pad-runway.png).
Add these toys to `tools/art/toys.py` in the same style and pipeline as the existing ones (SPECS entry, builder,
bake, export, checks; see cubby-shelf, classroom-bookshelf, desk-hangar). Studs, Z up, front faces -Y, origin at
base centre unless said otherwise. Look at each concept picture first and match it.

## landing-ring (paper chain hoop): outer diameter 74, inner opening at least 58 across, depth 8
- About 14 interlocking paper-chain links (flat paper strips looped and glued, visible overlap seam on each)
  alternating red, blue, yellow, green, forming a circle standing upright in the X-Z plane (planes fly along Y).
- Origin at the ring CENTRE (not the base): the game spins it about Y.

## speed-bolt (folded paper lightning bolt): 9 wide (X) x 2.5 deep (Y) x 16 tall (Z)
- Bright yellow folded paper, crisp folds, slightly thick (doubled paper), like powerup.png top left.
- Origin at its CENTRE (the game spins and bobs it). Budget ~600 triangles.

## runway-light (small paper landing light): 3 x 3 x 4 tall
- A little folded paper cone/tent with a pale warm tip (the game makes the tip glow and blink in sequence).
  Export the glowing tip as a SEPARATE mesh `runway-light-tip` (same origin) so the game can light only the tip.

## desk-runway (one piece of kraft cardboard: pad + runway, DRAWN markings): two variants
Real sizes on a desk (desk top 330 x 210, its room-side edge is where planes take off and land):
- Pad part: 100 wide (X) x 86 long (Y), under the hangar at the back (Y = 0 to 86 from the back edge).
- Runway part: 88 wide, continuing forward from the pad 130 studs to the desk's front edge (Y = 86 to 216).
- Flat corrugated cardboard 1.2 thick, torn/cut uneven edges, corrugated flutes visible on the cut edges, slightly
  warped, a couple of soft dents. Drawn on top in marker and crayon (texture, not geometry): yellow centre dashes,
  blue edge lines, green crayon grass scribbles on the pad corners beside the hangar, red chevrons on the pad, like
  pad-runway.png. No letters or numbers (Alan's desks are told apart elsewhere).
- Variant `desk-runway-droop` (Alan's first choice): past the desk's front edge the cardboard continues another ~40
  and flops LIMPLY down over the edge, a soft bend at the edge then hanging nearly vertical, slightly curled and
  sagging at the corners, like a floppy sheet hanging off a table.
- Variant `desk-runway-straight` (fallback): the end sticks out flat ~35 past the front edge (like the picture).
- Origin: the back edge's centre at desk-top height (the game places it at the hangar's back). Both variants share
  one texture set if you can (same UVs for the shared part); otherwise each gets its own.
- Texture rules: the colour map is uploaded to Roblox and moderated: no black gaps between UV islands (run
  `tools/art/fill_gaps.py` logic or bake with margin so gaps are filled with neighbouring colour), and no small
  bent shapes on black. Make a contact sheet of every map (`<toy>/maps-sheet.png`) for review.

## Rules
- Bake and export with toys.py as usual and look at the renders yourself (front, side, 3/4; the droop variant from
  the side so the hang is visible). Fix anything wrong (max 3 tries). Do not lower texture size.
- No uploads, no Roblox Studio, no git commits. Only touch the new toy folders and toys.py. Never read or print .env.
- Report: function names, sizes and triangle counts from the checks, render paths, anything still wrong.
