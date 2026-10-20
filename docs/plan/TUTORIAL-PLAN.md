# Tutorial plan (2026-10-18)

**Status:** agreed with Alan 2026-10-18 ([decision](../decisions/2026-10-18-tutorial-lessons.md)); being built.
Nothing below is built yet except the private room (see the end).
Based on the [tutorial research](../research/TUTORIAL-RESEARCH-2026-10-18.md) and Alan's direction (2026-10-18):
lessons work in steps, are kept separate, can be skipped and replayed from the menu, look like most games' tutorials,
and the flying ones happen in the player's own timed private room.

## How every lesson works (the same in all of them)
- **Read, then act (Alan 2026-10-19, every step, Flight School too):** a step that starts in the air first freezes the
  world (your plane, the targets, the Pal) with its note up; it moves again by itself after 5 seconds, with a countdown on the button (Space goes early).
  A "look" step ends the same way.
- **One step at a time.** Each step asks for one thing and waits until you've done it. It moves on by itself when
  you do it. Only "look at this" steps have a **Got it** button.
- **The goal note stays up** at the top of the screen (our sticky-note look) until the step is done, with a count
  when there's more than one ("Fly through the hoops 1/3") and a picture of the key or mouse button to press.
- **The thing is always there first.** A step that says "shoot the targets" only appears once the targets are in
  front of you, each with a big bouncing marker and an arrow at the screen edge when it's behind you.
- **Menus and HUD use a spotlight:** everything dims except the one bar or button being explained, an arrow points
  at it, and one short line says what it is.
- **Done = tick + sound.** Each finished step gets a tick on the note and a small "ding".
- **Stuck = hint.** If a step isn't done after about 10 seconds, the marker pulses bigger and the note adds a tip.
- **Crashing is fine.** If you fold during a lesson you're back in the air in a few seconds at the same step.
- **Skip is always visible:** "Skip step" and "Skip lesson". Lessons never pay Paper or XP.
- **Short words:** one instruction per note, about 10 words or fewer.
- **Short lessons:** people leave if it drags (Alan). Each lesson aims at 2-3 minutes.
- **Always say how to come back:** Skip and every end card say "You can replay this any time: Menu > Training",
  and the first time you're back at the main menu the Training button is spotlit once.

## Grabbing attention (Alan's playtest 2026-10-18; approved by Alan the same day)
Alan: small arrows aren't enough; every step must pull your eyes to the one thing to do, "in your face".
- **One focus look for everything**, menus and the 3D world alike: the whole screen dims except a bright hole
  around the target, and the dim breathes in and out. For a button it's the button; for a hoop, fan, bolt or
  enemy the hole follows the thing on screen as you fly.
