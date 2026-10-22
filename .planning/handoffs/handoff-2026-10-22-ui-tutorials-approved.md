# HANDOFF — 2026-10-22 — Tutorials approved by Alan; next is the desk quick menu (concept first)

**Labels:** kind=ui+product · lane=ui · branch=main · issues= · areas=src/client/Hangar.luau, src/client/HangarCustomize.luau, src/client/Tutorial.luau, src/client/TutorialLessons.luau, src/client/FlightController.luau, src/client/MenuController.luau, src/client/PauseScreen.luau, src/server/BotService.luau, src/server/CombatService.luau, src/server/RoundRuntime.luau, src/server/AvatarService.luau, src/shared/TrainingCourse.luau, docs
**Time:** 2026-10-22 19:00 -04:00

★ START HERE: Goal: the in-match desk quick menu gets its own small design matching the new Hangar (NOT the cubbies;
`docs/plan/HANGAR-PLAN.md` answer 2). Opening action: make a concept picture of it and show Alan, assembled in the
scene, before building or uploading anything. Done when Alan OKs the concept, it's built, and he says it works at the
desk in a match. Then the Range's first-visit sticky notes (Alan wants them), Match Tips, the Range build swap.

> Read on demand: AGENTS.md → THIS → `docs/decisions/2026-10-22-tutorials-approved.md` → `docs/plan/HANGAR-PLAN.md`
> → `docs/systems/planes-and-hangar.md` (desk part). Memories: assembled-preview-before-upload,
> in-game-menus-match-main-menus, alan-does-play-checks, codex-for-pictures-and-blender, look-at-textures-before-upload.

