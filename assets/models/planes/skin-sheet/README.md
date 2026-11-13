# Printed-sheet plane pieces

Local copies only. No uploads, Studio use or changes to today's pieces.

## Rebuild

```powershell
& D:/Blender/blender.exe -b --factory-startup --python-exit-code 1 --python tools/art/skin_sheet.py
```

Blender 5.1 + its bundled Python and NumPy only. Deterministic numerical normal bakes and 32-sample Cycles CPU renders.
The tool refuses to overwrite files that predate its first run. To rebuild its own outputs explicitly, append -- --rebuild. After an interrupted run, -- --resume reuses completed renders only if all FBX/normal/test-skin bytes remain identical.

## Review

../../../.. is the repository root. Reviews are in .planning/skins/sheet/: 50 PNGs at 1600 x 900, two test-skin PNGs, starter/review.jpg and heavy/review.jpg, plus the combined review.jpg.
Rows: three-quarter, top, side, front, bottom. Columns: today / creaseold / crease / hazard / lava. Each cell is 480 x 270.

## Layout

One 1024 x 1024 skin picture, shared across all 54 copies. SheetUV is derived from each piece's unscaled template placement in pieces.rbxmx.
TOP uses x/z, SIDE uses y/z, FRONT uses x/y. Nose is up in TOP and SIDE; FRONT has up at the top. Both sides share the same print. Regional seams are intentional.
Bounds are the union of all in-scope XML boxes, including CFrame rotation, padded 0.25 stud. There are 16 pixel outer margins and 16 pixel gaps. All regions share k=40.612341736960 pixels/stud.
See layout.json for exact bounds, floating-point rectangles, dominant-normal selection and coordinate-to-UV formulas. Rectangles use top-left pixel coordinates, [x,y,width,height]; UV origin is bottom-left.

sheet-template.png has white backing, slot-coloured triangle outlines, regional guides, nose arrows and a word legend. Keep guide lines off a finished skin picture.

## Normal transfer

For each destination texel, bilinearly sample the old normal map using its old UV, decode through Blender's old MikkTSpace tangent frame into object space, then solve the exact inverse of the SheetUV tangent frame. This is a normal bake, not a colour-channel copy.
The old and new frames use unnormalized interpolated Mikk attributes and a pixel-reconstructed signed bitangent. Reference: https://github.com/mmikk/MikkTSpace/blob/master/mikktspace.h and https://docs.blender.org/api/current/bpy.types.Mesh.html#bpy.types.Mesh.calc_tangents.
Facing surfaces have priority: TOP +y, SIDE away from x=0, FRONT -z. Opposite faces only fill uncovered texels. Same-facing overlap chooses the nearest projected surface. There is an 8px Euclidean normal gutter; empty pixels are (128,128,255).
Opposing faces cannot retain independent crease details when they share one texel. Thin triangles below one pixel also cannot retain all source detail. Per-piece coverage and subpixel counts are reported in manifest.json. The reduced shared-sheet texel density is visible in close views; the geometry itself is unchanged.

## Import contract

Y up, -Z forward, global_scale=.01, UnitScaleFactor=1, raw coordinates in studs. Do not recenter or change MeshPart placement/size. These are replacement MeshIds for skins, not new hitboxes. Blender's bundled FBX writer re-encodes the source with only its UV element replaced. Exact raw geometry, normal, smoothing and axis/unit records are fingerprint-checked. This avoids roundtrip geometric-normal drift on source needle faces.
Exactly one UV layer, SheetUV. Normal maps are 1024 x 1024, MikkTSpace tangent-space, OpenGL +Y. Normal data is non-colour. No geometry or image data is stored in game code.

## Using a skin

When a skin is worn, select the same-named sheet copy for each structural paper/cardboard/tube piece. SurfaceAppearance.ColorMap = that skin's shared picture; NormalMap = the piece's own <piece>-normal.png. Colour pictures are sRGB, normals non-colour; use roughness 0.7 (a constant roughness image in Roblox). Keep the colour tint white so it does not alter the skin picture. Accents, tape, elastic and stickers keep their current meshes/maps.

## Checks

Every output FBX is reimported. Bounds/raw FBX units, vertex positions/count, triangle surfaces/count, shading-normal corners, a single named UV layer, finite UVs in [0,1] and agreement with the coordinate formulas are checked. Source needle faces are retained; projected areas and faces below UV float precision are counted, without inflating their projection. Required-check failures raise an error and exit Blender with status 1.
Normal checks: facing priority over all raster candidates, object-space reconstruction, under 1 degree quantization error at selected texel centres, unit normals, saved PNG bytes/resolution and every empty background texel. Render dimensions/nonempty contents, JPEG dimensions/colour agreement and pre-existing file metadata are checked. Input FBX/map/XML/upload files also receive before/after SHA-256 checks. No Studio or engine integration check was performed.
All 54 in-scope MeshIds match their folder's uploads.json. Review-only sticker placeholders reuse the existing paper-sample wings-sticker-left/right geometry/maps; they have no uploads.json entry and are excluded from the 54-source comparison.

## Meshes

