# Daily and weekly missions

**Decided** on 2026-11-18 by Alan.

## Decision

**Missions are made by the game from shapes** (Alan: "tailor them to each player ... build shapes of them and let the
game generate them based on a tier of difficulty so you never get a full list of hard"). A shape is an action plus an
optional condition plus a count:
- Actions, all from a match: folds, assists, damage, wins, top-3 finishes, matches played, minutes flown, speed boosts
  collected, paper targets hit, folds in one life, few deaths, Paper earned, points in the zone, folds inside the zone.
- Conditions: a weapon, body, nose, wings, tail or booster the player owns; a game mode; "in one match". Only gear the
  player owns is picked. If they lose that gear (prestige), the mission is replaced by one of the same tier.
- **Counts come from what an average player does in a match** (Alan: "we need to think what might the average player
  accomplish"), times the matches the tier stands for. A condition such as a named weapon lowers the count, so a player
  is not pushed into one choice for long ("to reduce forced choice burnout").
- **A day of play is 3 matches, about 24 minutes** (Alan: "3 matches is 24 minutes thats a daily play rate").

**Daily: three missions, one easy, one medium, one hard**, never two with the same action (weekly too).

| Tier | Reward |
|---|---|
| Easy | 100 Paper + 150 XP |
| Medium | 200 Paper + 250 XP |
| Hard | 300 Paper + 400 XP |

"Play 3 matches" is a daily mission. A game-mode mission appears at most once a day and never as the hard one (the mode
is voted). One free swap a day; after it a daily swap costs 150 Paper, then 300, then 450 that day. **A swap never gives
back the same shape** (Alan: "the mission that takes its place is not the same shape"): the new mission has a different
action from the one swapped out, daily and weekly.

**Weekly: arduous** (Alan: "they should take at least a couple of days no more than 5 days to complete ... it takes you
playing for the week"). Three missions made by the game plus one fixed card. They come from the same pool as the
dailies (Alan: "the weekly missions are the same as the daily missions they share the same pool its just the numbers are
more difficult and there is no easy weekly mission"). The Blue Ribbon chest comes only from the fixed card (Alan: "you can
get legendarys from the blue ribbon chest, it needs to be more difficult to get the blue ribbon chest"):

| Card | Size | Reward |
|---|---|---|
| Game-made | about 2 days of play | 2,000 Paper |
| Game-made | about 3 days of play | Sticker chest |
| Game-made | about 4 to 5 days of play | Sticker chest + 2,000 Paper |
| Finish 15 daily missions | any days of the week | Blue Ribbon chest |

The old weekly "3 reward-eligible matches earn a Sticker chest" ([chest decision](2026-11-18-classroom-treasure-chests.md))
becomes a daily mission. A weekly mission can be swapped for 25% of its reward's Paper value, rising each swap that week
(2,000 Paper: 500, 1,000, 1,500; Sticker chest: 750, 1,500, 2,250; Sticker chest + 2,000 Paper: 1,250, 2,500, 3,750). The "15 daily missions" card
can't be swapped. It replaced "all 3 dailies on 5 days" (Alan: "that doesnt give the player much wiggle room ... 15 daily
missions might be a better way"): 21 dailies come each week, so a player can miss six. It keeps the week calendar: a
day is ticked when the player finished at least one daily mission that day. Missions are picked when the day or week starts and saved, so changing gear doesn't
reshuffle them. Daily resets at 00:00 UTC, weekly on Monday 00:00 UTC, like the chest milestones. Only reward-eligible
matches count.

### The numbers (Alan's OK, 2026-11-18)

What an average player does in one match (Alan: "these are good assessments"; no measuring first):

| Action | Average a match | Where it came from |
|---|---|---|
| Folds | 12 | Alan's average player |
| Assists | 7 | Worked out from veteran bot points (10 folds, 1,338 points) |
| Damage | 1,800 | Plane health 73-220, most about 130 |
| Paper earned | 660 | Alan's pace figure for 12 folds |
| Minutes flown | 7 | 8-minute round less respawns and desk time |
| Wins | 1 in 3 | Rules: 1 free-for-all in 12, half of team rounds |
| Top-3 finishes | 1 in 4 | Rules: 3 of 12 places, top 3 of the winning team |
| Paper targets | 2 | Economy reference match |
| Folds before being folded (best life) | 3 | Sum from 12 folds and about 10 deaths |
| Times folded | 10 | Bot matches |
| Speed boosts | 10 | Guess (no counter yet) |
| Zone points, Airspace | 350 | Guess (no counter yet) |
| Folds in the zone, Airspace | 5 | Guess (no counter yet) |

- Daily tiers stand for 1, 2 and 3 matches; weekly cards for 6, 9 and 13. Count = average x matches, rounded to a
  friendly number; an action is not offered where that comes under 3/4 of one (wins and top 3 start at the hard daily).
- A named weapon or part halves the count (folds, assists, damage and minutes only). A mode halves a daily count; a weekly
  mode count assumes one match in three is that mode. At most one mode mission a day and one a week, never the hard
  daily or the 4-5 day card. Zone points and folds in the zone are Airspace missions. About one daily in three has a
  condition.
- One-match feats: folds before being folded (easy 3, hard 4), folded at most (easy 8, medium 6, hard 4), and "in one
  match" (easy 3/4 of an average match, medium a full one, hard 1 1/4). A weekly feat is "N matches where..." at the
  easy level: 3, 5 and 7 matches (Alan: "7 matches where you folded at least 3 planes before being folded"; a feat done
  in a single match "cannot be a weekly"). One feat per card.
- "Paper earned" counts the report card's Paper, boosts included. "Play 3 matches" is one of the hard dailies that can
  come up, not a mission every day.

**At the desk** (Alan, same day: "there does need to be a way to check your missions mid-match ... it should be at the
desk", mobile is cramped): a Missions strip under "Switch to presets" that drops down a compact, semi-transparent list
of the missions and their progress, with a button switching Daily and Weekly; clicking the strip again collapses it.
Never mid-flight. **After a match** the report card gets the teacher's tick slip, saying only that a mission was
completed and to check Missions (Alan: "we don't need to tell them what mission they completed").

How it looks: a Missions sheet from the main menu with Daily and Weekly tabs, each card a goal, progress, reward and a
Claim button ([explanation picture](../../.planning/missions/weekly-tab-what-the-player-sees.jpg): its weekly cards are
the first, too-easy draft; the layout stands). Alan sees a picture of the real sheet before it ships.

**Look, after Alan's first Play look (2026-11-18):** no new pictures ("we don't want to introduce more assets because
that's more things to load"). Each mission card is the desk buttons' construction paper, its colour the difficulty
(Alan: "use colors to signify what difficulty it is"): green easy, yellow medium, red hard (weekly the same three for
2, 3 and 4-5 days), blue the 15-dailies card; never index cards ("you'd be ruining the integrity of the index card").
Progress is the level bar's hand-drawn bar; the notebook paper is turned so its lines run level and everything is
centred on it. Those four strips are kept full size in the menu sheets so the cards stay sharp ("a larger piece of
paper that we can scale down for all the buttons"). Main menu: the paper plane stays where it is (its fly-in lands
there); the stats card is drawn at 80% and Missions stacks under Shop below it, measured on the real art. Desk: the
strip sits a sliver under "Switch to presets" and the list a sliver under the strip, on tracing paper a little more
solid. The tick slip is taped across the report card's top-left corner with the Training board's crayon tick; Studio's
**Dev: mission next match** makes the next match finish a mission so the slip can be seen.

## Why

Alan wants players coming back every day and playing through the week, with goals that fit what each player owns and
plays. Generating from shapes gives hundreds of missions; tiers keep every list a mix.

## Affects

[Economy and shop](../systems/economy-and-shop.md#classroom-treasure-chests) (the weekly chest mission changes),
[ideas](../plan/IDEAS.md).
