# HANDOFF — 2026-11-13 — Origami Crane and Skins/Trails tabs in the game; Alan's playtest bugs and two rulings next

**Labels:** kind=product+ui · lane=beta-lane · branch=main · issues= · areas=src/client/{SkinShapes,PlaneLooks,HangarCustomize,Hangar,PlaneDeaths,CombatEffects}, src/server/{HangarService,ProfileService,FlightService,RoundRuntime}, config/{looks,commerce,skin-shapes,skin-pieces}.json, tools/art/{skin_sheet,skin_looks}.py, assets/models/planes/{skin-sheet,skins/crane,skin-looks.rbxmx}, tests/unit, docs
**Time:** 2026-11-13 22:48 -05:00

★ START HERE: Goal (Alan): the beta feels finished and the shop makes money; skins and trails are the build. The crane
and the Skins/Trails tabs are in; Alan playtested and found bugs. Next: fix his playtest list
(`docs/playtests/2026-11-13-crane-and-skins-tabs.md`), starting with the tabs clicking unreliably (he gave his go to
Play and screen-grab Studio to click through and watch). Done when Alan replays it and OKs the crane and tabs.

> Read on demand: AGENTS.md → this file; `docs/decisions/2026-11-13-skin-rules.md` (his rulings, two new tonight),
> `docs/plan/SKINS-PLAN.md`, `src/client/SkinShapes.luau`. Memories: no-cardboard-tab-buttons (new),
> design-theory skill before any screen, playtest-notes-before-handoff, alan-does-play-checks, mute-studio-tests.

## STATE (verify before acting)
- HEAD `4d1c8257` + this handoff's commit (main), pushed by the commit hook. Confirm: `git log --oneline -3`.
- Tests 635/0, 43 suites (2026-11-13, before the CombatEffects shot-offset edit, which was only syntax-checked). Re-run
  in Play, server: `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()` (in `task.spawn`, result to a
  workspace attribute; `tools/studio_cli.py` works when the session has no Studio tools).
- Docs OK (192 pages): `python tools/check_docs.py`. Rojo serve connected; Studio in Edit; DevMute cleared.
- Uploaded with Alan's go: 15 booster copies + 15 crease maps (`skin-sheet/uploads.json`), crane 5 meshes + 3 pictures
  (`assets/models/planes/skins/crane/uploads.json`). Pictures were "Reviewing" at upload; check they show.
