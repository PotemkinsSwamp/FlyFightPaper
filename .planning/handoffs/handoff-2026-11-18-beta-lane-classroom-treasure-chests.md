# HANDOFF - 2026-11-18 - Classroom treasure chests and angled trail previews

**Labels:** kind=product+ui · lane=beta-lane · branch=main · issues=none · areas=assets,config,src,tests,docs,state
**Time:** 2026-11-18 03:38 -05:00

★ START HERE: The four classroom chests are playable from Hangar > Customize > Skins > Treasure chests. Alan can judge prices, streak pacing and the new trail angle in private save 804.

[Current state](../../state/STATE.md), [Studio playtest](../../docs/playtests/2026-11-18-classroom-chests.md), [previous handoff](handoff-2026-11-18-beta-lane-hangar-trail-preview-and-skin-fixes.md).

## STATE (verify before acting)

- Private Team Create version 804. Play stopped with the original level-12, 3,000 Paper Studio defaults restored. All 23 changed script and test sources match the repo in both the local file and Studio Edit.
- The Studio server passed 721 checks across 48 suites. Rerun in Play with `return require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`. Studio profiles are disposable.
- Local main at the gameplay checkpoint is c119a32d. Compare `git rev-parse github-snapshot` and `git ls-remote origin refs/heads/main` for the GitHub mirror. Check Studio identity with `python tools/studio_cli.py list_roblox_studios`.
- Primary plus three Codex helpers. At least 33 minutes elapsed from the chest art upload to handoff. Exact model assignments, tokens and primary context usage were unavailable.

## NEXT ACTION + PLAN

- Alan's check is the player loop and its pacing. Preview a locked skin, inspect the possible outcomes, open a chest and wear a prize. Under Trails compare Cloaking Wake and Water Spray to his reference. Tune from his feedback. The ordinary Studio player path is verified.

## DECISIONS & WHY (this session)

- Alan chose Sticker and Blue Ribbon between Paper and Golden Star. Spend Paper or open chests earned from weekly missions and active play streaks. Duplicates give Paper. Only Dragon and Origami Crane grant matching trails. [Decision](../../docs/decisions/2026-11-18-classroom-treasure-chests.md).
- An intermediate ticket prototype was discarded after Alan clarified the economy. Earned openings use their own stock. Paper openings require an explicit purchase and server-side Roblox eligibility.
- Prices, odds, a 10% duplicate refund and the first mission and streak targets are working numbers for Alan to review. [Economy and earning rules](../../docs/systems/economy-and-shop.md#classroom-treasure-chests).
- The first revised preview still looked small on screen. The final closer chase view uses a cream ruled sheet, manual orbit and a local distortion of the print under Stealth.

## CONSTRAINTS / PRINCIPLES

- Follow the [project rules](../../AGENTS.md) and [upload lessons](../../docs/workshop/lessons.md). Private saves only. Paper is purchasable currency. The earned route stays available when paid random items are restricted. [Roblox guidance](https://create.roblox.com/docs/production/monetization/paid-random-items).

## CARRY NOTES / GOTCHAS

- New players start with zero earned chests. The lowest chest costs 1,000 Paper. A player without enough Paper sees a disabled purchase. A player without paid eligibility sees the earned route.
- Qualifying matches count on the UTC date of completion even when the save arrives later. Independent date windows handle out-of-order deliveries for the latest 32 periods of each track.
- The phone check used a constrained Studio frame. Physical touch and live DataStore checks remain separate.

## WHAT SHIPPED / OTHER QUEUED

- 215c4b49 Turn the trail preview nose up and show its wake against ruled paper
- 4f67ae2d Award classroom chests for play and pay Paper for duplicate skins
- 7b9d55d1 Browse classroom chests, inspect each outcome and wear a prize from the binder
- c119a32d Save the playable chests and verify the player reward paths in Studio
- Current beta backlog is in STATE. Further missions and the playtime calendar remain future work.

## KNOWLEDGE UPDATED

- [Economy](../../docs/systems/economy-and-shop.md), [saving](../../docs/systems/saving.md), [Hangar](../../docs/systems/planes-and-hangar.md), [skin plan](../../docs/plan/SKINS-PLAN.md) and [decision](../../docs/decisions/2026-11-18-classroom-treasure-chests.md) carry current rules. [Workshop lessons](../../docs/workshop/lessons.md) records the camera check. Documentation checker passed for 203 pages.

## POINTERS

- [Playtest and pictures](../../docs/playtests/2026-11-18-classroom-chests.md) include the duplicate receipt, the phone layout and the before/after trail view.
- The [chest atlas](../../assets/ui/hangarshelf/chests/classroom-chests.png) was generated with the built-in image tool as a transparent two-by-two sheet depicting folded notebook paper, coral stickers, a blue ribbon and a gold foil star. Roblox approved image asset 103691943840633.
