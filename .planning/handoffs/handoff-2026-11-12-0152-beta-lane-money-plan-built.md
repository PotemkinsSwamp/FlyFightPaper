# HANDOFF — 2026-11-12 — Money plan approved; daily gift, starter pack, first-buy double, new packs and Hangar buying built ("it's good")

**Labels:** kind=product+ui · lane=beta-lane · branch=main · issues= · areas=src/client/HangarCustomize.luau, src/client/ShopScreen.luau, src/client/MenuController.luau, src/client/PaperUI.luau, src/server/ProfileService.luau, src/server/ProfileRuntime.luau, src/server/HangarService.luau, src/server/CommerceService.luau, src/shared/ProfileSchema.luau, src/shared/CommerceRules.luau, config, tests/unit, docs
**Time:** 2026-11-12 01:52 -05:00

★ START HERE: Goal (Alan): the beta feels finished and the shop makes money. The approved [money plan](../../docs/plan/SHOP-MONEY-PLAN.md)
is half built. Next: the report-card line "2x Paper would have given you +X" (that match's real number, a 2x Paper
button, only when no 2x Paper is running) — done when it shows right on a real report card in Play, words inside their
paper. Then the rest of the plan (below).

> Read on demand: AGENTS.md → state/STATE.md → this file; then the money plan, docs/decisions/2026-11-12-personal-shop-picks.md,
> docs/systems/economy-and-shop.md (save rules), docs/systems/menus-and-hud.md (report card). Memories: plan-before-building-features,
> text-fits-its-box, paper-fits-its-content, familiar-roblox-layouts, mute-studio-tests, alan-does-play-checks.

## STATE (verify before acting)
- HEAD `65b3bac5` + this handoff (main); the commit hook copies every commit to GitHub. Confirm: `git rev-parse --short HEAD`.
- Tests: **512 / 0** (40 suites) in Studio Play this session, after the save rules landed. Re-run per
  docs/workshop/testing.md (start with `task.spawn`, write the result to a workspace attribute, read it in a second call).
