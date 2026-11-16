# HANDOFF — 2026-11-16 — The eight moving Rares are in the game (not yet seen in Play); the trails are next

**Labels:** kind=product · lane=beta-lane · branch=main · issues= · areas=tools/art/rare_sheets.py, tools/art/skin_motion.py, tools/art/upload_skins.py, src/shared/SkinMotion.luau, src/client/PlaneLooks.luau, config/skin-motion.json, config/looks.json, config/commerce.json, assets/models/planes/skins/, tests/unit/, docs/
**Time:** 2026-11-16 04:18 -05:00

★ START HERE: Goal (Alan 2026-11-16): finish the beta's looks; "in the next session, we'll start the trails". Opening action: ask Alan for his go on a Play look at the eight Rares and on the test run, then start the trails with a talk and a how-it-works note for his OK (trails are a new mechanic: no code before that OK). Done when Alan has OK'd the trails note.

> Read on demand: AGENTS.md → this file → [first skin set](../../docs/decisions/2026-11-16-first-skin-set.md) → [skins plan](../../docs/plan/SKINS-PLAN.md) ("Moving Rares", "Ideas" for the trail list) → `docs/workshop/lessons.md` ("Moving skin layers", "Uploads and Roblox moderation"). Memories: `plan-before-building-features`, `send-videos-not-gifs`, `alan-does-play-checks`, `look-at-textures-before-upload`, `hand-made-not-generic-roblox`.

