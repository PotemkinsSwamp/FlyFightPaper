---
name: concept-to-blender
description: Turn a concept picture or AI model sheet into a game-ready 3D model in Blender - break it into a numbered piece map (every piece counted and found in every view), trace each piece's exact shape, build piece by piece, and check the build against the map and the sheet (count, outline score, reviewer). Use BEFORE building, rebuilding or briefing any 3D model that has a concept picture or model sheet (skins, planes, weapons, buildings, props) in this Roblox game, whether built by Blender script, live in the Blender window, or briefed to Codex, and whenever Alan says a model "doesn't look like the concept".
---

# Concept to Blender: piece map, trace, build, score

Why: the Origami Crane took three passes built by eye; measured first, the fourth lined up (2026-11-13). The Dragon
head (2026-11-14): paint projected from the sheet smeared every blade ("atrocious"), and blades made from four numbers
(base, tip, width, thickness) could only be straight daggers. Worst of all, the sheet shows 3 pieces a side on top of
the head (seen from above) and the build had 6 a side: blades were counted in the side view, where the near and far
sides' pieces stack, and then mirrored (Alan). **Every piece is counted, numbered and found in every view before
anything is built; shapes are traced from the drawing, never invented.**
**No geometry and no brief before the piece map and the traced sheets have Alan's OK.**
This is the pipeline for every model made from a concept or sheet; the crane and the Dragon are only where its
rules were learned. Research, sources and the GitHub projects it borrows ideas from:
`.planning/research/concept-to-3d-blender.md`. Worked examples beside this file: `crane-measure.json`,
`example-piece-map.json` (the Dragon head).

