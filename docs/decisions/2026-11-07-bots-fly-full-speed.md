# Bots fly at full top speed

**Decided:** 2026-11-07 (Alan)
**Status:** built

## Decision
- Every bot flies at its plane's full top speed, the same as a player. The old per-skill speed cut (rookies 88%,
  regulars 93%, veterans 98%) is gone.
- Skill changes how hard a bot turns and pitches (and, later, how well it uses the brake), never its top speed.
- Like a player, a bot only flies slower when something makes it: a hard turn, the brake, spitballs, a headwind.

## Why
- Alan: "They're supposed to be using their top speed just like a player would." A plane has a top speed and everyone
  flies it unless they're speed matching or braking on purpose.

## Affects
- [Bots](../systems/bots.md)
