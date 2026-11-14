-- Skins drawn on each player's own screen only (skins plan, "Keeping skins cheap"): the server marks a plane with a
-- Skin attribute; here every paper and trim piece of it swaps, on this screen, to its printed-sheet copy
-- (assets/models/planes/skin-sheet) wearing the skin's picture plus the piece's own creases. The server's pieces and
-- hitbox never change. Boosters wear it too; pieces with no copy (tape, team stickers, weapons) keep their own look.
local AssetService = game:GetService("AssetService")
local Players = game:GetService("Players")
local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local Looks = require(Root.Shared.LooksRules)
local Pieces = require(Root:WaitForChild("Generated"):WaitForChild("SkinPieces")).pieces
local PlaneLooks = {}
local meshes = {} -- piece -> MeshPart carrying the copy's mesh
local mine = tostring(Players.LocalPlayer.UserId)

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

local function skinOf(model)
	if model.Name == mine and PlaneLooks.devSkin ~= nil then return Looks.item(PlaneLooks.devSkin) end
	return Looks.item(model:GetAttribute("Skin"))
end

local function dressPart(model, part)
	local name = part:IsA("MeshPart") and string.match(part.Name, "^[^-]+%-(.+)$")
	local ids = name and Pieces[name]
	local skin = ids and skinOf(model)
	local want = skin and skin.picture and skin.id or nil
	if not ids or part:GetAttribute("Skin") == want then return end
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
	if not (mesh and face and part.Parent and (skinOf(model) and skinOf(model).id) == want) then return end
	local size = part.Size
	part:ApplyMesh(mesh)
	part.Size = size
	for _, old in part:GetChildren() do if old:IsA("SurfaceAppearance") then old:Destroy() end end
	local look = face:Clone()
	if not want then look.Color = part.Color end
	look.Parent = part
	part:SetAttribute("Skin", want)
end

function PlaneLooks.dress(model)
	local appearance = model:FindFirstChild("Appearance")
	if not appearance then return end
	for _, part in appearance:GetChildren() do task.spawn(dressPart, model, part) end
end

local function watch(model)
	local function appearance(child)
		if child.Name ~= "Appearance" then return end
		child.ChildAdded:Connect(function(part) task.spawn(dressPart, model, part) end)
		PlaneLooks.dress(model)
	end
	model.ChildAdded:Connect(appearance)
	model:GetAttributeChangedSignal("Skin"):Connect(function() PlaneLooks.dress(model) end)
	local current = model:FindFirstChild("Appearance")
	if current then appearance(current) end
end

function PlaneLooks.start()
	local planes = workspace:WaitForChild("Planes")
	planes.ChildAdded:Connect(watch)
	for _, model in planes:GetChildren() do watch(model) end
end

-- Studio dev button: wear a skin on your own plane without owning it (only your screen sees it).
function PlaneLooks.setDevSkin(id)
	PlaneLooks.devSkin = id
	local plane = workspace:FindFirstChild("Planes") and workspace.Planes:FindFirstChild(mine)
	if plane then PlaneLooks.dress(plane) end
end

return PlaneLooks
