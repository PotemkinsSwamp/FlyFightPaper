# HANDOFF — 2026-10-19 — Hangar Range stage, targets and row picker built; still camera; side board decided, next

**Labels:** kind=ui+product · lane=ui · branch=main · issues= · areas=src/server/RangeStage.luau, src/client/RangeTargets.luau, src/client/ChaseCamera.luau, src/client/FlightController.luau, src/client/FlightHUD.luau, src/client/Audio.luau, src/server/RoundRuntime.luau, src/server/Bootstrap.server.luau, src/shared/TrainingCourse.luau, src/shared/UIAssets.luau, assets/ui/range
**Time:** 2026-10-19 22:25 -04:00

★ START HERE: Goal: the Hangar Range's **side board** working, shot like the plates. First step: lay the board out at the
right edge of the still Range view from the uploaded pieces (UIAssets `range`: board, title, strip-*, scoreCard, tag,
selected) and send Alan an **assembled preview** (PIL onto a Studio capture) before building; build after his OK. Done
when Alan plays it and says it works.

> Read on demand: AGENTS.md → THIS → [TUTORIAL-PLAN](../../docs/plan/TUTORIAL-PLAN.md) "The Hangar Range" (side board
> and Range loadouts) → [decision](../../docs/decisions/2026-10-19-range-row-picker-and-aim-pick.md) → [tutorial page](../../docs/systems/tutorial.md).
> Memories: assembled-preview-before-upload (new), alan-does-play-checks, studio-play-grabs-mouse, plan-before-building-features.

## STATE (verify before acting)
- HEAD = this handoff's commit on main (after `8ec600ab`); the commit hook copies to GitHub. `git log --oneline -3`.
- Tests: last full run 399/0 on 2026-10-19 (previous session); NOT re-run since this session's changes (FlightHUD aim
  pick, TrainingCourse RANGE shape). Re-run in Play from the server VM: `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- Studio in Edit, Rojo serving (`rojo serve serve.project.json`). Studio id changes between restarts: `list_roblox_studios`.
- Claude's last Play (Alan asked "try it"): Range opens via client `Root:SetAttribute("DevLesson","range")`; plates pick
  rows (Close tested), 27/40 hits on the lead ring at 410 studs, 0 errors seen.
- **Alan has not yet seen the last fix** (plane hung low, shots meet the crosshair, `8ec600ab`) in his own Play.
- Cost: 0 subagents; 1 Codex picture job (picker plates, Alan's ChatGPT plan); 4 Claude Play runs (Alan's request);
  primary context ~45% at handoff.

## NEXT ACTION + PLAN
1. Side board preview → Alan's OK → build: strips you **shoot** (like `RangePick` plates: CanQuery part + `combat.onProp`
   hook): Noob / Challenge / Veteran / Maneuvers (speed, then size, then swoops), score card (shots, hits, %; starts
   over on any change; a Reset strip), loadout strips 1-5 (also keys 1-5), Hangar strip (opens the in-game hangar).
   Words in-game (Kalam), not painted. New art only if the preview shows a gap.
2. **Range loadouts**: five of the Range's own, any part allowed, saved with the profile, never leaving the Range →
   a save-schema change (Codex's lane, Track C saving; publish rule on docs/systems/saving: shut down old servers).
3. First-visit sticky notes. 4. Hangar Tour (lesson 3, in the Range). Then Match Tips (Settings switch), Stage 11.
HOLDS (Alan's go, each): Studio Play runs (Alan does Play checks; give him a "what to look at" list), uploads (he runs
`python tools/ui_pieces.py range --upload`), publish, Meshy, anything paid, desktop control, closing Studio, Save to
File, real product IDs/prices, turning sales on.

## DECISIONS & WHY (this session) — all in the decision note above
- Still camera in the Range (not a chase camera): a swinging camera slid the flat scenery about and showed its edges.
- Plane at `RANGE.seat` (0,0,10): low at the bottom like the concept; it points at what the crosshair is on (plates and
  cut-outs are raycast; else the aim-help target; else the far row at 640) so shots meet the crosshair.
- Aim limits from the camera: yaw 48°, up 28°, down 34° (the plates sit about 46° out and 16° down).
- Lift and Health bars hide in the Range (nothing hurts you there; Lift never runs out).
- Aim help, whole game: marker follows the enemy whose **lead** is nearest the crosshair, 3° stickiness.
- Row picker plates: Close/Medium/Long range/All, 35/28/22/19 studs, on the floor at the bottom corners, All down at start.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md; memories above; lessons.md "Studio and the place file" (4 new Range lessons).

## CARRY NOTES / GOTCHAS
- Edit caches `require`: preview builders by cloning the module and pointing its requires at clones (lessons.md).
- Shell heredoc + Python turned `\\n` into real newlines in Luau strings twice; edit such lines with the Edit tool.
- Close targets look small/high vs the concept (camera 8 up); Alan may want the close row nearer. Not asked yet.
- The weapon bar (bottom right) touches the Long range/All plates' stands.
- Old carries: match bots still converge at 150 (Alan's call), vote-lap strip, cutscene hitch, Track C private publish,
  fan sound, live tutorial-room move untested (private publish).

## WHAT SHIPPED / OTHER QUEUED
- a75700a8 real stage + painted targets · 5ba0e9c5 level plane, row picker, aim pick by lead · 150a1133 picker art
  (Codex) · eeae0266 plates on the floor, sticks · 8724b82b docs · b987383f plate ids, bigger words · ea73dd7f still
  camera, plates hooked up, one floor · 73a77d84 side board decided · 8ec600ab plane low, shots meet crosshair · + this handoff.
- Queued (Alan's): VIP perks/private servers, cosmetics, special planes, drawing pass (paid), prices, bot gun fix.

## KNOWLEDGE UPDATED
- systems/tutorial (Range: stage, targets, still camera, seat, picker, Code table + RangeStage), systems/menus-and-hud
  (aim pick by lead), plan/TUTORIAL-PLAN (side board + Range loadouts), decisions range-row-picker-and-aim-pick (+README),
  playtests 2026-10-19-range-real-stage (+README), workshop/lessons (4 new), STATE rewritten (57 lines). Checker: OK (113 pages).

## POINTERS
- Concept: `assets/references/ui-concepts/range-stage-view-2.png`. Pieces: `assets/ui/range/ready/`. Preview script:
  session scratchpad only (PIL onto a Studio capture with the camera projection; camera = origin*(0,8,22), tilt 4°, FOV 72).
- Code: `src/server/RangeStage.luau` (stage, plates), `src/client/RangeTargets.luau` (cards, plates' tip),
  `src/client/ChaseCamera.luau` (still Range camera), `src/client/FlightController.luau` (aim limits, `steer`),
  `src/server/RoundRuntime.luau` (`rangePick`, `rangeTargets`), `src/shared/TrainingCourse.luau` (`RANGE`).
