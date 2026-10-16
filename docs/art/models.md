# Model catalog

Every 3D model still in `assets/models/` and why it is kept. Checked 2026-10-15: a model
counts as in the game if `default.project.json` loads it, or if a loaded model file uses its uploaded mesh or texture
IDs.

## In the game

### Big model files (what Rojo loads into the place)
| File | What it is |
|---|---|
| `classroom.rbxmx` | The room: walls, windows, desks, lamps, fans, hanging planets, 12 chalkboard pieces |
| `city-toys.rbxmx` | Every toy and hero building on the town rug (built by `tools/town_toys.py build`) |
| `city-rug.rbxmx` | The town rug: 280 carpet tiles, border and stitches (built by `tools/rug.py`) |
| `city-toys-v4.rbxmx` | The new town's toys from `toy-spots-v4.json` (`town_toys.py build v4`); goes in with the new town |
| `city-rug-v4.rbxmx` | The new town's playmat rug: 280 tiles + green stitched edge (`tools/rug.py --plan ... --build`); goes in with the new town |
| `classroom-decor.rbxmx` | Wall pictures, pencil cups, backpacks, globe, plants |
| `schoolyard.rbxm` | The schoolyard outside |
| `paper-plane.rbxmx` | Plane template the server copies |
| `texture-packs.json` | Studio texture-pack IDs written into every toy |

### Planes and weapons
| Folder | What it is |
|---|---|
| `planes/` | The modular plane system: 23 parts, stickers, concepts, `pieces.rbxmx` |
| `aircraft/` | Plane meshes and texture sheets |
| `equipment/` | Launchers, ammo and boosters |
| `toys/weapon-eraser`, `weapon-gatling-b`, `weapon-paperclip`, `weapon-pellet`, `weapon-pencil-b`, `weapon-staple` | Weapon models used by the plane pieces |

### Hero buildings in the town (Meshy, cut into 8-44 pieces each)
`bell-tower` (the centrepiece, 44 pieces plus clock), `banner-tower`, `book-apartments`, `book-stack-garden`,
`book-stack-lookout`, `book-stack-spire`, `brick-water-tower`, `clock-tower`, `crayon-box-tower`, `eraser-hall`,
`gateway-towers`, `glue-tower`, `milk-carton-tower`, `notebook-tower`, `open-book-hall`, `paint-palette-school`,
`pencil-case-hall`, `pencil-cup-tower`, `scissors-gate-house`, `sharpener-tower`, `stapler-offices`, `sweet-shop`,
`tape-dispenser-depot`, `tube-tower`.

### New town buildings (replan v3, 2026-10-15; not placed yet)
Meshy: `porthole-book-tower`, `tissue-box-tower`, `tape-roll-tower`, `juice-carton-tower`, `cereal-box-tower`,
`paint-jar-tower`, `egg-carton-market`, `pencil-case-bridge`. Blender (`tools/art/blocks.py`): `sticky-note-tower`,
`shoebox-hall`, `chalk-box-depot`, `abacus-hall`, `block-arch`, `monorail-station-north`, `monorail-station-south`,
`pencil-tin-tower`, `ruler-stilt-tower`, `log-cabin-tower`, `stacking-cup-tower`, `jenga-tower`, `ring-binder-tower`,
`pencil-pillar-tower`. `toys/monorail` holds only its concept so far.

### Other pieces
| Folder | What it is |
|---|---|
| `toys/` (70 subfolders) | Trees, cars, houses, stalls, crop rows, playground, ruler bridges, desk hangar and runway, landing rings, runway lights, ceiling pieces, clock hands, bookshelf, door, cubbies, fire station, terminal |
| `toys/speed-bolt` | The speed power-up |
| `toys/chalk-eraser` | The chalk eraser, built in Blender (`tools/art/toys.py`) from `model-sheet.png`; game copy `chalk-eraser.rbxmx` |
| `kit/` | Toy-brick building kit; 12 pieces used so far ([building kit](building-kit.md)) |
| `chalkboard460/` | Chalkboard meshes |
| `rug-tile/` | The one rug-tile mesh, used 280 times |
| `classroom/` | Only its chalkboard texture is used; the rest is old |

## Old models (removed 2026-10-15)
About 90 old folders that nothing loaded were removed: numbered early models (`airframe284`, `toy469` and the like),
old `meshy3xx`-`meshy7xx` folders, review and backup folders, `_rebake`, unused weapon toys, and old `layouts/`,
`prompts/`, `reviews/` and `runtime/` folders, plus the out-of-date `ASSET_PROVENANCE.json`. Files that were in git
can be brought back from git history. Files that were never in git were moved to
`D:\FlyFightPaper-old-models-2026-10-15` (outside the repo). `toys/desk-runway-straight` stays because
`tools/art/toys.py` still builds it.

## Other asset folders
| Folder | What it holds |
|---|---|
| `assets/references/` | Concept pictures and the approved art target ([reference pictures](references.md)) |
| `assets/ui/` | Menu and HUD art per screen (source, ready, upload records) |
| `assets/rug/` | Rug tiles, upload records, toy positions (`toy-placements.json`), previews |
| `assets/textures/` | Chalkboard textures (v2 "FOLD / FLY / FIGHT" is the live one), wall pictures |
| `assets/fx/` | Fan-wind particle pictures |
| `assets/MESHY_LOG.md` | Meshy tips and every credit spent |

## Related
- [Art pipeline](pipeline.md) · [Building kit](building-kit.md) · [Town and rug](../world/town.md) · [Planes and hangar](../systems/planes-and-hangar.md)

Back to [HOME](../HOME.md)
