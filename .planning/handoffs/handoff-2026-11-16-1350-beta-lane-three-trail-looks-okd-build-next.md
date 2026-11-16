# HANDOFF — 2026-11-16 — Three trail looks OK'd as 3D videos; nothing in the game yet; build them next

**Labels:** kind=product+ui · lane=beta-lane · branch=main · issues=none · areas=config/trails.json, tools/art, docs/plan/SKINS-PLAN.md, docs/decisions, tests/unit/Commerce.spec.luau
**Time:** 2026-11-16 13:50 -05:00

★ START HERE: Goal (Alan 2026-11-16): finish the beta's looks; the trails are next. Opening action: tell Alan the bots' four chances (skin and trail 35%, skin only 35%, trail only 15%, neither 15%: my reading of his "they also need a roll for having both") and show him the safety sheet of the trail pieces to upload; then put the three OK'd trails (Gold Stars, Storm Sparks, Holo Rainbow) in the game. Done when Alan has seen all three on his plane in Play and says they match the videos, the tests pass, and a 12-plane match holds 60 frames a second.

> Read on demand (pointers, never "in full"): AGENTS.md → THIS; then `docs/plan/SKINS-PLAN.md` section "Trails: how it works" and `config/trails.json` when the step needs them. Memories: effects-are-3d-shown-in-3d, plan-before-building-features, alan-does-play-checks, studio-play-grabs-mouse, mute-studio-tests, look-at-textures-before-upload, assembled-preview-before-upload, no-meshy-blender-only.

