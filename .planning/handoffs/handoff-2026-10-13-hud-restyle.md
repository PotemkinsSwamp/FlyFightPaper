# HANDOFF — 2026-10-13 — Stage 6 HUD built; Alan wants an on-brand restyle before approving

★ START HERE: Goal: make the in-flight HUD unique and on brand (paper/crayon classroom look), with bigger text,
covering everything: bars, weapon strips, the targeting/lock-on warnings, top notes, round strip, kill feed, edge
arrows. Opening action: show Alan a concept of the restyled HUD (a Codex picture is the cheap way) and get his OK
before building. Done when Alan approves Stage 6; then Stage 9 (game modes) starts.

> Read on demand: AGENTS.md → THIS → state/STATE.md → docs/MILESTONES.md (Stage 6, D12, "Tutorial (built last)").
> Memories: in-game-menus-match-main-menus, codex-for-pictures-and-blender, look-at-textures-before-upload,
> studio-play-is-shared, no-surprise-desktop-control.

## STATE (verify before acting)
- HEAD `1508f1cf` (main), NOT pushed (local only, as before). Confirm: `git rev-parse --short HEAD`.
- Tests 261/0 in Play (Server): `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- Studio: WORKING open in Edit, Rojo serve syncing (`curl -s http://localhost:34872/api/rojo`). Place NOT re-saved
  (Alan's Ctrl+S). Alan resized Studio's game view to 1279x719 for the last check: he may want it back.
- Cost this session: 0 subagents, 0 Codex, 0 Meshy, 0 uploads, 0 desktop control. Primary ~41% context.

## NEXT ACTION + PLAN
1. HUD restyle concept → Alan's OK. His words: "make it look more unique and on brand for the game, the targeting
   lock on the text everything, the text is a little small right now and its not very on brand."
   Current HUD code: src/client/FlightHUD.luau (crayon-cell bars/pips added this session; the lock warning, status
   note, round strip, kill feed are still plain text on tape labels with the Kalam font). Menu art pieces to reuse:
   src/shared/UIAssets.luau. New art = Codex pictures → contact sheet check → upload only with Alan's go.
2. Build the approved look; check in Play at 1918x1080 and 1279x719 (DevScreen hook opens menus; DevAutopilot flies).
3. Alan approves Stage 6 → Stage 9 modes (Airspace Control incl. capture bar, TDM visuals, bots per mode).
- HOLDS (Alan's go, each): uploads to his Roblox account (new HUD art), private publish, Studio-settings changes,
  Meshy spend, anything paid, desktop control (only if necessary or asked), closing Studio. Don't steer his plane
  while he is in Play (check get_studio_state first).

## DECISIONS & WHY (this session)
- HUD bars = crayon cells like the hangar (Alan's pick). Heat cells count DOWN (full = cool) so every bar reads
  "full is good". Flight notes fade after 4 s; the long controls sentence and the help bar are gone.
- Edge arrows: up to 4, nearest enemies within 800 studs NOT hidden by the city (no wall radar); the plane locking
  on to you is always red.
- Bots get eraser warnings like players, scaled by skill (Alan: veterans must not be impossible to hit): one roll
  per lock/eraser (config bots.*.eraser_notice/eraser_break/eraser_break_late_seconds); escape is the plane's own
  speed/turn. Eraser break beats fan/repair trips.
- Tutorial moved to the END (D12): its own empty copy of the classroom, targets, an enemy on cue, teaching HUD,
  arrows, hangar, weapons, plane building. Today's practice flight stays as a starting point (Tutorial button only;
  no first-join auto-start). Practice is never rewarded (economy rule).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (plain English, look at the game, model router, STATE ≤60 lines, hard limits); CLAUDE.md.

## CARRY NOTES / GOTCHAS
- Faking CombatInput from MCP: seq must be > the life's last seq AND ≤ last+2000; a fresh plane resets to ~0, so
  use a small per-life counter (e.g. 500+n), not 9000.
- MCP `require` of a client module gets a separate copy; drive running scripts through DevTools attributes
  (DevPractice, DevScreen, DevAutopilot, DevAim, DevCamera).
- BillboardGuis don't draw inside a ScreenGui: parent them to PlayerGui.
- Lesson: the practice target passed with a scripted pilot that aimed at it, but Alan never saw it. Anything a
  player must find needs a pointer when off-screen; check it from a player's view, not with scripted aim.
- Rookie-tier lock-dodge count included real gunfire dodges; sample sizes were small (≤23).

## WHAT SHIPPED / OTHER QUEUED
- Shipped: dd6d51a9 HUD crayon bars/pips/heat, fading notes, FFA place · 0ffc07f2 STATE · bfd3a9d3 bots dodge erasers +
  HUD margins · e0f67084 eraser dodging by skill · aaef26d2 edge arrows · 33f7e69a practice flight · 9e31808c
  tutorial moves to the end · ef291012 DevScreen hook · 3ca19270 STATE size checks · 1508f1cf STATE restyle request.
- Queued: Track C saving (needs private publish); bot-vs-bot rams never land; last stand-in sounds; full tutorial
  (last, D12).

## POINTERS
- src/client/FlightHUD.luau, src/client/PaperUI.luau, src/shared/UIAssets.luau, assets/ui/*/ready/,
  assets/references/ui-concepts/, src/client/Tutorial.luau, src/server/BotService.luau (eraser reactions).
