# Classic Dart / Option A, round 2

The model follows the approved concept's proportions. The old template-size
restriction has been removed, including its centres and 180-degree rotations.
Only tools/art/planes.py and assets/models/planes/ were changed. No uploads or commits.
Game integration is later work; this is an asset build and visual comparison.

## Rebuild

From D:/FlyFightPaper in PowerShell:

```powershell
& D:/Blender/blender.exe -b --factory-startup --threads 4 --python-exit-code 1 --python tools/art/planes.py
```

This rebuilds the Blender source, all 11 individual colour-region FBX files,
parts.json, validation.json, eight model renders and the three-view compare.png.
It also builds ../stickers/sticker-square.fbx, sticker-circle.fbx and stickers.json.
Every saved FBX is parsed and re-imported to verify scale, topology and placement.
Only Blender's built-in Python, NumPy and FBX exporter are needed.

## Measured reference and round-2 choices

The source is 1600 x 1001. Landmarks have about 1-3 pixels of reading uncertainty.
The top and side drawings have different printed scales: normalize the side by
452/575, then apply 15.3/452 studs per normalized pixel. The original measured
allocations remain the source of the longitudinal layout and wing silhouette.
The two brief rows below are explicit modeling choices, not pixel measurements.

| Measure | Reference landmarks | Raw pixels | Normalized pixels | Studs |
|---|---|---:|---:|---:|
| Overall length, top | y=493 to 945 | 452 | 452.000 | 15.3000 |
| Visible nose allocation | y=493 to 642 | 149 | 149.000 | 5.0436 |
| Visible body allocation | y=642 to 879 | 237 | 237.000 | 8.0223 |
| Visible tail allocation | y=879 to 945 | 66 | 66.000 | 2.2341 |
| Wing span, top | x=600 to 1002 | 402 | 402.000 | 13.6075 |
| Wing fore/aft extent, top | y=642 to 879 | 237 | 237.000 | 8.0223 |
| Sticker diameter, top | x=680 to 735 (left) | 55 | 55.000 | 1.8617 |
| Wing tip stripe width | x=624 to 652 (left) | 28 | 28.000 | 0.9478 |
| Tail base span, top | x=778 to 825 | 47 | 47.000 | 1.5909 |
| Overall length, side | x=24 to 599 | 575 | 452.000 | 15.3000 |
| Overall height, side | y=669 to 810 | 141 | 110.838 | 3.7518 |
| Fin rise, side | y=669 to 729 | 60 | 47.165 | 1.5965 |
| Tube length, side | x=184 to 301 | 117 | 91.972 | 3.1132 |
| Tube diameter, side | y=763 to 794 | 31 | 24.369 | 0.8249 |
| Body shoulders at wing root | about 1/5 of measured span; brief | 77 | 77.000 | 2.6000 |
| Body depth, shoulder to V keel | round-2 brief, 1.6-1.9 | brief | 53.176 | 1.8000 |
| Body depth including raised spine | side front, y=721 to 805; folded ridge included | 84 | 66.031 | 2.2351 |
Scale = 0.033849558. Nose/body/rear allocations sum to 15.3000 studs.

The body is 2.60 wide at the root and 1.80 deep from the wide flat shoulders
to the V keel. The raised folded spine adds .45, giving 2.25 total including
the ridge, close to the side drawing's 2.2351. The total is above the brief's
approximate 1.6-1.9 estimate; the drawn silhouette was given priority because
only overall length and span were fixed. The nose continues the body's exact
front section, tapers over 5.0436 studs, and changes to red over its front 40%.
Its roof facets are planar, without extra grooves. The wings use the full
8.0223-stud fore/aft envelope. The rear has one swept vertical fin and a
1.590-wide fuselage block, with no horizontal tail wings.

## Actual assembled bounds

