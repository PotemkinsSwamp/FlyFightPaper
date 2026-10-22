# HANDOFF — 2026-10-21 — Hangar Tour built and played twice; Hangar gets numbers and try-on/Select

**Labels:** kind=ui+product · lane=ui · branch=main · issues= · areas=src/client/Tutorial.luau, src/client/TutorialLessons.luau, src/client/Hangar.luau, src/client/HangarCustomize.luau, src/client/Audio.luau, src/server/RoundRuntime.luau, src/shared/ProfileSchema.luau, docs
**Time:** 2026-10-21 20:30 -04:00

★ START HERE: Goal: Alan's OK on the Hangar Tour and on Customize's new try-on/Select (click a card = try it on with
+/- numbers vs what you have on; Select puts it on). Opening action: give Alan the what-to-look-at list (below) and wait
for his notes; fix what he says. Done when he says both work. Then the queued UI list (NEXT ACTION 3).

> Read on demand: AGENTS.md → THIS → `docs/playtests/2026-10-21-hangar-tour.md` → `docs/systems/tutorial.md`
> (Hangar Tour paragraph) → `docs/systems/planes-and-hangar.md`. Memories: alan-does-play-checks, studio-play-is-shared.

## STATE (verify before acting)
- HEAD = this handoff's commit on main (after `813401b7`); the commit hook pushes to GitHub. `git log --oneline -3`.
- Tests: ProfileSchema logic re-checked with a fresh module in Edit (hangar tick valid, bad ticks rejected); the
  Edit-VM run showed 1 stale-cache failure (lessons.md "Tests in Edit mode lie"). Full suite in Play on the server:
  `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()` (not run this session).
- Studio: Edit, Rojo serving, Play stopped. Place file not re-saved (Ctrl+S = Alan's go).
- Cost: 0 subagents, 0 Codex, 0 uploads; ~12 Claude Play runs (Alan OK'd: "you should go through it yourself");
  primary context ~42% at handoff.

## NEXT ACTION + PLAN
1. Alan plays: (a) Customize in either Hangar: click a card → crayon ring, "Trying it on", plane changes, numbers show
   green/red changes vs what's on; Select → it's on and the next card compares with it; Cancel / clicking the equipped
   card stops trying; (b) Training > Hangar Tour again: no Range flash, soft ding on the click, steps 7 and 10 now
   need Select (the spotlight moves to Select after a card is clicked). Fix his notes.
2. Then (queued, in order): Range first-visit sticky notes if still wanted; desk quick-menu concept (condensed, NOT
   cubbies); a desk Match Tip for refolding; swap fly-off/slide-in; Match Tips; Stage 11.
HOLDS (Alan's go, each): publish, Meshy, anything paid, desktop control, closing Studio, Save to File, real product
IDs/prices, turning sales on. Play runs: he OK'd mine for checking this work; ask again if he's playing.
Uploads allowed with an assembled preview first.

## DECISIONS & WHY (this session)
- Tour engine additions (Tutorial.luau) are generic but only switched on by a lesson's fields: `screen` (note over
  that menu, buttons found only there, walls so only the lit thing is clickable, note dodges the spotlight —
  bottom-right first, cork cover until the menu is open, no read pause), `ready`, `stay`, `ding`, `pages`, `linger`.
  Flight/Combat School behave as before.
- Steps watch `Hangar.tour.state` (page, slot, preset, mount, draft, trying), not clicks: most Hangar clicks redraw
  and destroy the button. Rename ticks on Enter (the save takes ~2 s).
- Red X page only when one exists: the Hangar's placeWeapon swaps gear around to fit, so an X is rare.
- Try-on/Select is Alan's design ([decision](../../docs/decisions/2026-10-21-hangar-try-on-select.md)); gear no longer
  comes off by clicking it on its spot — Clear spot does (in STATE "Decisions to review").
- End card in the Range has no buttons (the mouse aims there) and the player stays in the Range (`stay="range"`).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md; memories above; `docs/workshop/lessons.md` (+1 this session: MCP click coordinates, Play ignores Rojo edits).

## CARRY NOTES / GOTCHAS
- Studio MCP: x/y clicks are AbsolutePosition space; the rotated pencil is missed by `instance_path`.
- A running Play never picks up Rojo edits: stop/start Play. The MCP's execute_luau can't see client modules' state
  (separate require cache): read GUI instead.
- Range builds' renames don't persist between Studio Plays (Studio profile).
- Old carries: match bots' guns converge at 150 (Alan's call), vote-lap strip, cutscene hitch, Track C private
  publish, fan sound, live tutorial-room move untested, Hangar save messages in the Range still mention the desk.

## WHAT SHIPPED / OTHER QUEUED
- a37ef75f Hangar Tour built: 14 steps over the real Range Hangar, only the lit button clickable
- 91372f02 Hangar Tour fixes from Alan's play: stats explained row by row, weight/click/red-X pages, 3 different targets, note out of the way, name selects on click
- ff3f6488 Hangar numbers back with live changes; Hangar Tour: no Range flash, softer ding on the click
- 813401b7 Hangar: click a card to try it on, Select puts it on; numbers compare with what you have on
- + this handoff (decision, playtest, lesson, STATE).
- Queued: NEXT ACTION 2; VIP perks, cosmetics, special planes, prices (Alan's).

## KNOWLEDGE UPDATED
- systems/tutorial: Hangar Tour paragraph (engine fields, steps, fixes), Code table; systems/planes-and-hangar: numbers
  + try-on/Select; plan/TUTORIAL-PLAN: Lesson 3 built; decisions: new 2026-10-21-hangar-try-on-select (+README);
  playtests: new 2026-10-21-hangar-tour (+README); workshop/lessons +1; STATE rewritten (60 lines). Checker: OK (123 pages).

## POINTERS
- Engine `src/client/Tutorial.luau` (menuLayer, block, cover, placeNote, pages/linger); steps `TutorialLessons.luau`
  (`Lessons.hangar`); Hangar `Hangar.luau` (statSheet numbers, `Hangar.tour`, tryOn), `HangarCustomize.luau`
  (trying, Select/Cancel/Buy); server `RoundRuntime:practice` (`hangar` = Range builds); `ProfileSchema.LESSONS`.
