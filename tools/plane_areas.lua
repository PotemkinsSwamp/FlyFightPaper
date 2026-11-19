-- How big a target each plane build is, for skins that are the hitbox (the Dragon; Alan 2026-11-15: "scale up the skin
-- until it's the same ... surface area that would have been the plane"). A build's size = its outline seen from above,
-- from the side and from behind, added (square studs), measured on the same precise shapes the server hits
-- (HitShapes) with a 0.2-stud grid of rays. Body and wings are measured together; a nose or tail other than nose_0 /
-- tail_0 adds its difference (they sit ahead of and behind the wings, so they hardly overlap them).
-- Run in Studio's Edit (MCP execute_luau or the command bar), once per body, setting BODY; BODY = a whole-shape skin's id
-- ("dragon", "hot_rod", ...) measures its hit piece (or its one piece) at its uploaded size: that skin's even.area in
-- config/skin-shapes.json. Paste a body's JSON into config/plane-areas.json, then python tools/generate_config.py.
local BODY = "body_standard"
local AssetService = game:GetService("AssetService")
local HttpService = game:GetService("HttpService")
local Root = game.ReplicatedStorage.FlyFightPaper
local Aircraft = require(Root.Shared.Aircraft)
local Catalog = require(Root.Shared.Catalog)
local catalog = Catalog.new(require(Root.Generated.Catalog))
local STEP = 0.2
local precise = {}
local function solid(mesh)
	if not precise[mesh] then
		precise[mesh] = AssetService:CreateMeshPartAsync(Content.fromUri(mesh), { CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition })
	end
	return precise[mesh]:Clone()
end
-- pieces: { {mesh, size, cframe} }; returns the outline areas from above, the side and behind, added.
local function size(pieces)
	local world = Instance.new("WorldModel")
	world.Parent = game:GetService("ServerStorage")
	local lo, hi = Vector3.one * math.huge, -Vector3.one * math.huge
	for _, p in pieces do
		local part = solid(p[1])
		part.Size, part.CFrame, part.Anchored, part.CanQuery, part.Parent = p[2], p[3], true, true, world
		local c, s = part.CFrame, part.Size / 2
		for i = 0, 7 do
			local corner = c:PointToWorldSpace(s * Vector3.new(i % 2 * 2 - 1, math.floor(i / 2) % 2 * 2 - 1, math.floor(i / 4) * 2 - 1))
			lo, hi = lo:Min(corner), hi:Max(corner)
		end
	end
	local params = RaycastParams.new()
	params.FilterType, params.FilterDescendantsInstances = Enum.RaycastFilterType.Include, { world }
	local total = 0
	for _, view in { { "X", "Z", "Y" }, { "Z", "Y", "X" }, { "X", "Y", "Z" } } do -- above, side, behind
		local a, b, along = view[1], view[2], view[3]
		local count = 0
		for u = lo[a] + STEP / 2, hi[a], STEP do
			for v = lo[b] + STEP / 2, hi[b], STEP do
				local start = { X = 0, Y = 0, Z = 0 }
				start[a], start[b], start[along] = u, v, hi[along] + 1
				local dir = { X = 0, Y = 0, Z = 0 }
				dir[along] = lo[along] - hi[along] - 2
				if world:Raycast(Vector3.new(start.X, start.Y, start.Z), Vector3.new(dir.X, dir.Y, dir.Z), params) then count += 1 end
			end
		end
		total += count * STEP * STEP
	end
	world:Destroy()
	return math.floor(total * 100 + 0.5) / 100
end
local function build(body, nose, wings, tail)
	local loadout = catalog:classLoadout("fighter", 99)
	loadout.body, loadout.nose, loadout.wings, loadout.tail, loadout.weapon_mounts, loadout.utility = body, nose, wings, tail, {}, nil
	local model = Instance.new("Model")
	local rootPart = Instance.new("Part")
	rootPart.Name, rootPart.Anchored, rootPart.Parent = "Root", true, model
	assert(Aircraft.build(model, loadout, catalog, true))
	local pieces = {}
	for _, part in model.Appearance:GetChildren() do
		local slot = string.match(part.Name, "^(%a+)")
		if part:IsA("MeshPart") and part.Transparency < 1 and (slot == "body" or slot == "nose" or slot == "wings" or slot == "tail") then
			table.insert(pieces, { part.MeshId, part.Size, part.CFrame })
		end
	end
	model:Destroy()
	return size(pieces)
end
local skin = require(Root.Generated.SkinShapes).shapes[BODY]
if skin then
	local name = skin.hitPiece or next(skin.pieces)
	local piece = skin.pieces[name]
	local lo, hi = Vector3.new(table.unpack(piece.min)), Vector3.new(table.unpack(piece.max))
	return HttpService:JSONEncode({ [BODY] = size({ { "rbxassetid://" .. piece.mesh, hi - lo, CFrame.identity } }) })
end
local out = { wings = {}, nose = {}, tail = {} }
for i = 0, 5 do
	out.wings["wings_" .. i] = build(BODY, "nose_0", "wings_" .. i, "tail_0")
	task.wait()
end
local base = out.wings.wings_0
for i = 1, 5 do
	out.nose["nose_" .. i] = build(BODY, "nose_" .. i, "wings_0", "tail_0") - base
	out.tail["tail_" .. i] = build(BODY, "nose_0", "wings_0", "tail_" .. i) - base
	task.wait()
end
return HttpService:JSONEncode({ [BODY] = out })
