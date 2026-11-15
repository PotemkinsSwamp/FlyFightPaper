# HANDOFF — 2026-11-15 — Crane gun pieces and desk photos fixed; next: a consistent six-view Dragon set for Tripo and Forge GUI

**Labels:** kind=product+ui · lane=beta-lane · branch=main · issues= · areas=src/client/WeaponMotion.luau, src/client/DeskHangar.luau, docs/decisions/2026-11-14-shape-skin-model-sheets.md, docs/plan/SKINS-PLAN.md, docs/workshop/lessons.md, docs/systems/, state/STATE.md, .planning/skins/dragon/tripo/
**Time:** 2026-11-15 15:45 -05:00

★ START HERE: Goal (Alan): test whether an AI 3D tool (Tripo, Forge GUI) makes a better Dragon skin than our Blender build, because "Claude isn't good enough at Blender". Next: make a **consistent six-view concept set of the Dragon (top, bottom, front, back, left, right)**: first try Alan's idea, Codex turning renders of the Fable Blender Dragon into finished concept pictures; fallback, Codex draws from the approved sheet. Done when every view agrees with every other (legs, fins, horns, wings, tail, colours) by your own side-by-side check, and Alan OKs the set. Then the set goes to Tripo and Forge GUI.

> Read on demand: AGENTS.md → this file; then `docs/decisions/2026-11-14-shape-skin-model-sheets.md` (the Dragon rulings and the AI-tool test ruling, near the end of the Dragon list). Memories: codex-for-pictures-and-blender, no-meshy-blender-only (superseded for this test by Alan's own ask), look-at-textures-before-upload, plan-before-building-features.

## STATE (verify before acting)
- HEAD: run `git rev-parse --short HEAD` (this handoff's commit sits on top of `4272e534`); main pushed (the hook copies to GitHub).
- Tests: 650/0 last run (2026-11-14); this session changed client code only (`WeaponMotion`, `DeskHangar`), not re-run. Re-run in a Studio Play server: `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- Docs: `python tools/check_docs.py` OK.
- Studio: Edit, DevMute cleared. Rojo serve was started by this session; if Studio's Rojo plugin says disconnected, start it again with the command in `docs/workshop/studio-and-rojo.md` and have Alan click Connect.
- Keys in `.env` (never show them): `TRIPO_API` (works only on `https://api.tripo3d.ai/v2/openapi` with a `User-Agent`; **balance 0 credits**), `FORGEGUI` (an `fgmcp_` key for Forge GUI's Studio link; setup unknown).
- Cost this session: Opus main; 2 web-fetch helpers (~58k and ~20k tokens); 1 Codex picture job (~51k tokens, Alan's ChatGPT plan); nothing paid, no uploads to Roblox.

## NEXT ACTION + PLAN
1. **Six-view Dragon set (Codex).** First try (Alan's idea): render the Fable Blender Dragon
   (`.planning/skins/dragon/body-fable/round-16/`) from all six sides and have Codex turn each render into a finished
   concept picture of that view, keeping its outline (so the views agree); he may want known round-16 faults (flat back
   fins) improved in the paintings. Fallback: Codex draws the set from the approved sheet
   `.planning/skins/model-sheets/dragon-b8-legs.png` (cross-check every view). Source pictures: the approved sheet `.planning/skins/model-sheets/dragon-b8-legs.png` and the fixed three-quarter `.planning/skins/dragon/tripo/input-three-quarter-fixed.png`. Known sheet traps: the three-quarter drew a back leg on top of the wing (fixed copy above); the side view is the least trusted; the front view cheats the legs; the back legs sit under the belly, below the wings. Front/back/left/right at level height (what Tripo's multi-view takes). Check each view against the others yourself before Alan sees it; send mismatches back to Codex.
2. **Tripo:** Alan runs it on tripo3d.ai's free plan with front, left, back, right (the API has 0 credits; buying is his call). Model saved as GLB into `.planning/skins/dragon/tripo/`.
3. **Forge GUI** (forgegui.com/create): find in a browser how it takes pictures and makes 3D (GLB); free starter credits; Alan doesn't mind its public gallery.
4. **Compare** the two models (and the Blender round 16) from the same angles, beside the sheet; Alan picks.
5. **Then Blender on the winner only:** trim to about 4,000 triangles, one 1024 picture set, cut into the five fit pieces. A free-plan Tripo model belongs to Tripo: remake on a paid plan before shipping.
- Backlog after the skin views (Alan): desk photos under the crane, crane gun pieces while firing, Toilet Roll shake with a read-only recorder (STATE "Waiting on Alan").
- HOLDS (Alan's explicit go, each): Roblox uploads; publish (he does it); place saves; desktop control or screen grabs beyond Studio Play checks; Studio Play while he plays; bot matches; anything paid (Tripo or Forge credits, subscriptions); any new mechanic or number. Sending Dragon pictures to Tripo and Forge for this test is his ask.

## DECISIONS & WHY (this session)
- **AI-tool test order (Alan, corrected twice):** consistent full concept set FIRST, then the tools; never the one-picture view again; the tools build the model, Blender only trims the winner. Renders of the Fable model are fine as Codex's starting point (Alan's own idea, after he turned down my paint-over pitch): the outputs are concept pictures, and the tools still do the modelling. Recorded in the decision note.
- **Crane gun pieces:** `WeaponMotion` draws each moving piece from SkinShapes' moved copy (`skin.CFrame * rest⁻¹ * pose`) and shows/hides that copy instead of the real piece; checked on a still plane in Play: 0.000 studs, 0 degrees off; real pieces stay hidden at the desk.
- **Desk photos:** the big photo skips `SkinHidden` parts; every pinboard and preset photo wears the worn skin (dev try-on first); checked in Play with the crane.
- **Toilet Roll shake:** four causes ruled out in Play (turning-motor overshoot, health dips, crash shapes, off-centre push); next is a read-only per-second recorder while Alan flies (his go). Details: `docs/systems/flight.md`.
- **Skins brief for outsiders:** published as a private page, https://claude.ai/artifact/62NjaQQdihwP9g2wWHLVd7 (Alan shares it himself). Figures there come from the skins plan and rules; Roblox's 20,000-triangle mesh cap was stated from memory.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md hard limits, model router, docs rules; commit by path and push each commit. Keys only with their own service's official API.

## CARRY NOTES / GOTCHAS
- Codex picture job: `codex exec -s workspace-write - -i <input.png> < prompt.txt` inside the repo (lessons.md). Safety: no hooked crosses, square spirals, paired bolts in any picture.
- The Fable Dragon session (round 16) waits on Alan's notes; its open question (back fins back to drawn height) is his.
- `.planning/` is not in git: the skin pictures live only on this PC.

## WHAT SHIPPED / OTHER QUEUED
- `10994863` Under the crane, guns' moving pieces move from the drawn gun
- `a599b212` Toilet Roll shake: four causes ruled out · `33795943` STATE under 60 lines
- `0df4e518` Desk photos wear your skin
- `1c106e19` Tripo test and ruling; Tripo API and Forge GUI notes · `4272e534` Forge gallery fine; backlog moved
- This handoff's commit: test-order ruling corrected (no Blender, set first) + handoff.
- Same day on main from the skin sessions: Dragon rounds 14–16 and builder changes (`git log --oneline a0b908b8..HEAD`).

## KNOWLEDGE UPDATED
- `docs/systems/planes-and-hangar.md` (crane gun pieces, desk photos), `docs/systems/weapons.md` (WeaponMotion row), `docs/systems/flight.md` (shake ruled out), `docs/decisions/2026-11-14-shape-skin-model-sheets.md` (Tripo test, Forge GUI, test order), `docs/plan/SKINS-PLAN.md` (Tripo line), `docs/workshop/lessons.md` (Tripo API), `state/STATE.md`. Checker OK.

## POINTERS
- `.planning/skins/model-sheets/dragon-b8-legs.png` · `.planning/skins/dragon/tripo/` · `.planning/skins/dragon/body-fable/round-16/` · `src/client/WeaponMotion.luau` · `src/client/DeskHangar.luau`
