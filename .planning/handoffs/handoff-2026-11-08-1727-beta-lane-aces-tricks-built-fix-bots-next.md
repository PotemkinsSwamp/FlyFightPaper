# HANDOFF — 2026-11-08 — text style C picked; Aces, bot tricks and switching built and measured; fix the bots next

**Labels:** kind=product · lane=beta-lane · branch=main · issues= · areas=src/server/BotService.luau, src/shared/BotTactics.luau, src/shared/BotBuilds.luau, src/shared/BotRosterRules.luau, src/server/CombatService.luau, src/server/RoundRuntime.luau, config/gameplay.json, tests/unit, docs
**Time:** 2026-11-08 17:27 -05:00

★ START HERE: Goal (Alan): the beta feels like a finished game, one map, a strong first-session hook. Next: fix the bots
so a bots-only match is a believable stand-in for real players' XP and Paper a match: make the Crayon Tank turn-fight
(drop its stand-off; rebuild its weapons only if still weak), and find why Aces don't beat veterans on the same build.
Done when a re-measure (Alan's go) shows the Crayon Tank in the range of the other builds and Aces clearly above
veterans, with no script errors.

> Read on demand: AGENTS.md → this file; docs/systems/bots.md (current bot rules); docs/playtests/2026-11-08-ace-bot-matches.md
> (numbers by build); docs/decisions/2026-11-08-unlock-ladder-and-bot-builds.md (Alan's calls, newest at "After the Ace
> matches"); docs/workshop/lessons.md "Attack a bot change before any match". Memories: attack-own-work-first,
> hand-made-not-generic-roblox, mute-studio-tests, studio-play-grabs-mouse, plan-before-building-features.

## STATE (verify before acting)
- HEAD `f9a4a599` on `main`. `main` has no upstream: the commit hook copies each commit to GitHub ("github: pushed").
  Confirm: `git log --oneline -3`.
- Tests: 476 passed, 0 failed in Play (2026-11-08, after the fixes). Re-run: DevMute on in Edit → Play → Server: spawn
  `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`, write the result to a workspace attribute, read
  it in a second call.
- Studio: Edit mode, DevMute and DevBotTier cleared. **Rojo's Studio plugin is disconnected** (server still runs, port
  34872): Alan clicks Connect, or ask before desktop control. Studio MCP tools dropped when the session restarted;
  `python tools/studio_cli.py TOOL '{json}'` drives Studio directly (worked all evening). New weapon models still not
  Saved to File or published (Alan's go). Published = v495.
- Docs: `python tools/check_docs.py` OK (157 pages).
- Cost this session: Opus main (~45% context at handoff); 2 Haiku match runners (3 matches each, ~128k and ~121k tokens,
  ~26 min each). The first runner's Ace numbers were wasted by my bugs. No Codex, no uploads, nothing paid.

## NEXT ACTION + PLAN
1. Fix the bots (Alan's order, 2026-11-08):
   - Crayon Tank turn-fights like the best builds (Tack Skirmisher ~12 folds a match). Only if still weak: rebuild its
     weapons (its Rubber Bands scatter at range: 6-9% hits).
   - Find why Aces (turn 1.0, aim 0.3-0.7°, reaction 0.15-0.25 s, pursuit 6-12 s) don't beat veterans on the same build
     and die as often. Measure per build before changing numbers. Spitball Hunter is weak too (~5 folds).
   - Check: 476+ tests, a one-minute muted bot match (per-bot hit rates, errors, `liveShots`/`peakShots`/`refusedShots`
     in MatchStatus), then measuring matches with `DevBotTier=ace_mix` (Alan's go) giving XP and Paper a match.
2. Roll text style C out to every menu and the HUD (recipe in docs/decisions/2026-11-08-text-style-crayon.md).
3. The unlock moment (concept fixes, then build; assembled preview + Alan's OK before any upload).
   Prices and levels are set from step 1's numbers, for Alan's OK.
- Before any match: attack the change first (what could misfire, what a real player would do). Stop rule: one
  one-minute check per change; full matches only once that check is clean.
- HOLDS (Alan's explicit go each): publish (he does it), Save to File, any upload, desktop control, Studio Play while he's
  playing, a bot match, anything paid.

## DECISIONS & WHY (this session)
- Text style C: today's Kalam made heavier + cream outline + soft shadow. Alan: it should look like a child wrote it with a
  crayon; the clearer rounded font "looks like every other Roblox game".
- Bots shoot whenever the targeting ring would show (1,000 studs), no gun-range rule (Alan: players don't know ranges,
  far planes are easier to hit). Each gun aims at its own lead: before today a bot's second gun used the first gun's lead.
- Aces are Studio-only (`ace` / `ace_mix`); roster mixes never plan them. Real lobbies decide in plan step 6.
- Stealing is judged once per target (per notice it made even good bots hop every few seconds); only damaged planes
  within 500 studs. Spitball-first gives up after 3 s. The Popper Dart got an Elastic Booster for its dart.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (model router, docs rules, hard limits); memories above; lessons.md bot entries.

## CARRY NOTES / GOTCHAS
- Studio-only error on Play stop with DevBotTier set: `existing_rookie_roster_has_experienced_bot` (BotService fill on
  PlayerRemoving). Harmless; fix if a measuring run ever needs a player to join mid-match.
- Unverified: bots' guns converge at the fixed `gun_convergence_studs`, not the target's range (players use their aim
  range); may cost hits at long range.
- `execute_luau` runs in its own module environment: `require` of a service gives a fresh copy, not the running one; read
  live numbers through `ServerStorage.MatchStatus` (now also `liveShots`, `peakShots`, `refusedShots`).
- RoundRuntime can't be required in Edit (RewardQueue's BindToClose); not a bug.

## WHAT SHIPPED / OTHER QUEUED
- Shipped: 01d6dba8 text style C picked · a809349a Aces, bot tricks, kill-stealing, smart switching · ebfa5844 one Ace
  per three veterans · 182c10ec per-gun leads, ring-range firing, Crayon peel-off, Aces spread over builds · fa2f0938
  Ace match results + lesson · f9a4a599 Alan's calls after the Ace matches · (this handoff's commit).
- Queued: Save to File + publish (Alan's go); CLASSES-PLAN steps 5-7; winners' circle, skins, shop.

## KNOWLEDGE UPDATED
- decisions: new 2026-11-08-text-style-crayon (+README); unlock-ladder-and-bot-builds (status + "After the Ace matches").
  playtests: new 2026-11-08-ace-bot-matches (+README). systems/bots.md: tiers, tricks, brake, stealing, firing, code table
  (BotTactics). lessons.md: "Attack a bot change before any match". STATE.md rewritten. Memories: attack-own-work-first,
  hand-made-not-generic-roblox. Checker: OK.

## POINTERS
- Bot brain: src/server/BotService.luau (`trickStep`, steal scan in `decide`, `steer` brake/boost/fire, `lead`/`leadWith`,
  `fill` DevBotTier). Rules: src/shared/BotTactics.luau (+ tests/unit/BotTactics.spec.luau). Skill numbers:
  config/gameplay.json `bots.profiles`, `bots.tricks_comment`.
- Text test picture: .planning/text-style-test.jpg. Unlock concept: .planning/unlock-concept2/.
