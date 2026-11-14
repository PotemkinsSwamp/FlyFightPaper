# HANDOFF — 2026-11-14 — Crane hitbox tilt, booster against the belly, crane shorter and blue again; stray gun pieces next

**Labels:** kind=product+ui · lane=beta-lane · branch=main · issues= · areas=src/shared/SkinFit.luau, src/client/SkinShapes.luau, src/client/PlaneLooks.luau, src/client/PaperUI.luau, src/server/HitShapes.luau, src/server/FlightService.luau, src/server/HangarService.luau, config/skin-shapes.json, tools/art/skin_looks.py, docs/
**Time:** 2026-11-14 02:00 -05:00

★ START HERE: Goal (Alan): the beta feels finished and the shop makes money; skins and trails are the build. Next: under the crane, each gun's moving piece (e.g. `Mount1-pellet`, drawn by `src/client/WeaponMotion.luau` at the desk and animated in flight) still shows at the REAL gun spot, not where the crane draws the gun. Make it follow the moved gun (the move is in `SkinFit.plane(...).guns`, the client copies are `SkinGun-*`). Done when, in Studio Play with the crane on, no gun piece shows anywhere but on the drawn guns, at the desk and in flight.

> Read on demand: AGENTS.md → this file; then `src/shared/SkinFit.luau`, `src/client/SkinShapes.luau`, `src/client/WeaponMotion.luau`. Supersedes handoff-2026-11-14-beta-lane-crane-replay-fixed-wing-tilt-next.md (its wing-tilt step is done). Memories: alan-does-play-checks, studio-play-is-shared, mute-studio-tests, no-meshy-blender-only, plan-before-building-features.

## STATE (verify before acting)
- HEAD `1b910e47` (main), pushed. Confirm: `git rev-parse --short HEAD`.
- Tests: 650 passed / 0 failed (44 suites). Re-run in a Studio Play server: `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()` (return one string from execute_luau).
- Docs: `python tools/check_docs.py` OK.
- Studio: Edit, DevMute cleared, rojo serve connected. Place saved to Roblox with Alan's go (version 735, Team Create save, not published) after clearing 29 stale `HitShapes` WorldModels from Edit ServerStorage.
- Side session [skin-concepts](#local_9d0b23f5-faf0-472c-acef-d44be96f7522) (shares this folder, touches `.planning/skins/`, `tools/art/` new files, skin docs): Alan picked Shark Jet A and Dragon B; Codex is redrawing them with a barrel body and underside view; Dragon-head Blender technique test next. It reports to whoever started it; check `list_sessions {"linked": true}` or ask Alan.
- Cost this session: Opus main; 2 Opus helpers (wing tilt ~277k tokens/15 min; booster ~329k/23 min); Codex model sheets 73,498 tokens (Alan's ChatGPT plan); 1 free picture upload (crane sheet 86508406688555).

## NEXT ACTION + PLAN
1. Stray gun pieces under the crane (above).
2. Toilet Roll shake: Alan 2026-11-14: in a match the whole plane shakes back and forth; only that body; never reproduced on autopilot. Look at what differs for that body in a real flown match.
3. Alan's flight feel check of the crane hitbox (walls, gaps) — his, list it under Waiting on Alan.
4. Then (with the skin session's output): six printed skins, Shark Jet, Dragon, three trails, the crane's matching trail.
- HOLDS (Alan's explicit go, each): any upload; publish (he does it); Save to File / place saves; desktop control or screen grabs beyond Studio Play checks; Studio Play while he's playing; bot matches; anything paid; any new mechanic or number (note first).

## DECISIONS & WHY (this session)
- Alan meant the crane was too TALL, not wide: width restored; belly stops at the real body's bottom (no booster reach), roof `wy + 0.5s` (was 0.9s). He OK'd the result.
- Wings, neck and tail join the stretched body's side edge `hy = body(ref.wy).Y` (hinged at the real wing height they floated).
- One shared fit `src/shared/SkinFit.luau` for screen and server: wings' hit+crash shapes turn up RISE about the hinge (same size), guns' and booster's shapes move to where they are drawn (Alan OK'd guns 2026-11-14). Booster moves straight up or down to touch the belly (`ref.keel` in config, middle 60% of each part, tape excluded; worst 0.04 off over 18 combos).
- Hangar keeps plane photos between clicks (`kept`, preload behind the old one); server sends the profile with every hangar answer (`onAnswer`).
- `skin_looks.py` writes one folder per skin (two `origami_crane` folders hid the Shape look: grey crane). Lesson in lessons.md.
- Crayon lettering holds its outline strokes in a table (name lookup threw when one was gone; root cause of the missing stroke not found).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md hard limits and model router; docs rules; commit by path, push each commit. Meshy is gone: all 3D in Blender.

## CARRY NOTES / GOTCHAS
- Config edits need `python tools/generate_config.py`; Rojo syncs Edit only, so restart Play after edits.
- To put the crane on in Play without owning it: a throwaway server Script in Play calling the live `flight:wear(p, "origami_crane")` after `RoundAction "join"`; hangar try-on draws it in the preview; the Studio account (level 12) owns no booster.
- Unknown: "No asset content representation found" warnings for 5 asset ids seen during the booster run; and a dev loadout once reverted to the Fighter at the desk.

## WHAT SHIPPED / OTHER QUEUED
- `91257f05` Handoff (previous) · `005716c1` Crane blue again, shorter body, wings/neck/tail on the body's edge · `fa841f98` Wing hitbox tilt + gun hit spots, shared fit · `13e84d7b` / `ee27719b` (skin session) model-sheet picks and barrel-body note · `710373a9` Crayon outline fix · `1b910e47` Booster against the crane belly.
- Earlier today: see the previous handoff's list.

## KNOWLEDGE UPDATED
- docs/systems/planes-and-hangar.md (crane fit, booster, hangar), damage-and-deaths.md (HitShapes), docs/plan/SKINS-PLAN.md (tilt built), docs/playtests/2026-11-13-crane-and-skins-tabs.md (replay + corrections), docs/decisions/2026-11-13-skin-rules.md (tilt + guns OK), docs/workshop/lessons.md (duplicate-name folders). Checker OK.

## POINTERS
- `src/shared/SkinFit.luau` · `tests/unit/SkinFit.spec.luau` · `config/skin-shapes.json` · `.planning/skins/model-sheets/` · state/STATE.md
