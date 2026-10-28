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
- Evening, after more phone joins (1 min 45 s at worst): loading order is the loading screen's own art first (it
  shows complete, never a bare brown board), then every menu's pictures in the order a player meets them, then the
  town. Skip only at a safe point: all menu pictures and the town's parts in, with a note that grey buildings fill
  in. Menus stay real-looking pictures (no code-drawn boxes); cut their weight with right-sizing, one tinted strip,
  shared boards and sheets, side-by-sides before any upload. Test changes with a cold PC cache
  (`tools/cold_cache.py`), not a phone reinstall each time; the phone confirms the big steps.
- Night: shrink every menu piece that looks the same smaller (not only the worst), then upload sheets and shrunk
  pieces together and test once. Result on the real PC, cold: Skip at 5.3 s (was 23.6), everything 16.3 s.
- Late: the goal is the whole load faster, not Skip sooner (putting everything after Skip is not the answer). Menu
  pieces sized for 1080 screens. The repacked town ships only after every blacked-out area is checked against the
  old pictures (Codex compares and fixes; close-ups for Alan before it ships).
- 2026-10-27: target 30 s at most for the whole phone load. Do, in order: (1) nonstop downloading (8 at a time on
  phones too: 3 at a time halved phone throughput; one queue for the whole load, no waiting on stuck plane pieces);
  (2) the checked repacked town; (3) one shared cork board for the cork-board menus (previews first). Not now: town
  pictures sized to viewing distance (would reverse "colour maps full size").

## Why
On Alan's phone the menus showed words without paper for a minute and the full load took about 2 minutes, even with
files already on the phone; "I've seen mobile games with more advanced maps and menu UI and theirs loads no problem."

- 2026-10-27 (later): no shared cork board (Alan): the main menu's board can't stand in for the hangar or Training
  boards without looking odd, and one picture fewer saves little. Instead: why are menu pictures megabytes? (PC cache:
  menus arrive as PNG, ~1.1 MB a board tile; the town's pictures arrive GPU-compressed, KTX2 BC1/BC3 + zstd.)

- 2026-10-27 (night): menu boards as 3D pictures approved (Alan): "they just look a lower resolution, which is fine"
  (cork grain 23-34% softer close up, ~7x smaller downloads). The pieces on top stay menu pictures for now.

## Affects
- [Load plan](../plan/LOAD-PLAN.md) · [Performance](../systems/performance.md) · [Never trade looks for frame rate](2026-10-10-no-quality-cuts-for-fps.md) (looks unchanged: checked side by side)
