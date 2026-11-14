# Shape skins: model sheets first, Shark Jet A and Dragon B, a barrel body (not a belly)

**Decided:** 2026-11-14 (Alan)  
**Status:** in force. The redrawn sheets and the Dragon-head test are on the [skins plan](../plan/SKINS-PLAN.md).

## Decision
- **How shape skins are made** (Alan, 2026-11-14, after the Origami Crane came out "decent but not what I wanted"):
  a full model sheet first (Codex pictures: the design flat from the side, top, bottom and front at one scale, plus a
  three-quarter view), measured with the concept-to-blender skill; then simple shapes in Blender, coloured by
  projecting the sheet's own views onto them; fine detail as painted colour plus a baked bump picture (normal map);
  glow, smoke and embers from Roblox's own effects, not modelled. **Proved on the Dragon's head first**, judged by Alan
  beside the sheet, before any full build.
- **Picks:** Shark Jet **A** (blue-grey, white belly) and Dragon **B** (emerald and gold, crest of fins), from
  `.planning/skins/model-sheets/`. **The Shark Jet's sheet is `shark-jet-a4.png`** ("that version of the shark works
  well"): a round jet fuselage with a cream underside, tapering to a sharp nose.
- **Every shape skin has a body with a bottom, and its sheet shows the underside** (Alan, same day): "you don't know
  what the bottom looks like", and a flat-bottomed, slim design looks very odd stretched over our deep bodies ("imagine
  if that was on the Toilet Roll"; the Dragon was "incredibly slim"). He means **a barrel, like a plane's fuselage**:
  a long tube under the wings, still sleek. **Not a belly:** the first redraw was briefed with animal words ("deep
  belly", "chunky") and Codex drew fat creatures ("they're paper airplanes"). **Not a box either:** a square barrel
  made the Dragon "blocky", "not aerodynamic". **Not a sausage:** the round Dragon "looks like a balloon"; the shark
  works because its head is the nose cone and the body tapers all the way. A skin must look like a paper airplane
  and a cool fighter first, the creature second.
- **Safety swaps (Claude's call, told to Alan before he picked):** Shark A's wing zigzags become soft rounded stripes, Dragon B's
  gold square spirals on the cheeks become plain gold bands. Bent or hooked shapes and paired lightning bolts are the
  kind of picture that got the account banned twice ([lessons](../workshop/lessons.md)).

## Why
Concept pictures from one angle left the crane's builder guessing, and guessing cost three passes. A sheet with every
view, measured, says what to build; projecting the sheet's own art keeps its look instead of repainting it by code.
The belly rule comes from how the game fits a skin: it stretches per axis to cover whichever body you fly, so a slim
design over the heavy bodies would be pulled into a box.

## Affects
[Skins plan](../plan/SKINS-PLAN.md), [skin rules](2026-11-13-skin-rules.md).
