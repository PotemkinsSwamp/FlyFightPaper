# HANDOFF — 2026-11-06 — Presets are in Studio; Alan's 8 playtest notes come next, then the new weapons

**Labels:** kind=product · lane=beta-lane · branch=main · issues=none · areas=src/client/DeskHangar.luau, src/client/Hangar.luau, src/client/BuildShelf.luau, src/server/HangarService.luau, src/server/FlightService.luau, config/catalog.json, docs/plan/CLASSES-PLAN.md
**Time:** 2026-11-06 20:24 -05:00

★ START HERE: Goal (Alan): the beta feels like a finished game, one map, with a strong first-session hook. First fix his 8 notes in docs/playtests/2026-11-06-presets-at-the-desk.md, starting with the desk menu reloading on a plane change. Done when he plays them in Studio and says they're right; then the four new weapons.

> Read on demand: AGENTS.md → state/STATE.md → this file; then only the docs the step touches. Memories: beta-feels-finished, alan-does-play-checks, studio-play-grabs-mouse, plan-before-building-features, creator-store-first, look-at-textures-before-upload, assembled-preview-before-upload.

## STATE (verify before acting — state drifts between sessions)
- HEAD is this handoff's commit (main), pushed; the last code commit is `fdb6510f`. Confirm: `git rev-parse --short HEAD`, `git status -sb`.
- Tests 455 passed, 0 failed at `fdb6510f`. Re-run in Play: Server `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`. Docs: `python tools/check_docs.py`.
- The published game is behind: PC keys, Range fixes, presets, free swap and the desk flip are NOT published. Alan publishes (File > Publish As > tile > start place > Overwrite).
- Rojo `serve.project.json` on port 34872 was started by this session and may not survive it. Check: `netstat -ano | grep 34872`. Alan clicks Connect in the plugin.
- The Studio id changes between sessions; use list_roblox_studios. Studio's phone view (Device Simulator) was off at the end: viewport 2046 x 801.
- Cost: subagent count and tokens from early in the session were lost in a context summary, so unknown; no agents in the last stretch. Primary stopped at about 40% of context by the hook. Wall clock not recorded.

