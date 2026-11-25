# The Emotes page with its classroom painting, Alan's look

**Date:** 2026-11-25 · **Who:** Alan, in his own Play · **Build:** `a7f9712b2` (the painting wired in)

Before Play, from the assembled picture: "this looks great to me"; the cart stays as drawn ("If eventually we have to
change it because we'll add more emotes, we can change it then"). In Play the painting sat right in his two
screenshots: the glass over the picture, the cards three across, the name and buttons on the cart's front. He did not
say so in words, and did not mention the main menu's strips, the framing or the jacket.

## His notes
| # | What he said | What was done |
|---|---|---|
| 1 | **Order the emotes by price**, "least to greatest amount of cost for paper". | Done the same hour: each board lists cheapest first, the free one leading (`src/client/EmoteShop.luau`). Compiles; not seen. |
| 2 | **The TV needs sounds**: "the sound of a TV turning on, turning off, the click". | Open. Already planned as three licensed candidates on a Dev button, his pick by ear. |
| 3 | **Emotes are cut off early on the TV** ("the bubblegum ... doesn't finish being scraped off of the screen"; "some of them are"). | Fixed in code, not seen: the TV stopped the moment the winners' camera would start home, but the real scene runs the emote 2 seconds more during that glide (the gum's scrape, Book Kicker's book sliding off). The TV now runs those 2 seconds too (`TV.frame`). |
| 4 | **A glitch: the last emote's sound keeps playing** after tapping another card (Magician, then Bubblegum). "The sound for that emote that was just playing has to stop." | Fixed in code, not heard: nothing stopped a sound once started. Every sound the TV starts is now tagged to that showing and stopped with it (`Audio.hush`, called in `TV.stop`). |
| 5 | **His kid does not sit on the books** in Nap: "he's not actually sitting on the books ... just floating"; the same will happen to players with bodies like his. (The "clothing artifact" was his shoes: not a fault.) | Open. The winners' moment has a seat fix (`sit` in `WinnersCutscene`); whether the TV runs it is not checked. |
| 6 | **Sneaky Toss's paper ball stays in the air** behind him: "it literally just stays where it's at". It should be thrown off screen, left or right, "like you normally would be throwing it at the runner-up", and be gone. | Open. On the TV the 1st it is thrown at is not there. |
| 7 | **Test Flight's plane flies backwards and upside down** ("the plane travels backwards ... instead of flying nose first"). "That might be a problem with the emote." | Open. Check the winners' moment too. |
| 8 | **What plays inside the TV must look as good as the page**: "a nice background, lighting, textures as well". | Plan OK'd by him ("go on all"); a first trial set was photographed in Edit and not shown (flat desk, flat light): [plan](../plan/EMOTE-SHOP-PLAN.md). |

## Open after this look
- Notes 2 to 8. Never said: whether the three main-menu strips are readable, whether Magician stays in the TV, whether
  the jacket rule looks right on him, buying and Use.

Back to [playtests](README.md)
