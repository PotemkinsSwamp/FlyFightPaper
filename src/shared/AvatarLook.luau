-- How a player's or bot's avatar is slimmed before our game builds its copy of them (the kid at the desk, on the
-- winners' stand and on the emote shop's TV). Alan 2026-11-25: 3D clothing can be several times wider than the body
-- (his own jacket: 5.4 studs across on a 1.1 stud torso) and hides the emotes; other games take it off and you still
-- look like you. Only the 3D ("layered") clothing worn on the body goes; hair, shoes, hats, faces, the body itself
-- and painted-on shirts and pants stay.
local AvatarLook = {}

-- The layered clothing types that wrap the body (Enum.AccessoryType names).
AvatarLook.BODY_CLOTHING = { Jacket = true, Sweater = true, Shirt = true, TShirt = true, Pants = true, Shorts = true, DressSkirt = true }

-- Takes the body's 3D clothing off a HumanoidDescription, in place, and returns it.
function AvatarLook.trim(description)
	local kept, removed = {}, false
	for _, piece in description:GetAccessories(false) do -- (false: the layered pieces only)
		if AvatarLook.BODY_CLOTHING[piece.AccessoryType.Name] then removed = true else table.insert(kept, piece) end
	end
	if removed then description:SetAccessories(kept, false) end
	return description
end

return AvatarLook
