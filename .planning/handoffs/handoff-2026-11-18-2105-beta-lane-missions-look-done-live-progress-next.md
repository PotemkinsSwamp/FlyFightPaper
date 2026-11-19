# HANDOFF — 2026-11-18 — Missions look done and seen in Play (cut-paper cards, fuller cards, gold star); next: live mission progress during a match

**Labels:** kind=ui+product · lane=beta-lane · branch=main · issues=none · areas=tools/ui_sheets.py, tools/art/cut_paper.py, src/client/MissionsScreen.luau, src/client/RoundEnd.luau, src/first, assets/ui/mainmenu, assets/ui/sheets, docs
**Time:** 2026-11-18 21:05 -05:00

★ START HERE: Goal: missions show their progress live while a match is played (Alan's ruling, below). Opening action: write a short how-it-works note for the build (which counts update live, how they reach the screen, what still ticks at match end) and build it; the counting rules are a good Codex job (pure logic + unit tests). Done when, in Studio Play (Alan's go), a damage and a speed-boost mission's bar moves on the desk Missions list mid-match, the saved progress after the match equals what was shown, and **Dev: finish missions** pressed mid-match gives the report card's gold star at the end.

> Read on demand: AGENTS.md → THIS → `docs/decisions/2026-11-18-daily-and-weekly-missions.md` (the "Live progress" paragraph is the ruling) → the missions code it touches. Memories: plan-before-building-features, alan-does-play-checks, studio-not-drawing, mute-studio-tests, paper-fits-its-content.

## STATE (verify before acting)
- HEAD `e8e2aa2e` + this handoff's commit (main); the commit hook copies to GitHub ("github: pushed"); plain `git push` has no upstream, that is normal. Confirm: `git rev-parse --short HEAD`.
- Tests: not re-run this session (client and tool changes only). Last: 746/746 (2026-11-18). Re-run (Alan's go for Play): `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()` on the Server.
- Studio: Play stopped, DevMute cleared, keep-awake nudge stopped. Rojo serve (ours) running and synced; Alan's Chum-a-Chum Studio + Rojo also open: leave them.
- Uploads this session (both Approved): white card `84680888117475`, menu sheet-3d-7 `136956893329600`. No place save, no publish.
- Docs checker OK (206 pages).
- Cost: 2 Sonnet visual reviewers (~108k and ~107k tokens); ~3.5 h wall clock; main context ~45% at handoff.

## NEXT ACTION + PLAN
1. **Live mission progress** (ruling in the decision page): server adds the match's running counts (folds, damage, speed boosts, targets, Paper) to saved progress and sends them to the player whenever they change; desk list + Missions sheet show it; "in one match" missions show the running count; wins / top 3 / "folded N or fewer" still tick at the end; saving stays once at match end; any mission finished during the match (incl. Dev: finish missions) gets the gold star at the end. **No mid-flight popup.** Check that the live number and the saved one never disagree.
2. Studio Play check (Alan's go), then pictures + his Play look.
3. Optional, ask first: the Daily/Weekly tabs and Claim/Swap buttons are still the crumpled-paper style shared with other menus (Alan wants the Missions sheet neat; he has not ruled on these).
- **HOLDS (Alan's explicit go, each):** any Studio Play (tests included), place saves, publish (he does it), desktop control or screen grabs, bot matches, every upload, any new mechanic or number not in the decision.
- **Stop rule:** one independent visual review per preview, then show Alan.

## DECISIONS & WHY (this session; Alan's words in the decision page and playtest note)
- Cards: Alan rejected the whitened torn desk strip ("ragged and crumpled up"); he wants neat, flat construction paper cut by a child. Now `tools/art/cut_paper.py ... 1004 154 47`, tinted in code (`TINT` in MissionsScreen). Tints reproduce the desk strips' colours.
- Load: the card went into free space on menu sheet-3d-7 (`ui_sheets.py --add`): 2 uploads, nothing else moved. A full repack would have been 10 uploads and ~0.6M more pixels.
- I kept UISheets' `["3d"]` list as before (only the sheet id swapped): `--upload` wanted to switch 9 newer menu pictures (report card included) to the 3D drawing, untested. MissionsScreen itself now draws 3D like the other menus (added to MENU_GUIS in MenuArt + ui_sheets).
- No empty space (Alan, marked screenshot): goal 52 (42 if over 58 letters), bar 400, count/reward 40, rewards right-aligned with the chest after, calendar squares 50, Daily cards 200 tall, tabs 300 x 84.
- Gold star replaces the slip's tape; placed lower/smaller (401,-32,108,101 page px) so it stays on a 16:9 screen; it slightly covers "101" in the card's title (my call, in STATE).
- Why Alan saw no star: he used **Dev: finish missions** (marks missions done mid-match); today the star needs the match's own stats to finish one at match end. His live-progress ruling makes that button give the star.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md; memories load-first-reuse-art, fix-the-annoyance-only, text-fits-its-box, paper-fits-its-content (now: fill fixed-size cards), design-theory skill before any screen, plan-before-building-features.

## CARRY NOTES / GOTCHAS
- Results phase is short: freeze the report card with workspace attribute `DevCardTime` (Client) right after the star shows; the star starts at card time ~1.25.
- `DevScreen` = "missions" opens the sheet; the Weekly tab needs a click (`...MissionsLayer.weeklyTab`). Server dev action `endMatch` ends a match.
- Studio's window is 2046 x 801 (short): the report card sits at the top; measure in sheet units, not by eye.
- `TextScaled` caps in screen pixels under the sheet scaling: use fixed sizes (lesson added).
- Untracked `tools/art/hero.py.old`, `assets/ui/shop/raw|source`: not this session's; leave.

## WHAT SHIPPED / OTHER QUEUED
- `6d27a4e1` Menu-sheet packer runs again; `--add` puts a new piece into free space on a loaded sheet
- `5e1e9966` Missions cards: one white cut-paper card tinted by difficulty, packed on a loaded sheet; bigger tabs; gold star; Missions screen drawn 3D
- `ebcaed71` Missions cards fill their paper; star lower; Alan's fourth-look notes
- `e8e2aa2e` Alan's ruling: live mission progress, star for any mission finished in the match, no mid-flight popup
- This handoff's commit. Queued: the beta queue in `state/STATE.md`.

## KNOWLEDGE UPDATED
- `docs/decisions/2026-11-18-daily-and-weekly-missions.md`: "After the fourth look" + "Live progress" paragraphs.
- `docs/playtests/2026-11-18-missions-first-look.md`: fourth-look section with pictures.
- `docs/systems/menus-and-hud.md`: Where it stands (2026-11-18) missions paragraph.
- `docs/workshop/lessons.md`: packer repack lesson rewritten; `--upload` rewrites the 3d list; TextScaled caps in screen px.
- `docs/workshop/tools.md`: `cut_paper.py`, `ui_sheets.py --add`. `state/STATE.md` (60 lines). Memory: paper-fits-its-content. Checker OK.

## POINTERS
- `src/client/MissionsScreen.luau` (CARD, TINT, card()), `src/client/MissionsDropdown.luau` (desk list), `src/client/RoundEnd.luau` (star + slip), `src/server/ProfileService.luau` (`_matchMissions`, dev finish), `src/server/RoundRuntime.luau` (~line 580 stats reward, `MissionsFinished`), `src/shared/Missions.luau` (`applyMatch`), `tests/unit/Missions.spec.luau`.
- Pictures: `.planning/missions/play-*.jpg`, `card-cut-preview.jpg`.
