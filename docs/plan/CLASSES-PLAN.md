# Classes, new weapons and mastery plan

**Words (Alan 2026-11-06):** players see **presets** (the six fixed planes, called classes on this page) and **loadouts**
(their own builds). In the code `class` is a preset and `preset` is a saved loadout, because the save keeps its field names.

Alan's answers are in (2026-11-06, [decision](../decisions/2026-11-06-classes-and-mastery.md)); building starts at step 1. It serves
[the beta has to feel like a finished game](../decisions/2026-11-06-beta-feels-finished.md). Winners' circle and emotes,
skins and the shop get their own plans after this one.

## What Alan decided
- Six ready-made class planes: three open at the start, the other three unlocking up to about level 10.
- Presets are separate from a player's loadouts: the Hangar has a tab for each, and the desk menu's "Switch to presets"
  button flips the cork strip over to the six of them. No part of one can be changed or copied into a loadout. Skins and
  trails can apply to them later.
- They carry low-tier weapons, at most two paperclips, and never an eraser.
- The Carrier needs care: lots of small guns is a big advantage even on a slow plane.
- New weapons: Point Popper, Stubby Crayon, Spitball, Thumbtack. No mini eraser. How each plays, and that every shot
  falls past its range: [the 2026-11-07 decision](../decisions/2026-11-07-four-new-weapons-and-falling-shots.md).
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
| Scout | Level 1 | Stays up longest, good for holding the zone | Courier Fold, Broad Wings, Ridge Tail | 2 Rubber Bands, Elastic Booster | 96 | 140 | 103-121 | 105 |
| Marksman | Level 5 | Few shots, must aim | Classic Fold, Ridge Tail | 2 Paperclips | 110 | 128 | 110-114 | 89 |
| Bomber | Level 8 | Big slow hits | Toilet Roll Gunship, Blunt Nose | 1 Stubby Crayon, 2 Pellets | 65 | 316 | 77 | 71 |
| Carrier | Level 10 | Huge health, many small guns | Cardboard Gunship | 4 Pellets | 64 | 330 | 73 | 77 |

- **Pace:** levels 5, 8 and 10 take 1,040, 2,240 and 3,240 XP. The first measured match gave about 340 XP a pilot
  ([numbers](../playtests/2026-11-07-bot-match-xp-and-rams.md)), so a new class about every 3 rounds, not the guessed
  2. Levels stay as they are until a real player's numbers say otherwise.
- **Carrier guns:** 4 Pellets is twice the damage of the starter plane if every shot lands, on a very slow, very big
  target. Bot matches decide if it stays at 4 or drops to 3.

## Why people still level up
1. **Class planes are good, never the best.** Each has a weak spot, and only your own build can fix it.
2. **Levels unlock parts and weapons** for your own builds, including the eraser and pencil that no class carries.
3. **Mastery** keeps every weapon and plane improving after it's unlocked.

## New weapon ladder
Ten weapons, eight of them by level 12. The order, levels and which are free:
[the 2026-11-08 decision](../decisions/2026-11-08-unlock-ladder-and-bot-builds.md). How each plays:
[the 2026-11-07 decision](../decisions/2026-11-07-four-new-weapons-and-falling-shots.md). Prices come from step 4c.

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
| Point Popper | Range, tighter scatter |
| Stubby Crayon | Reload, shot speed |
| Spitball | Range, how long the spitballs stick |
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
3. **Four new weapons:** rules and tests, then models (stand-ins from our own models to test; then a Codex picture and a Codex Blender model, no Meshy), sounds,
   kill-feed lines and hangar cards. Alan sees the assembled models before any upload.
4. **New unlock ladder** (Alan's answers: [decision](../decisions/2026-11-08-unlock-ladder-and-bot-builds.md)). In order:
   a. The new weapon order on the Gear sheet and the ladder; the first four free at their level, the rest paid.
   b. Veteran bot builds made with reason; rookies and regulars on the presets (not the Marksman); no Paperclip,
      Eraser or Pencil on bots.
   c. Measure: a few all-veteran bot matches (Alan's go) for Paper and XP a match, plus research on how other games
      pace unlocks. Then set levels, prices and level gifts so unlocking is a grind (Alan's OK on the numbers).
   d. The "you unlocked" moment: backpack concept picture for Alan's OK, then build it.
   e. Tutorial line: "New weapons and parts open up as you level. Some are free; the rest cost Paper." 
5. **Mastery:** save change (needs old servers shut down at publish), the earning rules, the stat changes on the
   server, and the Hangar's mastery bars. Codex can build and test the pure rules; Claude reviews.
6. **Bot skill follows the lobby:** bots match the lobby's average level, weighted towards its lower-level players, so
   one level 50 among level 1s doesn't bring veterans. Today a room's bots come from whether its players have
   graduated from rookie rooms (after 5 matches), not their levels.
7. **Balance pass:** bot matches with every class, then Alan's playtest.

**Cost:** free so far. New models try free Creator Store items first; Meshy would use existing credits and only with
Alan's go, like every upload.
