# Playtest 2026-10-18/19: Combat School

Alan played the new combat lessons in Studio several times, plus one real match. What he said and what changed.
Decisions: [aiming and combat lessons](../decisions/2026-10-19-aiming-and-combat-lessons.md). System: [tutorial](../systems/tutorial.md).

## Before building
- Pals must never kill a new player; the Health Pal shoots only until Health drops, then stops; the eraser must be slow
  enough to dodge; a crash needs a smooth way back. **Done:** Pals stop at 1 Health, half-speed erasers (slower after
  each hit), countdown + auto take-off + same step, Pals hold fire 2 s after you're back.
- A whole part on aiming, with its own eraser lock part, in slowed time. **Done** (slow motion, see below).
- Music: Liberty Bell for the lessons; Sprint, Comedy Clip (a), Tough Guys (A), Silly Chase into the match playlist. **Done.**

## Round 1
- Tutorial button should ask Flight School or Combat School; "Aiming" is part of Combat School; a first-time player is
  asked whether they want the tutorial. **Done.**
- Slow motion not slow enough ("almost to a standstill"). **Done:** 6% speed.
- The highlight round the crosshair hid it. **Done:** thin, half see-through frame, no dim.

## Round 2
- Targets too far to reach in slow motion; nothing taught the lead. **Done:** targets appear just ahead of you; moving
  ones sweep left and right across your view at full speed (Alan: head-on doesn't show the lead; bullets stay full speed).

## Round 3
- Ran out of Lift in slow motion. **Done:** Lift stays full there.
- Still nothing teaching the lead; the dot turns red, not green. **Done:** a look step on the ring ("AIM HERE",
  "that's called leading"); words say red.
- Freeze the world before each step so they can read, Flight School too. **Done** ("read, then act").

## Round 4
- The aim was off after a freeze (it drifted with the mouse). **Done:** aim held on the nose while frozen.
- No pressing to unfreeze: 5 seconds with a countdown. **Done.**
- The dot wasn't turning red / shots not landing on leads. Measured in a Claude Play run: shots and lead are right;
  the guns already aim at the ring within 7 degrees. Alan kept that help.

## Round 5 (a real match)
- The dot went red anywhere near a target. **Done:** red only while the dot is on the orange ring.
- (A crash in the HUD from one of these edits broke every menu for a while; fixed and checked in Play.)

Next: Alan's notes on Combat School (next session).

Back to [playtests](README.md)
