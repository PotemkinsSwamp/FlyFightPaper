# Menus and HUD

## What the player sees
Every screen is made of classroom crafts: a bulletin-board main menu, a kraft-folder hangar, lined-paper results, crayon lettering. In flight the HUD shows the aim circle and nose dot, health, Lift and boost, weapon readiness and heat, lock-on warnings, enemy markers with edge arrows, the kill feed and the round strip.

## Where it stands (2026-11-11)
**Unlock moment (built 2026-11-11, Alan OK'd it in Studio Play; not published yet):** leveling up in a match flies a small taped index card in
at the top left, under the Menu button and tilted (`ScreenFit.topLeft`); it unfolds (the part below the fold shaded as it
swings down, a faint crease after) with confetti that shoots up and tumbles down, sits 4 s, then folds and flies back
out ("You unlocked 2 new things! See them in the main menu."). The card is the index card with three ruled rows cut out
(two picture slices, nothing stretched). The main menu plays the backpack (never the in-match menu): drag the zipper, each thing pops out turning in 3D with Put it on /
See it and Later. How it works and its numbers: [the unlock plan](../plan/UNLOCK-PLAN.md); saving: [saving](saving.md).
Back/next are ink chevrons (Path2D: their points are shares of the box, they ignore UIScale); the zipper sound is one 1.3 s
nylon zip (no loop): moving the pull either way earns a little of it (2 s per whole pull, 0.3 s banked at most), so it
pauses when you stop, carries on when you go on, plays back and forth, starts over at its end and plays out when the bag
opens (moving a playing Sound's TimePosition gaps on Roblox, so it only pauses and resumes). Studio tests: `DevUnlock` = a level on ReplicatedStorage.FlyFightPaper opens a backpack of everything up to it (not saved),
`DevLevelNote` = a level shows its note, `DevLevelUp` = a level is a pretend level-up in a match (its note, then its
backpack when you open the Menu; while set, your saved unlocks don't wait).
**Menus fit (branch `wip/stretch-fix-2026-11-09`, not in the game yet):** every picture is drawn at its own shape
(`PaperUI.button` and `image` use Fit; boxes set to the picture's shape) and words sit inside their paper
(`PaperUI.fitWords` shrinks only words too long for their strip). Stats papers: Hangar uses the original paper widened on
both sides of its tape (`tools/art/widen_paper.py`), rows filling it evenly, centred over Customize; Customize uses the
original paper at 540 wide, rows written between its ruled lines at their original sizes, the binder drawn at 95%.
Sticky notes (lesson goal note, Range notes, Match tips, the welcome/end card) use the wide sticky note at its own
shape with everything on its paper; the note's X is a little torn red square (`tools/art/square_from_strip.py`).
Alan approved the Hangar and Customize stats on 2026-11-10; the 7 new pictures were uploaded 2026-11-11 (all approved
by Roblox, online pixels match the files) and the work merged to main. Phones: the lesson goal note keeps its old square note (its phone shapes not redone yet).

**Text style C** (2026-11-08, [decision](../decisions/2026-11-08-text-style-crayon.md)): every word made by
`PaperUI.words` is warm black over a cream edge and a soft shadow (`PaperUI.crayon`: the label's own letters are hidden
and three child copies draw the look, since a label shows only one UIStroke). Loud words (`PaperUI.loud`: every
`PaperUI.button`, titles, card and build names, the HUD's paper slips, the build-name box) are heavier with the full
edge; all other words are quiet, a thin edge and fainter shadow (Alan: descriptive words with the full look were hard
to read). Checked in Studio Play on the main menu and the Hangar binder's Gear page. The copies take the label's ZIndex
(Alan's phone 2026-11-11: in the touch buttons, a Global-layered screen, the crayon fill covered FIRE's words). Not
styled: the labels made directly (score pop-ups, dev buttons) and words that add their own outline. The BRAKE /
SPEED MATCH tag under the view is crayon words since 2026-11-11 (it was white words; Alan didn't want paper behind it).
Tab's live standings are built (2026-11-06); the live columns are not confirmed in play yet.

Menu-only screens (loading, main menu, settings, hangar, shop, wait, Training, round end) draw their boards and
pieces as 3D pictures inside little ViewportFrames (`first/BoardPlate`, `first/MenuArt`): same place, clicks and
tilt, a little softer up close (Alan OK'd), much smaller downloads. Flying screens keep ordinary pictures.
Stage 6 approved by Alan (2026-10-13) after the on-brand HUD restyle. Edge arrows now stay below the top strips.
Event messages and kill-feed lines now rotate (`src/shared/Lines.luau`); death lines say how it happened (weapon, the
building or thing hit, who chased or rammed you), the same line on your note and in the feed. Seen in Studio Play 2026-10-17 except the
between-rounds lines. Warnings (INCOMING!, LOCKED ON!), zone words and error messages stay fixed on purpose.
Folded by a part you don't own ([Alan 2026-11-12](../decisions/2026-11-12-fold-card-and-shop-mats.md)): a card at the
top (the shop's Featured card, smaller) with the part in 3D, "Folded by Mia's", its name, the level it unlocks at and its
Paper price; Buy with Paper first when you have the level and the Paper, else "Wait for level N" / "Need N more", and
always Buy now for Robux. It shows on the fold screen and stays at the desk; its X, LAUNCH, a menu over the desk, the
report card or owning the part put it away. Once per part a session; not in practice. That part also becomes the shop's
Featured card (`FoldGoal`, this client only). Built 2026-11-12, not yet seen in Play (it replaced a line on the top
note, which Alan found too easy to miss).
Main-menu ruler repainted by Codex (reads 3 to 12, right way up; 1 and 2 behind the paper ball), uploaded and seen
in Play 2026-10-17.
Level bar with next unlock on the main menu board's stats card, in the hangar under the plane, and on the results card
(seen 2026-10-17; partly filled bar seen on a test screen, the test account is at max level).
Settings: the steering bar runs 0.2-1.8 with the default 1 in the middle (was 0.2-3; older saves above 1.8 fly at
1.8, Alan 2026-10-28). Menu pictures drawn as 3D cards lift their words to the card's layer (a word under the card
was hidden: the Hangar shelf's "Range" tab looked like a blank second Back). A phone tap area is sized from the
button's resting size, so the hover grow can no longer switch it off mid-tap (that lost taps on the Range Hangar's Back).
Phone screen check 2026-10-29 (Device Simulator): Training board, match desk, Range menu good; the vote's cards and
help line were ~13 points, now taller cards with ~17-point words; the results card's names are ~14 points (heads crowd).
Phones (2026-10-24, seen in Studio's Device Simulator, not yet on a real phone): every paper screen has phone sizes
(`PaperUI.phone`, a screen under 540 points tall; a PC keeps exactly what was drawn). Menu backgrounds reach past a
phone's notch and crop from the bottom (titles stay whole); buttons stay in the safe area. Desk strips, lesson notes,
tips, the round end and the vote sit below Roblox's top bar (the Menu button).
Results card = a school report card (Alan 2026-11-11, [plan](../plan/REPORT-CARD-PLAN.md)): six rows (places 1-5
and your own, yellow highlighter) in a printed table with a red-pen grade per pilot (`MatchRules.grade`: 1st A+, top
quarter A, top half B, the rest C, from the place shown; team rounds by points across both teams), the top right box
your place circled (team rounds: the team's score), a teacher's note about the round, your pocket money and level bar.
The card picture is paper, printing and lines only (`tools/art/report_card.py`); every word is game text. Every cell
shrinks its words to fit its own column (long names). Team rounds: a card per team side by side (Red left, Blue
right, spaced so they don't touch); the winners' card has the gold star by its note. Tab's live standings use the same
card ("so far", no grades or note). After a match (money plan, Alan 2026-11-12): a sticky note by your own card (beside it
in a free-for-all, under it in a team round) says "2x Paper would have given you +X more Paper!" with a 2x Paper, 1 hour
button (79 R$). X is that match's Paper earned without 2x (the server counts it: true even if a boost ran out mid-match).
Only when X > 0, no 2x Paper is running and fewer than 3 buys today (the calm rule P). Alan's first two playtests
didn't show it: in a free-for-all "your page" was the hidden page 2, so the note (and the level bar) hid with it; fixed
2026-11-12, not yet seen in Play. Seen in Studio Play at phone size 2026-11-11 (Alan: "looks good"); PC size not yet
seen in Play (only the put-together preview). Match tips: the words fill the sticky note, as big as fits. Seen in Studio
Play at phone size 2026-10-29.
Dev mode: in Studio, and on the game owner's own account in live servers (server-set `Dev` attribute,
[decision](../decisions/2026-10-29-dev-mode-on-alans-account.md)), the desk shows the dev panel (modes, end match,
weapons, bots, "tips again"); every other account sees nothing and the server refuses its dev requests.
Top of the screen (screen fit step 2, every screen): one row (Roblox's bar, the Menu button, the match strip, which
moves right of the Menu button when centred would hit it), then one column under it in a fixed order: Airspace
capture strip, news note, lesson or Range note, warning or lock note, match tip; each sits under the real bottom of
every shown piece above it that it would touch side to side (`ScreenFit.inRow`, `atSide`, `inColumn`, `place`). A
note that would touch a top-corner piece (the kill feed, a touch screen's Health and Lift) slides into the gap
between them and shrinks to fit (small phones, Alan 2026-10-24). On a phone the match tip is a bit smaller and stays
up top over the news note and kill feed (never over Health and Lift) instead of dropping into the middle of the view. The desk's
stat sheet's top is level with the photo's on every screen (Alan 2026-10-24); the photo's plane rebuilds when more
of its parts arrive from the server (it once showed without a wing). Kill feed: up to 4 slips, level with the match
strip on every screen, filling top down (newest at the bottom) and fading oldest-first after 6 s with no new kill (Alan
2026-10-29); the desk's service strips start under the feed's real bottom; edge arrows stay below Health and Lift on touch
screens. Match tip on a touch screen: tap the note (no Got it button).

## Rules
**Live standings (Alan 2026-11-06):** during a round, Tab (a tap on the score strip on a phone) opens and closes every
pilot's Folds, Assists, Crashes and Pts on the Results pages, small at each side so the middle stays clear to fly. Each
round starts with it closed. It reads the same round news as the score strip. On a phone (checked 2026-11-07, Device
Simulator) the left page sits lower so Health, Lift and Boost stay in view, and names over 11 characters are cut short so
they stay readable. Code: `RoundEnd.luau`.

Esc over the Hangar opens the clipboard menu on top of it, with the Hangar still showing underneath; Keep flying (or Esc
when Roblox's own menu isn't open) goes back to the Hangar, not the room (Alan 2026-10-22). Esc always toggles Roblox's
system menu too, and the press that closes it never reaches the game.
The nose dot turns red when the shots would land with no aim help (Alan 2026-10-19,
[decision](../decisions/2026-10-19-less-aim-assist.md)): the target in range and the nose line passing within 2 studs of
the orange ring's point. The gun assist (`combat.gun_assist_deg`, 3 degrees, lessons too; was 7) sends
shots to the ring when the nose is that close.
**Phones (Alan 2026-10-23, [research](../research/TOUCH-AIM-RESEARCH-2026-10-23.md); built, first numbers from the
fake-pilot test there, not yet tried on a phone):** a wider gun assist that fades out towards its edge (`combat.touch_gun_assist_deg` 6, full inside
`touch_assist_inner_fraction` 0.5 of it, none past `touch_assist_max_range_studs` 800; never less than the mouse's), and the aim turns slower
(`touch_slowdown_scale` 0.65 within `touch_slowdown_cone_deg` 8, easing in over `touch_slowdown_ease_in_s` 0.25) while
the stick sweeps it over an enemy's ring, unless the stick is leaving it. The plane itself always turns at full speed.
The nose dot turns yellow (and the ring fills faintly) when the shots land only thanks to that help.
**Phone auto-fire (Alan 2026-10-28, built 2026-10-29):** on a touch screen FIRE (weapon 1) shoots by itself while its
ring is red or yellow (the shots land), on by default, with an Auto-fire switch in Settings (touch screens only;
`settings.autoFire`, missing = on). The 2 weapon stays hold-to-use. `FlightHUD` sets `onTarget`, `CombatController` fires.
Mouse players are unchanged.
The orange ring follows the enemy whose ring (its lead) is nearest the aim circle, not the nearest plane, and keeps it
until another's ring is 3 degrees nearer (Alan 2026-10-19, [decision](../decisions/2026-10-19-range-row-picker-and-aim-pick.md)).
The ring guesses a plane's path from its speed and turn; practice targets (the Range, Combat School drills) publish
their set path (`DrillPath`, `TrainingCourse.pathOf`), so their ring is exact (2026-10-20: the guess hit 0% with a
pencil on Veteran long range), and their card on screen and the server's hit check use that same path at the same
moment: the client draws it on its synced server clock, the server rewinds only the trigger message's trip
(`pathRewind`). The whole picture (26 x 13.6) is the hit area. Checked by `tests/unit/RangeAccuracy.spec.luau`
(Alan's idea, 2026-10-20): 3,709 of 3,709 shots aimed at the ring hit; pellets can't reach the long row's far swing. The Range has
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
| `src/client/ClipGlint.luau` | The paperclip's warning glint (rules on the weapons page) |
| `src/client/MenuController.luau` | Which screen shows; Esc; Tab opens the live standings |
| `src/shared/TouchWords.luau` | Phone wording: "Click" becomes "Tap", "hold left click" "hold FIRE", key hints like [Space] go; TouchControls rewrites every text on screen with it on a touch screen (tests: `tests/unit/TouchWords.spec.luau`, which also checks every lesson's text) |
| `src/shared/AimHelp.luau` | Phone aim help numbers: how far a shot bends to the ring, how much the stick slows over an enemy (tests: `tests/unit/AimHelp.spec.luau`) |
| `src/client/MenuBoard.luau` | Bulletin-board main menu |
| `src/client/Hangar.luau`, `src/client/DeskHangar.luau` | Main-menu and in-game hangar |
| `src/client/SettingsScreen.luau`, `src/client/Options.luau` | Settings screen and applying settings |
| `src/client/PauseScreen.luau` | In-match clipboard menu |
| `src/client/RoundEnd.luau` | Round end in the room: "Pencils down!", the winners' cutscene with the results card, vote card (1/2/3), next round's name |
| `src/client/UnlockMoment.luau` | The level-up note in a match and the backpack you unzip in the Menu, with a card per unlocked thing (3D) |
| `src/client/LevelBar.luau` | Your level, XP bar and next unlock: on the results card, the main menu board and the hangar |
| `src/client/WinnersCutscene.luau` | Camera glides to the chalkboard-row desks (the two outside ones slide in next to the middle one on this screen only) for a close-up of each winner in turn (3rd, 2nd, 1st) as their local copy stands up, hops on the desk and starts a Roblox emote; then one steady group shot of all three, a little from above, with paper name plates and confetti (falling in from above the top edge of every shot, never seen starting: Alan 2026-10-29), fading on this screen only what would block them and what hangs from the ceiling in front; then it glides back as the results card comes up. Plays the hop animation in `rounds.winner_hop_animation` once uploaded. 1st plays `rounds.winner_plane_emote` (Meshy full-body clip, empty until uploaded) holding a copy of their own plane in the right hand, nose turning the way the hand moves |
| `src/client/WaitScreen.luau` | "Waiting for a desk" note (only when 12 real players fill the server) |
| `src/client/Loading.luau` | Loading screen |
| `src/client/FlightHUD.luau` | Everything on screen while flying |
| `src/client/FoldOffer.luau` | The "Folded by" card: the part that folded you, its level and price, Paper/Robux buy buttons |
| `src/client/PaperUI.luau` | Shared builder for the paper screens; phone sizes (`isPhone`, `phone`) and the notch-safe sheet; `button` draws its picture at its own shape (Fit) and `fitWords` shrinks words only when they're too long for their paper |
| `tools/art/unlock_pieces.py` | The unlock backpack's pictures: sheet, its corner tapes, title tape, bags, pull, cream button and the 12 unzip frames (a real zipper's gap), plus the numbers UnlockMoment needs |
| `tools/art/square_from_strip.py` | Cuts a little square of torn paper from a strip's plain middle (the notes' red X box), torn all round from the strip's own edge |
| `src/client/ScreenFit.luau` | The one size rule ([screen fit plan](../plan/SCREEN-FIT-PLAN.md)): screen kind (phone, tablet, PC) and each piece's scale between its least and most; `dodger` keeps notes out of the way ([tutorial](tutorial.md)); Studio hooks `DevPhone`, `DevCover` |
| `src/client/ScreenCheck.luau` | Studio tool: lists overlapping pieces, pieces under Roblox's buttons or off screen, small words and small taps |
| `src/first/UIAssets.luau` | Uploaded menu and HUD image IDs (in ReplicatedFirst, so the loading screen can fetch them first; `src/shared/UIAssets.luau` points to it) |
| `src/shared/UIAssets.luau` | One line: returns `src/first/UIAssets.luau` |
| `src/first/UISheets.luau` | Menu sheets (written by `tools/ui_sheets.py`): packed piece id -> its sheet and spot; `first/LoadingFirst` points every label showing one at its sheet |
| `src/first/BoardPlate.luau` | Draws a menu board (the 2x2 background tiles) as a picture on a flat card inside the menu's own ViewportFrame: Roblox sends 3D pictures GPU-compressed (~7x smaller than as menu pictures). Used by `PaperUI.screen`, `first/LoadingFirst` and `Loading` (preloads) |
| `src/first/MenuArt.luau` | Menu-only pieces (the "3d" group in `first/UISheets`, never on screen while flying) drawn as pictures on flat cards inside little ViewportFrames: downloaded GPU-compressed. `first/LoadingFirst` calls it for every label; `Loading` preloads those files as full-size cards |
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
