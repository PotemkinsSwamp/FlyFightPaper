# HANDOFF — 2026-11-07 — Alan's 8 notes, the paperclip rework, its glint and Tab standings are in Studio; bot match next

**Labels:** kind=product · lane=beta-lane · branch=main · issues=none · areas=src/client/ClipGlint.luau, src/client/RoundEnd.luau, src/client/CombatController.luau, src/client/CombatEffects.luau, src/client/DeskHangar.luau, src/server/CombatService.luau, src/server/FlightService.luau, src/shared/CombatRules.luau, config/catalog.json, config/gameplay.json
**Time:** 2026-11-07 01:09 -05:00

★ START HERE: Goal (Alan): the beta feels like a finished game, one map, with a strong first-session hook. First ask Alan in one line whether his "looks good" covered the paperclip, Tab, the desk column and notes 1, 6 and 8; then, with his go, run one 8-minute bot match. Done when real XP per match and how often planes ram are known; then the phone check and the four new weapons.

> Read on demand: AGENTS.md → state/STATE.md → this file; then only the docs the step touches. Memories: beta-feels-finished, alan-does-play-checks, studio-play-grabs-mouse, plan-before-building-features, creator-store-first, look-at-textures-before-upload, assembled-preview-before-upload.

## STATE (verify before acting — state drifts between sessions)
- HEAD is this handoff's commit (main), pushed; the last code commit is `2979e3b1`. Confirm: `git rev-parse --short HEAD`, `git status -sb`.
- Tests: 458 passed, 0 failed in Alan's Play at `94cdd1b5`. After that only the Edit-mode copy ran (408 passed; 2 fail for want of plane models; 3 suites need a server), so the last 7 commits had no full run. Re-run in Play: Server `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`. Docs: `python tools/check_docs.py`.
- Published game: behind, none of this session or last is published. Alan publishes.
- The place file wasn't saved this session (Save to File needs his go); code reaches Studio through Rojo.
- Rojo `serve.project.json` on 34872 was up and connected at handoff and may not survive it. Check: `netstat -ano | grep 34872`. Alan clicks Connect.
- Studio's id changes between sessions; use list_roblox_studios.
- Cost: no subagents, no Codex, no Meshy, no uploads, no Robux. Wall clock about 5 hours by the handoff times. Primary hit the 40% context hook (about 400k tokens).

## NEXT ACTION + PLAN
1. Ask Alan what "looks good" covered. Unconfirmed: paperclip damage and taking turns, Tab's Folds/Assists/Crashes updating live, the white flash, the desk column, desk reload (1), ramming (6), pickup Boost (8). Check: his word in play.
2. One 8-minute bot match for real XP per match, which sets preset levels and mastery pace. HOLD: Alan's go. Also read crash deaths: the ram fix may make bots fold each other far more, and rammer bots aim for it. If rams swamp weapon kills, tune before going on.
3. Phone check of the desk switch, flip, six small photos, Tab pages and the score strip tap (small text possible). HOLD: he turns the Device Simulator on.
4. Four new weapons (classes plan step 3; show Alan assembled models before any upload), then unlock ladder, mastery, bots following the lobby, balance pass. Then their own plans: winners' circle + emotes + winner music, skins, shop.

