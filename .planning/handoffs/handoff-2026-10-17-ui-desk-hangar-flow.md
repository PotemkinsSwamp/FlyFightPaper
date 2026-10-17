# HANDOFF — 2026-10-17 — Menu art and the desk hangar flow done; Alan publishes, then Stage 9 playtest

**Labels:** kind=ui · lane=ui · branch=main · issues= · areas=src/client/DeskHangar.luau, src/client/Hangar.luau, src/client/MenuController.luau, src/server/HangarService.luau, src/server/DeskService.luau, assets/ui, docs/decisions

★ START HERE: Goal: Alan's Stage 9 sign-off. Everything he asked for this stretch is built, uploaded and checked in
Studio Play, but not live yet. First step: ask Alan whether he has clicked Publish As > Overwrite (his go; he
clicks it). Then support his Stage 9 playtest (list in state/STATE.md, item 5 = the new hangar flow) and fix what he
reports. Done when he says "Stage 9 approved".

> Read on demand: AGENTS.md → THIS; state/STATE.md; docs/decisions/2026-10-17-builds-change-at-the-desk.md for the
> hangar; docs/playtests/2026-10-17.md notes 1-3 and 7. Memories: studio-play-is-shared, look-at-textures-before-upload.

## STATE (verify before acting)
- HEAD: this handoff's commit on main, auto-pushed to GitHub by the commit hook. Confirm: `git rev-parse --short HEAD`.
- Tests 321/0 in Play, server: `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- Studio: "FlyFightPaper(First Fold) (placeId: 132768925825316)", in Edit, Rojo serving current code. Place file not
  re-saved (Ctrl+S needs Alan; code lives in src/).
- Live game: the last publish predates this session's work (menu art, hangar flow, and the earlier items listed in
  STATE "Since that publish").
- Cost: 2 research subagents (~130k tokens each), 1 Codex picture job (on Alan's ChatGPT plan), 16 free Open Cloud
  uploads. Primary context ~410k at handoff.

## NEXT ACTION + PLAN
1. Alan publishes (Publish As > Overwrite). 2. His Stage 9 playtest; fix what he reports, checked in Play.
3. Tutorial only when he says.
HOLDS (Alan's go each): uploads, publish, Studio-settings changes, Meshy, anything paid, desktop control, closing
Studio. Don't steer his plane while he's in Play.

## DECISIONS & WHY (this session)
- Menu photo = Codex "cinematic" version of a Studio capture (Alan picked B over the plain screenshot). The two crayon
  drawings are Codex drawings of Studio captures. All asked for "no text anywhere" (AI text reads as gibberish).
- Rulers: the made-up numbers erased and real ones lettered in. The hangar ruler already read 1-6, so it's untouched.
- Hangar (Alan): builds change only at the desk. **Saving a build also picks it** (the one you fly next). "Save & fly"
  appears only when your plane is parked at the desk. Clicking a build square in either hangar picks it.
  Refold stays 120 Paper; refolding into the build you already fly is refused with no charge.
- After Save & fly, and after Back when the hangar was opened with Edit, the player goes straight back to the desk.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (model router, docs rules, commit + push each step); memories look-at-textures-before-upload,
  touch-up-before-showing, in-game-menus-match-main-menus, studio-play-is-shared.

## CARRY NOTES / GOTCHAS
- The hangar keeps your unsaved changes when you leave it. A refold or fresh plane takes the build you picked, never
  the unsaved draft.
- Hangar protection (120 s) keeps counting while you edit from the desk; watch Alan's playtest for this.
- No unit test covers "no charge to refold the same build" (DeskService); checked in Play only (Paper went down
  120 once).
- The waiting screen also uses the menu plane picture; it now shows the clean plane (was the old one with pin and trail).
- Uncommitted files in the tree that aren't this session's: bell-tower assets, closeups, FlyFightPaper-WORKING.rbxlx,
  untracked ready/ and uploads/ folders. Commit by path only.

## WHAT SHIPPED / OTHER QUEUED
- 103de3fd Menus show today's town: new crayon drawings and photo, real ruler numbers, clean menu plane with a separate pin
- f18ea05d State: menu art done, waiting on publish
- 764c43df Decision: builds change at the desk (Edit from the quick hangar, Save & fly)
- de2d2d74 Builds change at the desk: Edit button, picked-build preview, Save & fly, unsaved-changes warning, no charge to refold the same build
- 4033547c State: hangar flow done, added to the playtest list
- this handoff (STATE trim, lesson, LATEST)
- Queued: nothing new; Stage 9 playtest is next.

## KNOWLEDGE UPDATED
- docs/decisions/2026-10-17-builds-change-at-the-desk.md (new) + README line.
- docs/playtests/2026-10-17.md: notes 1-3 marked done, note 7 (hangar research).
- docs/systems/planes-and-hangar.md and desks-and-service.md: "Where it stands" 2026-10-17, what the player sees.
- docs/workshop/lessons.md: fixing made-up text in AI pictures; menu pictures from Studio captures through Codex.
- state/STATE.md trimmed to 59 lines. Checker: OK.

## POINTERS
- Retouch scripts were throwaway (scratchpad); sources are in assets/ui/<screen>/source, pieces made with
  tools/ui_pieces.py (ids in src/shared/UIAssets.luau).
