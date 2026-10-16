# Modular plane set

23 parts: five bodies, five noses, five paired wing sets, five tails and three boosters.
All use the existing Classic slot pivots and plain colour-region FBX contract.

## Rebuild

From D:/FlyFightPaper in PowerShell:

```powershell
& D:/Blender/blender.exe -b --factory-startup --threads 4 --python-exit-code 1 --python tools/art/plane_set.py
```

Only Blender's built-in Python, NumPy and the existing planes.py helpers are needed.
The command rebuilds the FBXs, manifests, Blender source and every review image in this folder.
It only reads classic/. It does not upload assets or change the game.

## Dimensions and triangle totals

Sizes are assembled Roblox X / Y / Z in studs. Triangle totals include every colour region.

| Catalog id | Name | Size X / Y / Z | Triangles |
|---|---|---|---:|
| body_slim | Swift Fold | 2.6000 / 2.2500 / 8.0223 | 204 |
| body_heavy | Cardboard Gunship | 5.2553 / 3.3750 / 8.0223 | 324 |
| body_standard_mk2 | Courier Fold | 2.6459 / 2.2500 / 8.0223 | 250 |
| body_slim_mk2 | Racing Fold | 2.6000 / 2.2500 / 8.0223 | 244 |
| body_heavy_mk2 | Toilet Roll Gunship | 3.6000 / 3.5400 / 8.0223 | 1104 |
| nose_1 | Needle Nose | 2.6000 / 2.2500 / 6.6500 | 158 |
| nose_2 | Blunt Nose | 2.6000 / 2.2500 / 2.7200 | 104 |
| nose_3 | Long Point | 2.6000 / 2.2500 / 6.1200 | 158 |
| nose_4 | Compact Nose | 2.6000 / 2.2500 / 3.2200 | 158 |
| nose_5 | Tape Nose | 2.6000 / 2.2500 / 4.8500 | 298 |
| wings_1 | Swept Wings | 14.8000 / 0.2280 / 7.9864 | 84 |
| wings_2 | Broad Wings | 16.8000 / 0.2280 / 6.8864 | 84 |
| wings_3 | Delta Wings | 14.5000 / 0.2280 / 7.7664 | 84 |
| wings_4 | Cardstock Wings | 13.5430 / 1.3800 / 7.0864 | 200 |
| wings_5 | Feather Folds | 15.9000 / 0.3050 / 7.1064 | 596 |
| tail_1 | Split Tail | 2.1770 / 2.9588 / 2.2341 | 234 |
| tail_2 | Ridge Tail | 1.5900 / 2.9400 / 2.2341 | 240 |
| tail_3 | Wide Tail | 5.8000 / 2.9400 / 2.2341 | 358 |
| tail_4 | Guide Fin | 1.5900 / 4.1800 / 2.2341 | 168 |
| tail_5 | Tape Tail | 1.6131 / 2.9400 / 2.2341 | 334 |
| boost_band | Elastic Booster | 1.2700 / 1.0050 / 2.5350 | 242 |
| boost_spool | Spool Booster | 1.2700 / 1.0150 / 2.5350 | 384 |
| boost_twin | Twin Elastic Booster | 1.6700 / 1.0050 / 2.5350 | 344 |

## Assembly and choices

- Nose/body seam: Z=-2.606415929. New tail/body seam: Z=5.415929204. The outer and inner rim profiles exactly match Classic.
- Keep each region's center_offset_from_slot. All structural slot_pivot values are copied from classic/parts.json.
- Slim main shoulders are 1.30 studs wide, half Classic; their sockets remain 2.60 wide. The fixed two seams keep body length at 8.0223 studs. The narrow uninterrupted core gives the longer appearance without moving either join.
- Cardboard Gunship (body_heavy) retains its 5.20-wide shoulders and 3.375 depth. A neck tapers to the shared rear section.
- Cardboard Gunship's corrugation is a few visible folded zigzag rails, with two taped corner pads. Plain colours replace the grain and tiny individual flutes in the painting.
- Cardboard Gunship keeps its original square starter clearance bores. Toilet Roll has an uncut round wall; its starter clearance checks use the outward mount shift from the catalog. All checks retain the same radius, margin and 33 samples per axis.
- Toilet Roll Gunship (body_heavy_mk2) is an empty 24-sided cardboard tube, radius 1.75, centred at Y=-.25, with a .085 wall. Its open rims show discs recessed .35 and unchanged Classic socket joins. One raised spiral seam winds 1.25 turns; two .35-wide, .02-thick ragged paper strips follow opposite sides from the top, then hang freely .7-.8 studs below their attachment edges. The rear .25-wide accent band takes team colour.
- All wings have the Classic centre saddle at Y=.95 with its bottom at .85. Outer silhouettes differ; Cardstock has real upright tips and a brown backing. Feather Folds has three overlapping paper feather layers on each side, with rounded accent tips stepping back and shorter.
- New tails meet the whole Classic rear rim. Classic Tail itself is unchanged and retains its original smaller upper plug and slight overlap. Keeping every body's Classic rear neck preserves that compatibility.
- Booster pivots use each body's profile at Z=3.25. The original five anchors remain below the underside; the Toilet Roll anchor is above its top so the unchanged booster tray clears the band and seam. booster_body_pivots supplies all six anchors; booster_pivots and each export's slot_pivot use Classic as the default. Translate every booster region by its body anchor minus the default anchor, preserving center_offset_from_slot.
- Only booster positioning varies by body; all four existing structural pivots stay exactly the same.
- Elastic twists and the ribbed wound spool are deliberately coarse solid facets. All assets use colour only, with no textures, images, UVs or runtime geometry.
- The shared Classic joins take priority over the rectangular conceptual plugs. No separate conceptual plug is added to a nose or tail.
- region=accent is the only region marked team_color_at_runtime. The tube region is light grey-brown RGB 184,154,118 and belongs only to Toilet Roll; cardboard, paper, tape and elastic keep their suggested colours.

## Checks and review

validation.json records source and saved-FBX closed topology, consistent normals, positive volume, nondegenerate triangles, self-intersections, raw stud-scale bounds and Blender re-imports.
It also records shared seam rim checks, every nose/body pairing, every new tail/body pairing, wing saddle heights and tube clearance along 33 points per axis for every part.
All 18 body/booster pairings are checked for body intersections, excluding the short tape straps that intentionally tuck into the belly. Every isolated review render is checked for transparent margins so no fin or tip can be cropped.
The complete colour-region triangle count is strictly below 400 for every part except body_heavy_mk2, whose explicit per-part limit is 1200. Both limits are recorded in validation.json. Classic files and planes.py are hashed before and after and must be unchanged.

Review: renders/<catalog id>.png (23 isolated three-quarter views), parts-review.png, mixes.png (four builds beside their concept panels), joins.png (slim/heavy seam close-ups).
plane-set.blend contains all asset meshes and read-only imported Classic review pieces. FBXs contain only their named single-region mesh.
These are local asset deliverables; Roblox import and in-game appearance are for the later integration review.
