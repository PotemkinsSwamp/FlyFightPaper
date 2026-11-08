# 2026-11-08: Ace and veteran bot matches (tricks, stealing, switching)

## What Alan did
Gave the go for bots-only free-for-all matches with one Ace per three veterans (`DevBotTier` = `ace_mix`, 3 Aces and
8 veterans, his plane at the desk, sound muted), run by a Haiku helper, about 8 minutes each. He watched the first run
and said the bots looked worse once the Aces came in.

## What he saw
- **First run (3 matches, broken):** all three Aces flew the Crayon Tank (the test handed builds out in a fixed order),
  and the Crayon stand-off braked itself into easy prey: Aces 0-1 folds each, 2% of shots hit. Veterans: 5.4-6.0 folds,
  700-820 points a bot, about the same as before the tricks.
- **Alan's calls:** Aces must fly different builds; the Crayon trick was bad; and bots must not have a range rule:
  "If they can see the targeting circle, they're going to shoot"; far planes are easier to hit. Also: attack your own
  work before testing ([lesson](../workshop/lessons.md)).
- **Fixed run (3 matches, no script errors; live shots peaked at 228 of the 768 cap, none refused):**

| Measure | Match 1 | Match 2 | Match 3 |
|---|---|---|---|
| Veteran folds a bot (avg / top) | 7.1 / 16 | 6.6 / 11 | 7.2 / 13 |
| Veteran points a bot (avg / top) | 958 / 1,870 | 839 / 1,440 | 926 / 1,660 |
| Ace folds (each) | 13, 9, 2 | 14, 14, 0 | 5, 3, 0 |

- **By build, folds a match** (veterans, 6 bots each across the 3 matches; Aces in brackets): Tack Skirmisher
  (turn fight) 9-16, avg 12 (Aces 13, 14, 5); Popper Dart 5-13, avg 9 (Aces 9, 14); Spitball Hunter 3-6, avg 5
  (Aces 2, 3); Crayon Tank (stand-off) 0-5, avg 2, hitting 6-9% of shots (Aces 0, 0, 0).
- Aces are not clearly better than veterans on the same build yet, and die about as often.

## What changed because of it
- Built: each gun aims at its own lead (a bot's second gun had always used the first gun's lead); bots shoot whenever
  the targeting ring would show (1,000 studs); Crayon peels off instead of braking; Aces spread over the builds;
  stealing judged once per target, within 500 studs; spitball-first gives up after 3 s
  ([bots](../systems/bots.md)).
- Open: the Crayon Tank and the Spitball Hunter are weak, and Aces don't beat veterans yet (Alan's calls in
  [decision](../decisions/2026-11-08-unlock-ladder-and-bot-builds.md)).
