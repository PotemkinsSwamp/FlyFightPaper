# HANDOFF — 2026-10-27 — Load lane: PC cold 16 s, phone ~58 s; Alan's 30 s plan (nonstop downloads, checked repack, shared cork board)

**Labels:** kind=infra · lane=load · branch=main · issues= · areas=src/client/Loading.luau, src/first/LoadingFirst.client.luau, src/first/UISheets.luau, src/first/UIAssets.luau, tools/ui_sheets.py, tools/upload_texture.py, tools/town_toys.py, assets/ui/sheets, docs/plan/LOAD-PLAN.md
**Time:** 2026-10-27 18:50 -04:00

★ START HERE: Goal (Alan): a phone fresh join fully loaded in 30 s at most, looking the same. Opening action: step 1,
nonstop downloading in `src/client/Loading.luau` (8 at a time on phones too; one queue for the whole load instead of
steps that each wait for their slowest file; don't wait on stuck plane pieces). Prove it with a cold Studio test
(`tools/cold_cache.py`), then Alan publishes + phone fresh join. Done when the phone's `LoadLog.recent()` "done" time
drops well below 58.6 s and the loading screen is sharp within a few seconds.

> Read on demand: AGENTS.md → THIS → `docs/plan/LOAD-PLAN.md` (last 3 Progress bullets) →
> `docs/decisions/2026-10-25-fast-phone-loading.md` (last 3 bullets) → `docs/workshop/lessons.md` (loading lessons).
> Memories: alan-does-play-checks, studio-not-drawing, look-at-textures-before-upload, assembled-preview-before-upload.

## STATE (verify before acting)
- HEAD `cef0cfdb` + this handoff on main, pushed (hook copies to GitHub). `git log --oneline -3`.
- Docs checker OK (133). Unit suite not re-run (only loading/menu art code changed).
- Studio: cloud place open, NOT Rojo-connected; it holds HEAD's loading code (pushed with `cold_cache.py push`) and
  the ORIGINAL town (repack swapped in, then back: all 43 buildings on `parts/` pieces, 2,076 packs OK).
- Published: v358 = menus sized for 1080 + art-first + 3-at-a-time phones, WITHOUT 826485a5 (preload at real size).
  The open Studio has 826485a5; Alan has not published it yet.
- Last phone fresh join (v358): loading screen "ready" 2.5 s but blurry until ~35 s, menus 35.5, all 58.6 s.
  Real PC cold (v335): Skip 5.3 s, all 16.3 s.
- Cache backup: `%LOCALAPPDATA%\Roblox-cache-aside\20261025-192017` = Alan's ORIGINAL cache (keep). Test copies deleted.
- Cost this session: no subagents; ~15 Studio Plays; 3 rounds of free menu uploads (15, 14, 13 files; only the last
  13 are used); 1 web search; ~2 days wall clock with breaks; primary context ~45%.

## NEXT ACTION + PLAN (Alan's order, 2026-10-27)
1. **Nonstop downloading** (free, no look change). Evidence: phone throughput was ~2.2 MB/s at 8 at a time, ~1 MB/s
   at 3 at a time (my change, undo it). Check: cold Studio test, then Alan's phone join (bundles 826485a5 too).
2. **Repacked town, checked:** every building's blacked-out ("hidden underside") areas compared against the old maps;
   bad ones fixed and re-uploaded; close-ups of fixed buildings for Alan before it ships. Known bad: notebook tower
   `11-roof-back-left` (a visible lined-paper strip became flat grey). Alan asked Codex to do the comparing (his
   ChatGPT plan). Swap in Studio: `town_toys.py swaplua FOLDER` (back: `swaplua FOLDER parts`), slow batches, then
   `packs.lua`-style check (SerializeInstancesAsync shows "TexturePack"). Studio must be in front to draw/download.
3. **One shared cork board** for the cork-board menus (main menu, Training, hangar shelf; ~12 MB of backgrounds):
   side-by-side previews, Alan's OK, then upload.
- Not now (Alan): town pictures sized to viewing distance.
- Stop rule: a change ships when the cold test shows it faster and screenshots match; no review rounds.
HOLDS (Alan's go, each): publish, Save to File, any upload, desktop control, Meshy, anything paid, real product
IDs/prices, sales on, Studio Play while he plays. Standing OK: close/reopen Studio and the windowless Roblox app for
cold tests, move the cache aside, delete test cache copies (keep 20261025-192017).

## DECISIONS & WHY (this session)
- Goal is the WHOLE load faster, not Skip sooner (Alan): moving work after Skip doesn't count.
- Menu pieces sized for 1080 screens (`ROOM` 1.0 in `ui_sheets.py`); 21 unused menu pictures dropped.
- Stuck requests get a flat time limit (town groups 12 s): one group once held the PC 45 s.
- Loading-screen art preloads alone and at real size: a phone fetched 8x8 copies and showed them blurry.
- Repack ships only after the building-by-building check (it hid a visible strip once).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md; decisions 2026-10-10-no-quality-cuts-for-fps, 2026-10-25-fast-phone-loading; memories above.

## CARRY NOTES / GOTCHAS
- Studio only draws/downloads while in front: blank or grey screenshots = ask Alan to bring it forward; wait for
  `ContentProvider.RequestQueueSize` 0 before judging.
- A Studio cold test refills the cache: clear it again right before Alan's join (one join was timed warm).
- `ready/` files can differ from Roblox's copy: compare online pixels before building from them (lessons.md).
- Shop index cards appear a few seconds after opening the shop (not preloaded as sheets? check in step 1).
- Earlier uploads unused: first 15 and second 14 menu files (records overwritten; ids in git history).
- Stray untracked `tools/art/hero.py.old`; old untracked `.planning` files from before.

## WHAT SHIPPED / OTHER QUEUED
- 0fc0ce73 Loading: a stuck town group costs 12 s, not 48 s
- 487fd7b3 Menu sheets tool
- 12596565 Menus: 21 unused pictures no longer downloaded; sheet tool shrinks pieces
- e44058e0 Menus load as 46 files (~39 MB) instead of 128 (~60 MB), same look
- 140e7862 Real-PC cold join: Skip 5.3 s, everything 16.3 s
- 21595d22 Loading screen art alone first; phones menus 3 at a time (to undo in step 1)
- db93944d Menus sized for 1080; results pieces rebuilt from Roblox's pixels; upload tool waits for the id
- 5cf6b326 Repacked town held back; swap tool can swap back
- 6b84883e Decision: whole load faster; repack checked first
- 826485a5 Loading screen art preloads at real size (unpublished)
- cef0cfdb Decision: 30 s phone target and plan
- + this handoff (performance page status). Queued (other lanes): screen fit 3-6, iPhone/iPad re-check, prices, drawing pass.

## KNOWLEDGE UPDATED
- plan/LOAD-PLAN: night + late Progress bullets. decisions/2026-10-25-fast-phone-loading: night, late, 10-27 bullets.
- workshop/lessons: Studio cold refills cache; ready/ vs online pixels; phone fetches only as sharp as drawn.
- workshop/tools: ui_sheets.py row. systems/menus-and-hud: UISheets row. systems/performance: Where it stands.
- STATE top rewritten (late). Checker OK (133).

## POINTERS
- `src/client/Loading.luau` (`run`, `preload(items,size,slots,limit)`), `src/first/LoadingFirst.client.luau` (`fit`,
  KeepDrawn), `tools/ui_sheets.py`, `tools/town_toys.py swaplua`, `assets/models/*/repacked/repack.json`.
