# Tutorial

## What the player sees
A new player's first join goes straight into a guided lesson in an empty copy of the classroom: flying (steer, Lift,
fans, landing), shooting paper targets, then a fight with one enemy, then what every part of the HUD means, the
hangar, each weapon, and how building a plane works. It can be skipped and replayed, and never pays rewards.

## Where it stands (2026-10-19)
Being built now (after Stage 10). **Its own room works:** a brand-new player (no matches played) is asked once the
classroom has loaded, "Welcome, pilot! Want a quick tutorial?" (Yes / No thanks, and where to find it later; Alan
2026-10-19: ask, like most games). Yes, or the Tutorial button (which first asks "Which lesson?": Flight School or
Combat School), opens a fresh private server of the same place that nobody else can join, carrying the lesson picked. The room has no match, no clock, no bots and no rewards; the lesson starts by itself.
Finishing or skipping sends the player to a normal room for their level, tagged "tutorial seen" so that room doesn't
send them straight back. A player who leaves before playing a match sees it again on their next visit.
Studio stands in for the room: set the `DevTutorialRoom` attribute on `ReplicatedStorage.FlyFightPaper` during
Play; Skip turns the room back into a normal match. The live room move needs a private publish to test (Alan's go).
Lessons follow the agreed [tutorial plan](../plan/TUTORIAL-PLAN.md). **Flight School is approved by Alan (2026-10-18,
[decision](../decisions/2026-10-18-flight-school-approved.md)). Combat School is approved by Alan (2026-10-19,
[decision](../decisions/2026-10-19-combat-school-approved.md)) after sixteen rounds of notes.** **The Training board** (2026-10-19, built, not yet seen in Play): the Tutorial button
(main menu and pause menu) opens its own cork board (art in `assets/ui/trainingboard/`, concept
`training-board-c.png`): Flight School, Combat School, Hangar Tour and the Range, each a pinned sheet with a Play strip;
a lesson gets a tick and Replay once finished (saved on the account: the end card sends `lessonDone`, the server
ticks it only in the tutorial room). Hangar Tour and the Range show an "Almost ready!" note until they're built. From a match, Play first asks "Leave this match?"
(the lesson runs on another server). The welcome question goes only to a player with no matches and no ticks. The
Training Room has no time limit (Alan 2026-10-19: people leave, or Roblox kicks them for being idle).
**The Hangar Range** (2026-10-19 rough build; Alan played it: "conceptually, it works well"). Later that day: the real stage
and targets from its 35 uploaded pieces (`assets/ui/range/`, ids in UIAssets `range`), laid out from the concept as seen
from the Range camera; Alan's first look (Edit preview) asked for a bigger cloth and town, done. Not yet judged in Play;
next the side board. Its card opens it like a lesson that never ends; your own build hangs still on a puppet-theatre
stage far from the classroom (`Pinned`: it only turns to aim; closer camera): sky cloth, cardboard town in three depths,
three ground rows with warm bulbs, curtains, lamps with soft beams (all painted flats lit by their own paint). Three
target planes, drawn as painted cut-outs on sticks (`RangeTarget`), swing and bob in three rows, tilt with their swoop
and turn over on the stick when they change direction, show 4 tear pictures as they're hit, split into two halves with
a scrap burst, sink, and rise again after the respawn wait. After Alan's first Play look ([decision](../decisions/2026-10-19-range-row-picker-and-aim-pick.md)):
the aim stops at the stage edges (`RANGE.yaw`/`pitch`) and the plane stays level; the box round the stage is dressed
(drape walls, cardboard floor, bulbs); two targets per row; the row picker is four knock-down plates on the stage
floor at the bottom of the view (Close, Medium, Long range, All; `RANGE.picks`, `RangeRows`), each on a stick from a
hinged foot; the Range camera sits further back and higher (plane small at the bottom, like the concept) and the aim
reaches 35° down to them. A shot that hits one picks it, it tips back on its hinge with a ting and stays down, the unpicked rows' targets tip back and leave (`Lowered`). Plates use the board's paper strips
until their plane-shaped art is uploaded. Flight School's end card has "Next: Combat School". Flight School: the step engine
(goal note with key picture, tick and ding, hint after 10 s, Skip: tap K = step, hold K = lesson) and its 7 steps are
written; lessons fly the fixed training plane (pellets, eraser, booster); the news note and kill feed are hidden during
lessons (Alan). In Studio the Tutorial button turns the room into the tutorial world (match paused, bots gone) since
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
BotService:placePal), facing away, exactly your speed (Alan 2026-10-19: slower ones are harder, you overshoot and circle them), turning at 80%, flying straight away from you while you're within 600 studs,
turning only when blocked, never a stunt (Alan 2026-10-19: noob-level, "in a straight line", so you feel the chase): one that never shoots, one that comes in from behind you, off to one side, 400-500 studs back with a clear shot (Alan: ahead, you
just chased each other), heads straight for you and hunts you without a break (25% faster
while hunting, or a player flying away is never caught: measured in Play), shooting dead on (no aim wobble or delay,
full lead, its guns meeting at your range: Alan 2026-10-19, "veteran level" until then), until your Health is
down to half (its hits can't fold you; Alan: "whittle your health down"), then pulls round in front of you and runs like step 7's. Neither carries an eraser. Part 3, the eraser:
the plane refolds in the air with an eraser on right click (`eraser=true`), then in slow motion the big lock circle and
lock (holding right click fires one at full lock) on one target, its reload (the card comes while it fills, before
the next shot; a second slow-motion lock was cut as redundant), one lock at full speed, then a Pal whose erasers appear on their own 300 studs ahead
of you, toward the Pal, already chasing you, never while the note holds you still nor in a step's first second (before its freeze
reaches the server, an eraser used to slip out and hit the frozen player) (BotService:palEraser; 80% speed, 10% slower after each hit, never under 60%)
until you dodge one, then your eraser on it. Lessons have the same 3-degree aim assist as matches ([decision](../decisions/2026-10-19-less-aim-assist.md)).
Pals have half a normal plane's Health (Alan 2026-10-19: full Health was frustrating).
Folded by a crash: a countdown note, the plane takes off by itself, the step carries on and the Pal holds fire until
you've flown 2 seconds; after 3 crashes on a step, a tip.

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
aiming, the player attribute `DevAimLead` (DevTools.luau) steers at the HUD's orange ring and `DevAim` at a direction.
Every player's last 40 shots are recorded in Studio on the player attribute `DevShotLog` (CombatService): hit, wall or
air, the gun range sent, and how far and where each passed the nearest enemy's centre, so a playtest's misses can be read.

## Code
| File | What it does |
|---|---|
| `src/client/Tutorial.luau` | Lesson step engine: goal note, markers, spotlight, ticks, hints, Skip |
| `src/client/TutorialLessons.luau` | Each lesson's steps: Flight School, Combat School (aiming, then fighting) |
| `src/shared/TrainingCourse.luau` | The Training Room's course points, practice targets, slow-motion share and the Range's spot and targets |
| `src/client/RangeTargets.luau` | The Range's targets drawn as painted cut-outs on sticks that turn over, tear, split and sink |
| `src/server/RangeStage.luau` | The Range's puppet-theatre stage built from the painted pieces, measured from the concept |
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
