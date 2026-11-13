# HANDOFF — 2026-11-12 — Report card's Paper jar row built and OK'd by Alan (fourth look); Gift a friend note drafted, not yet shown

**Labels:** kind=product+ui · lane=beta-lane · branch=main · issues= · areas=src/client/{RoundEnd,ShopScreen,FlightHUD}.luau, tools/film_report_card.py, docs/{decisions,playtests,systems,workshop,plan}
**Time:** 2026-11-12 23:26 -05:00

★ START HERE: Goal (Alan): the beta feels finished and the shop makes money. Next: walk Alan through the Gift a friend how-it-works note ([gift plan](../../docs/plan/GIFT-PLAN.md), drafted this session, not shown yet) in plain words; done = his OK or his changes recorded in a decision note. No gift code before his explicit "build it". Then the goals review with him.

> Read on demand: AGENTS.md → this file; then `docs/plan/GIFT-PLAN.md` and `state/STATE.md`. Skill `design-theory` before showing any screen. Memories: plan-before-building-features, offer-pieces-catch-the-eye, text-fits-its-box, paper-fits-its-content, send-videos-not-gifs, mute-studio-tests, alan-does-play-checks.

## STATE (verify before acting)
- HEAD `59e9cd0e` + this handoff (main); every commit pushed by the commit hook ("github: pushed"). Confirm: `git rev-parse --short HEAD`.
- Tests: not re-run this session (last: 559 pass / 0 fail, 2026-11-12). This session changed client UI only. Re-run: Studio Play, then the runner in `docs/workshop/testing.md` on the server.
- Studio: Edit mode, DevMute off, `DevMatchPaper`/`DevCardTime` cleared, `results_seconds` back to 27 (`git diff src/generated` is empty). `rojo serve serve.project.json` running. Nothing published, nothing Saved to File, no uploads.
- Cost this session: main Opus (~47% context at wrap); 1 web-fetch subagent (~32k tokens, Roblox gifting rules); ~20 short muted Studio Plays for nine filmed takes (~1 h wall clock, most of it filming); no Codex, no uploads, nothing paid.

## NEXT ACTION + PLAN
1. **Gift a friend note with Alan** (GIFT-PLAN.md): what can be gifted, friends only, how it arrives (ProfileStore message to the friend's save), limits. Record his answers in `docs/decisions/` (+ README line). Code only after "build it"; the save rules are Codex's lane (Track C) with unit tests.
2. **Goals review with Alan** (what "the beta feels finished" still needs; the backlog in STATE).
3. Smaller follow-ups, each needing his look: the report card row on a phone size (not checked); the jar level rise is ~1 pixel per match (offered a count-up number on the jar's tag; he didn't answer).
- HOLDS (his explicit go, each): any upload, publish (he does it), Save to File, desktop control or screen grabs, Studio Play while he's playing, bot matches, anything paid, any new mechanic or number (gifting is one).

## DECISIONS & WHY (this session)
- Report card jar row, final (Alan's OK after four looks; [jar rules](../../docs/decisions/2026-11-12-paper-jar-rules.md), [playtest](../../docs/playtests/2026-11-12-double-this-match-and-shop.md)): everything inside the card's edges; big yellow Double panel (two greens clashed) with big words and a distinct bouncing buy button on the old green paper, "Worth" sticker pulsing above it; smaller jar on the right with a short green "See your jar" under it; "+165!" above the jar's right shoulder, turned 30°, under the level bar.
- Beside the jar the Double button switches to that panel (`shapeOffer` in `RoundEnd.luau`); with no jar (live game until go-live) it keeps its old wide look.
- The jar row sits on the card frame, not the page: a turned page (team rounds) switches off the clipping that draws the jar's level (`ShopScreen.jarLevel`).
- Flight HUD hides during the winners' moment: its weapon slip sat under the jar's button (logged in STATE "Decisions to review").
- Studio-only test switches: workspace `DevMatchPaper` (fake match Paper so the Double panel shows) and `DevCardTime` (hold the card's animations); documented in `docs/workshop/testing.md`.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (docs rules, model router, hard limits). Memories above. `docs/workshop/lessons.md` "Working with Alan" (two new lessons: rows stay inside the card's edges; "bigger words" means 30 px+ on selling pieces).

## CARRY NOTES / GOTCHAS
- Filming UI animation: Studio captures ~1 frame/s and the card shows only the last 10 s of results. Hide one winners' desk on the client (scene skips, card stays up), raise `results_seconds` to 120 for the shoot only, hold `DevCardTime` per frame. `tools/film_report_card.py` does it but was assembled at wrap-up from the working scratch scripts and **not yet run as one piece**.
- A long `execute_luau` call (minutes of waiting) loses its reply through the proxy: keep calls short and poll.
- `+165` level rise is nearly invisible at 10,000 cap (one match lifts it ~1 pixel).
- Dev switch (bottom right) still covers the 3rd-place name tag in the winners' moment (Studio only). `UIStroke ... CrayonInk` warning still not looked into.
- `assets/ui/shop/raw` and `source` untracked (as before).

## WHAT SHIPPED / OTHER QUEUED
- 11a97dca Report card: Paper jar piece redone to Alan's pick
- 434fc7a7 Plan: Gift a friend, how it works (draft for Alan's OK)
- c5e6e02a Report card jar: bigger scraps, Double clear of the jar; flight HUD hides during the winners' moment
- e8f43edf Docs: flight HUD hides during the winners' moment
- e1974e39 Report card: Double button folds up beside the jar, row inside the card
- 436fb33a Report card: big Double panel with its own bouncing buy button; smaller jar, short button under it
- 25d17e4a Report card: yellow Double panel, bigger words, Worth sticker above the buy button; +165 turned 30°
- a2e05f0a Report card: buy button and See your jar on the green paper
- 59e9cd0e Docs: Alan OK'd the report card's jar piece; STATE rewritten
- (+ this handoff commit: film tool, lessons, LATEST)
- Queued: Gift a friend (note → his OK → build), goals review, daily/weekly missions (`docs/plan/IDEAS.md`), XP line on the report card, bots that use the town, skill bonuses, part model redo.

## KNOWLEDGE UPDATED
- Decisions: paper-jar-rules (final row, Alan's OK). Playtest: double-this-match-and-shop (fourth look). Systems: economy-and-shop (jar row, Double panel), menus-and-hud (HUD hides in winners' moment). Workshop: testing (DevMatchPaper, DevCardTime, filming), tools (film_report_card.py), lessons (2 new). Plan: GIFT-PLAN (new, linked from HOME). STATE rewritten (59 lines). Checker: `python tools/check_docs.py` OK (183 pages).

## POINTERS
- Video `.planning/report-card-jar-redo.mp4`, still `.planning/report-card-jar-row-fit.png`, break state `.planning/report-card-jar-break.png` · `src/client/RoundEnd.luau` (`shapeOffer`, `showJar`, the RenderStepped animation) · `tools/studio_cli.py`
