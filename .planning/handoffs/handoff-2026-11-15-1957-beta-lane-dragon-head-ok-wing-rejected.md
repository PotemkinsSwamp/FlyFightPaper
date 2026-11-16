# HANDOFF — 2026-11-15 — Dragon: head accepted (clean shapes + bake); wing through Tripo rejected, redo structure-first

**Labels:** kind=product · lane=beta-lane · branch=main · issues= · areas=docs/decisions/2026-11-14-shape-skin-model-sheets.md, docs/workshop/lessons.md, state/STATE.md, .planning/skins/dragon/paint/tools/, .planning/skins/dragon/parts/
**Time:** 2026-11-15 19:57 -05:00

★ START HERE: Goal (Alan): a Dragon skin that looks good in the game, about 8,000 triangles, built in parts. The head is accepted. The wing I sent through Tripo is rejected ("very, very obvious problems"; "why did you feed it back through Tripo ... you had already recoloured it"; "the structure is the most important piece"). Opening action: rebuild ONE wing with no Tripo: its structure (three gold ribs, the skin sheet with the scalloped rear edge) built straight from the reference picture's outline and measurements, checked laid over that picture; then the texture put on top (Codex's finished top and underside paintings laid straight onto the flat faces, or TextureCraft materials by part). Show Alan the wing close up FIRST, then on the Dragon from the player's view. Done when Alan OKs the wing.

> Read on demand: AGENTS.md → this file → `.planning/skins/dragon/paint/tools/README.md` (last two sections: run order of the new scripts). Decision entries "Wing through Tripo: rejected", "Dragon head accepted", "eyes glow" in `docs/decisions/2026-11-14-shape-skin-model-sheets.md`; lessons "Do not send a simple, flat part through an image-to-3D tool" and "TextureCraft is a free hand-texturing app" in `docs/workshop/lessons.md`. Skills: `concept-to-blender` (measure the picture first), `design-theory` before showing.

