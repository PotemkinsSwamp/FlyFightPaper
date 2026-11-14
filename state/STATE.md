# Since Alan last checked (2026-11-13, night)
- **Skins work for Commons and Rares** (you played them in Studio: "pretty good"): 83 plane pieces got printed-sheet
  copies with their creases, uploaded with your go; bots wear skins by difficulty; "Dev: skin" button (bottom right)
  tries Hazard and Lava (rough test pictures) on your plane. Prices approved: Common 149 R$/2,800 Paper, Rare 299/5,600,
  Legendary 599/30,000, Mythical 999/60,000, trails 49/900; no free skins; boxes a maybe (odds shown are fine).
- Saving and buying skins and trails is built (save v13, tests 617/0); no Looks screen yet.
- **Origami Crane** (first Mythical) is being built in Blender by a linked Fable session; renders come to you first.

# Now: finish the game for the beta
Next: the Origami Crane (Blender, your OK on renders before upload), then skins on the boosters, the real skin
pictures (Hazard, Tiger, Flame, Gold Foil, Lava, Galaxy), Shark Jet, Dragon, the three trails, and a Skins and a
Trails tab in the customization menu ([skins plan](../docs/plan/SKINS-PLAN.md)). After skins: missions, the
playtime calendar, bots that use the town ([ideas](../docs/plan/IDEAS.md)). Not checked: phone sizes of the report
card row and the gift note and arrival; a real gift through the shop; the unlock backpack's music dip.

Decisions to review
Skins: bots in Common/Rare skins get a random plain trail; looks are made ahead in a file (`tools/art/skin_looks.py`)
  because runtime-built looks need ~4 MB in-memory pictures; crease pictures are 1024 (can go 512 if memory shows).
Gift arrival: Open it! is a tap; on Thanks the gift comes at you and fades; the pop is the Popper's, higher and soft.
Flight HUD hides during the winners' moment (its weapon slip sat under the report card's jar button).
Paper jar: the last card in the Paper section (orange like the packs, so the row of 3 is full); no gift button on it.
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
Loading: Skip once menus + town parts are in; a stuck file costs 8 s; 3 minutes at most.
Screen fit: phone under 540 points, tablet under 900; FIRE 76-120 points; small PC window gets tablet sizes.
Touch: aim help cone 6 (fades from 3), to 800 studs, slowdown 0.65 within 8 degrees; held Skip (1.5 s) skips a lesson.
Winners' moment: cheers 3.2 s, song at 1st's landing (8.1 s), fades by 26 s; 1st a winner's move, 2nd/3rd dances.
Combat School Pals, Range targets and Hangar behaviour: as listed on docs/systems/tutorial.md and planes-and-hangar.md.

Waiting on Alan
- Look at: the bigger starter pack wings, the big bodies in the Hangar (dev switch), the jar filling after a match.
- Publish when you like (report card, new shop window: the shop button only shows in Studio until go-live).
- Save to File when you want the new weapon models and the tape-roll tower in the place file (your go).
- In flight: Range notes + Range Menu strip click, leaving the Range, FFA strip at a desk, a Match tip.
- Device Simulator: small iPhone and iPad for the screen-fit re-check. Backlog: a new fan sound. Drawing pass outside AI check (costs money; your go).
