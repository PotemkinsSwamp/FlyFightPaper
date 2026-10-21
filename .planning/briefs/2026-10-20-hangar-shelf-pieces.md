# Codex image job: Hangar shelf + Customize binder pieces, ready for the game (2026-10-20)

Alan picked two concepts: `assets/references/ui-concepts/hangar-shelf-screen.png` (input image 1, the first screen)
and `assets/references/ui-concepts/hangar-customize-b.png` (input image 2, the Customize binder). Make the real game
pieces in exactly that look: photographic handmade classroom crafts, warm sunlight from the left, honey-brown wood,
real cork, fibrous torn paper. The game puts words, 3D planes and buttons on top, so EVERY piece is EMPTY: no text,
letters, numbers, planes, drawings, pins or tape unless listed. Each piece is a separate PNG.

## Pieces, saved to `assets/ui/hangarshelf/source/`
| File | Size (px) | What |
|---|---|---|
| background.png | 1920 x 1080 | Plain cork board filling the whole picture, like the concepts' cork, soft warm light from the left, slightly darker at the edges. Nothing on it. Not transparent. |
| cubby-back.png | 400 x 400 | The INSIDE of ONE empty cubby seen from the front: the back wall, the two side walls and the floor going back in perspective, honey wood, soft shadow at the top. Fills the image edge to edge. Not transparent. |
| cubby-front.png | 400 x 400 | The FRONT FRAME of the same cubby: top rail about 40 px, a half divider on the left and right (about 18 px each, so two side by side make one full divider), bottom rail about 70 px. The opening in the middle is FULLY TRANSPARENT. Placed side by side the copies must join seamlessly into one long shelf (same rail heights and wood at both ends). |
| shelf-end-left.png, shelf-end-right.png | 60 x 400 | The shelf's outer side boards that close the row at each end, matching cubby-front's rails. |
| outline.png | 512 x 512 | A thick yellow wax-crayon rectangle outline (band about 30-36 px, the same thickness all the way round, corners inside the outer 64 px, sides even along their length so it can be 9-sliced). Inside fully transparent. Plain bright yellow like the concept's picked cubby. |
| shelf-tab.png | 480 x 140 | One blank torn construction-paper tab like the concept's "My builds" tab, in WHITE / very pale paper (the game tints it yellow, pink or purple), flat bottom edge (it sits on the shelf's top rail), torn top and sides. |
| binder-left.png, binder-right.png | 700 x 1000 each | The open school binder from input image 2, front-facing and flat, EMPTY pages, drawn as ONE binder and then cut in half down the middle of the ring spine (rings split between the halves, so placed side by side they make the whole binder). Left: blue cover with a pale blue left page. Right: a cream right page with the binder edge; NO index tabs on it. Transparent outside the binder. |
| index-tab.png | 260 x 110 | One blank index tab sticking out to the RIGHT, in WHITE / very pale card (the game tints it per colour), slightly rounded right corners, flat left edge (it tucks under the page). |
| button-orange.png | 640 x 200 | The blank orange torn construction-paper button from input image 1 ("Customize" button), no text. Torn edges inside the outer 64 px left and right so it can be stretched sideways. |

How: draw each transparent piece on a flat pure magenta (#FF00FF) background, then remove the magenta with Python/PIL
into real alpha (soft edges, no pink fringe: despill magenta from edge pixels). Check every pixel outside the shape is
alpha 0. Draw the binder once at 1400 x 1000 and cut it in half with PIL.

## Checks to save (in `assets/ui/hangarshelf/`)
- `contact-sheet.png`: every piece on mid grey and on dark navy, with its file name under it.
- `assembled-check.png`, 1920 x 1080, made with PIL: background; five cubbies in a row along the bottom (cubby-back
  under cubby-front, 345 x 345 each, starting x = 60, y = 690) with the shelf ends; outline.png 9-sliced (64 px
  corners) over the middle cubby; three shelf-tab copies tinted yellow (255,215,60), pink (240,110,130) and purple
  (175,130,220) on the top rail at the left; button-orange stretched to 520 x 150 at (1330, 520).
- `binder-check.png`, 1920 x 1080: background; binder-left at (40, 150) and binder-right right next to it at 1:1
  scale of the 1400 x 1000 binder shrunk to 1260 x 900; six index-tab copies down the right page's edge, tinted
  yellow, pink, purple, blue (90,150,230), green (110,190,100), orange (245,150,60), one sticking out 30 px further.
Look at all three yourself. Redo a piece (max 3 tries) if: it has pink fringes; the cubbies don't join into one shelf;
the outline smears when stretched; the binder halves don't meet; it is not in the concepts' look; any shape could read
as a hate symbol (no crossed, hooked or bent-arm shapes).

Rules: Codex image generation and Python/PIL only (no Meshy, no uploads, no Studio, no git commits, never read .env).
Only write the files named above. Report each file and one line on it.
