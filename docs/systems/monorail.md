# Monorail

## What the player sees
A cream-and-red toy monorail train of three cars loops the new town 125 studs up: along the river, up the ring
road's outer pavements and down the middle of the monorail avenue, through the two stations' track tunnels. It is
solid: fly into it, or let it hit you, and your plane crashes.

## Where it stands (2026-10-16)
Code and tests done (296 tests passing); switched off (`enabled` false) until the new town stands in the place, so
not yet seen moving. Still to check in Studio: the cars' noses lead (the mesh turn in `TrainMotion.luau`), and the
train looks right in the station tunnels. Bots don't avoid it yet. Track pieces: [models](../art/models.md).

## Rules
- The train runs round the loop at a steady speed on server time and stops about 10 seconds at each station (Alan
  2026-10-16; not built yet); every client moves its own copy, so it costs no
  network traffic and everyone sees it in the same place the server judges.
- Each car's front and back both follow the track, so the cars bend round corners one by one.
- A plane whose middle comes within a small margin of a car's box is destroyed ("Hit by the monorail"), a crash
  like hitting a building (kill credit as for any crash).
- The beam and pillars are ordinary solid town pieces (crash or scrape like buildings).
- Route and clearance rules: [town replan decision](../decisions/2026-10-15-town-replan-v3.md).

## Code
| File | What it does |
|---|---|
| `src/shared/MonorailRules.luau` | Where each car is at a given time; whether a plane touches a car |
| `src/client/TrainMotion.luau` | Moves the train's three cars on each client |
| `src/server/FlightService.luau` | Destroys a plane the train touches (in its flight step) |
| `tests/unit/MonorailRules.spec.luau` | Loop, spacing, speed and hit tests |

## Tuning numbers
`config/gameplay.json` `world.monorail` (speed, margin, cars, on/off); the track line is
`config/monorail-track.json`, written by `tools/town_plan.py`.

## Related
- [Town and rug](../world/town.md)
- [Damage and deaths](damage-and-deaths.md)

Back to [HOME](../HOME.md)
