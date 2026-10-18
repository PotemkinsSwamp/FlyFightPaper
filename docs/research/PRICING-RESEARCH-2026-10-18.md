# Roblox pricing research (for a free-to-play paper-plane dogfight game, ages ~9-16)

Researched 2026-10-18. Prices in Robux (R$) unless stated. "not found" = I could not find it.

How to read the source tags:
- [API] = live read of Roblox's own public pass list at `https://apis.roblox.com/game-passes/v1/universes/<id>/game-passes?passView=Full&pageSize=100`, fetched 2026-10-18. This is the authoritative current price. Universe IDs used: Blox Fruits 994732206, Pet Sim 99 3317771874, Adopt Me 383310974, Arsenal 111958650, Rivals 6035872082, Jailbreak 245662005, BedWars 2619619496, Doors 2440500124, MM2 66654135, Brookhaven 1686885941, Dress to Impress 5203828273, Steal a Brainrot 7709344486, 99 Nights 7326934954, Blade Ball 4777817887, Wings of Glory 125223108, A-10 Warthog 4551443789, Hostile Skies 686030892. Game names/players confirmed at `https://games.roblox.com/v1/games?universeIds=<ids>`.
- Passes with price null / isForSale false are retired (off sale). I skip them in the tables but note when many exist.
- Developer-product (one-time buy) lists need a login, so they could NOT be read directly. Section 3 is therefore thin and mostly secondary sources.
- Search results were full of spam sites. Anything from a non-Roblox, non-wiki source is marked (secondary).

---------------------------------------------------------------------------------------------------

## 1. Platform basics

- Creator share: creators keep 70% of Robux spent in their own experience (Roblox keeps 30% marketplace fee); 30% of Marketplace (catalog) sales. https://create.roblox.com/docs/en-us/production/earning-on-roblox
- DevEx: 10,000 Robux = $38 (i.e. $0.0038/Robux), fixed. Needs age 13+, 30,000+ earned Robux, follow Community Standards. Same page. (Rate was $0.0035 before 2025-09-05 per secondary sources; some sites still show the old rate, so treat them as stale.) https://create.roblox.com/docs/en-us/production/earning-on-roblox ; secondary: https://rolearn.dev/insights/developer-payouts-billion-dollar-economy
- Higher DevEx tier: from 2026-06-08 DevEx rate is +42% on spend by age-checked US players 18+ in eligible games (R15 avatar games; passes, subscriptions, select in-game items, private servers). Not relevant to a kids game, but shows Roblox pays more for adult spend. https://about.roblox.com/newsroom/2026/04/roblox-fuels-high-fidelity-games-over-18-players-increases-qualifying-devex-rate-42
- Arithmetic (mine, not a source): a developer nets 0.7 x $0.0038 = about $0.00266 per Robux a player spends, i.e. a 399 R$ pass pays the developer about $1.06 in DevEx cash.
- Player buys Robux (US list prices): $4.99 = 400, $9.99 = 800, $19.99 = 1,700, $49.99 = 4,500, $99.99 = 10,000 (and small $0.99 = 80, $1.99 = 160). https://www.creation.dev/learn/how-much-does-robux-cost (secondary, dated 2026-02-17) ; same tiers in https://rowatcher.com/news/robux-prices-bundles-2026-guide (secondary)
- UNCERTAIN: web / gift-card purchases give "up to 25% more Robux" than app-store purchases (e.g. $4.99 = 500, $9.99 = 1,000 on web). Reported since Nov 2024 by press; Roblox's own page not fetched. https://reportify.cn/news/1059124707334557696 (secondary). So a typical kid on mobile pays about $0.0125 per Robux; on web or with a gift card about $0.010.
- UNCERTAIN: Premium members got +10% Robux on purchases; two secondary sources say this bonus was retired 2026-05-30, others still list it. Check Roblox directly. https://rowatcher.com/news/robux-prices-bundles-2026-guide (still lists it)
- Premium Payouts (engagement payouts for Premium playtime) ended: replaced 2025-07-24 by Creator Rewards. Now: 5 R$ per day when an "Active Spender" (spent $9.99+ in last 60 days) plays 10+ min; plus 35% share of the first $100 of a new/returning user's Robux purchases in their first two months (experience needs 100 DAU avg). Paid out after a 60-day hold. https://devforum.roblox.com/t/introducing-creator-rewards-earn-more-by-growing-the-community/3777628
- Managed Pricing (price optimisation + regional pricing, one opt-in; new experiences are enrolled by default): regional prices are 30%-100% of your default price by player's economic location; passes get regional pricing by default; private servers and subscriptions are regionalised automatically. https://create.roblox.com/docs/production/monetization/managed-pricing
  - Roblox's own numbers: regional pricing = +4-10% total Robux spend, +43-52% pass purchases in discounted regions (top 2,500 games, 2025); price-optimisation creators +4% earnings on average. Price tests run about 3 weeks, at least every 90 days, players are not told. https://devforum.roblox.com/t/managed-pricing-one-system-for-better-pricing-and-earnings-growth/4684738 (2026-06-15, Roblox's own claims)
  - Item-level price recommendations need 60,000+ transactions in 30 days. https://devforum.roblox.com/t/price-optimization-now-includes-item-level-price-recommendations/3894427 (2025-08-22)
  - Practical effect for us: hard-coded prices block it; read prices from the API, do not hard-code. https://create.roblox.com/docs/production/monetization/managed-pricing
