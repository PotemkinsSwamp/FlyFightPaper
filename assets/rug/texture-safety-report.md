# Texture safety report

Reviewed 2026-10-16. Part 2 continuation for the 2026-10-15 bake brief.

## Where it stands

Finished the fresh egg-carton-market bake, the five requested Meshy UV-fill passes, all 14 named Blender-building passes, and the full-size inspection of every regenerated sheet. No bake, fill, or preservation check failed. No named building was skipped for missing scene data or UVs.

Possible letter, number, cross, star and body-like shapes remain in 133 of the 215 colour maps. These are conservative visual flags, including faint and borderline readings. The filenames and locations below are for Claude to assess. UV gap filling preserves the mapped surface colours, so it cannot remove every shape already inside an island. No hand sign or hooked cross was identified in the 19 newly reviewed buildings.

The market topper is below the brief's aim of 6 front pixels per stud, at 4.109. Small red texture flecks below the corner roof trim and slightly jagged window-frame texture edges also remain visible in close-ups. These are recorded for review.

Nothing was uploaded, no Meshy credits were used, no Studio session was opened, and this job made no commit. Blender ran headless, one process at a time.

## Market rebake

The interrupted pieces were deleted first. The market was then baked from scratch at height 55 with front -y, vertical splits ground-floor:xy,upper-walls:y, detail 2.5 and minimum coverage 0.33. No explicit cuts or part count were supplied. The existing closed-mesh bake adapter was used without editing it or the shared tools.

| Check | Result |
|---|---|
| Pieces | 8 |
| Total triangles | 43,268 |
| Largest piece | 10,000 triangles, below 12,000 |
| Closed geometry | All pieces have zero boundary/nonmanifold edges |
| Height | 55 studs |
| UVs | No overlap; minimum coverage 0.4245; padding 4 pixels |
| Lowest front_pixels_per_stud | 4.109, 8-topper |
| Other pieces | 6.645 or higher |
| Saved geometry/UV verification | PASS |
| touchup.json changes | None; no structural addition or removal was needed |

Compared the source and baked model with the approved concept views. Checked the close-ups and straight front/back renders: the closed roof and four separate shopfronts/awnings remain recognizable. No black hole, missing roof section or melted structural feature was identified. The brief does not specify a fly-through opening for this building, so a through-hole ray test does not apply.

Evidence: [parts and density measurements](../models/egg-carton-market/parts.json), [close-ups](../models/egg-carton-market/renders/closeups.jpg), [straight front](../models/egg-carton-market/renders/straight-front.png), [straight back](../models/egg-carton-market/renders/straight-back.png), [saved geometry/UV check](../models/egg-carton-market/renders/part2-verify.log).

## UV fill and contact sheets

Ran the existing command for each building in the table, in the requested order:

```text
python tools/art/fill_gaps.py assets/models/<building>/parts --uv --all --blender D:/Blender/blender.exe
```

All 645 existing maps were covered: colour, normal and roughness. No metalness/metallic maps existed in these targets. The three-pixel protected bleed and every pixel inside the real UV islands stayed byte-identical. Map dimensions and colour modes stayed unchanged. During each fill, the saved scene, parts manifest and FBX files stayed unchanged. Each row links to its preservation record.

Rebuilt and viewed all 57 contact sheets: textures.png, textures-normal.png and textures-roughness.png for each building. Each tile is the original 1024 by 1024 map, with no resizing. Each sheet is 4096 pixels wide, with 34-pixel filename strips above the map rows. The findings below refer to colour maps; all three channel sheets were inspected at original size.

Juice, cereal and paint fills completed without changing map bytes because those maps were already filled. The bridge changed 48 maps, the market 24, and the 14 Blender buildings 429.

| Building | Pieces / colour maps | All maps | Changed maps | UV fill | Preservation record |
|---|---:|---:|---:|---|---|
| juice-carton-tower | 16 | 48 | 0 | Passed | [checks](../models/juice-carton-tower/renders/part2-texture-checks.json) |
| cereal-box-tower | 16 | 48 | 0 | Passed | [checks](../models/cereal-box-tower/renders/part2-texture-checks.json) |
| paint-jar-tower | 16 | 48 | 0 | Passed | [checks](../models/paint-jar-tower/renders/part2-texture-checks.json) |
| pencil-case-bridge | 16 | 48 | 48 | Passed | [checks](../models/pencil-case-bridge/renders/part2-texture-checks.json) |
| egg-carton-market | 8 | 24 | 24 | Passed | [checks](../models/egg-carton-market/renders/part2-texture-checks.json) |
| sticky-note-tower | 6 | 18 | 18 | Passed | [checks](../models/sticky-note-tower/renders/part2-texture-checks.json) |
| pencil-pillar-tower | 15 | 45 | 45 | Passed | [checks](../models/pencil-pillar-tower/renders/part2-texture-checks.json) |
| ring-binder-tower | 16 | 48 | 48 | Passed | [checks](../models/ring-binder-tower/renders/part2-texture-checks.json) |
| jenga-tower | 13 | 39 | 39 | Passed | [checks](../models/jenga-tower/renders/part2-texture-checks.json) |
| stacking-cup-tower | 5 | 15 | 15 | Passed | [checks](../models/stacking-cup-tower/renders/part2-texture-checks.json) |
| log-cabin-tower | 7 | 21 | 21 | Passed | [checks](../models/log-cabin-tower/renders/part2-texture-checks.json) |
| ruler-stilt-tower | 8 | 24 | 24 | Passed | [checks](../models/ruler-stilt-tower/renders/part2-texture-checks.json) |
| pencil-tin-tower | 8 | 24 | 24 | Passed | [checks](../models/pencil-tin-tower/renders/part2-texture-checks.json) |
| abacus-hall | 7 | 21 | 21 | Passed | [checks](../models/abacus-hall/renders/part2-texture-checks.json) |
| chalk-box-depot | 6 | 18 | 18 | Passed | [checks](../models/chalk-box-depot/renders/part2-texture-checks.json) |
| shoebox-hall | 5 | 15 | 15 | Passed | [checks](../models/shoebox-hall/renders/part2-texture-checks.json) |
| block-arch | 6 | 18 | 18 | Passed | [checks](../models/block-arch/renders/part2-texture-checks.json) |
| monorail-station-north | 17 | 51 | 51 | Passed | [checks](../models/monorail-station-north/renders/part2-texture-checks.json) |
| monorail-station-south | 24 | 72 | 72 | Passed | [checks](../models/monorail-station-south/renders/part2-texture-checks.json) |

## Blender inventory and skips

The 14 processed Blender buildings actually found were sticky-note-tower, pencil-pillar-tower, ring-binder-tower, jenga-tower, stacking-cup-tower, log-cabin-tower, ruler-stilt-tower, pencil-tin-tower, abacus-hall, chalk-box-depot, shoebox-hall, block-arch, monorail-station-north and monorail-station-south. Every one had hero.blend, a parts folder and usable saved piece UVs. No UV-related skips.

The filename predicate also found a fifteenth folder, bell-tower. It was outside the 14 named targets and had unrelated work already in progress, so it was left untouched. Its maps are not included in this review.

The already completed porthole-book-tower, tissue-box-tower and tape-roll-tower passes were not repeated. Their earlier 45 doubtful-map findings remain in the [previous review](../models/egg-carton-market/renders/part2-report.md). The pencil-case-bridge bake was not repeated.

## Colour maps still doubtful

Locations are within the individual 1024 by 1024 map as shown on the sheet. A listed shape is a possible reading of the flat map, including fills outside the UV islands. "Clean" means no requested shape was identified during this review. Unlisted maps within each building are clean by that definition.

### juice-carton-tower

[Colour sheet](../models/juice-carton-tower/renders/textures.png), [normal sheet](../models/juice-carton-tower/renders/textures-normal.png), [roughness sheet](../models/juice-carton-tower/renders/textures-roughness.png).

- [1-ground-floor-front-left-color.png](../models/juice-carton-tower/parts/1-ground-floor-front-left-color.png): Cream upright frame at right reads as H/P; small rectangular O-like frame at lower left.
- [2-ground-floor-front-right-color.png](../models/juice-carton-tower/parts/2-ground-floor-front-right-color.png): Cream angular branches in the upper half can read as a bent K/Y.
- [3-ground-floor-back-left-color.png](../models/juice-carton-tower/parts/3-ground-floor-back-left-color.png): Cream square window outline at lower left reads as O/C.
- [4-ground-floor-back-right-color.png](../models/juice-carton-tower/parts/4-ground-floor-back-right-color.png): Blue upright with a right arm reads as T; cream U-shaped frame at the bottom.
- [5-upper-walls-front-left-color.png](../models/juice-carton-tower/parts/5-upper-walls-front-left-color.png): Large cream two-lobed B-like form at centre right.
- [6-upper-walls-front-right-color.png](../models/juice-carton-tower/parts/6-upper-walls-front-right-color.png): Cream F-like upright and hook at lower centre.
- [7-upper-walls-back-left-color.png](../models/juice-carton-tower/parts/7-upper-walls-back-left-color.png): Cream square C-like frame and green F-like branches at right.
- [8-upper-walls-back-right-color.png](../models/juice-carton-tower/parts/8-upper-walls-back-right-color.png): Cream T-like junction at top and U-like window frames down the left.
- [9-roof-front-left-color.png](../models/juice-carton-tower/parts/9-roof-front-left-color.png): Cream angular C/U-like hook near the lower edge.
- [10-roof-front-right-color.png](../models/juice-carton-tower/parts/10-roof-front-right-color.png): Cream T-like neck and shoulders near the upper left.
- [13-topper-front-left-color.png](../models/juice-carton-tower/parts/13-topper-front-left-color.png): Red rectangular P/U-like frame across the upper middle.
- [14-topper-front-right-color.png](../models/juice-carton-tower/parts/14-topper-front-right-color.png): Thin white/red stacked bars near the top right can read as E/F-like strokes.
- [15-topper-back-left-color.png](../models/juice-carton-tower/parts/15-topper-back-left-color.png): Large red X-like crossing in the lower right.
- [16-topper-back-right-color.png](../models/juice-carton-tower/parts/16-topper-back-right-color.png): Large red Y-like branching junction across the centre.

Remaining colour maps: 2 clean.

### cereal-box-tower

