# Personal shop research 2026-11-12

Alan's ask: the shop needs "an algorithm". It should change for the player looking at it: players who have spent and
players who haven't, timers and rotations, **personal discounts** and **offers after a fold** (getting shot down) or a
lost match. This is a broad search; Alan picks what to use. It builds on the
[shop research](SHOP-RESEARCH-2026-11-11.md) (what makes Roblox players buy, the fair line) and doesn't repeat it.
Our prices: [shop prices plan](../plan/SHOP-PRICES-PLAN.md).

Two words used below. **Personalised** means the shop uses what it knows about one player to show them something
different. **Profiling** is the legal word for that: judging a person from data about them (what they bought, how
they play).

## How strong this is
About 15 web searches plus a read of the EU's new law proposal itself (the Digital Fairness Act, published 2026-11-11).
Cost: Opus only, about 100k tokens; no Codex, nothing paid. **Strong:** Roblox's own docs; the EU proposal (read in
full, but it's a proposal: it can still change). **Medium:** two published studies, Sony's and Jam City's price-test
backlash (news reports). **Weak:** most "personalised offers raise revenue X%" numbers come from companies selling
offer tools. I found **no** Roblox numbers for personalised shops, and no proof that rotating shops bring players back
(everyone does it; nobody publishes the data).

## 1. What we can and can't know about a player
- **We know** what they did in our game: what they bought from us (our own receipts in their save), their level,
  their Paper, the part they're saving for, how often they play, whether they just got folded.
- **We don't know** their age, their Robux balance, or what they spend in other games. Roblox doesn't tell us.
- **A price can't change per player on its own.** Each Roblox product has one price. A "personal discount" means a
  second product at the lower price, and the shop picks which one to show.
