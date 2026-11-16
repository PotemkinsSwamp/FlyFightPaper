# The first skin set: 8 Commons, 8 animated Rares, after the Dragon's boosters

**Decided:** 2026-11-16 (Alan)  
**Status:** in force; the Dragon's boosters and the eight Commons are made and in the game's list (2026-11-16, Tiger Stripes and Gold Foil taken off it); the Rares are next.

## Decision
- **First: the Dragon's boosters.** "the boosters don't match the dragon skin, so that needs to be fixed" (the crane's
  boosters wear its own printed sheet; the Dragon has none yet).
- **Then every skin that does not change the plane's shape: the Commons and the Rares only.**
- **Commons (8):** Hazard Stripes (made), Carbon Fiber, 8-Bit, Neon Grid, Flame Decal, Tie-Dye, Racing Stripe, Jungle Camo.
- **Rares (8), "the coolest looking":** Galaxy, Lava, Slime, Holographic, Glitch, Thunderstorm, Circuit Board, Comic Book.
- **Rares move.** His examples: lava "will kind of flow", slime "ooze around, move", frozen snowflakes "twinkle", gold
  "shine", galaxy stars "move around ... on the plane". "For the rest of the rares, it'll all kind of like follow that
  idea." How each one moves is a new mechanic: a how-it-works note for his OK comes before code.
- **Not in this set:** Gold Foil, Tiger Stripes and Frozen ("we just are not including them yet; we are starting with 8
  rare and 8 common"). They stay out of the game's list for now, not deleted from the ideas.
- **Tools, tested first:** the work runs on the Fable model. Before making the set, one test skin two ways: Fable with
  the tools it usually uses, and TextureCraft (the hand-texturing desktop app, [lessons](../workshop/lessons.md)); Alan
  compares them ("we will try texture craft first though a test one with just fable ... and one with texture craft and
  compare them").
- **Comparison result (Alan, 2026-11-16): the code-drawn way ("A").** Carbon Fibre was made both ways and shown on the
  same planes (`.planning/skins/tests/carbon/carbon-two-ways.jpg`). A Common or Rare is one flat picture shared by every
  part, so TextureCraft's edge wear and crease dirt (read from one 3D shape) cannot be used; it works as a material
  library (its carbon came out flat from the player's view). The set is drawn in code (`tools/art/skin_sheets.py`) and
  shown on real planes with `tools/art/skin_preview.py` before each upload.
- **Next (Alan, 2026-11-16, after the Commons):** "next session, we'll do all of the rares. And we'll talk about how to do
  the animations. And like glows and stuff, making it look like really good." So the Rares start with that talk (how each
  one moves and glows), then the how-it-works note, then the build.
- **The Rares talk (Alan, 2026-11-16):** Galaxy: "Everything should move, like planets orbit ... comets going across the
  sky, stars twinkle." Comic Book: onomatopoeias that "slam, like pulse slam", plus speed lines and bursts. The other six
  as suggested. For all eight (his yes to each): everything stays on the plane's surface; slow and easy to read, not busy;
  movement just loops; it moves wherever the skin is worn. **Glow is for up close:** "There's no point in trying to make it
  seen from far away because planes move so fast." The how-it-works note is on the
  [skins plan](../plan/SKINS-PLAN.md) ("Moving Rares"). **He OK'd it the same day:** "200 studs, it's fine. Right up
  close, not a beacon, yeah. Those rules or notes work. Go ahead and build them and then show me some videos." Still
  pictures tell him nothing about movement ("I would need like a GIF or a video").
- **The first videos (Alan, 2026-11-16):** six are good as shown (Galaxy, Holographic, Glitch, Thunderstorm, Circuit Board,
  Comic Book): "if I didn't say anything about them, then the rest of them are good". **Lava was too fast:** "Lava is
  very slow ... It's supposed to be kind of like a pulsing, slow-moving animation." **Slime did not ooze:** "it's just
  moving it like up and down across the screen. I feel like it could be better." Both redone.

## Why
Alan wants a full, finished-feeling shop for the beta: a small set of cool skins done well beats a long list of plain ones,
and moving Rares make the price step from Common worth it.

## Affects
[Skins plan](../plan/SKINS-PLAN.md), `config/looks.json`, [skin rules](2026-11-13-skin-rules.md).