[Colour sheet](../models/cereal-box-tower/renders/textures.png), [normal sheet](../models/cereal-box-tower/renders/textures-normal.png), [roughness sheet](../models/cereal-box-tower/renders/textures-roughness.png).

- [1-ground-floor-front-left-color.png](../models/cereal-box-tower/parts/1-ground-floor-front-left-color.png): Tan H-like window joins at lower left and large diagonal N-like brace across the centre.
- [2-ground-floor-front-right-color.png](../models/cereal-box-tower/parts/2-ground-floor-front-right-color.png): Tan H-like grid at left; cream T/F-like upright just left of centre.
- [3-ground-floor-back-left-color.png](../models/cereal-box-tower/parts/3-ground-floor-back-left-color.png): Cream/tan H-like window framing across the upper half; black V-like patches at the top.
- [4-ground-floor-back-right-color.png](../models/cereal-box-tower/parts/4-ground-floor-back-right-color.png): Cream H-like bars between paired blue windows on the right.
- [5-upper-walls-front-left-color.png](../models/cereal-box-tower/parts/5-upper-walls-front-left-color.png): Strong black X at upper left and broad tan H-like grid below it.
- [6-upper-walls-front-right-color.png](../models/cereal-box-tower/parts/6-upper-walls-front-right-color.png): Black F-like arrangement across the upper right; tan H-like framing at left.
- [7-upper-walls-back-left-color.png](../models/cereal-box-tower/parts/7-upper-walls-back-left-color.png): Black Y-like fork at the top centre; tan H-like joins around the blue windows.
- [8-upper-walls-back-right-color.png](../models/cereal-box-tower/parts/8-upper-walls-back-right-color.png): Black J-like hook in the upper right and cream T-like joins near the centre.
- [9-roof-front-left-color.png](../models/cereal-box-tower/parts/9-roof-front-left-color.png): Paired black lobes at upper right can read as a blocky B; tan L-like trim below.
- [10-roof-front-right-color.png](../models/cereal-box-tower/parts/10-roof-front-right-color.png): Tall black 1-like patch at upper right; tan L-like frame near the bottom left.
- [11-roof-back-left-color.png](../models/cereal-box-tower/parts/11-roof-back-left-color.png): Joined black blocks at centre/right can read as H; cream T-like strip below.
- [12-roof-back-right-color.png](../models/cereal-box-tower/parts/12-roof-back-right-color.png): Large black inverted-L/P-like junction along the upper/right edges.
- [13-topper-front-left-color.png](../models/cereal-box-tower/parts/13-topper-front-left-color.png): Cream H-like frame near the lower centre.
- [14-topper-front-right-color.png](../models/cereal-box-tower/parts/14-topper-front-right-color.png): Cream/tan H-like paired frame near the lower left.
- [15-topper-back-left-color.png](../models/cereal-box-tower/parts/15-topper-back-left-color.png): Cream H/T-like joins around the central framed panels.
- [16-topper-back-right-color.png](../models/cereal-box-tower/parts/16-topper-back-right-color.png): Cream/tan H-like framing in the upper middle and down the right.

Every colour map in this building is flagged.

### paint-jar-tower

[Colour sheet](../models/paint-jar-tower/renders/textures.png), [normal sheet](../models/paint-jar-tower/renders/textures-normal.png), [roughness sheet](../models/paint-jar-tower/renders/textures-roughness.png).

- [1-ground-floor-front-left-color.png](../models/paint-jar-tower/parts/1-ground-floor-front-left-color.png): Strong black Y-like fork on the right; blue T-like join near the upper left.
- [2-ground-floor-front-right-color.png](../models/paint-jar-tower/parts/2-ground-floor-front-right-color.png): Yellow H-like branches across the middle and cream U-like frame.
- [3-ground-floor-back-left-color.png](../models/paint-jar-tower/parts/3-ground-floor-back-left-color.png): Dark brown A/F-like branch at lower left.
- [4-ground-floor-back-right-color.png](../models/paint-jar-tower/parts/4-ground-floor-back-right-color.png): Dark brown Y-like fork across the middle.
- [5-upper-walls-front-left-color.png](../models/paint-jar-tower/parts/5-upper-walls-front-left-color.png): Cream F/T-like strip at centre left and H-like join at lower right.
- [6-upper-walls-front-right-color.png](../models/paint-jar-tower/parts/6-upper-walls-front-right-color.png): Blue T-like horizontal/vertical join across the lower middle.
- [7-upper-walls-back-left-color.png](../models/paint-jar-tower/parts/7-upper-walls-back-left-color.png): Cream H-like frame at lower right.
- [8-upper-walls-back-right-color.png](../models/paint-jar-tower/parts/8-upper-walls-back-right-color.png): Blue cross/T-like join through the centre; cream P/O-like window frame at right.
- [9-roof-front-left-color.png](../models/paint-jar-tower/parts/9-roof-front-left-color.png): Broad blue X-like diagonal junction between the black patches.
- [10-roof-front-right-color.png](../models/paint-jar-tower/parts/10-roof-front-right-color.png): Broad blue cross-like junction with a curved arm.
- [11-roof-back-left-color.png](../models/paint-jar-tower/parts/11-roof-back-left-color.png): Large blue C-like bend around the central black patch.
- [12-roof-back-right-color.png](../models/paint-jar-tower/parts/12-roof-back-right-color.png): Blue X/Y-like junction across the upper middle.
- [13-topper-front-left-color.png](../models/paint-jar-tower/parts/13-topper-front-left-color.png): Red H/F-like joined bars near the lower centre and cream O-like frame.
- [14-topper-front-right-color.png](../models/paint-jar-tower/parts/14-topper-front-right-color.png): Cream C-like hook at lower left and cream/red O-like frame at left centre.
- [15-topper-back-left-color.png](../models/paint-jar-tower/parts/15-topper-back-left-color.png): Red X-like crossing in the lower left.
- [16-topper-back-right-color.png](../models/paint-jar-tower/parts/16-topper-back-right-color.png): Large red X-like crossing through the middle.

Every colour map in this building is flagged.

### pencil-case-bridge

[Colour sheet](../models/pencil-case-bridge/renders/textures.png), [normal sheet](../models/pencil-case-bridge/renders/textures-normal.png), [roughness sheet](../models/pencil-case-bridge/renders/textures-roughness.png).

- [1-ground-floor-front-left-color.png](../models/pencil-case-bridge/parts/1-ground-floor-front-left-color.png): Green E-like bars at lower right; yellow U-like window surround in the middle.
- [2-ground-floor-front-right-color.png](../models/pencil-case-bridge/parts/2-ground-floor-front-right-color.png): Red M-like fork along the top and green E-like bars at lower centre.
- [3-ground-floor-back-left-color.png](../models/pencil-case-bridge/parts/3-ground-floor-back-left-color.png): Yellow Y-like branch at upper right, blue Y-like branch centrally, cream Z-like diagonal at lower left.
- [4-ground-floor-back-right-color.png](../models/pencil-case-bridge/parts/4-ground-floor-back-right-color.png): Small cream X in the middle beneath the blue/green framing.
- [5-upper-walls-front-left-color.png](../models/pencil-case-bridge/parts/5-upper-walls-front-left-color.png): Broad red T-like junction through the centre.
- [6-upper-walls-front-right-color.png](../models/pencil-case-bridge/parts/6-upper-walls-front-right-color.png): Red T-like upright through the middle and blue X-like crossing at lower left.
- [7-upper-walls-back-left-color.png](../models/pencil-case-bridge/parts/7-upper-walls-back-left-color.png): Blue H-like frame in the lower middle; red U-like patch below it.
- [8-upper-walls-back-right-color.png](../models/pencil-case-bridge/parts/8-upper-walls-back-right-color.png): Large red T-like angled join in the upper middle and blue X-like join below.
- [9-roof-front-left-color.png](../models/pencil-case-bridge/parts/9-roof-front-left-color.png): Strong black Y-like fork on the right.
- [10-roof-front-right-color.png](../models/pencil-case-bridge/parts/10-roof-front-right-color.png): Tall black angular hook/B-like silhouette in the centre.
- [11-roof-back-left-color.png](../models/pencil-case-bridge/parts/11-roof-back-left-color.png): Large black T-like join between the broad lower patch and upright at right.
- [12-roof-back-right-color.png](../models/pencil-case-bridge/parts/12-roof-back-right-color.png): Black T/F-like join between the broad left patch and upright at right.
- [13-topper-front-left-color.png](../models/pencil-case-bridge/parts/13-topper-front-left-color.png): Blue P/O-like field with a square opening; cream X-like window braces near the top left.
- [14-topper-front-right-color.png](../models/pencil-case-bridge/parts/14-topper-front-right-color.png): Tilted blue A-like outline with a square opening and yellow A-like diagonal frame.
- [15-topper-back-left-color.png](../models/pencil-case-bridge/parts/15-topper-back-left-color.png): Blue P/O-like outline with a central opening and cream X-like brace at right.
- [16-topper-back-right-color.png](../models/pencil-case-bridge/parts/16-topper-back-right-color.png): Tilted blue A-like outline and cream X-like window brace above it.

Every colour map in this building is flagged.

### egg-carton-market

[Colour sheet](../models/egg-carton-market/renders/textures.png), [normal sheet](../models/egg-carton-market/renders/textures-normal.png), [roughness sheet](../models/egg-carton-market/renders/textures-roughness.png).

- [1-ground-floor-front-left-color.png](../models/egg-carton-market/parts/1-ground-floor-front-left-color.png): Tan H-like wall/window join at centre left; blue sideways 8/bow-tie shape near the upper centre.
- [2-ground-floor-front-right-color.png](../models/egg-carton-market/parts/2-ground-floor-front-right-color.png): Tan H-like wall join across the upper middle; green pinched, body-like silhouette below centre.
- [3-ground-floor-back-left-color.png](../models/egg-carton-market/parts/3-ground-floor-back-left-color.png): Tan T/H-like wall joins at left; long grey C-like bend down the left half.
- [4-ground-floor-back-right-color.png](../models/egg-carton-market/parts/4-ground-floor-back-right-color.png): Large dark grey F-like upright and crossbar on the right; tan H-like wall join centrally.
- [5-upper-walls-front-color.png](../models/egg-carton-market/parts/5-upper-walls-front-color.png): Tan X/Y-like diagonal junctions across the centre and lower left.
- [6-upper-walls-back-color.png](../models/egg-carton-market/parts/6-upper-walls-back-color.png): Tan K/Y-like branches around the left of the large black rectangle; E-like bars near the bottom right.
- [8-topper-color.png](../models/egg-carton-market/parts/8-topper-color.png): Repeated pale ring/O/0-like outlines from the carton cones, including a paired 8-like cluster near lower centre.

