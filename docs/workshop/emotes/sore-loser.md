# Sore Loser

A runner-up emote (2nd and 3rd). Made by the [emote pipeline](../emote-pipeline.md); the idea is on the
[plan](../../plan/WINNERS-CIRCLE-PLAN.md); picked by Alan in [the second four runner-ups](../../decisions/2026-11-24-four-more-runner-up-emotes.md).

**The idea:** Arms crossed, back turned to 1st, sneaking looks over the shoulder.

## Where it stands
**Step 3: the reference video is made** (Alan's go, $0.28); waiting for his OK on the movement.

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
