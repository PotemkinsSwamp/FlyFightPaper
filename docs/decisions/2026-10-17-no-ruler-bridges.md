# No ruler bridges in the new town

**Decided:** 2026-10-17 (Alan)  
**Status:** in force

## Decision
The new town (layout D) gets no roof-to-roof ruler bridges. The plan's bridge step (`tools/town_plan.py`, `bridges`
in `assets/rug/replan-v4.json`) is no longer built.

## Why
The only spot the plan found joined two roofs 37 studs apart in height and crossed the block arch's top; Alan
doesn't need them in the denser new town.

## Affects
- [Town and rug](../world/town.md)

All decisions: [decisions](README.md)
