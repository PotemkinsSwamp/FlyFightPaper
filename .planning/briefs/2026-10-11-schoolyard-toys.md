# Codex job: schoolyard toys in tools/art/toys.py (2026-10-11)

Alan wants a real schoolyard outside the classroom windows (today: flat green lawn and five ball trees), built so it
could later become a second map. Add five toys to `tools/art/toys.py` in the same pipeline as `school-desk`
(SPECS entry, builder, bake, export, checks). Scale: the classroom is ~200 studs per metre (desk 108 tall).
Style: bright, chunky, toy-like but believable playground equipment, matching the cheerful classroom.

| Toy | Size (X width, Y depth, Z height, studs) | Look |
|---|---|---|
| jungle-gym | about 800 x 600 x 500 | Climbing frame: red and blue powder-coated tubes, a yellow deck platform, a short ladder, a rope net on one side, a small green roof. |
| swing-set | about 700 x 300 x 480 | A-frame steel legs (green), top bar, two swings with chains and rubber seats. |
| slide | about 800 x 160 x 440 | Ladder up to a small platform, yellow plastic slide chute curving down, rails. |
| basketball-hoop | about 360 x 200 x 640 | Grey pole on a base, white backboard with red square, orange rim with a white net. |
| fence-panel | exactly 500 x 10 x 240 | Green chain-link (wire pattern in the texture, alpha not needed: paint it on a thin panel), posts at both ends, top rail. Tiles side by side. |

Rules
- Budget 4000-6000 triangles each (fence ~800). 1024 maps like the others; do not lower texture size.
- Origin at base centre, front -Y, Z up, like the other toys. Look at each render yourself; fix what looks wrong
  (max 3 tries each).
- Only edit tools/art/toys.py and the five new folders under assets/models/toys/. No uploads, no Roblox Studio, no git
  commits, never read or print .env. Another Codex job is using tools/art/hero.py; do not touch it.
- Report: functions added, measured sizes, triangle counts, render paths, anything that still looks wrong.
