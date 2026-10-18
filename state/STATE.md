# Since Alan last checked (2026-10-17)
- **Published privately** ("FlyFightPaper(First Fold)", 12 players); live up to the desk hangar flow and menu art.
- **Done (Alan's notes):** clicking the weapon already on a mount takes it off; the button reads "Clear weapon spot".
  Event lines rewritten after Alan's notes: death lines say how it happened, Minecraft-style (weapon, the building
  or thing you hit, who chased or rammed you), classroom-themed, no sound words; your note and the kill feed say the
  same line. All in src/shared/Lines.luau. Seen in Studio Play; tests 326/0. Alan is reviewing the full list.
- **Round end, Alan's revisions all built** (seen in Studio Play): Studio "end match" button; winners' cutscene
  (camera glides to the chalkboard-row desks, the top 3 stand up, hop on the desks and dance/cheer/wave with name
  tags, camera glides back); results card with folds, assists, crashes, team totals, your Paper/XP and level bar;
  three big neon vote rings on the window wall with a HUD arrow; level bar + next unlock on the menu board, hangar
  and card. Fixed on the way: a team round starting right after a free-for-all (or the reverse) crashed seating
  the bots; emotes threw giant avatars' bodies apart (Roblox scales the hip movement twice).
- **Main-menu ruler** (numbers 1-12, right way up): its own session, waiting on Alan's OK before upload.
- **Join straight in:** a bot leaves at once for a joining player; beginners join a friend after one match.
- **20 speed boosts** (8 new, in the fly-through holes: porthole, tape roll, ruler stilts, abacus slot, block arch,
  pencil-case bridge, under both stations below the train). **Paper targets** back on ten open rooftops.
- **Airspace zones bigger and flatter where buildings are dense** (Alan); the Studio dev button "next spot" moves
  the zone to the next spot on each click (replaces "ceiling"). Checked by numbers in Play; looks wait on Alan.

# Stage 9 — what's left (MILESTONES D13)
Everything is built; what's left needs your eyes: the playtest list at the bottom, then your Stage 9 approval.
Toilet Roll body jitter: not reproduced; tell me when it happens.

What works
Flight, combat with 6 weapons, bots, menus, city, bell tower, power-ups, fans, all plane parts, hangar preview,
two aim markers, automatic takeoff, paper deaths, moving weapons, on-brand crayon HUD, moving Airspace zone.

Broken or not yet checked
Visual looks of deaths/glints/split planes still wait on Alan's eyes. Bot-vs-bot rams never land.
One cutscene frame showed a big green shape across the camera for a moment (probably a plane mid-takeoff when
everything froze); watch for it. During the vote lap the top strip still shows the old round's mode and clock.
Vote-ring arrow not yet seen pointing (needs flying away from the rings).
Track C saving needs a private publish (Alan's go). Place file not re-saved (needs Ctrl+S; code lives in src/).

Decisions to review
Results card "Crashes" counts every time a pilot went down (shot or crashed), from the round's deaths.
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

Waiting on Alan — Stage 9 playtest, then your approval
1. Modes: in the hangar pick "mode: team DM", "mode: airspace" and "mode: ceiling". Team colours on planes and names,
   the moving zone and its green arrow, the ceiling spot (east side, under the rings), veteran bots fighting for the
   zone while rookies wander, the "+100 FOLD" pop-ups and the results points.
2. Round end: in the hangar press "end match" (red, top). Watch the winners' cutscene, the results card, then fly
   through a neon ring on the window wall to vote. Try it once from the air and once from the hangar.
3. Train: skim it (should scrape, not crash), fly into its nose (crash), fit above it in the south station.
4. Escapes: puff the chalk eraser; take the ducts once more (spot a veteran bot diving out of a vent).
5. Hangar: land at your desk, pick a build, Edit build, change a part, Save & fly. Does it make sense first time?
   On the weapons tab, click a mounted weapon again: it comes off. Crash a few times: the lines change each time.
6. Say "Stage 9 approved", or what to fix.
