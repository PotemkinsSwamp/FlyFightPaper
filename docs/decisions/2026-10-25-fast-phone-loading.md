# Fast phone loading: menu first, Skip, smaller bump and shine maps

**Decided:** 2026-10-25 (Alan)  
**Status:** in force

## Decision
- Loading waits only for the menu's pictures, then offers Skip; the rest keeps loading behind the menu. Target:
  everything loaded in under a minute on a phone, seconds ideally ([load plan](../plan/LOAD-PLAN.md)).
- The progress bar is the true share of what has finished.
- Building bump (normal), roughness and metalness maps go to half size, and flat one-colour maps are shared or
  dropped; colour maps stay as they are. Approved after before/after close-ups of 3 buildings
  (`.planning/load-maps-before-after.png`: under 1 shade in 255 different on average). Upload the whole town,
  checked on contact sheets.

- Later the same day, after a fresh-join phone test (44.9 s with no paper art, then 1 min 2 s more): (1) menus first
  for real: streaming on, the town sent to each player whole once their menu is up (PersistentPerPlayer), Play waits
  for the town if it isn't there yet; (2) a load recorder so every join's times are saved; (3) repack the town's
  picture sheets tighter (same sharpness, no look change), not half-size colour. Alan: do them in order, keep working
  until all are done.

## Why
On Alan's phone the menus showed words without paper for a minute and the full load took about 2 minutes, even with
files already on the phone; "I've seen mobile games with more advanced maps and menu UI and theirs loads no problem."

## Affects
- [Load plan](../plan/LOAD-PLAN.md) · [Performance](../systems/performance.md) · [Never trade looks for frame rate](2026-10-10-no-quality-cuts-for-fps.md) (looks unchanged: checked side by side)
