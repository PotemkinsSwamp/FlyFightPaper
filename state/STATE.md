# Since Alan last checked (2026-10-22)
- **Tutorials approved** (your words: "conclude the tutorials as done"): Flight School, Combat School, Hangar Tour,
  Training board, Hangar try-on/Select. 28 of your notes fixed over two days (docs/playtests/2026-10-21-hangar-tour.md).
- Fixed for every flight: the nose dot now settles on the aim circle (the camera sits above the plane).

# Now: UI lane — next is the desk quick menu (your pick), then the Range's first-visit sticky notes
What works: everything in Stage 9 plus the tutorials. Then Match Tips and the Range build swap (fly off / slide in).

Broken or not yet checked: Visual looks of deaths/glints/split planes still wait on Alan's eyes. Bot-vs-bot rams never land.
During the vote lap the top strip still shows the old round's mode and clock. The desk's quick menu still has the
old 1-5 squares (next). Track C saving needs a private publish (Alan's go). A lesson started while the tour's Hangar
is open (Studio's DevLesson only) waits behind it. Place file not re-saved (needs Ctrl+S; code lives in src/).

Decisions to review
Combat School: every Pal runs (85% of your speed when far, 100% near, banks 25-50 degrees every 2.5-4 s); step 8's
  shots are fakes from the Pal's side while it's out of view (~4 s to half Health); look cards hold 5 s, action steps
  2.5 s; Pal erasers 80% speed, 10% slower per hit (floor 60%). "No thanks" to the welcome question isn't saved.
Eraser lock stays on after firing while the target stays in the circle (Claude's recommendation; you may want it reset).
Esc over the Hangar: Roblox's own menu toggles on every Esc, so "Keep flying" is the way back to the Hangar.
Hangar: a card click tries a part on, Select puts it on (not gear you own: it goes straight on); Clear spot takes gear off.
Hangar Tour: red X page only when a card has one (rare: the Hangar swaps gear to fit); look steps block all but Got it; no glow
  on the targets; end card has no buttons (click or Space closes it, or it goes after 7 s); Skip keeps you in the Range.
Hangar Range: Range Hangar is pink; Lift and Health bars hide there; targets 40 Health, 2 per row; hit box is the whole picture; Noob 0.6x, Challenge 1x, Veteran 1.4x, Maneuvers 1x + weave (stand-ins until you tune them).
Early part unlocks: one Roblox product per part (you'd create 28), and a part you own flies at ANY level (otherwise
  buying early is useless). Buying a part with Paper still needs the level.
Scrape wobble: nose and aim knocked 10 degrees off the wall, roll swing up to 30 degrees fading over 0.9 s
  (config flight.scrape_*); crash angle 25 (combat.collision_crash_angle_deg).
Results card "Crashes" counts every time a pilot went down (shot or crashed), from the round's deaths.
Winners' moment: 1st does a winner's move (Godlike, Celebrate, Jumping Cheer, Greatest), 2nd and 3rd two different
dances; desks 50 studs apart in the shot.
Winner desks: the chalkboard row has six desks, so "middle three" = desks 2-3-4, 1st in the middle (config rounds.winner_desks).
Duct props: cobwebs, spiders, toys and tools are see-through to planes (fly through them). Veterans flee to the
  ducts 40% of the time when shot at (vent within 500), wander in 12% of patrol turns; others never (config bots.*.duct_*).
Duct light: read "lights from below, connected to the lights above" as: ducts glow only through grilles where they
  pass over the classroom's ceiling lights (5 spots). Bots will skip duct links with fans and the pipe.
Chalk eraser: any shot puffs it (bots too, often by accident); cloud sits a little above the eraser; a plane only
  counts as hidden while inside it (not behind it). Lock-on in the cloud not seen live (no bot tried); same check as bots.
Stapler: kept its damage per second (17.5): 0.8 s bursts, each staple 4.67 damage. Bot "shot at" distance 10 studs.
Fan: 15 Lift/s, updraft 30. Dive with Lift: 1.25x max. Cardboard body: wings and guns scaled to fit.
Bot eraser skill (config bots.*.eraser_*): notice lock 15/30/45%, break 35/55/75%, late 0.4-0.9/0.2-0.5/0.05-0.3 s.
HUD heat cells count DOWN (full = cool). Flight notes fade after 4 s. Warning words INCOMING!/BREAK NOW!/LOCKED ON!.
Rotating lines skip warnings (INCOMING!, LOCKED ON!), zone words, error messages and the score pop-up words (FOLD,
  FINAL TEAR): those stay fixed so kids learn them at a glance.
Zone: 680-840 across, 200-130 tall by building density (ceiling 950 across, 340-620 up); open zone is yellow.
Bots and the zone (config bots.profiles.*.objective_*): share of time on the zone 30/60/85% (rookie/regular/veteran),
  "objective" personality +25%, "aggressive" -15%; only veterans head to the next zone early. Read "noobs should be
  as good" as "noobs should NOT be as good" at the objective.
Points: fold assist share rounded to 5, min 10 max 80; outside-zone fold = 40% (assist min 5); zone qualifying
  events stay 1 per 10 s; a pilot with no position sample counts as outside the zone.
Paper targets: 14.4 x 16.8 studs, 50 points each (500 max), server-checked instead of client-reported (cheat-proof).


Waiting on Alan
- The desk quick menu: a concept picture comes first for your OK.
- Your call later: give the match bots the gun fix too (their guns still cross at 150 studs, so they miss past it).
- Backlog (yours): a new fan sound for the real game. Private publish (your go) to test the move into the tutorial room.
0. Studio: File > Save to File (keeps the duct fan fix in the place file).
1. Drawing pass outside AI check: costs money per drawing; your go before it is built.
2. Prices: draft ladder in docs/research/PRICING-RESEARCH-2026-10-18.md for your OK; then products, passes, VIP perks.
