# Planes and hangar

## What the player sees
A plane is four parts (nose, wings, body, tail) plus weapons on mounts. Slim bodies are fast and fragile, heavy bodies are tough and slow and carry more. In the hangar you build, compare and save five builds. Weapons that can't fit are crossed out with a crayon X saying why.

## Where it stands (2026-10-15)
Plane parts redone (Stage 8). Smart weapon placing and the crayon X are in. Team and free-for-all colours are in.

## Rules
*Moved word for word from the old rulebook (GAME_SPEC.md, version 1.0). Starting tuning, not tested balance.*

Use studs, seconds, degrees in configuration; normalize internally where needed. Every actor has a unique
actor ID, controller type (internal), life ID, participant ID and match ID. A loadout has four structure IDs,
ordered weapon mounts, optional utility ID, and at most two distinct weapon types. Never equate a bot actor ID with
a Roblox UserId. Validate catalog versions and references server-side.

Each body has base speed/health/turn/Lift. Other parts contribute additive deltas. Equipped weapon/utility
mass is summed separately. Initial formulas:

```
health = clamp(body.base_health + sum(part.health_delta), 45, 400)
speed = clamp(body.base_speed + sum(part.speed_delta) - 1.2 * equipment_mass, 45, 155)
turn = clamp(body.base_turn + sum(part.turn_delta) - 1.5 * equipment_mass, 45, 240)
full_lift_seconds = clamp(body.base_lift + sum(part.lift_delta) - 1.5 * equipment_mass, 45, 125)
```

Apply archetype speed ceilings as an additional guard: heavy 95, standard 135, slim 155. Display final derived
stats before purchase/equip. Equipment mass never appears in the health formula. Collider size follows the
visible body scale; it cannot shrink to slim while keeping heavy mounts. Large bodies must retain a maneuver/
speed disadvantage after legal part combinations. Use stat enumeration to catch unintended dominant builds.

Starter: classic standard body/parts, two pellet guns, no utility. This yields 120 health, 107.6 speed,
167 degrees/second turning, and 90 seconds Lift. Heavy reference with two pencils and default parts yields
300 health, 62.8 speed, 103.5 turning, 61.5 Lift. These are arithmetic fixtures, not measured flight behavior.

Mount rules: use ordered compatible attachment positions. Heavy accepts heavy/medium/light; medium accepts
medium/light; light accepts light. Total capacity AND mount types AND owned/level-eligible selections must
pass. No free heavy compatibility from other parts. Purchasing a weapon unlocks its type, not consumable
copies. Each utility costs mass and supplies its own boost meter; one utility slot, starter empty.

Precision Paperclip uses 2 capacity; Rubber Band Repeater uses 2. Weapon class still controls mount
compatibility (paperclip medium, rubber light). Saved presets that exceed capacity or contain more than two
weapon types after tuning fall back to the starter build on join, keeping their names, ownership and account
progress. Pending refolds still recover normally, including the once-only refund of reserved or delivered refolds.

## Code
| File | What it does |
|---|---|
| `src/shared/Catalog.luau` | Parts and weapons, stats, which builds are legal |
| `src/shared/Aircraft.luau` | Puts the plane meshes together, mounts, team colours |
| `src/shared/BuilderModel.luau` | The build you are editing in the hangar |
| `src/client/Hangar.luau` | Main-menu hangar screen |
| `src/server/HangarService.luau` | Saving builds and buying parts |

## Tuning numbers
`config/catalog.json` (24 structures, 6 weapons, 3 boosters, starter build).

## Related
- [Plane colours by mode](../decisions/2026-10-13-plane-colours.md)
- [Toilet Roll Gunship](../decisions/2026-10-13-toilet-roll-gunship.md)
- [Balanced bot builds](../decisions/2026-10-07-balanced-bot-builds.md)
- [Weapons](weapons.md)
- [Art: models](../art/models.md)
- [Playtest 2026-10-13](../playtests/2026-10-13.md)
- [Milestones](../plan/MILESTONES.md)

Back to [HOME](../HOME.md)
