# HANDOFF — 2026-11-14 — Skins: Shark nose clean; three Dragon heads tried; new Blender skill in; Dragon head starts over

**Labels:** kind=product · lane=skins-lane · branch=main · issues= · areas=tools/art/sheet_model.py, .planning/skins, .claude/skills/concept-to-blender, docs/plan/SKINS-PLAN.md, docs/decisions, docs/workshop
**Time:** 2026-11-14 17:10 -05:00

★ START HERE: Goal (Alan): shape skins that look like their model sheets; proved on the Dragon's head first. Alan's
go (2026-11-14 ~17:05, his words): "go ahead and try to build the head of the dragon, start over. use only the skills,
blender and the concept image." First action: load the upgraded `concept-to-blender` skill and follow it on
`.planning/skins/model-sheets/dragon-b8-legs.png` (head only, nose to the back of the skull plus horns). Done when the
head passes the skill's own gated checks and Alan sees it beside the sheet and says it looks like it.

> Read on demand: AGENTS.md → this file → `.claude/skills/concept-to-blender/SKILL.md`. Research behind the skill:
> `.planning/research/concept-to-3d-blender.md`. Memories: measure-concept-before-brief, no-meshy-blender-only,
> touch-up-before-showing, look-at-textures-before-upload, codex-for-pictures-and-blender.

## STATE (verify before acting)
- HEAD `66d5908e`+ (main; the commit hook pushes to GitHub). Confirm: `git log --oneline -8`.
- Docs: `python tools/check_docs.py` (OK at handoff). No game code touched. Studio not used. Nothing uploaded.
- Blender 5.1 at `D:/Blender/blender.exe` (headless works). The Blender-window route needs Blender open with its MCP
  add-on running (closed today).
- Cost this session: 1 Sonnet reviewer (~115k tokens); ~25 headless Blender builds (~10 s each); research side
  session concept-to-3d-research (~2 h, 4 reader agents); primary at ~50% context (why this handoff).

## NEXT ACTION + PLAN
1. Dragon head from scratch per the new skill. Its piece-map step asks Alan to OK the map; put the open question in
   it: **side-view plate 4 under the horn: its own blade, or the base of the horn?** (research session's map,
   `.claude/skills/concept-to-blender/example-piece-map.json`). Alan's go above covers building after that.
2. Show Alan the head beside the sheet (worst part first). If it doesn't look like the sheet, say so plainly and
   change the method before building more.
3. Then the full Dragon, then the Shark Jet (`shark-jet-a4.png`), each beside its sheet before any upload.
4. Later: Codex printed-sheet pictures for Hazard, Tiger, Flame, Gold Foil, Lava, Galaxy.
HOLDS (Alan's go, each): uploads (texture contact sheet checked for symbols, hand shapes, text first), Save to File,
publish, anything paid, any new mechanic or number, any Studio Play.

## DECISIONS & WHY (this session)
- Projection painting is out for the Dragon (Alan: "atrocious ... unusable"): it smears every surface that doesn't
  face a drawn view. It still suits a smooth body with its art on its sides (the Shark nose is clean). Recorded in the
  [shape-skin decision](../../docs/decisions/2026-11-14-shape-skin-model-sheets.md).
- Alan's hybrid idea (paint the skin from the sheet, build things that stick out as 3D pieces, cut their drawings out
  of the paint) gave the best head of the three, but Alan asked to start over with the new skill, not polish it.
- The new skill (applied with Alan's OK in the research session): numbered piece map counted across views first,
  traced shapes, gated checks; reviewer stays an Opus agent; nothing installed from GitHub (one Blender MCP project
  lets any web page run code: never use it).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (docs rules, commit by path, push each commit, model router). Shared folder: touch only skin files, never
  switch branches. Memories above. Bad news first; describe a render by its worst part.

## CARRY NOTES / GOTCHAS
- AI sheets disagree between views by ~3% of the length per part; the Dragon's FRONT view draws the head 1.6x wide;
  sheets draw a thin white halo round every shape; cream and white are close to the background grey (lessons.md).
- `tools/art/sheet_model.py` has projection, hole-filled outlines, faceted blades, scales, cut-outs and a chase
  render; Alan said start over, so use it only if the skill's steps call for it.
- Each head test folder (`.planning/skins/dragon/test-head*`) has its spec and a `for-alan.jpg`; untracked on purpose.

## WHAT SHIPPED / OTHER QUEUED
- 92dfeac7 sheet_model.py: Shark nose paints clean · 10c84e86 Dragon head test (projection) · e11ab504 Dragon head from
  measured pieces; projection dropped for the Dragon · 2ddfbb13 Dragon head with painted skin + built pieces ·
  66d5908e (research session) concept-to-blender skill upgrade, sheet_tools.py, research report · (next) this handoff.
- Queued: trails art (Confetti, Rainbow Marker, Gold Stars); Shark Jet and Dragon matching trails.

## KNOWLEDGE UPDATED
- `docs/plan/SKINS-PLAN.md`: the three head tests and "start over with the new skill". `docs/decisions/2026-11-14-shape-skin-model-sheets.md`:
  projection out for the Dragon, pieces instead. `docs/workshop/lessons.md`: outline holes, halo, views that don't draw a
  part. `docs/workshop/tools.md`: sheet_model.py row. Checker: OK.

## POINTERS
- Sheet: `.planning/skins/model-sheets/dragon-b8-legs.png`; measured sheet `.planning/skins/dragon/dragon-measured.jpg`.
- Last comparison: `.planning/skins/dragon/test-head-hybrid/for-alan.jpg` (sheet | plain pieces | hybrid).
- Research hand-over: side-session notes `blender-skill-research.md`; report `.planning/research/concept-to-3d-blender.md`.
