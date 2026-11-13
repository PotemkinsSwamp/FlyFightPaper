# HANDOFF — 2026-11-13 — Gift arrival redone to Alan's story and tuned by ear; he ended on "Yeah, that's it"; goals review next

**Labels:** kind=product+ui · lane=beta-lane · branch=main · issues= · areas=src/client/{GiftMoment,MenuBoard,MenuController,DevTools,Audio,UnlockMoment}.luau, tools/film_gift.py, docs/{decisions,playtests,systems,workshop}, state
**Time:** 2026-11-13 01:55 -05:00

★ START HERE: Goal (Alan): the beta feels finished and the shop makes money. Next: the goals review with Alan (what
"the beta feels finished" still needs; backlog in `state/STATE.md`). Done = he has picked the next thing to build and
it is written in STATE. The gift arrival is finished unless he says otherwise.

> Read on demand: AGENTS.md → this file; then `state/STATE.md` and `docs/plan/MILESTONES.md` for the review. Gift
> arrival only if he reopens it: `docs/systems/economy-and-shop.md#the-gift-arriving`, `src/client/GiftMoment.luau`.
> Memories: dev-button-not-workspace-switch (new), audio-picks-links-and-studio (updated), plan-before-building-features,
> offer-pieces-catch-the-eye, mute-studio-tests, studio-play-grabs-mouse, playtest-notes-before-handoff.

