# Town replan v3 approved: two fans, a monorail train that kills

**Decided:** 2026-10-15 (Alan, after the v3 plan picture and building list)
**Status:** in force

## Decision
- The v3 plan is a go (`assets/rug/replan-v3-preview.png`, list and cost in `assets/rug/replan-v3.md`): 46 buildings,
  one of each, 22 new (10 Meshy, 12 Blender), gates over streets, open fly-through approaches, 8 ruler bridges, the
  monorail loop.
- **Only two fans:** Market Square and Fan Plaza.
- **The monorail train is solid:** flying into it, or being hit by it, kills you.
- Alan sees the concept pictures before any Meshy credits are spent.
- **Kid-built, not blown up** (Alan, on the first concepts): a building is something children built out of many
  classroom objects at their real size (books, boxes, cartons, pencils, rulers, tape, cups, craft sticks, toy
  bricks), never one small object (a glue stick, a pencil) made giant. Scale: a desk top is 330 studs, so 1 stud is
  about 4 mm: a pencil about 48 studs long, a book about 70 x 50 x 8, a shoebox about 85 x 50 x 30.
- **Simple beats busy** (Alan, on the kid-built redraws): few big pieces, never dozens of little ones (too many
  triangles; Meshy melts them). Big classroom objects can stand alone as one building (a ring binder, a lunch or
  pencil tin, a paint tub). No rulers in Meshy models (the marks melt); wooden toy blocks instead.

- **Layout rejected after the rug preview** (Alan, `assets/rug/preview-v3.png`): too grid-like and square; not how
  real cities look, and it would look odd built. Redo the street layout from real urban patterns. Keep: the bell
  tower at the centre and the tallest building; both fans the same distance from the bell tower; no blank field (the
  farm goes; use the space for something with better decorations); every building reaches a parking lot by a path,
  every parking lot reaches a road by a driveway, parking lots a little bigger. The 46 buildings stay.

- **City shape for the redo:** Alan leans toward a real city that has a monorail (named New York; unsure). Next:
  research real monorail cities (Seattle's monorail above an avenue to the Space Needle, Las Vegas, Tokyo, Wuppertal)
  and New York's grid-breakers (long blocks, a diagonal Broadway with squares where it crosses, a central park,
  elevated rail), then draw 3 layout options as plan pictures for Alan to pick. Claude's lean: Seattle + New York
  around the monorail.

- **Street layout: option D chosen** (Alan, `assets/rug/layout-options/option-d-manhattan-river.png`): Manhattan-style
  long blocks with a diagonal Broadway through the bell tower square (small paved corners where it crosses avenues), a
  river curving across the south with a riverside drive and bridges, a small Central Park in the north-west. The
  monorail is a LOOP: above the river, up the two outer streets, back above an avenue, through both stations. The two
  fans sit in round plazas at the far west and east of the main boulevard (750 from the bell tower each); the
  boulevard swings south round each plaza in a U. The bell tower stands over the central crossing on four legs, roads
  running under it, as today.
