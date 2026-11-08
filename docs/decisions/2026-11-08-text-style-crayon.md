# Game text: hand-written Kalam, heavier, with a light outline and a soft shadow

**Decided:** 2026-11-08 (Alan)
**Status:** picked; rolling it out to every menu and the HUD is its own job, queued in [STATE](../../state/STATE.md)

## Decision
- All game text uses **style C** from the text style test: today's font (Kalam Bold) made heavier, in warm black, with a
  light cream outline and a soft shadow.
- Recipe as tested (sizes for a 1080p sheet):
  - Colour warm black `40,30,24`.
  - Heavier: a stroke of the same colour, `size x 0.03` thick on titles and buttons, `size x 0.018` on small words.
  - Light outline: a cream (`255,248,232`) copy behind it, stroke = heavier stroke + `max(2, size x 0.07)`.
  - Soft shadow: a black copy behind both, 72% see-through, offset `size x 0.04 + 1` right and `size x 0.06 + 1` down.
- Rejected: the rounded Fredoka styles (D, E), Luckiest Guy and Permanent Marker titles, Patrick Hand, Comic Neue.

## Why
- Alan: the text should look like **a child wrote it with a crayon**; that is the point, and detail gets added on top.
  The rounded font (E) read clearest but "looks like every other Roblox game".
- The heavier Kalam alone (B) blurs in small words; the light outline fixes that, and small text in C reads easier than
  today's.

## Affects
- [Menus and HUD](../systems/menus-and-hud.md) (`src/client/PaperUI.luau` sets the game's font).
- Test picture (concept beside the eight styles): `.planning/text-style-test.jpg`.
