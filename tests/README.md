# Studio tests

Rojo syncs these modules to ServerStorage/FlyFightPaperTests.
In a Studio Play server, run:

```luau
require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()
```

The runner discovers every remaining .spec module, reports failures, and never runs automatically in gameplay.
Rules, equipment legality, rewards and mock profile persistence are retained and checked.
Retired city/loading/runtime tests were removed with their implementations. Flight tests are replaced with the rebuilt flight rules.
Gameplay feel, camera, collisions and frame rate are checked in Studio Play.