| Part | Size X/Y/Z | Centre X/Y/Z | Triangles, all regions |
|---|---|---|---:|
| body | 2.6000 / 2.2500 / 8.0223 | 0.0000 / 0.2750 / 1.4048 | 144 |
| nose | 2.6000 / 2.2500 / 5.0436 | 0.0000 / 0.2750 / -5.1282 | 158 |
| wings | 13.6075 / 0.2319 / 8.0223 | 0.0000 / 0.8960 / 1.4048 | 236 |
| tail | 1.5900 / 2.4218 / 2.4700 | 0.0000 / 1.6909 / 6.4150 | 120 |

Overall size: 13.6075 / 3.7518 / 15.3000 studs.

## Mounts, in assembled Roblox studs

Axes: X right, Y up, -Z forward. The muzzle is the centre of the front opening,
not an old logical offset. Both tubes point along (0,0,-1).

| Gun | Tube centre X/Y/Z | Muzzle X/Y/Z |
|---|---|---|
| left | -1.7600 / 0.0800 / -1.3134 | -1.7600 / 0.0800 / -2.8700 |
| right | 1.7600 / 0.0800 / -1.3134 | 1.7600 / 0.0800 / -2.8700 |

Tube length 3.113217, diameter 0.824870; wall .085.
Only 36.7% of each tube axis is ahead of the wing leading edge.
The right instance is translated +3.52 in X from the exported left gun.

Each tube sits just outside the body under the wing-root shoulder. A chamfered
closed tape band wraps around it and reaches the underside of the paper wing.
Use parts.json's mounts directly for the later weapon assembly and firing code.

## Mesh and FBX assembly contract

One Blender unit is one stud. Construction uses Roblox X/Y/Z and converts to
Blender X/-Z/Y. All new FBXs use Y up, -Z forward and identity assembly rotation.
The source and manifest describe the final assembled Roblox coordinates.
Each logical part has one common pivot shared by all its colour regions.
The pellet pivot is its tube centre; the separate tape band retains its offset.
Keep every region's center_offset_from_slot when assembling imported MeshParts.
Do not independently recenter or resize small accents to the whole part's bounds.

FBX global_scale=.01, apply_unit_scale=False and FBX_SCALE_NONE cancel Blender's
implicit 100x centimetre conversion. Raw saved vertex numbers are in studs and
UnitScaleFactor=1. The verifier checks raw FBX bounds to .0001 stud, then imports
with global_scale=100 solely to undo Blender's centimetre interpretation.
Roblox import scale is 1. Use the new sizes, pivots and mounts in parts.json;
these are not drop-in replacements for the old templates or their rotations.
No src/, config/, template, place file or upload has been changed.

Each file contains one mesh with one plain colour material. There are no texture
images, UV layers, shader image nodes or embedded textures. Accent meshes can
receive team colour; sticker meshes are separate 1.85-stud white placeholders.
Paper thickness is .085-.11 stud, stickers and colour overlays .035-.04.
The sealed red cone has a .045 rear wall and a locally solid front point.
The very front of the cone is sealed. All planar paper faces use flat normals,
so coplanar triangles shade alike and folds cannot be blurred across creases.
The hollow tubes have genuinely open mouths and watertight wall/rim topology.
The stripe and fin colour exports each contain two closed components.

## Visual comparison and remaining differences

compare.png includes top, side and three-quarter concept/model pairs. Top and
side use 452 pixels per 15.3 studs after uniform side normalization. The
three-quarter perspective camera is fitted to the nose, wing corners, body ridge
and fin top. Its actual lens, location and roll are in parts.json. The reference
crop and fitted render receive the same uniform .88 reduction in the comparison.
No image is stretched independently in X or Y to hide shape differences.

- The concept is a painted perspective sheet. Its top/side/three-quarter views
  disagree slightly at the nose root, wing rake and fin lean. The build uses
  the measured allocations and one consistent 3D shape. The top and side silhouettes
  are close; the three-quarter left leading edge remains a little steeper and the
  fin is more foreshortened than the painted view.
