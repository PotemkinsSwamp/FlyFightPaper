# Tutorial

## What the player sees
A new player's first join goes straight into a guided lesson in an empty copy of the classroom: flying (steer, Lift,
fans, landing), shooting paper targets, then a fight with one enemy, then what every part of the HUD means, the
hangar, each weapon, and how building a plane works. It can be skipped and replayed, and never pays rewards.

## Where it stands (2026-10-18)
Being built now (after Stage 10). **Its own room works:** a brand-new player (no matches played) is sent, once the
classroom has loaded, to a fresh private server of the same place that nobody else can join; the Tutorial button
does the same from any room. The room has no match, no clock, no bots and no rewards; the lesson starts by itself.
Finishing or skipping sends the player to a normal room for their level, tagged "tutorial seen" so that room doesn't
send them straight back. A player who leaves before playing a match sees it again on their next visit.
Studio stands in for the room: set the `DevTutorialRoom` attribute on `ReplicatedStorage.FlyFightPaper` during
Play; Skip turns the room back into a normal match. The live room move needs a private publish to test (Alan's go).
Lesson so far: steer, shoot the practice target, Lift and a fan, landing. Next: one enemy to fight, then the HUD,
hangar, weapons and plane-building steps.

## Rules
See "Tutorial (built last)" in [Milestones](../plan/MILESTONES.md). Practice is never reward-eligible.

## Code
| File | What it does |
|---|---|
| `src/client/Tutorial.luau` | Sticky-note step guide; starts by itself in the tutorial room |
| `src/server/RoundRuntime.luau` | Tutorial room: no rounds or bots; first-join routing; practice flights |
| `src/server/Matchmaking.luau` | Sends a player to a fresh private tutorial room and back |
| `src/server/MatchmakingAdapter.luau` | Reserves tutorial rooms; never lists them |
| `src/shared/CombatRules.luau` | `practiceTargetPose`: where the practice target goes |
| `src/server/CombatService.luau` | Practice pilots are nobody's enemy |

## Tuning numbers
None yet.

## Related
- [The tutorial is built last](../decisions/2026-10-13-tutorial-built-last.md)
- [Menus and HUD](menus-and-hud.md)

Back to [HOME](../HOME.md)
