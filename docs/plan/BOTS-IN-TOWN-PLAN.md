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
Three bots-only matches (ace mix: one Ace per three veterans), before any change: see "Where it stands".

## Where it stands
Plan approved; nothing built.

Back to [HOME](../HOME.md)
