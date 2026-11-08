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
