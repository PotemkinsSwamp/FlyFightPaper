# Modes and scoring

## What the player sees
Three modes, voted on after each round: free-for-all (8 minutes or 20 folds), team deathmatch (8 minutes or 60 team folds) and Airspace Control (hold a moving zone; first team to 240). Every point you earn pops up above your plane ("+100 FOLD"). Hidden kid-drawn paper targets on rooftops pay extra.

## Where it stands (2026-10-17)
Round end ([decision](../decisions/2026-10-17-rounds-never-stop.md)): nobody leaves the room; planes hold still for
the winners' moment (27 s, desks in `rounds.winner_desks`), then a safe vote lap through mode rings (keys 1/2/3) and
the next round starts in place. Through the break and the new round's first 2 s walls only bounce you off (your
screen doesn't play a crash either), and a plane carried into a team round keeps its pilot's control when it's
repainted (both fixed 2026-10-23, seen in a bots match). The top strip shows the break's own clock (VOTE 0:30, then
the next mode's countdown) and the vote cards sit under it (2026-10-23). Cutscene and the Studio "end match" button (now "end: <song>" buttons, one per winners' song; pressed between rounds they skip the rest of the break and end the next round as it starts, so there is no wait: Alan's ask 2026-11-21; his verdict in Play: "it's actually pretty good") seen working in Play 2026-10-17. Fixed the
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

