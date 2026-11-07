# Since Alan last checked (2026-11-07)
- **The beta must feel finished:** one map, a strong first-session hook. Plan: docs/plan/CLASSES-PLAN.md (step 3 now).
- **Weapons (your design, docs/decisions/2026-11-07-four-new-weapons-and-falling-shots.md):** every shot now falls in
  an arc past its range; a fold by a falling shot pays +50 (FOLD AT A DISTANCE). **Point Popper** (7 leads, bundle to
  50 studs, then a narrow steady spray) and **Thumbtack** (18/s close, weaker far) are in, on stand-in models. You
  checked both: good. Stubby Crayon and Spitball are next.
- **One shot per click** on PC for every weapon that isn't automatic (Paperclip too); phones keep hold-to-fire.
- **Cardboard Gunship:** heavy, heavy, medium, medium, medium, light (a fifth medium gun).
- **Fixed:** a thin rail folded a plane that then came back (the pilot's felt crash now counts); the desk landing ring
  catches its edge and steep dives; the Earth and 510 rug toys are now solid (only the open Studio has their shapes).
- **Bot match:** about 340 XP a match; staying to the end pays at least 60 XP. Phone simulator check passed.
- **None of this is published yet.** Studio test runs are muted (DevMute).

# Now: finish the game for the beta
Next: Stubby Crayon, then Spitball (rules and tests first, stand-in models), then their real models (Codex picture,
then Codex Blender; no Meshy), then the unlock ladder, mastery, bots following the lobby, winners' circle, skins, shop.

Decisions to review
Point Popper: 7 leads x 5, one a second, bundle to 50 studs, ring 3 studs out by 100, falls past ~100; level 2, 300 Paper.
Thumbtack: 900 studs/s, heavy drag, falls past ~500; full damage to 100 studs; level 4, 600 Paper; "Thumbtack Shooter".
Falling shots: slow hard (drag 3) and fall (196 studs/s^2) for up to 3 s; Paperclip carries ~840 studs while falling.
Landing catch box 90 x 90 x 70 (ring is 74 across); dives or climbs up to 60 degrees count.
A pilot's felt crash counts if the plane is within 40 studs of that solid part.
Solid now: cars, buses, boats, lamps, trees, benches, building site, playground, cubby shelf, Earth. Still see-through:
  landing rings, threads, desk hangars, runway lights, wall pictures, your three models.
Preset levels stay at 5, 8 and 10 at about 340 XP a match (one mostly rookie bot match; recheck with a real player).
Rams: stronger plane loses 15 extra, always survives; rams earn no kill; teammates and practice flights never ram.
Paperclip distance damage: 12 at 150 studs, 24 at 500, 36 at 1000, 60 at 2400. Tab list shows all 12.
PC keys: letters (not K or R), Shift, Ctrl, Alt, Space; Got it may share a key with Boost or Brake.
Auto-fire fires on the yellow dot too; in the Range it fires on targets, so a phone's accuracy card reads high.
Repack and smaller maps: bell tower + sweet shop keep full-size pictures (moderation caution).
Loading: Skip once menus + town parts are in; a stuck file costs 8 s; 3 minutes at most.
Screen fit: phone under 540 points, tablet under 900; FIRE 76-120 points; small PC window gets tablet sizes.
Touch: aim help cone 6 (fades from 3), to 800 studs, slowdown 0.65 within 8 degrees; held Skip (1.5 s) skips a lesson.
Winners' moment: cheers 3.2 s, song at 1st's landing (8.1 s), fades by 26 s; 1st a winner's move, 2nd/3rd dances.
Match Tips: 6 s on screen, 20 s apart. Walls stay soft 2 s into a new round. Classroom chatter 0.08.
Combat School Pals, Range targets and Hangar behaviour: as listed on docs/systems/tutorial.md and planes-and-hangar.md.
Eraser lock stays on after firing while the target stays in the circle.
Early part unlocks: one Roblox product per part (you'd create 30); a part you own flies at ANY level.
Scrape wobble 10 degrees, crash angle 25; stapler 17.5/s; fan 15 Lift/s, updraft 30; dive with Lift 1.25x max.
Duct props see-through; veterans flee to the ducts 40% when shot at. Chalk eraser cloud hides planes inside it.
Zone 680-840 across; bots on the zone 30/60/85%. Points: assist share rounded to 5 (10-80); outside-zone fold 40%.

Waiting on Alan
- **File > Save to File in Studio** so the new solid toys keep their exact shapes (else Studio recomputes them).
  Then Claude checks whether the place file grew enough to slow phone loading (fix if so: box shapes for small toys).
- Try the Point Popper, Thumbtack, one-click Paperclip and the solid toys when you like (stand-in weapon models).
- Publish (File > Publish As > Overwrite), then on your phone: kill feed, desk dev panel, results card, confetti.
- Device Simulator: small iPhone and iPad for the screen-fit re-check. Winners' moment: watch 2-3 endings.
- Backlog: a new fan sound. Drawing pass outside AI check (costs money; your go). Prices: draft ladder in
  docs/research/PRICING-RESEARCH-2026-10-18.md. Real-phone check after publishing.
