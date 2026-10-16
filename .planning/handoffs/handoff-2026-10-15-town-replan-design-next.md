# HANDOFF — 2026-10-15 — town replan: layout v2 liked; unique buildings, fly-throughs, fans, links, monorail next

★ START HERE: Goal: a denser, connected town Alan approves (Stage 4), built on layout v2 without reused buildings.
Opening action: write the replan design and cost plan for Alan's OK, before making any model: (1) the list of unique
buildings needed (about 28 new ones next to the 23 existing, one per lot in v2), each with a role in the height
plan; (2) which ones are fly-through buildings and where each sits so its holes have open approaches on both sides;
(3) a new updraft-fan layout; (4) roof connection points (bridges) and a toy monorail route through and around
buildings with fly-over and fly-under points. Show it as an updated plan picture plus a short list with the cost
(Meshy credits, Codex time) per building. Done when Alan says go.

> Read on demand: AGENTS.md → THIS → state/STATE.md; docs/decisions/2026-10-15-town-replan-rulings.md,
> docs/world/town.md, docs/art/pipeline.md, docs/art/building-kit.md, docs/workshop/lessons.md (pictures + art).
> Memories: creator-store-first, look-at-textures-before-upload, measure-concept-before-brief, touch-up-before-showing.

## STATE (verify before acting)
- HEAD = this handoff commit after `4be1334f`, main, local only (never pushed). Confirm: `git log --oneline -3`.
- Tests 292/0 (Play, Server): `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`; saving
  round-trip 17/0: `require(game.ServerStorage.FlyFightPaperTests.integration["ProfilePersistence.spec"]).run()`.
- Studio WORKING open in Edit; today's town in place (CityToys 1,664 parts = toy-placements.json); Alan pressed Ctrl+S
  after the ducts; the paper-target move is config (no save needed). Rojo serve was restarted by this session
  (`rojo serve serve.project.json`); if Studio stops picking up code, restart it.
- No scratch modules left in `src/generated` (DuctsPreview/TownPreview deleted; both git-ignored).
- Cost this session: no subagents, no Codex, no Meshy, no uploads, no spend. Desktop control used once (Alan's OK) to
  focus Studio for screenshots.

## NEXT ACTION + PLAN
1. Replan design + cost plan (above) → Alan's OK. Method is yours; Creator Store first, Codex Blender, Meshy last
   (stop at 300 credits left); concept pictures from Codex are free.
2. After OK: make the buildings (contact-sheet check every texture before Alan uploads), then rug redraw
   (`tools/rug.py` to the v2 street plan; new tiles uploaded by Alan), place buildings, fans, bridges, monorail; move
   paper targets and speed hoops (gateway arch, bell tower) to the new roofs; desk landing paths and duct vents stay
   clear. Prototype any step in Studio with `python tools/town_plan.py OUT.png --studio` (restores today's town after).
3. Still waiting on Alan from Stage 9: the playtest list in STATE (modes, vote screen, a target falling flat).
HOLDS (Alan's go each): uploads (he runs them), private publish, Studio-settings changes, Meshy spend beyond the plan
he OKs, anything paid, desktop control (only if truly necessary or he asks), closing Studio. Don't steer his plane
while he plays.

## DECISIONS & WHY (this session)
- Ducts design pass done and approved ("ducts look good"): HVAC look from geometry, free Creator Store props (scripts
  never used; a trap "Lego brick" deleted). Vent grilles solid; hinge sides chosen so bot routes never cross one.
- Veteran bots fly duct runs (escape 40% within 500 studs, wander 12%), only with Lift to finish; never abandon a run
  once inside. Paper targets: two were buried in later buildings, moved to open roofs (server hit + 50 points proved;
  the fall animation unseen because Studio wasn't drawing).
- `Runtime:bind` ticks the match clock first (wrong_match crash on respawn at round end; test added).
- Denser city: patching 21 copies into gaps was undone at Alan's word (not consistent with town planning); the real
  answer is the full replan (layout v2 liked; rulings note above).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (model router, Creator Store first, one writer per file, docs check-up each handoff, hard limits).
- Commit with explicit pathspecs (another session has staged files in this repo: never touch them).

## CARRY NOTES / GOTCHAS
- `screen_capture` times out in this Studio; see lessons.md "Getting pictures when Studio won't draw".
- Writing `assets/models/ducts.model.json` sometimes fails with Errno 22 right after a write: retry.
- Toilet Roll body jitter still unreproduced; bot-vs-bot rams never land.

## WHAT SHIPPED / OTHER QUEUED
- 4b561f95 Ducts look like real HVAC ductwork · 127c6777 Veteran bots fly the ducts · 5e98e0aa respawn wrong_match fix
- 722e53c4 Handoff (ducts dressed) · 57129681 Vent grilles solid · 7020af64 State: grilles
- dea7dc10 Two buried paper targets moved · 1e12a72e / 65970ca1 State: Stage 9 playtest list (and restore)
- 0ca15973 Decision: denser city · 29b4d979 21 copies (undone by bffcac6d) · e4c01c0e State
- 672b2a86 Town replan planner, plan picture, rulings · 4be1334f town_plan.py Studio prototype · this handoff.
- Queued: replan design → buildings → rug → placement (Alan gates the design and every upload); Stage 9 approval.

## KNOWLEDGE UPDATED
- docs/systems/escapes.md (ducts look, solid grilles, bot runs), docs/systems/bots.md (veterans in ducts),
  docs/systems/modes-and-scoring.md (targets moved, TDM passed), docs/world/town.md (replan), docs/workshop/tools.md
  (town_plan.py), docs/workshop/lessons.md (free-model traps, SpecialMesh props, SpotLight cap, live preview, pictures
  without drawing, test firing, git restore). Decisions: denser-city, town-replan-rulings (+README). Checker: OK.

## POINTERS
- tools/town_plan.py (v2 plan, height bands, landmarks, Studio prototype), assets/rug/replan-v2-preview.png,
  captures/proto-*.jpg (git-ignored prototype shots), tools/rug.py (street plan, Town.design), tools/town_toys.py.
