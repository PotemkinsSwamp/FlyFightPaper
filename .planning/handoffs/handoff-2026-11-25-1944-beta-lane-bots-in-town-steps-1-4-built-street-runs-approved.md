# HANDOFF — 2026-11-25 — Bots in the town: steps 1-4 built and measured; Alan "didn't notice much"; street runs and lower fights approved (steps 5-6, not built)

**Labels:** kind=product · lane=beta · branch=main · issues=none · areas=src/shared/AirRoutes.luau, src/shared/AirMapRules.luau, src/server/BotService.luau, src/server/FlightService.luau, src/client/FlightHUD.luau, config/gameplay.json, tools/run_bot_matches.py, tests/unit, docs/plan/BOTS-IN-TOWN-PLAN.md, docs/decisions, docs/playtests, state/STATE.md
**Time:** 2026-11-25 19:44 -05:00

★ START HERE: Goal: bots that visibly use the town. Alan played steps 1-4 and "didn't notice much of change". Opening action: build steps 5 and 6 of `docs/plan/BOTS-IN-TOWN-PLAN.md` with his new numbers. Step 5, street runs: the dive becomes a 10-15 s run along the low routes away from the attacker, through a hole within about 400 studs ahead, then back up. Chances 80/70/50/30% (Ace/Veteran/Regular/Rookie); follow through a hole 90/70/45/20%. Step 6, fights low more often: cruising picks low points 70% of the time, and a bot that loses its target low searches at that height. Done when bots-only matches show low about 25-30% (8-11% now), town crashes (rams not counted) no worse than about 1.5 a match, and the same server time. Then Alan's look with a short before/after video.

> Read on demand: AGENTS.md → this file → `docs/plan/BOTS-IN-TOWN-PLAN.md` (steps 5-6, every after-table) and `docs/decisions/2026-11-25-bots-use-the-town.md` (his words, new table). Code: `src/server/BotService.luau` (`decide`: shot-at block, hide/hole branches, routing; `steer`), `src/shared/AirRoutes.luau` (`buildTown`, `findHoles`, `hideSpot`, `holeAt`, `pick`). Memories: plan-before-building-features, alan-does-play-checks, send-videos-not-gifs, bots-are-the-balance-test.

