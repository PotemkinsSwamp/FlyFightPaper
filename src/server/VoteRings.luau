-- The vote lap's rings (Alan 2026-10-17, docs/decisions/2026-10-17-rounds-never-stop.md, revised again): three giant
-- hula hoops in front of the window wall, facing the room, one per mode: bright plastic with glowing tape stripes.
-- (No free Creator Store hoop matched the look on 2026-10-18, so they are built from round parts.) Fly through one to vote; each has a big sign with
-- its mode and live vote count. Spots and size: config rounds.vote_rings / vote_ring_radius.
local Root = game.ReplicatedStorage.FlyFightPaper
local Rounds = require(Root.Generated.Gameplay).rounds
local MatchRules = require(Root.Shared.MatchRules)

local NAMES = { FFA = "Free-for-all", TDM = "Team dogfight", CONTROL = "Airspace Control" }
local TINTS = { FFA = Color3.fromRGB(70, 150, 255), TDM = Color3.fromRGB(255, 90, 170), CONTROL = Color3.fromRGB(80, 230, 110) }
local KEYS = { "FFA", "TDM", "CONTROL" } -- the 1 / 2 / 3 keys

local VoteRings = {}
VoteRings.__index = VoteRings
VoteRings.NAMES = NAMES

function VoteRings.new(room)
	return setmetatable({ room = room, rings = {} }, VoteRings)
end

local SEGMENTS, TUBE, STRIPE_EVERY = 48, 18, 4 -- a round plastic tube of short cylinders; every 4th is glowing tape

function VoteRings:show()
	self:hide()
	local folder = Instance.new("Folder")
	folder.Name = "VoteRings"
	local radius = Rounds.vote_ring_radius
	for i, spot in Rounds.vote_rings do
		local center = Vector3.new(spot.center[1], spot.center[2], spot.center[3])
		local cframe = CFrame.lookAt(center, Vector3.new(0, center.Y, 0)) -- faces the middle of the room
		local ring = Instance.new("Model")
		ring.Name = "VoteRing" .. i
		for k = 1, SEGMENTS do
			local angle = k / SEGMENTS * math.pi * 2
			local piece = Instance.new("Part")
			piece.Anchored, piece.CanCollide, piece.CanQuery, piece.CanTouch, piece.CastShadow = true, false, false, false, false
			piece.Shape = Enum.PartType.Cylinder
			local stripe = k % STRIPE_EVERY == 0
			piece.Material = stripe and Enum.Material.Neon or Enum.Material.SmoothPlastic
			piece.Color = stripe and TINTS[spot.mode]:Lerp(Color3.new(1, 1, 1), 0.55) or TINTS[spot.mode]
			piece.Size = Vector3.new(radius * 2 * math.pi / SEGMENTS * 1.08, TUBE, TUBE) -- a cylinder runs along X
			piece.CFrame = cframe * CFrame.new(math.cos(angle) * radius, math.sin(angle) * radius, 0) * CFrame.Angles(0, 0, angle + math.pi / 2)
			piece.Parent = ring
		end
		local sign = Instance.new("BillboardGui")
		sign.Name, sign.Size, sign.StudsOffsetWorldSpace, sign.LightInfluence = "Sign", UDim2.fromOffset(340, 120), Vector3.new(0, radius + 70, 0), 0
		sign.MaxDistance, sign.AlwaysOnTop = 5000, false
		local words = Instance.new("TextLabel")
		words.Name, words.Size, words.BackgroundTransparency = "Words", UDim2.fromScale(1, 1), 1
		words.FontFace, words.TextScaled, words.TextColor3 = Font.fromEnum(Enum.Font.PermanentMarker), true, TINTS[spot.mode]
		words.TextStrokeColor3, words.TextStrokeTransparency = Color3.fromRGB(28, 26, 30), 0
		local anchor = Instance.new("Part") -- an invisible dot in the middle that carries the sign
		anchor.Name, anchor.Size, anchor.CFrame, anchor.Transparency = "SignAnchor", Vector3.one, cframe, 1
		anchor.Anchored, anchor.CanCollide, anchor.CanQuery, anchor.CanTouch = true, false, false, false
		anchor.Parent = ring
		words.Parent, sign.Parent = sign, anchor
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
		ring.words.Text = string.format("%d  %s\n%d %s", table.find(KEYS, ring.mode), NAMES[ring.mode], count, count == 1 and "vote" or "votes")
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
