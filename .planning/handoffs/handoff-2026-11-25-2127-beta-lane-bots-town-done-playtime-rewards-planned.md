# HANDOFF — 2026-11-25 — Bots in the town done (Alan OK from video); playtime rewards planned and mostly approved; real prices only

**Labels:** kind=product+docs · lane=beta · branch=main · issues=none · areas=src/server/BotService.luau, src/shared/AirRoutes.luau, config/gameplay.json, src/client/ShopScreen.luau, tools/follow_bot.luau, docs/plan/BOTS-IN-TOWN-PLAN.md, docs/plan/PLAYTIME-REWARDS-PLAN.md, docs/decisions, docs/playtests, docs/systems, docs/workshop, state/STATE.md
**Time:** 2026-11-25 21:27 -05:00

★ START HERE: Goal: a daily **playtime sticker chart** (16 boxes over 4 hours of match time, a treasure chest at 4 hours) that rewards long play without Robux, per `docs/plan/PLAYTIME-REWARDS-PLAN.md`. Everything is approved except **what the 4-hour treasure chest is**. Opening action: draft Alan's two chest ideas, (a) pick one of a few equal prizes, (b) a spin wheel of good prizes with a small chance of a great one, each with real prizes, odds and their worth in Paper and Robux (no fake prices), and get his pick. Done when he picks; then build the chart (rules + tests, server, then 2-3 look options for his pick).

> Read on demand: AGENTS.md → this file → `docs/plan/PLAYTIME-REWARDS-PLAN.md` (rules, approved table, research, open chest) and `docs/decisions/2026-11-25-real-prices-only.md`. For the build: `src/shared/CommerceRules.luau` (`dailyGiftDay`, `dailyGiftReward`), `src/shared/ProfileSchema.luau` (`dailyGift`), `config/economy.json` (`daily_gift`), `config/looks.json` (chests), `docs/systems/economy-and-shop.md`. Memories: plan-before-building-features, prices-need-other-games-first, offer-pieces-catch-the-eye, load-first-reuse-art, design-theory skill before any screen.

