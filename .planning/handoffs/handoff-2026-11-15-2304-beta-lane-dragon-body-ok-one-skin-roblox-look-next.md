# HANDOFF — 2026-11-15 — Dragon: body accepted with one skin from nose to tail; next is loading it into Roblox to look at it

**Labels:** kind=product · lane=beta-lane · branch=main · issues= · areas=docs/decisions/2026-11-14-shape-skin-model-sheets.md, docs/workshop/lessons.md, state/STATE.md, .planning/skins/dragon/paint/tools/, .planning/skins/dragon/parts/body/, .planning/skins/dragon/parts/head/reskin/
**Time:** 2026-11-15 23:04 -05:00

★ START HERE: Goal (Alan): a Dragon skin that looks good in the game. Every part is now accepted (body: "its good enough"), 7,964 triangles, one skin from nose to tail. Opening action, on Alan's go ("lets load the model into the game and see what it looks like when its in roblox"): get the Dragon into Roblox Studio so he can look at it under Roblox's own light. Done when he has seen it there and said what he thinks. The texture safety check comes BEFORE any upload (his account was banned twice over a texture).

> Read on demand: AGENTS.md → this file → `.planning/skins/dragon/paint/tools/README.md` (last section: body and one skin) → `docs/workshop/lessons.md` ("Uploads and Roblox moderation" before uploading). Memories: `one-skin-across-parts`, `look-at-textures-before-upload`, `roblox-mesh-import-gotchas`, `powershell-commands-for-alan`, `studio-play-is-shared`.

## STATE (verify before acting)
- HEAD: this handoff's commit sits on `b77f8988`; main; GitHub copy pushed by the commit hook (plain `git push` has no upstream: normal here). Confirm: `git rev-parse --short HEAD`.
- Tests 650/0 from 2026-11-14; no game code changed. Docs: `python tools/check_docs.py` OK (193 pages).
- Tripo credits 5,820 (none spent). Nothing uploaded, nothing saved, no Studio, no Play, no desktop control.
- Playtest notes: asked; none given (nothing is in the game yet).
- Cost: Fable main only, about 45% context at handoff, no helper agents. Two Codex picture runs on Alan's ChatGPT plan: 46,660 and 107,321 tokens (I had quoted about 47,000 for the second). No money.

## NEXT ACTION + PLAN
1. The Dragon into Roblox for Alan to look at. What it needs, in whatever order is cheapest: the parts' pictures as Roblox can take them (each part has its own colour, bump, metal, roughness set today; the head also a glow), the texture safety check on every picture that gets uploaded (contact sheet looked at, no bent-arm crosses, square spirals or paired bolts), the mesh exported facing the right way, then the upload. Check: Alan sees it in Studio and gives his verdict; compare how the matte finish and the join read there against `parts/body/seam-after.jpg`.
2. From his verdict: the leftovers below, then re-seat fins and legs on the new body, merge to one picture set at 1024, five fit pieces, the measured frame-rate check with 12 planes.
- HOLDS (Alan's explicit go, each): the upload itself is GO (quoted above). Still his go, each: any Tripo credits (tell him the count first), publish (he does it), place saves, desktop control or screen grabs, Studio Play (including the frame-rate check), bot matches, any new mechanic or number.
- Stop rule: nothing after the Roblox look before he has given his verdict on it.

## DECISIONS & WHY (this session)
- **Body accepted** ("its good enough") after three rejections, each his words: "fully inconsistent with the head" (I had matched the final views' finer, flatter scales, not the head); "a huge visible seam" (two scale designs met in a straight cut); "you can see the seam this is not seamless" (the cut left behind the eye, and the join from below).
- **The head is the standard, not the final views:** scale size (row 0.023), colours and bump depth were measured on the head. So the body's scales are bigger and its belly is big yellow V plates, unlike the sheet. Told to Alan.
- **One skin over the whole head tube**, written into a COPY of the head's pictures (`parts/head/reskin/`); gold, horns and eye untouched; the accepted head's files are unchanged, so it can be undone.
- **The body's first ring copies the head tube's 12-sided outline**, then eases to an ellipse: same shape either side of the join.
- **The upload jumps the queue** ahead of re-seating and merging: Alan wants to see it in Roblox first.
- My numbers he saw only as results: `ROWS` 4.5, `PLATE` 0.035, `BUMP` 0.34, split 0.37, the eye's rim 0.019 + 0.008, `HOLD` 0.012, `MELT` 0.09.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md hard limits and docs rules; no Meshy; Blender only; Codex paints (`codex exec -s workspace-write - < prompt.txt`, never `--model`); judge from the player's view AND close up, joins first (`one-skin-across-parts`).

## CARRY NOTES / GOTCHAS
- Open flaws, all told to Alan: a hairline at the join at far zoom (head side about 10% brighter in the side view; cause not found, the shapes now match); a leftover old chevron on the jaw (from below); fins and legs not re-seated (fin roots 0.004 to 0.013 into the back, no daylight); the belly's small step under the eye is the head's own shape.
- `show_dragon.py` must be given `parts/head/reskin/blender`, not `parts/head/clean/blender`, or the old seam is back.
- `body_build.py` must run before `head_reskin.py` (it writes `skin.npz`); the `HEAD` and `HEAD_END` tables in it were measured from the head with `uv_raster.py` and pasted in.
- The head's `eye=` bake values are still not written down: do not re-bake the head.
- STATE.md is 61 lines (limit 60; it was 61 at session start).
- Carried: stray folder `C:\parts` is safe for Alan to delete; backlog after the skin: desk photos under the crane, crane gun pieces while firing, Toilet Roll shake recorder.

## WHAT SHIPPED / OTHER QUEUED
- `b77f8988` Dragon body accepted with one skin from nose to tail; Roblox look next (Alan)
- This handoff's commit: handoff + LATEST.
- Untracked work (not in git, under `.planning/skins/dragon/`): new `paint/tools/body_build.py`, `head_reskin.py`, `uv_raster.py`, `body_sheet.py`; changed `show_dragon.py` (views `body-*`, `join-*`, `head-*`, `VIEWS=`), `README.md`; `parts/body/` (prompt, guides, painted, built, work), `parts/head/reskin/`, `parts/whole4/`.

## KNOWLEDGE UPDATED
- `docs/decisions/2026-11-14-shape-skin-model-sheets.md`: body accepted, the three rounds in his words, what is still open, the upload go.
- `docs/workshop/lessons.md`: parts that touch wear one skin and share one outline; fin notches are not the back line; cut a repeat tile from the middle of a generated swatch, quote Codex cost as a range.
- `state/STATE.md`: Dragon lines to current truth. Checker: OK (193 pages).
- Memory: `one-skin-across-parts` (new).

## POINTERS
- Pictures Alan has seen: `parts/body/seam-after.jpg` (the two views he circled, fixed), `parts/body/work/head-join-after.jpg` (head and join close), `parts/body/body-close.jpg` (beside the final views), `parts/whole4/dragon-new-body.jpg` (player's view).
- The whole Dragon: the `show_dragon.py` line in the README's last section. Each part's files: `parts/<part>/.../TAG-part.npz` + `TAG-color/normal/metal/rough[/glow].png`. `export_fbx.py` exists from an earlier round (check it still fits).
