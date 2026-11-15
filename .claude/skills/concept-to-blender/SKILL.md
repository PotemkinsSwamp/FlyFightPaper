---
name: concept-to-blender
description: Turn a concept picture or AI model sheet into a game-ready 3D model in Blender - list the sheet's impossible drawings, break it into a numbered piece map (every piece counted and found in every view), give every piece a card (traced shape, thickness, size against its parent, surface), build ONE module at a time and pass it alone in close-up beside the same crop of the sheet (numbers check, reviewer), then assemble and check the whole. Use BEFORE building, rebuilding or briefing any 3D model that has a concept picture or model sheet (skins, planes, weapons, buildings, props) in this Roblox game, whether built by Blender script, live in the Blender window, or briefed to Codex, and whenever Alan says a model "doesn't look like the concept" or its details are off.
---

# Concept to Blender: piece map, cards, one module at a time, checked in close-up

Why: the Origami Crane took three passes built by eye; measured first, the fourth lined up (2026-11-13). The Dragon
head (2026-11-14): paint projected from the sheet smeared every blade, blades made from four numbers could only be
straight daggers, and the build had 6 pieces a side where the sheet shows 3 (counted in the side view, where near and
far pieces stack, then mirrored). The whole Dragon (2026-11-15, 14 rounds): right structure, wrong details. Its outline
scored 0.83-0.93 while the legs, fins and wing ribs were plainly off, because every check looked at the whole model,
where a leg is 40 pixels, and sizes were judged by eye. A tail fan the top view draws lying flat was built flat, then
upright: two rounds lost. Alan and Gemini's review (2026-11-15) reshaped the skill round what the AI is bad at:

| The AI is bad at | So the skill |
|---|---|
| counting pieces, and noticing a wrong count | numbered piece map, counted where left and right don't overlap; count check |
| making a shape from a description | traces the shape from the drawing; cards hold numbers read off the sheet |
| seeing a wrong detail on a whole-model picture | builds and passes each module alone, in close-up, beside the same sheet crop |
| judging size, thickness and angle by eye | `numbers` reads them off the mesh; the outline score; landmarks |
| telling a wrong view from a right one | lists the sheet's impossible drawings first; Alan rules; they are never built or marked down |
| the honest fix (it fakes a view with an extra piece) | reject rules; every built part must be on the map |

**No geometry and no brief before the piece map, the cards and the exceptions have Alan's OK. No assembly before every
module has passed alone.** This is the pipeline for every model made from a concept or sheet; the crane and the Dragon
are only where its rules were learned. Research: `.planning/research/concept-to-3d-blender.md`.

Tools beside this file, run from the repo root (`python .claude/skills/concept-to-blender/sheet_tools.py test`; written
`sheet_tools.py` below):
- `sheet_tools.py`: `grid` (zoomed crop for reading points), `map` (piece map picture, count check), `pieces` (trace),
  `numbers` (the build's sizes, thickness and attachment against the cards), `views` (piece-coloured and silhouette
  renders), `score` (outline match).
- `match_views.py MAP.json ROUND`: renders from cameras matched to the sheet's own views: `check.jpg` (whole model,
  sheet | model) and `close-<module>.jpg` (one module alone, tight crops, sheet | model).
- `measure.py` (marked-up measuring sheet, colours), `overlay.py` (model over a one-angle concept).
- Builder: `tools/art/sheet_model.py` (its docstring lists the spec; writes `mesh.npz` and `model.blend`).
- Worked examples: `example-piece-map.json` (the whole Dragon: cameras, modules, exceptions, cards on the legs),
  `crane-measure.json`.
