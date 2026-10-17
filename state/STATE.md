# Since Alan last checked (2026-10-17)
- **Published privately** ("FlyFightPaper(First Fold)", server size 12); re-published by Alan with the security
  pass and safe server moves (details: docs/systems/flight.md, docs/systems/saving.md).
- **Since that publish (needs another Publish As, Alan's go):** late rewards reach a departed player's save; a
  teleport-and-back is caught; a slow friend check can't start two moves; room search reads 100 rows; fold credit
  (Alan: big damage wins, +25 finishing shot, 15 s, repair wipes); loading screen fixed. Tests 321/0.
- **Hangar flow (Alan's pick):** builds change at the desk: Edit build button, picked-build preview, Save / Save &
  fly - 120 Paper, unsaved-changes warning, free refold into the same build. Checked in Play; not yet published.
- **Menu art done (Alan OK'd, uploaded):** main menu drawings and photo show today's town (photo = Codex
  "cinematic" version, Alan's pick); rulers read real numbers; clean menu plane with its own pin. Checked in Play.
  Needs Alan's Publish As to go live (with the items above).
- **Join straight in:** a bot leaves at once for a joining player; beginners join a friend after one match.
- **Stations 170 tall, in the place, Alan OK'd them in Play;** south tin flies as invisible walls (its computed shape
  blocked the tunnel). Schoolyard trees and houses back.
- **Train 105 studs/s** (Alan: "slightly faster"; brake 35); tests 297/0. Stops centred 10 s in both stations; the
  north station is shorter than the train (end cars poke out ~20 studs).
- **20 speed boosts** (8 new, in the fly-through holes: porthole, tape roll, ruler stilts, abacus slot, block arch,
  pencil-case bridge, under both stations below the train). **Paper targets** back on ten open rooftops.
- **Airspace zones bigger and flatter where buildings are dense** (Alan); the Studio dev button "next spot" moves
  the zone to the next spot on each click (replaces "ceiling"). Checked by numbers in Play; looks wait on Alan.
- **Team match passed by numbers** (6 v 6, results, vote, next round; no bot ever chased a teammate).
- **Rookie graduation:** each step has its own test (qualifying match -> saved count, max 5 -> regular room ->
  regular bots); saving round-trip 17/0, rules 296/0. Not played live (needs 5 real qualifying matches).

# Stage 9 — what's left (MILESTONES D13)
Everything is built; what's left needs your eyes: the playtest list at the bottom, then your Stage 9 approval.
Toilet Roll body jitter: not reproduced; tell me when it happens.

What works
Flight, combat with 6 weapons, bots, menus, city, bell tower, power-ups, fans, all plane parts, hangar preview,
two aim markers, automatic takeoff, paper deaths, moving weapons, on-brand crayon HUD, moving Airspace zone.

Broken or not yet checked
Visual looks of deaths/glints/split planes still wait on Alan's eyes. Bot-vs-bot rams never land.
Track C saving needs a private publish (Alan's go). Place file not re-saved (needs Ctrl+S; code lives in src/).

Decisions to review
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
Zone: 680-840 across, 200-130 tall by building density (ceiling 950 across, 340-620 up); open zone is yellow.
Bots and the zone (config bots.profiles.*.objective_*): share of time on the zone 30/60/85% (rookie/regular/veteran),
  "objective" personality +25%, "aggressive" -15%; only veterans head to the next zone early. Read "noobs should be
  as good" as "noobs should NOT be as good" at the objective.
Points: fold assist share rounded to 5, min 10 max 80; outside-zone fold = 40% (assist min 5); zone qualifying
  events stay 1 per 10 s; a pilot with no position sample counts as outside the zone.
Paper targets: 14.4 x 16.8 studs, 50 points each (500 max), server-checked instead of client-reported (cheat-proof).

Waiting on Alan — Stage 9 playtest, then your approval
1. Modes: in the hangar pick "mode: team DM", "mode: airspace" and "mode: ceiling". Team colours on planes and names,
   the moving zone and its green arrow, the ceiling spot (east side, under the rings), veteran bots fighting for the
   zone while rookies wander, the "+100 FOLD" pop-ups and the results points.
2. Round end: let a round finish (or switch mode in the hangar): does the vote screen look on brand?
3. Train: skim it (should scrape, not crash), fly into its nose (crash), fit above it in the south station.
4. Escapes: puff the chalk eraser; take the ducts once more (spot a veteran bot diving out of a vent).
5. Hangar: land at your desk, pick a build, Edit build, change a part, Save & fly. Does it make sense first time?
6. Say "Stage 9 approved", or what to fix.
