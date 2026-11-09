# HANDOFF — 2026-11-09 — weights, prices and text style built; crisp menu pictures next, then the unlock moment

**Labels:** kind=product+ui · lane=beta-lane · branch=main · issues= · areas=config/catalog.json, config/economy.json, config/gameplay.json, src/shared/Catalog.luau, src/shared/BotBuilds.luau, src/shared/EconomyRules.luau, src/client/PaperUI.luau, src/client/Hangar.luau, tests/unit, docs
**Time:** 2026-11-09 00:03 -05:00

★ START HERE: Goal (Alan): the beta feels like a finished game, one map, a strong first-session hook. Next (Alan's
call): make the menu pictures crisp. Today they're stretched and low-resolution with soft edges (the Back button's tack is
squashed), so the new sharp text looks bad on them. Find what is stretched or blurry, fix what code can (no stretching),
re-make pieces that are too small, and show Alan an assembled before/after preview BEFORE any upload. Done when Alan
says the menus pop. Then the unlock moment.

> Read on demand: AGENTS.md → this file; docs/decisions/2026-11-08-text-style-crayon.md (newest bullets),
> docs/playtests/2026-11-08-text-style-menus.md, docs/systems/menus-and-hud.md, docs/workshop/lessons.md (last 3 bullets).
> Memories: text-fits-its-box (new), assembled-preview-before-upload, look-at-textures-before-upload, hand-made-not-generic-roblox,
> in-game-menus-match-main-menus, codex-for-pictures-and-blender, alan-does-play-checks, playtest-notes-before-handoff.

## STATE (verify before acting)
- HEAD = this handoff's commit on `main` (after d3b57935); the commit hook copies each commit to GitHub. `git log --oneline -3`.
- Tests 476/0 in Play (2026-11-08 ~23:30): start Play, then on Server `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`
  via `task.spawn` + a workspace attribute (long calls drop replies). Docs: `python tools/check_docs.py` OK (160 pages).
- Studio: Edit mode, DevMute ON (set it off when done testing, or leave for the next test run), Rojo connected.
  Published v495; nothing saved to file or published since (Alan's go each).
- Cost this session: Opus main only, no subagents, no Codex, nothing paid. ~1h40 wall clock plus 4 background bot
  matches (script, near-zero tokens). Primary context ~40% at handoff.

## NEXT ACTION + PLAN
1. **Crisp menu pictures.** Known from the code: `PaperUI.button` sets `ScaleType.Stretch` (pins baked into strip art get
   squashed when a button's shape differs from its picture), many `PaperUI.image` pieces stretch too; some uploads were
   made small (`assets/ui/*/ready`, `UIAssets.luau`). Check each screen at 1280x720+ and on a phone-sized window. Pins/tape
   as separate pieces, 9-slice or Fit where a piece must change shape. New art: Codex images or Blender (memories);
   contact sheet before upload (moderation). Show an assembled preview; upload only on Alan's go.
2. **The unlock moment** (concept frames `.planning/unlock-concept2/`, rules in the unlock-ladder decision note).
3. Later: shop step (re-scale Paper packs and Robux part prices to the new Paper economy; goal-based offers, see below);
   balance pass (Spitball builds weakest, Staple loses to the Pellet, watch Tack Skirmisher and Cardboard Tank).
- HOLDS (Alan's explicit go, each): publish (he does it), Save to File, any upload, desktop control, Studio Play while
  he's playing, a bot match, anything paid; any new mechanic or number before it's built.

## DECISIONS & WHY (this session; all in docs/decisions/)
- Weights: a gun's weight both fills and slows the plane (2 studs/s a point); bot builds re-made with Pellets (Staples at
  weight 2 lose to the free Pellet). Boosters keep their own weight (Alan OK'd). Toilet Roll mounts heavy, heavy, medium,
  light, light. → 2026-11-08-unlock-ladder-and-bot-builds.md.
- Pacing: Paper is the gate, not levels. Level 50 in ~18 h (each level 200 + 22*(L-1)^1.5 XP), everything owned in ~36 h
  of Paper (prices 4x, Pencil 32,000). Why: non-buyers take longer and choose; Robux is the shortcut; prestige comes sooner.
- Ethical selling: Alan wants offers timed to funnel players to Robux. Agreed line: offers tied to the player's own goal,
  capped, never after a loss or as fake urgency (players 9-16; FTC/Epic $245M, 2022). Build in the shop step.
- Text: loud (full style C) only on buttons, titles, names, HUD slips, the build-name box; descriptive words quiet (thin
  edge). Words must sit centred in the art under them.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md; memories above; docs/workshop/lessons.md ("Words must sit inside what they're on", "Never git stash").

## CARRY NOTES / GOTCHAS
- Only one UIStroke renders per text object, so style C draws child copies (`PaperUI.crayon`); text made without
  `PaperUI.words` (13 direct labels: score pop-ups, dev buttons, some HUD) is unstyled.
- Roblox caps TextSize at 100. `screen_capture` works in Play; `user_mouse_input` with an instance path clicks Play GUI.
- Not yet looked at in the new text: Settings, round end, Range notes, phone-sized window.
- Edit-VM `require` cache, ChatScript error, long Server calls drop replies: see the 2144 handoff.

## WHAT SHIPPED / OTHER QUEUED
- 1be61607 Guns' weight now slows the plane; lighter tank bodies; bots re-made for the new weights
- 98881e93 Bot test of the new weights: no errors, tanks no longer run away
- 9646b168 STATE: shorter, prices next
- 8c91caee Levels curve to 50 in about 18 hours; Paper prices scaled so owning everything takes about 36
- 361d971a Text style C: heavier warm-black words with a cream outline and soft shadow on every menu
- f4ae16a6 STATE under 60 lines
- e979f8b0 Text style C: full look only on buttons, titles and names; descriptive words get a thin edge
- d3b57935 Hangar stat names sit centred in their labels with even room around them
- (this commit) playtest note, decision ruling, lessons, STATE, this handoff
- Queued: Save to File + publish (Alan's go); results card → report card (must do); winners' circle, skins, shop step.

## KNOWLEDGE UPDATED
- decisions: unlock-ladder (weights built, bot builds, prices and pacing, ethical offers); text-style-crayon (loud/quiet,
  words fit boxes, crisp pictures next). systems: planes-and-hangar, weapons, bots, economy-and-shop, menus-and-hud.
- playtests: 2026-11-08-weights-and-tanks-matches, 2026-11-08-text-style-menus. lessons: words fit boxes, never git stash.
- Memory: text-fits-its-box. Checker: OK (160 pages).

## POINTERS
- src/client/PaperUI.luau (`words`, `crayon`, `loud`, `button`, `image`), src/first/UIAssets.luau (asset ids),
  assets/ui/ (source and ready art), .planning/text-style-c-*.jpg (tonight's screenshots), tools/ui_pieces.py, tools/ui_sheets.py.
