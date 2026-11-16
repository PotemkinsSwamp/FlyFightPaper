# HANDOFF — 2026-11-15 — Dragon: legs and back fins accepted, finish made matte; the body is the last part (outline plus paint)

**Labels:** kind=product · lane=beta-lane · branch=main · issues= · areas=docs/decisions/2026-11-14-shape-skin-model-sheets.md, docs/workshop/lessons.md, state/STATE.md, .planning/skins/dragon/paint/tools/, .planning/skins/dragon/parts/
**Time:** 2026-11-15 22:15 -05:00

★ START HERE: Goal (Alan): a Dragon skin that looks good in the game, about 8,000 triangles, built in parts. Accepted: head, both wings, tail fan, four legs, five back fins = 6,908 triangles, all in a matte finish. Opening action: build the BODY, the last part, by outline plus paint (Alan's ruling: no Tripo): one smooth closed tube read off the final side, top and bottom views (`.planning/skins/dragon/parts/body/final-body.jpg`, already shown to him), Codex paints the green back scales and the cream belly plates to wrap round it, about 1,100 triangles. Show him the close-up beside the final views with flaws named first, then the Dragon from the player's view. Done when Alan OKs the body.

> Read on demand: AGENTS.md → this file → `.planning/skins/dragon/paint/tools/README.md` (last three sections: leg, fins, matte finish). Decision entries from "Folded leg accepted" down in `docs/decisions/2026-11-14-shape-skin-model-sheets.md`. Memories: `latest-approved-reference-first`, `question-each-recipe-step`. Skills: `concept-to-blender`, `design-theory` before showing.

## STATE (verify before acting)
- HEAD: this handoff's commit sits on `e0e909c8`; main; pushed. Confirm: `git rev-parse --short HEAD`, `git status -sb`.
- Tests 650/0 from 2026-11-14; no game code changed. Docs: `python tools/check_docs.py` OK (193 pages).
- Tripo credits 5,820 (45 spent on the leg). Nothing uploaded, nothing saved, no Studio, no Play, no desktop control. Alan's Chrome still has the Tripo Studio tab open on the leg model.
- Playtest notes: none (Alan: "Nothing has been uploaded").
- Cost: Fable main only, about 50% context at handoff, no helper agents. Two Codex picture jobs on Alan's ChatGPT plan: leg views 77,509 tokens, fin 69,445 tokens. 45 Tripo credits. No money.

## NEXT ACTION + PLAN
1. The body (above). Check: close-up beside the final views' crop, then the player's view; the old body's see-through holes and the orange specks at the fin roots must be gone. The old body is 312 triangles still drawn by `show_dragon.py`; the new body replaces all of it.
2. Re-seat what stands on the body: the fins' roots follow the OLD body's back (`back()` in `fin_build.py`), the legs sit in a box read off the final views (`box=` in the leg's bake line). Check both for daylight once the new body is in.
3. Then: all pictures merged to one set (colour, bump, metal, roughness, glow), texture safety check, 1024 maps, five fit pieces, the measured frame-rate check with 12 planes.
- HOLDS (Alan's explicit go, each): any Tripo credits (tell him the count first), Roblox uploads, publish (he does it), place saves, desktop control or screen grabs, Studio Play (including the frame-rate check), bot matches, any new mechanic or number.
- Stop rule: reference crop shown before a build; close-up with flaws named first; nothing after the body before he accepts it.

## DECISIONS & WHY (this session)
- **Leg accepted** ("look fine I guess"). Tripo read "three claws in every view" as a 3 by 3 block of NINE claws. Kept: the three on the slant (outer-top, middle, inner-bottom), the one layout that shows three from the side and from below; the six others are painted over green (`nogold=1`). One tube + three claws, 357 triangles, drawn four times (`@0.265` = hind legs). Tripo at 2K texture = 45 credits, not 55.
- **Back fins accepted** ("ok it's good"). Alan picked outline plus paint. ONE fin (fin 2) painted by Codex, built as a gold spine on a thin web, drawn five times, each stretched to its own size and bowed sideways in turn as the top view draws them. 780 triangles. Fin 1 therefore lacks its taller web: he was told and accepted.
- **Matte finish, for every part** (Alan: "wrapped in plastic ... too much reflection"). Measured: previews lit 2.3 times too bright, gold mirroring the sky. Now gold metal 0.15, gold roughness 0.6, the rest roughness 0.9; preview = sun 1.4 + even white light 0.55 from all round. Built and reference agree within a few percent on gold and green. The brown bands he circled under the spines were undersides left dark by the old test light.
- **Body: outline plus paint** (Alan: "we can go with your body recommendation").
- My numbers he saw only as results: the leg's box on the Dragon, claws fattened 1.3 times, fin spine width 0.175 and bow 0.13 of a fin's length, roots sunk 15%.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md hard limits and docs rules; no Meshy; judge from the player's view AND close up. Claude cannot make pictures: Codex paints (`codex exec -s workspace-write - < prompt.txt`, never `--model`), Blender builds (`D:/Blender/blender.exe -b --factory-startup --python`).

## CARRY NOTES / GOTCHAS
- Before showing any render, compare the mean gold and green against the reference crop (reference fins strip: gold 216, 173, 54; green 20, 105, 32); a matched preview is what Alan judges.
- How the matte finish reads under Roblox's own light is unknown until a Studio check (his go).
- Codex saved the fin painting 1254 px square and with a slightly uneven background, though told 1024 and flat: resize and threshold, don't trust the brief.
- The head's and leg's metal and roughness pictures were rewritten in place to the matte numbers (no re-bake). The head's `eye=` values are not written down anywhere, so do not re-bake the head.
- Legs barely show from the player's view; blank green patches on the toe ends; both accepted.
- A Bash call holding several heredocs with backticks failed to parse here: write long files with the Write tool.
- STATE.md is 61 lines (limit 60; it was 61 at session start).
- Carried: stray folder `C:\parts` is safe for Alan to delete; backlog after the skin: desk photos under the crane, crane gun pieces while firing, Toilet Roll shake recorder.

## WHAT SHIPPED / OTHER QUEUED
- `694fabb7` Dragon folded leg built from a Tripo sculpt (45 credits); waiting on Alan's OK
- `126bd81c` Dragon folded leg accepted; back fins next (Alan)
- `008d9edb` Dragon back fins built from one painting; finish made matte after Alan's 'wrapped in plastic'
- `e0e909c8` Dragon back fins and matte finish accepted; body next, outline plus paint (Alan)
- This handoff's commit: handoff + LATEST + the body ruling.
- Untracked work (not in git): `.planning/skins/dragon/paint/tools/` (new: `leg_starts.py`, `leg_sheet.py`, `fin_start.py`, `fin_build.py`, `fin_sheet.py`; changed: `clean_shapes.py`, `bake_clean.py`, `part_starts.py`, `show_part.py`, `show_dragon.py`, `fan_lib.py`) and `parts/leg/`, `parts/fins/`, `parts/body/`, `parts/whole3/`.

## KNOWLEDGE UPDATED
- `docs/decisions/2026-11-14-shape-skin-model-sheets.md`: leg accepted (nine claws, three kept); fins accepted (method, numbers); the matte finish and why; body ruling.
- `docs/workshop/lessons.md`: Tripo turns a row seen from two sides into a block, 2K texture is 45 credits; painted skins want a matte finish and a preview measured against the reference.
- `state/STATE.md`: Dragon lines to current truth. Checker: OK (193 pages).

## POINTERS
- Pictures Alan has seen (under `.planning/skins/dragon/`): `parts/leg/leg-close.jpg`, `parts/fins/fins-close.jpg`, `parts/whole3/dragon-new-legs.jpg`, `parts/whole3/dragon-matte.jpg`, `parts/body/final-body.jpg`.
- The Dragon wearing every finished part: `show_dragon.py -- paint/base2.npz paint/pass6/skin-color.png parts/whole3/dragon parts/head/clean/blender parts/wing/built/wing:mirror parts/tail/built/tail parts/leg/clean/leg:mirror parts/leg/clean/leg@0.265:mirror parts/fins/built/fins`.
- For the body: `clean_shapes.py`'s `loft()` (tubes) and `fan_lib.py`, Codex's scale swatch `parts/leg/painted/scales.png`, the reference `six-views/final/`.
