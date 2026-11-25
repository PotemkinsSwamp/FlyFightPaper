# Sneaky Toss

A runner-up emote (2nd and 3rd). Made by the [emote pipeline](../emote-pipeline.md); the idea is on the
[plan](../../plan/WINNERS-CIRCLE-PLAN.md); picked by Alan in [the second four runner-ups](../../decisions/2026-11-24-four-more-runner-up-emotes.md).

**The idea:** Lobs a paper ball toward 1st, then acts innocent. **The ball misses** (Alan 2026-11-24: "it
misses ... it just like goes off to the side behind them").

## Where it stands
**Approved by Alan in his own Play** (2026-11-24; his words under "Alan in Play" below): waiting for the upload of its two clips, the primary session's on his go. No sound. In Studio it plays from the drafts `SneakyTossLeftClip` and `SneakyTossRightClip` in the open place's `Assets` (`DevRunnerUp` = "SneakyToss").

## Shot card
**Alan's OK (2026-11-24):** "Sneaky Toss looks good", with one change: **no whistling**, neither the sound nor the look ("doing a whistling sound's going to be difficult. We also can't make them look like they're whistling ... do it more visually with their body language to make them look like they're trying to pretend to be innocent. Like maybe they're kind of being shifty, looking back and forth ... hands behind their back, like rocking back and forth, looking away from first place, kind of like tilting their head back and forth"). The card below has it. One throw (my default).

**The feeling, in one line:** "Heh. Wasn't me." Cheeky and sly, then a show of innocence that fools nobody.

**How the body carries it** (faces cannot): two tempos. Before the throw everything is slow and careful, a sly
look, the ball weighed once in the hand. The throw itself is one quick flick. The instant the ball is gone the kid
pretends to be innocent with the whole body: hands behind the back, rocking forward and back on the heels, turned
away from 1st, the head tilting slowly from side to side. Now and then it turns shifty: quick little looks back and
forth, towards 1st and away again.

**Timing:** seconds after 1st's light (2nd is lit 1 s before it, 3rd 2 s before; the scene leaves about 10.4 s after).

| Time | The kid | Props | Camera | Sound |
|---|---|---|---|---|
| From the dark to 1st's light | Stands on the books facing us, hands behind the back | Ball hidden behind the back | Steady on all three (fixed) | None |
| 0 to 1 s | A slow, sly look sideways at 1st | Hidden | Steady | None |
| 1 to 2.2 s | Brings the ball out and bounces it once in the palm | Crumpled paper ball | Steady | None |
| 2.2 to 2.6 s | One quick flick of a throw towards 1st | The ball leaves the hand | Steady | A faint paper rustle (if Alan wants one) |
| 2.6 to 3.6 s | Already innocent: hands behind the back, face up and away from 1st | The ball flies past 1st, behind them, and off to the far side into the dark | Steady | None |
| 3.6 to 6 s | Rocks forward and back on the heels, looking away from 1st, the head tilting slowly side to side | None | Steady | None |
| 6 to 7.5 s | Shifty: two quick looks back and forth, towards 1st and away | None | Steady | None |
| 7.5 to 8.5 s | One longer peek at 1st; the shoulders shake once (a snigger) | None | Steady | None |
| To the end | Innocent again: rocking, head tilting, looking away | None | Steady | None |

- **The ball's path** (my reading of Alan's words): it passes behind 1st, never in front of them and never towards the lens, so it cannot cover 1st's emote whichever one plays; it leaves the light on the far side. One ball, one throw.
- **How big:** a crumpled ball about half the size of the kid's head, so it shows at the scene's distance. Measured in the picture at step 4.
- **Both sides:** the throw goes towards the middle, so 2nd and 3rd are mirror images (two clips, as So Close has).
- **With Skeet Shoot on 1st:** the runner-ups' emotes pause while they throw their planes, as for every runner-up emote.
- **Roblox's own emotes, checked first:** none known for an underhand toss and a fake-innocent rock on the heels; looked for at step 4. Else cut from the video.
- **Reused:** So Close's "which side is 1st on"; Skeet Shoot's thrown-plane path for the ball's arc, if it fits; the ball fixed to the hand until the throw.
- **New:** a prop that crosses the stage behind 1st (small: one arc, no hit).
- **No lens moment.**
- **For Alan to pick:**
  1. Settled by Alan: no whistle, as a sound or as a look.
  2. One throw **or** a second ball from the pocket near the end. My default: one.

