# HANDOFF — 2026-10-18 — Flight School attention pass built; six rounds of Alan's notes in, last round unseen

**Labels:** kind=ui+product · lane=ui · branch=main · issues= · areas=src/client/Tutorial.luau, src/client/TutorialLessons.luau, src/client/Audio.luau, src/shared/AirRoutes.luau, src/shared/UIAssets.luau, src/server/FlightService.luau, src/server/RoundRuntime.luau, assets/ui/tutorial, tools/ui_pieces.py

★ START HERE: Goal: Combat Training (Lesson 2 of the tutorial plan) that Alan plays and calls done. Flight School is
APPROVED by Alan (2026-10-18, decision note). First action: find why a respawned practice plane had no boost (crashes
stay on in Combat), then bring Alan a step-by-step Combat Training plan built on the plan's Lesson 2 for his OK
before any code (memory plan-before-building-features). Done = Alan plays it and says done.

> Read on demand: AGENTS.md → THIS → [playtest log](../../docs/playtests/2026-10-18-flight-school-attention.md) (every
> note and what was done) → [tutorial page](../../docs/systems/tutorial.md) → the plan's Lesson 2 when Combat starts.
> Memories: studio-play-is-shared, studio-play-grabs-mouse, plan-before-building-features, look-at-textures-before-upload.

## STATE (verify before acting)
- HEAD = this handoff's commit on main (after `86b3f949`), pushed by the post-commit hook. `git status -sb`.
- Tests: 397/0 in Play earlier this session (before the sound/tutorial-server edits). Re-run needs Play:
  `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()` on the server (5 s).
- Every changed module load-checked in Edit (clone next to the original, `require`): OK. RoundRuntime can't load in
  Edit at all (it failed the same way without this session's edits): judge it in Play.
- Studio open in Edit, Rojo serving (code syncs live; a running Play keeps the code it started with).
- Cost this session: 2 Codex picture jobs (concept ~5 min/98k Codex tokens; game pieces ~10 min/92k), on Alan's
  ChatGPT plan; no Claude subagents; one Play run by Claude (his go). Alan ran one upload (6 images, free). Primary
  context ~42% at handoff.

## NEXT ACTION + PLAN
1. Root-cause the "respawned practice plane had no boost" report (Combat Training keeps crashes). Check: crash a
   practice plane in Combat mode and the new plane has full boost.
2. Combat Training plan for Alan's OK: the plan's Lesson 2 steps (targets, slow foe, foe that shoots back, dodge an
   eraser, fire your own), reusing Flight School's attention look; its own music (Alan: different from Flight
   School's; pick by ear from links like last time); crashes on. Half-built helper: `Runtime:tutorialFoe` +
   `CombatService:enemy` foe rule. Then build, Alan tests, fix until he says done.
3. Then the plan's order: Training board + saved ticks + 8-min room, Hangar Tour, Match Tips (+ Settings switch),
   Weapons Range. Then Stage 11.
HOLDS (Alan's go, each): Studio Play runs (they grab his mouse; he often plays in the same Play: don't drive it while
he does), uploads (he runs them), publish, Meshy, anything paid, desktop control, closing Studio, Save to File, real
product IDs/prices, turning sales on.

## DECISIONS & WHY (this session)
- Concept + pieces approved by Alan; pieces are 9-slice (`FRAME_SLICE`, `TAG_SLICE`); uploaded with
  `ui_pieces.py tutorial --keep-size` (trimming would break the slice rects).
- Turn arrow only when flying the wrong way (>75° off the nose), a flat see-through arrow by the aim circle; the big
  3D arrow was removed (Alan: obnoxious, pointed "forward" into walls). The line does the main pointing.
- Guide line = straight if clear, else the bots' air routes (moved to `src/shared/AirRoutes.luau`, built on the client
  once per lesson, 0.1 s), Catmull-Rom smoothed, re-planned each second, 4.5 studs wide.
- Hoop course is fixed world points, hand-checked in Studio (50 studs clear, legs clear); it ends heading north with
  the west fan 90° left so the Lift note can be read first (Alan).
- Flight School is "gentle" (server `p.gentle` + model attribute `Gentle` so the client won't predict a crumple;
  client sends the lesson name with `practice`): bounce, Lift ≥ 1 s, Boost ≥ 0.01.
  Combat Training must keep crashes (Alan).
- Lesson music: one looped song, APM "Daisy Fresh" (Alan's pick by ear), volume .067; classroom chatter off; every
  step and hoop plays the same soft `ding` (.28), a step's 0.4 s late and once.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (docs rules, model router, holds); memories above; lessons.md "Tutorial UI traps", the packed-line comment
  trap and the Sound-in-Attachment trap (both new today).

## CARRY NOTES / GOTCHAS
- Unexplained: after a crash Alan's new plane had no boost (couldn't do the boost step). Gentle mode hides it in
  Flight School; check before Combat Training (crashes on there).
- Backlog (Alan): replace the real game's fan sound (`Audio.luau` `fan`, still a "wind tunnel" though softer).
- Burst marks at ±30° sit close to a wide frame's corners; fine so far, tune if Alan notices.
- Old carries still open: cutscene-start hitch; vote-lap strip shows the old round; Track C live saving needs a
  private publish; live shop screen waits for prices; e5359191's accidental sweep of art + rbxlx (never `git commit -a`).

## WHAT SHIPPED / OTHER QUEUED
- f0cea6e7 No client crumple in Flight School, Boost floor · + approval commit
- 3217981c Concept pictures (Codex) · 64c05a85 Dim, glow, arrow, line, fixed hoops · bfe8b057 Crayon frame, marks, tag;
  line on air routes (AirRoutes shared) · 9dfe9837 Piece tool keep-size · a23e9983 Pieces (Codex) · 271e57b2 Pieces
  uploaded (Alan) · c9402982 Bigger tag · 83781962 Playtest 1 fixes · bb1d5ffd Note back, bolder line, wrong-way arrow,
  hoops away from the fan · 70db65a8 Lesson music, step chime, desk-card frame · 8874ce1f Sounds heard everywhere,
  one song · 079495d9 Daisy Fresh · 3bf85338 Softer music/dings, quieter fan, Lift step spotlight · 86b3f949 Gentle
  Flight School, frames outside bars, fan ring in Lift step · + this handoff commit
- Queued: VIP perks and private servers (Alan decides), cosmetics, special planes, drawing pass (paid check), prices.

## KNOWLEDGE UPDATED
- systems: tutorial (attention pass, sound, gentle rule), sound-and-effects (lesson song, flat sounds fix), bots (AirRoutes
  moved). plan: TUTORIAL-PLAN "Grabbing attention" + Lesson 1 step 3 brought to current. playtests: new
  2026-10-18-flight-school-attention (+README). workshop: lessons (2 new traps), tools (keep-size). STATE rewritten (58
  lines). Checker: OK (103 pages).

## POINTERS
- `src/client/Tutorial.luau` (engine: focus, frames, line, turn arrow, hoops), `src/client/TutorialLessons.luau`
  (steps), `src/client/Audio.luau` (ding, lesson song, fan), `src/server/FlightService.luau` (`p.gentle`),
  `assets/ui/tutorial/` (pieces, contact sheet, stretch check), `.planning/briefs/2026-10-18-tutorial-attention-*.md`.