## STATE (verify before acting — state drifts between sessions)
- HEAD: this handoff's commit on `main`; the commit hook copies every commit to GitHub (it prints "github: pushed"). Confirm: `git rev-parse --short HEAD`, `git log --oneline -3`.
- Docs: `python tools/check_docs.py` → "docs OK: 196 pages".
- Tests: 665 passed, 2 failed in Play at the session's start (a shop test had skin counts typed by hand). Fixed in `tests/unit/Commerce.spec.luau`; that one file passes 17 of 17 on fresh copies in Studio Edit. **The whole set has NOT been re-run in Play since** (commit `bff6d965` says "667 of 667": that over-claims). Re-run (Alan's go): DevMute on, Play, on the Server `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- Studio: in Edit, DevMute off, place NOT saved. Nothing uploaded this session. Tripo credits 5,820, none used.
- The eight Rares: still not seen in Play (Alan has not given that go yet).
- Cost last session: no helper agents; one Fable session that passed 400,000 tokens and compacted once (the wrap-up came late because the video rounds kept going). About 14 Blender videos at 100 to 200 seconds each, on this PC, free.

## NEXT ACTION + PLAN
1. **The three OK'd trails in the game.** Check: Alan's Play look (his go) against `.planning/skins/trails/gold_stars.mp4`, `storm_sparks.mp4`, `holo_rainbow.mp4`.
   - Pieces to upload (free): the 3D models the videos use (star, flake, spark, bolt; built in `tools/art/trail_preview.py`) and one soft smoke picture (not drawn yet). **Hold:** safety sheet to Alan, his OK, then upload.
   - Drawing: one drawer in `src/client/PlaneLooks.luau` reading `config/trails.json` (not yet wired into `tools/generate_config.py`). The server already sets a `Trail` attribute on each plane.
   - The list: 13 trails in `config/looks.json` and the shop products; the crane's petals come with its skin; the bots' one roll in `LooksRules.botLooks`.
2. Whole test set in Play (his go).
3. Play look at the three trails and the eight Rares; the 12-plane frame-rate check (his go, each).
4. The other ten trails, each as a 3D video for Alan before any upload.
5. Rares follow-ups from his Play notes (undersides, frame rate); Dragon leftovers (see `state/STATE.md`).

**Stop rule for trail looks:** build each new trail as one thick body from the start (lessons page, "Trails"). If Alan turns a video down, the next round is two options side by side; if both miss, ask him what is wrong before a third render.

## DECISIONS & WHY (this session)
All of Alan's words are in `docs/decisions/2026-11-16-first-skin-set.md` ("Trails talk"). The ones that look odd without context:
- **Trails are thick 3D bodies, not strips.** Alan turned down flat pictures, a turning ribbon, cotton balls, wound cords and sparse crystals. So `tools/art/trail_pictures.py` and `assets/fx/trails/trail-rainbow.png` are unused by the three OK'd trails (kept: the other ten may want a picture, and the smoke picture can be drawn there).
- **Holo Rainbow runs through its colours three times** (`"rainbow": 3`). With one run the player saw only pink: the chase camera sits 24 studs behind the plane and the trail is about 105 studs long.
- **How the game will draw them is my plan, not yet tried in Studio:** soft smoke as Roblox's own particles (flat soft cards that face you are what particles are; the rainbow as a colour-over-life setting), 3D pieces as small parts moved on the player's own computer. Fallback if the frame rate drops: flat particles showing a pre-rendered spinning model.
- **Bots:** one roll, four results, 35/35/15/15. The numbers are mine (the same odds as 70% a skin, 50% a trail). Alan asked for "a roll for having both"; he has not seen the four numbers written out.
- **Price of Rare-matching trails is parked** by Alan; the list carries a stand-in of 99 Robux or 1,900 Paper.
- **The videos are a Blender imitation.** Known gaps to check in Studio: a small empty stretch right behind the tail, and big smoke passing close under the player's own camera.

## CONSTRAINTS / PRINCIPLES
- `AGENTS.md` (hard limits, Blender only, explicit gos). Alan's holds, each needing his go: Studio Play (tests included), place saves, publish (he does it), desktop control or screen grabs, Tripo credits (say the count first), bot matches, any new mechanic or number. Every picture or model: his OK on a preview, then the safety check, then upload.
- Memories named in the read line above; also bots-are-the-balance-test, hand-made-not-generic-roblox, no-quality-cuts-for-fps.

## CARRY NOTES / GOTCHAS
- Tests with hand-typed counts that the 13-trail list will break: `Looks.spec` (19 skins, 5 trails, 22 look products), `CommerceService.spec` (`looks==22`). `Commerce.spec` now counts from the config.
- `config/looks.json` still has the old five trails (confetti, rainbow_marker, gold_stars sold; water_spray, dragon_embers bundled); the Trails tab in the hangar lists them and draws nothing.
- Preview a trail: `D:/Blender/blender.exe -b --factory-startup --python tools/art/trail_preview.py -- <id> > "$TEMP/trail-<id>.log" 2>&1` (the log is huge and harmless; read only the DONE line). Two options side by side: `docs/workshop/tools.md`, `trail_preview.py` row.
- The trail videos live in `.planning/skins/trails/` and are not in git.
- Shell traps: a long heredoc with quotes fails in Bash (write the script to a file first); `cd` in one command moves later ones (start commands with `cd /d/FlyFightPaper`); Windows Python cannot open `/c/...` paths.
- Installed this session (free): `youtube-transcript-api` in `D:/pytools/yta`. PhotoCraft's command line (`D:\ArtCraft\PhotoCraft\photocraft-cli.exe`) works with no window and suits flat shapes.

## WHAT SHIPPED / OTHER QUEUED
- `bff6d965` Shop test counts skins from the config, so a longer skin list no longer breaks it
- `43c664b9` Trails talk: Alan's first answers
- `922ccb0d` Trails: how-it-works note written after the talk with Alan
- `b7d7b64a` Alan OK'd the trails note: price parked, bots roll a skin and a trail separately
- `a7bdcadc` Trails: first three drawn as preview videos; picture and video tools
- `8abb6486` State: three trail videos with Alan; bot numbers waiting on him
- `162d77ca` Trails redone in 3D after Alan's "bad"
- `1974d782` Trails: Gold Stars get sparkle dust; storm cloud and rainbow redone as two options each
- `95ad6c6d` Trails: Alan OK'd Gold Stars and picked the soft-smoke storm; Holo Rainbow redone as a thick rainbow cloud
- `776411ff` Trails: Alan picked the three-rainbow cloud for Holo Rainbow; bots make one roll
- This handoff's commit (handoff, LATEST, lessons, tools and hangar pages).
- Queued, not started: everything in `state/STATE.md` "Now" and "Waiting on Alan".

## KNOWLEDGE UPDATED
- `docs/plan/SKINS-PLAN.md`: "Trails: how it works" (the OK'd note, the 13 trails, the three OK'd looks, bots' one roll, smoke as particles).
- `docs/decisions/2026-11-16-first-skin-set.md`: every round of the trails talk in Alan's words.
- `docs/workshop/lessons.md`: new section "Trails (2026-11-16)": thick body first, check the player's own seat, pieces alone make no body, two Blender notes.
- `docs/workshop/tools.md`: `trail_pictures.py` and `trail_preview.py` rows. `docs/systems/planes-and-hangar.md`: Trails tab line.
- `state/STATE.md` rewritten (59 lines). Memory: `effects-are-3d-shown-in-3d` (new, then widened with "one thick body").
- Checker: `python tools/check_docs.py` → docs OK, 196 pages.

## POINTERS
- Trail numbers: `config/trails.json`. Preview tool: `tools/art/trail_preview.py`. Plan: `docs/plan/SKINS-PLAN.md`.
- Game code the build touches: `src/client/PlaneLooks.luau`, `src/client/CombatEffects.luau` (today's boost trail), `src/client/ChaseCamera.luau`, `src/shared/LooksRules.luau`, `src/client/HangarCustomize.luau`, `config/looks.json`, `tools/generate_config.py`.
- Previous handoff: `handoff-2026-11-16-0418-beta-lane-rares-in-game-trails-next.md`.
