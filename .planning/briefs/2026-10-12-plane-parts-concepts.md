# Codex image job: concept sheets for every plane part (2026-10-12)

The game's planes are modular: a player builds one from 1 body + 1 nose + 1 pair of wings + 1 tail, plus up to 4
weapon mounts and 1 booster. Any part must fit any other part. The starter parts are DONE and approved by Alan; every
new part must look like it belongs to the same toy set.

Look first at:
- `assets/models/planes/concepts/pilot/option-a.png` (approved starter, "Classic Dart"), `option-b.png` (chunky style:
  use for the heavy bodies), `option-c.png` (engineered/doubled-cardstock style: use for the slim bodies).
- `assets/models/planes/classic/render-exploded.png` and `render-threequarter.png` (the real starter model: body,
  nose, wings, tail, pellet tube in its taped cradle).
- `assets/references/classroom-city-approved-v1.png` (the game's overall look).

## Style rules (all sheets)
- Folded white/cream printer paper, cardstock and kraft cardboard, masking tape, straws, rubber bands, paper clips:
  a real paper toy, clean folds, slightly soft studio light, plain warm light background.
- Accent colour on every part: RED on tips/stripes (the game swaps red for blue on the blue team at runtime).
- NO stickers, discs, stars, roundels or any symbols on wings (team stickers are added in-game). NO text, numbers or
  labels anywhere on the images.
- Each part shown ALONE (exploded, not attached), all at the same scale, 3/4 view from above-front, nose direction
  pointing to the lower left, with the starter part drawn first in the row for comparison.
- Show the shared joins so they read as fitting together: the body has a front socket (the nose plugs in), a flat
  top saddle (the wings sit on it), a rear socket (the tail plugs in) and two cradle spots under each wing root
  (weapons hang there). Every nose has the same plug at its back; every tail the same plug at its front; every
  wing piece the same centre saddle strip underneath.
- Silhouettes must differ at a glance: slim = sharp and narrow; standard = classic folded dart; heavy = wide,
  thick and reinforced (cardboard and tape).

## Make (16:9, at least 1536 wide), saved to `assets/models/planes/concepts/parts/`
| File | Content (left to right, top row then bottom row) |
|---|---|
| bodies.png | 6 bodies: Classic Fold (starter body), Swift Fold (slim), Cardboard Gunship (heavy) / Courier Fold (standard mk2: same family as Classic, more layers), Racing Fold (slim mk2: even sharper, racing stripes), Binder Gunship (heavy mk2: ring-binder cardboard, metal rings, the biggest). |
| noses.png | 6 noses: Classic Nose (starter), Needle Nose (very thin and long), Blunt Nose (rounded, short, padded) / Long Point (long, multi-fold), Compact Nose (short wedge), Tape Nose (wrapped in masking tape bands). |
| wings.png | 6 wing pieces (each one piece, both wings joined by the saddle): Classic Wings (starter), Swept Wings (swept back) , Broad Wings (wide, straight, gliding) / Delta Wings (big triangle), Cardstock Wings (thick cardstock, folded-up tips), Feather Folds (layered feather-like folds). |
| tails.png | 6 tails: Classic Tail (starter single fin), Split Tail (two fins, V), Ridge Tail (fin plus folded ridge) / Wide Tail (fin plus wide tail planes), Guide Fin (tall single fin), Tape Tail (fin wrapped with tape). |
| weapons.png | 6 weapon mounts, each in its taped cradle, with its projectile beside it: Paper Pellet Gun (starter straw tube, a paper pellet), Staple Burst Gun (mini stapler-like launcher, a staple), Rubber Band Repeater (pencil + rubber band repeater, takes 2 slots so it is longer), Precision Paperclip (sleek launcher, a straightened paperclip dart; 2 slots), Guided Eraser (box launcher, a pink eraser; 3 slots), Pencil Launcher (big, a sharpened pencil rocket; 5 slots, heavy). |
| boosters.png | 3 boosters that strap under the back of the body: Elastic Booster (one rubber-band motor), Spool Booster (thread spool + band), Twin Elastic Booster (two band motors). |
| mixes.png | 4 fully assembled planes mixing parts from the sheets above (e.g. heavy body + broad wings + wide tail + pencil launcher; slim body + needle nose + swept wings + split tail + paperclips; and two more), 3/4 view, plus one small exploded view of one of them showing how the joins line up. |

## Rules
Codex image generation only (no Meshy, no Blender, no uploads, no Studio, no git commits, never read .env). Only write
the 7 files above plus a `README.md` in the same folder (one line per file). Look at each image yourself and redo any
that has text or symbols, a part attached instead of shown alone, the wrong number of parts, or parts that don't look
like the same toy set (max 3 tries each). Report each file and one line on it.
