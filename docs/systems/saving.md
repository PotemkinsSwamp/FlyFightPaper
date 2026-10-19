# Saving

## What the player sees
Your Paper, XP, level, owned parts, five saved builds and settings are kept between visits. Nothing you earned is
lost if a save fails for a moment; it retries without stopping the match for everyone else.

## Where it stands (2026-10-15)
The save now has a prestige rank (schema 5); its rules are on [Economy and shop](economy-and-shop.md#prestige).
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
Receipt IDs have a dedicated profile field. Real receipt processing stays disabled until Stage 10.

## Code
| File | What it does |
|---|---|
| `src/server/ProfileRuntime.luau` | One save session per player: load, autosave, final save, Studio mock |
| `src/server/ProfileService.luau` | Changes to a save (rewards, boosts, refolds), each applied exactly once |
| `src/server/RewardQueue.luau` | Retries a failed reward without blocking the round |
| `src/shared/ProfileSchema.luau` | What a save file may contain |
| `tests/unit/ProfileService.spec.luau` | Save changes, prestige and duplicate requests |
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
