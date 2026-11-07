# The four new weapons; every shot falls past its range

**Decided:** 2026-11-07 (Alan)  
**Status:** falling shots and the bonus built; the four weapons not built yet ([classes plan](../plan/CLASSES-PLAN.md) step 3)

## Decision
- **No hidden abilities.** What a weapon does must read from the real object: its size, weight and what it would
  really do. No marks, damage boosts or rules players have to be told. A scatter weapon must not remove material.
- **Every shot falls past its range.** It flies almost straight to its range, then slows hard and arcs down until it
  hits something or the floor. A falling shot keeps its usual damage. The Eraser stops seeking when its time runs out
  and falls the same way.
- **Fold at a distance:** a fold made by a falling shot pays +50 points on top of the fold. Not called "long shot".
- **Damage over distance:** the Paperclip is the only weapon that gets stronger; the Thumbtack gets weaker; the Point
  Popper's spread does the work by itself; the rest stay flat.
- **The four weapons** (first numbers; "most" = how many fit on a fast / standard / Gunship plane):

| Weapon | Class, capacity | How it plays | Range before falling |
|---|---|---|---|
| **Point Popper** (a pencil-lead tube) | medium, 3 | One shot a second: 7 leads of 5 damage. The leads fly in a tight bundle for 20 studs (all 7 hit there), then spray out in a circle like a shotgun (Alan changed this from a flat fan): past 20 studs only about one lead per gun can hit. Most 1 / 2 / 3 | 100 studs |
| **Thumbtack** | medium, 2, mass 2.0 | 6 damage, 3 shots a second; half damage at 300 studs, a quarter at 500. Most 1 / 2 / 4 | 500 |
| **Stubby Crayon** | medium, 3 | 40 damage, 2 s reload, a slow heavy shot (about 850 studs/s), hard to hit unless close. Most 1 / 2 / 3 | 600 |
| **Spitball** | light, 2 | 1 damage, 2 shots a second, slow. Up to 5 stick and show on the plane; each burns Lift faster and slows it (a full load about 2.5x Lift burn, 20% slower). None fall off for 6 s after the last hit, then one every 3 s; a fan blows them all off; the desk clears them. Most 2 / 3 / 5 | 350 |

- **Models:** for testing, the new weapons borrow models we already have. For the real ones Alan has no Meshy any more:
  a Codex reference picture, then Codex builds it in Blender. If that can't get it right, Alan finds another modeler.
- Later: look again at every weapon's range for balance.

## Why
- Alan: abilities players have to figure out don't belong; the object should explain itself. 42 damage a second up
  close was far too strong for an early gun, and +15% damage from a mark was "insane".
- A shot that just vanishes at its range looks wrong; a falling arc is what a thrown or shot object does, and a hit from
  past the range is skill (or luck) worth a bonus.
- A round shotgun cone would miss a thin plane above and below even very close, so the leads stay together first.
  Past that, a round spray (not a flat line) means one gun lands about one lead: getting close is the whole point.

## Affects
- [Weapons](../systems/weapons.md), [Economy and shop](../systems/economy-and-shop.md)
- [Classes plan](../plan/CLASSES-PLAN.md) (the weapon ladder)
- Replaces the weapon names in [Six classes, four new weapons and mastery](2026-11-06-classes-and-mastery.md)
  (Hole Punch became the Point Popper; the Spitball weighs planes down by sticking, not by a timer)
