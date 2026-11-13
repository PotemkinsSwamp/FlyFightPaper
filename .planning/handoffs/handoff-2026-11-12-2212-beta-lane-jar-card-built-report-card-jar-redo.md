# HANDOFF — 2026-11-12 — Bot match done (tanks fixed), Alan's 3 notes built, Paper jar shop card live in Studio; report-card jar piece to redo

**Labels:** kind=product+ui · lane=beta-lane · branch=main · issues= · areas=src/client/{ShopScreen,RoundEnd,MenuController,DevTools,Hangar,UnlockMoment}.luau, src/server/{ProfileRuntime,HangarService,RoundRuntime}.luau, src/first/UIAssets.luau, tools/art/shop_pieces.py, assets/ui/shop, docs/
**Time:** 2026-11-12 22:12 -05:00

★ START HERE: Goal (Alan): the beta feels finished and the shop makes money. First redo the report card's Paper jar piece to Alan's pick: the glass jar itself on the Double this match row under your card, paper scraps dropping in as the card comes up, the level rising from before the match to now, a big crayon "+165!" popping out, its own small pulsing yellow button ("Break the jar!" from 3,000, "See your jar" before). Done = an MP4 of it in Studio Play sent to Alan and his OK.

> Read on demand: AGENTS.md → this file; then [jar rules](../../docs/decisions/2026-11-12-paper-jar-rules.md) (the redo spec, in Alan's words), `src/client/RoundEnd.luau` (`showJar`, the Double button `offer`), `src/client/ShopScreen.luau` (`ShopScreen.jarPicture`). Skill: `design-theory` before showing anything. Memories: offer-pieces-catch-the-eye (new), send-videos-not-gifs, alan-does-play-checks, mute-studio-tests, plan-before-building-features, text-fits-its-box.

## STATE (verify before acting)
- HEAD `0b76e1ca` + this handoff (main); every commit pushed by the commit hook ("github: pushed" to the GitHub snapshot; `origin/main` is not the compare). Confirm: `git rev-parse --short HEAD`.
- Tests: 559 pass / 0 fail, 40 suites (2026-11-12, after the report-card and tutorial changes). Re-run: Studio Play, then on the server `task.spawn` the runner in `docs/workshop/testing.md`, write the result to a workspace attribute, read it in a short call.
- Studio: Edit mode, DevMute off, workspace `DevAccountLevel` = 12 (Play starts on the level account; the dev switch flips). `rojo serve serve.project.json` running. Nothing published, nothing Saved to File. The local preview pictures copied into Studio's content folder were removed.
- Cost this session: main Opus only (~55% context at wrap); 1 Codex picture job (jars, ~3 min, Alan's ChatGPT plan); 3 bot matches (~25 min Studio, near-zero tokens); ~8 short muted Studio Plays; 2 picture uploads (free, both Approved); no subagents, nothing paid.

## NEXT ACTION + PLAN
1. **Report card jar piece redo** (spec above and in the jar rules note). Built pieces to reuse: the amount (`PaperJar` change since ACTIVE, follows the attribute), `ShopScreen.jarPicture(parent, inside, x, y, w, h)` (empty jar + full jar clipped at the level), "See your jar" → `Menu.show("shop", false, "PaperJar")` (scrolls to the jar card). Shows every match something went in or the jar is full, even without the Double button; Studio only until go-live. The old orange card is switched off in `showJar` (`false and ...`): replace it, don't keep both. Check on a real card (dev `endMatch` action; the card shows ~8 s after the winners' moment, RESULTS lasts ~15 s; set the client `PaperJar` attribute to fake an amount). Words fit their paper; video (MP4), not stills.
2. **Gift a friend how-it-works note** for Alan's OK (no code before his OK): how a gift reaches the friend (in the server or not), what can be gifted, limits.
3. **Goals review with Alan.**
- HOLDS (his explicit go, each): any upload, publish (he does it), Save to File, desktop control or screen grabs, Studio Play while he's playing, bot matches, anything paid, any new mechanic or number.

## DECISIONS & WHY (this session)
- Big bodies at 3 mounts: no further change; bot match shows them mid-pack ([decision](../../docs/decisions/2026-11-12-big-bodies-three-mounts.md), numbers there).
- Off-centre shop models were **perspective**, not a wrong pivot: the near end looks bigger. Fixed by centring the corners' on-screen spread (`UnlockMoment.view`'s `turn`; lesson added). Starter pack items fill 90% of their box (`still(..., fill)`).
- Dev switch: server swaps the mock profile (`ProfileRuntime:devAccount`/`devSwitch`), keeping the level account to come back to; only `self.mock` (Studio) and `Dev` players; Hangar's own-everything mode follows the `DevAll` attribute.
- Paper jar card in the Paper section (6th card, orange like the packs, no gift button): logged under "Decisions to review" in STATE. Jar note shortened (Alan). **Fill rate stays** after a break (Alan, after the numbers: ~61 matches for an average player).
- Tutorial welcome question never in Studio (`RoundRuntime`; set player attribute `OfferTutorial` to see it).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (docs rules, model router, hard limits). Memories above. `docs/workshop/lessons.md` (new: perspective centring).

