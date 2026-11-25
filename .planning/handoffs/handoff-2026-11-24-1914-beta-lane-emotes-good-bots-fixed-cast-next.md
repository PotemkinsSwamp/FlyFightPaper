# HANDOFF — 2026-11-24 — Alan: "the emotes were fine now. They're good." Next: the bots become a fixed cast (each name one character model), then a couple more emotes

**Labels:** kind=product · lane=beta · branch=main · issues=none · areas=src/client/WinnersCutscene.luau, src/client/RoundEnd.luau, src/client/FlightHUD.luau, src/client/emotes, src/shared/MatchRules.luau, tests/unit/Match.spec.luau, docs/decisions, docs/playtests, docs/workshop/emotes, docs/workshop/lessons.md, docs/systems/modes-and-scoring.md, state/STATE.md
**Time:** 2026-11-24 19:14 -05:00

★ START HERE: Goal: every bot name is tied to one character model and no new names are ever made (Alan's rule, [decision](../../docs/decisions/2026-11-24-bots-are-a-fixed-cast.md)). Opening action: tell Alan in a few plain lines which names make up "the cast we have now" and how many (my reading: as many as one match can hold) and get his yes, since he believes a saved list of names exists and there is none; then build it. Done when a bot shows the same look under the same name in every match he plays, and a bot that fills in mid-match carries a cast name.

> Read on demand: AGENTS.md → this file → the decision above (it has how names and looks work today). Emote pages only if he raises an emote. Memories: alan-does-play-checks, studio-play-is-shared, plan-before-building-features, fix-the-annoyance-only, emotes-show-feeling-in-movement, playtest-notes-before-handoff.

## STATE (verify before acting)
- HEAD: the commit that adds this file, on `main`; before it `9a3000c0a`. The commit hook pushes to GitHub by itself. Confirm: `git rev-parse --short HEAD`, `git status --short | grep -v '^??'` (empty at handoff).
- Tests: the suite was not run (it needs Play). `tests/unit/Match.spec.luau` has the new tie cases; the same cases were run by hand in Studio's Edit against the synced `MatchRules` and passed. Docs: `python tools/check_docs.py` OK (248 pages).
- Studio: "FlyFightPaper(First Fold)", in Edit at 19:05; Alan goes in and out of his own Play (look before any call). Rojo was serving and syncing all session. **Nothing saved; no Dev attribute set by me; the one test sheet I made in Edit is deleted.**
- Every script changed this session compiles in Studio (`loadstring` on the synced source). Nothing was run in Play by me; Alan played it himself, several times.
- Cost: no agents, no Play runs of mine, no uploads, no generator calls. Primary's context about 42% at handoff, no compaction.

## NEXT ACTION + PLAN
1. **The bots' fixed cast.** Check: his own Play, twice (same names, same looks), and a bot that joins after a player leaves. Facts to start from are in the decision note ("How it works today", "To build it"). New mechanic: his yes on the short how-it-works first.
2. **More emotes** (his words: "Maybe only a couple more. Maybe we won't do any more first place ones, and we'll start looking at the runner-up emotes"). The pipeline: `docs/workshop/emote-pipeline.md`.
3. Later, his: buying the other emotes with Paper and their prices, "once we have all the emotes". Backlog, his: Airspace Control's zones "aren't constructed properly" (not looked at).
- HOLDS (his explicit go, each): every upload, place saves, publish (he does it), every generator call (price first), bot matches, any new mechanic or number.
- Stop rule: the emotes are approved as they play now. Nothing in them is retuned unless he raises it.

## DECISIONS & WHY (this session)
- **Alan's, each with a note in `docs/decisions/`:** bots do a random one of our emotes (plan OK'd, built); a tied team round shows one team on the stand; the stand matches the report card; a human winner does the free emote (Toy Pilot, Good Game), the others bought with Paper later; bots are a fixed cast (not built).
- **Mine, his to reverse (all told to him):** "when they turn it around" read as the turn A+ already has (he then said "A plus looks good"); the card's back drawn as pen strokes in code, no upload; 2nd and 3rd never do the same emote, and a bot beside a human never does Good Game; So Close's sigh still cut under A+ or Skeet Shoot; the dice for bots' emotes are the match's id so all screens agree; a winner counts as a bot when no player in the server has their id; hidden winners appear all at once when no building is in the way (he: "better now. It'll have to do for a beta").
- **The tie he met was not a bug in a normal match:** with a winning team the stand was always that team's top three. What was wrong: a tie mixed both teams, A+ took "the card with the star" (a tie has none), and the card sorted equal points in any order.
- **I could not tell which code one of his reports was about** (a match keeps the code it started with). He played again and found nothing wrong.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md; the memories named above; `docs/workshop/lessons.md`, "Fixes Alan checks in his own Play".

