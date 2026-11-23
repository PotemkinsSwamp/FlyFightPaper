# So Close

A runner-up emote (2nd and 3rd). Made by the [emote pipeline](../emote-pipeline.md), in its own side session; the idea is on the
[plan](../../plan/WINNERS-CIRCLE-PLAN.md).

**The idea:** Sits on the books shaking their head, sad not to be 1st (Alan).

## Where it stands
**Ready to record** (2026-11-22): steps 1 to 5 done. Built and checked by numbers in Edit only; nobody has seen it move or heard the sigh in the game.

## Shot card
**Alan's OK (2026-11-22):** "yes, cross-legged, sigh, keep the glance" (all three of my defaults below).

**The feeling, in one line:** "So close. I almost had it." Let down and deflated; not angry, not sulking, not crying.

**How the body carries it** (faces cannot): the tempo is slow and heavy, every move a little late and nothing snaps;
the posture caves in: one big sigh lets the shoulders drop, the chest curl forward and the head hang, and it never
comes back up. The head shakes are small, slow and low, as if to themselves, not to the camera.

**Timing:** the scene lights 3rd, then 2nd 1 s later, then 1st 1 s after that, and leaves about 10.4 s after 1st's
light: 3rd is lit about 12.4 s, 2nd about 11.4 s. Times below are seconds after the kid's own light.

| Time | The kid | Props | Camera | Sound |
|---|---|---|---|---|
| In the dark | Sits cross-legged on the books (Nap's seat), fairly upright, hands on the knees, head up | None | Steady on all three (fixed) | None |
| 0 to 1st's light (1 s for 2nd, 2 s for 3rd) | Still; one small breath | None | Steady | None |
| 1st's light, 1.1 s | Head turns slowly to 1st (towards the middle), 0.6 s, and rests there 0.5 s | None | Steady | None |
| Next 1.2 s | The sigh: shoulders rise a little, then everything sags: chest forward about 20 degrees, shoulders down, head falls, forearms slide onto the thighs, hands hang loose over the knees | None | Steady | One very quiet sigh, just under the music (if Alan wants one) |
| Next 3 s | Three slow head shakes, head still low, about 20 degrees each way, about 1 s each, the last one slowest | None | Steady | None |
| To the end | Stays slumped; a slow breath every 4 s; every 5 to 6 s one more short shake (two turns), smaller | None | Steady | None |

- **Both 2nd and 3rd can play it at once.** Both look at 1st when 1st's light clicks on (together, on purpose:
  everyone looks at the winner). After that they are kept out of step: 3rd sighs 0.5 s later than 2nd, and their
  repeat shakes come on different beats, so they never move as mirrors. Each turns towards the middle (1st stands
  between them), so the two glances are naturally opposite.
- **Roblox's own emotes, checked first (free to play in our game, as Applaud is in Good Game):** Roblox's
  **Disagree** (catalogue 4849495710, a standing head shake) for the shakes: only its head and chest turns, laid over
  the sitting legs, the way Nap took its looks from Roblox's standing idle. Roblox's **Sad** (catalogue 4849502101)
  is read for a slump. Both are read in Edit at step 4 (their keyframes); if neither fits a seated body, the body is
  cut from the Gemini video.
- **Reused:** Nap's cross-legged seat on the books (`sit`, `seatOn`), `bendArm` if the hands need resting on the
  knees, and the runner-up sound rule (a runner-up's sound plays only if it ends before 1st's sounds begin).
- **New:** nothing new as a mechanic. Two small new numbers: which way is "towards 1st" for each place, and the
  moment of 1st's light handed to the runner-up's emote (both in the shared scene file: asked of the primary
  session at step 4).
