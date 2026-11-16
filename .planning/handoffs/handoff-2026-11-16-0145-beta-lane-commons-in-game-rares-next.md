# HANDOFF — 2026-11-16 — Dragon's boosters done, all eight Commons in the game; the Rares are next (talk about movement and glow first)

**Labels:** kind=product · lane=beta-lane · branch=main · issues= · areas=tools/art/skin_sheets.py, tools/art/skin_preview.py, assets/models/planes/skins/, config/looks.json, config/commerce.json, src/client/HangarCustomize.luau, tests/unit/, docs/, .planning/skins/
**Time:** 2026-11-16 01:45 -05:00

★ START HERE: Goal (Alan 2026-11-16, [first skin set](../../docs/decisions/2026-11-16-first-skin-set.md)): finish the skins for the beta. Opening action: talk with Alan about how the 8 Rares move and glow ("we'll talk about how to do the animations. And like glows and stuff, making it look like really good"), then write the how-it-works note for his OK. No animation code before that OK. Done when Alan has OK'd the note; then build the Rares one at a time, each shown on real planes before upload.

> Read on demand: AGENTS.md → this file → the [first skin set](../../docs/decisions/2026-11-16-first-skin-set.md) decision → `docs/workshop/lessons.md` ("Printed-sheet skins", "Uploads and Roblox moderation") → [skins plan](../../docs/plan/SKINS-PLAN.md) ("Drawing it at runtime": shine and glow maps). Memories: `plan-before-building-features`, `look-at-textures-before-upload`, `assembled-preview-before-upload`, `alan-does-play-checks`, `hand-made-not-generic-roblox`, `no-quality-cuts-for-fps`.

