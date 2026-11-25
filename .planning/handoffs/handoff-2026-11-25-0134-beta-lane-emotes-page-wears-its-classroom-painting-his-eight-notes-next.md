# HANDOFF — 2026-11-25 — The Emotes page wears its classroom painting (approved, uploaded, wired, seen by Alan in Play); his eight notes are next

**Labels:** kind=product+ui · lane=beta · branch=main · issues=none · areas=src/client/EmoteShop.luau, src/first/UIAssets.luau, assets/ui/emoteshop, docs/plan/EMOTE-SHOP-PLAN.md, docs/decisions, docs/playtests, docs/workshop/lessons.md, state/STATE.md
**Time:** 2026-11-25 01:34 -05:00

★ START HERE: Goal: the Emotes page plays every emote on its TV whole and right, and what plays inside the TV looks as good as the page. Opening action: fix the two TV faults Alan hit first, an emote cut off before its end (Bubblegum never gets scraped off the glass) and the last emote's sound still playing after another card is tapped. Done when he sees Bubblegum run to its end and hears silence from the old emote after a switch, in his own Play (or in a Play run of yours, on his go).

> Read on demand: AGENTS.md → this file. For the notes: `docs/playtests/2026-11-25-emotes-page-with-its-painting.md` (his words, all eight). For the TV: `Cutscene.tv` at the end of `src/client/WinnersCutscene.luau`. For the TV's set: `docs/plan/EMOTE-SHOP-PLAN.md`, "Build order" 2b. Memories: visual-qa-before-showing, plan-before-building-features, audio-picks-links-and-studio, emotes-on-odd-avatar-bodies, alan-does-play-checks, scripts-through-the-write-tool.

## STATE (verify before acting)
- HEAD: the commit that adds this file, on `main`; before it `ce77d9bd0`. The commit hook pushes to GitHub. Confirm: `git rev-parse --short HEAD`, `git status --short | grep -v '^??'` (empty at handoff).
- Tests: the suite was not run (it needs Play). Docs: `python tools/check_docs.py` OK (259 pages).
- Studio: "FlyFightPaper(First Fold)" in Edit at 01:30; Alan goes in and out of his own Play; a second Studio ("Chum-a-Chum") is open: use the FlyFightPaper id. Rojo serving. **Place not saved.** Nothing of mine left in the place (two temporary folders made and deleted; camera lens put back to 70).
- `EmoteShop` and `UIAssets` compile in Edit (`loadstring` on the synced source) at 01:31, with the price ordering in.
- **Seen by Alan in Play** (build `a7f9712b2`): the page with its painting; his two screenshots show the glass over the picture, cards three across, name and buttons on the cart. **Not seen by anyone:** the cards in price order; the page on a phone or a tall screen (stretched edges); Use / Using on the cart; the main menu's three strips, Magician's framing and the jacket rule (he has never said).
- The four tiles were "Reviewing" at upload (01:17); they drew in his Play minutes later.
- Cost: two Codex picture jobs on his ChatGPT plan (about 76,000 tokens each); two independent reviewer passes (Opus subagent, about 127,000 tokens each); four free uploads. No Play run of mine, no place save. Primary's context about 50% at handoff, no compaction.

## NEXT ACTION + PLAN
1. **Notes 3 and 4** (the opening action above). Not looked into; where to look first is in CARRY NOTES.
2. **Notes 5, 6, 7:** a kid floating over the books in Nap; Sneaky Toss's ball hanging in the air (he wants it thrown off screen, left or right, and gone); Test Flight's plane flying backwards and upside down. Check each in the real winners' moment too: 7 may be the emote itself.
3. **Note 8, the TV's own picture:** fix the trial set's flat desk and flat light, show him the picture inside the page, then write it into `TV.room`, then his look in Play. Plan already OK'd by him.
4. **Note 2, the TV's sounds** (on, off, click): three licensed candidates on a Dev button, his pick by ear; the emote's own sounds quieter in the page.
5. Then: the card stills (props, the sixteen moments in `TV.POSE`), the page on a phone.
- HOLDS (his explicit go, each): every upload, place saves, publish (he does it), every generator call other than Codex pictures (price first), any Play run of mine, bot matches, any new mechanic or number.
- Stop rule for pictures: one independent reviewer pass per new picture; when what it still calls "no" is a trade-off rather than a fault, show Alan with that list first instead of another round.

