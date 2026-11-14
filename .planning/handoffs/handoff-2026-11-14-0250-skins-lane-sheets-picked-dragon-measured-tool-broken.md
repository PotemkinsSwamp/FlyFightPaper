# HANDOFF — 2026-11-14 — Skins: Shark Jet and Dragon sheets picked, Dragon measured; the paint-from-sheet tool scrambles

**Labels:** kind=product · lane=skins-lane · branch=main · issues= · areas=.planning/skins, tools/art/sheet_model.py, docs/plan/SKINS-PLAN.md, docs/decisions
**Time:** 2026-11-14 02:50 -05:00

★ START HERE: Goal (Alan 2026-11-14): shape skins that look like their model sheets, made by building simple shapes in
Blender and painting them by projecting the sheet's own views; proved on the Dragon's head before full builds. First
action: fix `tools/art/sheet_model.py` so the Shark-nose test (`.planning/skins/shark/test-nose/spec.json`) comes out
clean: Alan called the current one "horrible ... ruined and garbled" (jaw and whole underside scrambled). Done when
the nose sits beside the sheet in its `review.jpg` with no noise or speckles, checked on a zoomed crop by you and an
independent reviewer. Only then the Dragon head test.

> Read on demand: AGENTS.md → this file; then the [shape-skin decision](../../docs/decisions/2026-11-14-shape-skin-model-sheets.md),
> the "Model sheets..." section of `docs/plan/SKINS-PLAN.md`, `.claude/skills/concept-to-blender/SKILL.md`, and the
> 2026-11-14 entries in `docs/workshop/lessons.md`. Memories: measure-concept-before-brief, touch-up-before-showing,
> look-at-textures-before-upload, no-meshy-blender-only, codex-for-pictures-and-blender.

## STATE (verify before acting)
- HEAD `1e1d7dfb`+ (main, pushed after every commit; another session commits on main too). `git log --oneline -12`.
- No game code touched. Docs: `python tools/check_docs.py` (OK at handoff).
- Studio not used. Nothing uploaded. Sheets and renders are untracked under `.planning/skins/` (on purpose).
- Cost: 9 Codex Sol picture jobs ≈ 560k Codex tokens (one stopped by me); 0 Claude subagents; ~1h25 wall clock;
  primary at ~45% context.

## NEXT ACTION + PLAN
1. **Fix the tool** (`sheet_model.py`, painting loop): paint each face from ONE view (side unless it clearly faces
   up/down/forward; no per-texel blending), loosen the depth test (now 0.006 of the length) so steep faces don't
   speckle, and check the jaw/teeth and underside on a 3x crop. Re-run:
   `python tools/art/sheet_model.py .planning/skins/shark/test-nose/spec.json` (about a minute).
   Stop rule: when two honest tries still garble, say so to Alan plainly and change the method (e.g. paint from the
   side view only and recolour top/bottom from sampled colours), don't polish.
2. **Dragon head test**: spec from `.planning/skins/dragon/measure-spec.json` numbers (head 0-0.27 of the length;
   horns, crown spikes, eyes; head width from the TOP view). Render at the sheet's three-quarter angle beside the
   sheet's head; Alan judges. If it doesn't look like the sheet, change the method before building more.
3. Full Dragon, then Shark Jet (from `shark-jet-a4.png`), each beside its sheet before any upload.
4. Later: Codex printed-sheet pictures for Hazard, Tiger, Flame, Gold Foil, Lava, Galaxy (layout in
   `assets/models/planes/skin-sheet/`).
HOLDS (Alan's go, each): any upload (texture contact sheet checked for symbols/hand shapes/text first), Save to File,
publish, anything paid, any new mechanic or number, any Studio Play (ask; he plays in the same Studio).

## DECISIONS & WHY (this session; full text in the decision note)
- Shark Jet = `shark-jet-a4.png` (round jet body, cream underside). Dragon = `dragon-b8-legs.png` (Dragon B's details
  on the shark's airframe, legs tucked, front legs moved back by hand behind a neck).
- Every shape skin has a body with a bottom, shown from below: a barrel like a fuselage. NOT a belly (fat), NOT a box
  (blocky), NOT a sausage (balloon). Plane first, creature second.
- Measured Dragon OK'd: follow side and top views (front view draws head/body 1.6x wider); the body follows the
  plane's width; the head keeps its drawn size (Alan declined "head grows on big planes").
- Safety swaps: no zigzag bolts (Shark wings), no square spirals (Dragon cheeks).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (docs rules, commit by path, push each commit, Codex = Sol only, no `--model`). Shared folder with the
  main session: touch only `.planning/skins/`, `tools/art/` skin files, skin docs; never switch branches.
- Memories above; CLAUDE.md "bad news plainly": describe a render by its WORST part before showing it.

## CARRY NOTES / GOTCHAS
- The Dragon sheet's three-quarter view still shows the old front-leg spot (not used for building).
- `measure.py` sheet now at least 2400 px wide (fixed today). `sheet_model.py` deletes the factory cube (fixed).
- Codex image tool sometimes refuses shark teeth as "violence": rephrase as a cartoon grin, it retries.
- Leg move script was a throwaway (scratchpad, gone); redo by hand the same way if needed (lessons.md).

## WHAT SHIPPED / OTHER QUEUED
- 13e84d7b picks + belly rule · ee27719b barrel not belly + lesson · 3f3ed0fc Shark sheet picked · 02799f36
  sheet_model.py · 1672da77 Dragon approved + tool fixes · abb1f6ab measure.py width · 1e1d7dfb Dragon measured, plan
  · (next) plan: tool scrambles, lessons, this handoff.
- Queued: trails (Confetti, Rainbow Marker, Gold Stars) art; Shark Jet and Dragon matching trails.

## KNOWLEDGE UPDATED
- `docs/decisions/2026-11-14-shape-skin-model-sheets.md` (new) + README line. `docs/plan/SKINS-PLAN.md` new section
  "Model sheets and the Shark Jet and Dragon builds". `docs/workshop/tools.md` sheet_model.py row.
  `docs/workshop/lessons.md` 4 lessons (plane words for creature skins; edit pixels not redraw; one view per face;
  factory cube). Checker: OK.

## POINTERS
- Sheets + briefs + Codex logs: `.planning/skins/model-sheets/` (`prompt-model-sheets-*.txt`, `log-model-sheets-*.txt`).
- Measured sheet: `.planning/skins/dragon/dragon-measured.jpg`. Tool test: `.planning/skins/shark/test-nose/`.
- Crane method and its lessons: `tools/art/crane_skin.py`, shared notes `origami-crane-handover.md`.
