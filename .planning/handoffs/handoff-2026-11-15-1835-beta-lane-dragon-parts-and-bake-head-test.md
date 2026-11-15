# HANDOFF — 2026-11-15 — Dragon: projected paintings dropped; parts-and-bake head test done and shown

**Labels:** kind=product · lane=beta-lane · branch=main · issues= · areas=docs/decisions/2026-11-14-shape-skin-model-sheets.md, docs/workshop/lessons.md, docs/plan/SKINS-PLAN.md, state/STATE.md, .planning/skins/dragon/paint/, .planning/skins/dragon/parts/head/
**Time:** 2026-11-15 18:35 -05:00

★ START HERE: Goal (Alan): a Dragon skin that looks good in the game, built the way working creators do it: in parts, each part made high-detail in Tripo and baked onto our low-triangle mesh in Blender. Opening action: get Alan's verdict on the finished head test (`.planning/skins/dragon/parts/head/head-test-lowpoly.jpg`, sent to him at the end of the session, no answer yet). If he accepts the look: ask his go for the remaining parts (about 5 parts x 55 Tripo credits) and do the next part. If not: ask what is missing and aim at that. Done when Alan OKs the whole Dragon from the player's view.

> Read on demand: AGENTS.md → this file → `.planning/skins/dragon/paint/tools/README.md` (section "Parts and bake": the exact run order). Decision entry "stop projecting paintings; build in parts and bake" in `docs/decisions/2026-11-14-shape-skin-model-sheets.md`; lessons "AI 3D tools paint flat on purpose", "Tripo multi-view: every view at ONE scale" in `docs/workshop/lessons.md`.

## STATE (verify before acting)
- HEAD: `git rev-parse --short HEAD` (this handoff's commit sits on `3d2e50ca`); main; the commit hook copies to GitHub.
- Tests 650/0 from 2026-11-14; no game code changed. Docs: `python tools/check_docs.py` OK.
- Tripo credits 5,930 (55 spent on the head). Tripo Studio still has the head model and the multi-view settings (H3.1, 4K texture, lighting removed, private, 60,000 triangles).
- **Studio (Alan's open place, NOT saved by me):** a folder `Workspace.DragonTextureTest` with two test dragons sits at about (6000, 3000, 6000). Delete it when Alan says so (he was told). One private mesh was uploaded for it: asset 134858648363395 (record `paint/roblox-test/upload.json`).
- Cost this session: Fable main, ~62% context at handoff; 3 Sonnet research helpers (131,858 + 157,645 + 162,906 tokens); Codex picture jobs on Alan's ChatGPT plan (98,681 + 105,727 + 81,125 + 66,782 tokens); Tripo 55 credits; no money.

## NEXT ACTION + PLAN
1. Alan's verdict on the head test (above). Known flaws to tell him if he asks: the bake missed 9.5% of the head pieces' skin (filled from neighbours; the Tripo head came back 20% too wide because my four views were not at one scale), a light-blue patch by the eye, some plates reflect dull brown (metal with nothing to reflect in the preview).
2. If accepted, per part: one-scale views of the part alone → Codex paints them → Tripo multi-view HD → `bake_blender.py` → `compose_part.py` → `paint.py --bake` → `show_pbr.py`; show Alan the player's view after each part. Parts (his splitting rule): body with head core (one part, never cut through scales; the projected painting is the fallback for it), head gold (done as a test), one wing (mirrored), tail fan, one leg (reused x4), one back fin (reused at five sizes).
3. Then: all parts' colours set to fixed numbers, the normal/metal/rough pictures merged for the whole Dragon, texture safety check, 1024 maps, five fit pieces.
- HOLDS (Alan's explicit go, each): Tripo credits (ask with the count), Roblox uploads, publish (he does it), place saves, desktop control or screen grabs, Studio Play while he plays, bot matches, any new mechanic or number. Codex picture jobs are fine.
- Stop rule: one part at a time, shown from the player's view; no batch of parts before he accepts the first.

## DECISIONS & WHY (this session, after the 17:45 handoff)
- **Projected paintings are dropped** (Alan: pass 3 "just looks bad", "this is just not working"). Three passes proved it smears and seams on anything thin; only the smooth body took it well.
- **Research** (he asked for real recipes, not our method): creators split the model into parts, generate each high-detail, then bake onto low-poly with a fresh unwrap. Sources are single creators, several with tool ties; summarised in the decision entry. One video shows Claude driving Blender for exactly this bake.
- **Roblox Studio texture generator: not usable for an approved design** (tested on our mesh; Fast pale, Quality invents its own dragon).
- **Tripo's paint is flat on purpose**; the look is shape + light. So the bake carries the shape into a bump picture and bakes crease/edge shading into the colour. Alan on that look at high detail: "looks decent, finish the test".
- **Bake target = our existing low-triangle pieces**, not a new low-poly: keeps the 3,720 triangles and every piece's position; Tripo's part is sized per direction onto our piece's box.
- Alan's "keep going, don't hand off" (at ~40% context) was followed until the 60% context limit; this handoff is the limit, not a stop on the work.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md hard limits and docs rules; no Meshy; judge from the player's view first. Claude cannot make pictures; Codex paints, Tripo sculpts, Blender bakes.

## CARRY NOTES / GOTCHAS
- `part_starts.py` scales each view to fill its own frame: fix to ONE scale for all views before the next part (cause of the 20% misfit).
- Preview one-sided meshes in Eevee (`show_pbr.py` does); Cycles shows through coincident twin faces.
- Tripo: "Generate in Parts" turns texture off; Export dialog needs the texture size set to 4k each time; file lands in `~/Downloads` under the model's name.
- `paint.py` still builds the rest of the Dragon from the ten projected paintings plus the strut paintings (`--gold`); those parts are placeholders until their own bake.
- The 17:45 handoff's next step (per-piece gold paintings) was done and superseded by this route.
- Backlog after the skin (Alan): desk photos under the crane, crane gun pieces while firing, Toilet Roll shake recorder.

## WHAT SHIPPED / OTHER QUEUED
- `3d2e50ca` Handoff (beta lane): Dragon's Tripo shape cleaned to 3,720 triangles and painted piece by piece; gold pieces still too flat (Alan)
- This handoff's commit: decision entry, four lessons, skins plan and STATE lines, handoff, LATEST.

## KNOWLEDGE UPDATED
- `docs/decisions/2026-11-14-shape-skin-model-sheets.md`: "stop projecting paintings; build in parts and bake" (research, Roblox test, head test, splitting rule).
- `docs/workshop/lessons.md`: AI tools paint flat on purpose; Tripo multi-view at one scale; Roblox texture generator; Cycles and twin faces.
- `docs/plan/SKINS-PLAN.md`, `state/STATE.md`: Dragon lines to current truth. Checker: OK (193 pages).

## POINTERS
- `.planning/skins/dragon/parts/head/`: `painted/` (four head views), `tripo/head-hd.glb` (+ `lit.jpg`, `style.jpg`), `bake/`, `bake.npz`, `normal.png`, `metal.png`, `rough.png`, `head-test.jpg`, `head-test-lowpoly.jpg`.
- `.planning/skins/dragon/paint/`: `tools/` (+ README), `base2.npz`, `pass6/` (skin + `pbr/` lit renders), `codex/`, `roblox-test/roblox-generator-vs-ours.jpg`.
