# 2026-11-06: Alan tries presets at the desk in Studio

## What Alan did
Played a match in Studio with the six presets (stand-in weapons), switching planes at the desk and flying them.

## What he saw
1. Switching a loadout or preset sometimes reloads the whole desk menu, sometimes not. It should only change the plane.
2. **Paperclips aren't precise:** at long range, a perfect shot on the tracking circle doesn't hit. They need much more
   velocity and range; damage stays the same. Holding the button should keep firing, still waiting for each reload.
3. **Guns may cross:** they aim in to a point and form an X past it, which hurts precision.
4. **Bomber too strong:** 2 Paperclips + 2 Pellets. Make it 1 Paperclip + 2 Pellets.
5. **Scout too weak:** 1 Rubber Band does almost nothing. Make it 2.
6. **Planes no longer seem to collide:** two planes can't hurt each other. It should work from health: the stronger plane
   survives and the weaker one folds, by subtraction, probably with something extra on top.
7. **Staples get inaccurate** after a short distance. He thinks the targeting circle follows range but not how fast the
   shot flies, so it isn't where the shot will meet the plane.
8. **Speed pickups should add Boost:** about 0.5 s of Boost each.

## What it meant
All eight were changed the same day, and Alan's Studio check is still to come:
1. A swap took the old plane away before the new one arrived, so the HUD could catch a moment with no plane and pop the
   whole menu in again. The new plane now goes in first.
2. Paperclips: 3600 launch speed, about 2420 studs of range, same damage; holding fires at each reload.
3. With a target the guns already met at its range. With no target they crossed at 150 studs and spread; they now meet
   at the weapon's full reach.
4-5. Bomber 1 Paperclip + 2 Pellets; Scout 2 Rubber Bands.
6. The check needed the two planes' thin flight bodies to overlap, which almost never happens. It now goes by distance,
   then the exact shapes. The stronger plane also loses 15 extra and always survives.
7. The ring already used shot speed, drag and drop. Tapped bursts had a fault, fixed: their later rounds flew along the
   plain nose. Whether that was all of it isn't known. Alan's first shot log couldn't say, as it didn't record whether he
   was on the ring. With that mark added, 28 on-ring staple shots (about 7 bursts, so a small sample): 12 of 18 hit out
   to 300 studs, 2 of 10 from 575 to 760. No on-ring miss passed in front of the plane; four pairs passed about 10 studs
   behind. Then measured: Alan's screen draws bots 0.18 s behind the server, and the game allowed 0.1 s, so shots fell
   about 7 studs behind a 90 studs/s bot. Allowance set to 0.18; Alan: the staples work now.
8. A pickup adds 0.5 s of Boost, up to a full tank, on top of its speed. Planes with no booster get only the speed.

## Later the same day
- Paperclips are now far too strong in play: two hits from two clips fold most planes. Options went to Alan.
- Tab should show the live standings during a match. Plan went to Alan.
- Refill Lift removed from the desk: landing already fills Lift and Boost.
