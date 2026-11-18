# HANDOFF — 2026-11-18 — Missions built end to end (maker, counters, saving, Claim/Swap, sheet, desk drop-down); nothing seen in Play yet

**Labels:** kind=product+ui · lane=beta-lane · branch=main · issues=none · areas=src/shared/Missions.luau, src/server, src/client/MissionsScreen.luau, src/client/MissionsDropdown.luau, src/client/DeskHangar.luau, config/missions.json, docs
**Time:** 2026-11-18 15:53 -05:00

★ START HERE: Goal: daily and weekly missions working in the game exactly as in `docs/decisions/2026-11-18-daily-and-weekly-missions.md`. All code is in (`4745a38c`), but **no test has run and nothing has been seen in Studio**. Opening action: ask Alan's go for ONE Studio Play, then in it run the unit tests, press "Dev: finish missions", and screenshot the main-menu Missions sheet (Daily and Weekly) and the desk drop-down (PC and phone size). Done when tests pass and Alan has the sheet and drop-down pictures (design-theory checklist run first).

> Read on demand: AGENTS.md → THIS → the missions decision. Codex's record of the saving job: [handoff-2026-11-18-beta-lane-mission-saving.md](handoff-2026-11-18-beta-lane-mission-saving.md). Memories: alan-does-play-checks, studio-play-grabs-mouse, visual-qa-before-showing, design-theory skill, mute-studio-tests.

