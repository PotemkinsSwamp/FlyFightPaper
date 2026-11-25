# HANDOFF — 2026-11-25 — Emotes closed and zones reach the floor (both OK'd by Alan); bots in the town: plan approved, before numbers in, nothing built

**Labels:** kind=product · lane=beta · branch=main · issues=none · areas=src/client/WinnersCutscene.luau, src/client/ControlZone.luau, config/gameplay.json, tools/run_bot_matches.py, docs/plan/BOTS-IN-TOWN-PLAN.md, docs/decisions, docs/playtests, docs/workshop, state/STATE.md
**Time:** 2026-11-25 04:13 -05:00

★ START HERE: Goal: bots that feel smarter by using the town, the way a player does: they fly down the streets and between the towers, take the holes (tubes, arches, under bridges, rings), hide and follow by skill, and stop crashing or getting stuck. Opening action: step 1 of `docs/plan/BOTS-IN-TOWN-PLAN.md`, a map of the town's open air (low points over the town mat plus points at every hole a plane fits through) with faster route search. Done when bots-only matches show bots spending real time low over the town with crashes about as rare as the before numbers (in the plan), and the bots' server time staying about where it is.

> Read on demand: AGENTS.md → this file → `docs/plan/BOTS-IN-TOWN-PLAN.md` (steps, before table) and `docs/decisions/2026-11-25-bots-use-the-town.md` (his words, skill table). Code: `src/server/BotService.luau` (`steer`, `decide`), `src/shared/AirRoutes.luau`. Memories: ask-what-his-problem-is, plan-before-building-features, bots-are-the-balance-test, alan-does-play-checks, studio-play-grabs-mouse.

## STATE (verify before acting)
- HEAD: the commit adding this file on `main`; before it `de23d5224`. The commit hook pushes. Confirm `git rev-parse --short HEAD`, `git status --short | grep -v '^??'` (empty).
- Tests: unit suite not run (needs Play). Docs: `python tools/check_docs.py` OK (263 pages).
- Studio "FlyFightPaper(First Fold)" in Edit; **place NOT saved**. The open place has the Nap drafts deleted (the uploads play); the saved file still holds `NapSleepClip` / `NapWakeClip` drafts (same keys as the uploads, so harmless; delete them after a reopen). No preview parts left (`ZonePreviewClaude` deleted). DevMute off.
- Cost: no agents; 2 uploads (free); Claude's muted Play runs: one for Nap (measure + live fix trial), one for the five sitting emotes; 3 bots-only matches in the background (~25 min); keep-awake nudge during the Play runs. Context ~45% at handoff.

## NEXT ACTION + PLAN
1. **Step 1, the town map** (plan). Then step 2 (no crashing or getting stuck), 3 (using the town in a fight: the skill table), 4 (varied ways). After each step: `python tools/run_bot_matches.py 3` in the background and compare with the before table; record the after table in the plan.
2. Pure logic (route search with a heap, hole finding from ray results) can go to Codex with unit tests; Claude does the Roblox side, behaviour and checks.
3. Last: Alan's look in Play with a veteran chasing him through the streets (a "what to try" list in STATE).
- HOLDS (his explicit go, each): every upload, place saves, publish (he does it), generator calls other than Codex pictures (price first), any new mechanic or number beyond the approved plan. **Already given for this work:** bot matches and Claude's own Play runs for the bots work ("go on both"), and the plan's numbers.

## DECISIONS & WHY (this session)
- **`sit` rests on the legs only** (Nap floated worse after last night's re-cut): his hips' collision shape is a cone 0.45 studs under the drawn bottom; rays hit that shape, not what is drawn. Ceiling: a body whose drawn bottom hangs under its thighs sinks into the top book.
- **Alan:** Nap OK + upload; "those are fine lets move on from emotes now" (TV picture, quieter sounds parked); the town Airspace zones reach the floor, only the ceiling spot floats ("ok its good now"); bots in the town, all three goals, plan + numbers approved. All in `docs/decisions/` (2026-11-24 emote shop, 2026-11-25 zones, 2026-11-25 bots).
- **Mine, his to reverse:** zone tops and widths kept; lower confetti loop at least 20 studs up (`LOW_LOOP`); in STATE "Decisions to review".

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (model router, one writer per file, push after commit); memories above; `docs/workshop/lessons.md` "Emotes on real bodies" (rays hit the collision shape).

## CARRY NOTES / GOTCHAS
- Today's bots: lowest route layer 145 studs, pushed up under 75 (`steer`), long look-ahead swerves (reach max(150, speed x 2.1)); A* scans the open set (slow past ~100 points). Bots can't see through buildings already (`sees` uses `combat:visible`).
- The town is ~2,028 x 1,428 studs on the rug at y 0 (x within +/-1,014, z within +/-714); buildings are MeshParts in `Arena.CityToys` (names like `tube-tower/...`, `block-arch/...`, `pencil-case-bridge/...`, `porthole-book-tower/...`); the monorail train moves.
- `run_bot_matches.py` now prints a `BOTS:` line (deaths, crashes, scrapes, % low/mid/high over the town) and per-bot town seconds.
- In Edit, `require` of the generated config returns the first (cached) copy after a config edit; read the numbers from the JSON for previews.
- `.planning/emote-shop/` and older `.planning/` pictures are untracked, as before.

## WHAT SHIPPED / OTHER QUEUED
- `5a934e3dd` sitting kids rest on their legs · `8b615206e` Nap plays its uploaded sit clips
- `0dd6b0e55` all five sitting emotes checked · `a8f12f08b` emotes done for now
- `2702f6843` Airspace town zones reach the floor · `0199799f3` STATE under 60 lines
- `1c69dae49` bots in the town plan; bot matches count crashes, scrapes, time low · `de23d5224` the before numbers
- plus the commit with this file.
- Queued (unchanged): the bots' fixed cast look, Alan's looks in STATE's "Waiting on Alan", backlog in STATE.md.

## KNOWLEDGE UPDATED
- `docs/playtests/2026-11-25-nap-sits-and-zones-reach-the-floor.md` (new, his eight notes) + README line; row 5 of the painting note marked done.
- `docs/decisions/2026-11-25-airspace-zones-reach-the-floor.md`, `2026-11-25-bots-use-the-town.md` (new), README lines; `2026-10-16-zones-follow-density.md` heights replaced; `2026-11-24-emote-shop.md` emotes closed.
- `docs/plan/BOTS-IN-TOWN-PLAN.md` (new, linked from HOME; before table); `IDEAS.md` points to it; `EMOTE-SHOP-PLAN.md` step 6 done.
- `docs/systems/modes-and-scoring.md` (zones), `bots.md` (Related); `docs/workshop/lessons.md` (rays vs drawn), `emote-making.md` (Nap ids, re-cut).
- `state/STATE.md` top line, Now, Decisions to review. Memory: ask-what-his-problem-is. Checker: OK (263 pages).

## POINTERS
- `docs/plan/BOTS-IN-TOWN-PLAN.md`, `docs/decisions/2026-11-25-bots-use-the-town.md`, `docs/systems/bots.md`.
- `src/server/BotService.luau` (`steer` 551+, `decide` 373+, avoidance `clearance`), `src/shared/AirRoutes.luau`, `tools/run_bot_matches.py`.