Remaining colour maps: 1 clean.

### sticky-note-tower

[Colour sheet](../models/sticky-note-tower/renders/textures.png), [normal sheet](../models/sticky-note-tower/renders/textures-normal.png), [roughness sheet](../models/sticky-note-tower/renders/textures-roughness.png).

- [1-yellow-ground-pad-color.png](../models/sticky-note-tower/parts/1-yellow-ground-pad-color.png): Red Y-like fork in the upper right, above the small blue/yellow fittings.

Remaining colour maps: 5 clean.

### pencil-pillar-tower

[Colour sheet](../models/pencil-pillar-tower/renders/textures.png), [normal sheet](../models/pencil-pillar-tower/renders/textures-normal.png), [roughness sheet](../models/pencil-pillar-tower/renders/textures-roughness.png).

- [1-pencil-supported-box-1-1-color.png](../models/pencil-pillar-tower/parts/1-pencil-supported-box-1-1-color.png): Two faint dark rectangles stacked inside the red patch at upper left can read as B/8-like blocks.

Remaining colour maps: 14 clean.

### ring-binder-tower

[Colour sheet](../models/ring-binder-tower/renders/textures.png), [normal sheet](../models/ring-binder-tower/renders/textures-normal.png), [roughness sheet](../models/ring-binder-tower/renders/textures-roughness.png).

- [3-standing-binder-band-1-3-color.png](../models/ring-binder-tower/parts/3-standing-binder-band-1-3-color.png): Two faint dark squares in the red patch at lower right read as 8/B-like blocks; cream upright beside them has a small head/shoulders or pawn-like silhouette.
- [15-left-open-metal-ring-color.png](../models/ring-binder-tower/parts/15-left-open-metal-ring-color.png): Low-contrast grey squared U/L-like ring outline across the lower half.
- [16-right-open-metal-ring-color.png](../models/ring-binder-tower/parts/16-right-open-metal-ring-color.png): Low-contrast grey squared U/L-like ring outline across the lower half.

Remaining colour maps: 13 clean.

### jenga-tower

[Colour sheet](../models/jenga-tower/renders/textures.png), [normal sheet](../models/jenga-tower/renders/textures-normal.png), [roughness sheet](../models/jenga-tower/renders/textures-roughness.png).

- [1-crossed-block-layers-1-1-color.png](../models/jenga-tower/parts/1-crossed-block-layers-1-1-color.png): Two faint dark rectangular patches stacked within the red area at upper right can read as B/8-like blocks.

Remaining colour maps: 12 clean.

### stacking-cup-tower

[Colour sheet](../models/stacking-cup-tower/renders/textures.png), [normal sheet](../models/stacking-cup-tower/renders/textures-normal.png), [roughness sheet](../models/stacking-cup-tower/renders/textures-roughness.png).

- [1-inverted-cup-1-color.png](../models/stacking-cup-tower/parts/1-inverted-cup-1-color.png): Large faint circular disk in the lower half can read as O/0; the three dark window strokes inside it can read as III/111. The cream upright at the lower right has a small head-and-shoulders silhouette.
- [2-inverted-cup-2-color.png](../models/stacking-cup-tower/parts/2-inverted-cup-2-color.png): Large faint circular disk in the lower left can read as O/0. The cream upright along the lower left edge has a pawn/body-like outline.
- [3-inverted-cup-3-color.png](../models/stacking-cup-tower/parts/3-inverted-cup-3-color.png): Large faint circular disk in the lower half can read as O/0; the paired dark window strokes at lower left can read as II/11.
- [4-inverted-cup-4-color.png](../models/stacking-cup-tower/parts/4-inverted-cup-4-color.png): Large faint circular disk in the middle left can read as O/0. The cream upright near the bottom has a torso-like outline.
- [5-inverted-cup-5-color.png](../models/stacking-cup-tower/parts/5-inverted-cup-5-color.png): Large faint circular disk in the lower left can read as O/0; the cream narrow upright near the bottom has a pawn/body-like outline.

Every colour map in this building is flagged.

### log-cabin-tower

[Colour sheet](../models/log-cabin-tower/renders/textures.png), [normal sheet](../models/log-cabin-tower/renders/textures-normal.png), [roughness sheet](../models/log-cabin-tower/renders/textures-roughness.png).

- [5-framed-windows-door-and-steps-color.png](../models/log-cabin-tower/parts/5-framed-windows-door-and-steps-color.png): Cream shape at the lower left has a head-and-shoulders/pawn-like silhouette.
- [6-individual-log-gable-courses-color.png](../models/log-cabin-tower/parts/6-individual-log-gable-courses-color.png): Radiating tan wedges around the lower UV patches make pointed starburst-like shapes, especially at the bottom right.

Remaining colour maps: 5 clean.

### ruler-stilt-tower

[Colour sheet](../models/ruler-stilt-tower/renders/textures.png), [normal sheet](../models/ruler-stilt-tower/renders/textures-normal.png), [roughness sheet](../models/ruler-stilt-tower/renders/textures-roughness.png).

- [2-lower-cardboard-room-and-toy-feet-2-color.png](../models/ruler-stilt-tower/parts/2-lower-cardboard-room-and-toy-feet-2-color.png): Tan upright at the lower left has two stacked lobes, reading as a B/8-like outline.
- [6-upper-box-1-2-color.png](../models/ruler-stilt-tower/parts/6-upper-box-1-2-color.png): Tan upright at the lower left has two stacked lobes, reading as a B/8-like outline.
- [8-upper-box-2-2-color.png](../models/ruler-stilt-tower/parts/8-upper-box-2-2-color.png): Tan upright at the lower left has two stacked lobes, reading as a B/8-like outline.

Remaining colour maps: 5 clean.

### pencil-tin-tower

[Colour sheet](../models/pencil-tin-tower/renders/textures.png), [normal sheet](../models/pencil-tin-tower/renders/textures-normal.png), [roughness sheet](../models/pencil-tin-tower/renders/textures-roughness.png).

- [1-upright-tin-band-1-1-color.png](../models/pencil-tin-tower/parts/1-upright-tin-band-1-1-color.png): Two faint large circular outlines in the blue field can read as O/0 shapes.
- [2-upright-tin-band-1-2-color.png](../models/pencil-tin-tower/parts/2-upright-tin-band-1-2-color.png): Two faint dark blocks stacked in the red patch at upper left can read as B/8. The paired grey lobes across the lower half form a sideways 8-like outline.
- [3-upright-tin-band-2-1-color.png](../models/pencil-tin-tower/parts/3-upright-tin-band-2-1-color.png): Two faint large circular outlines in the blue field can read as O/0 shapes.
- [4-upright-tin-band-2-2-color.png](../models/pencil-tin-tower/parts/4-upright-tin-band-2-2-color.png): Tan upright at the lower right has a pinched head/torso-like outline.
- [5-upright-tin-band-3-1-color.png](../models/pencil-tin-tower/parts/5-upright-tin-band-3-1-color.png): Two faint large circular outlines in the blue field can read as O/0 shapes.
- [6-upright-tin-band-3-2-color.png](../models/pencil-tin-tower/parts/6-upright-tin-band-3-2-color.png): Tan upright at the lower right has a pinched head/torso-like outline.
- [7-half-open-canopy-and-real-hinge-1-color.png](../models/pencil-tin-tower/parts/7-half-open-canopy-and-real-hinge-1-color.png): Tan upright at the lower left has a pinched head/torso-like outline.
- [8-half-open-canopy-and-real-hinge-2-color.png](../models/pencil-tin-tower/parts/8-half-open-canopy-and-real-hinge-2-color.png): Dark grey connected blocks along the lower edge can read as a wide H.

Every colour map in this building is flagged.

### abacus-hall

[Colour sheet](../models/abacus-hall/renders/textures.png), [normal sheet](../models/abacus-hall/renders/textures-normal.png), [roughness sheet](../models/abacus-hall/renders/textures-roughness.png).

- [1-left-house-1-color.png](../models/abacus-hall/parts/1-left-house-1-color.png): Cream upright near the bottom centre ends in a rounded head/shoulders-like bulge.
- [2-left-house-2-color.png](../models/abacus-hall/parts/2-left-house-2-color.png): Cream upright along the left edge pinches above a lower lobe, making a body/pawn-like outline.
- [3-right-house-1-color.png](../models/abacus-hall/parts/3-right-house-1-color.png): Cream upright near the bottom centre ends in a rounded head/shoulders-like bulge.
- [4-right-house-2-color.png](../models/abacus-hall/parts/4-right-house-2-color.png): Cream upright along the left edge pinches above a lower lobe, making a body/pawn-like outline.

Remaining colour maps: 3 clean.

### chalk-box-depot

[Colour sheet](../models/chalk-box-depot/renders/textures.png), [normal sheet](../models/chalk-box-depot/renders/textures-normal.png), [roughness sheet](../models/chalk-box-depot/renders/textures-roughness.png).

- [3-six-round-chalk-columns-color.png](../models/chalk-box-depot/parts/3-six-round-chalk-columns-color.png): Jagged radial fill around the chalk-end patches in the lower half makes small starburst-like outlines, most visible in white and pink.
- [6-windows-double-door-and-step-color.png](../models/chalk-box-depot/parts/6-windows-double-door-and-step-color.png): Cream shape at the lower left has a head-and-shoulders/pawn-like silhouette; the adjacent faint dark blocks in the red area can read as B/8.

Remaining colour maps: 4 clean.

### shoebox-hall

[Colour sheet](../models/shoebox-hall/renders/textures.png), [normal sheet](../models/shoebox-hall/renders/textures-normal.png), [roughness sheet](../models/shoebox-hall/renders/textures-roughness.png).

- [3-windows-and-door-color.png](../models/shoebox-hall/parts/3-windows-and-door-color.png): Cream upright at the lower left has a pinched body/pawn-like outline; faint stacked dark blocks in the adjacent red strip can read as B/8.
- [4-propped-corrugated-awning-color.png](../models/shoebox-hall/parts/4-propped-corrugated-awning-color.png): Cream shape at the upper left ends in a rounded head with flared shoulders, an inverted body-like silhouette.

Remaining colour maps: 3 clean.

