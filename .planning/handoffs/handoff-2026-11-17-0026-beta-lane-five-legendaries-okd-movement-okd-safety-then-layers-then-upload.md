# HANDOFF — 2026-11-17 — All five Legendaries have Alan's OK; four safety sheets done; movement for four skins OK'd as videos; nothing uploaded

**Labels:** kind=product+docs · lane=beta-lane · branch=main · issues=none · areas=tools/art/sheet_model.py, .planning/skins/safety, .planning/skins/motion, .planning/skins/hot_rod/build, docs/decisions, docs/workshop, state
**Time:** 2026-11-17 00:26 -05:00

★ START HERE: Goal (Alan 2026-11-16): finish the beta's looks; the Legendary skins now, and each gets a small animation ("these legendaries need just a little more"). Opening action: the Ninja's safety check (`.planning/skins/ninja/build/tail-10/`, his OK is in its own session), told to Alan as a plain safe / not safe verdict with any risk shown on the plane, never as a texture sheet. Done when he has the verdict. Nothing is uploaded and nothing is in the game.

> Read on demand: AGENTS.md → THIS; then only what the step touches. Rulings in his words: `docs/decisions/2026-11-14-shape-skin-model-sheets.md` (last three bullets before "Why"). Lessons: `docs/workshop/lessons.md` ("Uploads and Roblox moderation", "Moving skin layers"). Upload path used for the Dragon: `.planning/skins/dragon/paint/tools/README.md`. Memories: show-risks-on-the-plane (new), look-at-textures-before-upload, visual-qa-before-showing, edit-tests-have-plugin-rights, plan-before-building-features, effects-are-3d-shown-in-3d.

## STATE (verify before acting — state drifts between sessions)
- HEAD `e4255fd2` (main) before this handoff's commit, pushed (GitHub copy). Confirm: `git rev-parse --short HEAD`.
- Tests: none run (no Play). Last known: 672 passed in Play. Docs: `python tools/check_docs.py` OK.
- Studio: the cloud place "FlyFightPaper(First Fold)" was open in Edit; one Edit-only test ran (three Dragons with Rare layers, `Archivable = false`, removed after two screen grabs). Nothing saved, no Play. Tripo credits 5,820 (none used). No Codex here.
- Cost this session: four reviewer subagents (Opus): 137,069 · 126,598 · 112,331 · 114,532 tokens (490,530 in all). The Ninja's side session has its own totals. Main session context at handoff: about 48%.

## NEXT ACTION + PLAN
1. **Ninja safety check** (`tail-10`, 2,166 triangles, one 1024 set). Tools: `.planning/skins/safety/` (`uv_dump.py` in Blender, then `sheet.py NAME ROUND UV.npy OUT`). Check: every picture looked at by me and one independent reviewer, gaps filled, no pinwheel layout (its build predates `uv.upright`: look at how its big pieces lie; a re-lay is one spec key plus a numbers comparison).
2. **The moving-layer pictures for the four OK'd movements**, each a how-it-works note to Alan first where it adds anything he has not seen, then pictures, then their safety check. What he OK'd (videos in `.planning/skins/motion/<skin>/<skin>.mp4`, numbers in `preview.py` there):
   - Stealth: lines breathe; one comet of light runs down them nose to tail every 2 s, with a soft purple spill beside the lines. Its glow lines become a layer seen from above, which replaces the risky UV glow picture (two bent bright lines on black: do not upload `stealth-glow.png` as it is).
   - Hot Rod: painted flames roll steadily back; fire burns from the nozzle and pops from the four pipes in turn.
   - Race Car: a crisp slanted shine streak crosses nose to tail in 1 s, every 2 s, dim on the spoiler.
   - Shark: every 4 s twin sheets of spray from the nose back, outward and low; a bright water line runs down the skin at the spray's speed, wet-dark skin behind it that dries.
   Open design work (mine to propose): which parts are Decal layers (Top and Bottom faces only), which are small real parts or Roblox particles (nozzle fire, spray), and how a skin's layers are described in config. Check: it runs as the game's own code in Play on his go, and the frame rate is measured.
