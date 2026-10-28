# HANDOFF — 2026-10-27 — Load lane: menus drawn as 3D pictures (Studio cold 19.3 s); waiting on Alan's publish + phone join

**Labels:** kind=infra+ui · lane=load · branch=main · issues= · areas=src/client/Loading.luau, src/first/MenuArt.luau, src/first/BoardPlate.luau, src/first/LoadingFirst.client.luau, src/client/PaperUI.luau, src/first/UISheets.luau, tools/ui_sheets.py, tools/art/repack_compare.py, assets/ui/sheets, docs/plan/LOAD-PLAN.md
**Time:** 2026-10-27 21:10 -04:00

★ START HERE: Goal (Alan): a phone fresh join fully loaded in 30 s at most, looking (almost) the same. Opening action:
ask Alan for his phone fresh-join times on the build he publishes from the open Studio (bar moving / loading screen
sharp / all loaded), then read his join in Studio (`require(game.ServerScriptService.FlyFightPaper.LoadLog).recent()`,
Server VM, during Play). Done when the phone's "done" is well below 58.6 s (v358) and the menus work on the phone.

> Read on demand: AGENTS.md → THIS → `docs/plan/LOAD-PLAN.md` (last 4 Progress bullets) →
> `docs/decisions/2026-10-25-fast-phone-loading.md` (last 3 bullets) → `docs/workshop/lessons.md` (loading lessons).
> Memories: alan-does-play-checks, studio-not-drawing, look-at-textures-before-upload, studio-play-is-shared.

## STATE (verify before acting)
- HEAD `5377a74a` + this handoff on main (the hook copies each commit to GitHub). `git log --oneline -3`.
- Docs checker OK (133): `python tools/check_docs.py`. Unit suite not re-run (only loading/menu drawing code changed).
- Studio: cloud place open, NOT Rojo-connected (normal for this lane); all 96 scripts checked equal to HEAD's `src/`
  (the check script: build per-file byte counts from `git show HEAD:<file>`, compare `#Source` minus CR in Edit).
  New modules MenuArt + BoardPlate were created in it by the push. Its cache was refilled by a cold test.