## STATE (verify before acting)
- HEAD = this handoff's commit on main (after `cbc89947`); the commit hook pushes to GitHub. `git log --oneline -3`.
- Docs checker OK (124 pages): `python tools/check_docs.py`. Unit suite not run this session (rules logic untouched
  except Pal/lesson server code): in Play on the server, `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- Studio: Edit, Play stopped. Studio was reopened mid-session: its MCP id changes (`list_roblox_studios`).
  Rojo serve was restarted by Claude in the background (`$env:LOCALAPPDATA\Rojo\bin\rojo.exe serve serve.project.json
  --address 127.0.0.1 --port 34872`; `rojo` is not on PATH); Alan reconnected the plugin. Check: port 34872 answers.
- Place file not re-saved (Ctrl+S = Alan's go). Code lives in src/.
- Cost: 0 subagents, 0 Codex, 0 uploads, $0. ~8 Claude Play runs (scripted, numbers only, while Alan wasn't playing).
  Primary context ~41% at handoff.

## NEXT ACTION + PLAN
1. Desk quick menu concept → Alan's OK on an assembled preview → build → his check at the desk. (Concept pictures:
   Codex images are the cheap route, per memory; uploads allowed after his OK on the preview.)
2. Range first-visit sticky notes (TUTORIAL-PLAN.md line ~114: picker, score card, loadout strips, how to leave; one
   at a time). 3. Match Tips (TUTORIAL-PLAN.md "Lesson 5", off switch in Settings). 4. Range build swap (old plane
   flies off, new one slides in: decisions/2026-10-19-range-controls-and-menu.md).
HOLDS (Alan's go, each): publish, Meshy, anything paid, desktop control, closing Studio, Save to File, real product
IDs/prices, turning sales on, Studio Play runs while he's playing. Uploads allowed with an assembled preview first.

## DECISIONS & WHY (this session)
- Gear skips try-on: owned gear goes straight on its spot (Alan: Select "breaks that whole thing"); unowned shows Buy.
- Nose dot vs aim circle: the plane now steers at the point on the circle's camera line at the dot's range (lead
  range, else 300). Changes steering in every match, slightly (camera parallax was the cause).
- Step 8 ambush is FAKE on purpose (Alan): `BotService:palAmbush` launches pellets 70 studs out on the Pal's side
  (closer if a wall), led, while the Pal is >60° off your nose, from 0.3 s after the note, until half Health. The
  Pal's own guns never fire. Measured: 120→60 Health in ~4 s.
- `CombatService:launch(origin)`: only erasers keep `target` (a pellet with a target steered and raised INCOMING!).
- All Pals run: own heading, bank 25-50° every 2.5-4 s, 85% speed beyond 250 studs, 100% near; never away from you.
- Lesson end card freezes everything (buttons usable); either button unfreezes first. Pal refolded if wrong weapon.
- Drill targets pause their path clock while frozen (`DrillPath.heldAt`, `TrainingCourse.pathAt`).
- Esc over the Hangar: pause menu draws over it (DisplayOrder 11), Keep flying / Esc returns (`state.under`).
- Eraser lock stays on after firing: Claude's recommendation, listed in STATE "Decisions to review".

## CONSTRAINTS / PRINCIPLES
- AGENTS.md; memories above; `docs/workshop/lessons.md` (+2 this session: Esc belongs to Roblox first; a shot with a
  target is an eraser).

## CARRY NOTES / GOTCHAS
- Every Esc toggles Roblox's own menu; the closing press never reaches InputBegan.
- Studio test path: DevLesson attribute on ReplicatedStorage.FlyFightPaper (client), Enter launches, K skips a step;
  starting a lesson via DevLesson while the tour's Hangar is open leaves it waiting behind (click Back).
- Old carries: match bots' guns converge at 150 (Alan's call), vote-lap strip, cutscene hitch, Track C private
  publish, fan sound, live tutorial-room move untested, Range rename doesn't persist between Studio Plays.

## WHAT SHIPPED / OTHER QUEUED
- 5d6d7cd3 Hangar: Customize stands on the shelf, gear goes straight on, a new name stays while it saves
- 1348e47f Hangar: Customize in front of the shelf; booster cards say speed and seconds
- 5045f5d2 Nose dot settles on the aim circle; Combat School step 8's Pal always starts behind you and the note warns you
- a444d0f2 Combat School: targets hold still while frozen; step 8 always hits you from behind; Pals run straight and slow down when far
- f9363b91 Combat School's end card offers the Hangar Tour next
- dfa95b1f Lesson end freezes for the card's buttons; Hangar Tour card closes on click or Space; Pals chase better and carry the right weapon
- 6474b863 Step 8: you get shot the moment the note lets go, from the Pal's side, before you can turn round
- db09241c Esc in the Hangar keeps it under the menu; step 8's shots no longer raise INCOMING and are led so they land
- bc54aeeb Paper Pals and practice targets no longer get a pilot avatar at a desk
- f1ee0995 Alan approves the tutorials (Flight School, Combat School, Hangar Tour)
- cbc89947 Record Alan's next order: desk quick menu, then Range sticky notes
- + this handoff (STATE rewrite, system page status lines).
- Queued (Alan's): Stage 10 prices/products, Stage 11 private publish and multi-client tests, VIP perks, cosmetics.

## AAR
Supposed: Alan checks tour + try-on, Claude fixes notes. Actual: 28 notes across Hangar and Combat School; step 8's
ambush reached him broken twice (timing, then no hits). Why: handed over on a compile check only. Next time: a short
scripted numeric Play run before handing over server-logic fixes (memory alan-does-play-checks updated). Cost matched.

## KNOWLEDGE UPDATED
- systems/tutorial (status: approved; end card freeze, Pal behaviour, ambush), systems/planes-and-hangar (gear, name,
  boosters, status), systems/flight (aim parallax), systems/menus-and-hud (Esc over Hangar), systems/bots (avatars);
  decisions: hangar-try-on-select (+gear), new 2026-10-22-tutorials-approved (+README, MILESTONES line);
  playtests/2026-10-21-hangar-tour items 9-28; workshop/lessons +2; STATE rewritten (59 lines). Checker: OK (124 pages).
- Memory: alan-does-play-checks refined (numeric Play checks before handover).

## POINTERS
- Desk menu today: `src/client/DeskHangar.luau` (layout B, numbered build squares); Hangar look: `Hangar.luau`,
  `BuildShelf.luau`, `HangarCustomize.luau`; art ids `src/shared/UIAssets.luau`; concepts `assets/references/ui-concepts/`.
