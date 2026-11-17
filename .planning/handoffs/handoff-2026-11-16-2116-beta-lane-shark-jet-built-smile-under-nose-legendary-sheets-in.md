# HANDOFF — 2026-11-16 — Shark Jet built in Blender (smile on the underside of the nose) and eight Legendary sheets redone from Alan's pictures: both wait on Alan

**Labels:** kind=product+docs · lane=beta-lane · branch=main · issues=none · areas=tools/art/sheet_model.py, .claude/skills/concept-to-blender, .planning/skins/shark, .planning/skins/model-sheets/legendary, docs/decisions, docs/workshop, state
**Time:** 2026-11-16 21:16 -05:00

★ START HERE: Goal (Alan 2026-11-16): finish the beta's looks; the Legendary skins now, the Shark Jet first. Two things are in front of Alan and neither has his answer: (1) the Shark Jet preview, round `whole-12` (`.planning/skins/shark/build/whole-12/mouth-views.jpg` and `check.jpg`): the smooth painted head with Codex's smile painted on the underside of the nose; (2) the eight Legendary model sheets (`.planning/skins/model-sheets/legendary/legendary-sheets.jpg`). Opening action: ask Alan for his verdict on both, the Shark first, and build what he says. Done when he has OK'd the Shark preview or given his list for it. Nothing is uploaded and nothing is in the game.

> Read on demand: AGENTS.md → THIS; then only what the step touches. The Shark's whole story and every ruling: `docs/decisions/2026-11-14-shape-skin-model-sheets.md` (the "Shark Jet" bullet and the "other eight Legendaries" bullet). Lessons: `docs/workshop/lessons.md`, end of "Making 3D models". Memories: latest-approved-reference-first, restyle-keeps-content, fix-the-annoyance-only, no-meshy-blender-only, look-at-textures-before-upload.