### block-arch

[Colour sheet](../models/block-arch/renders/textures.png), [normal sheet](../models/block-arch/renders/textures-normal.png), [roughness sheet](../models/block-arch/renders/textures-roughness.png).

- [1-blue-block-pier-color.png](../models/block-arch/parts/1-blue-block-pier-color.png): Two dark blocks stacked at the left can read as an 8/B-like mark. The cream patch in the lower middle has an H-like crossbar between uprights.
- [2-red-block-pier-color.png](../models/block-arch/parts/2-red-block-pier-color.png): Cream upright in the lower middle has a narrow neck and wider shoulders/body-like lobe.

Remaining colour maps: 4 clean.

### monorail-station-north

[Colour sheet](../models/monorail-station-north/renders/textures.png), [normal sheet](../models/monorail-station-north/renders/textures-normal.png), [roughness sheet](../models/monorail-station-north/renders/textures-roughness.png).

- [1-left-stand-box-1-color.png](../models/monorail-station-north/parts/1-left-stand-box-1-color.png): Faint inset rectangle in the upper-left red field can read as a squared O/0.
- [2-left-stand-box-2-color.png](../models/monorail-station-north/parts/2-left-stand-box-2-color.png): Dark red blocks in the upper left make an F/B-like mark. The cream region at the left has a head-and-shoulders outline; the yellow horizontal strip over blue can read as a T.
- [3-right-stand-box-1-color.png](../models/monorail-station-north/parts/3-right-stand-box-1-color.png): Faint inset rectangle in the upper-left red field can read as a squared O/0.
- [4-right-stand-box-2-color.png](../models/monorail-station-north/parts/4-right-stand-box-2-color.png): The cream region at the left has a head-and-shoulders outline; the yellow horizontal strip over blue can read as a T.
- [9-top-box-left-wing-color.png](../models/monorail-station-north/parts/9-top-box-left-wing-color.png): Cream shape near the lower right has a small head with flared shoulders, an inverted body-like silhouette.
- [10-top-box-right-wing-color.png](../models/monorail-station-north/parts/10-top-box-right-wing-color.png): Cream shape near the lower right has a small head with flared shoulders, an inverted body-like silhouette.
- [11-toy-brick-trims-and-join-tape-1-color.png](../models/monorail-station-north/parts/11-toy-brick-trims-and-join-tape-1-color.png): Concentric yellow square bands at upper left can read as O/0; the paired blue tapered patches below form an 8/hourglass-like mark.
- [12-toy-brick-trims-and-join-tape-2-color.png](../models/monorail-station-north/parts/12-toy-brick-trims-and-join-tape-2-color.png): Cream upright at the lower left has a head/shoulders and torso-like outline.

Remaining colour maps: 9 clean.

### monorail-station-south

[Colour sheet](../models/monorail-station-south/renders/textures.png), [normal sheet](../models/monorail-station-south/renders/textures-normal.png), [roughness sheet](../models/monorail-station-south/renders/textures-roughness.png).

- [1-left-toy-leg-course-1-color.png](../models/monorail-station-south/parts/1-left-toy-leg-course-1-color.png): Cream shape near the bottom has a head-and-shoulders/body-like outline; faint stacked blocks in the adjacent green patch can read as B/8.
- [2-left-toy-leg-course-2-color.png](../models/monorail-station-south/parts/2-left-toy-leg-course-2-color.png): Faint yellow tapered patches in the lower left form an I/hourglass-like mark.
- [4-left-toy-leg-course-4-color.png](../models/monorail-station-south/parts/4-left-toy-leg-course-4-color.png): Cream shape near the bottom has a head-and-shoulders/body-like outline.
- [5-left-toy-leg-course-5-color.png](../models/monorail-station-south/parts/5-left-toy-leg-course-5-color.png): Blue tapered patches joined by a narrow upright in the lower half form an I/X/hourglass-like mark.
- [6-right-toy-leg-course-1-color.png](../models/monorail-station-south/parts/6-right-toy-leg-course-1-color.png): Cream shape near the bottom has a head-and-shoulders/body-like outline; the yellow corner above it reads as L.
- [7-right-toy-leg-course-2-color.png](../models/monorail-station-south/parts/7-right-toy-leg-course-2-color.png): The brighter yellow corner in the middle right reads as L.
- [8-right-toy-leg-course-3-color.png](../models/monorail-station-south/parts/8-right-toy-leg-course-3-color.png): The brighter blue corner in the middle right reads as L.
- [9-right-toy-leg-course-4-color.png](../models/monorail-station-south/parts/9-right-toy-leg-course-4-color.png): Cream shape near the bottom has a head-and-shoulders/body-like outline; the yellow corner above it reads as L.
- [10-right-toy-leg-course-5-color.png](../models/monorail-station-south/parts/10-right-toy-leg-course-5-color.png): Blue tapered patches joined by a narrow upright in the lower half form an I/X/hourglass-like mark.
- [11-rounded-red-lunch-tin-half-1-color.png](../models/monorail-station-south/parts/11-rounded-red-lunch-tin-half-1-color.png): Red pointed upright meeting a horizontal band in the upper middle can read as a cross/star-like mark. The dark inset rectangle below reads as O/0; the cream shape at lower right has an inverted head-and-shoulders silhouette.
- [12-rounded-red-lunch-tin-half-2-color.png](../models/monorail-station-south/parts/12-rounded-red-lunch-tin-half-2-color.png): Red pointed upright meeting a horizontal band in the upper middle can read as a cross/star-like mark. The dark inset rectangle below reads as O/0; the cream shape at lower right has an inverted head-and-shoulders silhouette.
- [13-rounded-bottom-tin-rim-1-color.png](../models/monorail-station-south/parts/13-rounded-bottom-tin-rim-1-color.png): Large dark grey rectangular outline across the lower half reads as a squared O/0.
- [14-rounded-bottom-tin-rim-2-color.png](../models/monorail-station-south/parts/14-rounded-bottom-tin-rim-2-color.png): Large dark grey rectangular outline across the lower half reads as a squared O/0.
- [15-deep-lunch-tin-lid-1-color.png](../models/monorail-station-south/parts/15-deep-lunch-tin-lid-1-color.png): Grey corner bands near the lower left form an L-like outline.
- [16-deep-lunch-tin-lid-2-color.png](../models/monorail-station-south/parts/16-deep-lunch-tin-lid-2-color.png): Grey corner bands near the lower left form an L-like outline.
- [17-rolled-tin-rim-82-1-color.png](../models/monorail-station-south/parts/17-rolled-tin-rim-82-1-color.png): Grey vertical and horizontal trim bands in the lower half make H/L-like corners.
- [18-rolled-tin-rim-82-2-color.png](../models/monorail-station-south/parts/18-rolled-tin-rim-82-2-color.png): Grey trim bands at the middle and lower left make L-like corners.
- [19-rolled-tin-rim-143.3-1-color.png](../models/monorail-station-south/parts/19-rolled-tin-rim-143.3-1-color.png): Small dark grey angular slot in the middle left can read as L.
- [20-rolled-tin-rim-143.3-2-color.png](../models/monorail-station-south/parts/20-rolled-tin-rim-143.3-2-color.png): Small dark grey angular slot in the middle left can read as L.
- [21-rolled-tin-rim-149.2-1-color.png](../models/monorail-station-south/parts/21-rolled-tin-rim-149.2-1-color.png): Grey trim band in the middle right turns a corner into an L-like outline.
- [22-rolled-tin-rim-149.2-2-color.png](../models/monorail-station-south/parts/22-rolled-tin-rim-149.2-2-color.png): Grey trim band in the middle right turns a corner into an L-like outline.
- [23-metal-lined-open-track-tunnel-color.png](../models/monorail-station-south/parts/23-metal-lined-open-track-tunnel-color.png): Small grey hooked corner near the lower middle can read as L.

Remaining colour maps: 2 clean.

## Final checks and limits

- All 19 UV passes and all 645 per-map preservation checks passed.
- All 57 sheets were inspected at original size, including all 215 colour maps.
- The project documentation checker passed.
- All src files, tools/art/fill_gaps.py and tools/art/hero.py match the snapshots taken at the start of this job.
- tools/town_plan.py changed outside this job while it ran. This job neither edited nor reverted it.
- Concept images, Meshy source models and source maps were not edited.
- Files are left uncommitted for Claude to review. No upload clearance is claimed.

## Claude review (2026-10-16)

Every flagged colour map was opened and judged by eye: each sheet whole (500 px tiles), as small thumbnails (150 px, roughly how a quick image check sees it), and zoomed to full size on every spot the list above worried about. Sheets with large black areas were also viewed as black/red-only masks, and the jenga maps with boosted contrast, to look for hidden hooked crosses. Nothing was edited, uploaded or committed.

Verdicts: SAFE = nothing that could read as a symbol, letter string, number string, hand sign, body part or hooked cross. FIX = a region should be filled first. REDO = layout itself is risky. Single letters or digits (H, T, O, a lone 8) were treated as harmless.

