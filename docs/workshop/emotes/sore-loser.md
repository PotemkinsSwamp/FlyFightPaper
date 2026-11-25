# Sore Loser

A runner-up emote (2nd and 3rd). Made by the [emote pipeline](../emote-pipeline.md); the idea is on the
[plan](../../plan/WINNERS-CIRCLE-PLAN.md); picked by Alan in [the second four runner-ups](../../decisions/2026-11-24-four-more-runner-up-emotes.md).

**The idea:** Arms crossed, back turned to 1st, sneaking looks over the shoulder.

## Where it stands
**Ready to record** (2026-11-24): steps 3 and 4 done, step 5 skipped (silent, Alan's pick). The body is two cut clips,
`SoreLoserLeft` and `SoreLoserRight`, not yet baked into the place (the primary session bakes them: see Build); the
module is `src/client/emotes/SoreLoser.luau` (`DevRunnerUp` = "SoreLoser"). Marks (clip seconds; clip 1.0 is 1st's
light): Huff 1.3, Peek 3.0, Snap 5.6, Peek2 7.2, Snap2 10.5. Checked by numbers in Edit only; not yet seen in Play.

## Shot card
**Alan's OK (2026-11-24):** "Sore loser looks good." No pick named, so my defaults: standing, silent.

**The feeling, in one line:** "It's not fair. I should have won." Jealous and sulking, pretending not to care.

**How the body carries it** (faces cannot): stiff and held. The kid stands turned away from 1st, side-on to the
camera, arms crossed tight and high, chin up. Almost nothing moves, so the one thing that does is the joke: the head
creeps round slowly to peek at 1st, then snaps back fast, as if caught.

**Timing:** seconds after 1st's light (2nd is lit 1 s before it, 3rd 2 s before; the scene leaves about 10.4 s after).

| Time | The kid | Props | Camera | Sound |
|---|---|---|---|---|
| From the dark to 1st's light | Stands on the books, turned away from the middle, arms crossed, chin up, still | None | Steady on all three (fixed) | None |
| 0 to 1.5 s | Does not look. One small huff: the shoulders rise and drop | None | Steady | None |
| 1.5 to 2.3 s | The head creeps round over the shoulder towards 1st, slowly | None | Steady | None |
| 2.3 to 3.1 s | Holds the peek | None | Steady | None |
| 3.1 to 3.3 s | Snaps the head back, chin a little higher than before | None | Steady | One quiet "hmph" (if Alan wants one) |
| To the end | The same peek about every 4 s, each held a little longer; between peeks one impatient foot tap | None | Steady | None |

- **Both sides:** each runner-up turns away from the middle, so 2nd and 3rd are mirror images (two clips, as So Close has).
- **Roblox's own emotes, checked first:** none known with crossed arms and a turned back; looked for at step 4. Else the body is cut from the video.
- **Reused:** the runner-up sound rule (plays only if it ends before 1st's sounds begin); So Close's "which side is 1st on" and its Left and Right clips; `bendArm` for the crossed arms.
- **New:** nothing as a mechanic.
- **Risk:** crossed arms are the hardest pose to fit on every body (thick arms, short arms). An odd body that hides it is the accepted loss ([decision](../../decisions/2026-11-21-plane-stays-in-the-hand.md)).
- **No lens moment, no props.**
- **For Alan to pick:**
  1. Standing on the books **or** sitting on them with the back turned. My default: standing (two of the new four stand, two sit).
  2. One quiet "hmph" on the snap back **or** silent. My default: silent (1st's own sounds would cut it in most pairings).

## Reference video (step 3)
One Gemini call, `tools/gemini_video.py`, 360p, 12 s (the longest a runner-up is lit, rounded down), silent.
Price as So Close's: about **$0.28**. The video's second 0 is 2nd's light, so video = card time + 1 s. The kid faces
the picture's right and peeks towards its left, as 3rd does (1st on 3rd's left); 2nd is the mirror. The prompt
(`.planning/emotes/sore-loser-prompt-1.txt`):

> One continuous 12-second shot, no cuts. Fixed camera, straight on, level with the standing figure's chest, not moving or zooming. Plain light grey room, soft even light, no text, no music.
>
> A simple smooth grey mannequin with no face stands on top of a solid, steady stack of six large dark hardback books. The whole stack and the whole figure are in the picture, with empty space above the head. The mannequin stands side-on to the camera, its body turned to face the right edge of the picture, its back to the left of the picture, where the winner stands just out of view. Its feet never leave their spot on the top book and its body never turns; only the head turns.
>
> Attitude: a kid who came second and thinks it is not fair. Jealous and sulking, pretending not to care. The body is stiff and held: the arms are crossed tight and high across the chest the whole time, the chin is up. Almost nothing moves, so the head's peeks are the joke: each one creeps round slowly, then snaps back fast, as if caught looking.
>
> Hard rule for the arms: crossed tight and high across the chest for the whole shot, each hand tucked against the other arm. They never uncross, and the hands never touch the face or the head.
>
> 0 to 1 s: stands still, arms crossed, chin up, looking ahead to the right of the picture.
> 1 to 2.5 s: does not look. One small huff: the shoulders rise and drop once.
> 2.5 to 3.3 s: the head creeps round slowly over the shoulder, towards the left of the picture, peeking at the winner.
> 3.3 to 4.1 s: holds the peek.
> 4.1 to 4.3 s: snaps the head back to face the right of the picture, fast, chin a little higher than before.
> 4.3 to 6.5 s: still; at about 5.5 s one impatient tap of the front foot on the book.
> 6.5 to 7.3 s: the head creeps round again over the same shoulder, slowly.
> 7.3 to 8.5 s: holds the peek, a little longer this time.
> 8.5 to 8.7 s: snaps the head back, fast, chin up.
> 8.7 to 10.5 s: still; at about 9.5 s one more impatient foot tap.
> 10.5 to 11.3 s: the head creeps round a third time.
> 11.3 to 12 s: holds the peek to the end.
>
> Sound: silence the whole time. No music, no voice.

- **The video** (`.planning/emotes/sore-loser-gemini-api-1.mp4`, 12 s, 640x360; $0.28: 587 text tokens in, 23,172
  video tokens out). What my stills show (two a second; not judged in motion): a smooth mannequin stands side-on on a
  short stack of books (asked for six), facing the picture's right, arms crossed high the whole time; the body and
  feet stay put. Peeks: the head turns round towards the camera at about 3 to 4 s, 7 to 8 s and 11 s to the end; it
  turns about towards the camera, not all the way back to the left. Foot taps at about 5.5 and 9.5 s: the back foot
  lifts behind. Small in the picture: the head turns are hard to read in stills.

- **Alan on the video (2026-11-24):** "This is good. This is a good reference video. I would just fix the timing a
  bit. It's a little fast. But yeah, I think this is good to work with." So the movement is approved, slower: in the
  build every creep and hold is longer than the video's; only the snaps back stay fast.

## Build (step 4)
- **The body: a cut, not Roblox's emotes.** No Roblox-made emote has crossed arms (the Creator Store search for one
  found only unrelated models), and none turns the back. Two clips, the same but for the side
  (`CUTS.SoreLoserLeft` and `CUTS.SoreLoserRight` in `tools/emote_cuts/sore-loser.lua`; every number is in its
  comment): Left is for 1st on the kid's own left (1st on the picture's right): the body turned to the kid's right,
  the peeks over the left shoulder. 12 s, played once, held on its last pose.
