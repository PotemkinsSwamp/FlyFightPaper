# Menus and HUD

## What the player sees
Every screen is made of classroom crafts: a bulletin-board main menu, a kraft-folder hangar, lined-paper results, crayon lettering. In flight the HUD shows the aim circle and nose dot, health, Lift and boost, weapon readiness and heat, lock-on warnings, enemy markers with edge arrows, the kill feed and the round strip.

## Where it stands (2026-10-17)
Stage 6 approved by Alan (2026-10-13) after the on-brand HUD restyle. Edge arrows now stay below the top strips.
Event messages and kill-feed lines now rotate (`src/shared/Lines.luau`); death lines say how it happened (weapon, the
building or thing hit, who chased or rammed you), the same line on your note and in the feed. Seen in Studio Play 2026-10-17 except the
between-rounds lines. Warnings (INCOMING!, LOCKED ON!), zone words and error messages stay fixed on purpose.
Main-menu ruler repainted by Codex (reads 3 to 12, right way up; 1 and 2 behind the paper ball), uploaded and seen
in Play 2026-10-17.
Level bar with next unlock on the main menu board's stats card, in the hangar under the plane, and on the results card
(seen 2026-10-17; partly filled bar seen on a test screen, the test account is at max level).

## Rules
*Moved word for word from the old rulebook (GAME_SPEC.md section 9).*

All first-release screens and controls must be navigable at 1280×720 and the reference 1920×1080. Team markers
use shape/text as well as color. Health shows current and worn maximum; Lift and equipped boost are distinct.
Weapon groups show readiness/lock, with two individual pencil pips when equipped. Keep essential HUD readable.

Follow ART_DIRECTION for geometry, audio and effects. Start with repeatable procedural geometry; polish it,
do not substitute a generic baseplate for the promised classroom. Preserve sensible cover, fan routes, desk
approaches and heavy-plane clearance. Acceptance requires actual screenshots, logs, movement/combat scenarios,
profile/receipt failure tests, and genuine multi-client network checks—not code existence alone.

The full look brief is in [Art direction](../vision/ART_DIRECTION.md) ("Menu and UI look", "Required screens").

## Code
| File | What it does |
|---|---|
| `src/client/MenuController.luau` | Which screen shows; Esc and Tab |
| `src/client/MenuBoard.luau` | Bulletin-board main menu |
| `src/client/Hangar.luau`, `src/client/DeskHangar.luau` | Main-menu and in-game hangar |
| `src/client/SettingsScreen.luau`, `src/client/Options.luau` | Settings screen and applying settings |
| `src/client/PauseScreen.luau` | In-match clipboard menu |
| `src/client/RoundEnd.luau` | Round end in the room: "Pencils down!", the winners' cutscene with the results card, vote card (1/2/3), next round's name |
| `src/client/LevelBar.luau` | Your level, XP bar and next unlock: on the results card, the main menu board and the hangar |
| `src/client/WinnersCutscene.luau` | Camera glides to the chalkboard-row desks for a close-up of each winner in turn (3rd, 2nd, 1st), fading out on this screen only what would block them; local copies of the top 3 stand up, hop on the desks and emote, the results card beside them; then a zoom out to all three emoting, then it glides back. Plays the hop animation in `rounds.winner_hop_animation` once uploaded |
| `src/client/WaitScreen.luau` | "Waiting for a desk" note (only when 12 real players fill the server) |
| `src/client/Loading.luau` | Loading screen |
| `src/client/FlightHUD.luau` | Everything on screen while flying |
| `src/client/PaperUI.luau` | Shared builder for the paper screens |
| `src/shared/UIAssets.luau` | Uploaded menu and HUD image IDs |
| `src/shared/Lines.luau` | Rotating event lines (plane down, landing, desk service, kill feed, between rounds); one is picked at random, never twice in a row ([decision](../decisions/2026-10-17-fresh-rotating-lines.md)) |

## Tuning numbers
`config/gameplay.json` `menus`, `accessibility`. Menu art: `assets/ui/` (made by `tools/ui_pieces.py`).

## Related
- [Menus are made of classroom crafts](../decisions/2026-10-08-menu-look-classroom-crafts.md)
- [In-game menus reuse the main menu's art](../decisions/2026-10-11-in-game-menus-match-main-menus.md)
- [UI concept pictures](../art/references.md)
- [Tutorial](tutorial.md)
- [Milestones, Stage 6](../plan/MILESTONES.md)

Back to [HOME](../HOME.md)
