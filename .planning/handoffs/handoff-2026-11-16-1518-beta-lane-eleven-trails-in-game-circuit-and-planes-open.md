# HANDOFF — 2026-11-16 — Eleven trails are in the game (unseen in Play); Circuit Trace's third video and Mini Paper Planes are open

**Labels:** kind=product+ui · lane=beta-lane · branch=main · issues=none · areas=src/client/PlaneTrails.luau, config/trails.json, config/looks.json, src/shared/LooksRules.luau, tools/art, tests/unit, docs/plan/SKINS-PLAN.md, docs/decisions
**Time:** 2026-11-16 15:18 -05:00

★ START HERE: Goal (Alan 2026-11-16): finish the beta's looks; trails first. Opening action: ask Alan for his three answers: (1) Circuit Trace's third video (`.planning/skins/trails/circuit_trace.mp4`): OK or what is wrong; (2) OK to upload the Mini Paper Planes model (safety sheet sent, `.planning/skins/trails/safety-sheet.png`); (3) his notes from flying the eleven trails with the Dev: trail button. Then act on them. Done when all 13 trails are drawn, Alan has seen them in Play and says they match the videos, the tests pass and a 12-plane match holds 60 frames a second.

> Read on demand (pointers, never "in full"): AGENTS.md → THIS; then `docs/plan/SKINS-PLAN.md` ("Trails: how it works", the last paragraph of the list) and `docs/workshop/lessons.md` ("Trails") when the step needs them. Memories: effects-are-3d-shown-in-3d, alan-does-play-checks, no-surprise-desktop-control, look-at-textures-before-upload, playtest-notes-before-handoff, mute-studio-tests.

## STATE (verify before acting — state drifts between sessions)
- HEAD: this handoff's commit on `main`; every commit is copied to GitHub by the hook ("github: pushed"). Confirm: `git rev-parse --short HEAD`, `git log --oneline -3`.
- Docs: `python tools/check_docs.py` → "docs OK: 196 pages".
- Tests: **671 passed, 0 failed in Play** at commit `dcabf8b5` (after the first three trails and the bots' roll). Since then only trail drawing changed: `Trails.spec` passes 5 of 5 on fresh copies in Studio Edit, and all eleven trails ran through the real drawing code there with the real uploaded models, no errors. **The whole set has NOT been re-run in Play since** (Alan's go): DevMute on, Play, Server: `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- **Nobody has seen any trail in Play.** Studio drew no frames during my Play run (viewport 1 x 1) and Alan declined desktop access to its window. The 12-plane frame-rate check is not done.
- Studio: Edit, DevMute off, place NOT saved, Rojo connected. Uploaded this session (all Approved): star, bolt, curl, note, notes, petal (`assets/models/trails/upload-<piece>.json`). Not uploaded: dart. Tripo credits 5,820, none used.
- Cost last session: no helper agents; one Fable session, about half its context used (wrapped up on the context check, no compaction). About 35 Blender videos and still sets on this PC, free. Six free model uploads.

## NEXT ACTION + PLAN
1. **Alan's three answers** (START HERE). Check: his words, recorded in `docs/decisions/2026-11-16-first-skin-set.md`.
2. **Circuit Trace.** If OK'd: its row moves from `tools/art/trail_drafts.json` to `config/trails.json`; the game needs `lattice`, `axes`, `run` and one new model (`jog`, the bent trace: safety sheet, his OK, upload). If turned down again: he has now turned down three; ask what he pictures (a reference picture helps) before any render.
3. **Mini Paper Planes** (after his OK on the sheet): upload `assets/models/trails/dart.fbx`, read its MeshId, add `level` to `PlaneTrails.luau` (fly nose-first: a model's Blender +X arrives as -X), move its row to the config. Check: Edit dry run, then his Play look.
4. **His Play look and the 12-plane frame-rate check** (his flying; what to look at is in `state/STATE.md`). Heaviest: Gold Stars and Glitch Pixels (about 70 to 90 moving parts a plane).
5. **The shop list**: 13 trails in `config/looks.json` and the shop products (today the old five; trails are reached only through Dev: trail). Open before building: `rainbow_marker` is a saved id that testers may own and Holo Rainbow replaces it (my lean: keep the id, change the name); Rare-match price is parked at a 99 Robux / 1,900 Paper stand-in. Tests with hand-typed counts: `Looks.spec` (22 look products), `CommerceService.spec`.
6. The Hangar shows no trail yet (its plane sits in a ViewportFrame, where particles do not draw). Then Rares follow-ups from his Play notes and the Dragon leftovers (`state/STATE.md`).

**Holds, each needing Alan's go:** Studio Play (tests included), place saves, publish (he does it), desktop control or screen grabs, Tripo credits, bot matches, any new mechanic or number. Every picture or model: his OK on a preview, then the safety sheet, then upload.
**Stop rule for trail looks:** a turned-down video comes back as two options; if both miss, ask what is wrong before a third render (Circuit Trace is past that point: see step 2).

## DECISIONS & WHY (this session)
Alan's words for all of these are in `docs/decisions/2026-11-16-first-skin-set.md` ("Trails talk", last bullets).
- **OK'd and in the game:** Gold Stars, Storm Sparks, Holo Rainbow, Chalk Dust, Stardust, Goo Bubbles, Glitch Pixels, Confetti, Music Notes, Folded Petals, Dragon Embers (his pick B: dark smoke full of round embers; twinkling glints "just looks like orange glitter").
- **Paper Hearts is saved for a holiday set** (his call); its draft row stays in `trail_drafts.json`. Replacement: Mini Paper Planes (his pick A over Paper Butterflies; both were my ideas).
- **Bots: one roll, 35/35/15/15** (his OK), `bot_looks` in `config/looks.json`.
- **Smoke, sparkle dust and flat squares use pictures Roblox ships** (`rbxasset://textures/particles/...`), so no picture was drawn or uploaded. Sparkle dust is particles, not 3D parts (170 a second a plane was too many). Plain shapes (flake, strip, cube, bar, ball) are made in code.
- **The petal was reshaped from an almond to a teardrop** before upload: an almond with a centre crease could be misread as a body shape. It differs slightly from the video Alan OK'd; he was told.
- **Looks in the game that are my guesses until seen in Play:** `bright` cubes are lit SmoothPlastic (Neon would look flat); goo bubbles are see-through SmoothPlastic, not Glass (Glass can hide particles behind it); smoke lit by lightning relies on particles taking PointLight light.
- **Draft rows live in `tools/art/trail_drafts.json`**, not the game's config, so the game and its test only ever hold trails it can draw.

