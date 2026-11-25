# HANDOFF — 2026-11-24 — The bots are a fixed cast of twelve; four more runner-up emotes built, approved and uploaded (eight for each slot). Next: talk through a shop for the emotes

**Labels:** kind=product · lane=beta · branch=main · issues=none · areas=src/shared/BotRosterRules.luau, src/server/AvatarService.luau, config/gameplay.json, src/client/WinnersCutscene.luau, src/client/FlightHUD.luau, src/client/Audio.luau, src/client/emotes, tools/emote_cuts, assets/animations/emotes, docs/decisions, docs/playtests, docs/workshop/emotes, docs/workshop/emote-pipeline.md, docs/workshop/lessons.md, docs/systems/bots.md, docs/systems/modes-and-scoring.md, state/STATE.md
**Time:** 2026-11-24 22:32 -05:00

★ START HERE: Goal: a shop where players buy the other emotes with Paper (Alan: "next, we'll talk about creating a shop for the emotes"). Opening action: talk it through with him in plain words before anything is planned: where it lives, what a card shows, how an emote is previewed, prices, how a bought emote is picked for each slot. It is a new mechanic with new numbers, so a short how-it-works note needs his OK before code. Done (for the talk) when he has OK'd that note.

> Read on demand: AGENTS.md → this file. For the shop talk: `docs/systems/economy-and-shop.md`, `docs/decisions/2026-11-24-a-human-winner-does-the-free-emote.md`, the two emote lists in `docs/systems/modes-and-scoring.md`. Memories: plan-before-building-features, familiar-roblox-layouts, in-game-menus-match-main-menus, offer-pieces-catch-the-eye, load-first-reuse-art, explain-plans-in-text, emote-pipeline-side-sessions.

## STATE (verify before acting)
- HEAD: the commit that adds this file, on `main`; before it `55e73dee0`. The commit hook pushes to GitHub by itself. Confirm: `git rev-parse --short HEAD`, `git status --short | grep -v '^??'` (empty at handoff).
- Tests: the suite was not run (it needs Play). `tests/unit/BotRoster.spec.luau` (17 cases, the new BR16 for the cast) passed when run in Studio's Edit on fresh copies of the modules. Docs: `python tools/check_docs.py` OK (254 pages).
- Studio: "FlyFightPaper(First Fold)", in Edit at 22:20; Alan goes in and out of his own Play. Rojo serving. **Place not saved.** No draft emote clips are left in the place's `Assets` (all seven new clips play from their uploads). No Dev attribute set by me.
- Every script changed this session compiles in Edit (`loadstring` on the synced source). No Play run of mine; Alan played everything himself.
- Cost: four side sessions, one per emote (asked for on Opus 5.5; the model was not confirmed, tokens not measured), archived. Gemini: 5 reference videos, about $1.40, each on his go in its session. Uploads: 7 clips and 1 sound, free. Primary's context about 41% at handoff, no compaction.

