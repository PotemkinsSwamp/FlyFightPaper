# Codex image job: desk quick menu strips and tape (2026-10-22, second batch)

Same look as `.planning/briefs/2026-10-22-desk-menu-pieces.md` (input image 1 = concept
`assets/references/ui-concepts/desk-quick-menu-b.png`, input image 2 = `assets/ui/hangarshelf/preview-shelf.png`).
Alan: the old strips have a push pin drawn on them, and a pin must never stretch with its paper. The game now puts
separate tape pieces on the ends of plain strips. EVERY piece is EMPTY: no text, letters, numbers, pins, tape or
drawings unless listed.

## Pieces, saved to `assets/ui/deskmenu/source/`
| File | Size (px) | What |
|---|---|---|
| strip-blue.png, strip-green.png, strip-yellow.png, strip-red.png | 1024 x 260 each | One torn construction-paper strip like input image 1's right-hand buttons (Refill Lift blue, Repair green, Fresh plane yellow, Full refold red/pink), bright and saturated like the concept, crumpled texture, torn fibrous edges all round. NO pin, NO tape, nothing on it. Torn edges inside the outer 60 px. Transparent outside. |
| tape.png | 260 x 100 | One short piece of wrinkled beige masking tape with torn ends, lying flat, seen from above. SEMI-TRANSPARENT: alpha about 200 of 255 across the tape (things under it show through a little), a little lower at the torn ends. Transparent outside. |

How: draw each piece on a flat pure magenta (#FF00FF) background, then remove the magenta with Python/PIL into real
alpha (soft edges, no pink fringe: despill magenta from edge pixels). For tape.png then scale the tape's alpha to about
200. Check every pixel outside the shape is alpha 0.

## Check to save
- `assets/ui/deskmenu/contact-sheet-2.png`: every piece on mid grey and on dark navy, with its file name under it, plus
  each strip with two tape copies across its ends (turned about 25 degrees, opposite ways).
Redo a piece (max 3 tries) if: pink fringes; a pin or tape drawn on a strip; the tape is fully opaque; not in the
concept's look; any shape could read as a hate symbol (no crossed, hooked or bent-arm shapes).

Rules: Codex image generation and Python/PIL only (no Meshy, no uploads, no Studio, no git commits, never read .env).
Only write the files named above. Report each file and one line on it.
