# HANDOFF — 2026-11-08 — bots fixed and measured; build the weapon sizes, bot test, then prices and unlocks

**Labels:** kind=product · lane=beta-lane · branch=main · issues= · areas=src/server/BotService.luau, src/server/CombatService.luau, src/shared/BotBuilds.luau, src/shared/BotTactics.luau, src/client/CombatEffects.luau, config/catalog.json, config/gameplay.json, tools/run_bot_matches.py, tests/unit, docs
**Time:** 2026-11-08 21:44 -05:00

★ START HERE: Goal (Alan): the beta feels like a finished game, one map, a strong first-session hook. Next: build the
weapon sizes Alan set (Staple Burst Gun medium class weighing 2, Stubby Crayon heavy, Spitball Straw weighs 1; Striker
preset keeps one Staple plus a light weapon; re-make the bot builds that break), showing Alan the new bot builds as a
short "how it works + numbers" note BEFORE coding them. Done when tests pass and a bot test (Alan's go) with the new
Spitball numbers shows no errors and no plane far off the rest except what's queued for the balance pass. Then prices.

> Read on demand: AGENTS.md → this file; docs/decisions/2026-11-08-unlock-ladder-and-bot-builds.md (Alan's calls,
> newest from "The Crayon Tank was a bad build" down); docs/playtests/2026-11-08-bot-fixes-staple-matches.md (numbers);
> docs/systems/bots.md, weapons.md; docs/systems/economy-and-shop.md + docs/research/PRICING-RESEARCH-2026-10-18.md for
> step 2. Memories: plan-before-building-features (updated tonight), bots-are-the-balance-test (new),
> attack-own-work-first, mute-studio-tests.

## STATE (verify before acting)
- HEAD = this handoff's commit on `main` (after `d7a9e822`); `main` has no upstream: the commit hook copies each commit
  to GitHub ("github: pushed"). Confirm: `git log --oneline -3`.
- Tests: 476 passed, 0 failed in Play (2026-11-08 21:3x, with the Spitball at 3 + soak 1). Re-run: DevMute on (Edit) →
  Play → Server: `task.spawn` the `FlyFightPaperTests.unit.TestRunner.run()` and write the result + `failures` to a
  workspace attribute, read it in a short call (long Server calls drop their replies; see lessons.md).
- Studio: Edit mode, DevMute/DevBotTier cleared, Rojo connected and syncing (port 34872). Studio MCP tools work for
  Edit and start/stop; for Server calls use `python tools/studio_cli.py` (short calls). Published = v495; nothing
  saved to file or published tonight.
- Docs: `python tools/check_docs.py` OK (158 pages).
- Cost this session: Opus main only, ~46% context at handoff, ~4h15 wall clock. No subagents, no Codex, nothing paid.
  13 bot matches (6 one-minute checks, 7 full) by script: near-zero tokens.

## NEXT ACTION + PLAN
1. Weapon sizes (Alan, decided): Staple medium/2, Crayon heavy, Spitball 1. Breaks: Striker preset (slim, 2 Staples
   → 1 Staple + a light weapon), Popper Dart bot (Popper + 1 Staple, Alan accepted), Tack Skirmisher bot (only 2
   medium/heavy slots for 4 medium guns), Staple Tank bot (4 Staples max). Spitball at 1 frees room on spitball builds.
   Show Alan the re-made bot builds first (stats on paper: speed, turn, health, damage a second). Tests + docs.
2. Bot test (Alan's go): `python tools/run_bot_matches.py 1 75` (one-minute check), then full matches
   (`python tools/run_bot_matches.py [count]`, background). Alan asked for "a test", not necessarily three.
3. Prices and unlocks (Alan's OK): from his table (6 folds weak, 12 average, 25 really good; ~131 points a fold;
   Paper 0.363 x points + 90, XP 0.68 x points + 120 before win/podium), balancing fun against grind so impatient
   players buy 2x XP / 2x Paper / Paper.
4. Text style C everywhere (recipe: docs/decisions/2026-11-08-text-style-crayon.md). 5. The unlock moment.
- Balance pass (later, Alan): Staple Tank still strongest (six Staples at range; weapon sizes may fix it), Spitball
  planes weakest, Rubber Band light but weighs 2. Idea: gentle damage loss with distance for every weapon (whole-number
  damage makes small hits jump; solve first).
- Stop rule: one one-minute check per change; full matches only once it's clean.
- HOLDS (Alan's explicit go, each): publish (he does it), Save to File, any upload, desktop control, Studio Play while
  he's playing, a bot match, anything paid. Any new mechanic or number players feel: his OK on a how-it-works note first.

## DECISIONS & WHY (this session)
- Bots' guns meet at the lead point's distance (were fixed at 150 studs: wing guns missed past it; players got this fix
  2026-10-19). This is what made Aces' better aim count.
- Crayon Tank → Staple Tank: Rubber Bands need a plane that gets close; a slow tank can't (Alan).
- Bots are the balance test (Alan): a strong reasonable build means fix weapons/capacity, never weaken the bot build.
- Staple: bursts 1.05 s apart (13.3 a second, a Pellet's), ~800 studs (kept just past the Pellet's 750: range order rule).
- Ducts are for players: bots only follow a target up a vent (veteran 60%, Ace 90%); one Ace had lived there 35-40%.
- Spitball soak: 3 on impact, each stuck spitball 1 a second (max 5), shooter's credit, scraps but no hit marker;
  bots with 2+ stuck fly to a fan. One launcher hitting = 11 a second, two = 17, fully soaked +60 without a fan.
- BotBuilds' paper time-to-kill check skips spitball builds (it can't see slowing; matches judge them).
- Results card → report card: backlog, must do (Alan).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (model router now says bot matches by script, not the Haiku helper); memories above; lessons.md bot entries.

## CARRY NOTES / GOTCHAS
- `execute_luau` in the Edit VM caches `require`d modules: measuring after an edit can read the old module (tonight's
  build stats showed the Crayon Tank); restart Studio's MCP or read Source to be sure.
- Roblox's own `ChatScript` SetCore error appears in some match logs: not ours.
- Spitball soak not yet flown at 3 + 1; the soak has no unit test (the match check exercises it).
- Unchanged: `existing_rookie_roster_has_experienced_bot` error on Play stop with DevBotTier set (harmless).

## WHAT SHIPPED / OTHER QUEUED
- ef713dee Crayon turn-fights; bot guns meet at the target's distance · c5760c26 Staple Tank · 64b6e14d bots are the
  balance test · 9be1fb10 Staple slowed, ~800 studs · a8e18681 Spitball builds; duct trips · fd27b067 short duct runs
  only · dfaffd03 tools/run_bot_matches.py + lesson · 4faa50a2 rules: matches by script · b35a7808 match results ·
  0e1421d8 spitball soak; bots only follow into ducts · 6fd72ff0 Spitball 3 + soak 1 · d7a9e822 weapon sizes, report
  card · (this handoff's commit).
- Queued: Save to File + publish (Alan's go); report card; CLASSES-PLAN steps 5-7; winners' circle, skins, shop.

## KNOWLEDGE UPDATED
- systems/bots.md (builds, ducts, firing, convergence), weapons.md (Staple row, convergence, soak); decisions note
  (8 new calls); playtests: new 2026-11-08-bot-fixes-staple-matches (+README); workshop: tools.md, testing.md,
  lessons.md (long Server calls); AGENTS.md router line; STATE.md rewritten. Memories: bots-are-the-balance-test (new),
  plan-before-building-features (third correction). Checker: OK.

## POINTERS
- src/server/BotService.luau (`followDuct`, `trickStep`, `steer` firing/convergence), src/server/CombatService.luau
  (`soak`, `hit` soak flag, `launch` convergence), src/shared/BotBuilds.luau, src/shared/Catalog.luau (`COMPATIBLE`),
  config/catalog.json (weapons, classes), tools/run_bot_matches.py.
