# HANDOFF — 2026-11-16 — Shark Jet OK'd (chin with the grin wrapped round it); Stealth, Race Car and Hot Rod OK'd in their own sessions; Ninja waits; all five upload together

**Labels:** kind=product+docs · lane=beta-lane · branch=main · issues=none · areas=tools/art/sheet_model.py, .planning/skins/shark/build, .planning/skins/stealth, .planning/skins/race_car, .planning/skins/hot_rod, .planning/skins/ninja, docs/decisions, docs/workshop, state
**Time:** 2026-11-16 22:48 -05:00

★ START HERE: Goal (Alan 2026-11-16): finish the beta's looks; the Legendary skins now. The Shark Jet has his OK ("looks good", `.planning/skins/shark/build/chin-13/`), and his plan is "lets wait for the ninja then upload all at the same time". Opening action: ask Alan where the Ninja stands (its session waits on him: he and it agreed a new concept picture of the tail comes first), and meanwhile make the safety sheet (every picture of every texture, looked at, gaps filled) for the four skins that are OK'd: Shark, Stealth, Race Car, Hot Rod. Done when the four safety sheets are in front of Alan with anything risky named first. Nothing is uploaded and nothing is in the game.

> Read on demand: AGENTS.md → THIS; then only what the step touches. The Shark's whole story: `docs/decisions/2026-11-14-shape-skin-model-sheets.md` (the "Shark Jet" bullet). Lessons: `docs/workshop/lessons.md`, end of "Making 3D models". Upload path used for the Dragon: `.planning/skins/dragon/paint/tools/README.md`. Memories: visual-qa-before-showing, look-at-textures-before-upload, fix-the-annoyance-only, no-meshy-blender-only, side-session-pricier-model.

## STATE (verify before acting — state drifts between sessions)
- HEAD `92dd67d5` (main) before this handoff's commit, pushed (GitHub copy). Confirm: `git rev-parse --short HEAD`.
- Tests: none run (no Studio, no Play this session). Last known: 672 passed in Play. Docs: `python tools/check_docs.py` OK at the last commit.
- Studio: not touched. Place not saved. Tripo credits 5,820 (none used). No Codex this session (the Ninja session may ask for one tail picture).
- Shark, rebuild in order: `python .planning/skins/shark/build/make_spec.py ROUND` → `python tools/art/sheet_model.py .planning/skins/shark/build/ROUND/spec.json` → `python .planning/skins/shark/build/mouth_views.py ROUND` (13 views on one page) → `python .claude/skills/concept-to-blender/match_views.py .planning/skins/shark/measure/piece-map.json .planning/skins/shark/build/ROUND` and `sheet_tools.py numbers` (same map, `ROUND/mesh.npz`). `chin-13`: 2,186 triangles, closed mesh, every piece within its card.
- Cost this session: six reviewer subagents (Opus): 140,317 · 145,752 · 152,916 · 139,310 · 142,274 · 125,119 tokens (845,688 in all). Four side sessions on Fable 5.2 at extra-high effort (Stealth, Ninja, Race Car, Hot Rod): their own totals are in their sessions. Main session context at handoff: about 60%.

