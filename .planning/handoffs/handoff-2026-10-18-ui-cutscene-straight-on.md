# HANDOFF — 2026-10-18 — Round-end revisions built; ruler uploaded; next: Alan's evening notes on the cutscene

**Labels:** kind=ui · lane=ui · branch=main · issues= · areas=src/client/WinnersCutscene.luau, src/client/RoundEnd.luau, src/client/LevelBar.luau, src/server/VoteRings.luau, src/server/RoundRuntime.luau, config/gameplay.json, assets/ui/mainmenu

★ START HERE: Goal: the winners' cutscene and vote lap as Alan described in his evening notes
([decision](../../docs/decisions/2026-10-17-rounds-never-stop.md), "Revised again"). First: rebuild the cutscene shot
dead centre and straight on (1st on the middle desk, 2nd/3rd either side), with the town, ceiling decorations, desk
landing rings, planes and name tags hidden on the local screen while it plays. Done when Studio Play screenshots
show the three desks front and centre with nothing in the way, then Alan tries it.

> Read on demand: AGENTS.md → THIS → the decision above. Then only files the step touches. Memories:
> studio-play-is-shared, creator-store-first, look-at-textures-before-upload, in-game-menus-match-main-menus.

## STATE (verify before acting)
- HEAD `ef849c08`+this handoff's commit on main, auto-pushed by the post-commit hook. `git status -sb`.
- Tests 328/0 (before the last config-only commits). Re-run in Play (server):
  `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- Studio open in Edit mode (Play stopped), Rojo serving. Studio link tools: `python tools/studio_cli.py TOOL '{json}'`
  (execute_luau needs `datamodel_type`; code may be a Windows path to a .luau file; screen_capture needs `capture_id`).
- Cost last session: no subagents, no Codex; one Open Cloud upload (2 menu tiles, Alan's go). Primary context ~42%.

## NEXT ACTION + PLAN
1. **Cutscene, straight on:** camera looks straight along the desk row's normal at the middle desk (desks in
   `rounds.winner_desks`; 1st already goes on the middle one). Locally hide (LocalTransparencyModifier or similar,
   restored after) everything between camera and desks: town, ceiling decorations, the desks' landing-ring meshes,
   planes and their PilotName billboards. Keep the desks, their hangar runway/arch, chairs, chalkboard wall.
2. **Smoother stand-up and jump:** Alan wants uploaded animations if that's Roblox's best route. Research first
   (one standard search found: FBX → Studio Animation Editor import → publish → animation id; check whether Open
   Cloud can upload animations without Studio clicks). Then report the route + cost to Alan; each upload is his go.
   Until then, code-driven easing may smooth the current pivot moves.
3. **Vote rings → hula hoops:** Creator Store first (free, read any scripts), one colour per mode, soft glow, signs
   kept; positions stay in `rounds.vote_rings` on the window wall. Check the HUD arrow actually points (fly away).
4. Then Alan's Stage 9 playtest list in state/STATE.md.
HOLDS (Alan's go each): uploads (animations, any new art), publish, Studio-settings changes, Meshy, anything paid,
desktop control, closing Studio. Don't steer his plane while he's in Play (check first; my test Play is fine).

## DECISIONS & WHY (this session)
- Winner desks = DeskNorth3 (1st), North2, North4: the chalkboard row has six desks, so "middle three" = 2-3-4.
- Cutscene is all client-side: local clones of the winners' seated avatars; server celebrate/sitDown removed.
- Root-joint hip fix: Roblox scales animation hip movement twice on ScaleTo'd giant avatars; divide
  `Root.Transform.Position` by scale each PreSimulation (lesson in docs/workshop/lessons.md).
- "Crashes" on the card = all deaths (shot or crashed). Vote lap 30 s (Alan: at least 30).
- Round start in place: carried planes' teams cleared and rejoined before bots fill (fixed a TDM/FFA crash).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (docs rules, model router, holds). Memories named above.

## CARRY NOTES / GOTCHAS
- execute_luau resets the camera type after each script ("changed camera type, resetting"): test camera shots by
  binding a RenderStep that holds for a few seconds, then screen_capture.
- A test ScreenGui made with Instance.new defaults to Global ZIndex: set Sibling or fills hide behind frames.
- Python edits via bash heredoc mangle `\n` inside Luau strings; use the Edit tool for those lines.
- One cutscene frame showed a big green shape across the camera (likely a plane mid-takeoff when holds froze).
- During the vote lap the top round strip still shows the old round's mode and clock.
- Level bar partly-filled seen only on a test screen (the Studio account is level 50).
- `assets/ui/mainmenu/ready/` is untracked build output from ui_pieces.py; leave it.
- Five loose Workspace objects are Alan's: leave them.

## WHAT SHIPPED / OTHER QUEUED
- f3439173 Studio dev button: end match now
- a6148e5c Winners' cutscene at the chalkboard desks; team rounds no longer crash starting in place
- 12cb0dde Results card: folds, assists, crashes, team totals, your Paper/XP and level bar
- 2f0d3c0c Vote rings: three big neon rings on the window wall, HUD arrow to them
- 479e59ee Level bar and next unlock on the menu board, hangar and results card
- 795d43c7 Hangar level bar on the preview paper; state: round end revisions built
- 95b2ea09 / 0d484161 Lessons: emotes on giant avatars, round start teams; footer order
- 3deb590f Main menu: ruler reads 3 to 12, right way up (new background tiles)
- 7cfc57a2 Vote lap 30 s; Alan's notes on the cutscene recorded
- ef849c08 Decision: hula-hoop vote rings; uploaded animations (route to confirm)
- this handoff (docs check-up)
- Ruler side session ([Fix the main-menu ruler](#local_38060944-c49d-4f63-9a90-780690472375)) is done; can be archived on Alan's yes.

## KNOWLEDGE UPDATED
- docs/decisions/2026-10-17-rounds-never-stop.md: "Revised again" (Alan's evening notes, hula hoops, animation route).
- docs/systems/modes-and-scoring.md, menus-and-hud.md: where it stands; Code table + WinnersCutscene, LevelBar.
- docs/workshop/lessons.md: giant-avatar emotes, round-start teams, codex --skip-git-repo-check. STATE.md updated.
- Checker: OK (90 pages).

## POINTERS
- src/client/WinnersCutscene.luau (shot constants at the top), src/client/RoundEnd.luau, src/client/LevelBar.luau,
  src/server/VoteRings.luau, src/client/FlightHUD.luau (VoteArrow), config/gameplay.json `rounds`.
