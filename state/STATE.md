# Since Alan last checked (2026-10-18)
- **Tutorial (in progress):** plan agreed with you ([plan](../docs/plan/TUTORIAL-PLAN.md)): five separate lessons,
  fixed training plane, short, always replayable. Its own empty room is built (Studio: the Tutorial button clears the
  room). Flight School's steps are written; your playtest asked for much stronger attention-grabbing, approved as
  "Grabbing attention" in the plan: next session builds it, starting with a concept picture for the highlight art.
- **Real shop code built, switched off (Stage 10):** when someone pays, the game adds the item and saves it before
  telling Roblox "done", so nobody is charged without getting it and nobody gets it twice. Permanent 2x passes are
  checked with Roblox on join. Also: early part unlocks (one Roblox product per part, 28 parts). Nothing can be bought
  until you OK prices and we put the real product numbers in. Tests 388/0
  ([how it works](../docs/systems/economy-and-shop.md)).
- Earlier today: paper look on every plane part (approved); prestige built and parked; shop planned with you
  ([shop plan](../docs/decisions/2026-10-18-shop-plan.md)); wall scrapes made fair; Stage 9 approved.

# Now: Tutorial, attention-grabbing pass on Flight School (MILESTONES); Stage 10 code done and off
What works: everything in Stage 9 (flight, 6 weapons, bots, menus, city, power-ups, hangar, HUD, zone).

Broken or not yet checked: Visual looks of deaths/glints/split planes still wait on Alan's eyes. Bot-vs-bot rams never land.
During the vote lap the top strip still shows the old round's mode and clock.
Track C saving needs a private publish (Alan's go). Toilet Roll jitter: not reproduced; tell me when it happens. Place file not re-saved (needs Ctrl+S; code lives in src/).

Decisions to review
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
- Try the tutorial after each tutorial session (you're its tester); OK the highlight concept picture; run its upload.
- Private publish (your go) to test the real move into the private tutorial room.
0. Studio: File > Save to File (keeps today's duct fan fix in the place file).
1. Drawing pass outside AI check: costs money per drawing; your go before it is built.
2. Prices: draft ladder in docs/research/PRICING-RESEARCH-2026-10-18.md for your OK. Then: create the products and
   passes on Roblox (I'll give exact steps), and decide the VIP pass's perks and whether to turn on private servers.
