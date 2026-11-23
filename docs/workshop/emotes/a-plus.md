# A+

A 1st-place emote that covers the camera. Made by the [emote pipeline](../emote-pipeline.md), in its own side session; the idea is on the
[plan](../../plan/WINNERS-CIRCLE-PLAN.md).

**The idea:** Holds up their report card and slaps it on the lens, where it becomes the real report card.

## Where it stands
**Ready to record** (2026-11-22). Built from Alan's pick of the two reference videos, checked by numbers in Edit only:
nobody has seen it move, never run in Play. Its sounds are cut and timed, not uploaded. Next: step 6, the primary
session's muted recording and Alan's look and listen.

## Shot card
**OK'd by Alan, 2026-11-22**, with his picks: "I like the idea. I think it should show only the front. I think it
should be lands and then gloats." On the card itself: "it should look very similar to the actual report card ... it's
not a big change from the report card he's holding and the report card that you see at the end. Of course, the text on
it should be kind of blurry and hard to read because ... we don't want to regenerate every time the actual report
card." On the landing: "it should look exactly like he's the one who put the report card up there. Like it should line
up perfectly."

**The feeling:** smug show-off, "read it and weep". Slow and showy, chest out, chin up; then one sharp slap.

**The clock it lives in** (from `Cutscene.play`): the camera holds on the three winners 10.4 s after 1st's light, then
leaves; the real report card comes up as it leaves and gets its 10 s (`CARD`). A+ does not change when the camera
leaves, so the card keeps all 10 s.

**Sizes** are shares of the picture's height. The picture at the winners is at least 3.45 kid heights tall, so a card
0.35 kid heights tall (waist to chin) is about a tenth of it. The real card (one-player rounds) fills 83% of the
screen's height, on the right side (about 64% to 99% across), square.

