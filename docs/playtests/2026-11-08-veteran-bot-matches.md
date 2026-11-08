# 2026-11-08: three all-veteran bot matches (Paper and XP a match)

## What Alan did
Gave the go for three bots-only free-for-all matches as a stand-in for real players: 11 Veteran bots on the new builds
(`DevBotTier` = experienced) and Alan's plane left at the desk (not counted). He watched the first run and saw it was
wrong: the top bot had 3 folds and bots flew into walls.

## What he saw
- **First run (broken):** the new bot brake errored every frame when a bot wasn't chasing, so bots stopped steering; 9 of
  11 crashed in 34 s. Fixed the same day ([lesson](../workshop/lessons.md)); the runs below are after the fix.
- **Three fixed matches, about 8 minutes each, no script errors:**

| Measure | Result |
|---|---|
| Folds a match (all bots) | 67, 69, 69; crashes about 5 a match |
| Folds a bot | average 6.2, median 6, top 11 / 11 / 13 |
| Points a bot | average about 780, top 1,670 |
| Paper a bot (0.363 a point + 90) | average about 370, top about 700 |
| XP a bot (0.68 a point + 120) | average about 650, top about 1,260 |
| Level 15 at the average | about 10 matches |
| Braking | bots held the brake about 7% of the time |

- Alan: veterans are not as good as a decent real player (he gets about 20 folds a match); a free-for-all round also ends
  at 20 folds. So these numbers are an average player at best.

## What changed because of it
- The brake fix and the lesson above.
- Alan asked for an **Ace** tier above Veteran (one Ace per three Veterans in measuring matches), kill-stealing of
  damaged planes and build tricks for every bot with skill setting how well they're done
  ([decision](../decisions/2026-11-08-unlock-ladder-and-bot-builds.md)). Prices wait for the Ace matches and Alan's own.