## CONSTRAINTS / PRINCIPLES
- `AGENTS.md` (hard limits, Blender only, explicit gos, plain words to Alan). Memories named in the read line; also hand-made-not-generic-roblox, no-quality-cuts-for-fps, bots-are-the-balance-test.

## CARRY NOTES / GOTCHAS
- **Desktop control:** the computer-use grant for "Roblox Studio" does not cover the running window and its screenshot hid Alan's other apps; he declined the second request. When Studio will not draw, stop Play, clear DevMute, hand him the list.
- **A dismissed question dialog is not a yes** (he closed the upload question once, then answered in chat).
- Not verified visually: whether several `Emit(1)` calls in one frame land at their own places (if not, smoke clumps a little each frame); the STEP resize threshold (8%) in `PlaneTrails.luau`.
- The "Dev: trail" button's words were sized by character count (TextSize 14, 230 wide), never seen on screen.
- Shell traps: a heredoc holding Python with quotes fails in Bash here (write the script to a file, then run it); `cd` in one command moves later ones.
- Preview a trail: `D:/Blender/blender.exe -b --factory-startup --python tools/art/trail_preview.py -- <id> [36 126] > "$TEMP/trail-<id>.log" 2>&1` (frames 36 and 126 give a still from the player's seat and one from alongside; compare with Gold Stars at the same frames).
- The trail videos and safety sheet live in `.planning/skins/trails/` and are not in git.

## WHAT SHIPPED / OTHER QUEUED
- `b8899202` Trails: the three OK'd trails are drawn in flight; smoke and sparkles use Roblox's own pictures; Dev: trail button
- `dcabf8b5` Trails: star and bolt uploaded; bots make one roll at 35/35/15/15; 671 tests pass in Play
- `f680d852` Trails: the other ten drafted as 3D looks, with their new shapes and moves in the preview tools
- `bca5b1bd` State: the other ten trails are with Alan as 3D videos
- `9bfe9341` State: put back a waiting item dropped by mistake in the last edit
- `867de9ad` Trails: seven more in the game after Alan's OK; Dragon Embers and Circuit Trace redone as two options each; Paper Hearts saved, two replacement ideas drawn
- `96a50f40` Trails: four models uploaded (all Approved); Dragon Embers is his pick B, in the game; Circuit Trace drafted a third time; Mini Paper Planes picked
- This handoff's commit (handoff, LATEST).
- Queued, not started: plan steps 2 to 6; everything else in `state/STATE.md` "Now" and "Waiting on Alan".

## KNOWLEDGE UPDATED
- `docs/plan/SKINS-PLAN.md`: bots' numbers OK'd; how trails are drawn (built); the other ten: what is in, what is open, Paper Hearts saved.
- `docs/decisions/2026-11-16-first-skin-set.md`: every answer Alan gave this session, in his words.
- `docs/systems/planes-and-hangar.md`: `PlaneTrails.luau` row; eleven trails drawn. `docs/workshop/tools.md`: `trail_pieces.py`, `trail_drafts.json` rows.
- `docs/workshop/lessons.md` ("Trails"): Roblox's own pictures first; desktop control; compare with an approved trail at the same frames; glow colours clip; glints read as glitter; a cloud must not drown the theme; almond shapes; a dismissed question; read a model's way up from its vertices.
- `state/STATE.md` rewritten (59 lines). Memory: none new (the lessons are project-bound and in the docs).
- Checker: `python tools/check_docs.py` → docs OK, 196 pages.

## POINTERS
- Game: `src/client/PlaneTrails.luau`, `config/trails.json`, `tests/unit/Trails.spec.luau`, `src/client/DevTools.luau` (Dev: trail), `src/shared/LooksRules.luau` (`botLooks`).
- Tools: `tools/art/trail_preview.py`, `tools/art/trail_pieces.py`, `tools/art/trail_drafts.json`, `tools/upload_texture.py`.
- Previous handoff: `handoff-2026-11-16-1350-beta-lane-three-trail-looks-okd-build-next.md`.
