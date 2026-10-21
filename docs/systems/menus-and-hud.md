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
The nose dot turns red when the shots would land with no aim help (Alan 2026-10-19,
[decision](../decisions/2026-10-19-less-aim-assist.md)): the target in range and the nose line passing within 2 studs of
the orange ring's point. The gun assist (`combat.gun_assist_deg`, 3 degrees, lessons too; was 7) sends
shots to the ring when the nose is that close.
The orange ring follows the enemy whose ring (its lead) is nearest the aim circle, not the nearest plane, and keeps it
until another's ring is 3 degrees nearer (Alan 2026-10-19, [decision](../decisions/2026-10-19-range-row-picker-and-aim-pick.md)).
The ring guesses a plane's path from its speed and turn; practice targets (the Range, Combat School drills) publish
their set path (`DrillPath`, `TrainingCourse.pathOf`), so their ring is exact (2026-10-20: the guess hit 0% with a
pencil on Veteran long range), and their card on screen and the server's hit check use that same path at the same
moment: the client draws it on its synced server clock, the server rewinds only the trigger message's trip
(`pathRewind`). The whole picture (26 x 13.6) is the hit area. The Range has
no gun assist: shots go where the crosshair points, at its range.
The in-match **Menu** button sits in Roblox's top bar, just right of Roblox's own buttons (`GuiService.TopbarInset`;
Alan 2026-10-20: lower down it covered the Range Menu strip).
In a lesson the INCOMING / BREAK NOW! note drops just under the lesson's note, a size smaller (it was hidden behind it). A shot-path check against the target's shape was dropped after a Play measurement.
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
| `src/client/WinnersCutscene.luau` | Camera glides to the chalkboard-row desks (the two outside ones slide in next to the middle one on this screen only) for a close-up of each winner in turn (3rd, 2nd, 1st) as their local copy stands up, hops on the desk and starts a Roblox emote; then one steady group shot of all three, a little from above, with paper name plates and confetti, fading on this screen only what would block them and what hangs from the ceiling in front; then it glides back as the results card comes up. Plays the hop animation in `rounds.winner_hop_animation` once uploaded. 1st plays `rounds.winner_plane_emote` (Meshy full-body clip, empty until uploaded) holding a copy of their own plane in the right hand, nose turning the way the hand moves |
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