## Reference video (step 3)
One Gemini call, `tools/gemini_video.py`, 360p, 12 s (the longest a runner-up is lit, rounded down), sound on. Price
as for So Close (about 1,930 video tokens a second at $12 a million): about **$0.28**. Video seconds are the card's
plus 1 (one still second first, as in the dark). The throw goes to the picture's left, as from 3rd's desk (2nd's is
the mirror). A still stand-in for 1st stands on a taller stack at the left, so the ball has someone to pass behind.
No whistling anywhere in it, as a sound or a look (Alan); the innocence is the rocking, the looking away, the head
tilts and the shifty glances. Shop mannequins and "a harmless prank", after Skeet Shoot's first prompt was refused.
The prompt: `.planning/emotes/sneaky-toss-prompt-1.txt` (untracked); the moves in it, video seconds:

| Video s | The kid | Sound |
|---|---|---|
| 0 to 1 | Still, hands behind the back | None |
| 1 to 2 | Slow sly look left at the winner, shoulders hunched a little | None |
| 2 to 3.2 | One hand out with a crumpled white paper ball half the head's size; one bounce in the palm | None |
| 3.2 to 3.6 | Quick underhand flick; the ball arcs high behind the winner's back and out of the picture's left; never towards the camera, never in front of the winner | One faint paper rustle at 3.2 |
| 3.6 to 4.6 | Hand back behind the back; face up and away to the right | None |
| 4.6 to 7 | Rocks slowly on the heels, looking away, head tilting side to side | None |
| 7 to 8.5 | Two quick shifty glances at the winner and away | None |
| 8.5 to 9.5 | One longer peek; shoulders shake once (a held-back snigger) | None |
| 9.5 to 12 | Innocent again: rocking, looking away, head tilting | None |

- **The video** (Alan: "go"; $0.28: 695 text tokens in, 23,172 video tokens out): `.planning/emotes/sneaky-toss-gemini-api-1.mp4`,
  12.03 s, 640x360, with sound. What my stills show (two a second, eight a second over the throw; not judged in
  motion), video seconds:
  - **Works:** hands behind the back at the start; at 1.5 s the head turns towards the winner; 2.0 s one hand comes out
    with a white paper ball; 2.25 to 3.25 s it tosses the ball up a little in the open palm and catches it (about two
    bounces, not one); 3.4 s a lob from the palm, forearm out, up and towards the winner; 3.75 s the hand is back
    behind the back; 4 to 7 s the face is turned up and away from the winner; 8.5 to 11.5 s the head tilts from side
    to side, looking down and away. The winner stays still.
  - **Misses:** the ball drops down **in front of** the winner's chest to the floor, not behind them (the game's path is
    our own, by numbers, so this does not carry over); the winner's stack is not taller; the throw is a palm-up lob,
    not a quick flick; the rocking on the heels and the two quick shifty glances do not show in stills.
  - **The sound** (measured by loudness, not heard by me): a faint hiss all through (about -58 dB) and one soft thud at
    4.4 s (about 22 dB over the hiss), when the ball would reach the floor; no rustle at the throw (3.4 s).

- **Alan on the first video (2026-11-24):** "good enough for a rough reference, but you're going to have to fix the
  parts where it's wrong ... It needs to be like an actual throw. There's no rocking on the heels or quick shifty
  glancing ... I give you permission to try one more time to get a good reference and fix those problems."
- **The second video** (`sneaky-toss-prompt-2.txt`: an overarm throw "like throwing a baseball", the ball past the
  winner's head and out of the picture, the rocking and the glances spelled out; $0.28: 790 text tokens in, 23,172
  video tokens out; Gemini for Sneaky Toss so far $0.56): `.planning/emotes/sneaky-toss-gemini-api-2.mp4`, 12.03 s.
  My stills (two a second, eight over the throw, six over the innocence):
  - **Fixed:** a real overarm throw: 2.0 s the ball comes out, one toss in the palm (2.6 to 2.9), the hand goes up
    beside the head with the elbow high (3.1 to 3.3), the arm whips forward and releases above the shoulder (3.4); the
    ball flies high to the left, level with the winner's head at 3.75, and out of the picture's left by 4.0 (never on
    the floor, never towards the camera; in front of or behind the head cannot be told in stills).
  - **Still missing, and a new fault:** after the throw the figure turns its whole back to the camera (4 to 6.5 s and
    9.5 to 12 s) and side-on between, its feet turning with it, and from about 7 s it has a face. The rocking does not
    show in stills (six a second); the glances are whole-body turns, not quick head snaps.
  - **The sound** (measured, not heard): hiss about -57.5 dB; small sounds at 3.0 and 4.0 s, the loudest at 4.6 s
    (about 27 dB over the hiss), more small ones 5.8 and 8.1 to 8.8 s (the feet turning, my guess).

- **Alan on the second video (2026-11-24):** "it's definitely a lot better. There is like a weird shift, but it's good
  enough to work with. So go ahead and build it." So: the throw from the second video; the rocking, the shifty glances
  and the peek built by hand, the feet planted facing the front. **Sound: none** (he picked no rustle; the video has
  none at the throw).

