# Handoff - Illustrated chest openings

**Labels:** kind=ui · lane=beta-lane · branch=main · issues=none · areas=shop,hangar,chests
**Time:** 2026-11-18 05:43 -0500

**START HERE** Open Shop > Chests in private Studio save 820. Try Golden Star Trail, then compare it with Golden Star Skin. Each should keep its original gold clasp and hold a complete illustrated open case. [In-game opening with sound](../skins/chest-illustrations/golden-star-opening.mp4).

## STATE (verify before acting)

Play is stopped. Six changed game modules match Studio Edit, the rebuilt working file and local main at 602c4b1c. Compare github-snapshot with origin/main for the remote copy. The [playtest](../../docs/playtests/2026-11-18-shop-chest-openings.md#illustrated-chest-openings) records the eight practice purchases and phone frame. In Studio Play, run `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()` on the server for the 719 checks in 49 suites.

One coordinating agent and three helpers contributed. Model-specific token counts were unavailable. About half an hour included artwork generation, image approval, Studio recording and a correction found in that recording.

## NEXT ACTION + PLAN

Alan can judge the lid motion, the new case colors and price readability from the Shop. A physical phone check remains. Continue the same chat for his feedback. [Previous beta handoff](handoff-2026-11-18-beta-lane-chest-shop-and-prize-sheets.md).

## DECISIONS & WHY (this session)

- Alan wanted individual case materials changed while the front ornament keeps its color. Paper uses graph paper, Sticker purple cardstock, Blue Ribbon apricot, Golden Star deep teal with plum trim.
- The earlier opening generated its own lining and held a small tile. Each family and tier now has separate half-open and fully open images. The price sheet leaves space for the whole open case.
- Light Shop lettering needs a solid black outline. Pay particular attention to the disabled Paper button, where a white crayon edge used to fill the gaps between strokes.

## CONSTRAINTS / PRINCIPLES

Robux checkout stays in Studio practice. [Project rules](../../AGENTS.md) and [chest decisions](../../docs/decisions/2026-11-18-classroom-treasure-chests.md).

## CARRY NOTES / GOTCHAS

The eight full open prints are each 1024px square. Their exact registration and asset IDs are in `src/first/UIAssets.luau`. The four original closed Skin tiles still use the original atlas. The original front ornaments stay registered through the turn. Roblox can stop drawing when the monitor sleeps, so confirm actual frame updates before evaluating image quality.

## WHAT SHIPPED / OTHER QUEUED

c8bad889 covers Shop lettering. 602c4b1c covers the chest art, opening, local place, Studio recording and checks. [Other outstanding beta work](../../state/STATE.md).

## KNOWLEDGE UPDATED

Updated the Hangar and Shop system pages, chest decision, Studio playtest, tool index, image sizing lesson and current state. The docs checker passed for 204 pages.

## POINTERS

[All eight open cases](../skins/chest-illustrations/eight-open-chests.jpg), [Trail shelf](../skins/chest-illustrations/trail-shelf.png), [phone price](../skins/chest-illustrations/phone-price.png), [phone reward](../skins/chest-illustrations/phone-prize.png).
