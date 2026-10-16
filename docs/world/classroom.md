# The classroom

## What the player sees
A giant classroom, 2800 x 2200 studs and 620 tall, seen from the size of a paper plane. Twelve student desks line the
walls, each with a runway, a paper-chain hoop to launch through and a giant seated avatar (your real Roblox avatar on
your desk). Two neutral desks serve anyone. Sun comes through the windows onto a toy town in the middle of the floor.
Up high: hanging planets, rings, paper chains and tubes to fly through. The chalkboard reads FOLD / FLY / FIGHT.
Outside the windows is a schoolyard.

## Where it stands (2026-10-15)
Room, desks, avatars, lighting (Stage 4a) and decor are in. Stage 4 art waits on Alan's approval of the look.
Planned next: HVAC ducts in a space above a drop ceiling ([escapes](../systems/escapes.md)).

## Rules
- Room bounds live in config, never hard-coded to the walls; the room may grow slightly
  ([decision](../decisions/2026-10-07-keep-big-room.md)).
- Lighting targets (Stage 4a in [milestones](../plan/MILESTONES.md)): shadows on, sun through the windows, warm haze,
  bloom, no blur in gameplay.
- Avatar and desk rules: [Vision](../vision/VISION.md) ("Classroom and service") and
  [Art direction](../vision/ART_DIRECTION.md) ("Classroom layout", "Avatars").

## Where it lives
| What | Where |
|---|---|
| Room, desks, lamps, fans, planets, chalkboard | `assets/models/classroom.rbxmx` |
| Wall pictures, backpacks, globe, plants | `assets/models/classroom-decor.rbxmx` (exported by `tools/studio_export.lua`) |
| Schoolyard | `assets/models/schoolyard.rbxm` (`tools/schoolyard.lua`) |
| Ceiling (with vent holes) and the escape ducts above it | `assets/models/ducts.model.json` (`tools/ducts.py`; see [Escapes](../systems/escapes.md)) |
| Desk runways, rings, runway lights | `tools/desk_pieces.py`; drawn by `src/client/DeskPieces.luau` |
| Seated avatars | `src/server/AvatarService.luau` |
| Clock hands showing real time | `src/client/TowerClock.luau` |

## Tuning numbers
`config/gameplay.json` `world` (room size, 12 desks, 2 neutral desks, desk positions, routes, fans, speed pickups).

## Related
- [Town and rug](town.md) · [Desks and service](../systems/desks-and-service.md) · [Model catalog](../art/models.md)
- [Chalkboard says FOLD / FLY / FIGHT](../decisions/2026-10-01-chalkboard-fold-fly-fight.md)

Back to [HOME](../HOME.md)
