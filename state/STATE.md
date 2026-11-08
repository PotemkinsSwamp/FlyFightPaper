# Since Alan last checked (2026-11-08)
- **The beta must feel finished:** one map, a strong first-session hook. Plan: docs/plan/CLASSES-PLAN.md, step 4
  (unlock ladder) in progress; your calls: docs/decisions/2026-11-08-unlock-ladder-and-bot-builds.md.
- **Gear page:** all ten weapons on one page in shorter cards; the box under them says what the weapon does, plain words.
- **Weapon order + free weapons:** Pellet 1, Popper 2, Staple 3, Thumbtack 4 are free at their level; Spitball 6, Rubber
  Band 7, Paperclip 9, Crayon 12, Eraser 22, Pencil 40 cost Paper (old prices until the numbers are in).
- **Presets:** the Fighter now carries a Thumbtack and the Bomber a Crayon (their stand-ins were never swapped).
- **Bots:** rookies fly the level-1 presets, regulars every preset but the Marksman, veterans four player-style builds;
  no bot carries a Paperclip, Eraser or Pencil. Regulars and veterans brake when closing on a target.
- **Free-for-all ends only on time** (no 20-fold cap).
- **Bug I caused and fixed:** the brake broke bot steering (bots flew into walls); fixed, lesson added.
- **Veteran matches:** about 6 folds, 370 Paper, 650 XP a bot a match (top 11-13 folds). You: 6 = weak player, 11-13 =
  average, 25+ = really good.
- **Unlock moment concept:** 8 frames + crisp test pieces in .planning/unlock-concept2/ (gpt-image-2).
- **Text style picked: C** (Kalam heavier + light outline + shadow: "like a child wrote it with a crayon");
  rolling it out to every menu is queued.
- **Not saved or published yet:** the new weapon models are synced into your open Studio; Save to File and publish need
  your go.

# Now: finish the game for the beta
Next, in order: (1) Aces + bot tricks + smart
target switching, then Ace/veteran measuring matches (your go); (2) prices and levels from the numbers (your OK);
(3) the unlock moment (backpack bigger, at the screen's bottom edge, drag-to-unzip). Then the text rollout (style C), mastery, bots follow the lobby,
balance pass, winners' circle, skins, shop.

Decisions to review
Spitball: 5 per plane in all; each 6% slower, 1.5x Lift burn, 2.5 studs/s sink; stuck ones 4 credit each; hit box = pellet's.
Crayon 600 studs/s, 450 range, drop 8. New weapons keep their stand-in hit boxes; Popper lead drawn 0.15 x 1.2.
Ram catch: centres within 2.5 studs in the last 0.1 s; ram strength by relative speed.
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
- Save to File / publish when you want the new weapon models in the place and live (your go each).
- Publish (File > Publish As > Overwrite), then on your phone: kill feed, desk dev panel, results card, confetti.
- Device Simulator: small iPhone and iPad for the screen-fit re-check. Winners' moment: watch 2-3 endings.
- Backlog: a new fan sound. Drawing pass outside AI check (costs money; your go). Prices: draft ladder in
  docs/research/PRICING-RESEARCH-2026-10-18.md. Real-phone check after publishing.
