# HANDOFF — 2026-10-25 — Screen fit step 2 done; phone loading: menu first + Skip built, smaller maps approved

**Labels:** kind=ui+infra · lane=load · branch=main · issues= · areas=src/client/Loading.luau, src/first, src/client/ScreenFit.luau, src/client/FlightHUD.luau, src/client/DeskHangar.luau, src/client/MatchTips.luau, src/client/Tutorial.luau, src/client/RangeNotes.luau, src/client/ScreenCheck.luau, default.project.json, serve.project.json, docs
**Time:** 2026-10-25 01:19 -04:00

★ START HERE: Goal (Alan): the game loads on a phone in under a minute (seconds ideally) and looks exactly the same.
Opening action: build half-size normal / roughness / metalness maps for every town building piece (colour maps
untouched; flat one-colour maps shared or dropped), contact-sheet them, upload (Alan said go: whole town), swap the
ids in. Done when the town draws the same in Studio and Alan's phone loads clearly faster.

> Read on demand: AGENTS.md → THIS → `docs/plan/LOAD-PLAN.md` → `docs/decisions/2026-10-25-fast-phone-loading.md`;
> `docs/workshop/lessons.md` ("Uploads and Roblox moderation", "New models need texture packs", the two 2026-10-25
> lines) before any upload. Memories: look-at-textures-before-upload, texture-packs-after-new-models,
> commit-codex-output-first, alan-does-play-checks.

## STATE (verify before acting)
- HEAD `e3c21430` + this handoff's commit on main, pushed (the commit hook copies to GitHub). `git log --oneline -3`.
- Unit suite 425 / 0 this session (Server VM: `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`).
- Docs checker OK (132 pages): `python tools/check_docs.py`.
- Studio: Alan signed out/in (its login had gone stale after a week open); it now has the **published cloud copy**
  open (placeId 132768925825316), not the local `FlyFightPaper-WORKING.rbxlx`. Rojo serving (port 34872) synced the
  new `ReplicatedFirst.FlyFightPaper` folder into it. Device Simulator off at the end.
- Published game = c1114536 loading (no Skip yet). e3c21430 (Skip) needs Alan to republish.
- Cost: 1 Explore subagent (Sonnet, town pipeline survey), 0 Codex, 0 uploads, $0; ~15 Claude Play runs; 6 Blender
  headless renders. Context ~41% at handoff.

