-- Whole-shape skins sized by the screen (Alan 2026-11-19): for each body and each skin with an even fit, the size at which
-- the drawn skin covers the same share of the 1280x720 chase view as the plain plane, with each wing (nose_0, tail_0),
-- then what each other nose and tail multiplies it by (on wings_0). Rays through every 4th pixel of the chase camera hit
-- the precise shapes of the plain plane's body, nose, wings and tail (within 1% of the drawn triangles), then of the
-- skin's drawn pieces (not its hidden hit copy) where SkinFit puts them, grown or shrunk about the same point (centred on
-- the plane, at its wing height) until the shares match. Stored as times "as wide as the plane", so a scaled plane (the
-- winners' stand) scales its skin with it. It starts from the length-or-wingspan size (an empty table), never from the
-- stored one.
-- Run in Studio's Edit (MCP execute_luau or the command bar), once per body, setting BODY (and SKINS to measure only a new
-- skin; ~20 s for a big body); merge the JSON into config/skin-sizes.json "skins", then python tools/generate_config.py.
local BODY = "body_standard"
local SKINS = nil -- e.g. { "dragon" }; nil = every skin with an even fit
local AssetService = game:GetService("AssetService")
local HttpService = game:GetService("HttpService")
local Root = game.ReplicatedStorage.FlyFightPaper
local function fresh(module) -- Edit mode caches require: read the synced source through a clone
	local copy = module:Clone()
	copy.Parent = Root.Shared
	local ok, result = pcall(require, copy)
	copy:Destroy()
	return assert(ok and result, result)
end
local Aircraft = fresh(Root.Shared.Aircraft)
local SkinFit
do -- SkinFit reading an empty size table
	local empty = Instance.new("ModuleScript")
	empty.Name, empty.Source, empty.Parent = "SkinSizesEmpty", "return { skins = {} }", Root.Generated
	local copy = Root.Shared.SkinFit:Clone()
	copy.Source = string.gsub(copy.Source, '"SkinSizes"', '"SkinSizesEmpty"')
	SkinFit = fresh(copy)
	empty:Destroy()
end
local catalog = require(Root.Shared.Catalog).new(require(Root.Generated.Catalog))
local W, H, STEP = 1280, 720, 4
local F = Vector3.new(0, 2, 0) -- the chase camera, behind and above the plane (Root at the origin, nose to -z)
local CAMERA = CFrame.lookAt(F + Vector3.new(0, 6, 24), F + Vector3.new(0, 0, -60))
local TAN, ASPECT = math.tan(math.rad(72) / 2), W / H -- 72 degrees up and down

local precise = {}
local function solid(mesh)
	if not precise[mesh] then
		precise[mesh] = AssetService:CreateMeshPartAsync(Content.fromUri(mesh), { CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition })
	end
	return precise[mesh]:Clone()
end

-- pieces: { {mesh, size, cframe} }; the share of the chase view they cover.
local function share(pieces)
	local world = Instance.new("WorldModel")
	world.Parent = game:GetService("ServerStorage")
	local x0, y0, x1, y1 = W, H, 0, 0
	for _, p in pieces do
		local part = solid(p[1])
		part.Size, part.CFrame, part.Anchored, part.CanQuery, part.Parent = p[2], p[3], true, true, world
		for i = 0, 7 do
			local corner = part.Size / 2 * Vector3.new(i % 2 * 2 - 1, math.floor(i / 2) % 2 * 2 - 1, math.floor(i / 4) * 2 - 1)
			local c = CAMERA:PointToObjectSpace(part.CFrame:PointToWorldSpace(corner))
			local sx, sy = (1 + c.X / -c.Z / (TAN * ASPECT)) * W / 2, (1 - c.Y / -c.Z / TAN) * H / 2
			x0, y0, x1, y1 = math.min(x0, sx), math.min(y0, sy), math.max(x1, sx), math.max(y1, sy)
		end
	end
	local params = RaycastParams.new()
	params.FilterType, params.FilterDescendantsInstances = Enum.RaycastFilterType.Include, { world }
	local hits = 0
	for px = math.max(0, math.floor(x0 / STEP)) * STEP + STEP / 2, math.min(W, x1), STEP do
		for py = math.max(0, math.floor(y0 / STEP)) * STEP + STEP / 2, math.min(H, y1), STEP do
			local dir = CAMERA:VectorToWorldSpace(Vector3.new((2 * px / W - 1) * TAN * ASPECT, (1 - 2 * py / H) * TAN, -1))
			if world:Raycast(CAMERA.Position, dir.Unit * 200, params) then hits += 1 end
		end
	end
	world:Destroy()
	return hits * STEP * STEP / (W * H)
