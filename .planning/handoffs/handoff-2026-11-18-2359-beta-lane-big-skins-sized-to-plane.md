# HANDOFF — 2026-11-18 — Big skins now match the plane's length and wingspan; hidden trimmed hit copies in; F8 dev menu; tests and Alan's Play look next

**Labels:** kind=product+ui · lane=beta-lane · branch=main · issues=none · areas=src/shared/SkinFit.luau, src/client/DevTools.luau, src/client/PlaneTrails.luau, config/skin-shapes.json, tools/art/skin_hit_hulls.py, tools/plane_areas.lua, tests/unit/SkinFit.spec.luau, docs
**Time:** 2026-11-18 23:59 -05:00

★ START HERE: Goal: big skins stop hurting the player who wears them. The rules are built (Alan's picks below), but nothing has run in Play yet. Opening action: ask Alan's go for one Studio Play run of the unit tests (`require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()` on the Server; last 748/748 before today's changes). Fix anything red, then give him a short "what to look at" list for his own Play look (a Race Car and the Ninja on the Cardboard and Toilet Roll Gunships, the Shark fin through a gap, F8). Done when the tests pass and Alan says the size looks right.

> Read on demand: AGENTS.md → THIS → `docs/decisions/2026-11-14-shape-skin-model-sheets.md` (last three paragraphs: today's rulings) → `src/shared/SkinFit.luau` (evenFit). Memories: alan-does-play-checks, studio-play-grabs-mouse, mute-studio-tests, plan-before-building-features.

## STATE (verify before acting)
- HEAD `26115da0` + this handoff's commit (main); the commit hook copies to GitHub ("github: pushed"). Confirm: `git rev-parse --short HEAD`.
- Tests: NOT run since 748/748 (start of session). Changed since: `tests/unit/SkinFit.spec.luau` (Dragon size test, Legendary hit-copy test, Ninja length assertion removed). Run in Play only with Alan's go.
- Studio: Edit mode, Rojo serve running and synced (Edit-mode checks only this session: no Play, no save, no publish).
- Upload: one FBX, asset 131691880437289, Approved; five MeshIds in `config/skin-shapes.json` (`pieces.hullHit`). Record: `.planning/skins/motion/uploads/hit-hulls.json`.
- Docs checker OK (207 pages).
- Cost: no subagents, no Codex; ~1 h 40 min wall clock; one Open Cloud upload; Blender renders local; main context ~47% at handoff.

## NEXT ACTION + PLAN
1. Tests in Play (his go), fix red. Check: all pass.
2. His Play look at the new size (what-to-look-at list in STATE.md "Waiting on Alan"). If he likes it: delete the now-unused target-size data (`config/plane-areas.json`, `src/generated/PlaneAreas.luau` via `tools/generate_config.py`, `tools/plane_areas.lua`, `even.area` in `config/skin-shapes.json`) and their docs mentions.
3. Then the beta queue in `state/STATE.md`.
- **HOLDS (Alan's explicit go, each):** any Studio Play (tests included), place saves, publish (he does it), desktop control or screen grabs, bot matches, every upload, any new mechanic or number.
- **Stop rule:** the size rule is Alan's ruling; don't reopen it unless his Play look does.

## DECISIONS & WHY (this session; full text in the shape-skin decision)
- **F8 shows/hides all dev buttons** (hidden at start; Studio only as before). Photo viewpoints moved to Shift+F8. Why: the buttons covered his phone-size test.
- **Size rule, final (Alan's pick "keep the shape"):** a whole skin (Dragon + five Legendaries) is one even size, as long OR as wide as the plane, whichever comes first, never bigger, never stretched. Replaced (a) "never shorter or narrower" (made skins up to 2.2x the plane's target, 34% of the screen vs 8%) and (b) equal target size (flat skins over the tall Cardboard/Toilet Roll bodies still grew up to 2x on screen). A flat skin over a tall body is a thinner target (53-69%); Alan accepts it: "It's just a skin, it's just cosmetic" (weight, health, lift, speed unchanged).
- **He ruled out the plane's own parts as a hidden hitbox under the skin** ("if it can hit or crash where no skin shows, that's a problem"). The skin stays the hit and crash shape.
- **Hidden trimmed hit copies (`hullHit`) for the five Legendaries:** body, wings, nose, tail count; Race Car spoiler and Shark top fin don't; tall fins cut where a normal tail fin ends (0.10 of the length above the skin's body top, about half of each); trimmed parts are never hit and pass through walls. Dragon needed none. Picture he OK'd: `.planning/skins/hit-trim-preview.jpg` (green = trimmed).
- **Shark top fin: no hitbox and passes through walls** (Alan).
- Trail exhaust spots now use a fixed 8.4-stud skin length (`PlaneTrails.exhaust`) so the new hit pieces didn't move them.
- Correction told to Alan: the last handoff said Legendaries were look-only; in the code all five plus the Dragon are the hitbox (`SkinFit.plane` covers = `shape.even ~= nil`).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md; skin rules and shape-skin decisions; memories alan-does-play-checks, studio-play-grabs-mouse, explain-plans-in-text, look-at-textures-before-upload.

## CARRY NOTES / GOTCHAS
- Length comes from the hit copy: the Race Car's copy is 8.23 of its drawn 8.35 studs, so the drawn Race Car is ~1.5% longer than the plane. Fine unless Alan notices.
- The Ninja's `Assets.NinjaRig` still holds the OLD hullHit; HitShapes falls back to loading the new id (works; no first-spawn precomputed hull). Re-export the rig only if a first-spawn hitch shows.
- Edit-mode MCP `require` is cached: clone the ModuleScript beside itself to test fresh source (lessons.md, Studio section).
- The camera never changed (ChaseCamera.luau untouched); the Hot Rod's fins may still stand over the crosshair on his build at the new, smaller size; if so, offer a lower fin in the model (look only).
- Measuring scripts were throwaway (scratchpad); the real tool is `tools/art/skin_hit_hulls.py`.
- Untracked `tools/art/hero.py.old`, `assets/ui/shop/raw|source`: not this session's; leave.

## WHAT SHIPPED / OTHER QUEUED
- `7c083c87` Dev buttons hide until F8 (they covered the phone test); photo mode moves to Shift+F8
- `7b8239c9` State: big skins are the hitbox and too big on wide and narrow builds (measured); F8 dev menu
- `45f12c2c` Big skins are exactly as big a target as their plane: no more 'never shorter or narrower' (Alan)
- `690c61c9` State: hit-trim plan for the five Legendaries waits on Alan
- `3206a2e9` Legendaries hit and crash with a trimmed hidden copy: no spoiler, no shark top fin, tall fins cut to a normal fin's height (Alan)
- `26115da0` Big skins are as long or as wide as their plane, never bigger, never stretched (Alan)
- This handoff's commit. Queued: the beta queue in `state/STATE.md`.

## KNOWLEDGE UPDATED
- `docs/decisions/2026-11-14-shape-skin-model-sheets.md`: floor dropped, hit copies built, size by length/wingspan (Alan's words).
- `docs/systems/planes-and-hangar.md`: size rule, hit copies, measured shares, Code table row for `skin_hit_hulls.py`.
- `docs/playtests/2026-11-18-big-skin-size.md` (new, in README). `docs/workshop/tools.md`: `skin_hit_hulls.py`. `docs/workshop/lessons.md`: size skins by what players see; Edit-mode require cache. `docs/systems/performance.md`, `docs/workshop/testing.md`: F8 / Shift+F8.
- `state/STATE.md` (60 lines). Checker OK.

## POINTERS
- `src/shared/SkinFit.luau` (evenFit), `src/server/HitShapes.luau`, `src/client/DevTools.luau`, `tools/art/skin_hit_hulls.py`, `.planning/skins/hit-trim-preview.jpg`, `.planning/skins/motion/hulls/hit-hulls.json`.
- AAR: planned an options note for the camera; measuring showed the real fault was the size rule, which took three rounds (floor → equal target → length/wingspan) because equal target was proposed without checking the tall-bodied builds; Alan's side-by-side screenshots caught it. Lesson routed to lessons.md.
