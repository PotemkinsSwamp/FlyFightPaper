# Saving

## What the player sees
Your Paper, XP, level, owned parts, five saved builds and settings are kept between visits. Nothing you earned is
lost if a save fails for a moment; it retries without stopping the match for everyone else.

## Where it stands (2026-11-18)

Schema 17 adds `emotes`. Its `owned` map holds paid emote IDs with value `true`. `leader` and `runnerUp` hold
the equipped IDs. New and older saves start with `{ owned = {}, leader = "ToyPilot", runnerUp = "GoodGame" }`.
An invalid equipped pick falls back to its free emote when the save loads.
[Emote rules and Player attributes](economy-and-shop.md#emotes).

Schema 16 adds `missions` and removes the retired chest progress counter. Existing saves start with empty mission lists and retain all earned and purchased chest stock. A missed gift day resets the next claim. The server saves ownership or a duplicate refund with the Paper charge or consumed chest. It records the latest opening number so repeat clicks cannot spend twice. A paid chest receipt grants the unopened chest and receipt ID together before it is acknowledged. [Chest rules](economy-and-shop.md#classroom-treasure-chests).

A separate index counts distinct owners from saved collections across servers. It imports older collections in batches and retries interrupted updates. The reveal shows the recorded count once available. Reopening the same item never adds a second owner. Studio keeps its counts in memory for the Play session.

Skin and trail use separate equipment slots. Existing owned trails carry forward, and Mythical skin owners receive their matching trail. [Ownership checks in Studio](../playtests/2026-11-18-legendary-trails.md).

Schema 12 adds `giftIds`, an ordered list of the newest 200 received gift IDs, defaulting to empty for new and
older saves. IDs are nonempty UTF-8 strings bounded by `max_id_bytes`; duplicate IDs, malformed lists and more than
200 entries are rejected. Gift delivery has written unit tests and awaits Claude's Studio run.
Schema 11 adds `doubleLocks` for the [match-double receipt](economy-and-shop.md#products).
Schema 10 (2026-11-12) adds `paperJarMilli`: integer Paper subunits held in the jar, from 0 to the configured
cap in milliunits. New and older saves start at 0; malformed or over-cap values are rejected. Jar fill and breaks
share the reward/receipt transaction and its duplicate protection. [Jar rules](economy-and-shop.md#products).
Schema 9 (2026-11-12) adds the [shop save fields](economy-and-shop.md#products), with defaults for older saves.
Schema 8 (2026-11-11) adds `unlocksSeen`: the highest level whose unlocks you've opened in the [unlock backpack](../plan/UNLOCK-PLAN.md).
It only rises, never past your level (`RoundAction` "unlocksSeen"); older saves and prestige set it to the current level,
so nothing old piles up. Shut down old servers when publishing it (below).
Schema 7 adds the Range's own five builds (`rangePresets`, any part allowed) and the last Range build flown (`rangeSlot`); the shut-down-old-servers rule applies.
The save now keeps which lessons you've finished (schema 6, `lessons`: the [Training board](tutorial.md)'s ticks; a
new lesson name only widens `ProfileSchema.LESSONS`, no migration; Match Tips save there too, one tick each, from any room:
`ProfileSchema.TIPS`) and a prestige rank (schema 5). The Match tips switch is `settings.matchTips` (optional: missing
means on, so older saves need no migration) and a prestige rank (schema 5). **Before publishing a new schema, shut down all old servers**: an
old server can't read a newer save and would kick a player sent to it (Codex review 2026-10-19). Prestige: its rules are on [Economy and shop](economy-and-shop.md#prestige).
Built on ProfileStore (Stage 5, Codex's lane) and tested with a fake save store. In Studio, progress lasts one
Play session only. Published privately on 2026-10-17 ([how](../decisions/2026-10-07-private-publish.md)); real
saving, rejoin, server hop and multi-player tests are next, played on Roblox itself.
Live-only risks from the 2026-10-17 review (Codex, checked by Claude). Fixed (306 tests): a server move waits for
the real final save (a read of that saved version; a failed read doesn't block), gives up after 60 s, and refreshes
the new room's record just before sending.
Rewards earned after a player left (a late assist) are posted to their save with ProfileStore's offline messages
and applied once on their next join (Codex, reviewed; 318 tests). Rare gap: rejoining the same server while an older
reward message waits can skip that message. Still open: two players can
be sent to the same last seat (Roblox then refuses the full room and the move fails safely). Fixed: a slow friend
check can't start two moves; the room search reads 100 rows, so stale ones can't hide open rooms.

## How it works
*Moved from the old README.*

Stage 5 uses the official vendored ProfileStore library in `src/server/Packages/`. Live servers use
`PPD_ProfileStore_DEV_v1`; the older `PPD_DEV_v1` store is untouched. Studio always uses ProfileStore.Mock,
which cannot grant simulated purchases to a live profile, even when Studio API access is enabled.
Saving is configured in `config/server.json`: about one autosave per player per minute, plus join and leave.
Rewards and their operation IDs change together in the same profile. Recent session IDs store the last applied
operation sequence; retries from the active session cannot pay twice, and old sessions cannot write.
Receipt IDs have a dedicated profile field: a paid product and its receipt ID change in the same save, and the
receipt is acknowledged only once that save has reached Roblox ([economy and shop](economy-and-shop.md)). Switched off
until Alan approves prices.

## Daily and weekly missions

The save keeps the current UTC day and week, both lists, swap counts, finished-daily total, calendar and fixed-card claim. Card validation checks the saved shape and its progress, so tuning new counts and thresholds preserves existing cards. The server picks cards from the player's ID and the gear their catalog and level say they own. Losing gear replaces an unfinished card for free. A finished card remains claimable.

- The profile sent to the client and each Claim or Swap use refreshed missions. A UTC reset pays finished, unclaimed cards and saves the new lists together. An older server clock leaves a newer saved period in place.
- `statistics` uses the match completion time for mission progress. An earlier-day, ineligible or invalid summary leaves mission progress alone. Match statistics and other rewards still settle. Freshly finished cards go to that player via `MissionsFinished` after the operation is accepted.
- `missionClaim` pays the saved card's reward and marks it claimed together. Paper counts as earned Paper, XP goes toward levels, and chests enter earned stock.
- `missionSwap` replaces the card and deducts the Paper together at the server's price. Each operation uses the saved sequence to handle retries.
- `Dev: finish missions` marks the current cards ready to claim on Studio's practice profile. It also fills the fixed card's daily count.

[Mission rules and rewards](../decisions/2026-11-18-daily-and-weekly-missions.md).

## Friend gift delivery
The selected ProfileRuntime store handles checks and messages, so Studio uses its mock store throughout.
`MessageHandler` accepts validated `kind="gift"` messages beside reward messages and queues
`giftReceived` with `{giftId,from,fromName,key}`. It calls `processed()` only after the operation succeeds.
The grant and saved gift ID change together; a repeated gift ID succeeds without granting or showing it twice.
Oldest IDs are removed when the history passes 200 entries.

Received packs add their normal amount as purchased Paper. Timed boosts use BoostClock's verified paid grant,
including dormant time when a forever pass already covers that resource. Receiving changes no `firstBuys`,
`paperJarMilli`, `buysToday` or `receiptIds`, so the recipient's starter offer remains eligible.
Sender receipts use `giftSent`, which only records the receipt and one daily buy, without giving an item.
[Checkout and failure handling](economy-and-shop.md#friend-gifts) live on the shop page.
The requested memory-only recipient has one crash gap: if delivery succeeds but the giver's receipt has not
saved, a server restart can grant the fallback item to the giver as well. The waiting-gift check is a snapshot;
concurrent senders can pass it before any of their messages arrive, so it is not a reservation of the tenth slot.

After a new grant, session memory appends `{from=fromName,key=baseKey}` to the recipient's inbox.
`Runtime:update` publishes it as JSON in the Player attribute `GiftInbox`, explicitly `[]` when empty.
`giftSeen` removes the first nonnegative whole count, capped at the inbox length. The inbox is never saved;
the reward is already granted even if its moment is never seen.

## Code
| File | What it does |
|---|---|
| `src/server/ProfileRuntime.luau` | One save session per player: load, autosave, final save, Studio mock |
| `src/server/CosmeticOwners.luau` | Counts saved owners per cosmetic and imports older collections. `tests/unit/CosmeticOwners.spec.luau` covers repeats and interrupted updates. |
| `src/server/ProfileService.luau` | Changes to a save (rewards, missions, boosts, refolds), each applied exactly once |
| `src/server/RewardQueue.luau` | Retries a failed reward without blocking the round |
| `src/shared/ProfileSchema.luau` | What a save file may contain |
| `tests/unit/ProfileService.spec.luau` | Save changes, mission claims and swaps, rollover, prestige and duplicate requests |
| `tests/unit/ProfileRuntime.spec.luau` | Reward and gift message acknowledgments, session inbox and practice self-delivery |
| `tests/fixtures/FakeProfiles.luau` | Controllable saves and mailbox reads/sends for unit tests |
| `src/server/Packages/` | ProfileStore library (third party, unmodified) |

## Tuning numbers
`config/server.json` `profiles`, `schema`, `rewards`.

## Related
- [Saving uses ProfileStore](../decisions/2026-10-07-profilestore-saving.md)
- [The game stays private](../decisions/2026-10-07-private-publish.md)
- [Economy and shop](economy-and-shop.md)
- [Milestones, Stage 5](../plan/MILESTONES.md)
- [Testing](../workshop/testing.md)

Back to [HOME](../HOME.md)
