# Tools

Every script in `tools/`, what it does and when you'd run it. Commands for Alan are PowerShell
(`cd D:\FlyFightPaper; python tools/...`).

## Place, config and Studio
| Script | What it does / when |
|---|---|
| `tools/generate_config.py` | Turns `config/*.json` into Luau in `src/generated/`. Run after every config edit |
| `tools/save_place.py` | Rebuilds the working place with the art, keeping saved art and exact collision. Ctrl+S in Studio first |
| `tools/push_github.py` | Copies new `main` commits to GitHub (no Blender files or review pictures); runs by itself after every commit (`.githooks/post-commit`) |
| `tools/exact_collision.lua` | Run in Studio after a rebuild: new meshes load as solid boxes until this turns on their exact shapes; then Ctrl+S |
| `tools/studio_cli.py` | Calls Studio tools from the shell |
| `tools/studio_shot.sh`, `studio_grab.ps1`, `studio_top.ps1` | Screenshot of the Studio window (only when Studio is in front) |
| `tools/studio_export.lua` | Exports the classroom wall decor from Studio after editing it there |
| `tools/model_sheets.py` | Photographs models from 4 angles in Studio for review sheets |
| `tools/classroom_pictures.lua`, `classroom_trim.lua`, `schoolyard.lua` | Run inside Studio to rebuild wall pictures, wall trim, the schoolyard |
| `tools/ducts.py` | Builds the ceiling and escape ducts (`assets/models/ducts.model.json`) from `config/gameplay.json` `world.ducts` |

## Town and props
| Script | What it does / when |
|---|---|
| `tools/rug.py` | The city play rug: checks the layout, draws the preview, makes tiles, uploads, builds `city-rug.rbxmx`; `--plan assets/rug/replan-v4.json` prints the layout-D town (`preview-v4.png`, `fill-plan-v4.png`, `toy-spots-v4.json`, `--tiles` into `tiles-v4/`; `--upload` sends changed carpet maps and new tiles, `--build` writes `city-rug-v4.rbxmx` with the green stitched edge) |
| `tools/town_toys.py` | Uploads toy and building meshes, builds `city-toys.rbxmx` (`build v4`: the new town's `city-toys-v4.rbxmx`, lamps with a switched-off light), harvests texture packs |
| `tools/town_plan.py` | Plans the town on layout D: streets, river, plazas, monorail loop, the 46 buildings (real sizes), gates, parking lots, driveways, paths, bridges; writes `assets/rug/replan-v4-*` |
| `tools/city_links.py` | Ruler bridges, bell tower and ceiling pieces: plan, check, place |
| `tools/desk_pieces.py` | Desk runways, paper-chain rings and runway lights |
| `tools/toy_place_lua.py` | Prints Luau to re-place chosen toys live in Studio |

## Menus and uploads
| Script | What it does / when |
|---|---|
| `tools/ui_pieces.py` | Cuts one menu screen's art into pieces and (with `--upload`) uploads them |
| `tools/upload_texture.py` | Uploads a picture, FBX or animation (`--animation`, an .rbxm) to Roblox (used by the other upload tools) |
| `tools/winner_hop_animation.luau` | Builds the winners' stand-up-and-hop keyframes in Studio (R15); exported to `assets/animations/winner-hop.rbxm` for upload |
| `tools/meshy.py` | Paid Meshy jobs; every job logged in `assets/MESHY_LOG.md`. Stop at 300 credits left |

## Blender (`tools/art/`)
| Script | What it does |
|---|---|
| `planes.py`, `plane_set.py`, `plane_pieces.py` | Build the plane parts and write `planes/pieces.rbxmx` |
| `split_halves.py` | Cuts plane pieces into left and right halves (wing fit, two-colour free-for-all planes) |
| `weapons.py` | Weapon models in moving pieces |
| `toys.py`, `split_parts.py` | Town toys; splits moving bits like fan blades |
| `hero.py`, `bell_tower.py` | Meshy hero buildings and the bell tower into textured pieces |
| `cut_piece.py` | Cuts a box out of a finished hero building's pieces and closes the cut, keeping its textures (gateway towers' floor off the street) |
| `kit.py` | The classroom building kit |
| `blocks.py` | Blender-built town buildings (replan v3): one function per building, hero-piece output for `town_toys.py hero` |
| `materials.py` | Separates toy-town materials from baked colour sheets |
| `closeups.py` | Close-up render sheet to catch defects before upload |
| `fill_gaps.py` | Fills black gaps in textures so moderation doesn't misread shapes. Run before uploading hero pieces |
| `wind_sprites.py` | Draws the fan-wind particle pictures |
| `carpet.py` | Bakes the one shared rug carpet normal + roughness map (`assets/rug/carpet/`) |

## Docs
| Script | What it does / when |
|---|---|
| `tools/check_docs.py` | Checks every link works, every page is linked, every code file and tool is on a page. Runs automatically before every commit (`.githooks/pre-commit`) |

Back to [HOME](../HOME.md)
