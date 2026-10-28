# HANDOFF — 2026-10-28 — Load lane: streaming back on (phone sharp at once, 59 s); repack tried and reverted

**Labels:** kind=infra · lane=load · branch=main · issues= · areas=src/client/Loading.luau, src/server/LoadLog.luau, serve.project.json, assets/models/*/parts, docs/plan/LOAD-PLAN.md
**Time:** 2026-10-28 01:10 -04:00

★ START HERE: Goal (Alan): a phone fresh join fully loaded in 30 s at most, looking the same. Opening action: dig
into why the repacked town used ~575 MB of picture memory on the phone (today's town ~70 MB), measuring in Studio one
building at a time (`Stats:GetMemoryUsageMbForTag(Enum.DeveloperMemoryTag.GraphicsTexture)`). Done when the cause is
known and a fix is shown in Studio. No phone test for the small changes waiting in Studio (Alan 2026-10-28: "im not
testing it on my phone for that"); they ride along with the next real gain.

> Read on demand: AGENTS.md → THIS → `docs/plan/LOAD-PLAN.md` (last 8 Progress bullets) → `docs/workshop/lessons.md`
> (loading lessons). Memories: alan-does-play-checks, studio-not-drawing, studio-play-is-shared.

## STATE (verify before acting)
- HEAD `459ddecc` + this handoff on main (the commit hook copies to GitHub). `git log --oneline -3`.
- Docs checker OK (134): `python tools/check_docs.py`. Unit suite not run (only loading code changed).
- Studio: cloud place open, NOT Rojo-connected. Its Loading/LoadLog equal HEAD's files (checked by length after each
  patch: Loading 19389 bytes, LoadLog 2129). workspace.StreamingEnabled = true. Buildings = today's `parts/` records
  (checked per building by hash; bell-tower has 1 piece more than its records, older, untouched). The 41 swapped-back
  buildings got fresh SurfaceAppearances (Studio rebuilt their packs; they draw fine).
- Published: v390 = repacked town (live now, ~575 MB picture memory). Alan should publish soon to replace it.
- Phone joins today (`docs/playtests/2026-10-28-phone-joins.md`): v364 91.3 s, v367 88.7, v368 59.3 (sharp 0.8 s,
  menus 4.4), v390 58.9.
- Cost this session: 2 Sonnet helpers (building swap + photos ~373k tokens / 68 min; swap back ~245k / 25 min);
  ~14 short Studio Plays; 3 web searches; no uploads by me (Studio auto-made picture packs for swaps); ~5 h;
  primary context ~42%.

## NEXT ACTION + PLAN
1. **Repack memory (Alan: keep digging, not parked).** Facts: v368 (today's town) texture ~70 MB, v390 (41 repacked)
   ~575 MB on the phone; repack uploads already went through `town_toys.py send` (half-size bump/shine, shared flat
   maps), so that is NOT the cause. Ideas to test: a 2048 sheet stays at full size whenever any of its 4 pieces is near;
   colour sheets 2048 vs today's 1024 per piece; mip/streaming differences. Measure in Studio
   (`Stats:GetMemoryUsageMbForTag(GraphicsTexture)`) swapping one building at a time, before any phone test.
   Also open: open-book-hall repacked sheet draws grey/metallic; notebook-tower repacked bump flattens shading.
2. Then the next lever toward 30 s: the town's ~3,000 files take ~25 s on the phone (rug toys 262, rug 284, decor 142
   are smaller candidates).
- Studio holds two untimed changes (no second pass over the town, ~15 s on v368's numbers; planes before the town).
  Alan won't phone-test them alone: bundle them with the next real gain into one publish + phone join. The live build
  (v390) still has the repacked town (~575 MB); suggest Alan publish the open Studio when convenient to replace it.
- Stop rule: a change ships when a phone join shows it faster (Studio/PC timings misled three times today).
HOLDS (Alan's go, each): publish, Save to File, any upload, desktop control, Meshy, anything paid, real product
IDs/prices, sales on, Studio Play while he plays. Standing OK: close/reopen Studio and the windowless Roblox app for
cold tests, move the cache aside, delete test cache copies (keep 20261025-192017).

## DECISIONS & WHY (this session)
- `serve.project.json` StreamingEnabled false -> true: Rojo serve had silently turned streaming off, so every phone got
  the whole town at join (the 35 s blur and most of the wait). `LoadLog` now marks "STREAMING OFF" joins.
- Menu pictures go on screen (KeepDrawn) only when their queue turn comes: drawn things are fetched at once by Roblox.
- Phones wait for the menus before the town is sent (v358 order); PC keeps the overlap.
- Town's share of the bar follows `ContentProvider.RequestQueueSize` (Roblox fetches the town itself); 60 s cap.
- Free line (up to 6 s after the loading screen) kept: costs ~0.5 s when nothing waits.
- Repack: 41 buildings approved by Alan on photos, published, then reverted (no faster, memory 8x). Alan: dig into why.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md; decisions 2026-10-25-fast-phone-loading, 2026-10-10-no-quality-cuts-for-fps.

## CARRY NOTES / GOTCHAS
- Studio draws many town pictures soft after long sessions (memory): compare only freshly loaded pictures.
- Pushing code to the unlinked Studio: patch `Source` by exact-substring swaps and check the byte length against the
  file (`wc -c`); `cold_cache.py push` makes a 16 KB paste.
- `swaplua` keeps an old SurfaceAppearance when the colour id matches; to force fresh pictures replace
  `if not old or old.ColorMap~=` with `if true or old.ColorMap~=`.
- `.planning/repack-swap/` has the before/after photos (results.jsonl, page-1..5.jpg). Repacked records still in
  `*/repacked/`; `parts/` is today's (revert fb176826).
- Console "Asset type does not match" lines are old sound ids (Audio.luau), not new.

## WHAT SHIPPED / OTHER QUEUED
- 29c7cd7d Loading: menu pictures go on screen only when their turn comes; phones get the town after the menus
- 36ea8a16 Load recorder: frame rate and picture memory every 2.5 s while loading
- a0e12e65 Loading screen gets a free download line first (up to 6 s); recorder logs files waiting
- 43741a37 Streaming back on: Rojo serve had been turning it off; load log flags it
- 1a1677b4 Loading: no second pass over the town; the bar follows Roblox's own download line
- c77417e1 Load notes: repack Roblox-side check, town file counts
- 6fcbd258 Load notes: 41 repacked buildings swapped into the Studio copy after before/after photos
- 7bbae06e Town: 41 buildings use their repacked pictures (later reverted)
- fb176826 Revert of 7bbae06e
- 459ddecc Loading: plane pieces asked for all at once before the town; repack reverted, notes
- + this handoff (docs check-up). Queued (other lanes): screen fit 3-6, iPhone/iPad re-check, prices, drawing pass.

## KNOWLEDGE UPDATED
- plan/LOAD-PLAN: progress bullets for v364-v390, streaming cause, repack check/revert.
- decisions/2026-10-25-fast-phone-loading: repack approved, reverted; Alan: keep digging; planes yes.
- playtests/2026-10-28-phone-joins (new, in README). systems/performance "Where it stands" 2026-10-28.
- workshop/lessons: drawn things fetched at once; Rojo serve settings ship; fewer files is not faster.
- state/STATE.md rewritten top. Checker OK (134).

## POINTERS
- `src/client/Loading.luau` (`run`: free line, show/keepDrawn, planes burst, town watcher), `src/server/LoadLog.luau`,
  `serve.project.json`, `tools/town_toys.py` (`swaplua`, `send`), `.planning/repack-swap/`,
  `.planning/notebook-today-vs-repacked.jpg`, `.planning/clock-today-vs-repacked.jpg`.
