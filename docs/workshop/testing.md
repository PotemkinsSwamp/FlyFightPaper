# Testing

Two kinds of checks, and passing one says nothing about the other.

## Rule tests (automatic)
Rules logic (damage, economy, rewards, build legality, saving) has unit tests in `tests/`. Rojo syncs them to
`ServerStorage.FlyFightPaperTests`. To run: start Play in Studio, then on the server run

```luau
require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()
```

Run in Play, not Edit (Edit can reuse stale cached modules and report false failures). Last count: 558 passing, 40 suites (2026-11-12).

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
- **The Studio account** owns everything at level 34 with 100,000 Paper (nothing is saved in Studio). To see what a
  new player sees (buy buttons, locked parts): in Edit, set workspace attribute `DevAccountLevel` (e.g. 12) and
  optionally `DevAccountPaper` (default 3,000), then Play (the Hangar then drops its Studio "own everything" mode too); remove them for the full account
  (`ProfileRuntime.luau`, `Hangar.luau`).
- **Timed bot matches** (bots only) measure bot changes: deaths by cause, kills, shots, hits.
  `python tools/run_bot_matches.py 1 75` is the one-minute check; `python tools/run_bot_matches.py` three full matches
  (run it in the background; almost no tokens, where the `match-runner-haiku` helper cost ~120k a run).
- Alan's playtest is the final sign-off. Nothing is called fun or balanced without him.

## Requirement reviews
Full reviews against the vision: [QA review 2026-10-07](../research/QA-2026-10-07.md). Stage 11 repeats this.

## Related
- [Studio and Rojo](studio-and-rojo.md) · [Playtests](../playtests/README.md) · [Lessons learned](lessons.md)

Back to [HOME](../HOME.md)
