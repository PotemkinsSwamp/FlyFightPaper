# HANDOFF — 2026-11-16 — Scripted Play checks done: Rares fixed and moving in Play, trails match, worst-case frame rate open; shop list of 13 next

**Labels:** kind=product+ui · lane=beta-lane · branch=main · issues=none · areas=src/client/PlaneLooks.luau, tools/art/skin_looks.py, tools/looks_check, tests/unit/SkinMotion.spec.luau, docs/playtests, docs/workshop/lessons.md, state/STATE.md
**Time:** 2026-11-16 18:05 -05:00

★ START HERE: Goal (Alan 2026-11-16): finish the beta's looks. **Changed at Alan's request after this handoff was first written**, his words: "We are not worrying about price right now, next we are going to look at our handoffs and past work and figure out how to make the legendary skins starting with the shark." Opening action: read the past work on shape skins and the Shark Jet (pointers in NEXT ACTION) and bring Alan a plain how-we-make-it plan for the **Shark Jet**, with its approved sheet (`.planning/skins/model-sheets/shark-jet-a4.png`) shown first. Done when Alan has OK'd a plan for the Shark; nothing is built, briefed or uploaded before that.

> Read on demand (pointers, never "in full"): AGENTS.md → THIS; `docs/playtests/2026-11-16-scripted-looks-check.md` for every number and finding; `docs/workshop/lessons.md` ("Scripted Play tests", "Moving skin layers" last bullet) before any Play; `docs/plan/SKINS-PLAN.md` for the shop and Trails tab. Memories: latest-approved-reference-first, measure-concept-before-brief, one-skin-across-parts, question-each-recipe-step, no-meshy-blender-only, plan-before-building-features, studio-not-drawing, edit-tests-have-plugin-rights, alan-does-play-checks, no-surprise-desktop-control, mute-studio-tests, text-fits-its-box, familiar-roblox-layouts.

