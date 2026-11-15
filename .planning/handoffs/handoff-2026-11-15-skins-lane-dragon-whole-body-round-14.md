# HANDOFF — 2026-11-15 — Skins lane: whole Dragon built (round 14), Alan says many problems remain and will give a new list

**Labels:** kind=product+docs · lane=skins-lane · branch=main · issues=none · areas=.planning/skins/dragon/body-fable, .planning/skins/dragon/head-fable, tools/art/sheet_model.py, docs/decisions, docs/workshop, docs/plan
**Time:** 2026-11-15 01:13 -05:00

★ START HERE: Goal (Alan): the Dragon shape skin must look like its model sheet `.planning/skins/model-sheets/dragon-b8-legs.png`. The whole dragon exists as `.planning/skins/dragon/body-fable/round-14/` (picture `body-fable/sheet-vs-model.jpg`); Alan has seen it and says "there's still a lot of problems". Opening action: wait for his new instruction list, then do one pass on a new round folder. Done = each item on his list fixed and shown to him in one sheet-beside-model picture, with what is still short stated first.

> Read on demand: `AGENTS.md` → this file → `docs/decisions/2026-11-14-shape-skin-model-sheets.md` (every ruling, in his words) → `body-fable/round-14/gen_spec.py` (every number). Skill: `concept-to-blender`. Memories: no-meshy-blender-only, measure-concept-before-brief, fix-the-annoyance-only, restyle-keeps-content.

## STATE (verify before acting)
- HEAD `af84c461` (main), pushed (the commit hook copies to GitHub). Confirm: `git rev-parse --short HEAD`.
- Docs: `python tools/check_docs.py` OK. Tool self-test: `python .claude/skills/concept-to-blender/sheet_tools.py test` OK.
- Model: `sh .planning/skins/dragon/body-fable/build.sh round-14` rebuilds it in about 40 s (spec, count check against `piece-map.json`, Blender build, piece renders, sheet-matched renders `check.jpg`, outline scores). One closed mesh, 3,334 triangles (budget 4,000), counts match the map. Outline: top 0.87, side 0.83.
- `.planning/` is not in git: the model, pictures and scripts live only on this disk.
- Studio, uploads, Save to File: not touched.
- Cost last session: 5 Opus reviewer agents (118k, 124k, 116k, 119k, 121k tokens); about 55 Blender starts; 26 build rounds (head 12, body 14); the session did three jobs (head test, whole body, three correction passes) and ended at 67% of its context (668k tokens), above the 60% stop line.

## NEXT ACTION + PLAN
1. Alan gives his list. Build it as `body-fable/round-15/` (copy `round-14/gen_spec.py`, edit numbers in place). Proof: his items visibly fixed in `check.jpg`; counts match the map; mesh closed; under 4,000 triangles.
2. Still open from his earlier lists: dark outlines where gold trim meets green skin; the talons look striped from below (facet lines).
3. After he accepts the shape: the Roblox check (skill step 9) and the Shark Jet. Both need his go.
- Stop rule for review: the independent reviewer runs once on the round Alan is about to see, not after every round. Alan's eye is the gate; build from his list, not from the reviewer's.
- HOLDS (his explicit go, each): any upload, Save to File, publish, anything paid, any Studio use or Play.

