# Tutorial plan (2026-10-18)

**Status:** agreed with Alan 2026-10-18 ([decision](../decisions/2026-10-18-tutorial-lessons.md)); being built.
Nothing below is built yet except the private room (see the end).
Based on the [tutorial research](../research/TUTORIAL-RESEARCH-2026-10-18.md) and Alan's direction (2026-10-18):
lessons work in steps, are kept separate, can be skipped and replayed from the menu, look like most games' tutorials,
and the flying ones happen in the player's own timed private room.

## How every lesson works (the same in all of them)
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

## Grabbing attention (Alan's playtest 2026-10-18; proposal, waiting for his OK)
Alan: small arrows aren't enough; every step must pull your eyes to the one thing to do, "in your face".
- **One focus look for everything**, menus and the 3D world alike: the whole screen dims except a bright hole
  around the target, and the dim breathes in and out. For a button it's the button; for a hoop, fan, bolt or
  enemy the hole follows the thing on screen as you fly.
- **The target itself glows** (a bright outline that shows through walls) with "FLY HERE" and the distance.
- **Off-screen: you're turned toward it.** A big arrow in front of your plane points the way (like racing games'
  direction arrow), plus a glowing guide line from your plane to the target.
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
| 3 | The Lift bar pulses: "Lift keeps you flying. Fill it at a fan." Marker on the nearest fan | Fly up through the fan | Lift goes up in the fan |
| 4 | Marker on a fly-through with a speed bolt | Fly through it for extra speed | Bolt picked up |
| 5 | The Boost bar pulses, Shift picture | Hold Shift to boost | 1 second of boost |
| 6 | Marker "Line up here" in front of your desk, then on the desk's ring | Fly through your desk's ring to land | Parked at the desk |
| 7 | One spotlight card on the desk buttons: Refill Lift, Repair, Full refold, Fresh plane | Got it | Click |
End card: "Flight School done!" with **Next: Combat Training** and **Go to a match**.
(Lessons use a fixed training plane with a booster and an eraser; your own parts and builds are not touched.)

### Lesson 2: Combat Training (Training Room, about 3 minutes)
| # | What you see | What you do | Moves on when |
|---|---|---|---|
| 1 | Three paper targets ahead, each with a marker; the aim circle pulses, left-click picture | Hold left click to shoot them (1/3...) | All 3 down |
| - | Only if your gun overheats: the heat cells pulse, "Let go to cool down" (doesn't hold you up) | - | - |
| 2 | One enemy plane (red outline, marker) that flies slowly and doesn't shoot | Shoot it down | Folded, "+100 FOLD" pops |
| 3 | A second enemy that shoots back slowly; spotlight on your Health bar | Shoot it down (if it folds you, you fly again) | Folded |
| 4 | The enemy fires a slow eraser at you; "INCOMING!" then "BREAK NOW! Turn hard!" are explained as they appear | Turn hard to dodge it | The eraser misses |
| 5 | Right-click picture: your training plane has an eraser too | Hold right click on the enemy to lock, let go to fire | Your eraser hits |
End card: "You're ready!" with **Go to a match** (you're sent to a normal room with beginner bots).

### Lesson 3: Weapons Range (Training Room, optional, about 3 minutes)
Six stations, one weapon each: Pellet Gun, Staple Burst, Rubber Band Repeater, Precision Paperclip, Guided Eraser,
Pencil Launcher. Your plane switches to that weapon, one line says how it fires ("Hold to spray", "One big shot, slow
reload", "Hold to lock"...), and you hit the station's target to move on. Opened from the Training board only.

### Lesson 4: Hangar Tour (in the normal game, spotlight through the menus, about 2 minutes)
Offered the first time you open the Hangar ("Show me around?" **Yes** / **Skip**), and replayable from the board.
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
The main menu's Tutorial button opens a **Training board** listing the five lessons, each with a tick when done and
**Play** / **Replay**. Lessons 1-3 move you to your Training Room; 4 and 5 run where you are (5 is just on/off).

## The Training Room (private and timed)
- A new player's first join goes straight to their Training Room: Flight School, then Combat Training, then a match.
- Only you are in it. The room is timed: 8 minutes, with a warning 1 minute before the end. When the lessons
  are done, skipped, or time runs out, you're moved to a normal room for your level.
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
2. Flight School. 3. Combat Training. 4. Training board, saved ticks, the 15-minute room. 5. Hangar Tour.
6. Match Tips. 7. Weapons Range.
Each lesson is checked in Studio Play with screenshots of every step and shown to Alan before the next.

Back to [HOME](../HOME.md)
