# Handoff - Shop chest openings and the gift calendar

**Labels** kind=product+ui, lane=beta-lane, branch=main, areas=shop,hangar,cosmetics,saving

**Time** 2026-11-18 04:23 Eastern

**START HERE** Private Studio save 809 contains the eight chest cards. Open Shop > Chests, choose an earned opening or a Studio practice purchase, then Wear the reward. Alan's next check is the look and timing of the opening. [Playtest and video](../../docs/playtests/2026-11-18-shop-chest-openings.md).

## STATE (verify before acting)

- Play stopped, DevMute restored to absent. The ordinary Studio account starts at level 12 with 3,000 Paper. The Play-only gift date fixture is gone. Studio Edit and the working file matched all 29 changed Luau sources. Roblox acknowledged the private save.
- 719 passed, zero failed, 49 Studio suites. In Play use `return require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`. Test purchases and ownership totals use an isolated Studio profile.
- The current playable checkpoint is 6e2bdfc6. Compare the local github-snapshot ref with GitHub main. The project remains on local main.
- One primary Codex agent with shop, reveal and reward helpers. Exact total usage unavailable. [Previous checkpoint](handoff-2026-11-18-beta-lane-classroom-treasure-chests.md).

## NEXT ACTION + PLAN

Have Alan try the opening and compare the two chest designs. He can check the small print and buttons on his phone. Apply his feedback on timing and pricing. His last instruction limits Robux to Studio practice.

## DECISIONS & WHY (this session)

- Alan kept Sticker for the second tier. Both chest families have the four classroom tiers. Mythical trails stay exclusive to their matching skin. A daily gift or mission chest lets the player choose a family. The starter pack gives a Paper Skin chest.
- The fourth weekly claim is the monthly milestone at 28 consecutive UTC gift days. Three qualifying matches during a week still earn a Sticker chest. See [Alan's decision](../../docs/decisions/2026-11-18-classroom-treasure-chests.md) and the [odds and prices](../../docs/systems/economy-and-shop.md#classroom-treasure-chests).
- Owner counts use distinct saved profiles. Old collections enter the index in the background. The reward sheet can show Counting owners while the save and count catch up. Live totals can grow as old accounts are counted.

## CONSTRAINTS / PRINCIPLES

Real checkout is off. No products were registered. Never spend Robux, alter account settings or publish publicly. Keep the normal in-chat compaction and project handoff. Keep the independent skins-lane pointer below intact.

## CARRY NOTES / GOTCHAS

- Paper and practice Robux went through the normal Shop confirmation. Paid stock stays with the family bought. Earned stock is shared by tier. The player can preview the odds before spending.
- Historical owner indexing and checkout across multiple live servers were outside the isolated Studio test. The smaller screen check used a constrained frame. The place builder still lists the same Eraser mesh awaiting a saved exact collision shape as before the chest changes.

## WHAT SHIPPED / OTHER QUEUED

- 04a78588 adds the chest families, two payment paths, opening, streak rewards, ownership counter, binder dividers, tests and current system docs.
- 6e2bdfc6 saves the working file and adds the Studio check, video, screenshots and current state.
- Other gameplay feedback and beta tasks are in [state](../../state/STATE.md).

## KNOWLEDGE UPDATED

[Economy](../../docs/systems/economy-and-shop.md), [saving](../../docs/systems/saving.md), [Hangar](../../docs/systems/planes-and-hangar.md), the shop and skin plans, the decision index and the [Studio check](../../docs/playtests/2026-11-18-shop-chest-openings.md) reflect this build. Documentation check passed for 204 pages.

## POINTERS

[Chest opening video](../skins/chest-opening/in-shop-trail-opening.mp4), [shop shelf](../skins/chest-opening/shop-shelf.png), [approved trail-stamped chest art](../../assets/ui/hangarshelf/chests/trail-chests.png) and [current state](../../state/STATE.md).
