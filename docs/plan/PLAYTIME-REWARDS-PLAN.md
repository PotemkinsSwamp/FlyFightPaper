# Playtime rewards plan

**Status:** how it works, waiting on Alan (2026-11-25). His words: "lets tackle playtime rewards and we will bundle it
with the treasure chest because at the end of the playtime rewards you could get a treasure chest". The idea and his
first numbers: [ideas](IDEAS.md) (playtime rewards, treasure chest for buyers).

**Alan's changes to the first draft (2026-11-25):** the chest comes much later, "probably like 4-5 hours of total
playtime for the day"; "large rewards at every hour mark and then small rewards between", three between every hour mark.
Before the prizes are set: "we really have to consider how much we give away and whats worth the player retention vs
what we give away because we also want people to pay with robux, but also we need to look at how much player retention
is worth and what it pays us in the long game. after that we can consider whats in the chest." The box table below is
the first draft, replaced once that is weighed.

## What the player sees
A **sticker chart** for today, like the ones on a classroom wall: five boxes in a row, each with its time and its prize.
Playing fills the chart; when a box's time is reached it gets a gold star sticker and a "!" shows on its menu strip. Tap
the box to take the prize. The last box is a **treasure chest**. When the chart is full: "Come back tomorrow for a new
chart."

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

## Rewards
Alan's times (5 minutes, 10, 30, an hour, 2 hours), the chest last:

| Box | Playing today | Prize |
|---|---|---|
| 1 | 5 minutes | 100 Paper |
| 2 | 10 minutes | 15 minutes of 2x XP |
| 3 | 30 minutes | 250 Paper |
| 4 | 1 hour | 15 minutes of 2x Paper |
| 5 | 2 hours | **Paper treasure chest** (you pick Skins or Trails when you open it, like the daily gift's chests) |

How big that is: an average match is about 8.5 minutes and pays about 430 Paper
([economy check](../systems/economy-and-shop.md#reference-economy-check)), so 2 hours of play earns about 6,000 Paper.
The chart adds 350 Paper, two boosts (the Paper one is worth about 800 Paper over two matches) and a chest that sells for
1,000 Paper: roughly a third more on a long day, about 40% more in the first 5 minutes. The daily gift (100-300 Paper a
day, a chest every 7th day in a row) stays as it is; the two add up.

Other games: Tower Defense Simulator gives playtime rewards at 5, 15, 30, 60, 90 and 120 minutes; Toilet Tower Defense
gives nine crates over up to 6 hours in one sitting ([TDS wiki](https://tds.fandom.com/wiki/Playtime_Rewards),
[Sportskeeda](https://www.sportskeeda.com/roblox-news/toilet-tower-defense-rewards-update-daily-rewards-toilet-man)).
Ours ends at 2 hours: long enough to be a goal, not a reason to stay all evening.

**The treasure chest for buyers** (the idea of a chest earned by buying) becomes this chest, earned by playing. Nothing
in the chart is tied to spending, and its odds are the ones the Paper chest already shows.

## Why not Roblox's own playtime package
Roblox's Engagement Rewards package forgets all progress when a player leaves ("Time tracking starts at 0 for each
session"), brings its own plain screen and does nothing about idle players
([docs](https://create.roblox.com/docs/resources/feature-packages/engagement-rewards)). The daily gift already does
the saving, the UTC day and the chest and boost prizes; the chart uses those.

## Questions for Alan
1. The last box is today's Paper chest (the cheapest chest: mostly Common, sometimes Rare, a tiny chance of more). Or
   a better chest on some days?
2. Only time in matches counts (menus don't). OK?
3. Are the five prizes and amounts above OK?

## Build order (after his OK)
1. The rules (which boxes a number of seconds earns, the new day, one take per box) with unit tests: a Codex job (on
   Alan's ChatGPT plan; no other cost).
2. The server: count match seconds (pausing for idle players), save with the profile, take a box, give the prize through
   the daily gift's code.
3. The chart's look: two or three options built from our loaded art, put together in the scene, for Alan to pick
   before anything new is uploaded.
4. Check in Play; tests.

Back to [HOME](../HOME.md)
