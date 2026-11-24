# Fold It Up

A 1st-place emote that takes the whole picture. Made by the [emote pipeline](../emote-pipeline.md), in its own side session; the idea is on the
[plan](../../plan/WINNERS-CIRCLE-PLAN.md).

**The idea (first):** Grabs the picture itself, folds the whole screen into a paper plane and throws it away.
**The idea now (Alan, 2026-11-22):** Peels the picture off the screen, shows you it is only a crayon drawing of the
winners (stick figures, a crown on 1st), crumples it up and throws it over the shoulder. The name may change.

## Where it stands
Step 6: the sixth run's faults (the kid's arm did not read as reaching; the Menu tag over the hand) are fixed in the cut and module; ready to record again, waiting on Alan's notes on the sixth run.

## Alan on the first card (2026-11-22)
- **No faces:** "how are they going to look at them with a sly grin?" The feeling must be in the body: "tilt their
  head, look directly at the camera, tilt their head like they're observing, then take their hands together and rub
  them together close to their body." My mistake: the card asked the face for a grin.
- **The screenshot:** he doubts it works every time in the live game and is reliably thrown away after; "I don't
  know if this is the direction we want to go."
- **Folding the view itself:** "there's just no way to make that happen", and nothing sensible is left behind it
  (only black). His only working version: the kid grabs the screen, rips it off, the camera switches to one behind,
  and the kid folds what looks like a picture of the screen; which brings the screenshot back.
- **His verdict: "this one has to be rethought."**

