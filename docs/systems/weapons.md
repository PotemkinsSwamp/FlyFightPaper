# Weapons

## What the player sees
Six weapon families made of school supplies: paper pellets, staples, rubber bands, paperclips (a fast "railgun"), guided erasers (slow homing missiles) and pencils (huge, slow, deadly). Left and right mouse fire the two weapon types on your plane. Every weapon fires the instant you click.

## Where it stands (2026-10-15)
All six work, look and sound different; combat approved by Alan (2026-10-07). Sound levels from the 2026-10-13 playtest are in, waiting on Alan's ears.

## Rules
*Moved word for word from the old rulebook (GAME_SPEC.md, version 1.0). Starting tuning, not tested balance.*

Projectile positions and hit resolution are server-owned. Predict cosmetic muzzle flashes/trails locally;
never accept client damage or kill claims. Every shot has a unique ID, owner actor/life, spawn time, type,
and expiry. Swept travel tests prevent tunneling. Physics bodies are not required for every pellet.
Resolve the earliest eligible collision. No large pencil splash, homing pencil, homing rubber band, or
self-inflicted explosive damage. Friendly-fire damage and friendly homing locks are off in team modes.

All hits obey target health, current protection, match eligibility and server cooldowns. Discard invalid
shots, duplicate sequence numbers, nonfinite vectors, stale life IDs, excessive fire rate and impossible
muzzle transforms. Team projectiles may pass friendly planes but still hit world scenery. Hits on giant
avatars/scenery stop projectiles without awarding combat points.

Two default pellet guns provide 40 nominal damage/second against 120 health (three seconds ignoring travel,
misses and first-shot timing). Test all legal whole-loadout extremes; a six-gun heavy must not be judged by
one-gun metrics. Pencil 260 damage means ordinary planes usually die, heavy 300-health reference survives
with 40. Eraser damage is 30. Table data defines all six gun families.

| Weapon | Damage | Capacity | Speed (studs/s) | Fire timing |
|---|---:|---:|---:|---|
| Paper Pellet Gun | 2 | 1 | 1500, ~750 studs range | Hold; 0.1 s per shot; 30 shots then 1.5 s cooling |
| Staple Burst Gun | 7 | 1 | 1450, ~900 studs range | Hold; 3 shots, 0.09 s apart; 1.2 s between burst starts |
| Rubber Band Repeater | 1.6 | 2 | 1400, ~1050 studs range | Hold; 0.06 s per shot; 40 shots then 1.5 s cooling |
| Precision Paperclip | 24 | 2 | 1900, ~1400 studs range | One shot per click; 1.5 s reload per mount |
| Guided Eraser | 30 | 3 | 200, slowing to 110 | Click to launch unguided or hold through the 1.5 s lock; 4 s reload |
| Pencil Launcher | 260 | 5 | 650, ~1800 studs range | One shot per click, fires on the click; 4 s reload |

Speeds above are launch speeds. Unguided shots lose speed with distance (drag, down to 55-70% of launch speed at the end of
flight) and fall a little (drop, 80 studs/s^2 for pellets down to 3 for pencils); `drag`, `drop` and `lifetime` in
`config/catalog.json` set the range. Range runs pellet < staple < rubber < paperclip < pencil. Erasers keep their own rule below.

Automatic weapons fire while held at per-mount cadence. Burst staples queue three rounds with 0.09-second
spacing and 1.2 seconds between burst starts; releasing before a new burst stops new bursts. Paperclips and
pencils require a press, not unlimited server repeats. Erasers can launch on a press or while held with a
complete lock, subject to their per-mount reload and active-shot cap. Identical semiautomatic launchers
in a group fire one ready mount per press using stable round-robin order. One press must not spend both
pencils. Each mount's readyAt changes only when that mount fires. Assign buttons by the lowest-numbered
filled mount, never by weapon family. The hangar refuses a third type and labels filled mounts L or R.

Each pellet shot adds 1 heat, with a limit of 30 per mount; rubber uses a limit of 40. Releasing the trigger
drains heat at the limit divided by 1.5 seconds. The shot reaching the limit fires, then that mount cannot
fire until all heat drains over 1.5 seconds, even if the trigger stays held. Other mounts remain independent.
The server enforces this for players and bots; predicted shots use the same heat rules and respect server
cooling deadlines. Each button with a cooldown gun has its own heat bar labelled Left or Right; it fills with
heat and turns red with "Cooling" during cooldown. If both buttons have cooldown guns, show both bars.

Reload continues through flight/overlay/service. Existing mounts retain their cooldowns after repair/refold.
Replacing a type cannot finish an in-progress cooldown early: new types start their normal initial reload
at service completion, and reused mounts retain any later prior readyAt. A real respawn creates a new life
with spawn rules. Do not use ordinary repair/refold to reset projectile counts.

A player's guns meet at the range of the target they're aiming at (the client sends it with the aim; the server clamps
it to 20-1000 studs); with no target, and for bots, at `combat.gun_convergence_studs` (150). Fixed at 150, the two
wing guns crossed and flew past either side of a plane seen from behind at 300 studs even with the dot red on the
ring (measured 2026-10-19; Alan: "the shots don't make it"). After the fix, Play: 12 of 12 aimed pellets hit
targets crossing at 220 studs, and 6 of 6 at 130.

### Guided erasers
Initial lock: 1.5 seconds of valid target alignment/visibility within 750 studs. Incoming warning on the target.
Launch speed 200 studs/s through 250 studs flown, then falls linearly to 110 studs/s (0.55x) at 750 studs
flown and stays there. At 500 studs flown, speed is 155 studs/s. Use distance traveled along the shot's path,
including turns, rather than distance from the shooter. Client visuals follow the same slowdown.
Turn limit 90 degrees/s; eight-second lifetime. Guidance loses useful tracking behind solid
cover; retain last observed direction briefly (at most 0.4 seconds), then fly unguided to impact/expiry rather
than knowing the target through walls. No reacquisition through scenery. Erasers must visibly be avoidable.

At most TWO active erasers per pilot across all mounts. Register before spawning and release exactly once on
impact/expiry/removal. A full cap blocks launch without consuming a ready barrel's reload. Death/preset swaps
cannot free the cap while old missiles still exist. Initial death policy removes that pilot's surviving
projectiles with actual destruction callbacks; normal refold retains live projectiles and the cap. Multiple
attackers can each have two; this is not a global target shield.

## Code
| File | What it does |
|---|---|
| `src/client/CombatController.luau` | Mouse buttons to weapon groups, sends shots to the server |
| `src/client/CombatEffects.luau` | Your own shots drawn on the click frame, tracers, hit markers, damage ring |
| `src/client/WeaponMotion.luau` | Launcher pieces moving when they fire |
| `src/shared/CombatRules.luau` | Heat, reloads, bullet drop and drag, eraser homing, hit tests |
| `src/shared/WeaponLoadouts.luau` | Weapon choice to a legal starter loadout |
| `src/server/CombatService.luau` | The server's final word on every shot and hit |

## Tuning numbers
`config/catalog.json` `weapons` (damage, speed, drag, drop, reload); `config/gameplay.json` `combat`.

## Related
- [Combat approved](../decisions/2026-10-07-combat-approved.md)
- [Eraser fires on any click](../decisions/2026-10-13-eraser-fires-on-any-click.md)
- [Damage and deaths](damage-and-deaths.md)
- [Planes and hangar (mounts)](planes-and-hangar.md)
- [Playtest 2026-10-13](../playtests/2026-10-13.md)
- [Milestones](../plan/MILESTONES.md)
- [Glossary](../GLOSSARY.md)

Back to [HOME](../HOME.md)
