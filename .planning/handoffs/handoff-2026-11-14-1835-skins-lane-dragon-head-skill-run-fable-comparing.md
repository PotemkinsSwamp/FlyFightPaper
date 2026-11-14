# HANDOFF — 2026-11-14 — Skins: Dragon head built with the skill (top 0.908, reviewer "not yet"); Fable 5.2 run comparing

**Labels:** kind=product · lane=skins-lane · branch=main · issues= · areas=.planning/skins/dragon/head-skill, tools/art/sheet_model.py, .claude/skills/concept-to-blender, docs/decisions, docs/plan/SKINS-PLAN.md, docs/workshop/tools.md
**Time:** 2026-11-14 18:35 -05:00

★ START HERE: Goal (Alan): shape skins that look like their model sheets, proved on the Dragon's head. This session's
skill run reached a recognisable head, but not one that looks like the sheet. Alan: "the skills definitely helped, but I
just don't think you have the capability". He started a **Fable 5.2 run of the same skill from scratch** (side session
[dragon-head-fable](#local_4e61fa22-f699-417f-a288-64c04eb70d6d), effort high, Opus reviewer). First action: read that
session's final report and `.planning/skins/dragon/head-fable/compare.jpg` (sheet | this run's round 7 | Fable's head,
judged blind by its Opus reviewer), check its scores yourself (`sheet_tools.py score`), and show Alan the comparison,
worst part first. Done when Alan picks which head (or method or model) carries on to the full Dragon.

> Read on demand: AGENTS.md → this file → `.claude/skills/concept-to-blender/SKILL.md` only if you build. Memories:
> side-session-pricier-model, measure-concept-before-brief, no-meshy-blender-only, touch-up-before-showing.

## STATE (verify before acting)
- HEAD `ed8f60d0`+ (main; the commit hook pushes to GitHub). Confirm: `git log --oneline -5`.
- Docs: `python tools/check_docs.py` (OK at handoff). No game code touched. Studio not used. Nothing uploaded.
- Fable session: may still be running, or finished. Check with `list_sessions {"linked": true}`. If its first turn ran on
  Opus, it was told to delete that output and start over on Fable. Its files are in `.planning/skins/dragon/head-fable/`.
- Cost this session: 1 Opus reviewer agent (~130k tokens, 2.5 min); ~15 headless Blender builds (~10 s each); local
  Python checks; primary at ~42% context at handoff (why this handoff). Fable session's cost is in its own report.

## NEXT ACTION + PLAN
1. Compare (above). If Fable's head is clearly closer, its method and model carry on; if neither looks like the sheet,
   say so plainly and ask Alan before building more heads (three earlier tests plus this one have missed).
2. Then the full Dragon, then the Shark Jet (`shark-jet-a4.png`), each beside its sheet before any upload.
3. Later: Codex printed-sheet pictures for Hazard, Tiger, Flame, Gold Foil, Lava, Galaxy.
HOLDS (Alan's go, each): uploads (texture contact sheet checked for symbols, hand shapes, text first), Save to File,
publish, anything paid, any new mechanic or number, any Studio Play.
Stop rule: no fifth head from the same method without Alan naming what to change; one reviewer pass per candidate.

## DECISIONS & WHY (this session)
- **Dragon sheet's side view is least trusted** (Alan): build from top, three-quarter and front; the side gives heights
  only. Per side: accent blade ahead of the eye, two small horns above the eye, big horn, eye, eye-to-mouth trim, cheek
  guard, snout rim; the side-only plate under the horn is dropped. Recorded in the shape-skin decision page.
- Blade and horn heights kept only half the side view's climb (`RISE = 0.5`, `make_spec.py`): the reviewer saw them
  rise at twice the sheet's angle ("antlered creature"); this costs side score (0.92 → 0.85), on purpose.
- Head body painted with its own scales (no projection), so no drawn copies of blades land on the skin.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (docs rules, commit by path, push each commit, model router). Shared folder: the Fable session works in
  `head-fable/`; never touch it while it runs. Bad news first; describe a render by its worst part.

## CARRY NOTES / GOTCHAS
- Round 7 still short (reviewer, round 4 list): front-view horns are wide flat slabs (sheet: narrow spikes); face gold
  plates thin and gappy (sheet: thick, packed); head an egg from the front; small coin scales everywhere.
- `sheet_tools.py score` used to read the background from a crop's corners and gave a false 0.475; fixed (whole sheet).
- `start_session` ignores a pricier model (memory side-session-pricier-model).
- `make_spec.py` reads the old `test-head-hybrid/spec.json` for views, review crops and the body base settings.

## WHAT SHIPPED / OTHER QUEUED
- ed8f60d0 Skins: sheet_model builds traced plates; sheet_tools renders piece and silhouette checks, scorer reads the
  background from the whole sheet; Dragon side view ranked last (Alan) · (next) this handoff + skins plan update.
- Queued: trails art (Confetti, Rainbow Marker, Gold Stars); Shark Jet and Dragon matching trails.

## KNOWLEDGE UPDATED
- `docs/decisions/2026-11-14-shape-skin-model-sheets.md`: Alan's view ranking and the head's piece reading.
- `docs/plan/SKINS-PLAN.md`: the skill run's result and the Fable comparison. `docs/workshop/tools.md`: sheet_model
  builds traced plates. Skill `SKILL.md`: `views` command, scorer note, master views can be re-ranked by Alan.
- Memory: side-session-pricier-model (new). Checker: OK.

## POINTERS
- This run: `.planning/skins/dragon/head-skill/` (`piece-map.json/png`, `trace-spec.json`, `pieces.json`,
  `make_spec.py`, `round-07/for-alan.jpg`, `round-07/render-*.png`, scores in each round's `score-*.png`).
- Sheet: `.planning/skins/model-sheets/dragon-b8-legs.png`.
