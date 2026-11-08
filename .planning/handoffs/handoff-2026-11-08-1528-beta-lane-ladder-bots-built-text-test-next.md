# HANDOFF — 2026-11-08 — weapon ladder + bot builds built; text style test, then Aces, then the unlock moment

**Labels:** kind=product+ui · lane=beta-lane · branch=main · issues= · areas=config/catalog.json, config/gameplay.json, src/shared/Catalog.luau, src/shared/BuilderModel.luau, src/shared/BotBuilds.luau, src/server/BotService.luau, src/server/MatchService.luau, src/client/HangarCustomize.luau, src/client/Hangar.luau, src/client/TutorialLessons.luau, tests/unit, docs
**Time:** 2026-11-08 15:28 -05:00

★ START HERE: Goal (Alan): the beta feels like a finished game, one map, a strong first-session hook. CLASSES-PLAN step 4
is in progress. Open with the TEXT STYLE TEST: a few text styles side by side in Studio next to the concept picture
(bold rounded hand-lettered font, thick dark outline, soft shadow, warm black), built-in fonts only. Done when Alan
picks one; rolling it out to all menus is its own job after.

> Read on demand: AGENTS.md → this file; docs/decisions/2026-11-08-unlock-ladder-and-bot-builds.md (all of Alan's calls
> this session); docs/playtests/2026-11-08-veteran-bot-matches.md; docs/systems/bots.md. Memories: plan-before-building-features,
> weapons-need-no-explaining, studio-play-is-shared, studio-play-grabs-mouse, mute-studio-tests, assembled-preview-before-upload.

## STATE (verify before acting)
- HEAD = this handoff's commit on `main`, pushed (GitHub copy via the push hook). Confirm: `git log --oneline -3`, `git status -sb`.
- Tests: 471 passed, 0 failed in Play (2026-11-08). Re-run: DevMute on in Edit → Play → Server: spawn
  `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`, write passed/failed + `failures` to a workspace
  attribute; poll in a second call (one call times out).