| Part | Piece | Triangles | Regions |
|---|---|---:|---|
| body_heavy | body_heavy-cardboard-L | 186 | FRONT, SIDE, TOP |
| body_heavy | body_heavy-cardboard-R | 186 | FRONT, SIDE, TOP |
| body_heavy_mk2 | body_heavy_mk2-cardboard-L | 82 | SIDE, TOP |
| body_heavy_mk2 | body_heavy_mk2-cardboard-R | 106 | SIDE, TOP |
| body_heavy_mk2 | body_heavy_mk2-paper-L | 74 | FRONT, SIDE, TOP |
| body_heavy_mk2 | body_heavy_mk2-paper-R | 74 | FRONT, SIDE, TOP |
| body_heavy_mk2 | body_heavy_mk2-tube-L | 400 | FRONT, SIDE, TOP |
| body_heavy_mk2 | body_heavy_mk2-tube-R | 391 | FRONT, SIDE, TOP |
| body_slim | body_slim-paper-L | 140 | FRONT, SIDE, TOP |
| body_slim | body_slim-paper-R | 141 | FRONT, SIDE, TOP |
| body_slim_mk2 | body_slim_mk2-paper-L | 140 | FRONT, SIDE, TOP |
| body_slim_mk2 | body_slim_mk2-paper-R | 141 | FRONT, SIDE, TOP |
| body_standard | body-paper-L | 108 | FRONT, SIDE, TOP |
| body_standard | body-paper-R | 108 | FRONT, SIDE, TOP |
| body_standard_mk2 | body_standard_mk2-paper-L | 162 | FRONT, SIDE, TOP |
| body_standard_mk2 | body_standard_mk2-paper-R | 160 | FRONT, SIDE, TOP |
| nose_0 | nose-paper-L | 52 | FRONT, SIDE, TOP |
| nose_0 | nose-paper-R | 52 | FRONT, SIDE, TOP |
| nose_1 | nose_1-paper-L | 54 | FRONT, SIDE, TOP |
| nose_1 | nose_1-paper-R | 56 | FRONT, SIDE, TOP |
| nose_2 | nose_2-paper-L | 52 | FRONT, SIDE, TOP |
| nose_2 | nose_2-paper-R | 52 | FRONT, SIDE, TOP |
| nose_3 | nose_3-paper-L | 54 | FRONT, SIDE, TOP |
| nose_3 | nose_3-paper-R | 56 | FRONT, SIDE, TOP |
| nose_4 | nose_4-paper-L | 52 | FRONT, SIDE, TOP |
| nose_4 | nose_4-paper-R | 52 | FRONT, SIDE, TOP |
| nose_5 | nose_5-paper-L | 52 | FRONT, SIDE, TOP |
| nose_5 | nose_5-paper-R | 52 | FRONT, SIDE, TOP |
| tail_0 | tail-paper-L | 92 | FRONT, SIDE, TOP |
| tail_0 | tail-paper-R | 92 | FRONT, SIDE, TOP |
| tail_1 | tail_1-paper-L | 110 | FRONT, SIDE, TOP |
| tail_1 | tail_1-paper-R | 112 | FRONT, SIDE, TOP |
| tail_2 | tail_2-paper-L | 182 | FRONT, SIDE, TOP |
| tail_2 | tail_2-paper-R | 182 | FRONT, SIDE, TOP |
| tail_3 | tail_3-paper-L | 244 | FRONT, SIDE, TOP |
| tail_3 | tail_3-paper-R | 246 | FRONT, SIDE, TOP |
| tail_4 | tail_4-paper-L | 138 | FRONT, SIDE, TOP |
| tail_4 | tail_4-paper-R | 138 | FRONT, SIDE, TOP |
| tail_5 | tail_5-paper-L | 132 | FRONT, SIDE, TOP |
| tail_5 | tail_5-paper-R | 134 | FRONT, SIDE, TOP |
| wings_0 | wings-paper-L | 38 | FRONT, SIDE, TOP |
| wings_0 | wings-paper-R | 38 | FRONT, SIDE, TOP |
| wings_1 | wings_1-paper-L | 30 | FRONT, SIDE, TOP |
| wings_1 | wings_1-paper-R | 30 | FRONT, SIDE, TOP |
| wings_2 | wings_2-paper-L | 30 | FRONT, SIDE, TOP |
| wings_2 | wings_2-paper-R | 30 | FRONT, SIDE, TOP |
| wings_3 | wings_3-paper-L | 30 | FRONT, SIDE, TOP |
| wings_3 | wings_3-paper-R | 30 | FRONT, SIDE, TOP |
| wings_4 | wings_4-cardboard-L | 30 | FRONT, SIDE, TOP |
| wings_4 | wings_4-cardboard-R | 30 | FRONT, SIDE, TOP |
| wings_4 | wings_4-paper-L | 46 | FRONT, SIDE, TOP |
| wings_4 | wings_4-paper-R | 46 | FRONT, SIDE, TOP |
| wings_5 | wings_5-paper-L | 198 | FRONT, SIDE, TOP |
| wings_5 | wings_5-paper-R | 198 | FRONT, SIDE, TOP |

## Concurrent file changes

The metadata watch found changes outside this tool's output paths. They were left alone. This is not an unchanged-repository result; source FBX/map/XML/upload SHA-256 checks still passed.
- .planning/skins/save-rules-run.log
- .planning/skins/sheet/codex-run.log
- config/commerce.json
- docs/decisions/2026-11-13-skin-rules.md
- src/server/CommerceService.luau
- src/server/HangarService.luau
- src/server/ProfileService.luau
- src/shared/CommerceRules.luau
- src/shared/ProfileSchema.luau
- tests/unit/Commerce.spec.luau
- tests/unit/CommerceService.spec.luau
- tests/unit/GiftSave.spec.luau
- tests/unit/ProfileSchema.spec.luau

Build wall time: 186.2 seconds. No uploads or Studio review.
