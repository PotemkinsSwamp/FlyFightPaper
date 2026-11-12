# Shop money plan: the funnel

**Status:** for Alan's OK (2026-11-12). Nothing built. Every number below is new and needs his OK. Builds on his
[personal shop picks](../decisions/2026-11-12-personal-shop-picks.md) and the
[shop prices plan](SHOP-PRICES-PLAN.md) (packs, part prices and boosts stay as approved unless a line here changes them).

## The idea in one line
Walk a player from **free** to **a first small buy** to **buying for a goal** to **a bigger buy**, and give a reason
to come back and buy again. Each step below is one tool on that path; Alan ticks the ones he wants.

## 1. Free: get them into the shop
- [ ] **Free daily gift (J), a 7-day row of gifts.** Day 1: 100 Paper. Day 2: 150. Day 3: **15 minutes of 2x XP**.
  Day 4: 250. Day 5: 300. Day 6: **15 minutes of 2x Paper**. Day 7: 1,000 Paper. Then it starts again. A missed day
  doesn't reset the row (you just carry on). *The trick:* days 3 and 6 are free tastes of the boosts, so a player
  feels 2x once before being asked to pay for it. (A whole week is about 1,800 Paper: a bit under 3 average matches.)
- [ ] **Your next part on the Featured card (F)** and **Today's parts (H)**: three parts from your next levels,
  changing every day at the same time for everyone, each with its Paper price and "Unlock now".

## 2. The first buy (the hard one)
- [ ] **Starter pack (A) at 99 R$** (Swept Wings, 1,500 Paper, 1 hour 2x XP; worth 227 R$ bought apart, so "56% off"
  is true). Only for players who haven't bought anything; a real 3-day timer, one buy only. 99 R$ is the bottom of
  Roblox's 99-299 range: the cheapest first step. (149 R$ would still be 34% off, if Alan wants more per sale.)
- [ ] **First buy of each Paper pack: double Paper (B).** A "First buy: double!" sticker on each pack until you've
  bought it once (1,500 becomes 3,000, 15,000 becomes 30,000). Every pack gets one first buy, so this pulls players up
  the ladder: having bought the small one, the next pack still has its double waiting.

## 3. Buying for a goal
- [ ] **The right pack on a failed buy (G):** the "Not enough Paper" pop-up (built in Studio, waiting for Alan's look)
  shows the smallest Paper pack that covers the gap, beside "Unlock now".
- [ ] **After a match (win or lose, Alan: offers that fit):** on the report card, under the Paper you earned, a line
  "**2x Paper would have given you +420 more**" (that match's real number) with a small 2x Paper button
  (1 hour, 79 R$). Only when no 2x Paper is running. The same for XP when a level is close: "2x XP: level 13 in about 2
  matches instead of 4". *The trick:* the player sees the exact reward they missed, from their own match.
- [ ] **On the fold screen (N), no price:** "Folded by Mia's Thumbtack Shooter. It unlocks at level 4." It plants a
  goal the shop's Featured card picks up. (No buy button there: the plane respawns in 4 seconds and a Roblox buy
  takes longer than that.)

## 4. The bigger buy: decoy and anchor packs
- [ ] **A decoy pack.** Add **549 R$ for 7,500 Paper** between the 299 and 799 packs. It's a worse deal per Robux
  (13.7 Paper a Robux) than the packs around it (16.7 and 18.8), so it isn't really for buying: next to it, 799 R$ for
  15,000 looks like "250 Robux more for double the Paper", and that's the pack we want sold. (The well-known
  "decoy effect": [GameAnalytics](https://www.gameanalytics.com/blog/5-effective-behavioural-economic-monetization-patterns);
  [Adrian Crook](https://adriancrook.com/5-psychological-pricing-tactics-for-freemium-games/).) Its sticker: none;
  the 799 pack keeps "Most Value" (true).
- [ ] **An anchor pack, shown first.** Add **1,999 R$ for 40,000 Paper** ("Mega Box", 20 Paper a Robux, the best rate),
  and list packs biggest first, so the first price a player sees is the big one and the others feel cheap next to it.
  A few will buy it; for the rest it's the anchor.
- Stickers stay true: "Best value" only where the maths says so, no "Most popular" until real sales show it.

## 5. Coming back to buy again
- [ ] **Paper jar (a piggy bank).** While you play, an extra 25% of the Paper you earn drops into a jar (up to 10,000).
  Break the jar for 199 R$ and it's all yours; then it starts filling again. *Why:* it rewards playing, and the more
  someone plays, the better the deal looks. 40 of the top 100 mobile games have one
  ([GameRefinery](https://www.gamerefinery.com/boost-your-monetization-with-iap-mechanics/);
  [Heroic Labs](https://heroiclabs.com/blog/understanding-piggy-bank-mechanics-mobile-games/)). In our look: a glass
  jar of paper scraps on the shop's Featured shelf, filling up.
- [ ] **A chain of offers (later).** A row of steps: free, free, paid (99), free, free, paid (299)...; each paid step
  opens the free ones after it. Sensor Tower reports about 20% more repeat buying from these
  ([report](https://sensortower.com/report/how-to-build-an-effective-offer-system-in-your-game)). Bigger build: after
  the shop is live and the simpler tools show what sells.
- [ ] **No more offers after 3 buys in a day (P):** the shop still works; only the pop-ups and lines stop.

## What stays fixed
Roblox's rules (real timers, real sales, Roblox's own confirm on every buy), prices read from Roblox when live, and
nothing sold that can't be bought by everyone at the price shown.

## Build order (if all ticked)
Daily gift and starter pack first (the free and first-buy steps), then first-buy double and the new packs (small
changes to the shop and `config/commerce.json`), then the report-card line, then the Paper jar. Each piece gets a
look in Studio before Alan plays it. New Roblox products (decoy, anchor, jar) are created by Alan on Roblox when he
says go.

## Cost
Planning: Opus only, about 20k tokens. Building: mostly Opus; the jar and daily-gift saving rules are a good Codex job
(on Alan's ChatGPT plan) with unit tests.

Back to [HOME](../HOME.md)
