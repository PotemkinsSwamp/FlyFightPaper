# Roblox optimization research 2026-11-13

Research only: no game code, art or setting was changed. The full findings (every tip with why, how to measure,
source, date and confidence) are in the reusable skill `.claude/skills/roblox-optimization/` (`SKILL.md`, its
`reference/` files and `SOURCES.md`), which Claude loads before any speed work in this or any future Roblox game.

## Plain-English summary (for Alan)
**The headline:** in the last year Roblox added several systems that make detailed games cheaper to draw *without*
making them look worse: texture streaming (Dec 2025), automatic hiding of things behind walls (Jan 2025), merged
far-away buildings called SLIM (Dec 2025), and smarter mesh detail (opt-in since Apr 2026, still buggy). Much of the
older "cut detail to go faster" advice on the forums is now out of date. Our game already does many of the right
things (shots drawn on each player's own screen, quick "may skip" messages for effects, collision worked out once in
Studio, the town loaded after the menus).

Words used: a **draw call** is one "please draw this" request from the game to the graphics card; a few hundred is
fine, thousands make frames slow. **Streaming** means a player's device only holds the part of the map near them.

## The ten findings most likely to help Fly Fight Paper
| # | Idea | What it would mean in-game | Look | Rough cost to try |
|---|---|---|---|---|
| 1 | **A one-button speed check.** The F8 viewpoints already exist; add the engine's own counters (frame time, draw calls, triangles, shadow draws, memory) next to a screenshot of each spot. | Every future speed change comes with "before / after" numbers *and* pictures proving the look didn't change. | Same | Small (one session) |
| 2 | **Three streaming settings Roblox recommends** (unload far things early, newer model streaming, pause only outside loaded areas). The place still uses the old defaults. | Less memory on phones, fewer crashes, possibly faster joins. Risk: a script that assumed a far piece exists; test on your phone. | Same | Small (an hour plus a phone test) |
| 3 | **Reuse pieces.** 924 of 983 town pictures and 814 of 921 shapes are used by one piece only, so each costs its own draw call and download. Same shape + same picture drawn many times costs about the same as drawing it once; colour tints give variety for free. | New art built as kits of shared pieces lets the town get *more* detailed for the same speed. Also: find true duplicates (same shape uploaded twice) and point them at one copy. | Same or more | Free for new art; medium to clean up duplicates; large to rework the old town |
| 4 | **Walls hide what's behind them, for free (since Jan 2025).** Only plain, solid, simple pieces do the hiding; detailed or see-through ones don't. | If the classroom's big walls, floor and ceiling are plain solid pieces, everything behind them costs nothing while hidden. Worth checking with a wall in view. | Same | Small to measure |
| 5 | **Texture streaming is automatic now (Dec 2025).** Phones get blurry-far / sharp-near pictures within their memory; Roblox's test city used 45% less picture memory and reached good quality 7× faster. It probably explains why our October "repacked" sheets used 8× the memory (a shared sheet stays as sharp as its sharpest use). | The town's bump and shine maps were halved in October to help phones. Streaming may let them go back to full size with little memory cost: detail back. | **More** | Medium (re-upload + phone test); your call if it's worth the time |
| 6 | **Smarter mesh detail by distance** (Roblox's new mesh streaming: ~60% fewer triangles in their example, "nearly identical" look). | Faster frames in the busy town. But in Aug 2026 players reported meshes stuck blurry or blocky. | Same when it works | Small to switch on in a test copy; wait until the bug reports stop |
| 7 | **SLIM for far buildings.** Roblox merges each far building into one light piece; the whole building switches together. | Cheaper far town with *no pop-in* (one of your goals). Needs **Team Create** turned on for the place: an account setting only you can choose. | Far buildings simplified | Medium; needs your OK on Team Create |
| 8 | **Shadows only where you can see them.** Tiny pieces (rug toys, plane trim) draw into the shadow pass too. Turning off shadows that are invisible anyway saves work. | Smoother frames, mostly on PCs with shadows on. Any shadow you *can* see stays, or comes to you as a choice with pictures. | Same (checked by screenshot) | Small |
| 9 | **A full 12-plane match measured properly** (already due in Stage 11): frame time, server steps per second, network data, phone memory. Roblox changed how moving objects are sent in mid-2026, so old numbers may not hold. | Tells us which of the above actually matters before anyone builds anything. | Same | Small (a bot match in the background plus one phone join) |
| 10 | **Bots' thinking, only if the check shows it's heavy:** Roblox can compile hot server maths to faster machine code (`@native`), or split it across processor cores. | More or smarter bots for the same server cost. Only works on the server (not on PC players' machines). | Same | Small to try once measured |

## Things that would cost detail (only with your OK)
Smaller textures, shadows off where you'd notice, fewer particles, simplified far buildings, smaller view distance.
None is recommended now; they're listed in the skill's `reference/costs-detail.md` so they never happen quietly.

## Gaps
Roblox publishes no phone memory limit, no per-effect cost numbers, and no hard draw-call budget; the mesh streaming
and SLIM release states couldn't be confirmed past mid-2026. Several "facts" from the forum (including from the
starting guide) turned out disputed or outdated; the skill marks each with its date and confidence.

Back to [HOME](../HOME.md)
