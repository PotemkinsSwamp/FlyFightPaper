# HANDOFF — 2026-10-19 — Training board done; Hangar Range designed, rough build played, its art uploaded

**Labels:** kind=ui+product · lane=ui · branch=main · issues= · areas=src/client/Tutorial.luau, src/client/TutorialLessons.luau, src/client/RangeTargets.luau, src/client/FlightController.luau, src/client/ChaseCamera.luau, src/client/PlaneDeaths.luau, src/client/MenuController.luau, src/client/PaperUI.luau, src/server/RoundRuntime.luau, src/server/FlightService.luau, src/server/CombatService.luau, src/server/ProfileService.luau, src/shared/ProfileSchema.luau, src/shared/TrainingCourse.luau, src/shared/UIAssets.luau, assets/ui/trainingboard, assets/ui/range
**Time:** 2026-10-19 17:50 -04:00

★ START HERE: Goal: the **Hangar Range** looking like Alan's concept (`assets/references/ui-concepts/range-stage-view-2.png`)
and working with its side board. First step: replace the stand-in stage and cut-outs with the 35 uploaded pieces (ids in
UIAssets `range`), assembled to match the concept; Alan looks in Play and says how close it is. Then the side board.

> Read on demand: AGENTS.md → THIS → [TUTORIAL-PLAN](../../docs/plan/TUTORIAL-PLAN.md) "The Hangar Range" →
> [decision](../../docs/decisions/2026-10-19-range-map-and-hangar-tour.md) → [tutorial page](../../docs/systems/tutorial.md).
> Memories: alan-does-play-checks (new), plan-before-building-features, studio-play-grabs-mouse, look-at-textures-before-upload.

## STATE (verify before acting)
- HEAD = this handoff's commit on main (after `ba1edceb`); the commit hook pushes to GitHub. `git status -sb`.
- Tests: **399/0** in Play on the server VM this session. Re-run in Play: `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`
  (NOT in Edit: stale module cache, see lessons).
- Studio in Edit, Rojo serving. Alan's last Play: 0 script errors from the Range or board.
- **Not seen in Play by anyone:** the dim-hides-under-menu fix (`aaa228c1`) and the renamed board papers (`ba1edceb`).
- Cost: 1 Sonnet research agent (~136k tokens), 1 Codex review via codex-rescue (~26k), 8 Codex picture jobs (Alan's
  ChatGPT plan), 0 Play runs by Claude. Primary context ~50% at handoff.

## NEXT ACTION + PLAN
1. Real Hangar Range stage from the pieces (backdrop, side curtains mirrored, cardboard town in 2-3 depth layers,
   bushes, ledges, lamps; targets swap `target-<colour>-0..3` by Health, then the two halves fall + `scrap` burst).
   Stand-ins to replace: `Runtime:rangeStage()` (RoundRuntime) and `src/client/RangeTargets.luau`. Placing 3D pieces as
   flat textured parts is fine; never store pixels in Luau. Done when Alan says it looks like the concept.
2. Side board (screen GUI from `board`, `title`, `strip-*`, `scoreCard`, `tag`, `selected`): difficulty picker
   (Noob/Challenge/Veteran/Maneuvers), score card (shots, hits, %), quick loadouts 1-5 (instant, free), Hangar strip
   (opens the in-game hangar menu; saving swaps the plane). Every part triable, even locked (decision to review).
3. First-visit sticky notes. 4. Hangar Tour (lesson 3, runs in the Range). Then Match Tips (Settings switch), Stage 11.
HOLDS (Alan's go, each): Studio Play runs (Alan does the Play checks himself now: give him a "what to look at" list),
uploads (he runs `python tools/ui_pieces.py <screen> --upload`), publish, Meshy, anything paid, desktop control,
closing Studio, Save to File, real product IDs/prices, turning sales on.

## DECISIONS & WHY (this session)
- Training board = its own cork-board art (concept B/C); cards Flight, Combat, Hangar Tour, Hangar Range; no "Coming
  soon" (Alan: we're building them now); Match Tips off the board (Settings). Ticks saved: save schema 6 `lessons`.
- No Training Room time limit (Alan: people leave or get kicked for idling).
- Hangar Range = puppet-theatre stage (not a box), our town as cardboard scenery, theatre fills the view, three rows
  (close = tear speed, far = leading/range), red/blue targets on sticks that flip and tear in steps; name **Hangar
  Range**. Rough build reuses Combat School's drill target planes (all aim help, damage, red dot for free), hidden and
  drawn as cut-outs; the plane is `Pinned` (only turns to aim), own selected build.
- Range is a private room like the Training Room (same place, far spot at `TrainingCourse.RANGE.origin`), not a second place file.
- Publishing a new save schema: shut down old servers first (Codex review; saving page).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (docs rules, model router, holds, commit+push each step); memories above; lessons.md "Uploads", "Studio".

## CARRY NOTES / GOTCHAS
- Hangar Tour/Range card clicks: Range works; Hangar Tour still shows "Almost ready!" (`Tutorial.luau` go()).
- `ui_pieces.py` trims each piece separately: torn halves lose their offset from the whole; place them by eye.
- Concept's red bridge drew as "XXX": never that pattern on uploads (twin-tower piece has a plain beam).
- Old carries: match bots still converge at 150 (Alan's call), vote-lap strip, cutscene hitch, Track C private publish,
  fan sound, live tutorial-room move untested (private publish).

## WHAT SHIPPED / OTHER QUEUED
- 4e3681af Range own map decision + research · c50fc599 time-limit note · bc11984d board stand-in + saved ticks + leave
  fix · 33e9c9a2 board art from Codex · 5d77ab45 board art in, Range card · aaa228c1 dim under menu; shot cast cap ·
  eeec4e85 Range decision + first concept · d0de7eea Range concepts · 94837453 concepts round 2 · 02529341 Range plan ·
  a8d55808 Range rough build · c619e67b Hangar Range name + playtest note · 8f412379 papers redrawn · 2bd91ed2 35 Range
  pieces · ba1edceb ids in UIAssets · + this handoff commit
- Queued: VIP perks/private servers, cosmetics, special planes, drawing pass (paid), prices, bot gun fix (all Alan's).

## KNOWLEDGE UPDATED
- systems/tutorial (board, ticks, no limit, Hangar Range rough build + art, Code table + RangeTargets), systems/saving
  (schema 6, publish rule), plan/TUTORIAL-PLAN (board, The Hangar Range, Hangar Tour as lesson 3), decisions
  range-map-and-hangar-tour (+README), playtests 2026-10-19-training-board-and-range (+README), research
  RANGE-HANGAR-RESEARCH (+HOME), workshop/lessons (4 new), STATE rewritten (58 lines). Checker: OK (111 pages).

## POINTERS
- Concepts: `assets/references/ui-concepts/range-stage-view-2.png`, `range-stage-tear-2.png`, `target-damage-sheet.png`,
  `training-board-c.png`. Pieces: `assets/ui/range/ready/`. Code: `src/server/RoundRuntime.luau` (lesson range, addDrill,
  rangeTargets, rangeStage), `src/client/RangeTargets.luau`, `src/shared/TrainingCourse.luau` (RANGE), `src/client/Tutorial.luau` (board).
