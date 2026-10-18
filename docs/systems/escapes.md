# Escapes

## What the player sees
Ways to shake off a plane that is chasing you. Two are planned:
- **Chalk eraser (built):** a chalkboard eraser lying in the fountain park south of the bell tower, as if a child
  dropped it. Shoot it and it puffs a big chalk-dust cloud for 45 seconds; it keeps its full size for the
  first half, then shrinks (and so does the safe zone) until it is gone. The cloud blocks sight like a building: no
  lock-on, aim assist, bot sighting, marker, orange outline or name tag through it, into it or out of it. Inside it is like fog: clear up close, nothing
  past about 380 studs. It is ready again after 2 minutes: after a puff the felt is clean and dark, and chalk blotches
  slowly come back over it; lots of white with black showing through = ready.
- **Ceiling ducts (being built):** a dark maze of sheet-metal air ducts above the ceiling, 120 wide and 140 tall,
  with rooms (240 across) at every bend and junction. Four vent holes (180 across) at irregular spots, each with a
  solid grille hanging open under it: fly through the 18-stud gaps between its bars (every plane fits, wings level)
  or clip a bar; every vent leads to every other, with loops. No lamps: where a duct passes over one of the classroom's
  ceiling lights, its glow comes up through a floor grille (five of them). One link is a round plain steel pipe 25
  across the whole way (360 long, band clamps round it): the heavy gunship (26 wide) can't fit; other planes can if they fly it straight. Two
  spinning fans (red hub, three blades, in a round housing on a plate across the duct) to fly through a gap: a blade
  or the hub takes 75% of your health and shoves you sideways; 0.8 turns a second (Alan: faster and more damage,
  then slightly slower). Fans blow air down their duct: with it you're up to 30% faster, against it up to 15% slower
  (easier to time the blades; Alan found 30% slower too slow). The blower on one room's wall blows the same way, 50%.
  Wind swirls show which way the air goes. Inside it looks like real galvanised ductwork: an X pressed into every
  sheet, riveted joint bands, fans with a motor on four arms behind the hub. Up there: cobwebs in the corners, plastic
  spiders on the walls, dust bunnies, lost toys (toy cars, rubber ducks, a pile of toy spiders, marbles, a bouncy ball)
  and tools (screwdrivers, wrenches, a torch still on, lighting the floor). Only veteran bots will use the ducts.

No points for shaking someone off.

## Where it stands (2026-10-18)
Fan housings no longer poke through the classroom ceiling (Alan 2026-10-18): the ring is trimmed top and bottom to
the duct and the plate fills above and below the blades; checked with test rays, no see-through gaps. Live in the
open Studio place; needs File > Save to File.
Chalk eraser built and playtested by Alan: cloud made 2.25x then another 30% bigger (728 across), eraser half size,
cooldown 3 min -> 2 min, haze inside instead of white-out, chalk blotches on the felt as the ready sign. Its model (92 x 29 x 25 studs) is
built in Blender from Alan's approved model sheet and uploaded (2026-10-15). Ducts (2026-10-15): first built as a symmetrical loop and cross with 7 vents; Alan
looked and asked for a dark irregular maze, 4 vents, a real round pipe, fans that spin and blow air at you
([rulings](../decisions/2026-10-15-ducts-maze-rulings.md)). Rebuilt that way and flown on the test autopilot: up vent
J and out vent M after 36 s (camera inside the whole way), through the whole pipe dead centre with no damage, a
headwind slowed the plane from 107 to about 80, and a fan hub took 48 of 120 health. The server lets planes fly up to
the duct roof (768); bots still treat the ceiling (620) as their top. Design pass (2026-10-15, after Alan called the
first look boring): the HVAC look and the props above, all built by `tools/ducts.py`; the props are free Creator Store
meshes (asset ids in `PROPS`, scripts never used: one candidate "Lego brick" hid a Studio-only pop-up script and was
thrown away). Waiting on Alan's look in Play. Veteran bots fly the ducts ([bots](bots.md)).

## Rules
The rules are in the decisions below; the numbers are in `config/gameplay.json`.

## Code
| File | What it does |
|---|---|
| `src/client/ChalkCloud.luau` | The chalk-dust cloud; hides name tags; turns the haze white with the camera inside |
| `src/server/CombatService.luau` | Shooting the eraser starts the cloud |
| `src/shared/CombatRules.luau` | `inChalkCloud`: is this plane hidden? (used by aiming, lock-on and bots) |
| `src/client/FlightHUD.luau` | Hides markers for planes in the cloud |
| `tools/ducts.py` | Builds the ceiling with its vent holes and the ducts into `assets/models/ducts.model.json` |
| `src/server/FlightService.luau` | `headroom`: planes may fly above the ceiling up to the duct roof; `fanHit`; moving air's speed |
| `src/shared/DuctRules.luau` | Where the duct fans are and how they turn, when a plane clips one, the moving air (fans, blower), the bots' duct runs |
| `src/client/FanSpin.luau` | Turns the duct fans (on server time, matching the clip check) and the blower |
| `src/client/FanWind.luau` | Swirls showing which way the air moves in the ducts |
| `src/client/FlightController.luau` | Applies a fan's shove (`Knock`) |

## Tuning numbers
`config/gameplay.json` `world.chalk_eraser` (`radius`, `seconds`, `cooldown_seconds`); `world.ducts` (sizes, rooms,
links, vents, pipe, fans, blower; run `python tools/ducts.py` after changing it).

## Related
- [Escapes decision (ducts and chalk eraser)](../decisions/2026-10-14-escapes-hvac-ducts.md)
- [Chalk eraser rulings](../decisions/2026-10-15-chalk-eraser-rulings.md)
- [Ducts maze rulings](../decisions/2026-10-15-ducts-maze-rulings.md)
- [Concept pictures](../art/references.md) (`mode-concepts/hvac-vents.png`, `hvac-ducts.png`, `chalk-eraser.png`)
- [Town and rug](../world/town.md)
- [Milestones, Stage 9](../plan/MILESTONES.md)

Back to [HOME](../HOME.md)