- Price limits: developer products min 1 R$, max 1 billion. https://create.roblox.com/docs/production/monetization/developer-products . Cross-game pass/product sales disabled from 2026-05-30. https://create.roblox.com/docs/en-us/production/monetization/passes
- A game may have only 15 game passes (2021 claim, may have changed). https://devforum.roblox.com/t/roblox-game-monetization-guide/1235207 . Note the live API shows Bedwars with 80+ pass entries, so the limit is clearly gone or raised.

## 2. Game pass prices in top games ([API] 2026-10-18 unless noted)

| Game (players now) | Pass | Price |
|---|---|---|
| Blox Fruits (205k) | 2x Money (permanent) | 450 |
| | 2x Mastery (permanent XP-like) | 450 |
| | 2x Boss Drops | 350 |
| | Fast Boats | 350 |
| | Dark Blade (weapon) | 1,200 |
| | Fruit Notifier | 2,700 |
| Pet Simulator 99 (64k) | Auto Farm | 175 |
| | VIP | 400 |
| | Lucky / Ultra Lucky | 275 / 800 |
| | Auto Tap | 350 |
| | +15 Pets / +15 Eggs | 375 / 625 |
| | Daycare Slots | 625 |
| | Magic Eggs | 1,200 |
| | Super Shiny Hunter | 1,600 |
| | Super Drops / Double Stars | 2,400 / 2,400 |
| | Huge Hunter | 3,250 |
| Adopt Me (307k) | 1.25x Candy Multiplier | 50 |
| | Premium Plots | 285 |
| | +1 Pet Pen Slot | 295 |
| | VIP | 480 |
| | Cozy Home Lure | 765 |
| | Millionaire Pack | 795 |
| | (18 other passes retired/limited) | off sale |
| Arsenal (4k) | Primus Knight Bundle | 245 |
| | VIP | 395 |
| | Day of the Dead Bundle | 395 |
| | Bugs & Beasts Bundle | 495 |
| | Nexus Bundle | 725 |
| | Premium Battle Pass / seasonal bundles | off sale (retired) |
| Rivals (260k) | Starter Bundle | 59 |
| | RPG Bundle | 95 |
| | Medkit Bundle | 289 |
| | Exogun Bundle | 649 |
| | Standard Weapons Bundle | 849 |
| | Classic Bundle | 865 |
| | Energy Bundle | 975 |
| | Heavy Duty Bundle | 1,425 |
| Jailbreak (9k) | Car Stereo | 200 |
| | Duffel Bag | 345 |
| | VIP Trading | 350 |
| | Crime Boss / SWAT Team | 400 / 400 |
| | Pro Garage | 450 |
| | VIP Lifetime | 750 |
| BedWars (38k) | ~45 kit passes (one per kit) | 399 each |
| | Clan Pass | 399 |
| | VIP Rank | 400 |
| | Ember & Lumen Kit Bundle | 799 |
| | ~30 old battle passes/bundles | off sale |
| Doors (57k) | Kitty Bundle | 299 |
| | Admin Panel | 499 |
| Murder Mystery 2 (953k) | Radio | 475 |
| | Elite | 499 |
| | Bundle: Beach / Mortal (weapon sets) | 3,399 each |
| | ~65 older "GODLY" / bundle passes | off sale (limited-time) |
| Brookhaven RP (542k) | On Demand Fire | 40 |
| | Vehicle Upgrade | 35 |
| | Horse Upgrade | 85 |
| | Penthouse | 180 |
| | Vehicle Speed / Boost / Music | 199 each |
| | Vehicle Customization / Boat Pack / Theme Pack | 299 each |
| | Premium | 320 |
| | Land Unlocked / Disaster Pass | 375 each |
| | Estates / Vehicle Pack / House Pets | 599 each |
| | Prison Landmark | 699 |
| | VIP | 749 |
| Dress to Impress (194k) | Increased Item Limit | 129 |
| | Run Faster | 149 |
| | Outfit sets (Denim, Rich Girl, Moongazer, French Luxury, Sweet Berry, ...) | 279-449 |
| | x2 Money | 399 |
| | VIP Pass | 799 |
| Steal a Brainrot (131k) | 2x Money | 299 |
| | VIP | 375 |
| | Admin Commands | 7,999 |
| 99 Nights in the Forest (286k) | Decorator Pass | 199 |
| Blade Ball (22k) | Trading Sign | 112 |
| | Instant Spin | 120 |
| | VIP / Double Coins | 240 / 240 |

