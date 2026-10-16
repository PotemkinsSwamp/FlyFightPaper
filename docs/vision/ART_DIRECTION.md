# Art, UI, audio, and map production brief
Owner update2026-09-30: Built-in GPT image generation and Blender asset production are authorized. Alan clarified the local key is for Roblox asset operations, not OpenAI. No separate OpenAI API billing is inferred. Generated references never substitute for actual game screenshots or tested imported assets.

Owner update2026-10-01: Search for suitable free Creator Store assets first and use them when their style,
geometry and delivery fit the vision. Use built-in GPT Image references and original Blender models for
remaining gaps. This supersedes the earlier procedural-first preference. Keep the classroom visually coherent.

Owner update2026-10-01: Alan authorized the existing3,150 Meshy-credit inventory allocation in docs/MESHY_ASSET_PLAN.md (archived 2026-10-06; the current budget is [the Meshy credit decision](../decisions/2026-10-07-meshy-credit-budget.md)). This permits the budgeted Meshy jobs; no new credit purchases or reload. Built-in image generation and local Blender finishing remain authorized.

Produce the environment and aircraft, not only their scripts. No paid generation outside that explicit allocation is authorized. A generation-service failure must
not block local asset production. Actual viewport captures are the basis of visual acceptance.

## Visual language
Warm classroom daylight, paper fibers/folds, tape seams, cardboard cut edges, school-supply colors, restrained
shadows and soft toy-like destruction. Competitive readable silhouettes and clear landmarks; not realistic
warfare, baby-themed equipment, photorealistic injuries, or an educational minigame. Use a small coordinated
palette, contrasting teams with shape/symbol cues as well as color. No realistic human harm. Plane defeat
shows paper scraps and a short sound; avoid blinding sustained explosions.

Aircraft visibly change with parts. Slim has a narrow sharp nose/clean fold, standard a readable folded-sheet
profile, heavy a wider reinforced-paper construction. Weapon mounts visibly carry pellet tubes, staple
magazine, elastic repeater, precision clip rail, eraser launcher, or a large pencil mechanism. Do not place
weapons through wings or block the camera. Distinct silhouettes must match actual collider sizes.

## Classroom layout
Owner reference clarification2026-10-02: Distribute genuine fly-throughs across ground, mid-height and roof levels. Include open belfry or clock-tower-like upper structures without requiring clocks. Do not make most buildings variations of a ground-centered tunnel. Preserve wide main flight routes around optional precision openings, with visible structural support and no obstructing collision boxes. The current expanded room candidate is2800x2200x620; the older room dimensions below are historical starting proportions.

Reference room900×700×300 studs. Twelve student desks in two rows, six across, desk tops at70, with clear
air routes above/between them. Each has a launch/service pad and giant seated avatar. Two central neutral
service desks and several cardboard/book-city islands create cover without closing the whole arena.
At least three vertical strata: under/around desk level, above cities, and high open air. Avoid long
unbreakable straight corridors that make one precision loadout universally dominant.

Give landmarks names and visual identities: Pencil-Case Bridge, Cardboard Square, Book Towers, Window Run,
Fan Alley. Add multiple looping routes usable by a heavy chassis. Put upward fans on exposed routes and
horizontal fans along readable lines; never create protected stationary farming inside an objective.
Mark fan flow visually without filling the room with particles. Objective sits clear of service domes and
is reachable from both team sides. FFA launch desks have multiple escape directions.

The generator exports bounds, pad/approach poses, fan volumes, objective volume, destructible IDs, and 3D bot
waypoints. Geometry must be repeatable from the seed and safe to regenerate. Keep ordinary structure static;
small paper flags/cardboard props alone are destructible initially. Props have explicit scoring caps/respawn
rules, no endless reward per fragment. Each shared visual family gets one representative review before mass
replication rather than an expensive model call per book.

## Avatars
Real participating users' avatar appearance when available, posed seated consistently and scaled to classroom
students relative to the small planes. Use original varied presets as the fallback and for scripted pilots.
Normalize collision to an aligned seated-body proxy so huge accessories cannot change competitive cover.
No fake human account profile, online count or purchase behavior. Bots get the same in-match presentation
without AI labels. Fallback appearances are not a guarantee that all user assets load successfully.

## Menu and UI look (Alan, 2026-10-08)
Kids in an early-2000s classroom, like an I Spy book: menus and text are made of things from a kid's classroom.
Crayon and marker lettering, construction paper and cardstock panels, tape, push pins, stickers, lined paper.
Approved concepts (build as close to these as possible): `assets/references/ui-concepts/` main-menu.png (bulletin
board), hangar.png, settings.png, results.png. Game name on screen: FLY FIGHT PAPER. Menu pictures are real game
screenshots redrawn in crayon or as taped photos. Main menu shows Level, Paper and stats (planes downed, wins).
Build: background plate split in <=1024 tiles + separate transparent pieces (paper strips, cards, pins, tape)
with live text in a marker/handwriting font on top.

## Required screens
Main menu Play/Hangar/Equipment/Paper & Boost Shop/Practice/Settings. Rotatable aircraft preview, final build
stats, capacity/mount eligibility, ownership and level requirements, five saved presets. A concise tutorial
shows turn, fire, Lift/fan, landing and respawn; it is skippable and replayable with no repeat reward exploit.
In combat: crosshair, current/worn-max health, Lift, boost only when equipped, per-group reload/lock, team/target
markers, mode score/time, compact kill feed. Twin pencils show independent readiness. Service UI previews
wear, free alternatives, Paper cost and streak effect; never auto-purchases. Results explain score versus
Paper/XP. Menu overlay warns the match continues.

Neutral language and legible typography. Minimum1280×720 PC flow and1920×1080 reference; test scaling and no
clipped buttons. Icons plus words, no chat required for team play. Avoid full-screen reward spam or fake urgency.
Restructure HUD for eventual touch targets, but mark touch/controller as deferred rather than claiming support.

## Audio and effects
Distinct short cues for each weapon, lock/incoming eraser, empty Lift, fan pass, landing, service, death,
round start/end and confirmed equipment purchase. Subtle classroom ambience and optional music only with
reviewed free rights. No voice imitation or paid soundtrack. Provide separate sound/music levels and reduced
shake. Use pooled transient effects and cap distant sounds. Do not silently mark missing audio as finished;
use an honest fallback and record unavailable asset permissions.

## Evidence
Capture menu, builder with a slim and heavy loadout, active FFA HUD, team/control objective, each weapon,
service preview, worn health, twin reload, shop mock label, results, and overhead classroom view. Record
commit, resolution and Studio identity. Observe camera clipping and targeting against each avatar/plane size.
No generated concept image substitutes for a game screenshot. Fun/art approval remains observation-dependent.
# Owner wording correction, 2026-10-01

Use "FOLD / FLY / FIGHT" for the new classroom chalkboard tagline. Do not use "Explore" as game theming: this is a fixed-map aerial combat game. The approved corrected texture is `assets/textures/classroom-chalkboard391-v2-fight.png`; the first391 texture is superseded and must not be integrated.
