# Unlock moment plan (draft for Alan's OK)

**Status:** draft, 2026-11-11. Nothing built yet. Builds on Alan's choices in
[the unlock ladder decision](../decisions/2026-11-08-unlock-ladder-and-bot-builds.md) ("You unlocked" moment, details
and concept review). Look: the concept frames in `.planning/unlock-concept2/`.

## When it shows
- **After the round's results card**, as the camera glides back and the vote lap starts (nobody can be hurt then).
  Never mid-fight: a level-up during the round waits for the round's end.
- Only when your new level unlocks something. Two levels in one round = one moment, everything in one backpack,
  the tape shows your new level.
- If the next round is about to start (3 s left) and it's still open, it tucks itself away. Nothing is lost: every
  part is in the Hangar anyway.

## Step by step (what you see and do)
1. **The world goes dark and blurry**; a taped, lined sheet of paper drops in with "LEVEL 4!" on yellow tape (frame 1).
2. **A backpack rises from the bottom edge** (frame 2): big and wide, sitting on the bottom of the screen, its bottom
   never showing.
3. **You drag the zipper, right to left**, along the top of the backpack. While you drag it the paper and backpack
   shake a little; phones vibrate if Roblox lets them. If you don't start within about 2 s, "Drag to unzip" and a
   crayon arrow appear (frame 3). Shown while you're level 4 or below (your first three unlocks), never after.
4. **The backpack opens and the item pops out**, turning all the way round once as it rises, with a pop sound
   (frame 5's look, but the backpack stays cut off at the bottom).
5. **The item's card** (frame 7): the real 3D part, slowly turning; "You unlocked", its name, and what it does.
   - Free (price 0): "Now in your Hangar" + **Put it on** (opens the Hangar on that part's page) and **Later**.
   - Costs Paper: "Now available for purchase in the Hangar" + **See it** (no price shown) and **Later** (frame 8).
6. **More than one item:** they all come out of the same backpack. Swipe or drag between them; arrows on PC too, and
   dots under the item show how many. Free items come first. **Later** takes that item off; Later on the last one
   closes the moment. Put it on / See it closes it and opens the Hangar.
- **Skip** (small, bottom corner, from step 2 on): opens the backpack at once and goes straight to the cards.

## What comes out at each level (from today's catalog)
Level 2: Point Popper (free), Needle Nose, Split Tail, Swept Wings. Level 3: Staple (free). Level 4: Thumbtack (free),
Swift Fold. Level 5: Blunt Nose, Broad Wings, Ridge Tail, Elastic Booster, Marksman preset. Then one to four items at
levels 6-28 and the Pencil Launcher at 40. Preset planes (Marksman 5, Bomber 8, Carrier 10) come out as whole planes.

## Words
Weapons use their Hangar description (up to three lines; the paper grows to fit). Plane parts have no description
today: I'd write one short line each (about 25, like "Turns sharper, but a little slower") for you to read first.

## How it's built (cheap)
- One new client file (`UnlockMoment`), started by the results card closing. It compares your level before and after
  the round, so nothing new is saved.
- Art: the six pieces already cut from the concept (sheet, title tape, backpack closed and open, zipper pull flat and
  lifted). The zip is the open backpack showing through behind the pull as you drag. Items are the real 3D models
  (as in the Hangar cubbies), so every part works with no new pictures. Skipped: the gold burst behind the item
  (frame 5); add it if the pop feels flat.
- Before any upload: a put-together preview over a game screenshot, close up, for your OK.

## Cost
Opus (me) only: no Codex, no bot matches, nothing paid. Six free picture uploads (your go, after the preview).
About 2-3 hours to build. To check it: a menu-only Play with a dev switch that fires the moment, while you aren't
playing; then your Play check.

## Numbers to OK (my picks)
Dark layer 45%, blur 16; drag hint after 2 s, up to level 4; one full turn in 1.2 s as it pops; shake 3 pixels;
tucks away 3 s before the next round.

## Questions for Alan
1. Do preset planes (Marksman, Bomber, Carrier) come out of the backpack too? My pick: yes.
2. Showing it during the vote lap (after the results card) is OK? The other place is the main menu, which is calmer
   but later.