| Time (s after 1st's light) | The kid | The card | What the camera sees | Sound |
|---|---|---|---|---|
| 0 to 2.0 | Holds the card at the waist with both hands, head down, reading it; one slow nod at 1.5 | Its plain paper back to us | All three winners, steady | Quiet (2nd's and 3rd's sounds end before the flap) |
| 2.0 to 2.4 | Snaps it up over the head, both arms straight, chest out | High over the head, a tenth of the picture tall, its front to us | Same | **Paper flap**, short |
| 2.4 to 5.0 | Holds it up; turns slowly from the waist to show it to one runner-up, then the other, then back to us; feet stay put | Same | Same | None |
| 5.0 to 6.5 | Brings it down; the right hand alone holds it beside the face, left fist on the hip, looking straight at the camera | A tenth tall, beside the face, front to us | Same | None |
| 6.5 to 7.4 | Wind-up: right arm back past the shoulder, card flat, body twists away | Behind the shoulder | Same | None |
| 7.4 | The slap: the arm whips forward, flat palm at the camera; the card leaves the hand | Leaves the hand | Same | None (no whoosh) |
| 7.4 to 7.8 | Follow-through, palm out | Flies at the lens front first, turning square as it comes; grows slowly, then fast: a tenth, about 15% halfway, 83% at the end | Same | None |
| 7.8 | Palm still out | **Slaps flat on the lens exactly where the real card sits**, square, no skid | The camera jolts (Book Kicker's); the three name plates go | **The slap**: a flat paper smack, the loudest |
| 7.8 to 10.4 | Brushes the palms together once, then folds the arms, weight on one leg, chin up: gloating | Still on the lens | 1st in the middle, gloating beside the card; the runner-up on the right is hidden behind it | None |
| 10.4 | (out of view as the camera leaves) | **The real card takes over** in the same frame, same place, same size; its Double button, jar and mission slip pop in as they always do | The glide home, as always | None (the card's own) |

**The card the kid holds** (Alan: front only, very like the real card, its writing hard to read, never rebuilt from the
results): the real card's picture (`UIArt.results.reportCard`) with the same printed parts in the same places and
fonts: "PAPER FLIGHT 101", "REPORT CARD", the column heads, "Teacher's note:", "Your pocket money:", the red ring in the
top box and on the top row's grade. Everything filled in (names, numbers, grades, the note, the place) is faint ink
scribble in the same rows, the same every time (Book Kicker's `scribbled` handwriting), so it cannot be read. Its back
is plain paper.

**How it becomes the real one:**
- **Lines up perfectly:** the flying card ends exactly over the real card's rectangle, worked out on that frame from
  where the real card sits on that screen (PC, wide window or phone), square, no skid.
- **Same look:** same picture, same printed words in the same places; lit by nothing in the room, so the dark room does
  not darken it.
- **When:** at 10.4 s, when the camera leaves as always, the real card shows and the copy goes in the same frame: the
  scribbles turn into the real names and numbers, nothing else changes. Its 10 s start then, untouched. (Counting the
  copy, a card is on screen 2.6 s longer than usual.)
- **Team rounds** (two cards, Red left, Blue right): it becomes the card of 1st's team; the other comes up at the
  take-over as usual. My default.
- **Not known until seen:** whether the printed words on a 3D sheet are sharp enough that the swap does not blink.

**The body:** none of the 12 Roblox emotes the game already uses (Godlike, Celebrate, Jumping Cheer, Greatest and the
runner-ups' dances) holds something up or throws; a body cut from the Gemini video, as Book Kicker and Bubblegum. The
card is fixed to the hand(s) on every body.

**Reused:** Book Kicker's camera jolt, its hiding of the name plates, its flight-to-the-lens sums and its scribbles;
Camera Flick's flight time (about 0.4 s). Art already loaded: the report card picture, its red ring, the card's own
fonts. No new picture; uploads only the clip and two sounds.

**New (covered by Alan's OK):** the look-alike card in the kid's hand; the take-over at the camera's leaving. **From the
primary session later:** the emote hook, a way to find where the real card sits, and the name plates hidden from the
landing.

**Design check** (design-theory; on words now, on a screenshot at step 4): the look-alike keeps every printed part of
the real card, so nothing jumps at the swap; the real card is not changed.

## Reference video (step 3)
**The prompt** (`.planning/emotes/a-plus-gemini-prompt.txt`, untracked): an 11 s shot at 360p, the mannequin on a
shoulder-high stack of six books, the card's times as in the table, the card stuck on the lens's right third from
7.8 s, the two sounds asked for at their moments (the slap the loudest), no music. Price: about $0.26 (11 s x 1,931
video tokens a second at $12 a million, the words almost free).

**The video** (Alan: "go make the video"; about $0.26: 611 text tokens in, 21,241 video tokens out):
`.planning/emotes/a-plus-gemini-api-1.mp4`, 11 s, 640x360, with sound. What my stills show (two a second, ten a second
over the throw):
- **As asked:** reading it at the chest 0 to 1.5 s; snaps it up overhead with both arms at 2.0 to 2.5; the throw at
  7.3 to 7.7 (the arm swings in from the side, the card goes flat and flies at the camera); at 7.9 it is stuck flat and
  square on the right third, and stays; palms rubbed together 8.1 to 8.4; arms folded, weight on one leg, still to the
  end.
- **Not as asked:** the card is held in the kid's left hand (the picture's right) from 3.5 s, with the other fist up at
  4 to 4.5 and on the hip from 5; the turn shows only one side (side-on at 3.0 s), not both; the reading shows the
  card's printed front, not its back; the stack is about knee-high, not shoulder-high (asked for by size, missed again,
  as with Bubblegum).
- **Sound** (by loudness, not heard by me): a quiet paper flap at 2.3 to 2.4 s, on the snap overhead; a faint swish at
  7.4 to 7.5 on the throw; the smack at 8.0 s, about 18 dB over the flap, 0.1 s after the card lands in the picture.
  Nothing else, no music.

**Alan on the first video:** "there's a lot missing there. You should have extended the time. It probably tried to
smush all the time in ... extend the time and try to get it to do the things that it missed."

**Second prompt** (same file, rewritten): 15 s; every beat about 1.4 times longer (the slap's release at 10.6, the
card on the lens at 11.1); the blank back to the camera while reading, said outright; the card in the kid's own right
hand (the picture's left) until the throw; the turn to the picture's left, hold, to the right, hold, back; the stack in
metres (1.3 m of books under a 1.6 m figure).

**The second video** (Alan: "go make the video"; about $0.35: 750 text tokens in, 28,965 video tokens out; Gemini so
far for A+ about $0.61): `.planning/emotes/a-plus-gemini-api-2.mp4`, 15 s, 640x360, 24 frames a second, with sound.
What my stills show (two a second, close crops at six moments):
- **Fixed:** the slow pace, nothing crammed; the card in the kid's right hand (the picture's left) beside the head
  from 7.5 s, the other hand on the hip; the wind-up at 10.0, the release at 10.5, the card tumbling across to the
  picture's right and stuck flat there from about 11.4, square, to the end; palms together at 11.5; arms folded,
  still, 12 to 15.
- **Still missed:** the reading shows the printed front again; the turn goes only to the picture's left (side-on, arms
  out, 4.5 to 5.5 s) and back, never to the right; the stack is still about knee-high; the card on the lens looks a
  little smaller than a third of the picture.
- **Sound** (by loudness, not heard by me): the flap at 3.2 to 3.4 s, on the snap overhead; a swish on the throw at
  10.8; the smack at 11.3, with a short tail to 11.4. Nothing else, no music.

**Alan on the second video:** "the first one was better. This one is I don't know about this one." Both videos were
made at 360p (640x360), the lowest size; he asked that references never be made bigger. My offer: build from the
first video, its moves spread over the game's 10.4 s, with its misses fixed in the build. **Alan: "yes build from the
first one".** Gemini spent on A+: about $0.61.

## Build (step 4)
- **The body: a cut by numbers, not Roblox's emotes** (none of the game's holds something up or throws).
  `CUTS.APlus` in `tools/emote_cuts/a-plus.lua` (every number in its comment), on Toy Pilot's standing pose, both feet
  planted; 11 s, played once, held on its last pose. Seconds after 1st's light: reading at the chest, head down, a nod
  at 1.5; 2.0 to 2.4 the snap, the hands up in front of the face and on over the head; the waist turns 35 degrees to
  the kid's left (3.0 to 3.4) and to their right (4.2 to 4.5), back by 5.0; the arms come down round the outside, the
  right hand out beside the head, the left fist on the hip, a nod at 6.0; the wind-up 6.5 to 7.2 (chest twisted 28
  degrees away), the whip to 7.55 with the release at 7.4; palms meet at 7.9, one brush to 8.4; arms folded, weight
  on the right leg, chin up, from 9.1. The video's misses fixed here: the card stays in the right hand, it is shown to
  both sides, the reading shows its back.
- **The clip:** baked into the open place's `Assets` as `APlusClip` (unsaved draft: what `ourClip` plays in Studio),
  saved as `assets/animations/emotes/a-plus.rbxm`. Marks: Snap 2.0, Release 7.4. To bake again after a close without
  a save: `_G.EMOTE_CLIPS = { "cut:APlus" }` in Edit, then
  `python tools/emote_preview.py STUDIO_ID x --lua=emote_clips.lua "--bake=APlus:APlusClip:assets/animations/emotes/a-plus.rbxm"`.
- **The module** (`src/client/emotes/APlus.luau`; Studio's Dev attribute `DevFirstEmote` = "APlus"):
  - **The card:** a part 0.35 winner heights tall, the real card's shape (680 by 900), plain paper colour on the back.
    Its face is the real card's page (`PlayerGui.RoundEnd`, `Results.Page1`, or `Page2` when that one has the visible
    gold star), copied once when the winners' moment starts. Its pictures and printed words stay; every filled-in
    word (names, numbers, grades, the term, the place, the note, the pocket money, the level) is hidden under a faint
    zig-zag of ink, as long as the word was and in its colour. Unseen in the dark until 1st's light.
  - **In the hand:** its bottom edge on the right hand every frame, facing the kid while reading (top leaning 25
    degrees away), turned to face the camera over the snap (2.0 to 2.35), then turning with the chest; centred
    between the two hands until 5.0, over the right hand from 5.6. Where its plane cuts the head it moves out
    sideways or up by the overlap, so it never goes through a head of any size.
  - **The slap:** at Release it leaves the hand and flies 0.4 s to the lens in the camera's own frame (a straight
    path, so it grows slowly, then fast), turning square on the way. It lands at 7.8 on the real card's rectangle,
    worked out every frame from the real page's place, size and turn on this screen, at the depth where the card's
    own size fills it. On the lens it is lit by nothing, as the screen card is. The camera jolts (Book Kicker's
    `jolted`, from 7.8). Name plates and the Menu tag go from the landing until the swap (`covered`).
  - **The swap:** the scene's own leave time is kept (10.4 s after 1st's light), so the report card keeps its 10 s.
    The frame after the real page shows, the copy goes: the two are drawn together for one frame, never neither.
