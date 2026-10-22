# Codex image job: desk quick menu pieces (2026-10-22)

Alan picked `assets/references/ui-concepts/desk-quick-menu-b.png` (input image 1). Input image 2
(`assets/ui/hangarshelf/preview-shelf.png`) is the approved Hangar look the pieces must match: photographic handmade
classroom crafts, warm sunlight from the left, real cork, fibrous torn paper, wrinkled masking tape. The game puts
words and 3D planes on top, so EVERY piece is EMPTY: no text, letters, numbers, planes or drawings. Each piece is a
separate PNG.

## Pieces, saved to `assets/ui/deskmenu/source/`
| File | Size (px) | What |
|---|---|---|
| cork-strip.png | 400 x 1200 | A tall strip of plain cork board like input image 1's left strip behind the build photos: NO wooden frame, NO border of any kind; its long edges and short ends are rough, slightly uneven cut/torn cork. Soft drop shadow allowed only inside the outer 20 px. Nothing pinned on it. Transparent outside the cork. |
| photo.png | 480 x 400 | One small instant photo like input image 1's build photos: cream-white photo paper border (about 22 px on the top and sides, about 70 px at the bottom), the picture area inside is plain flat sky-blue paper (RGB about 120,175,225) with nothing on it, two short pieces of wrinkled masking tape over the top-left and top-right corners at an angle. Very slight curl and shadow so it reads as a real photo taped down. Transparent outside. |
| launch.png | 960 x 320 | The big LAUNCH! button paper from input image 1 with no text: bright, vivid, saturated green torn construction paper (much brighter than a dull sage green; like RGB 70,200,70), a wrinkled masking-tape piece across each end. Torn edges inside the outer 80 px on the left and right so it can be stretched a little sideways. Transparent outside. |

How: draw each piece on a flat pure magenta (#FF00FF) background, then remove the magenta with Python/PIL into real
alpha (soft edges, no pink fringe: despill magenta from edge pixels). Check every pixel outside the shape is alpha 0.

## Check to save
- `assets/ui/deskmenu/contact-sheet.png`: every piece on mid grey and on dark navy, with its file name under it.
Look at it yourself. Redo a piece (max 3 tries) if: it has pink fringes; it has a frame or border (cork strip); the
photo's blue area has anything on it; it is not in the concepts' look; any shape could read as a hate symbol (no
crossed, hooked or bent-arm shapes, including in the cork's texture).

Rules: Codex image generation and Python/PIL only (no Meshy, no uploads, no Studio, no git commits, never read .env).
Only write the files named above. Report each file and one line on it.
