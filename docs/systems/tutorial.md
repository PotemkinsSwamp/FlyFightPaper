# Tutorial

## What the player sees
A new player's first join goes straight into a guided lesson in an empty copy of the classroom: flying (steer, Lift,
fans, landing), shooting paper targets, then a fight with one enemy, then what every part of the HUD means, the
hangar, each weapon, and how building a plane works. It can be skipped and replayed, and never pays rewards.

## Where it stands (2026-10-22)
**Room moves (Alan's phone runs, v413, 2026-10-28):** the private tutorial room does know it is one (every join and
move there logs `RoomClass` tutorial). The failure was the way out: the tutorial sent him to the public room he had
just left (its list entry was still fresh, under 45 s), which had closed, so the move failed twice ("GameEnded").
Fix: a closing room crosses itself off its list (`Matchmaking` BindToClose → `MatchmakingAdapter:forget`).
Each join's log entry carries `RoomClass` (public, tutorial, rookie, regular or the error) and every room move.
**Phone fixes from Alan's run (2026-10-28):** a step that points at a HUD weapon or Boost row frames the round touch
button instead (FIRE, 2, BOOST; they show during a lesson's read pause); the note waits while the player moves to the
tutorial room (it showed "Tap LAUNCH" on the menu for 3 s); the Hangar's mount numbers are twice the size on a phone. Round buttons get the round crayon ring; the first shot
step frames FIRE and the eraser card frames 2; Skip reads "Skip / (hold: all)" on two lines; the naming step shows no
key on a phone. A note that dodges to a side now sits under Health and Lift (it sat 58 points high: ScreenFit mixed
two ways of counting from the top). Seen in Studio at a phone's size (2026-10-28); not yet on Alan's phone.
**Phones (Alan 2026-10-28):** the lesson note was too small and covered the middle of the view; on a phone it is now
860 x 200 (before scaling) up in Roblox's top bar right of Health and Lift (Alan: "moved up"), words about 20 points
(were 15), Got it and Skip beside the words with no key names; a tip takes the title's line. **Out of the way (Alan
2026-10-28, all screens):** lesson notes, match tips and Range notes stay home unless they keep covering what matters
(the step's target or highlight, its labels, the aim marks, enemies within 300 studs) for 0.4 s; then they slide to the
right side, left side (tilted 3 degrees) or bottom middle until the step or tip changes (`ScreenFit.dodger`). Never at
the desk. On a phone the lesson note turns 560 x 400 at a side. Seen in Studio at phone size (bottom and right spots,
both shapes); match tips and Range notes not yet seen (an account that has seen them all doesn't get them). Not yet
seen by Alan.
**Flight School, Combat School, the Hangar Tour and the Training board approved by Alan 2026-10-22**
([decision](../decisions/2026-10-22-tutorials-approved.md)). **Match Tips built 2026-10-23, not yet seen by Alan**:
nine one-line tips in real matches, each once (saved), a small sticky note under the match strip, gone after 6 s or
Space, 20 s apart, only while a round is on (never in the break, over a menu or the tutorial's question; the vote-lap
tip was dropped 2026-10-23: the vote card says it); tips a finished lesson taught are skipped (Flight
School: Lift, desk; Combat School: being folded); Settings > Match tips: On/Off. Seen working in a bots match: desk,
take-off (free-for-all), folded, low Lift (arrow at the bar), edge, your first fold (the last three faked); the team,
Airspace and scrape tips are untested; Alan: "they work" (2026-10-23). **The Range's first-visit
sticky notes work: Alan approved them** (2026-10-23, after two rounds of his notes): the tutorial's own note, top middle, five
notes one at a time, each with the lessons' crayon arrow just outside what it explains (an up row plate, Reset, Range
Menu, Hangar; over the Hangar, its Back button, note bottom right; the Menu button), then the last note, "The Range is
yours... to leave, press Menu, then Leave", at the Menu button (six in all); a note goes when you use its thing or press Space ("Got it"), K ("Skip all") ends them,
no timer, no shooting; never during a lesson or under a menu; seen once (saved as
`lessons.rangeNotes`, no tick on the board). **Its own room works:** a brand-new player (no matches played) is asked once the
classroom has loaded, "Welcome, pilot! Want a quick tutorial?" (Yes / No thanks, and where to find it later; Alan
2026-10-19: ask, like most games). Yes, or the Training button (named Tutorial until Alan 2026-10-20; it first asks "Which lesson?": Flight School or
Combat School), opens a fresh private server of the same place that nobody else can join, carrying the lesson picked. The room has no match, no clock, no bots and no rewards; the lesson starts by itself.
Finishing or skipping sends the player to a normal room for their level, tagged "tutorial seen" so that room doesn't
send them straight back. A player who leaves before playing a match sees it again on their next visit.
Studio stands in for the room: set the `DevTutorialRoom` attribute on `ReplicatedStorage.FlyFightPaper` during
Play; Skip turns the room back into a normal match. The live room move needs a private publish to test (Alan's go).
Lessons follow the agreed [tutorial plan](../plan/TUTORIAL-PLAN.md). **Flight School is approved by Alan (2026-10-18,
[decision](../decisions/2026-10-18-flight-school-approved.md)). Combat School is approved by Alan (2026-10-19,
[decision](../decisions/2026-10-19-combat-school-approved.md)) after sixteen rounds of notes.** **The Training board** (2026-10-19, built, not yet seen in Play): the Training button
(main menu and pause menu) opens its own cork board (art in `assets/ui/trainingboard/`, concept
`training-board-c.png`): Flight School, Combat School, Hangar Tour and the Range, each a pinned sheet with a Play strip;
a lesson gets a tick and Replay once finished (saved on the account: the end card sends `lessonDone`, the server
ticks it only in the tutorial room). From a match, Play first asks "Leave this match?"
(the lesson runs on another server). The welcome question goes only to a player with no matches and no ticks. The
Training Room has no time limit (Alan 2026-10-19: people leave, or Roblox kicks them for being idle).
**The Hangar Range** (built 2026-10-19; Alan has played each step; last layout not yet seen in Play;
decisions: [stage and picker](../decisions/2026-10-19-range-row-picker-and-aim-pick.md),
[controls and menu](../decisions/2026-10-19-range-controls-and-menu.md)). A **room, not a lesson** (`room=true`: no note,
no skipping; Menu > Leave ends it). Your build hangs still and level on a puppet-theatre stage (`Pinned`) seen from a
still camera; everything is painted flats from `assets/ui/range/` (UIAssets `range`). The crosshair moves over the
screen within `RANGE.yaw`/`up`/`down`; the plane points at the spot under it (a control or cut-out, else the aim-help
target's lead ring, else the far row), and the green dot is drawn at that spot's range so it sits on the circle once
the plane has turned. **Shots go where the green dot (the nose) points**, at that range (CombatEffects.aim; Alan
2026-10-21): the nose trails the crosshair while tracking, so the dot, not the crosshair, says where shots land. **Targets:**
two per row, painted cut-outs on long sticks (`RangeTarget`) sweeping wide and high over most of the stage, tearing in
4 pictures, splitting and rising again. **The card is the target itself** ([decision](../decisions/2026-10-21-range-targets-are-the-cards.md);
built 2026-10-21, not yet played): no plane behind it. It holds its own Health, is hit as the flat card you see
(`HitShapes.card`) on its set path (`DrillPath`), and an eraser locks onto it (`CombatService:addCard`, in
`workspace.RangeCards`). The lead ring picks it like a plane, but it gets no enemy diamond or arrow. Combat School's
targets stay real paper planes.
**Difficulty** (`Course.DIFFICULTY`): Noob 0.6x, Challenge 1x, Veteran 1.4x, Maneuvers 1x plus a weave.
**Controls, clicked with the crosshair** (RangeBoard; the guns still fire): the row plates on the floor (Close, Medium,
Long range, All; sticks stand on their hinges), the score card + Reset hanging top right (`RangeShots`/`RangeHits`,
start over on any change), Range Menu and Hangar strips hanging top left, level with the score card (Alan 2026-10-20; the game's Menu
button, which the crosshair can click too, is above them), and the Range Menu, which drops on strings on a spring: Loadouts 1-5 (also keys 1-5; swap
the plane in the air) and Difficulty plus Edit in Hangar (saving there swaps the plane). The loadouts are the Range's own
five builds (saved as `rangePresets`, any part allowed, never used in matches; you start on the one you last flew
there). The Hangar opened in the Range edits them ("Range only" on parts you don't own); built 2026-10-19, not yet played.
Flight School's end card has "Next: Combat School", and Combat School's "Next: Hangar Tour" (Alan 2026-10-22). Finishing in the air freezes everything (targets, Pal, your plane) and frees the mouse for the card's buttons; either button lets go first (Alan 2026-10-22). The Hangar Tour's card has no buttons: a click on it or Space closes it, or it goes after 7 s. A Pal kept from another step is refolded when it carries the wrong weapon (only the eraser Pal has an eraser). Flight School: the step engine
(goal note with key picture, tick and ding, hint after 10 s, Skip: tap K = step, hold K = lesson) and its 7 steps are
written; lessons fly the fixed training plane (pellets, eraser, booster); the news note and kill feed are hidden during
lessons (Alan). In Studio the Training button turns the room into the tutorial world (match paused, bots gone) since
Studio can't move players between servers; the match resumes after.
**"Grabbing attention" pass (2026-10-18, built, not yet seen in Play):** one focus look for every step, in the
art of Alan's approved concept (`assets/references/ui-concepts/attention-*.png`; pieces in `assets/ui/tutorial/`,
ids in UIAssets `tutorial`). The screen dims except a hole on the target (one frame with a screen-wide outline, so
the hole is round for 3D targets and a rounded box for buttons); a crayon frame (9-slice box, or ring) breathes and
wobbles on it with six "look here" marks pulsing out; a 3D target glows through walls (Highlight) and gets a taped
tag under it ("FLY HERE 120": what to do and how far). A dashed crayon guide line crawls from the plane to the
target along a path you can really fly: straight when clear, else along the bots' air routes
(`src/shared/AirRoutes.luau`, built on the client once per lesson, 0.1 s; re-planned every second), drawn as a bold (4.5 studs) smooth
curve. Only when you fly the wrong way (the way to go more than 75 degrees off the nose), a see-through paper arrow
by the aim circle points where to turn, backward-ish if it's behind you. Hoops are a fixed course of three
in clear air ahead of DeskSouth3 (hand-checked in Studio: 50 studs of empty air round each, legs clear), ending
heading north with the west fan 90 degrees to the left (time to read the Lift note before the fan), all shown at once, red and white like the concept, the current one bright. A HUD bar the step talks about gets its own breathing frame
all step, beside the 3D target's focus; the Lift step instead spotlights the Lift bar (the rest dimmed) while the fan
keeps its glow, line and turn arrow. Sound: one quiet looped song ("Daisy Fresh"), and the same soft ding for each hoop
and, a beat later, each finished step. Alan's first look: [playtest](../playtests/2026-10-18-flight-school-attention.md).
**Combat School** (Alan 2026-10-18/19, [decision](../decisions/2026-10-19-aiming-and-combat-lessons.md)), part 1,
aiming: in slow motion first (your plane at 6% speed, almost still, Lift kept full; turning, shots and targets at full speed; colours
soften, the music slows, a whoosh and a "SLOW MOTION" tag): the circle vs the dot (a star), three still targets
(the dot turns red = it will hit; the dot is always green/red, whatever crosshair colour is set), two that sweep left and right across in front of you at a real plane's speed (crossing your view is what shows
the lead): first a look step on the orange ring ("AIM HERE", "that's called leading"), then shoot them (350 studs away, crossing at 60 studs/s: measured in Play, faster
crossings left the nose trailing the ring so the dot never sat in it); then one crossing twice as fast (120
studs/s), still in slow motion (Alan 2026-10-19: at full speed you just caught up with it and felt no lead). HUD
pieces it points at (crosshair, lead ring, eraser circle) get a soft frame: thin, half see-through, no dim.
Until part 3 the plane has two pellet guns and no eraser (Alan 2026-10-19: its circle, sounds and lock-on distract
from aiming and suggest every plane has one).
**Targets are real paper planes** placed in clear air just ahead of where you are when the step starts (checked
against the room's exact shapes; the course points are the fallback), held still or sweeping
(`src/shared/TrainingCourse.luau`), so every aim help works on them as in a match. Part 2, fighting: one "Paper Pal"
at a time, at full speed again, appearing in the air 400-700 studs ahead (within 40 degrees of the nose, hidden behind
a building when it can be; never out of a hangar or off to the side: Alan 2026-10-19, "coming out of nowhere";
BotService:placePal), facing away, your speed when you're near and 85% while you're over 250 studs off (Alan 2026-10-21: chasing one took a minute; 2026-10-22: 70%/95% was too easy, no chase), turning at 80%, keeping its own heading and banking 25-50 degrees one way or the other every 2.5-4 s
and turning further only when blocked, never a stunt and never away from you (Alan 2026-10-19/21: noob-level, "in a straight line"; turning away from you made you both circle): one that never shoots, and one that starts behind you, off to one side, 400-500 studs back, flying away
(always placed afresh when the step starts or restarts; Alan 2026-10-21: it kept appearing ahead). Its "shots" are fakes (BotService:palAmbush; Alan 2026-10-21/22): from the moment the note lets you go, pellets appear 70 studs from you on its side (closer if a wall is in the way), out of sight, and hit,
only while it is over 60 degrees off your nose, until your Health is down to half (its hits can't fold you; Alan: "whittle your health down"; measured in Play: hits from 0.5 s after the note, about 8 Health a second); once you've been hit the note says "It's shooting you from behind!" while it's back there. You turn round, see it running, and chase it down. Neither carries an eraser. Part 3, the eraser:
the plane refolds in the air with an eraser on right click (`eraser=true`), then in slow motion the big lock circle and
lock (holding right click fires one at full lock) on one target, its reload (the card comes while it fills, before
the next shot; a second slow-motion lock was cut as redundant), one lock at full speed, then a Pal whose erasers appear on their own 300 studs ahead
of you, toward the Pal, already chasing you, never while the note holds you still nor in a step's first second (before its freeze
reaches the server, an eraser used to slip out and hit the frozen player) (BotService:palEraser; 80% speed, 10% slower after each hit, never under 60%)
until you dodge one, then your eraser on it. Lessons have the same 3-degree aim assist as matches ([decision](../decisions/2026-10-19-less-aim-assist.md)).
Pals have half a normal plane's Health (Alan 2026-10-19: full Health was frustrating).
Folded by a crash: a countdown note, the plane takes off by itself, the step carries on and the Pal holds fire until
you've flown 2 seconds; after 3 crashes on a step, a tip.

**The Hangar Tour** (lesson 3, built 2026-10-21; Alan's first play the same day, then fixed and played through by
Claude: step 4 walks the stat sheet row by row in kid words, step 11 is three pages (Weight, the click line, and a
red X only when a card really has one), the last step counts 3 different targets, the name is selected on click;
the note sits bottom right over the Hangar; the screen is covered in cork until the Hangar is open, so the Range
never flashes first; its ding is 20% softer (`softDing`) and comes with the click; a step with a visible change
lingers 2.3 s with the light off (`step.linger`); [plan](../plan/TUTORIAL-PLAN.md) "Lesson 3"): the
Training board's card moves you to the Range on the Range builds (the server treats lesson `hangar` like `range`),
`lesson.ready` puts the plane on the stage and opens the Range's Hangar (again if it gets closed, never over the game
menu) on the step's page, then the 14 steps run on the real screens. A menu lesson (`lesson.screen`) shows its note
over that menu, finds buttons only on it, has no read pause, moves the note out of the spotlight's way, and puts
see-through walls round the spotlight so only the lit button can be clicked (a look step: only Got it). A look step
can have pages (`step.pages`): Got it turns the page. Steps watch the
Hangar's own state (`Hangar.tour`: page, tab, picked build, spot, draft), not clicks, since most clicks redraw the
Hangar. The tick is saved as `hangar`; the end card (no buttons, gone after 7 s) hands over to the Range
(`lesson.stay`), and skipping keeps you there too.

## Rules
See "Tutorial (built last)" in [Milestones](../plan/MILESTONES.md). Practice is never reward-eligible.
Flight School can't be lost (Alan 2026-10-18): its plane (`p.gentle`, set when the client asks for practice with the
lesson "flight"; its model carries `Gentle` so the pilot's client doesn't crumple it either) only bounces off walls,
the floor, duct fans and the room's edge; its Lift stops at 1 second and its Boost at 0.01.
Combat School's Lift stays full the whole lesson (`p.keepLift`; Alan 2026-10-19: Lift isn't what it teaches).
Its aiming part can't be lost either (the step asks for gentle); its fights keep normal crashes, but a Pal can never fold you
(its hits stop at 1 Health) and Pals and targets never ram you. A respawned practice plane is the same training plane
(it used to come back as the player's own build, often with no booster: the "no boost" report).
Read, then act (Alan 2026-10-19): every step that starts in the air holds the player's plane, targets and Pal still
(FlightService:freeze, the same hold as the winners' moment) with its note up for 2.5 seconds (a look step's longer note 5), a bar draining along its Go button (Alan 2026-10-19: 5 s and
the 5-4-3-2-1 countdown were too long; Space goes early; Alan: nobody should have to press anything); nothing
counts while frozen; a look step's Got it unfreezes and finishes it; Flight School too. While held (model attribute
`Held`) the pilot's aim stays on the nose, the mouse is free to click Go, and nothing fires (the aim used to drift
with the mouse, so the plane pointed somewhere else when it let go).
A lesson step asks the server for what it needs with `RoundAction("lesson", {freeze, slow, gentle, repair, eraser, drill, pal})`; the
server keeps counts on the player (`DrillDown`, `PalFolds`, `PalEraserMisses`, `PalEraserHits`, `EraserHits`).
Studio: set `DevLesson` (flight / combat) on `ReplicatedStorage.FlyFightPaper` on the client to open a lesson. To test
aiming, the player attribute `DevAimLead` (DevTools.luau) steers at the HUD's orange ring when there's clear air to it
(else it flies the loop above the city) and holds the trigger (`DevFire`, CombatController) only while the dot is on
the ring; `DevAim` steers at a direction.
Every player's last 40 shots are recorded in Studio on the player attribute `DevShotLog` (CombatService): hit, wall or
air, the gun range sent, and how far and where each passed the nearest enemy's centre, so a playtest's misses can be read.

