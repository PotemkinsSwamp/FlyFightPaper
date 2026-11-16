# HANDOFF — 2026-11-16 — All 13 trails are in the game; nobody has seen one in Play; Alan's Play look is next

**Labels:** kind=product+ui · lane=beta-lane · branch=main · issues=none · areas=src/client/PlaneTrails.luau, config/trails.json, tools/art, tests/unit/Trails.spec.luau, docs/plan/SKINS-PLAN.md, docs/decisions
**Time:** 2026-11-16 15:53 -05:00

★ START HERE: Goal (Alan 2026-11-16): finish the beta's looks; trails first. Opening action: ask Alan for his notes from flying the 13 trails with the Dev: trail button (the list of what to look at is in `state/STATE.md`, "Waiting on Alan") and fix what he reports. Done when he has seen all 13 in Play and says they match his videos, the whole test set passes in Play and a 12-plane match holds 60 frames a second.

> Read on demand (pointers, never "in full"): AGENTS.md → THIS; the handoff before this one (same day, 15:18) for this session's decisions and gotchas, which all still hold; `docs/plan/SKINS-PLAN.md` ("Trails: how it works") and `docs/workshop/lessons.md` ("Trails") when the step needs them. Memories: effects-are-3d-shown-in-3d, alan-does-play-checks, no-surprise-desktop-control, look-at-textures-before-upload, mute-studio-tests.

## STATE (verify before acting — state drifts between sessions)
- HEAD: this handoff's commit on `main`, copied to GitHub by the hook. Confirm: `git rev-parse --short HEAD`, `git log --oneline -3`.
- Docs: `python tools/check_docs.py` → "docs OK: 196 pages".
- Tests: 671 passed, 0 failed in Play at `dcabf8b5`. Since then only trail drawing changed: `Trails.spec` passes 5 of 5 on fresh copies in Studio Edit, and all 13 trails ran through the real drawing code there with the real uploaded models (notes stand head-down, little planes fly nose-first, right way up). **Whole set not re-run in Play since** (Alan's go): DevMute on, Play, Server: `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- **No trail has been seen in Play by anyone.** The 12-plane frame-rate check is not done.
- Studio: Edit, DevMute off, place NOT saved, Rojo connected. Eight trail models uploaded, all Approved (`assets/models/trails/upload-<piece>.json`): star, bolt, curl, note, notes, petal, dart, jog. Tripo credits 5,820, none used.
- Cost last session: no helper agents; one Fable session past half its context (wrapped up on the context check, never compacted). About 40 Blender videos and still sets on this PC, free. Eight free model uploads.

## NEXT ACTION + PLAN
1. **Alan's Play notes on the 13 trails**, then fixes. Check: his words in a `docs/playtests/` note; a turned-down look goes back to a video (two options) before any change he has not asked for.
2. **Whole test set in Play and the 12-plane frame-rate check** (his go, each). Heaviest trails: Circuit Trace (about 100 moving parts a plane), Gold Stars, Glitch Pixels. If it dips: fewer parts a second first, never a different look (no-quality-cuts-for-fps).
3. **The shop list**: 13 trails in `config/looks.json` and the shop products (today the old five; every other trail is reached only through Dev: trail). Two things are Alan's first: keeping the saved id `rainbow_marker` under the name Holo Rainbow (my lean: yes, testers may own it), and the Rare-match price (stand-in 99 Robux / 1,900 Paper, parked by him). Tests with hand-typed counts: `Looks.spec` (22 look products), `CommerceService.spec`.
4. **A trail on the plane in the Hangar** (its plane sits in a ViewportFrame, where particles do not draw).
5. Rares follow-ups from his Play notes; the Dragon leftovers (`state/STATE.md`).

**Holds, each needing Alan's go:** Studio Play (tests included), place saves, publish (he does it), desktop control or screen grabs, Tripo credits, bot matches, any new mechanic or number. Every picture or model: his OK on a preview, then the safety sheet, then upload.

## DECISIONS & WHY (since the 15:18 handoff)
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
