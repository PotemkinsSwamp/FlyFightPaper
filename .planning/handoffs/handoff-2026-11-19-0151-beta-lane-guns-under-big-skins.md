# HANDOFF — 2026-11-19 — Big skins sized by the screen (done, Alan OK); guns under big skins mostly fixed; pellet gun flipped

**Labels:** kind=product+ui · lane=beta-lane · branch=main · issues=none · areas=src/shared/SkinFit.luau, src/shared/Aircraft.luau, config/skin-sizes.json, config/skin-undersides.json, tools/skin_sizes.lua, tools/skin_undersides.lua, tools/art/plane_pieces.py, assets/models/planes/pieces.rbxmx, tests/unit/SkinFit.spec.luau, docs
**Time:** 2026-11-19 01:51 -05:00

★ START HERE: Goal: every gun under a big skin touches it and hides its clip from straight above (Alan's rule below). Open the gaps that are left (list under NEXT), re-run the sweep, then ask Alan's go for the tests in Play and give him a what-to-look-at list. Done when the sweep shows small guns (spitball, pellet, thumbtack, paperclip, popper, staple) with clips 100% hidden on every skin, long guns centred on the wing, no gun floating >0.1 stud at its clip, tests pass, and Alan says it looks right in Play. Then emotes and redoing the winners' circle (Alan's next).

> Read on demand: AGENTS.md → THIS → `docs/systems/planes-and-hangar.md` (big skins + "Guns under a big skin" paragraph) → `src/shared/SkinFit.luau` evenFit `hang()`. Memories: alan-does-play-checks, mute-studio-tests, studio-play-grabs-mouse, plan-before-building-features.

