# Playtest 2026-10-18: Flight School with the attention pass

Alan played Flight School in Studio after the "Grabbing attention" pass ([tutorial](../systems/tutorial.md)).
"It works pretty well for the most part." His notes; how each was handled is in brackets.

1. **The guide line is a little odd: hard to tell where it's going.** [Now a smooth curve through the path's turns,
   leaving along the plane's nose, re-planned once a second instead of 2.5 times, so it doesn't jump. Not yet re-checked.]
2. **The arrow with the line is obnoxious.** Smaller and to the right of the line. [16 -> 10 studs wide, 14 studs to
   the right. Not yet re-checked.]
3. **The goal note sits in the middle of the view.** Move it up (the death note it dodged is gone). [Now just under
   the top strip. Not yet re-checked.]
4. **The Lift step didn't highlight the Lift bar.** [The bar's frame gave way to the fan after 3 s; now the bar has its
   own breathing frame the whole step, next to the fan's focus. Not yet re-checked.]

Also from Claude's own Play check: the close hoop's frame filled the screen (now capped at 28% of the screen height)
and the hoop looked like loose blocks (now 24 pieces end to end).

## Second look (same day)
5. **The line got worse: not visible enough to show you're going the wrong way; the arrow just follows the line
   ("go forward") even toward a wall.** [Line bolder (4.5 studs, full glow) and no longer bent out of the nose. The 3D
   arrow is gone: a smaller see-through arrow by the aim circle shows only when you fly the wrong way and points where
   to turn, back if the way is behind you. Not yet re-checked.]
6. **The sticky note was gone for the whole lesson** (the boost step showed only the bar). [Claude's bug: a comment put
   mid-line switched off the rest of the line, including the note's parent. Fixed.]
7. **The hoops aimed straight into the fan, so the Lift step was over before you could read it.** [New course ends
   heading north with the fan 90 degrees to the left and 450 studs of clear air ahead. Not yet re-checked.]

## Third look (same day)
8. **The desk card's frame cut off the ends of the four buttons.** [The frame trimmed 10% off each side of paper
   buttons; now 2%, since these strips reach the sides. Not yet re-checked.]
9. **Lessons need their own music: peaceful, focusing, playful, subtle (maybe classical), free to use; no distracting
   sounds; a ding for every finished step, like the hoops.** [Calm lesson playlist of four licensed tracks picked by
   description (Alan judges by ear), quieter than match music; classroom chatter off during lessons; each finished step
   plays a rising two-note chime, louder than the hoop ding (it used to be the same coin sound, masked by take-off,
   fan and bolt sounds). Combat Training gets different music later. Not yet heard.]

## Fourth listen (same day)
10. **Music too loud: lower it about 30%; one song, not a playlist; Alan picks it by ear.** [Volume .12 -> .084, one
    looped song (Pure Innocence as a stand-in); links to eight choices sent to Alan; he picked "Daisy Fresh".]
11. **Ring dings got louder each hoop (the first inaudible) and no chime after any other step.** [Root cause: sounds
    without a place sat in an attachment outside the room, which put them at the room's middle, so they faded with
    distance from it (the hoops get closer to the middle; the fan and bolts are far). They now play straight in
    SoundService; this also fixes the round-start bell, lock beeps and desk service sounds far from the middle. Every
    sound also loads at start. Not yet heard.]