- **Roblox already varies prices** without us: lower prices by country (regional pricing), 10-20% off for players with
  Roblox Plus (Roblox pays the difference, we get the full price), and Roblox's price tests (random groups see
  different prices). So the shop must always read prices from Roblox, which it already plans to.
  ([regional pricing](https://create.roblox.com/docs/en-us/production/monetization/regional-pricing.md);
  [Roblox Plus](https://create.roblox.com/docs/production/monetization/roblox-plus.md);
  [Roblox-paid discounts, DevForum](https://devforum.roblox.com/t/roblox-provided-discounts-on-in-game-items/4861443);
  [price tests](https://create.roblox.com/docs/production/monetization/price-optimization))
- I found **no Roblox rule against** showing different offers to different players. Roblox's rules on sales: a sale
  must be real (not "on sale" forever at the same price) and not so short that it rushes people.
  ([Roblox monetization rules](https://create.roblox.com/docs/en-us/production/monetization))

## 2. What the evidence says
- **The first purchase is the hard one.** Players who bought once are much more likely to buy again
  ([devtodev, Medium](https://medium.com/expload/why-are-your-players-non-paying-4b5ea69baa93)). Games fight this
  with cheap first offers: starter packs (Roblox: +2-10% revenue,
  [starter pack design](https://create.roblox.com/docs/production/game-design/starter-pack-design)) and **first-buy
  bonuses** (Genshin Impact: the first time you buy each currency pack, you get double;
  [PCGamesN](https://www.pcgamesn.com/genshin-impact/4-1-top-up-reset)).
- **A cheaper offer next to a better one helps the better one sell.** Crazy Panda's test: the small offer sold to 5.4%
  of players, the big one to 3.8% but for more money; making the weak offer better for regular buyers added 3% revenue
  ([GameAnalytics](https://www.gameanalytics.com/blog/personalizing-offers-for-in-app-monetization-crazy-panda)).
- **Free gifts to players about to quit didn't work.** Wooga gave free currency to big spenders the game predicted
  would quit: it changed neither quitting nor spending; *when* they were contacted mattered more than the gift
  ([Game Developer](https://gamedeveloper.com/business/churn-prediction-and-prevention-in-high-value-players)).
- **Making the game kinder can earn more than discounts.** A study of 300,000+ players: lowering difficulty for
  struggling players raised play, return visits *and* spending, short and long term
  ([Ascarza, Netzer and Runge, Columbia](https://business.columbia.edu/sites/default/files-efs/citation_file_upload/Personalized_games.pdf)).
  Our version of this already exists (the aim help, the bots' skill levels).
- **Offers after failing earn a lot in puzzle games.** Candy Crush's "extra moves" after a failed level is its
  bestseller; in one puzzle game the fail offer made 17% of all first purchases
  ([AppMagic](https://appmagic.rocks/blog/fail-offers)). Roblox's own docs suggest a starter-pack pop-up after a lost
  match, and show a game that sells an extra life after you die
  ([contextual purchases](https://create.roblox.com/docs/production/game-design/contextual-purchases)). **But** those
  games sell a way to *undo* the loss (keep your run). We have nothing to undo: a folded plane is back in 4 seconds
  and loses nothing. Here an offer at that moment would only be an advert at a frustrated moment.
- **Secret personal prices backfire when found out.** Sony's PlayStation Store price tests (one player saw 43% off,
  another 70% off the same game) and Jam City's Harry Potter game (different players, different pack prices) both drew
  public anger; Jam City cut prices ([Vice](https://www.vice.com/en/article/playstation-accused-of-charging-some-ps5-users-higher-prices-than-others/);
  [PocketGamer](https://www.pocketgamer.biz/news/68052/jam-city-slashes-harry-potter-hogwarts-mystery-iaps/)).
  Roblox players play with friends and compare screens.
- **Rotating shops:** almost every big game has one (Fortnite's daily shop, Brawl Stars' daily free item and personal
  deals, Grow a Garden's 5-minute restock, the same for everyone, with a paid instant restock). No published numbers on
  whether they bring players back ([Stash on Supercell](https://www.stash.gg/blog/supercell-store);
  [Grow a Garden restock](https://allthings.how/grow-a-garden-2-stock-predictor-how-restock-timing-works/)).

## 3. The law (research, not legal advice)
- **EU Digital Fairness Act, proposed 2026-11-11** (read in the
  [proposal text](https://commission.europa.eu/document/download/0575d59f-554f-4a9e-b54b-e6b717175809_en?filename=Proposal+for+a+Digital+Fairness+Act.pdf)).
  It still has to pass the EU Parliament and Council, then applies 12 months later: realistically 2028 or after.
  - *Article 13:* no personal prices from profiling that are likely to harm a player the trader knows is a minor
    (under 18) or vulnerable. Mostly about *higher* prices; the notes say discounts that benefit the player (like
    student rebates) are fine, unless they push something harmful.
  - *Article 14:* a paid-for currency (one bought with money, **or with another paid currency like Robux**) must show
    the real-money value of what it buys. Our Paper can be bought with Robux, so this could reach Paper prices. For
    games used by minors, paid currencies are off by default until a parent approves.
  - *Article 16:* no "pay-to-progress or pay-to-win" for minors: purchases that are **needed, or shown as needed**,
    to progress. Everything in our game can be earned by playing, so "Unlock now" is a shortcut, not a need, as long as
    the words never say "you need this".
  - *Article 9:* the *timing* and *persistence* of an offer count when judging if it is pushy.
  - Its list of banned dark patterns is in an annex I couldn't read; the press reports ten. Fines up to 6% of
    worldwide turnover were reported ([MMOHuts](https://mmohuts.com/news/eu-digital-fairness-act-proposal-takes-aim-at-loot-boxes-virtual-currency-and-subscriptions)).
- **EU consumer authorities' game currency principles** (March 2025, guidance, not law): show real prices, avoid
  currency layers, don't exploit weak spots, especially children's
  ([Bird & Bird](https://www.twobirds.com/en/insights/2025/european-move-towards-protecting-users-from-harmful-practices-in-video-games-eu-consumer-protection)).
- **UK Children's Code:** profiling of children off by default unless it's clearly in the child's interest; buy
  buttons neutral; time-limited offers need care ([ICO games guidance](https://ico.org.uk/about-the-ico/media-centre/news-and-blogs/2023/02/new-guidance-to-industry-issued-for-game-developers-on-protecting-children)).
- **US FTC:** studied "surveillance pricing" (prices set from personal data) in January 2025; no ruling that it's
  illegal ([McCarter](https://www.mccarter.com/insights/ftc-surveillance-pricing-study-finds-personal-data-is-used-to-set-individualized-consumer-prices-and-generate-higher-profits-for-companies/)).
- **What this means for us:** we can't tell who is a minor, and minors will play. The safe line is: **personalise
  what the shop shows (which part, which pack, which tip), not the price**, and use only what players do in our game.

## 4. Options for Alan
Each is something the shop could do. "My lean" is a suggestion; nothing is built or decided.

**Who you are (spent or not)**
- [ ] **A. Starter pack for first-timers only.** Shown until a player buys anything; gone after (it's already one
  purchase only, 3-day real timer). *Evidence:* Roblox's best-proven offer. *Risk:* low. *My lean:* yes.
- [ ] **B. First-buy bonus on each Paper pack.** The first time you buy each pack you get double Paper (1,500 becomes
  3,000), with a "First buy: double!" sticker. Same price for everyone, the rule is shown. *Evidence:* Genshin-style;
  a cheap first step. *Risk:* low. *My lean:* yes (a new number for your OK: double, or +50%).
- [ ] **C. A "next step" offer after a first buy.** Players who bought once see a middle bundle (for example Paper +
  1 hour 2x Paper). *Evidence:* second buys are easier; a cheaper offer beside a better one helps both. *Risk:* low.
  *My lean:* later, once real sales show what people buy.
- [ ] **D. Thank-you for buyers.** Anyone who bought gets something that isn't power (a sticker on the Hangar, a
  bigger free gift once). *Evidence:* loyalty programmes (vendor claims only). *Risk:* low. *My lean:* maybe.
- [ ] **E. Different prices by spending** (higher for spenders, secret lower ones for non-spenders). *Evidence:* used
  by big mobile games. *Risk:* high: EU Article 13 for minors, Sony/Jam City anger, friends compare screens, spenders
  learn to wait. *My lean:* no.

**What you want (your goal)**
- [ ] **F. Your next part on the Featured shelf.** The shop's top card shows the part you're closest to (or last looked
  at): "Swept Wings: 1,200 more Paper, or Unlock now 49 R$". This is the shop "changing with the player". *Evidence:*
  Roblox's "right item, right time". *Risk:* low (no price change). *My lean:* yes.
- [ ] **G. The right pack on a failed buy.** The pop-up Alan asked for in the Hangar suggests the smallest Paper pack
  that covers the gap, beside "Unlock now". *Risk:* low (the player pressed buy). *My lean:* yes (already planned).

**Timers and rotations**
- [ ] **H. Today's parts.** Three parts from your next few levels in the shop, changing every day at the same time
  for everyone (which three is personal; prices never change). *Evidence:* every big game rotates; no numbers.
  *Risk:* low, if the timer is real. *My lean:* yes, after F.
- [ ] **I. A real weekly sale.** One thing at a real lower price for a week, the same for everyone. Needs a second
  Roblox product per sale item. *Risk:* low if the sale is real and not repeated forever. *My lean:* later.
- [ ] **J. Free daily gift.** Already planned. *My lean:* yes.

**Personal discounts**
- [ ] **K. Comeback gift.** Back after 7+ days away: a free gift, not a sale. *Evidence:* Wooga: gifts didn't stop
  quitting. *Risk:* low. *My lean:* maybe (cheap kindness, don't expect money from it).
- [ ] **L. A secret discount for players who haven't bought.** *Risk:* medium (friends compare; the EU allows discounts
  that help the buyer, but it's still price profiling). B does the same job openly. *My lean:* no, use B.

**After a fold or a lost match**
- [ ] **M. Pop-up offer after a fold or a loss** (Roblox suggests it for starter packs). *Evidence:* big in puzzle
  games, but there the buy undoes the loss; ours undoes nothing. *Risk:* high: our Nov 11 rule, EU Article 9
  (timing), the UK code, players hate it. *My lean:* no (the rule stays).
- [ ] **N. A quiet tip on the fold screen, no price.** "Folded by Mia's Thumbtack Shooter. Unlocks at level 4."
  Information only, no button. It plants a goal that F and G can show later. *Risk:* low. *My lean:* yes.
- [ ] **O. After the match, not after the loss.** Back on the main menu, the Shop button can show a small dot when
  your next part is close. *Risk:* low. *My lean:* maybe.

**Guard rails (whatever is picked)**
- [ ] **P. Calm-down rule.** After 3 buys in a day, stop showing offers that day (the shop still works). *Evidence:*
  none on money; it's a trust builder and matches Roblox's "don't pressure" rules. *My lean:* yes.
- Always: offers use only what players do in our game; prices come from Roblox; every timer is real; the
  [checklist](SHOP-RESEARCH-2026-11-11.md#checklist-before-showing-any-shop-design) runs before any design is shown.

## 5. Risks to keep in mind
- **Paper might count as a paid currency** under the EU proposal (bought with Robux). If it passes as written, Paper
  prices might need a Robux value shown next to them. Not urgent (2028 or later); good to know before the shop grows.
- **Personal prices are the riskiest part** of a personal shop, legally and with players. Personal *content*
  (which part, which tip) gets most of the benefit with little risk.
- **No numbers of our own yet.** Until the shop is live, every "this earns more" above is someone else's game.
  Roblox's price tests need about 60,000 sales a month, so early choices should be simple and easy to change.

## Gaps
The EU proposal's annex (the list of banned dark patterns) wasn't readable here. No videos watched. No Roblox game was
found that shows different offers to spenders and non-spenders openly. The reported FTC August 2026 proposal to make
personal pricing disclosed wasn't confirmed.

Back to [HOME](../HOME.md)
