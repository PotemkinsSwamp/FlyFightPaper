# HANDOFF — 2026-10-29 — mobile lane: Alan played the published phone fixes; his 7 new notes are the to-do list

**Labels:** kind=ui+product · lane=mobile-lane · branch=main · issues= · areas=docs/playtests, docs/decisions, state, .planning/handoffs
**Time:** 2026-10-29 01:10 -04:00

★ START HERE: Goal (Alan): mobile works and looks good. First: fix Alan's 2026-10-29 phone notes
(`docs/playtests/2026-10-29-phone-run-published-fixes.md`), each checked in Studio (phone size, and PC where he said
"PC too"). Done when every note is fixed and checked, then Alan's next phone run confirms. Before the handoff at the
end: ask Alan for playtest notes first (memory playtest-notes-before-handoff).

> Read on demand: AGENTS.md → this file → the earlier handoff `handoff-2026-10-29-mobile-lane-phone-fixes-await-publish.md`
> (what this build changed, Device Simulator tap offsets, Studio gotchas). Memories: playtest-notes-before-handoff,
> assembled-preview-before-upload, look-at-textures-before-upload, studio-play-is-shared, alan-does-play-checks.

## STATE (verify before acting)
- HEAD = this handoff's commit on main (after `b7dd1af5`); the commit hook pushes to GitHub. Confirm: `git log --oneline -2`.
- Tests 426 passed / 0 failed last session; docs checker OK (138 pages): `python tools/check_docs.py`.
- Alan published HEAD's code himself (Publish As) and played it on his phone. Studio: open, editing the online copy;
  `FlyFightPaper-WORKING.rbxlx` is from 2026-10-25 (older than Studio; never rebuild from it without Save to File).
- Cost since last handoff: none (notes, decision, memory only). Primary context ~42%.

## NEXT ACTION + PLAN (Alan's notes, his order)
1. **Kill feed (top right):** a list that fills from the top down, ~4 slips on a phone (fit to the screen), each fades
   after a while with nothing new; several kills at once come down as a list. Today: fills from the bottom, 2 slips,
   newest replaces the 2nd, empty space beside the match strip, and over the desk it sits right above Refill Lift.
   Check: Studio phone view, 5 quick kills -> top-down list under the top row, fading.
2. **Dev mode on Alan's account in live servers** (decision `docs/decisions/2026-10-29-dev-mode-on-alans-account.md`):
   his account gets the dev panel (end match, modes, endings, results) in published servers; server checks his UserId
   (find it: the game's owner / his account, not the Studio test account `growtopianalanG` 52064999 unless they match);
   everyone else sees nothing and is refused. Also a way to see match tips again (his account has seen them all).
   Check: Studio with the check pointed at the test account, and a non-matching id refused; then his live test.
3. **Results card:** a notebook-page picture made to fit the layout (6 ruled lines: places 1-5 + your row; the level
   part below free), not a small picture stretched; place column (1st..5th, your 8th) fully on the paper; heads
   "Folds / Assists / Crashes" spaced apart. PC and phone. New art: assembled preview for Alan BEFORE any upload, and
   look at the texture before upload (moderation memory).
4. **Winners' confetti from the ceiling** (PC and phone): its start out of view, never popping in a foot above them.
5. Later (Alan: "eventually", not now): paper airplanes flying behind the winners through the confetti.
6. Then from before: iPad check (Device Simulator switch = Alan's go), match tips on a phone (via dev mode).
- HOLDS (Alan's go, each): publish (he does it, or approves desktop control at his PC), Save to File, any upload,
  desktop control, Studio Play while he plays, anything paid.

## DECISIONS & WHY (this session)
- Dev mode on Alan's account in live servers (decision note above): testing round ends on a phone took ~10 min a match.
- New working rule: no handoff or kickoff until Alan gives playtest notes (memory playtest-notes-before-handoff).
- Earlier choices still in "Decisions to review" (STATE): auto-fire on yellow too; steering top 1.8 for mouse too.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md; memories above. Publishing: File > Publish As > Overwrite only (decision 2026-10-07 private publish).

## CARRY NOTES / GOTCHAS
- Can't publish when Alan is away from his PC (lessons.md, 2026-10-29): the approval box is PC-only.
- Studio `endMatch` (RoundAction): results card ~18-21 s later for ~10 s, then the vote (~20 s).
- Device Simulator taps: GUI ≈ (x-62, y-20), TouchTapInWorld ≈ (x-62, y+38). Hide `Tutorial.Ask` before screenshots.

## WHAT SHIPPED / OTHER QUEUED
- This handoff commit: playtest note 2026-10-29, decision note dev mode, STATE rewrite, this handoff + LATEST.
- Previous session's commits: see `handoff-2026-10-29-mobile-lane-phone-fixes-await-publish.md` (c52c0ed7 … b7dd1af5).
- Queued: prices, drawing check, touch step 6 (STATE).

## KNOWLEDGE UPDATED
- docs/playtests/2026-10-29-phone-run-published-fixes.md (new) + README line.
- docs/decisions/2026-10-29-dev-mode-on-alans-account.md (new) + README line.
- state/STATE.md rewritten (top + Waiting on Alan). Memory: playtest-notes-before-handoff (+ MEMORY.md line).
- Checker: OK (138 pages).

## POINTERS
- Kill feed: grep "kill feed" in `src/client/FlightHUD.luau` / `ScreenFit.luau`; docs `docs/systems/menus-and-hud.md`.
- Results card: `src/client/RoundEnd.luau` (rows, PHONE_ROWS), art in `src/shared/UIAssets` (`results`).
- Confetti: `src/client/WinnersCutscene.luau` (confetti near line 53).
- Dev tools: `src/client/DevTools.luau`, server `IsStudio()` gates (`Bootstrap.server.luau`, `FlightService`, `BotService`, `CombatService`).
