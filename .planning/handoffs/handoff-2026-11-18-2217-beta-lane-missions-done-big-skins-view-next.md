# HANDOFF — 2026-11-18 — Missions done (live progress, Alan's OK); a 0-second-frame bot bug fixed; next: big skins block the view

**Labels:** kind=product+ui · lane=beta-lane · branch=main · issues=none · areas=src/shared/Missions.luau, src/server/RoundRuntime.luau, src/server/HangarService.luau, src/server/FlightService.luau, src/server/BotService.luau, src/client/MissionsScreen.luau, src/client/MissionsDropdown.luau, tests/unit, docs
**Time:** 2026-11-18 22:17 -05:00

★ START HERE: Goal: a plane wearing a big skin (Hot Rod's spoiler on the biggest parts: Cardstock wings + Cardboard body) must not fill the player's screen. Opening action: measure how much of the 1280x720 view each Legendary/Mythical skin covers on the biggest and smallest builds, then write Alan a short how-it-works note with options and numbers (e.g. the chase camera pulls back per skin so the plane covers the same share of the screen as its plain build, or the skin draws smaller/see-through from your own seat), including what each does to aiming (lead ring, crosshair) and range feel. Done when Alan picks one; build only after his OK.

> Read on demand: AGENTS.md → THIS → `docs/decisions/2026-11-13-skin-rules.md` (hitbox rule) → `src/client/ChaseCamera.luau`. Memories: plan-before-building-features, alan-does-play-checks, explain-plans-in-text, studio-not-drawing, mute-studio-tests.

## STATE (verify before acting)
- HEAD `0a618a50` + this handoff's commit (main); the commit hook copies to GitHub ("github: pushed"). Confirm: `git rev-parse --short HEAD`.
- Tests: 748/748 (2026-11-18, after the bot fix). Re-run (Alan's go for Play): `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()` on the Server.
- Studio: Play stopped, DevMute cleared, keep-awake nudge ended. Rojo serve running and synced. No place save, no upload, no publish.
- Docs checker OK (206 pages).
- Cost: no subagents, no Codex; ~2 h wall clock (most on the bot bug); main context ~45% at handoff.

## NEXT ACTION + PLAN
1. **Big skins block the view** (Alan 2026-11-18, screenshot: Hot Rod + biggest parts covers most of the screen). He asked whether to move the camera back "so that your perspective is keeping the same shape" and how that changes targeting and distance. Options note with numbers first (plan-before-building-features), his pick, then build and his Play look.
2. **His hitbox worry is already answered** (tell him again only if asked): Legendary/Mythical skins are look-only, the parts underneath stay the hitbox; only the Dragon and Shark Jet are their own hitbox, sized to the plane's own target size. So the spoiler costs nothing in a fight.
3. Then the beta queue in `state/STATE.md`.
- **HOLDS (Alan's explicit go, each):** any Studio Play (tests included), place saves, publish (he does it), desktop control or screen grabs, bot matches, every upload, any new mechanic or number.
- **Stop rule:** one options note → Alan picks → build. No review loops.

## DECISIONS & WHY (this session)
- Live missions ride the profile view the client already asks for every 3 s and when the desk list opens (no new messages): the list is only seen at the desk, where counts aren't moving. `RoundRuntime:liveMissions` + `Missions.applyMatch(state, summary, live)`.
- End-only in the live view: matches played, wins, top 3, "folded N or fewer". A one-match daily goal shows this match's count ("5 / 12"); weekly "In N matches" cards count matches only.
- Dev: finish missions pressed mid-match also sets "mission next match", so the star shows (the existing dev path).
- A match that doesn't count for the player (under 2 min active or hits on fewer than 3 planes) drops its live progress at the end. Alan saw it live and called missions done; kept as built.
- **Bot bug fix:** Studio gives 0-second frames; the takeoff divided by dt, so every plane taking off got infinite speed and was deleted, and the stuck pilot broke FlightService's loop every frame (bots vanished, player stuck on the runway). FlightService and BotService steps now skip `dt<=0`.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md; skin rules decision (look-only skins); memories plan-before-building-features, explain-plans-in-text, alan-does-play-checks, design-theory skill before showing a screen.

## CARRY NOTES / GOTCHAS
- Scripted pickups: move the invisible `SpeedPickupN` box onto the plane on `Stepped` (moving the plane trips "came unfolded"). A bot-flown human plane rarely qualifies a match, so end-of-match saving can't be checked by script (lessons.md).
- Mission picks are seeded by account + day; swaps for this test account only reach a few mission kinds. To get a chosen mission in Studio, a temporary local seed offset in ProfileService (reverted, never committed) worked.
- `ProfileService` warns "Skipped mission progress: <cause>" once per server per cause: a second ineligible match prints nothing.
- Untracked `tools/art/hero.py.old`, `assets/ui/shop/raw|source`: not this session's; leave.
- Side session "Skin concepts and Blender pipeline" exported the concept-to-blender skill to `D:\skill-exports\concept-to-blender\` for Codex (its own report).

## WHAT SHIPPED / OTHER QUEUED
- `4ddd1cad` Missions show live progress during a match
- `6dff3cf9` Live missions skip rounds with no match engine; live view test (748/748)
- `58ae169c` Planes no longer vanish on a 0-second frame; live missions seen in Studio Play
- `0a618a50` Alan: missions are done; next is big skins blocking the view
- This handoff's commit. Queued: the beta queue in `state/STATE.md`.

## KNOWLEDGE UPDATED
- `docs/decisions/2026-11-18-daily-and-weekly-missions.md`: "Missions are done" (Alan's words).
- `docs/playtests/2026-11-18-missions-first-look.md`: fifth look (live progress).
- `docs/systems/menus-and-hud.md`: live progress, how it works, what was seen.
- `docs/systems/flight.md`: the 0-second-frame fix.
- `docs/workshop/lessons.md`: 0 s frames; scripted pickups; scripted planes don't qualify.
- `state/STATE.md` (60 lines). Checker OK.

## POINTERS
- `src/client/ChaseCamera.luau`, `src/client/LegendarySkinMotion.luau`, `src/generated/SkinShapes.luau`, `src/server/HitShapes.luau`, `docs/systems/planes-and-hangar.md`.
- Alan's screenshot of the problem is in this chat only (Hot Rod in a match, chase view: the plane and its spoiler fill the middle third of the screen).
- Pictures: `.planning/missions/live-desk-1.jpg`, `live-desk-2.jpg`, `live-star-dev-finish.jpg`.
