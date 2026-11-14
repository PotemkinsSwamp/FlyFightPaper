# HANDOFF — 2026-11-14 — Crane playtest and replay fixed, booster wears the crane sheet; wing-hitbox tilt (with guns) next

**Labels:** kind=product+ui · lane=beta-lane · branch=main · issues= · areas=src/client/Hangar.luau, src/client/HangarCustomize.luau, src/client/SkinShapes.luau, src/client/PlaneDeaths.luau, src/client/BuildShelf.luau, src/server/HangarService.luau, src/server/RoundRuntime.luau, tools/art/crane_skin.py, config/looks.json, docs/
**Time:** 2026-11-14 00:58 -05:00

★ START HERE: Goal (Alan): the beta feels finished and the shop makes money; skins and trails are the build. Next: build the wing-hitbox tilt for shape skins, **with the guns' hit spots moving to the drawn guns** (Alan OK'd both 2026-11-14; how-it-works note in docs/plan/SKINS-PLAN.md "Wing-hitbox tilt"). Done when a unit test shows the tilted wing keeps its size and root, and a Studio flight shows shots hitting the crane's V wings and guns where they are drawn, and crashes only where the wings really are.

> Read on demand (pointers, never "in full"): AGENTS.md → this file; then docs/plan/SKINS-PLAN.md (tilt section), docs/decisions/2026-11-13-skin-rules.md, src/client/SkinShapes.luau `fit()`, src/server/HitShapes.luau, src/server/FlightService.luau (spawn colliders ~L207, `touching` ~L460). Memories: plan-before-building-features, alan-does-play-checks, studio-play-is-shared, mute-studio-tests, look-at-textures-before-upload.