House rules: [lessons, "Making 3D models"](../../../docs/workshop/lessons.md#making-3d-models),
[skin rules](../../../docs/decisions/2026-11-13-skin-rules.md). No upload, Save to File or Studio Play without Alan's go.

## 1. Get the sheet in order
- **Master views:** the side gives length and height, the top gives width, unless Alan ranks the views otherwise
  (Dragon: the side view is drawn unlike the others, so top, three-quarter and front lead). The front view says which
  way pieces face, never sizes (the Dragon's front draws the head 1.6x too wide). The three-quarter view shows true
  directions and is the likeness check at the end, not a source of sizes.
- **Clash check:** compare every size two views share (length: side and top; height: side and front; width: top and
  front; a piece's place along the body in every view). AI sheets disagree by about 3% per part; over 5% means a view
  is drawn differently: ask Alan which one wins.
- **Impossible drawings (exceptions):** AI sheets lay a piece flat so its pattern shows (an upright tail fin drawn as
  a flat fan from above), or draw one piece at different angles in different views. For every piece ask: can all
  the views be true at once in 3D? Each one that can't goes in the map's `exceptions` (view, box, why, the view that
  is right) with a recommendation; the three-quarter view usually shows the truth. **Alan rules on each.** From then
  on that box is left out of the score, the reviewer is told not to mark the build down there, and nothing is ever
  turned or added to match the wrong view.
- **Cameras, once:** for every view write where the nose tip is drawn and the length in pixels (`cameras` in the map);
  the three-quarter view also gets its own right and up directions, fitted to two far-apart landmarks (nose and wing
  tips). Every later picture uses them, so sheet and model always line up pixel for pixel.
- Outlines: background is only what the box edge reaches (cream and white sit close to the background grey); shrink
  outlines 2 px for the white halo the sheets draw round every shape.
- **Briefing a new sheet:** one flat background colour that appears nowhere in the design (bright magenta), all views
  at one scale, side, top, bottom and front plus a three-quarter view, no glow or outline round the shapes, nothing
  laid flat for show.
- A single-angle concept (no sheet): read its camera first (yaw and pitch from two slopes, `measure.py`'s notes).

## 2. Break the sheet into a numbered piece map, grouped into modules
Wrong counts, places and directions show from every angle, and no shape polish fixes them.
1. Go piece by piece across every view (zoomed crops): every blade, horn, plate, eye, edge strip, leg, toe, fin,
   spine, and the smooth body parts. Give each one a number and a name.
2. **Find each piece in every view** and mark it with its number; if a view can't show it, say why. A piece found in
   only one view is not understood yet.
3. **Count per side in a view where left and right don't overlap** (the top for anything on the back or head, the
   front for eyes and cheeks). In the side view the far side's pieces peek over or through the body: mark them as
   that piece's far copy (2'), never as a new piece.
4. Where views disagree on a count or a place, write it as a question with a recommendation.
5. **Group the pieces into 4-7 modules** (`modules` in the map: head, wing, legs, back fins, tail...), each with the
   views that show it. A module is what gets built and passed together.
`python sheet_tools.py map MAP.json` draws the map: every number on its piece, the counts, the questions, the
exceptions as orange boxes, and its own checks.

## 3. A card for every piece
The card is what the build is checked against, so it holds numbers read off the drawing (`grid` crops), never a
description. On the map, per piece:
- **`size`: long, wide, thick in sheet pixels.** Thickness comes from a second view, the one that looks along the
  piece. A piece with no thickness measured is not ready to build; nothing is a zero-thickness plane.
- **`parent` and `of_parent`:** its length as a share of what it sits on (a toe: half its leg pod), so small details
  can't shrink to specks.
- Cross-section in words: diamond, ridge on top with an upright rim, flat slab with a thick edge. Never "a cylinder".
- **Direction in two views** (side: rising or falling; top: fanning out or along the body), **bend** (straight,
  curved up, hooked tip), segments (a horn's joints), **landmarks** (tip, base, eye centre, marked in each view).
- Surface: which shared recipe it wears (step 5); what lies over what; lines (colour, width); colours (sampled).
Check the sums: parts along the body add up to the whole. `measure.py SPEC.json` writes the marked-up sheet.

## 4. Sort every piece into a kind, then trace it
| Kind | Examples | Shape from | Colour from |
|---|---|---|---|
| **Body** (smooth) | head, neck, barrel | `sheet_model.py` loft through the side and top outlines (`round`, `mid`, `bottom_line` shape it along its length) | painted: scales, underside, creases |
| **Thick plate** | armour blocks, crest blades, cheek guards | six-sided tube, corners turned 30 degrees (`phase`), [across, up] sizes from two views, `roll`ed onto the surface it lies on | flat colour, painted facet shading and creases |
| **Thin plate** | fin webs, wing skins | traced outline: `plate()` or `"kind": "sheet"` with a real thickness | flat colour or painted lines |
| **Tube** | horns, spines, toes, struts | traced in side and top: 3D centre line, width, steps at drawn joints | flat colour |
Never paint by projection onto a plate or tube: it smears on any face turned away from the view.
Small blobby parts: extrude the side outline sideways and the top outline upward and keep what both cover (Manifold
boolean); it matches both drawings but can't show dents the outlines don't show.
Tracing:
1. `python sheet_tools.py grid SHEET x0 y0 x1 y1 OUT 6 5`: a zoomed crop with sheet-pixel grid lines.
2. Read 5-10 points round each outline, base first, and note the tip's index. Trace a plate in the view that sees it
   flattest and click its base and tip in a second view (`other`) so it points where the sheet draws it. Trace a tube
   in both the side and the top view. Colour can't split overlapping plates of one colour: place points by hand.
3. `python sheet_tools.py pieces SPEC.json` snaps each point onto the nearest drawn edge (eye readings land 3-6 px
   off, the difference between a leaf and a dagger), fits a smooth curve, writes `pieces.json` and `pieces-check.png`.
4. **Look at `pieces-check.png` at full size.** Every outline must hug its drawn piece; move points until it does.

## 5. One shared surface recipe per material
- Each material on the sheet (green scales, gold armour, cream belly, wing leaf) gets ONE recipe, written once in the
  build script and worn by every piece of that material. A leg wears the body's scales, never a flat green.
- A recipe says what the sheet's artist drew: scale shape and size, a dark crisp outline round every scale; gold with
  a lit and a dark facet and a dark crease between; a dark line where gold meets green; leaf veins on a wing.
- **Recipes are painted into the one 1024 texture** (`sheet_model.py`: `colors`, `scales`, `plates`, `facets`,
  `lines`), because Roblox gets one picture and 4,000 triangles. Never Blender-only looks (Freestyle lines, shader
  nodes, displacement): they make the render match the sheet while the game model does not.

## 6. Show Alan the map, the cards and the exceptions, then stop
The piece map with its questions and exceptions (each with a recommendation), the cards' sizes in studs on the
starter plane, the traced check picture, and any decision the numbers force. Build only after his OK.

## 7. Build one module at a time and pass it alone
Put `"only": [map numbers]` in the spec: `sheet_model.py` builds just that module on the body.
Build rules:
- One build part per map piece, carrying its number (`"map": 2`); nothing gets built that is not on the map.
- Numbers in the script, never eyeballed offsets. Traced outlines are fixed: no bevel, subdivision or shrinkwrap may
  move a traced edge. Points are true points (one vertex).
- **Roots are sunk in:** every piece's base goes into what it sits on by 10-15% of that part's thickness, so no
  daylight shows from any angle. Never placed just touching.
- Shading: body smooth; plates and tubes flat (the facets are the look).
- Colour: cut out of the body's paint both the built pieces' shapes and the sheet's pixels in their colour, so no
  drawn copy of a blade is left on the skin.
- Budget for the whole model: 4,000 triangles, one mesh, one 1024 set, closed with real thickness everywhere.
- **One change per round:** name the single most visible difference, find the line of the script that causes it,
  edit that line in place (never regenerate the script), re-check. Each round in its own folder (`round-03/`).
- Blender in the window (Blender Lab MCP) is the fast loop: sheet views behind the model at the measured scale, render
  to a file (window screenshots came back black), everything done live goes back into the script. Read the render
  path the tool returns; "Traceback" in the output is a failure; after a timeout look before repeating; calls under
  3 minutes; long renders in a background Blender from a saved copy (`save_as_mainfile(copy=True)`).

**The module gate, in this order. A module moves on only when all four pass.**
1. **Count:** `python sheet_tools.py map MAP.json SPEC.json` (with `only`, it counts just that module).
2. **Numbers:** `python sheet_tools.py numbers MAP.json ROUND/mesh.npz`: every piece's length, width and thickness
   within 20% of its card, its share of its parent, nothing paper-thin, nothing floating. Fix every line it prints.
3. **Close-up:** `python match_views.py MAP.json ROUND` writes `close-<module>.jpg`: the module alone, each view cropped
   tight, beside the same crop of the sheet at the same scale. Open it at full size and compare piece by piece:
   shape, direction, thickness, surface.
4. **Reviewer on the close-up:** another Opus subagent that gets only `close-<module>.jpg`, the module's cards and the
   exceptions, never your opinion. It answers per piece (matches, close, not yet, with one fix each) and must reject:
   - a plain ball, an even-width cylinder or a cone standing in for a shaped piece;
   - a piece smaller, thinner or pointing another way than the sheet's;
   - **band-aid geometry:** an extra strip, tube or plate added to fake one view (a gold wave laid down the back to
     imitate the fins seen from above). The fix is always the real pieces' shape, thickness or overlap;
   - a piece that shares skin with the body but is flat-coloured, or drawn lines that are missing.
   Trust it on shape, clutter and thickness; check its size and angle claims against `numbers` (it has been 15% off,
   and has asked for less upright horns then preferred more upright ones).
The same failure twice means stop: write the lesson, rethink the method, then rebuild.

## 8. Assemble, then check the whole
Take `only` out. Fix in this order and don't move on while an earlier check fails:
1. **Count and numbers** again on the whole build (attachment now covers every join).
2. **Pieces:** `python sheet_tools.py views ROUND/mesh.npz ROUND` renders each map piece in its own flat colour; lay it
   beside the piece map: same count, places, directions, bends? (Two overlapping horns make one outline.)
3. **Outline score and landmarks:** `python sheet_tools.py score SHEET ROUND/sil-top.png OUT nose_x nose_y L upto clip
   MAP.json top` (and the side): the map's exceptions for that view are left out. Aim for 0.9. Red: model too small
   there; blue: too big. It judges the outer shape only: a high score says nothing about details. Landmarks: every
   named point within 2% of the length of its place on the sheet.
4. **Matched views:** `match_views.py` again: `check.jpg` (whole model) and every `close-*.jpg`, now for the joins: a
   leg tucks into the belly's outline, not on a stalk; a wing root has no gap.
5. **Other views:** behind and above (the game camera), the back, edge-on. Nothing shrinks to a line; the skin holds
   up where no sheet view looked. Check the model faces forward (imports can turn it 180 degrees).
6. **Colours** against the sampled ones: hue, how dark shadowed faces get, line brightness.
7. **Whole-sheet reviewer:** an Opus subagent with the sheet, the map, the exceptions and `check.jpg`; told which view
   is which and that the exception boxes are not to be marked down. Questions per piece plus a ranked list with a
   fix each and a verdict. To judge a fix, show it before and after in random order and ask which is closer to the
   sheet (left or right); note whether its pick agrees with the numbers.

## 9. Roblox check, then show Alan
- Triangles, one mesh, map sizes, closed. Flat facets: Roblox's docs don't say how hard edges import (developers
  report FBX keeps them, glTF smoothed them): confirm on one test piece in Studio first (an upload: Alan's go).
- Show Alan `check.jpg` and the close-up pages, with a plain note that **leads with what is still short of the
  sheet**: per module, the piece count against the map, what `numbers` still prints, the scores, the triangle count,
  the reviewers' remaining differences.
