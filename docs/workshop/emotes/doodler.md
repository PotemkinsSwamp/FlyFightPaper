# Doodler

A runner-up emote (2nd and 3rd). Made by the [emote pipeline](../emote-pipeline.md); the idea is on the
[plan](../../plan/WINNERS-CIRCLE-PLAN.md); picked by Alan in [the second four runner-ups](../../decisions/2026-11-24-four-more-runner-up-emotes.md).

**The idea:** Scribbles in a notebook, then holds up a drawing of themselves in 1st. Stick figures: a child drew it (Alan).

## Where it stands
**Step 3: the reference video's prompt is written** (below); it waits for Alan's go on the price (about $0.28). Nothing is made.

## Shot card
**Alan's OK (2026-11-24):** "Doodler looks good." No pick named, so my defaults: the kid alone in the drawing, silent.

**The feeling, in one line:** "In my head, I won." Lost in a daydream, then proud of the drawing and a little cheeky.

**How the body carries it** (faces cannot): hunched over the notebook, head down, shut off from the room. The pencil
moves in a few short bursts with still moments between. Then the kid sits up tall, turns the notebook round and
holds it out to us with both hands, head tipped to one side: the pride is in sitting up.

**Timing:** seconds after 1st's light (2nd is lit 1 s before it, 3rd 2 s before; the scene leaves about 10.4 s after).

| Time | The kid | Props | Camera | Sound |
|---|---|---|---|---|
| From the dark to 1st's light | Sits cross-legged on the books, notebook on the lap, head down, pencil moving in short bursts | Notebook, pencil | Steady on all three (fixed) | None |
| 0 to 1.2 s | Looks up at 1st, pencil still, the way someone drawing checks what they are drawing | Notebook, pencil | Steady | None |
| 1.2 to 3.5 s | Head down again: two more bursts, then one big last stroke | Notebook, pencil | Steady | Faint pencil scratches (if Alan wants them) |
| 3.5 to 4.5 s | Sits up tall, turns the notebook round and holds it at the chest, facing us | The drawing shows | Steady | None |
| To the end | Holds it up; tips the head; once, slowly, tilts the notebook left and right to show it off | The drawing shows | Steady | None |

- **The drawing:** thick crayon lines so it reads from far off: a stick kid standing on a tall stack of books, arms up, a big "1" and a star over the head. Drawn in code as pen strokes (as the back of A+'s card is), so no upload.
- **How big:** the notebook is about as wide as the kid's chest. At the scene's distance that is small, so the drawing is a few bold shapes. Its size in the picture is measured at step 4 and Alan sees a still of it before it is called done.
- **Every pencil burst is short** and the drawing is hidden until the turn, so the hand never works longer than the viewer can follow (Alan's rule from Next One).
- **Roblox's own emotes, checked first:** none known for writing while seated; looked for at step 4. Else cut from the video.
- **Reused:** Nap's cross-legged seat (`sit`, `seatOn`); A+'s code-drawn strokes; props fixed to the hands.
- **New:** nothing as a mechanic. Two small props (notebook, pencil).
- **No lens moment.**
- **For Alan to pick:**
  1. The drawing: the kid alone on top with a "1" and a star **or** the kid on top with two smaller stick kids below. My default: alone (fewer lines read better at this size).
  2. Faint pencil scratches **or** silent. My default: silent.

## Reference video (step 3)
One Gemini call, `tools/gemini_video.py`, 360p, 12 s (as So Close: about the longest a runner-up is lit), silent
asked for (the model returns a sound track anyway; nothing is cut from it). Price as So Close's: about **$0.28**.
Video seconds are 1 + seconds after 1st's light (as 2nd's clock). The look goes to the picture's left, as from 3rd's
desk; 2nd's is the mirror. The prompt (`.planning/emotes/doodler-prompt-1.txt`):

> One continuous 12-second shot, no cuts. Fixed camera, straight on, level with the seated figure's chest, not moving or zooming. Plain light grey room, soft even light, no text, no music.
>
> A simple smooth grey mannequin with no face sits cross-legged on top of a solid, steady stack of six large dark hardback books. The whole stack and the whole figure are in the picture, with empty space above the head. The mannequin faces the camera for the whole shot; its hips and crossed legs never leave their spot on the top book.
>
> It holds a small open spiral notebook, about as wide as its chest, and a short yellow pencil. Hard rule for the hands: the left hand always holds the notebook and the right hand always holds the pencil; neither is ever put down, dropped or let go. The hands never touch the face or the head.
>
> Attitude: a kid who came second but is lost in a daydream that they won. Head down, hunched over the notebook, shut off from the room; then proud and a little cheeky when they show the drawing. The pencil moves in short quick bursts with still moments between; the showing off is slow and pleased.
>
> 0 to 1 s: hunched over, the notebook flat on the lap, head down, the pencil scribbling in one short burst, then still.
> 1 to 2.2 s: the pencil stops. The head comes up and turns to the left of the picture, as if looking at the winner sitting just beside it, the way someone drawing a person checks what they look like. It rests there a moment.
> 2.2 to 4.5 s: the head goes down again over the notebook. Two short scribbling bursts with a still moment between, then one big sweeping last stroke across the page.
> 4.5 to 5.5 s: the mannequin sits up tall, turns the notebook round with both hands and holds it at its chest, the page facing the camera, the pencil still held in the right hand against the edge of the notebook.
> On the page: a child's thick crayon drawing of one stick figure standing on a tall stack of books, both arms up, a big number "1" and a star over its head. Only that one figure.
> 5.5 to 7 s: it holds the notebook still at its chest and tips its head to one side, pleased with itself.
> 7 to 9.5 s: once, slowly, it tilts the notebook to the left and then to the right to show it off, then holds it straight.
> 9.5 to 12 s: it holds the notebook up at its chest, still, head tipped.
>
> Sound: none. Silence the whole time. No music.