## DECISIONS & WHY (this session) — all recorded in the decision note
- **Big horns follow the three-quarter view**: lower, swept back (Alan: "they come too far up and at an angle"). Later he asked for an open V from the front, so the last segment turns out and up (tips 44 out, 82 up).
- **Tail fan stands upright in one flat vertical plane** (side view). The top and bottom views draw it flat: Alan calls that a drawing error; ignore them for the tail. I had laid it flat for one round (round 12): superseded.
- **Back = five separate hook fins**, thick gold cap, dark green web, alternating sideways curve. No continuous gold band.
- **Legs come from `create_detailed_leg()`**: scaled pod + 3 thick talons (35% of the pod's length, bases touching, curving down and back).
- **Wings**: 5 px thick skin, three diamond-section struts from one hub at the wing root, tapering to a point; tan underside; no trailing-edge trim.
- **Belly**: smooth tan from chin to tail with two lengthwise creases, tan jaw, no cross bands.
- **Piece 3 (small horn 2) is built** although the decision note once said to leave the "plate under the horn" out: the three-quarter and top views show it.
- **Gold pieces are thick six-sided ridged tubes** (`phase` 30, `roll`), not `plate()`; that is what made the head read as plates.
- Side outline score is capped: the sheet's side view still draws the old high horns.

## CONSTRAINTS / PRINCIPLES
- `AGENTS.md` (plain English to Alan, hard limits), skill `concept-to-blender`, `docs/decisions/2026-11-13-skin-rules.md`. All 3D in Blender (`D:/Blender/blender.exe`), no Meshy. Budget: one closed mesh, 4,000 triangles, one 1024 picture set.

## CARRY NOTES / GOTCHAS
- Alan's lists arrive as pasted "problems" + "what I want" text: build exactly those items; where one conflicts with an earlier ruling, say so in the report's first lines.
- A strut thinner than half the wing skin's thickness vanishes inside it (round 13). `strut()` keeps it proud.
- Pixel readings: top view X = px - 33, Y = 663 - py; side view X = px - 25, Z = 296.5 - py; length 544. Check a zoomed crop's origin before reading (I misread the belly by 8 px).
- `python body-fable/profile.py ROUND` prints the side outline, sheet against model, in numbers: cheaper than a picture.
- Bash tool: a heredoc containing `\'` fails; write such scripts with the Write tool (`setup_round*.py` are those).
- Over Remote Control no new session can be started or offered; at the desktop the "New session / Do it here" card works.
- The talons and fin caps are faceted with dark lines; `smooth: true` on a part gives one plain colour, smooth-shaded.
- The wing texture is 1024 for the whole dragon: veins cannot be crisper than about 2 px of the sheet.

## WHAT SHIPPED / OTHER QUEUED
- `13d5ebe4` Sheet builder: tube roll and phase, body shape lists, bottom line, facet shading
- `81714286` Skins: Alan on the rebuilt head
- `46c267a0` Skins: horn ruling and go for the whole body
- `80acabee` Sheet builder: thin slabs, underside colour, bounce light
- `9e49f155` Skins: whole Dragon first build recorded
- `519265e8` Skins: Alan's corrections and the correction pass; layered scales, belly plates, scaled pieces, veins
- `f33558f6` Skins: Alan's problem list and round 12; smooth pieces, belly creases, scale outline strength
- `af84c461` Skins: Alan's second list and round 14
- Not in git: `head-fable/` (head, 12 rounds, `compare.jpg`, blind result: this head closer than the Opus head in 3 of 4 views), `body-fable/` (14 rounds).
- Queued: Shark Jet build; Dragon Roblox check; folding the method into the skill (proposal below, needs Alan's OK).

## KNOWLEDGE UPDATED
- `docs/decisions/2026-11-14-shape-skin-model-sheets.md`: Alan's verdict on the head, the horn and tail rulings, both problem lists in his words, where round 14 stands.
- `docs/workshop/lessons.md` (Making 3D models): contradicting sheet views, thick ridged tubes, struts inside thick skins, measure in numbers, how far to trust the reviewer.
- `docs/plan/SKINS-PLAN.md`: the Dragon's current state. Checker: OK.
- Proposed, NOT applied (needs Alan's OK): edit `.claude/skills/concept-to-blender/SKILL.md` so that (1) gold pieces default to thick ridged tubes instead of `plate()`, (2) contradicting views go to Alan as a question before that piece is built, (3) sheet-matched renders and the numeric profile are the standard look, (4) the reviewer's angle claims are checked against the scores.

## POINTERS
- Hand-over notes with more detail: `C:\Users\gutie\AppData\Roaming\Claude\side-session-notes\local_9d0b23f5-faf0-472c-acef-d44be96f7522\dragon-body-fable-run.md` and `dragon-head-fable-run.md`.
- Scripts: `body-fable/build.sh`, `render_views.py`, `profile.py`, `setup_round1.py` / `8` / `11` / `13` (how each big round was derived); `tools/art/sheet_model.py` (docstring lists every spec key).
- Pictures: `body-fable/sheet-vs-model.jpg`, `body-fable/piece-map.png`, `head-fable/compare.jpg`.
