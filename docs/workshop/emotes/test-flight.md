# Test Flight

A runner-up emote (2nd and 3rd). Made by the [emote pipeline](../emote-pipeline.md); the idea is on the
[plan](../../plan/WINNERS-CIRCLE-PLAN.md); picked by Alan in [the second four runner-ups](../../decisions/2026-11-24-four-more-runner-up-emotes.md).

**The idea:** Tosses a tiny plane that loops and comes back to their hand.

## Where it stands
**Approved by Alan in his own Play** (2026-11-24: "Test Flight is good."), after the two fixes from his first look. Waiting for the uploads (the two clips and the whoosh), the primary session's, on his go. He has not heard the whoosh in the game yet: it is silent until its upload.

## Shot card
**Alan's OK (2026-11-24):** "For test flight, I think they should be sitting." The other pick not named, so my default: the last flight circles behind the head.

**The feeling, in one line:** "Whatever. I've still got the best plane." Relaxed and playful, quietly showing off.

**How the body carries it** (faces cannot): loose and unhurried. The throw is a lazy flick from the wrist, not a
wind-up. The head follows the plane the whole way round, and that is what tells us where to look. The catch takes
no effort: the hand is simply there. A small nod after each catch.

**Timing:** seconds after 1st's light (2nd is lit 1 s before it, 3rd 2 s before; the scene leaves about 10.4 s after).

| Time | The kid | Props | Camera | Sound |
|---|---|---|---|---|
| From the dark to 1st's light | Sits cross-legged on the books, the tiny plane held up between finger and thumb, looking it over | Tiny paper plane in the hand | Steady on all three (fixed) | None |
| 0 to 1 s | A look at 1st, then back to the plane | In the hand | Steady | None |
| 1 to 1.4 s | A lazy flick | The plane leaves the hand | Steady | None |
| 1.4 to 3.8 s | The head follows it; the catching hand waits, open | The plane flies out to the side away from 1st, makes one loop and glides back | Steady | None |
| 3.8 to 4.8 s | Catches it, a small nod, a still moment | In the hand | Steady | None |
| 4.8 to 8.2 s | The same again | A second flight: one loop | Steady | None |
| 8.2 to the end | A third flick; catches it and holds it up | A third flight: one slow circle behind the kid's own head, then to the hand | Steady | None |

- **The plane's path** stays in the kid's own light, beside and above them, within about one body height; it goes out on the side away from 1st, never in front of 1st and never towards the lens.
- **The catch lands in the hand on every body:** for the last part of each flight the plane steers to where that body's hand really is. While held it is fixed to the hand's grip point ([decision](../../decisions/2026-11-21-plane-stays-in-the-hand.md)).
- **How big:** ~~about one and a half hands long~~: withdrawn after Alan's look in Play; the size of every emote's plane.
- **Every hand move changes something we see:** flick, the plane leaves; catch, it is back.
- **No sound** (a whoosh belongs only to something passing the camera, Alan 2026-11-22).
- **Both sides:** the plane flies outwards, so 2nd and 3rd are mirror images.
- **Roblox's own emotes, checked first:** none known for a seated toss and catch; looked for at step 4. Else cut from the video.
- **Reused:** Nap's cross-legged seat (`sit`, `seatOn`); Toy Pilot's plane model and grip point, scaled down; Skeet Shoot's thrown-plane path, if it fits.
- **New:** a prop that flies a set path and homes on the hand at the end. The most build work of the four.
- **No lens moment.**
- **For Alan to pick:**
  1. Sitting cross-legged **or** standing. My default: sitting.
  2. Three flights, the last a circle behind the head **or** the same loop every time. My default: the circle last, so the ending differs.

## Reference video (step 3)
One Gemini call, `tools/gemini_video.py`, 360p, 12 s (the longest a runner-up is lit, rounded down). Price by the
earlier 12 s calls (about 1,930 video tokens a second at $12 a million): about **$0.28**. Alan: "go".