- The wing outer leading corners are .45 stud (13.3 normalized pixels) forward of
  the top tracing, and shoulder leading corners are .40 stud (11.8 pixels) aft.
  This reduces the three-quarter disagreement without changing span or the full
  8.0223 fore/aft envelope. It leaves a slightly shallower sweep in the top view.
- The core is 1.80 deep; including the raised ridge, the body/nose bounds are 2.25.
  That follows the drawn side silhouette, rather than treating 1.9 as a limit on
  the whole folded assembly. The overall plane height is still 3.7518.
- The barrels expose about one third of their length, as requested. The drawing
  shows more barrel ahead of the wing in its top view, so these mounts are farther aft.
- The red cone covers 40% as in the top view. The side painting shows a somewhat
  longer red area; one physical colour split cannot reproduce both percentages.
- White rounded-square placeholders remain for free-for-all. Team renders
  replace them with red squares or blue circles.
- Paper, red accents and tape are clean flat colours. Paper grain, pencilled
  lines, crayon variation and the reference's ground shadow are intentionally absent.
- The folded rear block and fin are geometrically sharp. The concept has a few
  softer/irregular paper corners that are not reproduced as surface noise.

## Saved-file verification

| FBX | Region | Triangles | Closed components |
|---|---|---:|---:|
| body-paper.fbx | paper | 144 | 1 |
| nose-paper.fbx | paper | 72 | 1 |
| nose-accent.fbx | accent | 86 | 1 |
| wings-paper.fbx | paper | 76 | 1 |
| wings-accent.fbx | accent | 40 | 2 |
| wings-sticker-left.fbx | sticker | 60 | 1 |
| wings-sticker-right.fbx | sticker | 60 | 1 |
| tail-paper.fbx | paper | 96 | 1 |
| tail-accent.fbx | accent | 24 | 2 |
| pellet-tube.fbx | paper | 192 | 1 |
| pellet-band.fbx | band | 64 | 1 |

Every source and saved FBX is checked for closed manifold topology, consistent
normals, positive volume, no degenerate triangles, no self intersections, no UVs,
and fewer than 1500 triangles per export and per whole logical part. The full
length, span, height, body depth and barrel exposure are also checked.

## Team sticker shapes and placement

Red uses a 1.7 x 1.7 square with .10-stud corner radius. Blue uses a 1.8-diameter
circle with 64 outline segments. Both are .04 stud thick, centred on their own
origin, in local Roblox X-Z with +Y up. Free-for-all keeps the white placeholders.
The shapes export white so the game can set their team colour. No other symbols.

../stickers/stickers.json records the spot centres and orientation axes measured
from the existing wing placeholders. Centres use assembled Roblox studs; it also
records wing-slot-relative centres. Replace each placeholder with one shape copy.
Use CFrame.fromMatrix(center, right, up_normal, back). The midpoint remains .04
stud above the wing, matching the placeholder's .06 top offset and .02 bottom gap.

| Wing | Centre X/Y/Z | Up normal X/Y/Z |
|---|---|---|
| left | -3.1600 / 0.9481 / 2.5726 | 0.0151 / 0.9999 / -0.0000 |
| right | 3.1600 / 0.9481 / 2.5726 | -0.0151 / 0.9999 / -0.0000 |

Both saved sticker FBXs are parsed and re-imported through the same checks as
the plane. Every placed shape vertex is checked against the placeholder footprint
and the existing wing clearance. Hidden sticker source objects are in classic.blend.

Review files: render-threequarter.png, render-threequarter-blue.png, render-top.png,
render-side.png, render-front.png, render-exploded.png and compare.png.
classic.blend includes a linked right-gun preview, without duplicate FBX files.
Team review files: render-team-red.png (red accents and squares) and
render-team-blue.png (blue accents and circles), using the same three-quarter camera.