- **Measured on the test kid in Edit** (`emote_preview.py --run`, no pictures): the feet move at most 0.008 heights;
  the fastest part is the hand in the whip, 0.156 heights in a thirtieth of a second (7.43 s); a hand or forearm at
  most 0.023 heights into the body's boxes (at the brush).
- **The module run in Edit with stand-ins** (its text, a plain kid, a made-up camera 40 studs off; no Play, no
  camera): no error; the card on the hand until 7.4; at 7.79 it covers about a third of the screen, at 7.8 exactly
  the real card's spot (with no results card in Edit, the spot of a 1920 by 1080 sheet fitted to the 2046 by 801
  window: 1216 to 1720 across, 30 to 697 down, 2.5 studs from the lens); `covered` from the landing; the flap asked
  for once.
- **On 14 of the bots' outfits in Edit** (the draft played with `Animator:StepAnimations`, the module's card in the
  hand, to the release): it plays on every one. The card goes at most 0.024 of the body's height into the head's box
  (box corners against a round head). A hand or forearm goes into the body at most 0.059 more than the body's own
  start, on two bodies with big heads, when the waist turns to the right with the arms up (the left forearm against
  the side of the turned head's box); elsewhere at most 0.04. Reading, the card's top is 0.06 to 0.15 heights over
  the chin on most bodies: the lower face is behind the card for the first 2 s. **An Edit check is not Play.**
- **Not known until it is seen in Play:** how the copy reads in the hand at the scene's distance; whether the swap
  shows on screen (the copy is drawn on a 3D sheet, the real card on the screen); whether the gloat reads as smug;
  arms overhead on hats and hair.

## First recording (step 6, the primary session's, 2026-11-22)
- **Muted Play recording** (`.planning/emotes/aplus-soclose-first-run-raw.mp4`, 2032 x 800, 1st's light at 13.93 s;
  with my sounds laid in: `aplus-soclose-first-run-sound.mp4`): no script error. Seen in its stills: the back at the
  chest, the snap, both turns, the card beside the head, the flight, the landing on the right, the scribbles, name
  plates and Menu tag away, the real card after.
- **The fault:** on the lens the copy was about 8% bigger than the real card and about 50 px higher (its top off the
  screen), so at the swap the card shrank and dropped. Also seen in my crops: the scribbled names were still readable
  under their zig-zags (a word's crayon look is three child copies of it, which kept their letters).
- **Fixed in the module, checked by numbers in Edit, not yet seen:** the real card's spot is now worked out from the
  page's place on its sheet and the sheet's place on the screen (the hidden card's own Absolute values are not
  trusted), and Roblox's camera turns those pixels into directions (`ViewportPointToRay`) instead of my own sums with
  the field of view. On a stand-in of the results screen's frames in Edit the sum gives Roblox's own layout to the
  tenth of a pixel, for the one-player spot and a team spot; the dry run lands the card exactly on the expected spot
  (1216 to 1720 across, 30 to 697 down on the 2046 x 801 window). The child copies of a scribbled word are emptied
  with it.
- **For Alan to judge, not bugs:** the landed card covers 3rd for the last 2.6 s; the card's back hides the kid's
  chest and chin for the first 2 s; with A+ on 1st, So Close's sigh is cut by A+'s first sound at 2.2 s.

## Sound (step 5)
- **From the video Alan picked** (`a-plus-gemini-api-1.mp4`; its sounds were in what he OK'd), measured every 10 ms,
  not heard by me: the paper flap from 2.29 to 2.57 s, its crack at 2.38 to 2.40; a faint swish on the throw at 7.46
  to 7.52 (not used: the card says no whoosh); the smack at 7.99 to 8.25, its peak at 8.00, just under full loudness.
- **Cut into two files, not uploaded:** `assets/audio/emotes/a-plus-flap.ogg` (0.335 s, raised 13 dB to a peak of
  -6.4 dB; its crack 0.115 s in) and `assets/audio/emotes/a-plus-slap.ogg` (0.335 s, as it was, peak -0.9 dB; the
  smack 0.035 s in).
- **When they play** (seconds after 1st's light; `APlus.sounds` in the module, names for `Audio` at step 6):
  `aPlusFlap` at 2.2 (Snap + 0.2: its crack at 2.32, as the card reaches the top of the snap); `aPlusSlap` at 7.8,
  the landing. `firstSound` 2.2: the runner-ups' sounds stop before the flap. Volumes are step 6's.

## Files
- `src/client/emotes/APlus.luau`: the card, its flight, the swap, the camera jolt, the sound times.
- `tools/emote_cuts/a-plus.lua`: the body cut, `CUTS.APlus`.
- `assets/animations/emotes/a-plus.rbxm`: the baked clip.
- `assets/audio/emotes/a-plus-flap.ogg`, `assets/audio/emotes/a-plus-slap.ogg`: the two sounds.
