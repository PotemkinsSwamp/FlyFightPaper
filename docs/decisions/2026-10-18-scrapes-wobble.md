# Scrapes wobble you; head-on hits crash

**Decided:** 2026-10-18 (Alan)  
**Status:** in force; not built yet

## Decision
- **Same rule for buildings and the train's sides.** Touching a wall at a shallow angle (under about 25 degrees
  between your flight path and the wall) is a **scrape**: a little damage, and the plane is knocked and wobbles (rolls
  and swings away) so you have to correct it. Grinding along the wall keeps hurting more the longer it lasts.
- Hitting more **head-on** (the nose or the front edge of a wing ploughing in) is a **crash**.
- The **front of the moving train** running into you (a T-bone, or catching you from behind) still kills at once
  ([train rule](../systems/monorail.md)).
- Alan picked "by angle" over "by which part touches" (a steep dive that only clips a wingtip should still crash).

## Why
Alan's Stage 9 playtest: a wing brushing the train or a building killed him outright. Today a wall crashes you once
you move into it faster than 12 studs/s (`combat.collision_crash_speed`), about an 8 degree angle at full speed, so a
graze while slightly angled in counts as a crash. Real planes that clip something wobble and have to be caught.

## Affects
- [Damage and deaths](../systems/damage-and-deaths.md) · [Flight](../systems/flight.md) ·
  [Monorail](../systems/monorail.md)

All decisions: [decisions](README.md)
