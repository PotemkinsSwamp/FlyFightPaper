# HANDOFF — 2026-11-09 — crisp-menus first try rejected and fully undone; next: fix stretched pictures by their boxes

**Labels:** kind=ui · lane=beta-lane · branch=main · issues= · areas=docs/playtests, docs/decisions, docs/workshop/lessons.md, state/STATE.md
**Time:** 2026-11-09 00:58 -05:00

★ START HERE: Goal (Alan): the beta feels like a finished game. Next: fix the STRETCHED menu pictures on every screen
WITHOUT changing any picture: draw each picture in a box of its own shape (fix the box, keep the art, tacks and tape
exactly as painted). Open with: measure every screen (menus AND in-match: desk, Esc menu, Match tip, Range notes, Range
board), fix one screen, show Alan that one before doing the rest. Done when Alan says nothing looks stretched.

> Read on demand: AGENTS.md → this file; docs/playtests/2026-11-09-menu-stretch-examples.md (his examples, the target
> list); docs/decisions/2026-11-08-text-style-crayon.md (newest bullet = the ruling); docs/workshop/lessons.md (last 4
> bullets: measure stretch, 9-slice, local picture preview). Memories: tacks-and-tape-fixed-size (rewritten tonight),
> assembled-preview-before-upload, look-at-textures-before-upload, alan-does-play-checks, studio-play-grabs-mouse.

## STATE (verify before acting)
- HEAD `77fdb859` on `main` before this handoff's commit; the code and art are exactly as at 77fdb859 (everything tried
  tonight was reverted; `git status --short src assets/ui` empty). Confirm: `git rev-parse --short HEAD`.
- Tests: 476/0 at 77fdb859 (not re-run tonight; no code changed). Re-run in Play: on Server
  `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()` via `task.spawn` + a workspace attribute.
- Docs: `python tools/check_docs.py` OK (161 pages). Studio: Edit mode, Rojo connected, DevMute on.
  Published v495; nothing saved, published or uploaded since.
- Cost tonight: Opus main only, no subagents, no Codex, nothing paid; ~1 h wall clock; primary context ~60% at handoff.

## NEXT ACTION + PLAN
1. **Measure every screen.** Menus by `DevScreen` (home, settings, hangar, hangar:customize, shop, queued); in-match ones
   (desk menu, Esc clipboard, Match tip, the Range's notes and board, lesson notes) need a match/Range in Play. Method in
   lessons ("Measure stretch"); also look for misplaced pieces (the Hangar's "Presets" paper overlaps the Loadout tape).
   Tonight's menu numbers: 60 of 151 pictures off by >10%.
2. **Fix by box shape**, piece by piece: keep each piece's centre (or edge it lines up with), set its size to the
   picture's own width:height, and move the words to fit. Where the screen truly needs another shape (the wide Match tip
   note; possibly the Customize stats paper and part cards), propose a new piece in the same style and show Alan an
   assembled preview before any upload (local preview trick in lessons, nothing uploaded).
3. Show Alan ONE fixed screen first (in-game screenshot, before/after); on his OK do the rest; he signs off when nothing
   looks stretched.
4. Bug: after a match, the match strip (FFA + clock) stays over the Hangar Range. Find who shows it; hide it outside a match.
5. Then the unlock moment (`.planning/unlock-concept2/`); later the shop step and the balance pass (STATE).
- HOLDS (Alan's explicit go, each): publish (he does it), Save to File, any upload, desktop control, Studio Play while
  he's playing, a bot match (in-match screens may need one: ask), anything paid, any new mechanic or number.
- Stop rule: build, don't re-review. One before/after per screen is the check; no extra review passes.

## DECISIONS & WHY (this session)
- **Keep the pictures, fix the boxes** (Alan's ruling, in the decision note): painted tacks/tape with shadows are the look;
  never scrub, swap, recolour or squash them.
- **The 3D drawing way stays.** I tried drawing PC menus as plain pictures (sharper cork); Alan: the main menu was already
  sharp, his problem is stretching. Reverted. Only the Customize part cards "could be sharper" (they are squeezed 0.40).
- Rejected and reverted tonight (don't redo): tacks/tape scrubbed off 10 pictures; code-drawn tacks (32) and tape;
  9-slice on every button; Back strip swapped to the main-menu red; Save/Fly given green pins instead of tape.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md; memories above; lessons "A quality fix keeps the pictures", "Words must sit inside what they're on".

## CARRY NOTES / GOTCHAS
- 9-slice bends any painted tack crossing a slice line; only use it on plain paper, if at all.
- Local preview: `%LOCALAPPDATA%\Roblox\Versions\version-fee454b8e2094ba9\content\textures\<folder>\` →
  `rbxasset://textures/<folder>/x.png` (Studio only; the folder from tonight is deleted).
- Studio MCP calls sometimes fail with "auto mode classifier gave no verdict"; retrying once usually works.
- Untracked junk in the repo root predates tonight (`captures${names[*]}.jpg`, `_reset_2026-10-06/`); not mine, left alone.

## WHAT SHIPPED / OTHER QUEUED
- Shipped: (this commit) playtest note 2026-11-09-menu-stretch-examples, decision ruling, 4 lessons, STATE, this handoff.
  No code or art commits.
- Queued: Save to File + publish (Alan's go); results card → report card (must do); winners' circle, skins, shop step.

## KNOWLEDGE UPDATED
- playtests: new 2026-11-09-menu-stretch-examples (his examples + the bug), listed in README.
- decisions: text-style-crayon gets the "fix the boxes, keep the pictures" ruling (replaces my wrong "pins as separate
  pieces" plan line).
- lessons: quality fix keeps the pictures; 9-slice bends crossings; local picture preview; measuring stretch.
- STATE rewritten (54 lines). Memory: tacks-and-tape-fixed-size rewritten to Alan's real meaning. Checker: OK (161 pages).

## POINTERS
- src/client/PaperUI.luau (`button` stretches its picture to w x h; `image` fits), src/first/UISheets.luau (piece →
  sheet cut, pixel sizes), src/first/MenuArt.luau, assets/ui/*/ready (picture sizes), tonight's previews:
  .planning/crisp-menus-*.jpg (the rejected look), .planning/crisp-only-zoom.jpg.
