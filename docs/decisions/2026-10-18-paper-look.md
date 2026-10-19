# Planes: paper texture and softer team colours

**Decided:** 2026-10-18 (Alan)  
**Status:** in force; colours and paper textures on every part and booster (2026-10-18), approved by Alan after trying it in game

## Decision
- Every plane part gets a paper texture: a UV layout (so Roblox can put any texture, and later skins, on it) and
  near-white colour, bump and roughness maps with fold creases and paper edges, tinted by the team colour.
- Team colours are softer, coloured-paper shades instead of pure red and blue: red 214,78,72 and blue 70,128,214
  (`src/shared/Aircraft.luau`).
- The models stay as they are (Alan: rebuilding them as thin folded sheets is too much); touch-ups only where a part
  needs one.

## Why
Alan, 2026-10-18: the planes looked bland and like plastic in Roblox, and skins will only look as good as the parts
under them. In-game test by the back wall: the old meshes had no UV layout, so no texture could show at all; the
paper sample showed its creases, and the softer colours made it read as coloured paper. Sample, renders and upload
ids: `assets/models/planes/paper-sample/`.

## Affects
- [Planes and hangar](../systems/planes-and-hangar.md) · [Shop plan](2026-10-18-shop-plan.md)

All decisions: [decisions](README.md)