| Sheet | Verdict | Reason |
|---|---|---|
| juice-carton-tower/parts/1-ground-floor-front-left-color.png | SAFE | Busy shopfront strip and red door; faint blue-on-blue blocks at the top are too low-contrast to read as text. Nothing symbolic. |
| juice-carton-tower/parts/2-ground-floor-front-right-color.png | SAFE | Flat blue/green/cream carton panels and dark window squares; the letter-like frames are ordinary window and wall outlines. No hooks, hands or body shapes. |
| juice-carton-tower/parts/3-ground-floor-back-left-color.png | SAFE | Flat blue/green/cream carton panels and dark window squares; the letter-like frames are ordinary window and wall outlines. No hooks, hands or body shapes. |
| juice-carton-tower/parts/4-ground-floor-back-right-color.png | SAFE | Flat blue/green/cream carton panels and dark window squares; the letter-like frames are ordinary window and wall outlines. No hooks, hands or body shapes. |
| juice-carton-tower/parts/5-upper-walls-front-left-color.png | SAFE | Cream patch with two blue holes reads as a single B/8; a lone letter is not a symbol. Nothing else. |
| juice-carton-tower/parts/6-upper-walls-front-right-color.png | SAFE | Flat blue/green/cream carton panels and dark window squares; the letter-like frames are ordinary window and wall outlines. No hooks, hands or body shapes. |
| juice-carton-tower/parts/7-upper-walls-back-left-color.png | SAFE | Flat blue/green/cream carton panels and dark window squares; the letter-like frames are ordinary window and wall outlines. No hooks, hands or body shapes. |
| juice-carton-tower/parts/8-upper-walls-back-right-color.png | SAFE | Flat blue/green/cream carton panels and dark window squares; the letter-like frames are ordinary window and wall outlines. No hooks, hands or body shapes. |
| juice-carton-tower/parts/9-roof-front-left-color.png | SAFE | Flat blue/green/cream carton panels and dark window squares; the letter-like frames are ordinary window and wall outlines. No hooks, hands or body shapes. |
| juice-carton-tower/parts/10-roof-front-right-color.png | SAFE | Flat blue/green/cream carton panels and dark window squares; the letter-like frames are ordinary window and wall outlines. No hooks, hands or body shapes. |
| juice-carton-tower/parts/13-topper-front-left-color.png | SAFE | Flat blue/green/cream carton panels and dark window squares; the letter-like frames are ordinary window and wall outlines. No hooks, hands or body shapes. |
| juice-carton-tower/parts/14-topper-front-right-color.png | SAFE | Large red field with small red/white trim scribbles at top right; zoomed in they are bake streaks, not text. |
| juice-carton-tower/parts/15-topper-back-left-color.png | SAFE | Big red X-like crossing on cream: a plain diagonal cross with straight arms, no hooks. Checked whole and at full size. |
| juice-carton-tower/parts/16-topper-back-right-color.png | SAFE | Red Y-shaped junction with straight arms; nothing hooked. |
| cereal-box-tower/parts/1-ground-floor-front-left-color.png | SAFE | Yellow cereal patch has small orange pinwheel/flower dabs (about 25 px, 6+ soft wedges, low contrast); zoomed, not hooked crosses. |
| cereal-box-tower/parts/2-ground-floor-front-right-color.png | SAFE | Same small orange flower dabs on yellow at top right; soft and low contrast, not a symbol. |
| cereal-box-tower/parts/3-ground-floor-back-left-color.png | SAFE | Tan frames around the black top patch look like random letters (T, A, E); no word, nothing offensive. |
| cereal-box-tower/parts/4-ground-floor-back-right-color.png | SAFE | Tan cardboard with window grids and black rectangles; H/T shapes are window frames. Black areas are plain blocks with no hooked arms. |
| cereal-box-tower/parts/5-upper-walls-front-left-color.png | SAFE | Black bow-tie/X of four wedges around the blue window at upper left (about x0-260, y100-500): a straight X, no hooks. Optional cleanup listed below. |
| cereal-box-tower/parts/6-upper-walls-front-right-color.png | SAFE | Tan cardboard with window grids and black rectangles; H/T shapes are window frames. Black areas are plain blocks with no hooked arms. |
| cereal-box-tower/parts/7-upper-walls-back-left-color.png | SAFE | Tan cardboard with window grids and black rectangles; H/T shapes are window frames. Black areas are plain blocks with no hooked arms. |
| cereal-box-tower/parts/8-upper-walls-back-right-color.png | SAFE | Black J-like blocks down the right edge are separate rectangles with diagonal corners; no cross is formed. |
| cereal-box-tower/parts/9-roof-front-left-color.png | SAFE | Large black rectangles on tan; no symbol. |
| cereal-box-tower/parts/10-roof-front-right-color.png | SAFE | Large black rectangles on tan; no symbol. |
| cereal-box-tower/parts/11-roof-back-left-color.png | SAFE | Large black rectangles on tan; no symbol. |
| cereal-box-tower/parts/12-roof-back-right-color.png | SAFE | Large black rectangles on tan; no symbol. |
| cereal-box-tower/parts/13-topper-front-left-color.png | SAFE | Tan cardboard with window grids and black rectangles; H/T shapes are window frames. Black areas are plain blocks with no hooked arms. |
| cereal-box-tower/parts/14-topper-front-right-color.png | SAFE | Tan cardboard with window grids and black rectangles; H/T shapes are window frames. Black areas are plain blocks with no hooked arms. |
| cereal-box-tower/parts/15-topper-back-left-color.png | SAFE | Tan cardboard with window grids and black rectangles; H/T shapes are window frames. Black areas are plain blocks with no hooked arms. |
| cereal-box-tower/parts/16-topper-back-right-color.png | SAFE | Tan cardboard with window grids and black rectangles; H/T shapes are window frames. Black areas are plain blocks with no hooked arms. |
| paint-jar-tower/parts/1-ground-floor-front-left-color.png | SAFE | Black Y-shaped block on the right with a yellow blob inside; straight edges, no hooks. |
| paint-jar-tower/parts/2-ground-floor-front-right-color.png | SAFE | Bold paint-jar colours with black blocks; letter-like joins are wall and window seams. No hooked cross or body shape. |
| paint-jar-tower/parts/3-ground-floor-back-left-color.png | SAFE | Thin dark curved seam with one horizontal stroke crossing it (lower left, about x60-260, y500-900). Checked at full size: one arc and one bar, no second arm, not a recognisable emblem. |
| paint-jar-tower/parts/4-ground-floor-back-right-color.png | SAFE | Dark forked seam lines across the middle (sideways Y); not a symbol. |
| paint-jar-tower/parts/5-upper-walls-front-left-color.png | SAFE | Bold paint-jar colours with black blocks; letter-like joins are wall and window seams. No hooked cross or body shape. |
| paint-jar-tower/parts/6-upper-walls-front-right-color.png | SAFE | Bold paint-jar colours with black blocks; letter-like joins are wall and window seams. No hooked cross or body shape. |
| paint-jar-tower/parts/7-upper-walls-back-left-color.png | SAFE | Bold paint-jar colours with black blocks; letter-like joins are wall and window seams. No hooked cross or body shape. |
| paint-jar-tower/parts/8-upper-walls-back-right-color.png | SAFE | Bold paint-jar colours with black blocks; letter-like joins are wall and window seams. No hooked cross or body shape. |
| paint-jar-tower/parts/9-roof-front-left-color.png | SAFE | Two big black quarter-discs with blue curved bands between them (lid shapes). Binarised and thumbnail views show no cross or hook. |
| paint-jar-tower/parts/10-roof-front-right-color.png | SAFE | Two big black quarter-discs with blue curved bands between them (lid shapes). Binarised and thumbnail views show no cross or hook. |
| paint-jar-tower/parts/11-roof-back-left-color.png | SAFE | Two big black quarter-discs with blue curved bands between them (lid shapes). Binarised and thumbnail views show no cross or hook. |
| paint-jar-tower/parts/12-roof-back-right-color.png | SAFE | Two big black quarter-discs with blue curved bands between them (lid shapes). Binarised and thumbnail views show no cross or hook. |
| paint-jar-tower/parts/13-topper-front-left-color.png | SAFE | Bold paint-jar colours with black blocks; letter-like joins are wall and window seams. No hooked cross or body shape. |
| paint-jar-tower/parts/14-topper-front-right-color.png | SAFE | Bold paint-jar colours with black blocks; letter-like joins are wall and window seams. No hooked cross or body shape. |
| paint-jar-tower/parts/15-topper-back-left-color.png | SAFE | Bold paint-jar colours with black blocks; letter-like joins are wall and window seams. No hooked cross or body shape. |
| paint-jar-tower/parts/16-topper-back-right-color.png | SAFE | Red field with black rectangles and blue arcs; the red is broad blobs, not hooked strokes. |
| pencil-case-bridge/parts/1-ground-floor-front-left-color.png | SAFE | Red/blue/yellow/green pencil-case print with cream window frames; X and T shapes are window braces. Black areas are separate rectangles. No hooked cross in the full-size or black/red-only views. |
| pencil-case-bridge/parts/2-ground-floor-front-right-color.png | SAFE | Red/blue/yellow/green pencil-case print with cream window frames; X and T shapes are window braces. Black areas are separate rectangles. No hooked cross in the full-size or black/red-only views. |
| pencil-case-bridge/parts/3-ground-floor-back-left-color.png | SAFE | Red/blue/yellow/green pencil-case print with cream window frames; X and T shapes are window braces. Black areas are separate rectangles. No hooked cross in the full-size or black/red-only views. |
| pencil-case-bridge/parts/4-ground-floor-back-right-color.png | SAFE | Red/blue/yellow/green pencil-case print with cream window frames; X and T shapes are window braces. Black areas are separate rectangles. No hooked cross in the full-size or black/red-only views. |
| pencil-case-bridge/parts/5-upper-walls-front-left-color.png | SAFE | Central red mass with several arms; checked full size and in a black/red-only view: irregular, not four bent arms around a centre. |
| pencil-case-bridge/parts/6-upper-walls-front-right-color.png | SAFE | Red/blue/yellow/green pencil-case print with cream window frames; X and T shapes are window braces. Black areas are separate rectangles. No hooked cross in the full-size or black/red-only views. |
| pencil-case-bridge/parts/7-upper-walls-back-left-color.png | SAFE | Red/blue/yellow/green pencil-case print with cream window frames; X and T shapes are window braces. Black areas are separate rectangles. No hooked cross in the full-size or black/red-only views. |
| pencil-case-bridge/parts/8-upper-walls-back-right-color.png | SAFE | Large red H-like shape with diagonals; reads as a letter at most. |
| pencil-case-bridge/parts/9-roof-front-left-color.png | FIX | Red and cream bars framing very large pure-black areas, the same red-on-black mix as the bell-tower strike. No hooked cross is visible now, but this is the highest-risk look in the set and the black is not seen on the model (close-up renders show none). Fill every pure-black (0,0,0) pixel with the roof's red (see FIX list). |
| pencil-case-bridge/parts/10-roof-front-right-color.png | FIX | Red and cream bars framing very large pure-black areas, the same red-on-black mix as the bell-tower strike. No hooked cross is visible now, but this is the highest-risk look in the set and the black is not seen on the model (close-up renders show none). Fill every pure-black (0,0,0) pixel with the roof's red (see FIX list). |
| pencil-case-bridge/parts/11-roof-back-left-color.png | FIX | Red and cream bars framing very large pure-black areas, the same red-on-black mix as the bell-tower strike. No hooked cross is visible now, but this is the highest-risk look in the set and the black is not seen on the model (close-up renders show none). Fill every pure-black (0,0,0) pixel with the roof's red (see FIX list). |
| pencil-case-bridge/parts/12-roof-back-right-color.png | FIX | Red and cream bars framing very large pure-black areas, the same red-on-black mix as the bell-tower strike. No hooked cross is visible now, but this is the highest-risk look in the set and the black is not seen on the model (close-up renders show none). Fill every pure-black (0,0,0) pixel with the roof's red (see FIX list). |
| pencil-case-bridge/parts/13-topper-front-left-color.png | SAFE | Red/blue/yellow/green pencil-case print with cream window frames; X and T shapes are window braces. Black areas are separate rectangles. No hooked cross in the full-size or black/red-only views. |
| pencil-case-bridge/parts/14-topper-front-right-color.png | SAFE | Red/blue/yellow/green pencil-case print with cream window frames; X and T shapes are window braces. Black areas are separate rectangles. No hooked cross in the full-size or black/red-only views. |
| pencil-case-bridge/parts/15-topper-back-left-color.png | SAFE | Red/blue/yellow/green pencil-case print with cream window frames; X and T shapes are window braces. Black areas are separate rectangles. No hooked cross in the full-size or black/red-only views. |
| pencil-case-bridge/parts/16-topper-back-right-color.png | SAFE | Red/blue/yellow/green pencil-case print with cream window frames; X and T shapes are window braces. Black areas are separate rectangles. No hooked cross in the full-size or black/red-only views. |
| egg-carton-market/parts/1-ground-floor-front-left-color.png | SAFE | Market walls: awning stripes, shop windows and black panels. Letter-like wall joins only. |
| egg-carton-market/parts/2-ground-floor-front-right-color.png | SAFE | Green blob below centre is an irregular shop patch; zoomed, not body-like. |
| egg-carton-market/parts/3-ground-floor-back-left-color.png | SAFE | Grey diagonal strokes look like random letters; no word. |
| egg-carton-market/parts/4-ground-floor-back-right-color.png | SAFE | Grey F/G-like band around the black panel; a single letter at most. |
| egg-carton-market/parts/5-upper-walls-front-color.png | SAFE | Market walls: awning stripes, shop windows and black panels. Letter-like wall joins only. |
| egg-carton-market/parts/6-upper-walls-back-color.png | SAFE | Market walls: awning stripes, shop windows and black panels. Letter-like wall joins only. |
| egg-carton-market/parts/8-topper-color.png | SAFE | Carton-cone rings and cream blobs; the blobs at lower left look like jumbled letters (C, 8, B) but spell nothing and are low contrast. |
| sticky-note-tower/parts/1-yellow-ground-pad-color.png | SAFE | Red rounded patch over a blue/yellow fitting and a tan box; the Y-fork is a soft corner. Nothing symbolic. |
| pencil-pillar-tower/parts/1-pencil-supported-box-1-1-color.png | SAFE | Two faint dark squares stacked in a red patch read as one 8/B; a single digit/letter is harmless. |
| ring-binder-tower/parts/3-standing-binder-band-1-3-color.png | SAFE | Cream rounded-cross patch (a corner join, about x850-1000, y800-1024) beside a red patch with a faint 8; zoomed, reads as a small plain cross/pawn, not a body part. |
| ring-binder-tower/parts/15-left-open-metal-ring-color.png | SAFE | Grey metal with a very faint radial X near the bottom left; barely visible. |
| ring-binder-tower/parts/16-right-open-metal-ring-color.png | SAFE | Grey metal with a very faint radial X near the bottom left; barely visible. |
| jenga-tower/parts/1-crossed-block-layers-1-1-color.png | SAFE | Contrast-boosted check: the light wood bars form plain plus/grid crossings (stacked blocks), no hooked ends. Two faint dark squares read as one 8. |
| stacking-cup-tower/parts/1-inverted-cup-1-color.png | SAFE | Faint circular cup base with soft window marks (I/II) and a cream corner knob at the bottom; zoomed, the knob is a plain rounded joint. |
| stacking-cup-tower/parts/2-inverted-cup-2-color.png | SAFE | Faint circular cup base with soft window marks (I/II) and a cream corner knob at the bottom; zoomed, the knob is a plain rounded joint. |
| stacking-cup-tower/parts/3-inverted-cup-3-color.png | SAFE | Faint circular cup base with soft window marks (I/II) and a cream corner knob at the bottom; zoomed, the knob is a plain rounded joint. |
| stacking-cup-tower/parts/4-inverted-cup-4-color.png | SAFE | Faint circular cup base with soft window marks (I/II) and a cream corner knob at the bottom; zoomed, the knob is a plain rounded joint. |
| stacking-cup-tower/parts/5-inverted-cup-5-color.png | SAFE | Faint circular cup base with soft window marks (I/II) and a cream corner knob at the bottom; zoomed, the knob is a plain rounded joint. |
| log-cabin-tower/parts/5-framed-windows-door-and-steps-color.png | SAFE | Cream strip with a rounded corner joint at the lower left; not body-like. |
| log-cabin-tower/parts/6-individual-log-gable-courses-color.png | SAFE | Soft radial wood-grain fans from the bake; low contrast, not a star symbol. |
| ruler-stilt-tower/parts/2-lower-cardboard-room-and-toy-feet-2-color.png | SAFE | Long curved colour band with a rounded end and a small tan two-lobe corner (B/8) at lower left; reads as a brush stroke. Not a body shape. |
| ruler-stilt-tower/parts/6-upper-box-1-2-color.png | SAFE | Long curved colour band with a rounded end and a small tan two-lobe corner (B/8) at lower left; reads as a brush stroke. Not a body shape. |
| ruler-stilt-tower/parts/8-upper-box-2-2-color.png | SAFE | Long curved colour band with a rounded end and a small tan two-lobe corner (B/8) at lower left; reads as a brush stroke. Not a body shape. |
| pencil-tin-tower/parts/1-upright-tin-band-1-1-color.png | SAFE | Blue tin with faint rounded window outlines (O shapes); very low contrast. |
| pencil-tin-tower/parts/2-upright-tin-band-1-2-color.png | SAFE | Two grey octagons side by side (sideways 8) and a red patch with a faint 8; harmless. |
| pencil-tin-tower/parts/3-upright-tin-band-2-1-color.png | SAFE | Blue tin with faint rounded window outlines (O shapes); very low contrast. |
| pencil-tin-tower/parts/4-upright-tin-band-2-2-color.png | SAFE | Grey/blue tin panels with a cream corner joint; not body-like. |
| pencil-tin-tower/parts/5-upright-tin-band-3-1-color.png | SAFE | Blue tin with faint rounded window outlines (O shapes); very low contrast. |
| pencil-tin-tower/parts/6-upright-tin-band-3-2-color.png | SAFE | Grey/blue tin panels with a cream corner joint; not body-like. |
| pencil-tin-tower/parts/7-half-open-canopy-and-real-hinge-1-color.png | SAFE | Grey/blue tin panels with a cream corner joint; not body-like. |
| pencil-tin-tower/parts/8-half-open-canopy-and-real-hinge-2-color.png | SAFE | Two grey bars joined by a pinch (wide H / sideways 8); harmless. |
| abacus-hall/parts/1-left-house-1-color.png | SAFE | Cream band ending in a rounded corner joint next to a blue/red band. Zoomed at full size: a bone-like corner patch, not a body part. |
| abacus-hall/parts/2-left-house-2-color.png | SAFE | Cream band ending in a rounded corner joint next to a blue/red band. Zoomed at full size: a bone-like corner patch, not a body part. |
| abacus-hall/parts/3-right-house-1-color.png | SAFE | Cream band ending in a rounded corner joint next to a blue/red band. Zoomed at full size: a bone-like corner patch, not a body part. |
| abacus-hall/parts/4-right-house-2-color.png | SAFE | Cream band ending in a rounded corner joint next to a blue/red band. Zoomed at full size: a bone-like corner patch, not a body part. |
| chalk-box-depot/parts/3-six-round-chalk-columns-color.png | SAFE | Vertical chalk-colour stripes with faint radial fan lines; not a starburst symbol at normal viewing. |
| chalk-box-depot/parts/6-windows-double-door-and-step-color.png | SAFE | Cream corner joint at lower left beside a red patch with a faint 8; harmless. |
| shoebox-hall/parts/3-windows-and-door-color.png | SAFE | Cream corner joint at lower left beside a red patch with a faint 8; harmless. |
| shoebox-hall/parts/4-propped-corrugated-awning-color.png | SAFE | Cream teardrop at upper left ending in a small notch; reads as a drip/feather, not body-like. |
| block-arch/parts/1-blue-block-pier-color.png | SAFE | Tan diagonal band ending in a small box frame; faint blue 8 at left. Harmless. |
| block-arch/parts/2-red-block-pier-color.png | SAFE | Tan bar plus cream stem with a rounded joint (a plain T/cross shape, like a sword hilt). Not a hate symbol or body part. |
| monorail-station-north/parts/1-left-stand-box-1-color.png | SAFE | Faint inset rectangle in red and cardboard; harmless. |
| monorail-station-north/parts/2-left-stand-box-2-color.png | SAFE | Cream hill shapes under a yellow strip; T reading only. Harmless. |
| monorail-station-north/parts/3-right-stand-box-1-color.png | SAFE | Faint inset rectangle in red and cardboard; harmless. |
| monorail-station-north/parts/4-right-stand-box-2-color.png | SAFE | Cream hill shapes under a yellow strip; T reading only. Harmless. |
| monorail-station-north/parts/9-top-box-left-wing-color.png | SAFE | Cream diagonal band with a rounded corner joint; not body-like. |
| monorail-station-north/parts/10-top-box-right-wing-color.png | SAFE | Cream diagonal band with a rounded corner joint; not body-like. |
| monorail-station-north/parts/11-toy-brick-trims-and-join-tape-1-color.png | SAFE | Concentric yellow squares, blue hourglass and a red bottle-shaped band; harmless geometry. |
| monorail-station-north/parts/12-toy-brick-trims-and-join-tape-2-color.png | SAFE | Cream diagonal band with a rounded corner joint; not body-like. |
| monorail-station-south/parts/1-left-toy-leg-course-1-color.png | SAFE | Cream corner joint at the bottom with a faint 8 in the next patch; harmless. |
| monorail-station-south/parts/2-left-toy-leg-course-2-color.png | SAFE | Faint diagonal X/hourglass from the face layout; low contrast, straight arms. |
| monorail-station-south/parts/4-left-toy-leg-course-4-color.png | SAFE | Cream corner joint at the bottom with a faint 8 in the next patch; harmless. |
| monorail-station-south/parts/5-left-toy-leg-course-5-color.png | SAFE | Faint diagonal X/hourglass from the face layout; low contrast, straight arms. |
| monorail-station-south/parts/6-right-toy-leg-course-1-color.png | SAFE | Cream corner joint at the bottom with a faint 8 in the next patch; harmless. |
| monorail-station-south/parts/7-right-toy-leg-course-2-color.png | SAFE | Two-tone corner reads as L; harmless. |
| monorail-station-south/parts/8-right-toy-leg-course-3-color.png | SAFE | Two-tone corner reads as L; harmless. |
| monorail-station-south/parts/9-right-toy-leg-course-4-color.png | SAFE | Cream corner joint at the bottom with a faint 8 in the next patch; harmless. |
| monorail-station-south/parts/10-right-toy-leg-course-5-color.png | SAFE | Faint diagonal X/hourglass from the face layout; low contrast, straight arms. |
| monorail-station-south/parts/11-rounded-red-lunch-tin-half-1-color.png | SAFE | Faint red spike rising from a band (like a steeple) and a dark window; red on red, low contrast. Cream corner joint at right. Harmless. |
| monorail-station-south/parts/12-rounded-red-lunch-tin-half-2-color.png | SAFE | Faint red spike rising from a band (like a steeple) and a dark window; red on red, low contrast. Cream corner joint at right. Harmless. |
| monorail-station-south/parts/13-rounded-bottom-tin-rim-1-color.png | SAFE | Grey tin with faint rim bands; L/O corners only, very low contrast. |
| monorail-station-south/parts/14-rounded-bottom-tin-rim-2-color.png | SAFE | Grey tin with faint rim bands; L/O corners only, very low contrast. |
| monorail-station-south/parts/15-deep-lunch-tin-lid-1-color.png | SAFE | Grey tin with faint rim bands; L/O corners only, very low contrast. |
| monorail-station-south/parts/16-deep-lunch-tin-lid-2-color.png | SAFE | Grey tin with faint rim bands; L/O corners only, very low contrast. |
| monorail-station-south/parts/17-rolled-tin-rim-82-1-color.png | SAFE | Grey tin with faint rim bands; L/O corners only, very low contrast. |
| monorail-station-south/parts/18-rolled-tin-rim-82-2-color.png | SAFE | Grey tin with faint rim bands; L/O corners only, very low contrast. |
| monorail-station-south/parts/19-rolled-tin-rim-143.3-1-color.png | SAFE | Grey tin with faint rim bands; L/O corners only, very low contrast. |
| monorail-station-south/parts/20-rolled-tin-rim-143.3-2-color.png | SAFE | Grey tin with faint rim bands; L/O corners only, very low contrast. |
| monorail-station-south/parts/21-rolled-tin-rim-149.2-1-color.png | SAFE | Grey tin with faint rim bands; L/O corners only, very low contrast. |
| monorail-station-south/parts/22-rolled-tin-rim-149.2-2-color.png | SAFE | Grey tin with faint rim bands; L/O corners only, very low contrast. |
| monorail-station-south/parts/23-metal-lined-open-track-tunnel-color.png | SAFE | Grey tin with faint rim bands; L/O corners only, very low contrast. |

