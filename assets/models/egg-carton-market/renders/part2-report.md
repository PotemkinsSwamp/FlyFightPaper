> Historical recovery note from the interrupted run. The completed continuation, market measurements and all new texture findings are in [texture-safety-report.md](../../../rug/texture-safety-report.md). The pending entries below describe the old run.

# Part 2 review

Status: in progress. The bridge bake and its geometry/UV checks have passed. Its 100 by 95 opening is clear in both background views, with zero blocked rays or intruding triangles. The market bake is queued behind a further paint-jar rebake; five texture reviews remain.

The UV-based fill is implemented in tools/art/fill_gaps.py. The original dark-gap mode remains available. UV mode rasterises the saved piece UVs at each map resolution, preserves a three-pixel bleed, and fills the remaining texels from the nearest protected texel. External maps are changed; geometry, UVs, originals and packed scene copies are left intact.

Checks passed: dark UV pixels preserved; RGB, RGBA and grayscale maps; colour, normal, roughness and both metalness suffixes; mixed resolutions; vertical UV orientation; repeatability; legacy dark-gap results including extra channels; review-image exclusion; missing UV data stops before writing.

| Building | Pieces | Total triangles | Lowest front_pixels_per_stud | UV fill | Geometry check |
|---|---:|---:|---:|---|---|
| porthole-book-tower | 16 | 57,532 | 4.304 | Done | Closed; every piece <=12,000 triangles |
| tissue-box-tower | 16 | 44,348 | 4.734 | Done | Closed; every piece <=12,000 triangles |
| tape-roll-tower | 16 | 54,326 | 5.335 | Done | Closed; every piece <=12,000 triangles |
| juice-carton-tower | 16 | 37,108 | 6.296 | Pending | Pending |
| cereal-box-tower | Pending | Pending | Pending | Pending | Pending |
| paint-jar-tower | Pending | Pending | Pending | Pending | Pending |
| pencil-case-bridge | Pending | Pending | Pending | Pending | Pending |
| egg-carton-market | Pending | Pending | Pending | Pending | Pending |

The first three buildings are below the aim of 6 front pixels per stud on their least-dense pieces. Their geometry was not changed in Part 2.

## New model touch-ups

pencil-case-bridge: the source opening measured about 79 studs wide. The asset-local touchup.py reads source_deformation in touchup.json and reshapes the existing book stacks, preserving their doors, frames, original faces and UVs. It also raises the opening while keeping the full height at 140. The source preview has been checked from both sides. The finished bake passed all 19,000 two-way rays, the thin-face intersection check, and front/back background renders for a clear 100 by 95 road gap. The saved geometry and UV verification also passed.

egg-carton-market: bake and close-up inspection pending.

## Colour maps still doubtful

These are visual review flags, not confirmed symbols or upload clearance. All filenames below refer to the regenerated full-resolution colour sheets. Claude must decide whether to repack, recolour or hand-fix them before upload.

### porthole-book-tower

- assets/models/porthole-book-tower/parts/1-ground-floor-front-left-color.png: Round O-like marks and small X-like centres.
- assets/models/porthole-book-tower/parts/2-ground-floor-front-right-color.png: Round O-like marks and angular letter-like patches.
- assets/models/porthole-book-tower/parts/3-ground-floor-back-left-color.png: Broad red U-like bend and blue T-like patch.
- assets/models/porthole-book-tower/parts/4-ground-floor-back-right-color.png: Red Z-like bend and green angular strokes.
- assets/models/porthole-book-tower/parts/5-upper-walls-front-left-color.png: Green star-like junction near the upper centre.
- assets/models/porthole-book-tower/parts/6-upper-walls-front-right-color.png: Cream cross-like junction and red curved letter-like patch.
- assets/models/porthole-book-tower/parts/7-upper-walls-back-left-color.png: Large blue X-like junction and red T-like patch.
- assets/models/porthole-book-tower/parts/8-upper-walls-back-right-color.png: Angular blue frame and green crossed strips.
- assets/models/porthole-book-tower/parts/9-roof-front-left-color.png: Large red X-like junction.
- assets/models/porthole-book-tower/parts/10-roof-front-right-color.png: Red hook/J-like bend against cream.
- assets/models/porthole-book-tower/parts/12-roof-back-right-color.png: Red/cream F-like bars near the bottom left.
- assets/models/porthole-book-tower/parts/13-topper-front-left-color.png: Stacked round O/8-like marks.
- assets/models/porthole-book-tower/parts/14-topper-front-right-color.png: Blue and red O-like loops.
- assets/models/porthole-book-tower/parts/15-topper-back-left-color.png: Blue 2/Z-like bend near the centre.
- assets/models/porthole-book-tower/parts/16-topper-back-right-color.png: Rectangular O-like frames and angular red strokes.

