# Town replan: layout v2, unique buildings, fly-throughs, fans, bridges, a monorail

**Decided:** 2026-10-15 (Alan, after the v2 plan picture and a Studio prototype)
**Status:** in force

## Decision
- The v2 layout is good (`assets/rug/replan-v2-preview.png`, made by `tools/town_plan.py`): a block grid of streets,
  a tall downtown round the bell tower stepping down to the edges, an anchor building per block, six landmark blocks
  (civic square, pond park, market square, sports pitch, farm, woods and pond).
- **No reused buildings:** design more unique buildings so no building appears twice.
- **Fly-through buildings** (arches, holes, legs) must sit where you can actually fly through them: open approach on
  both sides, never boxed in by neighbours.
- **New fan layout** for the updraft fans to suit the new town.
- **Building connection points:** roofs joined by bridges where it makes sense.
- **A toy monorail** running through and around buildings: it ties the city together and gives fly-over and
  fly-under points.

## Why
The prototype showed the layout reads well, but copies of the same buildings, boxed-in fly-throughs and a town
without links between buildings would not match the reference picture's busy, connected city.

## Affects
- [Town and rug](../world/town.md) · [Denser city](2026-10-15-denser-city.md) · [Milestones, Stage 4](../plan/MILESTONES.md)
- [Art pipeline](../art/pipeline.md) (Creator Store first, then Codex Blender, Meshy last)

All decisions: [decisions](README.md)
