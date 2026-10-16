# HANDOFF — 2026-10-12 — Power-ups + bell tower fixed; all weapons and plane parts modelled and in pieces; Ctrl+S pending

★ START HERE: Goal: Alan flies the new planes and weapons and approves. First ask whether he pressed Ctrl+S in Studio
(everything new is live-only until then). After his save: `tools/save_place.py` rebuild, reopen, check in Play that plane A,
the 6 weapons, the 23 new parts and the bolt render (screenshots). Then place the desk pieces. Done when Alan flies off the
new runway through the paper-chain ring with new parts and weapons, and approves.

> Read on demand: AGENTS.md → state/STATE.md → THIS. Memories: meshy-thin-parts, roblox-mesh-import-gotchas,
> look-at-textures-before-upload, exact-collision-baked, commit-codex-output-first, texture-packs-after-new-models.

## STATE (verify before acting)
- HEAD `72ab553d` (main), never pushed. `git rev-parse --short HEAD`.
- Tests 255/0 (Play server): `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- Studio: WORKING open (studio_id 61964466-…; MCP lists it as an AutoRecovery name, window title is WORKING.rbxlx).
  Place file last saved 19:42. Live-only in Studio: plane A meshes, CityToys bell-tower bricks moved, Assets.SpeedBolt,
  every AircraftPieces model (89 pieces, built with CreateMeshPartAsync). Rojo serving `serve.project.json`.
- Cost this session: Codex ×2 (craft pictures ~22k relay tokens; 23 plane parts ~28k, 29 min), 0 Sonnet/Haiku, Meshy
  480 credits (1,323 left; floor 300), ~99 free uploads (37 weapons, 61 plane parts, 0 images flagged), ~6 h; primary ~50%.

## NEXT ACTION + PLAN
1. Alan's Ctrl+S → `python tools/save_place.py` → reopen WORKING → Play: plane A + a heavy mix + each weapon render
   (DevCamera screenshots at 1280×720+). If packs changed: `town_toys.py packs` + rebuild (memory texture-packs-after-new-models).
2. Desk pieces (records in `assets/models/toys/<name>/upload.json`; MeshIds via Studio LoadAsset): desk-runway-droop replaces
   PadSouth/North* + RunwayTape (fallback straight); landing-ring replaces 12 `Landing*Segment` per ring (slow spin);
   runway-light + tip blink toward the runway. Check = Alan's look at desk shots.
3. Weapon animations from each piece's Role/Pivot/Axis attributes (spin drum/crank, staple lever hinge + strip slide,
   pencil band snap, missile drop then fly, pellet/wire/staple/pencil hide on fire, back on reload). Then weapon sizes per
   slot count (catalog slots: pencil heavy) with Alan.
- HOLDS (Alan's go, each): private publish; Studio-settings changes; Meshy spend; anything paid.

## DECISIONS & WHY (this session)
- Power-up triggers = measured boxes per hole (config `speed_pickups.spots[].box`), slab test `FlightRules.segmentHitsBox`;
  stacking `FlightRules.stackPickup` (+0.25 each, timer restarts, cap +1.0 = double speed, Alan's rule; cap in review).
- Bell-tower bricks: Bootstrap deletes anything loose at Workspace root on Play; the 3 copies now live in CityToys + placements.
- Weapons = Meshy pictures → Meshy models (Alan approved each look), cut by `tools/art/weapons.py`; paperclip railgun built
  from plain shapes (Meshy fused the wire into a blade, 3 cut attempts failed). Metallic maps skipped (white-on-black risk).
- Straw and railgun stand ON the wing (mount "bottom"), others hang under it; shots leave each launcher's `Muzzle` attribute.
- New plane parts share plane A's join sockets (slim bodies flare at the ends, heavy bodies get a small nose: join rule wins).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (model router, look at the game, STATE ≤60 lines, hard limits); CLAUDE.md (plain English, handoff last).

## CARRY NOTES / GOTCHAS
- Live-rebuild helper for AircraftPieces was a scratch script: regenerate from `pieces.rbxmx` (CreateMeshPartAsync, 180° yaw).
- Pencil slingshot is asymmetric; right-side copy mirrors position only (band inboard). Old pellet-tube/band uploads unused.
- Upload loop uploaded 3 unused paperclip maps before they were viewed (checked after: harmless); delete stale maps first.
- Bell-tower re-export files + closeups.png in the working tree are not ours: leave.

## WHAT SHIPPED / OTHER QUEUED
- 584ff546 Power-ups fire anywhere in the hole and stack; paper bolt; bell-tower bricks · 384c05f6 Codex craft pictures (rejected by Alan)
- 5f1cb887 / 234409a2 / cc789904 / 9cd6332f / 436ac2c3 / db67b7c6 Meshy weapon picture + model rounds
- 6535a6f7 Weapons cut into animatable pieces · d6ef3088 Weapons on the plane, own muzzles
- dd0792d4 23 plane parts (Codex) · b6c98ea9 Parts + boosters in pieces.rbxmx · 72ab553d STATE
- Queued: menu stage gaps; Track C saving (needs private publish).

## POINTERS
- `tools/art/weapons.py`, `tools/art/plane_pieces.py`, `tools/art/plane_set.py`, `src/shared/Aircraft.luau`,
  `assets/models/toys/weapon-*/pieces.json`, `assets/models/planes/set/` (README, parts-review.png, mixes.png).
- Previous: `.planning/handoffs/handoff-2026-10-12-2130-plane-a-in-desk-pieces-next.md`.

## ALAN'S PLAYTEST NOTES (2026-10-12, after this handoff; fix these before the desk pieces)
- **Hangar preview fit:** the plane picture on the hangar paper must scale every build to fill the same frame (bigger
  parts made planes overflow), and let him spin it in all directions (see the underside too, not just yaw).
- **Wings clip into wide bodies:** every wings piece sits on its centre saddle, so on the heavy bodies (Cardboard Gunship,
  Binder Gunship) the wing roots sink into the body sides. Picture: `.planning/handoffs/img/2026-10-12-wings-clip-heavy-body.webp`.
  Fix so wings meet each body's actual side (per-body wing root width or a saddle that follows the body).
- **Binder Gunship must change:** it looks like the Cardboard Gunship plus rings, and a binder isn't a paper plane.
  Needs a new idea and name: still cardboard-ish, bigger than the Cardboard Gunship. Workshop it with Alan (concepts first).
- **Rubber Band Repeater model is a mess:** redo it in Blender (clean shapes, plain colours, a drum that clearly spins,
  bands stretched lengthwise), like the paperclip railgun rebuild. Memory meshy-thin-parts.
- **Pencil launcher needs Blender work:** broken textures. Check every weapon's texture/UV in the game up close; redo bad
  pieces in Blender.
- **Weapon picking:** clicking a weapon while a mount slot is selected must replace what's in that slot (no "clear mount"
  first).
- **Shots must look like the weapon:** eraser shots still use the box eraser; each weapon's projectile should be its own
  piece (pellet ball, staple, band, paperclip wire, cap-eraser missile, pencil).
- **Pencil launcher shots a little faster** (catalog speed, small bump; check range/drop stays sensible).
- **To discuss (product call, Alan's):** with two different weapons fitted (e.g. pencil launchers + precision paperclips),
  which one does the aim/lead tracer follow? Bring options; don't decide alone.
- Open: Alan was playtesting live in Studio; still ask whether he pressed Ctrl+S before any rebuild.