Tools beside this file (run from the repo root, e.g. `python .claude/skills/concept-to-blender/sheet_tools.py test`;
written `sheet_tools.py` below): `measure.py` (marked-up measuring sheet, colours), `overlay.py` (model over a one-angle
concept), `sheet_tools.py` (grid, piece map and count check, trace,
score; `plate()` builds a traced plate).
Builder for model sheets: `tools/art/sheet_model.py` (body loft, painting from the sheet, tubes; it needs to
learn `plate()` parts and `"map"` numbers, a small change to that file). House rules:
[lessons, "Making 3D models"](../../../docs/workshop/lessons.md#making-3d-models),
[skin rules](../../../docs/decisions/2026-11-13-skin-rules.md). Holds as always: no upload, Save to File or Studio Play
without Alan's go.

## 1. Get the sheet in order
- **Master views:** the side gives length and height, the top gives width. The front view only says which way pieces
  face, never sizes (the Dragon's front draws the head 1.6x too wide). The three-quarter view is the likeness check at
  the end, not a source of sizes.
- **Clash check before anything else:** compare every size two views share (length: side and top; height: side and
  front; width: top and front; a piece's place along the body in every view). Write the clashes in a short list with
  which view wins. AI sheets disagree by about 3% per part (`sheet_tools.py` averages the two views and prints the
  gap); over 5% means a view is drawn differently: ask Alan which one wins.
- Outlines: background is only what the box edge reaches (cream and white sit close to the background grey); shrink
  outlines 2 px for the white halo the sheets draw round every shape.
- **Briefing a new sheet:** one flat background colour that appears nowhere in the design (bright magenta), all views
  at one scale, side, top, bottom and front plus a three-quarter view, no glow or outline round the shapes.
- A single-angle concept (no sheet): read its camera first (yaw and pitch from two slopes, `measure.py`'s notes;
  the crane's first passes used a camera from below a picture drawn from above).

## 2. Break the sheet into a numbered piece map
This step decides whether the model looks like the sheet at all: wrong counts, places and directions show from
every angle, and no amount of shape polish fixes them.
1. Go piece by piece across every view (zoomed crops): every blade, horn, plate, eye, edge strip, leg, fin, spine,
   and the smooth body parts. Give each one a number and a name.
2. **Find each piece in every view** and mark it with its number; if a view can't show it, say why (hidden under
   the horn from above). A piece found in only one view is not understood yet.
3. **Count per side in a view where left and right don't overlap** (the top for anything on the back or head, the
   front for eyes and cheeks). In the side view the far side's pieces peek over or through the body: mark them as
   that piece's far copy (2'), never as a new piece.
4. Note each piece's **direction in two views** (side: rising or falling; top: fanning out or lying along the body),
   its **bend** (straight, curved up, hooked tip), its segments (a horn's joints) and its **landmarks**: named points
   (tip, base, eye centre) marked in each view, checked against the build later.
5. Where views disagree (AI sheets do: a count, a place), write it as a question with a recommendation.
`python sheet_tools.py map MAP.json` draws the map: the views with every number on its piece, the list with counts,
the questions, and its own checks (a piece not placed in a view; a count that doesn't match the counting view).

## 3. Measure every piece
For each numbered piece: size and place (share of one reference length), joins and angles, surfaces (how many faces
show, lit and dark, ridge lines), layers (what lies over what), motifs, lines (colour, width), colours (sampled).
Check the sums: parts along the body add up to the whole. `python .claude/skills/concept-to-blender/measure.py
SPEC.json` writes the marked-up sheet.

## 4. Sort every piece into one of three kinds
| Kind | Examples | Shape from | Colour from |
|---|---|---|---|
| **Body** (smooth) | head, neck, barrel, tail root | `sheet_model.py` loft through the side and top outlines | painted from the sheet's views |
| **Plate** | crest blades, cheek guards, fins, wing panels | traced outline -> `plate()` (ridge down the middle: a lit and a dark facet, thick rim) | flat colour, darker rim |
| **Tube** | horns, spines, claws, tail spikes | traced in side and top -> 3D centre line, width, steps at drawn joints | flat colour |
Never paint by projection onto a plate or tube: projection smears on any face turned away from the view.
Small blobby parts (legs, paws): extrude the side outline sideways and the top outline upward and keep what both
cover (Blender's Manifold boolean); it matches both drawings but can't show dents the outlines don't show.

## 5. Trace every plate and tube
1. `python sheet_tools.py grid SHEET x0 y0 x1 y1 OUT 6 5`: a zoomed crop with sheet-pixel grid lines.
2. Read 5-10 points round each outline, base first, and note the tip's index. A plate is traced in the view that sees
   it flattest (crest blades: the side), and its base and tip are clicked in a second view (`other`, usually the
   top) so it points where the sheet draws it. A tube is traced in both the side and the top view. Colour can't
   split overlapping plates of one colour (tested on the Dragon's gold): place every plate's points by hand. Each
   traced piece carries its map number.
3. `python sheet_tools.py pieces SPEC.json` (spec format in the file): snaps each point onto the nearest drawn edge
   (eye readings land 3-6 px off, the difference between a leaf and a dagger), fits a smooth curve, writes
   `pieces.json` in model units and `pieces-check.png`.
4. **Look at `pieces-check.png` at full size.** Every outline must hug its drawn piece; move points and re-run until
   it does. A plate's face angle (tilt) comes from the front view: how much of its face shows there.

## 6. Show Alan the piece map and the traced sheets, then stop
The piece map with its questions, the shares and sizes in studs on the starter plane, the last build's numbers
beside them, the traced check picture, and any decision the numbers force, with a recommendation. Build only after
his OK.

## 7. Build piece by piece
- One build part per map piece, carrying its number (`"map": 2`); nothing gets built that is not on the map.
  `python sheet_tools.py map MAP.json BUILD_SPEC.json` checks every piece is built exactly its counted number of
  times (a mirrored part counts 2) before any render.
- Numbers in the script, never eyeballed offsets. Body: `sheet_model.py`. Plates: `sheet_tools.plate(V, F, outline,
  tip, view, offset, tilt=...)` (closed, outward, about 60 triangles; mirrored by default). Tubes: `pieces.json`
  spines and radii as `sheet_model.py` tube parts, 5-6 sides, joints as small steps.
- Shading: body smooth; plates and tubes flat (the facets are the look).
- **Traced outlines are fixed:** no bevel, subdivision or shrinkwrap may move a traced edge. Points are true points
  (one vertex, not four at the same spot). Pieces overlap their neighbour slightly where they join, so no gap shows.
- Colour: one view per spot on the painted body, cross-faded only in a thin band; cut out of the paint both the built
  pieces' shapes and the sheet's pixels in the built pieces' colour, so no drawn copy of a blade is left on the skin.
  Plain-colour pieces map their faces onto small colour squares in a corner of the same picture (or vertex colours,
  which show correctly in Roblox).
- Budget: 4,000 triangles after triangulating, one mesh, one 1024 set (colour, normal in Blender's own OpenGL kind,
  roughness, metalness), closed with real thickness everywhere.
- **Fast loop, Blender in the window** (Blender Lab MCP; Blender 5.1 open with its add-on): keep the scene loaded,
  put each sheet view behind the model as a reference picture at the measured scale (side and top ortho views give a
  live overlay), change one piece, render to a file (window screenshots came back black on the crane), compare.
  Seconds per look instead of a fresh Blender start. Everything done live goes back into the build script, which
  stays the record and makes the final run headless (`--factory-startup` keeps the 2-unit default cube: delete it).
- **One change per round:** name the single most visible difference, find the line of the script that causes it,
  edit that line in place (never regenerate the script), re-check. Keep every round in its own folder (`round-03/`:
  the script, the renders, the scores, the reviewer's answer) so rounds can be compared and the work resumed.
- Live-window hygiene: read the render path the tool returns, never an older file; output text with "Traceback" or
  "Error" is a failure even when the call says OK; after a timeout, look at the scene before repeating anything;
  keep each call under about 3 minutes; long renders go to a background Blender from a saved copy
  (`bpy.ops.wm.save_as_mainfile(filepath=..., copy=True)`), so the window never freezes.
- Full renders only when the checks below pass.

## 8. Check every build
Fix in this order and don't move on while an earlier check fails: pieces, outline and landmarks, other views,
colours, reviewer. The same failure twice means stop: write the lesson, rethink the method, then rebuild.
For checks, render orthographic, from cameras framed on the model's bounding box, all views tiled into one
contact sheet (the sheet's views beside them) so one picture shows everything.
1. **Pieces:** render the model with each map piece in its own flat colour from the top, the side and the front,
   beside the piece map: same count, same places, same directions, same bends? This catches what the score can't
   (two overlapping horns make one outline).
2. **Score and landmarks:** render the model as a flat silhouette (one colour, transparent background) from the side
   and from the top, then
   `python sheet_tools.py score SHEET RENDER OUT nose_x nose_y L upto clip` (upto: the model's furthest point back,
   horns included, as a share of the length; clip: compare only that far, e.g. where a head test ends). Aim for 0.9
   or better on the part being built (the hybrid Dragon head scores 0.87 from the side). Red on the picture: model
   too small there; blue: too big; it prints where along the body the biggest misses are. It judges the outline
   only. Landmarks: every named point on the render lies within 2% of the length of its place on the sheet.
3. **Likeness:** the three-quarter view laid over the sheet's (`overlay.py`, or the window's camera matched to it).
4. **Other views:** straight above, behind and above (the game camera), the front, the back, edge-on. Nothing may
   shrink to a line; the painted skin must hold up where no sheet view looked (back, edges, underside). Check the
   model faces forward (imports can turn it 180 degrees).
5. **Colours** against the sampled ones: hue, how dark shadowed faces get, line brightness.
6. **Independent reviewer:** another Opus subagent that gets only the sheet, the piece map and the renders, never
   your opinion. Tell it which view is which and where the head is. Ask questions per piece ("how many pieces a side
   do you count from above, on the sheet and on the model?", "does the horn's tip curve up like the sheet's?", "are
   the crest blades leaf-shaped or straight?") plus a ranked list with a fix each and a verdict (matches, close, not
   yet). Its eye for shape and clutter is good; its pixel sizes are off by up to 15%, so check size claims on the
   score. To judge a fix, show it the round before and after side by side in random order and ask which is closer
   to the sheet (one word: left or right); note whether its pick agrees with the scores, which tells you how far to
   trust it. Spend more effort on checking than on building. Fix, re-score, review again until close.

## 9. Roblox check, then show Alan
- Triangles, one mesh, map sizes, closed. Flat facets: Roblox's docs don't say how hard edges import (developers
  report FBX keeps them, glTF smoothed them): confirm on one test piece in Studio before relying on it (an upload:
  Alan's go).
- Show Alan full renders beside the sheet (three-quarter, side, top, front, behind and above, close-ups), with a
  plain note that **leads with what is still short of the sheet**, the piece count against the map, the scores, the triangle count, and the
  reviewer's remaining differences.
