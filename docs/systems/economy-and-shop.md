# Economy and shop

## What the player sees
You earn **Paper** (money) and **XP** (levels) from points in every match. Paper buys plane parts and weapons; levels unlock them. The shop sells Paper packs and 2x XP / 2x Paper boosts, but real sales are switched off until Alan approves products and prices.

## Where it stands (2026-10-15)
Earning, levels and part purchases work. The shop is a Studio-only practice shop with no Robux. Real purchases are Stage 10 and stay off.

## Economy details
All values here are initial tuning. They are not optimal prices, observed willingness to pay, or a forecast.
The supplied research describes evidence limitations. The current source of numeric truth is `config/`.

## Contribution and payout
Fold 100 points. An eligible fold assist pays its share of all attacker damage in the ten-second window
times 100, rounded to five and clamped to 10-80. Eligibility still requires at least 10% of the victim's
original maximum health. In Airspace only, if both the credited pilot and victim were outside the current
zone, a fold pays 40 and an assist pays 40% of its normal points, rounded to five with a five-point minimum.
Each fold from the third onward in a life earns a separate 25-point streak bonus. Revenge earns 25 once
for folding your most recent folder; the first fold of a round earns 100. These bonuses are never reduced.
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
Withdrawal forfeits final bonuses even after rejoin to the same round, not already-earned valid contribution.

Keep economic subunits internally so fractional base earnings and boosts do not change outcome through
rounding order. Initial precision1000 subunits per currency/XP unit; credit integers with residual retained.
Ordinary UI shows whole units. Event identities prevent duplicate rewards on retries. XP and Paper boost
multipliers are captured independently at earning time. Final bonus events use eligibility at finalization,
not retroactive multiplication of the full ledger.

## Levels and purchases
XP to advance level L: 200+40*(L-1), initial cap50. Maintain cumulative earned XP even at cap for statistics;
no implied future level or refund. Unlock requires both current level and Paper balance, validated together.
Bought Paper never grants levels. An owned weapon permits multiple legal mounted copies. Loadout legality
is validated again at spawn/service; client UI validation alone is insufficient.

The seed contains24 structure choices, six weapon types and three optional boost modules. Starter parts and
pellets are free/owned; other initial prices are in the catalog. Prices and target pacing can be changed in
one place without editing transaction logic. Full refold initially costs120 Paper with a free fresh-plane
alternative. No spending prompt appears on death, firing input, or automatic landing.

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
Three provisional Paper packs (1000/3500/10000 units) and two permanent passes. Pack quantities are delegated
starting values; no actual Robux prices or live product IDs are assigned. The shop's mock state is explicitly
DEVELOPMENT ONLY, cannot prompt real checkout, and cannot write mock purchases into production profiles.

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
Level L needs 200+40*(L-1) XP to reach L+1; initial cap50. Paper prices and minimum levels both apply. No
buying levels. Starting ownership contains baseline structures and pellets; starting wallet/XP is zero.
No daily-streak system, random loot, paid ammunition, premium revives, or unrequested currency.

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
| `src/client/ShopScreen.luau` | Studio-only practice shop screen |

## Tuning numbers
`config/economy.json` (points, Paper and XP per point, bonuses, levels, refold price); `config/commerce.json` (15 shop products; `mode` is "mock", live sales off); prices in `config/catalog.json`.

## Related
- [Points system decision](../decisions/2026-10-14-points-system.md)
- [Modes and scoring](modes-and-scoring.md)
- [Saving](saving.md)
- [Milestones, Stage 10](../plan/MILESTONES.md)

Back to [HOME](../HOME.md)
