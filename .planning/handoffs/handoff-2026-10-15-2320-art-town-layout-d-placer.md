# HANDOFF — 2026-10-15 23:20 — layout D chosen; planner places ~30 of 46; last Codex bake + texture safety running

**Labels:** kind=product · lane=art · branch=main · issues= · areas=tools/town_plan.py, tools/art/fill_gaps.py, assets/models/*, assets/rug, docs

★ START HERE: Goal: the town on layout D with all 46 buildings, parking lots with driveways, paths, gates, bridges and
the monorail loop, so Alan can OK a rug preview. Opening actions: (1) collect the Codex job that was still running
(egg-carton bake + UV-mask texture safety pass on the 8 Meshy buildings; brief `.planning/briefs/2026-10-15-bake-six-meshy.md`
Part 2), then (2) rewrite the placer in `tools/town_plan.py` so all 46 fit. Done when the plan picture shows all 46
placed with lots/driveways/paths and Alan OKs it.

> Read on demand: AGENTS.md → THIS → state/STATE.md; docs/decisions/2026-10-15-town-replan-v3.md (all rulings, incl.
> layout D); docs/workshop/lessons.md ("Making 3D models", new: block depth). Previous handoff (still valid for the
> buildings): handoff-2026-10-15-art-town-v3-buildings-layout-redo.md.

## STATE (verify before acting)
- HEAD = this handoff commit after `c396ec3a`, main, not pushed. Confirm: `git log --oneline -3`.
- No game code changed; tests last 292/0. Nothing uploaded. Today's town unchanged in Studio.
- **Running at handoff:** Codex job "bake last 2 + texture safety" (egg-carton-market baking at 23:09; pencil-case-bridge
  baked; `tools/art/fill_gaps.py` upgraded with a UV-mask mode, uncommitted). When it's done: read the diff of
  fill_gaps.py, look at every `renders/textures.png`, commit with explicit paths. If no Codex/Blender process is
  running and egg-carton has no parts.json, rerun Part 2 of the brief.
- The finished 6-bake job reported texture doubts (bake-review.json in each folder: X/O, cross, letter-like shapes) and
  4 of 6 below 6 px/stud (porthole 4.3, tissue 4.7, tape 5.3, cereal 5.1). Nothing goes to upload until the safety
  pass sheets look clean to Claude.
- Meshy: 1,043 credits left (floor 300). Cost this stretch: Codex ~5 jobs; no Meshy since the 8.

## NEXT ACTION + PLAN
1. Collect the running Codex job (above); review texture sheets; then run the upgraded fill_gaps (UV mode) on the 14
   Blender buildings too (one set has "+" window shapes).
2. Placer rewrite (`tools/town_plan.py`, roads/blocks/gates/monorail already right; placement is the problem):
   findings: blocks are ~140-230 deep after setbacks; big buildings are 125-195 deep; most tries fail "outside the
   block" because spots on plaza/river edges are used as street fronts; lots are reserved before buildings. Fix: only
   street-facing straight edges as fronts; biggest buildings first into the biggest central blocks; allow a 90° turn;
   lots after buildings, behind them, driveways through gaps; consider fewer/merged blocks or smaller setback. Keep
   tallest near the bell tower stepping down; low (≤80) in desk landing paths; fly-through approaches open.
3. Alan OKs the plan picture → rug: `tools/rug.py --plan` must learn the v4 JSON (road polylines, river, lots,
   driveways, paths, pylons) → preview → Alan OKs → he uploads tiles; then buildings upload (Alan) and placement.
HOLDS (Alan's go each): uploads (he runs them), private publish, Studio settings, Meshy beyond the 8, anything paid,
desktop control, closing Studio. Don't steer his plane in Play.

## DECISIONS & WHY (this stretch) — details in docs/decisions/2026-10-15-town-replan-v3.md
- Layout D (A + C): Manhattan blocks + Broadway + river, monorail LOOP, fans at boulevard ends (boulevard U's round
  them), bell tower over the crossing on legs. Rug back to today's 2000 x 1400 (Alan: v3's wider rug made it sparse).
- Building sizes are correct (parts.json = in-game sizes); sparseness was layout geometry.
- 13 Blender fixes accepted ("look good now"). Height changes: block-arch 160, abacus 75 (LOW_H = 80 in the planner).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md; commit explicit paths (pre-commit hook, place file, bell-tower, closeups, old untracked handoffs are not ours).

## CARRY NOTES / GOTCHAS
- shapely 2.2 installed (free; town_plan.py needs it).
- `assets/rug/layout-options/` holds the 4 sketches + their scripts (throwaway, kept for record).
- v3 rug (`preview-v3.png`, `tiles-v3/`, `replan-v3-*`) is obsolete; don't upload.
- Shoebox hall: 0.5-stud gap under awning posts (next touch-up).

## WHAT SHIPPED (since 600b0a8d)
499ec474 bake part-2 brief · e9864ca3 3 baked buildings · cbff14c6 13 Blender fixes · 09b4acf0 Blender sheet ·
296c745d 3 layout options · ea2a16b4 option D · 7fa027c3 fans apart · 4c46e1ee boulevard U · 1ec6b8ad roads under
tower · 6e9938e3 decision D · 4c6670a4 6 Meshy bakes · c396ec3a planner for D (WIP) · this handoff.

## KNOWLEDGE UPDATED
- docs/decisions/2026-10-15-town-replan-v3.md (layout D), docs/world/town.md, docs/workshop/tools.md (town_plan.py),
  docs/workshop/lessons.md (block depth vs footprints), state/STATE.md. Checker: OK.

## POINTERS
- tools/town_plan.py (layout D), assets/rug/replan-v4-preview.png, assets/rug/layout-options/option_d.py,
  assets/models/*/bake-review.json, .planning/briefs/2026-10-15-bake-six-meshy.md.
