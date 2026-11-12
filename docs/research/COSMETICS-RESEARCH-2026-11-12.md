# Cosmetics and playtime rewards research 2026-11-12

Alan's two ideas from 2026-11-12 ([ideas](../plan/IDEAS.md)): **playtime rewards** (little rewards for staying and
playing, on a growing scale: 5 minutes, 10, 30, an hour, 2 hours, shown as a little calendar you fill in) and
**cosmetics** (skins, trails, emotes and other small buys, maybe a whole system for getting them). This page says what
other games do and how it could fit ours. It builds on the [shop research](SHOP-RESEARCH-2026-11-11.md), the
[personal shop research](PERSONAL-SHOP-RESEARCH-2026-11-12.md) and the [shop money plan](../plan/SHOP-MONEY-PLAN.md).

## How strong this is
About 12 web searches plus a read of Roblox's own playtime-rewards package page. Cost: Opus, about 40k tokens, plus a
small page reader (about 20k); nothing paid. **Strong:** Roblox's docs (the rewards package, season pass design).
**Medium:** fan wikis on how Rivals, Arsenal, Jailbreak, Rocket League and War Thunder sell cosmetics (prices change
often). **Weak:** no Roblox sales numbers per kind of cosmetic, and no measured numbers on whether playtime rewards keep
players longer (only developers' opinions).

## 1. What cosmetics other games sell
- **Cosmetics are the top earners** in Roblox's biggest games: Rivals sells weapon skins, Dress to Impress outfits
  ([RoWatcher, 2026](https://rowatcher.com/news/the-10-highest-earning-roblox-games-in-2026-and-what-they-mean-for-the-platform),
  a blog). Emotes are the fastest-growing avatar category ([RoLearn](https://rolearn.dev/trend-reports/roblox-ugc-marketplace-trends-2026)).
- **Rivals:** an earned-and-bought currency (Keys: 49 / 199 / 449 R$ bundles) buys wraps (skins), finishers (what
  happens when you win a fight), emotes and charms. Its skin cases (249 R$) are random, which we don't do
  ([Bloxodes](https://bloxodes.com/wiki/rivals/currencies)).
- **Arsenal:** skins, kill effects, emotes and announcer voices, bought with earned Bucks in a rotating shop or with
  Robux; free codes give cosmetics ([Dexerto](https://www.dexerto.com/roblox/roblox-arsenal-codes-free-skins-bucks-announcers-1818274/)).
- **Jailbreak (vehicles, the closest Roblox match):** body colours, textures, spoilers and rims; seasons with a free
  track and a Season Pass for 349-399 R$ ([Sportskeeda](https://sportskeeda.com/roblox-news/jailbreak-season-22-pass-guide)).
- **Rocket League (cars):** decals, wheels, boost trails, goal explosions, toppers (little hats on the car) and
  antennas, some in a rotating shop ([Twinfinite](https://twinfinite.net/?p=214533)).
- **War Thunder (planes):** camouflages and decals, earned by tasks or bought (about 200 of its premium currency), plus
  player-made skins ([War Thunder wiki](https://wiki.warthunder.com/530-vehicle-customization)).
- **What they share:** what you buy is **seen by other players** in the match (that's why people buy it), most things
  can be earned slowly or bought now, and a rotating shop gives a reason to look every day.

## 2. What that means for a paper plane (ideas in our classroom look)
- **Skins = the paper itself:** lined notebook, graph paper, newspaper, comic page, origami pattern paper, gold foil,
  a test marked "A+" in red pen, homework covered in stickers; crayon doodles on the wings (flames, shark teeth,
  stars).
- **Trails = what follows the plane:** crayon scribble, glitter, rainbow marker, confetti, pencil shavings, bubbles,
  eraser crumbs, little paper hearts.
- **Fold effects** (Rivals' finishers, Arsenal's kill effects, Rocket League's goal explosions): what happens when you
  fold someone: a confetti burst, a rubber stamp "FOLDED!", a gold star sticker, the paper ball bouncing away.
- **Emotes = tricks and poses:** a barrel roll or loop on a key, a wing wiggle at the desk, more winner's moves and
  dances for the [winners' moment](../systems/menus-and-hud.md) (it already has some).
- **Other small buys:** toppers (a tiny party hat, crown or propeller cap on the plane's nose), stickers on the wings,
  a name tag style, decorations for your desk hangar, a "teacher" announcer voice.

## 3. Earning versus buying, and small rewards that lead to big ones
- **The usual mix:** most cosmetics bought with the earned currency (for us, Paper), some Robux-only "premium" ones,
  and bundles. Paper cosmetics also give Paper packs a new reason to sell.
- **Seasons (Roblox's own guide):** a free track for everyone and a paid track with extra missions and better rewards;
  players who upgrade halfway get the paid rewards they already passed
  ([season pass design](https://create.roblox.com/docs/production/game-design/season-pass-design)). Jailbreak charges
  349-399 R$. Needs new cosmetics every season, so it's a later step.
- **Leading up to a big one:** collections. Small rewards are pieces (stickers for a sticker page); finishing the page
  gives the big thing (a skin or trail). It turns lots of small rewards into one goal.
- **Not for us:** random paid boxes (Rivals' cases, Jailbreak's safes); our fair line and Roblox's rules rule them out.

## 4. Playtime rewards
- **Roblox ships a ready package** ([Engagement Rewards](https://create.roblox.com/docs/resources/feature-packages/engagement-rewards)):
  "Time" rewards unlock after so many seconds in the game, and progress **starts at 0 each visit** (leave and you
  lose it); "Daily" rewards unlock after a streak of days. The reward list, timings and icons are settings, and the
  game gives the reward through one function. Its look can be recoloured but not fully swapped, and it keeps its own
  save, separate from ours.
- **Developers' opinions** ([DevForum](https://devforum.roblox.com/t/how-effective-are-playtime-reward/3652644)):
  playtime rewards mostly make a visit longer; some players just leave the game running to collect them. Roblox's
  recommendations now favour games players come back to over time
  ([DevForum, 2026](https://devforum.roblox.com/t/recommended-for-you-algorithm-improvements-that-better-value-long-term-retention/4684575)),
  so counting real play matters more than counting idle minutes.
- **Mix small and big:** quick small rewards early, bigger ones further apart (Alan's 5, 10, 30, 60, 120 minutes
  already does this) ([RoWatcher](https://rowatcher.com/news/reward-pacing-in-roblox-why-generosity-kills-retention), a blog).
- **How it differs from the daily gift row:** the daily gift brings players back each day; playtime rewards keep them
  longer today. They work together.

## 5. Options for Alan
**Playtime rewards**
- [ ] **A. A playtime calendar now,** filled with Paper and boost minutes; cosmetics join it when they exist.
  *My lean:* yes, right after the daily gift.
- [ ] **B. Count only time in a match** (flying, not sitting in a menu), so leaving the game running earns nothing.
  *My lean:* yes.
- [ ] **C. Per day, not per visit:** the calendar fills across the day and starts again at midnight, so a dropped
  connection doesn't lose it (Roblox's package resets every visit). *My lean:* per day.
- [ ] **D. Our own, not Roblox's package:** same design, but on our save and in our art (one save, one look).
  *My lean:* our own; it's small.

**Cosmetics** (each needs a picture and a price note for Alan's OK first)
- [ ] **E. Paper skins first** (6-10): seen by everyone, and the most "paper plane" thing to sell. *My lean:* yes.
- [ ] **F. Trails** (4-6). *My lean:* yes, with the skins.
- [ ] **G. Fold effects** (4). *My lean:* second.
- [ ] **H. Toppers** (tiny hats on the nose). *My lean:* maybe; very Roblox and fun.
- [ ] **I. Tricks and more winner's moves.** *My lean:* later (animation work).
- [ ] **J. How they're paid for:** most with Paper (a reason to buy Paper packs), a few premium ones Robux-only, and
  bundles. *My lean:* yes; exact prices in a note.
- [ ] **K. Sticker collections:** playtime and daily rewards give sticker pieces; a full page gives a skin or trail.
  *My lean:* yes, once the first cosmetics exist.
- [ ] **L. A season pass** (free and paid tracks, about 349 R$). *My lean:* later, when there's a season's worth of
  new cosmetics.

## Gaps
No sales numbers per kind of cosmetic on Roblox; no measured effect of playtime rewards; prices from fan wikis change
often. No look yet at how plane skins would be made (a texture per body, or per part) — that's a question for the
[3D models](../workshop/lessons.md) work before any skin is promised.

Back to [HOME](../HOME.md)
