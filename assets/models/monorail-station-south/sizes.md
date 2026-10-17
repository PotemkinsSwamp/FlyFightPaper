# South monorail station measurements

Approved source: concept-front.png, variant E, 1254 x 1254 pixels. Front -Y, Z up.
Re-measured 2026-10-16 against the chosen E build spec in concept-v2-brief.md.
The long front runs roughly from (274,248) to (1161,189), with its lower edge near
(274,557) to (1161,493). The visible left end recedes toward approximately (101,196).
These are perspective picture guides, not one uniform pixels-per-stud scale.
The chosen build spec fixes dimensions where the generated picture is inconsistent.

| Part | Approximate picture guide | Current studs and placement |
|---|---|---|
| Two toy-brick legs | Front widths about 195-265 pixels; left end visibly deep | 41 x 80 x 80, centres x +/-64.5; nominal x -85..-44 and 44..85 |
| Five courses per leg | Blue/yellow courses and small real joins | 15.4 pitch, 15.2 block height; .2 joins, .15 side gaps |
| Three blocks per course | Three block faces across each leg | 13.667 pitch; round studs in four depth rows at y -31, -10, 10, 31 reach z 80 |
| Road opening | Broad central gap beneath the tin | 88 x 80, x -44..44, z 0..80, through Y |
| Rounded enamelled tin | Long red front about 890 pixels wide; rounded left end | 170 x 80 x 64, x -85..85, y -40..40, z 83..147, corner radius 6 |
| Bottom rim | Continuous narrow silver strip under the red body | 170 x 80 x 3, z 80..83; rolled edge near z 82 |
| Deep lid / seam | Silver cap about 50-70 pixels high in the picture | 170 x 80; lid z 143..149.3, seam at 143.3, rolled top reaches 150 |
| End-to-end track opening | Large silver-edged hole in the visible left end; no front portal | 62 x 42, y -31..31, z 100..142, through the full X length |
| Metal tunnel lining | Silver interior on end aperture and through long windows | .5-thick walls centred y +/-31.25; floor z 99.5..100; ceiling z 142..142.5, full 170 length |
| Three long windows, front and back | Three cream rectangles, approximately 240 x 150 pixels each; no small pairs | Clear 46 x 30 each, centres x -52, 0, 52, z 105..135; open through each 9-stud wall, no panes or mullions |
| Window spacing | Short red piers and slightly wider red end margins | Clear spans -75..-29, -23..23, 29..75; two 6 gaps and two 10 end margins |
| Cream window frames / silver reveals | Thin cream outer borders, silver inner edges | Cream 1.2 wide outside each clear rectangle, depth 1.5, centres y +/-40.8; .5-thick silver reveal sleeves across y 31..40.1 and -40.1..-31 |
| Rolled end aperture edges | Rounded silver border on each narrow end | 66 x 46 centreline, radius-2 corners, .65 tube; x +/-85.5, z centre 121 |
| Single-pane leg windows | Cream frames with blue inset panes | 16 x 20; both z 60, right also z 20; front at y -40 |
| Green door / knob / step | Green door and studded step on the left leg | 14 x 26, base 4, knob z 17 inset 2.8; step 20 x 7 x 3, centre y -43 |
| Clasp / hinge hardware | Two front catches above the windows, rear hinges on the lid seam | Base plates 10 x 1 x 8 from z 138.5; front barrels z 146, rear pins z 145.5 |

Width checks: 41 + 88 + 41 = 170. Window row: 10 + 46 + 6 + 46 + 6 + 46 + 10 = 170.
Depth check: 9 + 62 + 9 = 80. The .5-thick lining lies within the nominal 9-stud walls.
Height checks: leg studs reach 80; bottom rim 80..83; body 83..147; rolled lid reaches 150.
Tunnel centre is z 121. Window centre is z 120, leaving 5 below and 7 above inside the clear tunnel.

Camera: front-left (-.42,-1,.23), ortho 218, target z 75. The left end aperture is visible.
The station exports no track, train, road or bridge deck. Those picture elements are separate town assets.

Output checks and piece measurements: parts.json. Visual comparison: compare.png.
Remaining visual differences: fix-review.json.

2026-10-17 (Alan): everything above the legs lifted 20 studs (`STATION_LIFT` in blocks.py); legs 97 tall, track tunnel z 120-162, height 170.
