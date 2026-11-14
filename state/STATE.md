# Since Alan last checked (2026-11-14)
- **Your crane playtest list is fixed** (tabs, Buy not Try on, paper-and-tape buttons, crumpled ball wears the skin,
  crane guns under the wing, shelf wears the skin). From your replay: the **crane is shorter** (shallower belly, lower roof),
  its **wings sit on the body's edge**, the **grey crane is blue again**, the **hangar keeps the plane picture between clicks** (a new plane loads behind the old one
  and swaps in when ready) and **gets the shop's answer right after Buy** (it waited for a 3-second refresh).
- **Crane hitbox matches the drawn crane** (wings tilt 32 degrees, same size; guns and booster hit where drawn; the
  booster now sits against the belly). Tests 650/0. Place saved to Roblox (version 735, not published).
- **Boosters under the crane wear its blue wave paper** (sheet uploaded with your go, free; tests 635/0). Your answers
  are in the [notes](../docs/playtests/2026-11-13-crane-and-skins-tabs.md) and [skin rules](../docs/decisions/2026-11-13-skin-rules.md).

# Now: finish the game for the beta
Next: the crane's moving gun pieces drawn at the old gun spot (WeaponMotion), the Toilet Roll shake in flight; skin
art runs in its own session (model sheets picked: Shark Jet A, Dragon B; Dragon-head Blender test next), then the
six printed skins, Shark Jet, Dragon, the three trails
([skins plan](../docs/plan/SKINS-PLAN.md)). After skins: missions, the playtime calendar, bots that use the town
([ideas](../docs/plan/IDEAS.md)). Not checked: phone sizes of the report card row and the gift note and arrival; a
real gift through the shop; the unlock backpack's music dip.

Decisions to review
Skins: bots in Common/Rare skins get a random plain trail; looks are made ahead (`tools/art/skin_looks.py`); crane
  has no trail yet; its wings fit ~5% bigger than Blender's (part boxes, not vertices); Trails tab lists, draws nothing.
  Crane: about a quarter shorter (belly to the real body's bottom, roof 0.5 of a step up, was 0.9); width as before.
Gift arrival: Open it! is a tap; on Thanks the gift comes at you and fades; the pop is the Popper's, higher and soft.
Shop: chalk headings white with a dark outline; card parts sit still and bob. Stickers by real value: 40,000 "Most
  Value", 15,000 "Good Value" (5,000 lost its sticker). Pack pictures grow with the amount. Daily gift days turn over at
  UTC midnight; a boost gift you already own forever gives 250 Paper. Gear cards: slimmer Hit row, bigger words.
Report card: team cards moved apart a little (they touched); winners' note just "Red team wins!" (scores are in the
  boxes); Tab's live standings use the same card without grades or note.
Unlock: no count sticker on the in-match Menu button; phones keep the level-up note's first size. Customize binder at
  95% so the stats paper fits. Welcome card sits over Play.
Toilet Roll leaned 8 (not 9); boosters keep their weight (Elastic now -3 studs/s). Tank bots: Toilet Roll 3 Pellets,
  Cardboard 2 Crayons + a Pellet.
Bots follow a target up a vent: veterans 60%, Aces 90%; with 2+ spitballs stuck they fly to a fan. Staple ~800 studs.
  Spitball builds: Mk2 body, Nose 1, Wings 3, Tail 3 (105 studs/s); the Paper check skips them.
Spitball: 5 per plane in all; each 6% slower, 1.5x Lift burn, 2.5 studs/s sink; stuck ones 4 credit each; hit box = pellet's.
Point Popper: 7 leads x 5, one a second, bundle to 50 studs, ring 3 studs out by 100, falls past ~100; level 2, 300 Paper.
Thumbtack: 900 studs/s, heavy drag, falls past ~500; full damage to 100 studs; level 4, 600 Paper; "Thumbtack Shooter".
Falling shots: slow hard (drag 3) and fall (196 studs/s^2) for up to 3 s; Paperclip carries ~840 studs while falling.
Landing catch box 90 x 90 x 70 (ring 74 across), dives/climbs to 60 degrees count. Felt crash: within 40 studs of the part.
Solid now: cars, buses, boats, lamps, trees, benches, building site, playground, cubby shelf, Earth. Still see-through:
  landing rings, threads, desk hangars, runway lights, wall pictures, your three models.
Preset levels stay at 5, 8 and 10 at about 340 XP a match (one mostly rookie bot match; recheck with a real player).
Rams: centres within 2.5 studs in the last 0.1 s, strength by relative speed; stronger plane loses 15 extra, always
  survives; rams earn no kill; teammates and practice flights never ram.
Paperclip distance damage: 12 at 150 studs, 24 at 500, 36 at 1000, 60 at 2400. Tab list shows all 12.
PC keys: letters (not K or R), Shift, Ctrl, Alt, Space; Got it may share Boost/Brake's key. Auto-fire fires on the
  yellow dot too, and on Range targets (a phone's accuracy card reads high).
Loading: Skip once menus + town parts are in; a stuck file costs 8 s; 3 minutes at most.
Screen fit: phone under 540 points, tablet under 900; FIRE 76-120 points; small PC window gets tablet sizes.
Touch: aim help cone 6 (fades from 3), to 800 studs, slowdown 0.65 within 8 degrees; held Skip (1.5 s) skips a lesson.
Winners' moment: cheers 3.2 s, song at 1st's landing (8.1 s), fades by 26 s; 1st a winner's move, 2nd/3rd dances.

Waiting on Alan
- Replay the hangar: click skins, tabs and Cancel (no reload flash?), the crane's height and wing join, a
  booster under the crane, and Buy on a skin (the screen should change right away).
- Look at: the bigger starter pack wings, the big bodies in the Hangar (dev switch), the jar filling after a match.
- Publish when you like (report card, new shop window: the shop button only shows in Studio until go-live).
- Save to File when you want the new weapon models and the tape-roll tower in the place file (your go).
- In flight: Range notes + Range Menu strip click, leaving the Range, FFA strip at a desk, a Match tip.
- Device Simulator: small iPhone and iPad for the screen-fit re-check. Backlog: a new fan sound. Drawing pass outside AI check (costs money; your go).
