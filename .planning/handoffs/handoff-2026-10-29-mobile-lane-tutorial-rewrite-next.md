# HANDOFF — 2026-10-29 — mobile lane: Alan's phone notes fixed in Studio; next a tutorial rewrite for young players, then phone-aiming research

**Labels:** kind=ui+product · lane=mobile-lane · branch=main · issues= · areas=src/client (CombatEffects, FlightHUD, RoundEnd, MatchTips, WinnersCutscene), src/server (Bootstrap, RoundRuntime, FlightService), src/shared/ServiceRules, tools/art/results_page.py, assets/ui/results, docs
**Time:** 2026-10-29 22:05 -04:00

★ START HERE: Goal (Alan): mobile works and looks good, and a 10-year-old can do every tutorial step from its note
alone. First: write a step-by-step tutorial rewrite PLAN (new words for every step; Flight School arrows get "follow
the..." words; a new landing step that lines you up, slows you, lights your desk ring and says "fly into the glowing
circle"; the shooting-back Pal flies straight after it breaks off and makes one 90-degree turn when caught, no
circling) and get Alan's OK before building. Done = his OK, then each change checked in Studio Play at phone size.

> Read on demand: AGENTS.md → this file → `docs/playtests/2026-10-29-young-testers-tutorial.md` (notes 3-7).
> Memories: plan-before-building-features, playtest-notes-before-handoff, alan-does-play-checks, studio-play-is-shared.

## STATE (verify before acting)
- HEAD = this handoff's commit on main (after `4419afcf`); the commit hook pushes to GitHub. Confirm: `git log --oneline -2`.
- Tests 427 passed / 0 failed (Studio Play server: `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`).
  Docs checker OK (139 pages): `python tools/check_docs.py`.
- Studio: Alan's copy of the published game is open (placeId 132768925825316), Rojo was serving `serve.project.json` on
  34872 from this session (check it still answers; Alan reconnects the plugin). NOT published: Alan publishes himself.
- Cost this session: no agents; one free image upload (results page, asset 132705728947699). Primary context ~46%.

## NEXT ACTION + PLAN
1. Tutorial rewrite plan → Alan's OK → build → Studio Play check at phone size (notes 3-6 of the playtest note).
   Words: each step says the action, the target, how long, which button (PC and phone words: `TouchWords`).
2. Phone aiming (note 7): RESEARCH ONLY first (Alan: "research first before I make a decision"). How mobile and console
   flight/space shooters keep you on a target (throttle/air brake, auto speed-match when tailing, zoom on target,
   lock-on weapons). Write a short options page with sources and a recommendation; build nothing until he picks.
   My first take told to Alan: a brake (about 60% speed, drains Lift) + gentle speed-matching close behind an enemy.
3. Alan's publish + phone run of everything since 6eec885b (STATE "Waiting on Alan" has the what-to-try list).
4. Later: paper planes flying behind the winners; iPad check (Device Simulator switch = Alan's go).
- HOLDS (Alan's go, each): publish (he does it), Save to File, any upload, desktop control, Studio Play while he's
  playing, anything paid, building the tutorial changes before the plan's OK, building any aiming change.

## DECISIONS & WHY (this session)
- Dev mode = the game's owner account (`game.CreatorType` User + `CreatorId`, which is Alan's 52064999) or Studio; the
  server sets player attribute `Dev`, every dev request checks the server's copy. Other accounts never see the panel
  (checked in Studio with Dev=false). Decision note updated.
- Results page: drawn by `tools/art/results_page.py` from the old index card's real paper photo (lines removed),
  binder holes, torn left edge, masking tape; Alan OK'd it after rejecting a plain first try and pins.
- Team rounds: a page per team, Red left / Blue right (Alan OK'd the mock-up); TDM score shows folds, Airspace points.
- Match tip note keeps its size (Alan); words fill it (about 1.5x the old size; the note is the limit).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md; memories above. Publishing: File > Publish As > Overwrite only (decision 2026-10-07 private publish).

## CARRY NOTES / GOTCHAS
- A small Studio window counts as a phone: PC layouts (card, confetti, tips Got it) weren't seen at PC size.
- "tips again" was seen on the panel and in code paths, but tips were driven by forcing text; not flown live.
- Studio MCP clicks on the dev panel buttons miss (UIScale + AnchorPoint): fire `RoundAction` from the Client datamodel.
- Studio join: wait for `PlayerGui.Tutorial.Ask` + `MenuBoard`, click `Tutorial.Ask.Choice2` then `MenuBoard...Buttons.Play`.
- Pal after half Health: `BotService:palAmbush` sets `p.pal.mode="circle"` (that's the circling Alan saw).
- Landing step: `TutorialLessons.luau` flight step `land=true` (marker "LINE UP HERE" / "YOUR DESK: STRAIGHT ON").

## WHAT SHIPPED / OTHER QUEUED
- bd1a0d5f Kill feed fills top-down (4 slips, fades after 6 s); dev panel on the game owner's own account in live servers, server-checked; tips again button
- 4a40526b Winners' confetti starts above the top edge of every shot, so it falls in instead of appearing over their heads
- ae776144 Results card: loose-leaf page drawn to fit six rows (holes, torn edge, tape), words shrink to fit their columns, places 4th-12th, heads spaced
- b564718b Docs: results card page uploaded and seen in Studio
- e4cd8c88 State: your phone notes fixed and checked in Studio; what to try after you publish
- cf96f6f8 Match tips: words fill the sticky note (as big as fits, any length), bigger Match tip title
- 065ea993 Team rounds: a results page per team side by side (folds or zone points, winner's star, Your team tape)
- 677af650 Playtest: a younger tester's tutorial notes; match tips and team results done
- 4419afcf Playtest: phone aiming is too hard; discussion first
- This handoff commit: STATE, decision status, lessons, handoff + LATEST.
- Queued (STATE): prices, drawing check, touch step 6; kill-feed slip words are tiny on a phone too (seen, not raised by Alan).

## KNOWLEDGE UPDATED
- docs/systems/menus-and-hud.md: kill feed, dev mode, results card, team pages, match tips, confetti.
- docs/workshop/tools.md: `results_page.py`. docs/workshop/lessons.md: TextScaled/TextWrapped order; MCP clicks + small window.
- docs/decisions/2026-10-29-dev-mode-on-alans-account.md: status built.
- docs/playtests/2026-10-29-phone-run-published-fixes.md (outcome) + new 2026-10-29-young-testers-tutorial.md + README.
- state/STATE.md updated. Checker: OK (139 pages).

## POINTERS
- Tutorial: `src/client/TutorialLessons.luau` (steps), `src/client/Tutorial.luau` (engine), `docs/systems/tutorial.md`,
  `docs/plan/TUTORIAL-PLAN.md`. Pal: `src/server/BotService.luau` (palAmbush, Pal steering ~line 458).
- Results/team pages: `src/client/RoundEnd.luau`; art `tools/art/results_page.py`. Tips: `src/client/MatchTips.luau`.
