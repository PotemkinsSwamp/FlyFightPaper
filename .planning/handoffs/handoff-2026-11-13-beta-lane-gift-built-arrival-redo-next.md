# HANDOFF — 2026-11-13 — Gift a friend built (Studio only); Alan wants the gift's arrival moment redone next (on Fable)

**Labels:** kind=product+ui · lane=beta-lane · branch=main · issues= · areas=src/client/{ShopScreen,GiftMoment,MenuController}.luau, src/server/{HangarService,CommerceService,ProfileRuntime,ProfileService}.luau, src/shared/{CommerceRules,ProfileSchema}.luau, config/commerce.json, tests/unit, docs/{decisions,plan,playtests,systems,workshop}
**Time:** 2026-11-13 00:47 -05:00

★ START HERE: Goal (Alan): the beta feels finished and the shop makes money. Next: redo the gift's arrival moment
(`src/client/GiftMoment.luau`) to Alan's story in [the playtest note](../../docs/playtests/2026-11-13-gift-a-friend.md);
done = Alan watches it in Studio and OKs it (send a video, not stills). Alan is running this session on Fable to see
what it can do with animation. Then the goals review with him.

> Read on demand: AGENTS.md → this file; then the playtest note, `src/client/GiftMoment.luau`, `src/client/MenuBoard.luau`
> (the pinned plane, ~line 103), `src/client/UnlockMoment.luau` (the backpack: items one at a time). Skill `design-theory`
> before showing anything. Memories: offer-pieces-catch-the-eye, send-videos-not-gifs, mute-studio-tests,
> alan-does-play-checks, playtest-notes-before-handoff, studio-play-grabs-mouse.

## STATE (verify before acting)
- HEAD `1a18ad9a` + this handoff (main), pushed by the commit hook. Confirm: `git rev-parse --short HEAD`.
- Tests 599 pass / 0 fail, 42 suites (2026-11-13, Studio Play, server: `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`).
- Studio: Edit mode; DevMute, DevGiftSelf, DevGiftMoment, DevGiftTime all cleared. `rojo serve serve.project.json` running.
  Nothing published, uploaded or Saved to File.
- Cost this session: main Opus (~41% context at wrap); 1 codex-rescue wrapper (~38k Claude tokens, ~12 min; Codex itself
  on Alan's ChatGPT plan) for the server and saving; ~4 short muted Studio Plays; no uploads, nothing paid.

## NEXT ACTION + PLAN
1. **Gift arrival redo** (Alan's words in the playtest note). In short:
   - Remove the stray star (it's `Sparkle1`).
   - Rays spin and pulse unevenly: every other ray moving out while its neighbours move in, back and forth, plus bouncing.
     The rays are one picture now (`Assets.shop.rays`), so alternating rays may need separate pieces. Pick the cheapest
     way that looks right.
   - The plane is the menu board's own pinned plane. It comes off its pin, flies right, turns around, comes towards
     you (getting bigger), and flies up off the top. The package falls in from the top and you open it.
   - Thanks: the box stays open and the next gift comes out of it (like the backpack, its own look). After the last
     gift, the plane flies back and is pinned again.
   - One `giftSeen` per Thanks. The inbox can hold several gifts.
   - Test switches: workspace `DevGiftMoment` (pretend gift), `DevGiftTime` (hold a frame), `DevGiftSelf` (real gifts
     to yourself through the shop). Several pretend gifts may need a new switch.
   - Done = Alan's OK after watching a video.
2. **Goals review with Alan** (what "the beta feels finished" still needs; backlog in STATE).
3. Smaller, each needing his look: the gift note and the report card row at a phone size (not checked); the jar level
   rises ~1 pixel per match (offered a count-up number; no answer yet).
- HOLDS (his explicit go, each): any upload (a new picture for the rays would be one: show it assembled first), publish
  (he does it), Save to File, desktop control or screen grabs, Studio Play while he's playing, bot matches, anything
  paid, any new mechanic or number.

## DECISIONS & WHY (this session)
- [Gift decision](../../docs/decisions/2026-11-13-gift-a-friend.md): packs and timed boosts only. No passes yet (Roblox
  ties a pass to its buyer) and no starter pack. A gift never uses up the giver's first-buy 2x and counts as one of the 3
  buys a day. Search box (Alan). Plane delivery (his pick of three looks).
- Each giftable item has its own developer product (`gift_<key>`, 15, disabled, no ids), so a gift payment can't be
  mistaken for a self-buy. Who it's for is kept in server memory only. If that's lost, the giver gets the item.
- `GiftCheck` JSON carries a counter `n` so a repeated answer still reaches the client. A "busy" answer never replaces a
  good one.
- Gift inbox is session memory, not saved. The Paper or boost is saved; only the arrival moment can be missed if they
  leave first.
- Top-bar Gift a friend kept (Alan: redundant but keep). From it, the shop stays "For Sam" until a card's gift button.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (docs rules, model router, hard limits); memories above; `docs/workshop/lessons.md` (3 new Studio lessons).

## CARRY NOTES / GOTCHAS
- `execute_luau` can't call `Menu.show` (separate module cache): use the `DevScreen` attribute. Click by coordinates
  from `AbsolutePosition` (instance-path clicks missed nested buttons). Lessons page has details.
- The starter pack card lost its gift button: a gap is left beside its Buy button (not looked at closely).
- Codex-documented limits: two senders at once can pass the 10-waiting check; a crash between delivery and the
  giver's receipt save can also grant the giver.
- The shop's `mock_ui_label` dash in `config/commerce.json` was already garbled before this session (not Codex).
- `assets/ui/shop/raw` and `source` untracked (as before).

## WHAT SHIPPED / OTHER QUEUED
- dfe80026 Docs: Alan OK'd Gift a friend (packs and boosts only, his changes); treasure chest idea in the backlog
- 1a18ad9a Gift a friend: friend note with search, server check, practice gift, and the paper plane that brings it (Studio only)
- (+ this handoff commit: playtest note, STATE, lessons, LATEST)
- Queued: gift arrival redo, goals review, daily/weekly missions, treasure chest for buyers (check it's fair and allowed
  first), XP line on the report card, bots that use the town, skill bonuses, part model redo.

## KNOWLEDGE UPDATED
- Decisions: gift-a-friend (new; search and plane look added). Playtest: 2026-11-13-gift-a-friend (new). Plan: GIFT-PLAN
  (approved, as built), IDEAS (treasure chest). Systems: economy-and-shop (Friend gifts, Where it stands, Code rows),
  saving (schema 12 `giftIds`, gift delivery). Workshop: testing (gift switches), lessons (3). STATE rewritten (57 lines).
  Checker: `python tools/check_docs.py` OK (185 pages).

## POINTERS
- Stills `.planning/gift-1-pick-a-friend.jpg`, `gift-2-a-gift-for.jpg`, `gift-3-arrives.jpg` · `tools/film_report_card.py`
  (frame-by-frame filming pattern for videos) · `docs/systems/economy-and-shop.md#friend-gifts`
