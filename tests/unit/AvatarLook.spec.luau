local Root = game.ReplicatedStorage.FlyFightPaper
local AvatarLook = require(Root.Shared.AvatarLook)
local Suite = require(script.Parent.Parent.fixtures.Suite)
local Spec = {}

local function worn(description)
	local types = {}
	for _, piece in description:GetAccessories(true) do types[piece.AccessoryType.Name] = (types[piece.AccessoryType.Name] or 0) + 1 end
	return types
end

function Spec.run()
	local result, test = Suite.new()
	test("AL1 body clothing comes off; hair, shoes and hats stay", function()
		local description = Instance.new("HumanoidDescription")
		description:SetAccessories({
			{ Order = 1, AssetId = 11, AccessoryType = Enum.AccessoryType.Jacket, IsLayered = true },
			{ Order = 2, AssetId = 12, AccessoryType = Enum.AccessoryType.Pants, IsLayered = true },
			{ Order = 3, AssetId = 13, AccessoryType = Enum.AccessoryType.Hair, IsLayered = true },
			{ Order = 4, AssetId = 14, AccessoryType = Enum.AccessoryType.LeftShoe, IsLayered = true },
			{ AssetId = 15, AccessoryType = Enum.AccessoryType.Hat },
		}, true)
		description.Shirt = 21
		local same = AvatarLook.trim(description)
		local types = worn(description)
		assert(same == description, "trim returns the description it was given")
		assert(not types.Jacket and not types.Pants, "the jacket and the 3D pants are gone")
		assert(types.Hair == 1 and types.LeftShoe == 1 and types.Hat == 1, "hair, shoe and hat are kept")
		assert(description.Shirt == 21, "the painted-on shirt is kept")
	end)
	test("AL2 an avatar without 3D clothing is left as it is", function()
		local description = Instance.new("HumanoidDescription")
		description:SetAccessories({ { AssetId = 15, AccessoryType = Enum.AccessoryType.Hat } }, true)
		AvatarLook.trim(description)
		assert(worn(description).Hat == 1)
	end)
	return result
end

return Spec
