# South monorail station v2: concept brief (Alan 2026-10-16)

Why: the station moves to the middle river bridge. The monorail now crosses it along its LENGTH (end to end), not
front to back. The road still passes under it front to back, between the two legs.

Reference: `concept-front.png` in this folder (approved look). Keep its look: a red enamelled lunch tin with a silver
rolled rim and lid, metal clasps, cream-framed blue windows, standing on two blue-and-yellow toy-brick legs with
windows, a green door and step on the left leg. Grey studio background, photographic toy, soft light, same camera
height as the reference.

Sizes (studs; keep these proportions in the picture):

| Part | Size |
|---|---|
| Tin | 170 long x 100 deep x 64 tall (deeper than today's 70), lid on top; whole station 150 tall |
| Legs | two, each 41 wide x 100 deep x 80 tall; 88 gap between them for the road |
| Road | runs under the tin, front to back, between the legs |
| Track tunnel | 62 wide x 42 tall, 17 above the tin's bottom rim, runs straight through the tin from the LEFT END to the RIGHT END (through the two narrow 100-deep ends), centred front to back |
| Track | a grey beam with a yellow stripe passes through the tunnel and sticks out of both ends |

Check: 41 + 88 + 41 = 170 (legs + road = tin length). Tunnel 62 inside a 100-deep tin leaves 19-stud walls front and
back. Tunnel 17 + 42 = 59 of the tin's 64.

Camera: three-quarter view from the front-left, high enough to see the left END with the tunnel opening and the
beam coming out of it, and the long FRONT side with the road going under it.

Variants (one picture each, 1254 x 1254):
- A: same front as today (two window pairs, clasps) but no front opening; tunnel openings only at the ends, with the
  same silver lining.
- B: like A, plus a long low window strip along the front at tunnel height so you can see a train inside.
- C: like A, but the tunnel ends have a red tin "hood" frame sticking out 4 studs round each opening.

No text, letters, numbers or logos anywhere. No people.

## Round 2 (Alan 2026-10-16, on A-C): "like B, but it just has long windows you can see the train through"
Start from concept-v2-b.png. The front (and the back) of the tin has only LONG windows at tunnel height, cream-framed,
through which the train shows as it passes; no small window pairs, no separate low strip. The train inside is our toy
monorail (`assets/models/toys/monorail/train-concept.png`: cream body, red stripe, dark windows, yellow headlights).
- D: one long window running nearly the whole length of the front (thin cream frame, two or three slim mullions).
- E: three long windows in a row with short red tin between them.

## Chosen: E (Alan 2026-10-16). Build spec
`concept-front.png` is now E. Changes to `monorail_station_south()` in `tools/art/blocks.py` (everything else keeps
today's look and pieces):
- Depth 70 -> 80 for the tin, lid, rims, rolled edges and both toy-brick legs (walls either side of the tunnel 9 thick).
- Track tunnel runs along X, end to end: 62 wide (y -31..31) x 42 tall (z 100..142) through the whole 170 length;
  silver liner walls at y = +/-31.25, floor and ceiling; the rolled silver aperture edge on both END faces.
- No front/back tunnel opening and no small window pairs any more.
- Three long open windows on the front (-Y) and on the back (+Y): each 46 long x 30 tall, centres x -52, 0, 52,
  z 105..135, open straight through the 9-stud wall into the tunnel (no glass, so the train shows), cream frames
  like today's windows, silver lining on the reveals.
- Clasps and hinges stay above the windows (bases from z 138.5 up).
- Openings: road through Y between the legs (x -44..44, z 0..80); monorail tunnel through X (y -31..31, z 100..142).
- Camera: three-quarter from the front-left like concept E, so the left end's tunnel opening shows.

## Alan's review of the first build (2026-10-16): "almost good"
- No foundation: put the grey tile base plates back under both legs (as in the concept and today's station).
- The back (renders/back.png) is fine as it is (Alan, on seeing it): only the foundations change.
