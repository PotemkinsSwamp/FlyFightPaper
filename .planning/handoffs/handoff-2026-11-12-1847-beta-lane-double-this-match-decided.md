# HANDOFF — 2026-11-12 — money plan seen in Play; Double this match decided (go given), not built

**Labels:** kind=product+ui · lane=beta-lane · branch=main · issues= · areas=src/client/RoundEnd.luau, src/client/FoldOffer.luau, src/client/ShopScreen.luau, src/client/FlightHUD.luau, src/server/RoundRuntime.luau, tools/town_toys.py, docs/
**Time:** 2026-11-12 18:47 -05:00

★ START HERE: Goal (Alan): the beta feels finished and the shop makes money. Build **Double this match** on the report card and the **new 2x boost prices** exactly as in `docs/decisions/2026-11-12-double-this-match.md` (Alan's go given 2026-11-12: "yes, go with 25% and those boost prices"). Done = the grant is unit-tested (pays Paper and XP once, amount locked at press, only that match) and, in Alan's Studio Play after a real match, the button shows the right worth and price, the practice buy pays once, and every word fits its paper (measured, not guessed).

> Read on demand: AGENTS.md → this file; then the decision note above, `docs/systems/economy-and-shop.md` (products, receipts), `docs/systems/menus-and-hud.md` (report card), `src/client/RoundEnd.luau` (current 2x button), `src/server/RoundRuntime.luau` (`missedPaper`, rewards), `src/server/HangarService.luau` (`buyProduct`/`mockProduct`). Skill: `design-theory` before any screen. Memories: alan-does-play-checks, plan-before-building-features, text-fits-its-box, studio-play-is-shared, mute-studio-tests.

## STATE (verify before acting)
- HEAD `cd965cee` + this handoff (main), pushed (GitHub copy via the push hook). Confirm: `git rev-parse --short HEAD`.
- Tests: 529 pass / 0 fail, 40 suites (run 2026-11-12 after the jar minimum). This session's later changes are client UI only (no unit tests). Re-run: `docs/workshop/testing.md` (in Studio Play, the runner writes `DevTestResult`).
- Studio: open on the place, Edit mode at handoff; `rojo serve serve.project.json` running in the background (port 34872); Studio has the newest code (checked by markers). Nothing published; tape-roll tower walls live in Studio only until Alan presses Ctrl+S.
- Cost this session: main session (Opus, long, compacted once); 1 Codex job (~7 min, jar save rules, Alan's ChatGPT plan); 1 side session (Opus) that wrote the design-theory skill, research and 3 comparison pictures; a few short muted Studio test runs; no bot matches, no uploads, nothing paid.

## NEXT ACTION + PLAN
1. **Double this match + boost prices** (go given). Server: lock each player's match Paper and XP when they press (only while that report card is up), grant both again exactly once on the receipt (paid even if the window closed), one per match, counts toward the 3-buys-a-day rule, no Paper jar share. Price = 25% off worth (worth = 2 x Paper / 15 R$), nearest step (10, 15, 25, 35, 49, 69, 99, 149, 199, 249, 299); shown only at 75+ Paper. Client: replaces the green 2x button under your card; "Worth N R$!" sticker propped at an angle that pops in with a bounce and keeps gently pulsing; time left runs down on the button; after a buy it says it paid. Boosts (Paper and XP): 15m 10, 30m 15, 1h 25, 3h 69, 5h 99 R$. Studio uses practice buys (`mockProduct`). Codex's lane covers save and purchase code (AGENTS.md model router); read its diff, re-run the tests.
2. The Paper jar's shop card + its "Are you sure? The jar always costs 199 R$..." warning ([jar rules](../../docs/decisions/2026-11-12-paper-jar-rules.md)). The jar picture is new art, so it needs an assembled preview and Alan's upload go.
3. Gift a friend: a how-it-works note for Alan's OK first (Roblox gifting rules).
4. A goals review with Alan ("look at our goals and see what's next"), plus the playtest list in `state/STATE.md`.
- HOLDS (Alan's explicit go, each): any upload, publish (he does it), Save to File, desktop control or screen grabs (only when truly blocking), Studio Play while he plays, a bot match, anything paid, any new mechanic or number.

## DECISIONS & WHY (this session)
- Double this match replaces timed-2x selling on the report card; boosts were 5-10 Paper/R$ against 15-20 for packs: [decision](../../docs/decisions/2026-11-12-double-this-match.md).
- Fold card (part turning over a soft shadow; Buy now centred; red "Wait for level N" corner button closes it; once per part a session) and shop pictures on faded chalk green 104,133,118: [decision](../../docs/decisions/2026-11-12-fold-card-and-shop-mats.md). Brown kraft and midnight indigo were rejected.
- Paper jar breaks from 3,000 Paper, with a "wait for more" warning: [decision](../../docs/decisions/2026-11-12-paper-jar-rules.md).
- Prices: round numbers under 50, ending in 9 from 49 up (Alan disliked 19).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (docs rules, model router, hard limits). Memories: alan-does-play-checks, studio-play-grabs-mouse, plan-before-building-features, text-fits-its-box, paper-fits-its-content, familiar-roblox-layouts, in-game-menus-match-main-menus, hand-made-not-generic-roblox. `docs/workshop/lessons.md` "Working with Alan" (screen grabs last; temporary prints to catch moments in Alan's Play).

## CARRY NOTES / GOTCHAS
- The fold card's and the new 2x button's words aren't measured yet. Measure them in Alan's Play (`AbsolutePosition`/`TextFits`, or a temporary print) before showing anything new there.
- Alan's "a part revolves around a tip": he hasn't said which screen. Shop, fold card and Hangar views measure centred (box centre = visible centre).
- Output shows `UIStroke is not a valid member of TextLabel "CrayonInk"` 3x (`PaperUI` refresh via `ChildAdded` of a `UITextSizeConstraint`). Not looked into.
- The report card's 2x button uses `mockProduct` (Studio-only practice buy); in the live game it does nothing until real sales are switched on, like the shop's boosts.
- `studio_cli.py` works when the Studio MCP shows 0 tools; Edit vs Play datamodel: pass `datamodel_type`.
- Many untracked `.planning/*.jpg|png` files are older session pictures; leave them.

## WHAT SHIPPED / OTHER QUEUED
- 17a0309d Report card: 2x Paper note with this match's missed Paper and a 2x Paper button; shop tabs scroll in screen pixels
- 3f6e4f57 Paper jar save rules (Codex)
- cd37e055 Fold note names the part that folded you; shop: Your next part card and Today's parts
- c8f9f46f Test count: 529 passing after the Paper jar tests
- 0b699e78 Paper jar breaks from 3,000 Paper (Alan); decision note; 529 tests pass
- 38f534b6 Tape-roll tower: the roll's hole is open (mirrored walls)
- daa5fe4c Backlog: redo the part models, boosters first (Alan)
- 9fc31093 Report card: in free-for-all your card is page 1 (the 2x note and level bar sat on hidden page 2)
- 325462cc Shop: kraft paper circles behind pictures; Today's parts timer under the row
- fdf40376 Folded by a part you don't own: a card on the fold screen and at the desk
- 7708c1e4 Shop: brown circles out; Today's parts timer on dark paper, one line, server clock; backlog: bots that use the town
- 209bf63b Decision note: shop pictures stay off-white for now; Today's parts timer
- 57b09c3a Report card: 2x offer is a big green button under your card; fold card buttons down the middle, red Wait button
- 5049a92b Fold card part turns slowly; report card says (2x); backlog: skill bonuses
- 290f1790 / cf11ecc6 / 9686dcef / 7a027e0b Design theory skill, comparison pictures and research (side session)
- df45f99a Fold card: soft shadow under the turning part
- cb7bd93c Shop: faded chalk green behind every picture
- faf7f378 Playtest note + Double this match decision
- cd965cee Lessons: screen grabs last; temporary prints catch moments in Alan's Play
- Queued: jar card (needs art + upload go), Gift a friend note, goals review, the XP line on the report card ("2x XP: level 13 in about 2 matches", not built), bots that use the town, skill bonuses, part model redo (all in `docs/plan/IDEAS.md`).

## KNOWLEDGE UPDATED
- `docs/systems/menus-and-hud.md`: fold card, report card 2x button, FoldOffer code row. `docs/systems/economy-and-shop.md`: jar `jar_low`, Double this match next, server clocks, backing colour.
- Decisions: paper-jar-rules, fold-card-and-shop-mats, double-this-match (README lines). Playtest: 2026-11-12-money-plan-report-card-fold-card. IDEAS: part models, bots, skill bonuses, skins rotation. Lessons: tape-roll collision, screen grabs last, temporary prints.
- `state/STATE.md` rewritten. Checker: `python tools/check_docs.py` OK (180 pages).

## POINTERS
- `docs/plan/SHOP-MONEY-PLAN.md` · `docs/workshop/design-examples.md` (+ pictures) · `.claude/skills/design-theory/SKILL.md` · `docs/workshop/testing.md` · `tools/studio_cli.py`
