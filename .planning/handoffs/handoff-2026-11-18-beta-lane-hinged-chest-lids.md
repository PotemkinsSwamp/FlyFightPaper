# Handoff - Hinged chest lids and unlock chimes

**Labels** kind=ui, lane=beta-lane, branch=main, areas=chests,audio,art.
**Time** 2026-11-18 04:48 -0500.

**START HERE** Open a Golden Star chest from Shop > Chests in private Studio save 812. Its whole star stays fixed on the front while the lid swings back, the prize rises through glints, and the two backpack unlock chimes play. The open chest stays beneath the prize until dismissal. [Recording with game audio](../skins/chest-hinge/golden-star-opening.mp4).

## STATE (verify before acting)

- Play stopped after 719 checks passed in 49 suites. Desktop and a constrained phone frame were checked. All three changed sources matched Git, Studio Edit and the rebuilt working file. Local gameplay checkpoint 2c73953a. Compare github-snapshot with GitHub main.
- Studio's normal level 12 and 3,000 Paper settings were preserved. Eight uploaded animation sheets were approved. Shop purchases remain Studio practice only.
- One Codex session, no helpers. Duration about 19 minutes. Exact token count unavailable.

## NEXT ACTION + PLAN

Alan can judge the feel and loudness in the recording or in Studio. Resume from his feedback. [Previous handoff](handoff-2026-11-18-beta-lane-shop-chest-opening-and-gift-calendar.md).

## DECISIONS & WHY (this session)

- Alan wants rear hinges and the same whole-latch treatment across all tiers. The movement is baked around a fixed rear edge from each approved chest print. A brief overshoot settles into the held-open pose.
- Reuse the backpack ding and its follow-up a quarter-second later. Gold glints originate at the opening. The game's sound volume and reduced shake preferences still apply.

## CONSTRAINTS / PRINCIPLES

Use the [project rules](../../AGENTS.md) and [chest decision](../../docs/decisions/2026-11-18-classroom-treasure-chests.md). The private save is ready for Alan. No storefront or random reward rules changed in this pass.

## CARRY NOTES / GOTCHAS

Preloading the asset ID alone can succeed while an invisible label stays unloaded. Roblox also delivered a smaller texture in Studio. Keep the selected sheet drawable while warming it and select its frames using normalized positions. See the [workshop note](../../docs/workshop/lessons.md).

## WHAT SHIPPED / OTHER QUEUED

- 469cb242 Hinge chest lids behind the prize and keep each clasp whole.
- 2c73953a Save and verify the hinged chest openings with game audio.
- Other beta feedback remains in [state](../../state/STATE.md).

## KNOWLEDGE UPDATED

Updated the chest decision, Hangar system, art tools index, workshop notes and [Studio check](../../docs/playtests/2026-11-18-shop-chest-openings.md#hinged-lids-and-unlock-audio). Documentation check passed for 204 pages.

## POINTERS

[Eight reward poses](../skins/chest-hinge/eight-open-chests.jpg), [phone layout](../skins/chest-hinge/phone-reward.png) and [opening renderer](../../tools/art/chest_hinge.py).
