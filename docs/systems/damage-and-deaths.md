# Damage and deaths

## What the player sees
Shots and crashes take health. Grazing a wall or the train's side at a shallow angle is a scrape: a little damage, and the plane is knocked away and wobbles so you have to steer back; hitting more head-on crashes. A crash crumples your plane into a paper ball; being shot down tears it into paper shreds. The camera follows your remains until you respawn about four seconds later. The pilot who did the final weapon damage gets the **fold** (the game's word for a kill), unless someone else did half the plane's health or more in the last 15 s: then they get it and the finisher gets an assist plus +25 ([decision](../decisions/2026-10-17-fold-credit-big-damage-wins.md)). Others who did enough damage get an assist. A repair wipes earlier damage.

## Where it stands (2026-10-18)
Walls judged by angle (built 2026-10-18, waits on Alan's check): in Play a 15 degree graze along a wall scraped and
wobbled (8 health over 2 s of grinding), 45 degrees crashed; bots in a 2-minute match died only to weapons. Works. Death looks (shreds, paper ball, team colours) wait on Alan's eyes. Bot-vs-bot rams never land.

## Rules
- **Scrape or crash by angle** ([decision](../decisions/2026-10-18-scrapes-wobble.md)): touching a building, the
  room or the train's side at under 25 degrees between the flight path and the surface (`combat.collision_crash_angle_deg`)
  is a scrape: health that grows the longer contact lasts, and the pilot's client knocks the nose and aim 10 degrees
  away and rolls the plane into a fading wobble (`flight.scrape_*`). More head-on is a crash. Empty Lift on the floor
  and the train's moving front always kill. Judged by `Rules.crashes` in `src/shared/FlightRules.luau` on both the
  server and the pilot's client. The old rulebook text below is superseded where it differs.

*Moved word for word from the old rulebook (GAME_SPEC.md, version 1.0). Starting tuning, not tested balance.*

Use swept-volume world collision with a visually honest plane proxy. Collision damage depends on normal
impact speed: light glancing contacts cause little; hard direct impacts are potentially lethal. Initial
thresholds: under 15 normal studs/s no damage; 15–45 scale 0–25% original max health; above 45 scale toward
100% by 95. Use a 0.6-second contact damage gate and push away from the surface to prevent repeated overlap
callbacks deleting the plane. Tune based on observed forgiveness, not just formula output.

Initial aircraft-aircraft contacts cause at most 10% original max collision damage per contact and separate
without hard body blocking. Ramming alone earns no elimination; a recent eligible weapon attacker may still
get credit if a damaged plane crashes. Friendly aircraft cannot be used as high-damage missiles.

An actual health-zero event or lethal out-of-bounds/destruction transition resolves exactly once. Final
eligible weapon damage gets kill credit. For an environment crash/Lift exhaustion/withdrawal/disconnect,
use the last eligible weapon attacker within ten seconds; absent that, award no kill to anyone. Other
attackers contributing at least 10% original maximum health within ten seconds get one assist each, excluding
the credited killer. Keep this per victim life; no assist per pellet. Team self/friendly damage is ineligible.
Validate simultaneous last hits using authoritative ordering, not client timestamps. Bots use the same ledger.

Warn near bounds; guide toward room interior for a short recoverable grace interval. Persistent escape causes
ordinary destruction, not teleport to a safe base. Collision and paper-shred effects contain no gore or damage
to human figures. Respawn delay starts at four seconds; a player may instead remain in main menu.

## Code
| File | What it does |
|---|---|
| `src/server/CombatService.luau` | Kill and assist credit, hit tests |
| `src/server/HitShapes.luau` | Exact plane hitboxes on the server |
| `src/client/PlaneDeaths.luau` | Paper ball and shred death visuals |

## Tuning numbers
`config/gameplay.json` `combat` (collision thresholds, credit window).

## Related
- [Weapons](weapons.md)
- [Modes and scoring (points for folds)](modes-and-scoring.md)
- [Playtest 2026-10-13](../playtests/2026-10-13.md)
- [Audit 2026-10-07](../research/AUDIT-2026-10-07.md)
- [Glossary](../GLOSSARY.md)

Back to [HOME](../HOME.md)
