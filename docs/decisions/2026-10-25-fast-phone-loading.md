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

## Why
On Alan's phone the menus showed words without paper for a minute and the full load took about 2 minutes, even with
files already on the phone; "I've seen mobile games with more advanced maps and menu UI and theirs loads no problem."

## Affects
- [Load plan](../plan/LOAD-PLAN.md) · [Performance](../systems/performance.md) · [Never trade looks for frame rate](2026-10-10-no-quality-cuts-for-fps.md) (looks unchanged: checked side by side)