## STATE (verify before acting)
- HEAD: this handoff's commit sits on `595d7106`; main; pushed (the commit hook copies to GitHub). Confirm: `git rev-parse --short HEAD`, `git status -sb`.
- Tests 650/0 from 2026-11-14; no game code changed this session. Docs: `python tools/check_docs.py` OK (193 pages).
- Tripo credits 5,865 (spent this session: 10 on the head's Retopo, 55 on the wing sculpt). Tripo Studio tab left open on the wing model.
- Studio: `Workspace.DragonTextureTest` deleted from Alan's open place (not saved by me). Nothing uploaded, nothing saved, no Play.
- Stray folder `C:\parts` (my mistake: a first bake wrote there; files copied into the project). A safety check blocks me from removing it; Alan was told it is safe to delete.
- Cost: Fable main, ~50% context at handoff; 2 web-fetch helpers (17,828 + 17,798 tokens); one Codex picture job (79,892 tokens, Alan's ChatGPT plan); Tripo 65 credits; no money.

## NEXT ACTION + PLAN
1. Wing, structure-first (above). Reference: `.planning/skins/model-sheets/dragon-b8-legs.png` (TOP and BOTTOM views) and Codex's paintings `.planning/skins/dragon/parts/wing/painted/front.png` (top face) and `back.png` (underside), which are orthographic, at one scale, and match the old wing's outline (`parts/wing/renders/`). Check: the built wing laid over the painting, rib for rib, before any texture; then a close-up with no cracks, slivers or stray colour.
2. Then, per part, ask first "does it need sculpting, or only a correct outline plus paint?" Tail fan and back fins are outline-plus-paint like the wing. Body with head core and the leg: decide with Alan (no verdict yet). Tripo only where sculpted detail is needed, with his go for the credits (55 each).
3. Then: the whole Dragon's pictures merged to one set (colour, bump, metal, roughness, glow), texture safety check, 1024 maps, five fit pieces, and the measured frame-rate check with 12 planes.
- HOLDS (Alan's explicit go, each): Tripo credits (tell him the count first), Roblox uploads, publish (he does it), place saves, desktop control or screen grabs, Studio Play (including the frame-rate check), bot matches, any new mechanic or number.
- Stop rule: one part at a time; show the close-up with its flaws named first; no next part before he accepts the current one.

## DECISIONS & WHY (this session)
- **Head: accepted** (Alan: "that worked pretty well for the head", "it looks pretty good"). Mine kept, 1,600 triangles; Tripo's own rebuild (Retopo, 2,352 triangles, one fused skin, soft edges) was the comparison only.
- **How the head is built** (`clean_shapes.py`): the sculpt is split along inward creases; each hard piece becomes a few straight-sided rings along its length, the body one 12-sided tube, right side mirrored. Not a reducer. Gold and body are baked apart, each from its own share of the sculpt, so colours do not bleed.
- **Eyes glow light emerald, no pupil** (Alan: "a glowing gemstone"): a glow picture baked with the others, for SurfaceAppearance EmissiveMaskContent + EmissiveTint + EmissiveStrength. Preview numbers are mine.
- **About 8,000 triangles for the Dragon** (Alan); parts that need more get more. Roblox's cap is 20,000 per mesh (official page).
- **Wing through Tripo: rejected.** I repeated the head's recipe without asking whether a wing needs sculpting. Tripo fused the two front ribs near the shoulder and roughened the skin edge; my ring shapes and bake added cracks and pale slivers. I also showed the close-up as if those were minor. Rule now in the decision page: simple parts are built from the reference and textured on top.
- One metal value per material; cream is not metal (the mask tests for strong yellow).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md hard limits and docs rules; no Meshy; judge from the player's view AND close up. Claude cannot make pictures: Codex paints, Blender builds, TextureCraft textures (scriptable: `texturecraft-cli commands`, program in `D:\TextureCraft\app`).

## CARRY NOTES / GOTCHAS
- `bake_clean.py`: give OUT_DIR as given (it makes it absolute itself); extras are `key=value` (`eye=`, `turn=wing`).
- Blender MCP was not connected; everything ran with `D:/Blender/blender.exe -b --factory-startup --python` (Blender 5.1.1).
- Tripo Retopo: four-sided without "Smart Mesh" is 10 credits, triangles 5; the Smart Mesh switch (40) turns itself back on after a run.
- The Dragon under the new parts is still the old slim placeholder (`paint/base2.npz`); the head is squeezed 20% narrower to sit on the old head's box.
- `parts/wing/tripo/wing-hd.glb` and `parts/wing/clean*` are the rejected route; keep as reference, do not build on them.
- A file `green dragon 3d model.glb` appeared in Downloads at 19:19; not from this session.
- Backlog after the skin (Alan): desk photos under the crane, crane gun pieces while firing, Toilet Roll shake recorder.

## WHAT SHIPPED / OTHER QUEUED
- `d309ff3a` Dragon head rebuilt from clean simple shapes (1,600 triangles) beside Tripo's own rebuild; Roblox's mesh cap is 20,000 triangles
- `5ef99184` STATE: Dragon lines shortened
- `ba83309c` Dragon head accepted; eyes glow light emerald (glow picture); about 8,000 triangles; wing next (Alan)
- `595d7106` Dragon wing through Tripo rejected: simple parts are built from the reference, texture on top (Alan)
- This handoff's commit: handoff + LATEST.
- Untracked work (not in git): `.planning/skins/dragon/paint/tools/` (`seg.py`, `clean_shapes.py`, `bake_clean.py`, `show_dragon.py`, `part_starts.py` now one scale + wing) and `parts/head/clean/`, `parts/wing/`, `parts/whole/`.

## KNOWLEDGE UPDATED
- `docs/decisions/2026-11-14-shape-skin-model-sheets.md`: head rebuilt and accepted; eyes glow; about 8,000 triangles; Roblox cap 20,000; wing through Tripo rejected with the new rule.
- `docs/workshop/lessons.md`: no image-to-3D for simple flat parts; cream is not gold in a metal mask.
- `state/STATE.md`: Dragon lines to current truth (61 lines, as at session start). Checker: OK (193 pages).
- Memory: `question-each-recipe-step` (new).

## POINTERS
- Pictures Alan has seen: `parts/head/head-clean-on-dragon.jpg`, `parts/head/head-clean-vs-tripo.jpg`, `parts/head/clean/blender-dragon-eye.png`, `parts/wing/painted-contact.jpg`, `parts/whole/dragon-head-and-wings.jpg` (all under `.planning/skins/dragon/`).
- Head, finished: `parts/head/clean/blender-part.npz` + `blender-color/normal/metal/rough/glow.png`, `blender.blend`.