- **Fitting all 46 on layout D** (Alan's idea 2026-10-15, plus Claude's follow-ons for his review): dropped the extra
  streets that made double parallel roads (south street next to the ring road; the x = +-800 streets next to the
  east/west ring road; the monorail now runs up the ring road there); riverside drive moved onto the riverbank (it
  left a thin strip); setback 14 -> 6, gap between buildings 30 -> 22 (later 20). Three of today's small buildings shrink to
  80-85% (the plan's list says which) (the only room left is desk landing zones, 80 tall max). Removing the boulevard's
  outer ends was tried and fitted fewer.
- **Ruler bridges never cross roads, the monorail or water** (Alan 2026-10-15): only roof to roof inside a block.
- **Roads cross the river on road bridges** (with sidewalks); Broadway runs through Central Park, the pond moved off
  it; the chalk eraser's fountain park moved to (-215, 225), clear of the riverside drive and the gateway towers.
- **Broadway skips the two blocks next to the bell tower** (Alan 2026-10-16) so no road meets a leg; the bell tower
  stays square (a 16-degree turn was tried: legs only 3 studs from the roads). Two versions for Alan to pick:
  *mirror* (a diagonal the other way in each of those blocks; the gateway towers move south of the river, since the
  new diagonal meets the middle street where they stood) and *removed* (plain blocks). The planner checks no road
  touches a leg. **Alan picked *removed*** (2026-10-16). Gap between buildings 20 (16 as a last resort before shrinking); the placer keeps the best of 8
  varied passes.
- **Rug preview round 1** (Alan 2026-10-16): no footpaths (buildings front the sidewalk; this replaces "every building
  reaches a parking lot by a path"); Central Park is only the piece north-east of Broadway (the sliver across the
  road is town again, which also let every building keep its full size); the pond sits in the park's middle with a
  natural, lumpy shape; parking lots come in mixed sizes, some wide.
- **Rug round 2** (Alan 2026-10-16): building pads are a thin concrete footprint (1.5 studs), not a wide plot; each
  fan sits on a pad just bigger than its 170-square base, lawn round it (no big round plaza); parking lots sit square
  to the street grid (no slanted strays); pond turned 90 degrees where it is; centre lines run through the bell tower
  square; crosswalks sit just clear of the crossing street on every arm; the monorail track runs above the inner
  pavement so its pylons stand there (the printed islands mid-road read as potholes).
- **Rug round 3** (Alan 2026-10-16): fan pads are round (the fans are round), just bigger than the fan (radius 92);
  the pond turn is undone. Room made for the toy sites: a fenced building site with a crane (crane at most 80 tall:
  the free ground left is desk-landing zone), a fire station forecourt with its truck, a petrol station forecourt,
  each on a street front in its own block (`sites` in replan-v4.json). Next look: a concept-image pass to give the
  rug a real playmat-rug feel without changing its layout.
- **Bell tower on a square pad** (Alan 2026-10-16): a square just bigger than the 210-square tower (6 studs round it)
  replaces the 300-across circle, so no leftover paving slivers; the rest is grass. The playmat concept
  (`assets/rug/playmat-concept.png`) is liked "for the most part"; the rug look becomes playmat-style colour tiles
  plus one shared carpet normal/roughness map and a thicker stitched edge (no 3D pile: it would cost FPS).
  Alan's go (2026-10-16): build that look next and show him before any tiles.
- **Playmat look built, waiting on Alan** (2026-10-16): `tools/rug.py --plan` now prints the concept's colours and
  line weights (lime grass, slate roads, 17-stud yellow dashes, chunky zebras, bright blue water, cream pads, a
  paved grid on the bell square) with every shape still from replan-v4.json; tiles get a fine woven grain and fuzzy
  print edges. Review pictures: `assets/rug/playmat-v4-preview.png`, `playmat-v4-closeup.png` (real tiles). The
  shared carpet normal/roughness maps were remade in Blender (`tools/art/carpet.py`; seamless, fine weave, no
  tile-wide tilt); not uploaded yet, so the old asset ids still sit in `assets/rug/carpet/*.json`.
  Edge plan (not built): green binding (69,155,38), Fabric, 16 wide, 3 tall (today: navy, 12 wide, 1.4 tall), a
  3-stud round roll along its outer side for a padded look, quarter-round corners, the uploaded stitch picture in two
  rows on top. 12 plain parts, no new textures: no FPS cost.
- **Look and edge approved** (Alan 2026-10-16, "Looks good"): next the 280 tiles, which Alan uploads.
- **Rug uploaded** (2026-10-16, Claude ran it at Alan's request): 280 tiles + both carpet maps, no errors;
  `city-rug-v4.rbxmx` built (292 parts). Not in the place yet: it goes in with the new town.
- **Toys started in parallel** (Alan 2026-10-16): Claude built the building-site crane in Blender from a Codex concept
  (`assets/models/toys/crane/`, `toys.py crane`: 79.4 tall, 5,168 triangles, all checks pass). Alan: "The crane
  looks good." Its maps' gaps are filled from its real UVs (fill_gaps.py's fill(), maps copied as crane-*.png).
- **Creator Store toy search** (2026-10-16): usable after recolour: cone 108782875528596, water barriers 10759615367,
  paper boat 9061318246, rowing boat 17782001663; bus 78307699566459 (strip 19 scripts, decals), tug 11715778152,
  digger 139183043756595 (tiny). Nothing good for the dump truck or bus stop. Claude's advice: store for the simple
  pieces, Blender for the show pieces.
- **No store toys** (Alan 2026-10-16, on seeing the picks): "none of those fit our look". Every new toy (paper boat,
  rowing boat, tugboat, bus, bus stop, digger, dump truck, traffic cone, site barriers) gets a reference picture
  (Codex) and a Blender build in `toys.py`, like the crane.
  Built 2026-10-16 (Claude): bus, bus-stop, tugboat, cone, barrier, paper-boat, rowing-boat, dump-truck, digger;
  all pass the toy checks; maps gap-filled from real UVs and looked at. Uploaded 2026-10-16.
- **The building site must look like one** (Alan 2026-10-16, with 3 reference pictures): half-built building with frame
  and scaffolding, fence and gate, material piles and stacks, site cabin, portable toilet, cement mixer, vehicles.
  First a whole-site concept picture in our toy style for Alan's OK, then each piece in Blender.
  Concept `assets/references/construction-site/toy-site-concept.png`; Alan checked it fits the 80 x 100 plot
  (scale drawing) and said yes. Built in `toys.py` 2026-10-16: site-building (half-built tower, 43 tall), site-fence
  (one panel, repeated), cement-mixer, sand-pile, gravel-pile, plank-stack, pipe-stack, brick-stack, site-cabin,
  site-toilet; each piece's concept is a crop of the site picture. Maps gap-filled and looked at. Uploaded.
- **Toy placement approved** (Alan 2026-10-16): the building-site layout (43 toys), 4 bus stops with buses, the
  tugboat and 3 paper boats on the river, 2 rowing boats on the pond (`assets/rug/transport-plan-v4.png`).
- **Building uploads in batches** (Alan 2026-10-16): blobby textures are fine; only obvious shapes (hooked crosses,
  stars, codes, hand signs, bodies) block an upload. Upload building after building (2 s between files, a short
  break between buildings), after the normal/roughness maps are looked at too.
- **Street lamps get a real light** (Alan 2026-10-16): a toy lamp with a fake bulb that can actually light up, for
  future weather or dark events. Claude's call (to review): the bulb is its own glowing piece with a light that
  stays off until a darkness event turns it on.
- **Monorail next** (Alan 2026-10-16): track, pillars and train start the next session.
- **Monorail clear of every building** (Alan 2026-10-16): the train never touches a building (only ones low enough
  pass under it); the route runs up the ring road's outer pavement and down the middle of the monorail avenue, with
  corners rounded over the junctions (radius 100); straight through both stations' track tunnels. The south station
  moves to the middle river bridge (x 0, where the river runs straight east-west) and must be rebuilt with its tunnel
  end to end. Pillars on the avenue stand on its centre line, clear of junctions and zebras (Alan OK'd). Checked by
  `tools/town_plan.py` (clearance and tunnel asserts).
- **Monorail stops at stations** (Alan 2026-10-16): the train waits about 10 seconds at each of the two stations.
- **Toys for the new town** (Alan 2026-10-16). Keep from today: the park and plaza set (benches, fountains,
  flagpoles at the bell tower square, playgrounds and a picnic spot in Central Park, ducks and the boathouse at the
  pond), the fire station with its truck and the petrol station (each on a free block corner), about 6 market stalls
  round the egg-carton market, the two footbridges (pond or riverbanks). Retire the farm, airport, sports-pitch and
  little-house toys. New: river boats (tugboat, paper boat; rowing boats on the pond), a toy crane on a small
  building site, buses with a couple of bus stops. Creator Store first, then Blender; no Meshy spend.

## Why
Kid-built: a pencil can't be a building, but a tower kids made from pencils, boxes and books can.
Two fans keep Lift contested in the middle. A train you can pass through would look wrong; dodging it is part of
flying the town.

## Affects
- [Town and rug](../world/town.md) · [Town replan rulings](2026-10-15-town-replan-rulings.md)

All decisions: [decisions](README.md)
