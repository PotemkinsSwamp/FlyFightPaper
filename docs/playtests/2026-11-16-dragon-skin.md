# 2026-11-16: the Dragon as a plane skin (size, collision, shots)

## What Alan did
Looked at the Dragon in Studio under Roblox's light (edit mode), moved its wings in Studio, judged a row of planes with the
Dragon fitted over them, then flew it in Play, equipped from the hangar, on his fastest frame (slim body, narrow wings),
getting shot at by bots.

## What he saw
- **The look:** "looks fine in roblox it needs to input as a plane skin though like we did for the crane".
- **Wings:** too far back for a plane; he moved them forward (0.67 and 0.71 studs on the 8.4-stud model): "make them like
  the same number".
- **Gaps:** on the heavy planes the plane's own body and wingtips stuck out past the Dragon, invisible: "you will hit
  something and wonder why your plane crashed".
- **In Play, fast frame:** "didn't look like any of the shots were hitting me, yet I was getting hit"; the Dragon "felt
  like it was a little too small".
- **After the fixes:** "Okay, it looks good now."

## What changed
- Wings 0.69 studs forward on both sides; one mesh and one 1024 picture set.
- The Dragon keeps its proportions and **is** the hit and crash shape, as big a target as the plane it is on, centred on
  it, and never shorter or narrower than the plane ([decision](../decisions/2026-11-14-shape-skin-model-sheets.md),
  [planes page](../systems/planes-and-hangar.md)). Checked: the server's hit shape is the Dragon's own outline.
- Shots from a skin's moved gun (ace bots wear the crane or the Dragon) were drawn 1-3 studs beside the real shot the
  whole way; now they slide onto the real path within 15 studs.
- The "Dev: skin" try-on button now tells the server too (it changed only the screen before).
- **Later the same day, boosters:** they were plain under the Dragon ("the boosters don't match the dragon skin"). They now
  wear its printed sheet, its own green body scales; Alan looked in Studio: "its good".
