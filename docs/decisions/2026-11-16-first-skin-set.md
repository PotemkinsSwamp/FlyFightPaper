# The first skin set: 8 Commons, 8 animated Rares, after the Dragon's boosters

**Decided:** 2026-11-16 (Alan)  
**Status:** in force; the Dragon's boosters, the eight Commons and the eight moving Rares are made and in the game's list (2026-11-16, Tiger Stripes and Gold Foil taken off it); the Rares are not yet seen in Play. Trails are next.

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
  moving it like up and down across the screen. I feel like it could be better." Both redone, and on the second videos:
  **"Lava and Slime is good now. Put them in the game."** All eight are uploaded (approved) and in the game's list.
- **Next (Alan, same day):** "After you're done with that, we'll hand off, and then in the next session, we'll start the
  trails."
- **Trails talk, first answers (Alan, 2026-11-16, third session; the how-it-works note is not written yet):**
  - **Cut from the list:** "I don't like pencil shavings, eraser crumbs, ink splats, or crayon scribbles. So those got to
    go." Eight stay: chalk dust, confetti, rainbow marker, glitter, bubbles, music notes, paper hearts, gold stars.
  - **Trails that match Rares:** "it'd be cool to have one that matches Glitch, one that matches Thunderstorm ... maybe
    one that matches Galaxy. Possibly one that matches Salon [Slime? to confirm]. One that matches Circuit Board." Some of
    the eight can be "morph[ed]" to match a Rare; the rest "become the like more common ones".
  - **Shape:** "it definitely just comes from the back. And it'll be like a thin stream that like tapers off."
  - **Speed:** "when you hit a boost, it should extend because you're going faster. It should also do that whenever you
    catch momentum by doing a nosedive and then picking back up." Always on while flying; shown in the hangar too.
  - **How they are made:** "a mixture of generated images and what's described in the YouTube video" (YorusDevs, "How
    Opus 5.5 drew every visual effect in my Roblox game": white layered shapes drawn by code in PhotoCraft, coloured by
    the game, frame sheets for movement). PhotoCraft is on Alan's PC at `D:\ArtCraft\PhotoCraft`; a test streak drew fine.
  - **Second answers:** "Yeah, I meant slime." Glitter becomes Galaxy's and Bubbles becomes Slime's ("those are great");
    "You could make rainbow kind of match with the holographic." Rare-matching trails are sold "on their own". "Build
    the crane petals." "We also need something to match with the dragon as well" (Dragon Embers, already on the list).
    The how-it-works note is in the [skins plan](../plan/SKINS-PLAN.md) ("Trails: how it works").
  - **The note OK'd, with two changes:** "Length, yeah. Bigger one fast, yeah." **Price parked:** "The rare matching
    trails would probably be more expensive. But we're not worried about price right now. We're worried about just
    making them." **Bots:** "they should wear their matching trail. And the common and rare ones, just get a random
    one. They also don't all need them ... Not every bot needs skins. Not every bot needs trails. Some bot can have no
    skin and a trail. Some bot can have a skin and no trail. Some bots can have skins and trails. Some bots can have
    neither." This replaces "bots all wear skins" in the [skin rules](2026-11-13-skin-rules.md).
  - **First three videos (flat pictures, from above): "bad."** "They need some kind of 3D depth to them, and maybe some
    texture. Because it doesn't look like you used 3D stars. I'm worried about how they're going to look when actually
    put into a 3D environment. Honestly, the width is fine ... the gold stars one in a straight line is kind of odd ...
    random variations, in almost a cloud formation ... We need to make them 3D." Redone as 3D models in a Blender scene.
  - **The 3D videos:** "the gold stars look good, except it still needs that little particles that are around the gold
    star as well to like fill in the rest of it." **Holo Rainbow, no:** "it looks like a banner ... It's just a 2D banner
    that's rotating." **Storm Sparks, no:** "they just look like bubbles ... purple bubbles with little lightning ... it
    should be actual like thick clouds coming out and then lightning, you know, exploding throughout it." Redone: Gold
    Stars with sparkle dust; two options each for the other two (storm: A thick cotton cloud, B soft smoke, both lit
    from inside by the lightning; rainbow: A foil crystals whose colour runs through the rainbow, B six coloured cords
    wound round each other).
  - **His picks:** Gold Stars: "Stars are good." **Storm Sparks: B** ("definitely B"), the soft smoke lit from inside by
    the lightning; option A (cotton cloud) deleted. **Holo Rainbow, no again:** "it still just looks like a bunch of
    streamers attached to a plane. We need something with more body." Redone as a thick rainbow smoke cloud with foil
    flakes and sparkles, built like the storm he picked (a dense stream of big foil crystals was tried and dropped
    unseen: still no body). Two options: A the colour runs through the rainbow once along the stream (from your own
    seat you see only the pink end), B three times (your own seat shows most colours). **His pick: B** ("B is good").
  - **Bots' chances:** asked "70% wear a skin and 50% a trail, rolled separately: yes?", he said "bots they also need a
    roll for having both." Claude's reading: one roll with four results, skin and trail 35%, skin only 35%, trail only
    15%, neither 15% (the same odds, with "both" its own result). The numbers are Claude's, his to change.
    **Alan OK'd 35/35/15/15** (fourth session, asked with the four numbers written out); built as `bot_looks` in
    `config/looks.json`.
  - **Upload (fourth session):** shown the safety sheet of the only two pieces needing upload (a folded star, a
    lightning bolt; smoke and sparkles use Roblox's own pictures), he chose "Upload both". Both came back Approved.
    He also chose "Tests and screen grabs" for Claude's own Play run, then declined desktop access to the Studio
    window when it would not draw: the looking is his.
  - **The other ten as videos (fourth session).** Alan: "The dragon embers just looks like orange glitter needs to look
    more like actual ember and fire, the circuit board feels like it needs more circuit its kind if mainly cloud. Lets
    not add the paper hearts lets just save it for later release and bring in another one, i might want to save paper
    hearts for a holiday theme. ... Ok so if i didn't mention anything else then its good to put in." So **OK'd to put
    in:** Chalk Dust, Confetti, Music Notes, Stardust, Goo Bubbles, Glitch Pixels, Folded Petals. **Redone as two
    options each** (his pick pending): Dragon Embers (A a roaring flame, B dark smoke full of glowing embers), Circuit
    Trace (A boards, chips and traces with no cloud, B a lattice of neon traces with a faint glow). **Paper Hearts is
    saved for a holiday set**, not this release; its replacement is his pick between Mini Paper Planes and Paper
    Butterflies (Claude's two ideas). He dismissed the upload question for the four new models (curl, note, note pair,
    petal) without answering: not uploaded.
  - **His picks (fourth session, last round).** Alan: "Dragon b, circuit still needs work it looked better before,
    replacement A. The circuit trail just doesn't give a technology feel, the green circuit lines are to straight there
    should be flashing LED and a slight green circuit board cloud. And upload the other models that are approved".
    So: **Dragon Embers = B** (dark smoke full of glowing embers; in the game). **Paper Hearts' replacement = Mini
    Paper Planes** (its dart model's safety sheet is with him; not uploaded, not in the game). **The four models
    uploaded** (curl, note, note pair, petal; all Approved). **Circuit Trace: third go** with bent traces, flashing
    LEDs in four colours and a slight green cloud; video with him, verdict pending.
  - **"Looks good upload all"** (Alan, on the third Circuit Trace video and the Mini Paper Planes safety sheet). So
    **Circuit Trace is OK'd** and both models are uploaded (the paper plane and the bent trace, both Approved). The bent
    trace got a short branch and a third pad before upload so it could not be read as a bare zigzag; Claude checked its
    safety sheet and sent it to him after the upload. All 13 trails are now in the game.

  - **Five new Legendaries, 2026-11-17.** Alan clarified that a trail is a continuous plume of small objects leaving the exhaust. He chose Ninja stars and smoke like a smoke bomb. He approved building that concept alongside water drops and foam for Shark Jet, tongues of flame for Hot Rod, silver chaff in vapor for Stealth, and checkered racing flags in tire smoke for Race Car.

  - Alan asked for texture and a stronger identity after the first Legendary trail videos. He approved trying shining Ninja stars, folded reflective chaff, tire rubber and sparks, and teeth in the spray. The Hot Rod tubes already backfire. This pass changes only the appearance of the trail. Alan wants to leave behavior triggered by flight or the skin for later.

  - Alan chose Ninja A (brushed silver) and Hot Rod A (blue-core flame). Race Car B is the base, with more visible sparks. He rejected both Stealth chaff versions and wants a different idea. Shark needs a water jet with breaking seafoam and an occasional recognizable jaw bite. He asked for textured teeth that read from the flight camera.

  - Alan approved Shark Jet B, the rolling water jet with the hinged bite. Race Car keeps its twin tire tracks. The sparks need a metallic glow, more jump and less regular spacing. For Stealth he chose Cloaking Wake, with pockets of air that bend the view behind them.

  - Alan said the Race Car sparks looked like confetti and asked for streaks that string together like grinding metal, with some randomness. He liked the look of Stealth's distortion and wants one continuous stream that bends the background.

  - On 2026-11-18 Alan approved Stealth B, the continuous Cloaking Wake. Race Car needs occasional bursts of grinding sparks and large periodic skid marks in place of loose tread scraps.

  - After seeing the skid marks, Alan chose the previous Race Car tire smoke and tread scraps. He wants random spark bursts more often than in the skid mark preview, with breaks you can still see.

  - Alan approved the revised Race Car spark timing on 2026-11-18 and asked to upload all five Legendary trails.

- On 2026-11-18 Alan asked for every finished skin and trail to be accessible through the normal player menus. A working Studio test selector is insufficient. [Hangar checks](../playtests/2026-11-18-hangar-catalog.md)

## Why
Alan wants a full, finished-feeling shop for the beta: a small set of cool skins done well beats a long list of plain ones,
and moving Rares make the price step from Common worth it.

## Affects
[Skins plan](../plan/SKINS-PLAN.md), `config/looks.json`, [skin rules](2026-11-13-skin-rules.md).