## STATE (verify before acting)
- HEAD `77265d169` on `main` before this handoff's commit; the commit hook pushes. Confirm: `git rev-parse --short HEAD`, `git status --short | grep -v '^??'` (empty).
- Tests: **782/782 pass** (run in Play on the server after all of this session's code: `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`). Docs: `python tools/check_docs.py` OK (267 pages).
- Studio "FlyFightPaper(First Fold)" (`6c3f0268-...`) in Edit, Rojo serving, DevMute and DevBotTier cleared. Place not saved; nothing in it needs saving (all work is code via Rojo).
- Cost: 2 agents: a web-fetch read (~20k tokens) and a Sonnet research run (~132k tokens); no Codex jobs, no generator calls, no uploads. About 6 bots-only matches (3 aces, 1 regulars, 1 rookies, 1 one-minute) plus 4 recording Plays and 1 test Play; ~2.5 h wall clock. Primary context ~45% at handoff.

## NEXT ACTION + PLAN
1. Treasure chest drafts (a) and (b) for Alan's pick. Prices or values shown must be real; show what comparable games give (memory prices-need-other-games-first). A free earned wheel needs no odds by Roblox's rules, but show them like our chests; a wheel ever sold for Robux must show every prize and exact odds first.
2. The chart's rules as pure logic with unit tests (boxes earned for N seconds, new UTC day on first join, one take per box, lost at day end): a Codex job (Sol, AGENTS.md router). Read its diff, re-run the tests.
3. Server: count match seconds only (flying or at the desk in a match; 2 minutes of no input pauses), save with the profile, take a box, give prizes through the daily gift's code. Prize amounts in config (`economy.json` beside `daily_gift`).
4. Look: Playtime strip on the main menu + the sticker chart page + in-match "Sticker earned!" note; 2-3 options from loaded art, in the scene, design-theory checklist, his pick before any upload.
5. Play check, tests, docs.
- HOLDS (his explicit go, each): every upload, place saves, publish (he does it), generator calls other than Codex pictures (price first), any new mechanic or number beyond the approved chart. Studio Play while he works: menus and tests only unless he OKs (memories alan-does-play-checks, studio-play-grabs-mouse).

## DECISIONS & WHY (this session)
- **Bots in the town closed**: steps 5-6 built; low 24% (22-27%), town crashes 1.3 a match (rams not counted), botMs same; Alan watched the before/after video, "alright looks good", "i dont need to play lets move on". Numbers: `docs/plan/BOTS-IN-TOWN-PLAN.md` "After steps 5 and 6".
- **Street runs take only holes under 200 studs, never above the bot** (`7bc56d306`): filming showed a run climbing to a ceiling ring. The 3-match re-measure after this fix was stopped by the user/app mid-match 2 (no numbers); not re-run. Low priority: the fix only removes climbs.
- **Fake "was" prices declined** (Alan asked for a made-up price slashed to "75% off"): against US/EU/UK pricing law and Roblox's own discount guidance, and regulators are looking at kids' Roblox games in 2026. Alan agreed to real ones: "yes use the real prices". The starter pack now adds up its real total (218 R$) instead of a stale hand-typed 272 (`2c8031668`). Decision: `docs/decisions/2026-11-25-real-prices-only.md`.
- **Economy principle (Alan)**: long play earns everything without Robux; short-session, impatient players get honest ways to pay (unlock now, boosts, double this match, a chest now).
- **Playtime chart (Alan's calls)**: chest at 4 hours (he first said 4-5; I recommended 4: few reach either, Roblox stopped paying for long sittings, long day for a kid); "Bigger" prizes (small boxes 100/150/200/250 Paper + 5 min 2x XP each hour; hour boxes 15 min 2x Paper, 400 Paper, 30 min 2x XP, chest); match time only. Research behind it (Creator Rewards pays only for spenders; discovery weighs days played over 28 days; median player ~17 min a day): in the plan.
- **Not Roblox's Engagement Rewards package**: it resets on leave, has its own plain screen, no idle handling; the daily gift's code already saves, does UTC days and chest/boost prizes.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (router: Codex Sol only, read every diff; one writer per file; commit and push small). Memories listed above. Real prices only (decision above).

## CARRY NOTES / GOTCHAS
- Re-measure the low-hole fix when Studio is free: `python tools/run_bot_matches.py 3` in the background (~25 min); compare with the plan's after-table. Never edit `src/` while it runs.
- `git checkout -- <file>` failed "unable to unlink" on Rojo-served files; use `git show HEAD:<file> > <file>` (lesson added).
- The match tool's console includes earlier Plays' errors: a `BotService` line 225 `fill` assert stack appeared once and was not found in the next Play's log; watch for it.
- Bot videos: `tools/follow_bot.luau` + `video_capture` (30 s cap); keep the screen awake with `tools/keep_screen_awake.ps1` (8 min, restart it).
- Monorail pylons are still the most-hit town part (later, if Alan wants).

## WHAT SHIPPED / OTHER QUEUED
- `1718a585d` steps 5-6 (street runs, low cruising, low search; his skill numbers) · `7bc56d306` runs take only low holes
- `b6de3c545` playtime plan first draft · `9d40946cb` bots done + plan takes his changes · `c59038c87` research and 4-hour proposal
- `2c8031668` starter pack's real crossed-out price; real-prices decision · `77265d169` his calls (bigger, match time, 4 h)
- plus the commit with this file (lessons, `tools/follow_bot.luau`, tools page, LATEST).
- Queued (IDEAS): look back key, tricks in flight, skill bonuses, own report card, nicer part models, bots grab boosts, timed obstacles; leftovers: monorail pylons, Dragon leftovers, Shark fin through walls, Toilet Roll shake (his go). STATE "Waiting on Alan" has the Play looks.

## KNOWLEDGE UPDATED
- `docs/plan/BOTS-IN-TOWN-PLAN.md`: after-table for steps 5-6, the low-hole fix, Where it stands (done). `docs/systems/bots.md`: In the town; tuning line. `docs/decisions/2026-11-25-bots-use-the-town.md`: built.
- `docs/plan/PLAYTIME-REWARDS-PLAN.md` (new; HOME and IDEAS link it). `docs/decisions/2026-11-25-real-prices-only.md` (new) + README. `docs/systems/economy-and-shop.md`: starter pack's real crossed-out price.
- `docs/playtests/2026-11-25-bots-in-the-town-video.md` (new) + README. `docs/workshop/lessons.md`: 3 lessons (film a bot before trusting numbers; mode length from samples; git unlink). `docs/workshop/tools.md`: `tools/follow_bot.luau`. `state/STATE.md` top line, decisions to review, waiting on Alan. Checker OK (267 pages).

## POINTERS
- `docs/plan/PLAYTIME-REWARDS-PLAN.md`, `docs/decisions/2026-11-25-real-prices-only.md`, `docs/systems/economy-and-shop.md` (chests, daily gift, prices), `src/client/ShopScreen.luau` (`PRICE`, starter card), `config/looks.json` (chest odds and prices).
- Video for Alan: `.planning/bots-town-before-after.mp4` (not in git).
