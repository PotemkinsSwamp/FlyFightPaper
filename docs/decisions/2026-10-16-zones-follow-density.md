# Airspace zones follow how crowded the town is

**Decided:** 2026-10-16 (Alan)  
**Status:** in force

## Decision
Each Airspace zone spot's size follows its building density: where buildings stand close the zone is wider and
flatter, so pilots chase each other between the buildings; open spots keep a taller zone. All spots grew a little
for the denser new town. Worked out once per spot from the town plan (radius 340-420, half height 100-65, by the share
of the zone's floor under buildings, 9% to 28%), kept in `config/gameplay.json` `rounds.control_zones`. The ceiling
spot is unchanged.

In Studio the hangar's dev button "next spot" (was "ceiling") starts an Airspace round with the zone held still and
moves it to the next spot on every click, so every spot can be seen in one round.

## Why
The new town (layout D) is denser than the old one, and Alan wants the zone fights to happen in and among the
buildings, not above them.

## Affects
- [Modes and scoring](../systems/modes-and-scoring.md)

All decisions: [decisions](README.md)
