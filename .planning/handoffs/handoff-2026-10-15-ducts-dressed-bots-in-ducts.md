# HANDOFF — 2026-10-15 — ducts dressed as real HVAC, veteran bots fly them; Alan's look next

★ START HERE: Goal: finish Stage 9 so Alan approves it. Opening action: get Alan's look at the dressed ducts in Play
(his "no longer boring" is the done-check for the design pass) and the mode-vote screen with eyes; meanwhile do the
last unseen checks: a paper target being hit and the rookie graduation flow. Then Stage 9 "what to try" → his approval.

> Read on demand: AGENTS.md → THIS → state/STATE.md; docs/systems/escapes.md, docs/systems/bots.md,
> docs/workshop/lessons.md (5 new lines). Memories: studio-play-is-shared, studio-not-drawing, no-surprise-desktop-control.

## STATE (verify before acting)
- HEAD `5e98e0aa` + this handoff commit, main, local only (never pushed). Confirm: `git log --oneline -5`.
- Tests 292/0 (Play, Server): `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- Studio WORKING open in Edit, Rojo syncing code, Play stopped. Edit holds the NEW ducts (2,924 parts, 40 props,
  loaded by script): kept only if Alan presses Ctrl+S (or `python tools/save_place.py` rebuilds them from
  `assets/models/ducts.model.json`). No scratch left in Studio (PropCandidates and DuctsPreview removed).
- Studio stopped drawing late in the session (RenderStepped 0/s, captures time out): window behind others.
- Cost this session: no subagents, no Codex, no Meshy, no uploads, no spend. Primary context ~42% at handoff.

## NEXT ACTION + PLAN
1. Alan's look at the ducts (STATE "Waiting on Alan" 2). If still boring, ask what reads wrong and iterate in
   `tools/ducts.py` (live preview trick in lessons.md "Previewing a generated model").
2. Unseen checks: a paper target hit (see it fall flat, points land); rookie graduation flow; vote screen with eyes
   (`RoundAction` "devMode" ends a round → results → vote; needs Studio drawing).
3. Stage 9 "what to try" in STATE → Alan's approval (his gate; never mark it done).
HOLDS (Alan's go each): uploads (he runs them), private publish, Studio-settings changes, Meshy spend, anything paid,
desktop control (only if truly necessary or he asks; bringing Studio to front counts), closing Studio. Don't steer
his plane while he plays (check get_studio_state first).

## DECISIONS & WHY (this session)
- Props are free Creator Store meshes drawn as Part + SpecialMesh inside the generated duct model (asset ids in
  `PROPS`, never geometry); no uploads, no moderation risk, rebuilt by `tools/ducts.py`. All decor is non-solid.
- Rejected: a "Lego brick" free model hid a Studio-only pop-up script (deleted); emoji-named army-man uploads skipped
  (same spam pattern); three cobweb meshes showed as white sheets (their see-through look needs SurfaceAppearance).
- Dark is kept by dark colours (no duct part casts shadows, as before); metal look comes from geometry detail
  (creases, joint bands, rivets), not new textures, so nothing to upload.
- Bot runs (`DuctRules.botRuns`): skip fan ducts and the pipe; start 400-700 studs out on a line through the vent
  (inside the 155-stud wall margin), so entries are D-east, M-west, M-east, J-south; exits all 4 vents.
- Bots take a run only with ≥50% Lift AND enough Lift to finish it (Lift drains 1/s; a dry plane sank and crashed
  in testing); a run is abandoned only before the vent; fleeing only to a vent within 500 (no dodging en route).
- `Runtime:bind` ticks the match clock first (root cause of the `wrong_match` error, fixed for all callers).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (model router, Creator Store first, one writer per file, docs check-up each handoff, hard limits).
- Commit with explicit pathspecs (another session works in this repo).

## CARRY NOTES / GOTCHAS
- `src/generated/DuctsPreview.luau` is gitignored scratch for live preview; delete it after use (done this session).
- Writing ducts.model.json can fail with Errno 22 right after a write: retry.
- Duct-run frequency is a guess (40% escape / 12% patrol, config `bots.profiles.*.duct_*`); in 3 min of normal play
  one veteran took one run. Tune on Alan's feel.
- Toilet Roll body jitter still unreproduced; wait for Alan's description.

## WHAT SHIPPED / OTHER QUEUED
- 4b561f95 Ducts look like real HVAC ductwork: creased riveted sheets, mounted fans, steel pipe, cobwebs, spiders, lost toys and tools
- 127c6777 Veteran bots fly through the ceiling ducts to shake pursuers or wander; lighter dust bunnies
- 5e98e0aa A plane respawning as the round's time runs out no longer throws a wrong_match error
- this handoff commit (docs check-up, STATE, lessons).
- Queued: Alan's look → target hit, graduation, vote screen → Stage 9 approval (gated on Alan).

## KNOWLEDGE UPDATED
- docs/systems/escapes.md: what the player sees in the ducts now, where it stands, DuctRules row (bot runs).
- docs/systems/bots.md: veterans in the ducts (rules, config keys, test result).
- docs/workshop/lessons.md: free-model traps, SpecialMesh props, SpotLight 60-stud cap, live model preview, Errno 22.
- state/STATE.md rewritten top, Stage 9 list, decisions to review, waiting on Alan. Checker: OK.

## POINTERS
- Code: tools/ducts.py (PROPS, on_floor/web/spider, motor, creases), src/shared/DuctRules.luau (botRuns),
  src/server/BotService.luau (tryDuct, duct mode), src/server/RoundRuntime.luau (bind). Config: world.ducts.bot_runs.
- Concept: assets/references/mode-concepts/hvac-ducts.png.
