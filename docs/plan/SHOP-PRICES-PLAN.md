# Shop prices plan

**Status:** approved 2026-11-11 (Alan: "build it, pencil at 1,699"); pack amounts built. Nothing on sale yet. The shop step from the
[unlock ladder decision](../decisions/2026-11-08-unlock-ladder-and-bot-builds.md): Paper prices went up a lot on
2026-11-08 (parts 700-32,000), so the Robux side has to follow. Replaces the Paper pack and early unlock rows of the
[draft price ladder](../research/PRICING-RESEARCH-2026-10-18.md) once approved. Nothing is on sale either way.

## What a match pays now (from `config/economy.json`, rough)
About 370 Paper for a weak player (6 folds), 660 for an average one (12), 1,240 for a really good one (25). A match
with the break is about 8.5 minutes, so about 7 matches an hour. Everything in the game costs 167,400 Paper (about 36
hours for an average player).

## Paper packs (Robux prices kept; more Paper in each)
| Pack | Was | Now | Paper per Robux | Average matches |
|---|---|---|---|---|
| 99 R$ (about $1.25) | 1,000 | **1,500** | 15.2 | 2.3 |
| 299 R$ (about $3.75) | 3,500 | **5,000** | 16.7 (+10%) | 7.6 |
| 799 R$ (about $10) | 10,000 | **15,000** | 18.8 (+24%) | 23 |

Bigger packs give a bit more per Robux, like Roblox's own Robux packs. The small one buys any level 2-5 part; the big
one a Racing Fold or Guided Eraser with some left over.

## Early part unlocks (Robux, one product per part)
Buying a part with Robux skips its level and its Paper, and a prestige takes it back like any part. Price: its Paper
price at the big pack's rate (about 18.75 Paper a Robux), rounded to a usual Roblox price.
| Paper price | Parts | Robux |
|---|---|---|
| 700 | Needle Nose, Swept Wings, Split Tail | 49 |
| 1,200-1,600 | Blunt Nose, Broad Wings, Ridge Tail, Elastic Booster, Swift Fold | 79 |
| 2,100-2,500 | Rubber Band, Spitball, Crayon, Long Point, Delta Wings, Wide Tail | 129 |
| 3,500-4,000 | Toilet Roll Gunship, Precision Paperclip | 199 |
| 4,800-6,000 | Spool Booster, Compact Nose, Cardstock Wings, Guide Fin, Courier Fold | 279 |
| 8,500 | Tape Nose, Feather Folds, Tape Tail | 449 |
| 11,000-13,000 | Racing Fold, Guided Eraser, Twin Elastic Booster | 599 |
| 18,500 | Cardboard Gunship | 999 |
| 32,000 | Pencil Launcher | 1,699 |

All 29 together: about 8,950 R$ (about $110), close to buying their Paper in big packs. The free weapons (Pellet,
Popper, Staple, Thumbtack) need no product: their three old ones come out of `config/commerce.json`.
Alan chose the Pencil at 1,699 (its Paper value; it's the strongest weapon, so a high price keeps "buy the best gun on
day one" rare).

## Unchanged
2x XP / 2x Paper boosts 25 / 45 / 79 / 199 / 299 R$ for 15 / 30 / 60 / 180 / 300 minutes; permanent 2x Paper 999, 2x
XP 1,499. An hour of 2x Paper gives an average player about 4,650 extra Paper for 79 R$, much more than a pack, but
only if they play: it rewards playing, as before.

## How it's built (cheap)
- `config/commerce.json`: the three packs' amounts (keys `paper_pack_1500/5000/15000`, tests updated); the Studio practice
  shop shows these Robux prices.
- The Robux prices are typed in on Roblox when you create the products (Roblox can lower them by region); I'd write
  you the exact list then. Nothing goes on sale until you create the products and say go.
- Next, each with its own picture for your OK first: the Hangar's "Unlock now" button (with "a prestige takes this
  back"), the shop screen, and the goal offers ("2x Paper gets you the Toilet Roll 3 matches sooner", capped, never
  after a loss).

## Cost
Opus (me) only, about 30 minutes; no Codex, no bot matches, nothing paid.

Back to [HOME](../HOME.md)
