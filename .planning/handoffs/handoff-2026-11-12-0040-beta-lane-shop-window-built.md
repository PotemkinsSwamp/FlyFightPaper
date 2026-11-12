# HANDOFF — 2026-11-12 — Shop window built in Studio (Alan: "it works"); next: personalised-shop research + Hangar buying

**Labels:** kind=ui+product · lane=beta-lane · branch=main · issues= · areas=src/client/ShopScreen.luau, src/first/UIAssets.luau, src/client/UnlockMoment.luau, src/client/Hangar.luau, src/server/ProfileRuntime.luau, tools/art/shop_pieces.py, assets/ui/shop, docs
**Time:** 2026-11-12 00:40 -05:00

★ START HERE: Goal (Alan): the beta feels finished, and the shop makes money. Two next steps, both his asks:
(1) **research a personalised shop** ("an algorithm": the shop changes with the player looking at it: spenders vs.
players who haven't spent, timers, rotations; a broad search that includes personal discounts and offers after a fold;
he decides what to use after) — done = a research page in `docs/research/` with a checklist of options for his picks;
(2) **Hangar buying** per his playtest notes (locked look, "Unlock now" for Robux, pop-ups, bigger words) — a picture
for his OK first, then build.

> Read on demand: AGENTS.md → state/STATE.md → this file; then docs/playtests/2026-11-12-shop-window-and-hangar-buying.md,
> docs/decisions/2026-11-11-shop-direction.md (the research brief), docs/research/SHOP-RESEARCH-2026-11-11.md (what's
> already known). Memories: familiar-roblox-layouts, fix-the-annoyance-only, plan-before-building-features,
> assembled-preview-before-upload, mute-studio-tests, alan-does-play-checks.

## STATE (verify before acting)
- HEAD `4a365ab9` + this handoff (main), pushed by the commit hook (copies to GitHub). Confirm: `git rev-parse --short HEAD`.
- Tests: NOT run this session (UI + Studio-only profile changes). Re-run in Play:
  `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()` (docs/workshop/testing.md); last 484/0.
- Docs: `python tools/check_docs.py` → OK (170 pages).
- Studio: Edit, Alan has been playing in it. Workspace attributes set: `DevAccountLevel` 12, `DevAccountPaper` 3000
  (fresh account; delete both for the full one). DevMute cleared. Rojo `serve serve.project.json` running.
- Not published: shop window, report card, new prices. Shop button shows in Studio only (until go-live).
- Cost: Opus main (~65% context, no compaction); Codex on Alan's ChatGPT plan: 1 concept job (~100k), 1 redo (~27k,
  plus one killed run), 3 piece jobs (~104k / 98k / 91k); 48 free Open Cloud uploads (all "Reviewing" at upload); no
  Claude subagents, no bot matches, nothing paid.

## NEXT ACTION + PLAN
1. Personalised-shop research (brief in the shop decision, 2026-11-12 bullet): spend-based personalisation (first
   purchase, spenders, non-spenders), timers/rotations/refreshes, personal discounts, offers after a fold or loss,
   Roblox's rules and the law (EU CPC Oct 2026, FTC, UK), how to fit it to our shop. Build on the Nov 11 research, don't
   repeat it. Done = a page with options + evidence + risks for Alan to pick from. Tell him the cost first.
2. Hangar buying (his notes): picture of the Customize binder with a locked look, "Unlock now <R$>" where the Paper
   buy can't happen, a pop-up on a failed buy (level: buy with Robux; Paper: buy Paper or buy with Robux), bigger card
   words; the stale "You need more Paper." line goes. His OK on the picture, then build.
3. Then, each with a note for his OK: starter pack price (contents so far: Swept Wings, 1,500 Paper, 1 h 2x XP),
   daily gift amount, Gift a friend (how it works). Main menu / Hangar Shop button for go-live.