- **What the clip does** (clip seconds; 1.0 is 1st's light): stands on Toy Pilot's stance (Bubblegum's), the whole
  body turned 70 degrees away from 1st, arms crossed, chin up 8 degrees, a 1-degree breath every 4 s; 1.3 to 2.7 the
  huff (chest 5 back over 0.5 s, then 2 past where it was and settling); **3.0 to 4.3 the first peek creeps round**
  (head 55, chest 15: the face comes round to the camera; the chin dips 6, sneaking), held to 5.6, **5.6 to 5.85
  the snap back**, the chin 4 higher after it; 6.5 to 7.0 one toe tap of the foot away from 1st (18 degrees, the
  heel down); 7.2 to 8.5 the second peek, held 2.0 s (the first 1.3), snapped back 10.5 to 10.75; still to 12. The
  video's creeps take 0.8 s and its holds 0.8 and 1.2 s (Alan: "a little fast"); only two peeks fit before the
  scene leaves (the card's third is dropped).
- **The crossed arms** are Skeet Shoot's (Alan's note there: "one arm folds under the other"): each elbow placed,
  the forearm folded straight across, the right arm over and in front, the left tucked under; here in the chest's
  frame so they turn and huff with it, and the elbows further forward than Skeet Shoot's (see below).
- **Measured on the test kid** (Edit, no pictures, every 1/30 s): the feet never move or sink (0.0000); the body faces
  70 degrees away; the head at 70 away, at the peeks 0 (to the camera), chin 8 up, 2 at the first peek, 12 after;
  elbows bent 77 and 71 degrees, forearms within 5 degrees of level, about 0.17 of the kid's height in front of the
  chest; a forearm 0.043 heights into the chest's box at most, the forearms 0.043 into each other; the toe lifts
  0.06 heights; the biggest turn of a joint in one key 11 degrees, in the snap (meant to be fast).
- **Two faults the numbers found first:** hands aimed at points across the chest were out of a blocky arm's reach, so
  the arms stuck out in front (a search of 720 places: those reached went 0.08 into the chest); and with Skeet
  Shoot's own fold the tucked arm went 0.04 to 0.11 heights into the chest's box on the bots' bodies (Skeet Shoot
  measured 0.031 there). Both elbows brought further forward and the tucked hand a little out from the chest halved
  it (a 36-way search on the test kid).
- **On the twelve bots' outfits in Edit** (the fixed cast's outfit ids; the clip baked into a scratch folder,
  played with `Animator:StepAnimations` at ten moments, everything removed in the same call): it plays on every one;
  the head 70 degrees away, at the peek to the camera, on all; the feet never move (the first body of the first run
  read 0.07: Studio still loading the clip, 0.000 when run again) and sit at most 0.006 of the body's height lower
  than standing still; the elbows bent 63 to 77 degrees. A forearm or hand goes 0.006 to 0.046 heights into the
  chest's box on eleven, **0.059 on `3285769426`** (the longest arms, 0.61 of the height), the forearms 0.030 to 0.055
  into each other. No very stout or short-armed body is in the cast (arms 0.46 to 0.61 of the height), so the known
  risk, crossed arms on a thick body, is not measured: such a body hiding the pose is the accepted loss. **An Edit
  check is not Play.**
