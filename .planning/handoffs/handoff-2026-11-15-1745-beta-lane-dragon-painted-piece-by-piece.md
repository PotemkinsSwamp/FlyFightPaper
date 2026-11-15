# HANDOFF — 2026-11-15 — Dragon: Tripo shape cleaned (3,720 triangles), painted piece by piece; gold by code still too flat

**Labels:** kind=product · lane=beta-lane · branch=main · issues= · areas=docs/decisions/2026-11-14-shape-skin-model-sheets.md, docs/workshop/lessons.md, docs/plan/SKINS-PLAN.md, state/STATE.md, .planning/skins/dragon/paint/, .planning/skins/dragon/tripo/smart-mesh/
**Time:** 2026-11-15 17:45 -05:00

★ START HERE: Goal (Alan): the best Dragon skin: Tripo's shape, painted **piece by piece** (his ruling this session). Opening action: make the gold pieces look painted, not one flat colour (Alan, last message of the session): first try a Codex painting PER gold piece (one strut alone, laid flat, filling the frame, same finish as `paint/codex/painted/chase.png`) put onto just that piece; fallback real light baked in Blender or richer code (light and dark across the piece, bright edge lines, dark grooves). Re-run `paint.py` and show Alan the player's view beside that painting. Done when Alan says the player's view is right; then the other views, then the 1024 Roblox maps and the five fit pieces.

> Read on demand: AGENTS.md → this file → `.planning/skins/dragon/paint/tools/README.md` (run order of the pipeline). The Dragon entry "paint the Tripo shape piece by piece" in `docs/decisions/2026-11-14-shape-skin-model-sheets.md`; lessons "Projecting paintings onto a model" and "Tripo Smart Mesh, as delivered" in `docs/workshop/lessons.md`. Skills: design-theory before showing pictures; concept-to-blender for model work. Memories: look-at-textures-before-upload, send-videos-not-gifs.

## STATE (verify before acting)
- HEAD: `git rev-parse --short HEAD` (this handoff's commit sits on `4ee40cec`); main; the commit hook copies to GitHub.
- Tests 650/0 from 2026-11-14; no game code changed (docs and `.planning/` art only). Docs: `python tools/check_docs.py` OK.
- Studio and Roblox untouched. Tripo credits 5,985 (three GLB downloads were free on Pro; no Smart UV bought).
- Cost this session: Fable main, ~41% context at handoff, no subagents; two Codex picture jobs on Alan's ChatGPT plan (98,681 + 105,727 tokens, ten pictures); Tripo 0 credits; no money.

## NEXT ACTION + PLAN
1. Gold pieces (17 pieces, 1,003 triangles: wing struts, tail ribs): Alan wants shading, lighter and darker gold and light line work, as in the concept; "if you're doing it by code, you're just doing one colour". Today `gold_paint` in `paint/tools/paint.py` gives each facet one tone, so a strut seen from above is one flat pale band. Order he was told: (a) a painting per piece, square-on and filling the frame; (b) baked Blender light or richer code. Check: player's view (`pass3/wear-chase.png`) beside `codex/painted/chase.png`; Alan compares.
2. Go piece by piece through the rest (the mesh is 63 separate pieces, found by shared vertices): decide per piece "painting" or "code". Likely code: horns, head plates, fin rims, claws if they still smudge. Painting: body, wing skins, legs, belly. A piece that takes a painting should take it with only that piece's own area of the picture (piece mask), not the whole dragon.
3. If painted pieces still fail for Alan: his method 2, everything by code in Blender, depth from Roblox's bump, shine and metal pictures.
4. After his OK: other views, then 1024 colour, normal, roughness, metalness maps, texture safety check (contact sheet + `tools/art/fill_gaps.py`), cut into the five fit pieces.
- HOLDS (Alan's explicit go, each): Roblox uploads, publish (he does it), place saves, desktop control or screen grabs, Studio Play while he plays, bot matches, Tripo credits beyond a Smart UV, any new mechanic or number. Codex picture jobs are fine (his plan, no money).
- Stop rule: show Alan after each pass from the player's view first; do not polish the other nine views before he accepts that one.

## DECISIONS & WHY (this session)
- **Shape = Smart Mesh version `98dd3819` (3,844 triangles)**: best outline match to the approved views (side 93%, top 96%), clean separate back fins, real toes. The 4,119 one fuses the fins, the 4,209 one has a stray spike.
- **Mesh clean-up in Blender** (`base.py`, `fix_holes.py`): wing skin was one sheet (same colour both sides), so it got twin faces; 693 faces buried inside removed; slivers whose back shows got twins. 3,720 triangles, drawn one-sided like Roblox.
- **Ten new paintings over renders of this mesh** instead of projecting the six approved ones: those follow the old Blender model's outline and smeared every thin part. The approved six were Codex's look guide. Alan has seen the result and did not object to this, but he has not approved the new paintings as designs.
- **Alan's ruling on method** (his words summarised in the decisions note): piece by piece, gold by code with line work, paintings only on smooth pieces, assemble after; fallback all code + Roblox surface pictures.
- **Player's view wins** wherever its painting sees a surface squarely (`BIAS` in `paint.py`); the flat views fill the rest.
- Not mirrored left to right: the mesh is only nearly symmetric, and cutting it added triangles.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md hard limits and docs rules; commit by path. Alan's standing notes: no Meshy, Blender only; judge from the player's view first; weapons and skins must read without explaining.
- Claude cannot make pictures: painted looks come from Codex; Claude's own painting is code in Blender.

## CARRY NOTES / GOTCHAS
- Alan's verdict on pass 1: "artifacts, blurriness, poor shaping, poor application". Pass 2 fixed the sky patch under the horn, ragged strut edges and sharpness (825 texels per length); he has not answered on pass 2 yet (`paint/dragon-players-view-pass3.jpg`).
- Chunky outline is Tripo's mesh, not paint; if Alan still dislikes the shape, more triangles would need a new Tripo run (credits: his go).
- Blender preview must use one-sided faces (`show.py` does), or wing undersides look green.
- The scripts live in `.planning/` (not in git, like all Dragon art). Promote to `tools/art/` with a docs entry once a painted Dragon is approved.
- Codex `log.txt`, `log-b.txt` sit beside the prompts in `paint/codex/`.
- Backlog after the skin (Alan): desk photos under the crane, crane gun pieces while firing, Toilet Roll shake recorder.

## WHAT SHIPPED / OTHER QUEUED
- This handoff's commit: decisions note (Dragon piece by piece), two lessons, skins plan and STATE lines, handoff, LATEST. No other commits this session.

## KNOWLEDGE UPDATED
- `docs/decisions/2026-11-14-shape-skin-model-sheets.md`: new Dragon entry (shape pick, clean-up, ten paintings, Alan's two methods, pass 2 result).
- `docs/workshop/lessons.md`: "Projecting paintings onto a model: what breaks it"; "Tripo Smart Mesh, as delivered".
- `docs/plan/SKINS-PLAN.md`, `state/STATE.md`: Dragon lines to current truth. Checker: OK (193 pages).

## POINTERS
- `.planning/skins/dragon/paint/`: `tools/` (pipeline + README), `base2.npz` (mesh), `codex/` (`renders/` starts, `painted/` ten paintings, `guide.png`, prompts), `pass3/` (`skin-color.png`, `wear-*.png`, `check-*.jpg`), `dragon-players-view-pass3.jpg`.
- `.planning/skins/dragon/tripo/smart-mesh/` (three GLBs, Tripo's texture `v2-tex-0.png`) · `six-views/final/` (approved six).
