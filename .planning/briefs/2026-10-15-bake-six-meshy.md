# Codex job: bake the 6 new Meshy buildings into game pieces (2026-10-15)

Six Meshy hero models are back (`assets/models/<name>/meshy.glb` + `meshy-*.png`, committed). Bake each into textured
game pieces with `tools/art/hero.py`, exactly like our existing heroes (see `assets/models/tube-tower/parts.json` for
a tall one), then check close-ups and fix Meshy's melted bits through `<name>/touchup.json` (format: docstring near
hero.py line 144). Compare against the approved pictures `concept-front.png` / `-left` / `-back` / `-top`.

| name | --height | --vertical-splits | must stay true |
|---|---|---|---|
| porthole-book-tower | 330 | ground-floor:xy,upper-walls:xy,roof:xy,topper:xy | round porthole straight through front to back, about 55 wide, from about 150 to 215 up: open, clean, see-through, no film or webbing across it |
| tissue-box-tower | 280 | ground-floor:xy,upper-walls:xy,roof:xy,topper:xy | three boxes; tissue on top reads as soft tissue, not a melted blob |
| tape-roll-tower | 270 | ground-floor:xy,upper-walls:xy,roof:xy,topper:xy | tape roll's core open straight through, about 50 wide, from about 190 to 250 up |
| juice-carton-tower | 260 | ground-floor:xy,upper-walls:xy,roof:xy,topper:xy | the bendy straw: if melted, cut it out and add a clean touch-up cylinder straw |
| cereal-box-tower | 250 | ground-floor:xy,upper-walls:xy,roof:xy,topper:xy | open flaps on top stay thin and separate, the box is open (hollow) at the top or closed with a clean inner floor, never a black hole |
| paint-jar-tower | 170 | ground-floor:xy,upper-walls:xy,roof:xy,topper:xy | three jars, lids ridged, drips |

Settings for every bake: `--front -y` unless the model's front (door) is clearly another side (then pass that side
and say so), `--detail 2.5 --min-coverage 0.33`, no `--cuts`, no `--parts`. Run like:
`& 'D:/Blender/blender.exe' -b --factory-startup --python-exit-code 1 --python tools/art/hero.py -- assets/models/<name> --height H --front -y --vertical-splits ... --detail 2.5 --min-coverage 0.33`

Rules:
- ONE bake at a time (two side by side run out of memory). Blender is at `D:/Blender/blender.exe`.
- After each bake run `tools/art/closeups.py` and look at `renders/closeups.jpg` yourself, plus your own straight-on
  render through each fly-through hole (front and back) showing the background through it. A building is done only
  when no black hole, slot, notch, melted part or skin across a hole shows.
- Every piece closed, at most 12,000 triangles, front_pixels_per_stud reported (aim 6 or more).
- Texture contact sheet per building (all its `-color.png` maps on one sheet, `renders/textures.png`): look for
  anything that could read as a letter, number, hand sign, flag, body shape or symbol (Alan's account was banned
  twice for a texture like that); run `tools/art/fill_gaps.py` like the earlier heroes did. Report anything doubtful.
- Write only inside these 6 folders and their `touchup.json`. Never touch `concept-*.png`, `meshy*`, other folders
  or `tools/`. No uploads, no Studio, no git commits, never read `.env`.
- Report per building: pieces, total triangles, lowest front_pixels_per_stud, what touchup.json changed, close-up
  path, anything still wrong.

## Part 2 (Claude, 2026-10-15): the last two, then a texture safety pass on all 8
1. When the 6 bakes above are finished (no Blender running `hero.py`), bake `pencil-case-bridge` (--height 140,
   `ground-floor:xy,upper-walls:xy,roof:xy,topper:xy`; the road gap under the case 100 wide x 95 high stays open,
   check it like the holes above) and `egg-carton-market` (--height 55, `ground-floor:xy,upper-walls:y`), same
   settings, close-ups, touch-ups and checks.
2. **Texture safety pass (all 8 buildings).** Claude's look at `tissue-box-tower/renders/textures.png` found bold
   cross-, X- and letter-like shapes on the flat colour maps (moderation reads the flat map; an upload like that got
   Alan's account banned). Upgrade `tools/art/fill_gaps.py` as its own docstring suggests: take the real UV island
   mask from each piece's UVs (rasterise them, a few pixels' bleed), and fill EVERY texel outside the islands with
   the nearest island's colour (colour, normal, roughness, metalness alike), so no shape outlines remain on a
   contrasting background. The model looks identical in game (it only samples inside islands). Keep the old
   dark-gap mode working. Run it on all pieces of the 8 buildings, then redo each `renders/textures.png`.
3. Look at every new contact sheet at full size. Report any colour map where a shape could still read as a letter,
   number, cross, hooked cross, star, hand sign or body shape, with the file name, so Claude can decide (repack,
   recolour or a hand fix) before Alan uploads.