## NEXT ACTION + PLAN
1. Smaller maps (Alan's go, whole town): from `assets/models/*/parts/*-{normal,roughness,metalness}.png` make half-size
   copies (1024 → 512; the 2048/4096 ones halve too); flat maps (std < 3 on an 8x-reduced copy: 169 normal, 81
   roughness, 59 metal, 32 colour) become one shared tiny map per value or none. Contact sheets before upload; upload
   slowly and resumably through the existing records (`town_toys.py hero`, `upload_texture.py`); then `build v4` →
   `save_place.py`. New ids have no texture pack until Ctrl+S → `town_toys.py packs` → `build` again.
   Check: same viewpoints in Studio before/after, nothing missing; Alan's phone joins faster.
2. Load plan step 3 (streaming with Atomic buildings, Persistent room/landmarks, no pop-in) → plan to Alan first.
3. Load plan step 4 (one picture set per building band) only if phone numbers still say pictures.
4. UI lane: small iPhone + iPad re-check (`ScreenCheck.run()` in Play; Alan switches devices), then screen fit
   steps 3-6 (list in `docs/plan/SCREEN-FIT-PLAN.md` Progress).
Stop rule: a step is done when its check passes and Alan has seen it on his phone; no review rounds.
HOLDS (Alan's go, each): publish/republish (he does it), Save to File, closing Studio, desktop control (switching
simulator devices), Meshy, anything paid, real product IDs/prices, sales on, Studio Play while he plays. Uploads of
the smaller maps: **go given** (2026-10-25); any other upload needs his go.

## DECISIONS & WHY (this session)
- Notes in the top-middle column slide into the gap between corner pieces (touch Health/Lift, kill feed) and shrink,
  instead of dropping under them (Alan: small iPhones; the drop put them mid-view). `ScreenFit.place`.
- Match tip on phones: 85% size, stays up top, may cover news + kill feed, never Health/Lift (Alan).
- Desk stat sheet top = photo top on every screen (Alan); the old phone "+160 drop" went.
- Loading waits for the main menu's pictures, then Skip; town keeps loading behind; bar = true share; 3 min cap;
  any error still lets the player in (Alan; decision note 2026-10-25-fast-phone-loading).
- UIAssets lives in ReplicatedFirst (`src/first/UIAssets.luau`, `src/shared/UIAssets.luau` is a 1-line pointer) so
  `LoadingFirst.client.luau` can fetch the loading art + Kalam font before the world snapshot arrives.
- Bump/shine at half size, colour untouched: 3-building Blender close-ups differed < 1/255 on average; Alan OK'd.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md; decisions 2026-10-10-no-quality-cuts-for-fps and 2026-10-25-fast-phone-loading; memories above.

## CARRY NOTES / GOTCHAS
- Scripts can't read SurfaceAppearance maps (plugin rights): pass the instance to PreloadAsync (lessons.md).
- Studio's open copy is the cloud place: `save_place.py` writes the LOCAL rbxlx. Before rebuilding, agree with Alan
  which copy is the working one (open the local file, rebuild, then he publishes from it).
- Skip button never seen on screen (Studio loads in ~7 s); first real look is Alan's phone.
- ScreenCheck now skips world markers and lesson spotlight pieces, and allows tip-over-news on phones.
- Edge arrows can pass over LOCKED ON for a moment (left as is; Alan not asked).
- Comparison sheet: `.planning/load-maps-before-after.png`; render script was in the session scratchpad (re-make if needed:
  `D:\Blender\blender.exe -b assets/models/<b>/hero.blend --python <script>`; images ending -normal/-roughness/-metalness scaled).

## WHAT SHIPPED / OTHER QUEUED
- 62e390ff Screen fit step 2: top row + one column of notes; 2 kill-feed lines on a phone; desk strips under the feed; arrows clear of Health/Lift
- e20ce2cd Desk stat sheet level with the photo; notes under the kill feed on small phones
- 6c782159 Small phones: notes slide into the gap and shrink; match tip up top on phones; desk photo wing fix
- 674411f6 Plan: fast phone joins with the same look (for Alan's OK)
- c1114536 Loading: art + font before the game arrives; waits for menus + town; true bar; always lets you in
- e3c21430 Loading: main menu pictures first, then Skip
- + this handoff (decision note, STATE, plan progress).
- Queued (Alan's): stick tuning; winners' sound check; Save to File; prices; drawing pass; touch step 6 publish.

## KNOWLEDGE UPDATED
- plan/LOAD-PLAN (new: cause, 4 steps, Alan's answers, progress); decisions/2026-10-25-fast-phone-loading (+README);
  systems/performance (Phones paragraph, Code rows); systems/menus-and-hud (top row/column, gap rule, tip, desk
  sheet, UIAssets rows); plan/SCREEN-FIT-PLAN (progress 2026-10-24 later + 2026-10-25); workshop/lessons (+2:
  SurfaceAppearance maps unreadable, phone downloads whole map); HOME (load plan); STATE rewritten. Checker OK (132).

## AAR
Supposed: screen fit step 2 on each device, then steps 3-6. Actual: step 2 done on big phone + PC with Alan's fixes;
then Alan's real-phone test turned the session to loading. Why: nothing had been tried on a real phone; the cost of
4,500 unique assets with streaming off only shows there. Same/different next time: (1) Rojo live-syncs untested edits
into Studio, so whatever Alan publishes includes them: the untested ColorMap read (not allowed in game code) went out
in his publish and stuck the loading screen. Test in Play right after each edit, before he could publish; (2) verify Studio has the intended copy open (cloud vs local) before rebuild steps. Cost matched output.

## POINTERS
- `src/client/Loading.luau`, `src/first/LoadingFirst.client.luau`, `src/client/ScreenFit.luau` (`place`).
- Pipeline survey facts: `docs/research/PERFORMANCE-RESEARCH-2026-10-11.md` (fixes #5/#6), `tools/town_toys.py`
  (hero/build/packs), `tools/art/hero.py`, `tools/art/materials.py`, `tools/save_place.py`.
