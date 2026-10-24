# Screen fit plan: every piece in its place on any screen

Approved by Alan 2026-10-24 ([decision](../decisions/2026-10-24-screen-fit.md)). Follows the [touch plan](TOUCH-PLAN.md) step 4 (phone sizes) after Alan saw
the Menu button, the match strip and the kill feed pile up on a phone: "every UI element ... needs to follow this
minimum maximum size and where it belongs, so it always looks the way we want it to on any screen."

## What the player sees
On a small phone, a big phone, an iPad, a PC and a wide monitor:
- Every piece has its own spot. Nothing overlaps, nothing sits under Roblox's own buttons or a phone's notch, nothing
  runs off the edge.
- Words read (about 14 points or more on a phone, since our Kalam letters draw small) and every button is at least
  thumb-sized (about 44 points) on a touch screen.
- Pieces grow with the screen but stop at a maximum, so a big monitor doesn't get giant strips.
- The look stays the same paper-and-crayon look everywhere; pictures stay sharp (they are uploaded bigger than they
  ever show).

## How it works
1. **One size rule for everything** (one shared module): a piece's size = its drawn size x the screen's scale, kept
   between a minimum and a maximum. Three screen kinds pick the numbers: phone (under 540 points tall), tablet, PC.
   Today each screen has its own scale code (six copies); they all move to this one.
2. **A screen map** for everything drawn over the game. The screen is split into areas, and each piece belongs to
   one area, lined up in a row or column with its neighbours (Roblox's "flex" rows), so pieces push each other along
   instead of overlapping:
   - top row, in Roblox's top bar right of its own buttons: Menu, then the match strip;
   - top right: kill feed (fewer, shorter lines on a phone);
   - top left: Health, Lift and Boost;
   - top middle, under the top row: news, warnings, lock info, lesson notes, tips;
   - middle: crosshair, hit marker, lock ring, edge arrows;
   - bottom left: the stick; bottom right: FIRE, 2, BOOST (phones), weapons panel (PC);
   - at the desk: builds down the left, service strips down the right, note and LAUNCH bottom middle.
3. **Full-screen menus** (main menu, Settings, Hangar, binder, pause, round results, Training board) stay drawn
   sheets, since their pieces are a composed picture, but every word and button on them follows the same minimums.
4. **An automatic check** I run in Play on each screen: it lists any two pieces that overlap, anything off screen or
   under Roblox's buttons or the notch, words too small and buttons too small. Plus a screenshot of each screen on
   each device, for you.

## Build order after Alan's OK
1. The size-rule module and the automatic check (run it first to list today's problems).
2. Flying screen and touch controls (seen most).
3. Desk quick menu.
4. Over-the-game notes: lesson notes and cards, match tips, Range notes and Range menu, round-end banner and vote,
   winners' name plates, score pop-ups.
5. Full-screen menus: minimums on every word and button, checked on a tablet too.
6. Screenshots of every screen on every device for Alan.
Each step: the check passes on every device, screenshots compared, committed.

## Checks
Devices (Studio's Device Simulator): small phone (iPhone SE), big phone (iPhone Pro Max), an Android phone, iPad,
PC 1920 x 1080, a small PC window (1280 x 720), a wide monitor. Switching the simulator's device is a click in Studio:
Alan switches it, or gives Claude the go to click it. Done when the check is clean on every device and Alan's real
phone matches (touch plan step 6).

## Alan's answers (2026-10-24)
Plan OK; small PC moves OK with before/after pictures; 2 kill-feed lines on a phone; Alan switches simulator devices.

## Progress
- 2026-10-24: plan approved. Step 1 built: `ScreenFit` (screen kind by the short side: phone under 540, tablet under
  900; scale = min(width/1920, height/1080) kept between a least per kind and a most) now drives the flying screen,
  the desk strips, lesson notes, tips, Range notes, score words and the phone sizes; touch buttons keep thumb sizes
  (FIRE 76-120 points, 2/BOOST 52-84, stick radius 44-80). `ScreenCheck` lists overlaps, pieces under Roblox's
  buttons or off screen, small words and small taps. Not yet run on a drawn screen (Studio stopped drawing).
  **Next:** run the check on each screen; step 2: the top row (Menu then the match strip, placed from the top bar's
  real free room), notes under it stacked from each other's real edges (news, lock, threat, lesson note, tip), kill
  feed 2 slips on a phone.
- 2026-10-24 (later): first check runs on the big phone (831 x 439): Menu and match strip already apart; the kill feed
  ran under the desk's strips, the desk photo sat under Roblox's buttons, news / lesson note / tip all aimed at one
  spot, edge arrows crossed Health and Lift, Menu tap 42 points. **Step 2 built:** the top row and the column (see
  [menus and HUD](../systems/menus-and-hud.md)), feed 2 slips on a phone, desk strips under the feed, Menu 46 tall,
  the check skips markers that follow the 3D world. Check clean on the big phone: main menu (bar the welcome
  question's taps), desk, flying with news + LOCKED ON, round end banner. **Still listed for step 4:** lesson note
  words 12-13 points and Skip 24 tall; match tip words; welcome question's taps 30 tall; results card covers the
  desk's right strips (PC too); results header words run together on a phone; main menu Prestige and Shop (dev)
  taps 28-33 tall. **Next:** Alan switches devices (small phone, iPad, PC 1920 x 1080) and the check runs on each.

## Cost
Code only: no uploads, $0. About two to three sessions.
