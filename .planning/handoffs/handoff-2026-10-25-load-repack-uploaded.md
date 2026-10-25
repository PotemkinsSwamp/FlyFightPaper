# HANDOFF — 2026-10-25 — Load steps 1-2 built (menus first, load recorder); step 3 repack uploaded and approved, swap waits for Alan's phone test

**Labels:** kind=infra · lane=load · branch=main · issues= · areas=src/server/FlightService.luau, src/server/LoadLog.luau, src/client/Loading.luau, src/client/Bootstrap.client.luau, src/client/MenuController.luau, tools/art/repack.py, tools/town_toys.py, assets/models/*/repacked, docs/plan/LOAD-PLAN.md
**Time:** 2026-10-25 15:36 -04:00

★ START HERE: Goal (Alan): a phone joins in under a minute (seconds ideally) and looks exactly the same. Opening
action: read Alan's fresh-join numbers (`require(game.ServerScriptService.FlyFightPaper.LoadLog).recent()` in the
Server VM during Play) once he has published steps 1-2 and joined; then swap the repacked town into the open Studio
copy. Done when his next fresh join (after the swap is published) shows menus in seconds and the whole load is
under a minute, and close-ups match today's look.

> Read on demand: AGENTS.md → THIS → `docs/plan/LOAD-PLAN.md` (Progress, last 4 bullets). Lessons: lessons.md
> "Studio and the place file" (exact collision, compare looks in the same spot, 2048). Memories:
> alan-does-play-checks, studio-play-is-shared, studio-not-drawing, look-at-textures-before-upload, exact-collision-baked.

## STATE (verify before acting)
- HEAD `0d82d854` + this handoff on main; commit hook pushes to GitHub. `git log --oneline -3`.
- Docs checker OK (133): `python tools/check_docs.py`. Unit suite 425/0 (2026-10-25, after step 1):
  `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()` in the Server VM.
- Studio: the cloud copy (placeId 132768925825316) is open in Edit with steps 1-2 synced by Rojo, `StreamingEnabled`
  on and Arena/CityRug `PersistentPerPlayer` set in Edit; NOT yet published (Alan's go). No test models left.
  Local `FlyFightPaper-WORKING.rbxlx` NOT rebuilt this session (`default.project.json` now has StreamingEnabled=true).
- Repack: 440 pieces + 356 pictures uploaded, all Approved (checked via Open Cloud, not "Reviewing"); every new
  shape's size equals its old piece. Records in `assets/models/*/repacked/*.upload.json`, NOT copied over `parts/`.
- Cost: 2 Codex runs via codex-rescue (~35k + ~44k subagent tokens; Codex ~23 + ~36 min on Alan's ChatGPT plan),
  1 web-fetch agent (~60k), ~830 free uploads, 2 Claude Play runs, local Blender runs; ~11.5 h wall clock with waits;
  primary context ~40% at handoff.

## NEXT ACTION + PLAN
1. **Alan publishes + fresh phone join** (his go; his first step). Read `LoadLog.recent()`: phases are game in / main
   menu / menu pictures / town arrived / preloaded / done (seconds from the first ReplicatedFirst script).
2. **Swap the repacked town live in the Studio copy** (after step 1's test, so the tests don't mix). Per CityToys part
   `building/stem` with a repacked record: `AssetService:CreateMeshPartAsync(mesh, {CollisionFidelity=Precise…})` +
   `ApplyMesh` (this recomputes exact collision), fresh SurfaceAppearance with the record's 4 map ids. Packs: Studio
   makes them per new SA and Roblox throttles (429): go in slow batches. Check: same-spot close-ups of 3 buildings
   old vs new (~1/255), Play FPS, a tunnel raycast check on the monorail stations (lessons.md).
3. Alan saves (Ctrl+S, then **Save to File** = his go) → copy repacked records over `parts/*.upload.json`, `town_toys.py
   packs`, `build v4`, `save_place.py` (check its PRECISE_HEADER test). Alan publishes; fresh join; LoadLog numbers.
4. Then the UI lane: small iPhone + iPad re-check (Alan switches devices), screen fit steps 3-6.
Stop rule: each step done when its check passes and Alan has seen it on his phone; no review rounds.
HOLDS (Alan's go, each): publish, Save to File, closing Studio, desktop control, Meshy, anything paid, real product
IDs/prices, sales on, Studio Play while he plays, any upload beyond step 3's (step 3's are all done).

## DECISIONS & WHY (this session)
- Step 1 holds back the whole room (Arena + CityRug), not just buildings: the menus are 2D, and every client module
  after `Menu.start` waits for the town, so no client code runs on a half-sent room (no per-module audit fixes).
- Runtime workspace things made `Persistent` (planes, SpeedPickups now a Model, RangeStage): there is no character or
  ReplicationFocus, so non-persistent parts would never stream in.
- Repack = whole-pixel island moves only (no scale/turn): every texel byte-identical, normals stay valid. The gain is
  files (1,893 → 732), not pixels (old packing was already tight; −4.8% pixels only because last sheets fit size).
- 111 pieces keep their own maps (sharing would add pixels, or one too big); bell tower + sweet shop left out
  (moderation caution, same as the smaller-maps round). In STATE "Decisions to review".
- Big black areas on new sheets are hidden undersides already in approved pictures; judged safe on contact sheets.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md; decisions 2026-10-10-no-quality-cuts-for-fps, 2026-10-25-fast-phone-loading; memories above.

## CARRY NOTES / GOTCHAS
- Studio draws nothing while behind other windows (RenderStepped 0/s, captures time out); ask Alan to bring it front.
- Compare looks at the same spot: copies 300 studs apart drew visibly darker/brighter (cost an hour's detour).
- One FBX upload was refused once (milk-carton-tower 10-roof-front-right) and went through on retry; reason lost
  (retry overwrote the saved operation). Next refusal: read `upload-tmp.json` before retrying.
- Repacked PNG/FBX are gitignored (remake byte-for-byte with `tools/art/repack.py`; deterministic, checked).
- `town_toys.py readlua/meshes` now accept `FOLDER/repacked`; a localhost helper fed Studio the id lists (scratch, gone).
- Stray untracked `tools/art/hero.py.old` (2026-10-16, not this session). Workspace has stray Creator Store bits
  (HorseDragoon, "meme toy", "ungroup pibble"); the server deletes them at start; Alan's to keep or remove.
- Console "Asset content representation is being generated" lines at Play are old noise (AssetLoadFailures ~176).

## WHAT SHIPPED / OTHER QUEUED
- 44557094 Menus first: streaming on, the town is sent to each player once their menu pictures are in; Play waits for it
- 1cb03b37 Load recorder: each join's loading times and device are saved, readable in Studio
- 6e191e66 STATE: load steps 1-2 built, waiting on Alan's publish
- 864595b6 Repack tool: a building's pieces share 2048 picture sheets, same pixels; clock tower pilot uploaded
- d51713ca Repack: last sheet sized to fit, pieces that would grow stay as they are; plans for 45 buildings
- 7aef5ab9 Load step 3: repack planned for 45 buildings, contact sheets checked; waiting on a close-up in Studio
- 55a90d02 Repack look check: Roblox keeps 2048 pictures; repacked clock tower looks the same as today's
- cc2915b8 Repacked town uploaded: 440 pieces and 356 shared pictures, all approved; swap waits for Alan's step-1 test
- 0d82d854 STATE: repacked town uploaded, swap after Alan's step-1 test
- + this handoff. Queued (Alan's): stick tuning; winners' sound check; prices; drawing pass; touch step 6 publish.

## KNOWLEDGE UPDATED
- systems/performance: streaming/menus-first paragraph, Loading + LoadLog code rows. plan/LOAD-PLAN: progress for
  steps 1-3. workshop/tools: `repack.py` row, `town_toys repack`. workshop/lessons: +2 (same-spot compare; 2048 kept,
  EditableImage reads ≤1024). STATE rewritten top. Checker OK (133).

## AAR
Supposed: build steps 1-3 in order. Actual: 1-2 built and tested; 3 built, checked and uploaded, swap held for Alan's
test. Why: 2048 retention was unknown and Studio wasn't drawing; a same-spot lighting trap cost a detour. Next time:
render checks place both copies at one spot from the start; read a refused upload's operation before retrying.
Cost matched output (two Codex runs did the heavy tool work off Claude usage).

## POINTERS
- `src/client/Loading.luau` (`waitTown`, `town`, `ready`), `src/server/FlightService.luau` (`sendTown`),
  `src/server/LoadLog.luau`, `tools/art/repack.py`, `tools/town_toys.py` (`repack`), `tools/exact_collision.lua`,
  `.planning/repack-clock-tower-old-vs-new.jpg`.
