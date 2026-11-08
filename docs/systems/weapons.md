# Weapons

## What the player sees
Ten weapon families made of school supplies: paper pellets, the Point Popper (a pencil-lead tube that sprays leads), staples, thumbtacks, the Stubby Crayon (a slow, heavy hit), rubber bands, spitballs (they stick and weigh you down), paperclips (a fast "railgun"), guided erasers (slow homing missiles) and pencils (huge, slow, deadly). Left and right mouse fire the two weapon types on your plane. Every weapon fires the instant you click.

## Where it stands (2026-11-07)
Shots now fall in an arc past their range (2026-11-07, tests pass; Alan's feel check to come). The Point Popper,
Thumbtack, Stubby Crayon and Spitball Straw are in with their own models (2026-11-07: Codex concept renders Alan picked,
built in Blender by `tools/art/weapons.py`, uploaded; waiting on Alan's look in Play): a clear tube of pencil leads on an
orange cradle, a clear pin tub hanging by its rim with a cardboard barrel, a crayon in a striped crayon-box sleeve with a
red band, and a striped party cup hung upside down on a yellow strap with a green straw. Each has its own sound (Alan's
picks 2026-11-07: a balloon pop, a pneumatic air burst, a soft heavy thump, a wet splat; client `Audio`). Alan made
the Crayon slower, shorter and weight 4 after his first try (then, 2026-11-08, a bit faster and flatter again: 400
studs/s, 350 range and drop 30 made it impossible to hit with), so no plane carries more than two and the Pencil keeps the
heavy mount to itself; he approved the Spitball as a support weapon.
All six work, look and sound different; combat approved by Alan (2026-10-07). Sound levels from the 2026-10-13 playtest are in, waiting on Alan's ears.
Paperclip reworked and the shot timing fixed 2026-11-06; Alan confirmed staples and set the glint's strength in the air.
**Match aim measured (2026-10-21, Alan asked if matches miss like the Range did):** in a match shots leave along the
nose, where the green dot is drawn (the Range bug can't happen there). 30 s of 11 bots' real flight recorded on the
server, then "dot exactly on the ring" shots fired at it with the real hit shapes: pellets hit 99% at 150 studs, 88%
at 300, 61% at 450; pencils 89% / 47% / 21%. Knowing where the bot really went, 100% at every range, so every miss is
the ring's guess (bots turn and jink during a long flight); a turn-following guess gained only 0-7 points, not built.
**Screen delay measured (2026-11-06):** five bots' server positions against where Alan's screen drew them, in his Play:
every bot drawn 0.18 s behind (to within a third of a stud). The server allowed 0.1 s, so on-ring shots at a 90 studs/s
bot passed about 7 studs behind it. `combat.view_delay_seconds` is now 0.18; `max_rewind_seconds` went from 0.25 to 0.33
to keep the same room for ping. Live servers' delay can't be measured from Studio.

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
| Point Popper | 5 per lead, 7 leads | 3 | 500, ~100 studs range | One shot per click, up to one a second |
| Staple Burst Gun | 7 | 1 | 1450, ~900 studs range | Hold; 3 shots, 0.09 s apart; 1.2 s between burst starts |
| Thumbtack Shooter | 6 close in, 3 at 300 studs, 2 at 500 | 2 | 900, ~500 studs range | One shot per click, up to 3 a second |
| Spitball Straw | 1, and it sticks | 2 | 600, ~350 studs range | One shot per click, up to 2 a second |
| Rubber Band Repeater | 1.6 | 2 | 1400, ~1050 studs range | Hold; 0.06 s per shot; 40 shots then 1.5 s cooling |
| Precision Paperclip | 24 at 500 studs (12 close, 60 at full reach) | 2 | 3600, ~2420 studs range | One shot per click; mounts take turns, 1.75 s reload each |
| Stubby Crayon | 40 | 4 | 600, ~450 studs range, drop 8 | One shot per click, 2 s reload |
| Guided Eraser | 30 | 3 | 200, slowing to 110 | Click to launch unguided or hold through the 1.5 s lock; 4 s reload |
| Pencil Launcher | 260 | 5 | 650, ~1800 studs range | One shot per click, fires on the click; 4 s reload |

Only automatic weapons (pellets, rubber bands, staple bursts) keep firing while the button is held; every other weapon fires
once per click (Alan 2026-11-07). On phones, holding FIRE (or auto-fire) keeps those firing as each is ready: the client
sends `repeating` with the trigger (`CombatService.receive`). Bots press again for each shot.

Speeds above are launch speeds. Unguided shots lose speed with distance (drag, down to 55-70% of launch speed at the end of
flight) and fall a little (drop, 80 studs/s^2 for pellets down to 3 for pencils); `drag`, `drop` and `lifetime` in
`config/catalog.json` set the range. Range runs pellet < staple < rubber < pencil < paperclip. Erasers keep their own rule below.

Past its range (the end of `lifetime`) a shot doesn't vanish: it slows hard (`combat.shot_fall_drag`) and arcs down
(`combat.shot_fall_gravity`) for up to `combat.shot_fall_seconds`, nose first, and still hits with its usual damage
(`CombatRules.shotOffset`; an Eraser whose time is up stops seeking and falls the same way, `CombatRules.eraserFall`).
A weapon with `leads` (the Point Popper) fires that many shots at once (`CombatRules.leadFans`): they fly in one tight
bundle for `fan_after_studs`, then spray out in a circle: one lead straight on, the rest evenly round a ring starting
straight up. The ring opens at one steady rate, `fan_studs` out by `fan_full_studs` (`CombatRules.fanRadius`). A plane
seen from behind is a thin T: all 7 leads hit to about 65 studs, the ones above and below miss first (5 hit to about
80), and past that only the middle one does. Its DPS counts every lead. A weapon without its own model can borrow another's
(`Aircraft.STAND_IN`, empty now). The four newer weapons keep the hit box they were balanced with (`Aircraft.AMMO`:
pellet, staple, pencil and pellet ammo boxes); a piece named `clear` is see-through plastic (`plane_pieces.py`), and the
Popper's lead draws thicker than its hit box would make it so it can be seen.

A fold made by a falling shot pays the fold-at-a-distance bonus ([economy](economy-and-shop.md)). See
[the decision](../decisions/2026-11-07-four-new-weapons-and-falling-shots.md).

A Spitball sticks to the plane it hits (`sticks` in the catalog; `FlightService:spit`), up to 5 on a plane in all,
whoever shot them; a hit on a full plane knocks the oldest off (`CombatRules.stickSpitball`). Each one is weight
(Alan 2026-11-07): it burns Lift 50% faster, slows the plane 6% and pulls it down 2.5 studs/s (a full load: 3.5x Lift
burn, 30% slower, sinking 12.5 studs/s, so holding height takes about a 10 degree climb; `spitballLiftBurn` /
`spitballSpeed` through `BoostSpeedFactor`, `spitballSink` through `Updraft`, so bots feel it too). Each of your
spitballs still stuck when the plane folds counts as 4 damage toward credit (`spitballCredit`): about 3 earn an
assist; if the plane goes down with no hit in the last 15 s, the most spitballs gets the fold. None fall off for 6 s
after the last hit, then the oldest every 3 s (`CombatRules.spitballsLeft`); any fan blows them all off, landing at the desk
clears them, and a new plane starts clean. Every plane shows a wet paper blob on itself per spitball, and your own
screen gets a splatter per spitball that slides off when they go (client `Spitballs`). No HUD counter (Alan 2026-11-07). The desk's
"spitball hunters" dev button sends four bots with two spitball guns each after you; the "spitball" picker button gives you
the same plane.

Thumbtack damage falls with distance the same way: full to 100 studs, half at 300, a quarter at 500. The Hangar card
says which way a weapon's damage goes.

Paperclip damage follows how far the shot flew (`damage_by_range` in `config/catalog.json`): 12 at 150 studs or less, 24
at 500, 36 at 1000, 60 at 2400, in straight lines between. The lead ring picks targets out to 1000 studs, or to the shot's
full reach for a gun like this. See
[the decision](../decisions/2026-11-06-paperclip-rewards-distance.md).

A paperclip aimed at you glints (`ClipGlint.luau`; Alan 2026-11-06): the enemy is over `combat.glint_min_studs` away, in
clear view, and their nose has stayed within `gun_assist_deg` of hitting you for `combat.glint_hold_seconds`. In view, a
bright flash on their plane; out of view, a reddish glint spread along the bottom of the screen, leaning to
their side. No sound and no picture file. In Studio the attribute `DevGlint` on `ReplicatedStorage.FlyFightPaper` makes
every enemy glint, to judge the look; `DevGlintPeak` there sets the red glint's strength live. The desk's "clip hunters" dev button sends three paperclip-only bots after you.

A quick click on a burst weapon stays held until the burst's last round is out, so every round leaves on a fresh aim
(CombatController). Before 2026-11-06 the later rounds of a tapped burst flew along the plain nose. The lead ring
already used each weapon's speed, drag and drop.

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
it to 20-3000 studs); with no target, at the weapon's full reach, so the streams never cross on the way (Alan
2026-11-06: an X past 150 studs); bots keep `combat.gun_convergence_studs` (150). Fixed at 150, the two
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
| `src/client/Spitballs.luau` | Wet blobs on planes and the splatter on your screen for stuck spitballs |
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
