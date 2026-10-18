# Modes and scoring

## What the player sees
Three modes, voted on after each round: free-for-all (8 minutes or 20 folds), team deathmatch (8 minutes or 60 team folds) and Airspace Control (hold a moving zone; first team to 240). Every point you earn pops up above your plane ("+100 FOLD"). Hidden kid-drawn paper targets on rooftops pay extra.

## Where it stands (2026-10-17)
Round end ([decision](../decisions/2026-10-17-rounds-never-stop.md)): nobody leaves the room; planes hold still for
the winners' cutscene (15 s, desks in `rounds.winner_desks`), then a safe vote lap through mode rings (keys 1/2/3) and
the next round starts in place. Cutscene and the Studio "end match" button seen working in Play 2026-10-17. Fixed the
same day: a team round starting in place after a free-for-all (or the reverse) crashed seating the bots, leaving that
round without bots. Results card shows folds, assists, crashes and points per pilot, team totals in team rounds, and your Paper, XP
and level bar (seen 2026-10-17; the bar filling not yet seen, the test account is at max level). Alan's evening notes (same decision, "Revised again"): the cutscene is now straight on and dead centre (1st on the
middle desk), with the town, ceiling decorations, landing rings, planes and name tags faded out on your screen while it
plays; the card comes in after about 4 s, once the camera has stepped back beside it (seen in Play 2026-10-18, steady
60 FPS). The stand-up-and-hop animation is built and seen in a Studio test (waits on Alan's go to upload). Vote lap now 30 s. Vote rings: three giant hula hoops in front of
the window wall (plastic with glowing tape stripes, built from round parts as no free Creator Store hoop fit; seen 2026-10-18), with a white HUD arrow to the nearest one while none is on screen (seen pointing
the right way 2026-10-18; it stays hidden with a ring in view). Tests 328/0.
Zone moves and looks right. Paper targets stand on roofs; two (homework, the second broccoli) were buried inside
buildings placed later and moved to open roofs (2026-10-15). A hit tested in Play: the server pays 50 and tells the
shooter's screen; the board falling flat not yet seen (Studio wasn't drawing). Team deathmatch passed a full match by
numbers (2026-10-15: 6 v 6, no bot chased a teammate, results, vote and next round). Not yet seen: the ceiling zone
spot in a real match, the vote screen. Zone spots sized by building density, and the Studio "next spot" button
([decision](../decisions/2026-10-16-zones-follow-density.md)).

## Rules
*Moved word for word from the old rulebook (GAME_SPEC.md, version 1.0). Starting tuning, not tested balance.*

One match roster, at most twelve actors. FFA uses individual eliminations; TDM team eliminations; Airspace
Control earns a team one point per second while at least one eligible flying member occupies the zone and
no enemy does. Initial control target 240 or eight-minute timer. Zone centered (0,165,0), radius45, halfheight35.
Protection/grounding/menu bodies cannot capture. Extra teammates do not multiply team tick rate. A contested
zone pays nobody until uncontested. Personal contribution every ten eligible seconds uses economy config.

End a round once. Stop new scoring before snapshot/results. Eight seconds results, twelve seconds voting,
three seconds launch countdown. Human eligible participants each get one current vote; bots do not vote.
Offer all viable modes; bots may provide team seats. Tied votes choose the least recently played tied mode,
then a seeded random pick. No votes uses the same least-recent rule.

TDM/control timer ties are draws: completion but no winning-team/podium win bonuses. FFA top elimination tie
at timer is shared victory for present participants. No forced sudden-death extension. Personal podium order
is contribution, eliminations, assists, fewer deaths, then stable seeded actor order (not human/bot priority).
FFA top-three bonuses use that result order. Team podium bonuses go only to top three on a winning team.
Bots can hold result positions but have no wallet; do not shift positions to manufacture human rewards.

A returning-menu confirmation says life/streak ends and final bonuses are forfeited. Keep earned contributions;
award recent-attacker credit as above. A player withdrawing/rejoining the same round cannot reclaim final
bonuses or wipe activity/graduation records. Historical team eliminations remain. New joiners start fresh,
not with a replaced bot's streak or damaged body. Partial participants qualify for final bonuses only under
the same active-time/event requirements; do not create a completion farm from instant joins.

### Personal points (Alan's points workshop, 2026-10-14)
A knockout is called a **fold**. Every point a pilot earns pops up on their screen as number + word
("+100 FOLD", "+35 FOLD ASSIST", "+20 ZONE", "+25 STREAK", "+25 REVENGE", "+100 FIRST FOLD", "+50 TARGET").
Points (contribution) rank the results in every mode. Win conditions are unchanged (FFA 20 folds, TDM 60 team
folds, Airspace 240 team zone points).

| Earned for | Points |
|---|---|
| Fold (the credited killer, rules in section 4) | 100 |
| Fold assist (10%+ of the victim's max health in the 10 s window, as now) | your share of all damage the victim took in that window x 100, rounded to 5, between 10 and 80 |
| Airspace only: a fold or fold assist where neither the folder nor the victim was inside the zone | 40% of the above (fold 40), so only pilots who play the zone top the board |
| Streak: each fold once the folder has 3+ folds in the current life (3rd, 4th, ...) | +25 |
| Revenge: folding the pilot who most recently folded you (once per such fold) | +25 |
| First fold of the match (one per match) | +100 |
| Airspace: every 5 eligible seconds inside the zone while your team holds it | 20 (personal cap = whole round) |
| Hidden paper target hit | 50 each (your own 10 = 500 max); other small props stay 2 (max 20) |

Bonuses (streak, revenge, first fold) are never reduced by the Airspace 40% rule. Paper and XP per point are
rescaled so a reference match pays the same Paper and XP as before (config economy.json).

## Code
| File | What it does |
|---|---|
| `src/server/MatchService.luau` | Rounds, lives, points, teams |
| `src/server/RoundRuntime.luau` | Round phases, voting, rewards, score pop-ups; the round end in the room (planes hold, safe vote lap, next round in place) |
| `src/server/VoteRings.luau` | The vote lap's mode rings: built, counted, and which one a plane flew through |
| `src/shared/MatchRules.luau` | Mode rules |
| `src/client/ControlZone.luau` | Drawing the Airspace zone |
| `src/client/PaperTargets.luau` | Hidden paper targets |
| `src/client/ScorePopups.luau` | Point pop-ups |
| `src/server/PropsService.luau` | Breakable props |

## Tuning numbers
`config/gameplay.json` `rounds` (durations, targets, `control_zones`), `world.paper_targets`; points in `config/economy.json` `points`.

## Related
- [Modes workshop](../decisions/2026-10-13-stage-9-modes-workshop.md)
- [Points system](../decisions/2026-10-14-points-system.md)
- [Escapes](escapes.md)
- [Economy and shop](economy-and-shop.md)
- [Playtest 2026-10-14](../playtests/2026-10-14.md)
- [Milestones](../plan/MILESTONES.md)

Back to [HOME](../HOME.md)
