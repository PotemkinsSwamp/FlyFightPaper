# Real players: 12 per server, straight into the match

**Decided:** 2026-10-17 (Alan)  
**Status:** in force

## Decision
- **12 players per server**, the same 12 seats bots fill. Bots fill empty seats; each human takes one.
- **No waiting and no lobby:** a player who presses Play joins the running match at once. If all 12 seats are
  taken, a bot leaves (a dead one first, then one parked at its desk, then one nobody is fighting, then any). Only a
  server of 12 real players makes someone wait. Between rounds a joiner sees the results and vote, and gets a desk
  when the next round starts.
- **Friends:** a beginner who joins a friend's regular room may stay once they have finished one match (Alan: "one
  game after the tutorial"; the tutorial isn't built, so for now any qualifying match counts). Before that they
  still start in a beginners' room.
- **Private publish: go** (the game stays private).

## Why
Players should be flying within seconds of pressing Play. 12 fits the room (about 720 x 720 studs of air each), the
12 desks and the 60 FPS target; more needs more desks and testing on slower devices.

## Affects
- [Bots](../systems/bots.md) (roster and matchmaking rules)
- [Saving](../systems/saving.md)
- [Milestones, Stage 11](../plan/MILESTONES.md)

All decisions: [decisions](README.md)
