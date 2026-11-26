# Playtime rewards plan

**Status:** how it works, the chart's prizes and the treasure chest approved (2026-11-25); building. His words: "lets tackle playtime rewards and we will bundle it
with the treasure chest because at the end of the playtime rewards you could get a treasure chest". The idea and his
first numbers: [ideas](IDEAS.md) (playtime rewards, treasure chest for buyers).

**Alan's changes to the first draft (2026-11-25):** the chest comes much later, "probably like 4-5 hours of total
playtime for the day"; "large rewards at every hour mark and then small rewards between", three between every hour mark.
Before the prizes are set: "we really have to consider how much we give away and whats worth the player retention vs
what we give away because we also want people to pay with robux, but also we need to look at how much player retention
is worth and what it pays us in the long game. after that we can consider whats in the chest." (The first draft had five
boxes from 5 minutes to a chest at 2 hours.)

**Settled (Alan 2026-11-25):** "chest at 4 hours", then the same day "4 hours is a bit excessive ... we drop it down to 2. We just fit everything back into 2 hours": the same 16 boxes, one every 7½ minutes ([decision](../decisions/2026-11-25-playtime-chart-two-hours.md)); prices shown are always real ([decision](../decisions/2026-11-25-real-prices-only.md)). The look: he likes the treasure map idea (concept pictures in progress).

## What the player sees
A **sticker chart** for today, like the ones on a classroom wall: a row of boxes for each hour, each box with its time
and its prize. Playing fills the chart; when a box's time is reached it gets a gold star sticker and a "!" shows on its
menu strip. Tap the box to take the prize. The hour boxes are bigger, with bigger prizes; the last one is a **treasure
chest**. When the chart is full: "Come back tomorrow for a new chart."

- On the main menu: a **Playtime** strip with the others (Shop, Missions, Emotes) shows the next box and how long to go.
- In a match: a small paper note when a sticker is earned ("Sticker earned! Take it from the menu."). The prize is taken
  from the menu, also the in-match menu.

## The look (Alan 2026-11-25; concept pictures in `.planning/playtime/`)
- **A treasure map** in place of the sticker chart ("I kind of like the idea of the treasure map"): a path from Start to an
  X with the chest, 16 stops, the three half-hour stops drawn as landmarks, a paper plane where you are. On **light blue
  craft paper** with cut-paper pieces (his pick of three papers: "it should be on the blue craft paper"), with the
  notebook-hole edge and tape of the Missions sheet.
- From the picture review, for the build: a stop you can open bounces and says "Open!"; stops not reached are dimmed; a
  big stop's time sits on its own flag; the chest's X is not red (the close button is); labels get bigger paper.
