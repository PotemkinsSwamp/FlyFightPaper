# Planes and hangar

## What the player sees
A plane is four parts (nose, wings, body, tail) plus weapons on mounts. Slim bodies are fast and fragile, heavy bodies are tough and slow and carry more. In the hangar you build, compare, save and name five builds (click the name, up to 20 letters, Roblox-filtered). In the [Range](tutorial.md) it edits the Range's own five instead. Weapons that can't fit are crossed out with a crayon X saying why.
The hangar opens on the build you fly; saving makes a build the one you fly next, and at your desk **Save & fly – 120
Paper** also refolds it. Switching builds with unsaved changes asks first.

## Where it stands (2026-10-21)
**Hangar rework built; Alan played it and OK'd it 2026-10-21** ([plan](../plan/HANGAR-PLAN.md),
[decision](../decisions/2026-10-20-hangar-build-shelf.md)): the first screen is a cubby shelf (one still 3D plane per
build, `BuildShelf`), the big photo, tape name label (click to rename), reference-style stat sheet (each row: label, five boxes, the real number; Weight "2/6"; Alan 2026-10-21) and Customize. In Customize a card click only tries the part on (crayon ring, "Trying it on"): the plane shows it and each number shows its change from what you have on now, in green or red; **Select** puts it on and it becomes what the next card is compared with; Cancel or clicking the equipped card stops trying (a part you don't own shows Buy instead of Select). Gear you own skips this: pick a spot number, click the gear, it goes on. A new name shows straight away while it saves. Booster cards say how much speed for how long. Gear comes off with Clear spot
button; Customize is a binder (`HangarCustomize`) with index tabs (Body, Nose, Wings, Tail, Gear, Boost), the 3D plane
on the left page, cards on the right, a page turn when switching tabs. Art uploaded 2026-10-21
(`assets/ui/hangarshelf/`, `UIAssets.hangarShelf`). Not yet seen in Play. The desk's in-game menu keeps its old
squares until its own quick-menu concept.

Earlier (2026-10-18):
Softer coloured-paper team colours in (checked in Play: every plane red 214,78,72 / blue 70,128,214). Paper
textures on every part and booster (107 pieces; Classic in `paper-sample/`, the rest in
`assets/models/planes/paper-set/`), checked in Play in both team modes and free-for-all; `tools/art/plane_pieces.py` picks up any piece with a "mesh"
id in `paper-sample/` or `paper-set/uploads.json` ([decision](../decisions/2026-10-18-paper-look.md)). `Aircraft.paint` tints a textured piece through its SurfaceAppearance.
Plane parts redone (Stage 8). Smart weapon placing and the crayon X are in. Team and free-for-all colours are in.
One hangar flow ([decision](../decisions/2026-10-17-builds-change-at-the-desk.md)): Edit from the desk, Save / Save &
fly, opens on the flown build, unsaved-changes warning. Checked in Studio Play 2026-10-17; not yet played by Alan.
Weapons tab: clicking the weapon already on the picked mount takes it off; the button reads "Clear weapon spot"
(checked in Studio Play 2026-10-17).

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
| `src/client/Hangar.luau` | Main-menu hangar: the shelf screen, stat sheet, name label, plane photo |
| `src/client/BuildShelf.luau` | The cubby shelf: one still 3D plane per saved build |
| `src/client/HangarCustomize.luau` | The Customize binder: category tabs, part and gear cards, buying, Save |
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
