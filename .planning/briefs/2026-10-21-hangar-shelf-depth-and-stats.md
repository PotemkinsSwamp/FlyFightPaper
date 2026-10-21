# Codex image job: Hangar shelf with depth + reference-style stat sheet pieces (2026-10-21)

Alan looked at the assembled preview (`assets/ui/hangarshelf/preview-shelf.png`, input image 2) against the concept
(`assets/references/ui-concepts/hangar-shelf-screen.png`, input image 1) and asked for two things:
1. **The shelf needs depth like the concept.** The cubby insides are good, but the outside is flat. In the concept we
   look slightly DOWN on the shelf: you see the shelf's TOP surface (a board you could rest your hand on, the tabs sit
   on it), and the front frame has visible thickness (a lit top edge, darker underside, soft shadows cast into the
   cubbies). Redraw the outside of the shelf so it has that perspective.
2. **The stat sheet should look like the concept's:** torn notebook paper with tape at the top, big coloured paper
   label strips, and big crayon boxes (filled solid, or empty with a crayon outline in the row's colour).

Same look as before: photographic handmade classroom crafts, honey-brown wood, warm light from the left. Every piece
is EMPTY (no text, letters, numbers, planes, pins). Save to `assets/ui/hangarshelf/source/`, replacing the old files
of the same name (git keeps the old ones).

## Pieces
| File | Size (px) | What |
|---|---|---|
| cubby-front.png | 400 x 480 | ONE cubby's front, seen slightly from above. Top 80 px: the shelf's TOP surface in perspective (wood grain running left-right, lit by the sun, its front edge a rounded lit band). Below it the front frame: top rail about 36 px, a half divider on the left and right (about 18 px each, so two side by side make one full divider), bottom rail about 70 px, all with visible thickness and shading. The opening (about x 18-382, y 116-410) is FULLY TRANSPARENT. Copies placed side by side must join seamlessly into one long shelf (top surface, rails and grain continuous; no vertical seam). Straight-on: no sideways vanishing point, so every copy is identical. |
| cubby-back.png | 400 x 400 | Keep the current inside of the cubby (Alan likes it); only redraw if its light must change to match. Fills the image. Not transparent. It is placed behind cubby-front's opening (from y 80 of cubby-front down). |
| shelf-end-left.png, shelf-end-right.png | 70 x 480 | The outer side boards closing the row, matching cubby-front: top 80 px shows the top surface's END CORNER seen from above (left end: top-left corner; right end: top-right corner), then the side board's front face with thickness. |
| stats-paper.png | 720 x 800 | A torn sheet of notebook paper (holes down the left edge, faint blue ruled lines, a red margin line) with a strip of masking tape across the top centre, blank, slightly tilted (1-2 degrees) like the concept's. Transparent outside the paper. |
| stat-label.png | 320 x 96 | One blank torn construction-paper label strip like the concept's "Health" strip, in WHITE / very pale paper (the game tints it red, blue, green, orange...). |
| stat-box.png | 80 x 80 | One crayon-coloured FILLED square like the concept's bar boxes, in WHITE / very pale waxy crayon (tinted in the game), slightly uneven edges. |
| stat-box-empty.png | 80 x 80 | The same square as only a crayon OUTLINE (band about 6-8 px), WHITE (tinted in the game), inside fully transparent. |

How: draw transparent pieces on flat pure magenta (#FF00FF), then remove the magenta with Python/PIL into real alpha
(soft edges, despill, no pink fringe). Check every pixel outside the shape is alpha 0.

## Checks to save (in `assets/ui/hangarshelf/`)
- `contact-sheet.png`: every piece in `source/` on mid grey and dark navy with its file name (replace the old one).
- `shelf-check.png`, 1920 x 1080: `ready/bg-1..4.png` tiled as the background (or source/background.png); five
  cubbies in a row (cubby-front 345 x 414 each starting x = 45 + 60, y = 640; cubby-back 345 x 345 at the same x,
  y = 640 + 69) with the shelf ends (60 x 414) at both ends; three `source/shelf-tab.png` copies tinted yellow
  (255,215,60), pink (240,110,130), purple (175,130,220) standing ON the top surface at the left (their bottoms on the
  top surface, about y 640 + 40). Compare with input image 1: the shelf must read as a 3D piece of furniture.
- `stats-check.png`, 760 x 840: stats-paper with six rows: a stat-label tinted (red 230,90,90 / blue 80,140,230 /
  green 90,180,90 / teal 90,190,200 / orange 245,150,60 / purple 175,130,220) and five boxes after it, the first three
  stat-box, the last two stat-box-empty, both tinted the row's colour. Compare with the stat sheet in input image 1.
Look at the checks yourself. Redo a piece (max 3 tries) if: pink fringes; the cubbies don't join; the shelf still looks
flat; it is not in the concept's look; any shape could read as a hate symbol (no crossed, hooked or bent-arm shapes).

Rules: Codex image generation and Python/PIL only (no Meshy, no uploads, no Studio, no git commits, never read .env).
Only write the files named above. Report each file and one line on it.