Plane / flight-combat games (closest to ours; much smaller than the above) [API]:

| Game (players now) | Pass | Price |
|---|---|---|
| Wings of Glory dogfight sim (270) | Aerobatic Smoke Colors | 69 |
| | Spitfire Mk Vc (WWII, premium plane) | 489 |
| | Me 262 A-2a | 979 |
| | Lifetime Premium | 1,329 |
| | Horten 229 V3 | 1,329 |
| | F-7PG | 1,609 |
| | Rafale, F-14A, Su-30SM, Su-27SM3, A-10A, F-4 Kai (modern jets) | 2,099 each |
| | F/A-18C, F-16C | 2,449 each |
| A-10 Warthog Airstrike Training (73) | Custom Flares | 59 |
| | Armory (+50% ammo) / FIM-92K launcher | 99 / 99 |
| | Aviation Elite | 149 |
| | F-35B VTOL | 299 |
| | Elite Squadron | 359 |
| | SR-71 / B-21 | 399 / 399 |
| | FB-22A hypersonic missiles / V-22 Osprey | 699 / 699 |
| | UFO / AC-130 / Darkstar | 799 each |
| | Airstrike | 1,499 |
| | All Planes Bundle (SALE) / Ghost of Kiv | 2,999 / 2,999 |
| Hostile Skies jets (94) | Radio | 199 |
| | Champion Member | 399 |

Notes on the table:
- "2x" money/XP passes sit at 299-450 in the big games (Blox Fruits 450, DTI 399, Brainrot 299, Adopt Me candy 1.25x only 50).
- VIP passes sit at 375-800 (Brainrot 375, Arsenal 395, PS99 400, BedWars 400, Jailbreak 750, Brookhaven 749, DTI 799). Adopt Me 480.
- Retired items: MM2, BedWars, Adopt Me, Arsenal each list dozens of off-sale passes, i.e. they sell limited-time items and then pull them.
- The rblxguide.com Blox Fruits list (14 passes, e.g. "Permanent Dough 2,400") does not match Roblox's live list (6 passes), so that site is stale or wrong: https://rblxguide.com/games/blox-fruits/updates/blox-fruits-game-pass-tier-list-2026
- Wiki sites (fandom) block automated fetching; I could not use them.

## 3. Developer products (one-time buys)

Direct lists are login-only, so these are thin and mostly secondary.

