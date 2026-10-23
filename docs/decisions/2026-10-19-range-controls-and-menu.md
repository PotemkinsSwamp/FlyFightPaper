# Hangar Range: crosshair is the cursor, row plates stay on the floor, menu drops on strings; own loadouts next

**Decided:** 2026-10-19 (Alan, over three Play looks)  
**Status:** in force (built; waiting on Alan's Play check of the last layout)

## Decision
- **No side boards.** Two full side boards took 40% of the screen and the stretched cardboard looked wrong. The stage
  stays open and the targets sweep wide and high over most of it.
- **The crosshair is the cursor in the Range:** a click acts on whatever it is over (plates, strips, the game's own
  Menu button) while the guns fire as usual. Range only.
- **Row plates (Close / Medium / Long range / All) stay on the floor:** one click switches rows. Not in a menu: "that's
  how other games work". Each plate's stick stands on its hinge as one piece.
- **Score card + Reset** hang top right. **Range Menu and Hangar** are plain strips (no pins) hanging at the left edge
  under the game's Menu button, Hangar hanging from Range Menu; strings run behind the paper.
- **Range Menu drops on strings** with a small bounce: Loadouts 1-5 (also keys 1-5) and Difficulty (Noob, Challenge,
  Veteran, Maneuvers) plus Edit in Hangar; Back to range (or Range Menu again) pulls it back up.
- **Maneuvers** weaves at Challenge's speed (at Veteran's it was impossible).
- **The Range keeps its own five loadouts with names you can change** (Alan picked this over the swap animation first;
  plan OK'd later the same night): saved with the profile, any part allowed, never used in matches; the Hangar opened
  in the Range edits them; renaming (click the name, 20 letters) works for match builds too; you start on the Range
  build you last flew there (Alan's pick over "always build 1").
- **2026-10-20 (Alan, Play look):** the menu's Tutorial button is now **Training** (it holds three lessons and the
  Range); Range Menu and Hangar hang top left, level with the score card (a long lead ring hid behind them lower
  down); in the Hangar the build's name is a white tag under the plane, the 1-5 buttons sit half over the folder's
  bottom edge, and in the Range a **Test in Range** button (everyone, top left) saves and drops you back flying it.
  The lead ring must be trustworthy: practice targets now give it their exact path. Second look the same night:
  shots near the ring landed (the aim help) and dead-on shots at climbing targets missed (the hit check used the
  plane under the card, which lagged its path), so the Range has no aim help and judges hits on the path; the
  game's Menu button moved into Roblox's top bar for good (Alan: "that would have to be permanent, which I don't mind").
- Liked, later: on a swap the old plane flies off into the distance and the new one slides in from behind. **Dropped for now (Alan 2026-10-23: "not that important").**

## Why
Alan: the boards were "taking up too much of the screen"; "I have to click menu, then another one, then back to
range... no, they can't be in the menu"; "you should be able to change the names of the loadouts so that you know
what it is"; "I keep hitting them when shooting at the targets".

## Where
[Tutorial system page](../systems/tutorial.md) (the Range), `src/server/RangeStage.luau`, `src/client/RangeBoard.luau`.
