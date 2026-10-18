# Classic folded-paper sample

Local sample only. Original assets, code, config and place files are untouched. No uploads or commits.

## Rebuild

From D:/FlyFightPaper in PowerShell:

```powershell
& D:/Blender/blender.exe -b --factory-startup --threads 4 --python-exit-code 1 --python tools/art/plane_paper.py
```

Only Blender 5.1 and its included NumPy are required. CPU rendering is deterministic. All outputs stay in this folder.

## Review

- compare-threequarter.png: OLD left, NEW right, 1600 x 900. Same camera, scale, lights and matte material response; old uses the exact original geometry and flat colours. Warm-white paper (238,230,212), red details (206,48,43).
- team-red.png / team-blue.png: the exported maps multiplied by actual Aircraft.luau paper tints (235,40,50) / (25,115,255), with white accents and existing white square/circle geometry. Tape is yellow, matching the game.
- closeup-wing.png / closeup-nose.png: actual exported maps on unchanged geometry, 1600 x 900.
- maps-contact-sheet.png: every map, no drawn labels. Each row is listed below; columns are colour, normal, roughness.

## Material and geometry choices

All colour maps have identical R/G/B channels: light neutral paper, subtle fibres, gentle real baked ambient occlusion. No prepainted team colour, text, logos or authored symbols. Atlas gutters have neutral opaque backgrounds, never black cut-out silhouettes.

Normals use Blender MikkTSpace tangents and the UV handedness, OpenGL +Y green up. They contain continuous procedural fibres, fine pulp, a very slight broad wave, pressed channels along existing folds and narrow shading rolls at existing hard edges. No displacement, no added geometry and no silhouette changes. Roughness is matte paper, approximately 0.81-0.90. Metalness should be 0.

The edge-softening compromise is deliberate: normal-map shading instead of geometric bevels preserves every source vertex, seam and bounding box. It cannot round an outline or make a zero-angle grazing silhouette look curved. Existing paper thickness is retained.

Some original half FBXs contain zero-area triangles from their centre cuts. Only those invisible faces are removed in the sample; their count is recorded per file. All original vertex coordinates and all real surface faces are retained.

Classic also has coincident body/wing shoulder faces. Review images temporarily lower the wing regions by 0.0003 stud to stop Cycles shadow-ray interference. Both OLD and NEW receive the same subpixel separation. The saved Blender model, FBXs, UVs, pivots and verification bounds retain the exact original positions. Existing coplanarity remains an integration consideration.

Whole and split meshes are alternative exports. Do not display both simultaneously. Every FBX in classic/ has a same-named sample. The two pellet files are included for completeness. Half-mesh local centring is preserved from the actual half FBXs, with assembly placement recorded from halves.json.

Each mesh has its own non-overlapping PaperUV atlas, no mirrored/stacked charts. Large whole meshes use 1024; small and half meshes use 512 unless their surface area needs 1024. Gutters are 12 pixels. Tiny thin rim triangles naturally receive fewer pixels than the main paper surfaces.

## Import contract

FBX settings match Classic: Y up, -Z forward, global_scale=.01, UnitScaleFactor=1, raw vertex numbers in studs. Reimport with global_scale=100 only to cancel Blender's centimetre interpretation. Do not recenter the mesh or scale an accent to the whole slot. Copy slot_pivot and center_offset_from_slot from manifest.json; these are unchanged from the source records.

Use each entry's color, normal and roughness PNG in SurfaceAppearance.ColorMap, NormalMap and RoughnessMap. Set SurfaceAppearance.Color to the desired runtime tint. Colour is sRGB; normal/roughness are non-colour data. Export materials are neutral. Blender review tints are preview settings only. Game tint integration and Studio review are outside this sample.

## Meshes and contact-sheet rows

| Row | FBX / map prefix | Region | Triangles | Texture size |
|---:|---|---|---:|---:|
| 1 | body-paper-L | paper | 108 | 1024 |
| 2 | body-paper-R | paper | 108 | 1024 |
| 3 | body-paper | paper | 144 | 1024 |
| 4 | nose-accent | accent | 86 | 512 |
| 5 | nose-paper-L | paper | 52 | 512 |
| 6 | nose-paper-R | paper | 52 | 512 |
| 7 | nose-paper | paper | 72 | 512 |
| 8 | pellet-band | band | 64 | 512 |
| 9 | pellet-tube | paper | 192 | 512 |
| 10 | tail-accent | accent | 24 | 512 |
| 11 | tail-paper-L | paper | 92 | 512 |
| 12 | tail-paper-R | paper | 92 | 512 |
| 13 | tail-paper | paper | 96 | 512 |
| 14 | wings-accent-L | accent | 20 | 512 |
| 15 | wings-accent-R | accent | 20 | 512 |
| 16 | wings-accent | accent | 40 | 512 |
| 17 | wings-paper-L | paper | 38 | 1024 |
| 18 | wings-paper-R | paper | 38 | 1024 |
| 19 | wings-paper | paper | 76 | 1024 |
| 20 | wings-sticker-left | sticker | 60 | 512 |
| 21 | wings-sticker-right | sticker | 60 | 512 |

Every row corresponds to <prefix>-color.png, <prefix>-normal.png, <prefix>-roughness.png, left to right.

## Verification

All 21 FBXs were re-imported. Local raw FBX bounds, imported bounds, vertex positions, vertex counts, rendering surfaces, units and UVs were compared with their actual Classic twins. Zero-area source faces are excluded. Tolerance 2e-05 stud. Individual results are in manifest.json.

UV validation includes positive UV triangle area, atlas bounds, independent strict-interior raster overlap checks and analytical triangle clipping to catch subpixel overlaps, repeated after FBX reimport. Source-file SHA-256 values are checked again after the build. No source is opened for writing.

paper-sample.blend opens on the new assembled Classic with the same external maps used by the FBXs. Split alternatives are hidden. Images are also packed for portability, while the PNG sidecars remain the Roblox inputs.
