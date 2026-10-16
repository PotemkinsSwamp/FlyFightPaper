# Codex image job: the other 3 views for 8 Meshy buildings (2026-10-15)

Alan approved the front concepts. Meshy builds each model from 4 views, so each building needs `concept-left.png`,
`concept-back.png` and `concept-top.png` beside its approved `concept-front.png` (never change the front).

Copy the way our earlier sets were made: look at all four of `assets/models/glue-tower/concept-*.png` and
`assets/models/milk-carton-tower/concept-*.png`. Same picture size as the front, same plain light-grey background,
same soft light, same scale and framing (the building the same height in every view, centred with margin), the same
camera height and angle style as those sets. Meshy research (assets/MESHY_LOG.md top): views must agree; no harsh
shadows.

The 4 views must describe ONE building: every window, door, colour, stripe, flap, drip and hole in the same place,
seen from its side. Fly-through holes (porthole, tape roll) go straight through, so they show on the back too, and
the top view shows the tape roll and the pencil-case bridge's road gap. Invent nothing new the front doesn't support;
backs are plain versions of the front (windows, no second door unless obvious).

Buildings (folder `assets/models/<name>/`): porthole-book-tower, pencil-case-bridge, tissue-box-tower, tape-roll-tower,
juice-carton-tower, cereal-box-tower, paint-jar-tower, egg-carton-market.

Rules: Codex image generation only: no Meshy, no Blender, no uploads, no Studio, no git commits, never read `.env`.
Write only the 24 files named above. NO text, numbers, logos or symbols. Look at each set of four side by side and
redo any view that disagrees with the front (max 3 tries per view). Report each building with one line on it.
