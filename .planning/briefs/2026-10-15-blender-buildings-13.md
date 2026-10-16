# Codex Blender job: sticky-note round 2, then the other 13 Blender-built buildings (2026-10-15)

Alan liked the Blender sample (sticky-note-tower) apart from small things. Build the rest the same way, in
`tools/art/blocks.py` (one function per building, shared helpers), same output layout, checks and renders as
`.planning/briefs/2026-10-15-blender-buildings-sample.md` (read it all, including "Round 2").

## Order
1. sticky-note-tower: apply "Round 2" in the sample brief.
2. The 13 below, one at a time, smallest first. For each: FIRST measure its approved `concept-front.png` (and the
   look of `assets/references/classroom-city-approved-v1.png`): pick one scale from the building's height below, measure
   every part in pixels, convert, and write the table to `assets/models/<name>/sizes.md`; check the sums (parts stack
   to the total height, posts x 2 + opening = outer width). The approved picture wins over anything else. Then build,
   render, compare, fix (max 3 rounds each).

## Buildings (studs: width x depth x height; front faces -Y)
| name | size | must be true |
|---|---|---|
| shoebox-hall | 120 x 70 x 55 | lid propped open as a long awning |
| chalk-box-depot | 100 x 70 x 60 | round chalk-stick columns |
| abacus-hall | 140 x 60 x 65 | two end houses; between them the frame with bead rods; the open gap between the rods is 30 wide, from 10 to 60 up, straight through front to back |
| pencil-tin-tower | 100 x 70 x 160 | one metal tin on end, lid half open as a canopy (thin real hinge) |
| ruler-stilt-tower | 90 x 90 x 180 | box room at the bottom, four ruler posts, box stack on top; open air between 70 and 120 up, straight through; ruler marks as plain ticks, NO numbers |
| log-cabin-tower | 80 x 70 x 200 | round toy logs laid log-cabin style, simple roof |
| stacking-cup-tower | 70 x 70 x 230 | five smooth cups upside down, largest at the bottom |
| jenga-tower | 70 x 70 x 240 | crossed layers of three long blocks, a few pushed out as balconies |
| ring-binder-tower | 130 x 90 x 300 | one big binder on end; two open metal rings on the roof, the gap through them 45 wide, from 245 to 295 up, straight through front to back |
| pencil-pillar-tower | 90 x 90 x 345 | stacked cardboard boxes held by real pencil columns (hexagonal, painted, sharpened tips at the roof) |
| block-arch | 260 wide x 30 deep x 130 tall | a gate over a road: two block piers and one curved arch block; the road opening 160 wide and 86 high in the middle, clear |
| monorail-station-north | 170 wide x 70 deep x 150 tall | gate over a road on two legs; road opening 88 wide x 80 high; a tunnel through the top floor from front to back, 30 wide, from 112 to 146 up (the monorail beam, top at 125, runs through it) |
| monorail-station-south | 170 wide x 70 deep x 150 tall | same openings as the north station, built as its picture (metal tin + toy-brick legs) |

## Rules for every building
- Every opening above is open air, clean and see-through in renders from front and back; nothing (film, rod, glass)
  across it. Solid parts are closed meshes (they become collision).
- DOOR KNOBS at half the door's height, set in from the opening edge by about a fifth of the door width, on the door
  itself (Alan: off-centre knobs keep happening).
- No text, letters, numbers, logos or symbols in any texture.
- Blender only: no Meshy, no uploads, no Studio, no git commits, never read `.env`. Write only `tools/art/blocks.py`
  and files in these 14 folders (never touch `concept-*.png`). Another Codex job is baking Meshy buildings in 6
  other folders: never touch them; if Blender runs out of memory, wait and retry.
- Report per building: pieces, triangles, lowest front_pixels_per_stud, compare.png path, anything still off.
