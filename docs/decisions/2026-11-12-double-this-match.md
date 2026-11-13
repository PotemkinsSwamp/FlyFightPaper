# Double this match on the report card; cheaper 2x boosts

**Decided:** 2026-11-12 (Alan, after his report-card playtest)
**Status:** built 2026-11-12 ([economy and shop](../systems/economy-and-shop.md#products), [report card](../systems/menus-and-hud.md)); seen working in Alan's Play 2026-11-12 ([playtest](../playtests/2026-11-12-double-this-match-and-shop.md)). Prices are for when live sales are switched on;
Studio uses practice buys.

## Decision
- **Double this match** replaces the report card's 2x Paper button: pay once to get the Paper **and** XP you earned this
  match a second time. Shown only when you earned at least 75 Paper, only while the report card is up (a timer runs
  down on the button), once per match; it counts as one of the 3 buys a day. The server locks the amounts when you
  press it; a buy that goes through always pays, even if the window has closed.
- **Worth:** the Paper at the shop's Paper-pack price (about 15 Paper per Robux) plus the XP counted as worth the same
  as the Paper (2x XP and 2x Paper boosts cost the same). So worth = 2 x Paper / 15 R$.
- **Price: 25% off the worth**, rounded to the nearest price step: round numbers under 50 (10, 15, 25, 35), ending in 9
  from 49 up (49, 69, 99, 149, 199, 249, 299). Examples: 90 Paper -> 10 R$ (worth 12); 250 -> 25 (33); 500 -> 49 (67);
  1,000 -> 99 (133); 2,000 (about 40 folds) -> 199 (267). Each step is its own Roblox product.
- **How it shows:** no crossed-out price. A "Worth N R$!" sticker propped at an angle on the button, popping in with a
  bounce when the card comes up, then gently shrinking and growing so it catches the eye.
- **2x boosts (Paper and XP) get new prices** so the order holds (15 minutes worse than Double this match, 30 minutes
  about equal, longer ones better): 15 min 10 R$ (was 25), 30 min 15 (45), 1 hour 25 (79), 3 hours 69 (199), 5 hours
  99 (299). Their clocks still run while online (menus too).

- **The 75-Paper minimum stays** (Alan 2026-11-12, after a 36-Paper match showed no button): below it the cheapest
  price is worth more than what you'd get.

## Why
Alan: a 15-minute boost covers about 1.5 matches for 79 R$-class prices, "not worth it", and a player would see that
(boosts paid 5-10 Paper per Robux against 15-20 for Paper packs). Doubling the match you just played sells the moment
you're looking at your number, the timer makes it a now-or-never deal, and the price scales with how well you did.
He asked for prices that don't end on odd numbers like 19; charm prices ending in 9 are kept where they cross 50/100/200.

Back to [decisions](README.md)
