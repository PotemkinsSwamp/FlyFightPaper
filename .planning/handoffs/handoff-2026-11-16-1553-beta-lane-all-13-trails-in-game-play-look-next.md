# HANDOFF — 2026-11-16 — All 13 trails are in the game; nobody has seen one in Play; Alan's Play look is next

**Labels:** kind=product+ui · lane=beta-lane · branch=main · issues=none · areas=src/client/PlaneTrails.luau, config/trails.json, tools/art, tests/unit/Trails.spec.luau, docs/plan/SKINS-PLAN.md, docs/decisions
**Time:** 2026-11-16 15:53 -05:00

★ START HERE: Goal (Alan 2026-11-16): finish the beta's looks; trails first. Opening action (Alan's ask, same day): run a Play test **by script only, no screen grabs and no desktop control**, that (1) measures the frame rate of a 12-plane match with every bot wearing a skin and a trail, and (2) looks for anything wrong with every skin and every trail by reading what the game actually put on the planes against the config. Done when Alan has the numbers (does it hold 60?) and a plain list of what differs, skin by skin and trail by trail; then fix what the list and his own Play notes show.

> Read on demand (pointers, never "in full"): AGENTS.md → THIS; the handoff before this one (same day, 15:18) for this session's decisions and gotchas, which all still hold; `docs/plan/SKINS-PLAN.md` ("Trails: how it works") and `docs/workshop/lessons.md` ("Trails") when the step needs them. Memories: effects-are-3d-shown-in-3d, alan-does-play-checks, no-surprise-desktop-control, look-at-textures-before-upload, mute-studio-tests.

