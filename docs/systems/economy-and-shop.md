# Economy and shop

## What the player sees
You earn **Paper** (money) and **XP** (levels) from points in every match. Paper buys plane parts and weapons; levels unlock them. The shop sells Paper packs and 2x XP / 2x Paper boosts, but real sales are switched off until Alan approves products and prices.

## Where it stands (2026-11-12)
**Pacing (Alan, 2026-11-08):** Paper is the long wait, levels just open things up. An average player (12 folds a
match, ~660 Paper and ~1,190 XP) reaches level 50 in about 18 hours of play and could own everything (167,400 Paper)
in about 36; for the first 6 hours ~13 unlocked things are always waiting to be saved for. Prices scale up with level
(Pencil 32,000, Cardboard 18,500, first parts 700; table in the
[decision](../decisions/2026-11-08-unlock-ladder-and-bot-builds.md)). Paper packs and Robux part prices were re-scaled to
match (Alan 2026-11-11, [shop prices plan](../plan/SHOP-PRICES-PLAN.md): each part's Robux price comes from its Paper
price; current packs are listed below). The server save rules for the daily gift, starter bundle, Paper jar, first-buy doubles and daily buy count are built with unit
tests (2026-11-12), awaiting Claude's Studio run and client wiring. Other personal shop offers remain in the
[picks](../decisions/2026-11-12-personal-shop-picks.md).
Earning, levels, part purchases and prestige work (prestige checked in Studio Play). The shop is a Roblox-style shop window in our paper look
(2026-11-12, [shop screen plan](../plan/SHOP-SCREEN-PLAN.md)), Studio only and practice buys only until go-live. The real Roblox purchase code is built for the 30 fixed offers and part unlocks
and is switched off: with `mode` "mock" it never talks to Roblox's shop.
- **Receipts:** a paid boost or Paper pack is added together with its receipt ID in one save change, then the game
  waits for that save to reach Roblox before telling Roblox "granted". A failed save means "not yet": Roblox resends
  and the receipt ID stops a second payout. A product switched off after someone paid is still delivered.
- **Passes:** ownership is asked from Roblox on join and after a pass purchase; an error grants nothing.
- **Buying:** the server opens Roblox's buy window (`buyProduct`), only when live, enabled and mapped; never for an
  owned pass, a timed boost the permanent pass already covers, or an ended starter offer. The shop window shows the approved prices from the plan; live, they must come from Roblox's product info.
