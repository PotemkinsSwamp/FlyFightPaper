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
[decision](../decisions/2026-10-18-flight-school-approved.md)). Combat School is built (2026-10-19); after Alan's
first look its slow motion is slower and the crosshair's frame thinner.** Flight School's end card has "Next: Combat School". Flight School: the step engine
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
the lead): first a look step on the orange ring ("AIM HERE", "that's called leading"), then shoot them, the eraser's big lock circle and lock
(holding right click fires it at full lock), its reload; then full speed for one target and one eraser lock. HUD
pieces it points at (crosshair, lead ring, eraser circle) get a soft frame: thin, half see-through, no dim.
**Targets are real paper planes** placed in clear air just ahead of where you are when the step starts (checked
against the room's exact shapes; the course points are the fallback), held still or sweeping
(`src/shared/TrainingCourse.luau`), so every aim help works on them as in a match. Part 2, fighting: one "Paper Pal"
at a time at 60% speed: one that only flies the course, one that shoots until you're at half Health and then stops,
one that fires slow erasers (half speed, slower again after each hit) until you dodge one, then your eraser on it.
Folded by a crash: a countdown note, the plane takes off by itself, the step carries on and the Pal holds fire until
you've flown 2 seconds; after 3 crashes on a step, a tip.

## Rules
See "Tutorial (built last)" in [Milestones](../plan/MILESTONES.md). Practice is never reward-eligible.
Flight School can't be lost (Alan 2026-10-18): its plane (`p.gentle`, set when the client asks for practice with the
lesson "flight"; its model carries `Gentle` so the pilot's client doesn't crumple it either) only bounces off walls,
the floor, duct fans and the room's edge; its Lift stops at 1 second and its Boost at 0.01.
Combat School's aiming part can't be lost either (the step asks for gentle); its fights keep normal crashes, but a Pal can never fold you
(its hits stop at 1 Health) and Pals and targets never ram you. A respawned practice plane is the same training plane
(it used to come back as the player's own build, often with no booster: the "no boost" report).
Read, then act (Alan 2026-10-19): every step that starts in the air holds the player's plane, targets and Pal still
(FlightService:freeze, the same hold as the winners' moment) with its note up for 5 seconds, counting down on its button (Space goes early; Alan: nobody should have to press anything); nothing
counts while frozen; a look step's Got it unfreezes and finishes it; Flight School too. While held (model attribute
`Held`) the pilot's aim stays on the nose, the mouse is free to click Go, and nothing fires (the aim used to drift
with the mouse, so the plane pointed somewhere else when it let go).
A lesson step asks the server for what it needs with `RoundAction("lesson", {freeze, slow, gentle, repair, drill, pal})`; the
server keeps counts on the player (`DrillDown`, `PalFolds`, `PalEraserMisses`, `PalEraserHits`, `EraserHits`).
Studio: set `DevLesson` (flight / combat) on `ReplicatedStorage.FlyFightPaper` on the client to open a lesson.

## Code
| File | What it does |
|---|---|
| `src/client/Tutorial.luau` | Lesson step engine: goal note, markers, spotlight, ticks, hints, Skip |
| `src/client/TutorialLessons.luau` | Each lesson's steps: Flight School, Combat School (aiming, then fighting) |
| `src/shared/TrainingCourse.luau` | The Training Room's course points, practice targets and slow-motion share |
| `src/server/RoundRuntime.luau` | Tutorial room: no rounds or bots; first-join routing; practice flights |
| `src/server/Matchmaking.luau` | Sends a player to a fresh private tutorial room and back |
| `src/server/MatchmakingAdapter.luau` | Reserves tutorial rooms; never lists them; carries the lesson picked |
| `src/server/CombatService.luau` | Practice pilots are nobody's enemy except their lesson's; a Pal can't fold you; slow Pal erasers |
| `src/server/BotService.luau` | The Pals' brain: when they chase, shoot or fly the course |
| `src/server/FlightService.luau` | Gentle planes, slow motion, flying the practice targets |

## Tuning numbers
`TrainingCourse.SLOW_MO` (.06), target health, sweep size and speed in `TrainingCourse.DRILLS`; Pal speed (.6) and first
eraser speed (.5) in `RoundRuntime:lesson`; the soft frame's `SOFT_SLICE`/`SOFT_SEE_THROUGH` in `Tutorial.luau`.

## Related
- [The tutorial is built last](../decisions/2026-10-13-tutorial-built-last.md)
- [Menus and HUD](menus-and-hud.md)

Back to [HOME](../HOME.md)
