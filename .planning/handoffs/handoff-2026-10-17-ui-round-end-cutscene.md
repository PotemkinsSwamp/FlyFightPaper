# HANDOFF — 2026-10-17 — Lines done; round end first pass built and tried; next: Alan's revisions (cutscene)

**Labels:** kind=ui · lane=ui · branch=main · issues= · areas=src/shared/Lines.luau, src/client/RoundEnd.luau, src/server/RoundRuntime.luau, src/server/VoteRings.luau, src/server/FlightService.luau, src/server/AvatarService.luau, docs/decisions

★ START HERE: Goal: the round end Alan described ([decision](../../docs/decisions/2026-10-17-rounds-never-stop.md),
"Revised" section). First: add a Studio dev-panel button "End match" (ends the round now) so the round end can be
tested on demand. Then rebuild the winners' moment as a seamless client cutscene at the middle three desks of the row
nearest the chalkboard. Done when each piece is seen working in Studio Play (screenshots), then Alan tries it.

> Read on demand: AGENTS.md → THIS → the decision above. Then only the files the step touches. Memories:
> studio-play-is-shared, in-game-menus-match-main-menus.

## STATE (verify before acting)
- HEAD: this handoff's commit on main (after `c7174a48`), auto-pushed by the post-commit hook. `git status -sb`.
- Tests 328/0 in Play (server): `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- Studio: the place is open and **Play was left running** (I started it; Alan then tried the round end in it).
  Check `get_studio_state`; don't stop Play while Alan may be in it. Rojo serving current code.
- This session's Studio link had 0 tools: `python tools/studio_cli.py TOOL '{json}'` works (execute_luau needs
  `datamodel_type`; user_mouse_input clicks need `mouse_button`).
- Cost: no subagents; one side session started (ruler, below). Primary context ~42% at handoff.

## NEXT ACTION + PLAN
1. **Dev panel "End match" button** (the dev buttons sit in FlightHUD's picker; the existing `devMode` RoundAction
   already ends a round: add an "end" action that closes the round without changing the next mode).
2. **Winners' cutscene (client):** planes keep holding (server already holds them in RESULTS). The camera glides from
   where you are (plane or hangar) to the middle 3 chalkboard-row desks; local clones of the top 3's avatars replace
   the students there, stand up from the chair, jump onto the desk, emote ~10 s with the results card, then the camera
   glides back. No cut, no loading screen. Lengthen `rounds.results_seconds` to fit (about 14 s). Server-side
   `AvatarService:celebrate` (winners on their OWN desks) is replaced by this; remove it.
3. **Results card detail:** folds, assists, crashes beside points; your Paper and XP from the round with the level
   bar filling; in team rounds names in team colours and both team totals.
4. **Vote rings:** on the window wall, much larger, not paper rings, unmistakable (an edge arrow to them like the zone
   arrow helps). Positions in config `rounds.vote_rings`; VoteRings.luau builds them.
5. **XP bar + next unlock** on the main menu board and in the hangar (the old results menu that showed them was
   removed; its code is in git history: `git show d914994b^:src/client/ResultsScreen.luau`).
6. Then Alan's Stage 9 playtest list (state/STATE.md).
HOLDS (Alan's go each): uploads, publish, Studio-settings changes, Meshy, anything paid, desktop control, closing
Studio. Don't steer his plane while he's in Play.

## DECISIONS & WHY (this session)
- Event lines: Minecraft-style "how it happened", classroom-themed, no sound words (Alan rejected the first draft as
  cheesy). Alan approved the full list. HUD note and kill feed share one chosen line (server picks the template).
- Warnings, zone words, error messages and score pop-up words stay fixed (kids learn them at a glance).
- Rounds never stop; vote by flying through rings (+ keys 1/2/3), not shooting (needs aim/ammo). Cutscene desks:
  middle 3 by the chalkboard (Alan picked).
- Between rounds `flight.safe`: no damage, walls bounce, no out-of-room deaths; new round = full health/Lift, clean
  record, same plane (wear reset).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (docs rules, model router, holds). Memories: studio-play-is-shared, in-game-menus-match-main-menus,
  creator-store-first (for any ring model), look-at-textures-before-upload.

## CARRY NOTES / GOTCHAS
- First-pass round end not screenshotted by me end to end; Alan tried it live. Re-check all phases after changes.
- Long kill-feed lines between two long names shrink; watch for one that's too small.
- `Lines.death` uses `how.template` from the server so HUD and feed match; keep that when adding new ways down.
- Five loose Workspace objects (meme toy, HorseDragoon, Backpack, ungroup pibble, Model) are Alan's: leave them.
- Side session [Fix the main-menu ruler](#local_38060944-c49d-4f63-9a90-780690472375) owns the menu ruler art; don't
  touch MenuBoard art while it runs.

## WHAT SHIPPED / OTHER QUEUED
- eab1e5ed Hangar: click a mounted weapon again to clear it, 'Clear weapon spot'; event messages rotate
- f01a3424 Rotating lines: ready-at-desk too; HUD page updated
- 21e3608f State: weapon clear and rotating lines done
- b5e3af6e / ee29cbc9 Lesson: driving Studio when the link has no tools (→ tools/studio_cli.py)
- 88e742f6 Notes: how event lines must be written; Alan's round-end ideas
- aa6e8aff Decision: rounds never stop
- a4b171c7 Death lines say how it happened; new classroom-themed event lines
- 97e14a2f / 6fb3d1bb / b4fe17b8 State updates
- d914994b Round end in the room, first pass
- c7174a48 Decision: round end revised
- this handoff (docs check-up: modes page, playtest note 11, STATE)

## KNOWLEDGE UPDATED
- docs/decisions: fresh-rotating-lines (how lines are written), rounds-never-stop (new + revised) + README line.
- docs/systems: menus-and-hud (Lines, RoundEnd, where it stands), modes-and-scoring (where it stands, VoteRings,
  RoundRuntime), planes-and-hangar (weapon click-again). docs/playtests/2026-10-17.md note 11. docs/workshop/lessons.md
  (studio_cli when Studio tools are missing). MILESTONES Stage 9 round-end line. Checker: OK.

## POINTERS
- src/client/RoundEnd.luau (round end screen + camera), src/server/RoundRuntime.luau (finish, phaseChanged,
  watchRings, begin), src/server/VoteRings.luau, src/server/FlightService.luau (`safe`, `hold`, `newRound`),
  src/server/AvatarService.luau (celebrate/sitDown, PilotId), src/shared/MatchRules.luau (winners, throughRing),
  src/shared/Lines.luau, config/gameplay.json `rounds`.