## NEXT ACTION + PLAN
1. Alan's 8 notes (the page has his words). Check: he plays them in Studio.
   - Desk menu must not reload on a plane change. Lead, unproven: `swapAtDesk` destroys and rebuilds the plane, so the HUD may see it vanish and redo the desk menu. "Sometimes" fits a swap happening only before first flight.
   - Paperclips: much more velocity and range, same damage; hold to keep firing through reloads.
   - Guns crossing in an X: an older note says they cross at 150 studs. Make paperclips, at least, truly precise.
   - Bomber 1 Paperclip + 2 Pellets; Scout 2 Rubber Bands (`classes` in config/catalog.json; update the classes plan's table).
   - Plane collisions: find out why two planes no longer hurt each other. Rule: from each plane's health, the stronger survives, plus something extra.
   - Staples and the aim ring: check whether it uses shot speed, drag and drop for the time to reach the target.
   - Speed pickups add about 0.5 s of Boost each.
2. One 8-minute bot match for real XP per match, which sets preset levels and mastery pace. HOLD: Alan's go.
3. Phone check of the desk switch, flip and six small photos. HOLD: he turns the Device Simulator on.
4. Four new weapons (classes plan step 3; show Alan assembled models before any upload), then unlock ladder, mastery, bots following the lobby, balance pass. Then their own plans: winners' circle + emotes + winner music, skins, shop.

Holds (Alan's words): publish (he does it), Save to File, any upload, desktop control, Studio Play while he's playing, anything paid. Keep it cheap and tell him the cost.

## DECISIONS & WHY (this session)
- The beta is a finished product with one map; the hook matters more than larger playtests. Real people already tested it and it plays fine: docs/decisions/2026-11-06-beta-feels-finished.md.
- Six presets, four weapons, mastery, bots by lobby average weighted low: docs/decisions/2026-11-06-classes-and-mastery.md. No mini eraser; no eraser or pencil on a preset.
- Words: players see **presets** (fixed) and **loadouts** (their own). Code keeps `class` = preset and `preset` = saved loadout, so the save's fields never change.
- The desk flip squashes the cork picture's width and back, not 3D: it reads as a flip and needs no new parts. The Hangar went back to two tabs at Alan's word; he only wanted the switch and flip at the desk.
- Free swap only before first flight this life. Hangar safety carries across a swap on purpose (VISION: desk changes don't refill it).
- Mastery: rank 1 +5%, then small steps to +10%; ranks 6-10 open one per prestige (rank 10 at prestige 5 is Claude's pick, Alan can change it). 2x XP never speeds it.
- Weapons stay at the ladder's levels: Alan first doubted Stubby Crayon at 6, then said it's fine.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md hard limits and model router; the memories above. Plan features for Alan's OK before building. Play checks: he does them when he's here, only tests and menus are ours, and never while he's playing.

## CARRY NOTES / GOTCHAS
- Not seen: the desk flip in motion, the restored Hangar tabs in Play, anything at phone size, landed-without-dying and respawn swaps in Play, saving in Customize before first flight.
- A picked plane isn't saved: rejoining goes back to Loadout 1. Fix before the beta.
- One run showed all 3D menu pictures blank after opening the Hangar soon after loading; the next run was fine. Unknown cause, watch for it.
- One Play run stopped by itself partway; possibly Alan.
- Bots today: 85% rookie / 15% regular in rookie rooms, 85% regular / 15% veteran in regular rooms, by graduation after 5 matches, not lobby level.
- The flip is silent: Alan picks any sound (memory audio-picks-links-and-studio).
- `user_mouse_input` with `instance_path` clicks the middle of a piece, and the Welcome card can sit on top of it on a first join.
- The Paper Pal feed fix covers leaving only; folding the Pal still shows a line, as before.

## WHAT SHIPPED / OTHER QUEUED
Shipped (all on main, `0926ba6e..fdb6510f`, plus this handoff):
- fdb6510f A plane that hasn't flown swaps free at the desk; afterwards the note says Fresh plane or Full refold
- 935a99c8 Desk menu: Switch to presets flips the cork strip to the six presets; the Hangar keeps its two tabs
- 8f5e6638 Presets and loadouts: Switch to presets flips the pin board over; your own builds are now called loadouts
- 316c9d05 Class planes: six fixed planes on their own Classes shelf, each open from its level
- 56ba6867 Classes plan: Alan's answers on mastery, prestige and bots
- fbcea135 Classes plan: Carrier numbers with all four guns
- e1ec2676 Plan: six class planes, four new weapons and mastery, for Alan's OK
- d3f026b9 Decision: the beta has to feel like a finished game
- 601ff20c Range note 7 stays above Keep flying; a lesson's Pal leaves without a kill feed line
- a52fad0c Range notes all show on a phone: 3, 4 and 7 find their buttons, and they wait for the Hangar Tour's end card
- 3f7b2cfa Keys note: no dimmed band behind it, words clear of the tape
- 12dbff2e PC: change your Boost, Brake and Got it keys (Settings > Controls); notes and lessons name your key
- 18e52a70 Phone buttons confirmed on Alan's phone: playtest note and status
- e65e065a Phone buttons: a tight saved layout stays put; only buttons truly on top of each other go home
- 7d6a6673 Phone buttons: a button dropped tight against another stays put; a refused settings save now says so
- b3657b1c Phone button editor: Settings hides properly, Move tab clear of the crosshair card, red disc and dragged button on top
- 3e363c24 Phones: move your buttons (Settings > Phone buttons > Move); layouts save to your account
- 2586f139 Plan: move your phone buttons, then change your PC keys (for Alan's OK)
- 6364d4fd Phones: BRAKE sits right by FIRE, between 2 and BOOST
- c400ea49 Phones: BRAKE button always there; braking while speed matching doesn't stack
- b7485a3e Phones: FLAPS brake button when Speed match is off; no auto-fire in lessons; eraser Pal starts far away
- 411b7490 Brake on Space, phone speed matching, tutorial words for young players, Pals fly a square
- b7bfbe6c Research: how other games keep you on a plane's tail on phones; options for Alan

Queued: everything in the plan above. The tutorial rewrite was built earlier and still needs a real-phone run by a kid.

## KNOWLEDGE UPDATED
- docs/plan/CLASSES-PLAN.md (new), docs/decisions (2 new), docs/systems: planes-and-hangar, desks-and-service, tutorial, flight; docs/playtests (2 new); docs/workshop/lessons.md (test count after a fresh sync); state/STATE.md rewritten (58 lines). Checker: OK.
- No .knowledge/ in this project.

## POINTERS
- docs/plan/CLASSES-PLAN.md · docs/playtests/2026-11-06-presets-at-the-desk.md · docs/plan/CONTROLS-PLAN.md · docs/decisions/2026-10-18-shop-plan.md · src/client/DeskHangar.luau · src/server/FlightService.luau · src/shared/Catalog.luau

## AAR
Supposed to finish the mobile lane; it did, then Alan moved the goal to a finished beta. Two misses cost time: I called real-player testing the biggest gap without asking him, and I built the flip in the Hangar when he meant the desk. For a screen word that could mean two places, name the screen in the plan line before building.
