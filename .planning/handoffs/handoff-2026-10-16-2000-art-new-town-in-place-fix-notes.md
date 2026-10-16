# HANDOFF — 2026-10-16 — new town is in the place; monorail built and running; Alan's first-look notes to fix

**Labels:** kind=product+ui · lane=art · branch=main · issues= · areas=tools/town_toys.py, tools/town_plan.py, tools/rug.py, tools/art/toys.py, tools/art/blocks.py, src/shared/MonorailRules.luau, src/client/TrainMotion.luau, src/server/FlightService.luau, config, assets/models, docs

★ START HERE: Goal: the new town (layout D) right and playable. Opening action: confirm Studio has the NEW place open
(rebuilt by `tools/save_place.py` at commit 5bd2b7bf; Alan reopened it and looked) and whether Alan pressed Ctrl+S after
the 453 exact collision shapes were worked out; then fix Alan's notes in `docs/playtests/2026-10-16.md` one by one,
each checked in Studio by eye (1280x720+) and ticked ✅ there.

> Read on demand: AGENTS.md → THIS; `docs/playtests/2026-10-16.md` (the 7 notes); `docs/systems/monorail.md`;
> `docs/world/town.md` "Where it stands"; `docs/workshop/lessons.md` (place rebuilds, uploads). Memories:
> studio-play-is-shared, no-surprise-desktop-control, look-at-textures-before-upload, exact-collision-baked.

## STATE (verify before acting)
- HEAD = this handoff commit after `9f6e84ac`, main, NOT pushed. Confirm: `git log --oneline -3`.
- Tests: rules 296/0 (Play in Studio, server: `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`).
- Place file on disk = new town (save_place at 5bd2b7bf: 675 shapes reused, 453 left for Studio). Today's town:
  `D:\FlyFightPaper-snapshots\` (place saved 2026-10-15 and 2026-10-16 18:13, plus its city-toys/classroom files).
- Rojo `rojo serve serve.project.json` was running; after Studio reopened, Alan must click Connect.
- Cost this session: Codex 4 jobs on Alan's plan (3 picture rounds, 1 station build; forwarders ~24k Claude tokens
  each); Explore (Sonnet) inventory ~186k; primary context high at handoff.

## NEXT ACTION + PLAN
1. Alan's notes (`docs/playtests/2026-10-16.md`), each done when Alan's look/screenshot shows it fixed:
   gate pads (#6 pencil-case bridge) never over asphalt; abacus-hall tile redrawn to its outline; block arch lot hidden
   with decorations; gateway towers (#2, next to the bell tower) arch bottom middle cut off the road; north station
   (#4) back mirrored to match its front; grey untextured piece behind the tissue on the tissue-box tower.
2. South station v2 (#5): add the two grey foundation plates under the legs (brief: last section of
   `assets/models/monorail-station-south/concept-v2-brief.md`; back is fine per Alan), renders of both sides to Alan,
   texture sheet check, upload (his go), read mesh ids (`town_toys.py readlua/meshes`), `build v4`, save_place.
3. Train stops ~10 s at each station (Alan): extend `MonorailRules.cars` (time → distance with dwells at the two
   station centres along the loop) + a test; check in Play that noses lead (`MESH_TURN` in TrainMotion) and it fits
   both tunnels.
4. New-town gameplay leftovers: re-pick paper targets on new roofs and the gateway-arch speed pickup
   (`config/gameplay.json` world.paper_targets, speed_pickups last entry); check bot route nodes survive
   (AirRoutes lattice) and bots don't die on the train; Airspace zones with Alan; park toys (benches, fountains,
   playground, picnic, ducks, boathouse) and the one plan ruler bridge are not placed yet.
HOLDS (Alan's go each): uploads (auto-mode blocks them: give him the PowerShell command), private publish,
Studio-settings changes, Meshy, anything paid, desktop control, closing Studio. Don't steer his plane in Play. Never
Ctrl+S-overwrite: a rebuild needs his Ctrl+S first.

## DECISIONS & WHY (this session; full list in docs/decisions/2026-10-15-town-replan-v3.md)
- Monorail route: outer ring-road pavement + MIDDLE of the monorail avenue + river; corners radius 100 over the
  junctions; train never within 6 studs of a building taller than it can pass (asserts in `tools/town_plan.py`).
- Pillars on the avenue stand on its centre line (Alan OK); south station moved to the middle river bridge (x 0) and
  rebuilt with the tunnel end to end, design E (three long windows) chosen by Alan.
- Train: 45 studs/s on server time, clients move it, server kills on touch; stops 10 s at stations (to build).
- Town swap keeps the classroom's own pieces from toy-placements.json (`CLASSROOM_PIECES`); fans to x ±600.
- Rug tile redraws are OK where needed (abacus); otherwise prefer decorations (Alan).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md; commit explicit paths (bell-tower WIP, old closeups, untracked old handoffs, place file aren't ours).

## CARRY NOTES / GOTCHAS
- Python `write_text` on Windows writes CRLF: write bytes. `git add` with a glob aborts on one bad path: stage via
  `git status --porcelain | ... | git add --pathspec-from-file=-`.
- Studio capture is blank while Studio is behind other windows (checked the track by numbers instead).
- Throwaway helper that runs `readlua`→`meshes` through Studio MCP for many folders: scratchpad
  `read_meshes.py` (copy the pattern from `tools/model_sheets.py`).

## WHAT SHIPPED (since f1b9a1de)
bf6142c0 monorail pieces + corners · 3bbb27a1 route clear of buildings · d4d5fce4 pillars OK + brief · 83f5e5a1
concepts A-C · 526a0d04 brief round 2 · 7ce8acfd pieces uploaded + D-E · 26ea922e mesh ids, 49 pillars 164 beams ·
60061593 E chosen · 5b74dc64 moving train · ea3a678b buildings in build v4 · 5bd2b7bf swap to the new town ·
04f5d6b5 playtest note + station v2 build · 862448f5, 4ef20766, 9f6e84ac Alan's answers · this handoff.

## KNOWLEDGE UPDATED
- docs/systems/monorail.md (new, linked from HOME); docs/world/town.md (Where it stands: new town in the place,
  snapshot); docs/playtests/2026-10-16.md (new); docs/decisions/2026-10-15-town-replan-v3.md (monorail rulings);
  docs/workshop/lessons.md (city-toys holds classroom pieces; regenerate config before Play);
  docs/workshop/testing.md (296); state/STATE.md. Checker: OK.

## POINTERS
- tools/town_toys.py (`build v4`: buildings_v4, monorail_beams, monorail_train, CLASSROOM_PIECES), tools/town_plan.py
  (MONO, clearance asserts, config/monorail-track.json), tools/rug.py (pads, median pillars), tools/art/blocks.py
  (stations), assets/models/monorail-station-south/ (brief, renders/back.png).
