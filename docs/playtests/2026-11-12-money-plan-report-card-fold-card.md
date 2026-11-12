# 2026-11-12: the money plan in Play (report card 2x, fold card, shop rows, tape-roll tower)

## What Alan did
Played several free-for-all matches in Studio (Play shared with Claude's read-only checks), opened the shop, got folded
by parts he doesn't own, and practice-bought 2x Paper from the report card.

## What he saw
- **Report card 2x Paper note:** never showed in his first two matches. Cause (found with a once-a-match check that
  printed to Studio's Output): in a free-for-all "your page" was the hidden page 2, so the note and the level bar hid
  with it. Fixed. He then wanted it **on the card or taped under it**, plainly clickable, up with the card; built as a
  big green button. He pressed it and couldn't tell what happened: it now says "Thanks! 2x Paper is on for 1 hour".
  The next match paid double (200 points, 145 Paper = 200 x 0.363 x 2; XP stayed 1x); the card now says "(2x)".
- **2x boosts are poor value** (his point, confirmed with numbers): a 15-minute boost covers about 1.5 matches and the
  clock runs in menus too; boosts pay 5-10 Paper per Robux against 15-20 for Paper packs. His fix: **Double this
  match** on the report card ([decision](../decisions/2026-11-12-double-this-match.md)).
- **"Folded by" line on the top note:** in the wrong place. He designed a card instead: the part, the level it unlocks
  at, its Paper price, Paper buy first, else a wait, and Robux; on the fold screen and at the desk; once per part a
  session. First version: Buy button off to the right, unreadable dark "Wait" label, covered the "folded by" note, and
  the part didn't turn. Second version: "that looks a lot better"; the white circle behind the part looked wrong on the
  rainbow card. He asked for a design and colour theory skill (made in its own session, `.claude/skills/design-theory`)
  and picked **no circle, a soft shadow**, with the part turning.
- **Shop:** white paper behind pictures hides white parts and the white Paper icons. Brown kraft circles "looked very
  bad"; midnight indigo sank the dark pieces; he picked **faded chalk green** ([decision](../decisions/2026-11-12-fold-card-and-shop-mats.md)).
  Today's parts timer drew over the first card with a wide gap ("New parts in ... in 57m"): now one line on dark paper
  under the heading, on the server's clock.
- **Tape-roll tower:** folded every time he flew into the roll's hole. The left half's collision shape filled the
  hole; replaced with mirrored invisible walls (checked with rays; the porthole, binder rings and ruler stilts are
  open). Saved in Studio only after his Ctrl+S; `tools/town_toys.py` has it for rebuilds.
- **Backlog:** redo the part models (boosters first); bots that use the town (fly-throughs, boosts, varied routes);
  skill bonuses (ram someone and survive). See [ideas](../plan/IDEAS.md).
- **Not yet answered:** which screen showed a part "revolving around a tip" (the shop, fold card and Hangar views all
  turn around the model's middle when measured).

## What changed
Commits 2026-11-12 from "Tape-roll tower" to "Shop: faded chalk green". Pages: [menus and HUD](../systems/menus-and-hud.md),
[design examples](../workshop/design-examples.md), [lessons](../workshop/lessons.md).

Back to [playtests](README.md)
