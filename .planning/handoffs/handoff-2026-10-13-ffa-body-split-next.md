# HANDOFF — 2026-10-13 — 21 playtest notes in; FFA body/nose/tail split next (Alan's follow-up)

★ START HERE: Goal: free-for-all planes split down the middle on the BODY too (left red, right blue). Alan: thin
wings like the feather fold barely show colour, so wings alone don't read. Next: cut the paper/cardboard/tube middle
pieces into -L/-R halves and colour each half by side. Done when an FFA plane in Play shows a red left half and a blue
right half on body, nose and tail (numbers on part colours + a picture once Studio draws), and tests stay green.

> Read on demand: AGENTS.md → THIS → docs/PLAYTEST-NOTES-2026-10-13.md (rulings at the bottom). Memories:
> roblox-mesh-import-gotchas (FBX 180° turn, rojo can't set MeshId), exact-collision-baked (Ctrl+S before save_place),
> studio-not-drawing, studio-play-is-shared, no-surprise-desktop-control, look-at-textures-before-upload.

## STATE (verify before acting)
- HEAD `43afb045` (main), never pushed. Confirm: `git rev-parse --short HEAD`.
- Tests 261/0 (Play server): `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- Studio: WORKING open in Edit, Play stopped. Rojo serve restarted this session (it had died silently; the plugin
  reconnected by itself). Check: `curl -s http://localhost:34872/api/rojo`. Place file NOT re-saved (needs Ctrl+S).
- Cost last session: 0 sub-agents, 0 Codex, 0 Meshy, 0 uploads, no desktop control. Free Creator Store sounds only.
  Primary ~42% context.

## NEXT ACTION + PLAN
1. FFA split. Pattern to copy: `tools/art/split_wings.py` (Blender bisect at x=0, -L/-R FBX + json records) →
   upload (Open Cloud, ROBLOX_API; see how wing halves reached `assets/models/planes/uploads.json` "models"/"meshes")
   → `tools/art/plane_pieces.py` builds `pieces.rbxmx` from the halves → `Aircraft.colours`/`side()` in
   `src/shared/Aircraft.luau` already colour by -L/-R name (middle pieces currently fall to MIDDLE = white).
   Scope: paper + cardboard + tube regions of body_*, nose_*, tail_*, boost_* that span x=0 (~26 pieces, ~52 halves).
   Accent/tape stay whole (white/yellow either side). Wing-shift code slides only `wings` halves: don't let body
   halves slide. Colliders are runtime copies of Appearance parts (FlightService ~line 146): halves are fine.
   Test with a live `AssetService:CreateMeshPartAsync` swap before any rebuild.
2. HOLD: `tools/save_place.py` rebuild needs Alan's Ctrl+S first and his OK to close/reopen Studio.
3. Then Alan's playtest of all 21 notes ("what to try" in state/STATE.md); visuals still unseen by me: deaths,
   paperclip glints, FFA split, crossed-out hangar cards; sounds picked by description.
4. Then Stage 6 first 60 seconds → Stage 9 modes (Alan's order).
- HOLDS (Alan's go, each): private publish; Studio-settings changes; Meshy spend; anything paid; desktop control
  (only if necessary or asked); closing Studio. Don't steer his plane while he's in Play.

## DECISIONS & WHY (this session)
- Lift-out jitter cause: `Rules.velocity` switched branches per frame during turns; the server's climb check read
  the no-sink frames as cheating and snapped back 4x/s, and the snap itself failed the next check (loop). Now one
  continuous glide rule + the server restarts its empty-Lift count after a correction.
- Dive with Lift capped 1.25x cruise (`lift_dive_max_speed_factor`); climb check allows for that speed.
- Stapler 0.8 s bursts but damage 4.67/staple so damage per second stays 17.5 (bot balance tests hold). Alan may want stronger.
- Bots: front-only vision; break away only on a hit or a shot within 10 studs (20 was too jumpy). Kills/2 min 6 and 12 vs 11.
- Eraser (Alan): fires on any click, straight until the lock completes; bots wait for a full lock.
- Hangar placing lives in `BuilderModel:findPlace/placeWeapon` (tested); cards use it for the crayon X reason.
- Fans: 15 Lift/s while inside, updraft 30; old reuse timer deleted.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (look at the game, model router, STATE ≤60 lines, hard limits, Creator Store first); CLAUDE.md (plain
  English, handoff last).

## CARRY NOTES / GOTCHAS
- Studio not drawing → RenderStepped 0/s: test camera/death code via a Play-client clone with RenderStepped→Heartbeat.
- Fake CombatInput clicks must use a seq above the server's (info.seq) and within +2000, or they're silently dropped.
- DevAim set to nil lets the plane auto-level and land on a desk; keep an aim set during flight tests.
- After editing files, confirm Rojo synced (grep the Edit Source) before starting Play; it died once unnoticed.
- Python edits on Windows: keep each file's line endings (several files are CRLF).
- Bell-tower + closeups.png changes in the working tree are not ours: leave.

## WHAT SHIPPED / OTHER QUEUED
- Shipped (this session): 43afb045 rulings recorded · 23ffd201 eraser any click · e354fcac STATE · e9f843a1 notes 20-21 ·
  6a1c40e5 hangar smart placing + crayon X · 01b46911 note 17 · 2b032026 bots front vision / shot-at · aaa965f2 notes 7-13 ·
  81600038 sounds · cdfe243f notes · 304c7bd1 fans + dive with Lift · 2c79d8ce paperclip glints · ed49a70b remains colours ·
  d2886a0a FFA wing split · 090132a9 stapler · 4f271957 notes · 22a8dc5b camera follows remains · 5a197361 pencil instant ·
  f43a6e38 Lift-out jitter fix.
- Queued: Track C saving (needs private publish); menu stage gaps; bot-vs-bot rams never land; last stand-in
  sounds (hit, kill, service).

## POINTERS
- docs/PLAYTEST-NOTES-2026-10-13.md, state/STATE.md, tools/art/split_wings.py, tools/art/plane_pieces.py,
  src/shared/Aircraft.luau (colours/paint/build), src/client/PlaneDeaths.luau, src/client/Audio.luau,
  src/shared/BuilderModel.luau. Previous: handoff-2026-10-13-playtest-notes.md.
