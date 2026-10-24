# Touch plan: phones and tablets (2026-10-23, approved by Alan the same day)

Alan asked (2026-10-23) when to start mobile and controller support. The recommendation: touch now, finished before
the Stage 11 private playtest; controller after it. [VISION](../vision/VISION.md) says "PC first, touch later", so
moving it earlier was Alan's call: he OK'd it the same day (answers below).

## What the player sees

### Flying (the hard part)
On PC the mouse moves an aim point and the plane flies its nose after it ([flight](../systems/flight.md)). On a phone:
- **Left thumb: a steering stick.** Push it and the aim keeps turning that way; let go and the plane flies straight
  and levels out, like letting go of the mouse. It appears wherever the left thumb touches (no aiming for a small
  circle). The same stick input later serves a controller's left stick, so controller support comes almost free.
- **Right thumb: the buttons.** A big Fire button (weapon 1), a smaller one above it (weapon 2), and Boost (only with
  a boost part). Shaped and coloured like the paper HUD, not Roblox's grey defaults.
- Option in Settings for older players: **Drag to aim** (drag anywhere on the right half, like the mouse), with the
  buttons moved to the left. Default stays the stick.
- No tilt-the-phone steering (it tires arms and fights the stick); can be added later if players ask.

### Aim help on touch
Thumbs are less precise than a mouse. The aim help the game already has (it picks a target and shows its lead ring)
gets a little stronger for touch players only. How much is a tuning number, set by feel and by Alan.

### Menus, HUD and screens
- Every screen fits a phone: nothing under the thumbs while flying, text big enough to read, taps big enough to hit.
- Everything that is a key today gets a tap: the menu (Tab) becomes a small paper button at the top, Launch (Enter)
  and Fresh plane (R) are buttons at the desk, sticky notes get "Got it" and "Skip all" buttons (Space/K), the vote
  cards and Range cards are tappable (1-5), the Hangar's plane turns with a finger, sliders drag with a finger.

### Tutorials and tips
Flight School, Combat School, the Hangar Tour, the Range notes and Match Tips say the touch words on a phone ("push
the stick", "tap Fire") and the key words on PC.

## Build order after Alan's OK
1. **Steering stick + Fire/Boost buttons** in flight. Check: fly a lap and a fight in Studio's phone simulator.
2. **Aim help for touch:** research done ([touch aim research](../research/TOUCH-AIM-RESEARCH-2026-10-23.md): a wider soft-edged gun assist first, slowdown near enemies second), then build. Check: hit rate against the Range targets on the stick close to a mouse player's.
3. **Every key gets a tap** (list above). Check: a whole session from first join to a round end with no keyboard.
4. **Screens on phones and tablets:** every screen at two phone sizes and one tablet size in the simulator, with
   screenshots; fix overlaps and small text.
5. **Tutorial and tip words per device.**
6. **Real phone check** (needs a private publish: Alan's go): Alan plays on his phone; we measure FPS there.

## Progress
- 2026-10-23/24: step 1 (stick, FIRE / 2 / BOOST) and step 2 (aim help, fake-pilot tuned) built. Step 3 started:
  Settings sliders, the Hangar's plane turning and the Range's stage strips (tap the strip) take fingers; the lesson's
  Skip button held 1.5 s skips the whole lesson (like holding K); every text on screen says touch words (step 5,
  TouchWords).
- 2026-10-24: Alan turned on Studio's Device Simulator (a 749 x 381 phone, landscape; Claude's Play screenshots are
  now phone-sized). Flight screen done for phones: FIRE / 2 are paper discs that fill with their weapon's crayon state
  (heat, reload, lock) and name it; the weapons panel hides; Health and Lift sit top-left under the Menu button; the
  round strip sits in the top bar's row right of Menu; the kill feed drops under the top bar; HUD scale floor 0.4.
  Full-screen menus: the background covers the screen and the buttons sit on their own sheet that always fits (no
  more cropping on wide phones). **Next (step 4):** text on the menus is about 7-10 points on a phone (too small):
  go screen by screen (main menu, Settings, Hangar, desk strips, lesson notes, tips, round end) in the simulator.
- 2026-10-24 (later): step 4 done in the simulator: every paper screen gets phone sizes (bigger words and taps) while a
  PC keeps its look; Customize was off the bottom of a phone's desk strips, the Hangar's Back sat under Roblox's own
  buttons, and the lesson note, tips, round-end banner and vote covered the Menu button: all fixed. Menu backgrounds
  now reach the screen edges on notched phones. **Next:** taps in the simulator (step 3 check), stick tuning with
  Alan, then step 6.

## Checks
- Studio's Device Simulator (free) shows the screen sizes and gives touch-like input, but it can't show how thumbs
  feel or how fast the game runs on a phone ([Roblox: test on hardware](https://create.roblox.com/docs/performance-optimization/test-on-hardware)).
  So the feel and speed sign-off is on Alan's real phone (step 6).
- Done when Alan plays a full session on his phone (first join, the tutorial, a match, the winners' moment, the vote)
  and says it works.

## Alan's answers (2026-10-23)
1. Touch before Stage 11, controller right after: yes ([decision](../decisions/2026-10-23-touch-before-launch.md)).
2. Stick by default, "Drag to aim" as an option: yes.
3. More aim help for touch: yes, but research how to do and tune it first (step 2 starts with that research).
4. A private publish for the real-phone check once steps 1-5 are done: yes (the publish itself still gets his go then).

## Cost
Code only; no uploads expected beyond a few small button pictures (shown to Alan assembled first). $0 in tools.