- **The wheel shows chances by slice size, with no percentages written on it** (Alan: "the spots need to just indicate
  the percentage like all other spin wheels do"): 3,000 Paper 108 degrees, the boost pair 97, Sticker chest 90, 5,000
  Paper 36, Blue Ribbon chest 22, Golden Star chest 7. Proposed: a small "?" opens the list of exact chances, as our
  chests' prize lists do.
- **The treasure chest opens with the same animation as every other chest** (Alan: "the treasure chest is an animation
  like all the other chests"; `ChestOpening.luau`: the screen dims, the chest rises, rattles, the lid pops with sparkles).
  Proposed steps from map to prize (waiting on Alan's OK): tap the bouncing chest on the X; the map dims and the chest
  plays that opening; three things rise out and settle in a row above it (3,000 Paper, the wheel in the middle and
  biggest, the boost pair), each with its button (Take, Spin!, Take); a taken prize shows on the chests' prize note with
  Done; Spin! drops the side prizes back in, the wheel grows, spins about 4 seconds with the pencil ticking and stops,
  then the same prize note (a won chest: "Open now" plays that chest's opening, or "Later"); closing before choosing
  shuts the chest and it waits on the map until the day ends.

## Rules
- **What counts:** all time in the game: matches, the menus, building planes, training (Alan 2026-11-25: "if you are in
  the menu building planes or doing other stuff that play time should count"; first set to match time only). Time away
  from the keyboard does not: a player who has pressed, moved or tapped nothing for 2 minutes stops counting until the
  next touch, so nobody can leave the game running, or rejoin and leave it again, for a chest.
- **Today's chart:** time adds up over the day, so leaving and coming back keeps your stars. A new chart starts the
  first time you join on a new day (UTC, like the daily gift); it never resets while you are playing.
- Each box can be taken once a day; a box not taken by the day's end is lost (the chart page says so).
- The server counts and saves the time; the game on your screen only shows it.

## What keeping players is worth (looked up 2026-11-25)
- **A kid who never pays earns us nothing directly, however long they play.** Since July 2025 Roblox pays creators
  (Creator Rewards) 5 Robux a day for each *Active Spender* (about $10 spent on Roblox in the last 60 days) who plays 10+
  minutes, if ours is one of the first three games they play that day; and 35% of a new or returning player's first $100
  of purchases in 60 days when they came through our link or a search for our name. Roblox changed it because long,
  passive and AFK sessions were taking too big a share. ([Creator Rewards](https://create.roblox.com/docs/en-us/creator-rewards),
  [announcement](https://devforum.roblox.com/t/creator-rewards-is-live/3838257))
- **What keeping players does pay: being shown to more players.** Roblox's recommendations rank first by how often people
  who see the game go on to play it, and track each player's playtime and **days played** over the first day, days 2-7
  and days 8-28 (moved to 28 days in June 2026 to measure long-term retention). Players who come back on more days help
  the game's ranking; nothing official says one very long day helps more than several short ones.
  ([discovery](https://create.roblox.com/docs/en-us/discovery),
  [Roblox, June 2026](https://about.roblox.com/newsroom/2026/06/optimizing-discovery-great-games-reach-millions-players-roblox))
- **What players usually do:** in big Roblox games the median player plays about 17 minutes a day in 2 sessions; the
  median game keeps about 10% of new players to the next day, 1.6% to a week and 0.5% to a month (the top 1%: 22%, 9%
  and 4.7%). ([GameAnalytics 2025](https://www.gameanalytics.com/cn/reports/2025-roblox-report),
  [summary](https://gamedevreports.substack.com/p/gameanalytics-key-roblox-and-roblox)) So most players will only ever
  see the chart's first box or two; the hour boxes and the chest are for the few who play a lot.
- **Money:** a player pays about 1.25 cents a Robux; we get 0.38 cents through DevEx, about 30 cents of each dollar
  ([DevEx](https://create.roblox.com/docs/en-us/production/monetization/developer-exchange)).
- **No numbers anywhere** on how much timed rewards raise playtime or retention, or how much free currency cuts sales;
  only opinions (daily rewards help retention more than spending; free currency teaches players the shop).
- **Rules:** a chest earned without Robux needs no odds shown (ours shows them anyway); one that can also be bought
  with Robux must show every prize and its exact odds, which our chests already do
  ([paid random items](https://create.roblox.com/docs/production/monetization/paid-random-items)). No Roblox rule found
  on time-played rewards for under-13s.

**What that means for the chart:**
1. Giving away costs us only when it replaces something a player would have bought. Most kids never buy, so for them
   the prizes cost nothing and keep them around, which gets the game shown to more kids.
2. For players who do buy, plain Paper is what a free gift replaces most (Paper packs). **Boost time** is better to give:
   it only pays while you play (so it brings you back), it's a taste of a 10-Robux product, and it adds a lot of Paper
   for little Robux value. The free chest shows off the chest collection the same way.
3. The first box matters most: it's the one most players ever reach (15 minutes is about the median player's whole day).
4. A 4-hour chest gets almost all of a 5-hour one's benefit: very few kids play either, Roblox no longer pays for long
   sittings, and 5 hours is a very long day for a kid. Recommended: **4 hours** (Alan later chose 2).

## What the chart gives away (approved 2026-11-25: "Bigger", the small boxes' Paper doubled)
Sixteen boxes over 2 hours: one every 7½ minutes (about one a match), a big one every half hour (★). The prizes grow through the day.

| Half hour | 7½ min | 15 min | 22½ min | ★ the half hour |
|---|---|---|---|---|
| 0:00-0:30 | 100 Paper | 5 min 2x XP | 100 Paper | **15 min 2x Paper** |
| 0:30-1:00 | 150 Paper | 5 min 2x XP | 150 Paper | **400 Paper** |
| 1:00-1:30 | 200 Paper | 5 min 2x XP | 200 Paper | **30 min 2x XP** |
| 1:30-2:00 | 250 Paper | 5 min 2x XP | 250 Paper | **Treasure chest** (see below) |

How much that is, next to what playing earns (about 550 Paper an 8.5-minute match, **about 4,000 Paper an hour**;
[pacing](../systems/economy-and-shop.md)) and to the shop (Paper packs give 15-20 Paper a Robux; 2x boosts 10 Robux for 15
minutes, 15 for 30; the cheapest chest 45 Robux):

| A player who plays today | Gets from the chart | About | Worth in the shop |
|---|---|---|---|
| 15 minutes (the median player) | 100 Paper, 5 min 2x XP | 10% on top of their Paper | about 9 Robux |
| 1 hour | 900 Paper, 10 min 2x XP, 15 min 2x Paper | 1,900 Paper (+48%) if they keep playing | about 70 Robux |
| 2 hours, the whole chart | 1,800 Paper, 20 min 2x XP, 15 min 2x Paper, 30 min 2x XP, the chest | 2,800 Paper (+35%) plus the chest (about 3,900 more on average: +80% in all) | about 145 Robux plus the chest (about 150), about $3.70 a player pays; about $1.10 to us |

The daily gift (100-300 Paper a day, a chest every 7th day in a row) stays as it is; the two add up. (Proposed first
with half the small boxes' Paper, 1,100 for the day; Alan chose "Bigger".)

**The treasure chest (decided 2026-11-25):** Alan first asked for "a few equal options or a spin wheel roll for good
prizes and a small chance at a Great prize". Two drafts were shown (pick one of three; a wheel with a 2% Legendary
skin); he chose a mix: "it's still a choice", sure prizes on each side and the wheel in the middle, and "let's just
remove the paper chest" from the wheel. [Decision](../decisions/2026-11-25-playtime-chest.md).

The chest opens and three choices rise out, left to right:

`[ 3,000 Paper ]   [ Spin the wheel! ]   [ 1 hour 2x Paper + 1 hour 2x XP ]`

The two sure prizes are equal in Alan's eyes. Spinning gives one of six prizes, odds printed on the wheel. Worth is what
the prize costs in our shop today (dollars at 400 R$ = $4.99):

| Wheel prize | Chance | Spinning every day, about | Paper price | Robux price | Dollars |
|---|---|---|---|---|---|
| 3,000 Paper | 30% | 2 days in 7 | 3,000 | no 3,000 pack; 150-198 in packs | $1.87-2.47 |
| 1 hour 2x Paper + 1 hour 2x XP | 27% | 1 day in 4 | about 4,000 extra over that hour of play | 50 | $0.62 |
| A Sticker chest | 25% | 1 day in 4 | 3,000 | 135 | $1.68 |
| 5,000 Paper | 10% | once in 10 days | 5,000 | 299 (the 5,000 pack) | $3.73 |
| A Blue Ribbon chest | 6% | once in 17 days | 6,500 | 295 | $3.68 |
| **Great:** a Golden Star chest | 2% | once in 7 weeks | 12,000 | 539 | $6.72 |

A spin averages about 3,900 Paper (about 150 R$), a little above the sure prizes. With the Paper chest gone the wheel
never pays less than a sure prize, so most kids will spin; the side cards are for a kid who wants that exact prize.
The 2% for the great prize is higher than the 0.1% other wheels use because ours turns once a day at most, not every
20 minutes. Boosts stay at 1 hour: 3 hours of 2x Paper a day would be a near-free copy of the 999 R$ "2x Paper forever"
pass for the players most likely to buy it.

*What other games do* (fan wikis and guides, unofficial): Bubble Gum Simulator Infinity's wheel gives a free spin every
20 minutes and sells more (19 R$ a spin): coins 45%, more coins 20%, potions and keys 14% and 10%, a mystery box 3%,
5 spins 2.9%, a rare pet 0.1% ([Roonby](https://roonby.com/2025/04/15/wheel-spin-guide-bubble-gum-simulator-infinite-rewards-location-and-how-it-works/),
[Ginx](https://www.ginx.tv/en/bgsi-wheel-spin-rewards-ticket-price)). Durian Garden: one free spin a day, its most
common prize about 31%, a jackpot 0.1% ([game.guide](https://www.game.guide/durian-garden/rewards)). Tower Defense
Simulator's playtime chests (5 to 120 minutes) hold rare towers at about 1%; Toilet Tower Defense's last crates, after
up to 6 hours, can hold units found nowhere else (links above).

*Rules:* earned without Robux, so Roblox needs no odds shown; ours shows them anyway. The decision promises impatient
players "a chest now instead of at the end of the chart": if that is ever sold, the wheel inside it makes it a paid
random item, so the odds are shown before buying and Roblox's eligibility check runs, as our chests already do.

Other games: Tower Defense Simulator gives playtime rewards at 5, 15, 30, 60, 90 and 120 minutes; Toilet Tower Defense
gives nine crates over up to 6 hours in one sitting ([TDS wiki](https://tds.fandom.com/wiki/Playtime_Rewards),
[Sportskeeda](https://www.sportskeeda.com/roblox-news/toilet-tower-defense-rewards-update-daily-rewards-toilet-man)).

**The treasure chest for buyers** (the idea of a chest earned by buying) becomes the chart's last box, earned by playing.
Nothing in the chart is tied to spending.

## Why not Roblox's own playtime package
Roblox's Engagement Rewards package forgets all progress when a player leaves ("Time tracking starts at 0 for each
session"), brings its own plain screen and does nothing about idle players
([docs](https://create.roblox.com/docs/resources/feature-packages/engagement-rewards)). The daily gift already does
the saving, the UTC day and the chest and boost prizes; the chart uses those.

## Questions for Alan
1. ~~The chest at 4 hours or 5~~: 4 hours, then 2. 2. ~~The prizes~~: bigger (the table above). 3. ~~What counts~~: all time in
the game except time away from the keyboard (all Alan, 2026-11-25).
4. ~~The treasure chest~~: sure prizes either side of a spin wheel (above).

## Build order (after his OK)
1. The rules (which boxes a number of seconds earns, the new day, one take per box) with unit tests: a Codex job (on
   Alan's ChatGPT plan; no other cost).
2. The server: count seconds in the game (pausing for idle players), save with the profile, take a box, give the prize through
   the daily gift's code.
3. The chart's look: two or three options built from our loaded art, put together in the scene, for Alan to pick
   before anything new is uploaded.
4. Check in Play; tests.

Back to [HOME](../HOME.md)
