# Since Alan last checked (2026-10-18)
- **Planes look like paper (you approved it):** every part and booster now has its paper texture in the game:
  creases, paper edges, cardboard, toilet roll, tape and rubber bands, tinted red, blue, or half-and-half in
  free-for-all. Checked in Studio Play, sizes unchanged, tests 328/0
  ([decision](../docs/decisions/2026-10-18-paper-look.md)). **Duct fans** no longer poke through the ceiling.
- **Prestige built:** at level 50 a Prestige button appears on the main menu's stats card; hold to confirm. You go
  back to level 1 and lose your parts (even bought ones), keep your Paper, boosts and stats, and get a gold rank
  star on your level bar. Bots stay at your old difficulty. Checked in Studio Play; tests 340/0. You said keep the
  details for now; prestige is parked until you want to work on it.
- **Shop planned with you:** what we sell, whole-plane skins, sticker editor, drawing pass with safeguards,
  prestige, special planes ([shop plan](../docs/decisions/2026-10-18-shop-plan.md)); draft prices in the
  [pricing research](../docs/research/PRICING-RESEARCH-2026-10-18.md).
- **Stage 9 approved (2026-10-18).**
- **Wall touches are fair now (you re-checked):** a graze under about 25 degrees on a building, the
  room or the train's side is a scrape: a little damage, the nose is knocked away and the plane wobbles, and you
  steer back. Grinding along keeps costing more. More head-on crashes; the train's moving front still kills. Checked:
  15 degrees along a wall wobbled and survived, 45 crashed; train sides 5-20 degrees scrape, 30+ crash, front kills;
  bots died only to weapons in a 2-minute match. ([decision](../docs/decisions/2026-10-18-scrapes-wobble.md))
- Earlier: real-looking bots; plane emote parked for the shop (1,013 Meshy credits left); private publish.

# Now: Stage 10 shop (stays off until you OK prices) (MILESTONES)
Toilet Roll jitter: not reproduced; tell me when it happens.

What works: everything in Stage 9 (flight, 6 weapons, bots, menus, city, power-ups, hangar, HUD, zone).

Broken or not yet checked: Visual looks of deaths/glints/split planes still wait on Alan's eyes. Bot-vs-bot rams never land.
During the vote lap the top strip still shows the old round's mode and clock.
Track C saving needs a private publish (Alan's go). Place file not re-saved (needs Ctrl+S; code lives in src/).

Decisions to review
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
0. Studio: File > Save to File (keeps today's duct fan fix in the place file).
1. Drawing pass outside AI check: costs money per drawing; your go before it is built.
2. Prices: draft ladder in docs/research/PRICING-RESEARCH-2026-10-18.md for your OK.