**Winners' moment restaged (built 2026-11-19, seen working in Claude's muted Play run, not yet by Alan;** [plan](../plan/WINNERS-CIRCLE-PLAN.md)**).** "Pencils down!" (0.5 s), the room's lights fade to near-dark (1.5 s), the camera glides to the desks in the dark (2 s) and holds on all three, who already stand there as dark shapes; spotlights come on over 3rd, 2nd and 1st a second apart (4.6, 5.6, 6.6 s), each with its name plate and emote, the song from 1st's (the falling confetti is out: Alan 2026-11-19); the camera stays on all three (the zoom in on 1st is out: Alan, they kept coming out of frame), and at 17 s the lights come up as it glides home under the results card. The stand-up-and-hop and the three close-ups are gone. The dark is a nearly black, slightly see-through curtain on this screen; the room's own lighting is never touched. **Rebuilt 2026-11-20 with Alan in Studio; he says "it's good now" and the framing is right ([his choices](../decisions/2026-11-20-winners-curtain-and-cone.md), [his notes](../playtests/2026-11-20-winners-curtain-and-cone.md), [what failed first](../workshop/lessons.md)):** the winners, their books and the plane are real models at normal small size standing right in front of the camera, placed every frame where they look like big ones on their desks (drawn in layers they came out pixelated). They stand in the middle of their desk (1st a touch forward), in the room's ordinary light, with no lamp on them, and are in place as solid black shapes (a black Highlight) just before the camera sets off; a winner's click takes the black cover off. The curtain hangs at the lens while the dark comes down and during the glide, and behind the winners while the camera holds. Each spotlight is for show: a cone of light (24 very faint nested cones of Roblox's own cone shape, up to 1.4 times wider for a taller avatar) and a glowing disc on the desk no wider than the desk is deep; the whole spotlight stands 1.8 times further from the camera than its winner and that much bigger, so it sits behind them on the same spot of the picture and no haze lies over them. The camera comes as close as the screen allows, both ways (Alan 2026-11-20: scale to the screen): 1.25 winner heights of room beside the outside two, measured to the edge of the whole screen (a phone's notch strips included), and never closer than the distance where the name plates' bottoms reach the bottom of the screen; the outside plates slide in to stay whole on a phone. On Alan's own Studio pane (2.55 times wider than tall) that is the view he approved; seen by Claude in the simulator on an iPhone 17 Pro, HD 1080 and that pane (pictures `.planning/emotes/winners-phone-shot.jpg`, `winners-hd1080-shot.jpg`, `winners-laptop-shot.jpg`); Alan: "ok its good" (2026-11-20). 2nd and 3rd can play the first runner-up emote, Good Game (claps, a wave, a nod), instead of a random dance: Studio only, Dev panel "2nd/3rd"; Alan in Play, 2026-11-20: stiff and too fast; remade the same day from Roblox's own clap and wave (clap, wave, stand; no nod); the left hand is pulled onto the right at each clap (Alan: "yea that works"); it is now a dramatic slow clap, a steady one a second, three (Alan: "the slow clap is good now"), then the arms drop and the right forearm comes up into a low V, elbow down, for five lazy waves 0.8 s apart, standing with the weight on the right leg (Alan: "the stance is good. The clap is good", then "the wave is fine": Good Game is approved as it stands, Studio only until its two clips are uploaded on his go; faster clap timings, a bent-knee stance and Roblox's wave he rejected), to his word that feelings must show in the movement, not yet seen by him ([emote making](../workshop/emote-making.md)). Nap is built to Alan's own version (2026-11-20), Studio only, the third step of Dev "2nd/3rd", **approved by Alan in Play after the two fixes ("I think that's good. I think we move on"); one kid's arm glitched back and forth: Roblox's IKControl flipping it while awake, measured in Play and replaced by an arm bend of our own (`bendArm`), which he passed ("arms look fine now")**: the kid sits cross-legged asleep from the dark on, right elbow on the thigh and the head hanging face-down, held by the brow on the hand (after his first look: head more down, and every body moved each frame to rest on its books instead of floating), breathing, with paper Z's rising and a snore bubble at the mouth; when 1st's light clicks on they jolt awake (the bubble pops), look right, left, right and forward, and sink back onto the hand, which stayed in the air; then a new bubble grows (`nap` in `WinnersCutscene`; its two clips are in the open place and in `assets/animations/emotes/`). **Next One is built (2026-11-20), Studio only, the fourth step of Dev "2nd/3rd"; Alan's first look: "It's fine", but it read as fiddling with a flat sheet (the hand moved far more often than the paper changed); now four runs of the hand, one change each (flat, in half, the nose, the wings), approved by him in Play ("it looks good move on"):** the kid sits cross-legged, head down, a white sheet on the right hand in front of the belly; at their light the left hand runs over it four times, the paper really folding as ten hinged pieces, then the right hand lifts the finished plane to eye level and rocks it slowly while the kid looks at it (`nextOne` in `WinnersCutscene`, one clip; the plane is 1 stud long because avatars' arms are short: [emote making](../workshop/emote-making.md)). **The six clips of Camera Flick, Good Game, Nap and Next One are uploaded (2026-11-21, Alan's go) and the scene plays them from their ids in the config (`rounds.emote_clips`); Alan in Play, 2026-11-21: "they play the same". The emotes still show in Studio only, behind the Dev buttons, until who gets which one is decided.** Known: on the phone an outside winner's stretched-out arm can reach the camera island. Noted on phones and left alone (Alan: the zoom was the only problem): the big Menu button lies over 2nd's light, the name plates' words are about 10 points tall, and the report card afterwards covers the Menu button and the hangar papers. The copy of 1st's plane drops the HUD's coloured outline. Not yet confirmed by anyone: the wider cone on a tall avatar, and the outline fix on an outlined plane. Each winner stands on a stack of single books, 1st on six, 2nd on four thin ones, 3rd on two, in clear steps (Alan: on four, three and two 1st's did not look taller) (`Assets.WinnerBooks`, `assets/models/toys/winner-books/`: the eight books of the free Creator Store model 9749867161 by Ashbashthesmash, taken apart, no scripts, each its own model so one can be kicked later). The room is nearly black (Alan: only shapes) and the unlit winners are black shapes standing still. **Camera Flick is built in as 1st's emote, Studio only; Alan has run the first cut in Play, the admire beat is not yet seen** (2026-11-19): the Dev panel's "end: flick" button ends the match with it; 1st looks down and admires their plane, slowly turning it over (elbow tucked and the plane's bottom towards them, then the elbow out and forward and its top, held: Alan's order, picked from numbered stills 2026-11-20; smug means unrushed), looks up at the camera, winds back and pushes it at the lens 5.3 s after their light (Alan, in Play: the throw alone came too soon; then: the plane must sit fixed in the hand, and no baseball throw), the camera is knocked over, the plane slides down the lens and the scene leaves a little early (about 13.6 s instead of 17 s, so the results card is up for about 13 s). It plays from a clip registered for the Studio session ([how](../workshop/emote-making.md)); the real game needs one upload (Alan's go). ****Book Kicker** (1st jumps off the book stack and kicks it at the camera; 2026-11-21: lands close behind the stack by their own legs' reach; the open book's pages are fake handwriting and it ends tilted on the lens, blurrier the closer it comes; name plates and the "Menu" tag are hidden while it covers the lens. Alan called the dismount, the landing and the kick good on recordings and, in Play with its sound, "ok its good"; the clip and its two sounds are uploaded) sits behind "end: kicker", from its upload: [how it works](../workshop/emote-making.md). **Bubblegum** (1st, sassy on one leg, blows a small bubble that snaps and a big one that grows to the lens, pops and leaves gum over the picture; built 2026-11-22 from its draft clip; Alan on its first muted recording: the body is fine, the bubble must hide the face and the gum on the lens must be one sheet pulled off ([his notes](../playtests/2026-11-22-bubblegum-first-run.md)); both built the same day and recorded muted once more; three flaws seen in that recording (the face still faint through the bubble, strands like tents, the sheet's sides showing on the way home) fixed in code, not yet recorded; no sounds) sits behind "end: gum": [how it works](../workshop/emote-making.md). **The plane stays in the hand on every body** (Alan 2026-11-21: on an oddly shaped avatar it may be hard to see, an accepted loss; [decision](../decisions/2026-11-21-plane-stays-in-the-hand.md)). **Toy Pilot**, the free 1st-place emote, plays the same way from its draft behind "end: pilot" (2026-11-21; two cuts rejected by Alan, the third, posed from his Gemini reference video and checked in a Play recording of mine, not yet seen by him: [the cut](../workshop/emote-making.md)). A plane emote now stands in its first pose from the dark on. Still to come: the spotlight's switch sound, sounds for the flick. The hop animation's config entry and tool stay until Alan has seen the new scene.

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