- **The module** (`src/client/emotes/SoreLoser.luau`; `DevRunnerUp` = "SoreLoser" picks it). As So Close's: at its
  start it loads the Left clip and holds its first pose from the dark (turned away, arms crossed); at its first
  frame it swaps to the Right clip if 1st stands on the picture's left. The scene's own start at this kid's light is
  not used: every frame the clip's time is set from 1st's light: 2nd, clip = 1 + seconds after 1st's light; 3rd the
  same 0.6 s later, so both never peek as mirror images. So after 1st's light, 2nd's first peek starts at 2.0 s and
  snaps back at 4.6; 3rd's at 2.6 and 5.2; 3rd's second snap ends 10.35 s after it, just before the scene leaves
  (about 10.4).
- **Dry run of the module in Edit** (a copy, fake clips and winners, removed after): no error; 2nd left of 1st took
  the Left clip, 3rd right of 1st the Right one; clip times at 1st's light 1.0 (2nd) and 0.4 (3rd).
- **For the primary session, before the recording** (the bake writes the place's `Assets`, a shared file, so it is
  yours): `_G.EMOTE_CLIPS = { "cut:SoreLoserLeft" }` in Edit, then
  `python tools/emote_preview.py STUDIO_ID x --lua=emote_clips.lua "--bake=SoreLoserLeft:SoreLoserLeftClip:assets/animations/emotes/sore-loser-left.rbxm"`
  (and the same for Right); and its Dev button in `winnersDev.ups` (`src/client/FlightHUD.luau`).
- **Not known until it is seen in Play:** whether 70 degrees reads as turned away at the scene's distance and still
  shows the crossed arms; whether the peek reads as looking at 1st (the face comes round to the camera, as in the
  video, not all the way to 1st); hats and hair with the head turned 70 degrees; whether the slower timing is right.

## Sound (step 5)
None: Alan took the silent default on the card.

## Files
| File | What |
|---|---|
| `src/client/emotes/SoreLoser.luau` | The emote's module: picks the clip, times it to 1st's light |
| `tools/emote_cuts/sore-loser.lua` | The body cut: `CUTS.SoreLoserLeft`, `CUTS.SoreLoserRight` |
