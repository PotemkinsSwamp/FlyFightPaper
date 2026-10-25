# HANDOFF — 2026-10-25 — Load lane: loading rebuilt in Alan's order; cold-PC tests work; menus (~150 files, ~51 MB) are the wall

**Labels:** kind=infra · lane=load · branch=main · issues= · areas=src/client/Loading.luau, src/first/LoadingFirst.client.luau, tools/cold_cache.py, tools/town_toys.py, tools/upload_texture.py, docs/plan/LOAD-PLAN.md
**Time:** 2026-10-25 19:58 -04:00

★ START HERE: Goal (Alan): a phone gets to a working menu in ~10 s and everything loads as fast as possible, looking
exactly the same. Opening action: ask Alan to publish the build in the open Studio (HEAD has menus 8-at-a-time + plane
2 s limit; Studio has it pushed in), clear the cache (`python tools/cold_cache.py aside`, Studio + Roblox app closed),
he joins on the PC from the website, read `LoadLog.recent()` (reopen Studio: `cold_cache.py open`). Done when the
real-PC "menus" time is known (last: 28 s at 4-at-a-time; Studio predicts ~10 s).

> Read on demand: AGENTS.md → THIS → `docs/plan/LOAD-PLAN.md` (last Progress bullet) → `docs/workshop/lessons.md`
> (PreloadAsync, KeepDrawn, smaller files, cold-load timing). Memories: alan-does-play-checks, studio-play-is-shared,
> look-at-textures-before-upload, assembled-preview-before-upload.

## STATE (verify before acting)
- HEAD `c75e8b82` on main, pushed (hook copies to GitHub). `git log --oneline -3`. Docs checker OK (133).
- Unit suite not re-run this session (only Loading/LoadingFirst/tools changed): `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()` in Server VM.
- Studio: cloud copy open (id changes every reopen: `tools/studio_cli.py list_roblox_studios '{}'`), NOT Rojo-connected
  (reopened by script); HEAD's two loading files pushed in with `cold_cache.py push`. Published: v326 (= HEAD minus c75e8b82).
  Rojo server runs on 34872 (Alan clicks Connect in the plugin after a manual reopen).