## NEXT ACTION + PLAN
1. **The emote shop: the talk, then a how-it-works note for his OK.** Facts to bring: 16 emotes, 8 per slot, one free in each (Toy Pilot, Good Game); a person who places does the free one today (`Cutscene.FREE`); bots do a random one. Nothing about owning or picking an emote is saved yet (saving is Track C, Codex's lane).
2. Then build it to the OK'd note; his Play is the check.
3. His looks still open (in STATE.md, "Waiting on Alan"): the four new emotes from their uploads; Test Flight's whoosh loudness; the bots' cast.
- HOLDS (his explicit go, each): every upload, place saves, publish (he does it), every generator call (price first), bot matches, any new mechanic or number.
- Stop rule: the sixteen emotes are approved as they play. Nothing in them is retuned unless he raises it.

## DECISIONS & WHY (this session)
- **Alan's, each in `docs/decisions/` or the playtest note:** the cast is twelve names ("yes"); eight runner-up emotes to match the eight for 1st; the four picked; Slow Clap dropped (Good Game already is one); Sneaky Toss's ball misses, off to the side behind 1st; no whistling in it, innocence by body language; Test Flight sits; its plane's whoosh is its sound; Doodler's drawing is the kid in 1st with an arrow and "me", and it shortens itself when 1st's emote cuts the time.
- **Mine, his to reverse:** a cast bot keeps its name and look only, skill and plane are still dealt per match; a fill-in takes the first free cast name from its own place in the list; three tries at Roblox's outfit lookup before the plain outfit; `bot_look_outfits` (157) stays for Studio's "Mix N" test bots; the whoosh at volume 1 (the file peaks 26 dB under full); the new emotes went into `RUNNER_UPS` at upload, so bots do them in real matches; Doodler's notebook now covers the lower face on most bodies (told before he looked; he said "all 4 are good").
- **`kit.seenFor()`** is new shared scene code he asked for in effect ("figure out some way to make it shorter"): seconds after 1st's light for which the runner-ups are seen. A+ and Fold It Up got a `hides` number for it.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md; the memories named above; `docs/workshop/lessons.md`, "Runner-up emotes built four at once" and "Fixes Alan checks in his own Play".

## CARRY NOTES / GOTCHAS
- **Not seen by him:** any of the four new emotes from the uploads (identical by keys, poses and pose sum to the drafts he approved); the whoosh at all (the sound was in Roblox's review, loads in Studio).
- **The bots' cast was not confirmed by name.** His "looks good" came with the emote talk; I did not ask whether he saw the same looks twice or a fill-in. It is on his list.
- "fold + doodler" is a Dev button for Doodler's short version; the 1st-place "end:" buttons now rotate all eight runner-ups.
- A side session's `emote_preview.py` runs share one `_G.EMOTE` in Studio; two at once wipe each other.
- `.planning/emotes/*` are untracked working files (videos, the sessions' .rbxm copies).
- Not run: a lookup failure of a cast outfit in a real server (the three tries and the fallback are untested).

## WHAT SHIPPED / OTHER QUEUED
42 commits, `470a82047` to `55e73dee0`, plus the one with this file: `git log --oneline 9dc61c0bd..HEAD`. The ones that changed the game: `470a82047` the bots' fixed cast · `e26c6b816` `kit.seenFor` and Alan's first look · `a5be0f7e2` Sneaky Toss uploaded and in · `54a00a0c3` Sore Loser, Test Flight, Doodler uploaded and in · `5647e52e7` `e8dcd39c4` `60521fdec` `69ea5063c` `091d9febf` the Dev buttons and clip files. The side sessions' builds: Sore Loser `941e3749f` `95ba31c7a` · Test Flight `5d1d405f3` `ace490b4a` · Sneaky Toss `a36e2d209` `9396be6aa` · Doodler `d0aaae33f` `745a14bca` `aeb147b0e` `544c3c776`.
Queued, not started: the emote shop; Airspace Control's zones (his: "aren't constructed properly"); class reaction; the backlog in STATE.md.

## KNOWLEDGE UPDATED
- `docs/decisions/`: bots are a fixed cast (status built, the twelve names); four more runner-up emotes (new). README lines.
- `docs/playtests/2026-11-24-the-four-new-runner-up-emotes-first-look.md` (new): his three looks. README line.
- `docs/workshop/emotes/`: sore-loser, doodler, sneaky-toss, test-flight (new, each kept by its session). `docs/workshop/emote-pipeline.md`: the four rows, `seenFor`, `hides`. `docs/plan/WINNERS-CIRCLE-PLAN.md`: Slow Clap dropped, Sneaky Toss's wording.
- `docs/systems/bots.md` (the cast, Code table); `docs/systems/modes-and-scoring.md` (eight emotes per slot); `docs/workshop/lessons.md` (eight lessons); `state/STATE.md`. Checker: OK (254 pages).
- Memory: `emote-pipeline-side-sessions` (button at once; notes given in the primary), `emotes-show-feeling-in-movement` (a held pose reads as no feeling).

## POINTERS
- The cast: `avatar_display.bot_cast` in `config/gameplay.json`; `newIdentity` in `src/shared/BotRosterRules.luau`; `Service:look` in `src/server/AvatarService.luau`.
- Emote lists and who does which: `Cutscene.FIRSTS`, `RUNNER_UPS`, `FREE`, `choose`, `kit.seenFor` in `src/client/WinnersCutscene.luau`. Clip ids: `rounds.emote_clips` in `config/gameplay.json`. Sounds: `src/client/Audio.luau`. Dev buttons: `winnersDev` in `src/client/FlightHUD.luau`.
- Shop today: `docs/systems/economy-and-shop.md`.