## Code
| File | What it does |
|---|---|
| `src/client/Tutorial.luau` | Lesson step engine: goal note, markers, spotlight, ticks, hints, Skip |
| `src/client/TutorialLessons.luau` | Each lesson's steps: Flight School, Combat School (aiming, then fighting), the Hangar Tour |
| `src/shared/TrainingCourse.luau` | The Training Room's course points, practice targets, slow-motion share and the Range's spot and targets |
| `src/client/RangeTargets.luau` | The Range's targets drawn as painted cut-outs on sticks that turn over, tear, split and sink |
| `src/server/RangeStage.luau` | The Range's puppet-theatre stage built from the painted pieces, measured from the concept; its controls (row plates, score card, Reset, Menu note, the menu on strings) |
| `tests/unit/RangeAccuracy.spec.luau` | Fires ~3,700 shots dead on the lead ring at every Range target, row, difficulty and steady weapon; all must hit |
| `src/client/RangeNotes.luau` | The Range's first-visit sticky notes and their arrows |
| `src/client/MatchTips.luau` | Match Tips: the one-line notes in your first real matches, each shown once |
| `src/client/RangeBoard.luau` | The Range's controls: the crosshair as cursor, the menu dropping and pulling up, score card, rings, keys 1-5 |
| `src/server/RoundRuntime.luau` | Tutorial room: no rounds or bots; first-join routing; practice flights |
| `src/server/Matchmaking.luau` | Sends a player to a fresh private tutorial room and back |
| `src/server/MatchmakingAdapter.luau` | Reserves tutorial rooms; never lists them; carries the lesson picked |
| `src/server/CombatService.luau` | Practice pilots are nobody's enemy except their lesson's; a Pal can't fold you; slow Pal erasers |
| `src/server/BotService.luau` | The Pals' brain: wandering, when they turn on you and shoot |
| `src/server/FlightService.luau` | Gentle planes, slow motion, flying the practice targets |

## Tuning numbers
`TrainingCourse.SLOW_MO` (.06), target health, sweep size and speed in `TrainingCourse.DRILLS`; Pal speed (1.0 of its plane's speed), turn share (.8, BotService) and first
eraser speed (.8) in `RoundRuntime:lesson`; the soft frame's `SOFT_SLICE`/`SOFT_SEE_THROUGH` in `Tutorial.luau`.

## Related
- [The tutorial is built last](../decisions/2026-10-13-tutorial-built-last.md)
- [Menus and HUD](menus-and-hud.md)

Back to [HOME](../HOME.md)
