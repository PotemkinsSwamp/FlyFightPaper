# 2026-11-16: scripted check of all 19 skins and 13 trails (frame rate and what differs)

## What was run
Alan's ask: a Play test by script, no screen grabs, that measures the frame rate of a 12-plane match with every bot in
a skin and a trail, and lists anything wrong with each skin and trail by reading the game itself. Run in Studio on
Alan's PC, muted, his plane on the loop autopilot with the chase camera, 11 bots, Studio's 60 cap, quality 10 / level
21. The tool is `tools/looks_check/` ([tools](../workshop/tools.md)). It forced looks onto all 12 planes step by step
and, per step, counted frame times while the player's plane flew and read every plane's pieces, layers, trail emitters
and trail parts against the configs. Play ran about 50 minutes (planned 12): the screen slept, the autopilot got into a
crash loop, and the spoiled steps were re-run ([lessons](../workshop/lessons.md), "Scripted Play tests").

## What it showed

### Frame rate
| Case (12 planes) | Frames a second | Slowest frame |
|---|---|---|
| No skins or trails (6 runs) | 60.0 | 20-25 ms |
| Every plane in a skin and a trail, game as it was (Rares not moving) | 59.7 (59.2 from the overview camera) | 24 ms |
| The same with the Rares moving (fix rehearsed by the test, 4 runs) | 57 average (54-60) | 26 ms, one 68 ms |
| Worst case: 12 Galaxy + 12 Circuit Trace, moving (3 runs) | 52 average (48-58) | 27 ms |
| One skin on all 12, each of the 19 | 59.2-60 | under 33 ms, two 61-71 ms |
| One trail on all 12, each of the 13 | 56.7-60 | under 34 ms, one 45 ms |

- One trail on all 12: Glitch Pixels, Holo Rainbow, Stardust, Storm Sparks 60.0; Dragon Embers, Goo Bubbles 59.9; Music
  Notes 59.7; Mini Planes 58.6; Chalk Dust, Folded Petals 58.4; Gold Stars 57.8; Circuit Trace 59 over five runs (low
  56.7); Confetti 60 in four runs and 51 in one short run (195 frames, taken as noise).
- Parts in the air with one trail on all 12: Circuit Trace about 900, Gold Stars 730, Music Notes 660, Folded Petals 650,
  Confetti and Goo Bubbles 540, Mini Planes 410-570, Glitch Pixels 290, Chalk Dust 240, Stardust 140, Storm Sparks 20.
- A Rare's first load froze the game 0.4-0.7 s (partly the error below, which printed 187 times a switch); plain skins
  20-50 ms.
- Each case is a few hundred frames, so about plus or minus 1. Studio runs the server and the game in one program; a
  real player's device runs only the game. Not measured: Galaxy moving on all 12 with no trail (which half of the worst
  case costs more), phones.

### Skins
- **All 8 Rares were broken in real Play.** Every piece wore the right still picture, but `PlaneLooks` could not make a
  glowing layer: "The current thread cannot write 'EmissiveMaskContent' (lacking capability PluginOrOpenCloud)". The
  layer loop stopped at the first glowing layer and the pieces were never put on the moving list. Lava, Galaxy, Slime,
  Glitch, Circuit Board: no layer, no glow pulse. Comic Book: only the lines, frozen. Holographic: only the rainbow,
  frozen. Thunderstorm: only the clouds, frozen. The previews and Edit tests ran with plugin rights, which a game script
  does not have.
- **Shark Jet draws nothing** (no picture, no shape; its trail `water_spray` has no drawing). Changing from a picture
  skin to it left the old skin on 11 of 12 planes.
- **The 8 Commons, the Dragon and the Origami Crane: nothing found.** 187 of 187 pieces dressed on 12 planes with the
  right picture and mesh; Dragon 1 shape piece a plane, Crane 5, real parts hidden, guns and boosters moved; everything
  came off cleanly afterwards.
- Keep their own look under every skin, as designed: guns, booster elastic and tape, the heavy body's tape, stickers.
- Not tested: the server's hit shapes for Dragon and Crane on bots (the test only switched what is drawn).

### Trails
- **Nothing differs from `config/trails.json` on any of the 13:** emitter counts, pictures and light settings; part
  materials, colours and sizes; parts in the air within about 10% of the sum of the rows; all 8 uploaded models loaded.
- Notes stood upright (571 of 571), mini planes flew right way up (617 of 620), every bolt carried its light.
- The shop list still names `rainbow_marker` and `water_spray`, which have no drawing: a bot that rolls Rainbow Marker
  flies with no trail.
- Resting trail parts are kept, never freed: 4,705 after every trail had been on all 12 planes (memory did not grow).

### Only Alan's eyes can settle
Whether each looks good (Neon traces and LEDs, lit cubes, see-through goo, smoke under lightning); whether sparkles and
smoke start in clumps (a script cannot read where particles are); the Dev: trail button's words. The error log was full
of the Rare error, so quieter warnings may have been hidden.

## What changed
- **Rare layers are made ahead:** `tools/art/skin_looks.py` writes one Decal a layer (`SkinLooks/<skin>/Layers`), with
  its glow picture and colour; `PlaneLooks.layersOn` clones them. Rehearsed in the same Play by an ordinary script: all
  layers on all 12 planes, Galaxy's stars, planets and comet moved and its glow pulsed. Then run as the game's own code
  (check Play below).
- **A skin with no picture now takes the old skin off** (`PlaneLooks.sheetOf`).
- `SkinMotion.spec` checks every layer's ready-made Decal.

## Check Play, same day (the game's own fixed code, 7 minutes)
- **All 8 Rares work.** Each on all 12 planes: every layer on every piece (12 of 12 planes fine), 60.0 frames a second,
  first load 25-190 ms (was 0.4-0.7 s). Read on the player's plane: Lava's flow slides and glows 0.35-1.0; Galaxy's stars
  slide, both planet rings spin, the comet passes, glow 0.26-1.3; Slime's two layers slide; Holographic's rainbow and
  glint slide; Glitch snaps on and off and the sheet flashes; Thunderstorm's clouds slide and the bolt flashes (glow to
  2.0); Circuit Board's pulse slides and the board's glow breathes; Comic Book's lines slide and POW, SLAM and ZAP each
  slam in and out. Slime's glow pulse was read over too few frames to show.
- **Where the worst case's time goes** (looks switched every 13 s, three times round): nothing 60.0; Galaxy on all 12
  with no trail 60.0; Circuit Trace on all 12 with no skin 60.0; both together 54.5 (53.4, 57.0, 55.5); the mixed set
  58.5 (52.5 on 109 frames, 60.0, 59.0). Each half holds 60 alone; only the two together go under. Render time a frame
  (Roblox's own count) 8-9 ms with nothing, 11-13 ms with both.
- **Whole test set: 672 passed, 0 failed.** No `PlaneLooks` error in the log. The log shows 21 pictures answering "No
  asset content representation found" (one is Holographic's rainbow, which then reads as loaded): Studio asking for a
  packed copy that is not made yet ([lessons](../workshop/lessons.md), texture packs), not a missing picture. Glow
  pictures' load state cannot be read by script.
- Open: the worst case is under the bar (54.5 against 60); the next step is finding which work the two share
  ([performance](../systems/performance.md)).
