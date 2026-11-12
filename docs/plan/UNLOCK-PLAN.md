# Unlock moment plan (draft for Alan's OK)

**Status:** approved and built 2026-11-11 (Alan: "build it"; unzip redone so it opens like a real zipper; corner tapes over the LEVEL strip); waiting on his Play check. Drafted with Alan's notes (preset planes come out too; no backpack during the vote lap:
a small level-up note in the game, the backpack when you open the Menu). Nothing built yet. Builds on Alan's choices in
[the unlock ladder decision](../decisions/2026-11-08-unlock-ladder-and-bot-builds.md). Look: the concept frames in
`.planning/unlock-concept2/`.

## Part 1: the level-up note (in the game)
- **The moment you level up** (mid-round too), a small piece of paper flies in tilted at the top left (under the Menu
  button; Alan 2026-11-11: smaller and shorter, not the top middle), unfolds with a little pop of confetti, sits 4 s
  and flies back out: the level on yellow tape ("LEVEL 4!") and under it "You unlocked 2 new things! See them in the
  main menu." It doesn't take clicks or block your aim.
- A level with nothing new (11, 13...) shows just the level.
- Unopened things pile up, across play sessions too (6, 7, more is fine: they all go in one backpack). (The count
  sticker on the in-match Menu button was dropped once the backpack moved to the main menu, Alan 2026-11-11.)

## Part 2: the backpack (when you open the Menu)
Plays when the main menu shows with things waiting: when you join, or when you leave a match (never mid-match; Alan 2026-11-11).
1. **The screen goes dark and blurry**; a taped, lined sheet drops in with your level on yellow tape (frame 1).
2. **A backpack rises from the bottom edge** (frame 2): big and wide, its bottom never showing.
3. **You drag the zipper, right to left.** The paper and backpack shake a little while you drag; phones vibrate if
   Roblox lets them. If you don't start within about 2 s, "Drag to unzip" and a crayon arrow appear (frame 3), for your
   first three backpacks only.
4. **The item pops out**, turning all the way round once as it rises, with a pop sound.
5. **The item's card** (frame 7): the real 3D part slowly turning; "You unlocked", its name, and what it does.
   - Free: "Now in your Hangar" + **Put it on** (opens the Hangar on that part's page) and **Later**.
   - Costs Paper: "Now available for purchase in the Hangar" + **See it** (no price) and **Later** (frame 8).
   - Preset planes (Marksman, Bomber, Carrier) come out as whole planes, with "Put it on".
6. **Several items:** swipe or drag between them (arrows on PC too; dots show how many). Free ones first. **Later**
   takes one off; Later on the last one opens the Menu as normal. Put it on / See it go to the Hangar.
- **Skip** (small, bottom corner): opens the backpack at once and goes straight to the cards.
- Once a backpack is open, its items count as seen and the sticker goes.

## What comes out at each level (today's catalog)
Level 2: Point Popper (free), Needle Nose, Split Tail, Swept Wings. Level 3: Staple (free). Level 4: Thumbtack (free),
Swift Fold. Level 5: Blunt Nose, Broad Wings, Ridge Tail, Elastic Booster, Marksman. Then one to four things at levels
6-28 (Bomber 8, Carrier 10) and the Pencil Launcher at 40.

## Words
Weapons use their Hangar description (up to three lines; the paper grows to fit). Plane parts have none today: I'd
write one short line each (about 25, like "Turns sharper, but a little slower") for you to read first.

## How it's built (cheap)
- Saving: one new number in your saved profile, "levels seen". Things waiting = parts between that level and yours.
  Players who already have levels start with everything they have counted as seen (no giant backpack of old parts).
  The server only accepts a number up to your real level. This is Codex's saving lane: Codex writes it with a test,
  I check it.
- One client file for the backpack (`UnlockMoment`), started by the Menu opening; the level-up note and Menu sticker
  are small additions to existing files.
- Art: the six pieces already cut from the concept (sheet, title tape, backpack closed and open, zipper pull flat and
  lifted). The level-up note reuses the sheet and tape, unfolding; its confetti is the winners' confetti. Items are the
  real 3D models, so no new pictures per part. Skipped: the gold burst behind the item (frame 5); add it if the pop
  feels flat.
- Before any upload: a put-together preview over a game screenshot, close up, for your OK.

## Cost
Opus (me) for the screens; Codex for the saving piece (your ChatGPT plan, not Claude usage). No bot matches, nothing
paid. Six free picture uploads (your go, after the preview). About 3 hours. Checking: a menu-only Play with a test
switch while you aren't playing, then your Play check.

## Numbers to OK (my picks)
Level-up note: flies in 0.8 s, a 0.15 s beat, unfolds 0.7 s, sits 4 s, folds 0.4 s, flies out 0.55 s (Alan 2026-11-11); 0.52 of its first size on a PC. Backpack: dark layer 45%, blur 16; drag hint after 2 s for the first three
backpacks; one full turn in 1.2 s as it pops; shake 3 pixels.
