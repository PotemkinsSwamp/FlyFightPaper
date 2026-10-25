# Since Alan last checked (2026-10-25, evening)
- **Loading rebuilt in your order:** loading screen's own art first (shows whole), then every menu in the order a player
  meets them, then the town; Skip only once menus and town parts are in, with a "grey buildings fill in" note.
- **Found:** menu pictures were never really preloaded (fixed); Roblox throws away preloaded pictures nothing draws
  (the first screens now stay drawn); smaller files don't help (Roblox re-stores every upload).
- **Your real-PC cold join:** loading screen 1.3 s (instant), Skip 28 s, all 48.7 s. Phone: 1 min 46 s (worse: my
  12-at-once change; undone). Since then: menus 8 at a time, plane pieces 2 s limit; Studio cold 30.4 -> 20.4 s.
- **PC cold tests without your phone:** `tools/cold_cache.py` empties Roblox's download cache, then a join is timed.
- **Waiting on you:** publish this build, then a cold PC join (I clear the cache first). Next: menu sheets and
  lighter boards, previews before any upload. Repacked-town swap still waits behind this.

# Now: load lane: docs/plan/LOAD-PLAN.md (fast phone joins, same look); UI lane: screen fit steps 3-6 waiting
What works: everything in Stage 9, tutorials, desk quick menu; phones lay out cleanly on the big phone and PC.
Broken: a fresh phone join takes ~1 min 46 s; menus (~150 files, ~51 MB) are the wall; step 3 (repack) uploaded, swap waits.
Not yet: small iPhone and iPad not re-checked since the gap change.

Decisions to review
Repack: bell tower + sweet shop keep their pictures (moderation caution); 111 pieces keep theirs (sharing would add pixels).
Smaller maps: bell tower + sweet-shop swirl roof keep full-size maps (moderation caution).
Loading: Skip once all menus + town parts are in; a stuck file costs 8 s (plane pieces 2 s); 3 minutes at most.
  On a phone the match tip may cover the news note and kill feed (never Health/Lift).
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
- **Publish now, then a fresh join** (delete + reinstall Roblox): do the menus show in seconds? How long until the
  town is drawn? (Your join is recorded; no need to read /console.)
- Then switch the Device Simulator to the small iPhone and the iPad for my re-check (screen fit steps 3-6 follow).
- Winners' moment: watch 2-3 endings in Play (Studio's "end: parade / carnival / show" buttons in the desk hangar).
- Touch: try the stick and buttons in the Device Simulator (now on): does the stick turn too fast or slow? Buttons
  the right size? Watch for the yellow dot in the Range.
- Later: bots' guns cross at 150 studs (your call); backlog: a new fan sound.
1. Drawing pass outside AI check: costs money per drawing; your go before it is built.
2. Prices: draft ladder in docs/research/PRICING-RESEARCH-2026-10-18.md for your OK; then products, passes, VIP perks.
3. Touch step 6: a private publish so you can play on your phone (your go then).
