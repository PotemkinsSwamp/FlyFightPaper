# HANDOFF — 2026-10-18 — Winners' cutscene cinematic (close-ups, zoom-out, blur, uploaded hop); hula hoops in; next: research how devs make bots look like real players

**Labels:** kind=ui · lane=ui · branch=main · issues= · areas=src/client/WinnersCutscene.luau, src/server/VoteRings.luau, config/gameplay.json, tools/winner_hop_animation.luau, tools/upload_texture.py, assets/animations

★ START HERE: Goal: bots that look like real, present-day Roblox players so Alan can judge the winners' cutscene and
nobody can tell bots apart ([decision](../../docs/decisions/2026-10-18-emotes-and-bot-looks.md)). Alan (2026-10-18):
do NOT hand-dress bots (too slow, won't look real); first RESEARCH how Roblox devs make NPCs that look like real
players: plugins, free Creator Store kits, standard methods. Done when Alan gets a short plain list of 2-3 real
options with cost and how real they'd look, and picks one. Then build it; then the prototype prop emote.

> Read on demand: AGENTS.md → THIS → the decision above. Bot looks today: `src/server/AvatarService.luau`
> (`Service.outfit`, config `bot_outfits`), names `src/shared/BotNames.luau` (already player-style; keep). Memories:
> creator-store-first, studio-play-is-shared, look-at-textures-before-upload.

## STATE (verify before acting)
- HEAD `2deef6fd` + this handoff's commit on main, auto-pushed by the post-commit hook. `git status -sb`.
- Tests 328/0 (run 2026-10-18 after the config change). Re-run in Play (server):
  `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- Studio open in Edit (Play stopped), Rojo serving. Place file not re-saved this session (code lives in src/).
- Cost last session: no subagents, no Codex; one Open Cloud upload (hop animation, Alan's go, free). ~8 web searches.
  Primary context ~45% at handoff.

## NEXT ACTION + PLAN
1. **Research (no building yet):** how devs give NPCs real-player looks. Leads from one search on 2026-10-18, unchecked:
   - `AvatarEditorService:SearchCatalog` can list catalog bundles/items in-game; full-avatar bundles (head, body,
     layered clothing) applied through `HumanoidDescription` might give whole modern looks with no hand dressing.
     Check sorting (bestselling?) and that NPCs may wear items nobody bought.
   - `AvatarCreationService:GenerateAvatarAsync` (Roblox avatar generation): check what it does; generating while the
     game runs would break AGENTS' "no runtime AI calls" rule, at most a one-off build step, and Alan's call.
   - Creator Store / plugins for random player-like NPCs: read any scripts first (AGENTS).
   - Copying real players' avatars (by user id or outfit id) is out: VISION forbids forged or copied accounts.
   Report to Alan in plain words: options, cost, how real, recommendation. Alan picks.
2. Build the chosen option; check with Play screenshots of the desks and cutscene close-ups (giant ScaleTo'd avatars
   with layered clothing must still sit and stand right).
3. Prototype prop emote (plane around the head); a quick free test of whether Roblox-made emotes load in our game.
4. Then Alan's Stage 9 playtest list in state/STATE.md.
HOLDS (Alan's go each): uploads, publish, Studio-settings changes, Meshy, anything paid, desktop control, closing
Studio. Don't steer his plane while he's in Play (check first; my test Play is fine).

## DECISIONS & WHY (this session)
- Cutscene = close-up of 3rd, 2nd, 1st in turn (TURN 1.8 s), push in on 1st, then card goes and it zooms out to all
  three emoting (Alan's notes). Winners' moment 15 → 18 s so the group shot has time (STATE "Decisions to review").
- Only blockers fade (screen-overlap + sight-line test per shot); whole town buildings fade together ("name/piece"
  pieces in CityToys) because half a building shows its dark inside. Planes, other name tags, landing rings always fade.
- Group shot from just above the roofs with a 70° lens: Roblox's DepthOfFieldEffect caps focus at 500 studs.
- Hula hoops built from round parts: no free Creator Store hoop matched (checked 2026-10-18).
- Hop animation hand-keyed (tools/winner_hop_animation.luau), uploaded as rbxassetid://108989627946940.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (docs rules, model router, holds). Memories named above. VISION: no forged/copied accounts.

## CARRY NOTES / GOTCHAS
- Rojo can lag ~1 s behind an edit: check the Edit-side Source before pressing Play, or the old code runs.
- Python `open(...,'w')` on src/client/WinnersCutscene.luau and state/STATE.md sometimes fails with Errno 22 on this
  machine; the Edit tool works.
- Ending a round during its countdown (dev button spam) leaves no winners on the desks; real rounds end mid-game.
- One ~55-65 ms frame hitch at cutscene start remains (likely the winner clones); the part check is spread over frames.
- The focus blur barely shows in screenshots; may need stronger BLUR_NEAR/FAR once Alan sees it live.
- During the vote lap the top round strip still shows the old round's mode and clock.
- `assets/ui/mainmenu/ready/` is untracked build output; five loose Workspace objects are Alan's: leave them.

## WHAT SHIPPED / OTHER QUEUED
- 3e3b8185 Winners' cutscene straight on, dead centre, with the room cleared on your screen
- 7a3cb1bb Winners' stand-up-and-hop animation built, ready to upload
- d39eb3a7 Vote rings are now giant hula hoops
- c86a277b State: hoops in, vote arrow seen pointing, animation waits on upload go
- e91a445a Winners now stand up and hop with the uploaded animation
- 3e9cf4fd Winners' cutscene: close-up of each winner in turn; only blockers fade out
- dba67e6b State: cutscene close-ups
- 077e84b1 Winners' cutscene zooms out to all three emoting; focus blur; whole buildings fade
- 2deef6fd Decision: bots that look like real players first, then plane emotes
- e43ece72 Handoff: cinematic cutscene and hoops done; next bots that look like real players (superseded by this one)
- this handoff (Alan: research bot looks first, no hand-dressing)
- Queued (later, shop stage): Alan's emote ideas (plane around head, touchdown slam, throw-and-circle, plane into the
  camera) — in the decision note.

## KNOWLEDGE UPDATED
- docs/systems/modes-and-scoring.md, menus-and-hud.md: cutscene, hoops, arrow seen pointing, hop uploaded, 18 s.
- docs/workshop/tools.md: winner_hop_animation.luau, upload_texture.py --animation. lessons.md: animations without clicks.
- docs/decisions/2026-10-18-emotes-and-bot-looks.md (+ README line). STATE.md updated. Checker: OK (91 pages).

## POINTERS
- src/client/WinnersCutscene.luau (shot constants at the top), src/server/AvatarService.luau, config/gameplay.json
  (`rounds`, `bot_outfits`), docs/systems/bots.md.