## CARRY NOTES / GOTCHAS
- Someone clicked the starter pack's 99 in my test Play (practice buy, "Development simulation complete"); not me. Alan didn't say whether it was him. Ask before Play if he may be in Studio.
- The dev switch (bottom right) covers the 3rd-place name tag during the winners' moment (Studio only): nudge it up.
- First Play after a restart can take ~13 s to load menus: scripted checks must wait for it.
- `UIStroke is not a valid member of TextLabel "CrayonInk"` warning still not looked into. Gun crowding shrink code in `Aircraft.luau` may be unused.
- `assets/ui/shop/raw` and `source` are untracked (as before); `ready/` and `uploads/` are tracked.

## WHAT SHIPPED / OTHER QUEUED
- 0a8139c3 Alan's notes: dev switch, centred part pictures, floating starter items; bot match result
- fb252356 Backlog: daily and weekly missions (Alan)
- 68c5d4e2 Shop: Paper jar card (fill level, Breaks at 3,000, Full!, Are you sure? note)
- cc437a96 Shop: Paper jar pictures uploaded (Alan's go); shorter jar note (Alan)
- 357d61ec Docs: Paper jar card built, pictures approved, note wording
- b2d55365 Paper jar: fill rate stays; report card jar line planned (Alan)
- aafce969 Studio: no welcome tutorial question every Play (Alan)
- 8e0660b6 Report card: jar line with See your jar (first try)
- 7964a076 Report card: jar card off until its redesign (Alan disliked it)
- 0b76e1ca Docs: Alan's third look; redo picked
- Queued: Gift a friend note, goals review, daily/weekly missions (backlog, `docs/plan/IDEAS.md`), XP line on the report card, bots that use the town, skill bonuses, part model redo.

## KNOWLEDGE UPDATED
- Decisions: paper-jar-rules (card built, pictures approved, fill rate stays, report-card piece redo spec); big-bodies-three-mounts (bot match numbers). Playtest: 2026-11-12-double-this-match-and-shop (second-look build, third look). Systems: economy-and-shop (jar card, report-card piece off, centring), tutorial (no Studio question), performance (DevTools dev switch). Workshop: testing (dev switch), lessons (perspective), tools (shop_pieces jars). Plan: IDEAS (missions). STATE rewritten (59 lines). Memory: offer-pieces-catch-the-eye (new). Checker: `python tools/check_docs.py` OK (182 pages).

## POINTERS
- `.planning/paper-jar-preview.jpg`, `.planning/report-card-jar.jpg` (the disliked first try), `.planning/shop-centred-models-before-after.jpg`, `.planning/starter-pack-floating-before-after.jpg`, `.planning/dev-switch-hangar.jpg` · `tools/run_bot_matches.py` · `tools/studio_cli.py` · `tools/ui_pieces.py shop --keep-size --upload`
