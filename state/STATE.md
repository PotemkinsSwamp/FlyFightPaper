# Since Alan last checked (2026-10-24)
- **Winners' moment sound built:** match music fades at the banner, crowd and clapping build as 3rd and 2nd hop up,
  1st's landing gets the kids' "Yeah!" and the song (Parade March, Nawlins Carnival Kids or On With The Show, random
  each round, never twice in a row). Not yet heard by you in Play.
- **Touch (phones) moved before launch (your OK):** steering stick + FIRE / 2 / BOOST, phone aim help (researched,
  then tuned with a fake-pilot test: thumbs land 83-100% of a mouse's hits), touch words on every text, sliders /
  Hangar turning / Range strips take fingers, the flight screen laid out for a phone.
- Menu screens no longer get cut off at the top and bottom on wide screens (background covers, buttons fit).
- **Every screen readable on a phone (simulator):** bigger words and taps on the menus, desk strips, binder, round end;
  Customize no longer falls off the bottom; notes, tips, round end and the Hangar's Back stay clear of the Menu button
  and Roblox's own buttons; backgrounds reach past the notch. PC look kept by design (not re-screenshotted: the
  simulator is on). Finger taps checked; a Range strip tap missed by 58 points and is fixed.

# Now: UI lane: screen fit (docs/plan/SCREEN-FIT-PLAN.md, your OK): step 1 built; step 2 the top row and notes next
What works: everything in Stage 9, the tutorials, the desk quick menu, Range notes, Match Tips; on phones (simulator)
every screen and the controls. Broken: on a phone the Menu button, match strip, kill feed and the notes under them
still crowd each other (screen fit step 2 fixes it). Not yet: nothing tried on a real phone; stick feel not tuned. Track C saving needs
a private publish (your go). Place file not re-saved (Save to File, your go; code lives in src/).

Decisions to review
Screen fit: screen kinds by the short side (phone under 540 points, tablet under 900); touch buttons kept thumb-sized
  (FIRE 76-120 points); a small PC window gets tablet sizes.
Touch: FIRE / 2 / BOOST paper buttons right, stick on the left half; phone aim help cone 6 (fades from 3), out to 800
  studs, slowdown 0.65 within 8 degrees; yellow dot = lands thanks to the help; held Skip (1.5 s) skips a lesson.
Winners' moment: cheers from 3.2 s, clapping from 3rd's landing, "Yeah!" + song at 1st's landing (8.1 s), song
  fades by 26 s; each player's game picks its own random song.
Match Tips: under the match strip, 6 s on screen, 20 s apart; Flight School skips the Lift and desk tips, Combat
  School the "Folded!" tip; the vote-lap tip dropped (the vote card says it). Walls stay soft 2 s into a new round.
Desk quick menu: no level bar; Boost row teal (Speed is blue); blue pins on the red strip. Classroom chatter 0.08.
Combat School: every Pal runs (85% of your speed when far, 100% near, banks 25-50 degrees every 2.5-4 s); step 8's
  shots are fakes from the Pal's side while it's out of view (~4 s to half Health); look cards hold 5 s, action steps
  2.5 s; Pal erasers 80% speed, 10% slower per hit (floor 60%). "No thanks" to the welcome question isn't saved.
Eraser lock stays on after firing while the target stays in the circle (you may want it reset).
Esc over the Hangar: Roblox's own menu toggles on every Esc, so "Keep flying" is the way back to the Hangar.
Hangar: a card click tries a part on, Select puts it on (not gear you own: it goes straight on); Clear spot takes gear off.
Hangar Range: Range Hangar is pink; Lift and Health bars hide there; targets 40 Health, 2 per row; Noob 0.6x,
  Challenge 1x, Veteran 1.4x, Maneuvers 1x + weave (stand-ins until you tune them).
Early part unlocks: one Roblox product per part (you'd create 28); a part you own flies at ANY level.
Scrape wobble 10 degrees, roll up to 30 fading over 0.9 s; crash angle 25 (config flight.scrape_*, combat.*).
Winners' moment: 1st does a winner's move, 2nd and 3rd two different dances; winner desks 2-3-4 of the chalkboard row.
Duct props see-through to planes; veterans flee to the ducts 40% when shot at; ducts glow through 5 grilles.
Chalk eraser: any shot puffs it; a plane only counts as hidden while inside the cloud.
Stapler 17.5 damage/s (0.8 s bursts); fan 15 Lift/s, updraft 30; dive with Lift 1.25x max.
Bot eraser skill (config bots.*.eraser_*); HUD heat cells count DOWN; flight notes fade after 4 s.
Rotating lines skip warnings, zone words, errors and score pop-up words (fixed so kids learn them).
Zone 680-840 across by building density; bots on the zone 30/60/85% (rookie/regular/veteran).
Points: fold assist share rounded to 5 (10-80); outside-zone fold 40%; paper targets 50 points each, server-checked.

Waiting on Alan
- Winners' moment: watch 2-3 endings in Play (Studio's "end: parade / carnival / show" buttons in the desk hangar).
- Touch: try the stick and buttons in the Device Simulator (now on): does the stick turn too fast or slow? Buttons
  the right size? Watch for the yellow dot in the Range.
- Your call later: match bots' guns still cross at 150 studs. Backlog: a new fan sound.
0. Studio: File > Save to File (keeps the latest fixes in the place file).
1. Drawing pass outside AI check: costs money per drawing; your go before it is built.
2. Prices: draft ladder in docs/research/PRICING-RESEARCH-2026-10-18.md for your OK; then products, passes, VIP perks.
3. Touch step 6: a private publish so you can play on your phone (your go then).
