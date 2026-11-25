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

## Where it stands
Steps 1 and 2 built (step 2: a scrape or no nearer a still goal for 2 s sends a bot up 160 studs to open air to plan
again; on a route it looks ahead only to the next point; a wall inside its look-ahead below 270 studs makes it brake
like a player). Step 2's matches running. Next: steps 3 and 4, then Alan's look.

Back to [HOME](../HOME.md)
