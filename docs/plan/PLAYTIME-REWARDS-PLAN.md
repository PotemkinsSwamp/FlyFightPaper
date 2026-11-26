# Playtime rewards plan

**Status:** how it works and the chart's prizes approved (2026-11-25); the treasure chest's design open. His words: "lets tackle playtime rewards and we will bundle it
with the treasure chest because at the end of the playtime rewards you could get a treasure chest". The idea and his
first numbers: [ideas](IDEAS.md) (playtime rewards, treasure chest for buyers).

**Alan's changes to the first draft (2026-11-25):** the chest comes much later, "probably like 4-5 hours of total
playtime for the day"; "large rewards at every hour mark and then small rewards between", three between every hour mark.
Before the prizes are set: "we really have to consider how much we give away and whats worth the player retention vs
what we give away because we also want people to pay with robux, but also we need to look at how much player retention
is worth and what it pays us in the long game. after that we can consider whats in the chest." (The first draft had five
boxes from 5 minutes to a chest at 2 hours.)

**Settled (Alan 2026-11-25):** "chest at 4 hours"; prices shown are always real ([decision](../decisions/2026-11-25-real-prices-only.md)).

## What the player sees
A **sticker chart** for today, like the ones on a classroom wall: a row of boxes for each hour, each box with its time
and its prize. Playing fills the chart; when a box's time is reached it gets a gold star sticker and a "!" shows on its
menu strip. Tap the box to take the prize. The hour boxes are bigger, with bigger prizes; the last one is a **treasure
chest**. When the chart is full: "Come back tomorrow for a new chart."

- On the main menu: a **Playtime** strip with the others (Shop, Missions, Emotes) shows the next box and how long to go.
- In a match: a small paper note when a sticker is earned ("Sticker earned! Take it from the menu."). The prize is taken
  from the menu, also the in-match menu.

## Rules
- **What counts:** minutes in a match (flying, or at your desk between lives). Menus don't count, and nor does a
  player who has touched nothing for 2 minutes (counting starts again at the next touch). That stops kids leaving the
  game running in a menu for a chest.
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
   sittings, and 5 hours is a very long day for a kid. Recommended: **4 hours**.

## What the chart gives away (approved 2026-11-25: "Bigger", the small boxes' Paper doubled)
Sixteen boxes over 4 hours: three small ones every 15 minutes, a big one at each hour (★). The prizes grow through the day.

| Hour | :15 | :30 | :45 | ★ the hour |
|---|---|---|---|---|
| 1 | 100 Paper | 5 min 2x XP | 100 Paper | **15 min 2x Paper** |
| 2 | 150 Paper | 5 min 2x XP | 150 Paper | **400 Paper** |
| 3 | 200 Paper | 5 min 2x XP | 200 Paper | **30 min 2x XP** |
| 4 | 250 Paper | 5 min 2x XP | 250 Paper | **Treasure chest** (see below) |

How much that is, next to what playing earns (about 550 Paper an 8.5-minute match, **about 4,000 Paper an hour**;
[pacing](../systems/economy-and-shop.md)) and to the shop (Paper packs give 15-20 Paper a Robux; 2x boosts 10 Robux for 15
minutes, 15 for 30; the cheapest chest 45 Robux):

| A player who plays today | Gets from the chart | About | Worth in the shop |
|---|---|---|---|
| 15 minutes (the median player) | 100 Paper | 10% on top of their Paper | 6 Robux |
| 1 hour | 200 Paper, 5 min 2x XP, 15 min 2x Paper | 1,200 Paper (+30%) if they keep playing | 25 Robux |
| 4 hours, the whole chart | 1,800 Paper, 20 min 2x XP, 15 min 2x Paper, 30 min 2x XP, the chest | 2,800 Paper (+18%) plus the chest | about 145 Robux plus the chest (about $1.80 a player pays; about 55 cents to us) |

The daily gift (100-300 Paper a day, a chest every 7th day in a row) stays as it is; the two add up. (Proposed first
with half the small boxes' Paper, 1,100 for the day; Alan chose "Bigger".)

**The treasure chest (open):** Alan 2026-11-25: "its a treasure chest, we could either do a few equal options or a spin
wheel roll for good prizes and a small chance at a Great prize". Next: draft both (a pick-one of a few equal prizes; a
wheel of good prizes with a small chance of a great one), each with real prizes and their worth, for his pick. Earned
without Robux, so Roblox needs no odds shown, but the wheel shows its odds like our chests do; if a wheel spin is ever
sold for Robux, every prize and its exact odds must be shown first.

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
1. ~~The chest at 4 hours or 5~~: 4 hours. 2. ~~The prizes~~: bigger (the table above). 3. ~~What counts~~: match time
only (all Alan, 2026-11-25).
4. The treasure chest: a few equal prizes to pick from, or a spin wheel (drafts of both to come).

## Build order (after his OK)
1. The rules (which boxes a number of seconds earns, the new day, one take per box) with unit tests: a Codex job (on
   Alan's ChatGPT plan; no other cost).
2. The server: count match seconds (pausing for idle players), save with the profile, take a box, give the prize through
   the daily gift's code.
3. The chart's look: two or three options built from our loaded art, put together in the scene, for Alan to pick
   before anything new is uploaded.
4. Check in Play; tests.

Back to [HOME](../HOME.md)
