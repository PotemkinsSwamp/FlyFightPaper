# Bots

## What the player sees
Computer pilots fill empty seats so a match always has up to 12 planes. They fly with the same controls and limits as you, can't see behind them, and come in skill levels (rookie, regular, veteran) with separate personalities and quirks. They never wear an "AI" label. New players face rookies until they graduate.

## Where it stands (2026-10-15)
Passed Alan's vertical-slice gate (2026-10-11: "the bots pass, it is fun"). Every bot plays the Airspace zone, more often the better it is. Bots still to be checked in every mode; rookie graduation check open.
Veterans (Experienced) use the ceiling ducts (2026-10-15): when shot at they sometimes run for a vent within 500
studs (`duct_escape_chance` 40%), and now and then wander through instead of to the next patrol spot
(`duct_patrol_chance` 12%). They fly up a vent, room to room, and dive out another vent, skipping the fan ducts and
the round pipe (`DuctRules.botRuns`), only with over half their Lift and enough to finish. Inside they never dodge.
Tested: 5 minutes of forced runs, no crashes; 3 minutes of normal play, one run.

Bot looks (2026-10-18): each bot wears an outfit a real Roblox player saved, from a list of dressed-up ones
(`avatar_display.bot_look_outfits`, 157 of them, found once by `tools/find_bot_looks.luau`: layered clothing or 4+ accessories and
at least one creator-made item). Searching live is out: Roblox allows 300 avatar lookups a minute. Random accounts were
10x slower to search than saved outfits (most are quitters in Roblox's free starter looks, which made bots look
alike). Same name, same outfit; no two bots on a server share one; old catalog outfit if lookups fail.

## Rules
*Moved word for word from the old rulebook (GAME_SPEC.md, version 1.0). Starting tuning, not tested balance.*

Rookie/Regular/Experienced are internal profiles. No public bot badges, separate roster, fake account profile,
purchase chat, or online-human count. Normal custom scoreboard says Pilots/Eliminations. Developer-only view
can show controller/tier/state. Use coherent fictional names. Avatars: a random real player's current look (Alan 2026-10-18, see
[bot looks](../decisions/2026-10-18-emotes-and-bot-looks.md)), never their name.
No requirement to hide technical reality from platform inspection or falsely advertise all-human competition.

Shared command controller; states for launch, travel, target, pursue/aim/fire, evade, fan-seek, return/service,
objective, and stuck recovery. Classroom generator supplies a connected three-dimensional waypoint graph with
heavy-plane clearance. Local avoidance handles swept lookahead; do not repurpose a ground walking script
without free-flight adaptation. Profiles change reaction time, aim error and planning, never hidden stats.
Use smooth correlated aim error and varied route/personality selection, not per-frame random twitching.

Initial novice mix 85% Rookie/15% Regular, no Experienced. Regular fill 85% Regular/15% Experienced with maximum
one Experienced per team or per FFA. Sample sensibly for small populations. No adaptive difficulty by payer,
age, purchase prompt, current rank, or a desired forced loss. Occasional bot wins are possible; measure
systematic dominance, do not remove real scores or force crashes when bots lead.

A qualifying rookie participation requires 120 active seconds and three real combat/objective events. Five
qualifying matches graduate. Only one qualification per match; substantial participation persists even if
player exits before final results. AFK/menu presence does not qualify. XP boosts/levels are irrelevant to
this counter. Early graduation is disabled in the seed; optional later evidence-based change is not necessary
for first candidate. Persist graduation server-side; old clients cannot claim rookie state.

A human who joins never waits for a bot to die or land: a bot leaves at once (dead, then parked, then one nobody
is fighting, then any; [decision](../decisions/2026-10-17-real-players-join-instantly.md)). A beginner with
`friend_join_matches` qualifying matches may stay in a friend's regular room.

Production matching must isolate rookies from established players. Initial implementation: each combat server
hosts one eligibility class, with a small server-side routing adapter for compatible server/queue selection.
Trusted profile state determines eligibility. Do not trust client-requested class or arbitrary teleport data.
Use platform-supported reserved/compatible server routing after verifying APIs. Studio uses a mock routing
adapter for deterministic tests. Real routing verification is a release gate when a private published
experience is unavailable; do not silently mix veterans into the novice arena to avoid that work.

Human-first, at most twelve active actors, tier-appropriate fill when a spot is vacant. Two humans can start
FFA and four can start teams without waiting for twelve humans; solo can play a normal bot-supported match.
Queue a human in safe menu until a bot dies/reaches an appropriate safe despawn or round boundary. Preserve
damage/reward credit; never delete a nearly killed bot and replace it with an untouched human in midair.
Graduated solo users get regular fill, not weakest beginner opposition. Never award production rewards for
invulnerable debug bots or target-board practice.

## Code
| File | What it does |
|---|---|
| `src/server/BotService.luau` | Bot brain: vision, targets, states, zone play |
| `src/shared/AirRoutes.luau` | Flight routes through the room and pathfinding (also the tutorial guide line) |
| `src/shared/BotBuilds.luau` | Bot planes per skill tier |
| `src/shared/BotNames.luau` | Made-up pilot names in present-day styles (2026-10-18: lowercase handles, stretched names, x-swaps, nonsense words, ALL-CAPS jokes) |
| `src/shared/BotRosterRules.luau` | How many bots and which skill |
| `src/server/AvatarService.luau` | Seated avatars at desks, bot looks (`Service.look`) |
| `src/server/Matchmaking.luau, src/server/MatchmakingAdapter.luau` | Rookie or regular servers, transfers |

## Tuning numbers
`config/gameplay.json` `bots` (mixes, personalities, quirks, eraser skill, objective share); `config/server.json` `routing`.

## Related
- [What bots do first](../decisions/2026-10-07-bot-scope.md)
- [Balanced bot builds](../decisions/2026-10-07-balanced-bot-builds.md)
- [Human-like quirks](../decisions/2026-10-07-human-like-bot-quirks.md)
- [Playtest 2026-10-11](../playtests/2026-10-11.md)
- [Playtest 2026-10-13](../playtests/2026-10-13.md)
- [Playtest 2026-10-14](../playtests/2026-10-14.md)
- [Milestones](../plan/MILESTONES.md)

Back to [HOME](../HOME.md)