## NEXT ACTION + PLAN
1. **Safety sheets for the OK'd skins, shown to Alan** (Shark `chin-13`, Stealth `whole-06`, Race Car `whole-09`, Hot Rod `whole-05`). Check: every texture looked at for banned shapes, said plainly. Known flags: the Hot Rod session reported its four wing faces laid a quarter turn from each other round a middle in the picture file (a pinwheel look) as a must-fix before upload: confirm in `whole-05` whether that was fixed. The Shark's texture background is now navy: one look in the game for a dark fringe on cream edges.
2. **The Ninja**: its session ([skin-ninja], `local_ad2a3e67-dc82-4a32-b0a5-a4c97bab76cc`) waits on Alan; the tail needs a new concept picture first, then a rebuild, his OK, its safety sheet. Its star-shaped wing plates were swapped for a safe shape in its own session: check the final texture anyway.
3. **Upload all five together** (Alan's words; still each upload on his go after its safety sheet) → Studio look → per skin a `config/skin-shapes.json` entry (whole shape = hitbox, proven with a `SkinFit.spec` case) and a printed-sheet picture for boosters in `config/looks.json` → tests in Play → his Play look. Shark's Water Spray trail last (3D preview video first).
4. Then: the other four Legendaries (Bumblebee, Rocket, Mech, Pirate: sheets in `.planning/skins/model-sheets/legendary/`, none measured), the shop list of 13 trails (price parked), the worst-case frame rate, a trail on the plane in the Hangar, his Play look at the trails and Rares, Dragon leftovers.
- **HOLDS (Alan's explicit go, each):** any Studio Play (tests included), place saves, publish (he does it), desktop control or screen grabs, Tripo credits (tell him the count first), bot matches, any new mechanic or number, every upload. Every picture or model: his OK on a preview, then the safety sheet, then upload.
- **Stop rule for reviews:** one independent reviewer pass per preview before Alan sees it; fix its "no" items once, then show him with what is left named first. No second pass on a paint-only tweak.

## DECISIONS & WHY (this session; all in the decision page in his words)
- **The Shark's smile sits on a chin** (Alan pointed at the P-40: the front must show the full smile, underneath nothing mangled, no lines; a piece added in Blender is allowed). Paint on the needle's underside is seen at 9 degrees from ahead and stretches six times from below; a steep rounded front under the snout carries it instead.
- **The chin is part of the body's own mesh**, not an added piece: his reaction to a pasted-on mock-up was "looks horrible", and he asked whether a visual QA agent was in use (it was not).
- **The mouth's front third is re-laid; the rest is the sheet's own art.** Behind the fifth tooth the side mouth is untouched except for the lower lip (next line). Ahead of the chin the snout is all blue, underside too (the sheet has cream there): Codex's front view shows one dark snout over the grin.
- **The sheet's drooping lower lip is painted out** on his circles ("remove this stray mouth line on each side"): one thin even lip under the back teeth.
- **Colour pass on his words** ("contrast, add shadows, colors less dull, darken the blacks, darken the colors a little"): baked shadows plus a grade, numbers in `make_spec.py`.
- **Four skins ran in parallel side sessions** on his ask (Fable 5.2, extra-high), Blender only, each in its own folder; uploads were kept out of them.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md hard limits; no Meshy (Blender only); the concept-to-blender skill for every model with a sheet; visual-qa-before-showing (new this session); look-at-textures-before-upload; fix-the-annoyance-only; plain words for Alan, bad news first.

## CARRY NOTES / GOTCHAS
- **Told to Alan as still short on the Shark, and he OK'd it as is:** up close the lip is thicker under the middle teeth than along the cheeks; cheek teeth thinner than the middle ones; the chin is a small bump under the nose from the side; the light wing stripe is a little brighter and bluer than the concept's (do not push the grade further).
- The last colour tweak (`chin-13`: stronger shadows, 10% darker) was not re-reviewed; the reviewer saw `chin-12` ("yes with caveats").
- `tools/art/sheet_model.py` gained optional spec keys this session, all off by default: `extra_stations`, `bottom_exact`, `paint_script`, `uv.focus`, `grade`, `ao.normalize`. The side sessions were told not to edit that file; if one needed something it wrote a script in its own folder.
- `.planning/` is not in git (only handoffs are committed): the skins' build folders exist on this disk only.
- `make_spec.py --no-chin ROUND` still builds the old chin-less Shark (it reads `front_face.py`'s sheet). With the chin OK'd, `front_face.py`, `shark-jet-a4-face.png` and that switch are dead: delete them next time the file is open. Rounds `whole-*`, `jaw-*`, `chin-01` … `chin-12` are superseded scratch; `whole-12/mesh.npz` is read by `make_spec.py` for the old underside.
- A reviewer's pixel positions refer to the picture it opened; my own crops were wrong three times (crop boxes past the picture's edge): check a crop's size before judging from it.
- Still unanswered from before: delete the 8 stray pictures in `C:\.planning\skins\shark\test-nose`?
- A long Bash command (over about 8,000 characters) is cut off on this machine; Blender needs absolute output paths.

## WHAT SHIPPED / OTHER QUEUED
- `528b5eb4` Shark Jet: Alan's ruling (the smile shows from the front, nothing mangled underneath); four Legendary skins in their own sessions
- `a4c6a90a` Shark Jet: a chin built into the body with the grin wrapped round it; the builder learns extra rings, an exact underside, a sharper patch and a per-skin painter
- `cf20b259` Shark Jet: the stray dark line under the back teeth painted out; the chin keeps the belly's fold lines
- `2553690f` Shark Jet: Alan's OK on the mouth; shadows, contrast and richer, darker colours; the builder learns a colour grade and shadows that leave open surfaces alone
- `92dd67d5` Shark Jet has Alan's OK; the five Legendaries upload together once the Ninja is OK'd
- Queued (not started): everything in NEXT ACTION 1 to 4.

## KNOWLEDGE UPDATED
- `docs/decisions/2026-11-14-shape-skin-model-sheets.md`: the Shark Jet bullet, every ruling of this session in his words up to the OK and the upload plan.
- `docs/workshop/lessons.md` ("Making 3D models"): a picture that must read from ahead needs a steep surface (four things that each cost a round); nothing goes to Alan before an independent reviewer has seen it.
- `state/STATE.md`: the "Now" paragraph (58 lines). Checker: `python tools/check_docs.py` OK.
- Memory: new `visual-qa-before-showing`.

## POINTERS
- Shark: `.planning/skins/shark/build/` (`make_spec.py` holds every number; `chin_paint.py` the chin's paint; `mouth_views.py` the 13 views), final round `chin-13/` (`model.blend`, `skin-color.png`, `skin-normal.png`, `skin-glow.png`, `mouth-views.jpg`, `before-after.jpg`, `check.jpg`).
- Other skins, each with its own session's report: `.planning/skins/stealth/build/whole-06/`, `.planning/skins/race_car/build/whole-09/`, `.planning/skins/hot_rod/build/whole-05/`, `.planning/skins/ninja/build/whole-09/` (not final).
- Builder and checks: `tools/art/sheet_model.py`, `.claude/skills/concept-to-blender/`.