- Studio: Edit mode. Its MCP id changes when the link reconnects: `list_roblox_studios` first. Rojo live-sync on. New
  weapon models still not Saved to File or published (Alan's go). Published = v495.
- Docs: `python tools/check_docs.py` OK (155 pages).
- Cost: Opus main session (~40% context at handoff); Sonnet research helper (~133k tokens); Haiku match runners (one
  stopped on a stale Studio id ~100k, one 3-match run ~133k, 26 min); Codex: 2 picture jobs on Alan's ChatGPT plan
  (gpt-image-2, ~157k tokens). Nothing paid, no uploads.

## NEXT ACTION + PLAN
1. Text style test (above). Free. Alan picks.
2. Aces + bot tricks + smart switching (Alan said build it):
   - New tier `ace` above `experienced` (turn 1.0, aim ~0.5°, reaction ~0.15-0.25 s, hunts more), veteran builds.
   - EVERY bot gets kill-stealing and its build's trick; skill sets how well (Ace brakes at ~80 studs nearly exactly,
     Veteran 80-100 and sloppier, lower tiers worse); this replaces `brake_within`.
   - Tricks by main weapon: Popper dart (in, brake ~80, blast, boost out, return); Crayon stand-off 200-400 studs;
     Spitball first, then the other gun (target attribute `Spitballs`); others close turn fight using the brake.
   - Smart switching: finish the plane you're about to fold, then go for the damaged one; never hop damaged→damaged.
   - Better bots fire only within their gun's range.
   - Measuring: extend `DevBotTier` so a mix gives 1 Ace per 3 Veterans.
   - Check: unit tests + a one-minute bot match for errors/crashes (lesson), then Ace/veteran matches (Alan's go).
3. Prices, levels and gifts from the numbers, for Alan's OK. Bands (Alan): ~6 folds a match weak, 11-13 average, 25+
   strong. Research: docs/research/UNLOCK-PACING-2026-11-08.md. "A grind after unlocking." Level 15 is ~10 matches for
   an average bot today.
4. Unlock moment: concept fixes first (backpack bigger and wider, stays at the screen's bottom edge, never shows its
   bottom; darker background), then build per the decision note (drag-to-unzip, shake/haptics, Skip, swipe between
   several, free vs paid wording). Pieces: .planning/unlock-concept2/. Assembled preview + Alan's OK before any upload.
- HOLDS (Alan's explicit go each): publish (he does it), Save to File, any upload, desktop control, Studio Play while he's
  playing, a bot match, anything paid.

## DECISIONS & WHY (this session; full list in the decision note)
- Gear page holds all 10 cards on one page (Alan: no page flips); descriptions are plain words, no numbers.
- Free gear = `paper_price` 0, owned from its level via `Catalog:owns` (no save write, prestige-safe); every ownership
  check routes through it (validateLoadout, BuilderModel, Hangar owned()).
- Fighter/Bomber presets got the Thumbtack/Crayon: the plan's stand-ins were never swapped in step 3 (I first told Alan
  they already carried them; corrected).
- Old bot tests replaced (rookies light guns only, ±35% kill time every tier, turn/dodge rising every tier): presets
  differ on purpose. ±35% kept for veterans; damage still rises by tier; veterans out-turn regulars.
- Free-for-all has no fold cap (Alan: time is the limit); TDM keeps its 60.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (model router, docs rules, hard limits); memories listed above; lessons.md "After any bot code change, fly a
  one-minute bot match".

## CARRY NOTES / GOTCHAS
- Required modules stay cached between Studio Edit execute_luau calls (Catalog:classes "missing"): read config JSON in
  Python, or use Play for fresh code.
- Paid weapon prices are placeholders (Crayon at level 12 costs less than the Paperclip at 9) until plan step 3.
- Phone haptics on Roblox: not verified; check current docs before promising vibration.
- Concept frame 6 drew a zipper-pull-like item instead of a Thumbtack.

## WHAT SHIPPED / OTHER QUEUED
- Shipped: 38b91c32 Gear two pages · 8da86bbb all ten on one page + description box · 25c3657e cards inside the page,
  plain descriptions · da8995d9 plan answers · 3c56dc4e unlock pacing research · 4b68cc9d ladder order, first four free ·
  80dab580 bots on presets/veteran builds/brake · bb9da41c DevBotTier switch · 0b51c871 Braking attribute · e6347db0
  brake steering fix · f11296b0 veteran match numbers + calls · ca3b62fc switching/concept/order/skill bands · 6fd4392d
  FFA no fold cap · (this handoff's commit).
- Queued: Save to File + publish (Alan's go); text rollout; CLASSES-PLAN steps 5-7; winners' circle, skins, shop.

## KNOWLEDGE UPDATED
- decisions: new 2026-11-08-unlock-ladder-and-bot-builds (+README). playtests: new 2026-11-08-veteran-bot-matches
  (+README). research: new UNLOCK-PACING-2026-11-08 (HOME). systems: planes-and-hangar (Gear page), economy-and-shop
  (free gear), weapons (table order), bots (planes, brake, DevBotTier), modes-and-scoring (FFA time only). plan:
  CLASSES-PLAN step 4 split a-e, ladder table → decision. lessons.md: bot-code check. STATE.md rewritten. Checker: OK.

## POINTERS
- Bot code: src/server/BotService.luau (`steer` brake block, `chooseTarget`, `decide`), src/shared/BotBuilds.luau,
  config/gameplay.json `bots.profiles`. Ownership: src/shared/Catalog.luau `owns`. Cards: src/client/HangarCustomize.luau.
- Concepts: .planning/unlock-concept2/frames-sheet.png and pieces-check.jpg (gpt-image-2 via `codex exec
  --skip-git-repo-check` in a scratch folder; brief = references + "newest image model, write model.txt").