## STATE (verify before acting — state drifts between sessions)
- HEAD `af178ede` (main), local == remote, GitHub copy pushed by the hook. Confirm: `git rev-parse --short HEAD`.
- Tests: 635 passed / 0 failed (43 suites) at db22980a. Re-run in a Studio Play server: `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()` (returns a table: passed/failed/failures).
- Docs: `python tools/check_docs.py` OK (192 pages).
- Studio: Edit mode, DevMute cleared, rojo serve (serve.project.json) connected. Nothing Saved to File, nothing published.
- Uploads this session (Alan's go): crane printed sheet, image 86508406688555 (moderation was "Reviewing" at upload; it showed in Studio).
- Cost last session: Opus only, no subagents, no Codex/Meshy; 1 free picture upload; Blender ~1 min local; about 2h10m wall clock.

## NEXT ACTION + PLAN
1. **Wing-hitbox tilt + gun hit spots** (above). One shared fit rule (hinge x = ±cw*0.97, y = wy + 0.02s, rise from config/skin-shapes.json; the body is now `cw = clamp(0.8*bw, 0.9s, 1.3s)`) applied to the `wings-*` parts in FlightService's Colliders and `HitShapes.copyOf`; guns' hit shapes move by the same offsets the skin's drawn guns use (`SkinGunMove<slot>`). The skin is client-drawn today, so the server needs the fit from the plane's parts + the shape config (no client trust).
2. **Toilet Roll shake:** Alan 2026-11-14: in a match the whole plane shakes back and forth; only the Toilet Roll body. Never reproduced on autopilot (Oct handoffs). Look at what differs for that body (its wing_shift 1.35, booster anchor above the tube, the hanging paper strips, its colliders/mass) in a real flown match.
3. Then: real skin pictures (Hazard, Tiger, Flame, Gold Foil, Lava, Galaxy), Shark Jet, Dragon, the three trails, the crane's matching trail.
- **Waiting on Alan:** his replay of the hangar (no reload flash on clicks; Buy changes the screen at once), the narrower crane and its wing join, a booster under the crane. If the wings still look loose: tuck the wing roots into the roof (hinge inward/up) and update the tilt rule to match.
- **HOLDS (Alan's explicit go, each):** any upload; publish (he does it); Save to File; desktop control or screen grabs beyond Studio Play checks; Studio Play while he's playing; any bot match; anything paid; any new mechanic or number (the tilt is approved; any other new number gets a note first).

## DECISIONS & WHY (this session)
- **PageCatch:** a transparent TextButton over the binder's right page takes clicks; an ImageLabel (even Active) lets them through to the tab tucked under it. Lesson in docs/workshop/lessons.md.
- **Hangar keeps plane photos between redraws** (Hangar.luau `preview`/`render`): views are keyed by spot + draft + skin; a new plane is built hidden, `ContentProvider:PreloadAsync` on its model, then swapped in over the old one. The rest of the screen still rebuilds each click (cheap, cached images); only the 3D plane was the visible reload. Checked in Play: no frame without a plane.
- **Server sends the profile with every hangar answer** (`HangarService.onAnswer` → `RoundRuntime:sendProfile`): after Buy the client waited for its 3-second poll, which read as "two UIs, then a reload".
- **Crane body capped at 1.3s** (the starter's own 1.29s), factor 0.8 of the real body: Alan found it wide; skins never change hitboxes, so the drawn body may be narrower than the real one.
- **Crane has a `picture`** (config/looks.json) so boosters wear its sheet via PlaneLooks; tape and elastic keep their own look, as on other printed skins.
- **Studio try-on is only the "Dev: skin" button**; skin cards always say Buy/Unlock (Alan 2026-11-13).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md hard limits and model router; memories listed above; docs rules (one fact one page; check_docs before commit; push after every commit, by path).

## CARRY NOTES / GOTCHAS
- After editing `config/*.json` run `python tools/generate_config.py` (the game reads src/generated); this session forgot once and lost a Play restart (already in lessons.md).
- After `skin_looks.py` / config changes, restart Play: Rojo syncs into Edit only.
- Studio test account is level 12 and owns no booster: to check boosters, build a test plane in the Client VM (`Aircraft.build` + `PlaneLooks.dress` on a workspace model; set Transparency=1 on LTM-hidden parts, LTM isn't cloned) instead of buying.
- `execute_luau` returns only the first value: return one string.
- Crane sheet checked for symbols before upload (blue paper, white waves, five-petal blossoms only).

## WHAT SHIPPED / OTHER QUEUED
- Shipped:
  - `440d77f7` Playtest fixes: tabs no longer flip from page clicks, skins say Buy, taped-paper buttons, skinned crash ball, crane guns under the wing, shelf wears the skin
  - `9cc4cc58` Skins plan: how the wing-hitbox tilt would work, for Alan's OK
  - `2ff44903` Crane tool: --sheet paints the crane's printed sheet for boosters and shows boosters wearing it
  - `338aaff6` Hangar keeps the plane photo between clicks and gets the profile right after a buy; crane body no wider than the starter's
  - `db22980a` Boosters under the crane wear its printed sheet (uploaded with Alan's go); Alan's rulings: build the wing tilt with guns, Toilet Roll shakes in flight
  - `6288fec8` / `d2bd0246` / `af178ede` State updates
- Queued: steps 2-3 above; phone-size checks of the report card row and gift note (from earlier).

## KNOWLEDGE UPDATED
- docs/playtests/2026-11-13-crane-and-skins-tabs.md: "What changed" + "Replay (2026-11-14)" with Alan's notes, fixes and answers.
- docs/decisions/2026-11-13-skin-rules.md: tilt approved, gun hit spots move too (Alan 2026-11-14).
- docs/plan/SKINS-PLAN.md: tilt section marked OK'd.
- docs/systems/planes-and-hangar.md: crane body cap, booster sheet, hangar keeps photos, profile after buy.
- docs/systems/flight.md: Toilet Roll shake described (whole plane, in a match).
- docs/workshop/lessons.md: a picture over a button doesn't stop its clicks. docs/workshop/tools.md: crane_skin.py `--sheet`.
- Checker: OK.

## POINTERS
- docs/plan/SKINS-PLAN.md · config/skin-shapes.json · tools/art/crane_skin.py · .planning/skins/crane/ (sheet, previews, upload json) · state/STATE.md
