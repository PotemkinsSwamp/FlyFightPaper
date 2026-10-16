# Meshy log

## What makes better Roblox buildings (research 2026-10-10, docs.meshy.ai + Meshy help/tutorials)
- Views: same size, angle, framing and background in all 4; subject centred with margin; soft even light, no harsh
  shadows (read as shape); front first. A 3/4 front view is fine.
- Thin parts (railings, pencils, flagpoles) melt: draw them thick with wide gaps, or leave them out and add them clean
  (hero.py touchup.json boxes, or a Blender-built toy like the ruler bridge).
- Round shapes tangle: draw clear flat panels instead (square pencil cup).
- `--raw` turns off Meshy's "image enhancement", which redraws our views first (under test).
- Remesh (5 cr) only decimates; Retexture (10 cr) re-paints. Neither heals melted shapes.
- meshy-7.1 does return real normal/roughness maps for us (docs say it doesn't; checked 2026-10-10).
- Roblox: closed meshes, <=20k triangles each, 1024 maps, OpenGL normals.

| Date | Item | Job | Credits | Result |
|---|---|---|---|---|
| 2026-10-09 | sheet-fill | picture (nano-banana-pro) | 9 | succeeded, kept (concept sheet) |
| 2026-10-09 | sheet-town | picture (nano-banana-pro) | 9 | succeeded, kept (concept sheet) |
| 2026-10-09 | sheet-places | picture (nano-banana-pro) | 9 | succeeded, kept (concept sheet) |
| 2026-10-09 | ducks | 3D model, PBR, 3000 tris | 30 | succeeded, kept |
| 2026-10-09 | sweet-shop | hero model from 4 views, 2k geometry, 4K PBR | 35 | succeeded, kept |
| 2026-10-09 | glue-tower | hero model from 4 views, 2k geometry, 4K PBR | 35 | succeeded, kept? tbd |
| 2026-10-09 | pencil-cup-tower | hero model from 4 views, 2k geometry, 4K PBR | 35 | succeeded, kept? tbd |
| 2026-10-09 | clock-tower | hero model from 4 views, 2k geometry, 4K PBR | 35 | succeeded, kept? tbd |
| 2026-10-09 | crayon-box-tower | hero model from 4 views, 2k geometry, 4K PBR | 35 | succeeded, kept? tbd |
| 2026-10-09 | brick-water-tower | hero model from 4 views, 2k geometry, 4K PBR | 35 | succeeded, kept? tbd |
| 2026-10-09 | notebook-tower | hero model from 4 views, 2k geometry, 4K PBR | 35 | succeeded, kept? tbd |
| 2026-10-09 | gateway-towers | hero model from 4 views, 2k geometry, 4K PBR | 35 | succeeded, kept? tbd |
| 2026-10-09 | milk-carton-tower | hero model from 4 views, 2k geometry, 4K PBR | 35 | succeeded, kept? tbd |
| 2026-10-09 | book-apartments | hero model from 4 views, 2k geometry, 4K PBR | 35 | succeeded, kept? tbd |
| 2026-10-09 | tube-tower | hero model from 4 views, 2k geometry, 4K PBR | 35 | succeeded, kept? tbd |
| 2026-10-09 | banner-tower | hero model from 4 views, 2k geometry, 4K PBR | 35 | succeeded, kept? tbd |
| 2026-10-09 | sharpener-tower | hero model from 4 views, 2k geometry, 4K PBR | 35 | succeeded, kept? tbd |
| 2026-10-09 | tape-dispenser-depot | hero model from 4 views, 2k geometry, 4K PBR | 35 | succeeded, kept? tbd |
| 2026-10-09 | stapler-offices | hero model from 4 views, 2k geometry, 4K PBR | 35 | succeeded, kept? tbd |
| 2026-10-09 | scissors-gate-house | hero model from 4 views, 2k geometry, 4K PBR | 35 | succeeded, kept? tbd |
| 2026-10-09 | eraser-hall | hero model from 4 views, 2k geometry, 4K PBR | 35 | succeeded, kept? tbd |
| 2026-10-09 | paint-palette-school | hero model from 4 views, 2k geometry, 4K PBR | 35 | succeeded, kept? tbd |
| 2026-10-10 | pencil-cup-tower | hero model from 4 views, 2k geometry, 4K PBR | 35 | succeeded, kept? tbd |
| 2026-10-10 | book-stack-spire | hero model from 4 views, 2k geometry, 4K PBR | 35 | succeeded, kept? tbd |
| 2026-10-10 | book-stack-garden | hero model from 4 views, 2k geometry, 4K PBR | 35 | succeeded, kept? tbd |
| 2026-10-10 | book-stack-lookout | hero model from 4 views, 2k geometry, 4K PBR | 35 | succeeded, kept? tbd |
| 2026-10-10 | open-book-hall | hero model from 4 views, 2k geometry, 4K PBR | 35 | succeeded, kept? tbd |
| 2026-10-10 | pencil-case-hall | hero model from 4 views, 2k geometry, 4K PBR | 35 | succeeded, kept? tbd |
| 2026-10-12 | weapon-pencil | picture (nano-banana-2) | 6 | succeeded, kept? tbd |
| 2026-10-12 | weapon-paperclip | picture (nano-banana-2) | 6 | succeeded, kept? tbd |
| 2026-10-12 | weapon-rubber-band | picture (nano-banana-2) | 6 | succeeded, kept? tbd |
| 2026-10-12 | weapon-staple | picture (nano-banana-2) | 6 | succeeded, kept? tbd |
| 2026-10-12 | weapon-eraser | picture (nano-banana-2) | 6 | succeeded, kept? tbd |
| 2026-10-12 | weapon-rubber-band | picture (nano-banana-2) | 6 | succeeded, kept? tbd |
| 2026-10-12 | weapon-staple | picture (nano-banana-2) | 6 | succeeded, kept? tbd |
| 2026-10-12 | weapon-pencil | picture (nano-banana-2) | 6 | succeeded, kept? tbd |
| 2026-10-12 | weapon-pencil-b | picture (nano-banana-2) | 6 | succeeded, kept? tbd |
| 2026-10-12 | weapon-eraser | picture (nano-banana-2) | 6 | succeeded, kept? tbd |
| 2026-10-12 | weapon-paperclip | picture (nano-banana-2) | 6 | succeeded, kept? tbd |
| 2026-10-12 | weapon-rubber-band-top | picture (nano-banana-2) | 6 | succeeded, kept? tbd |
| 2026-10-12 | weapon-rubber-band | picture (nano-banana-2) | 6 | succeeded, kept? tbd |
| 2026-10-12 | weapon-eraser | picture (nano-banana-2) | 6 | succeeded, kept? tbd |
| 2026-10-12 | weapon-pencil-b | picture (nano-banana-2) | 6 | succeeded, kept? tbd |
| 2026-10-12 | weapon-paperclip | picture (nano-banana-2) | 6 | succeeded, kept? tbd |
| 2026-10-12 | weapon-pencil | picture (nano-banana-2) | 6 | succeeded, kept? tbd |
| 2026-10-12 | weapon-staple | 3D model, PBR, 3000 tris | 30 | succeeded, kept? tbd |
| 2026-10-12 | weapon-rubber-band-top | picture (nano-banana-2) | 6 | succeeded, kept? tbd |
| 2026-10-12 | weapon-gatling-a | picture (nano-banana-2) | 6 | succeeded, kept? tbd |
| 2026-10-12 | weapon-gatling-b | picture (nano-banana-2) | 6 | succeeded, kept? tbd |
| 2026-10-12 | weapon-eraser | picture (nano-banana-2) | 6 | succeeded, kept? tbd |
| 2026-10-12 | weapon-pencil-b | 3D model, PBR, 3000 tris | 30 | succeeded, kept? tbd |
| 2026-10-12 | weapon-paperclip | 3D model, PBR, 3000 tris | 30 | succeeded, kept? tbd |
| 2026-10-12 | weapon-eraser | picture (nano-banana-2) | 6 | succeeded, kept? tbd |
| 2026-10-12 | weapon-paperclip | picture (nano-banana-2) | 6 | succeeded, kept? tbd |
| 2026-10-12 | weapon-gatling-a | picture (nano-banana-2) | 6 | succeeded, kept? tbd |
| 2026-10-12 | weapon-gatling-b | picture (nano-banana-2) | 6 | succeeded, kept? tbd |
| 2026-10-12 | weapon-gatling-a | picture (nano-banana-2) | 6 | succeeded, kept? tbd |
| 2026-10-12 | weapon-gatling-b | picture (nano-banana-2) | 6 | succeeded, kept? tbd |
| 2026-10-12 | weapon-paperclip | 3D model, PBR, 3000 tris | 30 | succeeded, kept? tbd |
| 2026-10-12 | weapon-eraser | 3D model, PBR, 3000 tris | 30 | succeeded, kept? tbd |
| 2026-10-12 | weapon-eraser | picture (nano-banana-2) | 6 | succeeded, kept? tbd |
| 2026-10-12 | weapon-paperclip | picture (nano-banana-2) | 6 | succeeded, kept? tbd |
| 2026-10-12 | weapon-gatling-b | 3D model, PBR, 3000 tris | 30 | succeeded, kept? tbd |
| 2026-10-12 | weapon-paperclip-2 | picture (nano-banana-2) | 6 | succeeded, kept? tbd |
| 2026-10-12 | weapon-eraser-2 | picture (nano-banana-2) | 6 | succeeded, kept? tbd |
| 2026-10-12 | weapon-eraser | picture (nano-banana-2) | 6 | succeeded, kept? tbd |
| 2026-10-12 | weapon-paperclip | picture (nano-banana-2) | 6 | succeeded, kept? tbd |
| 2026-10-12 | weapon-paperclip | 3D model, PBR, 3000 tris | 30 | succeeded, kept? tbd |
| 2026-10-12 | weapon-eraser | 3D model, PBR, 3000 tris | 30 | succeeded, kept? tbd |
| 2026-10-12 | weapon-pellet-2 | picture (nano-banana-2) | 6 | succeeded, kept? tbd |
| 2026-10-12 | weapon-pellet | picture (nano-banana-2) | 6 | succeeded, kept? tbd |
| 2026-10-12 | weapon-pellet | 3D model, PBR, 3000 tris | 30 | succeeded, kept? tbd |
| 2026-10-15 | juice-carton-tower | hero model from 4 views, 2k geometry, 4K PBR | 35 | succeeded, kept? tbd |
| 2026-10-15 | porthole-book-tower | hero model from 4 views, 2k geometry, 4K PBR | 35 | succeeded, kept? tbd |
| 2026-10-15 | tissue-box-tower | hero model from 4 views, 2k geometry, 4K PBR | 35 | succeeded, kept? tbd |
| 2026-10-15 | tape-roll-tower | hero model from 4 views, 2k geometry, 4K PBR | 35 | succeeded, kept? tbd |
| 2026-10-15 | paint-jar-tower | hero model from 4 views, 2k geometry, 4K PBR | 35 | succeeded, kept? tbd |
| 2026-10-15 | cereal-box-tower | hero model from 4 views, 2k geometry, 4K PBR | 35 | succeeded, kept? tbd |
| 2026-10-15 | egg-carton-market | hero model from 4 views, 2k geometry, 4K PBR | 35 | succeeded, kept? tbd |
| 2026-10-15 | pencil-case-bridge | hero model from 4 views, 2k geometry, 4K PBR | 35 | succeeded, kept? tbd |