## STATE (verify before acting)
- HEAD `4745a38c` (main), pushed (hook copies to GitHub). Confirm: `git rev-parse --short HEAD`. Docs: `python tools/check_docs.py` OK.
- Tests: **not run** (Codex wrote ~30 new/changed tests: Missions, ProfileSchema, ProfileService, ProfileRuntime, RoundRuntime, ShopSave; ChestProgress tests deleted). Run in a Studio Play server: `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()` (last known: 719 passed, Codex save 820).
- Studio: open with `rojo serve` running (live-syncs `src/` into Alan's Studio). Save schema is now **16** (missions added, `chests.progress` removed): saves migrate on load. No place save made this session.
- Codex CLI updated 0.159.2 → 0.170.0 (`D:\npm-global`); GPT-6.2 Sol now works through the plugin.
- Cost this session: 3 codex-rescue relays (Sonnet-side ~53k, ~32k, ~40k tokens; Codex itself on Alan's ChatGPT plan), ~2 h wall clock. Main context at handoff ≈ 42%.

## NEXT ACTION + PLAN
1. **Play check (Alan's go):** tests; Dev: finish missions; main-menu Missions sheet both tabs (Claim, Swap, the fixed 15-dailies card with the week calendar; check the ✓ glyph renders in Kalam); desk drop-down (opens under the cream Missions strip, Daily/Weekly switch, folds on second tap, red "!" when claimable, readable over the busy runway at 22% see-through, phone size scroll). Then a real match: the summary reaches the save (progress moves).
2. **Report card tick slip** (not built): a torn notebook slip taped to the card's right edge, red-pen tick drawing itself, words only "Mission done! Check your Missions." (no mission names, Alan). Listen to the `MissionsFinished` RemoteEvent (server fires it after the statistics op finishes missions). File: `src/client/RoundEnd.luau`.
3. Pictures to Alan (sheet, drop-down, slip) after the design-theory checklist and one independent visual review; fix its must-fix items once, then show. Then Alan's own Play look.
- **HOLDS (Alan's explicit go, each):** any Studio Play (tests included), place saves, publish (he does it), desktop control or screen grabs, bot matches, any new mechanic or number not in the decision, every upload.
- **Stop rule:** one reviewer pass per preview; then show Alan.

## DECISIONS & WHY (this session; all in the decision page in his words)
- Numbers OK'd as estimates (Alan: "these are good assessments", no measuring): averages table + count rules in the decision page; counts in `config/missions.json` to retune from real play.
- Blue Ribbon only from the fixed "15 dailies" card ("you can get legendarys from the blue ribbon chest"); the 4–5 day card pays Sticker chest + 2,000 Paper (swaps 1,250/2,500/3,750).
- Weeklies share the daily pool with harder numbers, no easy weekly; one-match feats become "N matches where…" (3/5/7) at the easy threshold.
- Swaps stop after the listed prices (daily: free, 150, 300, 450; weekly: 3). Finished-unclaimed missions pay automatically at reset. Lost gear never takes a finished mission. (My calls, told to Alan.)
- "Paper earned" counts the match's Paper **with** captured 2x boosts (Codex wired it; matches the decision page). I had told Alan "before boosts" mid-session: tell him it ended up boosts-included, as first proposed.
- Desk quick look (Alan): strip under "Switch to presets", compact semi-transparent drop-down, Daily/Weekly switch, view only, never mid-flight. Missions count at match end (no mid-flight note).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (Codex = GPT-6.2 Sol, never pass --model; one writer per file); design-theory skill before any screen; familiar-roblox-layouts; no-cardboard-tab-buttons; text-fits-its-box; explain-plans-in-text.

## CARRY NOTES / GOTCHAS
- Rojo live-syncs edits into Alan's open Studio: never leave a `require` of a module that doesn't exist yet (MenuController loads Missions lazily for that reason).
- Repo files are CRLF in the working copy (autocrlf): edit by normalising `\r\n`, or use the Edit tool; `sed -i` in Git Bash turns a file to LF (harmless, git normalises).
- Goal text on the sheet/drop-down can be long ("In 5 matches, fold 9 planes in one match flying the Toilet Roll Gunship"): check fit on screenshots; grow the card, never shrink words.
- Codex's edge cases: a claim refused just after reset still pays the expired period's earned rewards; an offline match reward without boost capture counts base Paper.
- Main-menu Missions strip sits at 1300,560 next to Shop, overlapping the stats card/photo edges slightly: check on the screenshot.
- `docs/systems/economy-and-shop.md` now says the weekly 3-match Sticker mission is gone.

## WHAT SHIPPED / OTHER QUEUED
- `7959f31d` Missions numbers: average-player counts, weeklies share the daily pool, Blue Ribbon only from the 15-dailies card; Codex is 6.2 Sol
- `4d49fb20` Matches now count what missions need: speed boosts, folds in the zone, and what each piece of gear did
- `4419c158` Lesson: a Codex 'model not supported' error meant an old Codex program
- `875d3ccc` Mission maker: daily and weekly missions from shapes, progress, claims, swaps (Codex, tests not yet run); Missions sheet first draft
- `4745a38c` Missions saved in the player's save with Claim, Swap and rollover pay; old weekly chest counter retired; desk Missions drop-down; Dev: finish missions
- This handoff's commit. Queued: the beta queue in `state/STATE.md`.

## KNOWLEDGE UPDATED
- `docs/decisions/2026-11-18-daily-and-weekly-missions.md`: numbers table, count rules, weekly pool, 4–5 day reward, desk drop-down, tick slip.
- `docs/systems/menus-and-hud.md` Code table: MissionsScreen, MissionsDropdown. `docs/systems/economy-and-shop.md` and `docs/systems/saving.md` (Codex): missions code, save field and ops, retired chest counter.
- `docs/workshop/lessons.md`: the Codex CLI version lesson. `AGENTS.md`: Codex GPT-6.2 Sol. `state/STATE.md`: missions line. Checker OK (205 pages).

## POINTERS
- Rules: `src/shared/Missions.luau`, `config/missions.json`, `tests/unit/Missions.spec.luau`.
- Server: `src/server/ProfileService.luau` (mission ops), `src/server/HangarService.luau` (missionClaim/missionSwap/devFinishMissions), `src/server/RoundRuntime.luau` (`missionSummary`, `gearCount`, profile view), `src/server/MatchService.luau` (`zoneFolds`).
- Client: `src/client/MissionsScreen.luau` (sheet + `describe`), `src/client/MissionsDropdown.luau`, `src/client/DeskHangar.luau` (strip at 226,556), `src/client/MenuBoard.luau` (strip at 1300,560), `src/client/DevTools.luau` (Dev: finish missions).