Currency packs
- Murder Mystery 2 gems, ~1 gem = 1 R$: 100/100, 400/400, 800/800, 1,700 +300 bonus, 4,500 +1,000 bonus, 10,000 +3,000 bonus, i.e. bonus 0% / 0% / 0% / 17.6% / 22% / 30%. Dated 2022, so may have changed. (secondary) https://sportskeeda.com/roblox-news/how-get-diamonds-roblox-murder-mystery-2-2022 (summary via search; page itself blocked)
- Adopt Me Bucks (undated older guide): 24 R$ = 50 Bucks, 280 R$ = 600, 4,600 R$ = 10,000 Bucks; wiki says Bucks are sometimes discounted during events. (secondary, may be stale) https://commonsensegamer.com/roblox-adopt-me-best-ways-to-make-money/ ; https://adoptme.fandom.com/wiki/Bucks
- Roblox's own Robux packs follow the same shape: more per dollar in big packs (80/$0.99 up to 100/$ at $99.99, plus the Premium bonus). https://rowatcher.com/news/robux-prices-bundles-2026-guide
- Dev advice: make the cheap pack for trial, medium for regulars, big pack with bonus; avoid round tiers (use e.g. 100, 2,000, 7,600, 10,200) so players need the next pack up; mark one pack "best seller". https://devforum.roblox.com/t/roblox-game-monetization-guide/1235207 (2021, old)
- Another dev (2026-03) said: price higher-end items at the standard Robux package amounts (400/800/1,700...) not odd numbers like 439, start cheap and raise gradually. https://devforum.roblox.com/t/help-on-optimizing-monetization/4526613

Timed boosts / consumables
- Steal a Brainrot: 2x Server Luck 15 min = 249 R$; 4x Server Luck 15 min = 499 R$ (one source says 999; may be outdated). (secondary, from search summary of the game wiki) https://stealabrainrot.fandom.com/wiki/Robux_Shop
- SCROOMS: 2x Server Luck 15 min = 19 R$. (secondary) https://allthings.how/every-scrooms-store-item-and-its-robux-price/
- Toilet Tower Defense: "1 Luck Boost" product = 39 R$ (and permanent Lucky pass 199, Double Coins pass 99). (secondary) https://toilet-tower-defense-game.fandom.com/wiki/Gamepasses
- Be a Lucky Block: lucky blocks sold at 49 / 99 / 299 R$. (secondary) https://www.sportskeeda.com/roblox-news/all-lucky-blocks-be-lucky-block-rarity-price-luck
- Grow a Garden gear sold for Robux: Watering Can 39, Basic Sprinkler 79, Advanced Sprinkler 99, Godly Sprinkler 149, Master Sprinkler 199, Grandmaster Sprinkler 279. (secondary, 2025) https://www.sportskeeda.com/roblox-news/grow-garden-gear-guide-all-gears ; https://rblxguide.com/games/grow-a-garden/shops
- Other 15/30/60-minute 2x boost prices in big games: not found.

Starter / first-purchase packs
- Pet Simulator 99 Super Starter Pack = 240 R$ (includes a 2,000 diamond bag). (secondary) https://progameguides.com/roblox/is-the-super-starter-pack-worth-it-in-pet-simulator-99-roblox/ (via search summary)
- Starter packs elsewhere: Rivals "Starter Bundle" = 59 R$ [API]; Adopt Me "Starter Pack" is retired (off sale) [API]; Wings of Glory "German/American Starter Pack" and "Ace Pack" retired [API].
- Dev guidance: "a cheap first purchase is the hardest step"; give small rewards after milestones with rising prices to create repeat buyers. 2018 RDC claim cited there: 95% of Robux buyers purchase more than once. https://devforum.roblox.com/t/roblox-game-monetization-guide/1235207 (2021, old)

## 4. Cosmetics