## STATE (verify before acting — state drifts between sessions)
- HEAD: this handoff's commit on `main`, copied to GitHub by the hook. Confirm: `git rev-parse --short HEAD`, `git log --oneline -3`.
- Docs: `python tools/check_docs.py` → "docs OK: 196 pages".
- Tests: 671 passed, 0 failed in Play at `dcabf8b5`. Since then only trail drawing changed: `Trails.spec` passes 5 of 5 on fresh copies in Studio Edit, and all 13 trails ran through the real drawing code there with the real uploaded models (notes stand head-down, little planes fly nose-first, right way up). **Whole set not re-run in Play since** (Alan's go): DevMute on, Play, Server: `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- **No trail has been seen in Play by anyone.** The 12-plane frame-rate check is not done.
- Studio: Edit, DevMute off, place NOT saved, Rojo connected. Eight trail models uploaded, all Approved (`assets/models/trails/upload-<piece>.json`): star, bolt, curl, note, notes, petal, dart, jog. Tripo credits 5,820, none used.
- Cost last session: no helper agents; one Fable session past half its context (wrapped up on the context check, never compacted). About 40 Blender videos and still sets on this PC, free. Eight free model uploads.

## NEXT ACTION + PLAN
1. **The scripted Play test Alan asked for** (his words: "i want next session to do a play test without grabbing the screen so just a script and measure the performance if all bots have trails and skins also look for visual discrepancies of all the skins and trails"). This ask is his go for that Play run and its bot match; DevMute on first, off after. Two results:
   - **Frame rate:** a 12-plane match with every bot in a skin and a trail (the bots' own roll leaves some bare, so the test must force it), against the same match with none. Report average and slowest frames; the bar is a steady 60. Heaviest trails: Circuit Trace (about 100 moving parts a plane), Gold Stars, Glitch Pixels; heaviest skins: the moving Rares (Galaxy) and the Dragon. **First prove Studio is drawing:** last session it drew no frames (viewport 1 x 1, `RenderStepped` never fired) and every frame number would have been meaningless. If it is not drawing, ask Alan to put the Studio window in front; do not reach for the desktop.
   - **Discrepancies, by reading the game, not pictures:** for each of the 19 skins and 13 trails, what is really on the plane (pieces dressed, meshes and pictures loaded, moving layers present, trail emitters and parts made, their sizes, colours, materials, which way up) against the config and what Alan OK'd; plus every warning or error in the console. A script cannot judge whether something looks good: say so, and list what only his eyes can settle.
   - Levers that exist: the player attribute `DevTrail` (one trail on every plane on this screen), the `Dev: skin` button and `DevSkin` (own plane only), `DevPerf` (frame numbers), `DevBotTier`. Giving every bot a skin is not there yet; a Studio-only switch for it is test rigging, not a game rule.
2. **Alan's own Play notes on the 13 trails**, when he has them, then fixes. A turned-down look goes back to a video (two options) before any change he has not asked for. Whole test set in Play in the same run as step 1 (671 passed at `dcabf8b5`). If the frame rate dips: fewer parts a second first, never a different look (no-quality-cuts-for-fps).
3. **The shop list**: 13 trails in `config/looks.json` and the shop products (today the old five; every other trail is reached only through Dev: trail). Two things are Alan's first: keeping the saved id `rainbow_marker` under the name Holo Rainbow (my lean: yes, testers may own it), and the Rare-match price (stand-in 99 Robux / 1,900 Paper, parked by him). Tests with hand-typed counts: `Looks.spec` (22 look products), `CommerceService.spec`.
4. **A trail on the plane in the Hangar** (its plane sits in a ViewportFrame, where particles do not draw).
5. Rares follow-ups from his Play notes; the Dragon leftovers (`state/STATE.md`).

**Holds, each needing Alan's go:** Studio Play (tests included), place saves, publish (he does it), desktop control or screen grabs, Tripo credits, bot matches, any new mechanic or number. Every picture or model: his OK on a preview, then the safety sheet, then upload.

## DECISIONS & WHY (since the 15:18 handoff)
- **This handoff was changed at Alan's request** (2026-11-16, after it was first written): the next step is the scripted Play test above, not waiting for his Play notes. He wants no screen grabbing: last session's desktop tool hid his open windows.
- **Circuit Trace is OK'd on its third go** ("Looks good upload all"): bent traces, LEDs flashing in four colours, gold pads, chips, a slight green board cloud. His words on the first two: "mainly cloud", then "doesn't give a technology feel, the green circuit lines are to straight".
- **The bent-trace model got a short branch and a third pad before upload.** A bare zigzag line can be read as a rune; I checked its safety sheet myself and sent it to him after the upload (he had said "upload all" without seeing that sheet).
- **Mini Paper Planes replaces Paper Hearts** (his pick); Paper Hearts' draft row stays in `tools/art/trail_drafts.json` for a holiday set.
- Everything else: the 15:18 handoff and `docs/decisions/2026-11-16-first-skin-set.md`.

## CONSTRAINTS / PRINCIPLES
- `AGENTS.md`; the memories in the read line; also hand-made-not-generic-roblox, no-quality-cuts-for-fps, playtest-notes-before-handoff.

## CARRY NOTES / GOTCHAS
- The 15:18 handoff's carry notes all still hold (desktop control, a dismissed question is not a yes, the unverified `Emit` placement and resize step, the Dev: trail button's words never seen on screen, shell traps, the preview command).
- Looks that are my guesses until seen in Play: lit SmoothPlastic for `bright` cubes and chips; see-through SmoothPlastic for goo bubbles; smoke lit by lightning; Neon for traces and LEDs.
- An uploaded model arrives lying flat: Blender's up is +Z, Blender's +X is -X (`STAND` and the `level` turn in `PlaneTrails.luau` carry this).

## WHAT SHIPPED / OTHER QUEUED
- `cfaeb346` Handoff (beta lane): eleven trails in the game (the 15:18 handoff; it lists this session's earlier commits)
- `50d7ed29` Trails: all 13 are in the game: Circuit Trace (third go) and Mini Paper Planes, their two models uploaded
- This handoff's commit (handoff, LATEST).
- Queued, not started: plan steps 1 to 5; everything else in `state/STATE.md`.

## KNOWLEDGE UPDATED
- `docs/decisions/2026-11-16-first-skin-set.md`: "Looks good upload all" and what it covered. `docs/plan/SKINS-PLAN.md`: all 13 drawn. `docs/systems/planes-and-hangar.md`: thirteen trails. `docs/workshop/tools.md`: `trail_pieces.py` uploads. `docs/workshop/lessons.md` ("Trails"): a bare zigzag can be read as a rune. `state/STATE.md` (59 lines).
- Checker: `python tools/check_docs.py` → docs OK, 196 pages.

## POINTERS
- Game: `src/client/PlaneTrails.luau`, `config/trails.json`, `tests/unit/Trails.spec.luau`, `src/client/DevTools.luau` (Dev: trail).
- Tools: `tools/art/trail_preview.py`, `tools/art/trail_pieces.py`, `tools/art/trail_drafts.json`. Videos and safety sheets: `.planning/skins/trails/` (not in git).
- Previous handoff: `handoff-2026-11-16-1518-beta-lane-eleven-trails-in-game-circuit-and-planes-open.md`.
