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

**Daily: three missions, one easy, one medium, one hard**, never two with the same action.

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
playing for the week"). Three missions made by the game plus one fixed card:

| Card | Size | Reward |
|---|---|---|
| Game-made | about 2 days of play | 2,000 Paper |
| Game-made | about 3 days of play | Sticker chest |
| Game-made | about 4 to 5 days of play | Blue Ribbon chest |
| Finish 15 daily missions | any days of the week | Blue Ribbon chest |

The old weekly "3 reward-eligible matches earn a Sticker chest" ([chest decision](2026-11-18-classroom-treasure-chests.md))
becomes a daily mission. A weekly mission can be swapped for 25% of its reward's Paper value, rising each swap that week
(2,000 Paper: 500, 1,000, 1,500; Sticker chest: 750, 1,500, 2,250; Blue Ribbon: 1,625, 3,250, 4,875). The "15 daily missions" card
can't be swapped. It replaced "all 3 dailies on 5 days" (Alan: "that doesnt give the player much wiggle room ... 15 daily
missions might be a better way"): 21 dailies come each week, so a player can miss six. It keeps the week calendar: a
day is ticked when the player finished at least one daily mission that day. Missions are picked when the day or week starts and saved, so changing gear doesn't
reshuffle them. Daily resets at 00:00 UTC, weekly on Monday 00:00 UTC, like the chest milestones. Only reward-eligible
matches count.

How it looks: a Missions sheet from the main menu with Daily and Weekly tabs, each card a goal, progress, reward and a
Claim button ([explanation picture](../../.planning/missions/weekly-tab-what-the-player-sees.jpg): its weekly cards are
the first, too-easy draft; the layout stands). Alan sees a picture of the real sheet before it ships.

## Why

Alan wants players coming back every day and playing through the week, with goals that fit what each player owns and
plays. Generating from shapes gives hundreds of missions; tiers keep every list a mix.

## Affects

[Economy and shop](../systems/economy-and-shop.md#classroom-treasure-chests) (the weekly chest mission changes),
[ideas](../plan/IDEAS.md).