- Docs: `python tools/check_docs.py` → OK (174 pages).
- Studio: Edit, DevMute cleared, Rojo `serve serve.project.json` running. Workspace `DevAccountLevel` 12, `DevAccountPaper`
  3000 (fresh account). Practice buys/claims don't save (fresh Play = fresh account). Studio's window must be in front
  for screenshots (it wasn't at first: 1x1 viewport).
- Not published: everything shop/Hangar since the report card. Live sales still off (no product ids).
- Cost: Opus main (~50% context, no compaction). Subagents: 1 Codex job via codex-rescue (Claude ~40k driving; Codex
  ~13 min on Alan's ChatGPT plan), 2 web-fetch readers (~49k, ~20k, Sonnet-class). ~30 web searches. No bot matches,
  no uploads, nothing paid.

## NEXT ACTION + PLAN
1. Report-card line (above). Goal/check only; the report card is `docs/systems/menus-and-hud.md`.
2. Paper jar (25% of earned Paper into a jar up to 10,000; break for 199 R$): save rules (a good Codex job with tests,
   like this session's) + a jar on the Featured shelf. New Roblox product: Alan creates it.
3. Fold screen line N ("Folded by X's Thumbtack Shooter. It unlocks at level 4", no price), Featured "your next part"
   (F), Today's parts (H, 3 parts from your next levels, daily, same time for everyone), calm rule P (`BuysToday` >= 3:
   no offer lines/pop-ups that day).
4. Gift a friend: how-it-works note for Alan's OK first (Roblox gifting rules, regional-price transfers:
   `GetUsersPriceLevelsAsync`).
5. Shop bug: the right-side tab buttons scroll too far (Paper hides its heading and top row). `ShopScreen` tab press
   tweens `CanvasPosition` to `sections[name]` (sheet units) under the sheet's UIScale; check the units.
- HOLDS (Alan's explicit go, each): any upload, publish (he does it), Save to File, desktop control, Studio Play while
  he's playing, a bot match, anything paid, any new mechanic or number. Roblox products: he creates them.

## DECISIONS & WHY (this session)
- Personal shop picks A, B, F, G, H, J, N, P; **offers after a fold or loss are allowed when they fit** (the reward
  chased: 2x Paper/XP), "never after a loss" replaced; the shop **funnels** buying (decoy, anchor, ladder); **EU rules
  later** (no real-money value beside Paper; an EU-only menu if the law passes, 2028+). [decision](../../docs/decisions/2026-11-12-personal-shop-picks.md)
- Money plan approved as written ("great ideas, I like them"); offer chain stays later.
- Stickers stay true per Robux: 40,000 "Most Value", 15,000 "Good Value"; the 549 decoy gets none; no "Most popular"
  until real sales. First-buy double shows the doubled amount on the card.
- Retention/cosmetics: ideas recorded; research done ([cosmetics research](../../docs/research/COSMETICS-RESEARCH-2026-11-12.md));
  Alan hasn't picked. Build our own playtime calendar on our save (Roblox's package keeps its own save and resets per visit).
- `DevAccountLevel` switch now skips non-Instance players (unit-test stand-ins); it had broken two ProfileRuntime tests.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (one fact one page, commit + push small, model router, look at the game), memories above,
  docs/workshop/lessons.md (two new lines: pop-up dims whole screen; dev switches skip test players).

## CARRY NOTES / GOTCHAS
- New Player attributes (server, `ProfileRuntime:update`): `DailyGiftNext`, `DailyGiftReady`, `DailyGiftSecondsLeft`,
  `StarterPackEnds`, `FirstBuysUsed`, `BuysToday`; action `claimDailyGift`. Shop redraws on the first four.
- Untested edge: a paid starter-pack receipt arriving after the player bought a permanent 2x XP pass on another server
  (starter can't be prompted then; the boost part may refuse). Look before go-live.
- Mock (practice) buys now write a `mock:` receipt id, so any practice buy hides the starter pack in that Play.
- Unseen: the shop's top Paper row after the sticker/icon move (the Paper tab bug scrolls past it); shop at phone size.
- `.planning/hangar-buying/` holds this session's Play pictures (not in git).

## WHAT SHIPPED / OTHER QUEUED
- 58e6beb2 Personal shop research: options for a shop that changes with the player, and the new EU law proposal
- fdc5753e Decision: Alan's personal shop picks; offers after a fold when they fit; the shop funnels buying; EU rules later
- 8b43e20b Shop money plan for Alan's OK: daily gift row, starter pack, first-buy double, decoy and anchor packs, Paper jar
- e760529d STATE under 60 lines
- 5786da75 Shop money plan approved; ideas: playtime rewards calendar and cosmetics (skins, trails, emotes)
- 2a3b99fd Cosmetics research: paper skins, trails, fold effects, emotes and playtime rewards; options for Alan
- 111f1fb7 Shop save rules: daily gift row, starter pack with a real 3-day timer, first-buy double, 7,500 and 40,000 Paper packs, buys-today count (Codex, reviewed; 512 tests pass)
- 95a46a8a Hangar buying and the shop's new money pieces, built but not yet seen on screen
- 56fabc70 Hangar and shop checked in Play: bigger, darker card words, shorter Unlock now note, pop-up dims the whole screen, gift timer counts to midnight, pack pictures grow with the amount
- 65b3bac5 Not enough Paper note: dims the whole screen; one short line (Alan)
- Queued: cosmetics picks (Alan, options A-L), balance pass (Spitball planes weakest, 4-Paperclip Cardboard), lesson
  goal note phone shapes, Save to File (his go), personal report card (docs/plan/IDEAS.md).

## KNOWLEDGE UPDATED
- New: docs/research/PERSONAL-SHOP-RESEARCH-2026-11-12.md, docs/research/COSMETICS-RESEARCH-2026-11-12.md,
  docs/decisions/2026-11-12-personal-shop-picks.md (+README), docs/plan/SHOP-MONEY-PLAN.md (approved).
- Updated: docs/systems/economy-and-shop.md (save rules by Codex; shop window row), docs/systems/saving.md (schema 9),
  docs/systems/planes-and-hangar.md (Hangar buying, Alan OK), docs/playtests/2026-11-12-shop-window-and-hangar-buying.md,
  docs/plan/IDEAS.md (playtime rewards, cosmetics), docs/workshop/lessons.md (2 lines), docs/HOME.md, state/STATE.md
  (rewritten top, 59 lines). Checker: OK (174 pages). Memories: none new.

## POINTERS
- Shop: src/client/ShopScreen.luau (`paperPacks`, `freeGift`, `featured`), UIAssets.shop; save: src/server/ProfileService.luau
  (`dailyGift`, `starterPack`, `firstBuys`), src/shared/CommerceRules.luau (`starterPackEnds`), tests/unit/ShopSave.spec.luau.
- Hangar: src/client/HangarCustomize.luau (`padlock`, `robuxButton`, `Customize.unlockRobux`, `state.ask` pop-up).
