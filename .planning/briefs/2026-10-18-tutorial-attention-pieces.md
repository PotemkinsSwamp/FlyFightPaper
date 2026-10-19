# Codex image job: tutorial attention pieces, ready for the game (2026-10-18)

Alan approved the concept `assets/references/ui-concepts/attention-pieces.png` (also see attention-a/b/c.png). Now make
the real game pieces in exactly that look: thick wax-crayon strokes, bright yellow inside with a red-orange edge,
slightly uneven like a child drew them; yellow paper with masking tape. The game moves and stretches them, so each
piece must be a separate PNG with a TRANSPARENT background, built for stretching as described.

## Pieces, saved to `assets/ui/tutorial/source/`
| File | Size (px) | What |
|---|---|---|
| frame-box.png | 512 x 256 | The rectangle crayon frame, NO burst marks. The game stretches it to any button size with 9-slice: the crayon band must be the same thickness (about 36-44 px) all the way round, every corner fits inside the outer 64 px, the straight sides look the same along their length (no blobs in the middle of a side), and the inside is fully transparent. |
| frame-ring.png | 512 x 512 | The circle crayon frame, NO burst marks, band about 40 px, centred, inside fully transparent. |
| burst.png | 128 x 48 | ONE crayon "look here" dash mark, lying horizontally, centred. The game places and animates several around the frame. |
| tag.png | 512 x 160 | The blank torn yellow paper tag with masking tape on the top-left and bottom-right corners, no text. Stretched sideways with 9-slice: tape and torn corners inside the outer 96 px left/right, the middle stretch looks plain. |
| arrow-big.png | 512 x 320 | The folded yellow paper arrow with the crayon outline, pointing RIGHT, filling the image. |
| dash.png | 256 x 64 | Texture for the guide line: ONE crayon dash (yellow, orange edge) filling the left 60% of the width and the middle of the height; the right 40% fully transparent. It is repeated end to end, so the dash's left and right ends must be rounded crayon ends. |

How: draw each on a flat pure magenta (#FF00FF) background, then remove the magenta with Python/PIL into real alpha
(soft edges, no pink fringe: despill magenta from edge pixels). Check every pixel outside the shape is alpha 0.

## Checks to save (also in `assets/ui/tutorial/`)
- `contact-sheet.png`: every piece twice, on mid grey and on dark navy, with its file name under it.
- `stretch-check.png`: frame-box 9-sliced (64 px corners) to 600x160, 160x400 and 300x300; tag 9-sliced to 700x160;
  dash repeated 6 times in a row. Draw this with PIL (real 9-slice: corners copied, edges stretched one way, middle
  stretched both).
Look at both yourself. Redo a piece (max 3 tries) if: it has pink fringes; the stretched frame shows smeared blobs or
broken corners; the piece is not in the concept's look; any shape could read as a hate symbol (no crossed, hooked or
bent-arm shapes; the dash marks must not form any symbol).

Rules: Codex image generation and Python/PIL only (no Meshy, no uploads, no Studio, no git commits, never read .env).
Only write the files named above. No weapon words in prompts. Report each file and one line on it.
