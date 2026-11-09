# Game text: hand-written Kalam, heavier, with a light outline and a soft shadow

**Decided:** 2026-11-08 (Alan)
**Status:** built for every `PaperUI` word and button (2026-11-08); see [Menus and HUD](../systems/menus-and-hud.md)

## Decision
- All game text uses **style C** from the text style test: today's font (Kalam Bold) made heavier, in warm black, with a
  light cream outline and a soft shadow.
- Recipe as tested (sizes for a 1080p sheet):
  - Colour warm black `40,30,24`.
  - Heavier: a stroke of the same colour, `size x 0.03` thick on titles and buttons, `size x 0.018` on small words.
  - Light outline: a cream (`255,248,232`) copy behind it, stroke = heavier stroke + `max(2, size x 0.07)`.
  - Soft shadow: a black copy behind both, 72% see-through, offset `size x 0.04 + 1` right and `size x 0.06 + 1` down.
- **Loud and quiet** (Alan, after seeing it in the menus the same night): the full look only where words grab attention
  (buttons such as Play, Hangar, Launch, Repair, Customize; titles; card and build names; the HUD's round strip; the
  build-name box). Descriptive words (stat names, gear details, help text) get a thin cream edge and a fainter shadow
  and no extra weight, because the full look made them hard to read.
- **Words fit their boxes** (Alan, same night): letters centred in the art they sit on with even room all round, not
  filling it (Hangar stat names fixed; method in [lessons](../workshop/lessons.md)).
- **The pictures behind the words are the real problem** (Alan, 2026-11-09): menu art looks low-resolution and stretched
  (the Back button's tack squashed, soft edges, nothing pops), so sharp text looks worse on it.
- **Fix the boxes, keep the pictures** (Alan, 2026-11-09, after rejecting a try that scrubbed the painted tacks and tape
  off and drew new ones in code): the original pictures stay exactly as they are; their painted tacks and tape, with
  shadows, are part of the look and are never removed, swapped, recoloured or squashed. A stretched picture is fixed by
  drawing it in a box of its own shape. Only where a screen needs a shape no picture has (the wide Match tip note) does
  a new piece get made, in the same style, shown to Alan before any upload. The menus keep the 3D drawing way (the main
  menu was already sharp). Examples: [playtest](../playtests/2026-11-09-menu-stretch-examples.md).
- **Papers fit inside papers; make paper bigger rather than cram** (Alan, same night): a button, note or X sits fully on
  the paper under it, nothing overlaps another piece, and when rows don't fit, the paper grows. Small square buttons
  (the note's X) stay little square red paper boxes, not round stickers.
- Rejected: the rounded Fredoka styles (D, E), Luckiest Guy and Permanent Marker titles, Patrick Hand, Comic Neue.

## Why
- Alan: the text should look like **a child wrote it with a crayon**; that is the point, and detail gets added on top.
  The rounded font (E) read clearest but "looks like every other Roblox game".
- The heavier Kalam alone (B) blurs in small words; the light outline fixes that, and small text in C reads easier than
  today's.

## Affects
- [Menus and HUD](../systems/menus-and-hud.md) (`src/client/PaperUI.luau` sets the game's font).
- Test picture (concept beside the eight styles): `.planning/text-style-test.jpg`.
