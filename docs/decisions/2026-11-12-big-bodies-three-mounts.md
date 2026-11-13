# Big bodies get 3 mounts; Cardboard carries 10, Toilet Roll 8

**Decided:** 2026-11-12 (Alan, after playing: the big planes are still too strong)
**Status:** built 2026-11-12 ([planes and Hangar](../systems/planes-and-hangar.md)); not yet seen in Play by Alan.
Bot match 2026-11-12 (3 matches, `tools/run_bot_matches.py`): the tanks no longer dominate. Experienced bots per match:
Cardboard 8 kills / 9.5 deaths, Toilet Roll 9.3 / 10, against Tack Skirmisher 14 / 8.3 and Popper Dart 9 / 8.3; the
Spitball builds stay weakest (Hunter 6.6 / 9.4, Popper 3 / 8.6). One ace Cardboard had 17 kills, but aces top every
build (the Popper Dart ace had 14-15 each match).

## Decision
- The **Cardboard Gunship** and the **Toilet Roll Gunship** both get three mounts: heavy, heavy, medium (were six and
  five).
- **Capacity:** Cardboard up from 8 to **10**, so two Pencils fit, or two Crayons and a light or medium gun. Toilet Roll
  up from 7 to **8**: two Crayons, or one Pencil and a medium gun, never two Pencils. Alan leaned to 8 ("might be fair",
  9 was the other choice); it's one number in `config/catalog.json`.
- What sets them apart: the Cardboard carries the most (two of the biggest guns) and is the toughest and slowest; the
  Toilet Roll is cheaper, earlier, faster and turns better, but carries one big gun at most.
- Saved builds with more guns keep the guns that fit, in order. The fixed planes keep their guns: Bomber a Crayon and two
  Pellets, Carrier three Pellets. Tank bots: Toilet Roll three Pellets, Cardboard two Crayons and a Pellet.

## Why
Alan: fewer guns, not less carrying room, is what takes the big planes down; weight still decides which big guns fit.

Back to [decisions](README.md)
