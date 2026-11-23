# Fold It Up

A 1st-place emote that takes the whole picture. Made by the [emote pipeline](../emote-pipeline.md), in its own side session; the idea is on the
[plan](../../plan/WINNERS-CIRCLE-PLAN.md).

**The idea (first):** Grabs the picture itself, folds the whole screen into a paper plane and throws it away.
**The idea now (Alan, 2026-11-22):** Peels the picture off the screen, shows you it is only a crayon drawing of the
winners (stick figures, a crown on 1st), crumples it up and throws it over the shoulder. The name may change.

## Where it stands
Step 1: the second card (peel, show, crumple) waits for Alan's OK. Nothing is made.

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

## Shot card (second, waits for Alan's OK)
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

**For Alan to pick (my default first):**
- **The reach:** (1) pinch through forced perspective, as in the table; (2) the beckoning finger.
- **The sheet's size in his hands** (the kid is about a third of the screen's height): (1) poster size, about half
  the kid's height, about a sixth of the screen tall, held up with both arms; (2) real paper size, a third smaller,
  where the crown may be too small to read.

**The body:** none of the 12 Roblox emotes the game already uses rubs hands, pinches, crumples or throws (same
finding as [A+](a-plus.md)). A body cut from the Gemini video, as Book Kicker and Bubblegum.

**Reused:** the sheet's flight along the line of sight is Book Kicker's and Bubblegum's lens sums run backwards; the
scene's curtain, lights and name plates as they are. Nothing hides the name plates or the Menu tag except for the
instant of the pinch.

**New (needs Alan's OK on this card):** one crayon drawing (made as a picture, checked by Alan, then uploaded with
his go); the sheet at the lens and in the hand; a paper ball; the timings above (my numbers).

**Sounds (few and quiet; the music plays under them):** a crinkle at the pinch, a short peel, a flap as he turns it,
a scrunch, a soft toss.

## Files
None yet.
