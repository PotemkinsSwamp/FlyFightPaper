# HANDOFF — 2026-11-17 — Ninja safe; the five real moving-layer pictures are made; four rebuilt movement videos are with Alan

**Labels:** kind=product+docs · lane=beta-lane · branch=main · issues=none · areas=.planning/skins/motion, .planning/skins/safety, docs/decisions, docs/workshop, state
**Time:** 2026-11-17 19:51 -05:00

★ START HERE: Goal (Alan 2026-11-16): finish the beta's looks; the Legendary skins now, each with a small animation. Opening action: get Alan's verdict on the four rebuilt movement videos (`.planning/skins/motion/<skin>/real/<skin>-approved-above-rebuilt-below.mp4`: his OK'd video on top, the version drawn from the real layer pictures below). Done when he has said yes or named what to change. Nothing is uploaded and nothing is in the game.

> Read on demand: AGENTS.md → THIS; then only what the step touches. Rulings in his words: `docs/decisions/2026-11-14-shape-skin-model-sheets.md` (last bullets before "Why"). Lessons: `docs/workshop/lessons.md` ("Uploads and Roblox moderation", "Moving skin layers"). Memories: show-risks-on-the-plane, look-at-textures-before-upload, visual-qa-before-showing, edit-tests-have-plugin-rights, plan-before-building-features.

## STATE (verify before acting — state drifts between sessions)
- HEAD `2bd4bc05` (main) before this handoff's commit, pushed (GitHub copy). Confirm: `git rev-parse --short HEAD`.
- Tests: none run (no Play). Last known: 672 passed in Play. Docs: `python tools/check_docs.py` OK.
- Studio: not touched. Place not saved. Tripo credits 5,820 (none used). No Codex.
- Cost this session: two Opus reviewers, 113,018 (Ninja pictures) and 144,334 (movement videos) tokens; Blender renders on this PC (~15 min). Main session context not measured. Model switched to Opus 5.5 at handoff.

## NEXT ACTION + PLAN
1. **Alan's verdict on the four rebuilt videos.** Differences named to him, worst first: Stealth lines a little whiter; its body-side line and trailing-edge strips do not glow (a layer from above cannot reach them); Hot Rod flames a touch more yellow; flames and comet move on top surfaces only. Fire and spray are still Blender stand-ins (in the game: Roblox particles).
2. **Safety check of the five layer pictures** (`.planning/skins/motion/<skin>/layers/`: `stealth-lines.png`, `stealth-comet.png` (4 x 4 flipbook), `hot_rod-flames.png` (4 x 4 flipbook), `race_car-shine.png`, `shark-water.png`), told to Alan as safe / not safe with risk shown on the plane. Watch hardest: `stealth-lines.png` is bright bent lines on black/clear, the same shapes as the glow picture that must not be uploaded.
3. **Upload all five skins and the layer pictures together**, each on his go: Shark `chin-13`, Stealth `whole-06` (colour and normal only, NOT `skin-glow.png`), Race Car `whole-09`, Hot Rod `whole-06`, Ninja `tail-10`.
4. **Game code**, plan note to Alan first (a flipbook layer is a new kind): Decals on the shape skin's mesh (Top; Stealth lines also Bottom), flipbook = three Decals in a ring (last frame fading out, this frame, next fading in; two Decals stepped visibly), `config/skin-motion.json` entries, `SkinFit.spec` cases, `config/skin-shapes.json` entries, nozzle fire and spray as particles. Check: runs as the game's own code in Play on his go, frame rate measured.
5. Then his Play look; then the other four Legendaries (Bumblebee, Rocket, Mech, Pirate; `uv.upright` from the start), the shop list of 13 trails, worst-case frame rate, a trail in the Hangar, Dragon leftovers.
- **HOLDS (Alan's explicit go, each):** any Studio Play (tests included), place saves, publish (he does it), desktop control or screen grabs, Tripo credits (tell him the count first), bot matches, any new mechanic or number, every upload. Every picture or model: his OK on a preview, then the safety check, then upload.
- **Stop rule for reviews:** one independent reviewer pass per new preview; fix its "no" items once, then show him with what is left named first. No second pass on a timing or paint-only tweak.

## DECISIONS & WHY (this session)
- **Ninja: "its safe i looked at it"** (Alan). The reviewer agreed (colour low risk: one curled red sash piece alone on black; bump safe). Recorded in the decision page.
- **Movement that follows the paint is a flipbook** (mine): a Decal cannot be masked by another picture, so rolling flames and a comet down the lines are 16 frames in one 4 x 4 picture. Movement that ignores the paint (shine, water line) stays one sliding picture. Layer pictures are drawn tail at top, nose at bottom: no quarter turn.
- **Stealth's glow is now a layer picture** (lines from above, left half; from below, right half) and the comet's spill stops at any step in the surface, so it no longer washes over the raised slats (the reviewer's main "worse" point).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md hard limits; Blender only; visual-qa-before-showing; look-at-textures-before-upload; show-risks-on-the-plane; fix-the-annoyance-only; plain words, bad news first.

## CARRY NOTES / GOTCHAS
- **The game's glow is not the preview's glow.** The preview lit the comet by its see-through amount x 10; a Decal with no glow picture glows by its colour picture (lessons.md). Expect the comet and spill to need retuning in Play.
- The Stealth's body-side line and trailing-edge strips face sideways or backward: no Top/Bottom layer covers them. Options if Alan minds: bright paint, or a small glowing part.
- Hot Rod's flame layer moves over the top only (2.5 s per plane length; its video is 5 s, twice the loop).
- `.planning/` is not in git: `layers.py`, `preview.py` (new `PICTURES_DIR` argument), the pictures and videos live on this disk only.
- My slip, second time: a `#` note typed mid-line swallowed a statement (`layers.py`, caught by the error it caused). Now a lesson in `lessons.md`; if it happens a third time, it is a CLAUDE.md rule candidate.
- Carried, still unanswered: delete the 8 stray pictures in `C:\.planning\skins\shark\test-nose`? Dead Shark files (`front_face.py`, `shark-jet-a4-face.png`, `--no-chin`) to delete when its `make_spec.py` is next open.

## WHAT SHIPPED / OTHER QUEUED
- `9224a797` Ninja's pictures are safe (Alan looked; the reviewer agreed); lesson: movement that follows the paint is a flipbook
- `2bd4bc05` The five real moving-layer pictures are made; four rebuilt movement videos are with Alan
- Queued (not started): NEXT ACTION 2 to 5.

## KNOWLEDGE UPDATED
- `docs/decisions/2026-11-14-shape-skin-model-sheets.md`: the Ninja safety bullet, in his words.
- `docs/workshop/lessons.md`: flipbook layers; check a rebuilt effect frame by frame against the approved video; no `#` mid-line.
- `state/STATE.md`: "Now" paragraph and a new first line under "Waiting on Alan" (59 lines). Checker: `python tools/check_docs.py` OK.

## POINTERS
- Layers and videos: `.planning/skins/motion/layers.py`, `preview.py`, `<skin>/layers/`, `<skin>/real/` (rebuilt video, side-by-side video, `compare.jpg`).
- Safety: `.planning/skins/safety/` (`sheets/ninja-sheet.jpg` new, `ninja-uv.npy`).
- Builds: Shark `.planning/skins/shark/build/chin-13/`, Stealth `stealth/build/whole-06/`, Race Car `race_car/build/whole-09/`, Hot Rod `hot_rod/build/whole-06/`, Ninja `ninja/build/tail-10/`.
- Game code to build on: `src/client/PlaneLooks.luau`, `src/shared/SkinMotion.luau`, `src/client/SkinShapes.luau`, `config/skin-motion.json`, `config/skin-shapes.json`, `tools/art/skin_looks.py`.
