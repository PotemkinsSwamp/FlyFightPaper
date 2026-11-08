# HANDOFF — 2026-11-08 — four new weapons finished (rules, models, sounds); unlock ladder next

**Labels:** kind=product+ui · lane=beta-lane · branch=main · issues= · areas=config/catalog.json, config/gameplay.json, src/shared/CombatRules.luau, src/shared/Aircraft.luau, src/shared/FlightRules.luau, src/server/FlightService.luau, src/server/CombatService.luau, src/server/BotService.luau, src/client/Spitballs.luau, src/client/Audio.luau, tools/art/weapons.py, tools/art/plane_pieces.py, assets/models/toys/weapon-*
**Time:** 2026-11-08 00:20 -05:00

★ START HERE: Goal (Alan): the beta feels like a finished game, one map, a strong first-session hook. CLASSES-PLAN step 3
(four new weapons) is done and Alan-approved ("everything is good"); confirm its last item, the Hangar cards for the
four, then plan step 4 (new unlock ladder) as a short plan for Alan's OK before building it.

> Read on demand: AGENTS.md → this file; docs/plan/CLASSES-PLAN.md (steps 4-7); docs/systems/weapons.md; docs/systems/economy-and-shop.md for step 4. Memories: plan-before-building-features, weapons-need-no-explaining, playtest-notes-before-handoff, studio-play-is-shared, mute-studio-tests.

## STATE (verify before acting)
- HEAD = this handoff's commit on `main`, pushed (GitHub copy via the push hook). Confirm: `git log --oneline -3`, `git status -sb`.
- Tests: 471 passed, 0 failed in Play (2026-11-08). Re-run: DevMute on in Edit → Play → spawn
  `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()` writing `workspace` attribute TestResult; poll in a second call.
- Studio: open, Edit mode, `rojo serve serve.project.json` running. The four new launchers (AircraftPieces) are live-synced
  with their MeshIds but **not saved into FlyFightPaper-WORKING.rbxlx** and **not published** (both Alan's go). Published = v495.
- Docs: `python tools/check_docs.py` OK (152 pages).
- Cost last session: Opus main session only; 5 Codex jobs on Alan's ChatGPT plan (2 picture rounds + 1 spitball redraw,
  3 Blender builds); 13 free mesh uploads, all Approved. Nothing paid. Context at handoff ~45%.

## NEXT ACTION + PLAN
1. Check step 3's last item: the Hangar weapon cards (name, picture, numbers) show right for popper, thumbtack, crayon,
   spitball (Alan looks in Play; menus only from me). Done when Alan says they read right.
2. Step 4, new unlock ladder: write the plan (levels and Paper prices for the four, a reward every level to ~15, the
   "you unlocked" moment, tutorial and bots updated) for Alan's OK — an OK on the plan is NOT a go to code; wait for "build it".
3. Then steps 5-7 (mastery, bots follow the lobby, balance pass), one at a time, each ending in something Alan tries.
- HOLDS (Alan's explicit go each): publish (he does it), Save to File, any upload, desktop control, Studio Play while he's
  playing, a bot match, anything paid.

## DECISIONS & WHY (this session; rulings in docs/decisions + the playtest note)
- Crayon: medium, weight 4 (two only on a Gunship), 40 dmg / 2 s, 600 studs/s, 450 range, drop 8 — 400/350/30 was "impossible to hit".
- Spitball = weight, not a timer: 5 per plane from everyone; each 6% slower, Lift burn +50%, sink 2.5 studs/s (gentle: ~10°
  climb holds height at a full load, Alan: "can't be too harsh"); each of yours stuck = 4 credit (3 → assist). Approved as support.
- Bots fly at full top speed; skill only in turning/pitch (later brake) — decision 2026-11-07-bots-fly-full-speed.
- Ram: overlap check also catches a pass within 2.5 studs in the last 0.1 s; ram vs brush by relative speed (a pass caught
  after crossing pointed the old closing-speed test backwards).
- New weapons keep the hit box they were balanced with (`Aircraft.AMMO`), only the look is new; Popper's lead drawn 0.15 x 1.2
  (true scale was 0.02 thick, invisible). Pieces named `clear` are 0.55 transparent (`plane_pieces.py`).
- Concept pictures are game renders over the toy city, never product photos (Alan; lesson added).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (model router, Codex lane, docs rules, hard limits); memories: plan-before-building-features (ideas ≠ go; one
  weapon at a time), weapons-need-no-explaining, studio-play-is-shared, mute-studio-tests, look-at-textures-before-upload,
  assembled-preview-before-upload, audio-picks-links-and-studio.

## CARRY NOTES / GOTCHAS
- `codex exec` for pictures needs `--skip-git-repo-check` in a scratch folder; Blender jobs run in the repo (`-s workspace-write`). Commit Codex output before touching it.
- Uploading plain weapon FBX parts: `town_toys.send(...)` per part, then LoadAsset in Studio to read each inner MeshId into
  upload.json `meshes` (the model id is not a MeshId); then `python tools/art/plane_pieces.py`. The throwaway uploader lived in scratch.
- A scratch file named `inspect.py` shadowed Python's stdlib (PIL import broke) — never name throwaway scripts after modules.
- The crayon's rubber-band piece renders as a flat frame at the back; Alan didn't object.
- Bot brake skill (Alan's idea) is not built; not requested yet.

## WHAT SHIPPED / OTHER QUEUED
- Shipped (since 4e9e84a2): 5a27ac2a Stubby Crayon rules · 5cf81400 Crayon heavy/slower; Spitball sticks · 01c9b41b Crayon medium weight 4 ·
  a5f6b4c8 spitball hunters dev button · 47ca953e bots at full top speed · d9f65541 spitballs are weight + assists ·
  6884b829 head-on rams; Spitball approved · 9410b6da concept pictures · a5137167 game-render concepts + lesson ·
  17aa2716 Blender models v1 · 3b6ba176 spitball strap/clip concepts · c40db997 strong colours · 9453dbd3 thumbtack no base ·
  057fe699 spitball cup model · bd9b94fd upload records · 377cf021 new weapons fly their own models · 69157c30 own sounds ·
  0c7a12d4 Crayon 600/450/drop 8 · (this handoff's commit).
- Queued: Save to File + publish (Alan's go); CLASSES-PLAN steps 4-7; winners' circle, skins, shop after.

## KNOWLEDGE UPDATED
- docs/systems/weapons.md (four weapons' models, sounds, Spitball rules, AMMO/clear/DRAWN), bots.md (full speed),
  damage-and-deaths.md (ram catch), planes-and-hangar.md (one line); decisions: four-new-weapons (status + Crayon/Spitball
  rows), new bots-fly-full-speed; playtest 2026-11-07-new-weapons-crayon-spitball-models; lessons.md (game-render concepts);
  state/STATE.md rewritten. Checker: OK.

## POINTERS
- Models: tools/art/weapons.py (popper/thumbtack/crayon/spitball builders), assets/models/toys/weapon-<name>/ (ref*.png, pieces.png, upload.json).
- Rules: src/shared/CombatRules.luau (spitball*, credit weight), src/server/FlightService.luau (spit, regionsFor sink, ram), src/client/Spitballs.luau.
