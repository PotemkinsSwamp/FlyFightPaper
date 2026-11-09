# 2026-11-09: stretched menu pictures (Alan's examples)

## What Alan did
Looked at a before/after preview of "crisp menus" (Studio, edited pictures loaded locally, nothing uploaded), rejected
it, then went through the game himself (menus, a match's desk, the Esc menu, the Hangar Range) and sent screenshots of
what looks bad.

## What he saw
- **The rejected try** (all undone the same day): tacks and tape scrubbed off 10 pictures and new shiny tacks/tape
  drawn by code, Save loadout and Fly this build given green pins, the Back strip swapped, menus drawn without the 3D
  way. "You made everything look worse": the tacks lost their shadows, the scrub marks show, the red dot on Back and the
  taped Save buttons were what he liked. The main menu was already sharp; only the Customize part cards could be sharper.
- **Real problems, his examples** (he says there are more):
  - Back buttons (Hangar, Settings): the red tack is squashed.
  - Customize: the stats paper is stretched wide (tape and holes wide); the part cards are squeezed.
  - Hangar page: the "Presets" paper overlaps the Loadout name tape (placed wrong).
  - A match's desk: the Menu button's tacks squashed; the **Match tip note is the worst** (stretched, low resolution,
    its buttons squashed); the Repair / Fresh plane / Full refold / Customize strips look stretched.
  - Esc menu (clipboard): the button strips are stretched (tacks oval).
  - Hangar Range: the lesson notes are stretched (tape wide, Got it / Skip tacks squashed); the Range board's Loadout
    and Difficulty strips and the red "picked" scribble are stretched.
- **Bug:** after a match, the match strip (FFA and the clock) still shows over the Hangar Range.

## Second look (same night, ~01:40): Alan on try 2 (branch `wip/stretch-fix-2026-11-09`, not on main)
- Good: the Range board is sharp now (keep that).
- The X on the "replay any lesson" note: keep the little square red box (not a round sticker), and it must sit ON the
  note's paper, not hang off its edge.
- Every piece of paper must fit inside the paper it sits on; overlaps are bad design (the X off the note, the Range's
  note over the stats card on the main menu, the tutorial arrow over a drawing, Settings' Back over the High tab).
- Stats paper beside the plane: a phantom smudge next to the tape where it was widened ("should have left the tape
  the way it was"). Make the paper bigger instead of cramming: in Customize and beside the plane, the rows (Weight)
  run off the paper's bottom.
- Words don't fit or aren't centred, and inconsistently: "Paper Pellet Gun" overflows its card while "Spitball Straw"
  fits; the desk's "Safe in the hangar..." words spill off the thinner tape. "I keep having to tell you."
- The Presets page's "Presets can't be changed..." floats on the cork: it needs a paper under it.
- Bugs: after leaving the Hangar Range, its note ("The Range - note 1 of 7") stays on the main menu; in the Range the
  Menu strip couldn't be clicked and the view looked zoomed out (check whether try 2's Range change did it); the FFA
  strip was missing at the desk until launch (try 2's practice check; the plane likely keeps `Practice` after the Range).

## What changed because of it
- Ruling in [the text style decision](../decisions/2026-11-08-text-style-crayon.md): keep the pictures exactly, fix the
  boxes they are drawn in; new pieces only where no picture has the needed shape, shown to Alan first.
- Lessons: [a quality fix keeps the pictures; 9-slice bends what crosses its lines; local picture previews](../workshop/lessons.md).
- Next session: measure every screen (menus, desk, Esc menu, notes, Range board) and fix the stretched ones; the FFA strip bug.