- Published: v361 = one queue at 8 on phones, WITHOUT the 3D menus. Alan publishes the open Studio next.
- Phone v361: loading screen 1.9 s (blurry until ~42), town arrived 42.0, menus 50.0, all 81.2 s (v358: 58.6).
- Studio cold (`tools/cold_cache.py`): old code 56.5 → one queue 30.0 → + 3D boards 25.9 → + all 3D menu pieces 19.3 s.
- Cache backup kept: `%LOCALAPPDATA%\Roblox-cache-aside\20261025-192017` (Alan's original). Test copies deleted.
- Cost this session: 1 Codex job (forwarder ~38k tokens; Codex on Alan's ChatGPT plan, ~10 min); ~10 Studio Plays
  (4 cold tests, the rest menu-only); 14 free uploads (all Approved); 1 web search; ~3 h; primary context ~43%.

## NEXT ACTION + PLAN
1. **Alan's phone fresh join** on the new publish (above). If faster and the menus work: note it in LOAD-PLAN + STATE.
   If any menu piece is missing/blank/misplaced on the phone: it's in `first/MenuArt` (draw/forget, stretch, ZIndex).
   If still far from 30 s: read the phone's step times; town preload is the next biggest share.
2. **Repacked town, Roblox side:** the repack FILES are clean (Codex, `tools/art/repack_compare.py`, 46 buildings,
   `.planning/repack-check/`); the notebook tower's grey bar came from the Studio swap. Swap only the notebook tower
   (`town_toys.py swaplua assets/models/notebook-tower`), wait for packs, look at the bar's face with Studio in
   front; back with `swaplua ... parts`. Ship the repack only after Alan sees close-ups.
- Shared cork board: dropped (Alan). Town pictures sized to viewing distance: not now (Alan).
- Stop rule: a change ships when a cold test shows it faster and screenshots match; no review rounds.
HOLDS (Alan's go, each): publish, Save to File, any upload, desktop control, Meshy, anything paid, real product
IDs/prices, sales on, Studio Play while he plays. Standing OK: close/reopen Studio and the windowless Roblox app for
cold tests, move the cache aside, delete test cache copies (keep 20261025-192017).

## DECISIONS & WHY (this session)
- Menus drawn as 3D pictures (Alan OK'd, "they just look a lower resolution, which is fine"): Roblox sends a picture
  on a 3D surface GPU-compressed (KTX2 BC1/BC3 + zstd, ~7x smaller for a cork tile) and a menu picture as PNG. The card
  lives only inside the menu's own ViewportFrame; nobody else sees it. Cork grain 23-34% softer up close.
- Only screens never up while flying go 3D (Alan: frame rate matters only in flight): list in `first/MenuArt` and
  `tools/ui_sheets.py` (MENU_GUIS). A piece any flying screen shows stays an ordinary picture, so sheets were
  regrouped (7 menu-only + 5 flying; same pixels) to avoid downloading a sheet in both formats.
- Phones back to 3 downloads at a time (one queue kept): 8 made the phone slower (lessons.md).
- One phone test per batch of changes (Alan: no reinstall for each little thing), so the next phone join measures
  3-at-a-time + 3D boards + 3D pieces together.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md; decisions 2026-10-10-no-quality-cuts-for-fps (Alan OK'd this softness explicitly), 2026-10-25-fast-phone-loading.

## CARRY NOTES / GOTCHAS
- Pushing to a reopened Studio: `cold_cache.py push` needs the script to exist; prepend creating new ModuleScripts.
- Studio stops drawing when behind other windows: identical captures twice = not drawing; test with a marker frame.
- The settings and hangar screens didn't show by toggling `Cover.Visible` from a script (only main menu and Training
  were compared); same code path, but check them in Play on the phone/PC.
- `ui_sheets.py` (build) deletes `assets/ui/sheets/uploads/*.json`; if a build is abandoned, `git checkout -- assets/ui/sheets`.
- `usage.json` was read once in Play; a new menu/HUD piece needs it re-read (labels per ScreenGui) before a rebuild.
- Unused now: the 11 old mixed sheet uploads (ids in git history before 345f6fa1).
- Stray untracked `tools/art/hero.py.old`; old untracked `.planning` files from before.

## WHAT SHIPPED / OTHER QUEUED
- 2a892c8d Loading: one nonstop queue, 8 at a time on every device (Studio cold 56.5 s -> 30.0 s)
- 6e1c8bf2 Repack check tool: every repacked building matches today's pieces in Blender; notebook grey bar is Roblox-side
- 8ec3d47f STATE: load 30 s in Studio cold test, repack files check clean; lesson on 1024 picture reads
- 4cf1d59b Decision: no shared cork board; look at why menu pictures are big instead
- 97af1520 Test: a menu picture drawn as a 3D picture downloads ~7x smaller, nearly the same look
- 0336b41d Menu boards drawn as 3D pictures; phones back to 3 downloads at a time
- 3e97e201 Phone v361 slower (81 s); phones back to 3 at a time; 3D boards cold 25.9 s
- 1759143e Decision: 3D menu boards OK (slightly softer cork)
- 345f6fa1 Menu sheets regrouped: menu-only and flying pieces on separate sheets, sizes for 3D drawing
- a15a8dd7 Menu-only pieces drawn as 3D pictures too (MenuArt)
- 5377a74a Load notes: all menu-only pictures 3D, Studio cold 19.3 s
- + this handoff (docs check-up). Queued (other lanes): screen fit 3-6, iPhone/iPad re-check, prices, drawing pass.

## KNOWLEDGE UPDATED
- plan/LOAD-PLAN: 5 Progress bullets (one queue, repack check, picture formats, phone v361, 3D menus).
- decisions/2026-10-25-fast-phone-loading: no shared cork board; 3D boards OK.
- systems/performance + systems/menus-and-hud: "Where it stands" 2026-10-27; Code rows BoardPlate, MenuArt.
- workshop/tools: repack_compare.py row; ui_sheets.py groups. workshop/lessons: 1024 picture reads; PNG vs 3D
  downloads; phones slower at 8; ViewportFrame ZIndex. Checker OK (133).

## POINTERS
- `src/first/MenuArt.luau` (draw/forget/preload/fetchable), `src/first/BoardPlate.luau`, `src/first/LoadingFirst.client.luau`
  (`fit` calls MenuArt.draw), `src/client/Loading.luau` (`walk`, one queue), `tools/ui_sheets.py`, `assets/ui/sheets/usage.json`.
- Pictures: `.planning/board3d-*` (before/after, zoom), `.planning/menu-3d-test-*`, `.planning/repack-check/`.
