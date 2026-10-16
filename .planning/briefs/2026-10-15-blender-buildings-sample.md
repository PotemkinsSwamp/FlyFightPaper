# Codex Blender job: first Blender-built town building (sample for Alan): sticky-note-tower (2026-10-15)

Alan approved 22 new town buildings; 14 are built in Blender (no Meshy) because they are clean shapes, thin parts or
exact openings. This first one is a sample Alan sees before the other 13 are built, so it must not look plainer than
our Meshy buildings (last time a Blender "kit" shop came out "sharper but less detail"): real geometry for frames,
door and bricks, and painted/baked texture detail matching the picture.

Approved picture: `assets/models/sticky-note-tower/concept-front.png`. Look also at `assets/references/classroom-city-approved-v1.png`.

## Write `tools/art/blocks.py`: Blender-built town buildings
One script, one function per building (later briefs add the other 13), shared helpers (window, door, toy-brick
doorstep, paper/cardboard materials, bake, export). Run like `tools/art/toys.py`:
`& 'D:/Blender/blender.exe' -b --factory-startup --threads 4 --python-exit-code 1 --python tools/art/blocks.py -- sticky-note-tower`

Output exactly the hero-building layout that `tools/town_toys.py hero` / `stand` already read (copy the format from
`assets/models/sweet-shop/parts.json` and `assets/models/sweet-shop/parts/`):
- `assets/models/<name>/parts/<n>-<label>.fbx` plus `<n>-<label>-color.png`, `-normal.png` (OpenGL), `-roughness.png`,
  1024 x 1024 each. Studs, Z up, front facing -Y, every piece sharing the building's base-centre origin.
- `assets/models/<name>/parts.json` with `pieces[]`: label, prefix, triangles, bounding_box (min/max), origin, and
  `front_pixels_per_stud` measured like `tools/art/hero.py` does.
- Every piece a closed mesh (no holes, no boundary edges), at most 12,000 triangles, at least 6 texture pixels per
  stud on its outer faces (split into more pieces if needed).
- `assets/models/<name>/renders/front.png` and `three-quarter.png` (same camera as the concept), and
  `assets/models/<name>/compare.png` (concept left, render right).

## sticky-note-tower: sizes in studs (measured from the picture; building 90 x 90 x 190)
| Part | Size and place |
|---|---|
| 6 sticky-note pads | each 86 x 86 x 31.5, stacked from the ground to 189. Colours bottom to top: yellow #F5D630, pink #F06FA6, blue #45A6E6, green #7DC84A, orange #F7902F, yellow #F5D630. Each pad turned about the centre by 0, +2.5, -2, +2.5, -2.5, +2 degrees (the footprint must stay inside 90 x 90). Sides show fine stacked-sheet lines about every 0.3 studs (normal + colour), slightly uneven sheet edges; the top of the top pad is plain smooth paper. |
| windows | kraft cardboard frame 17 x 17 outer, bars 3 wide, standing 1.5 proud of the pad face; blue glass #2F6FC8, 11 x 11, set 0.5 in. Centred at each pad's mid-height. Two per face on all four faces of every pad, centres 21 left and right of the face centre, except the ground floor front. |
| ground floor front | window centre 30 left of centre, door centre 4 left, window 22 right. Door: kraft frame 19 wide x 27 tall outer (from the pad bottom), red door #D42A20 13 x 24, yellow knob 1.6 across. |
| doorstep | toy bricks with round studs on top, in front of the door: bottom row of 4 bricks (blue, yellow, yellow, blue), each 8 wide x 6 deep x 3 tall, total 32 wide; on top one red brick 12 x 4 x 3 centred on the door. |
| pieces | one piece per pad (its windows, door and doorstep go with it): 6 pieces. |

## Rules
Blender only (no Meshy, no uploads, no Studio, no git commits, never read `.env`). Write only `tools/art/blocks.py`
and files under `assets/models/sticky-note-tower/` (never touch `concept-front.png`). No text, numbers, logos or
symbols in any texture. Look at your compare.png and fix anything that misses the picture or the sizes (max 3 rounds).
Report: pieces with triangles and front_pixels_per_stud, and one line on how close the render is to the picture.

## Fix round 1 (Claude, after compare.png)
My size table was wrong: measured properly, the picture's tower is about 62 studs wide for 190 tall (front face
~340 px against ~1085 px of height). Change: pads 62 x 62 x 31.5 (turns as before; footprint stays inside 90 x 90).
Windows: frame 15 x 15 outer, bars 2.5, glass 9.5 x 9.5, centres 15 left and right of each face centre. Ground floor
front: window centre 21 left, door centre 3 left (frame 17 x 26, red door 11 x 23), window 16 right. Doorstep: bottom
row 4 bricks each 9 wide x 7 deep x 4 tall (36 wide), red brick 14 x 5 x 4 on top, centred on the door.
Depth: bake soft ambient occlusion lightly into the colour maps (darker where pads meet, round window frames and
under the door frame) so it doesn't read flat in game. Render front.png/three-quarter.png with the concept's camera
(3/4 from slightly above, same framing) and soft shadows so compare.png is a fair side-by-side.

## Round 2 (Alan liked the look, 2026-10-15) and the other 13 buildings
sticky-note-tower fixes: pads 72 x 72 (measured again; 62 was too slim); turns clearly visible like the picture
(0, +4, -3, +4, -4, +3 degrees; footprint still inside 90 x 90 so shrink to 70 if needed); doorstep bricks as big as
the picture's (bottom row about 40 wide); DOOR KNOB at half the door's height, set in from the opening edge by about a
fifth of the door width, on the door itself (Alan: knobs off-centre is a repeated error on our models).
