# Playtest 2026-10-20: Range aim, Range builds, Hangar look

Alan played the Range several times through the night and judged two rounds of Codex concepts. What he said and what
changed. Decisions: [Range controls](../decisions/2026-10-19-range-controls-and-menu.md),
[build shelf](../decisions/2026-10-20-hangar-build-shelf.md). Systems: [tutorial](../systems/tutorial.md),
[menus and HUD](../systems/menus-and-hud.md).

## Aim
- Crosshair dead on the circle rarely hit (pencil, Veteran, long). **Done:** the guess from speed and turn can't follow
  the swoops (0% simulated); targets now give their exact path.
- Then: shots near the circle hit, climbing targets missed. **Done:** no aim help in the Range; hits judged on the path.
- Still missing: "make the target the entity". **Done instead:** screen and server read the path at the same moment
  (the real cause); the whole picture is the hit area.
- His idea: shoot at the circle along known paths and count hits. **Done:** `tests/unit/RangeAccuracy.spec.luau`,
  3,709/3,709 after fixing a cast that skipped a card stepping onto a shot. Alan: "the targeting is now good."

## Range and menus
- Range Menu / Hangar strips hid long lead circles: **Done:** top left, level with the score card.
- Range Menu sat behind the game's Menu button and couldn't be clicked: **Done:** Menu button in Roblox's top bar;
  crosshair can click it (Alan confirmed).
- "Tutorial" button holds three lessons and the Range: **Done:** now "Training".

## Hangar
- Name box invisible, then "looks really bad"; 1-5 squares not centred and can't show names or future special planes.
  **Next:** cubby shelf + separate Customize screen, concepts for both first (decision note).
- Test in Range for everyone (the dev button only in Studio): **Done.**