- **The target itself glows** (a bright outline that shows through walls) with "FLY HERE" and the distance.
- **A bold guide line leads you there** along a path you can really fly; a small see-through arrow by the aim circle
  shows only when you fly the wrong way and points where to turn (Alan's playtests, 2026-10-18).
- **Calm and kind:** one quiet song of its own ("Daisy Fresh"), a soft ding for every hoop and every finished step, no
  classroom chatter; in Flight School you can't crash (you bounce off) and Lift stops at 1 second.
- **Hoops are a fixed course** in clear air in front of the Training Room desk, checked by hand so none sit inside a
  building (one spawned inside the bell tower), with the next hoop already visible, like flight games' ring courses.
- **Real art for the frame and arrow**, in the game's paper-and-crayon look: a concept picture first (Codex), Alan
  OKs it, then it's uploaded (Alan runs uploads). The plain rounded rectangle is a stand-in until then.
- **It fades the moment the step is done** (done: LAUNCH fades on click).

## The lessons
Five separate lessons. The first two run in your own private **Training Room** (a copy of the classroom with
nobody else in it). The rest happen in the normal game.

### Lesson 1: Flight School (Training Room, about 2 minutes)
| # | What you see | What you do | Moves on when |
|---|---|---|---|
| 1 | Your plane on your desk, the LAUNCH button lit | Click LAUNCH (or press Enter) | You're in the air |
| 2 | Three paper hoops in a gentle line ahead, mouse picture | Move the mouse to steer through them (1/3...) | All 3 hoops |
| 3 | Everything greyed out but the Lift bar: "Your Lift drops every second. Fill it up in a fan: follow the line!" The fan glows with its ring and the line | Turn and fly up through the fan | Lift goes up in the fan |
| 4 | Marker on a fly-through with a speed bolt | Fly through it for extra speed | Bolt picked up |
| 5 | The Boost bar pulses, Shift picture | Hold Shift to boost | 1 second of boost |
| 6 | Marker "Line up here" in front of your desk, then on the desk's ring | Fly through your desk's ring to land | Parked at the desk |
| 7 | One spotlight card on the desk buttons: Refill Lift, Repair, Full refold, Fresh plane | Got it | Click |
End card: "Flight School done!" with **Next: Combat Training** and **Go to a match**.
(Lessons use a fixed training plane with a booster and an eraser; your own parts and builds are not touched.)

### Lesson 2: Combat School (Training Room, about 6 minutes): part 1, aiming (added by Alan 2026-10-18)
Alan 2026-10-19: Aiming and Combat Training are one lesson, "Combat School"; the Tutorial button asks Flight School or
Combat School; a first-time player is asked whether they'd like the tutorial. Slow motion first (your plane almost still; shots and targets at full speed; colours soften, music
slows), then full speed. Walls only bounce you off. Targets are paper planes just ahead of you, held still or sweeping left and right across your view (Alan: that's
what shows the lead).
| # | What you do | Moves on when |
|---|---|---|
| 1 | Launch | In the air |
| 2 | Put the dot on the star (the circle steers; the dot is where the guns point) | Dot on the star for 1 s |
| 3 | Shoot three still targets when the dot turns red | All 3 down |
| 4 | Look: the orange ring in front of a plane flying past is where it WILL be (leading) | Got it |
| 4b | Shoot two that fly past left and right: dot on the orange ring (red = on the ring) | Both down |
| 5 | Hold right click with a target in the big eraser circle | Lock starts |
| 6 | Keep holding until the box turns red: the eraser fires and chases (1/2) | 2 down by erasers |
| 7 | Look: erasers reload in 4 seconds | Got it |
| 8 | Full speed: one flying past, with pellets | Down |
| 9 | Full speed: one eraser lock | Down |
Then straight on to part 2.

### Lesson 2, part 2: fighting
One "Paper Pal" at a time, at 60% speed. A Pal can never fold you; only crashes can. Folded by a crash: a countdown,
the plane takes off by itself, the step carries on, and the Pal holds fire until you've flown 2 seconds.
| # | What you do | Moves on when |
|---|---|---|
| 1 | Launch | In the air |
| 2 | Shoot down a Pal that only flies the course | Folded |
| 3 | A Pal shoots you until you're at half Health (Health bar framed), then stops: shoot it down | Folded |
| 4 | Health refilled; a Pal fires slow erasers (INCOMING! / BREAK NOW! explained as they show): dodge one | One misses |
| 5 | Your eraser on the Pal | Your eraser hits |
End card: "You're ready!" with **Go to a match**.

### The Hangar Range (not a lesson; the Training board's fourth card)
Alan's design, 2026-10-19 ([decision](../decisions/2026-10-19-range-map-and-hangar-tour.md)); look: concepts
`assets/references/ui-concepts/range-stage-view-2.png` (the scene), `range-stage-tear-2.png` (a target tearing),
`target-damage-sheet.png` (the damage steps), built from separate 2D pieces put back together to match.
- **Where:** a private room like the Training Room; you appear on a big kid-made puppet-theatre stage far from the
  classroom (same place file; only the stage loads around you). Studio stands in for it like the Training Room does.
- **Your plane** hangs still, seen from the wings up (weapons in view); you move it left, right, up and down and shoot
  freely. Heat and reload stay real, so you learn how each weapon really behaves.
- **Targets:** flat red or blue paper-plane cut-outs (team colours only) on sticks rising from behind three ledges:
  close (how fast a weapon tears one), middle, far by the scenery (leading and range). They move back and forth and up
  and down; at the side the stick turns and the cut-out flips. Each hit tears it more (5 damage steps) until it splits,
  bursts and falls; the stick sinks and a fresh one rises.
- **Side board** (Alan 2026-10-19, [decision](../decisions/2026-10-19-range-row-picker-and-aim-pick.md)): stands at the
  right edge of the still view like the concept, and **you shoot its strips** to use it (like the row plates). The
  difficulty strips: Noob (slow, steady), Challenge (faster, wider sweeps), Veteran (fast, quicker turns), Maneuvers
  (sudden swoops and dodges like real enemies). The score card (shots, hits, %) starts over on any change (difficulty,
  rows, loadout) and has a reset strip.