## CARRY NOTES / GOTCHAS
- **Not seen by him one by one:** he said "the emotes were fine now" without naming which cases he played. Unconfirmed by name: a tie's stand, "end: real", himself on the free emote, A+ in a team match with the right card, the Dev buttons' top layer, the smiley reading as smug.
- **In Studio every "end:" button except "end: real" still forces our emotes on everyone** through `DevFirstEmote` / `DevRunnerUp`, and the two attributes stay set until another button changes them. "end: real" clears both.
- **Bots' names today:** made from word parts by the bot's number on the server (`newIdentity`, `src/shared/BotRosterRules.luau`; the seed is fixed in `config/server.json`), so a server's first bots are always the same names; a later fill-in gets a new one. Looks: `Service:look` in `src/server/AvatarService.luau`, 157 outfits in `config/gameplay.json`. Bot ids are `bot-roster:<number>`; dev bots are `bot-mix:<k>` named "Mix N".
- No Luau checker on this PC outside Studio; no compile check is possible while Studio is in his Play.
- `.planning/emotes/*` are untracked working files. The seen-in-stills items of the last handoff (grey head as the camera leaves, brighter room in some takes) are unchanged and not raised by him.

## WHAT SHIPPED / OTHER QUEUED
Commits (newest first): the commit with this file · `9a3000c0a` lessons · `85880ca7c` emotes good; bots a fixed cast (decided) · `a099bb52e` backlog; free emote compile-checked · `b5f6cb8bd` a human winner does the free emote · `77dda8b65` the stand matches the report card · `244bd995a` a tied team round shows one team · `dc61e68ea` second round: A+'s own team card, Fold It Up's two hand moves, bots' random emotes, "end: real" · `96ce78327` first round: A+ the real card with the A+ back, Fold It Up's hands at the chest, winners hidden behind buildings · `3d6023e5f` his problems written down.
Queued, not started: the bots' cast; more emotes (runner-up ones first); emote prices and buying; Airspace zones; class reaction; the backlog in STATE.md.

## KNOWLEDGE UPDATED
- `docs/playtests/`: three notes for his three looks (problems; second look; the stand matches the card, with his "the emotes were fine now"). README lines.
- `docs/decisions/`: a tied team round shows one team; a human winner does the free emote; bots are a fixed cast (new); bots do a random one of ours (status: built). README lines.
- `docs/workshop/emotes/a-plus.md`, `fold-it-up.md` (a section each); `docs/workshop/emote-pipeline.md` (both rows); `docs/systems/modes-and-scoring.md` (winners hidden behind buildings; who is on the stand and which emote); `docs/workshop/lessons.md` (five lessons); `state/STATE.md`. Checker: OK (248 pages).
- Memory: `emotes-show-feeling-in-movement` (confident is slow; two meanings, two motions).

## POINTERS
- Who does which emote: `Cutscene.choose`, `Cutscene.emoteName`, `Cutscene.FREE` in `src/client/WinnersCutscene.luau`; hidden winners: `Cutscene.behindBuilding`. The stand: `Rules.winners` in `src/shared/MatchRules.luau`. The card's order and the hidden level bar: `src/client/RoundEnd.luau`. A+'s card: `front`, `back`, `realPage` in `src/client/emotes/APlus.luau`. Fold It Up's hands: `SCHEME`, `BRUSH`, `rubArms` in `src/client/emotes/FoldItUp.luau`. Dev buttons: `winnersDev` in `src/client/FlightHUD.luau`.
