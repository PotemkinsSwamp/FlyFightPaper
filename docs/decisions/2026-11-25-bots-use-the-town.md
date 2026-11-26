# Bots use the town and feel smarter

**Decided:** 2026-11-25 (Alan)  
**Status:** in force; built 2026-11-25 ([plan](../plan/BOTS-IN-TOWN-PLAN.md))

## Decision
Alan: "lets get the bots to be able to move through buildings and be smarter when it comes to that". Asked which of
three things he meant, he said "all 3, I want them to feel smarter":
1. Bots fly down among the buildings, along the streets and between the towers, not only over the rooftops.
2. Bots use the town's holes: tubes, arches, under bridges, rings.
3. Bots stop crashing into buildings and getting stuck on them.

Also in the plan he approved ("go on both", with his go for bot matches and Claude's own Play runs for this work):
when chased, a bot may dive into the town to shake you off; when you duck through a hole, it may follow; in Airspace
zones bots fight down between the buildings; in tight spots bots slow like a player braking; a bot that scrapes walls
or gets nowhere for about 2 seconds climbs to open air and finds a new way; different bots take different ways.

Skill decides how smart (his OK on these numbers):

| | Ace | Veteran | Regular | Rookie |
|---|---|---|---|---|
| Follows you through a hole | 90% | 60% | 25% | never (goes around) |
| Dives into the town when chased | most times | often | sometimes | never (climbs away) |

**Changed the same evening** (after his first look, "i didnt notice mush of change"; [playtest](../playtests/2026-11-25-bots-in-the-town-first-look.md)):
"lets do A and B and allow lower skill bots to use the town more often", then "yes those numbers are good":
- **A. Street runs:** a bot shot at that rolls its dive drops to the low routes and heads away from its attacker for
  10-15 seconds, through a hole when one is within about 400 studs ahead, then climbs back and fights again.
- **B. Fights low more often:** cruising bots pick low points 70% of the time (each bot's habit moves it a little); a
  bot that loses you low keeps searching at your height.
- New skill numbers (replace the table above):

| | Ace | Veteran | Regular | Rookie |
|---|---|---|---|---|
| Street run when shot at | 80% | 70% | 50% | 30% |
| Follows you through a hole | 90% | 70% | 45% | 20% |

Done when bots-only matches show bots low about 25-30% of the time, crashes into the town no worse than about 1.5 a
match (rams not counted), the same server time; then his look with a short before/after video.

## Why
Bots only flew over the town (their routes' lowest layer was 145 studs up and they were pushed up under 75 studs),
never through it, so they read as dumb next to a player who hides and chases between buildings. Rookies stay easy
to beat. This is the "bots that use the town" idea from 2026-11-12 ([ideas](../plan/IDEAS.md)).

## Affects
- [Bots](../systems/bots.md)

All decisions: [decisions](README.md)