## DECISIONS & WHY (this session)
- **Alan's:** the classroom painting as drawn ("this looks great to me"), the cabinet cart stays ("we can change it then"); what plays inside the TV must look as good ("a nice background, lighting, textures"); his go on the upload and on the plan for the TV's set ("go on all"); cards in price order. All in `docs/decisions/2026-11-24-emote-shop.md` and the playtest note.
- **Mine, his to reverse:** a room in one-point perspective instead of a wall of chalkboard (the first painting was turned down by the reviewer and by me); a chalkboard left and a blue bulletin board right; cards three across at 166 x 127 (were 196 boxes, two across), so their words are smaller (22 and 20, were 27 and 24); the glass 600 x 450 (was 640 x 480); the name and buttons on the cart's cabinet front; "Your Paper" on a tape label; a pin on each card; the chalkboards are part of the painting, not the Shop's loaded one.
- **Why one painting with a see-through glass:** the hole is then exactly centred by construction; Codex painted over a flat guide drawn from the code's numbers and pasted the guide's pink shape back, so the glass came back pixel-exact.
- **Why the boards were stretched in pixels:** my brief asked for 3% of plain wall at the sides, which fought the guide; Codex drew both boards 40 pixels short. Plain slate and blue paper were stretched, nothing redrawn.
- **Why wider and taller screens get stretched edge pixels:** no extra pictures to download; it is unseen and may look streaky on a phone.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md; the memories named above; `docs/workshop/lessons.md` (three new lessons under "Making 3D models", next to the Codex picture job line).

## CARRY NOTES / GOTCHAS
- Where I would look first, unverified: the TV ends an emote at `leaveAt(s)` in `TV.frame`; `TV.stop` is where a lingering sound would have to be stopped; the winners' moment seats a kid with `sit`, and whether the TV's path runs it is unchecked; on the TV a Runner-up emote has a 1st who is not there (`s.stub`), which is who Sneaky Toss throws at.
- The reviewer still called the approved picture short on: card words small, wheels touching the bottom edge of a wide screen, the switched-off TV a dark mass. Alan saw the same picture and approved it; I did not act on these.
- Brown cards on the blue board measure 2.8 to 1 (our rule says 3 to 1).
- The painted power light is always lit; a dark dot covers it while the TV is off (`Lamp`, sheet 1259, 787).
- Before this session's layout the two buy buttons hung 22 pixels off a wide screen and a card's still poked past its paper; both are gone with the new numbers.
- `state/STATE.md` is 63 lines (the rule is under 60): trim it at the next rewrite.
- `.planning/emote-shop/` is untracked: his four photos, the assembled pictures, `compose.py`, `compose2.py`, `guide2.py`, `tv_on.py` (they rebuild every picture from `assets/ui/emoteshop/raw/`; the pose photos they read are in this session's tool-results folder and may be gone).
- A bash heredoc with an apostrophe failed again here: write the script with the Write tool, then run it.

## WHAT SHIPPED / OTHER QUEUED
`git log --oneline e25415285..HEAD`:
- `4ab6f39af` Codex's first two paintings, the guide and the brief · `ddb88f2bd` the second guide (a room) and its two paintings
- `1c51b2a0d` the picture assembled, what the reviews found short · `2e9c85e28` Alan's OK, the four tiles cut
- `b26bf28de` the four tiles uploaded · `a7f9712b2` the page wired to the painting
- `f17a48088` plan and STATE after the wire-in · `ce77d9bd0` cards in price order, his eight notes
- plus the commit with this file.
Queued, not started: Airspace Control's zones; class reaction; his looks at the four new runner-up emotes from their uploads and at the bots' cast; the backlog in STATE.md.

## KNOWLEDGE UPDATED
- `docs/plan/EMOTE-SHOP-PLAN.md`: new section "The page's picture" (how it was made, both tries, the layout numbers, what is still short, load cost); "As built" and "Build order" brought up to date (2 done, 2b the TV's own picture).
- `docs/decisions/2026-11-24-emote-shop.md`: his OK on the picture and his ask for the TV's own picture.
- `docs/playtests/2026-11-25-emotes-page-with-its-painting.md` (new) and its README line: his eight notes.
- `docs/workshop/lessons.md`: painting over a flat guide; a wall is not a room; your own avatar in a pose without a Play run.
- `state/STATE.md`: the Emotes lines and "Waiting on Alan".
- Memory: `visual-qa-before-showing` (one pass a picture; trade-offs go to Alan). Checker: OK (259 pages).

## POINTERS
- The page: `src/client/EmoteShop.luau` (numbers at the top; the painting's tiles in `tile`; the cart's front; the cards' loop with the price order).
- The painting's ids: `emoteshop.room` in `src/first/UIAssets.luau`; files in `assets/ui/emoteshop/` (`raw/` Codex's, `source/` and `ready/` the four tiles, `uploads/` Roblox's answers).
- The TV: `Cutscene.tv` in `src/client/WinnersCutscene.luau` (`TV.room` the set, `TV.play`, `TV.frame`, `TV.stop`, `TV.POSE`).
- The trial set's picture: `.planning/emote-shop/room-a-tv-on-trial-set.png` (not shown to Alan); what it was built from: the plan page, 2b.