## Build (step 4, 2026-11-24; numbers in Edit only)
- **The body: a cut, not Roblox's emotes.** No Roblox emote holds the hands behind the back, throws overarm and rocks on
  the heels, and the throw has to be timed to 1st's light and mirrored, so the body is posed by numbers on Toy Pilot's
  standing pose (feet apart).
- **Two clips, one per side** (`CUTS.SneakyTossLeft` and `CUTS.SneakyTossRight` in `tools/emote_cuts/sneaky-toss.lua`; every
  number is in its comments): Left throws towards the kid's own left (1st on the picture's right) with the left hand,
  Right the mirror. 12 s, played once, held on the last pose. In the video's seconds: clip second 1 is 1st's light.
  Baked into the open place's `Assets` as `SneakyTossLeftClip` and `SneakyTossRightClip` (unsaved drafts: what `ourClip`
  plays in Studio); saved as `assets/animations/emotes/sneaky-toss-left.rbxm` and `-right.rbxm`. To bake again
  after a close without a save: a copy of `tools/emote_clips.lua` with `_G.EMOTE_CLIPS = { "cut:SneakyTossLeft" }` as its
  first line, then `python tools/emote_preview.py STUDIO_ID x --lua=THAT_COPY "--bake=SneakyTossLeft:SneakyTossLeftClip:assets/animations/emotes/sneaky-toss-left.rbxm"` (and Right).
- **The marks** (clip seconds; 1st's light is 1.0; for 3rd add 0.6): Look 1.0 (the sly look starts), Out 2.0 (the hand
  comes out with the ball), Toss 2.62 and Catch 2.9 (the one bounce), Cock 3.32 (hand up by the head, elbow high),
  **Release 3.44 (the throw)**, Away 3.85 (face up and away), Back 4.05 (hand behind the back again), **Glance 7.1 (the
  first shifty look)**, Glance2 7.85, Peek 8.5 to Peeked 9.7 (the snigger 8.95 to 9.42).
- **What the clip does:** both hands clasped behind the back from the dark; 1.0 to 1.6 the head turns about 50 degrees
  to 1st, a little down, the chest 5 forward (hunched); the throwing hand round the side to in front of the belly
  (2.0 to 2.45), flicks up for the bounce and gives on the catch; the wind-up (the chest turns 14 away, leans 4 back,
  the hand beside the head with the elbow high), the whip out towards 1st and up (the chest turns 14 into it, 7
  forward), the follow-through down and across, and straight back behind the back; the head follows the ball for a
  moment, then turns up and away (about 30 degrees to the other side, 19 up). From 4.2 the innocence: up onto the toes
  (25 degrees, the heels up) and back onto the heels (15, the toes up) every 1.1 s, the hips riding up 0.025 of the
  kid's height on the toes, the body leaning 4 degrees with it; the head tilting 11 degrees each way every 2.6 s; both
  faded down for the glances and the peek. Glances: the head snaps level to 1st in 0.12 s, holds 0.25, snaps back.
- **Measured on the test kid** (Edit, no pictures, every 1/30 s): the feet stay put (the middle of the feet moves at most
  0.021 of the kid's height, from the rock's turn about toe and heel); the soles never go into the book by more than
  0.004 heights; no hand or forearm in the body's boxes (the hands behind the back stay 0.007 heights clear); the
  biggest turn of one joint in one frame is the throwing forearm folding up into the wind-up (73 degrees at 3.2 s:
  the elbow goes from 38 to 125 degrees bent in a third of a second; a real fold, not a flip); the head's snaps are
  36 degrees a frame. **First fault the numbers found:** with the elbow high the forearm spun 85 degrees in a frame;
  the forearm now starts each frame bent, not straight.
- **The module** (`src/client/emotes/SneakyToss.luau`; `DevRunnerUp` = "SneakyToss" picks it): So Close's way: the Left
  clip held on its first pose from the dark, swapped for Right at the first frame if 1st stands on the picture's left;
  every frame the clip's time is set from 1st's light (2nd: 1 + seconds after 1st's light; 3rd 0.6 s behind, so two
  kids playing it are out of step).
