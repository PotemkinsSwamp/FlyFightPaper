-- So Close, a runner-up emote (docs/workshop/emotes/so-close.md; card and reference video OK'd by Alan 2026-11-22):
-- sitting cross-legged on the books, the kid looks over at 1st when 1st's light clicks on, sighs and sags, and shakes
-- their head slowly, low, never sitting back up. The body is one of two clips (tools/emote_cuts/so-close.lua), the same
-- but for which way the head turns: SoCloseLeft to the kid's own left (1st on the picture's right), SoCloseRight to
-- their right. Its time is set here every frame, so the look lands on 1st's light whatever this kid's place: clip
-- second GLANCE is 1st's light. 3rd holds the look HOLD_3RD seconds longer and then runs at SPEED_3RD, so if 2nd and
-- 3rd both play it they look at 1st together and are out of step after that.
-- The sound: the reference video's sigh (Alan: "the sigh that we can put into the sounds"), once, at SIGH (clip
-- seconds), as a runner-up's sound (cut if 1st's own sounds come first). It plays once "soCloseSigh" is in Audio.
local SoClose = {}
local LENGTH, GLANCE, HOLD_3RD, SPEED_3RD = 12, 1.0, 0.5, 0.92
local SIGH = 2.5 -- the exhale, as the body sags (the clip's mark Sag)
SoClose.sounds = { { "soCloseSigh", SIGH } } -- clip seconds (docs/workshop/emote-pipeline.md, "The emote module")

local function track(who, kit, side)
	local id = (kit.ourClip("SoClose" .. side))
	if not id then return nil end
	local animation = Instance.new("Animation"); animation.AnimationId = id
	local made = who.animator:LoadAnimation(animation)
	made.Looped, made.Priority = false, Enum.AnimationPriority.Action
	return made
end

function SoClose.start(kit, who)
	local st = { kit = kit, who = who, seat = kit.seatOn(who.cast, who.top), clip = track(who, kit, "Left") }
	-- the clip's own first pose from the dark on (both clips start the same); which side is known at the first step
	if st.clip then st.clip:Play(0, 1, 0) end
	-- the scene's start at this kid's light is not used: the time is set every frame below
	st.track, st.held = { Play = function() end, AdjustSpeed = function() end }, true
	return st
end

-- This kid's clip time `first` seconds after 1st's light.
local function clipTime(place, first)
	if place == 3 then
		local held = first - GLANCE -- after the look has landed (clip GLANCE + 1, the head at rest on 1st)
		return first < GLANCE and first + 1 or held < HOLD_3RD and GLANCE + 1 or GLANCE + 1 + (held - HOLD_3RD) * SPEED_3RD
	end
	return first + 1
end

function SoClose.step(st, since, _shot, steady, winners)
	local who = st.who
	if not st.side then
		local me, top = winners[who.place], winners[1]
		st.side = (me and top and me ~= top and (top.spot - me.spot):Dot(steady.RightVector) < 0) and "Right" or "Left"
		if st.side == "Right" then
			local right = track(who, st.kit, "Right")
			if right then
				if st.clip then st.clip:Stop(0) end
				st.clip = right
				right:Play(0, 1, 0)
			end
		end
	end
	local first = winners[1] and winners[1].since or since - (who.place - 1)
	local t = math.clamp(clipTime(who.place, first), 0, LENGTH - 0.01)
	if st.clip then st.clip.TimePosition = t end
	if not st.sighed and t >= SIGH then
		st.sighed = true
		if t < SIGH + 0.3 then st.kit.runnerSound("soCloseSigh") end
	end
	st.kit.sit(who.model, st.seat)
end

return SoClose
