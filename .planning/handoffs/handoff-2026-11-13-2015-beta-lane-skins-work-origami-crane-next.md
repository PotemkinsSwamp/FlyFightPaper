# HANDOFF — 2026-11-13 — Printed-sheet skins work in Studio (Alan OK'd); Origami Crane running in a linked Fable session

**Labels:** kind=product+data · lane=beta-lane · branch=main · issues= · areas=tools/art/{skin_sheet,skin_looks,upload_paper}.py, assets/models/planes/{skin-sheet,skin-looks.rbxmx}, config/{looks,skin-pieces,commerce}.json, src/{shared/LooksRules,shared/ProfileSchema,shared/CommerceRules,server/FlightService,server/ProfileService,client/PlaneLooks,client/DevTools}, docs
**Time:** 2026-11-13 20:15 -05:00

★ START HERE: Goal (Alan): the beta feels finished and the shop makes money; skins and trails are the build. Commons and
Rares work (Alan played them: "pretty good"). Next: check on the linked session [origami-crane]
(`local_70db8a74-aa69-453d-905f-5402e1592473`, Fable 5.2 high, Blender) and bring its crane renders to Alan; then skins on
the boosters. Done for the batch when Alan plays every first-batch skin and trail in Studio and OKs them.

> Read on demand: AGENTS.md → this file; `docs/plan/SKINS-PLAN.md` (how it works, prices, status),
> `docs/decisions/2026-11-13-skin-rules.md` (his rulings), `docs/playtests/2026-11-13-printed-sheet-skins.md`.
> Memories: report-workarounds-as-solved (new), assembled-preview-before-upload, look-at-textures-before-upload,
> plan-before-building-features, dev-button-not-workspace-switch.

## STATE (verify before acting)
- HEAD `618b8ad4` + the docs/handoff commits after it (main), pushed by the commit hook. Confirm: `git log --oneline -3`.
- Tests 617/0, 43 suites (2026-11-13, after all code). Re-run in Play, server:
  `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()` (start in `task.spawn`, read a workspace attribute).
- Docs checker OK (189 pages): `python tools/check_docs.py`.
- Rojo serve running and connected (port 34872); `SkinLooks` and `SkinPieces` synced. Studio in Edit; DevMute off.
- Uploaded with Alan's go: 83 piece copies + 83 crease maps (`assets/models/planes/skin-sheet/uploads.json`, mesh ids
  in `config/skin-pieces.json`) and 2 test skins (Hazard 124257520246805, Lava 127563698335848). Nothing published or
  Saved to File.
