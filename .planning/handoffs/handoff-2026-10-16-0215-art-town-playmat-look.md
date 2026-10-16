# HANDOFF — 2026-10-16 02:15 — rug layout settled through 4 rounds of Alan's notes; playmat look approved to build

**Labels:** kind=product · lane=art · branch=main · issues= · areas=tools/rug.py, tools/town_plan.py, assets/rug, assets/references/playmat, docs

★ START HERE: Goal: the layout-D rug printed in the playmat look Alan liked (`assets/rug/playmat-concept.png`), for
his OK, then 280 tiles he uploads. Opening action: make `tools/rug.py`'s v4 PlanTown draw that style (bright lime
grass, dark-slate roads with bold yellow dashes and chunky zebras, bright blue water, woven-carpet feel, fabric
border; layout exact), remake the ONE shared carpet normal + roughness map in Blender to match, and plan a thicker
stitched rug edge. Done when Alan OKs a new preview (and a close-up crop) of the look.

> Read on demand: AGENTS.md → THIS → state/STATE.md; docs/decisions/2026-10-15-town-replan-v3.md (every ruling,
> rounds 1-3, square bell pad, look plan); assets/rug/playmat-concept-notes.md; assets/references/playmat/.
> Memories: no-quality-cuts-for-fps, look-at-textures-before-upload, creator-store-first.

## STATE (verify before acting)
- HEAD = this handoff commit after `de7bb28a`, main, not pushed. Confirm: `git log --oneline -3`.
- Plan: `python tools/town_plan.py` (~3-4 min) → `assets/rug/replan-v4.{json,md}`, `replan-v4-preview.png`: 46/46,
  none shrunk, 16 lots, 3 toy sites. Rug: `python tools/rug.py --plan assets/rug/replan-v4.json` (~10 s) → "v4 rug
  checks passed", writes preview-v4.png, fill-plan-v4.png, toy-spots-v4.json.
- No game code changed; tests last 292/0. Nothing uploaded; today's town unchanged; Studio untouched.
- Cost this stretch (since dfa007d0): 1 Codex image job (Sol, Alan's ChatGPT plan) + 1 launcher agent (~23k tokens).
  No Meshy (1,043 left). Primary context ~46% at handoff.

## NEXT ACTION + PLAN
1. Build the playmat look (above). Keep every shape from replan-v4.json exact; take colours/line weights from the
   concept; no printed buildings, cars, trees or text. Show preview + close-up. Check: Alan OKs.
2. Shared carpet normal/roughness (Blender) replacing `assets/rug/carpet/*` maps; thicker rug slab with stitched
   binding (today's border parts are 1.4 tall). FPS must not drop (one shared map, flat tiles, no 3D pile).
3. `--tiles` → 280 tiles in `assets/rug/tiles-v4/`; teach `--plan` to upload/build (Alan runs uploads).
4. Toys (Alan's list, decision note) incl. a building-site toy set (crane ≤80 tall, diggers, cones); Creator Store first.
5. Before ANY building upload: look at every sheet flagged in `assets/rug/texture-safety-report.md` (133 of 215).
HOLDS (Alan's go each): uploads (he runs them), private publish, Studio settings, Meshy beyond the 8, anything paid,
desktop control, closing Studio. Don't steer his plane in Play. Alan gives map notes in rounds: don't run ahead
on work he hasn't asked for (he said so 2026-10-16).

## DECISIONS & WHY (this stretch) — details in the decision note
- Round 2: thin 1.5-stud building pads; square-to-grid lots; centre lines through the bell square; crosswalks placed
  by stepping out from each junction until clear of the crossing street; monorail track over the inner pavement so
  pylons stand there (printed mid-road islands read as "potholes").
- Round 3: round fan pads r92 (fans are round); pond turn undone; toy sites placed by the planner (`sites` in JSON).
- Flat grass (round shade patches read as printed trees). Square bell pad (tower 210 square, pad +6 each side).
- Rug look: colour tiles + one shared normal/roughness map + thicker edge; NOT 3D pile or per-tile normal maps
  (millions of triangles / ~280 extra textures would cost FPS and memory).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md; commit explicit paths (pre-commit hook, place file, bell-tower, old closeups, old untracked handoffs aren't ours).

## CARRY NOTES / GOTCHAS
- Windows intermittently refuses Python writes in the repo (`OSError [Errno 22] Invalid argument`), even on
  tools/rug.py and PNGs: retry (loop 3-5x) or use the Edit tool; then confirm with grep/`git diff --stat`.
- The review picture (fill-plan-v4.png) is not the rug: send preview-v4.png (or crops of it) when Alan judges the look.
- Old Town class in rug.py still drives today's rug (`python tools/rug.py`); don't rename its methods.
- Broadway/avenue half-circle plaza (NW) left as is; Alan didn't ask to change it.

## WHAT SHIPPED (since dfa007d0)
28d24d75 rug round 2 · eb3c6f26 round 3 + toy sites · 43d74b2a flat grass + playmat refs · c2975192 playmat concept
(Codex) · 6e21a8e9 square bell pad · a525811c tree markers as dots · de7bb28a decision + STATE · this handoff.

## KNOWLEDGE UPDATED
- docs/decisions/2026-10-15-town-replan-v3.md (rounds 2-3, sites, square bell pad, look plan + go);
  docs/world/town.md (playmat references link); assets/references/playmat/README.md (new); state/STATE.md. Checker: OK.

## POINTERS
- tools/rug.py (PlanTown v4, plan_fill, plan_main), tools/town_plan.py, assets/rug/preview-v4.png,
  playmat-concept.png, playmat-concept-closeup.jpg, assets/rug/carpet/ (current shared maps).