## STATE (verify before acting — state drifts between sessions)
- HEAD: this handoff's commit on `main`, copied to GitHub by the hook. Confirm: `git rev-parse --short HEAD`, `git log --oneline -5`.
- Docs: `python tools/check_docs.py` → "docs OK: 197 pages".
- Tests: **672 passed, 0 failed in Play** on the code of `944de9cb` (only docs and `tools/looks_check` changed after). Re-run (Alan's go, DevMute on, screen kept awake): Server `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- Studio: Edit, DevMute off, place NOT saved, Rojo running, no test switches left on the workspace. The mouse nudge is stopped. Tripo credits 5,820, none used. No uploads this session.
- Cost last session: no helper agents; one Fable session, about 2 hours, wrapped up at the context check (never compacted). Studio Play: about 50 minutes (planned 12) plus 7 minutes.

## NEXT ACTION + PLAN
1. **Legendary skins, the Shark Jet first** (above). Where the past work is: `docs/decisions/2026-11-14-shape-skin-model-sheets.md` (Shark Jet A picked, sheet `shark-jet-a4.png`, a barrel body); `docs/plan/SKINS-PLAN.md` (Legendary = the printed sheet plus add-on pieces; the list: shark jet, bumblebee, rocket, hot rod, stealth fighter, mech, pirate, ninja; about 4,000 triangles a skin; the Blender joints test); `.planning/skins/shark/`, `.planning/skins/model-sheets/`, `.planning/skins/concepts/legendary-*.png`; the Dragon's road into the game as the worked example (handoffs `2026-11-15-skins-lane-dragon-whole-body-round-14` and `2026-11-16-0054-beta-lane-dragon-skin-in-game-skin-set-next`, `docs/playtests/2026-11-16-dragon-skin.md`, `config/skin-shapes.json`, `src/shared/SkinFit.luau`); the `concept-to-blender` skill. Today Shark Jet has no picture and no shape and its trail `water_spray` has no drawing. One thing to settle with Alan in the plan: the skins plan says a Legendary is add-on pieces on the real plane, the model-sheet decision drew the Shark as a whole barrel body.
1b. **Shop list of 13 trails** (`config/looks.json` and the shop products are still the old five, so a bot that rolls Rainbow Marker flies with no trail): the 13 in the list, the Trails tab and the shop, bots only roll trails that are drawn, the whole test set passing in Play. Price is parked (Alan). Tests with hand-typed counts: `Looks.spec` (22 look products), `CommerceService.spec`. Any screen that changes gets the design-theory checklist and Alan's look before it counts.
2. **Worst-case frame rate.** Numbers (12 planes, Studio, Alan's PC): 60 with nothing, with any one skin, with any one Rare moving; 56.7-60 with one trail on all 12; 58.5 with a mixed set on every plane; **54.5 with 12 Galaxy + 12 Circuit Trace** (each alone holds 60). Not known: which work the two share. Find it (Roblox's frame profiler), then fewer parts a second before any change of look; a changed number is Alan's OK. Re-measure with `tools/looks_check/` (`ClaudePart` = `rares` or `ab`).
3. **Alan's own Play look** at the 13 trails and the 8 Rares (he has given no notes yet). Only his eyes: whether each looks right, glow pictures, sparkles or smoke starting in clumps, the still undersides.
4. **A trail on the plane in the Hangar**: a how-it-works note with options to Alan first (smoke and sparkles cannot draw inside the Hangar's plane picture).
5. Rares follow-ups from his notes; the Dragon leftovers (`state/STATE.md`); Shark Jet is still not made (draws nothing).

**Holds, each needing Alan's go:** any Studio Play (tests included), place saves, publish (he does it), desktop control or screen grabs, Tripo credits (tell him the count first), bot matches, any new mechanic or number. Every picture or model: his OK on a preview, then the safety sheet, then upload. **Not a hold any more:** keeping his screen awake during a Play he has OK'd (see DECISIONS).

## DECISIONS & WHY (this session)
- **Alan, after the handoff: Legendary skins come next, the Shark first, by looking at our own handoffs and past work; price is not a worry now.** The shop list moved to second.
- **Alan: "you are going to have to keep it awake while you need the screen drawing"** (said twice). His screen sleeps after 60 idle seconds and Studio then draws nothing. Start the one-pixel mouse nudge before a Play that must draw, stop it after; never ask him to wake it.
- **His "Go" to my three end-of-session questions is read as:** keep the saved id `rainbow_marker` behind the name Holo Rainbow (my recommendation); leave the Rare-match trail price at the 99 Robux / 1,900 Paper stand-in; no Play notes from him yet. It is a reading of one word: it sits in `state/STATE.md` ("Decisions to review" and "Waiting on Alan") for him to reverse.
- **A Rare's layer Decals are made ahead** (`skin_looks.py` → `SkinLooks/<skin>/Layers`), cloned by `PlaneLooks`. A game script may not write `Decal.EmissiveMaskContent`; every earlier test ran through the Studio link, which has plugin rights, so all eight passed there and none moved in Play.
- **The test forces looks through each plane's `Skin` and `Trail` attributes**, from the test's own script. No bot-skin switch was added to the game.
- **`tools/looks_check/` is kept in the repo** on purpose: the frame-rate bar has to be re-measured after any trail or skin change.
- **Confetti's one reading of 51 is treated as noise**: four later runs inside one flight read 60. Where the plane is moves the number more than a trail does, so compare inside one flight.

## CONSTRAINTS / PRINCIPLES
- `AGENTS.md`; memories in the read line; also no-quality-cuts-for-fps, hand-made-not-generic-roblox, plan-before-building-features, playtest-notes-before-handoff.

## CARRY NOTES / GOTCHAS
- The Studio link keeps old copies of modules it has `require`d: an Edit read showed 3 trails when the game had 13. Clone the module and what it requires, or read it in Play.
- Edit-mode spec runs through the Studio link are not trustworthy for the same reason (four suites "failed" on stale copies). The real run is the test set in Play.
- `tools/studio_cli.py` takes a code file path and ran beside the session's own Studio tools without breaking them. `loadstring` works in Edit only (compile checks), not in the Play client.
- The `loop` autopilot must be re-set on every takeoff or the plane crashes two seconds into each life (the client half does it).
- Not tested: the server's hit shapes for Dragon and Crane on bots; Slime's glow pulse (read over too few frames); phones.
- The log the Studio link reads holds about 300 lines. It shows 21 "No asset content representation found" lines: Studio asking for a packed copy, not a missing picture.
- Resting trail parts are never freed (4,705 after every trail had been on all 12 planes; memory flat). Fine in a real match; a note for the frame-rate work.
- The 15:53 handoff's carry notes still hold (a dismissed question is not a yes, the Dev: trail button's words never seen on screen, shell traps).

## WHAT SHIPPED / OTHER QUEUED
- `944de9cb` Rare skins: moving layers are made ahead so they work in real Play; a skin with no picture takes the old skin off
- `9574583f` Scripted Play check of all 19 skins and 13 trails: frame-rate numbers, what differs, the tool and the lessons
- `deeeb44b` Rares confirmed moving in a second Play (game's own code), 672 tests pass; worst-case frame rate traced to Galaxy and Circuit Trace together
- This handoff's commit (handoff, LATEST, `state/STATE.md`).
- Queued, not started: plan steps 1 to 5; everything else in `state/STATE.md`.

## KNOWLEDGE UPDATED
- `docs/playtests/2026-11-16-scripted-looks-check.md` (new): both Play runs, every number, what differs skin by skin and trail by trail.
- `docs/workshop/lessons.md`: "Scripted Play tests" (screen sleep, autopilot, comparing inside one flight, stale modules, forced looks, the short log); "Moving skin layers": a game script cannot set a Decal's glow picture.
- `docs/systems/performance.md` (the looks numbers and what is next), `docs/systems/planes-and-hangar.md` (Rares fixed and seen moving), `docs/plan/SKINS-PLAN.md` (layers made ahead), `docs/workshop/tools.md` (`looks_check`, `skin_looks.py`'s Layers), `state/STATE.md` (59 lines).
- Memory: studio-not-drawing (rewritten: keep the screen awake myself), edit-tests-have-plugin-rights (new).
- AAR: the first Play ran four times its plan because the screen slept, the autopilot looped into crashes, and the test set was left out of it; all three are now in the tool or the lessons. No skill or CLAUDE.md change proposed.
- Checker: `python tools/check_docs.py` → docs OK, 197 pages.

## POINTERS
- Game: `src/client/PlaneLooks.luau`, `src/client/PlaneTrails.luau`, `config/looks.json`, `config/trails.json`, `src/shared/LooksRules.luau` (bots' roll), `src/client/ShopScreen.luau`, `src/client/HangarCustomize.luau`.
- Tools: `tools/looks_check/client_sampler.lua`, `tools/looks_check/server_plan.lua`, `tools/studio_cli.py`, `tools/art/skin_looks.py`.
- Previous handoff: `handoff-2026-11-16-1553-beta-lane-all-13-trails-in-game-play-look-next.md`.
