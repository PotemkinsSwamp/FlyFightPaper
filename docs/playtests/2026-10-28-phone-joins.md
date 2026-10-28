# 2026-10-28: four fresh joins on Alan's phone (loading)

## What Alan did
Published each build from Studio and joined fresh on his phone, timing the loading screen; the game's load recorder
(`LoadLog.recent()`) saved each join's step times, frame rate, picture memory and files waiting.

## What he saw
| Build | Loading screen | Fully loaded | Notes |
|---|---|---|---|
| v364 (3D menus) | blurry until 35.5 s | 91.3 s | "it got worse" |
| v367 (crowd fix, free line) | blurry until 35.8 s | 88.7 s | bar moving at 13 s; "didn't get any better" |
| v368 (streaming back on) | sharp at once | 59.3 s | menus 4.4 s; skippable ~10 s |
| v390 (41 repacked buildings) | sharp | 58.9 s | "not sure it was that much faster" |

## What changed because of it
- The blur and most of the wait were streaming switched off by `serve.project.json` (whole town sent at join): fixed.
- Our second pass over the town (15 s) dropped; planes now asked for before the town.
- The repack: fewer files but no faster, picture memory ~70 -> ~575 MB; reverted, cause being dug into
  ([load plan](../plan/LOAD-PLAN.md), [decision](../decisions/2026-10-25-fast-phone-loading.md)).
