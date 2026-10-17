# HANDOFF — 2026-10-17 — Published; next: "Clear weapon spot" + click-again, rotating event lines game-wide

**Labels:** kind=ui · lane=ui · branch=main · issues= · areas=src/client/Hangar.luau, src/server/FlightService.luau, docs/decisions, docs/playtests/2026-10-17.md

★ START HERE: Goal: Alan's evening notes, then his Stage 9 sign-off. First: on the hangar's weapons tab, clicking the
weapon already on the picked mount clears it, and the "Clear mount N" button stays but reads "Clear weapon spot"
(young players). Then make every event message rotate through short, on-theme lines, with waits described, not
counted ([decision](../../docs/decisions/2026-10-17-fresh-rotating-lines.md)), starting with the death line. Done
when both are checked in Studio Play and Alan has seen the lines.

> Read on demand: AGENTS.md → THIS; docs/decisions/2026-10-17-fresh-rotating-lines.md; docs/playtests/2026-10-17.md
> notes 8-11. Memories: studio-play-is-shared.

## STATE (verify before acting)
- HEAD: this handoff's commit on main, auto-pushed. Confirm: `git rev-parse --short HEAD`.
- **Live:** Alan re-published 2026-10-17 evening: menu art and the desk hangar flow are live.
- Tests 321/0 in Play, server: `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- Studio: "FlyFightPaper(First Fold) (placeId: 132768925825316)", Rojo serving current code.

## NEXT ACTION + PLAN
1. Weapons tab: click-again clears; button renamed "Clear weapon spot" (src/client/Hangar.luau, weapon cards and
   ClearMount). Check in Play.
2. Rotating lines, game-wide (Alan's decision): find every message that describes an event (plane down, refolding,
   landing, service results, folds, round events; e.g. `destroy` in src/server/FlightService.luau, DeskService
   messages, ScorePopups) and give each a small set of short, kid-friendly paper lines picked at random; waits say
   what is happening ("being refolded"), no seconds. Alan gave the idea, not the words: write them, show him the
   list before calling it done. One shared place for the line sets beats lines scattered per file.
3. Then the discussion (note 11): rounds that roll straight into the next while everyone keeps flying, versus a
   pause for results, XP and the next unlock. Research, recommend, Alan decides; nothing built before that.
4. Then his Stage 9 playtest (state/STATE.md list).
HOLDS (Alan's go each): uploads, publish, Studio-settings changes, Meshy, anything paid, desktop control, closing
Studio. Don't steer his plane while he's in Play.

## DECISIONS & WHY (this session)
- Keep the clear button (kids who miss click-again still have it), plainer words: "Clear weapon spot".
- Fresh rotating lines apply to all event wording, not just deaths (Alan: keeps the game fresh; other games do it).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md; in-game-menus-match-main-menus; studio-play-is-shared.

## CARRY NOTES / GOTCHAS
- Carries from handoff-2026-10-17-ui-desk-hangar-flow.md still apply (unsaved draft kept, protection timer while
  editing, no unit test for the free same-build refold).
- Server messages are attributes ("Message", "MenuMessage"); tests may match exact strings: run the suite after
  changing any wording.

## WHAT SHIPPED / OTHER QUEUED
- 1cc08004 Handoff: Alan's notes: click-to-clear weapons, fresh death lines, then never-ending rounds talk
- this handoff (decision fresh-rotating-lines, playtest notes 9-10 updated, STATE: published)

## KNOWLEDGE UPDATED
- docs/decisions/2026-10-17-fresh-rotating-lines.md (new) + README line; docs/playtests/2026-10-17.md notes 9-10;
  state/STATE.md (published, next). Checker: OK.

## POINTERS
- src/client/Hangar.luau, src/server/FlightService.luau, src/server/DeskService.luau, src/client/ScorePopups.luau,
  src/server/RoundRuntime.luau (round phases, for note 11).