end

local function plane(body, nose, wings, tail)
	local loadout = catalog:classLoadout("fighter", 99)
	loadout.body, loadout.nose, loadout.wings, loadout.tail, loadout.weapon_mounts, loadout.utility = body, nose, wings, tail, {}, nil
	local model = Instance.new("Model")
	local rootPart = Instance.new("Part")
	rootPart.Name, rootPart.Anchored, rootPart.Parent = "Root", true, model
	assert(Aircraft.build(model, loadout, catalog, true))
	return model
end

local function plain(model)
	local pieces = {}
	for _, part in model.Appearance:GetChildren() do
		local slot = string.match(part.Name, "^(%a+)")
		if part:IsA("MeshPart") and part.Transparency < 1 and (slot == "body" or slot == "nose" or slot == "wings" or slot == "tail") then
			table.insert(pieces, { part.MeshId, part.Size, part.CFrame })
		end
	end
	return pieces
end

-- Skin `id`'s drawn pieces on `model`, `m` times the size SkinFit draws it at.
local function skin(id, model, m)
	local shape = SkinFit.shapes[id]
	local o = SkinFit.outline(model.Appearance, CFrame.identity)
	local fitted = SkinFit.plane(id, model.Appearance, CFrame.identity)
	local anchor = Vector3.new(0, o.wy, (o.zN + o.zT) / 2) -- evenFit grows the skin about this point
	local pieces = {}
	for name, at in fitted.placed do
		if name == shape.hitPiece then continue end
		table.insert(pieces, { "rbxassetid://" .. shape.pieces[name].mesh, at[2] * m, CFrame.new(anchor + (at[1].Position - anchor) * m) })
	end
	return pieces
end

-- The size multiple m (on what SkinFit draws now) whose share is `target`: share grows about as m^e, e from the last two
-- (up to m^5 for a long skin: its back end nears the camera).
local function solve(id, model, target)
	local m, s = 1, share(skin(id, model, 1))
	local mWas, sWas
	for _ = 1, 8 do
		if math.abs(s / target - 1) < 0.005 then break end
		local e = mWas and mWas ~= m and math.log(s / sWas) / math.log(m / mWas) or 2
		if not (e > 0.5 and e < 10) then e = 2 end
		mWas, sWas = m, s
		m *= (target / s) ^ (1 / e)
		s = share(skin(id, model, m))
		task.wait()
	end
	return m, s
end

-- How many times "as wide as the plane" skin `id` is drawn on `model` when it covers `target`.
local function size(id, model, target)
	local m, s = solve(id, model, target)
	local shape, o = SkinFit.shapes[id], SkinFit.outline(model.Appearance, CFrame.identity)
	local name, piece = next(shape.pieces)
	local now = SkinFit.plane(id, model.Appearance, CFrame.identity).placed[name][2].X / (piece.max[1] - piece.min[1])
	return now * m / (o.xo / shape.even.half_span), s
end
local function round(x) return math.floor(x * 1000 + 0.5) / 1000 end

local ids = SKINS or {}
if not SKINS then for id, shape in SkinFit.shapes do if shape.even then table.insert(ids, id) end end end
table.sort(ids)
local out, shares = {}, {}
for _, id in ids do out[id] = { [BODY] = { wings = {}, nose = {}, tail = {} } } end
for _, mix in { "wings_0", "wings_1", "wings_2", "wings_3", "wings_4", "wings_5", "nose_1", "nose_2", "nose_3", "nose_4",
	"nose_5", "tail_1", "tail_2", "tail_3", "tail_4", "tail_5" } do
	local slot = string.match(mix, "^(%a+)")
	local model = plane(BODY, slot == "nose" and mix or "nose_0", slot == "wings" and mix or "wings_0", slot == "tail" and mix or "tail_0")
	local target = share(plain(model))
	shares[mix] = { plain = math.floor(target * 1e4 + 0.5) / 100 }
	for _, id in ids do
		local k, s = size(id, model, target)
		local row = out[id][BODY]
		row[slot][mix] = round(slot == "wings" and k or k / row.wings.wings_0) -- a nose or tail: times wings_0's size
		shares[mix][id] = math.floor(s * 1e4 + 0.5) / 100
	end
	model:Destroy()
	task.wait()
end
return HttpService:JSONEncode({ sizes = out, shares = shares }) -- shares: % of the screen, plain and each skin at its size
