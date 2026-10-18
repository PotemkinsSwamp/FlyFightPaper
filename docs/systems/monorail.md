# Monorail

## What the player sees
A cream-and-red toy monorail train of three cars loops the new town 125 studs up: along the river, up the ring
road's outer pavements and down the middle of the monorail avenue, through the two stations' track tunnels. It is
solid: fly into it, or let it hit you, and your plane crashes.

## Where it stands (2026-10-16)
Running in the place. Stops at both stations (2026-10-16, 297 tests passing): checked in Play by numbers, the
middle car stands still at each station's middle for 10 s. Speed 90 looked at in Play (2026-10-16; now 105, brake 35: Alan "slightly faster"): both end cars'
noses face outwards; the south tin holds the whole train, the north station is shorter than the train, so the end
cars poke out about 20 studs each side. Bots don't avoid it yet. Both stations rebuilt 170 tall (2026-10-17, Alan's note): their track tunnels lifted 20 studs, so the
beam rests on the tunnel floor (120 up) and there are about 26 studs of air above the train's roof; not uploaded yet. Track pieces: [models](../art/models.md).

## Rules
- The train runs round the loop on server time and waits 10 seconds at each station with its middle car in the
  station's middle (Alan 2026-10-16), slowing down into a station and speeding up out of it; every client moves its
  own copy, so it costs no network traffic and everyone sees it in the same place the server judges.
- Each car's front and back both follow the track, so the cars bend round corners one by one.
- A plane touches a car when any corner of its parts (wingtips, nose, tail fin) or its middle comes within 1 stud of
  the car's box (Alan 2026-10-18: wings used to pass through), like a building wall: a skim scrapes and pushes the
  plane off; a hard hit, or the train running into the plane, crashes it.
- The beam and pillars are ordinary solid town pieces (crash or scrape like buildings).
- Route and clearance rules: [town replan decision](../decisions/2026-10-15-town-replan-v3.md).

## Code
| File | What it does |
|---|---|
| `src/shared/MonorailRules.luau` | Where each car is at a given time; whether a plane touches a car |
| `src/client/TrainMotion.luau` | Moves the train's three cars on each client |
| `src/server/FlightService.luau` | Destroys a plane the train touches (in its flight step) |
| `tests/unit/MonorailRules.spec.luau` | Loop, spacing, station stops, speed and hit tests |

## Tuning numbers
`config/gameplay.json` `world.monorail` (speed, station wait, brake, margin, cars, on/off); the track line and the
stations' middles are `config/monorail-track.json`, written by `tools/town_plan.py`.

## Related
- [Town and rug](../world/town.md)
- [Damage and deaths](damage-and-deaths.md)

Back to [HOME](../HOME.md)
