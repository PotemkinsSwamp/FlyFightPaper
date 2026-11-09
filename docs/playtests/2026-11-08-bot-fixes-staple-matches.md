# 2026-11-08 (night): bot fixes, the Staple, and new veteran builds (bot matches)

## What Alan did
Gave the go for one-minute checks and three-match runs, bots only (one Ace per three veterans, his plane at the desk,
muted), run by `tools/run_bot_matches.py`. Made the calls between runs: the Crayon Tank was a bad build (Staple Tank
instead), bots are the balance test, the Staple was too strong, Spitball builds belong on a medium plane, fix the ducts.

## What he saw
- **Fixes before the runs:** the Crayon Tank turn-fights; bots' guns meet at the target's distance (they met at 150
  studs, so wing guns missed past it). First one-minute check: Aces hit 33-37%, veterans 15-26% on the same planes.
- **Run 1 (Staple Tank, old Staple):** veterans 9.0 folds a match (Staple Tank 14.2, Tack Skirmisher 9.8, Popper Dart
  8.3, Spitball Hunter 3.7); Aces 12.8. One Ace spent 35-40% of every match in the ducts.
- **Run 2 (Staple at a Pellet's 13.3 a second, ~800 studs):** veterans 8.1 (Staple Tank 12.2, Tack 8.5, Popper 8.3,
  Spitball Hunter 3.3); Aces 10.2.
- **Run 3 (plus Spitball Hunter and Spitball Popper on a medium plane, short duct trips only):** no script errors.

| Plane | Veterans: folds a match (avg) | Aces |
|---|---|---|
| Staple Tank | 19, 16, 17, 10, 14 (15.2) | 19 |
| Tack Skirmisher | 19, 8, 13, 11 (12.8) | 13, 23 |
| Popper Dart | 8, 3, 7, 9, 12 (7.8) | 11 |
| Spitball Hunter (Rubber Bands) | 4, 5, 3, 5, 4, 5 (4.3) | 4, 6 |
| Spitball Popper | 2, 2, 2, 0 (1.5) | 1, 2, 2 |

- Veterans averaged 1,074 points a match (about 131 a fold): ~480 Paper and ~850 XP with the finishing bonus, before
  win and podium bonuses. Aces beat veterans on every plane (by 15-45%); their overall average (9.0) is low only
  because 5 of their 9 seats drew the two Spitball builds.
- Still wrong: some Aces spent 109-145 s of the 470 in the ducts even with short trips only (the fix limits how often a
  run starts, counted from its start, not how long one takes).

## What changed because of it
- Built: Staple Tank, Staple nerf, Spitball builds, duct limits ([bots](../systems/bots.md),
  [weapons](../systems/weapons.md), [decision](../decisions/2026-11-08-unlock-ladder-and-bot-builds.md)).
- Open: the duct time; the Staple Tank is still the strongest plane and both Spitball builds the weakest (balance
  pass, Alan: later).
