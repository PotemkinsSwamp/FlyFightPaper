# Codex job: classroom models in tools/art/toys.py (2026-10-11)

Alan: the classroom has no door, the updraft fans are plain grey boxes and the desk launch pads have no hangar. Add
five toys in the same pipeline and style as `school-desk` / `school-chair` (studs; the room is ~166 studs per metre;
bright, warm, toy-like but believable; 1024 maps, never lower). Origin at base centre, front -Y, Z up.

| Toy | Size (X width, Y depth, Z height) | Look |
|---|---|---|
| classroom-door | 190 x 20 x 370 (frame included) | Wooden classroom door in a painted frame, tall narrow window with wired glass, lever handle, kick plate, a small "Room 12" sign above the window. Front face (-Y) is the room side. Flat back. |
| floor-fan | 160 x 160 x 36 | Box fan lying face-up on the floor blowing upward: chunky blue plastic frame, chrome wire grille on top, white blades visible through it, small feet. |
| desk-hangar | 110 x 70 x 50 | A little folded-cardstock aircraft hangar for paper planes: arched roof, open front (-Y), painted number "1" and red-white stripes, sits on a desk. |
| cubby-shelf | 600 x 120 x 300 | Low wooden classroom cubby shelf, 3 x 2 cubbies, each holding a coloured bin, a backpack or books. Open front (-Y). |
| bulletin-board | 360 x 8 x 260 | Cork board in a wooden frame (empty cork; pictures get pinned on later in Roblox). Front -Y. |

Rules
- Budget: door ~2500, fan ~3500, hangar ~1500, cubby ~5000, board ~500 triangles.
- Look at each render yourself; fix what looks wrong (max 3 tries each).
- Only edit tools/art/toys.py and the five new folders under assets/models/toys/. Do not touch tools/art/hero.py or
  assets/models/_rebake. No uploads, no Roblox Studio, no git commits, never read or print .env.
- Report: functions added, measured sizes, triangle counts, render paths, anything still wrong.
