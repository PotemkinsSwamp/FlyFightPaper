-- So Close (docs/workshop/emotes/so-close.md; card OK'd by Alan 2026-11-22: "yes, cross-legged, sigh, keep the
-- glance"; the reference video OK'd with the glance added: "add the looking up at the first player part and then
-- going back to doing the shaking the head"). A runner-up, let down: one look at 1st, one big sigh that sags the
-- whole body, slow low head shakes, never sitting back up. Two clips, the same but for the side the head turns to:
-- SoCloseLeft looks to the kid's own left (1st on the picture's right), SoCloseRight to their right. Played once,
-- 12 s; the scene's module (src/client/emotes/SoClose.luau) sets the clip's time each frame so the look lands on
-- 1st's light.
-- The body is generated clip Nap B sitting still (Nap's N.rest, cross-legged, hands on the knees: the same seat).
-- By numbers, in this clip's seconds (SO below):
-- * all through, a breath every BREATH_EVERY seconds (the chest BREATH degrees);
-- * GLANCE_AT to +GLANCE_TURN the head turns GLANCE degrees to the side and the chest GLANCE_CHEST, held until the sag
--   takes it back to the front;
-- * the hands hang over the knees: IN of the way towards the other knee, OVER of the thigh's thickness up, the
--   elbows bent out to the side by OUT of the chest's width (with none the arm flipped over in a frame);
-- * the sigh: SIGH_AT to SAG_AT a small lift (chest LIFT degrees back, head LIFT_HEAD up), then over SAG seconds the
--   chest leans SLUMP degrees forward and the head drops HEAD_DOWN more; the hands go from the knees to hanging over
--   them;
-- * SHAKES: { start, seconds, degrees }: one slow "no" each (left, right, back to the middle, eased at both ends), the
--   head rolling ROLL of its turn with it (the video's head tips as it shakes).
local SO = { length = 12, BREATH_EVERY = 4, BREATH = 1.5, GLANCE_AT = 1.0, GLANCE_TURN = 0.6, GLANCE = 45, GLANCE_CHEST = 8,
	SIGH_AT = 2.1, SAG_AT = 2.5, SAG = 0.8, BACK = 0.6, LIFT = 4, LIFT_HEAD = 6, SLUMP = 20, HEAD_DOWN = 30, ROLL = 0.25, IN = 0.05, OVER = 0.7, OUT = 0.35,
	SHAKES = { { 3.3, 0.9, 18 }, { 4.2, 1.0, 16 }, { 5.2, 1.1, 14 }, { 9.0, 1.2, 10 } } }
SO.marks = { Glance = SO.GLANCE_AT, Sigh = SO.SIGH_AT, Sag = SO.SAG_AT }
local so -- this body's numbers, worked out once
function SO.work(c)
	if so then return so end
	local base = c.nap(N.rest)
	local at = build(base)
	so = { base = base, hands = {}, elbows = {}, rest = {}, pole = {}, low = {} }
	local knees = {}
	for _, side in { "Left", "Right" } do
		local hip, knee = (at.LowerTorso * joints[side .. "UpperLeg"].c0).Position, (at[side .. "UpperLeg"] * joints[side .. "LowerLeg"].c0).Position
		local up = Vector3.yAxis * 0.8 * (first[side .. "UpperLeg"].Size.X + first[side .. "UpperArm"].Size.X) / 2
		knees[side] = knee
		so.hands[side], so.elbows[side] = at[side .. "Hand"].Position, (at[side .. "UpperArm"] * joints[side .. "LowerArm"].c0).Position
		so.rest[side] = hip:Lerp(knee, 0.45) + up -- where the elbow rests: on top of the thigh
		-- which way the elbow bends: out to the side of that (the rest point alone lies nearly on the line from the
		-- shoulder to the hand, and the arm flipped over in a frame)
		so.pole[side] = so.rest[side] + Vector3.xAxis * (side == "Right" and 1 or -1) * SO.OUT * first.UpperTorso.Size.X
		so.low[side] = { hip = hip + up, knee = knee + up }
	end
	for _, side in { "Left", "Right" } do -- hanging: just past the knee, a little in towards the other
		local knee = knees[side]
		so.low[side].hand = knee + (knees[side == "Left" and "Right" or "Left"] - knee) * SO.IN + Vector3.new(0, SO.OVER * first[side .. "UpperLeg"].Size.X, -0.5 * first[side .. "Hand"].Size.Y)
	end
	-- (A search for the lean that rests the elbows on the thighs chose almost none: the slump went. So the lean is
	-- the card's.)
	so.lean = SO.SLUMP
	return so
end
function SO.reset() so = nil end -- for the number checks: work it out again after a number is changed
-- The pose at `t`; `side` 1 turns the head to the kid's left, -1 to their right.
function SO.pose(t, c, side)
	local w = SO.work(c)
	local sag = eased((t - SO.SAG_AT) / SO.SAG)
	local lift = t < SO.SAG_AT and eased((t - SO.SIGH_AT) / (SO.SAG_AT - SO.SIGH_AT)) or 1 - eased((t - SO.SAG_AT) / 0.5)
	local look = eased((t - SO.GLANCE_AT) / SO.GLANCE_TURN) * (1 - eased((t - SO.SAG_AT) / SO.BACK))
	local shake = 0
	for _, s in SO.SHAKES do
		local u = (t - s[1]) / s[2]
		if u > 0 and u < 1 then shake = s[3] * math.sin(2 * math.pi * eased(u)) end
	end
	local breath = SO.BREATH * math.sin(t / SO.BREATH_EVERY * 2 * math.pi)
	local turn = table.clone(w.base)
	turn.UpperTorso = w.base.UpperTorso * CFrame.Angles(-math.rad(w.lean * sag + breath - SO.LIFT * lift), math.rad(side * SO.GLANCE_CHEST * look), 0)
	local yaw = side * SO.GLANCE * look + shake
	turn.Head = CFrame.fromOrientation(-math.rad(SO.HEAD_DOWN * sag - SO.LIFT_HEAD * lift), math.rad(yaw), -math.rad(SO.ROLL * shake)) * w.base.Head
	for _, s in { "Left", "Right" } do
		reach(turn, s, w.hands[s]:Lerp(w.low[s].hand, sag), w.elbows[s]:Lerp(w.pole[s], sag))
	end
	return turn
end
CUTS.SoCloseLeft = { length = SO.length, once = true, marks = SO.marks, clips = { nap = N.clip }, pose = function(t, c) return SO.pose(t, c, 1) end }
CUTS.SoCloseRight = { length = SO.length, once = true, marks = SO.marks, clips = { nap = N.clip }, pose = function(t, c) return SO.pose(t, c, -1) end }
_G.SO_CLOSE = SO -- for the number checks (emote_preview.py --run)
