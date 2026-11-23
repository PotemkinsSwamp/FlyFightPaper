# Fold It Up

A 1st-place emote that takes the whole picture. Made by the [emote pipeline](../emote-pipeline.md), in its own side session; the idea is on the
[plan](../../plan/WINNERS-CIRCLE-PLAN.md).

**The idea:** Grabs the picture itself, folds the whole screen into a paper plane and throws it away.

## Where it stands
Step 1: the first card is turned down; the emote is being rethought without a screenshot. Nothing is made.

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

**My pick: A with C as its automatic fallback.** The picture is asked for half a second before the grab; if it is
not there at the grab, the same pieces show plain paper and the emote plays the same.

## Shot card (draft, waits for Alan's OK)
**The feeling: cheeky show-off. "This whole picture is mine": playful, a little rude, never angry.** Quick, neat
hands for the grab; a careless toss at the end.

Seconds after 1st's light. The scene leaves at its usual 10.4 s, so the report card keeps its 10 seconds.

| Time | The kid | The picture / the plane | What the camera sees | Sound |
|---|---|---|---|---|
| 0 to 1.5 | Light on. Looks at 2nd, then at 3rd, then straight at you with a sly grin; rubs hands | Live | All three, as always | Music only |
| 1.5 to 2.5 | Leans in and reaches both arms at the camera, hands open at shoulder height | Live (the screenshot is taken at 2.0) | Same | None |
| 2.5 | Pinches: both hands snap shut | **The grab:** the picture freezes, gets a white paper border and lifts off the glass: 92% of the screen, tilted 3 degrees, a soft shadow under it | Black round the sheet's edges; name plates and Menu tag gone | Paper snatch (crisp) |
| 2.5 to 3.0 | Hidden behind the sheet | Hangs, a tiny sway | Black edges | None |
| 3.0 to 3.6 | Hidden | **Fold 1, the crease:** the top half folds down over the bottom (its plain paper back shows), then opens again; a crease line stays across the middle | Black over the top half for a moment | Fold 1 |
| 3.6 to 4.3 | Hidden | **Fold 2:** the two right-hand corners fold in to the crease: two triangles of plain paper, the picture now a house shape pointing right | Black where the corners were | Fold 2 |
| 4.3 to 5.0 | Hidden | **Fold 3:** the new slanted edges fold in to the crease again: a sharp nose | More black on the right | Fold 3 |
| 5.0 to 5.6 | Hidden | **Fold 4:** folds in half along the crease, the bottom half up behind the top: a long flat dart, half as tall, the picture's top half outside | Black over the bottom half | Fold 4 |
| 5.6 to 6.2 | Hidden | **The wings:** fold down and the plane turns to point away from you; the picture's pieces on its wings. About 60% of the screen wide | Black round it | Double crease |
| 6.2 to 7.0 | 1st's light clicks back on: the kid stands on the stack, one hand out, palm up | The plane hangs, bobbing | The kid under the plane | Click (the scene's own) |
| 7.0 to 7.6 | Catches it | The plane glides down into the hand, smaller as it goes | The kid with the plane | Soft paper tap |
| 7.6 to 8.6 | A glance at it, a shrug, then tosses it backhand over the shoulder | Flies off into the dark behind | The kid | Whoosh, quiet |
| 8.6 to 10.4 | Dusts off the hands, arms folded, chin up | Gone | The kid alone | None |
| 10.4 | The scene leaves as usual | | The curtain lifts, the camera glides home, the report card comes up as always with its 10 s | Music |

**For Alan to pick (my default first):**
- **The grab:** (1) *pinch and lift*, as in the table; (2) *reach up and pull down*: the kid jumps, grabs at the top
  edge of the screen and pulls it down, and that pull is fold 1 (the grab and the first fold are one move).
- **What is behind the folded picture:** (1) *black, and 2nd and 3rd are gone*: when the light comes back only 1st
  stands there, the other two were folded into the plane ("takes the whole picture"); (2) *black, all three come
  back*: 2nd and 3rd are back on their stacks doing their own emotes, only the picture was thrown; (3) *the live
  scene keeps going under the frozen picture*: I advise against it, every kid would be seen twice.
- **The throw:** (1) *into the kid's hand, tossed over the shoulder*, as in the table; (2) *it throws itself*: the plane
  pulls back and darts off into the dark over the desks, then the light comes on 1st, already dusting off.

**Who folds:** nobody is seen. The folds move by themselves, quick and neat, as if someone on your side of the glass
did them. Each fold 0.6 to 0.7 s: snaps fast, settles slow.

**The body:** none of the 12 Roblox emotes the game already uses reaches, pinches or throws (same finding as
[A+](a-plus.md)). A body cut from the Gemini video, as Book Kicker and Bubblegum; the backhand toss may reuse Camera
Flick's throwing arm.

**Reused:** Book Kicker's hiding of the name plates and the Menu tag; the scene's curtain and spotlight click; Camera
Flick's plane model for the toss if the folded plane is swapped for it in the hand.

**New (needs Alan's OK on this card):** taking a screenshot of the player's screen (silent, kept only for this
emote, never saved or sent anywhere); paper pieces at the lens that fold; in version (1) of "behind", 2nd and 3rd
leaving the scene before the card; the fold timings above (my numbers).

**What the scene must do (asked of the primary session at step 4):** let the emote darken the room fully and turn
the spotlights off and on during the folds; hide the name plates and Menu tag from the grab to the throw.

**Sounds (few and quiet; the music plays under them):** the paper snatch at the grab; one short crease per fold
(four, then a quick double for the wings); a soft tap as it lands in the hand; a quiet whoosh on the toss.

## Files
None yet.
