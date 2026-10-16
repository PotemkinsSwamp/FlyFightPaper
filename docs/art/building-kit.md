# Classroom building kit (Alan's go, 2026-10-09)

**Why:** Meshy buildings (even the sweet shop, made from 4 views at 4K) look soft and blended in Roblox: one painted
texture per piece, capped at 1024 px, plus decimated shapes. Detailed Roblox games build from clean modular geometry
with crisp colours and repeating materials. Alan approved trying a kit, styled ONLY on
`assets/references/classroom-city-approved-v1.png` (never on the current in-game buildings).

## The kit (Codex builds it in Blender: `tools/art/kit.py`, outputs `assets/models/kit/`)
Classroom things make up the buildings, as in the reference:
- **Cardboard:** wall panels (corrugated face, visible fluted cut edges), box corners, flaps, tape strips and patches.
- **Toy bricks:** 1x1, 2x2, 2x4 with studs (corner quoins, roof edges, trims), in the reference's red/blue/green/yellow.
- **Pencils:** columns and railings (hexagonal, painted, sharpened tip or eraser end with metal band).
- **Rulers:** ledges, canopies, bridges (wood with printed marks).
- **Books:** stacked floor slabs and towers (cloth covers, page edges, spine bands).
- **Crayons, paper flags and bunting, push pins, paper cut-outs** for rooftops and signs.
- **Openings:** arched and square window frames with sills and flower boxes, doors, shop windows, awnings (scalloped).
Surfaces: real geometry for frames, ledges and bricks; large surfaces use small **repeating** materials (corrugated
cardboard, book cloth, paper, plastic) as Roblox MaterialVariants or tiling SurfaceAppearances, so they stay sharp up
close. Bold, clean, slightly Roblox-like colours. Triangle budget per piece small, since pieces repeat (instances).

## Who makes which piece (Alan asked to use Meshy where it can look good, 2026-10-09)
- **Blender (Codex):** pieces that must fit together exactly or repeat: cardboard wall panels, window and door
  frames, ledges, toy bricks, roof edges, awnings, book slabs, ruler ledges.
- **Meshy (image-to-3D, ~30 credits each, concept pictures from Codex):** small detailed props where one 1024
  texture covers only a few studs, so it stays sharp: sharpened pencils, crayons, glue bottle, pencil cup, tape roll,
  scissors, push pins, paper flowers / plants for window boxes, cupcakes and sweets, little toy figures, origami
  crane, rooftop signs. Also the room-finish list (globe, desk lamp, backpack, planets). Budget ~300-450 credits for
  kit props; check each in Studio before making more of the same kind.

## Building maker
`tools/art/kit.py` assembles a building from a short recipe (width, depth, floors, window style/count per floor,
door/shop front, awning colour, roof dressing, trims) and exports pieces + a placement list for
`tools/town_toys.py` (same `stand` flow as the hero pieces).

## Test (first step)
Build the kit, then the **sweet shop** from it (reuse the Meshy lollipop and cupcake sign from
`assets/models/sweet-shop/parts/4-topper` if they fit). Place it beside the Meshy sweet shop in the test copy and show
Alan both, close up and from the air. If the kit shop wins, it becomes the method for redoing the city (Stage 4d);
if not, fall back to Meshy hero buildings with tighter UV packing (`tools/art/hero.py`, 20% texture use today).
Codex time estimate (not measured): kit + first shop 1-2 h; later buildings 15-30 min each. No Meshy credits.

## Related
- [Art pipeline](pipeline.md) · [Model catalog](models.md) · [Reference pictures](references.md)

Back to [HOME](../HOME.md)
