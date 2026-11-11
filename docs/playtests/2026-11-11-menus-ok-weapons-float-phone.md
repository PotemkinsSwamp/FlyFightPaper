# 2026-11-11: menus with the uploaded pictures; weapons float; phone flight screen

## What Alan did
Looked over the menus after the 7 new pictures were uploaded and merged, published the game (today's code is live),
and played it on his real phone. Sent two screenshots of one build in the Hangar.

## What he saw
- **Menus: approved.** "All the text and images look good."
- **Weapons don't attach to the planes** (two examples on one build): the popcorn Poppers hang under the wings with a
  gap; a gun on the body spot sits in the body's side.
- **Phone:** "the speed match and the buttons look bad now, something didn't port right." His phone screenshot (in a
  match): the FIRE and BRAKE buttons' crayon fill sits over their words, and the "SPEED MATCH" tag under the view is
  white words that don't match the game's text.

## What changed
- Every gun now hangs by its highest point and touches what it hangs from: the wing root on the body pair (they hung up
  to half a stud below it, on every plane), the wing on the wing spots (now touching instead of a hairline gap; Swept
  Wings hung lower still), and crowded guns shrink toward their top. Checked on exact shapes: all 1,500 placements
  (6 bodies x 6 wing sets x 10 weapons x every spot) touch, none pokes through a wing. Details:
  [planes and hangar](../systems/planes-and-hangar.md).
- Phone: both came from text style C (2026-11-08), never checked on a phone. The crayon words' three copies stayed at
  ZIndex 1 and drew under the buttons' crayon fill (the touch screen layers globally): copies now take the label's
  ZIndex, for every word in the game. The BRAKE / SPEED MATCH tag got the crayon words.
- Phone, second look (published): FIRE / BRAKE words and the weapon name now read on top. He didn't like the notebook
  strip behind SPEED MATCH: it is crayon words alone now.
- Guns attached: "looks good". He asked for a Clear all on the Gear page: built next to Clear spot (the Buy / Cancel
  places). He wanted it identical to Clear spot but red, with tape not a pin: the green taped paper recoloured red
  (preview `.planning/menu-fit/10-clear-all-red-preview.jpg`, his OK, uploaded), same size and tilt.
