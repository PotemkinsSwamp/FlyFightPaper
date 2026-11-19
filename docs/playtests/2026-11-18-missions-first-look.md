# Missions first look, 2026-11-18

## What Alan asked for

The daily and weekly missions from the [missions decision](../decisions/2026-11-18-daily-and-weekly-missions.md), seen
in Play: the main-menu Missions sheet, the desk drop-down, and the report card's tick slip.

## Alan's Play notes (three rounds, same day)

- **First look:** the main-menu Missions strip sat under the pinned paper plane; the sheet used plain coded boxes and
  bars, and its notebook paper looked tilted; the desk strip sat too far below "Switch to presets" and its list touched
  the loadouts' cork. He asked for a dev button to test the tick slip.
- **Second look:** the plane must stay where it is (its fly-in lands there); instead the stats card is drawn smaller and
  Missions goes under Shop. Cards from the paper we already have, never new
  pictures. Desk: strip and list each a sliver apart, the tracing paper a little more solid. No tick slip showed (the
  server log said "Skipped mission progress: ineligible_match": the dev flag never reached the save).
- **Third look:** the column on the main menu fits after moving it 50 left. The 15-dailies card came up empty (cause:
  the blue paper drew over its week, count and reward; fixed by drawing the card under everything on it). The paper's
  torn edges look rough on the cards and on the Daily/Weekly tabs. In the desk list the space between a goal and its
  bar was too big (words, tabs and bar now bigger, the goal sits on its bar) and a scroll bar showed while it opened
  (removed). The tick slip showed on the second dev match, but it is hard to see: white slip on the white card, top
  left. The first dev match showed no slip and no Paper jar (he did nothing that match; the jar only shows when Paper
  was added). He thinks the jar should show even with nothing added.

## Studio check

- Unit tests: 746 of 746 pass (one Missions test fixed: its last match had 100 folds, which honestly finished a
  110-fold weekly; now 50).
- Open after this look: the paper edges (discussed with Alan before any change), the tick slip's look, and the jar on
  an empty match.
