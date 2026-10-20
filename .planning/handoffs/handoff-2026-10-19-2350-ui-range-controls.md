# HANDOFF — 2026-10-19 — Hangar Range controls built and fixed from Alan's Play; the Range's own loadouts next

**Labels:** kind=ui+product · lane=ui · branch=main · issues= · areas=src/server/RangeStage.luau, src/client/RangeBoard.luau, src/server/RoundRuntime.luau, src/server/HitShapes.luau, src/server/FlightService.luau, src/server/CombatService.luau, src/server/HangarService.luau, src/client/FlightController.luau, src/client/FlightHUD.luau, src/client/Tutorial.luau, src/client/TutorialLessons.luau, src/client/MenuController.luau, src/shared/TrainingCourse.luau, docs
**Time:** 2026-10-19 23:50 -04:00

★ START HERE: Goal: the Range keeps **its own five loadouts, with names you can change**, separate from match builds
(picking one in the Range no longer changes the match pick). First: plan it for Alan's OK (memory
plan-before-building-features): where the five live in the save, how renaming works (Hangar), what the strips show.
Saving is Codex's lane (Track C). Done when Alan plays it and says it works.

> Read on demand: AGENTS.md → THIS → [decision](../../docs/decisions/2026-10-19-range-controls-and-menu.md) →
> [tutorial page](../../docs/systems/tutorial.md) (the Range) → TUTORIAL-PLAN "The Hangar Range" ("Range loadouts").
> Memories: plan-before-building-features, alan-does-play-checks, studio-play-is-shared, assembled-preview-before-upload.

## STATE (verify before acting)
- HEAD = this handoff's commit on main (after `a3fc921a`); the commit hook copies to GitHub. `git log --oneline -3`.
- Tests: full suite last run 399/0 (previous sessions); NOT re-run since (needs a Play run = Alan's go). New
  `tests/unit/RangeCourse.spec.luau` passes 2/2 (run in Edit from a cloned copy). Full: in Play from the server,
  `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- Studio: Alan was in Play at handoff; Rojo serving. **The last layout commit (`5d32b68a`, Range Menu/Hangar strips at
  the left, strings behind the paper) was never previewed or played**: Studio was in Play when it was made.
- Cost: 1 Codex second-opinion job (Alan's ChatGPT plan, ~27k tokens); Gemini CLI failed to start (0); 0 Claude Play
  runs (Alan played 3 times); primary context ~42% at handoff.

## NEXT ACTION + PLAN
1. Check `5d32b68a` with Alan (Edit preview when Studio is in Edit, then his Play): the left strips clear of shooting,
   strings read as holding them, both clickable. Fix what he says.
2. **Range loadouts + names** (plan → Alan's OK → build): five Range builds saved with the profile, any part allowed,
   never leaving the Range; renaming in the Hangar; strips and keys 1-5 use them. Save-schema change → Codex (Track C);
   publish rule on docs/systems/saving (shut down old servers).
3. Swap flourish Alan liked: old plane flies off into the distance, new one slides in from behind.
4. First-visit sticky notes, then the Hangar Tour (lesson 3, in the Range), then Match Tips, Stage 11.
HOLDS (Alan's go, each): Studio Play runs (Alan does Play checks; give a what-to-look-at list), uploads (he runs them),
publish, Meshy, anything paid, desktop control, closing Studio, Save to File, real product IDs/prices, turning sales on.

## DECISIONS & WHY (this session) — full list in the decision note
- No side boards; the stage stays open; targets sweep wide/high (`RANGE.targets`): boards ate 40% of the screen.
- Crosshair is the cursor in the Range only (client raycast on click, `RangeBoard`); guns still fire.
- Row plates stay on the floor (one click), not in the menu: Alan, "that's how other games work".
- Range Menu drops on a spring (not a tween: a tween left it stuck halfway 3-4 times).
- Range targets are hit as their flat card (`HitShapes`, 22 x 11.5 box), not the side-on plane under it.
- Nose aims at the lead ring's distance (`FlightState.leadPoint`), so the dot can turn red in the Range.
- Range = room, not lesson (`Lessons.range.room`): no note, K does nothing.
- ponytail: Range loadouts are the saved match builds and set `SelectedPreset` until step 2 lands.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md; memories above; lessons.md "Studio and the place file" (5 new lines this session).

## CARRY NOTES / GOTCHAS
- `refold` now hands network ownership back (`FlightService:refold`); watch other mid-air rebuilds for the same trap.
- Hangar save while in the Range swaps the plane (`HangarService`), but its other messages still talk about the desk.
- Gemini CLI: free personal sign-in no longer supported (Google says move to Antigravity: Alan's account step).
- I dated notes 2026-10-20 by guess mid-session and fixed them; run `date` before dating anything.
- Edit preview can't run while Alan is in Play (Edit datamodel unavailable): wait or ask.
- Old carries: match bots' guns converge at 150 (Alan's call), vote-lap strip, cutscene hitch, Track C private publish,
  fan sound, live tutorial-room move untested.

## WHAT SHIPPED / OTHER QUEUED
- dcbc4d42 nose dot sits on the aim circle · a05ca03e Range is a room, not a lesson · d7821f72 plates back, sticks on
  hinges, layout · 75dd19de controls work (cursor, menu, score, difficulty, loadouts, Hangar) · 740a6256 fixes from
  Play (swap, card hits, lead aim, spring menu, Maneuvers, notes, Menu button) · 5d32b68a left strips, strings behind ·
  b1b9b99f decision note · a3fc921a docs + date fix · + this handoff.
- Queued (Alan's): VIP perks/private servers, cosmetics, special planes, drawing pass (paid), prices, bot gun fix.

## KNOWLEDGE UPDATED
- systems/tutorial (Range paragraph rewritten to current truth; Code table + RangeBoard), decisions
  2026-10-19-range-controls-and-menu (+README), playtests 2026-10-19-range-controls (+README), workshop/lessons (+5:
  drawn stand-in hitbox, refold ownership, flats sorting/9-slice, tween→spring + Gemini, measure play area first),
  STATE rewritten (57 lines). Checker: OK (115 pages).

## POINTERS
- Code: `src/server/RangeStage.luau` (stage, controls, menu sheet), `src/client/RangeBoard.luau` (clicks, spring, score,
  rings, keys), `src/server/RoundRuntime.luau` (`rangeAction`, `rangePick`, `lowerDrill`), `src/shared/TrainingCourse.luau`
  (`RANGE`, `DIFFICULTY`, `difficulty`, weave in `pose`), `src/server/HitShapes.luau` (card hit).
- Edit preview recipe: clone RangeStage + UIAssets + TrainingCourse into a folder, repoint requires, build, capture from
  camera (0,908,12022) looking at (0,901.02,11922.24) with FOV 72; destroy `workspace.RangeStage` after.
