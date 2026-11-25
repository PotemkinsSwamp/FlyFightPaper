# Doodler

A runner-up emote (2nd and 3rd). Made by the [emote pipeline](../emote-pipeline.md); the idea is on the
[plan](../../plan/WINNERS-CIRCLE-PLAN.md); picked by Alan in [the second four runner-ups](../../decisions/2026-11-24-four-more-runner-up-emotes.md).

**The idea:** Scribbles in a notebook, then holds up a drawing of themselves in 1st. Stick figures: a child drew it (Alan).

## Where it stands
**Ready to record again** (2026-11-24, second build after Alan's first look in Play; see "Alan in Play"):
`DevRunnerUp` = "Doodler"; the draft `DoodlerClip` (the seat only) is in the open place's `Assets` (unsaved); the
older drafts `DoodlerLeftClip` and `DoodlerRightClip` are deleted from it. Its marks are in seconds after 1st's light,
not clip seconds (the clip is held still): with a 1st that leaves the runner-ups seen to the end, **the look at 1st
0 to 1.35** (3rd 0 to 1.85), **the turn 2.3 to 4.15** (3rd 2.8 to 4.65), the drawing held up to the end. Shorter
under 1st-place emotes that take the lens (table under "Build"). No sound. What could not be judged without Play is
under "Checks in Edit".

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

## Alan in Play (2026-11-24, first look)
- **His words** (notes on [the playtest page](../../playtests/2026-11-24-the-four-new-runner-up-emotes-first-look.md)):
  "I couldn't see it there because the first place one was one that hit the camera. For this one, I think the picture
  they turn around, it should show it like they're in first place, and there should be an arrow drawn to it that says
  me. So it's like they're saying, like, I should be first place. Versus right now the image is kind of just like, I
  don't even know what it is because it keeps happening too fast. There's not enough time where it turns it around to
  where you can see the image. They spend too much time drawing ... if the first place is one that shortens it, then
  the doodler needs to be shortened as well. Only if the first place one is the one that shortens it."
- **What changed:** the drawing (the kid in 1st place, an arrow from "me"); less drawing and more showing (the
  drawing up from 4.15 s after 1st's light instead of 6.15); a shorter version only when 1st's emote takes the lens
  early (`kit.seenFor()`, added to the scene by the primary session the same day). Kept: one pencil in the right hand,
  the notebook turned so the drawing is the right way up, silent, sitting.

## Build (step 4)
- **Roblox's own emotes, checked first:** none of them writes or draws while seated, so the body is ours.
- **The body clip is only the seat** (`CUTS.Doodler` in `tools/emote_cuts/doodler.lua`: Nap B sitting still, 1 s,
  held). The chest and the head are turned by the module every frame (as the arms are bent there), so the timing can
  follow 1st's emote with no pose jumping. (The first build had two 13 s clips, one per side of the look; a clip has
  one fixed timeline, so it could not shorten itself.) Baked into the open place's `Assets` as `DoodlerClip` and
  saved as `.planning/emotes/doodler.rbxm` (the two tracked files `assets/animations/emotes/doodler-left.rbxm` and
  `-right.rbxm` are the first build's and no longer used). To bake again: `_G.EMOTE_CLIPS = { "cut:Doodler" }` in
  Edit, then `python tools/emote_preview.py STUDIO_ID x --lua=emote_clips.lua "--bake=Doodler:DoodlerClip:.planning/emotes/doodler.rbxm"`.
- **The module** (`src/client/emotes/Doodler.luau`; `DevRunnerUp` = "Doodler" picks it). Every time below is seconds
  after 1st's light. Its plan is worked out once per kid at its first frame, from `kit.seenFor()` and its place:
  - **Before 1st's light:** hunched over the notebook on the lap (chest 22 degrees forward, head 32 more), two
    bursts: the books (-1.9 to -1.15), then the kid and the "1" (-0.95 to -0.1). 2nd is lit at -1, 3rd at -2.
  - **The look at 1st:** up over 0.5 s, held 0.5 (3rd 1.0, so the two are out of step after), back down over 0.35;
    the head 45 degrees round, the chest 8. Pencil still.
  - **One burst** (0.95 s): the arrow and "me".
  - **The turn** (1.85 s): lifted up facing the kid, top up (0.5; the camera sees the blue cover); the left hand to
    the middle of the spiral and the right hand, still holding the pencil, lets go to the chest (0.2); turned half
    round about its upright middle line (0.8: the drawing comes round to us right way up); in close to the chest
    (0.3). Then the head tips 18 degrees away from 1st and the notebook tilts 14 degrees one way and the other.
  - **Shortened** (Alan: "only if the first place one is the one that shortens it"): the drawing must be held up still
    at least 1.6 s before `seenFor()` runs out. If not, in this order: the burst after the look goes (its strokes are
    finished while the notebook faces the kid, so nothing is seen appearing), the turn goes 1.3 times quicker, and
    the look at 1st goes.
- **Under each 1st** (from the plan, checked in Edit; "up" is the drawing turned to us, within 20 degrees, every
  stroke on):

| 1st's emote | Seen until | 2nd: turn / drawing up from / held | 3rd: turn / up from / held | Lost |
|---|---|---|---|---|
| Toy Pilot, Magician, Skeet Shoot | 10.4 | 2.3 / 3.7 / 6.75 s | 2.8 / 4.2 / 6.25 s | nothing |
| Bubblegum | 9.0 | 2.3 / 3.7 / 5.35 s | 2.8 / 4.2 / 4.85 s | nothing |
| A+ | 7.8 | 2.3 / 3.7 / 4.15 s | 2.8 / 4.2 / 3.65 s | nothing |
| Book Kicker | about 5.9 | 2.3 / 3.7 / 2.25 s | 2.45 / 3.85 / 2.1 s | 3rd: the burst after the look is 0.6 s, not 0.95 (drawn quicker) |
| Camera Flick | about 5.7 | 2.25 / 3.65 / 2.1 s | 2.25 / 3.65 / 2.1 s | 3rd: the burst after the look is 0.35 s (drawn quicker); 2nd: nothing to speak of |
| Fold It Up | 3.05 | 0.03 / 1.1 / 2.0 s | 0.03 / 1.1 / 2.0 s | the look at 1st and the arrow being drawn (it is on the page when shown); the turn 1.3 times quicker |

  Under Fold It Up the kid scribbles from their own light to 1st's (2nd 1 s, 3rd 2 s), then sits up straight away and
  turns the notebook; the drawing is up from 1.1 s and held to 3.05.
- **The drawing** (Alan: "it should show it like they're in first place, and there should be an arrow drawn to it
  that says me"): in code (Path2D, as A+'s card back), crayon strokes 36 of the page's 900 pixels thick on cream
  paper: a red, a blue and a green book stacked, a black stick kid on top with both arms up, a big gold "1" over the
  head, and a red arrow from a red "me" to the kid. Against the paper: black 14.9 to 1, blue 5.9, red 4.8 (words need
  4.5), green 3.6, gold 3.2 (pictures need 3; design-theory rule 1.2). Nothing uploaded.
- **Sizes** (the kid's heights): the page 0.4 tall and 0.3 wide, bigger than the first build's 0.33 so "me" can be
  read; the pencil 0.1 long. Held for the turn its height under the chin plus 0.05, 0.02 clear of the chest.
- **The pencil:** one, in the right hand only. While drawing its point is on the page and it runs up through the
  hand; from the turn on it is fixed in the hand as it was then.

## Sound (step 5)
None: Alan took the silent default on the card. Skipped.

## Checks in Edit (step 4)
- **How they were run:** a copy of the module with the scene's own `sit`, `seatOn`, `rig`, `bendArm` and `paper`
  (copied from `WinnersCutscene.luau`) and `seenFor` set to each 1st's value, a test kid as 2nd and as 3rd beside a
  stand-in 1st, stepped every 1/20 s with `Animator:StepAnimations`, the chest, head and arm turns called after each
  pose, every part put where the pose says (the joints switched off for the check only: in Edit, placing one limb
  dragged the whole body). Everything made was removed in the same call. No pictures of Studio. **An Edit check is
  not Play.**
- **The plain test kid, under all six 1st-place timings, as 2nd and 3rd:** no error; the drawing turned to us with
  every stroke on for the seconds in the table; no part of the body inside the notebook; the pencil touches the hand
  all through; the left hand on its marks to within 0.015 of the kid's height; the right hand up to 0.047 short while
  drawing the page's far corners (the "1", the arrow's tail), its pencil still in it.
- **Faults the numbers found first:** the chest and head turns piled up frame on frame when the held clip did not
  write its pose again (the hands ended a third of the kid's height off): they are now turned from the clip's own
  pose every frame. The bigger notebook was 0.03 to 0.04 out of the hands' reach as it came up and turned: it is now
  held lower and closer, and gripped above the middle of its side edges once lifted.
- **On the 12 bots' outfits** (`bot_cast`, the full timing, every 0.1 s): no body part inside the notebook on any; the
  left hand within 0.035 of its marks; the right hand up to 0.082 short at the "1" (`3285769426`), its pencil still in
  it on all 12. Clothing through the notebook on seven: bags, a cape, a fanny pack and pigtails at the lap, hair, a
  scarf, a camera and a necklace at the chest: the accepted loss on odd outfits (Alan, 2026-11-21).
- **The drawing's size in the picture:** the page is 0.4 of the kid's height and the picture at the winners at least
  3.45 kid heights tall, so it is at most about an eighth of the picture's height: about 83 pixels tall at 720p and
  125 at 1080p. In it: "me" about 20 and 30 pixels tall, the stick kid 30 and 45, the "1" 17 and 25, the crayon lines
  3.3 and 5. Rendered at those sizes from the module's own strokes (`.planning/emotes/doodler-drawing-sizes.png`, my
  own render, not Studio): "me", the arrow, the kid on the books and the "1" read at both.
- **Not known until it is seen in Play:** whether the drawing reads under the spotlight at the real distance; how
  the quick turn reads under Fold It Up; whether the look at 1st reads with the head 45 degrees round; long hair and
  hats over the notebook.

## Files
| File | What |
|---|---|
| `src/client/emotes/Doodler.luau` | The emote's module: its timing under each 1st, the seat, the chest and head, the notebook, the pencil, the drawing, the arms |
| `tools/emote_cuts/doodler.lua` | The body cut: `CUTS.Doodler`, the seat only |
| `assets/animations/emotes/doodler-left.rbxm`, `doodler-right.rbxm` | The first build's two clips, no longer used (the new one: `.planning/emotes/doodler.rbxm`) |