- Cost: main Opus ~48% context; 1 Codex job (Alan's ChatGPT plan, server wiring, ~6 min); 1 Opus-High research session
  (8 Sonnet helpers ~1.15M tokens + ~150k Opus, 35 min); crane sessions on Fable (Blender, local); 38 uploads; ~6 h.

## NEXT ACTION + PLAN
1. **Playtest bugs** (all in the playtest note): tabs click on/off unreliably (find why by clicking in Play; the binder
   redraws every 3 s and on profile changes, Hangar.update key now includes `looks`); boosters under the crane;
   "Try on" for unowned skins must be **Buy** (drop the dev Try on; dev try-on stays on the "Dev: skin" button, which
   should list shape skins too); Cancel / Take off use `Art.tab`, must be paper and tape; the **crumple ball** death
   must carry the skin (torn-apart already does); crane **guns don't touch the crane** (`SkinShapes` hang); **build
   shelf**: big photo mixes skin and parts (hiding uses `LocalTransparencyModifier`, which a ViewportFrame likely
   ignores: use Transparency on preview copies), loadout cards don't show the skin.
2. **Wing-hitbox tilt** (Alan's ruling, general rule): the server tilts the real wings' hit and crash shapes to the shape
   skin's wing angle (crane 32 degrees at the root), same size. New mechanic: how-it-works note for his OK first.
3. **Crane printed sheet** (Alan's ruling): its blue wave-and-blossom paper as a sheet picture (`config/looks.json`
   `picture`) so boosters wear it; upload is his go.
4. Then: real skin pictures, Shark Jet, Dragon, three trails (draw them), the crane's matching trail.
- HOLDS (Alan's explicit go, each): any upload, publish (he does it), Save to File, desktop control or screen grabs
  (granted for step 1's click-through), Studio Play while he's playing, any bot match, anything paid, any new
  mechanic or number.

## DECISIONS & WHY (this session)
- **Crane = five rigid MeshParts** (head, body, tail, two wings) placed and scaled by the client from the plane's part
  boxes (port of `crane_skin.py` formulas): no Bones, no EditableMesh; geometry stays in uploaded assets. Body is
  stretched per axis; wings hinge on the stretched body's side middle so the root never floats. Fit within ~5% of
  Blender on the starter (wings ~5% bigger: boxes, not vertices).
- Server keeps real shots and hitbox; moved guns are client copies; `SkinGunMove<slot>` attribute shifts only the
  drawn shot's start (own and others').
- Hidden parts carry `SkinHidden`; crane pieces carry `SkinPiece`; `PlaneDeaths` skips hidden parts so the crane
  crumples (torn-apart path) instead of the plane.
- Booster skin copies fit inside the existing sheet bounds, so the 83 uploaded copies stayed byte-identical.
- Crane in catalog as Mythical (999 R$ / 60,000 Paper), no trail yet; its Robux product off like the others.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (docs rules, model router, hard limits); design-theory skill and its screenshot checklist before Alan sees
  a screen; `docs/workshop/lessons.md` (new: no cardboard tab buttons); skin rules note.

## CARRY NOTES / GOTCHAS
- Three sessions shared this folder; a peer's plain `git commit` swept my staged files once (73a73ecf). Commit by path.
- MCP `execute_luau` runs in its own VM: module state (Hangar.tour, PlaneLooks.devSkin) is not the game's.
- `PlaneLooks` loads in server tests (TouchWords requires the menus): keep client modules safe without LocalPlayer.
- Moved guns are copies: they don't animate when firing (WeaponMotion drives the real ones).
- Unit tests count skins and products; adding a look means updating Commerce/CommerceService/Looks specs.
- Carried: phone sizes of gift note/arrival and report card row; a real gift through the shop; backpack music dip.

## WHAT SHIPPED / OTHER QUEUED
- 73a73ecf (crane session, also carried my booster sheet files) · de2faf8e tools page rows · c40739ad, 52baee43,
  d4666536, 18e4e4ab, 56f4aa40 crane passes and game files (crane sessions) · 9e910994, 6a5249aa optimization skill
  (research session) · e24e9a51 decision: speed work waits until content is done (research session)
- dc911a29, ee55a076, 0039cc96 (crane session), 4d1c8257 skin rules · 7a9b2b6d boosters wear the skin · 8a3c0726 crane
  in the catalog · a51c7e73 skins save (Codex) · 0dcf4992 Skins and Trails tabs, fitter · a1779992 crane in the game
  · 8d92b815 playtest notes
- Queued: skin boxes (numbers note first), missions, playtime calendar, bots that use the town (IDEAS).

## KNOWLEDGE UPDATED
- Decisions: skin rules (guns underneath + shots, V wings, head never stretches, shape skins tilt the wing hitbox,
  Mythicals get a printed sheet). Playtest: 2026-11-13-crane-and-skins-tabs (new). Systems: planes-and-hangar (Where it
  stands, SkinShapes + HangarCustomize rows). Plan: SKINS-PLAN status. Workshop: tools.md (skin_sheet 98, skin_looks
  shapes), lessons.md (no cardboard tabs). STATE rewritten (60 lines). Checker OK (192 pages).

## POINTERS
- `src/client/SkinShapes.luau` · `src/client/HangarCustomize.luau` (lookCards, lookControls) · `config/skin-shapes.json`
  · `assets/models/planes/skins/crane/crane-fit.json` · `tools/art/crane_skin.py` · `.planning/skins/looks-server-brief.md`
- AAR: planned crane renders → OK → in game; actual: four crane passes (Alan steered in the crane sessions), then
  crane + tabs + saving in one push; tests caught a client module breaking a server test; one syntax slip
  (multi-assignment with a call) broke PlaneLooks in Play until fixed. Cost matched output; the tab-click bug needed a
  real click-through that numeric checks couldn't show.
