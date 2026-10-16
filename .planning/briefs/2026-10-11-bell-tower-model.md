# Codex job: the big bell tower model, design A (2026-10-11; Alan picked A)

Build design A from `assets/references/bell-tower/concept-a.png` and `front-a.png` as a hero building, matched as
closely as you can: four legs of stacked LEGO-style bricks (red/blue/red, green base plate), a kraft-cardboard arch
block with taped corners, a band of red and blue bricks, a kraft clock body with a clock face on every side, a band of
blue bricks with red corner bricks, four yellow-brick corner posts round an open belfry, a gold toy bell, a blue
cardboard pyramid roof and a red cone tip with a small gold ball. Tape patches as in the concept. Style must sit with the other hero buildings (e.g.
`assets/models/gateway-towers/render-front.png`) and the approved reference `assets/references/classroom-city-approved-v1.png`.

## Exact sizes, measured from front-a.png (studs, Z up, base centre at origin, front -Y; a paper plane is 7 wide)
Round 2 (Alan: "the dimensions are way off"). Round 1 used a wrong spec (belfry far too tall, roof too flat, legs too
thin). These numbers come from the concept itself; match the concept's proportions, not round 1.
| Part | Height (Z) | Size |
|---|---|---|
| 4 brick legs (red, blue, red 2x2-stud bricks with studs, green base plate) | 0 - 110 | each 40 x 40, centres (+-83, +-83) |
| Kraft arch block, taped corners, four-way arch | 110 - 188 | 206 x 206; arch opening 120 wide, clear to 155 high, on all 4 sides and straight through both ways |
| Brick band (blue bricks, red 2x2 corner bricks a bit higher) | 188 - 200 | 160 wide band, corners at the arch block corners |
| Kraft clock body, taped corners, clock face on all 4 sides | 200 - 258 | 142 x 142; clock face 50 across |
| Brick band (blue bricks, red 2x2 corner bricks under the posts) | 258 - 278 | 118 x 118, aligned with the belfry posts |
| Open belfry: 4 yellow brick posts only | 278 - 340 | posts 24 x 24, outer 118 x 118 (opening 70 on every side) |
| Gold bell hanging from the belfry roof | bottom at 300 or higher | about 36 across, 40 tall |
| Blue cardboard pyramid roof | 340 - 398 | base 128 x 128 (overhangs the posts) |
| Red cone tip + small gold ball | 398 - 430 | cone base 26 |
Nothing may block the arch or belfry openings. Look: real chunky bricks with studs and soft bevels, cardboard with
visible corrugated edges and tape patches, warm lighting like the concept, not flat colours.

## Clock as its own asset (Alan, round 3: the game will animate the hands)
- The tower body gets NO painted clocks: leave a flat round seat (50 across) on each of the 4 sides where a clock sits.
- One separate clock asset, made once and placed 4 times, in `assets/models/bell-tower/clock/`, three meshes that
  share one texture set: `clock-face` (cream dial, 12 tick marks/numerals, wooden/cardboard rim and a centre cap, 50
  across, about 3 thick, front faces -Y), `clock-hour` and `clock-minute` (black hands, slightly in front of the dial,
  pointing straight up at 12). Each hand's origin is the clock centre so it can turn about the Y axis; record each
  mesh's size and that pivot offset from its box centre in `clock/checks.json` (like split_parts.py's "axis").
- Also record in `parts.json` (or clock/checks.json) the 4 clock positions and facings on the tower (centre point,
  outward direction), so placement code can stand them.

## Pipeline
- Model and texture it in Blender (Blender is `D:/Blender/blender.exe`), save the source in
  `assets/models/bell-tower/`, then cut it into independently textured pieces with `tools/art/hero.py` the same way the
  other hero buildings are (read hero.py for its expected input; output `parts/*.fbx` + colour/normal/roughness maps +
  `parts.json`, renders). Keep the bell as its own piece if hero.py allows. Per piece at most 12000 triangles, total at
  most 48000. Texture density at least that of gateway-towers (front_pixels_per_stud in its parts.json); no quality cuts.
- Render front, side, 3/4 and a view looking straight through the arch and through the belfry; put a compare.png of
  your front render next to front-a.png. Fix anything that does not match or is not open (max 3 tries).
- Do NOT edit tools/art/toys.py (another Codex job is editing it). A new builder script (e.g. tools/art/bell_tower.py)
  is fine. No uploads, no Roblox Studio, no git commits, never read or print .env, no Meshy.
- Report: files written, piece list with triangle counts, measured sizes (legs, arch opening, belfry opening, bell low
  point, total height), render paths, anything still wrong.