Holds (Alan's words): publish (he does it), Save to File, any upload, desktop control, Studio Play while he's playing, anything paid. Keep it cheap and tell him the cost.

## DECISIONS & WHY (this session)
- All in docs/decisions/2026-11-06-paperclip-rewards-distance.md: paperclip keeps speed and accuracy, takes turns, 1.75 s reload, damage 12 at 150 studs to 24 at 500, 36 at 1000, 60 at 2400; Tab is press-to-open; the glint.
- Shots rewind 0.18 s, not 0.1: measured in his Play, five bots drawn 0.18 s behind the server, to within a third of a stud. `eraser_server_late_seconds` keeps the old 0.1 on purpose: that's how late the server sees a human, a different thing.
- Rams: stronger plane loses the weaker's health plus 15 and always keeps 1; teammates and practice flights never ram; still no kill credit. The ram check now goes by distance, because Root is a thin 8 x 1.2 x 10 slab.
- The lead ring reaches 1000 studs, or the shot's full reach for a gun with `damage_by_range`; pencils stay at 1000.
- Bots' guns stay meeting at 150 studs on purpose: changing it would shift bot balance.
- The red glint's 0.528 is Alan's pick in the air; nearly everything fainter vanished over the bright town. No sound, no arrow, no picture file (drawn from frames).
- Tab list shows all 12 pilots: Claude's pick; he didn't answer that one.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md hard limits and model router; the memories above. Plan features for Alan's OK before building. Before judging accuracy from hits, record whether the shot was on the ring (lessons.md).

## CARRY NOTES / GOTCHAS
- Not seen in Play by Claude: Tab, the desk column, the clip hunters button. Alan said only "ok looks good" after the button moved.
- Clip hunters may charge in too close to glint (needs over 300 studs, 0.3 s aimed). If so, make them hang back.
- `DevGlint` and `DevGlintPeak` on ReplicatedStorage.FlyFightPaper, set from the Client VM, make every enemy glint and tune the red glint live. They end with Play.
- `DevShotLog` now says the weapon and RING or free. It holds 40 shots; one Striker burst is 6.
- From last session, still open: a picked plane isn't saved on rejoining; one run showed all 3D menu pictures blank; bots are by graduation, not lobby level; the flip is silent; Paper Pal fold line.
- Hangar card says "Hits harder the further away" in place of the paperclip's damage per second. Bots use paperclips under the same rules.

## WHAT SHIPPED / OTHER QUEUED
Shipped (all on main, plus this handoff):
- 2979e3b1 Clip hunters button sits right beside eraser hunter
- 53ee6b0b Desk dev button: clip hunters, three paperclip bots hunt you to test the glint
- aecf881d Decision note: the red glint's strength Alan picked in the air
- 5d55b1b3 Paperclip's red glint set to Alan's 4x
- 2d8763a2 Paperclip's red glint much stronger, and Studio can tune it during Play
- 2150b645 Paperclip's red glint 20% stronger
- 575c7715 Paperclip's red glint a little stronger: the middle of the last two tries
- debea5be Paperclip's red glint is fainter and fades out at the sides
- c2f97fcf A paperclip aimed at you glints: a bright flash in view, a faint red glint along the bottom when behind you
- bf7c1084 Paperclip damage keeps climbing to its full reach, and its aim ring reaches that far
- 94cdd1b5 Tab shows the live standings over the game; on a phone, tap the score strip
- 88592f8b Paperclips take turns, reload in 1.75 s, and hit harder the further the shot flew
- 63f18522 Desk menu: no Refill Lift strip, landing already fills Lift and Boost
- 224f6a38 Shots allow for the 0.18 s Alan's screen really draws bots behind, so on-ring shots land
- 5256237d Playtest note: what the staple shot log really shows
- c94fd7f2 Studio shot log marks which shots left on the lead ring, and names the weapon
- 7ccd82a8 Alan's 8 notes: desk stays up on a swap, planes really ram, faster held paperclips, bursts stay on aim, pickups add Boost

Queued: everything in the plan above.

## KNOWLEDGE UPDATED
- docs/systems: weapons (timing, paperclip, glint), damage-and-deaths (rams), flight (pickups), desks-and-service, menus-and-hud (Tab, ClipGlint), tutorial (shot log). docs/decisions: new note + README. docs/playtests/2026-11-06-presets-at-the-desk.md. docs/workshop/lessons.md: 3 new. docs/plan/CLASSES-PLAN.md table. state/STATE.md rewritten. Checker: OK.
- No .knowledge/ in this project.

## POINTERS
- docs/decisions/2026-11-06-paperclip-rewards-distance.md · docs/playtests/2026-11-06-presets-at-the-desk.md · docs/plan/CLASSES-PLAN.md · src/client/ClipGlint.luau · src/client/RoundEnd.luau (`fillLive`) · src/shared/CombatRules.luau (`shotDamage`, `alternateMount`, `aimedAt`, `ramLoss`)

## AAR
Supposed to fix 8 notes; did, then took on Alan's paperclip, Tab and glint asks. Two misses. I read a hit count as proof the circle was off when it couldn't separate his aim; he caught it, and the RING mark and the delay measurement then found the real 0.18 s cause, which beat more log reading. I also said the button was "right beside" eraser hunter when it was two rows up: name a screen spot only after checking the layout numbers. Cost matched output: the glint strength took six rounds because previews were on a dark road; go to real Play sooner for anything faint.