## How the picture can be folded (read 2026-11-22; nothing built or tried)
Read from Roblox's API reference (the docs' own source files, pages dated 2026-11-20) and the Roblox staff answers in
the [Captures APIs announcement](https://devforum.roblox.com/t/captures-apis-are-now-available/2838188) thread.

**A. A real screenshot on paper pieces at the lens** (`CaptureService:TakeScreenshotCaptureAsync`, the current call;
the older `CaptureScreenshot` is being retired, staff 2026-01-26).
- **Shows where:** an ImageLabel or a Decal (staff: "should work anywhere image ContentIds currently work"), so on
  flat parts in front of the camera, each piece showing its own crop of the one picture.
- **Cannot bend or be redrawn:** a screenshot cannot become an `EditableImage` (staff 2026-01-27: "EditableImages does
  not support ScreenshotCaptures"; trying it crashes Studio or kicks the player). So the picture can only ride on flat
  pieces; a triangle needs a hard-edged see-through mask over the crop (my idea, untried).
- **Prompt:** none. Taking the picture is silent; only saving or sharing it asks the player (a 2024 forum post
  complains of exactly that).
- **Our game's screen bits:** the new call leaves them out by default (`UICaptureMode.None`), so the name plates and
  the Menu tag are not in the picture. Players reported in 2024 and 2025 that 3D-hung screen bits (SurfaceGui,
  BillboardGui) also vanish from captures. **Our dark curtain is drawn on a SurfaceGui**, so the picture may come out
  with the room lit, not dark. Not known until tried.
- **Hitch and delay:** the reference says nothing. Staff (2024): "there will likely still be some delay before the
  image is available depending on the device", and at most about one a second. A memory leak was reported in 2024;
  the new call frees itself.
- **Phones:** the feature started on phones, so they are covered. A forum user wrote in 2024 that captures were
  "blocked off to 13+ users"; not confirmed for this call, and most of our players are under 13. Not known until
  tried on a young account.
- **Verdict: not safe on its own.** Safe only with a fallback (B or C below) that takes over when the picture is late
  or does not come, and only after a check in a real game on Alan's PC and phone (Studio may differ).

**B. A copy of the winners drawn inside screen frames** (`ViewportFrame` + `WorldModel` for the animated bodies).
- No shadows, no blur or other screen effects, only one flat light and an overall tint: the spotlit kids in the dark
  would change look the instant they are grabbed.
- Each folding piece needs its own frame with its own moving copies of all three avatars: about eight frames times
  three avatars, every frame, on a phone. Roblox: create these only while shown, delete them after.
- **Verdict: not safe** (the look jumps, and it is heavy on phones).

**C. No real picture: paper pieces that close over the view and become the plane.**
- Plain parts in front of the camera, as Bubblegum's gum and Book Kicker's book. Works everywhere, no prompt, no
  hitch.
- The joke is weaker: what is folded is paper, not the picture you were looking at.
- **Verdict: safe.**

**Dropped (Alan, 2026-11-22):** no screenshot; no real picture is folded. The picture is a crayon drawing, the same
for everyone.

## Alan's direction for the second card (2026-11-22)
- Option 1 of my three (peel it off, keep the camera still): "I think I like number one."
- The drawing: "not poorly drawn, but like a crayon drawing of what it would look like, except the characters on it
  are just kind of like stick figures. And the number one spot maybe has like a crown on their head."
- Not folded but crumpled: "I kind of like to crumble it up and throw it over his shoulder because it's very smug ...
  After he shows it."
- His question: the camera is far from the winners and arms cannot be stretched, so how can the kid grab the screen?

## How the kid reaches the screen
**Forced perspective, as in the holiday photo of someone "holding up" the Leaning Tower.** The kid reaches towards
the camera and pinches the air; on the screen the fingertips sit on one spot of the picture, and the paper lifts from
exactly that spot, as if he pinched the glass. Then the sheet travels along the line from the lens to his hand: on
the screen it stays over his hand the whole way and only gets smaller, so it reads as pulled into his hand. The
arms keep their real length and the camera does not move. The other way, for Alan to pick: he crooks a finger
("come here") and the sheet peels itself off and floats to his hand.

**What the peeling sheet shows:** its back. The drawing faces the kids, as if it had been stuck on the outside of
the glass all along; we see white paper with the crayon showing through faintly, mirrored. He turns it round to
show us the front.

## Shot card (second; Alan's OK with the video, 2026-11-22)
**The feeling: smug. "That's all you are to me": a picture to scrunch up.** Slow, sure head moves; quick, neat
hands; the toss without looking.

Seconds after 1st's light. The scene leaves at its usual 10.4 s, so the report card keeps its 10 seconds. 2nd and
3rd go on with their own emotes all through.

| Time | The kid | The sheet | What the camera sees | Sound |
|---|---|---|---|---|
| 0 to 1.0 | Head tilts to one side, looking straight at the camera | None | All three, as always | Music only |
| 1.0 to 2.0 | Head tilts slowly the other way, as if sizing you up | None | Same | None |
| 2.0 to 3.0 | Brings the hands together and rubs them, close to the body | None | Same | None (a dry rub, if any) |
| 3.0 to 3.6 | Reaches one arm at the camera, hand at face height, then pinches | None | Same | None |
| 3.6 | The fingers close | **The pinch:** the whole picture turns to paper round his fingertips and lifts there in a small tent | The scene seen through a white sheet for an instant | Paper crinkle |
| 3.6 to 4.4 | Yanks the hand back to the chest | Comes off the glass and shrinks into his hand along the line of sight; white back, crayon showing through mirrored | The room comes back round the shrinking sheet | Peel, short and crisp |
| 4.4 to 5.0 | Takes it in both hands and turns it round | Now in his hands | The kid with a sheet | Paper flap |
| 5.0 to 6.8 | Holds it out at chest height, facing you; a small head tilt at it | **The drawing:** three stick figures on three book stacks, 1, 2, 3, a crown on 1st; size in the hands: see below | The drawing held up | None |
| 6.8 to 8.0 | Crumples it with both hands, a little twist at the end | Becomes a paper ball | The ball in his hands | Scrunch |
| 8.0 to 8.8 | Tosses it backhand over the shoulder without looking | Arcs behind him into the dark | The kid; the ball gone | Soft toss, quiet |
| 8.8 to 10.4 | Dusts off the hands, arms folded, chin up | Gone | The kid | None |
| 10.4 | The scene leaves as usual | | The curtain lifts, the camera glides home, the report card comes up with its 10 s | Music |

**Alan on the second card (2026-11-22):** the drawing at **poster size**, about half the kid's height. The reach is
not settled: "I just don't know what the forced perspective pinch would look like." He thought of the kid beckoning
the camera forward, and dropped it himself: the zoom would have to work on every body and "it also ruins the
picture". He asked to see it: a picture from me or a Gemini video.

**The pinch, frame by frame (as told to Alan in words):**
1. 3.0 s: all three as always; 1st raises one hand towards you. On the screen the hand is a small spot near the
   middle.
2. 3.6 s: his fingers close. A milky see-through sheet is suddenly over the whole view (the scene still seen through
   it, a little white), pinched into a small point at his fingertips, with creases running from there to the
   corners, as cling film does when you pinch it.
3. 3.6 to 4.4 s: the sheet comes away from you towards his hand, getting smaller and whiter, always centred on his
   hand: half the screen, then a quarter, until it is a poster in his fist. Round it the room is back.
4. 4.4 s: he holds the poster, its white back to you, the crayon showing through; he turns it round.

**The body:** none of the 12 Roblox emotes the game already uses rubs hands, pinches, crumples or throws (same
finding as [A+](a-plus.md)). A body cut from the Gemini video, as Book Kicker and Bubblegum.

**Reused:** the sheet's flight along the line of sight is Book Kicker's and Bubblegum's lens sums run backwards; the
scene's curtain, lights and name plates as they are. Nothing hides the name plates or the Menu tag except for the
instant of the pinch.

**New (needs Alan's OK on this card):** one crayon drawing (made as a picture, checked by Alan, then uploaded with
his go); the sheet at the lens and in the hand; a paper ball; the timings above (my numbers).

**Sounds (few and quiet; the music plays under them):** a crinkle at the pinch, a short peel, a flap as he turns it,
a scrunch, a soft toss.

## Reference video (step 3)
- **First call (2026-11-22, Alan's go; 15 s, 360p, about $0.35 asked):** prompt `.planning/emotes/fold-it-up-prompt-1.txt`
  (the second card at 1.3 times its pace, the act running 0.5 to 14 s, the sounds at their moments, no music).
  **Refused by Google's safety filter** after making it: "The video was filtered out because it violated Google's
  Generative AI Prohibited Use policy". No video came back; whether it was charged is not shown (the tool stops
  before the price on an error). The filter does not say what it objected to.
- **Alan on the wording:** "you can just say a person"; "I think it should be fine to say a drawing done by a child".
- **Second call (Alan's go; 15 s, 360p, $0.35: 786 text tokens in, 28,965 video tokens out):**
  `.planning/emotes/fold-it-up-gemini-api-2.mp4`, prompt `fold-it-up-prompt-2.txt` (no "kid"; the drawing "done by
  a child"; the sheet "tracing paper just in front of the camera"). Gemini so far: $0.35, plus the refused call if it
  was charged.
- **What my stills show** (two a second, eight a second over the pinch and the toss; not judged in motion):
  - Three grey mannequins in a dim room, each under a spotlight, the camera still; the middle one a little smaller;
    the stacks all about knee-high (the real 1st stack reaches the shoulders: asked again, again not given).
  - Head tilts at 0.5 to 1 s and 2 to 2.5 s; hands rubbed in front of the belly 3.5 to 4.5 s; the arm out at the
    camera, palm forward, 4.5 to 5.0 s.
  - **The pinch reads:** at 5.1 s paper rushes in from the picture's edges (a square hole round the figure for one
    frame); 5.25 to 5.5 s the whole picture is a white sheet, the scene faint through it, creased in an X to one point
    in the middle (on the figure's chest, a little under the hand); 5.6 to 6.0 s the sheet shrinks onto the figure,
    still pinched to that point, and crumples into a white star at the chest at 6.1 s.
  - **Not as asked:** the back of the poster and the turn are skipped: at 6.5 s it is already held out with the
    drawing to the front. The poster is about a third of the figure's height and wider than its shoulders.
  - **The drawing:** sun, clouds, grass; two stick kids on book stacks, the middle one with a yellow crown and a
    smile on a white block marked "2" (should be books and "1"). Held 6.5 to 9.5 s.
  - Crumpled 9.5 to 10.8 s; tossed at about 10.9 s **overhand, up past its head** (not backhand over the shoulder),
    the ball flying up and back to the picture's right; hands dusted 12 to 13.5 s; arms folded, chin up, to the end.
  - **Sound** (by loudness, not heard by me): the sheet 5.5 to 6.4 s; a short sound at 6.8 s; the scrunch 9.5 to
    10.4 s; a sharp hit at 11.2 s (the toss); short ticks at 12.1 and 12.6 s; a louder burst at 13.8 to 14.1 s (the
    dusting or the arms folding). Otherwise a quiet room tone. Waits for Alan's look.

- **Alan on the second video: "I think this is good enough to work off of."** The sounds are fine except the
  figure's own voice (a "hmmm"): no sound from the person. The drawing is not Gemini's: it is made by Codex
  (ChatGPT's picture tool), brief `.planning/emotes/fold-it-up-drawing-brief.txt`, three close versions to
  `fold-it-up-drawing-a/b/c.png`. The reach: "the only way to get forced perspective is to literally make the hand
  and arm grow like it's reaching towards the camera, and then pull it and then shrink backwards ... How can we do
  that in a way that it works for every single model in a live game?"

- **Alan on the growing arm (2026-11-22): "yes go ahead with the growing arm ... it's coming straight at the camera,
  so you should really only see the hand ... it should all happen kind of like fast, so you don't think about it too
  much."** The toss: backhand over the shoulder (his words of the second card; the video's was overhand), my default,
  not asked again.

## The drawing
Codex (the picture tool on Alan's ChatGPT plan), brief `.planning/emotes/fold-it-up-drawing-brief.txt`: three close
versions, 1200 by 900, `.planning/emotes/fold-it-up-drawing-a.png`, `-b`, `-c` (side by side:
`fold-it-up-drawings-abc.png`). One layout: three stick figures on book stacks 2, 1, 3, a yellow crown on 1st, arms up
in a V; the others' arms straight out; only the sun's corner and the book colours differ. **A blind reviewer (one Opus
agent, given the pictures, the brief and Alan's words):** reads at 120 px (crown and numbers clear); crayon, careful,
"a little too perfect up close"; no moderation risk (the outer figures' arms cross their bodies in a plain "+", the
normal stick figure); B's brick red and yellow-green lean muddy; best A ("A's colours with B's sun corner" the best
mix); the books end 15 px from the bottom edge. **Waits for Alan's pick**; not uploaded.

## The build (step 4; 2026-11-22; numbers in Edit only, never run in Play, nobody has seen it)
- **The body** (`tools/emote_cuts/fold-it-up.lua`, `CUTS.FoldItUp`; A+'s way: Toy Pilot's standing pose, the arms
  from a table of poses, the head keyed, both feet held): 11 s, played once. Seconds after 1st's light: head tilted
  to the kid's right 0.2 to 1.0, slowly to the left by 2.0 (14 degrees); hands together in front of the belly 2.0,
  rubbing four strokes, head down 15; the right arm straight at the camera 3.0 to 3.3, the chest leaning in 8;
  yanked back to the chest by 3.8; both hands to the poster's sides by 4.1; held out at the chest to 6.6, one head
  tilt at 5.6; the hands working round each other (three turns) 6.9 to 7.6; the right hand low 7.8, up past the
  shoulder at 8.15 and back over it 8.35, down round the outside 8.55; palms at the belly 8.7, two brushes; arms
  folded by 10.0, chin up, the weight on the right leg. Marks: Pinch 3.3, Back 3.8, Show 4.5, Crumple 6.6, Ball 7.6,
  Release 8.15.
- **The clip:** baked into the open place's `Assets` as `FoldItUpClip` (an unsaved draft: what `ourClip` plays in
  Studio), saved as `assets/animations/emotes/fold-it-up.rbxm`. To bake again after a close without a save:
  `_G.EMOTE_CLIPS = { "cut:FoldItUp" }` in Edit, then `python tools/emote_preview.py STUDIO_ID x --lua=emote_clips.lua
  "--bake=FoldItUp:FoldItUpClip:assets/animations/emotes/fold-it-up.rbxm"`.
- **The module** (`src/client/emotes/FoldItUp.luau`; the Dev button "end: fold" sets `DevFirstEmote` = "FoldItUp"):
  - **The hand at the lens:** from 3.05 the real right hand is hidden and a copy of it slides along the line from the
    lens to the real hand, faster and faster, nearest at Pinch, back on the hand at Back. On the screen it stays on
    the wrist and grows to 12 times its size (`GROW`); never nearer the lens than 0.3 studs. No arm part changes,
    so sleeves and 3D clothes are never touched.
  - **The sheet:** from Pinch, four triangles (two wedges each) from the corners of a sheet 1.15 times the picture,
    half way between the lens and the hand, to the hand behind it: a tent, every other side a little greyer so the
    creases read; 0.35 see-through, with a white Highlight so it stays paper-white in the dark. As the hand goes back
    its corners close in on the poster's corners and the tent flattens; solid by Back.
  - **The poster:** a part half a winner's height tall, 4 to 3; the drawing on its front (`DRAWING`, empty until the
    upload: plain paper till then), on its back the same drawing mirrored and faint (through the paper). Its front
    faces the kid until it turns round over 0.35 s ending at Show; from the right hand alone at Back to both hands'
    middle by 4.1. Crumpling (Crumple to Ball) it shrinks to a twentieth while it wobbles.
  - **The ball:** three paper lumps (0.11 winner heights) grow in the hands as the poster goes, ride the right hand,
    and at Release fly up and back over the right shoulder (start speed 0.4 right, 2.2 up, 1.6 back, winner heights
    a second; falling 4 a second a second), gone 1.1 s later in the dark behind.
  - `covered` (name plates and the Menu tag put away): Pinch to 0.3 s after. The scene's own leave time is kept
    (10.4 s after 1st's light): the report card keeps its 10 s.
- **Measured on the test kid** (`emote_preview.py --run`, no pictures): the feet move at most 0.008 heights; a hand
  or forearm at most 0.032 heights into the trunk's or head's boxes; at the pinch the arm points 10 degrees off
  straight ahead and the hand is 0.37 heights in front of the chest; holding, the hands are 0.52 apart (the poster
  0.67 wide) and its top 0.15 heights under the middle of the head.
- **The module run in Edit with stand-ins** (its text, the test kid posed by the clip, a made-up camera 3.7 kid
  heights off, as the scene's; no Play, Edit's camera untouched): no error; the copy hand 4% of the screen's height
  at 3.2 s, **24% at the pinch**, 7% at 3.45, always exactly on the wrist on screen; at the pinch the sheet spans 1.7
  to 1.8 times the picture's width and 1.2 its height; at 3.45 it has closed in to 0.6 of the width; the poster
  turned to the kid until 4.3 and to the camera from 4.6; the ball 0.5 heights up and 0.5 behind the kid 0.45 s
  after Release, 1.5 behind 1.05 s after; `covered` at 3.35, not at 3.7.
- **On 14 of the bots' outfits in Edit** (the draft played with `Animator:StepAnimations`, every quarter second):
  it plays on every one (the first body of each batch read as not moving: Studio still loading the clip, gone when
  run again). The feet move at most 0.014 of the body's height; the right hand is 0.24 to 0.33 heights in front of the
  chest at the pinch; a hand or forearm goes at most 0.043 into the body's boxes (arms folded at 10.0 s, A+'s fold,
  and the toss on `4560704730`), after moving the rubbing and the dusting forward (they were 0.049 and 0.057 on big
  bellies). Holding, the poster's top is from 0.10 under to 0.10 over the chin: on most bodies the chin is behind
  it. **An Edit check is not Play.**
- **Not known until it is seen in Play:** whether the growing hand reads as forced perspective or as a hand that
  pops; how the sheet looks in the dark room (the Highlight's white); the poster's crayon at the scene's distance;
  whether the smug head moves read on real avatars; gloves or wrist accessories stay at the wrist while the copy hand
  travels.

## Sound (step 5)
Cut from the video Alan OK'd (`fold-it-up-gemini-api-2.mp4`; its sounds were in what he OK'd), measured every 10 ms;
each file starts 0.025 s before its first sound, raised 5 dB, fades of 0.01 s in and 0.04 s out; not heard by me,
not uploaded. **Left out:** the figure's own "hmmm" at 13.8 to 14.5 s of the video (Alan), and two faint hums at 8.2
and 8.9 s. Times in seconds after 1st's light (`FoldItUp.sounds`; Audio names for step 6):

| File | From the video | Length | Plays at | Audio name |
|---|---|---|---|---|
| `assets/audio/emotes/fold-it-up-peel.ogg` | 5.495 s (the sheet: crinkle and peel, 5.52 to 6.67) | 1.26 s | 3.275 (Pinch) | `foldPeel` |
| `assets/audio/emotes/fold-it-up-flap.ogg` | 6.755 s (the poster turned, 6.78) | 0.23 s | 4.125 (the turn starts) | `foldFlap` |
| `assets/audio/emotes/fold-it-up-scrunch.ogg` | 9.485 s (crumpling, 9.51 to 10.58) | 1.17 s | 6.575 (Crumple) | `foldScrunch` |
| `assets/audio/emotes/fold-it-up-toss.ogg` | 11.215 s (the toss, 11.24; the loudest, peak -0.8 dB after the raise) | 0.24 s | 8.125 (Release) | `foldToss` |
| `assets/audio/emotes/fold-it-up-dust.ogg` | 12.095 s (one tap of the hands, 12.12) | 0.23 s | 8.925 and 9.225 (the two brushes) | `foldDust` |

The peel runs 0.76 s past Back, over the take and the turn. The first sound is at 3.275 (`firstSound`): the
runner-ups' sounds stop before it.

## Files
- `tools/emote_cuts/fold-it-up.lua`: the body cut.
- `src/client/emotes/FoldItUp.luau`: the hand, the sheet, the poster, the ball, the sound times.
- `assets/animations/emotes/fold-it-up.rbxm`: the baked clip (the draft `FoldItUpClip`).
- `assets/audio/emotes/fold-it-up-peel.ogg`, `-flap.ogg`, `-scrunch.ogg`, `-toss.ogg`, `-dust.ogg`: the sounds.
- Working files, untracked: `.planning/emotes/fold-it-up-*` (prompts, the two videos, the drawing brief and pictures).

## First run in Play (step 6, the primary session's muted recording, 2026-11-22)
- **Files:** `.planning/emotes/fold-it-up-first-run-raw.mp4` (2032 by 800, 30 s; 1st's light at 11.45 s) and
  `fold-it-up-first-run-sound.mp4` (the sounds laid at their times, 3 dB down because one file peaks near full
  scale, and the music's sighs; starts 3.45 s before the light). So Close on 2nd and 3rd. No script error.
- **Seen in its stills** (ten a second round the pinch, 2.5 a second after; not judged in motion): at about 3.3 s a
  milky creased sheet with the big hand in its middle fills nearly the whole picture, the winners seen through it;
  within about half a second it shrinks to the poster in front of the kid; the poster (plain paper, no drawing yet)
  is held in front of the chest and face, turned and shown; crumpled to a ball by about 7.6 s; the ball up over the
  head at about 8.5 s; the hands dusted; arms folded to the end; then the report card, name plates back.
- **Not readable in stills:** whether the pinch reads as grabbing the picture; whether an edge of the sheet shows at
  the pinch (in one still its bottom edge sits just inside the picture's bottom). Nothing changed until Alan has seen
  it.

## Alan on the first run (2026-11-22)
- **The drawings:** "the codex drawings are all absolutely the same. You should have given him a reference photo of
  what ... the winner circle looks like, so then they can draw what it looks like if a child was to recreate it." My
  miss: the brief described the scene in words. Second brief `.planning/emotes/fold-it-up-drawing-brief-2.txt` with a
  frame of the first run as the reference (`fold-it-up-scene-ref.png`, 13.6 s of the raw recording: all three lit,
  the stacks, spotlights, name tags, blackboard): three versions `fold-it-up-drawing-2a/2b/2c.png` (more or less of
  the classroom).
- **The folded arms:** "they're just crossing their elbows and their arms are remaining straight. They're not
  actually folding their arms under each other" (the same note as on Skeet Shoot). Fixed in the cut by Skeet Shoot's
  way: each elbow placed (the upper arm down and forward) and the forearm folded across from it, the hands raised
  towards the other arm, the right arm over and in front, the left under. On 8 of the bots' outfits in Edit the
  elbows are now bent 75 to 94 degrees (measured at the joints), the forearms within 20 degrees of level, the right
  forearm 0.01 to 0.03 heights nearer the camera; a forearm goes at most 0.061 heights into a big belly's box while
  the arms move into the fold (9.75 s). Baked again (`FoldItUpClip`, `fold-it-up.rbxm`).
- **"We need the codex image to actually lay it on the thing to see what it looks like. And we need the sounds on
  them."** The drawing reaches the poster only through an upload (his go), then a recording by the primary session
  with the sounds laid under it.
- **The second drawings** (Codex with the scene frame; `fold-it-up-drawing-2a/2b/2c.png`, side by side
  `fold-it-up-drawings-2abc.png`; each laid on the blank poster of the first run's frame at 17.2 s, tinted to the
  poster's measured paper tone, `fold-it-up-drawings-2-on-poster.png`): crayon on a dark scribbled room, yellow
  spotlight cones, desks, the 2nd/1st/3rd tags; 2a with the blackboard, 2b also the wall posters, 2c only the
  winners. **A blind reviewer (one Opus agent):** no moderation risk in any; on the poster in the game's light the
  crown is yellow on a yellow cone and does not stand out (all three); 2b too busy to read at that size; in 2a the
  sitting 2nd and 3rd read as cut off; 2c reads best (big crown, tall stack, the tags) but its books look like
  cushions; the tags' letters look typed; 2c shows white paper corners. Waits for Alan's pick.
- **Alan's pick: 2a, as it is** ("2A looks the most like the classroom"; whether it reads at poster size "doesn't
  really matter"). The file: `.planning/emotes/fold-it-up-drawing-2a.png` (1200 by 900). Next, step 6 (the primary
  session, Alan's go): upload it as an image, put its id in `DRAWING` in `src/client/emotes/FoldItUp.luau`, record
  again with the sounds under it.

## Second run in Play (step 6, the primary session, 2026-11-23)
- **Uploads:** Alan's go "do all the uploads" (2026-11-22). Drawing 2a resized to 1024 by 768 first (Roblox shrinks
  anything over 1024; the mirrored back uses the picture's own pixel size): `assets/ui/emotes/fold-it-up-drawing.png`,
  `rbxassetid://114077761748868`, approved by Roblox. `DRAWING` and `DRAWING_SIZE` (1024 by 768) set in
  `src/client/emotes/FoldItUp.luau` by the primary session (commit 096303771).
- **The muted recording:** Fold It Up on 1st, So Close on 2nd and 3rd, free-for-all, 56 frames a second, no game
  error. Raw `.planning/emotes/fold-it-up-soclose-second-run-raw.mp4`; with sound
  `fold-it-up-soclose-second-run-sound.mp4` (1st's light at 7.07 s; the five files laid at `FoldItUp.sounds`' times,
  So Close's sighs at 1.5 and 2.0 s; the whole track 2.3 dB down, overlapping sounds summed past full scale).
- **Seen in its stills** (the primary session's; not judged in motion): the poster's back plain cream (the faint
  mirrored drawing does not show), the front shows the drawing clearly; it shrinks as it is crumpled; the ball is
  tossed up to the picture's left (the kid's right); the arms end folded. Waits for Alan's look.

## Alan on the second run (2026-11-23): take the screen for real
"Wouldn't it be cooler if it looked like it was actually taking the screen? So the screen goes like dark as she's
pulling the frame. So the frame is like essentially like zooming out ... and then switch to a camera at like somewhere
else. So the perspective will have to change ... Then she'll turn to that camera, crumple it up, and throw it away. So
it gives more of the impression that she's taking the frame."
- **A new mechanic (a second camera, the picture shrinking into black): plan to Alan in words first, nothing built.**
- **How it can be done without a screenshot (my plan):** the lens widens (50 to 120 degrees, Roblox's most) while
  black bars at the lens cover everything outside the old picture: the live picture, still moving, shrinks to about a
  quarter of the screen with black round it (a wider lens shows the old picture exactly, only smaller). Then black,
  then the scene's camera is somewhere else (the module's `camera` hook; the winners' stand-ins follow any camera).
  The kid is turned on the stack by the module. **Needs from the primary session:** a hook to set the lens angle (the
  scene writes `FieldOfView` itself each frame), and a look at what stands in the way from the new angle.

## Third build: the screen is taken (2026-11-24; Alan's "yes" to the plan in words; numbers in Edit only, never run in Play)
My defaults, which his "yes" did not change: the second camera 35 degrees round 1st at the same distance (all three
stay in view); the picture shrinks to a quarter, then a cut to black.
- **The module** (`src/client/emotes/FoldItUp.luau`, rewritten; the body clip is unchanged):
  - **The hand at the lens:** as before (3.05 to 3.8, 12 times at the pinch).
  - **The picture shrinks (3.3 to 3.9):** `FoldItUp.fov` widens the lens from 50 to 120 degrees, fast at first, so the
    live picture is 0.78 of the screen at 3.4 s, 0.45 at 3.6, 0.27 at 3.9. Four black bars 0.25 studs from the lens
    cover everything outside the old picture, with a paper-white rim (0.02 of its height) between; the camera rolls
    up to 9 degrees (`camera`), the bars stay with the picture. Unlit (filled SurfaceGuis, the curtain's way). The
    milky tent of the second build is gone.
  - **Black (3.9 to 4.1):** one black sheet over the lens; under it the lens goes back to 50 and the camera swings
    35 degrees round 1st's real spot to the kid's left (the toss goes off to the far side). The black lifts in 0.15 s.
  - **The turn (4.1 to 4.6):** the module turns the kid on the stack 35 degrees to face that camera (`PivotTo`, as
    Book Kicker moves its kid). The poster is in both hands from the black on, its drawing the way the kid faces: no
    flip any more, the back is never shown.
  - Show, crumple, toss, dust, fold: as before, in the turned kid's frame. `covered` from the pinch until the black
    has lifted (4.25). The flap sound moved to the black lifting (4.075). The scene's leave time is kept.
- **The scene's lens hook** is in (the primary session, commit b4050d81a: `made.fov(st, t)` in place of `SHOT_FOV` during the
  hold). Without it the bars close in but the picture does not shrink.
- **Run in Edit with stand-ins** (the module's text, the test kid, made-up cameras): no error; the black starts 0.04
  outside the old picture's edge at every moment and reaches far past the widest view; the second camera is 35
  degrees round at 3.70 heights (the front's distance), to the kid's left; the kid faces it by 4.6; the drawing is 7
  degrees off square to the lens and 16% of the screen tall while shown; the ball leaves over the far shoulder.
- **Not known until Play:** whether anything in the room stands between the side camera and the winners (the scene
  clears the shot for the front view only); how the spotlights and the dark curtain look from the side; whether the
  shrinking picture reads as "she took the screen"; the stand-in winners during the wide lens.

## Third run in Play (the primary session's muted recording, 2026-11-24) and its two fixes
- **Files:** `.planning/emotes/fold-it-up-third-run-raw.mp4`, with sound `fold-it-up-third-run-sound.mp4` (1st's light
  at 7.07 s; peel 3.275, flap 4.075, scrunch 6.575, toss 8.125, dust 8.925 and 9.225; the track 2.2 dB down). Fold It
  Up on 1st, So Close on 2nd and 3rd, 56 frames a second, no game error.
- **Works (its stills and mine):** the live picture with its cream edge shrinks and rolls away into black with the
  big hand in it; a beat of black; the side view opens; the drawing reads on the poster; toss; arms fold.
- **Faults from the side camera:** (1) 3rd out of the picture (only hat and shoulder in the bottom right corner,
  its name plate on top); (2) the dim classroom (the blackboard) fills the right half: the dark is as see-through
  as in the front view, but the side view has more room in it; (3) on the way home the camera glides from the side
  spot through furniture (a grey block, a desk top beside the report card); (4) 1st's face a grey block for a few
  frames at leaving (A+ has it too: the scene's fade); (5) lopsided: 1st left of centre, the right half empty.
- **Fixed in the module (numbers in Edit only; not recorded):**
  - **(1) and (5):** the side camera was aimed at 1st; with the row about 0.8 of the camera's distance wide, the
    near runner-up fell 51 degrees off the aim, past the picture's edge (50). It is now turned so 2nd and 3rd are
    as far from the picture's middle as each other (their real spots, from `winners`), and swings 30 degrees
    (`SIDE`), not 35. With stand-ins: the runner-ups at 0.65 of the half picture each side (the front view: 0.67),
    1st 0.17 left of the middle; the near runner-up 0.73 of the front's distance away, the far one 1.24.
  - **(3):** from 9.4 to 10.3 s the camera swings back round to the front and the kid turns back with it
    (`BACK_AT`, `BACK_FOR`), so the scene's glide home starts from the front spot, the path the other emotes use.
  - **(2) and (4)** are the scene's (how dark the curtain is; the fade): not touched, Alan's call.

## Fourth run in Play (the primary session's muted recording, 2026-11-24, with the two fixes)
- **Files:** `.planning/emotes/fold-it-up-fourth-run-raw.mp4`, with sound `fold-it-up-fourth-run-sound.mp4` (1st's
  light at 7.11 s; the third run's sound times). Fold It Up on 1st, So Close on 2nd and 3rd, 54 frames a second, no
  game error.
- **Seen in its stills:** from the side all three are in view (2nd left, 1st middle, 3rd right, in full); the camera
  is back at the front before leaving and the glide home is clean.
- **Left:** in the side view the three name plates sit a little off their kids (2nd's and 1st's left of and below
  their stacks, 3rd's over the bottom of 3rd's books): the scene hangs them on the desks' front edges, front meaning
  the first camera. Not touched; offered to Alan: keep them away for the whole side view (`covered` until 10.3).
- **Not this emote's:** the grey face at leaving is the scene's fade (the head goes grey a few frames before the
  body; A+ too); the dim room is as in the front view (not a fault). Waits for Alan's look.

## Alan on the fourth run (2026-11-24) and the fourth build
- **His notes:** the hand must stay big while she takes the screen ("her hand should still be large on it because
  she's grabbing it"), better: "we can see the hand holding the picture ... her giant hand in the frame, but also
  wrapped around the frame", only just over it; "there shouldn't be a white border. It calls to the eye too much";
  the switch of cameras is too fast ("a smooth transition ... that camera went out, we're switching to this camera");
  the toss is wrong ("like throwing a baseball but in reverse ... You literally just bend your elbow, palm facing
  you, and then throw the object past you, behind you"); and the recordings always show the same bot's body ("we
  tune it to that model too much"): test other models.
- **Built (numbers in Edit only; not recorded):**
  - **The hand holds the picture:** from the pinch the copy hand, as it looked at the pinch, takes the picture's
    bottom edge (0.3 of the half width right of the middle, a quarter of the hand over the picture) in 0.15 s and
    stays there while the picture shrinks, tilting with it: 0.4 of the screen's height falling to 0.26 as the picture
    falls to 0.27 (`HOLD_TALL`), 2 studs from the lens, in front of the black (now 3 studs off), with a small light
    at the lens (`LAMP`: it is out of every spotlight). It is the avatar's own hand part, so it is whatever that body
    has (most Roblox hands have no fingers). Gone with the black.
  - **No rim:** the black meets the picture's edge.
  - **The switch:** the black closes over the small picture and the hand in 0.25 s (3.9 to 4.15), stays 0.35 s, lifts
    over 0.4 s on the second camera (4.5 to 4.9); the kid turns to it 4.6 to 5.2. It was 0.2 s of black and 0.15 s
    to lift. The drawing is shown square from 5.2 to 6.6 (1.4 s; it was about 2). The flap sound moves to 4.475.
  - **The toss** (the cut, baked again): the elbow stays in front of the shoulder and only folds; the hand goes from
    low in front up beside the head and flicks back past the shoulder; the chest no longer twists. The ball leaves
    backwards and up (0.1 right, 1.8 up, 2.0 back). On 12 of the bots' outfits in Edit: the elbow 0.04 to 0.13
    heights in front of the shoulder and at most 0.03 out to the side all through, bent from about 30 to about 140
    degrees; the hand passes 0.02 to 0.12 heights outside the head's box, except one big-headed body where it is
    0.03 inside the box's corner.
  - **With stand-ins:** no error; the hand 35% of the screen tall at 3.5 s, 31% at 3.7, 26% at 3.9, at the picture's
    bottom edge; all black 4.15 to 4.5; `covered` to 4.9.
- **Other bodies:** asked of the primary session: the next recordings with a different winner each time.

## Fifth run in Play (the primary session's muted recording, 2026-11-24, two other bodies) and its two fixes
- **Files:** take A, 1st is Pibbler (Alan's dog avatar, bulky): `.planning/emotes/fold-it-up-fifth-run-a-raw.mp4`,
  `-a-sound.mp4` (1st's light at 7.25 s). Take B, 1st is itsfinn (blocky, wings, shoulder pets): `-b-raw.mp4`,
  `-b-sound.mp4` (light at 7.37 s). So Close on 2nd and 3rd, no game error. Sounds at 3.275, 4.475, 6.575, 8.125,
  8.925 and 9.225. How other winners were got: with no points the first match of a Play always puts the same bot
  1st; ending the following matches gives other orders (`docs/workshop/lessons.md`, "Scripted Play tests").
- **Works (its stills and mine):** the big hand at the shrinking picture's bottom edge, big, no rim, on both; the
  lens light lights the hand and nothing else; black, then the side view opens slower; the drawing reads on both
  (on the dog across the chest under the snout); the toss on itsfinn: the arm folds, the ball leaves up and back.
- **Faults:** the dog's hand is a brown furry lump (its own hand part: an odd body, an accepted loss); the hand hung
  under the picture with its fingers pointing down, away from it (take B's hand has fingers: clear to see); from the
  side 3rd sat in the bottom right corner, its books at or past the bottom edge in take A and its name plate over
  them; 2nd's and 1st's plates left of and below their stacks. Take B's room is brighter all through (the player
  was in the hangar menu when the match ended): the scene's.
- **Fixed in the module (numbers in Edit only; not recorded):**
  - **The hand's fingers point up over the picture's edge**, the back of the hand to us (she holds it from behind;
    a hand part's own down is its fingertips), in place of the hand as it looked at the pinch.
  - **The near runner-up is no longer low in the corner:** what puts a winner low is how near they are along the
    camera's line (at 30 degrees the near one was at 0.73 of the front view's depth). The side camera now swings 20
    degrees and stands 1.15 times as far from 1st (`SIDE`, `FAR`): with stand-ins the near runner-up is at 0.96 of
    the front's depth, the far one 1.33, 1st 1.14 (so 1st is about an eighth smaller in the side view), the
    runner-ups 0.57 of the half picture each side. The swing back before leaving closes the distance too.

## Alan on the fifth run: the hand in the corner (2026-11-24, given in the primary session with a marked still)
- **His words:** "where the hands land on the screen, the character is not in the position ... The hand should be in
  the corner, grabbing it, but the hand is for some reason at the bottom." On `.planning/emotes/fold-it-up-alan-hand-corner.png`
  he crossed out the big hand under the picture's bottom middle and circled the picture's top left corner.
- **Built (numbers in Edit only; not recorded):**
  - **The big hand** leaves the kid's own hand at 3.05 and flies, growing, to the picture's top left corner as we see
    it, there at the pinch (with stand-ins: 7% of the screen tall near the middle at 3.2 s, 19% half way at 3.29, 39%
    at the corner at 3.35). It holds the corner: palm to us, fingertips pointing up and left out over the corner, a
    quarter of the hand past it (`GRIP_OVER`), and follows the corner in as the picture shrinks (26% of the screen
    tall when the picture is 0.27). The line-to-the-wrist growth of the earlier builds is gone.
  - **The kid's arm** (the cut, baked again) reaches up and out to the kid's right and at the lens, towards that
    corner as we see it, and **stays reaching until the black** (4.15), so the kid in the shrinking picture is still
    in the grabbing pose; the hands go to the poster in the dark (by 4.45). The chest keeps leaning in until then.
    On 4 of the bots' outfits in Edit the reaching hand is 0.06 to 0.13 heights over the shoulder, 0.09 to 0.13 out
    and 0.14 to 0.24 in front; nothing goes into the head or chest.

## Sixth run in Play (the primary session's muted recording, 2026-11-24, the corner build) and its fixes
- **Files:** take A, 1st Pibbler: `.planning/emotes/fold-it-up-sixth-run-a-raw.mp4`, `-a-sound.mp4` (light at 7.41 s);
  take B, 1st itsfinn: `-b-raw.mp4`, `-b-sound.mp4` (light at 7.29 s). So Close on 2nd and 3rd, no game error; the
  fifth run's sound times.
- **Works (its stills):** a small hand leaves the kid towards our upper left, grows, is at the picture's top left
  corner at the pinch and stays on it all through the shrink (pale and clear on itsfinn, fingers over the corner);
  from the side all three sit clear of the edges, 3rd whole, each name plate under its own stack.
- **Faults:** (1) the kid's own arm does not read as reaching to the corner (on itsfinn the arms look down or at the
  chest; on the dog no arm shows); (2) at the pinch the big hand runs off the screen's top left and the yellow Menu
  tag sits on top of it for a few frames; (3) on the dog the hand is a furry lump (its own hand part: an odd body).
- **Fixed (numbers in Edit only; not recorded):** (1) the reach was mostly forwards, so from the front it hardly
  showed: the hand now goes up and well out to the kid's right (on 4 outfits 0.14 to 0.23 heights out from the
  shoulder, 0.10 to 0.15 up, 0.08 to 0.13 in front; it was 0.09 to 0.13 out), the arm as straight as it gets; baked
  again. (2) `covered` starts when the hand sets off (3.05), so the Menu tag and the plates are away before it
  arrives; a little less of the hand is past the corner (`GRIP_OVER` 0.15, was 0.25). (3) not touched.