- Studio MCP tools vanished from the session mid-way; `python tools/studio_cli.py TOOL '{json}'` works (lessons).
- Cache backups: `%LOCALAPPDATA%\Roblox-cache-aside\20261025-192017` = Alan's ORIGINAL cache (3.3 GB, keep);
  `20261025-195425` = a test leftover (Alan OK'd deleting test leftovers).
- Cost: 1 web-fetch agent (~43k tokens); ~14 Studio Play / cold runs; 2 free test uploads (ids 121039818785131,
  131542721558510, unused); `imagequant` pip package installed; ~4.3 h wall clock; primary context ~40%.

## NEXT ACTION + PLAN
1. Alan publishes + cold PC join (above). Then a phone fresh join only if the PC numbers show a big step.
2. Cut the menus before Skip (agreed with Alan, previews first, upload = his go): (a) **sheets**: pack small menu pieces
   into a few 1024 sheets (ImageRectOffset/Size; check the Android rect bug report, padding) — fewer files is the PC
   win; (b) **fewer pixels**: right-size (~15%), one tinted strip/sticker, shared/tiled boards (~15 MB, a look change:
   side-by-sides). Measure each with a cold Studio test (`$TEMP`-style one-shot script: aside → open → push → Play →
   read LoadTimes) before asking Alan to publish.
3. Light loading screen: ON HOLD (real app shows it in 0.8-1.3 s on PC). Preview exists (`.planning/light-loading/compare-v4.jpg`: close, grain softer in light stripes, only ~40% fewer board pixels). Phone may still need it.
4. Then the repacked-town swap (`town_toys.py swaplua FOLDER`, previous handoff's step 2-3), then iPhone/iPad re-check, screen fit 3-6.
Stop rule: a change ships when the cold test shows it faster and looks unchanged; no review rounds.
HOLDS (Alan's go, each): publish, Save to File, any upload, desktop control, Meshy, anything paid, real product IDs/prices,
sales on, Studio Play while he plays. Standing OK this session: close/reopen Studio and the windowless Roblox app for
cold tests, move the cache aside, delete test cache leftovers (keep 192017).

## DECISIONS & WHY (this session)
- Alan's loading order + safe Skip + "cold PC tests, not phone reinstalls": decisions/2026-10-25-fast-phone-loading.md (evening bullet).
- Menus 8 at a time, town 40 x 6: real PC was latency-bound (~0.7 s/file at 4), phone slower at 12 (town 49 s vs 27 s).
- Plane pieces in ReplicatedStorage never report back from PreloadAsync: 2 s limit each (8 s for other files).
- KeepDrawn: first screens' labels kept drawn at 0.99 transparency (Roblox staff: undrawn preloads get collected); not all menus (memory on phones).
- Skip waits for every menu + town parts (Alan); the town's pictures load after Skip.
- No JPG/palette PNGs: Roblox re-stores uploads as its own PNG (255 KB JPG → 975 KB). Lesson recorded.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md; decisions 2026-10-10-no-quality-cuts-for-fps, 2026-10-25-fast-phone-loading; memories above.

## CARRY NOTES / GOTCHAS
- Studio cold has a ~5-6 s start-up wait before any first picture; the real app doesn't. Studio Edit warms the town's files.
- Alan's Roblox app lingers windowless after a join; `cold_cache.py aside` refuses until it's closed.
- Bar text: Alan said the bar "didn't move for 30 s" on PC at 4-at-a-time; check it moves visibly with 8.
- `upload_texture.py` now sends JPG as image/jpeg (harmless; JPG doesn't help).
- Stray untracked `tools/art/hero.py.old`; old untracked .planning files from before (not this session's).

## WHAT SHIPPED / OTHER QUEUED
- d0f6732c Swap tool: puts a building's repacked pieces in place in Studio, same size and spot
- b65421b0 Loading screen and menu pictures really load first: they go in as picture labels, not id text
- 9bf3becc Lesson: PreloadAsync needs picture labels, not id text
- d855fb3b Loading in strict order: loading screen art, main menu, town; other screens after
- ae60dfa4 Loading order: loading screen art, then every menu's pictures, then the town
- f91c349e Loading: each step finishes before the next (45 s stall cut), menus in small batches; recorder notes cut steps
- 4defb0bc Loading: every menu first in the order players meet them, files side by side; Skip only once town parts are in, with a note
- 63b17409 Loading screen and main menu pictures stay drawn until the menu is up
- 1b8aea46 Cold-load test tool
- 3d16e753 Cold tests: push code into a reopened Studio; recorder notes the download queue
- e32e965c Loading: fewer files at once; recorder notes the slowest loading-screen file
- c75e8b82 Loading: menus 8 at a time; plane pieces cost 2 s, not 8
- + this handoff (docs: decision evening bullet, LOAD-PLAN progress, lessons x2 more, STATE top). Queued: repack swap; previous lanes' items.

## KNOWLEDGE UPDATED
- decisions/2026-10-25-fast-phone-loading: evening rulings. plan/LOAD-PLAN: evening progress + numbers. systems/performance:
  loading order + Code rows. workshop/lessons: +5 (id text, list fetch + stuck pieces, smaller files, KeepDrawn, cold timing).
  workshop/tools: cold_cache.py row, town_toys swaplua. STATE top rewritten. Checker OK (133).

## POINTERS
- `src/client/Loading.luau` (`run`: MENUS/WORLD lists, `preload(items,size,slots,limit)`), `src/first/LoadingFirst.client.luau`,
  `tools/cold_cache.py`, `.planning/light-loading/`, measurement script logic in this handoff's plan step 2.
