# HANDOFF — 2026-11-18 — Missions seen in Play by Alan (3 rounds); tests 746/746; next: packer fix + one tinted card paper + gold-star tick slip

**Labels:** kind=ui+product · lane=beta-lane · branch=main · issues=none · areas=src/client/MissionsScreen.luau, src/client/MissionsDropdown.luau, src/client/MenuBoard.luau, src/client/DeskHangar.luau, src/client/RoundEnd.luau, src/client/DevTools.luau, src/server, tests/unit/Missions.spec.luau, assets/ui/sheets, docs
**Time:** 2026-11-18 19:45 -05:00

★ START HERE: Goal: the missions screens look finished with no added load. Opening action: fix `tools/ui_sheets.py` (it crashes with `KeyError: 103691943840633` AND wipes `assets/ui/sheets/ready` + `uploads` before crashing: `git checkout -- assets/ui/sheets` restores) so a repack runs; then make ONE plain white card-shaped piece of the desk construction paper, tinted green/yellow/red/blue in the game, packed into free space on an existing sheet. Done when the mission cards' torn edges look clean on a Play screenshot and Alan OKs it.

> Read on demand: AGENTS.md → THIS → `docs/decisions/2026-11-18-daily-and-weekly-missions.md` (the two "After ... look" paragraphs hold every ruling) → `docs/playtests/2026-11-18-missions-first-look.md`. Memories: load-first-reuse-art (new), fix-the-annoyance-only, alan-does-play-checks, design-theory skill, offer-pieces-catch-the-eye.

