# Since Alan last checked (2026-10-23)
- **Range sticky notes approved** after two rounds of your notes: the tutorial's own note, Space for Got it, K for
  Skip all, arrows beside what they point at, a Back note over the Hangar, last note "The Range is yours".
- **Match Tips built and seen working** ("they work"): nine one-line tips in your first real matches, each once;
  only while a round is on; Settings > Match tips On/Off.
- **Fixed:** losing control when a team or Airspace round repainted your plane (it flew straight into a wall); a plane
  left on a wall in the break folding the instant the next round began; the vote lap's top strip (now VOTE 0:30, cards
  under it, no tips over it); classroom children only heard while flying in a match; no match clock in the Range.
- Range build swap animation dropped for now (your call).

# Now: UI lane: the winners' moment sounds (picked; cue sheet for your OK, then build)
What works: everything in Stage 9, the tutorials, the desk quick menu, the Range notes, Match Tips.
Broken or not yet checked: Match Tips for team, Airspace and wall scrapes not seen live. Visual looks of
deaths/glints/split planes still wait on your eyes. Bot-vs-bot rams never land. Track C saving needs a private
publish (your go). Place file not re-saved (needs Save to File, your go; code lives in src/).

Decisions to review
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
- Winners' moment sounds: your OK on the cue sheet (what plays when over the 27 s), and a longer winners' track
  (Cartoon Time is only 5 s). Picks so far are in docs/plan/MILESTONES.md Stage 7.
- Your call later: give the match bots the gun fix too (their guns still cross at 150 studs).
- Backlog (yours): a new fan sound. Private publish (your go) to test the move into the tutorial room.
0. Studio: File > Save to File (keeps the latest fixes in the place file).
1. Drawing pass outside AI check: costs money per drawing; your go before it is built.
2. Prices: draft ladder in docs/research/PRICING-RESEARCH-2026-10-18.md for your OK; then products, passes, VIP perks.
