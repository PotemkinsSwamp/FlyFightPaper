# HANDOFF — 2026-11-15 — Dragon: wing and tail fan accepted (built from paintings, no Tripo); pod legs were the wrong design; folded leg gets sculpted next

**Labels:** kind=product · lane=beta-lane · branch=main · issues= · areas=docs/decisions/2026-11-14-shape-skin-model-sheets.md, docs/workshop/lessons.md, state/STATE.md, .planning/skins/dragon/paint/tools/, .planning/skins/dragon/parts/
**Time:** 2026-11-15 20:38 -05:00

★ START HERE: Goal (Alan): a Dragon skin that looks good in the game, about 8,000 triangles, built in parts. Accepted so far: head, wing (both sides), tail fan = 4,700 triangles. Opening action: make ONE folded leg (rounded thigh, shin folded back under it, three toes, three straight gold claws) by the head's recipe: show Alan the leg's crop from the final views first (`.planning/skins/dragon/parts/leg/final-legs.jpg`), Codex paints that one leg's four views, Tripo sculpts it, rebuild in clean shapes, bake, show the close-up with flaws named first, then on the Dragon from the player's view. Done when Alan OKs the leg.

> Read on demand: AGENTS.md → this file → `.planning/skins/dragon/paint/tools/README.md` (last four sections). Decision entries from "Wing built from the painting: accepted" down in `docs/decisions/2026-11-14-shape-skin-model-sheets.md`. Memories: `latest-approved-reference-first` (new), `question-each-recipe-step`. Skills: `concept-to-blender`, `design-theory` before showing.

## STATE (verify before acting)
- HEAD: this handoff's commit sits on `6d0a7cfb`; main; pushed. Confirm: `git rev-parse --short HEAD`, `git status -sb`.
- Tests 650/0 from 2026-11-14; no game code changed. Docs: `python tools/check_docs.py` OK (193 pages).
- Tripo credits 5,865 (none spent this session). Nothing uploaded, nothing saved, no Studio, no Play, no desktop control.
- Cost: Fable main only, about 50% context at handoff, no helper agents. Two Codex picture jobs on Alan's ChatGPT plan: tail side view 55,181 tokens, leg scale swatch 56,819 tokens. No money.

