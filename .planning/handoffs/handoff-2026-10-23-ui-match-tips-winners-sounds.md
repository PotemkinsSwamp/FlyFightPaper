# HANDOFF — 2026-10-23 — Range notes approved, Match Tips work, three match bugs fixed; winners' moment sounds picked, cue sheet next

**Labels:** kind=ui · lane=ui · branch=main · issues= · areas=src/client/RangeNotes.luau, src/client/MatchTips.luau, src/client/FlightHUD.luau, src/client/RoundEnd.luau, src/client/Audio.luau, src/client/FlightController.luau, src/client/SettingsScreen.luau, src/shared/Aircraft.luau, src/shared/ProfileSchema.luau, src/server/FlightService.luau, src/server/RoundRuntime.luau, docs
**Time:** 2026-10-23 19:16 -04:00

★ START HERE: Goal: the winners' moment sounds the way Alan wants them ("tasteful", timed to the 27 s moment).
Opening action: find a LONGER fun winners' music track (licensed APM, ~15-25 s; Cartoon Time is only 5 s), then write a
cue sheet (what starts and fades when) for Alan's OK, then build it. Done when Alan hears it in Play and says it works.

> Read on demand: AGENTS.md → THIS → `docs/plan/MILESTONES.md` Stage 7 "To do" (the picks + the timeline) →
> `src/client/WinnersCutscene.luau` (timings at the top) and `src/client/Audio.luau` (music, ambience).
> Memories: audio-picks-links-and-studio, alan-does-play-checks, plan-before-building-features, studio-play-is-shared.

## STATE (verify before acting)
- HEAD `fc958345` + this handoff's commit on main; the commit hook copies to GitHub and pushes. `git log --oneline -3`.
- Unit suite 418 passed, 0 failed (last run in Play this session): server VM,
  `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`. Docs checker OK (125 pages): `python tools/check_docs.py`.
- Studio: Edit, studio id changed mid-session (call `list_roblox_studios`). Rojo serving on 34872. Place not re-saved.
  SoundService has a Claude-made `WinnerSoundPicks` folder (19 numbered Sounds, not saved): handy for "play N", delete when done.
