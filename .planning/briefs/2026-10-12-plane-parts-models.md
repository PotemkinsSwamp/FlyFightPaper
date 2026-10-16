# Codex Blender job: the other 20 plane parts + 3 boosters (2026-10-12)

Plane A (Classic Fold body, Classic Nose, Classic Wings, Classic Tail) is modelled, approved and in the game. Build
every other part the same way, so any body, nose, wings and tail can be mixed and still join cleanly.

## Read first
- `assets/models/planes/classic/README.md`, `classic/parts.json`, `tools/art/planes.py` (how plane A is built,
  measured, validated, exported; the FBX contract; the assembled frame: X right, Y up, -Z forward, studs).
- Concept pictures in `assets/models/planes/concepts/parts/`: `bodies.png`, `noses.png`, `wings.png`, `tails.png`,
  `boosters.png`, `mixes.png` and that folder's README.md (names and layout of each sheet). Alan approved these looks.
- Catalog ids and names: `config/catalog.json` ("body_*", "nose_*", "wings_*", "tail_*", utilities "boost_*").

## What to build (23 parts)
| Catalog ids | Sheet | Notes |
|---|---|---|
| body_slim, body_heavy, body_standard_mk2, body_slim_mk2, body_heavy_mk2 | bodies.png | slim = about half the starter width and a bit longer; heavy = about twice the width, 1.5x the height, corrugated cardboard with taped corners; Binder Gunship (body_heavy_mk2) has three metal rings and a red spine |
| nose_1 .. nose_5 | noses.png | Needle, Blunt, Long Point, Compact, Tape |
| wings_1 .. wings_5 | wings.png | Swept, Broad, Delta, Cardstock, Feather Folds |
| tail_1 .. tail_5 | tails.png | Split, Ridge, Wide, Guide Fin, Tape |
| boost_band, boost_spool, boost_twin | boosters.png | strap under the back of the body |

## Joins (the hard rule)
- Use plane A's join points exactly: every nose's rear face and every body's front face meet at plane A's
  body/nose seam (z = -2.606416) with the same socket cross-section as plane A's body front; every tail's front meets
  every body's rear at plane A's seam; every wings piece's centre saddle sits on plane A's wing seat height. A body
  can be wider or narrower outside the socket, but the socket itself is shared, so any nose/tail fits any body.
- Slot pivots: reuse plane A's `slot_pivot` per slot (body, nose, wings, tail) so the game's assembly code needs
  no changes. Boosters: pivot at the underside of the body's rear third; write it in the manifest.
- Weapon mounts: plane A's mount points stay valid on every body (heavy bodies may widen around them; no part may
  cover a mount's tube centre or muzzle in parts.json `mounts`).

## Look
- Same toy set as plane A: plain colour regions (cream paper, red accent, cardboard brown, tape beige, metal grey),
  folded-paper facets, low poly (each part under 400 triangles, all regions together), no textures needed beyond
  plain colours (like plane A). Accent regions are team-coloured at runtime: mark them region "accent" as plane A does.
- Match each concept picture's silhouette; when the picture and the join rule disagree, the join rule wins.

## Output
- Extend `tools/art/planes.py` (or add `tools/art/plane_set.py` that imports its helpers; do not copy-paste it)
  so one command rebuilds everything. New files go in `assets/models/planes/set/`: one FBX per part per colour
  region, named `<catalog id>-<region>.fbx` (e.g. `nose_1-paper.fbx`), and `set/parts.json` with the SAME schema
  as `classic/parts.json` exports (file, object, part = catalog id, region, size, triangles, suggested colour,
  team_color_at_runtime, slot_pivot, center_offset_from_slot, fbx bboxes) plus booster pivots.
- Validation like plane A (FBX re-import round trip, sizes, no self-intersections), written to `set/validation.json`.
- Review renders in `set/renders/`: one three-quarter render per part, plus `set/mixes.png` showing 4 assembled
  mixes (e.g. heavy body + broad wings + wide tail; slim body + needle nose + swept wings + split tail; and two more)
  next to the matching `concepts/parts/mixes.png` panel, and `set/joins.png` with close-ups of nose/body and
  body/tail seams for a slim and a heavy body (no gaps, no overlaps poking out).
- `set/README.md`: the rebuild command, per-part sizes and triangle counts, any choice you made.

## Rules
Blender only (D:/Blender/blender.exe, headless). Only touch `tools/art/planes.py` (additive, plane A output must
rebuild byte-for-byte the same or be left alone), a new `tools/art/plane_set.py` if you add one, and
`assets/models/planes/set/`. Do NOT touch `assets/models/planes/classic/`, `pieces.rbxmx`, `uploads.json`,
`assets/models/toys/`, `tools/art/weapons.py`, src/, config/. No uploads, no Studio, no Meshy, no git commits,
never read .env. Look at your renders yourself before you finish; fix anything that does not match the concept or
does not join. Report: what was built, the rebuild command, triangle counts, and anything you could not do.
