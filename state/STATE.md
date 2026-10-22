# Since Alan last checked (2026-10-21)
- **New Hangar built and OK'd** (you played it: "looks good"): a cubby shelf of your builds (each its real 3D plane),
  big photo, tape name with a pencil, reference-style stats; Customize is a binder with index tabs (Body, Nose, Wings,
  Tail, Gear, Boost) and a page turn. The Range's Hangar is pink ("Range Customize") and shows only Range builds.
- **Range targets are the cards themselves** (no plane behind); shots follow the green dot, so the long row hits too.
- **In the Range a click on an open menu is no longer a shot** (it used to close Customize).

# Now: Hangar Tour (lesson 3) — built 2026-10-21, waiting on Alan's Play check
Plan: docs/plan/TUTORIAL-PLAN.md, Lesson 3 (14 steps in the Range with the Range builds, your answers in it).
What works: everything in Stage 9 (flight, 6 weapons, bots, menus, city, power-ups, hangar, HUD, zone).

Broken or not yet checked: Visual looks of deaths/glints/split planes still wait on Alan's eyes. Bot-vs-bot rams never land.
During the vote lap the top strip still shows the old round's mode and clock. The desk's quick menu still has the
old 1-5 squares (gets its own condensed concept later). Track C saving needs a private publish (Alan's go).
Place file not re-saved (needs Ctrl+S; code lives in src/).

Decisions to review
Combat School: the hunting Pal (step 8) flies 25% faster until you're at half Health (else a player flying away is
  never caught); look cards hold 5 s, action steps 2.5 s; Pal erasers 80% speed, 10% slower per hit (floor 60%).
  "No thanks" to the welcome question isn't saved.
Hangar: a card click tries a part on, Select puts it on; clicking gear already on a spot no longer takes it off (Clear spot does).
Hangar Tour: the red X page shows only when a card has one (the Hangar swaps gear to fit, so it's rare); look steps block all clicks but Got it; light off 1.5 s after a wing/gear change so you see it; no glow
  on the targets; end card has no buttons (mouse aims in the Range), goes after 7 s; Skip keeps you in the Range.
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
- Hangar Tour: play it from Training > Hangar Tour (your go for Play); what to look at is in the chat.
- Your call later: give the match bots the gun fix too (their guns still cross at 150 studs, so they miss past it).
  Match aim measured: misses come from bots turning mid-flight; a faster pencil or less jinky bots is your balance call.
- Backlog (yours): a new fan sound for the real game. Private publish (your go) to test the move into the tutorial room.
0. Studio: File > Save to File (keeps the duct fan fix in the place file).
1. Drawing pass outside AI check: costs money per drawing; your go before it is built.
2. Prices: draft ladder in docs/research/PRICING-RESEARCH-2026-10-18.md for your OK; then products, passes, VIP perks.
