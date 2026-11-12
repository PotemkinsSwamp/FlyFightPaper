# Weapon unlock order, free and paid weapons, a grind, and bot builds

**Decided:** 2026-11-08 (Alan)
**Status:** in progress (order, free weapons, bot builds, Aces, tricks and switching built; Ace matches, prices and the unlock moment next)

## Decision
- **Order** (the unlock ladder and the Hangar's Gear sheet): Paper Pellet (level 1), Point Popper (2), Staple (3),
  Thumbtack (4), Spitball Straw (6), Rubber Band (7), Precision Paperclip (9), Stubby Crayon (12), Guided Eraser (22),
  Pencil Launcher (40).
- **The first four are free** at their level. **Everything after costs Paper**: the stronger a weapon, or the more
  special (Spitball), the more it costs.
- **Unlocking is a grind:** reaching an item's level makes it buyable, but for most things you still save up for a
  while after that. Level 15 after about 6 matches is too fast. Levels, prices and level gifts get set from how other
  games pace unlocks and from real match numbers (a veteran bot match as a stand-in for real players), not guesses.
  Alan's estimate of a real player: about 15 folds a match on average, 40-50 for a strong one.
- **"You unlocked" moment:** the screen goes dark and blurry around a sheet of paper; a backpack at the bottom unzips
  and the item pops out, spinning all the way round, with its name and what it does. Put it on (to the Hangar), Later,
  Next for the next item, Skip. Concept picture first. Other animations (chalk dust onto the blackboard, a projector)
  can come later.
- **Bots:** rookies and regulars fly the preset planes as they are (Fighter's Thumbtack and Bomber's Crayon kept), but
  not the Marksman. Veterans fly their own builds, made with reason the way a player would build: a big body with
  speed parts around it to fit better weapons; or a fast plane with a Point Popper that zips in, brakes, fires and
  zips out. No bot carries a Paperclip, Eraser or Pencil.

- **Every bot steals folds:** it sees a damaged plane (paper flying off) and goes for it to take the fold; better bots
  do it more.
- **Every bot tries its build's tricks**, and skill sets how well: an Ace brakes at about 80 studs almost exactly, a
  Veteran at 80-100 and less reliably, lower tiers worse. Tricks come from the build: Popper dart (in, brake, blast,
  boost out), Crayon stand-off (200-400 studs), Spitball first then the other gun, close turn fights with the brake.
- **Ace tier** above Veteran: better turning, aim and reactions, hunts more. In measuring matches one Ace per three
  Veterans. Whether real lobbies get Aces is for step 6.
- **Unlock moment details:** you drag the zipper yourself (right to left; the screen shakes slightly while you drag on
  PC, phones vibrate if Roblox allows, else shake); "Drag to unzip" arrow after about 2 s for the first few times; a
  small Skip jumps to everything out; several unlocks all come out of one backpack and you swipe or drag between them
  (arrows on PC too), Later removes one; free: "Now in your Hangar" + Put it on; paid: "Now available for purchase in
  the Hangar" + See it (no price). Look: as close as possible to the gpt-image-2 concept frames
  (`.planning/unlock-concept2/`), crisp separate 2D pieces, real game text.
- **All the game's text should look better** (bolder, outlined, shadowed, like the concept pictures): a style test first.

- **Switching targets is a skill** (Alan, later the same day): a good bot that is about to fold the plane it's on
  finishes it first, then goes after the damaged one; it never hops from damaged plane to damaged plane (fewer points
  over time). Aces judge this best, Veterans less, and so on down.
- **Concept review:** frames 1-2 are right. The backpack is bigger and wider, stays at the bottom edge of the screen
  and never shows its bottom (so frames 3-4 as drawn are wrong). Items poking past the paper's edge (frames 6-7) are OK
  if the background is darkened enough.
- **When it plays** (Alan, 2026-11-11): not during the vote lap (it would interrupt play). Leveling up shows a small
  "you unlocked something, open Menu" note with confetti; the backpack plays when you open the Menu, and unlocks pile
  up until you do. Preset planes come out of the backpack too. How it works: [the unlock plan](../plan/UNLOCK-PLAN.md).
- **Backpack details** (Alan, 2026-11-11, trying it in Studio): the zipper opens like a real one (shut at the pull,
  gaping behind it); the red and blue corner tapes sit over the LEVEL strip; the item is the real 3D part; back/next are
  ink chevrons on the page (never over the binder holes); the zipper sound is one long nylon backpack zip (no loop: the
  loop was grating), playing while you move the pull either way and pausing when you stop.
- **Order:** text style test, then Aces and bot tricks (and their measuring matches), then the unlock moment.
- **After the Ace matches** (Alan, later the same day): the Crayon Tank turn-fights like the best planes (drop its
  stand-off; rebuild its weapons only if it's still weak). Order now: fix the bots (Crayon Tank, why Aces don't beat
  veterans) so a match gives a real simulated-player measure of XP and Paper a match; then roll the chosen text style
  out to everything; then the unlock moment. Bots shoot whenever the targeting ring would show, no range rule.
- **The Crayon Tank was a bad build** (Alan, after the fixed bots' first 1-minute check): Rubber Bands fire fast and
  hit hard at medium range before they scatter, so they need a plane that gets close; a slow tank can't, so nobody
  would build it. Ace builds must be strong and make sense on the numbers. Replaced by the Staple Tank (same heavy
  body, six Staple guns: fast, straight, full damage at any distance, 105 damage a second at 500 studs).
- **Bots are the balance test, not the thing to tune** (Alan, after the Staple Tank): Aces play like above-average
  players and veterans like average ones (no bot can play like the best). So build the reasonable combinations real
  players would make, let the bots fly them, and balance the weapons from what comes out. A build that is too strong
  points at a weapon or capacity problem to fix in the game, never at the bot build to weaken (taking a Staple off the
  tank would hide it). Balance holistically: e.g. raising weapon capacities would leave small fast planes one gun.
- **The Staple was too strong** (Alan, after the baseline matches: Staple Tank veterans ~14 folds, other builds 4-10):
  per capacity point it out-damaged everything, with no catch (fast, straight, no overheat, full damage at any
  distance, free). Its damage per staple stays; its bursts come 1.05 s apart instead of 0.8 (13.3 a second, a
  Pellet's), and it reaches ~800 studs instead of ~900 (just past the Pellet's 750, keeping the range order). Gentle
  damage loss with distance for every weapon is an idea for the balance pass (whole-number damage would make small
  hits jump, e.g. a Pellet's 2 to 1).
- **Spitball builds** (Alan, same evening): the Spitball is support (it slows a plane and makes it fall), so it
  belongs on a medium plane: a fast one just catches up and brakes, a medium one sometimes can't catch small planes.
  Two veteran builds: Spitball with two Rubber Bands, and Spitball with the Point Popper. The old Spitball Hunter's
  parts made it slow (90 studs/s) for its health.
- **Ducts are for players; spitballs soak** (Alan, after the third run): bots never take the ducts on their own, only
  follow a plane they were chasing up a vent. The Spitball Popper (1.5 folds) and Spitball Hunter (4.3) proved the
  Spitball too weak even as support, so stuck spitballs now soak the paper until a fan dries them. Numbers Alan
  locked after seeing them: 3 damage on impact (was 1), soak 1 a second per stuck spitball (5 stuck at most): one
  launcher hitting every shot does 11 a second, two do 17, and a fully soaked plane takes up to 60 more without a fan. The price table: 12 folds a match is an average player, 25 a really good one; Paper and XP from those.
- **Weapon weights and the tank bodies** (Alan, end of 2026-11-08; next to build, then a bot test). Why: a plane's
  health and its guns multiply in a straight fight; with a Pellet in every slot the Toilet Roll was ~3.8x a Classic
  Fold and the Cardboard ~4.2x, and being slower didn't pay for it (no need to chase in a room-sized arena).
  - Staple Burst Gun stays light but weighs 2 (it was briefly going to be medium); Stubby Crayon heavy; Spitball
    Straw weighs 1. Rubber Band stays light at 2 (Alan is fine with it).
  - One weight per gun: the weight you see (capacity) both fills the plane and slows it (the hidden "mass" goes), and
    each point now costs 2 studs/s of speed (was 1.2 per mass); turning and Lift costs unchanged.
  - Cardboard Gunship: weight capacity 8 (was 10), health 220 (was 330); rest unchanged.
  - Toilet Roll Gunship: the midpoint of the Courier Fold and the new Cardboard on every stat: health 180 (was 300),
    speed 87 (76), turning 135 (120), Lift 92 (78), 5 gun slots (6), weight capacity 7 (10).
  - Expected: Toilet Roll ~1.9x and Cardboard ~2.8x a Classic Fold with Pellets in every slot. The bot test flies the
    strongest reasonable tank loadouts (all Pellets, Staples); if the Cardboard still dominates, next lever is its
    health or slots. Toilet Roll (level 8) unlocks before the Courier Fold (12): for the prices step.
  - Breaks to re-make (bots shown to Alan first): Popper Dart (Popper + 2 Staples weighs 7 > 6), Tack Skirmisher (8 >
    6), Staple Tank (6 Staples), Bomber preset (Toilet Roll loses a slot). Striker and the Spitball builds still fit.
    No saved-plane handling: no real players yet.
  - **Built** (same night; Alan OK'd the bot builds first): Pellet Tank (Toilet Roll, Long Point / Delta / Wide, five
    Pellets) replaces the Staple Tank; a Cardboard Tank (same parts, six Pellets) tests the Cardboard; Popper Dart and
    Tack Skirmisher swap their Staples for Pellets; the Bomber keeps Crayon + 2 Pellets. Alan OK'd two side calls: the
    Toilet Roll's mounts are heavy, heavy, medium, light, light, and boosters keep their weight (the Elastic now costs 3
    studs/s). Seen on the numbers: at weight 2 the Staple loses to the free Pellet (13.3 a second for 2 vs 20 for 1), so
    only the Striker preset still carries it.
  - After the test: prices and unlocks from the 12 / 25 folds table, fun vs grind so impatient players buy 2x XP,
    2x Paper or Paper.
- **Prices and level pace** (Alan, end of 2026-11-08; built): grindier, and Paper is the gate, not levels, so
  players who never buy take longer and choose what to save for, Robux (Paper, 2x Paper/XP) is the shortcut, and
  prestige comes sooner. An average player (12 folds) reaches level 50 in ~18 h (each level needs 200 +
  22*(level-1)^1.5 XP, so every level takes longer than the last) and could own everything in ~36 h of Paper. Prices
  scale with level from the old ones (each kept its place among its neighbours): parts at levels 2/5/10/16/24 cost
  700/1,200/2,500/4,900/8,500; Swift Fold 1,600, Toilet Roll 3,500, Courier 6,000, Racing 11,000, Cardboard 18,500;
  Spitball 2,300, Rubber Band 2,100, Paperclip 4,000, Crayon 2,400, Eraser 11,500, Pencil 32,000; boosters
  1,300/4,800/13,000. Item levels unchanged.
  - Alan wants offers timed well to funnel players to Robux ethically. Agreed line for the shop step: offers tied to
    the player's own goal ("1,200 Paper from the Toilet Roll; 2x Paper gets it 3 matches sooner"), capped, never after a
    loss or as fake urgency (players are 9-16; the FTC fined Epic $245M over purchase tricks in 2022).
- **Backlog, must do** (Alan): the results card becomes a report card and looks like one.
- **What players earn, for prices** (Alan): about 6 folds a match is a weak player, 11-13 average (the best veteran
  bots), 25+ a really good one. Price from those, not from the average bot.

- **Free-for-all has no fold cap** (built): it ends only when time runs out, like other games; only goal modes end
  early. Revisit later if it plays badly.

## Why
- Alan: the weaker weapons should be free and the stronger ones paid, thinking about how strong they are alone and
  together. "We kind of want it to be a grind."
- Paperclips, Erasers and Pencils on bots would be too strong.

## Affects
- [Economy and shop](../systems/economy-and-shop.md), [Weapons](../systems/weapons.md), [Bots](../systems/bots.md),
  [Planes and hangar](../systems/planes-and-hangar.md)
