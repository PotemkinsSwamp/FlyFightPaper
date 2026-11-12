# HANDOFF — 2026-11-11 — Report card built, shop prices set, shop research done; shop concept picture next

**Labels:** kind=ui+product · lane=beta-lane · branch=main · issues= · areas=src/client/RoundEnd.luau, src/shared/MatchRules.luau, src/first/UIAssets.luau, tools/art/report_card.py, assets/ui/results, config/commerce.json, src/shared/CommerceRules.luau, src/client/ShopScreen.luau, tests/unit, docs
**Time:** 2026-11-11 22:46 -05:00

★ START HERE: Goal (Alan): the beta feels finished. Next: a **concept picture of the shop** in our classroom style
(school store counter with a "this week" poster and price tags on string, a sticker album for owned/not-yet, a prize
box for a free daily gift, the starter pack with its real 3-day timer), built from the shop research's tricks and
checklist. Done = Alan OKs the concept. No code before that.

> Read on demand: AGENTS.md → state/STATE.md → this file; then docs/decisions/2026-11-11-shop-direction.md and
> docs/research/SHOP-RESEARCH-2026-11-11.md (sections 4-5 and the checklist). Memories: plan-before-building-features,
> restyle-keeps-content, assembled-preview-before-upload, codex-for-pictures-and-blender, hand-made-not-generic-roblox,
> text-fits-its-box, paper-fits-its-content.

## STATE (verify before acting)
- HEAD `69b8c940` + this handoff (main), pushed by the commit hook. Confirm: `git rev-parse --short HEAD`.
- Tests: 484/0 in Play after the report card (`require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`,
  in Play, as in docs/workshop/testing.md). After the price change: Edit-mode run 451 passed, 4 suites can't load in
  Edit (ProfileStore BindToClose; lessons.md 2026-11-11); Commerce suites pass. Re-run in Play to confirm all 484+.