- Rivals (skin cases, random): Skin Case 1/2/3 = 249 R$ each or 724 for three (about 3% off). Skin Tickets (10 per open) also open them. https://robloxrivals.miraheze.org/wiki/Skins
- Rivals Daily Shop by rarity: Common 299, Rare 449, Legendary 599 R$ (Mythical not listed); rarity tiers Common, Rare, Legendary, Mythical (+ Special/Secret); 4 "Genuine" and 1 "Unique" ultra-rare skins exist. https://robloxrivals.miraheze.org/wiki/Skins ; https://timesaver.gg/blog/roblox-rivals-best-skins-tier-list (secondary). Cases are unavailable in some regions because of random-item laws (see section 9).
- Murder Mystery 2: weapon bundles 3,399 R$; Plasmablade pass 1,699 R$ (older); rarity ladder "GODLY" and "EVO" items sold as limited-time passes then retired. [API] + https://sportskeeda.com/roblox-news/plasmablade-roblox-murder-mystery-2-how-obtain-price-rarity (secondary, old, from search summary)
- Arsenal: themed bundles 245-725 R$ (skins + effects). [API]
- Dress to Impress: outfit sets 249-449 R$ (3-6 pieces each); limited luxury dress 249; discontinued items spike in resale. https://bloxodes.com/wiki/dress-to-impress/robux-items (secondary) + [API]
- Blade Ball: limited weapon packs 1,499 (Starlight Pack) and 2,399 (5-item pack) R$; emotes mostly from crates/merchant with star currency, not direct Robux. (secondary, from search summary) https://www.sportskeeda.com/roblox-news/blade-ball-battle-royale-update-spooky-showdown-haunted-merchant
- Wings of Glory: Aerobatic Smoke Colors = 69 R$ (cheapest cosmetic-like item); plane camo pack was sold at "20% SALE" (retired). [API]
- Trails, kill effects, sprays/stickers, emotes in Arsenal/Rivals/BedWars/Jailbreak: individual Robux prices not found. BedWars premium battle pass includes titles, emotes, kill effects, kit skins (see section 6).
- Jailbreak cosmetics (rims, spoilers, skins): Robux prices not found (wiki ranks them by rarity only).
- Pass-sold cosmetics tend to be bundles at 245-975 R$, with prestige/weapon sets 1,500-3,400 R$.

## 5. Paying to unlock progression early

- Blade Ball battle pass: skip 1 level = 79 R$, 10 levels = 790 R$, whole pass = 2,399 R$ (Haunted pass; Season 9 Cyber pass also 2,399). (secondary, via search summaries) https://www.sportskeeda.com/roblox-news/blade-ball-haunted-battle-pass-all-rewards-premium-pass-price ; https://www.sportskeeda.com/roblox-news/blade-ball-season-9-battle-pass-cyber-pass-rewards-premium-price
- Anime Vanguards battle pass: 10-level skip = 999 R$ (premium 799). (secondary) https://www.sportskeeda.com/roblox-news/anime-vanguards-battlepass-all-rewards-premium-pass-price
- Fat Race season 1: season pass 1,199 R$; "unlock everything now" 1,899 R$. (secondary) https://www.sportskeeda.com/roblox-news/fat-race-season-1-battle-pass-all-rewards-season-pass-price
- Wings of Glory: modern jets sold directly for 2,099-2,449 R$ and old WWII planes 489-1,329 R$, so price scales with aircraft era and power, a direct "buy the plane" shortcut. [API]
- A-10 Warthog: planes/weapons are priced by power: F-35B 299, SR-71/B-21 399, hypersonic/Osprey 699, UFO/AC-130/Darkstar 799, Airstrike 1,499; everything bundled at 2,999. [API]
- BedWars: ~45 kits all at 399 R$ regardless of kit strength (flat price, not scaled). Kits are also unlockable for in-game currency. [API] + https://sportskeeda.com/roblox-news/5-best-gamepasses-roblox-bedwars (secondary)
- Rivals: weapon bundles scale with count/power: 59 / 95 / 289 / 649 / 849 / 865 / 975 / 1,425. [API]
- "Skip the level requirement" for a single item with a Robux price: not found for Arsenal, Jailbreak or Rivals.

## 6. Season / battle passes

