# HANDOFF — 2026-10-16 — new town playable; Alan's notes fixed but three new ones

**Labels:** kind=product+ui · lane=art · branch=main · issues= · areas=tools/push_github.py, tools/town_plan.py, tools/rug.py, tools/art/blocks.py, tools/art/cut_piece.py, tools/exact_collision.lua, tools/town_toys.py, src/shared/MonorailRules.luau, src/client/ChalkCloud.luau, config, assets/models, assets/rug, docs

★ START HERE: Goal: the new town right and playable. Opening action: run the rules tests and watch the train once at
the new speed (90). Then fix Alan's three third-look notes (bottom of `docs/playtests/2026-10-16.md`): the stacked-lids
tower's wrecked windows, the floating paper targets, the block arch's buried pier. Each one is done when it's fixed in
Studio by eye and ticked there.

> Read on demand: AGENTS.md → THIS; `docs/playtests/2026-10-16.md`; `docs/world/town.md`; `docs/systems/monorail.md`;
> `docs/workshop/lessons.md` (exact collision, uploads). Memories: studio-play-is-shared, look-at-textures-before-upload.

## STATE (verify before acting)
- HEAD `17395b0e`+handoff (main); every commit auto-pushed to GitHub (`.githooks/post-commit` → `tools/push_github.py`).
  Confirm: `git rev-parse --short HEAD`; `git ls-remote origin main` == `git rev-parse github-snapshot`.
- Tests: rules 297/0 at 930d6997. Not re-run after the speed change (45→90, brake 15→30): Alan was in Play. Re-run:
  in Play, server: `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- Place: rebuilt with save_place at ~20:40. Alan saved it at 21:09, so all exact collision shapes are in the file (730
  saved shapes). Backup from before the rebuild: `D:\FlyFightPaper-snapshots\FlyFightPaper-WORKING-2026-10-16-2035.rbxlx`.
  After Studio reopened, Rojo needs Alan's click on Connect (check that a src change shows up in Studio).
- Cost: no agents, Codex or Meshy. Uploads were Alan's (~264 assets, free). Blender local. Primary context ~45% at handoff.

## NEXT ACTION + PLAN
1. Tests green, and the train at 90 looks right (noses lead, fits both tunnels, stops in the stations).
2. **Stacked-lids tower** (probably `paint-jar-tower`, Alan's screenshot): on one side, the top window is wrecked and
   the touched-up one below doesn't match. Make both match the good windows beside them. Fix in the bake/touchup, or
   with clean window geometry. Close-ups and a texture contact sheet before upload (look-at-textures lesson).
3. **Paper targets** (`config/gameplay.json` world.paper_targets) float since the town moved: re-place them on open
   rooftops round the new town (from replan-v4 buildings + Studio raycasts). Also re-place the gateway-arch speed
   pickup (speed_pickups, last entry).
4. **Block arch's blue pier** is buried in the brown building east of it: move that building (or the arch), checking
   the plan's GAP asserts, without reshuffling the town (use the GATE_MOVES-style after-placement move).
5. Then: bot route nodes and bots vs the train; Airspace zones with Alan; remaining park toys (playground, picnic,
   ducks, boathouse) and the roof-to-roof ruler bridge.
HOLDS (Alan's go each): uploads (give him the PowerShell command), private publish, Studio-settings changes, Meshy,
anything paid, desktop control, closing Studio. Don't steer his plane in Play. A rebuild needs his Ctrl+S first; after
a rebuild with new meshes, run `tools/exact_collision.lua` in Studio, wait, then ask for Ctrl+S.

## DECISIONS & WHY (this session)
- Pencil-case bridge moved 51 studs south (its west leg stood on the main boulevard's curve). It moves after the
  other buildings are placed (`GATE_MOVES` in town_plan.py); moving it the normal way reshuffled 24 buildings.
- The rug paves only under pieces that touch the ground (`ground_pad`, `PAD_SKIP` in rug.py), for gates and the
  abacus. This also fixed the block arch's lot without decorations, since those tiles were redrawn anyway.
- Gateway floor cut with `tools/art/cut_piece.py` on the 4 ground pieces only. A hero.py re-run would have lost
  Codex's normal repairs and re-uploaded 16 pieces.
- North station: `same_both_sides()` copies front details to the back, turned 180 degrees, skipping any that already
  have a twin.
- Train: the middle car stops at each station's middle, easing in and out. Speed 90 is my pick for "a lot faster"
  (planes fly 45-155); Alan to judge.
- Eraser moved to the park's edge (the fountain took its spot). The cloud follows it, the coat scales with it, and
  Alan may move or resize it (then copy its CFrame into `assets/models/toys/chalk-eraser/chalk-eraser.rbxmx`).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md; commit explicit paths (bell-tower WIP, old closeups and untracked old handoffs aren't ours; the place
  file is never committed).

## CARRY NOTES / GOTCHAS
- Rug tile uploads skip any tile that has a record, even if it was redrawn: diff the previews and delete those tiles'
  `assets/rug/uploads/*.json` first (done this session for 40 tiles).
- Writing a file sometimes fails with `OSError Errno 22` (Windows lock); retry or use the Edit tool.
- Studio pictures time out or come back stale while Studio is busy working out shapes. Wait, then retake.
- Tissue-tower grey piece (note 5) not found; ask Alan for a screenshot if it shows again.

## WHAT SHIPPED / OTHER QUEUED
80b5809a push tool · 930d6997 train stops · dc9bff75 bridge move + ground pads · 66259851 gateway cut ·
2d33f2d9 post-commit hook · 5d460656 GitHub copy fix + catch-up · 48b37c47 stations + 40 tiles marked ·
9ab5a04a exact collision step + eraser coat · d5cf551e upload records · d46ccd81 eraser park + town build ·
a3170906 notes ticked · 17395b0e train 90 + third-look notes · this handoff.

## KNOWLEDGE UPDATED
- docs/systems/monorail.md (stops, speed knobs); docs/world/town.md (where it stands, exact-collision step);
  docs/playtests/2026-10-16.md (ticks, second and third looks); docs/workshop/lessons.md (box collision after
  rebuilds); docs/workshop/tools.md (push_github, cut_piece, exact_collision); state/STATE.md. Checker: OK.

## POINTERS
- tools/town_plan.py (GATE_MOVES, legs assert, stations in monorail-track.json), tools/rug.py (ground_pad, eraser park
  toys), tools/town_toys.py (`hero`, `readlua`/`meshes`, `build v4`), tools/save_place.py, tools/exact_collision.lua.
