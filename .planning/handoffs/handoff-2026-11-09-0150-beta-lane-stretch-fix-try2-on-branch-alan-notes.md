# HANDOFF — 2026-11-09 — stretch fix try 2 parked on a branch; Alan's second-look notes are the list

**Labels:** kind=ui · lane=beta-lane · branch=main · issues= · areas=src/client (PaperUI, Hangar, HangarCustomize, DeskHangar, notes), src/server/RangeStage.luau, assets/ui, AGENTS.md, docs
**Time:** 2026-11-09 01:50 -05:00

★ START HERE: Goal (Alan): the beta feels finished; right now, menus where nothing is stretched, every word sits
inside its paper, every paper sits inside its parent paper, no overlaps. Open with the list in
docs/playtests/2026-11-09-menu-stretch-examples.md ("Second look"), and the parked work on branch
`wip/stretch-fix-2026-11-09` (commit 60939e73). Take from it only what Alan liked or didn't object to; redo the rest.
Done when Alan says the menus look right. Check every screen on a screenshot against AGENTS.md's new "Words and papers
fit" rule BEFORE showing him.

> Read on demand: AGENTS.md (new rule under "How to check work") → this file → the playtest note → decision note
> 2026-11-08-text-style-crayon (last 2 bullets) → lessons (last 4). Memories: tacks-and-tape-fixed-size,
> text-fits-its-box, assembled-preview-before-upload, alan-does-play-checks.

## STATE (verify before acting)
- `main`: code and art exactly as at 77fdb859 (handoffs/docs since). `git status --short src assets/ui` empty.
- Branch `wip/stretch-fix-2026-11-09` @ 60939e73 (local; not merged, not for publishing: its UIAssets points 7 new
  pieces at `rbxasset://textures/ffp-preview/...` files that exist only in Alan's Studio content folder
  `%LOCALAPPDATA%\Roblox\Versions\version-fee454b8e2094ba9\content\textures\ffp-preview\`).
- Tests 476/0 at 77fdb859 (no main code change since). Docs checker OK. Studio: Edit mode, Rojo connected (now serving
  main). Published v495; nothing saved, published or uploaded.
- Cost tonight: Opus main only, no subagents, no Codex, nothing paid; ~2 h wall clock; context ~63% at handoff.

## NEXT ACTION + PLAN
What the branch has (judge each against Alan's notes; `git show 60939e73 --stat`):
- KEEP (Alan liked / no objection): Range signs drawn at full resolution (RangeStage `paint` PixelsPerStud, words on
  their own "Words" SurfaceGui; RangeBoard reads `.Words`); PaperUI.button keeps the picture's shape (Fit); Back on the
  red-dot strip at its own shape; part cards from the trimmed card shapes (cards fine; only their words need fixing).
- REDO: the note's X (little square red paper box, fully on the note; e.g. cut a square from a red strip's plain
  middle and keep its torn edges); the wide stats paper (smudge beside the tape: the inserted band came from x 500-655,
  too near the tape: take a band further right/below the tape, or keep the original paper and make its BOX bigger);
  Customize and Hangar stat sheets: bigger paper so all 6 rows fit with margin; card names (TextScaled/size per card
  so "Paper Pellet Gun" fits like "Spitball Straw"); desk note words vs the thinner tape (bigger tape box or smaller
  words); Settings Back clear of the High tab; a paper under "Presets can't be changed...".
- BUGS: FFA strip hidden at the desk (FlightHUD `match` check uses the plane's `Practice`; FlightService sets it only
  true, line ~197: set `Practice` to `p.practice or nil`); the Range's note stays on the main menu after leaving the
  Range (RangeNotes visibility); in the Range the Menu strip couldn't be clicked and the view looked zoomed out (test on
  main first: was it tonight's RangeStage change?).
- Then: upload the new pieces (Alan's go, contact sheet first), swap the preview paths for ids, merge to main, commit,
  push. Then the unlock moment.
- HOLDS (Alan's go, each): publish (he does it), Save to File, any upload, desktop control, Studio Play while he's
  playing, a bot match, anything paid, any new mechanic or number. In-match screens (desk, Esc, Match tip, Range): give
  Alan a what-to-look-at list (he plays; my Play grabs his mouse when flying).
- Stop rule: one before/after per screen, checked against the rule, then show Alan. No extra review passes.

## DECISIONS & WHY (this session)
- Keep the pictures; fix the boxes; papers fit inside papers; bigger paper rather than cram; square X box (decision note).
- Main keeps the 3D menu drawing (main menu already sharp). Range signs were the real blur (1 pixel per stud).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (new rule "Words and papers fit"); memories above; lessons "A quality fix keeps the pictures".

## CARRY NOTES / GOTCHAS
- A `--` comment inside a one-line call cuts the call off (I broke the menus once tonight: Tutorial.luau).
- To try the branch: `git switch wip/stretch-fix-2026-11-09` (Rojo syncs it; preview pictures already in Studio's
  content folder). Never `git stash` (lessons). Branch is local only.
- Studio MCP "auto mode classifier gave no verdict": retry once.

## WHAT SHIPPED / OTHER QUEUED
- 90ba1d12 Handoff: crisp-menus try rejected and undone; Alan's ruling and stretch examples; fix boxes next
- 60939e73 (branch `wip/stretch-fix-2026-11-09`, not main) WIP: stretch fix try 2
- (this commit) playtest note second look, decision bullet, AGENTS rule, STATE, this handoff.
- Queued: Save to File + publish (Alan's go); report card; winners' circle, skins, shop step; balance pass.

## KNOWLEDGE UPDATED
- playtests/2026-11-09-menu-stretch-examples: "Second look" section. decisions/text-style-crayon: papers fit, bigger
  paper, square X. AGENTS.md: "Words and papers fit" rule (corrected twice). STATE rewritten. Checker: run on commit.

## POINTERS
- src/client/PaperUI.luau, Hangar.luau (`statSheet`, `nameTag`, Presets note), HangarCustomize.luau (cards, title),
  DeskHangar.luau (note tape), Tutorial.luau (Ask/X), RangeNotes.luau, FlightHUD.luau (~line 327), FlightService.luau
  (~197), RangeStage.luau; previews .planning/stretch-fix-*.jpg; Alan's screenshots are described in the playtest note.
