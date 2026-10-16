# HANDOFF — 2026-10-13 — Aim markers, desk pieces, Toilet Roll tube done; automatic takeoff next

★ START HERE: Goal: finish Stage 8 (planes) so Alan can sign it off. Next: **automatic takeoff** (MILESTONES D11):
on launch the plane rolls down its desk runway, off the edge and through its paper-chain hoop on its own; the player
gets control once through the hoop. Bots too. Done when, in Play, a human and a bot both launch from a desk, fly
through their hoop untouched, and control starts right after (screenshot sequence + no crash into the desk).

> Read on demand: AGENTS.md → state/STATE.md → THIS. Memories: no-surprise-desktop-control (changed today),
> roblox-mesh-import-gotchas, codex-for-pictures-and-blender, texture-packs-after-new-models, exact-collision-baked.

## STATE (verify before acting)
- HEAD = the commit of this handoff on main, never pushed. `git rev-parse --short HEAD`.
- Tests 255/0 (Play server): `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- Studio: WORKING open, rebuilt place = git; a Play session was running at handoff (likely Alan's: leave it).
  Rojo server restarted (`rojo serve serve.project.json`, port 34872); the Studio plugin is NOT connected: Alan
  clicks Connect (do not click it for him).
- Cost: Codex ×5 (Sol: 2 pictures, 1 refused picture, tube model + 1 fix round ~25-31k relay tokens each, 10-14 min),
  0 Sonnet/Haiku, 0 Meshy, 4 free uploads; primary ~45% context.

## NEXT ACTION + PLAN
1. Automatic takeoff. Today `FlightService:launch` (src/server/FlightService.luau ~182) pivots the plane to `home`
   tilted 9° and hands it straight to the player. Landing already has a scripted LANDING state (`land`, ~260); a
   TAKEOFF state can mirror it: path = hangar → along the runway (home -Z) → off the desk edge (runway droops 37
   studs) → through `ServiceRules.approach(home, cfg)` (hoop centre: home*(0, 15, -145)) → FLYING. Client input
   and gun assist ignored until FLYING; spawn protection covers the roll. Bots launch the same way
   (BotService `mode="launch"`). Side desks: home from `NeutralDesk` CFrame ±48 (desk_pieces.py has the same maths).
2. Weapon animations from piece Role/Pivot/Axis attributes (pieces.rbxmx; tools/art/weapons.py).
3. Weapon sizes per mount so nothing clips; plane colours that stand out (Stage 8 list in MILESTONES).
4. Then Stage 7 sounds/effects → Stage 6 first 60 seconds → Stage 9 modes (Alan's order, D10).
- HOLDS (Alan's go, each): private publish (Stage 5 saving waits on it; not given); Studio-settings changes; Meshy
  spend; anything paid; desktop control (only if truly necessary or he asks). Ask before closing Studio if he may be using it.

## DECISIONS & WHY (this session)
- Aim markers per trigger (orange ring = left, cyan diamond = right), each fills on its own willHit.
- Desk pieces = toys in toy-placements.json via tools/desk_pieces.py (place/lua/drop) + town_toys build; non-solid
  (Box fidelity). Runway stretched to desk depth; lights 2× model size, spread over the desk; rings spin + hover
  client-side (src/client/DeskPieces.luau). Old pads/tape/post rings deleted from classroom(-decor).rbxmx.
- NeutralDesk1/2 collision Parts had X/Z sizes swapped vs the visible school-desk mesh: now 200×230 (runway reach +
  no invisible-desk bumps). Server homes unaffected (use CFrame + Size.Y).
- Toilet Roll = empty cardboard tube (Alan's photos; picture tool refused tube+plugs+tape). 24 sides, 1,104 tris
  (per-part override 1200 in plane_set.py), no mount-clearance notch (mounts shift out by wing_shift 1.35),
  booster under the tube (my brief wrongly said on top; fixed).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (model router, look at the game, STATE ≤60 lines, hard limits); CLAUDE.md (plain English, handoff last).

## CARRY NOTES / GOTCHAS
- Instances made in Edit via CreateMeshPartAsync did not appear in Play; make test pieces on the Server in Play.
- RenderStepped doesn't fire when Studio isn't drawing (window behind): test frame code with a Heartbeat clone.
- With IgnoreGuiInset, GUI AbsolutePosition is 58 px off viewport coords: read `.Position` offsets instead.
- Codex image tool refuses tubes with end plugs + tape; model straight from photos when Alan sends them.
- After new toys: Play once, Ctrl+S (Alan), `town_toys.py packs`, `build`, save_place — or Play starts slow.
- Bell-tower re-export files + closeups.png in the working tree are not ours: leave.

## WHAT SHIPPED / OTHER QUEUED
- 78d215ce Two aim markers · 06a51d19 Toilet Roll concept (full roll; superseded by the tube)
- c23584f0 Desk pieces on every desk · 8c1db5b7 STATE
- a3b97e08 Toilet Roll tube modelled (Codex) · 66c3fe4b Tube in the game (uploads, booster, wing_shift)
- e683f9ea Place rebuilt · 71bede98 STATE · 003f9689 Side-desk runway reach, ring hover, packs saved; place rebuilt
- 0e1e5664 STATE · 9e8c3512 Alan's order (8,7,6,9) + automatic takeoff recorded
- Queued: Track C saving (needs private publish); menu stage gaps; bot-vs-bot rams.

## POINTERS
- src/server/FlightService.luau (launch, land), src/shared/ServiceRules.luau (approach/hangar), src/server/BotService.luau,
  src/client/FlightController.luau, src/client/DeskPieces.luau, tools/desk_pieces.py, docs/MILESTONES.md (D10, D11).
- Previous: `.planning/handoffs/handoff-2026-10-13-playtest-notes-done.md`.
