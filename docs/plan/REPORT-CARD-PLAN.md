# Report card plan

**Status:** approved and built 2026-11-11 (Alan: "build it"; seen in Studio Play at phone size: "looks good").
Not yet published. Alan's backlog must-do: "the results card becomes a report card and
looks like one" ([decision](../decisions/2026-11-08-unlock-ladder-and-bot-builds.md)). First draft was a personal card
(your own grades per subject); Alan: results are everyone's, so it stays the class's results on a report card. Look:
`.planning/report-card-concept/` (close-up.jpg, in-scene.jpg).

## What the player sees
Same moment, place and size as today's results page (the last 10 s of the winners' moment, right of the winners), and
the same facts: places 1-5 and your own row, with Folds, Assists, Crashes and Points; your Paper and XP; your level bar.
What changes is that it looks like a school report card:
- **Cream card** with a printed blue double border, a round school seal with a paper plane, "PAPER FLIGHT 101" (as on
  the chalkboard), "REPORT CARD" and "Term: Free-for-all" (or the round's mode). Tape on the two top corners.
- **A printed table** with a pale blue head row: place, Pupil, Folds, Assists, Crashes, Pts, Grade. Names and numbers
  look handwritten in blue ink; your row is marked with yellow highlighter (today's highlight).
- **Grade column in red pen**, one per pilot, from their place (team rounds: by points across both teams): 1st A+ (circled), top quarter A, top half B, the rest
  C. No D or F (players are 9-16). With 12 pilots: 1st A+, 2nd-3rd A, 4th-6th B, 7th-12th C.
- **Box at the top right:** free-for-all "Your place" with your place in red, circled; team rounds "Team score".
- **Teacher's note** in red pen, about the round, never about you: "Top of the class: theo4928!"; team rounds "Red team
  wins!" (both scores are in the cards' top boxes; the winners' card also gets the gold star sticker), and on the losing team's card "Good try, Blue
  team!". Tied team round: "A tie! Well flown, everyone." Signed by nobody (no name to explain).
- **Your pocket money:** "+240 Paper +340 XP", then your level bar and next unlock as today.
- **Team rounds:** a card per team side by side (Red left, Blue right), as today.

## How it's built (cheap)
- One new card picture drawn by `tools/art/report_card.py`: paper, border, seal, table lines and head band only;
  every word (title too) is game text, so it stays sharp and works for any name and mode. A second small picture,
  the red pen ring, circles your place and A+ grades. The Term words, notes and grades use fonts already in Roblox (Special Elite for the
  printed words, Kalam for ink, Indie Flower for the red pen).
- `RoundEnd.luau`: new column spots, the Grade column, the top-right box and the note. Grades and note words are
  worked out on your screen from the results it already gets (no server or saving change).
- Phones: today's phone sizes carry over; checked in Studio's Device Simulator before you see it.
- Check: Studio Play with the "end match" button while you're not playing, screenshots at PC and phone size, then your
  look in a real round.

## Cost
Opus (me) only; no Codex, no bot matches, nothing paid. Two free picture uploads (card and red ring; Alan's go
2026-11-11, both approved by Roblox review). About 2 hours.

## Not in this plan
- A personal report card (your own grades per subject) for all-time stats: Alan 2026-11-11, maybe later on its own
  screen ([ideas](IDEAS.md)).

Back to [HOME](../HOME.md)
