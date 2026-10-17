# The town and the play rug

## What the player sees
In the middle of the classroom floor is a giant city play rug, like the classic classroom car rug: grey roads with
dashed lines, crosswalks, grass blocks, ponds and a playground. A town made of school supplies stands on it: book
stacks, cardboard and carton towers, a glue tower, a sharpener tower, a stapler office block, a sweet shop and more.
The **bell tower** over Town Square is the centrepiece. Ruler bridges run roof to roof. Toy cars, trees, houses and
stalls fill the ground. Ten hidden kid-drawn paper targets sit on rooftops, and a chalk eraser lies in the fountain
park south of the bell tower.

## Where it stands (2026-10-16, evening)
In the game: the **new town (layout D)** — `default.project.json` now builds `city-rug-v4.rbxmx` and `city-toys-v4.rbxmx`
(`tools/town_toys.py build v4`: toys, the 45 buildings and the bell tower at the plan's spots, the monorail track
and train, and the classroom's own pieces from `toy-placements.json`). Fans moved to x +/-600, the chalk eraser to
its park. Alan's first-look notes: [playtest 2026-10-16](../playtests/2026-10-16.md) (6 of 7 fixed and seen in
Studio the same evening; the rug paves only under pieces that touch the ground; eraser park has a fountain, benches
and bushes). After any rebuild with new meshes run `tools/exact_collision.lua` in Studio, then Ctrl+S. Today's town is kept in
`D:\FlyFightPaper-snapshots\` (place files as saved 2026-10-15 and 2026-10-16, its city-toys and classroom files);
its hand placements stay in git (`assets/rug/toy-placements.json`). Earlier rulings:
[replan rulings](../decisions/2026-10-15-town-replan-rulings.md).

**New town assets:** playmat rug (280 tiles, shared carpet maps, green stitched edge); all 45 buildings + bell tower
(the south monorail station is being rebuilt with an end-to-end tunnel, not uploaded); the new toys made in Blender
from Codex reference pictures (`tools/art/toys.py`: crane, bus, bus stop, tugboat, boats, digger, dump truck, cone,
barrier, the building-site set, street lamp with a bulb spot for a real light, the monorail pillar, beam and cars);
toy plan `assets/rug/toy-spots-v4.json`. The monorail: [Monorail](../systems/monorail.md).

**Replan (2026-10-15):** 46 buildings approved and made (one of each: our 23, the bell tower, 22 new: 8 Meshy, 14
Blender by `tools/art/blocks.py`; sheets `assets/rug/replan-v3-concepts.jpg`, `assets/rug/replan-v3-blender.jpg`).
Street layout **D** chosen (`assets/rug/layout-options/option-d-manhattan-river.png`): long blocks, diagonal Broadway
through the bell tower crossing, a river with a riverside drive, monorail loop, fans in boulevard plazas, on today's
rug size (2000 x 1400). `tools/town_plan.py` plans it (`assets/rug/replan-v4-*`): all 46 placed (fussiest
first: the four biggest, then tallest first so towers ring the bell tower; each takes the street-front spot that best
fits the height curve, set back inside the block only if no front is free). All keep their full size; Broadway skips the two blocks next to the bell tower and the extra parallel streets went (Alan's idea; see the decision). Rulings: [decision](../decisions/2026-10-15-town-replan-v3.md). The rug should feel like a real car play mat: [playmat references](../../assets/references/playmat/README.md). The building site must read as a real one: [construction site references](../../assets/references/construction-site/README.md).

## Layout rules
- Buildings stand on grass blocks, never on a road; the rug's roads are the flight lanes. Lay out the rug first.
- Real town planning: a shared building line, even setbacks, every place reachable, open space with a fill plan.
  Alan OKs a preview before tiles are uploaded ([decision](../decisions/2026-10-09-town-planning-rules.md)).
- Fly-throughs at ground, mid and roof level; routes wide enough for heavy planes.
- The bell tower stays the centre ([decision](../decisions/2026-10-12-bell-tower-is-the-centre.md)).
- The vision names these landmarks: Pencil-Case Bridge, Cardboard Square, Book Towers, Window Run (Fan Alley was
  dropped). Not checked against today's town.
- Full layout brief: Stage 4b in [milestones](../plan/MILESTONES.md) and "Classroom layout" in [Art direction](../vision/ART_DIRECTION.md).

## Where it lives
| What | Where |
|---|---|
| Rug tiles and plan | `assets/rug/`, built by `tools/rug.py` into `assets/models/city-rug.rbxmx` |
| Toys and hero buildings | `assets/rug/toy-placements.json`, built by `tools/town_toys.py` into `assets/models/city-toys.rbxmx` |
| Bridges, bell tower, ceiling pieces | `tools/city_links.py` |
| Paper target spots | `config/gameplay.json` `world.paper_targets` |
| The replan's layout and plan picture | `tools/town_plan.py` |
| Which models are used | [Model catalog](../art/models.md) |

## Related
- [The classroom](classroom.md) · [Art pipeline](../art/pipeline.md) · [Building kit](../art/building-kit.md)
- [Modes and scoring](../systems/modes-and-scoring.md) (zone spots, paper targets) · [Escapes](../systems/escapes.md)
- [Keep the big room](../decisions/2026-10-07-keep-big-room.md)

Back to [HOME](../HOME.md)
