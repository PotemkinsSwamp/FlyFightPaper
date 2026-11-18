-- Skins drawn on each player's own screen only (skins plan, "Keeping skins cheap"): the server marks a plane with a
-- Skin attribute; here every paper and trim piece of it swaps, on this screen, to its printed-sheet copy
-- (assets/models/planes/skin-sheet) wearing the skin's picture plus the piece's own creases. The server's pieces and
-- hitbox never change. Boosters wear it too. Skins cover the team stickers; tape and weapons keep their own look.
-- Skins that change the plane's shape (the Origami Crane) are fitted by SkinShapes. A Rare's moving layers are Decals over
-- the sheet, slid, turned and lit here (SkinMotion has the sums).
local AssetService = game:GetService("AssetService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local Looks = require(Root.Shared.LooksRules)
local SkinFit = require(Root.Shared.SkinFit)
local Pieces = require(Root:WaitForChild("Generated"):WaitForChild("SkinPieces")).pieces
local SkinShapes = require(script.Parent.SkinShapes)
local SkinMotion = require(Root.Shared.SkinMotion)
local PlaneLooks = {}
local meshes = {} -- piece -> MeshPart carrying the copy's mesh
local mine = Players.LocalPlayer and tostring(Players.LocalPlayer.UserId) -- nil when a server test loads the menus

-- One load per key, shared by every plane that asks at the same time (false = loading).
local function once(cache, key, make)
	while cache[key] == false do task.wait() end
	if cache[key] == nil then
		cache[key] = false
		local ok, made = pcall(make)
		if not ok then warn("PlaneLooks " .. key .. ": " .. tostring(made)) end
		cache[key] = ok and made or nil
	end
	return cache[key]
end
local function asset(id) return Content.fromUri("rbxassetid://" .. id) end

-- Rares move (skins plan, "Moving Rares"): every piece wearing one carries a Decal a layer, in the layers' order.
-- Each Decal projects from one face of a piece's box (SkinMotion.decal). Holographic foil also covers the underside.
local moving = {} -- piece -> { spec, look (its sheet), decals, piece (where its box lies on the sheet) }
local boxes = {} -- piece name -> SkinMotion.piece(...)
local function place(decal, bottom, layer, piece, a, b, tx, c, d, ty, solid, glow)
	if not a then
		decal.Transparency = 1
		if bottom then bottom.Transparency = 1 end
		return
	end
	local sx, sy, ox, oy, rot = SkinMotion.decal(piece, a, b, tx, c, d, ty)
	decal.UVScale, decal.UVOffset, decal.Rotation, decal.Transparency = Vector2.new(sx, sy), Vector2.new(ox, oy), rot, 1 - solid
	if layer.glow then decal.EmissiveStrength = glow end
	if bottom then
		-- Looking through the same piece from below reverses the box's V axis. Flip it about its centre
		-- before rotation so the same physical point catches the same colour and reflection on either face.
		bottom.UVScale, bottom.UVOffset = Vector2.new(sx, -sy), Vector2.new(ox, oy + sy)
		bottom.Rotation, bottom.Transparency = rot, 1 - solid
		if layer.glow then bottom.EmissiveStrength = glow end
	end
end
local function layersOn(part, name, skin, look)
	for _, old in part:GetChildren() do if old.Name == "SkinLayer" then old:Destroy() end end
	local spec = skin and SkinMotion.skins[skin.id]
	moving[part] = nil
	if not spec then return end
	local piece = boxes[name]
	if not piece then -- the piece as it sits on the plane the sheet was drawn for
		local made = Root.Assets.AircraftPieces:FindFirstChild(name, true)
		if not made then return end
		piece = SkinMotion.piece(made.CFrame, made.Size); boxes[name] = piece
	end
	-- Each layer's Decal (pictures, glow picture and colour) is made ahead by tools/art/skin_looks.py: a game script may
	-- not set a Decal's glow picture. Edit-mode tests have plugin rights and never see that; only real Play does.
	local ahead = Root.Assets.SkinLooks[skin.id].Layers
	local decals, undersides = {}, {}
	for i, layer in spec.layers do
		local decal = ahead[layer.name]:Clone()
		decal.Name = "SkinLayer"
		if skin.id == "holographic" then
			local bottom = decal:Clone()
			bottom.Face = Enum.NormalId.Bottom
			bottom.Parent = part
			undersides[i] = bottom
		end
		place(decal, undersides[i], layer, piece, SkinMotion.state(layer, 0))
		decal.Parent = part
		decals[i] = decal
	end
	local preview = part:FindFirstAncestorWhichIsA("ViewportFrame")
	moving[part] = { spec = spec, look = look, decals = decals, undersides = undersides, piece = piece,
		preview = preview, screen = preview and preview:FindFirstAncestorWhichIsA("ScreenGui") }
end
-- One pass a frame: each layer's place is worked out once, then given to every near piece that wears it. Far pieces keep
-- their layers standing still (Alan: planes are too fast to read a skin from far away).
local function move()
	local t, camera, now = os.clock(), workspace.CurrentCamera, {}
	if not camera then return end
	local eye = camera.CFrame.Position
	SkinShapes.step(t, eye, SkinMotion.near)
	for part, worn in moving do
		if not part.Parent then moving[part] = nil
		elseif (worn.preview and worn.preview.Visible and worn.screen and worn.screen.Enabled)
			or (not worn.preview and (part.Position - eye).Magnitude <= SkinMotion.near) then
			local spec = worn.spec
			if spec.glow and (spec.glow.pulse or spec.glow.flash) then worn.look.EmissiveStrength = SkinMotion.glow(spec.glow, t) end
			for i, layer in spec.layers do
				if layer.kind ~= "still" or (layer.glow and (layer.glow.pulse or layer.glow.flash)) then
					local set = now[layer]
					if not set then set = table.pack(SkinMotion.state(layer, t)); now[layer] = set end
					place(worn.decals[i], worn.undersides[i], layer, worn.piece, set[1], set[2], set[3], set[4], set[5], set[6], set[7], set[8])
				end
			end
		end
	end
end

local function skinOf(model)
	if model.Name == mine and PlaneLooks.devSkin ~= nil then return Looks.item(PlaneLooks.devSkin) end
	return Looks.item(model:GetAttribute("Skin"))
end

-- The printed sheet a plane's pieces wear now: its skin's id, or nil (no skin, or a skin with no picture yet).
local function sheetOf(model)
	local skin = skinOf(model)
	return skin and skin.picture and skin.id or nil, skin
end

local function isTeamMark(part)
	return part:GetAttribute("TeamSticker") or part:GetAttribute("Region") == "sticker"
end
local function dressPart(model, part)
	if isTeamMark(part) then
		-- Death and winner scenes clone Transparency and reset LocalTransparencyModifier. Restore from the
		-- paint job's authored value, even when this is the first time we see a respawned or cloned marker.
		local bare = part:GetAttribute("BareStickerTransparency")
		if bare == nil then bare = if part:GetAttribute("TeamSticker") then 0 else 1 end
		part.Transparency = if skinOf(model) then 1 else bare
		return true
	end
	local name = part:IsA("MeshPart") and string.match(part.Name, "^[^-]+%-(.+)$")
	local ids = name and Pieces[name]
	if not ids then return true end
	local want, skin = sheetOf(model)
	if part:GetAttribute("Skin") == want then return true end
	local mesh, face
	if want then
		mesh = once(meshes, name, function()
			return AssetService:CreateMeshPartAsync(asset(ids.mesh), { CollisionFidelity = Enum.CollisionFidelity.Box })
		end)
		-- Made ahead by tools/art/skin_looks.py: runtime-built looks need in-memory pictures (~4 MB each), too heavy.
		local made = Root:WaitForChild("Assets"):FindFirstChild("SkinLooks")
		face = made and made:FindFirstChild(want) and made[want]:FindFirstChild(name)
	else -- skin taken off: today's piece and its own (team-tinted) look
		local pieces = Root:FindFirstChild("Assets") and Root.Assets:FindFirstChild("AircraftPieces")
		mesh = pieces and pieces:FindFirstChild(name, true)
		face = mesh and mesh:FindFirstChildOfClass("SurfaceAppearance")
	end
	-- The plane may have been rebuilt or re-skinned while the copy loaded.
	if not (mesh and face and part.Parent and (sheetOf(model)) == want) then return false end
	local size = part.Size
	part:ApplyMesh(mesh)
	part.Size = size
	for _, old in part:GetChildren() do if old:IsA("SurfaceAppearance") then old:Destroy() end end
	local look = face:Clone()
	if not want then look.Color = part.Color end
	look.Parent = part
	part:SetAttribute("Skin", want)
	layersOn(part, name, want and skin or nil, look)
	return true
end

-- A Hangar photo is built once, with all of its plane parts already present. Finish fitting it before the caller
-- preloads the visible meshes and their cloned looks. Flying planes use the streaming path below.
function PlaneLooks.dressPreview(model, skinID)
	local appearance = model:FindFirstChild("Appearance")
	if not appearance or not model.Parent then return false end
	model:SetAttribute("Skin", skinID)
	local shape = SkinFit.shapes[skinID]
	if shape and not SkinShapes.wear(model, skinID) then return false end
	if not appearance.Parent then return false end
	local waitForParts = Instance.new("BindableEvent")
	local waiting, ok = 0, true
	for _, part in appearance:GetChildren() do
		if part:IsA("MeshPart") and (not part:GetAttribute("SkinHidden") or isTeamMark(part)) then
			-- PreloadAsync can fetch a MeshPart's texture. A SurfaceAppearance's processed PBR pack streams only
			-- while drawing. Give the photo's actual hull its matching base colour as well.
			if shape and shape.pictures and part.Name:match("^Skin%-") then
				part.TextureID = "rbxassetid://" .. shape.pictures.color
			end
			waiting += 1
			task.spawn(function()
				local ran, dressed = pcall(dressPart, model, part)
				if not ran or not dressed then ok = false end
				waiting -= 1
				if waiting == 0 then waitForParts:Fire() end
			end)
		end
	end
	if waiting > 0 then waitForParts.Event:Wait() end
	waitForParts:Destroy()
	return ok and appearance.Parent == model and model.Parent ~= nil
end

-- Shape skins (Legendary, Mythical: SkinShapes) go on once a burst of new parts has arrived, one fit at a time.
local busy = setmetatable({}, { __mode = "k" })
local function shape(model)
	if busy[model] then busy[model] = "again"; return end
	busy[model] = true
	task.spawn(function()
		repeat
			busy[model] = true
			task.wait(0.2)
			local skin = skinOf(model)
			if not (skin and SkinShapes.has(skin.id)) then SkinShapes.clear(model)
			elseif SkinShapes.wear(model, skin.id) then
				-- The moved booster's copies wear the sheet too, even when copied before their real part was dressed.
				for _, part in model.Appearance:GetChildren() do
					if string.match(part.Name, "^SkinBooster%-") then task.spawn(dressPart, model, part) end
				end
			end
		until busy[model] ~= "again" or not model.Parent
		busy[model] = nil
	end)
end

function PlaneLooks.dress(model)
	local appearance = model:FindFirstChild("Appearance")
	if not appearance then return end
	shape(model)
	for _, part in appearance:GetChildren() do task.spawn(dressPart, model, part) end
end

local function watch(model)
	local function appearance(child)
		if child.Name ~= "Appearance" then return end
		child.ChildAdded:Connect(function(part)
			if part:GetAttribute("SkinPiece") then return end -- a shape skin's own piece
			task.spawn(dressPart, model, part)
			local skin = skinOf(model)
			if skin and SkinShapes.has(skin.id) then shape(model) end
		end)
		PlaneLooks.dress(model)
	end
	model.ChildAdded:Connect(appearance)
	model:GetAttributeChangedSignal("Skin"):Connect(function() PlaneLooks.dress(model) end)
	local current = model:FindFirstChild("Appearance")
	if current then appearance(current) end
end

function PlaneLooks.start()
	RunService.RenderStepped:Connect(move)
	local planes = workspace:WaitForChild("Planes")
	planes.ChildAdded:Connect(watch)
	for _, model in planes:GetChildren() do watch(model) end
end

-- Studio dev button: wear a skin on your own plane without owning it (DevTools also tells the server, for hit shapes).
function PlaneLooks.setDevSkin(id)
	PlaneLooks.devSkin = id
	local plane = workspace:FindFirstChild("Planes") and workspace.Planes:FindFirstChild(mine)
	if plane then PlaneLooks.dress(plane) end
end

return PlaneLooks
