# Testing

Two kinds of checks, and passing one says nothing about the other.

## Rule tests (automatic)
Rules logic (damage, economy, rewards, build legality, saving) has unit tests in `tests/`. Rojo syncs them to
`ServerStorage.FlyFightPaperTests`. To run: start Play in Studio, then on the server run

```luau
require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()
```

Run in Play, not Edit (Edit can reuse stale cached modules and report false failures). Last count: 296 passing (2026-10-16).

| Folder | What it covers |
|---|---|
| `tests/unit/` | 22 test files plus the runner: routes, boosts, bot builds and roster, builder, catalog, combat rules, shop, economy, flight rules and service, hangar, match, matchmaking, assets, saving, rewards, rounds, desk service, ballistics |
| `tests/integration/` | Saving round-trip (ProfilePersistence) |
| `tests/fixtures/` | Fake clock, fake save store with forced failures, assertion helper |

## Playing it (by eye)
Flight feel, combat, visuals and frame rate are checked by playing in Studio:
- Every change to feel or visuals is checked in real Play at 1280x720 or larger, with screenshots.
- **8 fixed viewpoints** (F8 photo mode in `src/client/DevTools.luau`): spawn desk, city overview, low avenue,
  through a fly-through hole, window side, chalkboard wall, chase cam in a dogfight, hangar. The latest set is in the
  git-ignored `captures/` folder. Compare against the reference picture and the previous set.
- F9 shows the performance overlay; see [Performance](../systems/performance.md).
- **Timed bot matches** (bots only) measure bot changes: deaths by cause, kills, shots, hits. The
  `match-runner-haiku` helper runs these.
- Alan's playtest is the final sign-off. Nothing is called fun or balanced without him.

## Requirement reviews
Full reviews against the vision: [QA review 2026-10-07](../research/QA-2026-10-07.md). Stage 11 repeats this.

## Related
- [Studio and Rojo](studio-and-rojo.md) · [Playtests](../playtests/README.md) · [Lessons learned](lessons.md)

Back to [HOME](../HOME.md)