## STATE (verify before acting)
- HEAD `db564ce1` (main) + this handoff's commit; pushed (hook copies to GitHub). Confirm: `git rev-parse --short HEAD`.
- Tests: **746/746 pass** (Studio Play server run 2026-11-18, then Missions.spec 18/18 in Edit after its fix). Re-run (Alan's go for the Play): `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()` on the Server; pure-rules specs also run in Edit with `require(spec).run()`.
- Rojo: `"%LOCALAPPDATA%\Rojo\bin\rojo.exe" serve serve.project.json --address 127.0.0.1 --port 34872` (this session's ran in the background; Alan's Studio was connected). A second Rojo on port 34880 is Alan's Chum-a-Chum project: leave it.
- Docs checker OK (206 pages). No place save, no upload, no publish this session.
- Cost: no subagents; ~4 h wall clock; main context ~66% at handoff.

## NEXT ACTION + PLAN
1. **Packer fix** (good Codex job: pure tool, checkable): `tools/ui_sheets.py` build must run on today's `src/first/UIAssets.luau` without wiping anything first. The desk strips stay packed small (Alan; `sizes.json` back to their old sizes). Check: a build writes ready/ + contact.png and `git status` shows only intended changes.
2. **One white card paper** from `assets/ui/deskmenu/source/strip-*.png` (lengthen with `tools/art/widen_paper.py ... 0 380:268 700:268`, never stretch; whiten so `ImageColor3` tints read as the four papers), saved at about 1069 x 164, packed into free space on a sheet already loaded. MissionsScreen cards then use it with a tint per tier (today they stretch `Assets.deskMenu.strip*`). Show Alan the four tints on the sheet before any upload; the repack upload needs his go.
3. **Daily/Weekly tabs bigger** on the Missions sheet (no new picture: drawn nearer their packed size).
4. **Tick slip → gold star** (Alan's pick): `UIArt.results.goldStar` slams down on the card's edge, then the note "Mission done! Check your Missions." with the Training board tick drawing itself; the star pulses. Code is `RoundEnd.luau` (slip block + RenderStepped). Test with Studio's **Dev: mission next match**.
5. Pictures to Alan after the design-theory checklist; then his Play look.
- **HOLDS (Alan's explicit go, each):** any Studio Play (tests included), place saves, publish (he does it), desktop control or screen grabs, bot matches, every upload, any new mechanic or number not in the decision.
- **Stop rule:** one independent visual review per preview, then show Alan.

## DECISIONS & WHY (this session; Alan's words in the decision page)
- **Load first:** no new picture sets; one tinted piece is the only addition he OK'd. Roblox shrinks/squashes pictures without smoothing, so a big master paper would look worse (I explained; he chose right-sized one piece).
- Main menu: plane stays at 1230,443 (its fly-in lands there). Stats card at 80% (`UIScale`, box 1465,63), Shop 1530,488, Missions 1530,562: measured on the real art, gaps 15/15/25, moved 50 left per his mark.
- Mission cards: construction paper coloured by difficulty (green easy, yellow medium, red hard; weekly 2/3/4-5 days the same; blue = 15 dailies). Never index cards (no stretching them).
- Desk: strip at 226,490 (phone centre 376,548), list at 232,581 (phone 232,596), tracing paper (`shop.tabCream`) 15% see-through, no scroll bar; bigger words/tabs/bar, goal sits on its bar.
- Dev: mission next match finishes one open mission (else reports the first daily) at the next match end, even an ineligible one (Studio mock only).
- Paper jar unchanged (shows only when Paper was added: AFK players don't matter).
- My calls (STATE "Decisions to review"): no "Reward" caption; phone stats lines 20% smaller; sheet has no phone layout yet.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md; memories load-first-reuse-art, fix-the-annoyance-only (I moved the approved plane once this session: never again), text-fits-its-box, paper-fits-its-content, design-theory skill before any screen.

## CARRY NOTES / GOTCHAS
- Equal-ZIndex siblings draw in no fixed order: set ZIndex whenever pieces overlap (fixed on the cards; check the tick slip/star too).
- The first dev match showed no slip: he did nothing that match; likely no stats row for him. The second showed it. If it recurs, check `state.mine` in RoundEnd (slip requires it).
- `docs/systems/menus-and-hud.md` "Where it stands" not yet rewritten for missions beyond the Code table lines.
- Repo files are CRLF; editing via Python with newline handling or the Edit tool works; `sed -i` on JSON multi-line arrays doesn't match.

## WHAT SHIPPED / OTHER QUEUED
- `57c30c45` Missions look from Alan's notes: construction-paper cards by difficulty, Missions under Shop with a smaller stats card, desk strip and tracing-paper list a sliver apart, report card tick slip and Dev: mission next match
- `7da2fe1f` Desk strips load full size so the Missions cards stay sharp; lesson: the menu-sheet packer is out of date
- `f00abf27` Missions test: a 50-fold match, not 100; all 746 unit tests pass
- `9f833857` Missions: the card paper sits under its week, count and reward; desk list bigger, no scroll bar; Alan's playtest notes
- `e352c5aa` Desk strips packed small again (load first); Alan's picks: one tinted card paper, bigger tabs, gold-star tick slip, Paper jar unchanged
- `db564ce1` STATE under 60 lines
- This handoff's commit. Queued: the beta queue in `state/STATE.md`.

## KNOWLEDGE UPDATED
- `docs/decisions/2026-11-18-daily-and-weekly-missions.md`: two "After ... look" paragraphs (all rulings above).
- `docs/playtests/2026-11-18-missions-first-look.md` (new, indexed): Alan's three rounds of notes.
- `docs/workshop/lessons.md`: packer out of date + wipes its folder; measure placement on real art; ZIndex for overlaps; no smoothing on shrink.
- `docs/systems/menus-and-hud.md` Code table lines for MissionsScreen/MissionsDropdown. `state/STATE.md` rewritten lines (60). Memory: load-first-reuse-art. Checker OK.

## POINTERS
- `src/client/MissionsScreen.luau` (CARD/STRIP/LEVEL constants, `MissionsScreen.bar`), `src/client/MissionsDropdown.luau` (SIZES, SEE_THROUGH), `src/client/MenuBoard.luau` (CARD_SCALE), `src/client/RoundEnd.luau` (slip), `src/server/ProfileService.luau` `_matchMissions` (dev path), `src/first/UISheets.luau`, `tools/ui_sheets.py`, `tools/art/widen_paper.py`.
