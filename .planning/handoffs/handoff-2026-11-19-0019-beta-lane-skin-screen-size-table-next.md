# HANDOFF — 2026-11-19 — Big skins: size each one by the screen (measured table) next; F8 now hides every dev button

**Labels:** kind=product+ui · lane=beta-lane · branch=main · issues=none · areas=src/shared/SkinFit.luau, src/client/DevTools.luau, src/client/FlightHUD.luau, AGENTS.md, docs/decisions, state
**Time:** 2026-11-19 00:19 -05:00

★ START HERE: Goal: a plane in a big skin covers about the same share of the screen as the same plane without a skin. Alan's ruling (2026-11-19): for each whole-shape skin (Race Car, Hot Rod, Ninja, Stealth, Shark Jet, Dragon) and each body + wings mix (6 x 6), measure once the one even size at which the skin covers the same share of the 1280x720 chase view as the plain plane; store it as a table the game reads (SkinFit's even size). Opening action: build the measuring tool (Studio Edit mode, rays through the chase view) and run it. Done when, on the four check builds below, every skin is within about 10% of the plain plane's screen share, tests pass, and Alan says the size looks right in Play.

> Read on demand: AGENTS.md (new rule "Every new whole-shape skin gets its screen sizes") → THIS → the earlier handoff `handoff-2026-11-18-2359-beta-lane-big-skins-sized-to-plane.md` (how the hit copies and size rule got here) → `src/shared/SkinFit.luau` evenFit. Memories: alan-does-play-checks, studio-play-grabs-mouse, mute-studio-tests.

## STATE (verify before acting)
- HEAD `bb30b35d` + this handoff's commit (main); hook copies to GitHub. Confirm: `git rev-parse --short HEAD`.
- Tests: NOT run since 748/748 (before 2026-11-18's skin changes). `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()` on the Server, in Play, Alan's go.
- Studio: Alan stopped Play; Edit mode; Rojo serve running. Nothing saved, nothing published.
- Live size rule now: "as long or as wide as the plane, whichever first, never bigger" (2.4-5% of the screen vs the plain plane's 6.8-7.7%: too small, Alan). The screen table replaces it.
- Cost of this stretch: no subagents, no Codex, no uploads; ~20 min; main context ~52%.

## NEXT ACTION + PLAN
1. Measure: per skin x body x wings (nose_0, tail_0), bisect the even size k until the drawn skin's chase-view share equals the plain plane's. Method that worked (Edit-mode `execute_luau`): build the plane with `Aircraft.build(model, loadout, catalog, true)`, plain = body/nose/wings/tail MeshParts; skin pieces placed as evenFit does (`at(p)`, hit piece skipped); `AssetService:CreateMeshPartAsync(..., PreciseConvexDecomposition)` in a `WorldModel`; camera `CFrame.lookAt(F+(0,6,24), F+(0,0,-60))`, F=(0,2,0), FOV 72, rays every 8-10 px. Chunk per body with `task.wait()`.
2. Store the table (one config file through `tools/generate_config.py`; a tool in `tools/` named on the planes-and-hangar page and in `docs/workshop/tools.md`, since AGENTS.md now requires a row for every new skin). SkinFit reads it; a mix not in the table falls back to today's rule.
3. Check builds (same seat, plain vs each skin): Cardboard Gunship + Cardstock Wings (plain 6.8%), Toilet Roll Gunship + Broad Wings (7.7%), Classic Fold + Classic Wings, Swift Fold + Swept Wings (0.8%). Update `tests/unit/SkinFit.spec.luau` (Dragon test asserts the current length/wingspan rule).
4. Tests in Play (his go), then his Play look (what-to-look-at list in STATE.md). Then delete what the new rule leaves unused (`config/plane-areas.json`, `PlaneAreas`, `tools/plane_areas.lua`, `even.area`, if nothing reads them).
- **HOLDS (Alan's explicit go, each):** any Studio Play (tests included), place saves, publish (he does it), desktop control or screen grabs, bot matches, every upload, any new mechanic or number (this table is approved).
- **Stop rule:** within ~10% on the check builds = build it; don't reopen the rule without his Play look.

## DECISIONS & WHY
- **Size by the screen** (Alan 2026-11-19, after equal target was too big and length/wingspan too small): what he judges is the chase view; no single rule fits flat skins (Shark, Dragon) and boxy ones (Race Car, Ninja). A thinner or thicker target than the plane is accepted ("It's just a skin, it's just cosmetic"); never a hidden hitbox (the skin stays the hit and crash shape); never stretched; camera unchanged.
- **Project rule (AGENTS.md):** every new whole-shape skin gets its screen-size row before it ships.
- **F8 is one toggle for every dev button** (corner switch and the hangar's dev panel), via the player attribute `DevShown` (DevTools sets it; FlightHUD reads it). Works wherever the server marks the player Dev (Studio, or the owner live). I had first wired only the corner buttons; Alan caught it.
- Earlier rulings this lane (hit copies, Shark fin passes through walls): previous handoff and the shape-skin decision.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md; `docs/decisions/2026-11-14-shape-skin-model-sheets.md` (last paragraphs); memories alan-does-play-checks, studio-play-grabs-mouse, plan-before-building-features.

## CARRY NOTES / GOTCHAS
- Edit-mode `require` is cached: to read fresh synced source, clone the ModuleScript beside itself and require the clone (lessons.md, Studio section). `SkinFit` requires `Generated.SkinShapes`; rewrite that name in the clone too.
- Studio Edit tools fail while Alan is in Play ("Edit datamodel is not available in Play mode"); ask, never stop his Play.
- Starting points from 2026-11-18's measurements: on Alan's and the biggest build, roughly the geometric mean of the length/wingspan size and the equal-target size lands near the plain share (3.5-8.4% vs 6.8-7.7%); Shark and Dragon need relatively more.
- Ninja's `Assets.NinjaRig` still holds the old hit copy (falls back fine). Race Car's drawn length is ~1.5% over its hit copy's.

## WHAT SHIPPED / OTHER QUEUED
- `bb30b35d` F8 also shows and hides the hangar's dev panel (one toggle for every dev button)
- `bc1e9a70` Handoff (beta lane): big skins sized to the plane (previous handoff, all earlier commits listed there)
- This handoff's commit (AGENTS.md rule, decision, STATE). Queued: the beta queue in `state/STATE.md`.

## KNOWLEDGE UPDATED
- `AGENTS.md`: rule "Every new whole-shape skin gets its screen sizes".
- `docs/decisions/2026-11-14-shape-skin-model-sheets.md`: "Then too small" ruling. `state/STATE.md` (60 lines). Checker OK (207 pages).

## POINTERS
- `src/shared/SkinFit.luau`, `src/client/DevTools.luau`, `src/client/FlightHUD.luau` (picker.Visible), `config/skin-shapes.json`, `docs/systems/planes-and-hangar.md`, `docs/playtests/2026-11-18-big-skin-size.md`.
- Alan's comparison screenshots (Ninja and Race Car vs the plain plane) are in this chat only.
