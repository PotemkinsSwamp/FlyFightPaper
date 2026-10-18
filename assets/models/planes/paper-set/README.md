# Modular folded-paper set

Local build only. No uploads, commits or Studio use.

## Rebuild

```powershell
& D:/Blender/blender.exe -b --factory-startup --threads 4 --python-exit-code 1 --python tools/art/plane_paper.py -- --set
```

Blender 5.1 + included NumPy only. Deterministic CPU bakes and 16-sample renders.

## Review

renders/<part>-compare.png: OLD flat source left, NEW right, 1600 x 900. Same geometry, camera, scale and lights.
renders/<part>-blue.png: NEW blue, 1600 x 900. renders/game-distance.png: 23 red parts, 200px longest projected span per part.
contact-sheets/<part>.png: exact PNG bytes at native resolution; one mesh per row, colour/normal/roughness columns. The -boosted sheet stretches each complete map's min/max to 0/255 (constant maps stay neutral). No labels.

## Round 2 response to review

Classic round-2 fold valleys/ridges, bright cut rims, isotropic tooth and shallow handling marks continue across the halves. Joint planes come from this set's slot bounds; coplanar pigment interfaces and split caps are excluded.

## Material and geometry choices

Near-white identical RGB colour channels and opaque neutral gutters throughout. No authored text, logos or symbols. Paper/accent roughness .84, coarser card/tube .88, smooth faintly wrinkled tape .425, smooth rubber .65. Corrugation is confined to actual narrow card edge faces. Tube normals shade continuously around the barrel; its faint wrap follows the existing single raised spiral.
Normal maps use MikkTSpace, OpenGL +Y. No displacement or vertex edits. Only zero-area source triangles are removed and counted. Each mesh has a non-overlapping PaperUV atlas, 12px gutters, 1024 above 48 square studs and 512 otherwise.
Real needle triangles collapsed by Smart Project receive small separate UV charts before packing. Overlapping islands are split at non-coplanar panels; individual triangle charts are a final fallback. Corrections are recorded in the UV checks; no real faces are removed.
Handling fields use each assembled part's own bounds and common world positions. AO sees only that part's assembled display meshes. Wing accents receive a temporary .0003-stud review separation in both old/new; exports retain source positions.

## Import contract

Y up, -Z forward, global_scale=.01, UnitScaleFactor=1, raw coordinates in studs. Do not recenter. Original slot_pivot and center_offset_from_slot values remain in manifest.json. Halves are recentered on X only. Booster pivots and body-specific anchors are copied from parts.json.
Use sidecar maps in SurfaceAppearance and tint at runtime: red paper 214,78,72 / card 165,55,50; blue paper 70,128,214 / card 45,90,170; accents white; tape/elastic 255,212,20. Colour is sRGB, other maps non-colour. Export materials are neutral. No whole-mesh alternatives are exported.

## Meshes and contact-sheet rows

Row numbers restart for each part; columns are colour, normal, roughness.

