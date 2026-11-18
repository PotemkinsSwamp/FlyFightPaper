-- Legendary and Mythical skins that change the plane's shape (skins plan): one model cut into a few pieces, each placed
-- and sized from this plane's own parts, on each player's screen only. The real body, nose, wings and tail hide under it;
-- guns move under the wings (Alan 2026-11-13: nothing on top of a Mythical) and the booster up against the belly. The
-- measuring and fitting is shared with the server (src/shared/SkinFit.luau), which turns the wings' hit and crash shapes
-- and moves the guns' and booster's to match; the plane's flight and where shots leave never change.
local AssetService = game:GetService("AssetService")
local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local SkinFit = require(Root:WaitForChild("Shared"):WaitForChild("SkinFit"))
local NinjaMotion = require(script.Parent.NinjaMotion)
local Shapes = SkinFit.shapes
local SkinShapes = {}
local meshes = {} -- mesh id -> MeshPart to copy (false while loading)

SkinShapes.has = SkinFit.has
SkinShapes.step = NinjaMotion.step

local function meshOf(id)
	while meshes[id] == false do task.wait() end
	if meshes[id] == nil then
		meshes[id] = false
		local ok, made = pcall(function()
			return AssetService:CreateMeshPartAsync(Content.fromUri("rbxassetid://" .. id), { CollisionFidelity = Enum.CollisionFidelity.Box })
		end)
		if not ok then warn("SkinShapes mesh " .. id .. ": " .. tostring(made)) end
		meshes[id] = ok and made or nil
	end
	return meshes[id]
end

-- A Rojo sync can deliver the bone hierarchy before the template's mesh content.
-- Load the actual asset in that case, keeping the bind frames from the template.
local function rigPiece(template, id, needsBones)
	local expected = "rbxassetid://" .. id
	if not needsBones and template.MeshId == expected then return template:Clone() end
	local loaded = meshOf(id)
	if not loaded then return nil end
	local part = loaded:Clone()
	if needsBones then
		for _, child in part:GetChildren() do
			if child:IsA("Bone") then child:Destroy() end
		end
		for _, child in template:GetChildren() do
			if child:IsA("Bone") then child:Clone().Parent = part end
		end
	end
	return part
end

-- Take the shape off: the real parts, guns and booster come back, the pieces and moved copies go.
function SkinShapes.clear(model)
	NinjaMotion.clear(model)
	local appearance = model:FindFirstChild("Appearance")
	if not appearance then return end
	for _, part in appearance:GetChildren() do
		if part:GetAttribute("SkinPiece") then part:Destroy()
		elseif part:GetAttribute("SkinHidden") then
			part.LocalTransparencyModifier = 0
			part:SetAttribute("SkinHidden", nil)
		end
	end
	for slot = 1, 8 do model:SetAttribute("SkinGunMove" .. slot, nil) end
end

-- Put shape `id` on `model` (a flying plane or the hangar photo). Returns false if the plane's parts aren't there yet.
function SkinShapes.wear(model, id)
	SkinShapes.clear(model)
	local shape, appearance = Shapes[id], model:FindFirstChild("Appearance")
	if not (shape and appearance) then return false end
	local rootPart = model:FindFirstChild("Root")
	local frame = rootPart and rootPart.CFrame or CFrame.identity
	local fitted = SkinFit.plane(id, appearance, frame) -- the same fit the server's hit and crash shapes use
	if not fitted then return false end
	-- Its look is made ahead (tools/art/skin_looks.py writes SkinLooks/<id>/Shape): scripts can't set a look's pictures.
	local assets = Root:WaitForChild("Assets")
	local looks = assets:FindFirstChild("SkinLooks")
	local look = looks and looks:FindFirstChild(id) and looks[id]:FindFirstChild("Shape")
	local rig = shape.rig and assets:WaitForChild(shape.rig, 5)
	if shape.rig and not rig then return false end
	local pieces = {}
	local preview = rootPart == nil or (appearance:FindFirstChildWhichIsA("BasePart") and appearance:FindFirstChildWhichIsA("BasePart").Anchored)
	local function attach(part, cf)
		part.CFrame = frame * cf
		part.Anchored, part.Massless, part.CanCollide, part.CanQuery, part.CanTouch, part.CastShadow = preview, true, false, false, false, true
		part.Parent = appearance
		if rootPart and not preview then
			local weld = Instance.new("WeldConstraint")
			weld.Part0, weld.Part1, weld.Parent = rootPart, part, part
		end
	end
	for name, at in fitted.placed do
		if name == shape.hitPiece then continue end
		local part, template
		if rig then
			template = rig:WaitForChild(name, 5)
			if template and template:IsA("MeshPart") then
				part = rigPiece(template, shape.pieces[name].mesh, name == "body")
			end
			if not (part and model.Parent and appearance.Parent) then
				if part then part:Destroy() end
				SkinShapes.clear(model)
				return false
			end
		else
			local mesh = meshOf(shape.pieces[name].mesh)
			if not (mesh and model.Parent and appearance.Parent) then continue end
			part = mesh:Clone()
		end
		part.Name = "Skin-" .. name
		if template and name == "body" then
			NinjaMotion.fitBones(part, template, at[2])
		else
			part.Size = at[2]
		end
		part:SetAttribute("SkinPiece", true)
		if look then look:Clone().Parent = part end
		attach(part, at[1])
		pieces[name] = part
	end
	if id == "ninja" then
		local foil = looks and looks:FindFirstChild("holographic")
		local layers = foil and foil:FindFirstChild("Layers")
		NinjaMotion.wear(model, rootPart, pieces, shape, layers and layers:FindFirstChild("glint"), preview)
	end
	-- Hide what the shape covers; guns hang under the wings and the booster tucks up to the belly (SkinFit.plane): the real
	-- part hides, a copy (with its look, PlaneLooks dresses late ones) shows at the new spot.
	for _, part in appearance:GetChildren() do
		local slot = part:IsA("BasePart") and not part:GetAttribute("SkinPiece") and string.match(part.Name, "^(%a+)")
		if slot == "body" or slot == "nose" or slot == "wings" or slot == "tail" then
			part.LocalTransparencyModifier = 1
			part:SetAttribute("SkinHidden", true)
		end
	end
	for mount, offset in fitted.offsets do model:SetAttribute("SkinGunMove" .. mount, offset) end -- the drawn bullet starts from the gun you see
	for _, moves in { fitted.guns, fitted.boosters } do
		for part, move in moves do
			if part.Parent ~= appearance then continue end -- rebuilt while the pieces loaded
			local copy = part:Clone()
			for _, child in copy:GetChildren() do if child:IsA("WeldConstraint") then child:Destroy() end end
			copy.Name = "Skin" .. part.Name -- "SkinBooster-boost_twin-paper-L": PlaneLooks finds the piece's printed copy by name
			copy:SetAttribute("SkinPiece", true)
			copy.LocalTransparencyModifier = 0
			part.LocalTransparencyModifier = 1
			part:SetAttribute("SkinHidden", true)
			attach(copy, move * frame:ToObjectSpace(part.CFrame))
		end
	end
	return true
end

return SkinShapes
