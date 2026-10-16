# Hangar landing and the in-game hangar menu (Alan, 2026-10-11)

Alan: "it's a paper airplane, an airplane, not a helicopter." Today a plane flies into the approach ring, is turned
around and backs onto the pad (`FlightService:land`, one 1.5 s tween to `serviceHome`). Replace it with a real landing.

## Alan's rulings (asked 2026-10-11, answers final)
1. **Rings move out and down**, lined up with the runway, just past the desk's room-side edge. The plane **must enter
   lined up with the runway**: no entering from the side (some assistance allowed: a forgiving cone, gentle auto-align).
2. **Spawn inside the hangar** (round start and after being destroyed), with the in-game hangar menu up; fly out.
3. **Side (neutral) desks get hangars and runways too**, two per desk (one per landing slot), **with no numbers**
   (they are free to use). Needs an unnumbered colour map for desk-hangar (blank crown).
4. **In-game hangar menu shows all of:** service buttons (Refill Lift, Repair, Fresh plane, Full refold 120 Paper,
   big Launch), the plane on taped paper with crayon health/lift/boost bars, the match score + timer, and swap to one
   of the 5 saved builds (counts as a refold).

## Flow to build
- Fly through the ring (inside a cone around the runway line) -> glide down onto the tape runway at the desk edge ->
  roll along the runway, over the pad, into the hangar (anchored tweens, server-side, like today) -> State DESK.
- In the hangar the menu covers the world view. On Launch the plane is already turned to face out (turned while
  hidden) and flies out of the hangar over the pad and runway.
- Current geometry (studs): desk tops y=108, rows at z=+-850 (330 x 210, room-side edge at z=+-745); pads 95 x 82 at
  the desk centre; hangars (110 wide, 50 tall, 70 deep, entrance toward the room) at z=+-919; rings today at z=+-808
  (12 `Landing*Segment` parts each in classroom.rbxmx), approach box `home + look*42 + up 31`, size 86 x 60 x 100.
  Neutral desks at x=+-1160, z=0 (230 x 200), two slots at local x=+-48. Landing timing in config/gameplay.json
  `service.landing_assist_seconds`.
- Things that read `p.home`/`serviceHome`: FlightService (spawn, launch, atDesk, queue markers), AvatarService (pilot
  avatar placement), BotService (repair goal; bots don't land yet), CombatService (`inServiceZone`).
- Client: FlightHUD shows the launch button and service row when State == DESK (lines ~207-265, ~459); the main-menu
  Hangar screen (src/client/Hangar.luau) has the build-swap logic to reuse (its kraft-folder look is NOT this menu's style; see below); MenuController sends "loadout".

## Look of the in-game hangar menu (Alan, 2026-10-11)
"Like a drawing from a child on white journal paper with crayons and coloured pencils, and the menu buttons look like
they are drawn." Make reference images first (Codex image job below) and build the menu to match them; show Alan the
references before building.

## Codex image job: in-game hangar menu references
Save to `assets/references/ui-concepts/` with these names, 16:9, at least 1536 px wide. Look at the existing
concepts there first (hangar.png, main-menu.png, results.png, settings.png) for layout and content, but this menu's
style is different: **a child's drawing on white lined journal paper** (blue ruled lines, red margin line, maybe
spiral holes or a torn edge), everything drawn in **wax crayon and coloured pencil**, wobbly hand-drawn outlines,
scribble shading. **Buttons look drawn by a kid** (crayon-outlined boxes or clouds with scribble fill and hand
lettering), not computer buttons. Text must be spelled correctly and readable.
| File | Content |
|---|---|
| desk-hangar-menu.png | Full-screen in-game hangar menu: centre: the player's paper plane drawn on the page with crayon health, lift and boost bars beside it; one row of drawn buttons "Refill Lift", "Repair", "Fresh plane", "Full refold - 120 Paper"; a big drawn "LAUNCH!" button; top corner: small score card ("Red 12 - Blue 9", "2:41 left"); a strip of 5 saved builds drawn as little plane doodles labelled "Build 1".."Build 5". |
| desk-hangar-menu-alt.png | Same content, different layout (buttons down the right side, plane larger on the left). |
| desk-hangar-buttons.png | One sheet of the button set alone on white journal paper, each in normal and pressed look (pressed = darker scribble), plus a crayon bar in empty/half/full: for slicing into UI pieces. |
Rules: Codex image generation only (not Meshy); look at every image yourself and redo garbled text (max 3 tries);
only write the three files above; no uploads, no Studio, no git commits, never read .env.

## Layout ruling (Alan, 2026-10-11): **layout B** = `assets/references/ui-concepts/desk-hangar-menu-alt.png`
Big plane on taped paper on the left with Health/Lift/Boost crayon bars under it; score card top right; Refill Lift,
Repair, Fresh plane, Full refold stacked down the right; big LAUNCH! bottom right; 5 build doodles along the bottom.
Button looks (normal/pressed) and bars: `desk-hangar-buttons.png`.
**The drawn plane in the reference is a placeholder (Alan, 2026-10-11): show the player's ACTUAL plane model** (their
real build, live 3D in a ViewportFrame like the main-menu Hangar does, see src/client/Hangar.luau), sitting on the
taped paper sheet. The 5 build slots also show each saved build's real model, not doodles.