| Part | Row | FBX / map prefix | Region | Triangles | Texture size |
|---|---:|---|---|---:|---:|
| body_slim | 1 | body_slim-paper-L | paper | 140 | 512 |
| body_slim | 2 | body_slim-paper-R | paper | 141 | 512 |
| body_slim | 3 | body_slim-accent | accent | 24 | 512 |
| body_heavy | 1 | body_heavy-cardboard-L | cardboard | 186 | 1024 |
| body_heavy | 2 | body_heavy-cardboard-R | cardboard | 186 | 1024 |
| body_heavy | 3 | body_heavy-accent | accent | 24 | 512 |
| body_heavy | 4 | body_heavy-tape | tape | 24 | 512 |
| body_standard_mk2 | 1 | body_standard_mk2-paper-L | paper | 162 | 1024 |
| body_standard_mk2 | 2 | body_standard_mk2-paper-R | paper | 160 | 1024 |
| body_standard_mk2 | 3 | body_standard_mk2-accent | accent | 24 | 512 |
| body_slim_mk2 | 1 | body_slim_mk2-paper-L | paper | 140 | 512 |
| body_slim_mk2 | 2 | body_slim_mk2-paper-R | paper | 141 | 512 |
| body_slim_mk2 | 3 | body_slim_mk2-accent | accent | 64 | 512 |
| body_heavy_mk2 | 1 | body_heavy_mk2-tube-L | tube | 400 | 1024 |
| body_heavy_mk2 | 2 | body_heavy_mk2-tube-R | tube | 391 | 1024 |
| body_heavy_mk2 | 3 | body_heavy_mk2-cardboard-L | cardboard | 82 | 512 |
| body_heavy_mk2 | 4 | body_heavy_mk2-cardboard-R | cardboard | 106 | 512 |
| body_heavy_mk2 | 5 | body_heavy_mk2-paper-L | paper | 74 | 512 |
| body_heavy_mk2 | 6 | body_heavy_mk2-paper-R | paper | 74 | 512 |
| body_heavy_mk2 | 7 | body_heavy_mk2-accent | accent | 192 | 512 |
| nose_1 | 1 | nose_1-paper-L | paper | 54 | 512 |
| nose_1 | 2 | nose_1-paper-R | paper | 56 | 512 |
| nose_1 | 3 | nose_1-accent | accent | 86 | 512 |
| nose_2 | 1 | nose_2-paper-L | paper | 52 | 512 |
| nose_2 | 2 | nose_2-paper-R | paper | 52 | 512 |
| nose_2 | 3 | nose_2-accent | accent | 32 | 512 |
| nose_3 | 1 | nose_3-paper-L | paper | 54 | 512 |
| nose_3 | 2 | nose_3-paper-R | paper | 56 | 512 |
| nose_3 | 3 | nose_3-accent | accent | 86 | 512 |
| nose_4 | 1 | nose_4-paper-L | paper | 52 | 512 |
| nose_4 | 2 | nose_4-paper-R | paper | 52 | 512 |
| nose_4 | 3 | nose_4-accent | accent | 86 | 512 |
| nose_5 | 1 | nose_5-paper-L | paper | 52 | 512 |
| nose_5 | 2 | nose_5-paper-R | paper | 52 | 512 |
| nose_5 | 3 | nose_5-accent | accent | 82 | 512 |
| nose_5 | 4 | nose_5-tape | tape | 144 | 512 |
| wings_1 | 1 | wings_1-paper-L | paper | 30 | 512 |
| wings_1 | 2 | wings_1-paper-R | paper | 30 | 512 |
| wings_1 | 3 | wings_1-accent-L | accent | 12 | 512 |
| wings_1 | 4 | wings_1-accent-R | accent | 12 | 512 |
| wings_2 | 1 | wings_2-paper-L | paper | 30 | 1024 |
| wings_2 | 2 | wings_2-paper-R | paper | 30 | 1024 |
| wings_2 | 3 | wings_2-accent-L | accent | 12 | 512 |
| wings_2 | 4 | wings_2-accent-R | accent | 12 | 512 |
| wings_3 | 1 | wings_3-paper-L | paper | 30 | 1024 |
| wings_3 | 2 | wings_3-paper-R | paper | 30 | 1024 |
| wings_3 | 3 | wings_3-accent-L | accent | 12 | 512 |
| wings_3 | 4 | wings_3-accent-R | accent | 12 | 512 |
| wings_4 | 1 | wings_4-paper-L | paper | 46 | 1024 |
| wings_4 | 2 | wings_4-paper-R | paper | 46 | 1024 |
| wings_4 | 3 | wings_4-accent-L | accent | 24 | 512 |
| wings_4 | 4 | wings_4-accent-R | accent | 24 | 512 |
| wings_4 | 5 | wings_4-cardboard-L | cardboard | 30 | 1024 |
| wings_4 | 6 | wings_4-cardboard-R | cardboard | 30 | 1024 |
| wings_5 | 1 | wings_5-paper-L | paper | 198 | 1024 |
| wings_5 | 2 | wings_5-paper-R | paper | 198 | 1024 |
| wings_5 | 3 | wings_5-accent-L | accent | 108 | 512 |
| wings_5 | 4 | wings_5-accent-R | accent | 108 | 512 |
| tail_1 | 1 | tail_1-paper-L | paper | 110 | 512 |
| tail_1 | 2 | tail_1-paper-R | paper | 112 | 512 |
| tail_1 | 3 | tail_1-accent | accent | 48 | 512 |
| tail_2 | 1 | tail_2-paper-L | paper | 182 | 512 |
| tail_2 | 2 | tail_2-paper-R | paper | 182 | 512 |
| tail_2 | 3 | tail_2-accent | accent | 36 | 512 |
| tail_3 | 1 | tail_3-paper-L | paper | 244 | 512 |
| tail_3 | 2 | tail_3-paper-R | paper | 246 | 512 |
| tail_3 | 3 | tail_3-accent | accent | 48 | 512 |
| tail_4 | 1 | tail_4-paper-L | paper | 138 | 512 |
| tail_4 | 2 | tail_4-paper-R | paper | 138 | 512 |
| tail_4 | 3 | tail_4-accent | accent | 24 | 512 |
| tail_5 | 1 | tail_5-paper-L | paper | 132 | 512 |
| tail_5 | 2 | tail_5-paper-R | paper | 134 | 512 |
| tail_5 | 3 | tail_5-accent | accent | 24 | 512 |
| tail_5 | 4 | tail_5-tape | tape | 168 | 512 |
| boost_band | 1 | boost_band-paper-L | paper | 28 | 512 |
| boost_band | 2 | boost_band-paper-R | paper | 28 | 512 |
| boost_band | 3 | boost_band-tape | tape | 48 | 512 |
| boost_band | 4 | boost_band-accent | accent | 24 | 512 |
| boost_band | 5 | boost_band-cardboard-L | cardboard | 88 | 512 |
| boost_band | 6 | boost_band-cardboard-R | cardboard | 88 | 512 |
| boost_band | 7 | boost_band-elastic | elastic | 86 | 512 |
| boost_spool | 1 | boost_spool-paper-L | paper | 122 | 512 |
| boost_spool | 2 | boost_spool-paper-R | paper | 122 | 512 |
| boost_spool | 3 | boost_spool-tape | tape | 48 | 512 |
| boost_spool | 4 | boost_spool-accent | accent | 24 | 512 |
| boost_spool | 5 | boost_spool-cardboard-L | cardboard | 144 | 512 |
| boost_spool | 6 | boost_spool-cardboard-R | cardboard | 144 | 512 |
| boost_spool | 7 | boost_spool-elastic | elastic | 40 | 512 |
| boost_twin | 1 | boost_twin-paper-L | paper | 52 | 512 |
| boost_twin | 2 | boost_twin-paper-R | paper | 52 | 512 |
| boost_twin | 3 | boost_twin-tape | tape | 48 | 512 |
| boost_twin | 4 | boost_twin-accent | accent | 24 | 512 |
| boost_twin | 5 | boost_twin-cardboard-L | cardboard | 88 | 512 |
| boost_twin | 6 | boost_twin-cardboard-R | cardboard | 88 | 512 |
| boost_twin | 7 | boost_twin-elastic | elastic | 172 | 512 |

## Verification

All 95 FBXs pass the existing export_check roundtrip: units, bounds, vertex multiset/count, real surfaces, and UV raster/analytical overlap checks. Tolerance 0.00002 stud. Saved maps are checked for channel equality, unit normals and material roughness. Source and Classic sample SHA-256 checks pass before/after. See manifest.json for individual results.

Build wall time: 1505.1 seconds. Studio appearance remains untested.
