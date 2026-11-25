-- Doodler (docs/workshop/emotes/doodler.md; card OK'd by Alan 2026-11-24, the reference video OK'd the same day with
-- one pencil and the notebook turned round the right way). A runner-up lost in a daydream that they won: hunched over
-- a notebook on the lap, scribbling in short bursts; one look up at 1st, as someone drawing checks their model; head
-- down again; then they sit up tall and show the drawing, head tipped, pleased with themselves. Two clips, the same
-- but for the side the head turns to: DoodlerLeft looks to the kid's own left (1st on the picture's right),
-- DoodlerRight to their right. Played once, DD.length s; the scene's module (src/client/emotes/Doodler.luau) sets the
-- clip's time each frame so clip second DD.look is 1st's light, and does the arms, the notebook and the pencil: this
-- clip moves only the chest and the head. The seat and the arms underneath are generated clip Nap B sitting still
-- (Nap's N.rest, cross-legged: the same seat as Nap and So Close).
-- By numbers, in this clip's seconds:
-- * all through, a breath every BREATH_EVERY seconds (the chest BREATH degrees);
-- * hunched over the lap: the chest HUNCH degrees forward, the head DOWN more;
-- * LOOK to +LOOK_IN the chest comes up to LOOK_HUNCH and the head to LOOK_DOWN, turned LOOK degrees to the side
--   (the chest LOOK_CHEST), held until BACK, back down over BACK_IN;
-- * UP to +UP_IN the kid sits up tall: the chest TALL degrees back, the head TALL_DOWN (a little down, at the camera);
-- * TIP to +TIP_IN the head tips TIP degrees over, away from 1st, and stays so.
local DD = { length = 13, BREATH_EVERY = 4, BREATH = 1.5, HUNCH = 22, DOWN = 32,
	LOOK = 2.0, LOOK_IN = 0.5, LOOK_HUNCH = 8, LOOK_DOWN = -4, LOOK_TURN = 45, LOOK_CHEST = 8, BACK = 3.2, BACK_IN = 0.45,
	UP = 6.0, UP_IN = 0.6, TALL = -3, TALL_DOWN = 6, TIP = 8.0, TIP_IN = 0.7, TIP_BY = 18 }
DD.marks = { Look = DD.LOOK, Up = DD.UP }
-- The pose at `t`; `side` 1 turns the head to the kid's left, -1 to their right.
function DD.pose(t, c, side)
	local base = c.nap(N.rest)
	local look = eased((t - DD.LOOK) / DD.LOOK_IN) * (1 - eased((t - DD.BACK) / DD.BACK_IN))
	local up = eased((t - DD.UP) / DD.UP_IN)
	local tip = eased((t - DD.TIP) / DD.TIP_IN)
	local breath = DD.BREATH * math.sin(t / DD.BREATH_EVERY * 2 * math.pi)
	local hunch = DD.HUNCH + (DD.LOOK_HUNCH - DD.HUNCH) * look
	local down = DD.DOWN + (DD.LOOK_DOWN - DD.DOWN) * look
	hunch, down = hunch + (DD.TALL - hunch) * up, down + (DD.TALL_DOWN - down) * up
	local turn = table.clone(base)
	turn.UpperTorso = base.UpperTorso * CFrame.Angles(-math.rad(hunch + breath), math.rad(side * DD.LOOK_CHEST * look), 0)
	turn.Head = CFrame.fromOrientation(-math.rad(down), math.rad(side * DD.LOOK_TURN * look), -math.rad(side * DD.TIP_BY * tip)) * base.Head
	return turn
end
CUTS.DoodlerLeft = { length = DD.length, once = true, marks = DD.marks, clips = { nap = N.clip }, pose = function(t, c) return DD.pose(t, c, 1) end }
CUTS.DoodlerRight = { length = DD.length, once = true, marks = DD.marks, clips = { nap = N.clip }, pose = function(t, c) return DD.pose(t, c, -1) end }
_G.DOODLER = DD -- for the number checks (emote_preview.py --run)