## STATE (verify before acting)
- HEAD: the commit adding this file on `main`, after `113673299`; the commit hook pushes. Confirm: `git rev-parse --short HEAD`, `git status --short | grep -v '^??'` (empty).
- Tests: 782/782 pass (Play server: `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`), run after step 3. Steps 4 and later not re-run: re-run to confirm. Docs: `python tools/check_docs.py` OK (264 pages).
- Studio "FlyFightPaper(First Fold)" (id `6c3f0268-...`) in Edit, Rojo serving. **Place not saved**; nothing in it needs saving: all of this session's work is code via Rojo. DevMute is cleared by the match tool.
- Cost: 2 Codex jobs (gpt-6.2-sol confirmed in `~/.codex/sessions/2026/11/25/`; on Alan's ChatGPT plan; AirMapRules + tests, then the leg-cost parameter); no other agents. About 25 bots-only matches in the background, ~3.5 h of Studio. Several short Play runs. Context ~48% at handoff.

## NEXT ACTION + PLAN
1. Step 5 (street runs) and step 6 (fights low), with the numbers in the decision. Config: `bots.profiles[*].town_dive_chance` → .8/.7/.5/.3 and `hole_follow_chance` → .9/.7/.45/.2; update `bots.town_comment`. Then `python tools/run_bot_matches.py 3` in the background (about 25 min), plus a short regulars and rookies match (`1 462 regular`, `1 462 rookie`). Read the CRASHES line (RAM or the part hit) and record an after-table in the plan.
2. A before/after video for Alan of a bot running from a chaser through the streets (MP4 via ffmpeg, never GIF). Then his look: restart Play, Dev panel **ace bots**.
3. Later, if he wants it: the monorail pillars and beam, the parts of the town hit most.
- HOLDS (his explicit go, each): every upload, place saves, publish (he does it), generator calls other than Codex pictures (price first), any new mechanic or number beyond steps 5-6. **Already given:** bot matches and Claude's own Play runs for this work, the numbers of steps 1-6.

## DECISIONS & WHY (this session)
- **Most bot-match "crashes" are rams** (20 of 27 in five diagnostic matches): collisionDeaths counts rams, and the rammer quirk flies into hurt planes on purpose. That is by design and was counted in the "before" table too. Real town crashes are about 1.3 a match for aces and veterans; rookies only hit the town. Skill, personality and habits showed no wall-crash pattern; the plane and personality differences followed who got rammed.
- **Low layers at 60/95, 70 apart; floor push over the town 45** (lamps top out at 37.5, trees at 42, measured). Holes are found at server start by rays across each building group (`AirMapRules.holes` on the hit grid; 20 holes; ~5 s, 3 ms a frame).
- **Crash fixes, all mine:** dives get shallower near the floor (step 3 crashed at 22 studs); circling within 150 studs of the goal is not "stuck" (step 3 had 633 s unstuck); the cruising wobble never aims under the floor; route checks are capped at 12 a plan (55 ms frame spikes).
- **My calls, his to reverse** (STATE "Decisions to review"): the low heights, floor 45, stuck climb 160, shallow dives. His dive words were first read as 75/50/20/0%; his new numbers (80/70/50/30) replace that.
- **Match tests:** the "outside the zone" point moved to a room corner. The town zones now reach the floor (last session), so the old point (0,0,0) sat inside the Centre zone.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (model router: Codex is Sol only, never `--model`; read every Codex diff; one writer per file; push after commit). Memories above. `docs/workshop/lessons.md` "Scripted Play tests": prove a match-tool change with a one-minute match; crashes include rams.

## CARRY NOTES / GOTCHAS
- Never edit `src/` while bot matches run: Rojo syncs, and the next Play in the run picks up the half-done code.
- Python patch scripts go through the Write tool. A `\\n` in a bash heredoc became a real line break inside Luau and cost three matches with no report.
- `run_bot_matches.py` prints `botMs each second` (average and peak) and `CRASHES` (bot, [skill style, plane], mode, x,y,z, Lift, "hit <part>" or "hit RAM"). `python tools/run_bot_matches.py 1 60` checks a tool change in 2 minutes.
- Crash counts swing from 1 to 10 a match; compare totals over 3 or more matches.
- I couldn't find the Dev picker (MixedBots or AceBots) in PlayerGui from a script; the server action works. If Alan can't find the **ace bots** button, look at where the picker lives.
- Bots spend only ~8% of flying time cruising; chasing (~28%) and dodging decide where fights happen.

## WHAT SHIPPED / OTHER QUEUED
- `3282fbc73` match tests: the outside-the-zone point moved · `e2d2cae35` step 1 town map, heap search, floor 45 · `036c795d5` match tool: personality, botMs each second
- `d07cbd892` step 2 stuck/brake/look-ahead, capped checks, crash log · `1bd10a009` step 3 dive/hole follow/Airspace height · `e8f4c9f45` step 4 route habits, shallow dives, stuck fix
- `43d7db6bd` plan numbers · `4311fe166` Dev button "ace bots"; crash part and Lift · `87cdb0431` STATE · `040a74ef1` rams vs walls in the crash log
- `2ee3a41e8` step 4 numbers, rams finding · `faeb7ab63` lesson · `0b91cea82` Alan's first look + look-back idea · `113673299` steps 5-6 approved
- plus the commit with this file.
- Queued: steps 5-6 (approved), the look-back key (backlog, IDEAS), the bots' fixed cast look and the rest of STATE's "Waiting on Alan".

## KNOWLEDGE UPDATED
- `docs/plan/BOTS-IN-TOWN-PLAN.md`: after-tables for steps 1-4, the crash diagnosis, steps 5-6 added, Where it stands.
- `docs/decisions/2026-11-25-bots-use-the-town.md`: his evening change and the new skill table. `docs/playtests/2026-11-25-bots-in-the-town-first-look.md` (new) + README line.
- `docs/systems/bots.md`: Where it stands (town), Code table (`AirMapRules.luau` + test), tuning (`world.town_routes`). `docs/plan/IDEAS.md`: Look back. `docs/workshop/lessons.md`: two lessons (match-tool check, rams). `state/STATE.md`: top line, Decisions to review, Waiting on Alan. Checker OK (264 pages).

## POINTERS
- `docs/plan/BOTS-IN-TOWN-PLAN.md`, `docs/decisions/2026-11-25-bots-use-the-town.md`, `docs/systems/bots.md`, `tools/run_bot_matches.py`, `tests/unit/AirMapRules.spec.luau`.
