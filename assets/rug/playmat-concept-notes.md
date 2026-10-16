# Play-mat concept notes

Source: [preview-v4.png](preview-v4.png), 2000 x 1400 pixels.
Style references: the three supplied images in ../references/playmat/.

## Files and method

- [playmat-concept.png](playmat-concept.png): 2000 x 1400, full rug, straight top-down.
- [playmat-concept-closeup.jpg](playmat-concept-closeup.jpg): 3840 x 2688. A direct crop of the final full concept, original-image coordinates x=520..1480 and y=545..1217, enlarged exactly 4x. It includes the bell-tower plaza, fountain park and three straight river crossings south of the plaza.
- Built-in OpenAI ImageGen made the surface restyle, followed by one correction to restore a pad it had omitted. The tool returned 1498 x 1050 pixels despite the requested dimensions. Windows System.Drawing resized that result to the source's 2000 x 1400 canvas, then cropped and enlarged the closeup. The enlargement interpolates existing pixels; it does not add genuine 4x textile detail.
- A separately generated closeup changed pad shapes and was rejected. Neither that draft nor the first full-rug draft is a project deliverable.
- Pillow made temporary side-by-side review sheets: full original versus full concept, and the exact original crop versus the final closeup. Both sheets were visually inspected. Read-only colour checks helped estimate the small differences below.

Only these two images and this notes file were written in the project. No code changes, commits, publishing, Roblox asset uploads or Meshy use. The supplied reference images were inputs to the requested ImageGen operation.

## Full-rug comparison

This is a style concept, not a pixel-exact replacement for the source layout.

| What | What moved, appeared or vanished |
| --- | --- |
| Roads and junctions | No whole road or junction visibly added or removed. The outer loop, upper-left diagonal, both U bends, lower-right diagonal and central grid remain in their original arrangement. Boundaries were redrawn with slight waviness, rounding and local shifts of a few source pixels. Widths are not mathematically identical. |
| River and bridges | All original crossing connections remain, including the diagonal crossing at the lower right. Riverbank curves and bridge edges drift slightly. For example, the blue region immediately east of the central bridge starts about 2 pixels farther left and 1 pixel farther down. No separate raised bridge or railing was invented. |
| Pond | Remains in the upper-left block. Its blue outline extends about 2 pixels farther left and up, and 1 pixel farther right. The small green lily-like dots vanished. |
| Building pads | No complete blank building pad visibly added or removed. Positions and orientations remain recognisable, including both rotated pads. Edges are softened and slightly shifted. For example, the pad at source x=86..224, y=232..343 becomes approximately x=84..221, y=230..342; the lower-right rotated pad's outline also changes slightly. These are approximate colour-boundary measurements. |
| Brown rectangular pad | Vanished in the first draft, then restored in the final image in the same block. Its left edge/tabs and horizontal divisions were redrawn; its main left edge is a few pixels farther right. Its overall position and footprint are close, not identical. It remains a flat brown pad. |
| Parking areas | No complete parking area visibly added or removed, and their orientations remain. Parking bay lines, outlines, divider spacing and narrow entrances were regenerated rather than copied, so stripe counts and tiny connector details are not exact. |
| Fan pads south of river | Underlying blank pads remain. Small pale/red grille or slot marks vanished, and tiny edge tabs/connectors were simplified. These pads' edges shift slightly. |
| Plazas | All three main circular plaza locations remain, including the central plaza divided by the road cross. Their paving rings and spokes were redrawn more strongly. Tiny centre marks vanished, and circular contours shift slightly. |
| Fountain park | Circular grass patch, cross paths and fountain remain. The two small red/brown round decorations vanished. The blue fountain centre grew from roughly 28 to 36 pixels across, with its centre about 1 pixel right and 1 pixel up. Path widths and the grass-circle edge also changed slightly. |
| Printed additions | Yellow road dashes became larger and brighter; white road edges, crossings and parking lines were reprinted. Woven texture and a green fabric binding appeared as requested. No printed buildings, cars, trees, words, numbers, arrows or logos were detected. |
| Outer framing | Same full rectangular composition after resizing. The new binding occupies the former green outer margin and rounds the four corners slightly. It looks somewhat padded; individual stitch loops are not consistently distinct. |

The grass speckling and water/paving line patterns also changed as part of the surface restyle. The road print came out dark slate grey, and the carpet texture is more pronounced and swirly than a perfectly flat felt print.

## Closeup comparison

The closeup is an exact crop and enlargement of the final concept, so it introduces no additional layout changes relative to that image. Compared side by side with the same rectangle of preview-v4.png:

- The central road cross, four plaza sectors, three river crossings, adjacent empty pads, parking areas and fountain park retain the same arrangement.
- The enlarged fountain, removed park decorations, regenerated paving/parking lines, softened pad corners and small road/riverbank shifts listed above remain visible.
- Features outside the crop are outside the frame, not deleted: this includes most of the rug, the pond, outer fabric border and lower-right diagonal crossing.
- Fibre detail is enlarged from the full concept. This is useful for judging the proposed colour and line treatment, but not proof of native high-resolution carpet texture.