### Spot-check of sheets that were not flagged

All 82 unflagged colour maps were viewed as thumbnails; these 27 were also viewed at 500 px, and all 13 jenga maps with boosted contrast.

| Sheet | Verdict | Note |
|---|---|---|
| juice-carton-tower/parts/11-roof-back-left-color.png | SAFE | Plain colour blocks or cardboard; nothing symbolic. |
| juice-carton-tower/parts/12-roof-back-right-color.png | SAFE | Plain colour blocks or cardboard; nothing symbolic. |
| egg-carton-market/parts/7-roof-color.png | SAFE | Two big black panels on cardboard; plain rectangles. |
| sticky-note-tower/parts/2-pink-pad-color.png | SAFE | Tan box with a faint B/8 mark, like the flagged yellow pad; harmless. |
| sticky-note-tower/parts/6-yellow-roof-pad-color.png | SAFE | Same tan box with faint B/8 mark; harmless. |
| pencil-pillar-tower/parts/15-four-sharpened-hex-pencil-tips-color.png | SAFE | Plain colour blocks or cardboard; nothing symbolic. |
| pencil-pillar-tower/parts/2-pencil-supported-box-1-2-color.png | SAFE | Plain colour blocks or cardboard; nothing symbolic. |
| ring-binder-tower/parts/1-standing-binder-band-1-1-color.png | SAFE | Plain colour blocks or cardboard; nothing symbolic. |
| ring-binder-tower/parts/13-binder-roof-left-color.png | SAFE | Faint 8 on blue; harmless. |
| ring-binder-tower/parts/14-binder-roof-right-color.png | SAFE | Plain colour blocks or cardboard; nothing symbolic. |
| jenga-tower/parts/10-crossed-block-layers-4-2-color.png | SAFE | Plain plus/grid crossings of wood bars, no hooked ends (also checked with boosted contrast). |
| jenga-tower/parts/2-crossed-block-layers-1-2-color.png | SAFE | Plain plus/grid crossings, no hooked ends. |
| log-cabin-tower/parts/1-crossed-log-courses-1-color.png | SAFE | Plain colour blocks or cardboard; nothing symbolic. |
| log-cabin-tower/parts/7-two-cardboard-roof-slopes-and-cut-edges-color.png | SAFE | Plain colour blocks or cardboard; nothing symbolic. |
| ruler-stilt-tower/parts/4-four-rulers-with-plain-ticks-color.png | SAFE | Plain colour blocks or cardboard; nothing symbolic. |
| abacus-hall/parts/5-open-wood-abacus-frame-color.png | SAFE | Plain colour blocks or cardboard; nothing symbolic. |
| abacus-hall/parts/6-painted-counting-beads-1-color.png | SAFE | Plain colour blocks or cardboard; nothing symbolic. |
| chalk-box-depot/parts/4-open-chalk-roof-tray-1-color.png | SAFE | Plain colour blocks or cardboard; nothing symbolic. |
| shoebox-hall/parts/1-cardboard-box-1-color.png | SAFE | Plain colour blocks or cardboard; nothing symbolic. |
| shoebox-hall/parts/5-toy-bricks-and-taped-props-color.png | SAFE | Plain colour blocks or cardboard; nothing symbolic. |
| block-arch/parts/3-curved-wood-arch-sector-1-color.png | SAFE | Plain colour blocks or cardboard; nothing symbolic. |
| monorail-station-north/parts/13-corrugated-top-box-cut-edges-1-color.png | SAFE | Plain colour blocks or cardboard; nothing symbolic. |
| monorail-station-north/parts/6-top-box-lid-left-color.png | SAFE | Plain colour blocks or cardboard; nothing symbolic. |
| monorail-station-south/parts/24-real-hinges-and-closing-clasps-color.png | SAFE | Plain colour blocks or cardboard; nothing symbolic. |
| monorail-station-south/parts/3-left-toy-leg-course-3-color.png | SAFE | Plain colour blocks or cardboard; nothing symbolic. |
| jenga-tower/parts/6-crossed-block-layers-3-1-color.png | SAFE | Plain plus/grid crossings, no hooked ends. |
| chalk-box-depot/parts/1-box-and-base-1-color.png | SAFE | Plain colour blocks or cardboard; nothing symbolic. |

