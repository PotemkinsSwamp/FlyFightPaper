# 2026-11-11: the unlock backpack in Studio

## What Alan did
Opened the test backpack in Studio Play several times (`DevUnlock` 5 and 8: everything up to that level), dragged the
zipper, stepped through the cards and pressed Later and Put it on.

## What he saw
- **Unzipping works** ("if it looks like that video, it works"); the first version of the opening (cut straight at the
  pull) looked very bad, the redone one opens like a real zipper.
- **Arrows:** cream paper tags over the binder holes looked bad; ink chevrons on the page beside the dots are better.
- **Zipper sound:** wanted one zip that follows the pull. Tries: a whole-file loop (choppy, restarted), the sound's place
  tied to the pull (slowed down it sounded deep; then broken: Roblox gaps when a sound is moved), then the usual game
  method (a short zip loops, pull speed sets its loudness): "a little better", then 20% quieter, but
  grating when pulled slowly ("like a car starting"). Then one long zip tied to where the pull is: stopping mid-way
  silenced it and going back made no sound. Last: one long zip played by how far the pull moves, either way: "its good
  now".
- Picked the "Bag Zipper From Nylon Bag Backpack Luggage 1" sound.

## What changed
Chevrons, card centred on the page's writing area, the zip that plays as far as you pull (see
[menus and HUD](../systems/menus-and-hud.md) and [the unlock plan](../plan/UNLOCK-PLAN.md)). The level-up note (seen in a match
through `DevLevelNote`): "looks good", on screen 2 s instead of 4; then:
back to 4 s but smaller, shorter and tilted at the top left, with a fly-in he can see, a real unfold and confetti that
moves (it just popped up and vanished); the backpack belongs on the main menu, not the in-match menu. Checked with
`DevLevelUp`: the backpack followed him to the main menu after Leave match. Not yet seen: phones.