## STATE (verify before acting)
- HEAD = this handoff's commit on `52584196`; main; GitHub copy pushed by the commit hook. Confirm: `git rev-parse --short HEAD`.
- Tests: **not re-run since the skin list changed** (665/0 before it, 2026-11-16). Counts in four specs were edited by hand. Alan: "we don't need a playtest run". Re-run (his go, it is a Studio Play): on the server `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`. Docs: `python tools/check_docs.py` OK (196 pages).
- Studio: Edit, code synced by Alan's own `rojo serve` (port 34872). Place NOT saved. The scrolling Skins tab is new code nobody has confirmed in Play (Alan looked at skins in Studio and gave no note on it).
- Uploads: 10 free pictures this session, all Approved (ids in `assets/models/planes/skins/uploads.json`; the Dragon's sheet 71720517887759). Two are orphans replaced by redos (first Flame Decal 75265625499827, first 8-Bit 122622827211471). Tripo credits 5,820 (none spent).
- Cost: main session only (Opus 5.5 for the first reads, then Fable 5.2), no helper agents, no Codex, no money; about 45% context at handoff.

## NEXT ACTION + PLAN
1. The Rares talk, then the how-it-works note (above). His examples: lava "will kind of flow", slime "ooze around, move", galaxy stars "move around ... on the plane"; glows too. The 8: Galaxy, Lava, Slime, Holographic, Glitch, Thunderstorm, Circuit Board, Comic Book. Check: Alan's OK on the note.
2. Build each Rare (picture in `tools/art/skin_sheets.py`'s layout, plus whatever the note settles for movement and glow), preview on real planes including the blunt nose, his OK, safety check, upload, add to the list. `config/looks.json` has `lava` (old test picture) and `galaxy` (no picture) today.
3. Dragon leftovers: crash ball and shop card pictures, the jaw chevron, the frame-rate check with 12 Dragons.
- HOLDS (Alan's explicit go, each): Studio Play (tests count), place saves, publish (he does it), desktop control or screen grabs, Tripo credits (count first), bot matches, any new mechanic or number (the Rares' movement and glow are one). Every skin picture: his OK on a preview of it on planes, then the safety check, then upload.
- Stop rule: nothing is "done" without Alan's look. After one redo misses, show two options side by side.

## DECISIONS & WHY (this session)
- **Code-drawn skins, not TextureCraft** (Alan picked "A"): a Common or Rare is one flat picture shared by every part, so TextureCraft's edge wear and crease dirt cannot be used; details in the decision.
- **Dragon's boosters** wear a printed sheet of its own body scales at the body's scale size (17 x 27 px a scale): "its good".
- **Racing Stripe** is painted in the SIDE view too (cream from y 0.97 up; fins all cream) so the body's ridge no longer cuts the stripes: "looks fine".
- **Flame Decal**: a flame-coloured patch in the FRONT view where the blunt nose's face sits; it also shows small at the back of the body: "good".
- **8-Bit** took three passes; the third (half bright, half the dark purple base; pink, cyan, yellow, violet) is in. My call: Alan answered "that looks good. Upload that" to a two-option picture where I had recommended B, so I uploaded B. A (six colours) is one line in `eight_bit()`.
- **Skin list**: Tiger Stripes and Gold Foil removed (his earlier ruling), seven Commons added at the existing Common price; the Skins tab scrolls because 13 cards no longer fit.
- My own calls are listed in STATE "Decisions to review" (Commons line).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md hard limits and docs rules; Blender only for 3D; Alan wants this work on the Fable model; "No skin needs animation" in the 2026-11-13 skin rules is replaced for Rares by the first-skin-set decision.

## CARRY NOTES / GOTCHAS
- Not checked in Play: the scrolling Skins tab (place kept between clicks, nothing over the buttons), Carbon Fiber's weave in motion (may shimmer), the tests.
- I swept an untracked file (`tools/art/hero.py.old`) into a pushed commit with `git add -A tools`, then removed it from git (`67a8fb32`); it is still on disk. Name files when adding.
- Roblox asset names are capped at 50 characters; redo uploads got a number ("FFP skin 8-Bit 3").
- A skin without a `picture` in `config/looks.json` is listed in the shop but draws plain (`galaxy` today).
- The Dragon pipeline scripts and the two new ones (`booster_sheet.py`, `booster_preview.py`) are untracked under `.planning/skins/dragon/paint/tools/`.
- Older carries stand: `tools/plane_areas.lua` after part changes; the monorail train tests crash-shape boxes; stray `C:\parts`; backlog (desk photos under the crane, crane gun pieces while firing, Toilet Roll shake recorder).

## WHAT SHIPPED / OTHER QUEUED
- `a2670887` Boosters under the Dragon wear its green scales (printed sheet uploaded, approved)
- `5813ca15` Alan OK'd the Dragon's boosters in Studio (its good)
- `b6ecd059` Preview tool: a printed-sheet skin on two real planes before upload
- `8eef2ecf` Seven Common skins drawn (not uploaded yet); Alan picked the code-drawn way over TextureCraft
- `36a836c3` Seven new Commons in the game's skin list (uploaded, approved); Skins page scrolls; Tiger Stripes and Gold Foil off the list
- `67a8fb32` Take hero.py.old back out of git (added by mistake; the file stays on disk)
- `41b04a5f` 8-Bit redrawn bright all over, Flame Decal gets a flame face on the blunt nose (Alan's notes; not uploaded yet)
- `7dce16bc` Flame Decal with the flame face on the blunt nose is in (Alan: good); 8-Bit third pass drawn, two options to pick from
- `52584196` 8-Bit third pass is in: half bright, half purple, pink cyan yellow violet (Alan's pick)
- This handoff's commit: handoff, LATEST, playtest note, lessons, STATE, decision and planes page lines.
- Queued after skins: Shark Jet, trails, missions, playtime calendar, bots that use the town.

## KNOWLEDGE UPDATED
- `docs/playtests/2026-11-16-common-skins.md` (new, in README): Alan's words on each skin.
- `docs/decisions/2026-11-16-first-skin-set.md`: status, the comparison result, next session's order (Rares, talk first).
- `docs/systems/planes-and-hangar.md`: Dragon's boosters, the eight Commons, the scrolling Skins tab, what is unchecked.
- `docs/plan/SKINS-PLAN.md`: status. `docs/workshop/tools.md`: `skin_sheets.py`, `skin_preview.py`.
- `docs/workshop/lessons.md`: new section "Printed-sheet skins" (7 lessons: ridge takes SIDE, FRONT shared with the blunt nose, preview on the blunt nose, even spread and two options on a redo, hooked-cross scan, five places a list change touches, name files in `git add`).
- `state/STATE.md` top rewritten (59 lines). Checker: OK (196 pages). No memory changes: the lessons are project-bound.

## POINTERS
- Painter and preview: `tools/art/skin_sheets.py` (one function a skin), `tools/art/skin_preview.py` (`MORE=1 ONLY=starter,blunt,heavy2 VIEWS=front,chase,top`).
- How a look reaches the screen: `tools/art/skin_looks.py` → `assets/models/planes/skin-looks.rbxmx` → `src/client/PlaneLooks.luau`; glow fields already used for the Dragon's eye (`EmissiveMaskContent`, `config/skin-shapes.json` "glow").
- Which face takes which view: `.planning/skins/tests/faces/faces.py` and `faces.json`.
- Pictures Alan judged: `.planning/skins/tests/` (`commons-on-planes.jpg`, `racing-stripe-fix.jpg`, `fix2-*.jpg`, `eight-bit-third-pass.jpg`), `.planning/skins/dragon/booster/dragon-boosters-preview.jpg`.
