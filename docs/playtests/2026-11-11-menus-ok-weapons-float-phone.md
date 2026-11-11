# 2026-11-11: menus with the uploaded pictures; weapons float; phone flight screen

## What Alan did
Looked over the menus after the 7 new pictures were uploaded and merged, published the game (today's code is live),
and played it on his real phone. Sent two screenshots of one build in the Hangar.

## What he saw
- **Menus: approved.** "All the text and images look good."
- **Weapons don't attach to the planes** (two examples on one build): the popcorn Poppers hang under the wings with a
  gap; a gun on the body spot sits in the body's side.
- **Phone:** "the speed match and the buttons look bad now, something didn't port right." (Speed match is the
  phone-only Settings row; not yet pinned down: waiting on a phone screenshot.)

## What changed
- Every gun now hangs by its highest point and touches what it hangs from: the wing root on the body pair (they hung up
  to half a stud below it, on every plane), the wing on the wing spots (now touching instead of a hairline gap; Swept
  Wings hung lower still), and crowded guns shrink toward their top. Checked on exact shapes: all 1,500 placements
  (6 bodies x 6 wing sets x 10 weapons x every spot) touch, none pokes through a wing. Details:
  [planes and hangar](../systems/planes-and-hangar.md).
- Phone: measured every phone-sized menu button in Studio's phone mode; only the Hangar Back strip stands out (drawn at
  half its box height). Nothing changed yet.