- BedWars: premium pass 799 R$ per season (runs 8+ weeks), free track for everyone; premium has titles, emotes, kill effects, lobby gadgets, kit skins and kits; one new kit was free at level 30, others paid. https://robloxbedwars.fandom.com/wiki/Battle_Pass (summary via search) ; https://sportskeeda.com/roblox-news/5-best-gamepasses-roblox-bedwars (secondary)
- Anime Vanguards 799 (skip 10 levels +999); Universal Tower Defense 799 (bundle 4,999; free tier gives half the gems); Anime Adventures 799; Blade Ball 639 (skips 79 / 790 / 2,399); Crossblox S2 199 (+ "Premium Plus" 649); Fat Race 1,199 (full unlock 1,899). (secondary, 2023-2025 articles) https://insider-gaming.com/roblox-universal-tower-defense-season-1-battlepass/ ; sportskeeda links above
- Arsenal and BedWars battle passes are all off sale now (seasonal; the API shows ~25 retired season passes for BedWars). [API]
- Common range from these: 199-799 R$ for premium track, 639-799 most common; free track exists everywhere with smaller rewards.

## 7. Private servers

- Price is set by the developer in Robux per month, renews monthly, owner can cancel; changing the price cancels all active subscriptions. https://create.roblox.com/docs/production/monetization/private-servers ; https://en.help.roblox.com/hc/cs/articles/205345050-Private-VIP-Servers-FAQ (via search summary)
- Private servers are regionalised automatically. https://create.roblox.com/docs/production/monetization/managed-pricing
- Typical prices: not found from a reliable source (the price list needs a logged-in session). Secondary sites say 5-100 R$/month or 100-500 R$/month (conflict). One concrete data point: Tower of Hell = 250 R$/month. https://tower-of-hell.fandom.com/wiki/Private_Servers (fan wiki, from search summary)
- Roblox says private servers cannot be combined with paid access. https://create.roblox.com/docs/production/monetization/private-servers

## 8. Pricing psychology / what developers report

