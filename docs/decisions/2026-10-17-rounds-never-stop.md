# Rounds never stop: winners' moment, a safe vote lap, next round where you are

**Decided:** 2026-10-17 (Alan)  
**Status:** in force; first pass built 2026-10-17, revised after Alan tried it (below)

## Decision
When a round ends, nobody is sent to a results menu. Instead:
1. **"Pencils down!"**: the round end is announced in-game; planes glide on a safe autopilot (no crashing, no damage).
2. **Winners' moment (about 8 s):** the camera shows the desks; the top 3 (or the winning team's best 3) jump up on
   their desks and emote. The round's results show on a paper scoreboard beside them (nobody is flying, so it is
   safe to read).
3. **Vote lap (about 20 s):** everyone flies freely with no damage; walls bounce you off instead of crashing you.
   Three big paper rings appear mid-room, one per mode (later: per map), each with its picture and live vote count.
   Fly through one to vote. Backup: press 1/2/3 or click the small card at the top. The chalkboard keeps the top
   scores up during the lap.
4. **The next round starts where everyone is**, with no relaunch; planes change colour if the mode changes.
- XP, level and the next unlock show on the main menu board and in the hangar, reachable mid-match through Menu
  without leaving the game.

## Revised after Alan tried the first pass (2026-10-17)
- **The winners' moment is a cutscene**, not the live room: planes go on autopilot and the camera glides from
  wherever you are (your plane, or the hangar) into the **middle three desks of the row nearest the chalkboard**.
  In the cutscene the students at those desks are replaced by the round's top 3 (whole round in free-for-all; the
  winning team's top 3 in team modes). They stand up from their chairs, jump onto the desks and emote for about 10
  seconds while the results card shows, then the camera glides back to where you were. No loading screen, no hard
  cut: it must look like the same room. Emotes may later become things players buy.
- **Results card, more detail:** per pilot folds, assists and crashes beside points; your own Paper and XP from the
  round with your level bar filling; in team rounds names in red or blue and both team totals at the top.
- **Vote rings:** on the window wall, much larger, and not paper rings: something that stands out, and it must be
  obvious where to fly the moment the vote starts (Alan couldn't find the first-pass rings).
- **Dev panel:** a Studio button that ends the match now, to test the round end.

## Why
Alan: other games (TF2) keep you playing between rounds, and dead time makes players leave. Shooting vote targets
was dropped because it needs aim, ammo and maybe a trip to the desk; flying through a ring is the skill everyone has.
The winners' moment gives the top players a show-off moment that a non-stop game would otherwise lose.

## Affects
- [Modes and scoring](../systems/modes-and-scoring.md) · [Menus and HUD](../systems/menus-and-hud.md) ·
  replaces the results sheet and vote screen in [Stage 9](../plan/MILESTONES.md)

All decisions: [decisions](README.md)
