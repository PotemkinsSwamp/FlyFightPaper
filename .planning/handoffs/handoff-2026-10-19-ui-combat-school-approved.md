# HANDOFF — 2026-10-19 — Combat School approved; aiming fixed for the whole game; Training board next

**Labels:** kind=ui+product · lane=ui · branch=main · issues= · areas=src/client/CombatEffects.luau, src/client/FlightHUD.luau, src/client/FlightController.luau, src/client/Tutorial.luau, src/client/TutorialLessons.luau, src/client/Audio.luau, src/server/BotService.luau, src/server/CombatService.luau, src/server/RoundRuntime.luau, src/shared/TrainingCourse.luau, config/gameplay.json

★ START HERE: Goal: the next tutorial piece, the **Training board** (Tutorial button opens a board of the lessons with
saved ticks; the tutorial room's time limit), per the plan's order. Its plan needs Alan's OK before building
(memory plan-before-building-features). Done when Alan plays it and says so. Then Hangar Tour, Match Tips, Weapons Range.

> Read on demand: AGENTS.md → THIS → [TUTORIAL-PLAN](../../docs/plan/TUTORIAL-PLAN.md) ("The Training board", "Build
> order") → [tutorial page](../../docs/systems/tutorial.md). Memories: plan-before-building-features, studio-play-is-shared, studio-play-grabs-mouse.

## STATE (verify before acting)
- HEAD = this handoff's commit on main (after `76d521a4`); the post-commit hook pushes to GitHub. `git status -sb`.
- Tests: **397/0** in Play this session (after fixing two stale test fakes). Re-run in Play on the server:
  `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- Studio in Edit, Rojo serving. Last Play loads: 0 script errors.
- **Not seen in Play by Claude:** the last two commits (lesson sticky note fix `680a46ad`, step 8 Pal rework
  `b332bfb8`/`76d521a4`). Alan played after them and approved the lesson.
- Cost: no subagents, no Codex. Claude ran ~6 Play runs (Alan's go). Context ~45% at handoff.

## NEXT ACTION + PLAN
1. Training board: write the step-by-step plan from TUTORIAL-PLAN ("The Training board", item 4 of "Build order")
   for Alan's OK, then build, check in Play (start, read the console, drive it), Alan plays.
2. Then in order: Hangar Tour, Match Tips (+ its Settings off switch), Weapons Range. Then Stage 11.
HOLDS (Alan's go, each): Studio Play runs (grab his mouse; he often plays in the same Play), uploads (he runs them),
publish, Meshy, anything paid, desktop control, closing Studio, Save to File, real product IDs/prices, turning sales on.

## DECISIONS & WHY (this session)
- **Guns meet at the target's range** (players): fixed at 150 studs the two wing guns crossed and missed a plane seen
  from behind at 300 though the dot was red. Measured after: 12/12 hits at 220. Studio shot recorder `DevShotLog` kept.
- **Aim assist 7 → 3 degrees, lessons too** (Alan, after trying 1 and 0): 7 felt "magnetised"; War Thunder is the
  model. Red dot = you'd hit with NO help ([decision](../../docs/decisions/2026-10-19-less-aim-assist.md)).
- **Match bots still converge at 150** (they miss past it); only the tutorial's hunting Pal got the fix. Changing bots
  makes every match harder: Alan's call (in STATE "Waiting on Alan").
- Combat School shape: pellets only until a last eraser part; Lift always full; Pals spawn in the air, your speed, half
  Health, fly straight away; step 8's Pal comes from behind and aims dead on until you're at half Health, then pulls
  in front and runs; erasers to dodge come from ahead, never while frozen. Details: tutorial page.
- Read pause 2.5 s with a draining bar (look cards 5 s). Mouse ignored 0.1 s after locking (the "jolt left").

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (docs rules, model router, holds, commit+push every step); memories above; workshop/lessons.md "A
  behaviour fix isn't fixed until it's seen in Play" (new) and "One error in a client module's start()".

## CARRY NOTES / GOTCHAS
- Scripted edits: never put a `--` comment mid-line in these one-line Luau statements (it hid the lesson note).
- Bash heredocs with apostrophes inside Python failed once; write the edit script to the scratchpad and run it.
- MCP Luau VM is separate: drive with attributes (DevLesson, DevAimLead, DevAutopilot) or fire `RoundAction("lesson",
  {...})` from the client VM; it can't hold event connections between calls.
- Old carries: cutscene-start hitch, vote-lap strip, Track C needs a private publish, live shop waits for prices,
  new fan sound (Alan's backlog). Paperclip sound volumes not heard by Claude (Alan said OK implicitly by moving on).

## WHAT SHIPPED / OTHER QUEUED
- c9f9fc8e guns meet at target range; Lift full; no eraser until last part; wandering Pals · 84d8d487 no jolt; read bar
  · 45c715ae red dot follows real aim; Pals in the air · f9c559e7 assist 7→1; reload card; erasers from nowhere ·
  b17bf455 fast drill in slow-mo; Pals ahead · 5c7cf352 Pals 5% faster · a008cc98 assist 3; half Health; no eraser
  before freeze · c41f999a assist 1 · 41369b22 assist 3; paperclip ting+zap · 2f6ba740 step 8 hunts; your speed ·
  3aa08861 cut 2nd eraser lock · 05b9c00f note higher, INCOMING under it; no stunts · cdad846c step 8 measured fix ·
  680a46ad lesson note fix · b332bfb8 step 8 from behind · 76d521a4 step 8 dead-on aim · + this handoff commit
- Queued: VIP perks/private servers (Alan), cosmetics, special planes, drawing pass (paid), prices, bot gun fix (Alan).

## KNOWLEDGE UPDATED
- systems/tutorial (Combat School as built, Pals, eraser part, read pause, DevShotLog), menus-and-hud (red dot, assist,
  INCOMING under the note), weapons (convergence rule), sound-and-effects (paperclip). decisions: less-aim-assist,
  combat-school-approved (+README). playtests: 2026-10-19-combat-school rounds 6-16. workshop/lessons: mouse lock
  delta; Play-check lesson. STATE rewritten (57 lines). Checker: OK (108 pages).

## POINTERS
- `src/server/BotService.luau` (placePal, palEraser, wander, Pal brain), `src/client/TutorialLessons.luau`,
  `src/client/Tutorial.luau`, `src/client/FlightHUD.luau` (red dot), `src/client/CombatEffects.luau` (assist),
  `src/server/CombatService.luau` (convergence, DevShotLog), `docs/plan/TUTORIAL-PLAN.md`.
