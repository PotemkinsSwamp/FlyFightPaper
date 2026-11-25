# Doodler

A runner-up emote (2nd and 3rd). Made by the [emote pipeline](../emote-pipeline.md); the idea is on the
[plan](../../plan/WINNERS-CIRCLE-PLAN.md); picked by Alan in [the second four runner-ups](../../decisions/2026-11-24-four-more-runner-up-emotes.md).

**The idea:** Scribbles in a notebook, then holds up a drawing of themselves in 1st. Stick figures: a child drew it (Alan).

## Where it stands
**Step 4: building** (Alan's OK on the video, 2026-11-24, with two changes: see below).

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

- **The video** (`.planning/emotes/doodler-gemini-api-1.mp4`, 12 s, 640x360; $0.28: 580 text tokens in, 23,172 video
  tokens out). What my stills show (two a second; not judged in motion): a grey mannequin sits cross-legged on four
  dark books, the notebook flat on its lap in the left hand, the pencil in the right; head down, scribbling, 0 to
  1.5 s; about 1.5 to 2.2 s the head comes up and turns to the picture's left, then goes back down; scribbling again
  2.5 to 4.5 s; at about 4.5 to 5 s it turns the notebook up to the chest, page to the camera, fast (in one still
  step); the page: a stick figure on a stepped stack of books, arms up, a "1" and a star over it, as asked, alone;
  from about 6 s the head tips well over to one side and stays tipped to the end; about 7 to 8 s the notebook tilts
  to the picture's left (the stills show only that one side of the tilt) and comes back straight; still to 12 s. The
  pencil stays in the right hand against the notebook's edge all through. Sound: not used (Alan's silent default).

- **Alan on the video (2026-11-24):** "This is good. The only thing is ... whenever they turn the notebook around,
  they turn it on the wrong side. So the actual flipping of the notebook would have to be slightly different. Also,
  they should only be holding one pencil. But other than that, I think it's good ... go ahead and build it." So: one
  pencil, in the right hand only (the video's left hand held one too, in the stills); and the turn is built as a
  person shows a page: lifted up facing the kid first (top edge up), then turned round to us about its upright
  middle line, so the drawing faces us right way up and the cover faces the kid. My own three changes from the video
  (said to Alan before his OK): the turn takes about a second, not a snatch; the tilt goes once each way; the head
  tip is kept.

## Build (step 4)
- **Roblox's own emotes, checked first:** none of them writes or draws while seated (none I know of in Roblox's
  catalogue, and the Creator Store search does not list emotes), so the body is a cut, as So Close's.
- **The body: two clips, one per side of the look** (`CUTS.DoodlerLeft` and `CUTS.DoodlerRight` in
  `tools/emote_cuts/doodler.lua`; every number is in its comment). 13 s, played once, held on the last pose. They move
  only the chest and the head; the seat and the arms underneath are Nap B sitting still (Nap's and So Close's seat).
  Marks (clip seconds): **Look 2.0** (1st's light: the head comes up and turns 45 degrees to 1st by 2.5, held to 3.2,
  back down by 3.65) and **Up 6.0** (sits up tall by 6.6). The head tips 18 degrees, away from 1st, 8.0 to 8.7 and
  stays tipped. Hunched while drawing: the chest 22 degrees forward, the head 32 more.
- **Baked** into the open place's `Assets` as `DoodlerLeftClip` and `DoodlerRightClip` (unsaved drafts: what
  `ourClip` plays in Studio) and saved as `.planning/emotes/doodler-left.rbxm` and `doodler-right.rbxm` (untracked:
  this session writes nothing in `assets/animations`). To bake again after a close without a save:
  `_G.EMOTE_CLIPS = { "cut:DoodlerLeft" }` in Edit, then
  `python tools/emote_preview.py STUDIO_ID x --lua=emote_clips.lua "--bake=DoodlerLeft:DoodlerLeftClip:.planning/emotes/doodler-left.rbxm"` (and Right).
- **The module** (`src/client/emotes/Doodler.luau`; `DevRunnerUp` = "Doodler" picks it). Times as So Close: clip
  second = 2 + seconds after 1st's light, so the look lands on 1st's light for 2nd and 3rd alike; 3rd holds the look
  0.5 s longer and then runs at 0.92, so the two are out of step after. Rested on the top book every frame (`sit`,
  `seatOn`). Clip seconds of the rest, all in the module:
  - **Drawing, stroke by stroke:** five bursts, each drawing one part of the picture as the pencil's point runs
    along its strokes: 0.15 to 0.65 the books, 1.05 to 1.55 the kid's head, body and legs (before 1st's light);
    3.75 to 4.25 the arms, 4.65 to 5.15 the "1", and 5.4 to 5.95 the star in one sweep (the big last stroke). Still
    between bursts, the point lifted off the paper. So every move of the hand adds something to the page.
  - **The notebook on the lap**, its near edge just before the belly, resting on the top of the crossed legs, its far
    edge tipped 25 degrees up, the drawing's top away from the kid (they read it). Left hand on its left edge.
  - **The show (Alan's turn):** 6.0 to 6.6 lifted before the chest, facing the kid, top up (the camera sees the blue
    cover: the drawing still hidden); 6.6 to 6.85 the left hand goes to the middle of the spiral and the right hand,
    still holding the pencil, lets go to the chest; **6.9 to 7.8 turned half round about its upright middle line**
    (the drawing comes round to us right way up); 7.8 to 8.15 both hands back on its side edges and it comes in close
    to the chest, its top edge under the chin. Tilts: 14 degrees one way by 9.9, the other by 11.0, straight by 11.9.
  - **The pencil:** one, in the right hand only. While drawing, its point is on the page and it runs up through the
    hand; from 6.0 it is fixed in the hand as it was then.
  - **The drawing:** in code (Path2D, as A+'s card back), crayon strokes 36 of the page's 900 pixels thick on cream
    paper: a red, a blue and a green book stacked, a black stick kid on top with both arms up, a red "1" and a gold
    star over it. Nothing uploaded.
  - **Sizes** (the kid's heights): page 0.26 wide, 0.33 tall (A+'s card size, held the same way on every body); the
    pencil 0.1 long.

## Files
| File | What |
|---|---|
| `src/client/emotes/Doodler.luau` | The emote's module: picks the clip, times it to 1st's light, the seat, the notebook, the pencil, the drawing, the arms |
| `tools/emote_cuts/doodler.lua` | The body cut: `CUTS.DoodlerLeft`, `CUTS.DoodlerRight` |
