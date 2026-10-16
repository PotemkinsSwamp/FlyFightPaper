# HANDOFF — 2026-10-13 — Playtest notes fixed (wings, weapons, shots, hangar); Toilet Roll model + two aim markers next

★ START HERE: Goal: Alan flies the new planes and weapons and approves. Next: build TWO lead markers (Alan's choice:
one per weapon type, each its own look) and check them in Play on a pencil + paperclip plane; then the Toilet Roll
Gunship concept picture (Codex image) for Alan's OK, then its model; then the desk pieces. Done when Alan approves
after flying.

> Read on demand: AGENTS.md → state/STATE.md → THIS. Memories: plain-vertex-colour-pieces, no-surprise-desktop-control,
> codex-for-pictures-and-blender, measure-concept-before-brief, roblox-mesh-import-gotchas, exact-collision-baked.

## STATE (verify before acting)
- HEAD `b57a894f` (main), never pushed. `git rev-parse --short HEAD`.
- Tests 255/0 (Play server): `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- Studio: WORKING open (rebuilt place, matches git), Rojo connected to `serve.project.json`. Place file = committed.
- Cost: Codex ×3 (Blender: repeater + pencil ~28k relay tokens 9 min; eraser ~26k 8 min), 0 Sonnet/Haiku, 0 Meshy,
  35 free uploads (26 wing halves, 9 weapon pieces); ~3 h; primary ~45% context.

## NEXT ACTION + PLAN
1. **Two aim markers** (Alan chose): FlightHUD lead marker today follows only the trigger-group-1 weapon
   (`src/client/FlightHUD.luau` ~line 95-160, `willHit` picks one group). Show one marker per weapon type, each its
   own look (e.g. small ring for fast guns, bigger pencil-tip mark for slow ones). Check: Play, build pencil +
   paperclip, both markers lead a bot correctly; screenshot.
2. **Toilet Roll Gunship** (body_heavy_mk2, renamed; stats/price/level swapped with Cardboard Gunship, Alan): concept
   picture first (Codex image, ref style = existing parts), Alan approves, then model in `tools/art/plane_set.py`
   (Codex Blender), keep the shared join sockets + BoosterDrop, set catalog `wing_shift` to its half-width
   (wings start at its outer wall). Today it still wears the binder model.
3. Desk pieces (from previous handoff): desk-runway-droop replaces PadSouth/North* + RunwayTape (straight fallback);
   landing-ring replaces 12 `Landing*Segment` per ring (slow spin); runway-light + tip blink. Records in
   `assets/models/toys/<name>/upload.json` (model ids only; mesh ids via Studio InsertService:LoadAsset).
4. Weapon animations from piece Role/Pivot/Axis attributes; weapon sizes per slot with Alan.
- HOLDS (Alan's go, each): private publish; Studio-settings changes; Meshy spend; anything paid. Ask before closing
  Studio if Alan may be using it.

## DECISIONS & WHY (this session)
- Wings = left/right halves (`tools/art/split_wings.py` → `planes/wing_halves.json`); Aircraft.build slides `-L/-R`
  (and sticker left/right) out by catalog `wing_shift` (2.65 on both cardboard-sized bodies = box half-width + a bit),
  every mount slot too. First try used 1.3 (difference of widths) — roots then sat at the nose's width; Alan caught it.
- Swapping a weapon onto a mount that would make 3 types swaps every mount holding the old weapon (else empties them).
- Shot look = launcher's own `fire`/`drop` piece, scaled evenly to the ammo hit-box length, slimmed to ≤1.5× its width
  (hit box unchanged). Per-axis stretch turned the paperclip wire into a plank.
- Pencil: speed 650, drag .0936, lifetime 3.2 → range ~1,800 and end speed 74% (test rule: 50-75%).
- Toilet Roll swap also swapped price/level (heaviest unlocks later); heavy reference test build → body_heavy_mk2.
- Rubber/pencil/eraser launchers rebuilt from plain shapes with vertex colours (they render in Roblox; no textures).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (model router, look at the game, STATE ≤60 lines, hard limits); CLAUDE.md (plain English, handoff last).
- Memory no-surprise-desktop-control: reopen Studio via `Stop-Process` + `save_place.py` + `Start-Process`.

## CARRY NOTES / GOTCHAS
- Editing config/catalog.json needs `python tools/generate_config.py` (Rojo syncs src/generated); forgot once and a
  test pass was stale.
- MCP `screen_capture` camera params are unreliable; set `workspace.CurrentCamera.CFrame` (Edit) or bind a
  RenderStep camera (Client, Play) then capture without params. In Play, menus cover the view: click via
  `user_mouse_input` with `instance_path`.
- Edit-VM `require` caches modules; require a clone parented beside the original to see fresh code.
- Fresh meshes can render invisible for seconds after reopen; look again before debugging.
- Old Meshy maps for gatling-b/pencil-b/eraser are unused now (plain pieces); upload.json rewritten.
- Bell-tower re-export files + closeups.png in the working tree are not ours: leave.

## WHAT SHIPPED / OTHER QUEUED
- 0d79dbaa Place rebuilt after Alan's save · 6877fca9 Shots look like their weapon; pair swap; pencil faster
- 22294821 Hangar preview fit + spin · 35529aba Repeater + pencil launcher rebuilt (Codex)
- 48f9c8e1 Wing halves slide out · efe20301 Wings at the box's outer wall · ee463572 Toilet Roll Gunship swap
- 64eb38ce Eraser launcher rebuilt (Codex); place rebuilt · b57a894f STATE
- Queued: menu stage gaps; Track C saving (needs private publish).

## POINTERS
- `src/shared/Aircraft.luau` (build, mountOffset/muzzleOffset shift, shotLook/shotSize), `src/client/Hangar.luau`,
  `src/client/FlightHUD.luau`, `tools/art/weapons.py`, `tools/art/split_wings.py`, `tools/art/plane_pieces.py`.
- Previous: `.planning/handoffs/handoff-2026-10-12-2359-weapons-and-parts-in.md`.
