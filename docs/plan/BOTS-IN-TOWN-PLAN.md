# Bots in the town plan

**Status:** approved by Alan 2026-11-25 ("go on both": the plan and the skill numbers, plus his go for bot matches
and Claude's own Play runs for this work). What he asked for and the numbers:
[decision](../decisions/2026-11-25-bots-use-the-town.md). Nothing built yet; the "before" matches are below.

## Steps
1. **A map of the town's open air and faster route finding.** Today's routes (`src/shared/AirRoutes.luau`) are a
   7 x 5 grid of points at 145, 310 and 495 studs, joined where a ball of 18 studs passes, searched by scanning every
   open point (fine for about 100 points, too slow for more). Add low points over the town mat (around 40 and 90
   studs up, about 70 apart, only where a plane fits) and a point in front of, inside and behind every hole a plane
   fits through, found by casting rays across each building (a ray that crosses the building's box without touching
   it, with touching rays around it, is a hole). Join points the same way; search with a heap. Built while the server
   starts, spread over frames so no frame stalls; bots use today's routes until it is ready. Lower the floor push
   (today under 75 studs) to just above the street lamps and trees inside the town.
2. **No crashing, no getting stuck.** On a route through the town, look ahead only as far as the next point (the
   long look-ahead swerves off a street that is clear along the route); ease off speed where the way is tight; if
   a bot scrapes a wall or gets no nearer its goal for about 2 seconds, climb to open air and plan again.
3. **Using the town in a fight.** A chased bot rolls (the table in the decision) to head for the nearest hole or
   street that breaks the chaser's line of sight; a bot whose target passes through a hole rolls to follow it
   through, otherwise goes round or over. Airspace bots spread through the zone's whole height.
4. **Varied ways.** Each bot adds its own small random cost to route legs (fixed per bot), some prefer low ways,
   some high, so they do not all follow one path.

Pure logic (the point map's search, hole finding from ray results) goes to Codex with unit tests; the Roblox side,
the behaviour and the checks are Claude's.

## How it is checked
`tools/run_bot_matches.py` (bots only, muted, in the background) after each step, against the "before" numbers:
crashes, wall scrapes, time over the town low (under 100 studs) / mid (100-270) / high, and later holes flown
through. Server time per frame for the bots (`botMs`) must stay about where it is. Then Alan's look in Play with a
veteran chasing him through the streets.

## Before (2026-11-25)
Three bots-only free-for-all matches (`python tools/run_bot_matches.py 3`: eleven bots, ace mix = one Ace per three
veterans, 466 s each), before any change. Time over the town is the share of seconds a flying bot spent over the
town mat.

| Match | Bot deaths | Crashes | Wall scrapes | Low (under 100) | Mid (100-270) | High | botMs |
|---|---|---|---|---|---|---|---|
| 1 | 101 | 0 | 1 | 0% | 41% | 57% | 0.48 |
| 2 | 105 | 4 | 2 | 0% | 41% | 57% | 0.39 |
| 3 | 100 | 3 | 1 | 0% | 43% | 55% | 0.38 |

So today: about 2 crashes and 1 scrape a match, and bots spend almost no time low among the buildings (a few
seconds a bot a match). The after numbers must keep crashes about this low while "low" goes up. No script errors of
ours (one Roblox chat script message).

## After step 1 (2026-11-25)
The town map: low points at 60 and 95 studs, 70 apart (street lamps top out at 37.5 studs and trees at 42 inside the
town; numbers in `config/gameplay.json` `world.town_routes`), and points before, inside and after 20 holes found by the
rays (under the gateway, the south station, the pencil-case bridge and the stilt tower; through the block arch, the
bell tower's arches and belfry, the tape roll, the porthole, the ring binder, the ceiling rings and the cardboard
tubes). 913 points; the server builds them in about 5 s while the game loads. Search with a heap (Codex,
`src/shared/AirMapRules.luau`, tested). Floor push over the town 45 studs. Same three matches as before:

| Match | Bot deaths | Crashes | Wall scrapes | Low (under 100) | Mid (100-270) | High | botMs (end) | botMs each second |
|---|---|---|---|---|---|---|---|---|
| 1 | 105 | 6 | 5 | 4% | 50% | 45% | 0.38 | 0.64 avg, 7 peak |
| 2 | 102 | 10 | 2 | 4% | 49% | 46% | 0.32 | 0.78 avg, 55 peak |
| 3 | 96 | 9 | 3 | 5% | 48% | 46% | 0.41 | 0.85 avg, 17 peak |

Low time came (15-30 s a bot a match, from about none), but crashes tripled (8 a match against 2), so step 1's "crashes
about as rare" is not met; step 2 is the crash fix. Bots spend only 8% of their flying time cruising (patrol, where
routes go low); chasing (28%) and dodging (18%) stay where the fight is, so more low time needs step 3. Shorter
matches the same day: regulars (255 s) 1 crash, 7% low; rookies (252 s) 5 crashes, 5% low. The frame spikes came from
checking every point of the map for one in reach; capped at 12 checks a plan with step 2.

## After step 2 (2026-11-25)
A scrape, or no nearer a still goal for 2 s, sends a bot up 160 studs to open air to plan again; on a route it looks
ahead only to the next point; a wall inside its look-ahead below 270 studs makes it brake like a player. The route
checks per plan are capped at 12 (the frame spikes). The match tool now logs where each crashing bot was a second
before.

| Match | Bot deaths | Crashes | Wall scrapes | Low | Mid | High | botMs (end) | botMs each second |
|---|---|---|---|---|---|---|---|---|
| 1 | 106 | 5 | 0 | 6% | 48% | 44% | 0.46 | 0.64 avg, 5 peak |
| 2 | 85 | 3 | 1 | 6% | 46% | 46% | 0.41 | 0.62 avg, 8 peak |
| 3 | 102 | 3 | 0 | 5% | 51% | 43% | 0.30 | 0.62 avg, 4 peak |

Six of the eleven crashes were bots going to a fan for Lift (out of Lift, gliding down past the things hanging from
the ceiling; likely as before, no "before" crash spots to compare); two low ones were monorail pillars and a bot at 33
studs that the cruising wobble had aimed under the floor (fixed in step 3).

## After step 3 (2026-11-25)
A bot shot at rolls `town_dive_chance` once per attacker to fly somewhere low its attacker can't see (instead of a
dodge); a bot whose target passes within 45 studs of a hole's middle rolls `hole_follow_chance` once per hole to
follow it through (a hole run, flown like a duct run), otherwise its routes and straight lines skip that hole; Airspace
bots spread through 85% of the zone's height above the town's floor. Alan's words for the dive (most times, often,
sometimes, never) are read as 75%, 50%, 20%, 0.

