# Shop research 2026-11-11

What makes Roblox players buy, what they like and hate, the rules for kids, and how to make a shop tempting in our
classroom style. Asked for by Alan before any shop design ("research first"). Prices themselves:
[pricing research](PRICING-RESEARCH-2026-10-18.md) and the [shop prices plan](../plan/SHOP-PRICES-PLAN.md).

## How strong this is
Five researchers (Claude Sonnet, about 720k tokens) read about 100 pages. **Strong:** Roblox's own docs and numbers
(starter packs, regional pricing, price tests, subscriptions, shop design rules) and the rules for kids (Roblox,
FTC, UK CMA, EU CPC). **Weak:** YouTube, TikTok, Instagram and Dribbble pages would not open for them, so video advice
is from titles and snippets only; top-game shop layouts are from fan wikis and guide sites; most "conversion
benchmarks" online come from blogs with no data. Craft-game shop teardowns (Paper Mario, Tearaway, Toca Boca) were
not found. Treat the look-and-feel numbers as starting points to tune in Play.

## 1. What makes people buy (best evidence)
- **Starter pack: the one offer Roblox itself pushes.** Roblox reports a 2-10% revenue gain. Their recipe: shown from
  the first spawn, one purchase only, 2-5 items, 99-299 R$, a big discount, a real 1-3 day timer with a HUD button.
  [starter pack design](https://create.roblox.com/docs/production/game-design/starter-pack-design)
- **The first purchase is the hard one;** a cheap entry item, then steps up. Show offers when a player wants them
  (short of Paper at a part, after a level-up), not at login. ([DevForum guide](https://devforum.roblox.com/t/roblox-game-monetization-guide/1235207), old; [Roblox analyst, 2025-01](https://devforum.roblox.com/t/super-low-payer-conversion-rate/3411035))
- **Regional pricing** lifted the share of players who buy by a median 26% in Roblox's tests (pass buys +43-52% in
  cheaper regions). It needs prices read from Roblox, not written into the game (we already do this).
  ([Roblox, 2025-04](https://about.roblox.com/newsroom/2025/04/roblox-launches-regional-pricing-for-in-experience-items); [DevForum, 2026-06](https://devforum.roblox.com/t/managed-pricing-one-system-for-better-pricing-and-earnings-growth/4684738))
- **Roblox's price tests** give +4% on average but need about 60,000 sales a month: not for us at launch.
- **Subscriptions** (monthly VIP) added about 7% spend on average; a later step, once there's steady new content.
  ([DevForum, 2024-05](https://devforum.roblox.com/t/increased-payouts-for-subscriptions-within-experiences/2963619))
- **Roblox's shop design rules:** easy to find, icon in the game's art, quick in and out, say what each thing does,
  rotate a few items so it feels fresh, don't overuse "limited" or "exclusive".
  ([monetization foundations](https://create.roblox.com/docs/production/game-design/monetization-foundations))
- **Roblox's UI rules for shops:** the best-value offer drawn biggest, one loud colour for the buy button, prices you
  can't afford shown differently, name + picture + price on every card, feedback (a change and a sound) on every press.
  ([UI/UX design](https://create.roblox.com/docs/en-us/production/game-design/ui-ux-design))

## 2. What players like and hate (top games: Pet Simulator 99, Grow a Garden, Rivals, Blox Fruits, Steal a Brainrot, Dress to Impress, 99 Nights...)
- **Liked:** clear multipliers with a visible effect (2x Money, 2x Mastery are the "worth it" buys), cosmetics that
  don't make anyone fall behind (Rivals, Arsenal trails), buying a specific item instead of a random case, a season
  pass that pays back if you finish it.
- **Hated:** pay-to-win luck or power, random eggs and crates, free things turned Robux-only later, pay-to-harass
  (Grow a Garden's pay-to-steal), pop-ups for basics, passes that barely do anything or have vague names, prices
  hidden behind layered currencies.
- **What nearly all big games do:** sell time-savers, two currencies (earned + Robux), scarcity timers, visible
  status (locked VIP rooms, rare items others can see).
- **Ideas players and writers praise:** name things like identities, not features ("Ace" beats "2x XP Gamepass";
  one blog, untested); show what you get right on the card.

## 3. The rules and the fair line (kids)
Research only, not legal advice; most law was read through law-firm summaries.
- **Must not:** fake scarcity or timers that reset; "sales" that aren't lower than normal; pushy words to minors
  (Roblox's own example: "See Price", not "LAST CHANCE"); random paid items without odds (we have none); urging kids
  to buy or get others to buy; one-press charges or easy accidental buys (the FTC's $245M Epic order, 2022); working
  around Roblox's parental spending limits.
  ([Roblox monetization guidelines](https://create.roblox.com/docs/production/monetization); [EU CPC action vs 9 game companies, 2026-10-15](https://www.lewissilkin.com/insights/2026/10/15/eu-consumer-protection-network-launches-action-involving-nine-video-games-compani-102o5do))
- **Should not (seen as manipulative):** currency layers that hide the real cost (children find conversions "scary"
  and overspend: [CHI 2025 study](https://deceptive.design/articles/theyre-scamming-me-how-children-experience-and-conceptualize-harm-in-game-monetization));
  making a wait annoying on purpose so "skip" looks good; offers after a loss or a death; guilt wording on "no"
  buttons; showing who owns what as pressure; ads for packs on the results screen or lobby.
- **Trust builders:** price and contents on the same screen; everything earnable by play, and saying so; calm words;
  offers tied to a goal the player already has; working smoothly with parents' limits.
- **Note:** Roblox's starter-pack page suggests a pop-up after a lost match. That clashes with our "never after a
  loss" rule; the rule stays.

### Checklist before showing any shop design
1. Every pack, boost and pass shows its Robux price and exactly what it gives on the same card.
2. Only one step from Robux to the thing (no forced chains), and pack sizes don't leave nagging leftovers.
3. "Unlock now" shows its Robux price next to the free way (level and Paper).
4. Any timer is real time and never resets; any sale is a real lower price.
5. No offer on the results screen, after a death or after a loss; offers only for a goal the player picked.
6. A daily cap on offers; "Not now" stays dismissed; calm, guilt-free wording.
7. No random rewards; no showing other players' buys as pressure.
8. Every buy goes through Roblox's normal confirm; no buy button where a menu tap could hit it.
9. The whole game is reachable without buying, and the shop says so.

## 4. Making it tempting (look and feel)
- **One thing moves at a time.** The featured card wiggles (2-3 degrees, 0.4 s) every 3-5 s; a shine sweeps across
  it every 4-6 s; everything else sits still, so the eye goes there.
- **Hover:** card grows to about 1.05 in 0.12 s, tilts a little, its price tag swings. **Press:** dips to 0.96, springs
  back past 1.04 to 1.0 in about 0.18 s, with a paper tap sound. **Open:** the shop pops in with a springy scale.
- **Buying:** the card lifts, a gold star or "SOLD!" stamp slams down, 20-40 paper confetti bits, a tiny shake;
  under 1.2 s. **Paper arriving:** 5-12 little paper bits fly to your Paper counter, which bumps and counts up.
- **Can't afford yet:** never a red angry shake; a grey tag with "1,200 more Paper" and a small progress strip (the
  goal-gradient effect: people push harder the closer a goal looks). A press gives a soft, short side-to-side nudge.
- **Show it in use:** the part spins on its card or the plane flies a slow loop; the weapon fires once on hover.
- **Stop-motion feel:** idle wiggles that hop between 2-3 poses (like flipped paper cut-outs) read as hand-made, not
  glossy. Native drop shadows (UIShadow, 2026) give paper depth.
- Sources: Roblox UI docs above; [DevForum Ultimate UI Design Guide](https://devforum.roblox.com/t/the-ultimate-ui-design-guide/1236916);
  [Clean UI thread](https://devforum.roblox.com/t/how-to-make-extremely-clean-ui-while-keeping-good-ux/2438099);
  "Juice it or lose it" ([talk](https://www.youtube.com/watch?v=Fy0aCDmgnxg)); car-wash stamp-card study (Nunes and
  Dreze 2006) for the progress strip. Videos worth watching: [UI animations](https://www.youtube.com/watch?v=8pJGBz-J75w),
  [custom shop UI](https://www.youtube.com/watch?v=F8w-vTQ71fE).

## 5. In our classroom style (ideas for Alan to pick from)
- **What the shop is:** best fit is the **school store window / counter** (a place with a "featured" poster, price tags
  and a kid behind the counter); the **book fair rack** is the strongest nostalgia (posters, rows of shiny supplies);
  the **prize box** fits a free daily gift, not the paid shop; a **sticker album** fits "what you own and what's
  next" (owned = full-colour sticker, not yet = pencil sketch in a dotted outline).
- **Tricks in our materials:** price tags on string written in crayon; crooked sticker badges ("NEW!", gold star,
  "Teacher's pick") instead of glossy ribbons; one bigger, tilted "this week" poster; items on cut-out paper with
  shadows; things popping out of a cardboard box when bought; a hand-drawn arrow pointing at the featured item.
- **Where it shows:** a Shop button on the main menu and Hangar (art to match), never mid-flight; "1,200 more Paper"
  hints on the part's own card in the Hangar; Roblox's own top-left Shop button stays off unless it fits.

## Gaps
No video watched; no measured numbers for badges, red dots or confetti; no craft-game shop teardowns; no first-purchase
rate from Roblox. A next step could be opening the best video links in the browser and making a picture board.

Back to [HOME](../HOME.md)
