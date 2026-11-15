# HANDOFF — 2026-11-15 — Dragon: Tripo makes the shape, Blender paints it from our approved views

**Labels:** kind=product · lane=beta-lane · branch=main · issues= · areas=docs/decisions/2026-11-14-shape-skin-model-sheets.md, docs/workshop/lessons.md, docs/plan/SKINS-PLAN.md, state/STATE.md, .planning/skins/dragon/six-views/, .planning/skins/dragon/tripo/, .planning/skins/dragon/body-fable/round-17/
**Time:** 2026-11-15 17:01 -05:00

★ START HERE: Goal (Alan): the best Dragon skin, from the workflow he ruled: **Tripo for the shape only, Blender for the paint.** Opening action: in Tripo Studio (Alan's Chrome, signed in, Pro), download the best UNTEXTURED Smart Mesh version (~4,000 triangles; the 4 versions made 2026-11-15 ~16:40, three have whole wings, one has holes between the wing struts) as GLB into `.planning/skins/dragon/tripo/`. Then unwrap it, project the six approved paintings onto it, plus a new seventh Codex painting of the player's view (behind and above). Done when the player's view of the painted model matches that painting crisp (gold, scales, glowing eye, fins), then the other views, under 4,000 triangles and 1024 pictures, and Alan OKs it.

> Read on demand: AGENTS.md → this file; then the Dragon entries near the end of `docs/decisions/2026-11-14-shape-skin-model-sheets.md` (six-view set, Forge, Tripo, Alan's ruling). Lessons: `docs/workshop/lessons.md` (paint over renders once; Tripo nose-up; player's view first). Memories: look-at-textures-before-upload, concept-to-blender skill before modelling.

## STATE (verify before acting)
- HEAD: `git rev-parse --short HEAD` (this handoff's commit sits on `bcfc9c27`); main, the commit hook copies to GitHub ("github: pushed"); plain `git push` says "no upstream", expected.
- Tests: 650/0 last run 2026-11-14; no game code changed this session (docs and `.planning/` art only). Docs: `python tools/check_docs.py` OK.
- Studio: not touched this session. Tripo credits left 5,985 (Pro, website only; the API key `TRIPO_API` still has 0 credits).
- Cost this session: Opus main (~43% context at handoff); 1 web-fetch helper (~52k tokens + one follow-up); Codex picture jobs on Alan's ChatGPT plan: 99,547 + 70,497 + 97,239 tokens; Tripo 215 credits (HD 45, Smart Mesh x4 100, texture 20, HD nose-up 45, retopo 5); Alan bought Tripo Pro himself.

## NEXT ACTION + PLAN
1. Download the untextured Smart Mesh GLB (Alan's go covers it, 2026-11-15). Turn it nose-forward in Blender: it is stored nose-up; the matrix in the scratch script used for the HD model was rows ((0,0,-1),(1,0,0),(0,-1,0)) (nose to -X, back to +Z, like our renders). Check: 6 renders beside `six-views/final/*`.
2. Seventh painting: render the Blender round-17 model (`body-fable/round-17/model.blend`) from the player's view (behind and above, `sheet_model.py`'s "chase" direction) and have Codex paint it in the same finish as `six-views/final/` (legs C, belly plates, glowing eye with no pupil), once from the render, never repainting a painting.
3. Unwrap (Blender Smart UV first; Tripo "Smart UV" only if it's messy, a few credits, Alan's go needed for credits beyond the download) and project: each spot from the painting that faces it best with a depth test (`tools/art/sheet_model.py` does this for sheets), chase painting last; flat gold/green/cream by part where no painting sees well. Prove it on the head and fins close up before the whole model.
4. Player's view first: painted model vs the seventh painting; then all six. Then mirror for symmetry if needed, the 1024 maps for Roblox (colour, normal, roughness and metalness split from Tripo's packed map if reused), cut into the five fit pieces.
- HOLDS (Alan's explicit go, each): Roblox uploads (picture safety check first); publish (he does it); place saves; desktop control or screen grabs beyond Studio Play checks; Studio Play while he plays; bot matches; Tripo credits beyond this plan; any new mechanic or number. Tripo Studio in Alan's Chrome is fine for this work.
- Stop rule: one projection pass, checked from the player's view; if the head or fins smear, fix those pieces (flat colour or a closer painting), don't redo the whole model.

## DECISIONS & WHY (this session)
- **Tall back fins again** (Alan): the low caps came from mistaking the front-view tail for a fin; built as `body-fable/round-17/` (`FH = 1.0`).
- **Six views painted over renders** (one Codex job each round, outline 95-99% the render's, so views agree). Alan's picks: C's folded legs, belly plates, eye stays the glowing gem with NO pupil. Final set: `six-views/final/` (painted once from renders; painting a painting "fried" C).
- **Forge GUI**: free plan can't make 3D (Creator $22/month); its 3D box takes several pictures, multi-view unknown. Not used.
- **Tripo**: free website can't multi-view (six pictures made six models); Alan bought Pro. Level views see the wings edge-on (narrow blades), so the pictures go in **nose-up** (`six-views/tripo-noseup/`). HD Model + 5-credit retopo gave `tripo/dragon-tripo-4k-tris.glb` (4,022 triangles, 1024 maps), good shape but Tripo's paint is soft and smeary from the player's view (Alan's screenshot). Hence the ruling: Tripo shape, Blender paint.
- Roblox limits used: 20,000 triangles per mesh, 1024 textures (official docs); our budget ~4,000 triangles, one 1024 set.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md hard limits, model router, docs rules; commit by path; the hook pushes. Keys only with their own service. Free-plan Tripo outputs belong to Tripo; Pro outputs are Alan's (private, commercial).

## CARRY NOTES / GOTCHAS
- Tripo Studio: cube icon = "Multi-view Images to 3D"; Smart Mesh tab supports multi-view, P2.0, 1/2/4 versions; slots lose their file inputs once filled (delete then upload); Privacy set to Private each run; Export dialog: GLB, texture 512/1k/2k/4k, "Send to Roblox" bridge (an upload: Alan's go). Downloads land in `~/Downloads` as `tripo_convert_<id>.glb`.
- Alan has `Tripo3d_Roblox_Bridge-Win-latest.zip` and a Blender bridge zip in Downloads (not installed by me).
- `.planning/` is not in git: all Dragon pictures and GLBs live only on this PC.
- Backlog after the skin (Alan): desk photos under the crane, crane gun pieces while firing, Toilet Roll shake recorder (STATE "Waiting on Alan").

## WHAT SHIPPED / OTHER QUEUED
- `183552f9` Dragon: tall back fins again (Alan); six matching concept views painted by Codex from the Blender renders
- `67e5545c` Skins: Forge GUI needs a paid plan for 3D (nothing spent); Dragon views get anatomy options next (Alan)
- `3980135f` Dragon views: Alan picks folded legs and belly plates, keeps the glowing eye; paint once from renders
- `5212d793` Skins: Tripo multi-view needs Pro on the website, or a few cents a model through the API
- `a8c79112` Skins: Forge GUI's plans and what its 3D box can and can't be shown to do
- `ecbe07a1` Skins: first Tripo Dragon models; feed flat flyers to multi-view nose-up so it sees the wings
- `bcfc9c27` Skins: Tripo HD Dragon at 4,022 triangles; Alan's ruling: Tripo shapes it, Blender paints it
- This handoff's commit: skins plan + STATE lines, player's-view lesson, handoff, LATEST.

## KNOWLEDGE UPDATED
- `docs/decisions/2026-11-14-shape-skin-model-sheets.md`: fins, six-view set, picks, Forge, Tripo plans, Tripo results, Alan's workflow ruling.
- `docs/workshop/lessons.md`: paint over renders once; Tripo nose-up for flat flyers; judge a skin from the player's view first.
- `docs/plan/SKINS-PLAN.md` Tripo line and `state/STATE.md` skins line rewritten to current truth. Checker OK.

## POINTERS
- `.planning/skins/dragon/six-views/` (`final/`, `renders/`, `tripo-noseup/`, prompts and logs) · `.planning/skins/dragon/tripo/` (`dragon-tripo-4k-tris.glb`, `renders/`, `concept-vs-tripo.jpg`) · `.planning/skins/dragon/body-fable/round-17/` · `tools/art/sheet_model.py` · `.claude/skills/concept-to-blender/`
