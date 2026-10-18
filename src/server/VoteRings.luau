-- The vote lap's rings (Alan 2026-10-17, docs/decisions/2026-10-17-rounds-never-stop.md): one row of three big paper
-- rings over each side of the room, one per mode. Fly through one to vote; each shows its mode and live vote count.
-- Spots and size: config rounds.vote_rings / vote_ring_radius. The look is the desks' landing ring, scaled up.
local Root = game.ReplicatedStorage.FlyFightPaper
local Rounds = require(Root.Generated.Gameplay).rounds
local MatchRules = require(Root.Shared.MatchRules)

local NAMES = { FFA = "Free-for-all", TDM = "Team dogfight", CONTROL = "Airspace Control" }
local TINTS = { FFA = Color3.fromRGB(120, 170, 255), TDM = Color3.fromRGB(255, 140, 190), CONTROL = Color3.fromRGB(130, 220, 140) }

local VoteRings = {}
VoteRings.__index = VoteRings
VoteRings.NAMES = NAMES

function VoteRings.new(room)
	return setmetatable({ room = room, rings = {} }, VoteRings)
end

function VoteRings:show()
	self:hide()
	local folder = Instance.new("Folder")
	folder.Name = "VoteRings"
	local template
	for _, item in self.room:GetDescendants() do
		if item:IsA("MeshPart") and item.Name:find("^landing%-ring") then template = item break end
	end
	local size = Rounds.vote_ring_radius * 2.25 -- the mesh's hole is about 0.9 of its width
	for i, spot in Rounds.vote_rings do
		local cframe = CFrame.new(spot.center[1], spot.center[2], spot.center[3])
		local ring = template and template:Clone() or Instance.new("Part")
		ring.Name, ring.Anchored, ring.CanCollide, ring.CanQuery, ring.CanTouch, ring.CastShadow = "VoteRing" .. i, true, false, false, false, false
		ring.Size, ring.CFrame = Vector3.new(size, size, template and size * 8 / 74 or 4), cframe
		if not template then ring.Shape, ring.Transparency = Enum.PartType.Cylinder, 0.6 end
		ring.Color = TINTS[spot.mode]
		for _, child in ring:GetChildren() do if not child:IsA("SurfaceAppearance") then child:Destroy() end end
		local sign = Instance.new("BillboardGui")
		sign.Name, sign.Size, sign.StudsOffsetWorldSpace, sign.LightInfluence = "Sign", UDim2.fromOffset(260, 90), Vector3.new(0, size * 0.62, 0), 0
		sign.MaxDistance, sign.AlwaysOnTop = 4000, false
		local words = Instance.new("TextLabel")
		words.Name, words.Size, words.BackgroundTransparency = "Words", UDim2.fromScale(1, 1), 1
		words.FontFace, words.TextScaled, words.TextColor3 = Font.fromEnum(Enum.Font.PermanentMarker), true, TINTS[spot.mode]
		words.TextStrokeColor3, words.TextStrokeTransparency = Color3.fromRGB(28, 26, 30), 0
		words.Parent, sign.Parent = sign, ring
		ring:SetAttribute("Mode", spot.mode)
		ring.Parent = folder
		self.rings[i] = { mode = spot.mode, cframe = cframe, words = words }
	end
	folder.Parent = self.room
	self.folder = folder
	self:update({})
end

function VoteRings:update(totals)
	for _, ring in self.rings do
		local count = totals[ring.mode] or 0
		ring.words.Text = string.format("%s\n%d %s", NAMES[ring.mode], count, count == 1 and "vote" or "votes")
	end
end

-- The mode whose ring the step from `from` to `to` went through, or nil.
function VoteRings:passed(from, to)
	for _, ring in self.rings do
		if MatchRules.throughRing(from, to, ring.cframe, Rounds.vote_ring_radius) then return ring.mode end
	end
	return nil
end

function VoteRings:hide()
	if self.folder then self.folder:Destroy() end
	self.folder, self.rings = nil, {}
end

return VoteRings