3. **Upload all five together** (his plan; each upload on his go after its safety check): Shark `chin-13`, Stealth `whole-06` (colour and normal only), Race Car `whole-09`, Hot Rod `whole-06` (re-laid, OK'd), Ninja `tail-10`. Then per skin a `config/skin-shapes.json` entry with a `SkinFit.spec` case, a printed-sheet picture for boosters, tests in Play, his Play look.
4. Then: the other four Legendaries (Bumblebee, Rocket, Mech, Pirate; build them with `uv.upright` from the start), the shop list of 13 trails, worst-case frame rate, a trail in the Hangar, Dragon leftovers.
- **HOLDS (Alan's explicit go, each):** any Studio Play (tests included), place saves, publish (he does it), desktop control or screen grabs, Tripo credits (tell him the count first), bot matches, any new mechanic or number, every upload. Every picture or model: his OK on a preview, then the safety check, then upload.
- **Stop rule for reviews:** one independent reviewer pass per new preview before Alan sees it; fix its "no" items once, then show him with what is left named first. No second pass on a timing or paint-only tweak.

## DECISIONS & WHY (this session; all in the decision page in his words)
- **Race Car "it's fine"; Hot Rod's re-laid picture "that's fine"** (`whole-06` replaces `whole-05`: same mesh, every texture piece the same way up, 16% fewer texels per length, six views within 1 of 255).
- **The Stealth keeps its glow** ("It needs the glow. The glow is important") and it moves, "the same treatment as the rare skins".
- **Legendaries get small animations**, as many as fit. All four previews OK'd; the Shark's first idea (sun-on-water net) "just looks bad", replaced on his idea by the breach splash, which "should pair with a skin animation", and "the shine needs to follow the water".
- **A flat texture picture means nothing to him**: verdicts in plain words, risks shown on the plane.
- **Mine, told to him:** strict "every piece the same way up" over a tighter pack that allowed half turns (5% loss instead of 16%): the claim "no piece is turned against another" is worth more than sharpness nobody can see.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md hard limits; Blender only (no Meshy); concept-to-blender skill for models with a sheet; visual-qa-before-showing; look-at-textures-before-upload; show-risks-on-the-plane; fix-the-annoyance-only; plain words, bad news first.

## CARRY NOTES / GOTCHAS
- **The movement videos are Blender mock-ups.** Paint movement is masked to up/down-facing surfaces to match what a Decal can do; the comet's purple spill, the nozzle fire and the spray have no game design yet.
- The Dragon test proved a layer Decal sits on a shape skin's one mesh (Top and Bottom, glow works) with plugin rights in Edit only: prove it from a LocalScript in Play before calling it working.
- Stealth's glow in the UV picture also lights its trailing-edge strips, which face backward: a Top/Bottom layer will not cover them; decide (bright paint, or a small glowing part).
- Low risks named to Alan and left as they are: Stealth's colour picture has the same bent lines in purple on grey; the Shark's teeth are a black-and-white zigzag.
- My two slips, both caught: a `#` note typed mid-line in Hot Rod's `make_spec.py` switched off five settings (found by the reviewer, fixed, rebuilt); a multi-replace script that failed half way saved nothing and I rendered the old file once. A long Bash command (over about 8,000 characters) is cut off here: write long files with the Write tool.
- `.planning/` is not in git (only handoffs): safety sheets, motion videos and build rounds exist on this disk only.
- Carried, still unanswered: delete the 8 stray pictures in `C:\.planning\skins\shark\test-nose`? Dead Shark files (`front_face.py`, `shark-jet-a4-face.png`, `--no-chin`) to delete when `make_spec.py` is next open.
- The Hot Rod session's `upload-brief.md` is superseded by this handoff (its step 1 is done a different way: rebuilt, not transferred).

## WHAT SHIPPED / OTHER QUEUED
- `eb45360f` Model builder can lay every texture piece the same way up; the lesson and where the safety sheet tools live
- `c9cdcbb4` Safety sheets for Shark, Stealth, Race Car and Hot Rod are with Alan
- `e9e5c503` Alan: Race Car and the re-laid Hot Rod are fine; the Stealth keeps its glow; Legendaries get small animations
- `a095c5ed` Lesson: a Rare-style moving layer also sits on a Legendary's 3D shape
- `680eeab4` Movement previews for four Legendaries are with Alan
- `fa68b477` Alan OK'd the Stealth, Hot Rod and Race Car movement; the Shark gets a breach splash
- `e4255fd2` Alan OK'd the Shark's breach splash with its water line on the skin; the Ninja has his OK
- Queued (not started): everything in NEXT ACTION 1 to 4.

## KNOWLEDGE UPDATED
- `docs/decisions/2026-11-14-shape-skin-model-sheets.md`: three new bullets (safety sheets and "Legendaries move"; movement previews; the Shark breach), all in his words.
- `docs/workshop/lessons.md`: pinwheel layouts and `uv.upright`; "same model, new layout" proven with numbers; a layer Decal sits on a shape skin; movement lessons from five preview rounds.
- `docs/workshop/tools.md`: `sheet_model.py` gains `uv.upright`. `state/STATE.md`: the "Now" paragraph (58 lines).
- Memory: new `show-risks-on-the-plane`. Checker: `python tools/check_docs.py` OK.

## POINTERS
- Safety: `.planning/skins/safety/` (`uv_dump.py`, `sheet.py`, `sheets/<skin>-sheet.jpg`, `sheets/hot_rod-old-vs-new.jpg`).
- Movement: `.planning/skins/motion/preview.py` (one branch per skin; Blender makes frames, plain Python makes the mp4) and the four videos.
- Builds: Shark `.planning/skins/shark/build/chin-13/`, Stealth `stealth/build/whole-06/`, Race Car `race_car/build/whole-09/`, Hot Rod `hot_rod/build/whole-06/`, Ninja `ninja/build/tail-10/`.
- Rares' moving-layer code to build on: `src/client/PlaneLooks.luau`, `src/shared/SkinMotion.luau`, `config/skin-motion.json`, `tools/art/skin_looks.py`; shape skins: `src/client/SkinShapes.luau`, `config/skin-shapes.json`.
