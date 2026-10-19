# Codex image job: tutorial "look here" highlight frame and direction arrow (2026-10-18)

The game is a kids' paper-plane game in a classroom; its screen art is torn paper, masking tape and wax crayon.
Look first at `assets/references/ui-concepts/hud-concept-2.png` (the approved screen look) and
`assets/ui/hud/contact-sheet.png` (the paper pieces we already have). Match that look exactly.

The tutorial must pull a new player's eyes to the ONE thing to do, "in your face". We need concept art for:
1. **The highlight frame**: drawn around the target. A thick, bright, hand-drawn crayon outline (yellow/orange with a
   darker edge so it reads on any background), a little uneven like a child drew it, with short crayon "look here"
   burst marks around it. It must work around a rectangle (a button) and around a round thing (a hoop in the sky).
2. **A label tag** that sits under the frame: a small torn yellow paper tag, taped, reading "FLY HERE 120".
3. **The direction arrow**: one BIG chunky arrow made of folded/cut paper with a crayon outline, floating in front
   of the player's paper plane, pointing toward a target that is off the screen to the right.
4. **The guide line**: a dotted crayon line (like a dashed trail drawn with a crayon) from the plane toward the target.

## Make (16:9, at least 1536 wide), saved to `assets/references/ui-concepts/`
| File | Content |
|---|---|
| attention-a.png | Flying in the classroom (like hud-concept-2 but with fewer HUD pieces): the WHOLE screen is darkened except a bright round hole around a paper hoop ahead; the hoop has the glowing crayon frame and the "FLY HERE 120" tag. A second hoop is faintly visible behind it. |
| attention-b.png | Same scene, the target is off screen to the right: the big paper arrow in front of the plane points right, the dotted crayon guide line runs off the right edge, screen slightly darkened. |
| attention-c.png | The plane sitting on a school desk before take-off: screen darkened except a bright rectangle hole around a big "LAUNCH" button at the bottom middle, which has the crayon frame and burst marks. |
| attention-pieces.png | Model sheet on plain flat grey (#808080): the frame around a rectangle, the frame around a circle, the tag (blank, no text), the big arrow pointing right. Each piece alone with space around it. |

Rules: Codex image generation only (no Meshy, no uploads, no Studio, no git commits, never read .env). Only write the
four files above. No weapon words in prompts. Look at each image yourself and redo (max 3 tries each) any where:
the dim is missing or the hole is not clearly the brightest part; the frame looks like a clean computer shape instead
of crayon; the arrow is small; any shape could read as a hate symbol (no crossed or bent-arm shapes). Report each file
and one line on it.
