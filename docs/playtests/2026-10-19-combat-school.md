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

## Round 6 (a match and Combat School)
- Red dot on the ring, but shots still missed beyond close range, in matches too. **Found and fixed:** the two wing
  guns always met at 150 studs and spread past it, so a plane seen from behind at 300 was missed on both sides.
  Now they meet at the target's range ([weapons](../systems/weapons.md)). Measured after: 12/12 hits crossing at 220.
  Round 4's measurement checked the aim direction, not where the two guns' shots went.
- Ran out of Lift in Combat School. **Done:** Lift stays full all lesson.
- The eraser distracts while learning to aim. **Done:** no eraser until a last part; Alan's idea of a later
  every-weapon lesson is the planned Weapons Range.
- Pals too hard to chase 1v1 (circling). **Done:** slower, slow-turning, wandering Pals that only turn on you briefly.

## Round 7
- Long-range shots land now. Up close the dot stayed green though the shots hit. **Done:** red also anywhere on the
  plane's middle up close.
- The aim jolted left on every launch and every unfreeze. **Found and fixed:** locking the mouse read as a big move.
- The read pause: 2.5 s, a draining bar, no countdown. **Done.**

## Round 8
- Still hitting while the dot was green. **Done:** red now follows the guns' real aim (the gun assist), not a screen
  distance. My Round 7 fix was a guess that didn't match how the guns aim.
- Pals waited to come out of the hangar, next to you. **Done:** they appear in the air 350-550 studs away, ahead,
  behind a building when possible, before the step's read pause.

## Round 9
- Too much aim assist: bullets "magnetised", trails visibly turning; or dot on the ring and nothing hits. **Done:**
  assist 7 degrees to 1, none in lessons, red dot only when you'd hit without help
  ([decision](../decisions/2026-10-19-less-aim-assist.md)).
- The reload card should come between the two eraser shots. **Done.**
- The eraser to dodge: faster (still slower than a real one) and from nowhere, not after the Pal lines up. **Done.**

## Round 10
- Naming's better. Step 6 (fast crossing target) at full speed: you just caught up, no lead felt. **Done:** you stay
  in slow motion and it crosses twice as fast.
- Step 7's Pal appeared to the left; too slow, so you circle it. **Done:** it appears ahead (400-700 studs), flies at
  85%, and heads away from you, changing course every 2.5 s.
- Step 8's Pal took 10 s to attack. **Done:** it comes at you for its first 6 seconds.
- The eraser came while you were frozen, from the side. **Done:** none while frozen; it comes from ahead, toward the Pal.

## Round 11
- A Pal slower than you is harder (you overshoot and circle). **Done:** every Pal flies 5% faster than you.

## Round 12
- Hitting anything is "extremely difficult": asked for 3 degrees; then, told the tutorial had none at all: **1 degree
  everywhere, lessons included.**
- Pals have too much Health. **Done:** half.
- Still frozen while an eraser comes. **Found:** the eraser fired in the moment between the step starting and its
  freeze reaching the server. **Done:** none in a step's first second, then 2 s after the freeze ends.

## Round 13
- Aim assist up to 3 degrees, everywhere. **Done.**
- Paperclip: the ting came late (after the shot had gone) and it's too quiet; it needs a soft electric railgun zap
  too. **Done:** ting the instant it fires, louder, zap under it.

## Round 14
- Step 8's Pal should hunt you hard until your Health is whittled down (never folding you), then run. **Done.**
- Pals the same speed as you, not faster. **Done.**

## Round 15
- Step 8's Pal still didn't come after you. **Not found yet** by reading the code; needs a Play run with its thinking logged.
- Step 13 (second slow-motion eraser lock) is redundant. **Cut.**
- INCOMING / BREAK NOW! hidden behind the lesson note. **Done:** the note sits higher, the warning just under it.
- Step 7's Pal does too many maneuvers. **Found:** the normal bot brain started orbits and break turns. **Done:** no
  stunts; it flies straight away from you.

Next: find step 8 in Play, then Alan plays Combat School again.

Back to [playtests](README.md)
