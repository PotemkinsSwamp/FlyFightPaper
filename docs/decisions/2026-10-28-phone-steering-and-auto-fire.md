# Phone steering bar and phone auto-fire

**Decided:** 2026-10-28 (Alan)  
**Status:** in force, built 2026-10-29

## Decision
- **Steering speed bar:** the turning speed stays as it is; only the Settings slider changes so the default 1 sits in
  the middle of the bar and the low end is easy to set (a non-linear bar; the saved value keeps its 0.2-3 range).
- **Phone settings with auto-fire:** phones get their own settings. Auto-fire: FIRE (weapon 1) shoots by itself while
  the dot is red (on target), on by default, with a switch in the phone Settings. The 2 weapon (the eraser's lock-on)
  stays hold-to-use.

Built: the bar is 0.2-1.8 (Alan's phone run that night: "no reason why anybody's using 3"); auto-fire also fires on
the yellow dot (the shots land thanks to the phone's aim help), not only red.

## Why
Alan's phone run (2026-10-28): steering at 1 felt very fast and the pencil slider was too coarse to set lower (0.2-1
is under a third of the bar, about 40 points on a small phone). On a phone, steering and holding FIRE at once is hard;
auto-fire on target removes that, and the eraser keeps its deliberate lock-on.

## Where it lives
[Menus and HUD](../systems/menus-and-hud.md) (Settings), [flight](../systems/flight.md) (touch controls). Numbers:
`src/client/SettingsScreen.luau` (slider 0.2-3), `config/gameplay.json` flight.touch_*.
