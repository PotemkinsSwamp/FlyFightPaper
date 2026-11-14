# Speed work waits until the game's content is done

**Decided:** 2026-11-13 (Alan)  
**Status:** in force

## Decision
None of the ideas from the [optimization research](../research/OPTIMIZATION-RESEARCH-2026-11-13.md) get built
during beta. Optimization starts once everything is in and nothing new is being added, as the step before leaving
beta. Bringing back the full-size bump and shine maps (idea 5) also waits until then.

## Why
Every new piece of art or feature changes the numbers; optimizing now would mean doing it again and again.

## Affects
- [Performance](../systems/performance.md)
- The `roblox-optimization` skill (`.claude/skills/roblox-optimization/`): still used to avoid building new things
  the slow way, but not for clean-up work until then.

All decisions: [decisions](README.md)
