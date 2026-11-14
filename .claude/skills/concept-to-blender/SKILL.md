---
name: concept-to-blender
description: Measure a concept picture in full, then build it in Blender to the numbers and check it against the picture. Use BEFORE building, rebuilding or briefing any 3D model that has a concept picture (skins, planes, weapons, buildings, props) in this Roblox game, whether Claude builds it by Blender script or briefs Codex or Meshy, and whenever Alan says a model "doesn't look like the concept".
---

# Concept to Blender: measure first, then build

Why (Alan, 2026-11-13): the Origami Crane took three passes built by eye and still had a head and neck 4 to 5 times
too thin. Measured first, the fourth pass lined up with the concept on its first build. Building by eye costs more
usage and time than measuring. **No geometry and no brief before the measured sheet has Alan's OK.**

Tools beside this file: `measure.py` (the marked-up sheet and colour samples; plain Python) and `overlay.py` (the
model laid over the concept; Blender). `crane-measure.json` is a worked example of a measuring spec.
House rules this sits on: [lessons, "Making 3D models"](../../../docs/workshop/lessons.md#making-3d-models),
[skin rules](../../../docs/decisions/2026-11-13-skin-rules.md) for skins. Holds as always: no upload, Save to File or
Studio Play without Alan's go.

## 1. Read the camera
Decide what the picture's camera sees before measuring anything, because every length is squashed by it.
- Which side of the model faces us, and are we above or below it? Proof: which faces show (a wing's top or its
  underside, the back or the belly). The crane's first three passes used a camera from below; the concept is from above.
- **Yaw** (0 = pure side view, 90 = from the front) and **pitch** (degrees above level). Two readings pin them down:
  the slope `a` of the nose-tail line in the picture (down per across) and the slope `b` of the line joining two
  mirrored points, such as the wing tips. Then `sin(pitch) = sqrt(a * b)` and `tan(yaw) = a / sin(pitch)`.
- Say how sure you are. A drawn or AI-made concept is not a true 3D view: expect one part in ten.

## 2. List everything in the picture
One table, every row measured in step 3. Nothing gets built that is not on it; anything on it that will not be built
is named to Alan. For **every part, including the ones you are not rebuilding** (the crane's wings turned out two
thirds of the concept's size, found only after the head was done):
- **Size and place:** length, height, width across, where it joins its neighbour, its angle to the body.
- **Surfaces:** how many faces show, which are lit and which dark, where each fold line runs. This gives the
  cross-section (a folded strip = a fold on top, a corner each side, an edge underneath), so the part has real width
  seen from above and behind, where players look.
- **Layers:** which piece lies over which, and where the paper edges show.
- **Design elements:** each motif (blossom, wave, stripe): its size, how many, on which face, how far apart.
- **Lines:** colour, width in pixels, and which edges carry one (every fold, or only the outline).
- **Colours:** sample them (step 3). Bright white lines mean paint, not metal: metal mirrors the sky and turns
  blue-grey, which hid the crane's detail.

## 3. Measure
- Pick one reference length that the fit keeps (the body, breast to tail root) and give every size as a share of it.
- Zoom in (crop at 2x to 4x), note each landmark in picture pixels, write a spec like `crane-measure.json`, run
  `python .claude/skills/concept-to-blender/measure.py SPEC.json`. It corrects for the camera, prints each share and
  angle, samples the colours and writes the sheet.
- Lines must lie in the model's middle plane (nose, tail, up). A point on the near side sits half a width towards the
  camera: shift it back before trusting it. Widths across can only be read from visible top faces: say so.
- Check the sums: parts along the body must add up to the whole reach.

## 4. Show Alan the sheet, then stop
Send the sheet with: the shares, the same sizes in studs on the starter plane, the last build's numbers beside them
if there was one, and **any decision the numbers force** (the crane's beak ends 2 studs past the nose) with a
recommendation. Build only after his OK.

## 5. Build to the numbers
- Put the measured numbers in the script as numbers (shares or units of the scale), not as eyeballed offsets.
- Fast loop: geometry and textures only (`--no-render` on `tools/art/crane_skin.py`, about a minute), then quick
  EEVEE looks. Full renders only when the checks below pass.
- Keep faces clean. Add a layer only where the concept shows one: extra flaps with outlined edges read as clutter.

## 6. Check every build against the concept
1. **Overlay:** `overlay.py` renders the model from the measured camera at the measured scale, pinned on one anchor
   spot, see-through over the concept. Outlines, joints and tips should coincide. Do the whole model as well as the
   part you changed.
2. **Other views:** straight above, behind and above (the chase view), and the side. Nothing may shrink to a line.
3. **Colours:** compare the render with the sampled colours: hue, how dark the shadowed faces get, line brightness.
4. **Independent reviewer:** an Opus subagent that gets only the concept and the renders, never your opinion. Tell it
   which view is which and where the head is (one reviewer took the tail for the neck), what was rebuilt, and which
   length to judge sizes against. Ask for a ranked list with a fix each and a verdict (matches, close, not yet).
   Its eye for shape, clutter and colour is good; its pixel numbers are off by up to 15%, so check a size claim on
   the overlay before acting. Fix, re-render, review again until it says close.

## 7. Show Alan
Full renders on the three builds and review sheets (concept beside the model, the overlay, above, behind, side, close
ups), with a plain note that **leads with what is still short of the concept**, the triangle count, and the
reviewer's remaining differences.
