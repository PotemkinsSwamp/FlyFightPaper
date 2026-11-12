# HANDOFF — 2026-11-11 — Unlock moment built and OK'd in Studio; Alan publishes next

**Labels:** kind=ui · lane=beta-lane · branch=main · issues= · areas=src/client/UnlockMoment.luau, src/client/MenuController.luau, src/client/ScreenFit.luau, src/server/ProfileService.luau, src/shared/ProfileSchema.luau, tools/art/unlock_pieces.py, assets/ui/unlock, docs
**Time:** 2026-11-11 21:45 -05:00

★ START HERE: Goal (Alan): the beta feels finished. The unlock moment is done and Alan OK'd it in Studio Play. Next: ask Alan whether he has published yet (his job; old servers must be shut down after, because the save version went to 8). Then the results card becomes a report card (backlog must-do): a how-it-works note with a concept for his OK before any code. Done when he approves the note.

> Read on demand: AGENTS.md → state/STATE.md → this file; docs/plan/UNLOCK-PLAN.md only if the unlock moment comes up. Memories: plan-before-building-features, alan-does-play-checks, studio-play-is-shared, playtest-notes-before-handoff, text-fits-its-box, paper-fits-its-content.

## STATE (verify before acting)
- HEAD `444a948f` (main), pushed by the commit hook (local == GitHub copy). Confirm: `git rev-parse --short HEAD`.
- Tests: 483 passed / 0 failed at e131eeb7; since then, client UI only (UnlockMoment, ScreenFit, MenuController). Re-run in Studio as in `docs/workshop/testing.md`.
- Docs: `python tools/check_docs.py` → OK (164 pages).
- Studio: Edit mode, Play stopped, test switches cleared (DevLevelUp/DevUnlock/DevLevelNote/DevPhone/DevTouch off, DevMute false). Place file NOT saved this session (code reaches Studio via Rojo; Save to File needs Alan's go).
- The 9 unlock pictures: Approved by Roblox review (checked via Open Cloud asset API).
- Cost: Opus main session (long; one compaction), one Codex job for saving (schema 8, Alan's ChatGPT plan). No bot matches, nothing paid; 9 free picture uploads.

## NEXT ACTION + PLAN
1. Ask Alan whether he has published (guns, phone words, SPEED MATCH without paper, Clear all, unlock moment) and shut down old servers. Publishing is his; don't push it.
2. Results card → report card: a short how-it-works note and concept for his OK before code (memory plan-before-building-features). Done = his approval.
3. Then the shop step (re-scale Paper packs and Robux part prices), balance pass later (STATE.md list).
- HOLDS (Alan's explicit go, each): any upload, publish (he does it), Save to File, desktop control, Studio Play while he's playing (ask first even in a Play you started), a bot match, anything paid, any new mechanic or number.

## DECISIONS & WHY (this session; full list in docs/decisions/2026-11-08-unlock-ladder-and-bot-builds.md)
- Backpack plays only on the main menu (join, or after Leave match), never the in-match menu: Alan, after trying it.
- Level-up note: small (PC 0.52 of first size), tilted -4° at the top left under the Menu button (`ScreenFit.topLeft`); flies in 0.8 s, beat 0.15, unfolds 0.7 (shaded flap + crease), sits 4 s, folds 0.4, flies out 0.55; confetti is per-frame physics so it visibly bursts and falls. Phone keeps its size so words stay readable (Decisions to review).
- Card made shorter by cutting three whole ruled rows out of the index card (two ImageRect slices), not stretching: Alan dislikes stretched paper.
- The red count sticker on the in-match Menu button was removed (pointed at the wrong menu once the backpack moved). Decisions to review.
- Zipper sound: one 1.3 s nylon zip (9113260940, 1.0–2.3 s), played by how far you move the pull either way (2 s per whole pull, 0.3 s banked); only Pause/Resume, because moving a playing Sound's TimePosition gaps on Roblox. Loops sounded "grating, like a car starting".
- Unzip frames are a polar warp so the zipper is shut at the pull and gapes behind it (Alan: opening from the wrong end looked very bad).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (docs one-fact-one-page, commit+push small, model router), memories listed above, docs/workshop/lessons.md (new line: ask before test screens or mouse input while Alan may be playing).

## CARRY NOTES / GOTCHAS
- Not seen: a real XP level-up in a match (tested with Studio's `DevLevelUp` pretend level-up, which calls the same note). Check on Alan's first real level-up.
- On a phone the note (right of Health/Lift, under the Menu button) may sit over a centred match tip for its 4 s; unchecked.
- In Studio, saved profile data is live (ProfileStore "data will be saved"): don't edit Alan's level to test; use `DevLevelUp`/`DevUnlock` (not saved).
- Studio Play is shared: Alan joined my test Plays; a `DevUnlock` backpack popped over his match and a test drag went into his game.
- Edit-mode `ContentProvider:PreloadAsync` reports Failure for new images even when approved; check moderation via the Open Cloud assets API instead.

## WHAT SHIPPED / OTHER QUEUED
- 5ec867af Unlock moment plan for Alan's OK
- 29be6550 Unlock plan: level-up note in game, backpack in the Menu
- 7cd6a186 Save which level's unlocks you've seen (schema 8)
- e131eeb7 Unlock moment: level-up note in a match, backpack you unzip in the Menu
- 23140b0d Unlock backpack: ink arrows on the page, zipper sound that follows your pull
- 3386b45d Zipper sound: one long zip that plays as far as you pull, either way
- 553ac21f Level-up note stays 2 seconds
- a26983ef Lesson: ask before test screens or mouse input while Alan may be playing
- 4bae43fd Level-up note: small and tilted top left, flies in, unfolds, sits 4 s; backpack on the main menu only
- 444a948f Status: unlock moment OK'd in Studio, publish next
- Queued: report card (must-do), shop prices, balance pass, lesson goal note phone shapes, Save to File (Alan's go).

## KNOWLEDGE UPDATED
- docs/plan/UNLOCK-PLAN.md: status approved; note look/timing; main-menu-only backpack; sticker dropped.
- docs/systems/menus-and-hud.md: Unlock moment paragraph (note, unfold, sound, DevLevelUp), Code rows.
- docs/systems/saving.md: schema 8 + shut down old servers on publish.
- docs/decisions/2026-11-08-unlock-ladder-and-bot-builds.md: When it plays, Backpack details, main-menu change.
- docs/playtests/2026-11-11-unlock-moment.md: every round of Alan's notes through "looked good".
- docs/workshop/lessons.md: shared-Play lesson. docs/workshop/tools.md: unlock_pieces.py.
- state/STATE.md rewritten (59 lines). Checker: OK.

## POINTERS
- Code: src/client/UnlockMoment.luau (note ~line 459+, Studio hooks at the end), ScreenFit.topLeft, MenuController render().
- Art: tools/art/unlock_pieces.py, assets/ui/unlock/{source,ready,uploads}; UIAssets.unlock.
- Concept frames: .planning/unlock-concept2/. Screenshots: .planning/level-note*.png.