- **To switch on (Alan's go):** create the products and passes on Roblox, put their IDs and approved prices in
  `config/commerce.json`, set `enabled`, `mode` "live" and `live_sales_authorized` true, then test on a private server.
- **Free gear** (2026-11-08): anything with a Paper price of 0 is yours from its level on (`Catalog:owns`), with
  nothing written to the save, so a prestige takes it away until you level again. Today: the starter parts and the
  first four weapons (Pellet, Popper, Staple, Thumbtack); everything after costs Paper
  ([decision](../decisions/2026-11-08-unlock-ladder-and-bot-builds.md)). Its Hangar card says "Free at level N".
- **Early part unlocks:** one Roblox product per part that costs Paper (29, `part_<id>` in `config/commerce.json`;
  free gear has none), all off; Robux prices in the [shop prices plan](../plan/SHOP-PRICES-PLAN.md). A part you own flies at any level; Paper purchases still need the level. Buying an owned part is refused.
  Prestige takes bought parts back like any other. Still to do with prices: the hangar's "Unlock now" button and its
  "prestige takes this back" warning.
- **Not built yet:** VIP pass (benefits not chosen), private
  servers (Roblox setting, Alan) and their match settings, cosmetics, special planes, drawing pass (paid outside check).

## Economy details
All values here are initial tuning. They are not optimal prices, observed willingness to pay, or a forecast.
The supplied research describes evidence limitations. The current source of numeric truth is `config/`.

## Contribution and payout
Fold 100 points. An eligible fold assist pays its share of all attacker damage in the ten-second window
times 100, rounded to five and clamped to 10-80. Eligibility still requires at least 10% of the victim's
original maximum health. In Airspace only, if both the credited pilot and victim were outside the current
zone, a fold pays 40 and an assist pays 40% of its normal points, rounded to five with a five-point minimum.
Each fold from the third onward in a life earns a separate 25-point streak bonus. Revenge earns 25 once
for folding your most recent folder; the first fold of a round earns 100. A fold by a shot already falling past its
range earns 50 more, shown as FOLD AT A DISTANCE (Alan 2026-11-07). These bonuses are never reduced.
Airborne uncontested zone contribution is 20 per five eligible seconds, capped at 1,920 per match so a full
480-second round can pay throughout. Paper targets pay 50 each with their own 500-point cap per participation.
Small props stay at 2 each with a separate 20-point cap. Team victory score is separate. Human and AI
contributions have identical base rates and multiplier eligibility. No hidden bot-specific cap/discount.

Base Paper = 0.363 x contribution points (previously 0.4). Base XP = 0.680 x contribution points
(previously 0.75). Exact reference preservation would require312/860 Paper and585/860 XP per point.
The payout code only accepts exact milliunit rates, so these rounded rates are the closest supported values.
Completion90 Paper/120 XP;
win40/60; podium Paper30/20/10 and XP45/30/15. Apply bonuses only to eligible real accounts under match rules.
A normal completed bot-supported match is eligible, but developer/practice/debug scenarios are not. Winning
team's top three or FFA podium may contain bots; do not fabricate account wallets or shift ranks for payment.

Completion eligibility: at least120 active seconds AND three real qualifying combat/objective events in this
match. Substantial damage events are counted with anti-spam grouping, not every automatic pellet. A real
fold/fold assist, one meaningful damage engagement, or ten eligible zone seconds can qualify; zone payments
every five seconds do not double qualifying events. Target/prop-only activity
cannot unlock completion. Do not award repeated completions for restarted or rapidly cancelled rounds.
Staying to the end with the120 active seconds but without the three events pays 60 XP and no Paper (Alan 2026-11-07,
`stayed_xp`): a struggling new player never ends a full match with nothing, and a plane left idle still earns nothing.
Withdrawal forfeits final bonuses even after rejoin to the same round, not already-earned valid contribution.

Keep economic subunits internally so fractional base earnings and boosts do not change outcome through
rounding order. Initial precision1000 subunits per currency/XP unit; credit integers with residual retained.
Ordinary UI shows whole units. Event identities prevent duplicate rewards on retries. XP and Paper boost
multipliers are captured independently at earning time. Final bonus events use eligibility at finalization,
not retroactive multiplication of the full ledger.

The free daily gift is a seven-step row: 100 Paper, 150 Paper, 15 minutes of 2x XP, 250 Paper, 300 Paper,
15 minutes of 2x Paper, then 1,000 Paper. One claim per UTC calendar day, with the date supplied by the server.
Missed days keep the next step; step seven wraps to step one. Gift Paper counts as earned Paper but is never
boosted. Timed gifts extend the same online boost balance as a purchase. If a permanent pass already covers
that resource, its gift becomes 250 earned Paper instead. A claim changes the reward and saved row together.

## Levels and purchases
XP to advance level L: 200+40*(L-1), initial cap50. Maintain cumulative earned XP even at cap for statistics;
no implied future level or refund. Unlock requires both current level and Paper balance, validated together.
Bought Paper never grants levels. An owned weapon permits multiple legal mounted copies. Loadout legality
is validated again at spawn/service; client UI validation alone is insufficient.

The seed contains24 structure choices, six weapon types and three optional boost modules. Starter parts and
pellets are free/owned; other initial prices are in the catalog. Prices and target pacing can be changed in
one place without editing transaction logic. Full refold initially costs120 Paper with a free fresh-plane
alternative. No spending prompt appears on death, firing input, or automatic landing.

## Prestige
Alan's idea is in the [shop plan](../decisions/2026-10-18-shop-plan.md); the details below are Claude's. Alan,
2026-10-18: keep them for now, they will change later; he is not set on working on prestige yet, so don't go deeper.
- **When:** at the level cap (50), from the menus only (never in a match). Ranks 1-10; at rank 10 you stay at 50.
- **Takes back:** your level (back to 1, XP 0; XP earned past 50 is not carried over) and every part and weapon
  except the free starter ones, bought ones too. Saved builds keep their names; a build that uses a part you no
  longer own (or can't use at level 1) becomes the starter build.
- **Keeps:** Paper, cosmetics, boosts and passes, settings, statistics, and how many matches you've played (so the
  bots stay at your old difficulty instead of going back to beginner bots).
- **Gives:** a gold star with your rank on your level bar (main menu, desk hangar, results); other players will see
  it with your name once name tags come with the Stage 10 cosmetics. Plus one prestige-only cosmetic per rank (trail,
  sticker, skin...), made with those cosmetics. Levelling speed is the same as before.
- **Warnings:** the Prestige button sits on the main menu's stats card at max level; its confirm sheet lists what
  goes (how many parts) and what stays (your Paper); you hold the button for 2 seconds to confirm. Part purchases with Robux will say "prestige takes this back".
- Can't prestige while a refold is still being paid out.

## Reference economy check
The reference match uses six folds, four assists at an assumed 40% damage share (40 points each), no zone
points, and two paper targets (100 points), with full completion, 50% average winning frequency, ten expected
podium Paper and 15 expected podium XP. That is 860 contribution points, compared with 780 under the old
rules with 20 prop points. Old base earnings were 312 Paper and 585 XP; the supported rates now pay 312.18
Paper and 584.8 XP before final bonuses. Including expected final bonuses gives 432.18 unboosted Paper and
749.8 XP (previously 432 Paper and 750 XP). Streak, revenge and first-fold bonuses are excluded from this
illustration. This is a hypothetical example, not measured telemetry.
The configured complete mechanical collection costs40,900 Paper. At that rate and510 seconds per cycle,
raw currency collection takes about13.4 hours, or about14.8 hours with one120-Paper refold every three matches.
This does not include skill variance, queue time, required XP gates or every user's behavior. Check both
currency and the maximum level gate separately. Low/ordinary/high scenarios must be re-modeled after tests.

The first500-Paper purchase takes two such reference matches; unusually strong play can buy earlier.
A permanent2× modifier does not imply exactly half collection time because XP and Paper gates differ.
Do not extend the free grind solely to justify a costly permanent product. Real pricing remains owner-approved.

## Products
Ten distinct temporary products: XP and earned Paper separately for900,1800,3600,10800,18000 online seconds.
Five Paper packs (1,500 / 5,000 / 7,500 / 15,000 / 40,000), one starter bundle, one Paper jar and two permanent passes. The new
packs, bundle and jar follow the approved [money plan](../plan/SHOP-MONEY-PLAN.md). 2x boosts cost 10/15/25/69/99 R$
(2026-11-12). Eleven **Double this match** products (`match_double_10` ... `match_double_299`, one per price step;
[decision](../decisions/2026-11-12-double-this-match.md), built 2026-11-12): the report card's button pays this match's
Paper and XP once more. `CommerceRules.matchDoublePrice` gives the price (nearest step to 25% off the worth, worth =
2 x Paper / 15 R$; none under 75 Paper). Pressing it (`doubleMatch`, only in the results phase) writes a lock into the
player's save (`doubleLocks`, Alan 2026-11-12: exact on any server): that match's Paper and XP under the price's
product key. The lock pays nothing; Roblox's buy window opens only once the lock is confirmed stored
(`ProfileRuntime:confirmDoubleLock`). The receipt reads the lock in the same save change as its receipt ID, pays
exactly those amounts as bought Paper plus XP (no Paper jar share), deletes the lock and sets the player's
`MatchDoubled` to the match (stops a second press). A receipt with no lock pays what its price was set for (price x 10
Paper and matching XP). One lock per price, so a second unpaid press at the same price replaces the first. Studio's
practice buy runs the same lock-then-pay path at once. The shop's clocks
(daily gift, Today's parts, starter pack) run on the server's time; pictures sit on mint green circles (Alan 2026-11-12, was faded chalk green), except the coloured cards (the passes and Your next part), which have a soft shadow instead (`PaperUI.shadow`, Alan 2026-11-12); the starter pack's items float on a shadow with their words on a dark plate (Alan 2026-11-12). The Paper jar is the last
card in the Paper section: a glass jar that fills to the Paper inside (two drawings, empty and full, the full one cut at
the level), the amount, and 199 R$ from 3,000 (below: "Breaks at 3,000"); "Full!" at 10,000; before full, an "Are you
sure?" note offers Break it now or Keep filling ([jar rules](../decisions/2026-11-12-paper-jar-rules.md)). The report
card's jar piece (Alan's pick, [jar rules](../decisions/2026-11-12-paper-jar-rules.md); Studio only until go-live) shares
a row with Double this match, all inside the card's width (Alan 2026-11-12, third look): on the left the Double panel
(yellow paper, since two greens clashed; sliced so its tacks keep their shape; heading, amounts and time left in big
words, and the "Worth" sticker, pulsing, above the shop's bright green buy button with the price, bouncing); on the right the glass jar (no card),
a little smaller, with a short yellow button under it. Six torn scraps drop in
(the Range's scrap picture, cut with `ImageRectOffset`), the level rises from before the match to now
(`ShopScreen.jarLevel`), a yellow "+165!" (or "Full!") pops out to rest above the jar's right shoulder, turned 30 degrees, just under the level bar, and the
yellow button pulses ("Break the jar!" from 3,000, else "See your jar"; both open the shop on the jar card). It sits on the card frame, not
the page, because a turned page (team rounds) switches off the clipping that draws the level. 3D part pictures are centred as seen, not on their box's middle (the near end looks bigger; `UnlockMoment.view`'s `turn`). Robux prices are the
[shop prices plan](../plan/SHOP-PRICES-PLAN.md)'s, typed in on Roblox when the products are made; no live product IDs
are assigned yet. The shop's mock state is explicitly
DEVELOPMENT ONLY, cannot prompt real checkout, and cannot write mock purchases into production profiles.

The first buy of each Paper pack gives twice its Paper, whether bought through a receipt or the Studio practice
shop. Later buys of that pack give its normal amount. The pack key travels with the grant; the save operation
decides and records its first buy together with the purchased Paper. Receipt replays give nothing extra. This
bonus does not apply to the starter bundle, daily gifts or other purchased Paper.

The starter bundle gives Swept Wings (`wings_1`), 1,500 purchased Paper and 3,600 seconds of 2x XP together in one
save operation. Owning the wings already is fine. An in-flight receipt after a permanent XP upgrade adds dormant
XP time, just like a paid timed boost. The offer starts on the first server load that sees no saved start time and
lasts 259,200 real seconds, including time away. It never restarts. It is offered only before any purchase, with
no receipt history or permanent pass, and only once. An expired or previously used offer cannot open checkout;
a paid receipt still grants the entire bundle after expiry or a racing purchase. The practice shop applies the
same bundle and availability rules, only to Studio mock profiles. It explicitly refuses individual part products.
Practice buys record simulated receipt history in mock profiles so an earlier buy closes this offer there too.

The Paper jar fills with an extra 25% of the Paper actually credited by match contribution and final-bonus
operations, after 2x Paper boosts, capped at 10,000 Paper; ordinary earnings stay unchanged. Gifts, purchases
and refunds never fill it. Breaking it (`paper_jar`, planned 199 R$, disabled and unmapped) grants its whole
Paper as purchased Paper without first-buy doubling, keeping any fractional remainder so it can fill again.
A jar under 3,000 Paper (`min_break_paper`, [Alan 2026-11-12](../decisions/2026-11-12-paper-jar-rules.md)) refuses
checkout and practice buys with `jar_low`; paid receipts still grant and record whatever remains, including zero.
The shop card and its "Are you sure?" note are built (above). [Saved field](saving.md#where-it-stands-2026-11-12).

Every newly granted developer-product receipt and every practice buy adds one to the current UTC day's buy
count. Replaying an operation or receipt adds nothing. A new day's first buy resets the saved count; until then
the displayed count is zero. At three buys, client offer lines and pop-ups should stop; the server still accepts
ordinary checkout and receipts. Pass ownership restoration is not a developer-product receipt and does not add
to this count. Claiming a daily gift does not count as a buy.

Schema 9 adds these saved fields; older saves receive the defaults without losing existing progress:

| Field | Meaning and default |
|---|---|
| `dailyGift` | `{next=1,lastDay=-1}`; next step 1-7 and last claimed UTC day, with -1 meaning never |
| `starterPack` | `{offeredAt=0,bought=false}`; first offer Unix time (0 before first load) and whether the bundle was bought |
| `firstBuys` | Empty map initially; each used Paper pack key maps to `true` |
| `buysToday` | `{day=-1,count=0}` initially; UTC day and number of granted receipts/practice buys that day |
| `doubleLocks` | `{}` initially (schema 11); Double this match locks: product key -> `{matchId, paper, xp}`, removed when its receipt pays |

`ProfileRuntime` refreshes these Player attributes on load, after operations, and on its normal one-second
status update, including UTC midnight and starter expiry. Clients read them; clients cannot set saved rewards.

| Player attribute | Meaning |
|---|---|
| `DailyGiftNext` | Next gift step, 1-7 |
| `DailyGiftReady` | Whether the server's current UTC day is later than the saved last claim |
| `DailyGiftSecondsLeft` | Seconds to the next UTC midnight when claimed; 0 when ready |
| `StarterPackEnds` | Saved offer start plus 259,200 seconds while available; otherwise 0 |
| `PaperJar` | Whole Paper currently held in the jar, rounded down |
| `FirstBuysUsed` | Comma-separated used pack keys, sorted by key; empty string before any pack buy |
| `BuysToday` | Saved buy count when its UTC day is today; otherwise 0 |

The new Hangar action is `claimDailyGift`, with no client date or reward. Existing `buyProduct` and `mockProduct`
accept `starter_pack`, `paper_jar` and both new pack keys. Successful claims report the actual Paper or timed reward. A repeat
claim says "Already claimed today. Come back tomorrow." An unavailable starter offer says "The starter pack has ended."
An empty jar says "Your Paper jar is empty. Play a match to fill it."

Same-resource multipliers cap2×. Timed purchases add duration; five hours is not a balance cap. Permanent
ownership disables new same-resource timed offers. On permanent upgrade retain remaining seconds dormant,
explain no additional multiplier or automatic refund, and resolve already-in-flight receipts. No changing
benefits because a player previously spent more. Native price display must use actual platform product info
when live commerce is eventually authorized [P8]. Do not invent a dollars-per-Robux conversion.

## Offline-pausing timer
Both resources pause offline. Loaded online menus, desk time, spectating and intermission count under the
retained default; loading, transfer gaps and unavailable profile recovery do not. Another Roblox experience
is not this game's online session. Maintain separate durable remaining-second balances, not expiry dates.

Product wording example: “2× XP — 30 online minutes. Doubles earned XP. Pauses when you leave this game;
time in its menus still counts. Additional purchases add time, not a larger multiplier.” Use matching earned-
Paper language. Show calm remaining-time indicators, not pressure to stay online. Purchased Paper is excluded.

## Delivery and operational boundaries
Use official server receipt handling for repeatable developer products and checked ownership for passes [P8].
Add value once, persist before acknowledging, and handle replays/races/outages. Never use purchase-window
closure as proof. Test delayed delivery and a previously active boost expiring during checkout. Failed
storage/entitlement checks keep sales unavailable rather than guessing.

No real spending or public sale activation is authorized by this handoff. Codex implements full mocks and
real adapters, documents actual missing IDs/prices, and continues independent work. The launch checklist
requires separate approved catalog, terms, price display, entitlement tests and applicable platform review.
Model/asset budget remains zero extra; fictional in-game Paper transactions during tests are not real charges.

## Measurement
Track actual actor source internally, verified reward/grant events, error/delivery recovery, first unlock,
match completion, return visits, earned-versus-bought Paper, refold drain, product comprehension and refunds/
complaints when available. Do not count bot activity as human retention or sales. Research informs hypotheses;
conversion and profitability require first-party evidence and actual receipts/costs.

## Rules (progression and purchases)
*Moved word for word from the old rulebook (GAME_SPEC.md section 8).*

Use `economy.json` and the economy details above. Contribution pays exactly the same for AI/humans.
Level L needs 200 + floor(22*(L-1)^1.5) XP to reach L+1 (a curve; was 200+40*(L-1)); cap 50. Paper prices and minimum levels both apply. No
buying levels. Starting ownership contains baseline structures and pellets; starting wallet/XP is zero.
The daily gift row above is not a streak: missed days never reset it. No random loot, paid ammunition, premium revives, or unrequested currency.

Two independent remaining-seconds boost balances. Consume trusted loaded online intervals, not calendar
elapsed time; pause offline/loading/transfer/unavailable recovery. Menu/desk/intermission counts under the
retained default, disclosed before purchase. At an earning event determine XP/Paper multiplier independently.
No retroactive doubling earlier actions after buying at match end. Add duration once per verified grant;
cap multiplier at2, not accumulated seconds at5h. Permanent pass stops that balance consumption and preserves
it dormant; disable new redundant temporary offers and safely settle in-flight receipts.

Actual developer-product grants require verified server receipts and durable idempotency [P8]. Pass ownership
uses authoritative checks; no optimistic UI flag grants permanent power. Failed profile load never creates
writable defaults over an existing account. Storage failures require retries/backoff and protected sessions
rather than silent loss [P9]. Final commerce remains disabled until approved IDs/prices, reliable delivery,
and applicable permissions are verified. Mock UI is unambiguously development-only.

## Code
| File | What it does |
|---|---|
| `src/shared/EconomyRules.luau` | Points to Paper and XP, bonuses, levels, purchases |
| `src/shared/CommerceRules.luau` | Shop products and 2x passes |
| `src/shared/BoostClock.luau` | 2x boost timers (count only while online) |
| `src/server/HangarService.luau` | Buying parts, the practice shop |
| `src/client/ShopScreen.luau` | The shop window (Studio only until go-live): built to the approved concept's measurements, pictures named in `UIAssets.shop`, animations; the starter pack's saved timer, the free gift card with its 7-day row (Claim, ticks, time to the next), Paper packs biggest first with "First buy 2x!", pictures growing with the amount ([money plan](../plan/SHOP-MONEY-PLAN.md); checked in Play 2026-11-12; the tab buttons scroll too far, see STATE); gift buttons are previews ([shop screen plan](../plan/SHOP-SCREEN-PLAN.md)) |
| `src/server/CommerceService.luau` | Real Roblox purchases: receipts, pass checks, buy prompts (off) |
| `tests/unit/CommerceService.spec.luau` | Receipts paid once, saved before granted; passes; prompts; late starter bundles |
| `tests/unit/ShopSave.spec.luau` | Gift rows, starter timing and bundles, first-buy doubles, buy counts, schema migration and Player attributes |
| `tests/unit/MockShop.spec.luau` | Practice-only guards, typed grants and refusal of individual part products |

## Tuning numbers
`config/economy.json` (points, Paper and XP per point, bonuses, levels, refold price, daily gifts, starter bundle and jar); `config/commerce.json` (30 fixed offers plus part unlocks; `mode` is "mock", live sales off); prices in `config/catalog.json`.

## Related
- [Points system decision](../decisions/2026-10-14-points-system.md)
- [Modes and scoring](modes-and-scoring.md)
- [Saving](saving.md)
- [Milestones, Stage 10](../plan/MILESTONES.md)

Back to [HOME](../HOME.md)
