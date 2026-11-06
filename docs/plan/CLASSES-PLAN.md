# Classes, new weapons and mastery plan

Alan's answers are in (2026-11-06, [decision](../decisions/2026-11-06-classes-and-mastery.md)); building starts at step 1. It serves
[the beta has to feel like a finished game](../decisions/2026-11-06-beta-feels-finished.md). Winners' circle and emotes,
skins and the shop get their own plans after this one.

## What Alan decided
- Six ready-made class planes: three open at the start, the other three unlocking up to about level 10.
- Class planes are separate from a player's saved builds, in their own area, like a shooter's game loadouts under your
  own. No part of one can be changed or copied into a build. Skins and trails can apply to them later.
- They carry low-tier weapons, at most two paperclips, and never an eraser.
- The Carrier needs care: lots of small guns is a big advantage even on a slow plane.
- New weapons: Hole Punch, Stubby Crayon, Spitball, Thumbtack. No mini eraser.
- Spitball has a very high drop-off and weighs its target down: their Lift falls faster.
- Building your own plane has no extra gate: it starts once you've unlocked parts.
- Mastery for each class, weapon and part: a long-term goal that never makes long-time players overpowered.
- Bots have no mastery.

## The six classes
Speed, Health, Turn and Lift are measured from the game's own stat rules with today's parts and weapons. Crayons and
Thumbtacks don't exist yet, so those rows used stand-ins and will shift a little. All are first tuning.

| Class | Opens | Job | Parts | Weapons | Speed | Health | Turn | Lift |
|---|---|---|---|---|---:|---:|---:|---:|
| Fighter | Level 1 | All-rounder | Classic Fold, classic parts | 2 Pellets, 1 Thumbtack | 106 | 120 | 116 | 88 |
| Striker | Level 1 | Fast glass cannon | Swift Fold, Needle Nose, Swept Wings | 2 Staples, Elastic Booster | 150 | 79 | 136-141 | 96 |
| Scout | Level 1 | Stays up longest, good for holding the zone | Courier Fold, Broad Wings, Ridge Tail | 1 Rubber Band, Elastic Booster | 98 | 140 | 105-123 | 107 |
| Marksman | Level 5 | Few shots, must aim | Classic Fold, Ridge Tail | 2 Paperclips | 110 | 128 | 110-114 | 89 |
| Bomber | Level 8 | Big slow hits | Toilet Roll Gunship, Blunt Nose | 2 Stubby Crayons, 2 Pellets | 65 | 316 | 77 | 71 |
| Carrier | Level 10 | Huge health, many small guns | Cardboard Gunship | 4 Pellets | 64 | 330 | 73 | 77 |

- **Pace:** levels 5, 8 and 10 take 1,040, 2,240 and 3,240 XP. At a guessed 600 XP a match, that's a new class about
  every 2 rounds. Step 1 measures the real XP per match, and these levels move if it's off.
- **Carrier guns:** 4 Pellets is twice the damage of the starter plane if every shot lands, on a very slow, very big
  target. Bot matches decide if it stays at 4 or drops to 3.

## Why people still level up
1. **Class planes are good, never the best.** Each has a weak spot, and only your own build can fix it.
2. **Levels unlock parts and weapons** for your own builds, including the eraser and pencil that no class carries.
3. **Mastery** keeps every weapon and plane improving after it's unlocked.

## New weapon ladder
Ten weapons, eight of them by level 12 (today: four). Damage figures are first guesses; each gun does about what a
Pellet gun does in the right situation, or less. Prices follow the ladder.

