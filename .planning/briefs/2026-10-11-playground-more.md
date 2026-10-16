# Codex job: six more playground toys in tools/art/toys.py (2026-10-11)

Alan: the playground looks empty. Add six toys in the same pipeline and style as `jungle-gym`, `swing-set`, `slide`
(same scale: ~200 studs per metre, bright red/blue/yellow/green powder-coat and plastic, toy-like but believable).

| Toy | Size (X width, Y depth, Z height, studs) | Look |
|---|---|---|
| seesaw | about 600 x 80 x 160 | Red plank on a yellow centre pivot, two seats with handles. |
| merry-go-round | about 400 x 400 x 180 | Round blue platform with yellow/red segments, centre post, curved hand rails. |
| spring-rider | about 120 x 60 x 170 | A cheerful green duck (or horse) on a thick coiled spring and a flat base plate. |
| monkey-bars | about 600 x 150 x 420 | Two ladders joined by a horizontal ladder of rungs on top, blue posts, yellow rungs. |
| tire-swing | about 500 x 300 x 480 | A-frame (orange), three chains down to a black tyre hanging flat. |
| crawl-tunnel | about 400 x 160 x 160 | Red plastic tube on a low frame, rings at both ends. |

Rules
- Budget 3000-6000 triangles each (spring-rider ~3000). 1024 maps; do not lower texture size.
- Origin at base centre, front -Y, Z up. Look at each render; fix what looks wrong (max 3 tries each).
- Only edit tools/art/toys.py and the six new folders under assets/models/toys/. Do not touch tools/art/hero.py or
  assets/models/_rebake (another Codex job). No uploads, no Roblox Studio, no git commits, never read or print .env.
- Report: functions added, measured sizes, triangle counts, render paths, anything still wrong.
