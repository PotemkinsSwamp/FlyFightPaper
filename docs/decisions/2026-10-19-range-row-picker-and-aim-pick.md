# Hangar Range: stays on the stage, level plane, shootable row picker; aim help picks by lead

**Decided:** 2026-10-19 (Alan, after his first Play look at the real stage)  
**Status:** in force (built; waiting on Alan's Play check and the picker art upload)

## Decision
- **No black box:** the aim stops at the stage edges (about 30° left/right, 20° up/down) and the edges of the view are
  dressed as the theatre (drape-coloured walls, cardboard floor, bulb strips), not a full 360° room.
- **Your plane stays level** in the Range: it only points, it never banks.
- **Row picker = knock-down targets you shoot**, on the close row's lip near the bottom: Close, Medium, Long range and
  All. Shoot one: "ting", it tips back and stays down while picked; the old rows' targets fall and the new rows' rise.
  Each plate is a plane shape with its word over it; the closer the row, the bigger the plate (Close biggest).
- **Smarter aim help, whole game:** the marker picks the enemy whose lead (where you'd shoot to hit it) is nearest your
  crosshair, not the plane itself, and keeps it until another is clearly nearer. A near target crossing your sight no
  longer steals the marker from the far one you're leading.

## Why
Alan: "it's just in a big black box"; "your plane needs to stay level"; shooting the far targets, "the ones up close
might move forward and then take the targeting". He wants one target at a time, switching by where the crosshair points.

## Where
[Tutorial system page](../systems/tutorial.md) (the Range), `src/client/FlightHUD.luau` (aim pick).