- Docs: `python tools/check_docs.py` → OK (168 pages).
- Studio: Edit mode, Play stopped, DevMute false, DevTestResult cleared. Device Simulator is ON (Play = 749x381 phone).
  Place file not saved (Save to File needs Alan's go).
- Alan published the earlier build (guns, phone words, SPEED MATCH, Clear all, unlock moment) and shut down old
  servers. The report card and new prices are NOT published.
- Cost this session: Opus main (~50% context, no compaction); 5 Sonnet research agents ≈ 126k/135k/146k/155k/163k
  tokens (~725k); 2 free picture uploads (both Approved by Roblox review); no Codex, no bot matches, nothing paid.

## NEXT ACTION + PLAN
1. Shop concept picture (Codex image on Alan's ChatGPT plan, or a PIL mock-up; tell him the cost) in our style; run the
   research checklist on it; show it close up and over a game screenshot. Done = Alan's OK.
2. Then, each with its own picture/note first: the Hangar's "Unlock now" button (+ "a prestige takes this back"), the
   live shop screen, the starter pack (contents and price for his OK), goal offers (capped, never after a loss/death).
3. Going live is Alan's: he creates the ~35 products/passes on Roblox (prices in docs/plan/SHOP-PRICES-PLAN.md), then
   IDs + `approved_robux_price` go into config/commerce.json, `mode` live (his go).
- HOLDS (Alan's explicit go, each): any upload, publish (he does it), Save to File, desktop control, Studio Play while
  he's playing (ask first; Play grabs his mouse), a bot match, anything paid, any new mechanic or number.

## DECISIONS & WHY (this session)
- Report card = everyone's results on a school report card (Alan rejected my first, personal version: "player
  specific"). Grade per pilot: 1st A+, top quarter A, top half B, rest C (`MatchRules.grade`); FFA from the place shown,
  team rounds by points across both teams (team places only rank the winning team; seen as a C for the round's best).
- Team cards moved apart (0.8 scale at x 1060/1636: they touched); winners' note shortened to "Red team wins!" (the
  scores are in the boxes); Tab standings reuse the card without grades/note. In STATE "Decisions to review".
- All card words are game text (sharp at any size); the picture is paper/printing/lines only.
- Shop prices (Alan: "build it, pencil at 1,699"): packs 1,500/5,000/15,000 for 99/299/799 R$; part prices by Paper
  price band; free weapons' 3 unlock products removed. Prices live on Roblox, not in config, until go-live.
- Shop direction (docs/decisions/2026-11-11-shop-direction.md): store counter + sticker album + prize box; starter pack
  WITH a real 3-day timer (Alan picked it over my no-countdown suggestion); main audience probably NOT children (Alan),
  so don't tune everything to kids, but Roblox's rules and the fair-play checklist still apply.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (one fact one page, commit + push small, model router, look at the game), memories above,
  docs/workshop/lessons.md.

## CARRY NOTES / GOTCHAS
- Not seen in Play: the team-round grade fix, and the report card at PC size (simulator was on). Both in STATE's list.
- Python `Path.write_text` on Windows writes CRLF; this repo mixes CRLF/LF per file. Keep each file's own endings
  (read bytes, detect, write back) or git shows whole-file diffs.
- Research gaps: no videos watched (YouTube/TikTok/Instagram blocked for agents), no craft-game shop teardowns.
  The built-in browser could open video pages if Alan wants a picture board later (he chose concept first).
- Roblox's starter-pack page suggests a pop-up after a lost match: our rule (never after a loss) wins.

## WHAT SHIPPED / OTHER QUEUED
- 900592af Report card plan for Alan's OK: the class results on a school report card
- 0673d473 Results card is now a school report card: grades in red pen, your place circled, teacher's note
- 0601f175 Shop prices plan for Alan's OK: bigger Paper packs, Robux part prices from Paper prices
- 54e2064a Shop prices plan: tables end cleanly
- 9d74a4e8 Shop prices: Paper packs 1,500 / 5,000 / 15,000; free weapons lose their Robux unlock products
- c16390ee Shop research: what makes Roblox players buy, the rules for kids, a tempting classroom-style shop
- 6dd8eefe Decision: shop is a school store counter with a sticker album and prize box; starter pack with a real 3-day timer
- 69b8c940 Note: main audience is probably not children; shop rules still apply
- Queued: shop concept → Unlock now → shop screen → starter pack → offers; balance pass (Spitball planes weakest,
  4-Paperclip Cardboard); lesson goal note phone shapes; Save to File (Alan's go); personal report card for all-time
  stats (docs/plan/IDEAS.md).

## KNOWLEDGE UPDATED
- docs/plan/REPORT-CARD-PLAN.md (new, built), docs/plan/SHOP-PRICES-PLAN.md (new, approved), docs/plan/IDEAS.md
  (personal report card idea), docs/research/SHOP-RESEARCH-2026-11-11.md (new), docs/decisions/2026-11-11-shop-direction.md
  (new + README), docs/decisions/2026-11-08-unlock-ladder (report card built), docs/systems/menus-and-hud.md (report
  card), modes-and-scoring.md (MatchRules row), economy-and-shop.md (prices), docs/research/PRICING-RESEARCH (rows point
  to the plan), docs/workshop/tools.md (report_card.py replaces results_page.py), lessons.md (Edit-mode tests),
  state/STATE.md (60 lines). Memory: restyle-keeps-content (new). Checker: OK (168 pages).

## POINTERS
- Report card: src/client/RoundEnd.luau (makePage, fillResults), tools/art/report_card.py, assets/ui/results/ready/
  report-card.png + red-ring.png; concepts and previews in .planning/report-card-concept/.
- Shop: config/commerce.json, src/shared/CommerceRules.luau, src/client/ShopScreen.luau (Studio practice shop),
  docs/systems/economy-and-shop.md.