Video seconds are seconds after 1st's light plus 1 (as So Close's: the clip's second 1.0 is 1st's light). The
glance goes to the picture's left, as from 3rd's desk (1st beside it on that side), so the plane flies out to the
picture's right; 2nd's is the mirror. **My timing change to the card** (to see the held-up plane before the camera
leaves, 10.4 s after 1st's light): each flight takes 3.2 s, not 3.8 and 3.4, so the third flick comes 7.4 s after
1st's light (card: 8.2) and the plane is held up from 9.6 s.

The prompt (`.planning/emotes/test-flight-prompt-1.txt`):

> One continuous 12-second shot, no cuts. Fixed camera, straight on, level with the seated figure's chest, not moving or zooming. Plain light grey room, soft even light, no text, no music.
>
> A simple smooth grey mannequin with no face sits cross-legged on top of a solid, steady stack of six large dark hardback books. The whole stack and the whole figure are in the picture, with plenty of empty space above the head and to the right of the figure. The mannequin faces the camera; its hips and crossed legs never leave their spot on the top book. It holds a tiny white folded paper plane, only about one and a half hand lengths long.
>
> Attitude: a kid who came second in a contest and acts like it does not care: "Whatever. I've still got the best plane." Relaxed, loose and unhurried, quietly showing off. The throws are lazy flicks of the wrist, never a wind-up. The catches take no effort: the hand is simply there.
>
> Hard rules: only the left hand (on the right side of the picture) throws and catches; the right hand rests on the right knee the whole time. The plane always stays beside and above the figure, within one body height of it, mostly on the right side of the picture. It never flies towards the camera and never goes more than a little past the left side of the head. The head follows the plane the whole way, every flight.
>
> 0 to 1 s: holds the tiny plane up at chest height between finger and thumb of the left hand, turning it a little, looking it over.
> 1 to 2 s: a short glance to the left of the picture, as if at the winner sitting just beside, then back to the plane.
> 2 to 2.4 s: a lazy flick of the wrist; the plane leaves the hand, out and up to the right of the picture.
> 2.4 to 4.4 s: the plane flies out to the right, beside and a little above the figure, makes one small loop-the-loop and glides back. The head follows it; the left hand stays up, open, waiting.
> 4.4 to 5.2 s: the plane glides into the open left hand and the fingers close on it. One small nod. A still moment.
> 5.2 to 5.6 s: the same lazy flick again.
> 5.6 to 7.6 s: a second flight the same way: out to the right, one loop, glides back; the head follows.
> 7.6 to 8.4 s: caught in the left hand again, a small nod, still.
> 8.4 to 8.8 s: a third lazy flick, up and out to the right.
> 8.8 to 10.6 s: the plane makes one slow, wide circle around the back of the head: up and out to the right, behind the head to just past its left side, then back behind the head and down into the waiting left hand. The head turns to follow it.
> 10.6 to 12 s: holds the plane up at shoulder height between finger and thumb, showing it off, and stays still.
>
> Sound: silence the whole time. No music, no whoosh, no sound effects.

- **The video** (`.planning/emotes/test-flight-gemini-api-1.mp4`, 12 s, 640x360; $0.28: 708 text tokens in, 23,172
  video tokens out). What my stills show (two a second, not judged in motion): a grey mannequin sits cross-legged on
  six books, the plane in the hand on the picture's right; flicks at about 2.0, 5.2 and 8.4 s; each of the first two
  flights goes out to the right and a little above the head, loops and comes back to the open hand (caught about
  4.0 and 7.5 s); the head follows the plane; a small white trail line drawn behind the plane (not wanted in the
  game). **Not as asked:** no glance to the left at 1 to 2 s (the head stays on the plane); the third flight's circle
  passes in front of the neck and chest, not behind the head (caught about 10.8 s); the plane is held up from about
  11 s. Sound: not used (the card has none).

- **Alan on the video (2026-11-24):** "you're not going to be able to use that voice line. They don't use voice lines.
  But you can use the little whooshing sound of the plane. I think it's good. I think this is good enough to work
  with. Yeah, you're going to have to add the glance, though." So the movement is approved with the glance at 1st
  added in the build; the third circle goes behind the head as on the card; **the sound is the video's plane whoosh**
  (his call, in place of the card's "no sound"); the voice in the video is not used.

## Build (step 4)
- **The body: a cut, not a Roblox emote.** No Roblox emote throws and catches sitting; the seat and the resting hand
  are Nap B sitting still (as Nap's and So Close's), the throwing arm and the head by numbers.
- **Two clips, mirror images** (`CUTS.TestFlightLeft` and `CUTS.TestFlightRight` in `tools/emote_cuts/test-flight.lua`;
  every number is in its comment): Left throws with the left hand out to the kid's own left (used when 1st is on the
  picture's left, so 3rd in the usual line-up), Right the other way (2nd). 12 s, played once, held on its last pose.
- **Marks** (clip seconds; clip second 1.0 is 1st's light): Glance 1.0 (the head turns 50 degrees to 1st, back by
  2.0), flick 1 from 1.7, **Release1 2.2, Catch1 4.3**, flick 2 from 5.05, **Release2 5.3, Catch2 7.4**, flick 3 from
  7.85, **Release3 8.1, Catch3 10.5**, held up by **Show 11.0**. A small nod 0.05 to 0.55 s after each catch. In
  seconds after 1st's light: 2nd's are these minus 1; 3rd holds the glance 0.3 s longer, so its are these minus 0.7
  from the first flick on (the camera leaves about 10.4 s after 1st's light: 2nd's plane is held up from 10.0 s, 3rd's
  is just caught then).
- **What the clip does:** the plane held at the chest and looked over (a small rock of the hand); the glance; each flick
  cocks the hand in and tosses it out and up over 0.5 s (the forearm turns at most 15 degrees in one frame); between
  flick and catch the hand waits open beside the body, a third of a height out; the head follows the plane the whole
  way (85% of the way, at most 75 degrees to the side; behind the head it swings across); the chest turns a fifth of
  the head's turn; at the end the hand rises to shoulder height. Measured on the test kid: the hand lands exactly on
  its marks (0.000 off at the waits and the show).
- **The plane** (`src/client/emotes/TestFlight.luau`): the kid's own plane at the size every emote's plane is
  (`holdPlane`'s own, as Toy Pilot's and Skeet Shoot's: 0.28 to 0.36 of the kid's height on the bodies measured). Held:
  fixed to the throwing hand, its tail at the grip point and its nose along the forearm (held by the tail, as Toy
  Pilot's). Flying: the clip's path in the kid's own frame and height (the same numbers in both files), from where the
  hand let go; for its last 0.7 s it steers to where this body's hand really holds it. One rigid plane: the nose follows
  the path and its top is carried along with the nose, turned only as much as the nose turns, so it has no roll of its
  own: it goes over on its back through a loop and stays level round a flat turn; in the hand its top is drawn back up
  slowly (6% a frame). Flights 1 and 2: out and up to the side away from 1st, one loop-the-loop seen face-on from the
  camera (0.19 heights across, its top half a height above the hips), a wide turn behind and back into the hand.
  Flight 3: up, then one full circle round the head (0.38 heights across, low behind it and high over the forehead,
  never in front of the face), back down into the hand. Centred on that body's own head.
- **Dry run in Edit** (the module itself, on real rigs posed by the baked clips through `Animator:StepAnimations`, the
  scene's timing every 1/30 s, a stand-in card the plane's size; everything removed in the same call), on the plain kid
  and the twelve bots of the fixed cast, each with 1st on either side (26 runs), after the fixes: no error; the right
  clip every time; **the gap between the plane's tail and the grip point while held: 0.0000** (from each catch on); the
  last flying place before a catch is 0.025 to 0.028 heights from the hand (its glide speed); **the plane's roll in
  flight: 0 degrees a second in all three flights, on both sides, no reversal**; in the hand it settles level after a
  catch at 109 degrees a second at most, one way only; **never inside the head or the chest**: the closest any part of
  it comes is 0.006 heights to the head and 0.009 to the chest, at a toss or a catch, when it is in the hand beside the
  body (in flight it stays further off); **the path's furthest point 0.72 heights from the hips**, 0.32 to 0.56 heights
  above the head top at its highest, at most 0.28 heights towards the camera, at most 0.37 heights past the kid's
  middle towards 1st (the far side of the circle round the head; 1st sits about one and a half heights away); hidden
  behind the head for 4 or 5 frames on the circle; three whooshes asked for.
- **The body clip after the fixes** (the test kid, every 1/30 s): the biggest turn of any joint in one frame 10 to 19
  degrees, the forearm in the first flick (Nap's jolt has 25); the head now swings across more slowly as the plane
  passes behind it (it had 16 degrees in a frame); the hand exactly on its marks.
- **Size in the picture** (worked out from the So Close recording, 2032 x 800, not seen): a sitting runner-up there is
  about 300 pixels tall (about 420 standing), so the plane is now about 120 pixels long and its loops reach about 270
  pixels out from the kid's middle and about 200 above the head.
- **Not known until it is seen in Play:** whether the loops stay inside the picture on a narrow screen (a phone); how
  the lazy flick and the nods read; the plane's look in the hand; long hair or hats round the circle behind the head.

## Alan's first look in Play (2026-11-24)
- **His words:** "Test flight is poor because the paper airplane is extremely small. We've kind of kept a momentum of
  what the paper airplanes look like size-wise everywhere else, yet for some reason they're way smaller. Plus, also, on
  one of them, I saw the paper airplane flap its wings like it was a butterfly. So for some reason, you treated it like
  a butterfly or something, or a bird. They're supposed to just, like, throw it, like, toss, like, pick it up and throw
  it, and then it fly around, and then them catch it." ([his notes](../../playtests/2026-11-24-the-four-new-runner-up-emotes-first-look.md))
- **The size:** it was a tenth of the kid's height (the card's "one and a half hands", my number, now withdrawn); it is
  now `holdPlane`'s own size, the same as every other emote's plane, about three times bigger. The loops and the circle
  round the head were made bigger to suit it, and the circle wider so the plane clears the head.
- **The flapping, found by numbers:** in every flight, on both sides, not just one: the plane's top was aimed by the
  path's bend each frame, and the bend jumps at every point the path is drawn through, so the wings rolled back and
  forth up to about 4,000 degrees a second, 31 times in each loop flight and 40 times in the circle. Now the top is
  carried along with the nose (above): no roll of its own, 0 in every flight.
- Kept: sitting, the glance at 1st, three flights, the whoosh.
- **His second look, after the fixes (2026-11-24): "Test Flight is good."** Approved in his own Play; the whoosh not yet heard (silent until its upload).

## Sound (step 5)
- **One sound, the video's own plane whoosh** (Alan: "you can use the little whooshing sound of the plane"; the voice
  is not used): `assets/audio/emotes/test-flight-whoosh.ogg`, 1.8 s, cut from 5.35 to 7.15 s of
  `test-flight-gemini-api-1.mp4` (the second flight: a swell as it leaves the hand and one over the loop; the voice is
  at 1.3 to 3.5 s, not in it). Lightly de-hissed, 0.05 s fade in, 0.3 s out, its loudest point 26 dB under full
  (So Close's sigh, which Alan called right, is 28). Measured by loudness, not heard by me. Laid on the video at the
  three releases: `.planning/emotes/test-flight-whoosh-on-video.mp4`.
- **When it plays:** at each release (clip seconds 2.2, 5.3, 8.1), once each, as `testFlightWhoosh` through
  `runnerSound` (skipped when it would still be playing as 1st's first sound starts). It plays once step 6 adds
  `testFlightWhoosh` to `src/client/Audio.luau` at volume 1.

## For the primary session
- The two clips are baked into the open place's `Assets` as `TestFlightLeftClip` and `TestFlightRightClip` (replaced
  after the fixes) and saved as the files below; the Dev button "2nd/3rd: test flight" is in.
- Step 6: `testFlightWhoosh` in `Audio` (the file above), on Alan's go.

## Files
| File | What |
|---|---|
| `src/client/emotes/TestFlight.luau` | The emote's module: picks the clip, times it to 1st's light, the seat, the plane in the hand and its three flights, the whooshes |
| `tools/emote_cuts/test-flight.lua` | The body cut: `CUTS.TestFlightLeft`, `CUTS.TestFlightRight` |
| `assets/audio/emotes/test-flight-whoosh.ogg` | The whoosh |
| `assets/animations/emotes/test-flight-left.rbxm`, `test-flight-right.rbxm` | The two baked clips |