- Cost: main Opus ~45% context; Codex (Alan's ChatGPT plan) 2 jobs: sheet copies 201k, save rules 158k tokens;
  1 web-fetch subagent ~33k; local Blender rebuild 9.5 min; 168 uploads; ~3.5 h wall clock.

## NEXT ACTION + PLAN
1. **Origami Crane** (running in [origami-crane]): renders on 3+ builds, ≤ 4,000 triangles; Alan's OK on renders, then
   upload (his go), then fitting in game (Bones on wing/tail corners; hides the parts it covers; weapons and boosters
   stay visible; outline round the skin).
2. **Boosters wear the skin** (Alan): add `boost_*` paper/cardboard/accent pieces to `tools/art/skin_sheet.py` scope
   (rebuild `-- --rebuild`), upload the new copies (his go), `upload_paper.py sheet` → `lua`/`meshes`, `skin_looks.py`.
3. **Real skin pictures** on `assets/models/planes/skin-sheet/sheet-template.png` + `layout.json` (Hazard, Tiger,
   Flame, Gold Foil + shine, Lava + glow, Galaxy); contact sheet, then upload (his go); set `picture` in `config/looks.json`,
   run `tools/art/skin_looks.py` and `tools/generate_config.py`.
4. Shark Jet (sheet + fin and jaw add-ons), Dragon, the three trails, a **Skins tab and a Trails tab** in the
   customization menu with the pick shown on your plane (design-theory skill first), players' worn skin on their
   plane (`FlightService` sets `Skin`/`Trail` from the save), hangar previews skinned, team outline (Highlight).
- HOLDS (Alan's explicit go, each): any upload, publish (he does it), Save to File, desktop control or screen grabs,
  Studio Play while he's playing, any bot match, anything paid, any new mechanic or number.

## DECISIONS & WHY (this session)
- Alan's rulings (prices, Paper for Legendary 30,000 / Mythical 60,000, no free skins, bots by difficulty, boxes as a
  maybe with odds shown, boosters skinned, Skins and Trails tabs, Crane first, Fable runs Blender): skin rules note.
- **Skin copies, not a re-layout of today's pieces:** plain planes stay byte-identical; copies swap in only on screens
  where a skin is worn. Same upload count, zero risk to the plain look.
- **Trim (accents) wears the skin** (Alan); tape, team stickers, weapons don't.
- **`MeshPart:ApplyMesh` on the screen's own pieces**, not hidden parts plus welded copies: no welds, death crumples
  keep the skin, taking it off restores today's mesh and tinted look from `AircraftPieces`.
- **Looks made ahead** (`skin_looks.py` → `skin-looks.rbxmx`, one SurfaceAppearance per skin and piece): the runtime
  builder only takes EditableImages (~4 MB each); this is the standard texture path (lesson recorded).
- Bots in Common/Rare skins get a random plain trail (Claude's pick, in STATE "Decisions to review").

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (docs rules, model router, hard limits); memories above; `docs/workshop/lessons.md` (3 new lines);
  design-theory skill before any screen or picture goes to Alan.

## CARRY NOTES / GOTCHAS
- `skin_sheet.py` counts are hard-coded (83): widening scope means editing the 7 count lines; run with `-- --rebuild`.
  Its "existing file watch FAIL" only means other files changed during the run.
- Crease maps are 1024 and mostly empty; shrink to 512 if a memory check ever shows them.
- Gold Foil shine (MetalnessMap) and Lava glow (EmissiveMask) go on the ready-made looks; glow still untested.
- Studio Play behind other windows stays on the loading screen; call modules directly to test.
- Carried: phone sizes of the gift note/arrival and report card row; a real gift through the shop; the unlock
  backpack's music dip; starter pack card gap; `assets/ui/shop/raw` and `source` untracked; `mock_ui_label` dash.

## WHAT SHIPPED / OTHER QUEUED
- ad3fa92b Skins: prices, earning and bot skins drafted for Alan's OK
- 231e8877 Skins: Alan's calls on prices, no free skins, bots skinned by difficulty, boxes as a maybe
- 6cd6d6d5 Skins: Alan OK'd Legendary 30,000 and Mythical 60,000 Paper
- a069e3c7 Skins plan: skin copies of the pieces, built on screen with CreateSurfaceAppearanceAsync
- 7b9b8639 Skins: Alan is fine showing box odds
- 749cc53b Skins: printed-sheet copies of the 54 plane pieces with their creases (Codex, Blender, not uploaded)
- 5f3b4a81 Skins and trails can be owned, bought with Paper or Robux and worn; bots pick by difficulty (save v13, tests 617/0)
- e9dc0484 Skins: trim pieces wear the skin too (83 copies); upload tool gets a sheet mode
- ffe775c8 Skins show in Studio: bots wear them by difficulty, a dev button tries them on your plane (test Hazard and Lava pictures)
- 618b8ad4 Skins playtest: Commons and Rares work; boosters wear skins; Skins and Trails tabs; Origami Crane next
- (+ STATE/skins plan/lessons commit and this handoff)
- Queued after skins: skin boxes (numbers note first), missions, playtime calendar, bots that use the town ([ideas](../../docs/plan/IDEAS.md)).

## KNOWLEDGE UPDATED
- Decisions: skin rules (prices, no free skins, bots by difficulty, boxes, boosters, tabs, Crane first).
- Plans: SKINS-PLAN (prices table, method, status). Playtest: 2026-11-13-printed-sheet-skins (new, in README).
- Systems: economy-and-shop (LooksRules in Code), planes-and-hangar (Where it stands, PlaneLooks in Code).
- Workshop: tools.md (skin_sheet, skin_looks, upload_paper sheet), testing.md (617/43), lessons.md (3 lines).
- STATE rewritten (59 lines). Memory: report-workarounds-as-solved. Checker: OK (189 pages).

## AAR
- Planned: numbers note → re-layout shown → Alan plays skins. Actual: all three, plus the save rules. Why it differed:
  the documented runtime look builder turned out to need in-memory pictures, so looks moved to a made-ahead file; I
  then described the dropped route as if live and Alan spent a turn on it (memory written). Cost matched output.

## POINTERS
- `src/client/PlaneLooks.luau` · `src/shared/LooksRules.luau` · `tools/art/skin_sheet.py` · `tools/art/skin_looks.py`
  · `assets/models/planes/skin-sheet/README.md` · `.planning/skins/sheet/` (renders, contact sheets, briefs, logs)
