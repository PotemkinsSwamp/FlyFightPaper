# Planes and hangar

## What the player sees
A plane is four parts (nose, wings, body, tail) plus weapons on mounts. Slim bodies are fast and fragile, heavy bodies are tough and slow and carry more. In the hangar you build, compare, save and name five builds (click the name, up to 20 letters, Roblox-filtered). In the [Range](tutorial.md) it edits the Range's own five instead. Weapons that can't fit are crossed out with a crayon X saying why.
The hangar opens on the build you fly; saving makes a build the one you fly next, and at your desk **Save & fly – 120
Paper** also refolds it. Switching builds with unsaved changes asks first.

## Where it stands (2026-11-14)
**Skins (Studio only):** a plane with a `Skin` attribute (bots get one by difficulty from `FlightService`) is
drawn on each screen with its printed-sheet piece copies (`PlaneLooks.luau`); the "Dev: skin" button tries the test
skins on your plane. Boosters and the hangar photo wear it too. Players wear their saved skin (bought with Paper and
picked in Customize's **Skins** tab; a **Trails** tab lists trails, not drawn yet). Shape skins (the Origami Crane) are
fitted by `SkinShapes.luau` from `config/skin-shapes.json` (the crane: five pieces uploaded 2026-11-13, guns hung under
the wings with their whole length under the wing, drawn shots start from the moved gun; the body's belly stops at the real body's bottom
and its roof is low, and the wings, neck and tail join the stretched body's side edge; boosters wear its printed sheet,
uploaded 2026-11-14, and move straight up or down, never turned or resized, until their top touches the belly's middle,
`ref.keel` in the config; their tape strap's top tucks inside) ([skins plan](../plan/SKINS-PLAN.md)). Under a shape skin
the server turns the real wings' hit and crash shapes up to the skin's wing angle and puts the guns' and booster's where
the screen draws them, by the same fit (`SkinFit.luau`; built 2026-11-14, checked in Play: wings 32 degrees, same size,
guns and boosters exactly on the drawn ones; boosters within 0.04 of touching the belly, mesh against mesh, on all 18
body and booster builds; not yet flown past walls).
The shelf's big photo and its cubbies wear your skin too; a crash crumples into a ball of the skin's printed pieces.
A skin you don't own shows Buy (or Unlock now); Studio's try-on is only the "Dev: skin" button (it lists the crane).
The hangar keeps each plane photo between clicks and swaps a new plane in only once it has loaded; after a buy the
server sends the fresh profile at once. Playtest fixes and Alan's replay: [notes](../playtests/2026-11-13-crane-and-skins-tabs.md).

**Hangar buying, built and checked in Play 2026-11-12 (Alan's notes, [playtest](../playtests/2026-11-12-shop-window-and-hangar-buying.md)).**
A part above your level is greyed with a drawn padlock and "Level 20"; one you can buy shows "3,500 Paper"; card words
are bigger (gear cards show size and weight only). Above your level, "Unlock now" with the part's Robux price (from
`Customize.unlockRobux`, the approved table) replaces Buy. Buy without enough Paper opens a "Not enough Paper" note over
the sheet with Get Paper (the shop) and Unlock now. A card click clears the last buy's reply. Gear cards: a slimmer Hit
row so size and weight read bigger. The note dims the whole screen (past the sheet). Pictures: `.planning/hangar-buying/`
(not in git). Alan OK'd the pictures 2026-11-12 ("it's good").

**Guns touch the plane (Alan 2026-11-11: they floated).** Every gun hangs by its highest point (`Aircraft` `topOf`):
on the body pair from the wing root (`ROOT_UNDER`, per wing set), on the wing spots from the wing (`Mount1`/`Mount2`,
`tools/art/plane_pieces.py`), and a crowded gun shrinks toward its top. The pellet tube keeps plane A's spot through the
root. Checked on exact shapes in Studio: all 1,500 body x wings x weapon x spot placements touch, none pokes through.
Not yet seen by Alan.

**Presets (step 2 of the [classes plan](../plan/CLASSES-PLAN.md)):** six fixed planes, each open from its level (`classes`
in `config/catalog.json`, the newer weapons now have their own models). The Hangar shows them on their own tab; the desk
menu's "Switch to presets" flips its cork strip over to them (`DeskHangar.luau`). Players call their own builds loadouts.
A preset flies without owning its parts (`Catalog:classLoadout`, `SelectedClass`) and can't be changed; a refold accepts it
(`Catalog:isClassLoadout`). The pick isn't saved yet, like a picked build: rejoining goes back to build 1.

**Hangar rework built; Alan played it and OK'd it 2026-10-21; try-on/Select approved with the tutorials 2026-10-22** (the desk's quick menu is next) ([plan](../plan/HANGAR-PLAN.md),
[decision](../decisions/2026-10-20-hangar-build-shelf.md)): the first screen is a cubby shelf (one still 3D plane per
build, `BuildShelf`), the big photo, tape name label (click to rename), reference-style stat sheet (each row: label, five boxes, the real number; Weight "2/6"; Alan 2026-10-21) and Customize. In Customize a card click only tries the part on (crayon ring, "Trying it on"): the plane shows it and each number shows its change from what you have on now, in green or red; **Select** puts it on and it becomes what the next card is compared with; Cancel or clicking the equipped card stops trying (a part you don't own shows Buy instead of Select). Gear you own skips this: pick a spot number, click the gear, it goes on. A new name shows straight away while it saves. Booster cards say how much speed for how long. Gear fits all ten weapons on one page in shorter cards (name, Hit boxes, size and weight; Alan 2026-11-08); the box under them says what the weapon on the picked spot, or the card you're trying on, does in plain words, no numbers (Alan 2026-11-08; `description` in `config/catalog.json`). Gear comes off with Clear spot,
or every spot at once with Clear all (Alan 2026-11-11; `BuilderModel:clearMounts`; the same taped paper as Clear spot
in red, `hangar/source/button-red.png`: the green one recoloured, tape kept, uploaded 2026-11-11); Customize is a binder (`HangarCustomize`) with index tabs (Body, Nose, Wings, Tail, Gear, Boost), the 3D plane
on the left page, cards on the right, a page turn when switching tabs. Art uploaded 2026-10-21
(`assets/ui/hangarshelf/`, `UIAssets.hangarShelf`). Not yet seen in Play. The desk's quick menu has its own design
([decision](../decisions/2026-10-22-desk-quick-menu.md)).

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

Each body has base speed/health/turn/Lift. Other parts contribute additive deltas. Equipment mass is the guns'
weight (the capacity they use: one weight per gun, Alan 2026-11-08) plus the booster's own hidden weight. Formulas:

```
health = clamp(body.base_health + sum(part.health_delta), 45, 400)
speed = clamp(body.base_speed + sum(part.speed_delta) - 2 * equipment_mass, 45, 155)
turn = clamp(body.base_turn + sum(part.turn_delta) - 1.5 * equipment_mass, 45, 240)
full_lift_seconds = clamp(body.base_lift + sum(part.lift_delta) - 1.5 * equipment_mass, 45, 125)
```

Apply archetype speed ceilings as an additional guard: heavy 95, standard 135, slim 155. Display final derived
stats before purchase/equip. Equipment mass never appears in the health formula. Collider size follows the
visible body scale; it cannot shrink to slim while keeping heavy mounts. Large bodies must retain a maneuver/
speed disadvantage after legal part combinations. Use stat enumeration to catch unintended dominant builds.

Starter: classic standard body/parts, two pellet guns, no utility. This yields 120 health, 106 speed,
167 degrees/second turning, and 90 seconds Lift. A Toilet Roll with a Pencil, two Pellets and default parts yields
180 health, 73 speed, 124.5 turning, 81.5 Lift. These are arithmetic fixtures, not measured flight behavior.

Mount rules: use ordered compatible attachment positions. Heavy accepts heavy/medium/light; medium accepts
medium/light; light accepts light. Total capacity AND mount types AND owned/level-eligible selections must
pass. No free heavy compatibility from other parts. Purchasing a weapon unlocks its type, not consumable
copies. Each utility costs mass and supplies its own boost meter; one utility slot, starter empty.
The Gunships (Alan 2026-11-08, so health times guns no longer runs away; mounts cut to 3 on 2026-11-12, still too
strong): both have three mounts, heavy, heavy, medium. The Cardboard Gunship (220 health) carries 10: two Pencils, or two
Crayons and a light or medium gun. The Toilet Roll sits midway between it and the Courier Fold on every stat (180 health,
87 speed, 135 turn, 92 Lift) and carries 8: two Crayons, or one Pencil and a medium gun, never two Pencils (Alan leaned 8
over 9; one number in `config/catalog.json`). The fixed planes on them: Bomber a Crayon and two Pellets, Carrier three
Pellets.

Precision Paperclip uses 2 capacity; Rubber Band Repeater uses 2. Weapon class still controls mount
compatibility (paperclip medium, rubber light). Saved presets that exceed capacity or contain more than two
weapon types after tuning fall back to the starter build on join, keeping their names, ownership and account
progress. A build saved when its body had more mounts keeps its guns, packed in order into the mounts that take them;
the rest are dropped (`Catalog:fitMounts`). Pending refolds still recover normally, including the once-only refund of reserved or delivered refolds.

## Code
| File | What it does |
|---|---|
| `src/shared/Catalog.luau` | Parts and weapons, stats, which builds are legal |
| `src/shared/Aircraft.luau` | Puts the plane meshes together, mounts, team colours |
| `src/client/PlaneLooks.luau` | Draws skins on this screen only: swaps each paper and trim piece for its printed-sheet copy (`config/skin-pieces.json`) wearing the skin picture plus its creases ([skins plan](../plan/SKINS-PLAN.md)) |
| `src/shared/BuilderModel.luau` | The build you are editing in the hangar |
| `src/client/Hangar.luau` | Main-menu hangar: the shelf screen, stat sheet, name label, plane photo |
| `src/client/BuildShelf.luau` | The cubby shelf: one still 3D plane per saved build or class (tests for classes: `tests/unit/Classes.spec.luau`) |
| `src/client/HangarCustomize.luau` | The Customize binder: category tabs, part and gear cards, buying, Save; the Skins and Trails tabs (try on, Wear, Buy, Unlock now, Take off) |
| `src/client/SkinShapes.luau` | Shape skins (Legendary, Mythical): draws the skin's pieces on this screen where `SkinFit` puts them, hides what they cover, draws the guns under the wings ([skins plan](../plan/SKINS-PLAN.md)) |
| `src/shared/SkinFit.luau` | Shape skins' one fit for screen and server: measures the plane's parts, places the skin's pieces, and says where each real wing turns (about the drawn hinge) and each gun hangs |
| `tests/unit/SkinFit.spec.luau` | Under the crane, on two builds: wing shapes turn by its angle about the drawn hinge at the same size, gun shapes move by the screen's offsets, crash shapes refit on a skin change; no shape skin moves nothing |
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
