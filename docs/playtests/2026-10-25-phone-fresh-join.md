# 2026-10-25: a fresh join on Alan's phone (smaller bump/shine maps)

## What Alan did
Deleted and reinstalled the Roblox app (no game files left on the phone), then joined the published game with the
half-size bump/shine maps and the Skip loading screen.

## What he saw
- 44.87 s on a plain cardboard-coloured screen: the loading words in the crayon font and a plain "Skip", no paper art.
- Then the full loading screen (cork board, title, bar already part-filled, green Skip).
- 1 min 2 s more until everything had loaded. About 1 min 47 s in all: "still way too long".
- In Studio the town looked the same after the smaller maps (Alan).

## What changed because of it
- Cause: the menu's pictures wait in the same download line as the town's ~1,600 files, because the whole town is
  sent at join; asking for them first doesn't move them up the line. Then the town itself is big (colour pictures
  ~470 MB as PNGs, bump/shine ~170 MB, shapes ~90 MB, measured on our source files).
- Plan changed ([load plan](../plan/LOAD-PLAN.md)): menus first by sending the town per player after the menu is up
  (streaming, PersistentPerPlayer), a load recorder, then repacking the town's picture sheets
  ([decision](../decisions/2026-10-25-fast-phone-loading.md)).
