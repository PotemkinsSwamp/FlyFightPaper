# HANDOFF — 2026-10-17 — new town notes fixed; train scrapes like a building; stations taller next

**Labels:** kind=product+ui · lane=art · branch=main · issues= · areas=config/gameplay.json, src/shared/MonorailRules.luau, src/server/FlightService.luau, src/server/RoundRuntime.luau, src/server/MatchService.luau, src/client/FlightHUD.luau, tools/rug.py, tools/town_toys.py, tools/art/hero.py, tools/art/fill_gaps.py, assets/models/paint-jar-tower, docs

★ START HERE: Goal: the new town right and playable, then Alan's Stage 9 approval. Opening action: make both monorail
stations a little taller and the same height, so the train sits close to each station's floor (Alan's 4th-look note 5,
bottom of `docs/playtests/2026-10-16.md`). Done when renders of both stations are OK'd by Alan, uploaded with his go,
rebuilt, and the train is seen in both in Play.

> Read on demand: AGENTS.md → THIS; `docs/playtests/2026-10-16.md` (4th look); `docs/systems/monorail.md`;
> `docs/workshop/lessons.md` (rebake settings, Windows file locks). Memories: studio-play-is-shared, look-at-textures-before-upload.

## STATE (verify before acting)
- HEAD `907d5e95` (main); GitHub copy in sync (`git ls-remote origin main` == `git rev-parse github-snapshot`).
- Tests: rules 297/0 at 5ad77622 (in Play, server: `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`).
- Place: rebuilt 23:00 and saved by Alan twice; the paint-jar tower's new pieces were swapped in live and saved
  (~01:40). Rojo connected. Backup: `D:\FlyFightPaper-snapshots\FlyFightPaper-WORKING-2026-10-16-2310.rbxlx`.
- **Studio tools:** this session's Roblox_Studio MCP showed 0 tools; worked round with a scratch script that runs
  StudioMCP.exe directly (initialize, then tools/call). If tools are missing again, do the same (or restart the session).
- Cost: no agents, no Codex, no Meshy. One upload: 64 assets (paint-jar tower, Alan's go, free). Blender local
  (5 rebakes, ~4 h of background CPU). Primary context ~55% at handoff.

## NEXT ACTION + PLAN
1. **Stations taller (note 5):** north and south station the same, a bit taller, train near the station floor. Check
   how each station is built (north: `tools/art/blocks.py`; south: its model) and the monorail clearance rules in
   `tools/town_plan.py`. Renders of both sides → Alan's OK → upload (his go) → rebuild (Alan closes/reopens Studio:
   my Stop-Process was refused by the permission check) → `tools/exact_collision.lua` → Alan's Ctrl+S → Play look.
2. **Alan flies the train:** a skim should scrape, a hard hit or the train running into you crashes; fit in the south
   station's gap above the train (box margin now 1 stud). Tune if he says so.
3. **Alan's Stage 9 playtest** (list in `state/STATE.md` "Waiting on Alan"): modes, "next spot" through every zone,
   the boosts, paper targets, escapes, vote screen → "Stage 9 approved" or fixes.
4. After approval: the Tutorial (MILESTONES), then Stage 11.
HOLDS (Alan's go each): uploads (PowerShell command if blocked), private publish, Studio-settings changes, Meshy,
anything paid, desktop control, closing Studio. Don't steer his plane in Play. Rebuild only after his Ctrl+S.

## DECISIONS & WHY (this session)
- Train hits judged like a building wall (Alan): `MonorailRules.hit` returns the nearest face's normal;
  `FlightService:impact` takes the train's own speed into the plane as `pushed`, so its nose ramming you crashes.
- Zones sized once per spot from the town plan, not live: Alan's "dynamic" read as "denser = larger and shorter";
  static per-spot numbers ([decision](../../docs/decisions/2026-10-16-zones-follow-density.md)).
- "next spot" replaced "ceiling": in an Airspace round it only moves the zone; from another mode it starts one.
- Paint-jar windows: shape copies of the back yellow window, 1 stud proud, nothing cut away. Paint-only copies left
  dark streaks (torn shape deeper than the copy); cutting the torn faces left holes after simplifying.
- No ruler bridges in the new town (Alan, [decision](../../docs/decisions/2026-10-17-no-ruler-bridges.md)).
- Block arch pier: nothing touches it (23/30 studs to neighbours); left unless Alan sends a screenshot.
- Bots don't dodge the train: 7 min of bot matches, 0 train crashes, 3 close passes.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (holds, docs rules, model router); memories no-quality-cuts-for-fps, look-at-textures-before-upload,
  studio-play-is-shared. Commit explicit paths (bell-tower WIP and old closeups.png edits aren't ours).

## CARRY NOTES / GOTCHAS
- **Windows file locks** (Errno 22 on overwrite) hit PNG, FBX, rbxmx and .py files all night. Moving the file aside
  works; hero.py and fill_gaps.py do it now. For other writes: move aside, write, delete the `.old`; check no `.old`
  file gets committed (two did; removed).
- **Rebake = all pieces re-upload** (records are dropped) and needs the original `--detail 2.5 --min-coverage 0.33`.
- `town_toys.py build v4` leaves out a building whose upload records are missing: check "not ready: none".
- Paint-jar windows: faint light streaks left in one pane each, close up only.
- STATE.md is at 60 lines; trim when adding.

## WHAT SHIPPED / OTHER QUEUED
23252c4e targets + gateway bolt + train at 90 · 95a45d74 Central Park toys · 4b4c2f00 Alan's eraser/fountain ·
175fe7f7 train 105 + 8 boosts · 9c5eb1eb boathouse nudge · 589fb4ff zones by density + next spot · 65b3178f /
d36f26ec toy file (tower back in) · f174651a hero.py copies, detail record, lock handling · a68276c2 tower rebake ·
e9b8deef tower uploaded, note ticked · 5ad77622 train scrapes, tighter box, next spot fix, 4th look, no bridges ·
907d5e95 stray file removed · this handoff.
Queued: stations taller (go for upload); bots dodging the train (only if Alan asks).

## KNOWLEDGE UPDATED
- docs/playtests/2026-10-16.md (3rd look ticked, 4th look); docs/systems/monorail.md (speed 105, scrape rule);
  docs/systems/modes-and-scoring.md (zones, next spot); docs/world/town.md (park toys, eraser, no bridges);
  docs/decisions: zones-follow-density, no-ruler-bridges; docs/art/pipeline.md (touch-up copies);
  docs/workshop/lessons.md (rebake settings, file locks); state/STATE.md. Checker: OK (84 pages).

## POINTERS
- tools/art/hero.py (`touch_up` copies), assets/models/paint-jar-tower/touchup.json, tools/rug.py (`PlanTown.parks`,
  `toy(size=)`), tools/town_toys.py (`build v4`, `readlua`/`meshes`), tools/save_place.py, tools/exact_collision.lua.
