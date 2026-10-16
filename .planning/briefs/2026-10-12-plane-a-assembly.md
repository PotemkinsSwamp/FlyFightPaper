# Plane A in the game: multi-mesh parts, team colours and stickers, new gun mounts (2026-10-12)

The approved starter plane (body_standard + nose_0 + wings_0 + tail_0 + pellet guns) is modelled as plain-colour
pieces: `assets/models/planes/classic/parts.json` (every piece: part, region, size, `slot_pivot`,
`center_offset_from_slot`, suggested colour, `team_color_at_runtime`; mounts) and the sticker shapes in
`assets/models/planes/stickers/stickers.json`. All pieces are uploaded; their MeshIds are in
`assets/models/planes/uploads.json` under "meshes" (keys = FBX stems), real sizes = parts.json sizes (checked).
Axes in parts.json: X right, Y up, -Z forward, studs, assembled plane frame = the plane's Root frame.

## 1. Generator `tools/art/plane_pieces.py` -> `assets/models/planes/pieces.rbxmx`
Write a Folder `AircraftPieces` (rbxmx, same XML style as `assets/models/aircraft/aircraft.rbxmx`) containing:
- One `Model` per catalog part id that has new pieces: `body_standard` (body-paper), `nose_0` (nose-paper,
  nose-accent), `wings_0` (wings-paper, wings-accent, wings-sticker-left, wings-sticker-right), `tail_0`
  (tail-paper, tail-accent). Each child is a MeshPart named after its FBX stem with: MeshId from uploads.json,
  `size` and `InitialSize` = parts.json size, CFrame position = `slot_pivot + center_offset_from_slot` (identity
  rotation), Color3uint8 = suggested colour, Material SmoothPlastic, Anchored, CanCollide/CanTouch/CanQuery false,
  CastShadow true, CollisionFidelity Box (2), RenderFidelity Automatic (0), and a string attribute `Region` = the
  region ("paper", "accent", "sticker", "band").
- `launcher_pellet` Model: pellet-tube and pellet-band, positioned RELATIVE TO THE LEFT MOUNT's tube centre
  (parts.json mounts.left.tube_center), i.e. tube at its centre offset, band at its offset.
- A Folder `Stickers` with MeshParts `sticker-square` and `sticker-circle` (sizes from stickers.json / the upload
  check: square 1.7 x 0.04 x 1.7, circle 1.8 x 0.04 x 1.8), at the origin.
Print what it wrote. Add `"AircraftPieces": {"$path": "assets/models/planes/pieces.rbxmx"}` next to
`AircraftParts` in BOTH `default.project.json` and `serve.project.json`.

## 2. `src/shared/Aircraft.luau`
- `build`: for each of body/nose/wings/tail, if `Root.Assets.AircraftPieces` has a Model named `loadout[slot]`,
  clone every MeshPart child into Appearance (name them `slot.."-"..child.Name`), Size*factor, CFrame =
  body.CFrame * CFrame.new(child.Position*factor); same anchoring/weld/flags as today. Otherwise keep today's
  single-template path (other parts aren't remade yet). The early "template missing" check must accept either.
- Weapons: if `AircraftPieces` has `launcher_<id>`, clone its children at `mountOffset(slot,factor)` +
  child offset*factor, mirrored in X for right-side slots (even slot numbers): mirror = negate the X offset (pieces
  are symmetric, no rotation needed). Else today's EquipmentParts path.
- New `Aircraft.paint(model)`: reads `model:GetAttribute("Team")`. team:1 = RED (accent 206,48,43; stickers =
  `sticker-square`, colour 206,48,43), team:2 = BLUE (accent 40,95,200; stickers = `sticker-circle`, colour
  40,95,200), "" or nil (free-for-all) = red accent and the plain white placeholder stickers. Accent = every
  Appearance part whose Region is "accent". Stickers: for each Region "sticker" part, swap its MeshId-carrying
  part for a clone of the chosen sticker template placed at the placeholder's CFrame, sized template.Size*factor
  (keep a reference to the placeholder so switching back to FFA restores it; simplest: keep placeholders but set
  Transparency 1 and parent the team sticker next to it, welded like the others, named `slot.."-team-sticker"..n`;
  remove old team stickers before adding). Call `paint` at the end of `build`, and in `build` connect (once per
  model, guard with an attribute) `model:GetAttributeChangedSignal("Team")` to `paint` (server-side builds only
  need it; previews too is fine).
- Mounts: `mountOffset(slot,factor)` = slots 1/2 at plane A's tube centres (±1.76, 0.08, -1.3134), slots 3/4 under
  the wings at (±3.7, 0.38, -0.6); odd slots left (-X) like today. New `Aircraft.muzzleOffset(slot,factor)` =
  mountOffset + (0,0,-1.5566*factor) (parts.json weapon.muzzle_offset_from_center). Replace the three
  `mountOffset(...)+Vector3.new(0,0,-3*factor)` uses (CombatService.luau ~218, CombatEffects.luau ~295,
  FlightHUD.luau ~139) with `muzzleOffset`. Booster position unchanged.
- `src/server/CombatService.luau` line ~25: also preload `Root.Assets.AircraftPieces` (HitShapes.preload walks
  direct children only: make it walk descendants so Models' MeshParts are found; edit `src/server/HitShapes.luau`
  preload accordingly). Check HitShapes' copy code (~line 40) still finds every MeshPart in Appearance (it should;
  skip parts with Transparency 1 so hidden placeholder stickers aren't hit shapes).
- `src/server/RoundRuntime.luau` ~line 86-88: name tags follow the same colours: team:1 red text (255,120,110) with
  "[■] ", team:2 blue text (110,170,255) with "[●] ".

## Check
`python tools/plane_pieces.py` runs (path: tools/art/). Tests in `tests/unit/` must not need changes; if any test
uses mountOffset numbers, update only those expectations and say so. You can't reach Studio: say what you couldn't
check. Don't commit.