## STATE (verify before acting — state drifts between sessions)
- HEAD `18582317` (main), pushed (GitHub copy). Confirm: `git rev-parse --short HEAD`.
- Tests: none run this session (no Studio, no Play). Last known: 672 passed in Play (previous handoff). Docs: `python tools/check_docs.py` OK at the last commit. Skill self-test: `python .claude/skills/concept-to-blender/sheet_tools.py test` OK.
- Studio: not touched. Place not saved. Tripo credits 5,820 (none used). Nothing uploaded.
- Shark build, last round: `python .planning/skins/shark/build/front_face.py whole-08` → `python .planning/skins/shark/build/make_spec.py ROUND` → `python tools/art/sheet_model.py .planning/skins/shark/build/ROUND/spec.json` → `python .claude/skills/concept-to-blender/match_views.py .planning/skins/shark/measure/piece-map.json .planning/skins/shark/build/ROUND` (and `sheet_tools.py map / numbers`). Player's-eye pictures: `D:/Blender/blender.exe -b ROUND/model.blend --python .planning/skins/shark/build/player_view.py -- ROUND`. `whole-12`: 1,738 triangles, one 1024 picture set, every piece within 20% of its card, outline match 0.95 top / 0.97 side (measured on `whole-03`, same outline).
- Cost this session: 2 reviewer agents (Opus, 114,733 and 130,447 tokens). Codex (Alan's ChatGPT plan): front view 55,327; Legendary sheets first batch 466,678 (wrong, my brief) plus a reworded retry of three (count not read); redo 313,467; third try of two 77,480. Main session context at handoff: about 75%.

## NEXT ACTION + PLAN
1. **Alan's verdict on the Shark preview (`whole-12`).** Check: his OK, or his list built and shown again (flaws first, the views he circled before: head-on, a little below, a little above, passing by, exactly side, exactly front, underneath).
2. On his OK, each on his go: the safety sheet of its pictures (gap fill, look at every picture) → upload → Studio look → `config/skin-shapes.json` entry (the Dragon's fit code is config-driven; prove it with a `SkinFit.spec` case) + a printed-sheet picture for boosters in `config/looks.json` → tests in Play → his Play look. Water Spray trail last (3D preview video first).
3. **Alan's look at the eight Legendary sheets.** None is measured: each needs the concept-to-blender skill's sheet check (clash check, impossible drawings, piece map) before anything is built. Whether each is a whole shape or add-on pieces is his call, one by one.
4. Then, from the earlier plan: the shop list of 13 trails (price parked), the worst-case frame rate, a trail on the plane in the Hangar, his Play look at the trails and Rares, Dragon leftovers.
- **HOLDS (Alan's explicit go, each):** any Studio Play (tests included), place saves, publish (he does it), desktop control or screen grabs, Tripo credits (tell him the count first), bot matches, any new mechanic or number, every upload. Every picture or model: his OK on a preview, then the safety sheet, then upload.

## DECISIONS & WHY (this session; all in the decision page in his words)
- **Shark Jet is a whole shape and is the hitbox** like the Dragon (Alan: "Whole shape", "Yes"). Built without Tripo.
- **The back is roof-shaped, not round** (my call, told to him): the side view draws the box 13 px and the rails 11 px tall, which only fits rails on a sloped shoulder.
- **The head's shape is fixed** (Alan: "no we cant change the head shape"). No blunter snout, no steps.
- **The mouth:** the sheet's mouth stops at the sides and that is the sheet's mistake (Alan). Codex redrew the front view with a full grin (`.planning/skins/shark/front/painted/front.png`, OK'd by Alan: "Ok put that mouth on the model"). A stepped head matched it head-on but showed lines at an angle: Alan called it a visual break. Final instruction: "paint it the same as you did before but add the smile to the bottom side of the point so it lines up." `whole-12` does that (`front_face.py`): each underside point gets the colour Codex's picture has where that point is seen from dead ahead.
- **Wings are painted from the top view on both faces; the fold box from the side view's strip** (the top view draws a flat copy of the fin on the box).
- **Legendary sheets are drawn from Alan's approved concept pictures, unchanged** (`legendary-1.png`, `legendary-2.png`, one cut-out per skin as `design.png`). My first batch described the skins in my own words and was wrong.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md hard limits; no Meshy (Blender only); the concept-to-blender skill for every model with a sheet; latest-approved-reference-first (now also: in a picture brief the approved picture is the design); look-at-textures-before-upload; plain words for Alan, bad news first.

## CARRY NOTES / GOTCHAS
- **Known short on `whole-12`, told to Alan:** head-on the smile is the middle of Codex's grin under the nose with the side teeth fanning beside it, smaller than his picture; from straight underneath it is stretched along the nose; the cream changes tone where the side and bottom pictures meet; fin and tail tips a little blunt; paint only as sharp as the sheet.
- The independent reviewer said "not yet" on `whole-03` (fold box a grey brick: fixed in `whole-04`, not re-reviewed; teeth showing from below: superseded by the mouth work). No reviewer has seen `whole-12`.
- Ninja sheet: the silver wing plates are four-point stars. Look hard before any upload (the ban lesson).
- Bumblebee sheet: the tail fins may be drawn lying flat in the top and bottom views (not measured).
- Codex's picture filter refuses "stealth", "fighter", "ninja", weapon words, and a cut-out that still carries the written name.
- `sheet_model.py` front paint and the `terrace` (steps) option were added and taken out again; the file is back at commit `0e7cbffa`'s version. `match_views.py` gained `boxes` (hand-given close-up crops for a module that is paint).
- A long Bash command (over about 8,000 characters) is cut off on this machine: write files with the Write tool.
- Blender writes a relative output path to `C:\`: pass absolute paths (`player_view.py` now does). `C:\.planning\skins\shark\test-nose` holds 8 old stray pictures from the 14th: asked Alan whether to delete, no answer.
- I committed `tools/art/hero.py.old` (not mine) with a `git add -A`; taken back out of git in `18582317`, the file is still on disk. It is in the pushed history of `e6de478d`. Commit by explicit path.
- Rounds `whole-01` … `whole-11`, `body-*`, `back-*`, `wing-*`, `tail-*` under `.planning/skins/shark/build/` are superseded scratch; `whole-12` is current. `whole-08/mesh.npz` is read by `front_face.py` for the head's outline.

## WHAT SHIPPED / OTHER QUEUED
- `ef1a1082` Shark Jet: Alan's rulings, the how-we-make-it plan and the measured sheet's numbers
- `0e7cbffa` Shark Jet built in Blender from its sheet; the model builder learns folded fins, a paper-cone head, per-piece paint views
- `fd7f56d0` Alan's ruling that the mouth carries under the nose
- `b4985aa3` Alan's correction: Codex redraws the front view
- `8a2ed7b5` Codex's front grin on the model's underside (first fit)
- `5c7c281b` a stepped head (later rejected); briefs sent for the other eight Legendary sheets
- `429db6dc` State: the stepped head shows lines; five sheets in, three re-sent
- `e6de478d` steps taken out, Codex's smile on the underside; the eight sheets redone from his approved pictures
- `18582317` `tools/art/hero.py.old` taken back out of git
- Queued (not started): everything in NEXT ACTION 2 to 4; promoting the Dragon's shared scripts to `tools/art/` if reused.

## KNOWLEDGE UPDATED
- `docs/decisions/2026-11-14-shape-skin-model-sheets.md`: the Shark Jet bullet (rulings, method, every mouth round in his words) and a new bullet for the eight Legendary sheets.
- `docs/decisions/2026-11-13-skin-rules.md`, `docs/plan/SKINS-PLAN.md`: the Shark Jet is a whole shape and the hitbox.
- `docs/workshop/lessons.md` ("Making 3D models"): painting a smooth model from its sheet (four traps); a needle nose cannot show a face head-on; in a picture brief the approved picture is the design.
- `state/STATE.md`: the "Now" paragraph (58 lines). Checker: `python tools/check_docs.py` OK.
- Memory `latest-approved-reference-first`: extended with the picture-brief rule.

## POINTERS
- Shark: `.planning/skins/shark/measure/` (piece map, masks, scripts), `.planning/skins/shark/build/` (`make_spec.py` holds every number; `front_face.py`; `player_view.py`), `.planning/skins/shark/front/` (Codex's front view and its brief).
- Legendary sheets: `.planning/skins/model-sheets/legendary/` (`make_briefs.py`, `template.txt`, `<id>/design.png`, `<id>/<id>-sheet.png`).
- Builder and checks: `tools/art/sheet_model.py`, `.claude/skills/concept-to-blender/` (SKILL.md, `sheet_tools.py`, `match_views.py`).
- Upload path used for the Dragon: `.planning/skins/dragon/paint/tools/README.md` ("Into Roblox", "The game's Dragon").
