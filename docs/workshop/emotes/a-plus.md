# A+

A 1st-place emote that covers the camera. Made by the [emote pipeline](../emote-pipeline.md), in its own side session; the idea is on the
[plan](../../plan/WINNERS-CIRCLE-PLAN.md).

**The idea:** Holds up their report card and slaps it on the lens, where it becomes the real report card.

## Where it stands
Step 3: the card is OK'd with Alan's picks (2026-11-22); the reference video is made and waits for his look and
listen. Nothing built.

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

Waits for Alan's look and listen.

## Files
None yet.
