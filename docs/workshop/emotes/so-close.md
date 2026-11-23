# So Close

A runner-up emote (2nd and 3rd). Made by the [emote pipeline](../emote-pipeline.md), in its own side session; the idea is on the
[plan](../../plan/WINNERS-CIRCLE-PLAN.md).

**The idea:** Sits on the books shaking their head, sad not to be 1st (Alan).

## Where it stands
Step 3: the reference video is made (2026-11-22) and waits for Alan's look and listen.

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

## Files
None yet.
