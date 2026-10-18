# HANDOFF — 2026-10-18 — Bots wear real players' saved outfits with modern names; next: rebuild the winners' shot like the big games

**Labels:** kind=ui · lane=ui · branch=main · issues= · areas=src/server/AvatarService.luau, src/shared/BotNames.luau, src/client/WinnersCutscene.luau, config/gameplay.json, tools/find_bot_looks.luau, tools/meshy_to_r15.py, tools/r15_keyframes.luau, tools/meshy.py, assets/animations/meshy

★ START HERE: Goal: a winners' moment that looks like Alan's reference clips (Black Ops 3 "Winners Circle", Street
Fighter characters in Apex Legends): the top 3 side by side on three neighbouring chalkboard-row desks, big in frame
(head to knees fill most of the screen), ALL emoting at once with Roblox's own emotes, one steady eye-level group
shot (slow push in at most), a name plate under each with place and score, confetti, about 10 s
([decision](../../docs/decisions/2026-10-18-winners-shot-redesign.md)). First action: find which Roblox-made emotes
load in our game (free test), then rebuild the shot in `src/client/WinnersCutscene.luau`. Done = Play screenshots
and an MP4 of the shot sent to Alan, and he says it reads like his clips.

> Read on demand: AGENTS.md → THIS → the decision above. Alan's clips are not in the repo (uploads to the
> 2026-10-18 session); the decision note says what they show. Memories: send-videos-not-gifs, studio-not-drawing,
> studio-play-is-shared, look-up-roblox-ui-steps.

## STATE (verify before acting)
- HEAD `0844ec6c` + this handoff's commit on main, auto-pushed by the post-commit hook. `git status -sb`.
- Tests 328/0 (2026-10-18, after the names change). Re-run in Play (server):
  `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- Studio open in Edit, Play stopped, Rojo serving. Place file not re-saved (code lives in src/). ServerStorage may
  carry leftover attributes `BotLookScan`/`BotLookIds` from search tools: harmless, delete if seen.
- Cost last session: 1 web-fetch subagent (~106k tokens), no Codex; Meshy 30 credits (1,043 → 1,013); ~10 web
  searches; no uploads. Primary context ~43% at handoff.

## NEXT ACTION + PLAN
1. **Roblox emotes test (free):** pick ~6 Roblox-made emotes (dances, cheers, flexes; look up current animation ids
   in Roblox docs / catalog, not memory), load each on a winner copy in Play, keep the ones that play smoothly on
   giant ScaleTo'd avatars (the hip fix in WinnersCutscene must still hold). Check: each plays, feet stay on desk.
2. **Rebuild the shot** per the decision: three neighbouring desks (config `rounds.winner_desks`), all three hop up
   and emote together, one steady group shot filling the frame, name plates (place + score), confetti; drop the
   one-at-a-time close-ups and long glides. Check: 1280x720 Play screenshots + MP4 to Alan (ffmpeg is installed).
3. Alan's Stage 9 playtest list (state/STATE.md "Waiting on Alan") once the shot is in.
HOLDS (Alan's go each): uploads, publish, Studio-settings changes, Meshy, anything paid, desktop control, closing
Studio. Don't steer his plane while he's in Play (check first; your own test Play is fine). If Studio stops
drawing (RenderStepped 0/s), ask Alan to click on Studio; don't move windows yourself.

## DECISIONS & WHY (this session)
- **Bots wear outfits real players saved** (Alan: copying looks is fine; VISION only forbids forged accounts, so
  names stay made-up). Saved-outfit ids, not user ids: random accounts are mostly starter outfits that look alike;
  157 found once by `tools/find_bot_looks.luau` (Roblox allows 300 lookups/min, too few for runtime search).
- **Names modernized** (Alan: old ones read like 2018): lowercase handles, stretched names, x-swaps, nonsense words,
  ALL-CAPS jokes. No real usernames (would look like that kid's account).
- **Plane emote parked for the shop stage:** arm-only IK version "looked bad, no life" (removed); Meshy full-body
  clips "better but odd". Pipeline kept: `tools/meshy.py motion`, `tools/meshy_to_r15.py`, `tools/r15_keyframes.luau`,
  plane-in-hand code in WinnersCutscene (inactive while `rounds.winner_plane_emote` is ""). Alan dislikes Adobe
  (Mixamo): never suggest it.
- Non-human avatars (mice, bears) are normal R15 bodies: emotes play on them; held props may poke through.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (docs rules, model router, holds). Memories named above. VISION: no forged accounts, no AI labels.

## CARRY NOTES / GOTCHAS
- A few items in some saved outfits fail with "Asset is not approved for the requester": that bot skips the item.
- Studio `screen_capture` times out when Studio is behind other windows; the cutscene (RenderStepped) also stops.
- Never name a scratch Python file after a stdlib module (`inspect.py` broke numpy imports).
- One ~55-65 ms hitch at cutscene start (winner clones) and the vote-lap round strip still showing the old round:
  both still open from earlier sessions.

## WHAT SHIPPED / OTHER QUEUED
- df53ea0a Bots now wear the look of random real Roblox players
- 08fa7a36 Bots wear outfits real players saved; 1st place flies their plane round their head
- db4d2fcf 33 real-player outfits for bots; State: bot looks and plane emote
- ac0cc704 Plane emote prototype out (arm-only, no life); 1st dances again
- 8905dc8e Three Meshy plane-play body animations (30 credits)
- 51579c9f Meshy body clips converted to R15; 1st place's plane emote holds their plane (waits on upload)
- 07cb6430 Bot names in today's Roblox styles (lunaaa, sxphie_12, honeypotato, RAWR)
- 0844ec6c 157 real-player outfits for bots; decision: steady group winners' shot with Roblox emotes
- this handoff
- Queued: plane emotes for the shop stage (better motion source: more Meshy tries or Roblox video capture, Alan's
  go); refreshing the outfit list now and then (rerun the tool).

## KNOWLEDGE UPDATED
- docs/systems/bots.md (looks from saved outfits, names, Code table), docs/systems/menus-and-hud.md (cutscene emote
  line), docs/workshop/tools.md (find_bot_looks, meshy_to_r15, r15_keyframes, meshy motion), docs/workshop/lessons.md
  (lookup limits + outfit search; Meshy clips + temp animation ids), decisions: 2026-10-18-winners-shot-redesign.md
  (new) and emotes-and-bot-looks (verdicts). STATE.md updated. Memory: send-videos-not-gifs. Checker: OK (92 pages).

## POINTERS
- src/client/WinnersCutscene.luau (shot constants at the top), src/server/AvatarService.luau (`Service:look`),
  src/shared/BotNames.luau, config/gameplay.json (`rounds`, `avatar_display.bot_look_outfits`).
