# Modes and scoring

## What the player sees
Three modes, voted on after each round: free-for-all (8 minutes or 20 folds), team deathmatch (8 minutes or 60 team folds) and Airspace Control (hold a moving zone; first team to 240). Every point you earn pops up above your plane ("+100 FOLD"). Hidden kid-drawn paper targets on rooftops pay extra.

## Where it stands (2026-10-17)
Round end ([decision](../decisions/2026-10-17-rounds-never-stop.md)): nobody leaves the room; planes hold still for
the winners' moment (27 s, desks in `rounds.winner_desks`), then a safe vote lap through mode rings (keys 1/2/3) and
the next round starts in place. Through the break and the new round's first 2 s walls only bounce you off (your
screen doesn't play a crash either), and a plane carried into a team round keeps its pilot's control when it's
repainted (both fixed 2026-10-23, seen in a bots match). The top strip shows the break's own clock (VOTE 0:30, then
the next mode's countdown) and the vote cards sit under it (2026-10-23). Cutscene and the Studio "end match" button (now three "end: <song>" buttons, one per finalist winners' song, 2026-10-23) seen working in Play 2026-10-17. Fixed the
same day: a team round starting in place after a free-for-all (or the reverse) crashed seating the bots, leaving that
round without bots. Results card shows folds, assists, crashes and points per pilot, team totals in team rounds, and your Paper, XP
and level bar (seen 2026-10-17; the bar filling not yet seen, the test account is at max level). Alan's evening notes (same decision, "Revised again"): the cutscene films each winner close up and straight on in turn
(3rd, 2nd, then 1st with a slow push in), a little from below, the results card on the right; then the card goes and
it zooms out to all three emoting together, from just above the town's roofs with a wide lens. Only things that
would block a winner fade out on your screen (whole buildings, never half of one), and a Roblox focus blur keeps the
winners sharp (Alan 2026-10-18: closer, more cinematic). Rebuilt 2026-10-18 like the big games' winner screens
([decision](../decisions/2026-10-18-winners-shot-redesign.md)): close-ups as each hops up, then one steady group shot,
a little from above, of all three dancing with Roblox's own emotes, paper name plates (place, name, points) and
confetti; the two outside desks slide in next to 1st on your screen only (the real ones can't move: towers stand by
their landing paths). The results card comes up for the last 10 s, so the moment is 27 s. A tied team round has no
places, so its top 3 come in results order. Alan OK'd the group shot in Play 2026-10-18. The stand-up-and-hop animation is uploaded (Alan's go, 2026-10-18, free) and seen playing for all three winners in Play. Vote lap now 30 s. Vote rings: three giant hula hoops in front of
the window wall (plastic with glowing tape stripes, built from round parts as no free Creator Store hoop fit; seen 2026-10-18), with a white HUD arrow to the nearest one while none is on screen (seen pointing
the right way 2026-10-18; it stays hidden with a ring in view). Tests 328/0.
Zone moves and looks right. Paper targets stand on roofs; two (homework, the second broccoli) were buried inside
buildings placed later and moved to open roofs (2026-10-15). A hit tested in Play: the server pays 50 and tells the
shooter's screen; the board falling flat not yet seen (Studio wasn't drawing). Team deathmatch passed a full match by
numbers (2026-10-15: 6 v 6, no bot chased a teammate, results, vote and next round). Not yet seen: the ceiling zone
spot in a real match, the vote screen. Zone spots sized by building density, and the Studio "next spot" button
([decision](../decisions/2026-10-16-zones-follow-density.md)).

**Winners' moment restaged (built 2026-11-19, seen working in Claude's muted Play run, not yet by Alan;** [plan](../plan/WINNERS-CIRCLE-PLAN.md)**).** "Pencils down!" (0.5 s), the room's lights fade to near-dark (1.5 s), the camera glides to the desks in the dark (2 s) and holds on all three, who already stand there as dark shapes; spotlights come on over 3rd, 2nd and 1st a second apart (4.6, 5.6, 6.6 s), each with its name plate and emote, the song from 1st's (the falling confetti is out: Alan 2026-11-19); the camera stays on all three (the zoom in on 1st is out: Alan, they kept coming out of frame), and at 17 s the lights come up as it glides home under the results card. The stand-up-and-hop and the three close-ups are gone. The dark is the room's own lighting turned down on this screen, with the haze set aside. **Rebuilt 2026-11-20; runs in Play and is sharp; the dark is now a nearly black see-through curtain behind the winners and the room's lighting is left alone; each winner is a black shape (a black Highlight) until their click and then stands in the room's ordinary light, with no lamp on them (Alan's idea after real lamps came on late and pulsed; [why](../workshop/lessons.md)); the spotlight is a real cone of light around each winner with a round pool as its floor (Alan picked the strength from a Studio preview; the flat strip looked bad); seen working in Claude's muted run, waiting for Alan's look:** the winners, their books and the plane are real models at normal small size standing right in front of the camera, placed every frame where they look like big ones on their desks, each under a real spotlight (the layers they were drawn in before came out pixelated: Alan); on the big desk a spotlight is a see-through shaft and a glowing pool ([why](../workshop/lessons.md)). The windows stay daylight-bright in the dark. Each winner stands on a stack of single books, 1st on six, 2nd on four thin ones, 3rd on two, in clear steps (Alan: on four, three and two 1st's did not look taller) (`Assets.WinnerBooks`, `assets/models/toys/winner-books/`: the eight books of the free Creator Store model 9749867161 by Ashbashthesmash, taken apart, no scripts, each its own model so one can be kicked later). The room is nearly black (Alan: only shapes) and the unlit winners are black shapes standing still. **Camera Flick is built in as 1st's emote, Studio only; Alan has run the first cut in Play, the admire beat is not yet seen** (2026-11-19): the Dev panel's "end: flick" button ends the match with it; 1st looks down and admires their plane, slowly turning it over (elbow tucked and the plane's bottom towards them, then the elbow out and forward and its top, held: Alan's order, picked from numbered stills 2026-11-20; smug means unrushed), looks up at the camera, winds back and pushes it at the lens 5.3 s after their light (Alan, in Play: the throw alone came too soon; then: the plane must sit fixed in the hand, and no baseball throw), the camera is knocked over, the plane slides down the lens and the scene leaves a little early (about 13.6 s instead of 17 s, so the results card is up for about 13 s). It plays from a clip registered for the Studio session ([how](../workshop/emote-making.md)); the real game needs one upload (Alan's go). Still to come: the spotlight's switch sound, sounds for the flick. The hop animation's config entry and tool stay until Alan has seen the new scene.

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
Points (contribution) rank the results in every mode. Win conditions: FFA ends only when time runs out (no fold cap,
Alan 2026-11-08: like other games), TDM at 60 team folds, Airspace at 240 team zone points.

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
| `src/shared/MatchRules.luau` | Mode rules; the winners' top 3; the report card's grade for a place |
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