- **The ball:** a white ball (`kit.paper`), half the thrower's head (kept between 0.06 and 0.11 winner heights), on top
  of the throwing hand from Out (the bounce rises 0.13 heights over it), and from Release its own path: a thrown
  ball's arc that passes, 0.35 s after the hand, a point behind 1st's head: behind the back of 1st's whole box as the
  camera sees it (taken at the release, so whatever 1st's emote is doing, hats and wings too) by 0.15 heights plus the
  ball's radius; then on, falling 3 heights a second squared (a light paper ball), past the far runner-up. The throw
  is quick. It is worked out in the big room and drawn in the world
  of the winner it is nearest across the picture, so it hides behind that one correctly. It is gone when it drops to
  the desk tops (at about the far desk's outer edge, behind the far runner-up), leaves the side of the picture, or
  after 2 s. Its distance from the camera only grows, so it never comes towards the lens.
- **Dry run of the module in Edit** (the module itself, loaded from its file: it compiles; three stand-in kids at the
  scene's places, 1st 0.06 of a desk forward and on a taller stack, the runner-ups 2.7 winner heights to either side,
  the scene's camera and lens on a 1920x1080 screen, the clips playing; once with all three avatars the same scale and
  once with three different ones; all removed in the same call). The same on both sides and both scale mixes:
  - no error; 2nd took the Left clip and 3rd the Right;
  - **the ball in the hand: 27 px across against the thrower's head's 55 px** (half the head, as carded);
  - **the path** (seconds after the release): it leaves the hand off to the side of the picture, 0.22 winner heights
    nearer the camera than the back of 1st's box; it is behind that back by 0.03 at 0.26 s, still well off 1st on the
    screen; **while it is over 1st on the screen it is at least 0.07 winner heights behind the back of 1st's whole box**
    (0.16 at the moment it passes behind 1st's head); 0.44 behind at 0.56 s, 1.05 at 0.96 s; behind the far runner-up
    by at least 0.34 while it passes them; its distance from the camera grows the whole way (at least 1.2 heights a
    second); it reaches the desk tops 1.01 s after the release at 813 px from the middle of a 960 px half-screen, and is
    gone there (it would leave the picture's side at 1.15 s);
  - the screen heights: it flies about 80 px above the picture's middle, level with 1st's head top, passes behind it,
    and drops to 137 px below the middle by the end.
  Three faults the dry runs found first: the ball dropped through the desk top in mid-picture beside the far runner-up
  (a heavier fall); the off-picture test read Studio's Edit window (2046 x 801), not a game screen; slower throws reached
  the desk tops sooner on the screen. Hence the quicker throw and the lighter fall.
- **On the bots' twelve bodies** (the fixed cast's outfits in `config/gameplay.json`, the Left clip at 13 moments, Edit,
  made and removed in each call): it plays on every one; the feet move at most 0.029 of the body's height (the rock's
  turn about toe and heel); on four bodies a sole corner goes up to 0.024 of the height into the book at the deepest
  rock (the rock's toe and heel are worked out on the test kid's feet; on the others they sit a little off: 0.14 studs
  on a 6-stud kid); a hand or forearm goes at most 0.026 of the height deeper into the body's boxes than at that
  body's own start (a forearm coming out from behind the back at 2.45 s); at the release the throwing hand is level
  with the middle of the head on every body (0.00 to 0.05 heights over it); the head turns to the same side at 1st's
  light and away after on all twelve. **An Edit check is not Play.**
- **Not known until it is seen in Play:** whether the overarm throw reads as a real throw at the scene's distance (the
  wind-up folds the forearm fast: 73 degrees in one frame), whether a 27 px white ball is easy to follow in its 1 s
  flight, whether the rocking (the hips up 0.025 of the height, a 4-degree lean) reads from straight on, whether the
  quick head snaps read as shifty, how the ball's vanishing at the desk tops beside the far runner-up looks, and long
  hair or hats on the head tilts. If both runner-ups play it, 3rd throws 0.6 s after 2nd: two balls cross behind 1st.

## Sound (step 5)
None: Alan picked no rustle after hearing the videos, and the card has no other sound. Nothing for `runnerSound`.

## Alan in Play (2026-11-24)
In his own Play, after the primary session's recording ([playtest note](../../playtests/2026-11-24-the-four-new-runner-up-emotes-first-look.md)):
"Sneaky toss isn't bad. It's very close. It's very close. The only thing I'll say is the way that they're throwing
it. That's more or less the problem. Actually, no. Honestly, I think sneaky toss is good. No, sneaky toss is good."
**Approved as it plays, the throw included** (he named it, then took it back): nothing changes. Next: the upload of
the two clips (step 6, the primary session's, on his go).

## Files
| File | What |
|---|---|
| `src/client/emotes/SneakyToss.luau` | The emote's module: picks the clip, times it to 1st's light, the ball and its flight |
| `tools/emote_cuts/sneaky-toss.lua` | The body cut: `CUTS.SneakyTossLeft`, `CUTS.SneakyTossRight` |
| `assets/animations/emotes/sneaky-toss-left.rbxm`, `sneaky-toss-right.rbxm` | The two baked clips |
