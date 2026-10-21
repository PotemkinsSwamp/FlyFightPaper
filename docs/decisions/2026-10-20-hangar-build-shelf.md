# Hangar: builds live in a cubby shelf; Customize opens the part editor

**Decided:** 2026-10-20 (Alan, from three Codex concepts)  
**Status:** in force (planned, not built)

## Decision
- The five 1-5 squares are replaced by a **classroom cubby shelf** (concept "picker-b"): each saved build sits in its
  own cubby as its real 3D plane (a still ViewportFrame between a painted back wall and the shelf's front frame, redrawn
  only when that build changes), with its name on a masking-tape label under it. The picked cubby has a yellow crayon
  outline.
- **Groups are tabs on top of the shelf:** My builds, Range (the Range's own five) and Special (ready-made planes to
  unlock or buy, later). The row scrolls sideways when a group has more than fit.
- **Two screens:** the shelf screen shows the picked build big (the taped photo), its name on a masking-tape label with
  a pencil (concept A: click to rename), and a **Customize** button that opens the part editor (part tabs, cards,
  stats, Save). Tapping a cubby picks that build (in the Range it swaps your plane). Alan: "you tap ... one of your
  presets and then there's a button to customize ... it pulls up another screen."
- Names are always visible (no hover), so it works on phones.
- **The Customize screen gets its own concepts first and must grow without a redo** (Alan, same night): today it edits
  body, nose, wings, tail, weapons and boost; later skins, trails, skins for single parts and for weapons, mixed and
  matched. So categories are a list that can get longer (not a fixed row of six tabs), and a part can carry a skin.

## Why
The 1-5 squares can't show names, had no room for future special planes, and the white name box didn't match the
crafts look (Alan 2026-10-20: "we might as well just change it now so it's able to easily include other things in the
future"). Cubbies looked best; a ViewportFrame makes them as cheap as polaroids. The crayon-card concept was dropped:
every build would need a hand-drawn picture.

## Pictures
`assets/references/ui-concepts/hangar-shelf-cubbies-b.png` (chosen), `hangar-name-tape-a.png` (name label),
`hangar-shelf-polaroids-a.png` (runner-up).

## Affects
- [Planes and hangar](../systems/planes-and-hangar.md), [Tutorial](../systems/tutorial.md) (the Range)

All decisions: [decisions](README.md)
