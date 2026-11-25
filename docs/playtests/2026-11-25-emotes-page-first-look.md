# The Emotes page, Alan's first look

**Date:** 2026-11-25 · **Who:** Alan, in his own Play · **Build:** `dc74aebb3` (the first build of the page, flat colours)

The page ran and the TV played emotes (he watched Magician on it). No word on the 3D jacket coming off; not asked.

## His notes
| # | What he said | What was done |
|---|---|---|
| 1 | **The Leader ranking.** After changing his mind out loud: "the ones that affect the camera in any way are the coolest ones". Coolest: Camera Flick, Magician, Fold It Up. Then Bubblegum, Book Kicker, Skeet Shoot. Then A+ (with Toy Pilot, which is free). | Three Leader price groups in `config/emotes.json`, same day. |
| 2 | **The Runner-up ranking.** "They're all kind of just basic." Coolest: Nap, Doodler, Test Flight; then Sneaky Toss, Sore Loser; then So Close, Next One; "it would be better if we just divide that into 2 lists instead of 3". | Two Runner-up groups: the three, and the other four. |
| 3 | **30,000 Paper is too much** ("that's like equivalent of like $15"). "The coolest emote probably is like $5 worth of paper. Maybe like between 5 and 10. And then it goes down from there." And "the least coolest leader emote should still be more expensive than the least coolest runner-up emote". | Numbers proposed and put in the config, waiting for his OK: [plan](../plan/EMOTE-SHOP-PLAN.md#prices). |
| 4 | **The background is boring** ("It's just a beige background. It's very, very boring. It needs work"). | Open: the page's pictures. |
| 5 | **The chalkboards and the TV need detail** ("You kind of just did it in like SVG ... it's kind of boring"). "Either create 2D assets using codex and then import them, or figure out how to put more detail. But I would lean 2D assets." | Open: the page's pictures. |
| 6 | **On the TV the kid goes out of frame** ("the books are too far out ... the magician ... lifts into the screen, you're out of frame"); a taller character would be worse. "Either the books need to move down, or the frame needs to adjust the size of your character ... always your character is in frame." | For a Leader emote the picture is now 3.1 kid heights tall (was 2.7) and reaches 2.75 heights over the desk top, about the winners' moment's own headroom (`TV.TALL`, `TV.MID`). Not seen. Every avatar is already scaled to the same height, so a taller character is no worse; a tall hat or hair still is. |
| 7 | **The door is wrong** ("the emotes shouldn't be in the shop"). "We need to make the shop and missions button smaller and then fit it under the missions button. So it's shop, missions, and then emotes." | Done: three small strips on the main menu (200 x 54, were 250 x 70); the Shop's Emotes button is gone; the page's X goes back to the main menu. Not seen. |

## Open after this look
- The page's pictures (notes 4 and 5), his OK on the price numbers (note 3), his look at notes 6 and 7.
- Never asked: whether the jacket came off and he still looks like himself; whether Book Kicker's book reaches the
  glass; A+ and Fold It Up on the TV; buying and Use.

Back to [playtests](README.md)
