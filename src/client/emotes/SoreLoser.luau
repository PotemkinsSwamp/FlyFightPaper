-- Sore Loser, a runner-up emote (docs/workshop/emotes/sore-loser.md; card and reference video OK'd by Alan
-- 2026-11-24): standing on the books turned away from 1st, arms crossed, chin up; the head creeps round to peek at
-- 1st and snaps back as if caught. Silent. The body is one of two clips (tools/emote_cuts/sore-loser.lua), the same
-- but for the side: SoreLoserLeft for 1st on the kid's own left (1st on the picture's right), SoreLoserRight the
-- mirror. Its time is set here every frame from 1st's light (clip second 1.0 is 1st's light), so the peeks follow
-- the winner's moment whatever this kid's place; 3rd runs LATE_3RD seconds behind 2nd, so if both play it they do
-- not peek as mirror images.
local SoreLoser = {}
local LENGTH, LIGHT, LATE_3RD = 12, 1.0, 0.6

local function track(who, kit, side)
	local id = (kit.ourClip("SoreLoser" .. side))
	if not id then return nil end
	local animation = Instance.new("Animation"); animation.AnimationId = id
	local made = who.animator:LoadAnimation(animation)
	made.Looped, made.Priority = false, Enum.AnimationPriority.Action
	return made
end

function SoreLoser.start(kit, who)
	local st = { kit = kit, who = who, clip = track(who, kit, "Left") }
	-- held on its first pose from the dark on (turned away, arms crossed); which side is known at the first step
	if st.clip then st.clip:Play(0, 1, 0) end
	-- the scene's start at this kid's light is not used: the time is set every frame below
	st.track, st.held = { Play = function() end, AdjustSpeed = function() end }, true
	return st
end

function SoreLoser.step(st, since, _shot, steady, winners)
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
	local t = first + LIGHT - (who.place == 3 and LATE_3RD or 0)
	if st.clip then st.clip.TimePosition = math.clamp(t, 0, LENGTH - 0.01) end
end

return SoreLoser
