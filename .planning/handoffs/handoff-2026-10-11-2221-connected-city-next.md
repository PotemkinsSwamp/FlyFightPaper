# HANDOFF — 2026-10-11 — Exact collision + fast Play, in-game hangar menu, classroom filled; connected city next

★ START HERE: Goal: a more connected toy city you can fly THROUGH (Alan's playtest ask). First, if Alan has pressed
Ctrl+S since this handoff, harvest packs (`town_toys.py packs` + `build`) for the 3 re-baked buildings + flagpole and
commit. Then build the connected-city plan in `.planning/briefs/2026-10-11-connected-city-kit.md`, starting with a
top-down LAYOUT PREVIEW (bell tower spot, bridges between close neighbours, fly-through ceiling pieces) for Alan's OK.
Done for step 1 when Alan approves the preview; nothing is placed before that.

> Read on demand: AGENTS.md → state/STATE.md → THIS; the brief above. Memories: exact-collision-baked,
> in-game-menus-match-main-menus, texture-packs-after-new-models, rug-layout-review, codex-for-pictures-and-blender.

## STATE (verify before acting)
- HEAD `1293236d` (main). Remote origin exists but main has no upstream; nothing pushed (never pushed before either).
- Tests 222/0 (Play server: `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`).
- Studio: WORKING open (studio_id a0b1ff52-…; `list_roblox_studios`), Edit mode, Rojo serving serve.project.json.
  **Live Studio holds unsaved work:** re-baked Gateway/Garden/Banner (48 pieces, exact collision done) + flagpole on
  the Banner roof. Place file on disk is 19:03 (before that). Repo already records them (toy-placements, uploads).
- Play start ~4 s; 60 FPS client and server with 12 planes (measured this session).
- Codex: all jobs finished (7 this session, Sol); none running. Check: `node ~/.claude/plugins/cache/openai-codex/codex/1.0.6/scripts/codex-companion.mjs status --all`.
- Cost: 7 Codex jobs (menu art [retired], re-bake resume ×2 [1 failed to start], bookshelf+light, wall decor,
  backpack cubby, concept art); 0 Claude subagents; ~245 free Roblox uploads; no Meshy; ~6 h wall clock.

## NEXT ACTION + PLAN
1. (Alan's Ctrl+S) → `python tools/town_toys.py packs FlyFightPaper-WORKING.rbxlx` → `build` → check the 48 new
   pieces + flagpole have TexturePack → commit city-toys.rbxmx + texture-packs.json (+ the place with a STATE commit).
2. Connected city (rulings in the brief, final): layout preview first (read real footprints/roof heights; bridges only
   between close neighbours at matching heights; legs on roofs/grass, never streets; nothing overlaps; lanes kept).
3. On approval: new kit pieces via Codex Blender (ruler-bridge SECTION that repeats with tape over joints, pencil
   stilts, cardboard tube tunnel, fly-through ceiling hoops/rings/hanging tubes) + the big bell tower (~430 tall,
   ~110 ground arch, ~90 open belfry with bell). Exact collision on every piece. Place, Alan Ctrl+S, packs.
4. Then: ~90 texture sets still unpacked, final 8-viewpoint pass for Alan's "approves the look" gate (Stage 4).
- HOLDS (Alan's go, each): private publish; Studio-settings changes; Meshy spend; anything paid.

## DECISIONS & WHY (this session)
- Exact collision = PreciseConvexDecomposition on every visible solid Arena mesh, computed ONCE in Studio (~40 min
  for 1,027) and saved; `save_place.exact_shapes()` copies saved shapes by mesh id (reads MeshId/url AND Rojo's
  MeshContent/uri). HitShapes.exactRoom deleted. Test on a copy: 975/975 solid parts exact after a rebuild.
- ClassroomDecor moved from .rbxm to `classroom-decor.rbxmx`, extracted from Alan's save (so live edits round-trip).
- In-game hangar menu = main Hangar art (kraft folder floating over the live game), layout B kept; journal-paper art
  retired (Alan). Stats: Health/Lift/Boost live, Speed/Climb/Swerve from the build (main Hangar ranges).
- Hangar safety refills after 120 s out of the hangar in a row, or on a kill (Alan). Config `protection_refill_out_seconds`.
- Old CeilingLight slabs stay (invisible) because they hold the SurfaceLights; meshes sit over them.
- Alan deleted 2 ClassroomPoster parts and PencilCaseBridgePart1 on purpose (confirmed).
- Alan playtested: "it plays good". Not formally marked as the vertical-slice gate (his words recorded in STATE).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (model router, look at the game, STATE ≤60 lines, hard limits); CLAUDE.md (plain English, handoff last).
- Memories: no-quality-cuts-for-fps, exact-collision-baked (Ctrl+S before any save_place rebuild), rug-layout-review.

## CARRY NOTES / GOTCHAS
- Claude cannot press Ctrl+S: computer-use access to robloxstudiobeta.exe was declined; ask Alan.
- Background Codex jobs die when the Claude session ends; on start, check status and resume with
  `task --resume <codex session id>` (only when no other Codex task is running).
- Long Luau: `tools/studio_cli.py execute_luau '{"studio_id":…,"code":"<file path>"}'` reads the code from a file.
- screen_capture: one at a time (parallel ones time out); a camera above y≈620 shows only the ceiling.
- Before any save_place on the real place: run it on a scratch copy first and check the "Exact collision: N reuse" line.
- Seen in a log, not investigated: "Attempt to shapecast with distance 1082 (max 1024)" from some server code.
- Loading still shows 1 failed picture per join in Studio (now skipped quickly; which id is unknown).

## WHAT SHIPPED / OTHER QUEUED
- 0cc4ea88 exact collision + no mesh preload · 0155355e hangar menu v1 · 2d2cf5ab menu in main Hangar art · a634076d
  floating folder · dd384717 stats sheet + Speed/Climb/Swerve · 134487ff note label · 8d64868e stats sheet tweak ·
  2210bb1a hangar safety refill · f5114ab0 bookshelf/light models · 6cefc8c1 shelves+lights placed · 2ceaf6fa packs ·
  480b30c5 11 wall decorations · 4cc788f4 window-wall bunting · cba65314 backpack cubbies · a1fc0690 repo = Alan's save,
  MeshContent fix · 3ef10903 re-bakes + flagpole · acbbcc5f concept art · 1293236d connected-city plan · STATE commits
  b230a4fc 052c40ae d68b29ac ccab79a3 597958a6 d4e6e8f3 5f343468.
- Queued: Codex Track C saving (needs private publish = Alan's go).

## POINTERS
- `.planning/briefs/2026-10-11-connected-city-kit.md` (rulings + rules), `assets/references/connected-city/` (photos +
  mood boards), `assets/models/kit/pieces.json` (50-piece kit), `tools/town_toys.py` (hero/readlua/meshes/stand/
  placelua/kit/packs/build), `tools/save_place.py`, `src/client/DeskHangar.luau`, `docs/MILESTONES.md`.