## STATE (verify before acting)
- HEAD `d574889e` + this handoff (main), pushed by the commit hook ("github: pushed"). Confirm: `git rev-parse --short HEAD`.
- Tests 599 pass / 0 fail, 42 suites, run after the visual redo (commit db966aa4) and NOT after the later sound, music
  and dev-button commits (client drawing and sound only). Re-run in Studio Play, server:
  `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- Docs checker OK (186 pages): `python tools/check_docs.py`.
- Studio: Edit mode; DevMute, DevGiftMoment, DevGiftTime, DevGiftEnds, DevGiftSelf all cleared. `rojo serve
  serve.project.json` running. Nothing published, uploaded or Saved to File.
- Cost this session (about 1 hour wall clock): main session only on Fable, no subagents, no Codex; about 55-60% of its
  context at handoff. 9 short muted Studio Plays on the menu (no flying), 2 filming runs (~5 min; the first died at
  start), 7 Creator Store sound searches (the three 20-result ones cost the most context: ask for 6-8). Nothing paid.

## NEXT ACTION + PLAN
1. **Goals review with Alan.** Check: the next build item is his pick, recorded in STATE. Any new mechanic or number
   needs a how-it-works note and his OK before code.
2. Smaller, each needing his look: the gift note, the arrival and the report card row at a phone size (none checked);
   a real gift sent through the shop (`DevGiftSelf`) into the new arrival (only pretend gifts were played); the unlock
   backpack's music dip (built, not run); the jar level rises ~1 pixel per match (count-up number offered, no answer).
- HOLDS (his explicit go, each): any upload, publish (he does it), Save to File, desktop control or screen grabs,
  Studio Play while he's playing, any bot match, anything paid, any new mechanic or number.

## DECISIONS & WHY (this session)
- [Decision note](../../docs/decisions/2026-11-13-gift-arrival-story-and-sounds.md): his story, the wait before each
  gift, shine 2, rustle 2, no ding or coin, music to a tenth, no menu song of its own.
- **No new pictures, so no upload:** the lid, body and inside are parts of the one gift box picture, cut on a slant
  with a see-through gradient; each ray is a stroke cut from the rays picture (lessons page has the measured rule).
- **Everything drawn is a function of the time and the tap times** (`draw(t)`), so a held time shows a still: that is
  what lets `tools/film_gift.py` film it frame by frame. Sounds are skipped while filming.
- **The moment waits for the board's own plane to be pinned,** then hides it and flies a copy from the same spot; at
  the end the board's plane and pin are shown again.
- **Open it! is a tap** (button or box). Alan's note said "you open it"; he played it and didn't object.
- **A tap within RISE + 0.5 s of the last is ignored:** Open it! and Thanks! share a spot (design-theory 2.6).
- **Pretend gifts go through `GiftMoment.pretend(keys)`** (the dev button and the `DevGiftMoment` switch both call it);
  they play at once on the main menu, otherwise when it next shows.
- **Music dip also set by the unlock backpack** (Claude's reading of "whenever an animation pops up like this").
- **The pop is the Point Popper's balloon pop, higher and soft:** no licensed cartoon or cork pop was found. Alan
  heard it and said nothing about it.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (docs rules, model router, hard limits); the memories above; `docs/workshop/lessons.md` (4 new lines).

## CARRY NOTES / GOTCHAS
- Alan's last word was "we'll go with rustle 2. Yeah, that's it. Go ahead and hand off." Reading it as his OK of the
  arrival is Claude's; he never watched the video (`.planning/gift-arrival-redo.mp4`, made before the sounds, the
  rummage and the longer wait: it is out of date).
- This shell: a long `python - <<'EOF'` edit failed once on quoting, and one write to `state/STATE.md` failed once with
  "Invalid argument" (a retry worked). Put edit scripts in the scratchpad and run them from there.
- `execute_luau` can't call `Menu.show` (separate module cache): use the `DevScreen` attribute. Clicks: read
  `AbsolutePosition + AbsoluteSize/2` and click those numbers with `user_mouse_input`.
- A gift's shine can ring up to 5 s; it is faded when the next gift comes and at the last Thanks (`hush` in GiftMoment).
- If the menu closes mid-moment (a room move), the gift's cover stays up over the game until its taps are done (as
  before this session; not seen in play).
- Carried: the starter pack card's gap where its gift button was; `assets/ui/shop/raw` and `source` untracked; the
  garbled `mock_ui_label` dash in `config/commerce.json`; Codex's two documented gift-delivery limits.

## WHAT SHIPPED / OTHER QUEUED
- db966aa4 Gift arrival redone to Alan's story: the board's plane leaves its pin and flies over, Open it!, each Thanks brings the next gift out of the box, rays move in and out in turns
- d71350ec Lesson: Studio captures are JPEG pictures
- 3e2659b2 Gift arrival has sounds: ding and coin as it opens, coin for each next gift, whoosh for the plane, thump for the box
- a5864edd STATE trimmed
- 57f20779 Studio button "Dev: send me a gift" plays the gift arriving with two pretend gifts
- c7338679 Gift arrival: music turns right down while it's up, and a shine rings as each gift rises (three to pick from)
- 0af73924 STATE trimmed
- 95eaee03 Gift arrival: shine picked, music down to a tenth, a rummage and a pop before each gift instead of the ding
- d574889e Gift arrival: rustle picked by Alan, try-three code removed; his notes and decision written up
- (+ this handoff commit: sound page, STATE date, LATEST)
- Queued: goals review, daily/weekly missions, treasure chest for buyers (check it's fair and allowed first), XP line
  on the report card, bots that use the town, skill bonuses, part model redo.

## KNOWLEDGE UPDATED
- Decisions: gift-arrival-story-and-sounds (new, listed in the README). Playtest: 2026-11-13-gift-a-friend (what was
  built; "Second look" with his words). Systems: economy-and-shop (Where it stands; new "The gift arriving" section;
  code row), sound-and-effects (music turns down under a menu moment). Workshop: lessons (slanted cut with no upload;
  Edit captures show StarterGui not CoreGui; captures are JPEG), testing (dev gift button, `DevGiftMoment` list,
  `DevGiftTime` taps), tools (`film_gift.py`). STATE rewritten (58 lines).
- Memories: dev-button-not-workspace-switch (new); audio-picks-links-and-studio (three candidates in the moment, the
  dev button cycles them). No skill or CLAUDE.md change proposed.
- Checker: `python tools/check_docs.py` OK (186 pages).

## POINTERS
- `.planning/gift-arrival-redo.mp4` (out of date, see carries) · `tools/film_gift.py` (re-film: muted Play on the main
  menu, then `python tools/film_gift.py OUT.mp4`) · `docs/systems/economy-and-shop.md#the-gift-arriving` ·
  `docs/systems/sound-and-effects.md#rules`
