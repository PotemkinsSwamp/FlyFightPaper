# HANDOFF — 2026-10-09 — City rug rebuilt as a planned town (Alan approved the layout); bots fly clean on it

★ START HERE: Goal: finish Stage 4b with final-quality 3D toys on the town rug. Opening action: ask Alan how the rug looks in Play (WORKING place, Rojo) and fix anything he flags; then start the toys from `assets/rug/fill-plan.png` / `assets/rug/toy-spots.json` (trees and cars first, they fill the empty grass). Done when the town reads full and planned in Play at 60 FPS with 12 planes, bots still crash 0 times, and Alan likes it.

> Read on demand: AGENTS.md → state/STATE.md → THIS. Then `docs/MILESTONES.md` Stage 4 (4b toys + Meshy rules). Memories: studio-test-copy, rug-layout-review.

## STATE (verify before acting)
- HEAD `95a99ef` (main), local only, never pushed. Confirm: `git rev-parse --short HEAD`.
- Tests: not re-run this session (no rules logic changed; only fan positions in config). Last: 220/0. Re-run in a Play server: `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- Rug check: `python tools/rug.py` must print "plan OK" (fails on any overlap, missing gap, building on a road, or place with no driveway/footpath).
- Studio: FlightTestG (Claude's copy, id 5422…) is live-linked to the repo files (Rojo) and has the new rug + moved buildings. A third Studio (scratchpad FlightTestH.rbxlx) was opened but never connected to MCP; close it if it is still up. No servers running.
- Match on the new layout (Haiku match-runner, FlightTestG, 202 s, 12 mixed bots): 16 deaths, 16 by weapon, 0 crashes; server 60 FPS. Client FPS NOT measured (Alan's screen check pending). Console: one "Infinite yield ... RoundView" warning in the test copy, not investigated.
- Cost this session: 1 Haiku agent (~42k tokens); no Codex; no Meshy credits; 318 free uploads to Alan's account (280 rug tiles + tile mesh + normal/roughness/stitch maps + 34 tiles of a rejected draft, unused); ~3 h wall clock; primary context ~56% at handoff.

## NEXT ACTION + PLAN
1. Alan's Play look at the rug (from the air and low down; carpet texture; FPS on his screen). Fix what he flags; layout changes go through `tools/rug.py` (re-run, re-draw changed tiles, upload, `build`).
2. 3D toys at final quality (Alan: every new model final quality, colour+normal+roughness): trees (round + pine), cars, then fountains, benches, houses, stalls, planes, playgrounds, pool, barn etc. at the saved spots. Meshy stops at 300 credits; log jobs in `assets/MESHY_LOG.md`; Codex Sol for Blender jobs, Astra only after Sol fails. Instance copies of each model (cheap), place from toy-spots.json.
3. Then Stage 4c–4g in order. The ★ "Alan approves the look" gate is at the end of Stage 4.
- HOLDS (Alan's go, each): passing the Stage 3 gate; private publish; Studio-settings changes; anything after the ★ gate.

## DECISIONS & WHY (this session)
- **Alan (2026-10-09): the rug is FLAT ground only.** Cars, trees, fountains, pools, benches, people, stalls, houses come off the rug and become 3D toys, so the city has more 3D than just buildings (closer to the reference). Their planned spots are kept in `assets/rug/toy-spots.json`.
- **Town-planning rules (after Alan said the layout looked poorly done; researched real codes):** buildings face their street on a shared build-to line 14 studs behind the pavement; ≥14 studs between buildings; ≥5 studs clear grass between any painted things; every pad/car park/park/court has a driveway or footpath. `tools/rug.py` enforces all of these.
- **Buildings moved** (24 groups, up to ~220 studs) to fit the street plan; each mesh moved with its BuildingCollision boxes and flag. Lift fans moved to x=-780/780, z=0 (config/gameplay.json) so their plazas end the east-west boulevard and clear the ring road.
- **Carpet look:** each tile is a MeshPart (uploaded thin box, `assets/models/rug-tile`) with a SurfaceAppearance: unique colour map + one shared pile normal map + roughness. Decals can't show material normals (tested). Tiles turned 180° (mesh shows the picture's top toward +Z).
- **Tiles are not in git** (280 × ~1 MB; `tools/rug.py --tiles` redraws them); upload records in `assets/rug/uploads/` are.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (model router, look-at-the-game rule, STATE ≤60 lines, hard limits). CLAUDE.md (plain English for Alan; handoff is the last act).

## CARRY NOTES / GOTCHAS
- Never upload rug tiles before Alan approves the preview: `assets/rug/preview.png` (flat rug) and `assets/rug/fill-plan.png` (where toys go).
- Re-uploading: delete the matching `assets/rug/uploads/tNN_MM.json` first (upload skips existing records). `--build` re-draws all tiles (~20 min); to only rebuild the model call `rug.build(rug.upload(names))`.
- Long shell heredocs fail on this machine ("filename or extension is too long"): write the script with Write, then run it.
- Studio camera captures from y>620 hit the ceiling; top-down shots from y=600 come out rotated 180° (top = south).
- Alan declined desktop control this session; work through Studio MCP only unless he grants it.
- Studio test copy: FlightTestG is Rojo-linked, so file changes show up there without pushing.

## WHAT SHIPPED / OTHER QUEUED
- e574bb7 City rug redesign: planned street grid, buildings moved, flat ground only, overlap check, carpet fibre maps
- a54281b Rug layout follows town-planning rules (build-to line, even gaps, fan plazas clear of the ring road)
- 6ce3157 Every pad, car park, park and court gets a driveway or footpath; fill-plan map of the planned 3D toys
- 965846e City rug built: 280 unique carpet tiles, stitched navy edge; old tile set removed
- 95a99ef STATE: town rug built, bots fly clean on it
- Queued: 4b 3D toys, then 4c–4g.

## POINTERS
- Rug: `tools/rug.py` (street plan `ROADS`, block designs in `Town.design`, rules `SETBACK/PAD/GAP`, `connect()` paths), `assets/rug/`, `assets/models/city-rug.rbxmx`, `assets/models/rug-tile/`.
- Room: `assets/models/classroom.rbxmx` (moved buildings). Fans: `config/gameplay.json` world.fans.

## AAR
- Planned: street plan → move buildings → rich tiles → carpet texture → Play check. Actual: done, but Alan caught overlaps and weak urban design twice before I did. Why: hand-placed pieces had no overlap check at first, then the check's map was too small and missed most of the rug; and I fitted things around each other instead of designing to street rules. Now: the rules live in `tools/rug.py` and fail the build; previews go to Alan before uploads (memory rug-layout-review). Cost: the 34 wasted uploads were the only waste.
