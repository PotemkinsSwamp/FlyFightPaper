# Tools

Every script in `tools/`, what it does and when you'd run it. Commands for Alan are PowerShell
(`cd D:\FlyFightPaper; python tools/...`).

## Place, config and Studio
| Script | What it does / when |
|---|---|
| `tools/generate_config.py` | Turns `config/*.json` into Luau in `src/generated/`. Run after every config edit |
| `tools/skin_sizes.lua` | Run in Studio's Edit, once per body: the size at which each whole-shape skin covers as much of the chase view as the plain plane, with each wing, nose and tail, for `config/skin-sizes.json` ([planes and hangar](../systems/planes-and-hangar.md)). Every new whole-shape skin gets its rows before it ships |
| `tools/save_place.py` | Rebuilds the working place with the art, keeping saved art and exact collision. Ctrl+S in Studio first |
| `tools/push_github.py` | Copies new `main` commits to GitHub (no Blender files or review pictures); runs by itself after every commit (`.githooks/post-commit`) |
| `tools/exact_collision.lua` | Run in Studio after a rebuild: new meshes load as solid boxes until this turns on their exact shapes; then Ctrl+S |
| `tools/studio_cli.py` | Calls Studio tools from the shell |
| `tools/film_report_card.py` | Films the report card (and its Paper jar row) frame by frame in a running Studio Play and joins an MP4 (setup steps in its header; written 2026-11-12 from the scripts that made Alan's videos, not yet run as one piece) |
| `tools/film_gift.py` | Films a friend's gift arriving (three pretend gifts by default) frame by frame in a running, muted Studio Play on the main menu and joins an MP4: `python tools/film_gift.py OUT.mp4 [KEYS] [FPS]` (about 5 minutes; no flying, so no mouse grab) |
| `tools/run_bot_matches.py` | Muted bots-only measuring matches in the open Studio (`[count] [report_at] [tier]`, default 3, 462 s, `ace_mix`): per-bot skill, plane, shots, hits, folds, points, seconds in each state, script errors. Run in the background; needs Alan's go |
| `tools/looks_check/client_sampler.lua`, `tools/looks_check/server_plan.lua` | The scripted skins-and-trails check, run in Play through `tools/studio_cli.py` (client half first, then the server half; needs Alan's go for the Play run, DevMute on, the screen on and Studio in front). The server half forces looks onto all 12 planes step by step (nothing, all dressed, each trail, each skin; or `ClaudePart` = `trails`, `rares` (each Rare, then Galaxy and Circuit Trace alone and together) or `ab` for the fair on/off frame-rate comparison); the client half flies the player's plane on the loop autopilot, counts frame times while it flies and reads what is really on every plane against the configs. Results: LocalPlayer attributes `ClaudeR<step>`. First run and its numbers: [playtest 2026-11-16](../playtests/2026-11-16-scripted-looks-check.md) |
| `tools/cold_cache.py` | Cold-load tests on the PC: `aside` moves Roblox's download cache to a backup folder (Studio and Roblox closed), `open` reopens the cloud place in Studio, `push FILE...` puts changed `src/` files into it (no Rojo link after a reopen); then Play and read `LoadLog.recent()` |
| `tools/studio_shot.sh`, `studio_grab.ps1`, `studio_top.ps1` | Screenshot of the Studio window (only when Studio is in front) |
| `tools/studio_export.lua` | Exports the classroom wall decor from Studio after editing it there |
| `tools/model_sheets.py` | Photographs models from 4 angles in Studio for review sheets |
| `tools/classroom_pictures.lua`, `classroom_trim.lua`, `schoolyard.lua` | Run inside Studio to rebuild wall pictures, wall trim, the schoolyard |
| `tools/ducts.py` | Builds the ceiling and escape ducts (`assets/models/ducts.model.json`) from `config/gameplay.json` `world.ducts` |

## Town and props
| Script | What it does / when |
|---|---|
| `tools/rug.py` | The city play rug: checks the layout, draws the preview, makes tiles, uploads, builds `city-rug.rbxmx`; `--plan assets/rug/replan-v4.json` prints the layout-D town (`preview-v4.png`, `fill-plan-v4.png`, `toy-spots-v4.json`, `--tiles` into `tiles-v4/`; `--upload` sends changed carpet maps and new tiles, `--build` writes `city-rug-v4.rbxmx` with the green stitched edge) |
| `tools/town_toys.py` | Uploads toy and building meshes (`repack FOLDER`: a repacked building's shared sheets and pieces; `swaplua FOLDER`: Luau that swaps its pieces in the open Studio copy), builds `city-toys.rbxmx` (`build v4`: the new town's `city-toys-v4.rbxmx`, lamps with a switched-off light), harvests texture packs; bump/shine maps go up at half size and flat ones share one tiny map per value (`assets/models/flat-maps.json`) |
| `tools/town_plan.py` | Plans the town on layout D: streets, river, plazas, monorail loop, the 46 buildings (real sizes), gates, parking lots, driveways, paths, bridges; writes `assets/rug/replan-v4-*` |
| `tools/city_links.py` | Ruler bridges, bell tower and ceiling pieces: plan, check, place |
| `tools/desk_pieces.py` | Desk runways, paper-chain rings and runway lights |
| `tools/toy_place_lua.py` | Prints Luau to re-place chosen toys live in Studio |

## Menus and uploads
| Script | What it does / when |
|---|---|
| `tools/ui_pieces.py` | Cuts one menu screen's art into pieces and (with `--upload`) uploads them; `--keep-size` skips trimming (9-slice pieces) |
| `tools/ui_sheets.py` | Shrinks menu pieces to their drawn size (`assets/ui/sheets/sizes.json`) and packs the small ones into a few 1024 sheets, menu-only pieces ("3d", drawn by `first/MenuArt`) apart from pieces any flying screen shows (`assets/ui/sheets/usage.json`, read in Studio Play) (contact + compare pictures to look at first); `--add folder/name` puts a new piece into free space on a sheet already built (only that sheet changes); `--upload` uploads changed files and writes `src/first/UISheets.luau` |
| `tools/upload_texture.py` | Uploads a picture, FBX or animation (`--animation`, an .rbxm) to Roblox (used by the other upload tools) |
| `tools/find_bot_looks.luau` | Run in Studio Edit through the Studio link: finds dressed-up outfits real players saved, for bot looks (writes ids to the ServerStorage attribute `BotLookOutfits`, ~5 a minute) for `avatar_display.bot_look_outfits` |
| `tools/meshy_to_r15.py` | Blender script: turns a Meshy text-to-motion clip (SMPL skeleton) into R15 joint poses, `NAME.r15.json` next to it (limbs follow the clip's bones in world space; hips stay over one spot) |
| `tools/r15_keyframes.luau` | Builds KeyframeSequences from `*.r15.json` and registers temporary test ids in Play (attributes `DevEmote_NAME`; set `DevWinnerEmote` to see one in the cutscene) |
| `tools/winner_hop_animation.luau` | Builds the winners' stand-up-and-hop keyframes in Studio (R15); exported to `assets/animations/winner-hop.rbxm` for upload |
| `tools/meshy.py` | Paid Meshy jobs (pictures, models, `motion` = text-to-motion body clips, 10 credits); every job logged in `assets/MESHY_LOG.md`. Stop at 300 credits left |

## Blender (`tools/art/`)
| Script | What it does |
|---|---|
| `planes.py`, `plane_set.py`, `plane_pieces.py` | Build the plane parts and write `planes/pieces.rbxmx` |
| `plane_paper.py` | Paper retexture sample of the Classic plane (UVs, paper colour/normal/roughness maps) into `planes/paper-sample/` |
| `plane_paper.py -- --set` | UVs, paper maps and reviews for the 95 set meshes in [planes/paper-set/README.md](../../assets/models/planes/paper-set/README.md) |
| `skin_sheet.py` | Printed-sheet skin copies of the 98 plane paper, trim and booster pieces (sheet UVs, creases baked into each piece's normal map, sheet template) into `planes/skin-sheet/` ([skins plan](../plan/SKINS-PLAN.md)) |
| `skin_looks.py` | Writes `planes/skin-looks.rbxmx`: one ready-made look (skin picture + piece creases) per skin and piece copy, plus one `Shape` look per shape skin in `config/skin-shapes.json`, and one ready-made Decal per Rare moving layer (`<skin>/Layers/<layer>`, with its glow picture and colour), all cloned by `PlaneLooks.luau` (a game script can't set a look's pictures or a Decal's glow picture) |
| `plane_assembly.py` | Not Blender (Blender can import it): where every piece, gun and booster of any part mix sits, worked out offline the same way `Aircraft.build` does it (`python tools/art/plane_assembly.py body_heavy nose_3 wings_4 tail_3 weapons=pellet,pellet boost=boost_band`); also the gun spots and booster spot a Mythical skin fits around |
| `skin_sheets.py` | Draws the Common skins' printed sheets in code (Carbon Fiber, Racing Stripe, 8-Bit, Neon Grid, Flame Decal, Tie-Dye, Jungle Camo) into `planes/skins/<id>.png`, one 1024 picture each in the skin-sheet layout (`python tools/art/skin_sheets.py [id ...]`); look at them on planes with `skin_preview.py`. Nothing uploaded |
| `skin_preview.py` | A printed-sheet skin (Common, Rare) on two real builds before any upload: every piece with a sheet copy wears the given 1024 picture plus its creases, six views a build (`blender -b --factory-startup --python tools/art/skin_preview.py -- OUT SHEET.png ...`). `FRAMES=1` renders a folder of colour and glow sheets as video frames, three builds in one shot (used by `skin_motion.py`). Nothing uploaded |
| `rare_sheets.py` | Draws the Rare skins' pictures in code: the still sheet `planes/skins/<id>.png` plus its moving layers `<id>-<layer>.png` (see-through) and glow pictures `-glow.png` (`python tools/art/rare_sheets.py [id ...]`; [skins plan](../plan/SKINS-PLAN.md), "Moving Rares"). Nothing uploaded |
| `skin_motion_spec.py` | Rewrites `tests/unit/SkinMotion.spec.luau` with the preview tool's own numbers (where every Rare layer sits at a few moments), so the game's `SkinMotion.luau` is held to the approved videos; run after `config/skin-motion.json` changes (`python tools/art/skin_motion_spec.py`) |
| `skin_hit_hulls.py` | The five Legendaries' hidden hit copies: each built skin less its extras (spoiler, top fin, scarf), tall fins cut flat where a normal tail fin ends, as one FBX in Roblox's axes plus each copy's box (`D:/Blender/blender.exe -b --factory-startup --python tools/art/skin_hit_hulls.py -- OUT.fbx`); upload with `tools/upload_texture.py --model`, read the MeshIds with `LoadAsset`, measure the skin's screen sizes with `tools/skin_sizes.lua` ([planes and hangar](../systems/planes-and-hangar.md)) |
| `upload_skins.py` | Uploads a skin's pictures one at a time after Alan's OK and the safety look: the still sheet and a Rare's layers and glow pictures (`python tools/art/upload_skins.py <id> ...`; `check` reads every picture's moderation result). Records ids in `planes/skins/uploads.json` and writes `config/skin-pictures.json`; run `tools/generate_config.py` and `skin_looks.py` after |
| `skin_motion.py` | A moving Rare as a video on real planes before any upload: plays `config/skin-motion.json` (each layer's slide, turn, path and glow) over the still sheet frame by frame, renders through `skin_preview.py` and joins the frames with ffmpeg into `.planning/skins/rares/<id>.mp4` (`python tools/art/skin_motion.py <id> [seconds]`). Nothing uploaded |
| `trail_pictures.py` | Draws the trails' ribbon pictures in code into `assets/fx/trails/` (`python tools/art/trail_pictures.py`; [skins plan](../plan/SKINS-PLAN.md), "Trails"): a 512 x 64 strip spanning the whole trail, see-through near its long edges. Today: one six-band rainbow strip, which no OK'd trail uses (Alan turned ribbons down); the smoke picture for Storm Sparks and Holo Rainbow is still to draw. The trails' pieces are 3D models, built in `trail_preview.py`. PhotoCraft's command line (`D:\ArtCraft\PhotoCraft\photocraft-cli.exe`, no window; `run --new ... --cmd shape.create ...`) drew the first flat pictures fine and is the tool for flat shapes if a trail needs them again. |
| `trail_preview.py` | A trail as a 3D video before any upload (`blender -b --factory-startup --python tools/art/trail_preview.py -- <id> [frame ...]` -> `.planning/skins/trails/<id>.mp4`, or stills when frames are given; about 100 s a video, three can run at once): plays `config/trails.json` in a 3D scene, the real starter plane (`plane_assembly.py`) or the matching Legendary model selected by the draft's `preview_skin`, flying a weaving path over a floor with boxes, normal speed then boost; first the game's chase camera, then another plane's view from alongside. Builds the 3D pieces itself (star, flake, shard, spark, puff, bolt, and a soft smoke card). Two options side by side: render both ids, then join them with ffmpeg (`hstack`, a letter drawn on each; the pairs are `.planning/skins/trails/<id>-A-or-B.mp4`). An imitation of the game's drawing: confirm the real look in Studio after upload. Blender prints many harmless "Shadow buffer full" lines: send its output to a log. |
| `trail_pieces.py` | The trail pieces as 3D models, used by `trail_preview.py`: uploaded ones (`UPLOADED`: star, bolt, curl, note, notes, petal, dart, jog), ones only in drafts or unused (heart, butterfly, shard, spark, puff, trace, board, four-point Ninja star, checkered flag, flame tongue, water drop) and plain shapes the game makes itself (ball, cube, bar, strip, chip, square). Run alone (`blender -b --factory-startup --python tools/art/trail_pieces.py [-- piece ...]`) it writes `assets/models/trails/<piece>.fbx` for the named `UPLOADED` pieces (all of them with no names) and their safety sheet `.planning/skins/trails/safety-sheet.png`. The `-- legendary` option exports the four new draft meshes and makes their separate `legendary-pieces.png` review sheet. The flags and stars carry their two colours in the mesh. Nothing uploaded: after Alan's OK, `python tools/upload_texture.py <fbx> --creator 52064999 --name "FFP trail <piece>" --output assets/models/trails/upload-<piece>.json --model`, one at a time, then read each Model's inner MeshId in Studio (`LoadAsset`) into `config/trails.json` `meshes` |
| `trail_spark_showers.py` | Draws the Race Car's grinding sparks as tapered paths with hot tips. Also renders the earlier split-grain comparison. |
| `trail_atlas.py` | Makes the shared color and opacity texture for the Legendary trail pieces. |
| `export_legendary_trails.py` | Exports the approved trail pieces and Stealth's weighted glass wake together from Blender, with UVs for the shared texture. |
| `export_legendary_hulls.py` | Exports the four approved Legendary hulls from their Blender builds with their texture coordinates and measurements for fitting to a player's plane. |
| `fetch_trail_assets.py` | Reads the uploaded model in Studio Edit, records its inner mesh IDs and sizes, and saves the glass wake with its 13 bones for Rojo. |
| `trail_skids.py` | Draws periodic rubbed-rubber marks along the Race Car's flight path for the `photo_finish:skid` Blender preview. |
| `trail_cloak.py` | Refracts a clean view of the scenery through Stealth's continuous slipstream or the earlier swept-wing pockets. The ruled floor makes the bend visible at flight speed. |
| `trail_surf.py` | Models the Shark wake's breaking crests and its two jaws with attached teeth. Poses the bite around one hinge in the Blender review. |
| `trail_finishes.py` | Blender materials for brushed steel, reflective folded foil, worn rubber and soft-edged flame in the Legendary trail reviews. |
| `legendary_trail_options.json` | The two visual treatments per Legendary. Pass the trail name with `:A` or `:B` to the preview tool. |
| `trail_review_cut.py` | Labels the two views of each trail and assembles the five comparison clips into a single reel. Pass `shark` for water, `sparks` for metal showers, `continuity` for grinding sparks and the continuous cloak, `skid` for the large rubber marks, or `bursts` for Race Car's revised spark timing. |
| `trail_drafts.json` | Trail looks still being shown to Alan (the ten after the first three), in the words of `config/trails.json`; `trail_preview.py` reads it for any trail the game's config does not have. A trail's row moves to `config/trails.json` when Alan OKs its video and `PlaneTrails.luau` can draw it |
| `crane_skin.py` | The Origami Crane Mythical skin: builds the crane (joints placed from the real plane), paints its 1024 colour/normal/roughness pictures, fits it to three builds and renders previews (`-- OUTDIR [--quick]`; [skins plan](../plan/SKINS-PLAN.md)). `--sheet` also paints `crane-sheet.png`, its printed-sheet picture for boosters, and dresses the renders' boosters in it. Nothing uploaded |
| `ninja_motion.py` | Rigs the approved Ninja model from `tail-10`. Run Blender in the background with `--python tools/art/ninja_motion.py -- render` to write the packed `assets/models/ninja/ninja-motion.blend` and the flight preview. The flight action also drives delayed samples used to bend the two scarf tails. |
| `sheet_model.py` | A shape skin from its measured model sheet (Alan's method, 2026-11-14): body lofted through the sheet's outlines plus measured pieces (tubes, faceted blades, plates traced with the concept-to-blender skill's `sheet_tools.py`) in plain colours with scales on the body (the Dragon), or painted by projecting the sheet's SIDE/TOP/BOTTOM/FRONT views (the Shark), bumps and glow, renders beside the sheet and from the chase camera (`python tools/art/sheet_model.py SPEC.json`; [skins plan](../plan/SKINS-PLAN.md)). First used for the Dragon's head test. `uv.upright` lays every texture piece the same way up (no pinwheel layouts: [lessons](lessons.md)). Nothing uploaded |
| `upload_paper.py` | Uploads paper plane pieces and maps (`set` for paper-set/, `sheet` for the skin copies in skin-sheet/: mesh + crease map; resumable; ids in `<folder>/uploads.json`), then `lua` / `meshes` record each upload's inner MeshId (FBXs upload as Models) |
| `split_halves.py` | Cuts plane pieces into left and right halves (wing fit, two-colour free-for-all planes) |
| `weapons.py` | Weapon models in moving pieces |
| `toys.py`, `split_parts.py` | Town toys; splits moving bits like fan blades |
| `hero.py`, `bell_tower.py` | Meshy hero buildings and the bell tower into textured pieces |
| `cut_piece.py` | Cuts a box out of a finished hero building's pieces and closes the cut, keeping its textures (gateway towers' floor off the street) |
| `kit.py` | The classroom building kit |
| `blocks.py` | Blender-built town buildings (replan v3): one function per building, hero-piece output for `town_toys.py hero` |
| `materials.py` | Separates toy-town materials from baked colour sheets |
| `closeups.py` | Close-up render sheet to catch defects before upload |
| `cut_paper.py` | Not Blender: one white construction-paper card cut neatly with scissors (straight snips, snipped corners, paper grain, black shadow), for tinting in the game (the Missions cards) |
| `square_from_strip.py` | Not Blender: cuts a little torn square from a menu strip's plain middle (the notes' red X box) |
| `unlock_pieces.py` | Not Blender: the unlock backpack's upload pictures from `assets/ui/unlock/source` (12 unzip frames that gape like a real zipper, the sheet's corner tapes cut out, a cream button) and the numbers `UnlockMoment.luau` needs |
| `widen_paper.py` | Not Blender: makes a ruled paper wider by repeating plain bands on both sides of its tape, lines kept continuous (the Hangar stats paper) |
| `repack.py` | Repacks a building's pieces onto shared 2048 sheets by moving UV islands whole pixels only (same pixels, 4x fewer picture files); `--check` proves geometry and every texel unchanged. Output `FOLDER/repacked/` (pictures and FBXs not kept in git: re-run to remake), uploaded by `town_toys.py repack` |
| `repack_compare.py` | Renders a building's `parts/` pieces and its `repacked/` pieces from 5 fixed views in Blender and diffs them (`--all` for every building); contact sheets and `summary.txt` in `.planning/repack-check/`. Checks the repack files only, not what Roblox draws |
| `fill_gaps.py` | Fills black gaps in textures so moderation doesn't misread shapes. Run before uploading hero pieces |
| `wind_sprites.py` | Draws the fan-wind particle pictures |
| `shop_pieces.py` | Turns Codex's shop pieces (`assets/ui/shop/raw/`) into upload-ready ones in `assets/ui/shop/source/` (trims, splits the big ones, makes the white gift icon and the ray ticks, cuts the two Paper jar drawings with one box so they line up); then `tools/ui_pieces.py shop --keep-size --upload`. How to swap one picture is in its header |
| `report_card.py` | Draws the results card's report card (paper, border, seal, table lines; no words) and the red pen ring into `assets/ui/results/ready/` |
| `carpet.py` | Bakes the one shared rug carpet normal + roughness map (`assets/rug/carpet/`) |

## Docs
| Script | What it does / when |
|---|---|
| `tools/check_docs.py` | Checks every link works, every page is linked, every code file and tool is on a page. Runs automatically before every commit (`.githooks/pre-commit`) |

Back to [HOME](../HOME.md)
