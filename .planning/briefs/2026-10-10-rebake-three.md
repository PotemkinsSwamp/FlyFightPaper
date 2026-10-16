# Codex job: re-bake three toy-town buildings with Alan's fixes (2026-10-10)

Alan saw these in real Play. Fix them by re-baking with `tools/art/hero.py` + `FOLDER/touchup.json`
(format: docstring near `hero.py` line 144). Alan's in-game shots: `.planning/briefs/2026-10-10-shots/`.

## Rules
- Work on COPIES: copy `assets/models/NAME` to `assets/models/_rebake/NAME` and bake there. Never touch the originals.
- Same settings as the original bake (read `parts.json`: requested_height, vertical_splits, front) and `--detail 2.5`.
  No quality loss: do not lower detail or texture size (Alan's rule).
- Delete every `parts/*.upload.json` in the copy before baking (hero.py reuses stale upload records).
- Run tall bakes one at a time (they run out of memory side by side).
- After each bake run `tools/art/closeups.py` on the copy and look at `renders/closeups.jpg` yourself.
- No uploads, no Studio, no commits. Report: what you changed in touchup.json, triangle totals, and the closeups path.

## 1. gateway-towers (height 265; splits ground-floor:xy,upper-walls:xy,roof:xy,topper:xy)
- Roof: black slots run along both yellow ruler parapets on the bridge roof. The existing delete boxes cut the roof
  under the parapets and the flat ruler panels don't cover the hole. Add flat roof filler boxes (roof cardboard
  colour) under/behind each panel so no gap shows from above. An earlier note says `"delete_rule": "all"` fixes the
  back-ruler notch; try it.
- Left tower, front face, about mid-height: a black see-through hole (missing faces) the size of two windows. Patch it
  (clean box or paint in the wall colour/texture) so the wall is closed.

## 2. crayon-box-tower (height 215; same splits as the gateway)
- Roof: broken triangles (jagged, see-through bits) around the crayons. Clean them up.
- The crayons' textures don't fully show: tips/tops look dark or untextured in game. Make each crayon read as a
  clean coloured crayon with a pointed tip, like `concept-front.png`.

## 3. book-stack-garden (height 234; splits ground-floor:xy,upper-walls:xy,roof:xy,topper:xy)
(Earlier drafts said "book-stack-lookout"; that was wrong. Alan's shot `lookout-water-tower.webp` shows book-stack-garden.)
- Remove the wooden water tower on top (Alan: "textures really weak"), legs included. Keep the four green bricks on
  the roof corners. Where the tower stood, the roof must be closed and clean (no hole, no stubs).
- The pencil flag is a separate toy placed by Claude, not part of this model. Do not add one.

When done, Claude reviews the close-ups, uploads (`town_toys.py hero`), places and checks in Studio.

## 4. banner-tower (added 2026-10-11 from Claude's roof-view sweep; read `parts.json` for height and splits)
- Same flaw as the gateway roof: black slots run along the yellow ruler parapets on the lower roof terraces (see the
  two roof views in `assets/models/banner-tower/renders/closeups.png`, bottom right). Close them the same way.
