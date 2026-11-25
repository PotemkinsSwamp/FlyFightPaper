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
| 2 | **The TV needs sounds**: "the sound of a TV turning on, turning off, the click". | Done: his pick by ear of three, "sound 3" (a TV knob's click, with a short soft burst of static when it comes on; `tvOn` / `tvOff` in `Audio`). The other two and the Studio button are gone. He also found that a double click (his mouse sends two) put the TV on twice with two clicks heard: a second tap within half a second now does nothing (`TAP_GAP` in `EmoteShop`). |
| 3 | **Emotes are cut off early on the TV** ("the bubblegum ... doesn't finish being scraped off of the screen"; "some of them are"). | Fixed in code, not seen: the TV stopped the moment the winners' camera would start home, but the real scene runs the emote 2 seconds more during that glide (the gum's scrape, Book Kicker's book sliding off). The TV now runs those 2 seconds too (`TV.frame`). |
| 4 | **A glitch: the last emote's sound keeps playing** after tapping another card (Magician, then Bubblegum). "The sound for that emote that was just playing has to stop." | Fixed in code, not heard: nothing stopped a sound once started. Every sound the TV starts is now tagged to that showing and stopped with it (`Audio.hush`, called in `TV.stop`). |
| 5 | **His kid does not sit on the books** in Nap: "he's not actually sitting on the books ... just floating"; the same will happen to players with bodies like his. (The "clothing artifact" was his shoes: not a fault.) | Still floating in his second look (same day, screenshot). Fixed in code, not seen: `sit` now rests a kid on the legs and feet only, not the hips piece (his avatar's costume torso reaches lower behind the legs, out of sight). Applies to every sitting emote, in the TV and the winners' moment. Before: open, cause likely found, not seen. The TV does run the seat fix (`sit`). Measured in Edit on his avatar in the Nap pose: `sit` rests him on his hips piece's box, which is 1.14 tall and 1.66 deep (a plain body: 0.40 and 1.00), with his legs 0.4 to 0.6 studs above the books; a plain body rests on its feet. So the box is probably bigger than what is drawn. A picture in Edit is the next step (Studio was minimised). The same would show in the winners' moment. |
| 6 | **Sneaky Toss's paper ball stays in the air** behind him: "it literally just stays where it's at". It should be thrown off screen, left or right, "like you normally would be throwing it at the runner-up", and be gone. | Fixed in code, not seen: with no 1st to aim at, the throw stopped with an error every frame from the release on, so the ball hung where the hand let go (and the TV never switched itself off). It now flies where the head of a 1st standing there would be and on out of the picture (`aim` in `emotes/SneakyToss.luau`; the numbers checked in Edit). |
| 7 | **Test Flight's plane flies backwards and upside down** ("the plane travels backwards ... instead of flying nose first"). "That might be a problem with the emote." | Fixed in code, not seen. Not the emote: the plane the Emotes page builds for the TV had its front turned half a circle (a model with no main part takes a piece's own turn), so every emote on the TV held and flew it tail first. Its front is now set as a flying plane's (`plane` in `EmoteShop`; measured in Edit: nose ahead). The winners' moment uses the real plane and was never wrong. |
| 8 | **What plays inside the TV must look as good as the page**: "a nice background, lighting, textures as well". | Plan OK'd by him ("go on all"); a first trial set was photographed in Edit and not shown (flat desk, flat light): [plan](../plan/EMOTE-SHOP-PLAN.md). |

| 9 | (second look, same day, screenshot) **Card pictures show only the top of the head** (So Close, Nap). | Fixed in code, not seen: both kids curl forward, so from the front the head hid the body. Their cards' camera now goes 55 degrees round to the side (`TV.POSE`). |

## Open after this look
- Notes 2 to 8. Never said: whether the three main-menu strips are readable, whether Magician stays in the TV, whether
  the jacket rule looks right on him, buying and Use.

Back to [playtests](README.md)