### Summary

- Flagged sheets: 133 judged. 129 SAFE, 4 FIX, 0 REDO.
- Spot-check: 27 unflagged sheets viewed closely (plus all 82 as thumbnails): all SAFE. The flagging missed nothing worrying; the only extra pattern found is the plain plus-shaped block grid on every jenga map, which has no hooked ends.
- No hooked cross, hand sign or body part was found anywhere. Most flags were ordinary letter-like window frames, which are not a moderation risk.
- Worst sheets: the four pencil-case-bridge roof maps (9-12). They are about half pure black with red and cream bars around it, the same red-on-black mix that got the account struck. Nothing there reads as a symbol today, but they are the closest match to the old problem, so fill them before upload.

FIX list (colour maps only; normal and roughness maps need no change):

1. pencil-case-bridge/parts/9-roof-front-left-color.png: replace every pure-black (0,0,0) pixel (506,429 px, inside x0-987, y22-1023) with the roof red RGB(211,16,12).
2. pencil-case-bridge/parts/10-roof-front-right-color.png: same, 459,344 px inside x0-757, y16-1004, fill RGB(203,19,15).
3. pencil-case-bridge/parts/11-roof-back-left-color.png: same, 569,515 px inside x0-935, y86-1023, fill RGB(210,17,14).
4. pencil-case-bridge/parts/12-roof-back-right-color.png: same, 606,581 px inside x0-920, y0-1008, fill RGB(203,18,13).

The black sits inside the real UV islands (the protected-texel counts are larger than the non-black area), so this changes faces on the model. The existing close-up renders show no black anywhere on the bridge, so these look like hidden faces; re-render the close-ups after the fill to confirm nothing visible turned red.

Optional, lower priority (SAFE as they are): the cereal-box-tower and paint-jar-tower maps also carry large pure-black areas (blue or tan on black, no red). If the same hidden-face check holds for them, filling their black with the neighbouring colour would remove the last high-contrast shapes, including the black bow-tie X on cereal-box-tower 5-upper-walls-front-left.

Nothing urgent beyond the FIX list. Normal and roughness sheets were not re-reviewed here.

### Not in the Codex report: 3 more buildings

porthole-book-tower, tape-roll-tower and tissue-box-tower (16 colour maps each) were never in the Codex flag list. Same method: every map whole at 500 px, as thumbnails, zoomed on anything doubtful, and red-only and blue/green-only masks for the tissue box. None of the 48 maps has pure-black areas. Nothing was edited or uploaded.

