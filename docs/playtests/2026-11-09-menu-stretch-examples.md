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

## What changed because of it
- Ruling in [the text style decision](../decisions/2026-11-08-text-style-crayon.md): keep the pictures exactly, fix the
  boxes they are drawn in; new pieces only where no picture has the needed shape, shown to Alan first.
- Lessons: [a quality fix keeps the pictures; 9-slice bends what crosses its lines; local picture previews](../workshop/lessons.md).
- Next session: measure every screen (menus, desk, Esc menu, notes, Range board) and fix the stretched ones; the FFA strip bug.
