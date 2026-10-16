# Codex job: close roof holes on two buildings, take the Banner Tower's flag off (2026-10-11)

Alan saw these in Studio. His shots (red circles): `.planning/briefs/2026-10-11-shots/alan-gateway-holes.webp`,
`alan-garden-roof-hole.webp`, `alan-banner-flag.webp`. Fix by re-baking with `tools/art/hero.py` +
`FOLDER/touchup.json` (format: docstring near hero.py line 144).

## Rules (same as `.planning/briefs/2026-10-10-rebake-three.md`)
- Work on COPIES: copy `assets/models/NAME` to `assets/models/_rebake/NAME` (replace any old copy) and bake there.
  Never touch the originals.
- Same settings as the original bake (read the copy's `parts.json`: requested_height, vertical_splits, front;
  do NOT pass --cuts or --parts) plus `--min-coverage 0.33 --detail 2.5`. No quality loss (Alan's rule).
- Delete every `parts/*.upload.json` in the copy before baking.
- One bake at a time (they run out of memory side by side).
- After each bake run `tools/art/closeups.py` on the copy and look at `renders/closeups.png` yourself, including a
  straight-down roof view you render yourself if the close-ups don't show the whole roof. A fix counts only when
  no black hole, slot or notch shows from above or from the sides.
- No uploads, no Studio, no commits, never read .env. Report: what you changed in each touchup.json, triangle
  totals, close-up paths, anything still wrong.

## 1. gateway-towers (the archway)
- A big black hole in the bridge roof between the two towers, around the yellow ruler parapet and green brick
  (first shot, top circle). Close it with flat roof filler (roof cardboard colour) so the bridge roof is solid.
- A black notch/slit in a side wall of the right tower, mid-height between windows (first shot, lower circle). Patch.

## 2. book-stack-garden
- The water tower was removed last time and left a big black star-shaped hole in the roof (second shot). Close the
  whole roof with a clean flat cardboard roof deck at the right height, under the four green corner bricks (keep
  them). The pencil in the middle is a separate toy, not part of this model.

## 3. banner-tower
- Start from the CURRENT `assets/models/banner-tower/touchup.json` (it already has a masking-tape strip over the
  roof crack; keep it, and make sure no dark sliver remains along the roof's middle join, especially by the front
  parapet).
- Remove the flag, its wooden pole and the black base from the roof entirely (delete box; third shot). Close the roof
  under it. Claude will stand the separate wooden `flagpole` toy at the roof centre so Alan can move it freely.
- Report the roof deck height (Blender z) and the roof centre (Blender x, y) for placing that toy.