### tissue-box-tower

- assets/models/tissue-box-tower/parts/1-ground-floor-front-left-color.png: Green hooked cross/branch-like silhouette.
- assets/models/tissue-box-tower/parts/2-ground-floor-front-right-color.png: Green hook and blue T-like junctions.
- assets/models/tissue-box-tower/parts/3-ground-floor-back-left-color.png: Green H-like hooked junction.
- assets/models/tissue-box-tower/parts/4-ground-floor-back-right-color.png: Large blue cross and green hooked cross-like junction.
- assets/models/tissue-box-tower/parts/5-upper-walls-front-left-color.png: Large blue X-like junction.
- assets/models/tissue-box-tower/parts/6-upper-walls-front-right-color.png: Blue X-like junction and broad red letter-like patch.
- assets/models/tissue-box-tower/parts/7-upper-walls-back-left-color.png: Large blue X/T-like junction.
- assets/models/tissue-box-tower/parts/8-upper-walls-back-right-color.png: Blue X-like junction and red upright T-like patch.
- assets/models/tissue-box-tower/parts/9-roof-front-left-color.png: Large blue M-like patch.
- assets/models/tissue-box-tower/parts/10-roof-front-right-color.png: Blue angular letter-like patch and red upright stroke.
- assets/models/tissue-box-tower/parts/11-roof-back-left-color.png: Blue Y/A-like patch against cream.
- assets/models/tissue-box-tower/parts/12-roof-back-right-color.png: Large blue X-like junction.
- assets/models/tissue-box-tower/parts/13-topper-front-left-color.png: Large red P/O-like loop.
- assets/models/tissue-box-tower/parts/14-topper-front-right-color.png: Red A/Y-like branching patch.
- assets/models/tissue-box-tower/parts/15-topper-back-left-color.png: Red E/F-like branches against white.
- assets/models/tissue-box-tower/parts/16-topper-back-right-color.png: Red F/P-like branches and limb-like silhouette.

### tape-roll-tower

- assets/models/tape-roll-tower/parts/3-ground-floor-back-left-color.png: Broad tan H/T-like joins around the window gaps.
- assets/models/tape-roll-tower/parts/4-ground-floor-back-right-color.png: Broad tan H-like patch.
- assets/models/tape-roll-tower/parts/5-upper-walls-front-left-color.png: Broad tan cross/T-like join.
- assets/models/tape-roll-tower/parts/6-upper-walls-front-right-color.png: Tan H-like join and blue C-like bend.
- assets/models/tape-roll-tower/parts/7-upper-walls-back-left-color.png: Broad tan T-like join and angular blue strokes.
- assets/models/tape-roll-tower/parts/8-upper-walls-back-right-color.png: Broad tan H/T-like joins.
- assets/models/tape-roll-tower/parts/9-roof-front-left-color.png: Tan H-like join against blue.
- assets/models/tape-roll-tower/parts/10-roof-front-right-color.png: Tan H/T-like joins.
- assets/models/tape-roll-tower/parts/11-roof-back-left-color.png: Repeated red X/8-like paired circular motifs.
- assets/models/tape-roll-tower/parts/12-roof-back-right-color.png: Repeated red X/8-like paired circular motifs.
- assets/models/tape-roll-tower/parts/13-topper-front-left-color.png: Large tan inverted-U-like arch.
- assets/models/tape-roll-tower/parts/14-topper-front-right-color.png: Large tan O/C-like arch.
- assets/models/tape-roll-tower/parts/15-topper-back-left-color.png: Large cream O/P-like ring.
- assets/models/tape-roll-tower/parts/16-topper-back-right-color.png: Large cream C/O-like arches.

### juice-carton-tower

Review pending.

### cereal-box-tower

Review pending.

### paint-jar-tower

Review pending.

### pencil-case-bridge

Review pending.

### egg-carton-market

Review pending.

Current doubtful-map count: 45. Five building reviews remain.
