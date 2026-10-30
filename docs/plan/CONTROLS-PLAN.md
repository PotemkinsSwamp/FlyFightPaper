# Controls plan: move your phone buttons, then change your PC keys

**OK'd by Alan 2026-10-30** (no size slider, no movable stick); part 1 built 2026-10-30, not yet seen in Play. Alan, after trying the BRAKE button on his phone: "it's not ergonomically placed
well"; he wants players to set controls up their own way: on a phone, move the buttons; on a keyboard, change the
keys. Phone buttons first (Alan).

## What the player sees
**Phone (part 1).** Settings has a new **Phone buttons: Move** tab (phones only, above Auto-fire). Tapping
it closes Settings and shows the layout editor over the game:
- FIRE, 2, BOOST and BRAKE where they are now; the left half of the
  screen shaded with the words "Steering stick" (the stick appears wherever your left thumb lands there, so buttons
  can't go there).
- A sticky note on the shaded half (out of the buttons' way): "Drag a button to move it." and three buttons: **Save**, **Reset** (back to the game's
  layout) and **Cancel**.
- You drag a button with your finger; it follows smoothly. While it would overlap another button or leave the
  screen it turns red; let go there and it slides back to its last good spot.
- Save keeps it on your account: the same layout on any phone or tablet you play on.
- In a match the editor works like the other menus over the game: your plane keeps flying (the Settings rule today).

**PC (part 2, after part 1 is approved).** Settings gets a **Controls** page: Boost (Shift), Brake (Space) and Got it
(Space) listed with their keys; click one, press a key. Esc and Roblox's own menu keys can't be used; choosing a key
another action has swaps the two. Every note, tip and lesson that names a key says *your* key ("Hold Ctrl to brake").

## How it works (part 1)
1. **Saving:** the profile's settings get `touchLayout`: for each button that was moved, where its middle sits as a
   share of the screen's width and height (0 to 1). Missing = the game's layout, so old saves and unmoved buttons
   need nothing. The save check accepts only those four buttons and numbers 0 to 1 (unit tests, like Auto-fire's).
2. **Placing:** `TouchControls` places each button from the saved shares; sizes stay as today (thumb-sized for the
   screen). On a screen of a different shape (phone vs tablet) a saved spot can land off-screen or on another button:
   it is pushed back on screen and apart; if that still fails, that button uses the game's spot.
3. **The rules** (a small shared module with unit tests, `TouchLayout`): on screen and below Roblox's top bar; the
   whole button on the right half; no two buttons touching (an 8-point gap, the closest today).
4. **The editor:** a layer in `TouchControls` (it owns the buttons). It also takes mouse drags, so it can be checked
   in Studio with the phone view on.
5. **Lessons:** they already find a button by its name wherever it is, so their frames and arrows follow a moved
   button (to be checked).

## Build order after Alan's OK
1. `TouchLayout` rules + unit tests; `touchLayout` in the save check + tests.
2. Buttons placed from the saved layout.
3. The editor and the Settings tab.
4. Studio check at phone size (Alan's go for Play): drag each button, the red overlap, Reset, Cancel, Save, then
   leave and rejoin and the layout is still there; a lesson step that frames FIRE after FIRE was moved.
5. Docs; then Alan tries it on his phone (publish: Alan).

## Checks
Unit tests for the rules and the save; Studio Play at phone size with screenshots; Alan's phone run is the sign-off.

## Cost
No assets, uploads or paid tools: the editor reuses the stickers, notes and tabs we have. Part 1 about one session,
part 2 about half a session, each plus a phone or PC try by Alan.

## Alan's answers
2026-10-30: OK, phone buttons first. No size slider; the steering stick stays where your thumb lands.