## NEXT ACTION + PLAN
1. The folded leg (above). **The Dragon's reference is `.planning/skins/dragon/six-views/final/` (six 1536 x 1024 views), NOT `model-sheets/dragon-b8-legs.png`.** Alan's go is already given (asked with the cost, 2026-11-15): "Sculpt in Tripo" = 55 credits (tell him the count again before spending: 5,865 → 5,810), driving Tripo Studio in his Chrome, one model download. One leg is built, then placed four times (front and hind, mirrored). Check: close-up beside the final views' crop; then the player's view.
2. Then back fins (Claude's lean: outline plus paint, each a curved gold blade) and the body (lean: lofted tube with a wrapped scale texture; Codex's swatch `parts/leg/painted/scales.png` is ready). Ask Alan "sculpting, or outline plus paint?" for each before any Tripo, and show him the final-view crop first.
3. Then: all pictures merged to one set (colour, bump, metal, roughness, glow), texture safety check, 1024 maps, five fit pieces, the measured frame-rate check with 12 planes.
- HOLDS (Alan's explicit go, each): Tripo credits beyond the leg's 55 (tell him the count first), Roblox uploads, publish (he does it), place saves, desktop control or screen grabs, Studio Play (including the frame-rate check), bot matches, any new mechanic or number.
- Stop rule: one part at a time; reference crop shown before the build; close-up with flaws named first; no next part before he accepts the current one.

## DECISIONS & WHY (this session)
- **Wing accepted** ("the wings look good"): Codex's top painting read column by column (outline, rib edges, the bright ridge line, tip caps), three ribs + one skin sheet built to those numbers, painting laid on top; underside skin wears the underside painting with its gold painted out; rib undersides wear the top's gold so paint and shape always agree. 1,130 triangles a wing.
- **Tail fan accepted and KEPT** ("the tail looks great"; later "Keep the one I built"): Alan first flagged the old placeholder tail ("huge gaps"), so it was thrown out; Codex painted a fresh side view and the same method read it in rings round the hub. 840 triangles, 0 see-through gaps (the builders count them now). It was measured from the older b8 sheet (five wide blades) and differs from the final view (bent top bar, three thin ribs with knobs); Alan was shown both and kept mine. Do not redo it unless he asks.
- **Pod legs: wrong design, deleted.** I measured the legs off the b8 sheet (plain pods + talons). Alan: "that's the wrong leg ... we redid the legs ... an actual folded leg". Script and build removed. The lean I gave him before looking (sculpting) was right for the real design; my switch to "no sculpting needed" came from reading the wrong picture.
- Rib height (a quarter of rib width each side), skin thickness, the tail's hub position (x 0.845, z -0.034) and its size (about 7% under the sheet so the Dragon keeps its length) are my numbers; Alan saw the results, not the numbers.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md hard limits and docs rules; no Meshy; judge from the player's view AND close up. Claude cannot make pictures: Codex paints (`codex exec -s workspace-write - < prompt.txt`, never `--model`), Blender builds (`D:/Blender/blender.exe -b --factory-startup --python`).

## CARRY NOTES / GOTCHAS
- My repeated slip (three times): patching these one-line-per-statement scripts by string replace and ending the replacement with a `#` comment when more code followed on that line; it silently commented the rest out. Put comments on their own line.
- In my Blender renders the undersides of ribs look dark brown: the test light only comes from above. Unknown in game until a Studio check (needs Alan's go).
- The old body has see-through spots near the hind legs from below (old placeholder, one-sided); it shows once the old legs are off. Goes away with the body rebuild; tell Alan before he sees it.
- `show_dragon.py` now also renders `-tail` and `-legs` close views; `show_part.py ... upright` is for parts standing on the centre line.
- STATE.md is 61 lines (limit 60; it was 61 at session start).
- Carried: stray folder `C:\parts` is safe for Alan to delete; backlog after the skin: desk photos under the crane, crane gun pieces while firing, Toilet Roll shake recorder.

## WHAT SHIPPED / OTHER QUEUED
- `57f16d08` Dragon wing rebuilt from the painting's outline, no Tripo; waiting on Alan's OK of the close-up
- `b03fb781` Dragon wing accepted: built from the painting's outline, paint on top; tail fan next (Alan)
- `dbb8d32d` Dragon tail fan rebuilt solid from the design sheet's side view; waiting on Alan's OK
- `b1a25f6a` Dragon tail fan accepted: solid, built from a fresh side painting; leg next (Alan)
- `6d0a7cfb` Dragon legs: pods were the wrong design (old sheet); folded leg gets sculpted in Tripo, tail kept (Alan)
- This handoff's commit: handoff + LATEST.
- Untracked work (not in git): `.planning/skins/dragon/paint/tools/` (new: `fan_lib.py`, `wing_build.py`, `tail_build.py`, `show_part.py`; changed: `part_starts.py`, `show_dragon.py`) and `parts/wing/built/`, `parts/tail/`, `parts/leg/`, `parts/whole2/`.

## KNOWLEDGE UPDATED
- `docs/decisions/2026-11-14-shape-skin-model-sheets.md`: wing accepted; tail accepted and kept though it differs from the final view; pod legs wrong, folded leg sculpted in Tripo with Alan's go for 55 credits.
- `docs/workshop/lessons.md`: before building a part, find the LATEST approved picture of it and show Alan the crop first.
- `state/STATE.md`: Dragon lines to current truth. Checker: OK (193 pages).
- Memory: `latest-approved-reference-first` (new).

## POINTERS
- Pictures Alan has seen (under `.planning/skins/dragon/`): `parts/wing/built/wing-close.jpg`, `wing-over-painting.jpg`; `parts/tail/built/tail-close.jpg`, `tail-sheet-painting-built.jpg`, `tail-final-vs-built.jpg`; `parts/whole2/dragon-new-tail.jpg`; `parts/leg/final-legs.jpg`.
- Finished parts: `parts/head/clean/blender-*`, `parts/wing/built/wing-*`, `parts/tail/built/tail-*`. The Dragon wearing them: `show_dragon.py -- paint/base2.npz paint/pass6/skin-color.png parts/whole2/dragon parts/head/clean/blender parts/wing/built/wing:mirror parts/tail/built/tail`.
- The head's recipe (what the leg follows): README sections "Parts and bake" and "Clean shapes, then bake"; the head's Codex brief `parts/head/prompt.txt`.
