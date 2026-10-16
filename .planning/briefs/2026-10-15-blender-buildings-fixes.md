# Codex Blender job: Alan's fixes to the Blender-built buildings (2026-10-15)

Alan looked at every compare.png (`assets/rug/replan-v3-blender.jpg`). sticky-note-tower is right; leave it. Fix the
others in `tools/art/blocks.py`, same output, checks and renders as before
(`.planning/briefs/2026-10-15-blender-buildings-13.md`). **The approved concept picture is the target: match it.**
Re-measure each picture into its `sizes.md` where the build drifted.

## Rules for all of them (Alan's general notes)
- **Build the separate objects the picture shows**, never one merged block: stacked boxes sit ON each other with
  visible joins, lips and overhangs, tape strips where they meet; blocks are separate blocks with gaps.
- **Cardboard shows its corrugated edge**: wherever a cut edge of cardboard shows (box rims, flaps, lids, openings),
  model the wavy flute layer between the two liners (the "honeycomb" side profile), plus real cardboard surface
  texture (fibres, slight creases, tape).
- **Texture and shading on everything**: wood grain and end grain, cardboard fibres, metal shine and edge wear, plastic
  gloss, soft baked occlusion where parts meet. Nothing flat-coloured.
- Windows, doors and frames stand proud of the wall like the picture (a wooden block's window sticks out).
- Door knobs at half the door's height, set in from the opening edge, on the door (lesson).
- Parts face the way the picture shows (rings, hinges, lids).

## Per building
| name | fix |
|---|---|
| shoebox-hall | Looks very off: rebuild to match the picture (box proportions, lid propped as a long awning on its posts, windows, door, bricks, cardboard edges and texture). |
| chalk-box-depot | Doors as in the picture; corrugated cardboard edges on the box rim; more texture; the box's top lip thicker so the chalk ends are hidden behind it. |
| abacus-hall | The abacus top bar sits UNDER the two houses' roofs and joins house to house (today it floats). Frame and rods connect into the house walls. |
| block-arch | Three separate wooden blocks: two piers and a real curved arch block resting on top of them (a proper arch shape, not a flat bar; keep the road opening about 160 wide and 86 high, so make the arch block taller if needed). Windows stick out like on a wooden block. Wood grain, end grain, shading. |
| monorail-station-north | Very off. Three boxes: two stand boxes and a top box resting on them, overhanging with a lip and taped to them, like the picture. The track opening through the top box must be as big as the picture's (about a third of the top box's width and most of its height, at least 60 wide and from about 100 to 142 up), straight through front to back. No rail inside (the rail is made elsewhere and passes through). All the picture's details: toy-brick trims, tape, cardboard texture and edges. |
| monorail-station-south | Track opening the same size and height as the north station. The top must read as a real lunch tin (rounded tin body, rolled rim, lid seam, hinges, clasp, metal shine) sitting on the toy-brick legs, not a sheet of metal on a block. Match its picture. |
| pencil-tin-tower | Touch up toward its picture (tin edges, rolled rim, hinge, canopy, windows). |
| ruler-stilt-tower | Fine; give the boxes a real cardboard look (texture, corrugated edges, tape). |
| log-cabin-tower | Logs go all the way up to the roof, including the gable ends under it; only the two roof slopes are cardboard. |
| stacking-cup-tower | Each cup's rolled lip clearly visible; windows wider, like the picture. |
| jenga-tower | Individual blocks with clear gaps between them (it reads as one block today); wood grain and end grain. |
| ring-binder-tower | Turn the rings 90 degrees to face the way the picture shows; make them real metallic binder rings (round wire, shiny metal, hinged clasp), not plain hoops; keep the fly-through gap. More binder texture (cover grain, spine). |
| pencil-pillar-tower | Pencil tips show the sharpened wood cone AND the dark graphite point; more texture and shading overall. |

## Rules
Blender only: no Meshy, no uploads, no Studio, no git commits, never read `.env`. Write only `tools/art/blocks.py` and
files in these 13 folders (never touch `concept-*.png`, never sticky-note-tower). Another Codex job is baking Meshy
buildings in other folders: never touch them; if Blender runs out of memory, wait and retry. Look at each compare.png
yourself and fix until it matches the picture (max 3 rounds each). Report per building: what changed, triangles,
lowest front_pixels_per_stud, anything still off.
