# Hangar plan: cubby shelf + Customize binder

**Status:** built; Alan OK'd it in Play 2026-10-21
**Looks:** `assets/references/ui-concepts/hangar-shelf-screen.png` (first screen) and `hangar-customize-b.png`
(Customize), picked by Alan ([decision](../decisions/2026-10-20-hangar-build-shelf.md)).

## What the player sees

### Screen 1: the shelf (opens first)
- Cork board. **Back** (red strip) top left.
- The **big taped photo** of the picked build: the real 3D plane, turning slowly, drag to turn it (as now).
- Under it, the **masking-tape name label** with a pencil. Click it to type a new name (up to 20 letters).
- Right: the **stat sheet** (Health, Speed, Climb, Swerve, Lift and the weight row, the same bars as today), and under
  it the big orange **Customize** button.
- Bottom: the **cubby shelf**. Tabs on top: **My builds** (outside the Range) or **Range** (in the Range: only the Range builds), **Special** (hidden until
  special planes exist). Each cubby holds that build as its real 3D plane, standing still, with its name on tape
  underneath. The picked one has the yellow crayon outline.
- **Tap a cubby = pick that build.** It becomes the build you fly next (in the Range it swaps your plane at once). The
  photo, name and stats change to it.
- The arrow at the shelf's end only shows when a group has more than five builds (none do yet).

### Screen 2: Customize (the binder)
- Opens on the picked build. Cork board, **Back** top left, "Customize" title label on top.
- **Left page:** the plane photo (3D, drag to turn) with its name label. On the Gear page it becomes the mount diagram
  (numbered mount tags, as today), with the "Mount 2: medium, left click" line and **Clear spot** under it.
- **Index tabs** down the binder's edge: **Body, Nose, Wings, Tail, Gear, Boost**. Gear = the weapons (Alan
  2026-10-20). The tab list is a list in the code, so Skins, Trails and part skins later are one line each plus their
  page; a tab for something that doesn't exist yet isn't shown.
- **Right page:** the cards for the picked tab, 2 across and 3 down (no tab has more than 6 parts today). Gear cards
  keep their hit pips, damage, weight and the crayon X with the reason. Locked parts show their price; clicking one
  shows Buy / Cancel and the stat bars with it, as now. Problems ("Too much weight for this body...") show at the
  bottom of the page in red.
- Right of the binder: the stat sheet and the green **Save** button. At your desk in a match: **Save** and
  **Save & fly – 120 Paper**. In the Range: **Save** and **Test in Range**.
- **Back with unsaved changes** shows "You have changes you haven't saved. Click Back again to drop them." (the same
  rule as switching builds today).
- If a page ever needs more than 6 cards, it flips to a second page (Alan: "flip through the book"). Not built until
  needed.

## Art (new pieces)
Codex draws them in the concepts' style; I cut them out and fill gaps; Alan sees them **put together on a real Hangar
capture and close up**, then he uploads them:
1. Cork board background.
2. One cubby: the back wall, and the front frame with a see-through opening (repeated for each cubby, so a longer
   shelf is just more copies), plus the two shelf ends.
3. The yellow crayon outline for the picked cubby.
4. The open binder (both pages and rings), with nothing on the pages.
5. One index tab (tinted per colour in the game) and the orange Customize button.
Reused: masking-tape label (`tapeLabel`), red Back strip, stat sheet and bars, part cards, green button, group tabs from
the Range strips if they match.

## Code
- A new BuildShelf module: the cubby row. One still 3D view per cubby, redrawn only when that build changes,
  so the shelf costs no more than five pictures.
- `src/client/Hangar.luau`: becomes the shelf screen; the binder goes into a new HangarCustomize module,
  moving today's part, gear and buy code across rather than copying it.
- No server or saving changes: picking, renaming, saving and buying use what exists.
- Code can start with today's pieces standing in while the art waits for upload; the ids swap in after.

## Checks
- Unit tests stay green (no rules change).
- Alan's Play check with a what-to-look-at list: main menu, desk in a match, the Range; phone-sized window.

## Alan's answers (2026-10-20)
1. In the Range the shelf shows **only the Range builds**: they are a separate set, so they stay apart (same look).
2. The in-game desk menu does **not** get the cubbies: it is a quick menu and needs its own, smaller matching concept,
   made after the Hangar is done.

Back to [HOME](../HOME.md)
