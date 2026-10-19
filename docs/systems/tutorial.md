# Tutorial

## What the player sees
A new player's first join goes straight into a guided lesson in an empty copy of the classroom: flying (steer, Lift,
fans, landing), shooting paper targets, then a fight with one enemy, then what every part of the HUD means, the
hangar, each weapon, and how building a plane works. It can be skipped and replayed, and never pays rewards.

## Where it stands (2026-10-19)
Being built now (after Stage 10). **Its own room works:** a brand-new player (no matches played) is sent, once the
classroom has loaded, to a fresh private server of the same place that nobody else can join; the Tutorial button
does the same from any room. The room has no match, no clock, no bots and no rewards; the lesson starts by itself.
Finishing or skipping sends the player to a normal room for their level, tagged "tutorial seen" so that room doesn't
send them straight back. A player who leaves before playing a match sees it again on their next visit.
Studio stands in for the room: set the `DevTutorialRoom` attribute on `ReplicatedStorage.FlyFightPaper` during
Play; Skip turns the room back into a normal match. The live room move needs a private publish to test (Alan's go).
Lessons follow the agreed [tutorial plan](../plan/TUTORIAL-PLAN.md). **Flight School is approved by Alan (2026-10-18,
[decision](../decisions/2026-10-18-flight-school-approved.md)). Aiming and Combat Training are built (2026-10-19),
not yet seen in Play.** The lessons run in order: Flight School, Aiming, Combat Training (the end card has "Next"). Flight School: the step engine
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
and, a beat later, each finished step. Alan's first look: [playtest](../playtests/2026-10-18-flight-school-attention.md). Combat Training not started; a
half-built enemy helper (`tutorialFoe` in RoundRuntime, the foe rule in CombatService:enemy) waits for it.

## Rules
See "Tutorial (built last)" in [Milestones](../plan/MILESTONES.md). Practice is never reward-eligible.
Flight School can't be lost (Alan 2026-10-18): its plane (`p.gentle`, set when the client asks for practice with the
lesson "flight"; its model carries `Gentle` so the pilot's client doesn't crumple it either) only bounces off walls,
the floor, duct fans and the room's edge; its Lift stops at 1 second and its Boost at 0.01.
Aiming can't be lost either (same gentle plane). Combat Training keeps normal crashes, but a Pal can never fold you
(its hits stop at 1 Health) and Pals and targets never ram you. A respawned practice plane is the same training plane
(it used to come back as the player's own build, often with no booster: the "no boost" report).
A lesson step asks the server for what it needs with `RoundAction("lesson", {slow, repair, drill, pal})`; the
server keeps counts on the player (`DrillDown`, `PalFolds`, `PalEraserMisses`, `PalEraserHits`, `EraserHits`).
Studio: set `DevLesson` (flight / aim / combat) on `ReplicatedStorage.FlyFightPaper` on the client to open a lesson.

## Code
| File | What it does |
|---|---|
| `src/client/Tutorial.luau` | Lesson step engine: goal note, markers, spotlight, ticks, hints, Skip |
| `src/client/TutorialLessons.luau` | Each lesson's steps: Flight School, Aiming, Combat Training |
| `src/shared/TrainingCourse.luau` | The Training Room's course points, practice targets and slow-motion share |
| `src/server/RoundRuntime.luau` | Tutorial room: no rounds or bots; first-join routing; practice flights |
| `src/server/Matchmaking.luau` | Sends a player to a fresh private tutorial room and back |
| `src/server/MatchmakingAdapter.luau` | Reserves tutorial rooms; never lists them |
| `src/shared/CombatRules.luau` | `practiceTargetPose`: where the practice target goes |
| `src/server/CombatService.luau` | Practice pilots are nobody's enemy |

## Tuning numbers
None yet.

## Related
- [The tutorial is built last](../decisions/2026-10-13-tutorial-built-last.md)
- [Menus and HUD](menus-and-hud.md)

Back to [HOME](../HOME.md)