- Cost: 0 subagents, 0 Codex jobs, 0 uploads, $0. ~10 Claude Play runs (bots match, Alan's OK) for numbers and screenshots.
  Primary context ~42% at handoff.

## NEXT ACTION + PLAN
1. Longer winners' track (APM, kid-friendly, fun; game-show feel), checked it loads; give Alan links + offer to play it in Studio.
2. Cue sheet for his OK, from the timeline in MILESTONES (0-1.2 s banner, glide to 3.2 s, hops ~5/6.5/8.5 s, dance to
   17 s, results card 17-27 s): match music fades at the banner; crowd cheers 9120973900 + kids "Yeah!" 1841221347 low as
   they jump on the desks; clapping 9113138035; the winners' track under the dancing; all out before the vote lap.
   Confirm the real timings in Play first (the 27 s is read from code).
3. Build (client, Audio.luau / WinnersCutscene's stage changes), Alan checks in Play.
HOLDS (Alan's go, each): publish, Meshy, anything paid, desktop control, closing Studio, Save to File, real product
IDs/prices, turning sales on, Studio Play runs while he's playing. Uploads allowed after an assembled preview he OKs.

## DECISIONS & WHY (this session)
- Range notes = the tutorial's own note (top middle, Space/K); a Back note shows over the Hangar only if note 4 opened it;
  the last note ("The Range is yours ... Menu, then Leave") saves on show and ignores its own save echo.
- Match Tips: 9 tips (tipVote retired but kept in `Schema.TIPS` so saves holding it stay valid); only in ACTIVE rounds;
  saved as lesson ticks from any room (`RoundRuntime` lessonDone allows `Schema.TIPS`); `settings.matchTips` optional
  (missing = on), so no schema migration.
- Repaint bug: Aircraft.paint welds team stickers → Roblox resets network ownership → `SetNetworkOwner(pilot)` again
  (lessons.md). Break walls: `FlightService:setSafe` + Root `WallsSafe` for the client; walls soft 2 s into a round.
- Winners' moment: Alan wants cheering + clapping + a longer winners' track, and
  later emote music for winners who own one (MILESTONES Stage 7).
- Range build swap dropped (Alan: "not that important").

## CONSTRAINTS / PRINCIPLES
- AGENTS.md; memories above; `docs/workshop/lessons.md` (+1: adding a part to a flying plane takes it off its pilot).

## CARRY NOTES / GOTCHAS
- First Play run's faked fold tip didn't show, never explained (worked in the next Play); team/Airspace/scrape tips unseen live.
- Studio's DevMode beats the vote: the countdown now names DevMode's mode (Studio only).
- Creator Store audio previews don't play for Alan; user uploads load in-game but have unknown owners: offer licensed only.
- Old carries: match bots' guns converge at 150 (Alan's call), cutscene hitch, Track C private publish, fan sound.

## WHAT SHIPPED / OTHER QUEUED
- 041f187d Range notes look like the tutorial's (Space: next, K: skip all), first one points at a plate that's up; no match clock in the Range
- 2c6999e4 Range notes: arrows sit beside what they point at, a Back note over the Hangar, then the Menu note and a closing note
- e61595e0 Classroom children heard only while flying in a match; the Range's last note is 'The Range is yours', pointing at Menu for leaving
- af092c74 Range notes: the last note stays up when its own save comes back
- f1352498 Alan approves the Range sticky notes
- f7ef8f0d Match Tips: one-line sticky notes the first time things happen in a real match, each once; Settings > Match tips On/Off
- bf0b85aa Plan: winners' moment gets its own tune, match music fades out (Alan's note)
- 5a81e533 Planes stay yours when a team round repaints them mid-flight (you lost control and flew into a wall)
- 3b89db2d Round break: walls only bounce (no fake crash on your screen), and stay soft for the new round's first 2 seconds
- 2f40287d Range build swap animation dropped for now (Alan)
- 3e20e1f9 Vote lap: the top strip shows the vote clock, the vote cards sit under it, and no match tips in the break
- e7fbf611 Plan: winners' moment plays kids cheering (emote music later, for winners who own one)
- fc958345 Plan: winners' moment sounds Alan picked and the moment's 27-second timeline
- + this handoff (STATE rewrite).
- Queued (Alan's): Save to File, Stage 10 prices/products, Stage 11 private publish, drawing pass, emotes with music.

## KNOWLEDGE UPDATED
- systems/tutorial (Range notes approved, Match Tips status, Code row MatchTips); plan/TUTORIAL-PLAN (Range notes
  rounds, Match Tips details); systems/saving (TIPS, matchTips); systems/sound-and-effects (children only in flight);
  systems/modes-and-scoring (break walls, repaint, vote strip); decisions/2026-10-19-range-controls (swap dropped);
  plan/MILESTONES Stage 7 (winners' sounds + timeline); workshop/lessons +1; STATE rewritten. Checker: OK (125 pages).

## AAR
Supposed: retest notes → Match Tips plan → build → swap. Actual: notes took 3 rounds (layout, then the self-save hiding
the last note: a client gate never exercised), Match Tips went smoothly, and Alan's playtest found two real match bugs
(repaint ownership, break walls) that a bots match then reproduced in minutes. Why the notes slipped: the last note's
save echo wasn't traced before handing over. Next: before handing over UI that saves, trace what the save's reply does
to the screen. Cost matched output. Audio hunt cost 3 rounds: links missing, then unlicensed picks; memory added.

## POINTERS
- Winners' moment: `src/client/WinnersCutscene.luau` (BANNER/GLIDE/TURN/ZOOM/CARD at the top), `config/gameplay.json`
  rounds.results_seconds 27, `src/client/Audio.luau`. Tips: `src/client/MatchTips.luau`. Notes: `src/client/RangeNotes.luau`.
