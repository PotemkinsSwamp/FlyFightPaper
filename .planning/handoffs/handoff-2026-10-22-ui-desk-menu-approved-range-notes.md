# HANDOFF — 2026-10-22 — Desk quick menu approved; music playlist fixed; Range sticky notes built, fix awaiting Alan's retest

**Labels:** kind=ui · lane=ui · branch=main · issues= · areas=src/client/DeskHangar.luau, src/client/FlightHUD.luau, src/client/CombatEffects.luau, src/client/RangeNotes.luau, src/client/RangeBoard.luau, src/client/Audio.luau, src/client/Hangar.luau, src/client/MenuController.luau, src/shared/UIAssets.luau, src/shared/ProfileSchema.luau, assets/ui/deskmenu, docs
**Time:** 2026-10-22 23:15 -04:00

★ START HERE: Goal: the Range's first-visit sticky notes work. Opening action: ask Alan to retest them in the Range
(the fix in `eadd3de4` is untested); read his notes and the console. Done when he says they work. Then Match Tips
(step-by-step plan for his OK first), then the Range build swap.

> Read on demand: AGENTS.md → THIS → `src/client/RangeNotes.luau` (one file) → `docs/systems/tutorial.md` (Range part).
> Memories: alan-does-play-checks, plan-before-building-features, assembled-preview-before-upload, studio-play-is-shared.

## STATE (verify before acting)
- HEAD = this handoff's commit on main (after `eadd3de4`); the commit hook pushes to GitHub. `git log --oneline -3`.
- Docs checker OK (125 pages): `python tools/check_docs.py`. Unit suite not run (ProfileSchema gained one lesson id,
  `rangeNotes`): in Play on the server, `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- Studio: Edit (Alan plays in it; check `get_studio_state` before anything). Rojo serving on 34872
  (`$env:LOCALAPPDATA\Rojo\bin\rojo.exe serve serve.project.json --address 127.0.0.1 --port 34872`). Place not re-saved.
- Cost: 0 Claude subagents; 4 Codex `exec` image jobs on Alan's ChatGPT plan (~70-90k tokens each); 7 Open Cloud
  uploads; $0. 0 Claude Play runs (read-only probes in Alan's Play only). Primary context ~41% at handoff.

## NEXT ACTION + PLAN
1. Alan retests the Range notes (what to try: open the Range from the Training board; five notes one at a time with an
   arrow: row plate, score card, Range Menu, Hangar, Menu button; using the thing or shooting/clicking the note moves on;
   "Skip all"; none during the Hangar Tour; not again after leaving). If broken: read his Play's console and the live
   `PlayerGui.RangeNotes` state (Client datamodel, read-only) before changing code.
2. Match Tips (TUTORIAL-PLAN.md "Lesson 5"; off switch in Settings): plan in plain words for Alan's OK, then build.
3. Range build swap (old plane flies off, new one slides in: decisions/2026-10-19-range-controls-and-menu.md).
HOLDS (Alan's go, each): publish, Meshy, anything paid, desktop control, closing Studio, Save to File, real product
IDs/prices, turning sales on, Studio Play runs while he's playing. Uploads allowed after an assembled preview he OKs.

## DECISIONS & WHY (this session)
- Desk quick menu = concept B, refined by Alan (decisions/2026-10-22-desk-quick-menu.md): match strip + kill feed stay
  up at the desk (FlightHUD's new `MatchInfo` ScreenGui holds `Top` and `KillFeed`); stats Health/Speed/Lift/Boost;
  Customize opens the binder (`Menu.show(screen, fromDesk, page)`, `Hangar.open("customize")`); strips big-middle-
  small-middle-big; no drawn pins (a pin never stretches with its paper), the kill feed's own pins at 30 px; tape
  tried and dropped ("takes too much attention"). The big photo can't go higher: Roblox's buttons + Menu button.
- Range notes are saved as `lessons.rangeNotes` (reuses the lesson-tick save; no board tick since no Lessons entry).
- The Range runs as the tutorial's `range` room (TutorialOpen true): notes hide only for OTHER lessons.
- Music: `Play()` inside `Ended` is ignored by Roblox; next song starts 0.3 s later (tested both ways in Alan's Play).
- Claude's calls in STATE "Decisions to review": no level bar, Boost teal, blue pins on the red strip, chatter 0.08.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md; memories above; `docs/workshop/lessons.md` (+3 this session: GUI moves break FindFirstChild paths; the
  Range is a tutorial room / `x ~= nil` with false; Play() inside Ended).

## CARRY NOTES / GOTCHAS
- Studio may not keep the save between Plays: notes may reappear each Studio test (real game: once).
- `assets/ui/deskmenu/preview.py`-style mockups: the script lives in the session scratchpad; the approach is in
  lessons.md ("Menu previews before upload"). Contact sheets are left off the GitHub copy (size), still in git.
- Old carries: match bots' guns converge at 150 (Alan's call), vote-lap strip, cutscene hitch, Track C private
  publish, fan sound, live tutorial-room move untested, Range rename doesn't persist between Studio Plays.

## WHAT SHIPPED / OTHER QUEUED
- fb64d03a Desk quick menu: two concept pictures for Alan to pick from
- b796df63 Desk quick menu rebuilt as concept B: pieces round the edges, match strip and kill feed stay up, Customize opens the binder
- 96eb7632 Kill feed lines show again (they lost the feed when it moved to the match layer)
- 511de2d9 Desk quick menu redone from Alan's notes: cork strip and taped photos, bigger LAUNCH, pinned strips big-small-big, left side level with the match strip
- 005856a1 Music playlist moves on to the next song; classroom children louder under the music. Alan approves the desk quick menu
- f0d72277 Range: first-visit sticky notes point at the plates, score card, Range Menu, Hangar and Menu, one at a time
- eadd3de4 Range notes: show in the Range (it runs as a tutorial room) and never as an empty note in the corner
- + this handoff (STATE rewrite, lessons +1: GUI moves).
- Queued (Alan's): Stage 10 prices/products, Stage 11 private publish and multi-client tests, VIP perks, cosmetics.

## AAR
Supposed: concept → OK → build → his check, then notes. Actual: desk menu took three preview rounds (fine, cheap), but
two things reached Alan broken: the kill feed (moved without grepping its users) and the notes (empty note: a
`false ~= nil` gate plus the Range counting as a lesson). Why: handed over on a compile check; client UI gating was
never exercised. Next: grep a GUI piece's name before moving it (lessons.md); before handing over client UI, check its
show-conditions against the real state (e.g. read `TutorialOpen`/`TutorialLesson` in the Range). Cost matched output.

## KNOWLEDGE UPDATED
- decisions/2026-10-22-desk-quick-menu (new, + README line; approved); systems/desks-and-service (status, Code row);
  systems/planes-and-hangar (desk line); systems/sound-and-effects (playlist, chatter); systems/tutorial (Range notes,
  Code row RangeNotes); plan/TUTORIAL-PLAN (first-visit details); art/references (approved desk concept);
  workshop/lessons +3; STATE rewritten (59 lines). Checker: OK (125 pages).

## POINTERS
- Desk menu: `src/client/DeskHangar.luau`, art `assets/ui/deskmenu/` (`UIAssets.deskMenu`), briefs
  `.planning/briefs/2026-10-22-desk-menu-*.md`. Notes: `src/client/RangeNotes.luau`, hooks in `RangeBoard.luau`.