## STATE (verify before acting)
- HEAD `e99d414a` (main) + this handoff's commit; pushed, GitHub copy made by the hook. Confirm: `git rev-parse --short HEAD`.
- Tests: 749/749 at `4f7c36e4` (screen-size table). NOT run since the gun changes (`3bd430e0`..`e99d414a`, incl. the rewritten Dragon gun test). Run on the Server in Play (Alan's go; DevMute on first, off after): `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- Studio: Edit mode, Rojo serve running, DevMute off. **The pellet flip is live in the open place's `Assets.AircraftPieces.launcher_pellet` (set by script, same numbers as `pieces.rbxmx`): needs Alan's Ctrl+S** (he was saving). `_G.WM` holds my checker (EditableMeshes; not saved, gone on restart).
- Cost this session: no subagents, no Codex, no uploads; ~3 h; main context ~75% at handoff.

## NEXT ACTION + PLAN
1. Finish the gun gaps (2026-11-19 sweep, 5,040 legal body x wings x weapon x slot guns under the six even skins):
   - Edge slivers: pellet/spitball/thumbtack/paperclip wing spots 96-98% hidden (cover check uses 0.1-unit cells with a half-cell margin; a full-cell margin pushed the spitball into the fallback). Alan: the spitball has no reason not to fit under every wing.
   - Popper and Staple wing guns 71-79% hidden (clip is a strip at the gun's back end).
   - Body-spot eraser/rubber/spitball/thumbtack: 0.1-0.25 stud gap where the skin's body meets its wing.
   - Origami crane keeps its own rule (not checked against the new rule).
   - Checker caveat: my "out at one end only" metric splits by the gun's halves, wrong for clips at one end of the gun (popper, staple, crayon); split by the clip's halves.
2. Tests (his go), then his Play look: guns under Ninja/Race Car/Stealth with spitball, pellet, rubber band; pellet gun on a plain plane.
3. Then emotes and the winners' circle redo (Alan 2026-11-19). Plan-first rule: a how-it-works note for his OK before code.
- **HOLDS (Alan's explicit go, each):** any Studio Play (tests included), place saves, publish (he does it), desktop control or screen grabs, bot matches, uploads, any new mechanic or number.
- **Stop rule:** small guns 100% hidden + long guns centred + no clip gap >0.1 = build is done; don't keep tuning past that without his Play look.

## DECISIONS & WHY
- **Screen-size table** (Alan's ruling, done, "sizes look right"): `config/skin-sizes.json` per skin x body = wings size x nose x tail multipliers, stored against the wingspan (body+wings alone missed by up to 45% with other noses/tails). Old plane-areas rule deleted.
- **Guns under big skins** (Alan 2026-11-19, in `docs/decisions/2026-11-14-shape-skin-model-sheets.md`): touch the skin, tilt to its slope (max 15°; Race Car body guns ~5°). **Only the clip must hide from straight above**; small guns fully under the wing; long guns may stick out but centred on the wing front to back, never half off one edge.
- Clip = measured patch of each weapon's top within 5% of its height (`clips` in `config/skin-undersides.json`); a gun's whole top piece was far too big (the spitball's body mesh includes its straw).
- Underside grid per skin at 0.1 stud, own frame, right half; guns may move under the skin's body if the wing can't hide them; inner gun placed first, others avoid it.
- **Pellet gun flipped on every plane**: its cradle was modelled sitting on a desk (straw up; `mount: bottom` meant on top of the wing); now hangs by the cradle's flat bottom (`FLIP` in `tools/art/plane_pieces.py`; Aircraft's pellet exception removed).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (screen-size rule for new skins; now also run `tools/skin_undersides.lua` for a new skin or weapon model). Memories: alan-does-play-checks, mute-studio-tests, plan-before-building-features.

## CARRY NOTES / GOTCHAS
- Edit-mode `require` is cached: clone the module (and any generated module it reads, renamed) before requiring fresh source.
- Big Studio results: keep them in `_G`, pull to a file with `FULL=1 python tools/studio_cli.py execute_luau '{"code": "<file.lua>", ...}' > out.txt` (keeps 30 KB out of context).
- `SkinFit.plane` with a long gun that fits nowhere took ~17 ms (scan of every spot); fine now, watch it if wear hitches at match start.
- Eraser's hanger is narrower than a coarse ray grid: use ≥16x40 samples or it reads as a 1.3-stud gap.

## WHAT SHIPPED / OTHER QUEUED
- `9144ffe3` Big skins cover as much of the screen as the plane without a skin: measured table
- `4f7c36e4` State: 749/749 tests pass with the screen-size table
- `c5bc77b1` Delete the old big-skin size rule's leftovers
- `5ef701d4` State: next is guns under big skins, then emotes and the winners' circle; speed worry dropped
- `3bd430e0` Pellet gun hangs upside down by its paper cradle's flat bottom
- `73718ac2` Guns under big skins touch the skin and hide their clip: underside grids and weapon clips
- `e99d414a` Guns that can't hide their clip stay centred on the wing; Alan's rule
- Queued: emotes + winners' circle redo (next after guns); the rest of the beta queue in `state/STATE.md`.

## KNOWLEDGE UPDATED
- `docs/systems/planes-and-hangar.md`: big skins sized by the screen; guns-under-skins paragraph with sweep numbers and open items; pellet hang; tools rows. `docs/decisions/2026-11-14-shape-skin-model-sheets.md`: built table; Alan's gun rule. `docs/workshop/tools.md`: skin_sizes, skin_undersides rows (plane_areas removed). `docs/workshop/lessons.md`: plane_areas pointer replaced. `state/STATE.md` (59 lines). Checker: OK (207 pages).

## POINTERS
- `src/shared/SkinFit.luau` (screenSize, gridOf, evenFit hang), `src/shared/Aircraft.luau` (Look attribute on gun parts), `config/skin-sizes.json`, `config/skin-undersides.json`, `tools/skin_sizes.lua`, `tools/skin_undersides.lua`, `tests/unit/SkinFit.spec.luau` (Dragon gun + table coverage tests), `assets/models/toys/weapon-pellet/ref.png` (cradle design), `.planning/new-weapons-concepts.jpg`.
