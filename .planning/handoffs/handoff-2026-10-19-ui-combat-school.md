# HANDOFF — 2026-10-19 — Combat School built; five rounds of Alan's notes in, more coming

**Labels:** kind=ui+product · lane=ui · branch=main · issues= · areas=src/client/Tutorial.luau, src/client/TutorialLessons.luau, src/shared/TrainingCourse.luau, src/server/RoundRuntime.luau, src/server/FlightService.luau, src/server/CombatService.luau, src/server/BotService.luau, src/client/FlightHUD.luau, src/client/FlightController.luau, src/client/Audio.luau, src/client/DevTools.luau, src/client/MenuController.luau, src/server/MatchmakingAdapter.luau

★ START HERE: Goal: Combat School (Lesson 2 of the tutorial plan) that Alan plays and calls done. He opens the next
session with his notes on it. First action: take his notes, fix them, check each fix in Play (with his go), and have
him play again until he says done. Then the plan's next lessons in order.

> Read on demand: AGENTS.md → THIS → [playtest](../../docs/playtests/2026-10-19-combat-school.md) (every note and
> what was done) → [tutorial page](../../docs/systems/tutorial.md) → [decision](../../docs/decisions/2026-10-19-aiming-and-combat-lessons.md).
> Memories: studio-play-is-shared, studio-play-grabs-mouse, plan-before-building-features.

## STATE (verify before acting)
- HEAD = this handoff's commit on main (after `ca804a6f`); the post-commit hook copies to GitHub. `git status -sb`.
- Tests: 397/0 on 2026-10-18; NOT re-run this session (CombatRules lost its unused practice-target functions; no test
  used them). Re-run in Play: `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()` on the server.
- Last Play (Claude, 2026-10-19, after the final edit): loads with 0 script errors; HUD and Tutorial present; Tutorial
  button opens "Which lesson?"; Play reaches a flying plane. Studio left in Edit, Rojo serving.
- Cost: no subagents, no Codex. Claude ran 3 Play test runs + 2 short load checks (Alan's go). Context ~50% at handoff.

## NEXT ACTION + PLAN
1. Alan's Combat School notes → fix → check in Play (start Play, read the console for errors, drive the step with the
   DevLesson / DevAim / DevAimLead hooks, screenshot) → Alan plays → repeat until he says done. Then a decision note.
2. Not yet checked in Play by Claude: the eraser lock steps, the three Pal fights, the crash path in Combat School.
3. Then the plan's order: Training board + saved ticks + 10-min room, Hangar Tour, Match Tips (+ Settings switch),
   Weapons Range. Then Stage 11.
HOLDS (Alan's go, each): Studio Play runs (grab his mouse; he often plays in the same Play), uploads (he runs them),
publish, Meshy, anything paid, desktop control, closing Studio, Save to File, real product IDs/prices, turning sales on.

## DECISIONS & WHY (this session; details in the decision note)
- Two lessons, Flight School and Combat School (aiming then fighting); Tutorial button asks which; first-time players
  are asked, not sent. Live: the pick rides the teleport (`WantLesson` → TeleportData.lesson → `StartLesson`).
- Targets are real paper planes (`drill` pilots, no brain, flown by FlightService), so every HUD aim help works on them.
  Placed in clear air near the pilot (exact room shapes, fallback = course points). Moving ones sweep across the view.
- Slow motion = only the player's plane at 6% (Lift kept full). Bullets/targets full speed (Alan: don't slow bullets).
- Read, then act: every step that starts in the air freezes the lesson 5 s (`FlightService:freeze`, attribute `Held`:
  aim held on the nose, no firing), countdown on the button, Space goes early.
- Measured: the guns already fire at the lead ring within 7° (`combat.gun_assist_deg`). Alan kept that help. The red
  dot = dot on the orange ring + in range (his rule after a real match); the old shape check was wrong both ways.
- Pals: 60% speed, gentle (no crash, Lift floor), damage stops at 1 Health, never ram; eraser Pal half speed, slower
  after each hit, stops after a miss; Pals hold fire until the player has flown 2 s.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (docs rules, model router, holds); memories above; lessons.md "One error in a client module's start()"
  (now says: after any client edit, start Play and read the console; a compile check can't see it).

## CARRY NOTES / GOTCHAS
- Scripted file edits: assert each replacement matched. Two doc edits this session silently missed (mixed line endings).
- MCP Luau runs in a separate VM: drive game code through attributes (DevLesson on ReplicatedStorage.FlyFightPaper;
  player DevAim / DevAimLead). Injected mouse moves swing the aim; click at screen centre (959,540 at 1918x1080).
- The nose trails a fast crossing target (~0.2 s); the lesson tip says steer a little ahead of the ring.
- Training Room 10-minute timer is in the plan, not built. Old carries: cutscene-start hitch, vote-lap strip, Track C
  needs a private publish, live shop waits for prices, new fan sound (Alan's backlog).

## WHAT SHIPPED / OTHER QUEUED
- 2aa3f34a Practice planes respawn as the training plane · eaf00217 Four more songs; Liberty Bell for lessons ·
  8725a628 Aiming + Combat Training · ba19852b Combat School, picker, first-join question, slower slow-mo, thin frame ·
  e28a31a5 Targets near you, sweeping · 7fd46c96 Lift full, leading step, red not green · 36ee656f Read, then act ·
  69efd386 Aim held while frozen · 941e2765 5 s countdown · 1e08a96e Ring rule, slower/further targets, welcome closes,
  DevAimLead · 44480511 Aim help kept · 262031e6 Fix: HUD crash broke every menu · ca804a6f Red only on the ring ·
  + this handoff commit
- Queued: VIP perks and private servers (Alan decides), cosmetics, special planes, drawing pass (paid check), prices.

## KNOWLEDGE UPDATED
- systems/tutorial (Combat School, read pause, drills, Pals, hooks), systems/menus-and-hud (red dot rule),
  systems/sound-and-effects (songs). decisions: new 2026-10-19-aiming-and-combat-lessons (+README). playtests: new
  2026-10-19-combat-school (+README). plan: TUTORIAL-PLAN lessons 2 parts 1-2, read-then-act, picker, first join.
  workshop/lessons: compile check vs Play. STATE rewritten (55 lines). Checker: OK (106 pages).

## POINTERS
- `src/client/Tutorial.luau` (engine: read pause, crash card, picker/welcome card, slow-mo look, soft frame),
  `src/client/TutorialLessons.luau` (steps), `src/shared/TrainingCourse.luau` (course, drills, sweeps),
  `src/server/RoundRuntime.luau` `Runtime:lesson` (freeze/slow/gentle/repair/drill/pal), `src/server/BotService.luau`
  (Pal brain), `src/client/FlightHUD.luau` (red dot), `src/client/DevTools.luau` (DevAimLead).