## STATE (verify before acting)
- HEAD = this handoff's commit on `22113978`; main; GitHub copy pushed by the commit hook. Confirm: `git rev-parse --short HEAD`.
- Tests: **not run in Play since two skin-list changes** (665/0 before the first). Counts edited by hand in `Looks.spec` (19 skins, 22 look products) and `CommerceService.spec` (22). The new `SkinMotion.spec` (2 tests) passed in Studio Edit on fresh copies. Re-run (Alan's go, it is a Play): on the server `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`. Docs: `python tools/check_docs.py` OK (196 pages).
- Studio: Edit, code synced by Alan's own `rojo serve` (port 34872). Place NOT saved. My test planes are deleted. `assets/models/planes/skin-looks.rbxmx` was regenerated (1,766 looks); I did not confirm Rojo took the new copy in.
- Uploads: 44 free pictures this session, all Approved (`python tools/art/upload_skins.py check`: 46 of 46). Five are unused first copies, re-sent as squares: 84504014326983 (comet), 99475449895815 (bolt), 74174814675400, 112816129100912, 109491424072975 (the three words). Tripo credits 5,820 (none spent).
- Cost: main session only (Fable 5.2) plus one web-fetch helper (55k tokens); no Codex, no money. About 75% context at handoff: the per-piece rework came late.

## NEXT ACTION + PLAN
1. With Alan's go: the Rares in Play (his look list is in STATE.md, "Waiting on Alan") and the test run. Check: his notes; tests 0 failed.
2. The trails: talk, how-it-works note, his OK, then the build. Today: `config/looks.json` lists five (Confetti, Rainbow Marker, Gold Stars sold; Water Spray and Dragon Embers come with their skins); the Trails tab lists them and draws nothing; concepts `.planning/skins/concepts/trails-1.png`, `trails-2.png`; trails keep their own colours in team games; bots in Common or Rare skins get a random plain trail ([skin rules](../../docs/decisions/2026-11-13-skin-rules.md)).
3. Rares follow-ups, Alan's call after his Play look: layers on undersides (a second set of Decals facing down, twice the layers), the 12-plane frame-rate check with everyone in Galaxy, any speed or brightness changes (numbers in `config/skin-motion.json`; then `python tools/generate_config.py` and `python tools/art/skin_motion_spec.py`).
4. Dragon leftovers: crash ball and shop card pictures, the jaw chevron, the frame-rate check with 12 Dragons.
- HOLDS (Alan's explicit go, each): Studio Play (tests count), place saves, publish (he does it), desktop control or screen grabs, Tripo credits (count first), bot matches, any new mechanic or number (trails are one). Every picture: his OK on a preview (movement as a video), then the safety look, then upload.
- Stop rule: nothing is "done" without Alan's look. After one redo misses, show two options side by side.

## DECISIONS & WHY (this session)
- **The how-it-works note is OK'd** (skins plan, "Moving Rares"): everything stays on the plane, slow and readable, loops, moves wherever worn, within 200 studs; glow is for up close.
- **All eight approved on videos**; Lava and Slime took a redo each (Lava 5 times slower with a deeper pulse; Slime two goo layers at different speeds). Alan's words are in the decision.
- **Galaxy is one small solar system a wing**, not one big orbit: a planet crossing the body's step was cut in two (my call; in STATE "Decisions to review").
- **A Decal ignores the skin's sheet layout**: it stretches its picture over each piece's own box and draws on up-facing sides only. `SkinMotion.decal` sets every piece's layers from the piece's template in `Assets.AircraftPieces`. So undersides and body sides wear the still sheet; the preview videos moved there too.
- **Placed pictures are square** (comet, bolt, words): Roblox scales a picture before it turns it.
- **Far planes keep their layers, standing still** (not removed): Lava's and Slime's layers are the look itself.
- **39 pictures for the eight, not the 28 the note guessed** (glow pictures); all free.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md hard limits and docs rules; Blender only for 3D; Alan wants this work on the Fable model.

## CARRY NOTES / GOTCHAS
- Never seen in Play: the Rares moving (the frame loop in `PlaneLooks.start`), the Skins tab with 19 skins, the tests.
- If a Rare draws plain in Play, check `ReplicatedStorage.FlyFightPaper.Assets.SkinLooks.<id>` and `Generated.SkinPictures` exist (Rojo may not have taken the regenerated files in).
- My first Studio test misread a Decal as following the sheet; a picture with words on real pieces showed the truth at once (lessons.md). Test a layout with words before building on it.
- Rojo's watcher can hold a `src/` file for a moment (a script's write fails, retry). A long here-document in Bash failed to parse twice; write the script to a file first.
- The preview tool draws movement on every face; the game does not (above). Tell Alan when showing a video.
- Preview videos and the Studio picture are untracked in `.planning/skins/rares/` (`<id>.mp4`, `rares-in-studio.jpg`).
- Older carries stand: `tools/art/hero.py.old` untracked on purpose; `tools/plane_areas.lua` after part changes; stray `C:\parts`; backlog (desk photos under the crane, crane gun pieces while firing, Toilet Roll shake recorder).

## WHAT SHIPPED / OTHER QUEUED
- `d5932eff` Moving Rares: how-it-works note written after the talk with Alan; sliding-layer test passed in Studio
- `09759c7f` Alan OK'd the moving-Rares note; preview tools for the eight Rares
- `dbaedcab` All eight Rares drawn and moving in preview videos; Galaxy gets one small solar system a wing
- `535f0591` State: the eight Rares' preview videos are with Alan
- `dd9217d6` Alan's notes on the Rares' videos: six good; Lava slowed five times, Slime redone
- `22113978` The eight moving Rares are in the game: pictures uploaded (approved), layers drawn piece by piece, six new skins in the list
- This handoff's commit: handoff, LATEST, STATE, the spec's generator, tools page.
- Queued after trails: Shark Jet, missions, playtime calendar, bots that use the town.

## KNOWLEDGE UPDATED
- `docs/plan/SKINS-PLAN.md`: "Moving Rares" (the OK'd note, the table as built, how it is drawn, cost, limits, what is left).
- `docs/decisions/2026-11-16-first-skin-set.md`: the Rares talk, Alan's OKs and notes in his words, trails next.
- `docs/systems/planes-and-hangar.md`: the Rares in "Where it stands"; `SkinMotion.luau` in the Code table.
- `docs/workshop/lessons.md`: new section "Moving skin layers" (Decal facts measured in Studio, the misread, drawing for movement, tests in Edit without Play).
- `docs/workshop/tools.md`: `rare_sheets.py`, `skin_motion.py`, `skin_motion_spec.py`, `upload_skins.py`, `skin_preview.py`'s video mode.
- `state/STATE.md` rewritten at the top (59 lines). Checker: OK (196 pages). No memory changes: the lessons are project-bound.

## POINTERS
- Pictures: `tools/art/rare_sheets.py` (one function a Rare) → `assets/models/planes/skins/<id>*.png`. Movement numbers: `config/skin-motion.json`. Video: `python tools/art/skin_motion.py <id>`.
- In the game: `src/shared/SkinMotion.luau` (sums), `src/client/PlaneLooks.luau` (`layersOn`, `move`), `tools/art/skin_looks.py` (the sheet's own glow), `config/skin-pictures.json` (ids by file name, written by `upload_skins.py`).
- What Alan judged: `.planning/skins/rares/*.mp4`.