- **No lens moment, no props.**
- **For Alan to pick:**
  1. Sitting: cross-legged (Nap's seat, proven) **or** legs hanging over the front of the books (more "kid on a
     bench", but the seat rule rests the lowest point on the book top, so hanging legs need a new seat rule).
     My default: cross-legged.
  2. Sound: one very quiet sigh at the sag **or** none at all. My default: the sigh.
  3. The glance at 1st is my addition: keep it or drop it. My default: keep (it says *why* they are sad).

## Reference video (step 3)
One Gemini call, `tools/gemini_video.py`, 360p, 12 s (the longest a runner-up is lit, rounded down), sound on.
Price by Bubblegum's two calls (about 1,930 video tokens a second at $12 a million): about **$0.28**. Alan: "go".
The prompt (`.planning/emotes/so-close-prompt-1.txt`; the glance goes to the picture's left, as from 3rd's desk;
2nd's is the mirror):

> One continuous 12-second shot, no cuts. Fixed camera, straight on, level with the seated figure's chest, not moving or zooming. Plain light grey room, soft even light, no text, no music.
>
> A simple smooth grey mannequin with no face sits cross-legged on top of a solid, steady stack of six large dark hardback books. The whole stack and the whole figure are in the picture, with empty space above the head. The mannequin faces the camera for the whole shot; its hips and crossed legs never leave their spot on the top book.
>
> Attitude: a kid who just lost a contest by a tiny margin and came second. Let down and deflated: not angry, not sulking, not crying. Every move is slow and heavy, a little late; nothing snaps.
>
> Hard rule for the hands: at the start both hands rest on the knees; after the sigh both forearms rest on the thighs with the hands hanging loose over the knees. The hands never touch the face or the head.
>
> 0 to 1 s: sits fairly upright, hands on the knees, head up, looking at the camera. One small breath.
> 1 to 2.1 s: the head turns slowly to the left of the picture, as if looking at the winner sitting just beside it, and rests there.
> 2.1 to 3.3 s: one big sigh: the shoulders rise a little, then everything sags. The chest curls forward, the shoulders drop, the head falls forward and comes back to face the front, the forearms slide onto the thighs, the hands hang loose over the knees. A soft, quiet sigh is heard.
> 3.3 to 6.3 s: three slow head shakes, "no", the head still hanging low; small turns, the last one the slowest.
> 6.3 to 9 s: stays slumped and still; one slow breath.
> 9 to 10.2 s: one more short, smaller head shake, two turns.
> 10.2 to 12 s: stays slumped and still.
>
> Sound: only the one soft sigh at 2.1 s; silence the rest of the time. No music.

- **The video** (`.planning/emotes/so-close-gemini-api-1.mp4`, 12 s, 640x360, with sound; $0.28: 464 text tokens
  in, 23,172 video tokens out). What my stills show (two a second; not judged in motion): a wooden-jointed mannequin
  sits cross-legged on a short stack of three books (asked for six; our stack is our own), upright, hands on the
  knees; 1.5 to 2.5 s the head turns and tips towards the picture's left; by 3 s it has sagged: chest forward, head
  hanging, forearms on the thighs, hands loose over the knees, as carded; the shakes at about 4.5, 5.5, 6.5 and 9.5 s
  read in stills as the head tipping side to side more than turning; slumped and still to the end; the crossed legs
  and hips never move. **Sound** (measured by loudness, not heard by me): a faint hiss all through (about -55 dB) and
  one soft sound 2.7 to 3.2 s (about 8 dB over the hiss), on the sag: the sigh, very quiet.

- **Alan on the video (2026-11-22):** "It didn't do the looking up. Unless you can add the looking up at the first
  player part and then going back to doing the shaking the head. If you can do that, then it's good. It also has the
  sigh that we can put into the sounds." So the movement is approved with the look at 1st added in the build (it is
  in the cut), and the video's sigh is the sound.

## Build (step 4)
- **The body: a cut, not Roblox's emotes.** The card's plan was Roblox's Disagree for the shakes; Studio's tools could
  not read its keyframes this session, and Alan approved the video's slow low shake, so the shakes are by numbers
  (as Nap's breath and nod are). The seat and the resting hands are Nap B's sitting still, as Nap's.
- **Two clips, one per side of the look** (`CUTS.SoCloseLeft` and `CUTS.SoCloseRight` in `tools/emote_cuts/so-close.lua`;
  every number is in its comment): Left looks to the kid's own left (1st on the picture's right). 12 s, played once,
  held on its last pose. Marks (clip seconds): Glance 1.0, Sigh 2.1, Sag 2.5. Baked into the open place's `Assets`
  as `SoCloseLeftClip` and `SoCloseRightClip` (unsaved drafts: what `ourClip` plays in Studio) and saved as
  `assets/animations/emotes/so-close-left.rbxm` and `so-close-right.rbxm`. To bake again after a close without a
  save: `_G.EMOTE_CLIPS = { "cut:SoCloseLeft" }` in Edit, then
  `python tools/emote_preview.py STUDIO_ID x --lua=emote_clips.lua "--bake=SoCloseLeft:SoCloseLeftClip:assets/animations/emotes/so-close-left.rbxm"` (and Right).
- **What the clip does** (clip seconds): sits upright, hands on the knees, a breath every 4 s all through; 1.0 to 1.6
  the head turns 45 degrees to the side (49 to 53 measured with the chest's 8), held; 2.1 to 2.5 a small lift (chest
  4 back, head 6 up); 2.5 to 3.3 the sag: chest 20 forward, head 30 further down (65 down in all, measured), the
  head back to the front, the hands from the knees to resting on top of them; shakes at 3.3 (0.9 s), 4.2 (1.0 s),
  5.2 (1.1 s), each about 20 to 25 degrees each way measured, the head rolling a quarter of that; one smaller (about
  10) at 9.0 to 10.2; still to 12.
- **Measured on the test kid** (Edit, no pictures, every 1/30 s): the feet and hips never move (0.0000); the biggest
  turn of any joint in one key 9 to 11 degrees (a forearm in the sag; Nap's jolt has 25); the hands in the hanging
  pose go 0.050 of the kid's height into the leg boxes (Nap B's own hands-on-knees pose, which Nap is built on, goes
  0.064: the boxes are bigger than the limbs), and 0.085 for a moment as they pass over the thighs in the sag.
- **Two faults the numbers found first:** with the elbow aimed at the thigh the arm flipped over in one frame (56 to
  66 degrees) during the sag, because that aim lay almost on the line from shoulder to hand: the elbow is now aimed
  a third of the chest's width out to the side. A search for the lean that rests the elbows on the thighs chose
  almost none, losing the slump: the lean is the card's 20.

- **The module** (`src/client/emotes/SoClose.luau`; `DevRunnerUp` = "SoClose" picks it). At its start it loads the
  Left clip and holds its first pose from the dark (both clips start the same); at its first frame it looks where 1st
  stands on the picture and swaps to the Right clip if 1st is on the left. The scene's own start at this kid's light
  is not used: every frame the module sets the clip's time from **1st's** light, so clip second 1.0 (the look) is
  1st's light for both runner-ups. 2nd: clip = 1 + seconds after 1st's light (it starts at its own light). 3rd: the
  same until the look lands, then held 0.5 s longer on 1st, then 0.92 speed, so 2nd and 3rd look together and are
  out of step after (3rd's sag starts 0.5 s after 2nd's; its late shake comes 0.9 s after 2nd's). Every frame the
  kid is rested on the top book with Nap's seat (`sit`, `seatOn`).
- **Dry run of the module in Edit** (a copy of the module, two test kids as 2nd and 3rd on either side of a stand-in
  1st, the scene's timing stepped every 1/30 s with `Animator:StepAnimations`; all removed after): no error; 2nd
  took the Left clip and 3rd the Right; half a second after 1st's light both faces point at 1st (0.73 and 0.70 of
  the way, 49 and 48 degrees turned); 2nd's sag at 1.5 s after 1st's light, 3rd's at 2.0; both rest exactly on
  their seat (0.000) from the second frame on (the first frame, in the dark, 0.23 studs into the book); the sigh
  asked for once by each.
- **On 14 of the bots' outfits in Edit** (the Left clip at seven moments): it plays on every one, the head 68 degrees
  down at 9.5 s on all; a hand or forearm goes into the body's boxes at most 0.011 of the body's height more than
  that body's own hands-on-knees start (worst 0.085, on `4560704730`, whose arms already sit 0.080 deep at the
  start; Bubblegum measured the same body as the worst). **An Edit check is not Play.**
- **Not known until it is seen in Play:** how the slump and the slow shakes read at the scene's distance; whether a
  45-degree look reads as looking at 1st; long hair and hats with the head hanging 65 degrees.

## Sound (step 5)
- **One sound, the video's own sigh** (Alan: "the sigh that we can put into the sounds"):
  `assets/audio/emotes/so-close-sigh.ogg`, 0.86 s, cut from 2.64 to 3.50 s of `so-close-gemini-api-1.mp4` (the sigh
  rises from 2.66 s, is loudest at 2.80, tails off by 3.35; measured by loudness, not heard by me). Lightly
  de-hissed, a 0.03 s fade in and 0.2 s out, raised 8.5 dB so its loudest point is 28 dB under full (first cut: 29.3 dB, 6 dB under full; Alan: "way too loud";
  the video's hiss is about 10 dB under the sigh). Not uploaded.
- **When it plays:** clip second 2.5 (the mark Sag: the exhale as the body sags), once per kid. That is 1.5 s after
  1st's light for 2nd and 2.0 s for 3rd. The module already asks for it as `soCloseSigh` through `runnerSound`;
  it plays once step 6 adds `soCloseSigh` to `src/client/Audio.luau` (at volume 1: the file is already quiet). Because it is a runner-up's sound it is skipped when it would still be playing as 1st's first sound
  starts: with Bubblegum on 1st (its snap 2.0 s after 1st's light) neither sigh plays.

## First run in Play (step 6, 2026-11-22; the primary session's muted recording)
- **Ran with no script error**, on 2nd and 3rd at once, with A+ on 1st. Raw: `.planning/emotes/aplus-soclose-first-run-raw.mp4`
  (2032 x 800, 30 s; 3rd's light about 11.9 s, 2nd's 12.9, 1st's 13.93). With the sigh laid at 1.5 and 2.0 s after
  1st's light, 14 dB down: `.planning/emotes/aplus-soclose-first-run-sound.mp4`.
- **Seen in the primary session's stills** (two a second, not judged in motion): both kids sit cross-legged on their
  books from the dark on, neither floats; both are slumped well forward from about 2 s after 1st's light, heads
  hanging, and stay so. 2nd was a wide black body with a yellow pet on the shoulder; 3rd a white checked one with a
  cap, whose head ends up almost in the lap. Not readable in stills: the look at 1st and the head shakes.
- **From the pairing with A+:** A+'s landed card covers 3rd for the last 2.6 s, and A+'s first sound (2.2 s after
  1st's light) cuts both sighs in the game (each would still be playing).
- **Alan on the sound recording (2026-11-22): "the sigh is way too loud it should be subtle".** The file is now
  20.8 dB quieter than my first cut (its loudest point 28 dB under full; the recording he heard peaked 4 dB under
  full): the quiet is in the file itself, so it plays at volume 1 in `Audio`. Heard against the raw recording, both
  sighs at their times (1.5 and 2.0 s after 1st's light): `.planning/emotes/so-close-sigh-quieter.mp4`. Waits for
  his listen.

## Files
| File | What |
|---|---|
| `assets/audio/emotes/so-close-sigh.ogg` | The sigh |
| `src/client/emotes/SoClose.luau` | The emote's module: picks the clip, times it to 1st's light, the seat, the sigh |
| `tools/emote_cuts/so-close.lua` | The body cut: `CUTS.SoCloseLeft`, `CUTS.SoCloseRight` |
| `assets/animations/emotes/so-close-left.rbxm`, `so-close-right.rbxm` | The two baked clips |