- **Range loadouts:** five builds of its own, kept only for the Range and saved with your profile (they never become
  your match builds); any part works there, even ones you don't own yet. Numbered strips (shoot one, or keys 1-5)
  swap your plane instantly; **Hangar** opens the in-game hangar on top to edit them; saving swaps your plane at once.
- **First visit:** sticky notes point at the picker, the score card, the loadout strips and how to leave, one at a time.
- **Leave:** Menu > Leave takes you back to a normal room. From a match, opening it first says you'll leave the match.
- **Build order:** (1) rough build for feel: stand-in stage, one moving cut-out that flips and tears, the held plane and
  its camera; Alan plays it. (2) 2D pieces from the concepts (Codex), checked on a contact sheet, uploaded by Alan.
  (3) Rows, patterns and the picker. (4) Score card, loadout strips and Hangar. (5) Sticky notes. Then the Hangar Tour.

### Lesson 3: Hangar Tour (in the Range, spotlight through the menus, about 2 minutes)
Played from the Training board (Alan 2026-10-19): it moves you to the Range, walks the Hangar, then "Now try it!" hands
you to the Range with the plane you built and its sticky notes.
1. The part tabs: nose, wings, body, tail, weapons, boost. Click the Wings tab.
2. A part card: click one to try it on; the plane in the middle changes.
3. The stat bars (health, speed, turn, Lift, capacity): what goes up and down when you swap parts.
4. A locked card: it needs a level and Paper. Where the level bar and your Paper are.
5. The Weapons tab: the numbered weapon spots on your plane. Click a spot, then a weapon.
6. Capacity and spot sizes: a red X means it doesn't fit, and the card says why.
7. Two weapon types per plane: left click fires one, right click the other.
8. Save: your five saved builds. Click Save.
9. Flying it: pick a build at your desk; "Full refold" changes your plane mid-match (costs Paper), "Fresh plane" is free.

### Lesson 5: Match Tips (in your first real matches, each shown once)
Short notes that pop up the first time something happens, not before:
- First spawn: "Fold enemy planes for points. Most points wins."
- First Team match: "You're on Red/Blue. Don't shoot the blue outlines."
- First Airspace match: "Hold the zone with your team." (arrow to the zone)
- First fold, first time folded, first scrape on a wall, first time near the edge, first time Lift is low
  ("Land at your desk or find a fan"), first vote lap ("Fly through a ring to vote").
Can be turned off in Settings.

## The Training board (menu)
The main menu's Training button (Alan 2026-10-20: was Tutorial) opens a **Training board** listing the lessons, each with a tick when done and
**Play** / **Replay**: Flight School, Combat School, Hangar Tour and the Range (no tick: not a lesson). Flight School
and Combat School move you to your Training Room (from a match it first warns you'll leave it); the Hangar Tour and
the Range move you to the Range map. Match Tips are not on it (on/off in Settings)
([decision](../decisions/2026-10-19-range-map-and-hangar-tour.md)).

## The Training Room (private and timed)
- A new player's first join asks "Want a quick tutorial?"; Yes: their Training Room, Flight School, then Combat School, then a match.
- Only you are in it. No time limit (Alan 2026-10-19: "people will leave, or they'll be kicked for being idle").
  When the lessons are done or skipped, you're moved to a normal room for your level.
- If the move fails, it tries again; if it still fails, a button says "Try again".
- Which lessons you've finished is saved, so the game knows not to send you back unless you ask.

## Alan's answers (2026-10-18)
Fixed training plane: yes. 15 minutes is too long; keep it quick (8-minute room, Claude's pick). First join: Flight
School, then Combat Training, then play; skippable, and it must tell them they can come back. Match Tips: off switch
in Settings.

## What already exists and what changes
- **Kept:** the private room (built and committed: new players go to it, no match or bots; Skip moves them on;
  the real move is only testable after a private publish, Alan's go).
- **Replaced:** the current sticky-note steps (they point at things that aren't on screen), the one practice target
  (becomes the hoops, targets and enemies above), and the "matches played = 0" first-join check (becomes the saved
  lesson ticks). A half-built enemy step exists only on disk and is not committed.

## Build order after Alan's OK
1. The step engine everyone shares: goal note, key pictures, world markers, spotlight, tick and hint, Skip.
2. Flight School. 3. Combat Training. 4. Training board and saved ticks. 5. Hangar Tour.
6. Match Tips. 7. Weapons Range.
Each lesson is checked in Studio Play with screenshots of every step and shown to Alan before the next.

Back to [HOME](../HOME.md)
