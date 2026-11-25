# Airspace zones reach the floor

**Decided:** 2026-11-25 (Alan)  
**Status:** in force

## Decision
Every Airspace Control zone in the town reaches all the way down to the floor. The only zone that floats is the one
placed high up on purpose: the ceiling spot.

Alan: "some zones do not extend all the way to the floor and they should the only one that shouldn't is the one
purposefully placed high up on the ceiling".

As built the same day: each of the five town zones keeps its width and its top (235 to 270 studs up), and its
bottom is now the floor, so its middle height and half height are both half its top
(`config/gameplay.json` `rounds.control_zones`). Before, their bottoms hung 70 to 105 studs over the floor. The
zone's lower confetti loop drifts 20 studs over the floor, so it never dips into it (`LOW_LOOP` in
`src/client/ControlZone.luau`; Claude's number).

## Why
A pilot fighting low between the buildings, inside the circle drawn on the ground, was not in the zone.

## Affects
- [Modes and scoring](../systems/modes-and-scoring.md)
- Replaces the "shorter" half of [zones follow density](2026-10-16-zones-follow-density.md); the width rule stands.

All decisions: [decisions](README.md)
