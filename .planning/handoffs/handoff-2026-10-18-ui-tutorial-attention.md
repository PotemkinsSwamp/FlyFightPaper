# HANDOFF — 2026-10-18 — Stage 10 shop code done (off); tutorial planned, Flight School drafted, attention pass approved

**Labels:** kind=ui+product · lane=ui · branch=main · issues= · areas=src/server/CommerceService.luau, src/server/ProfileService.luau, src/server/Matchmaking*.luau, src/server/RoundRuntime.luau, src/client/Tutorial.luau, src/client/TutorialLessons.luau, src/client/FlightHUD.luau, docs/plan/TUTORIAL-PLAN.md

★ START HERE: Goal: build the approved "Grabbing attention" pass of the [tutorial plan](../../docs/plan/TUTORIAL-PLAN.md)
on Flight School, so every step pulls the player's eyes to the one thing to do. First action: a Codex concept picture
(paper-and-crayon highlight frame + arrow) for Alan's OK. Done = Alan plays Flight School in Studio and says he always
knew where to go (he is the tester; Claude only does script/picture checks).

> Read on demand: AGENTS.md → THIS → the tutorial plan ("How every lesson works", "Grabbing attention", Lesson 1) →
> [tutorial page](../../docs/systems/tutorial.md) → [decision](../../docs/decisions/2026-10-18-tutorial-lessons.md).
> Memories: plan-before-building-features, studio-play-grabs-mouse, codex-for-pictures-and-blender,
> look-at-textures-before-upload, powershell-commands-for-alan.

## STATE (verify before acting)
- HEAD = this handoff's commit on main (after `b779e05c`), pushed by the post-commit hook. `git status -sb`.
- Tests: 397/0 on 2026-10-18 BEFORE the last tutorial edits (training plane, foe helper, Studio tutorial world,
  spotlight, feed). Re-run needs Play: `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()` on the
  server. Last edits were only load-checked in Edit (`require` of each changed module: OK).
- Studio open in Edit, Play stopped, Rojo serving. rbxlx was committed by mistake in e5359191 (see carries).
- Cost this session: 3 Codex jobs via codex-rescue (purchases ~7 min, part unlocks ~3.5 min, tutorial routing ~2.3
  min; ~25-33k Claude tokens each); 4 Sonnet agents (Explore x3 ~25-127k, web research ~115k). No uploads, nothing
  paid. Primary context ~45% at handoff.

## NEXT ACTION + PLAN
1. Concept picture of the highlight frame + arrow (Codex), Alan OKs; then the asset for upload (Alan runs it; contact
   sheet first per look-at-textures-before-upload).
2. Build "Grabbing attention" on Flight School: screen dim with a hole that follows the 3D target, glowing target with
   "FLY HERE" + distance, big direction arrow in front of the plane + guide line when off-screen, a fixed hand-checked
   hoop course in clear air in front of the Training Room desk (next hoop visible). Then Alan tests.
3. Then Combat Training, Training board + saved lesson ticks + 8-min room, Hangar Tour, Match Tips (+ Settings switch),
   Weapons Range (plan's build order). Each lesson: Alan tests before the next. Then Stage 11.
HOLDS (Alan's go, each): Studio Play runs (they grab his mouse: only when he says go or is away, one short batch),
uploads (he runs them), publish (incl. the private publish to test the real tutorial-room move), Meshy, anything
paid, desktop control, closing Studio, Save to File, real product IDs/prices, turning sales on.

## DECISIONS & WHY (this session)
- Stage 10: receipts are granted with their receipt ID in one save change and acknowledged only after that save
  reaches Roblox; a product disabled after payment is still delivered; pass ownership asked from Roblox, errors grant
  nothing. Early part unlocks: one product per part (28); an owned part flies at any level (else buying early is
  useless; in STATE "Decisions to review"). Two schema tests were updated to that rule, not weakened.
- Tutorial room = fresh reserved server, never listed; leaving it tags teleport data `tutorialSeen` so the next room
  doesn't send a still-new player (0 matches) straight back. Studio stand-in: the Tutorial button clears the room
  (match paused, bots removed), Skip/finish resumes the match.
- Alan's tutorial rulings (decision note): plan before code; short lessons; fixed training plane (pellet + eraser +
  Elastic Booster, `WeaponLoadouts.make(catalog,"training")`); always say how to come back; Match Tips switch; no news
  notes/kill feed during lessons; Alan is the tester; attention design approved.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (docs rules, model router, holds). Memories above. Lessons: docs/workshop/lessons.md "Tutorial UI traps".

## CARRY NOTES / GOTCHAS
- e5359191 swept uncommitted art (bell-tower parts, building close-up renders) and the place file into git by
  mistake (`git commit -a`); 136d35b0 notes it. Never use `-a` here; files on disk were unchanged.
- Unverified in Play: new spotlight look, fade-out, LAUNCH-on-click, 3D marker (font arrows were empty boxes, now
  crayon pictures), Lift-bar pulse after the 58-px fix, bolt/boost/landing/desk card/end card, feed suppression.
- Hoops spawn by spherecast and one landed inside the bell tower: replace with the fixed course (plan item).
- Half-built Combat helper is committed: `Runtime:tutorialFoe` (RoundRuntime) + foe rule in `CombatService:enemy`.
- Studio stand-in resumes a paused round whose clock kept running, so it may end at once; fine for Studio.
- Still open from before: cutscene-start hitch; vote-lap strip shows the old round; Track C live saving tests need a
  private publish; live shop screen / "Unlock now" button wait for prices.

## WHAT SHIPPED / OTHER QUEUED
- 3211c4ca Real Roblox purchases built and switched off (Codex) · 3d49d4f9 Early part unlocks, off (Codex)
- 91926970 / c8e423b1 / e5359191 State updates (e5359191 = the accidental sweep) · 136d35b0 Note on the sweep
- 35712115 Tutorial's own empty room (routing by Codex) · 6398c0f6 Tutorial plan drafted · c17d5df9 Plan agreed
- ef5a4ada Flight School in progress · f636507e Studio tutorial world; bolder spotlight; crayon arrows
- 29df94b0 Decision: Alan tests the tutorial · adb7257d Fade-out, LAUNCH on click, no lesson lines in the kill feed
- 44d221fb Attention proposal · b779e05c Attention approved · + this handoff commit
- Queued: VIP pass perks and private servers (Alan decides), cosmetics, special planes, drawing pass (paid check).

## KNOWLEDGE UPDATED
- systems: economy-and-shop (Stage 10 where it stands, Code), saving (receipts), tutorial (room, Flight School, Code).
- decisions: 2026-10-18-tutorial-lessons (+README). plan: TUTORIAL-PLAN (new, approved). research:
  TUTORIAL-RESEARCH-2026-10-18 (new). HOME links. workshop/lessons: tutorial UI traps, Studio Play takes the mouse.
- STATE rewritten (56 lines). Checker: OK (102 pages).

## POINTERS
- `src/client/Tutorial.luau` (engine), `src/client/TutorialLessons.luau` (steps), `src/server/RoundRuntime.luau`
  (tutorialRoom, firstJoin, practice, tutorialFoe), `src/server/CommerceService.luau`, `config/commerce.json`.