- HOLDS (Alan's explicit go, each): any upload, publish (he does it), Save to File, desktop control, Studio Play while
  he's playing (ask; Play grabs his mouse), a bot match, anything paid, any new mechanic or number.

## DECISIONS & WHY (this session)
- Store-counter concept rejected ("unrecognizable from all other roblox uis"); shop = normal Roblox shop window in our
  materials (decision updated). "Limited time!" and gift buttons OK. Built to the approved concept's measured
  proportions (`.planning/shop-concept/layout-measured.md`); every picture one named line in `UIAssets.shop`.
- No "Every part can be earned by playing" line (Alan: boosts can't be earned). Chalk headings: crisp white, dark
  outline (crayon edge blurred them). Starter-pack items are real 3D parts, still, posed by kind (`POSE`), bobbing.
- Starter pack, free gift and gift buttons are Studio previews only (example numbers) until their notes are OK'd.
- Skip in the unlock backpack is unchanged (I changed it by mistake and reverted: memory fix-the-annoyance-only).
  The Studio account now starts with its unlocks seen; `DevAccountLevel` also turns off the Hangar's Studio
  own-everything mode (`Hangar.luau` `dev`).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (one fact one page, commit + push small, model router, look at the game), memories above,
  docs/workshop/lessons.md. Research has no prices-per-player decision yet: research only.

## CARRY NOTES / GOTCHAS
- `tools/art/shop_pieces.py`: raw Codex pieces in `assets/ui/shop/raw/` (not in git), prepared in `source/`; header says
  how to swap one picture. Big pieces are split (window 2x2, title bar / featured / free card halves) and overlap 1 px.
- The 2x Paper boost row hides when the pass is owned (practice buys don't save, so a fresh Play shows it again).
- Shop tabs light by scroll position (`sections`); custom scrollbar handle (Roblox's bar hidden).
- Not seen: shop at phone size in Play; Robux icon size vs concept (Alan didn't object).
- Alan's binder screenshot also showed weapon card words very small ("light, weight 2. Owned").

## WHAT SHIPPED / OTHER QUEUED
- a9c2edef Decision: shop is a normal Roblox shop window in our materials; Limited time and gift buttons OK
- 24a25c2e Shop screen plan for Alan's OK: the approved concept built to its proportions, with movement
- 0a76ff6d Shop is now a Roblox-style shop window in our paper look, built to the approved concept, with moving rays, stars and rainbow stickers
- 87426507 Shop: the starter pack's part fills its square
- f64bf5c2 Starter pack preview: 1 hour of 2x XP instead of 2x Paper (Alan)
- c8f23eea Unlock backpack: Skip closes it all; the Studio test account starts with its unlocks seen (Alan)
- 16982786 Skip works as before (my mistake); shop parts sit still at their best angle and bob
- 374a303b Studio switch for a fresh test account (DevAccountLevel); next: personalised shop research brief (Alan)
- 22d402cd Testing page: the fresh Studio account switch
- d22543c3 Fresh Studio account: the Hangar shows what it really owns
- 4a365ab9 Playtest note: shop window OK; Hangar buying needs a locked look, Unlock now, pop-ups and bigger words
- Queued (from before): balance pass (Spitball planes weakest, 4-Paperclip Cardboard), lesson goal note phone shapes,
  Save to File (his go), personal report card (docs/plan/IDEAS.md).

## KNOWLEDGE UPDATED
- docs/plan/SHOP-SCREEN-PLAN.md (new, built), docs/decisions/2026-11-11-shop-direction.md (Roblox-window change, starter
  pack contents, research brief), docs/systems/economy-and-shop.md (shop window, code row), docs/workshop/tools.md
  (shop_pieces.py), docs/workshop/testing.md (fresh account switch), docs/playtests/2026-11-12-shop-window-and-hangar-buying.md
  (new + README), docs/HOME.md (plan link), state/STATE.md (rewritten, 59 lines). Memories: familiar-roblox-layouts,
  fix-the-annoyance-only (new), mute-studio-tests (updated). Checker: OK (170 pages).

## POINTERS
- Shop: src/client/ShopScreen.luau, UIAssets.shop (src/first/UIAssets.luau), tools/art/shop_pieces.py, assets/ui/shop/;
  concepts and Alan's Roblox shop screenshots in .planning/shop-concept/ (roblox-examples/, shop2-a/b.png).
- Hangar buying: src/client/Hangar.luau (binder cards, `owned`), src/server/HangarService.luau (purchasePart messages).