| Match | Bot deaths | Crashes | Wall scrapes | Low | Mid | High | botMs (end) | botMs each second |
|---|---|---|---|---|---|---|---|---|
| 1 | 91 | 8 | 2 | 8% | 52% | 39% | 0.41 | 0.68 avg, 10 peak |
| 2 | 88 | 2 | 0 | 8% | 54% | 37% | 0.30 | 0.65 avg, 6 peak |
| 3 | 92 | 7 | 2 | 10% | 57% | 32% | 0.33 | 0.61 avg, 4 peak |

Bots hid 1,556 bot-seconds and flew 100 through holes over the three matches; dodging fell by half; deaths about 10%
fewer. Crashes rose again, both causes mine: bots dove steeply at the low routes and pulled up too late (one at 22
studs), and the stuck rule fired on bots circling near their goal (633 s "unstuck", from 159), climbing them out of the
town. Fixed with step 4: the lower a bot, the shallower its dive (straight down 200 studs over the floor, about 12
degrees at it); circling within 150 studs of the goal is not stuck; a hide spot counts as reached within 100 studs.

## After step 4 and what the crashes are (2026-11-25)
Step 4: each bot adds its own fixed 0-30% cost to each route leg and likes low ways or high ones by up to 35%, and
cruises low or high by that liking. Three matches: crashes 5, 5, 7; low 8%, 11%, 9%; botMs 0.56-0.65 avg, peaks 4-6 ms.

"Crashes" in these tables are every collision death, and **rams count** (a plane flown into another; the weaker one
dies). From 2026-11-25 the match tool tells them apart (a crash with no wall touch in the last 2.5 s is a ram) and
names each crashing bot's skill, style and plane. Five diagnostic matches (Alan asked whether skill, personality or
habits cause them):

| Bots | Crashes | Rams | Into the town |
|---|---|---|---|
| Aces and veterans, 3 matches | 19 | 15 | 4: monorail beam, monorail pillar twice, gateway towers |
| Regulars, 1 match | 6 | 5 | 1: book-stack lookout |
| Rookies, 1 match | 2 | 0 | 2: a ceiling ring, a monorail pillar |

Rams are the rammer quirk at work (it flies into a weaker plane on purpose); the rammed are mostly hurt bots flying to
repair or to a fan. Plane and personality differences in crash counts (Cardboard Tank and objective bots highest)
follow who gets rammed, not who hits walls. Real crashes into the town: about 1.3 a match for aces and veterans, mostly
the thin monorail pillars and beam; rookies only hit the town (worse pilots by design). The "before" 2.3 a match mixed
rams and walls and cannot be split now.

## Where it stands
Steps 1-4 built and measured; crashes into the town about 1.3 a match (rams are by design). Dev panel **ace bots** makes
every bot a veteran or an ace for Alan's look. Next: Alan's look in Play; then, if he wants, the monorail pillars (the
most hit part).

Back to [HOME](../HOME.md)