| Sheet | Verdict | Reason |
|---|---|---|
| porthole-book-tower/parts/1-ground-floor-front-left-color.png | SAFE | Round porthole windows with a thin diagonal cross inside (window bars in blue/cream, about 100 px) and soft wood rosettes. Zoomed: they read as windows; the cross is a slanted X in pane colours, not a bold upright cross-in-circle emblem. Watch item, not a fix. |
| porthole-book-tower/parts/2-ground-floor-front-right-color.png | SAFE | Round porthole windows with a thin diagonal cross inside (window bars in blue/cream, about 100 px) and soft wood rosettes. Zoomed: they read as windows; the cross is a slanted X in pane colours, not a bold upright cross-in-circle emblem. Watch item, not a fix. |
| porthole-book-tower/parts/3-ground-floor-back-left-color.png | SAFE | Book-spine colours (red/blue/yellow/green) on cream; letter-like frames are wall and window edges. No hooked cross, hand or body shape. |
| porthole-book-tower/parts/4-ground-floor-back-right-color.png | SAFE | Red chevron (>) and green forked trim at centre right; a single zigzag, not paired lightning runes. |
| porthole-book-tower/parts/5-upper-walls-front-left-color.png | SAFE | Red/cream crescent (C) beside blue and green blocks; harmless. |
| porthole-book-tower/parts/6-upper-walls-front-right-color.png | SAFE | Book-spine colours (red/blue/yellow/green) on cream; letter-like frames are wall and window edges. No hooked cross, hand or body shape. |
| porthole-book-tower/parts/7-upper-walls-back-left-color.png | SAFE | Red and blue diagonal bands crossing at the top; straight crossings, no hooked ends. |
| porthole-book-tower/parts/8-upper-walls-back-right-color.png | SAFE | Book-spine colours (red/blue/yellow/green) on cream; letter-like frames are wall and window edges. No hooked cross, hand or body shape. |
| porthole-book-tower/parts/9-roof-front-left-color.png | SAFE | Big red roof shapes forming F/P-like outlines on cream; letters at most. |
| porthole-book-tower/parts/10-roof-front-right-color.png | SAFE | Big red roof shapes forming F/P-like outlines on cream; letters at most. |
| porthole-book-tower/parts/11-roof-back-left-color.png | SAFE | Yellow/orange roof gradient with a cream panel and red edge bars; nothing symbolic. |
| porthole-book-tower/parts/12-roof-back-right-color.png | SAFE | Yellow/orange roof gradient with a cream panel and red edge bars; nothing symbolic. |
| porthole-book-tower/parts/13-topper-front-left-color.png | SAFE | Round porthole windows with a thin diagonal cross inside (window bars in blue/cream, about 100 px) and soft wood rosettes. Zoomed: they read as windows; the cross is a slanted X in pane colours, not a bold upright cross-in-circle emblem. Watch item, not a fix. |
| porthole-book-tower/parts/14-topper-front-right-color.png | SAFE | Round porthole windows with a thin diagonal cross inside (window bars in blue/cream, about 100 px) and soft wood rosettes. Zoomed: they read as windows; the cross is a slanted X in pane colours, not a bold upright cross-in-circle emblem. Watch item, not a fix. |
| porthole-book-tower/parts/15-topper-back-left-color.png | SAFE | Blue/green/yellow open-box outline meeting at a Y corner, the three faces of a box in perspective. Checked full size: the arms turn in opposite directions, so it is not a three-armed pinwheel. |
| porthole-book-tower/parts/16-topper-back-right-color.png | SAFE | Red, green and cream frames around cream panels; window shapes only. |
| tape-roll-tower/parts/1-ground-floor-front-left-color.png | SAFE | Cardboard with blue windows and cream tape strips; ordinary wall/window outlines. |
| tape-roll-tower/parts/2-ground-floor-front-right-color.png | SAFE | Cardboard with blue windows and cream tape strips; ordinary wall/window outlines. |
| tape-roll-tower/parts/3-ground-floor-back-left-color.png | SAFE | Cardboard with blue windows and cream tape strips; ordinary wall/window outlines. |
| tape-roll-tower/parts/4-ground-floor-back-right-color.png | SAFE | Cardboard with blue windows and cream tape strips; ordinary wall/window outlines. |
| tape-roll-tower/parts/5-upper-walls-front-left-color.png | SAFE | Cardboard with blue windows and cream tape strips; ordinary wall/window outlines. |
| tape-roll-tower/parts/6-upper-walls-front-right-color.png | SAFE | Cardboard with blue windows and cream tape strips; ordinary wall/window outlines. |
| tape-roll-tower/parts/7-upper-walls-back-left-color.png | SAFE | Cardboard with blue windows and cream tape strips; ordinary wall/window outlines. |
| tape-roll-tower/parts/8-upper-walls-back-right-color.png | SAFE | Cardboard with blue windows and cream tape strips; ordinary wall/window outlines. |
| tape-roll-tower/parts/9-roof-front-left-color.png | SAFE | Cardboard with blue windows and cream tape strips; ordinary wall/window outlines. |
| tape-roll-tower/parts/10-roof-front-right-color.png | SAFE | Cardboard with blue windows and cream tape strips; ordinary wall/window outlines. |
| tape-roll-tower/parts/11-roof-back-left-color.png | FIX | Dot panel at upper centre: four upright chains of three joined red circles side by side. At normal and thumbnail size they read like a row of 8s (8888); 88 is a known hate number. Fill the panel (see FIX list). |
| tape-roll-tower/parts/12-roof-back-right-color.png | SAFE | Same kind of dot panel, but the chains lie sideways with open rings (reads as o-o-o / sideways 8s, not digits). Red scalloped blobs elsewhere. Harmless; optional same fill for consistency. |
| tape-roll-tower/parts/13-topper-front-left-color.png | SAFE | Tan with cream tape-roll rings (C/O/G-like letters) and small red dot grids; no word, nothing symbolic. |
| tape-roll-tower/parts/14-topper-front-right-color.png | SAFE | Tan with cream tape-roll rings (C/O/G-like letters) and small red dot grids; no word, nothing symbolic. |
| tape-roll-tower/parts/15-topper-back-left-color.png | SAFE | Tan with cream tape-roll rings (C/O/G-like letters) and small red dot grids; no word, nothing symbolic. |
| tape-roll-tower/parts/16-topper-back-right-color.png | SAFE | Tan with cream tape-roll rings (C/O/G-like letters) and small red dot grids; no word, nothing symbolic. |
| tissue-box-tower/parts/1-ground-floor-front-left-color.png | SAFE | Green window frames and blue panels on cream; U/O/Q-like frames only. |
| tissue-box-tower/parts/2-ground-floor-front-right-color.png | SAFE | Green window frames and blue panels on cream; U/O/Q-like frames only. |
| tissue-box-tower/parts/3-ground-floor-back-left-color.png | SAFE | Green window frames and blue panels on cream; U/O/Q-like frames only. |
| tissue-box-tower/parts/4-ground-floor-back-right-color.png | SAFE | Green window frames and blue panels on cream; U/O/Q-like frames only. |
| tissue-box-tower/parts/5-upper-walls-front-left-color.png | SAFE | Large blue X/K shapes with straight arms plus a red upright bar. Zoomed: no arm bends at its tip, so no pinwheel. |
| tissue-box-tower/parts/6-upper-walls-front-right-color.png | SAFE | Large blue X/K shapes with straight arms plus a red upright bar. Zoomed: no arm bends at its tip, so no pinwheel. |
| tissue-box-tower/parts/7-upper-walls-back-left-color.png | SAFE | Large blue X/K shapes with straight arms plus a red upright bar. Zoomed: no arm bends at its tip, so no pinwheel. |
| tissue-box-tower/parts/8-upper-walls-back-right-color.png | SAFE | Large blue X/K shapes with straight arms plus a red upright bar. Zoomed: no arm bends at its tip, so no pinwheel. |
| tissue-box-tower/parts/9-roof-front-left-color.png | SAFE | Blue panels and red/cream bars; T and n shapes only. |
| tissue-box-tower/parts/10-roof-front-right-color.png | SAFE | Blue block reading as a 2/Z, dark red blocks at left; a single character at most. |
| tissue-box-tower/parts/11-roof-back-left-color.png | SAFE | Blue Y/X bands and faint white tissue doodle lines; doodles spell nothing. |
| tissue-box-tower/parts/12-roof-back-right-color.png | SAFE | Blue X crossing with dark red wedges and faint white doodle lines; straight arms. |
| tissue-box-tower/parts/13-topper-front-left-color.png | SAFE | Red upright bar, red right-angle bracket at top right and a dark red diagonal bar (a K-like group). Red-only mask checked: separate pieces, no common centre, not a hooked cross. |
| tissue-box-tower/parts/14-topper-front-right-color.png | SAFE | Red mass with window holes reading like A/4 in the red-only mask; arm ends do not bend the same way round. Busiest red sheet of the three buildings, but no symbol. |
| tissue-box-tower/parts/15-topper-back-left-color.png | SAFE | Red T at the top, a red Y-shaped block lower left and a small red E at right, on white. Letters only. |
| tissue-box-tower/parts/16-topper-back-right-color.png | SAFE | Red brackets (reversed C / 5-like) on white along the top and right edge. Red-only mask checked: no common centre, reads as one S/5 shape at most. |

Summary for these three: 48 judged. 47 SAFE, 1 FIX, 0 REDO. No hooked cross, hand sign or body part.

- Worst sheet: tape-roll-tower 11-roof-back-left (the 8888-like dot panel).
- Next to watch: tissue-box-tower 14-topper-front-right and 16-topper-back-right (bold red bracket shapes on white, the closest look to the old strike in this group, but no hooked cross), and the porthole-book-tower windows with a slanted cross inside a circle (sheets 1, 2, 13, 14). These read as windows and stay SAFE; if Alan wants the lowest possible risk, upload them last and one at a time.

FIX list:

5. tape-roll-tower/parts/11-roof-back-left-color.png: fill the rectangle x440-790, y175-465 with flat cardboard tan RGB(155,120,85), the colour of the panel's own border. This removes the joined red circles. A preview made in the scratchpad (not saved to the repo) shows the rest of the sheet untouched. This changes a visible roof panel (it goes plain), so look at the roof close-up after the fill. A gentler option is to cut only the narrow red necks between the circles so they become separate dots.

Optional: tape-roll-tower/parts/12-roof-back-right-color.png has the same panel turned sideways (about x450-740, y270-620); it is SAFE, but the same fill would keep the two roofs matching.

### Fixes applied (2026-10-16, main session)
- Pencil-case-bridge roofs 9-12: pure black (max channel <= 6) filled with each roof's red. Before/after close-up renders differ by 9 of 5.1M pixels (hidden faces).
- Tape-roll-tower 11-roof-back-left: panel x440-790, y175-465 filled flat tan (155,120,85). Close-ups show no visible change (under the tape roll).
