# Since Alan last checked (2026-11-18)
- Daily and weekly missions now save progress, handle Claims and Swaps, and pay unclaimed rewards at reset. The server sends mission completions for the report card. Studio checks are pending. [Saving](../docs/systems/saving.md#daily-and-weekly-missions)
- Private Studio save 820 has the illustrated chest openings. All eight chests hold a sharp open pose. Trail cases use different paper and trim. Light Shop lettering has a black outline. All 719 tests passed. [Studio video and pictures](../docs/playtests/2026-11-18-shop-chest-openings.md#illustrated-chest-openings)
- Customize keeps the book and stats on screen while you pick gear or looks. All 18 trails run behind the plane. Holographic moves on both faces and skins cover the team stickers. [Studio check and pictures](../docs/playtests/2026-11-18-hangar-preview-and-clicks.md)
- The normal Hangar now shows 23 skins and 18 trails. Shark Jet has its finished body. All 41 cards were selected and worn in Studio with a test wallet. [Hangar check](../docs/playtests/2026-11-18-hangar-catalog.md)
- **Two scripted Play tests are done** ([numbers and the full list](../docs/playtests/2026-11-16-scripted-looks-check.md)). Frame rate, 12 planes: 60 with no looks, with any one skin, and with any one Rare moving; 56.7-60 with one trail on all 12; 58.5 with a mixed set on every plane; 54.5 in the worst case (12 Galaxy + 12 Circuit Trace: each alone holds 60, only together they go under).

# Now: finish the game for the beta
The five finished Legendary skins and matching trails are installed. The two Mythicals include their trails. The four other Legendary ideas (Bumblebee, Rocket, Mech and Pirate) are concepts. The remaining performance check is Galaxy plus Circuit Trace on all 12 planes.
Dragon leftovers: crash ball and shop card pictures, jaw leftover. **Next: check the missions in Play and connect the report card slip** ([decision](../docs/decisions/2026-11-18-daily-and-weekly-missions.md)). Queued: Toilet Roll shake, playtime calendar, bots that use the town ([ideas](../docs/plan/IDEAS.md)).
Not checked: phone sizes of the report card row and the gift note and arrival; a real gift through the shop; the unlock backpack's music dip.
Decisions to review
Chest prices, drop rates, 10% duplicate refunds and the first mission and streak targets are tuning choices. [Numbers](../docs/systems/economy-and-shop.md#classroom-treasure-chests)
Dragon (my calls): centred on the plane lengthwise; guns hang under its wing as a triangle outline, clear of its body;
  shots from a moved gun join their real path within 15 studs; the one 1024 set gives each part the share Studio showed it.
Commons (my calls): booster scales the body's size; Racing Stripe's fin all cream; 8-Bit option B taken on "that looks good"
  (A = six colours, one line in `skin_sheets.py`); a flame patch shows small at the back of the body.
Trails (my calls): names; 99 Robux / 1,900 Paper stand-in for a Rare match (price parked); the saved id `rainbow_marker` stays behind the name Holo Rainbow (my reading of your "Go", 2026-11-16); stars, flakes and bolts are real small parts, smoke and sparkle dust are Roblox particles with Roblox's own pictures (sparkle dust as 3D parts was too many: about 170 a second a plane);
  a foil flake is a thin chip. Holo Rainbow keeps the saved Rainbow Marker ID.
Rares (my calls): Galaxy is one small solar system a wing (a big orbit was cut by the body); far planes keep their layers standing still; Holographic has moving underside layers; 39 pictures, not the 28 I first said.
Skins: bots in Common/Rare skins get a random plain trail; looks are made ahead (`tools/art/skin_looks.py`); the crane grants Folded Petals; its wings fit ~5% bigger than Blender's (part boxes, not vertices).
  Crane: about a quarter shorter (belly to the real body's bottom, roof 0.5 of a step up, was 0.9); width as before.
Gift arrival: Open it! is a tap; on Thanks the gift comes at you and fades; the pop is the Popper's, higher and soft.
Shop: chalk headings white with a dark outline; card parts sit still and bob. Stickers by real value: 40,000 "Most
  Value", 15,000 "Good Value" (5,000 lost its sticker). Pack pictures grow with the amount. Daily gift days turn over at
  UTC midnight; a boost gift you already own forever gives 250 Paper. Gear cards: slimmer Hit row, bigger words.
Report card: team cards moved apart a little (they touched); winners' note just "Red team wins!" (scores are in the
  boxes); Tab's live standings use the same card without grades or note.
Unlock: no count sticker on the in-match Menu button; phones keep the level-up note's first size. Customize binder at 95% so the stats paper fits. Welcome card sits over Play.
Toilet Roll leaned 8 (not 9); boosters keep their weight (Elastic now -3 studs/s). Tank bots: Toilet Roll 3 Pellets, Cardboard 2 Crayons + a Pellet.
Bots follow a target up a vent: veterans 60%, Aces 90%; with 2+ spitballs stuck they fly to a fan. Staple ~800 studs.
  Spitball builds: Mk2 body, Nose 1, Wings 3, Tail 3 (105 studs/s); the Paper check skips them.
Spitball: 5 per plane in all; each 6% slower, 1.5x Lift burn, 2.5 studs/s sink; stuck ones 4 credit each; hit box = pellet's.
Point Popper: 7 leads x 5, one a second, bundle to 50 studs, ring 3 studs out by 100, falls past ~100; level 2, 300 Paper.
Thumbtack: 900 studs/s, heavy drag, falls past ~500; full damage to 100 studs; level 4, 600 Paper; "Thumbtack Shooter".
Falling shots: slow hard (drag 3) and fall (196 studs/s^2) for up to 3 s; Paperclip carries ~840 studs while falling.
Landing catch box 90 x 90 x 70 (ring 74 across), dives/climbs to 60 degrees count. Felt crash: within 40 studs of the part.
Solid: cars, buses, boats, lamps, trees, benches, building site, playground, cubby shelf, Earth. See-through: rings, threads, desk hangars, runway lights, wall pictures, your three models.
Preset levels stay at 5, 8 and 10 at about 340 XP a match (one mostly rookie bot match; recheck with a real player).
Rams: centres within 2.5 studs in the last 0.1 s, strength by relative speed; stronger plane loses 15 extra, always
  survives; rams earn no kill; teammates and practice flights never ram.
Paperclip distance damage: 12 at 150 studs, 24 at 500, 36 at 1000, 60 at 2400. Tab list shows all 12. PC keys: letters (not K or R), Shift, Ctrl, Alt, Space; Got it may share Boost/Brake's key. Auto-fire fires on the
  yellow dot too, and on Range targets (a phone's accuracy card reads high).
Loading: Skip once menus + town parts are in; a stuck file costs 8 s; 3 minutes at most.
Screen fit: phone under 540 points, tablet under 900; FIRE 76-120 points; small PC window gets tablet sizes.
Touch: aim help cone 6 (fades from 3), to 800 studs, slowdown 0.65 within 8 degrees; held Skip (1.5 s) skips a lesson.
Winners' moment: cheers 3.2 s, song at 1st's landing (8.1 s), fades by 26 s; 1st a winner's move, 2nd/3rd dances.

Waiting on Alan
- **Missions.** Check both tabs, try a free and a paid Swap, then press **Dev: finish missions** and Claim Paper, XP and chests.
- **Shop > Chests.** Open a Skin or Trail chest and try Wear. Check the opening animation, the two chest designs and the rarity papers in the Hangar. Robux buttons are Studio practice only.
- **Trails, your Play look:** start a match, press **Dev: trail** (bottom right, above Dev: skin): each press puts the next of the 18 trails on every plane, then each its own. Against your videos: is each one thick body? 3D pieces 3D? Rainbow showing most colours from your seat? Storm cloud lit by its lightning? Notes the right way up, little planes nose-first? Dragon's embers glowing, not glittering? Circuit's LEDs flashing? Anything in your aim? Does it hold 60 with all 12 planes wearing one (Circuit Trace, Gold Stars and Glitch Pixels are the heaviest)?
- **The Rares in Play (your eyes; a script says they move, not that they look right):** Dev: skin through the eight, on your plane and in the hangar. Does each move like its video? How does Holographic read from below? Do sparkles and smoke start in clumps?
- Try quick card changes and Cancel, then drag the live trail preview. Check the crane's height and wing join, a booster under it, and opening an earned chest. Also look at: the bigger starter pack wings, the big bodies in the Hangar (dev switch), the jar filling after a match.
- After the skin views (Alan 2026-11-15, backlog): the desk's big photo and pinboard under the crane (crane only);
  no gun piece floating off the crane's guns, at the desk and firing; the Toilet Roll shake with my recorder (your go).
- Publish when you like (report card, new shop window; shop button Studio-only until go-live). Save to File for the new weapon models and tape-roll tower (your go).
- In flight: Range notes + Range Menu strip click, leaving the Range, FFA strip at a desk, a Match tip. Device
  Simulator: small iPhone and iPad. Backlog: a new fan sound; a drawing-pass outside AI check (costs money; your go).