- Price points seen in live data [API]: passes cluster at 299 / 349 / 399 / 449 / 499 / 599 / 749 / 799 (all end in 9 or 5 or 0); 1,200-3,250 for "hunter/luck" passes (PS99, Fruit Notifier 2,700, planes 2,099 / 2,449); 59 / 69 / 95 / 99 at the bottom.
- Tiered ladder: entry 25-75, core 150-500, power 800-1,500, elite 1,500-5,000 is one blog's recommendation (secondary, unsourced). https://www.creation.dev/learn/how-to-price-game-passes-roblox ; (Wings of Glory and A-10 data above match this shape, with 59-149 / 299-799 / 1,499-2,099 / 2,999 bundles.)
- Anchoring: a high-priced item makes the mid ones look cheaper (secondary). Bundles as anchor: A-10 "All Planes Bundle [SALE]" = 2,999 vs single planes 299-799. [API]
- Limited-time / rotation: MM2, BedWars, Arsenal, Adopt Me list dozens of retired passes, so they sell seasonal items and pull them. Rivals has a Daily Shop with rarity-based prices (299 / 449 / 599). Dev advice: limited sales build hype, then return to normal price; remove items that do not sell. https://devforum.roblox.com/t/roblox-game-monetization-guide/1235207 (2021)
- Dev guide (2021): entry items 50-400 R$ ("400 is the upper limit for a logical entry price"), gameplay items 400-6,000, "whale" items above 6,000; avoid high prices for short-lived benefits; dev products with instant benefit are "favourite"; 1-5% of players generate at least 75% of revenue (claim in the guide; old). https://devforum.roblox.com/t/roblox-game-monetization-guide/1235207
- Conversion data: one small dev reported 0.3% conversion and about 5 R$ per paying user (2026-03). https://devforum.roblox.com/t/help-on-optimizing-monetization/4526613 . Roblox itself: Active Spender defined as $9.99+ in 60 days. https://devforum.roblox.com/t/introducing-creator-rewards-earn-more-by-growing-the-community/3777628
- Revenue model (author's estimate, not Roblox data): about $0.003-0.006 per daily user conservative, $0.015-0.025 well monetized; example 400 R$ pass leaves dev 280 R$ ($0.98 at the old rate). https://rowatcher.com/news/devex-math-in-2026-what-you-actually-take-home-per-1-000-players (secondary)
- Roblox ecosystem: top 1,000 creators averaged $1.3M in 2025; median DevEx creator got $1,550; 35,000+ creators in DevEx; 132M daily users in Q1 2026. https://create.roblox.com/docs/en-us/production/earning-on-roblox
- Flat pricing: BedWars charges 399 for every kit regardless of strength; Rivals bundles and plane games scale price with power. [API]
- Promoted passes (Buy Robux promotion page) must be priced above 49 and under 801 R$ while on sale. https://create.roblox.com/docs/en-us/production/monetization/passes

## 9. Rules

- Paid random items (loot boxes, crates, capsules, gacha, keys/spin tickets bought with Robux, luck boosts) must show every possible outcome with the real numerical odds before purchase, as percentages totaling exactly 100%; odds for one-time outcomes must update per user; keys/re-roll tokens and "luck" items must state their numerical effect. Free-earned random rewards need no odds. https://create.roblox.com/docs/production/monetization/paid-random-items
- Per-user restriction: call `PolicyService:GetPolicyInfoForPlayerAsync()`; if `ArePaidRandomItemsRestricted` is true the user must not use paid random generators (directly or via Robux-bought currency). You must give them a remedy: free earnable path, fixed non-random purchase, direct purchase at expected-value price, hide the item, or block with an error. If `IsPaidItemTradingAllowed` is false, no trading of paid-item outcomes. The page names no countries or ages, it says "due to regulations in various countries". Same URL.
- Practical example: Rivals skin cases are unavailable in some regions for this reason. https://robloxrivals.fandom.com/wiki/Skin_Cases (via search summary)
- Younger users: parents can set a monthly spending limit; it resets at the calendar month end, no rollover; high-spend alerts default at $100 / $250 / $500; gift card redemptions are not covered by the limit. https://en.help.roblox.com/hc/articles/4409125091348 (via search summary; page itself returned 403). Secondary: over-limit purchases need parent approval; Under-13 accounts get stricter defaults. https://rowatcher.com/news/roblox-parental-controls-2026-the-complete-setup-guide . No Roblox page found that restricts developer-product pricing by age.
- Refunds: Roblox says it will not refund purchases made inside an experience; contact the developer (often impossible); Robux refunds "very unlikely"; paid-access Robux purchases are not refundable. https://www.pocketgamer.com/roblox/refund/ (2022, may be dated) ; https://create.roblox.com/docs/en-us/production/monetization/paid-access-robux (from search summary). Official Roblox refund page was blocked (403), so verify.
- Receipts: handle purchases with ProcessReceipt and return PurchaseGranted only after granting the item; the receipt Robux amount equals what the user actually paid (matters with price optimisation/regional prices). https://create.roblox.com/docs/production/monetization/developer-products
- Developer products: no per-user purchase history is kept by Roblox, you must store it yourself in data stores. Same URL.
- Terms detail "selling to younger users": not found as a separate rule beyond the above.

---------------------------------------------------------------------------------------------------

## Patterns (my reading of the numbers above, not facts from a source)

1. The dominant pass price is 299-499 R$ (about $3.60-$6 at mobile rates). Permanent 2x money/XP passes sit at 299-450; VIP at 375-800. Few big-game passes are below 100 or above 1,500.
2. Games with direct "buy the thing" progression price it by power and size: A-10 Warthog 59 -> 99 -> 299 -> 399 -> 699 -> 799 -> 1,499, all bundled at 2,999. Wings of Glory old planes 489-1,329, modern jets 2,099-2,449. This is the closest comparable to a plane game, and the small plane games are tiny (73-270 players), so their prices are untested at scale.
3. Cosmetic bundles of several items cluster at 245-975 R$; prestige or weapon sets 1,500-3,400 R$; random cases about 249 R$ with a 3-for-724 discount; rarity-priced shops use roughly 300 / 450 / 600 (about +50% / +33% per tier).
4. Battle passes: premium track 639-799 R$ (about $8-10), free track always there, tier skips sold at roughly 79 R$ per level or about 2,400 to unlock all.
5. Limited-time rotation is everywhere: MM2, BedWars, Arsenal and Adopt Me have dozens of retired passes; items are sold for a window then pulled.
6. Currency packs reward big buyers with a bonus that grows with pack size (MM2: 0% up to 800, then 17.6% / 22% / 30%). Roblox's own Robux packs do the same.
7. Developers say to use standard Robux package sizes (400/800/1,700/4,500/10,000) for high-end prices, start cheaper and raise later, and let Managed Pricing handle regions (30-100% of default price). Hard-coded prices block this.
8. Spend is concentrated: guide claims 1-5% of players generate 75%+ of revenue; one small dev saw 0.3% conversion and about 5 R$ per payer. A kids' game should assume few payers and a long tail of cheap items, with a handful of high-price aspirational items.
9. Random paid items need odds shown and a non-random fallback for restricted players, and Roblox does not refund in-game purchases, so the shop should be clear about what each item does before it is bought (parents' spending limits already exist).
10. Gaps: I could not read developer-product lists (timed boosts, packs) for the big games, and private-server prices are not public without login; both need an in-game look.

---------------------------------------------------------------------------------------------------

## Draft price ladder (Claude, 2026-10-18; waits on Alan, nothing is on sale)

What is sold: [shop plan](../decisions/2026-10-18-shop-plan.md). Our numbers: a normal match pays about 430 Paper;
parts cost 500-5,000 Paper and unlock at levels 2-40 (`config/catalog.json`). Every 100 R$ a player spends pays
the developer about $0.27 (70% share at the DevEx rate above).

Ground rules
1. **Each step builds on the last:** a cheap first buy (49-99), the everyday middle (149-499), a few big items
   (799-2,999) that make the middle look fair.
2. **Buying a part early never costs less than buying its Paper,** or nobody buys Paper packs.
3. **Permanent beats long timed boosts** in value, so the 5-hour boost points people to the pass.
4. **No random paid items** (loot boxes): every buy says exactly what you get.
5. Prices are read from Roblox, not written into the game, so Roblox's regional pricing can lower them in poorer
   countries.

| What | Draft price (R$) | Why |
|---|---|---|
| Starter pack (once per player): 1,500 Paper + 1 trail + 30 min 2x XP | 99 | Cheap first purchase is the hardest step |
| Paper packs: 1,000 / 3,500 / 10,000 | 99 / 299 / 799 | Bonus grows with size (+17%, +25%) |
| 2x XP or 2x Paper for 15 / 30 / 60 / 180 / 300 min | 25 / 45 / 79 / 199 / 299 | 5 h nearly the pass price |
| Permanent 2x XP / 2x Paper | 399 / 449 | Big games: 299-450 |
| Early part unlock, by the part's level: 2-5 / 7-12 / 14-20 / 22-28 / 40 | 79 / 199 / 249 / 349 / 499 | Always above its Paper value |
| Unlock every part now | 2,999 | Anchor; plane games bundle at 2,999 |
| VIP: +5 build slots, name colour, VIP desk spot | 499 | Big games: 375-800 |
| Emotes: free-asset / custom | 49-79 / 149-249 | Alan: free ones cheap |
| Trails: common / rare / legendary | 99 / 199 / 349 | Small items, rarity steps |
| Sticker packs (5 stickers) | 49-99 | Sticker editor itself free |
| Fold effects: common / rare / legendary | 149 / 299 / 449 | Shown to the whole lobby |
| Paper types (graph, newspaper ... foil, holographic) | 149 / 249 / 399 | |
| Whole-plane skins: common / rare / legendary | 299 / 499 / 799 | Rivals shop 299 / 449 / 599 |
| Drawing pass | 349 | One-time, big feature |
| Private server, per month | 100 | Roblox lowers it by region |
| Special planes | 15,000-30,000 Paper | 35-70 matches, or Paper packs |
| Season sticker book (later) | 499-699 | Big games: 639-799 |

To check after launch: which items sell, then change prices (Roblox's own price tests can help once sales are
high enough). Rotating limited-time cosmetics are a later step.
