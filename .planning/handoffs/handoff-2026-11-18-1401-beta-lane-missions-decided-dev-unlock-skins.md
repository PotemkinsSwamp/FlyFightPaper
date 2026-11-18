# HANDOFF — 2026-11-18 — Daily and weekly missions decided (not built); dev "everything unlocked" now owns skins and trails

**Labels:** kind=product+docs · lane=beta-lane · branch=main · issues=none · areas=src/server/ProfileRuntime.luau, docs/decisions, docs/plan, docs/workshop, state, .planning/missions
**Time:** 2026-11-18 14:01 -05:00

★ START HERE: Goal (Alan 2026-11-18): build daily and weekly missions exactly as decided in `docs/decisions/2026-11-18-daily-and-weekly-missions.md`. Opening action: measure what an average player does per match for each mission action (folds, assists, boosts, zone points, …), because every mission count is built from those averages. Done (first step) when each action has a per-match average written down with where it came from. Nothing about missions is built yet.

> Read on demand: AGENTS.md → THIS → the missions decision. Codex's eight handoffs from 2026-11-18 (all `handoff-2026-11-18-beta-lane-*.md`) cover the chests, Hangar catalog and trails; only open one when a step touches it. Memories: plan-before-building-features, familiar-roblox-layouts, offer-pieces-catch-the-eye, visual-qa-before-showing, studio-play-grabs-mouse, alan-does-play-checks.

## STATE (verify before acting — state drifts between sessions)
- HEAD `584cf795` (main) before this handoff's commit, pushed (GitHub copy). Confirm: `git rev-parse --short HEAD`.
- Tests: none run by me. Codex's last: 719 passed in Play (`require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()` on the server). Docs: `python tools/check_docs.py` OK (205 pages).
- Studio: private Team Create save 820 (Codex). I did not open Studio. The dev-button change syncs through Rojo but is **not yet tried in Play**.
- Cost this session (Opus 5.5 part): one Sonnet reviewer 106,881 tokens; the picture made locally. Main session context at handoff ≈ 42%. (Fable part of this session, before the model switch: see the 2026-11-17 handoff.)

## NEXT ACTION + PLAN
1. **Per-match averages** for every mission action, as the base of all counts (Alan: "we need to think what might the average player accomplish"). Sources to weigh: the reference match in `docs/systems/economy-and-shop.md` (6 folds, 4 assists, ~430 Paper, 8.5 min), playtest notes, `tools/run_bot_matches.py` (bot matches need Alan's go; humans are not bots, so say how a bot number was adjusted). Speed boosts, zone points, folds inside the zone and folds in one life are **not counted yet**: they need counters in the match.
2. **Plan note to Alan with the actual numbers** before code (his rule): the average per action, the condition discount (named weapon/part lowers the count to avoid "forced choice burnout"), a few sample generated missions per tier, daily and weekly. One day of play = 3 matches.
3. **Build, after his OK.** Mission maker (shapes, tiers, picking, swap prices) as pure logic with unit tests: a good Codex job (Codex's lane rules in AGENTS.md). Then the match counters, saving (picks saved at day/week start; the old weekly "3 matches → Sticker" in `src/shared/ChestProgress.luau` becomes a daily mission — migrate saved progress safely), Claim and swap on the server, the Missions sheet (picture to Alan first; layout from `.planning/missions/weekly-tab-what-the-player-sees.jpg`), the report card's mission ticks, the mid-match "mission done" note.
4. Then Alan's Play look. Other beta queue: `state/STATE.md`.
- **HOLDS (Alan's explicit go, each):** any Studio Play (tests included), place saves, publish (he does it), desktop control or screen grabs, bot matches, any new mechanic or number not in the decision, every upload. Pictures: his OK on a preview first.
- **Stop rule for reviews:** one independent reviewer pass per preview; fix its "must fix" items once, then show him.

## DECISIONS & WHY (this session; all in the decision page in his words)
- Missions are game-made from shapes (action + optional condition + count), tiered so a list is never all hard; counts from average-player rates; a named-gear condition lowers the count.
- Daily: easy/medium/hard, 100+150 XP / 200+250 XP / 300+400 XP. Mode missions at most once a day, never the hard one. One free swap, then 150/300/450 Paper.
- Weekly: 2 / 3 / 4-5 days of play → 2,000 Paper / Sticker / Blue Ribbon, plus "all dailies on 5 days" → Blue Ribbon (not swappable). Weekly swap = 25% of the reward's Paper value, rising (×1, ×2, ×3).
- "Play 3 matches" is a daily mission now (Alan: 3 matches ≈ 24 min = a day's play), replacing the weekly Sticker one.
- Dev "everything unlocked" owns every skin and trail (Alan's ask); the level account gets its own looks back.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (Codex helps, model router, hard limits); design-theory skill before any screen; familiar-roblox-layouts; plain words, bad news first.

## CARRY NOTES / GOTCHAS
- **Alan wanted the plan explained in text, not a picture**, when he asked to "illustrate" it; I made a picture first. For plans, explain in words (a text mock-up is fine); pictures are for looks.
- The explanation picture's weekly cards are the first, too-easy draft; the layout is fine.
- Python on Windows writes `\r\n` in text mode: one source file came out with CRLF this session (fixed). Write files with `newline=''` or binary.
- The four rebuilt Legendary movement videos (my 2026-11-17 work): Codex recorded Alan's approval (`148685ae`) and installed the skins.

## WHAT SHIPPED / OTHER QUEUED
- `be78ef27` The dev everything-unlocked button now owns every skin and trail too
- `584cf795` Alan's daily and weekly missions plan: game-made from shapes, arduous weeklies, paid swaps
- Codex's commits since `7701a9d1` are listed in its own eight handoffs.
- Queued: NEXT ACTION 1 to 4; the rest of the beta queue in STATE.

## KNOWLEDGE UPDATED
- New `docs/decisions/2026-11-18-daily-and-weekly-missions.md` (listed in the decisions README). `docs/plan/IDEAS.md` points to it. `docs/workshop/testing.md`: the Studio account owns skins and trails. `state/STATE.md`: top line and next step (60 lines). Checker OK.
- Not yet changed: `docs/systems/economy-and-shop.md` still describes the weekly 3-match Sticker mission as live — correct when the missions are built (it is live until then).

## POINTERS
- Mission data available at match end: `src/server/RoundRuntime.luau` `queueSettlement` (row: present, victory, kills, deaths, activeSeconds, qualifyingEvents, finalPaper); weapon per hit in `src/server/CombatService.luau` damage history; speed pickups `src/server/FlightService.luau`.
- Existing weekly mission and its tests: `src/shared/ChestProgress.luau`, `tests/unit/ChestProgress.spec.luau`; shown in `src/client/HangarChests.luau`.
- Dev button: `src/server/ProfileRuntime.luau` `devAccount`, `src/client/DevTools.luau`.