## Prompts used for the retained full concept

The following prompts are recorded verbatim. The coordinate estimate in the correction prompt was deliberately approximate; the comparison above describes the actual saved result.

<details>
<summary>Initial surface restyle prompt</summary>

```text
Use case: style-transfer.
Asset: concept picture of an existing Roblox city rug restyled as a real children's printed car play-mat carpet.
INPUTS: Image 1 (preview-v4.png) is the EDIT TARGET and the absolute, immutable layout master. Images 2, 3 and 4 are STYLE REFERENCES ONLY. Do not borrow their buildings, roads, objects, typography or layout.
EDIT IMAGE 1 ONLY. Output one complete rectangular rug, perfectly orthographic straight top-down, identical 10:7 framing to image 1, ideally 2000 x 1400 pixels. Artwork fills the entire canvas. No camera tilt, no perspective, no floor, no props, no surrounding background.
NONNEGOTIABLE GEOMETRY: Trace and preserve every contour and exact screen position in image 1. Every road centreline, road width, outer rectangular loop, upper-left diagonal, two lower U-shaped roads, lower-right diagonal, all junctions, the east-west river and every bridge crossing, the upper-left pond, every rectangular parking lot with its orientation, every rectangular or rotated blank beige building pad, fan pad, circular plaza and park must remain exactly the same position, size and shape. Do not invent a different city. Do not simplify, move, add, remove, merge, split or reshape any road, block, pad, parking area, plaza, park, bridge or water boundary. Preserve the source's road-over-water topology at every crossing and all narrow gaps between features.
CHANGE ONLY THE PRINT AND MATERIAL: cheerful lime-green grass, mid-grey roads, clean soft-white edge lines, clear golden-yellow dashed centre lines, chunky white zebra crossing bars in the existing crossing positions, vivid bright blue river/pond, warm pale cream blank building/fan pads and plazas. Reuse every parking area with simple white parking dividers, no letter P. Keep source paths and fountain circle in the small centre-left circular park. Preserve subtle concentric plaza paving as flat print. Everything is flat kid-friendly printed-felt artwork with soft woven low-pile carpet texture, fine visible fibres, slight fibre fuzz along the coloured print edges, not raised embroidery. No grass blades or photo grass. A narrow neatly stitched fabric binding runs around the very outer canvas edge, within the existing green margin, without covering or shifting the outer road loop. Bright evenly lit textile product scan with no dramatic shadows.
EMPTY PADS: All pads are flat blank shapes, NOT roofs or printed buildings. No printed buildings, cars, buses, toys, trees, people, street furniture, road signs or added decorative objects. No text, letters, numbers, logos, arrows, pictograms, emblems or symbols anywhere. Remove any tiny pre-existing icon-like pad/park marks while retaining their underlying pad/park geometry; road stripes, parking dividers and simple paving lines are allowed.
Repeat: this is an exact-layout surface restyle of image 1, not a newly designed map. Prioritize geometric fidelity above decorative detail.
```

</details>

<details>
<summary>Pad restoration prompt</summary>

```text
Use case: precise-object-edit / style-transfer.
Image 1 is the generated carpet draft to EDIT. Image 2 is preview-v4.png, the original exact layout master used only to restore a missed pad.
Make ONE targeted correction to Image 1: restore the missing brown rectangular pad shown in Image 2 in the SECOND block from the LEFT in the TOP row. Original reference coordinates on its 2000 x 1400 canvas: the brown footprint occupies approximately x=632..714, y=206..342, just RIGHT of the vertical road at x=600, BELOW the large cream pad at x=720..843,y=92..170, and LEFT of the tall parking lot x=790..852. It is an elongated vertical rectangle, not a building. Match its precise source footprint including its little left projecting tabs if visible; keep the footprint brown/tan as a FLAT PRINTED EMPTY PAD with subtle existing straight horizontal divisions, no symbols. This missing original pad MUST be restored.
Preserve every other feature of Image 1 exactly, including all existing blank building/fan pads, all roads and crossroads, road widths, pond, river, bridges, curved roads, parking lots, plazas and park. Change nothing else in the city layout. The green carpet binding must not conceal source geometry.
Keep precisely the same cheerful lime-green low-pile printed-felt carpet style, grey roads with white edges and yellow dashes, blue water, cream blank pads, woven texture and stitched green fabric binding from Image 1. No added objects. No printed buildings, trees, cars or toys. No text, letters, numbers, logos, arrows, emblems, pictograms or symbols. Every pad stays blank.
One complete rug in exactly the original top-down 10:7 composition with no perspective or background. Output 2000 x 1400 pixels if possible. The entire rug must fit in the same framing without shifting, cropping or adding padding.
```

</details>