| Level | Weapon | How it plays |
|---|---|---|
| 1 | Pellet | Today's |
| 2 | **Hole Punch** (new) | Short-range scatter of paper dots |
| 3 | Staple | Today's |
| 4 | **Thumbtack** (new) | Steady single shots |
| 6 | **Stubby Crayon** (new) | A small, slow, heavy hit, a taste of the Pencil |
| 7 | Rubber Band | Today's |
| 9 | **Spitball** (new) | Short reach with a very high drop-off. A hit makes the target's Lift fall faster for a few seconds (repeat hits restart the timer and don't stack) |
| 12 | Paperclip | Today's |
| 22 | Eraser | Today's; still limited to two in the air per pilot |
| 40 | Pencil | Today's |

## Mastery
- **Earned by playing:** a weapon by hits and folds with it, a part by flying and fighting with it. Folds on bots count
  the same as folds on people (VISION), but bots themselves have no mastery.
- **Ten ranks each, slow on purpose.** First guess, tuned after step 1: rank 1 after about 8 matches with that weapon
  or part, rank 5 after about 100, rank 10 after about 500.
- **The first rank is the big one, the rest are small:** the full ceiling is +10% on any one stat.

| Rank | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Total bonus | +5% | +5.6% | +6.1% | +6.7% | +7.2% | +7.8% | +8.3% | +8.9% | +9.4% | +10% |

- **Rank 1 feels like an event:** a "Mastered!" card after the match and a star on the weapon or part in the Hangar.
- **Prestige opens the top ranks:** ranks 1-5 are open to everyone. Each prestige opens one more rank, so rank 10 needs
  prestige 5. Mastery stays through prestige.
- **Never for Robux:** 2x XP doesn't speed it up, and it can't be bought.
- **Not earned in the Range or lessons.**

| Mastery of | Improves |
|---|---|
| Pellet, Staple, Thumbtack, Rubber Band | Range, bullet speed |
| Hole Punch | Range, tighter scatter |
| Stubby Crayon | Reload, shot speed |
| Spitball | Range, how long the weight lasts |
| Paperclip | Range, bullet speed |
| Eraser | Speed, flight time, faster lock |
| Pencil | Shot speed, reload |
| Any weapon's last level | A little more damage (none on the Pencil, which already folds most planes in one hit) |
| Nose | Speed |
| Wings | Left and right handling |
| Tail | Up and down handling |
| Body | Lift |

**Classes and parts together:** mastery is stored per part, and a class plane is made of parts. So flying the Striker
raises its parts' mastery, the class's mastery bar shows their progress, and that progress carries into your own
builds. Class mastery also earns rewards at each level (titles first, skins and emotes once they exist).

**Fairness watch:** long-time players fly slightly better planes than new players; the ranks' small steps and the
ceiling keep that gap small. Alan's eraser worry: no class carries one, and matches get watched for eraser spam once
more people reach level 22.

## Build steps
Each step ends in something Alan can try.

1. **Measure:** real XP per match from a bot match. Settle the class levels and mastery pace.
2. **Classes with today's weapons:** a class row on the Hangar shelf, locked ones showing their level, and the server
   lets a class plane fly with parts you don't own. Stand-in weapons until step 3. No new art. Tests first.
3. **Four new weapons:** rules and tests, then models (Creator Store first, then Codex Blender, Meshy last), sounds,
   kill-feed lines and hangar cards. Alan sees the assembled models before any upload.
4. **New unlock ladder:** new weapon levels and prices, a reward at every level up to about 15, and a clear
   "you unlocked" moment after a match. Tutorial and bots updated to match.
5. **Mastery:** save change (needs old servers shut down at publish), the earning rules, the stat changes on the
   server, and the Hangar's mastery bars. Codex can build and test the pure rules; Claude reviews.
6. **Bot skill follows the lobby:** bots match the lobby's average level, weighted towards its lower-level players, so
   one level 50 among level 1s doesn't bring veterans. Today a room's bots come from whether its players have
   graduated from rookie rooms (after 5 matches), not their levels.
7. **Balance pass:** bot matches with every class, then Alan's playtest.

**Cost:** free so far. New models try free Creator Store items first; Meshy would use existing credits and only with
Alan's go, like every upload.
