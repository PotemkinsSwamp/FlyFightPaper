-- Weapons move when they fire (Stage 8). Each launcher piece carries a Role from tools/art/weapons.py: "fire" and
-- "drop" leave with the shot and slide back in on reload, "spin" turns about Axis through Pivot while firing (gatling
-- drum, crank), "hinge" swings (staple lever), "slide" moves along Axis (staple strip), "snap" springs forward
-- (slingshot band). The welded original stays put and is hidden on this client; a local copy is drawn moved.
local RunService = game:GetService("RunService")
local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local Catalog = require(Root.Shared.Catalog).new(require(Root.Generated.Catalog), require(Root.Generated.Gameplay))
local Deaths = require(script.Parent.PlaneDeaths)

local SPIN_TURNS_PER_SECOND = 3
local HINGE_DEGREES = 40
local SLIDE_STUDS = 0.3
local SNAP_STUDS = 0.6
local SHOWN = { FLYING = true, TAKEOFF = true, LANDING = true }

local Motion = {}
local planes = {} -- model -> { key, pieces = { {original, copy, role, slot, pivot, axis, side, factor, rest} }, fired = {slot -> time}, spin = {slot -> angle, rate} }
local folder

local function vector(text)
	if not text then return nil end
	local x, y, z = string.match(text, "([^,]+),([^,]+),([^,]+)")
	return Vector3.new(tonumber(x), tonumber(y), tonumber(z))
end

-- Seconds between this weapon's shots: what a piece has to reload in.
local function reload(weaponId)
	local weapon = weaponId and Catalog:get(weaponId)
	return weapon and (weapon.burst_spacing or weapon.shot_interval or weapon.burst_period) or 0.5
end

local function track(model)
	local appearance, body = model:FindFirstChild("Appearance"), model:FindFirstChild("Root")
	local launchers = Root.Assets:FindFirstChild("AircraftPieces")
	local key = appearance and tostring(model:GetAttribute("Mounts"))
	local entry = planes[model]
	if entry and entry.key == key and entry.appearance == appearance then return entry end
	if entry then for _, piece in ipairs(entry.pieces) do piece.copy:Destroy() end end
	entry = { key = key, appearance = appearance, pieces = {}, fired = entry and entry.fired or {}, spin = {} }
	planes[model] = entry
	if not appearance or not body or not launchers then return entry end
	local ids = string.split(model:GetAttribute("Mounts") or "", ",")
	for _, part in ipairs(appearance:GetChildren()) do
		local slot, name = string.match(part.Name, "^Mount(%d+)%-(.+)$")
		slot = tonumber(slot)
		local launcher = slot and ids[slot] and launchers:FindFirstChild("launcher_" .. ids[slot])
		local template = launcher and launcher:FindFirstChild(name)
		local role = template and template:GetAttribute("Role")
		if part:IsA("BasePart") and role and role ~= "static" then
			local copy = part:Clone()
			for _, child in ipairs(copy:GetChildren()) do
				if not (child:IsA("SurfaceAppearance") or child:IsA("Decal") or child:IsA("Texture")) then child:Destroy() end
			end
			copy.Anchored, copy.CanCollide, copy.CanQuery, copy.CanTouch = true, false, false, false
			copy.Parent = folder
			local side = slot % 2 == 1 and 1 or -1
			local factor = part.Size.X / template.Size.X
			local rest = body.CFrame:ToObjectSpace(part.CFrame)
			-- Pivot and Axis are in the launcher's own frame (left mount); the right mount mirrors X.
			local mirror = function(v) return Vector3.new(side * v.X, v.Y, v.Z) end
			local pivot = vector(template:GetAttribute("Pivot"))
			table.insert(entry.pieces, { original = part, copy = copy, role = role, slot = slot, weapon = ids[slot], side = side, rest = rest,
				pivot = pivot and rest.Position + mirror(pivot - template.Position) * factor,
				axis = vector(template:GetAttribute("Axis")) and mirror(vector(template:GetAttribute("Axis")).Unit), factor = factor })
		end
	end
	return entry
end

-- 0 -> 1 quickly on the shot, then back to 0 over most of the reload.
local function pulse(t, interval)
	if t < 0.05 then return t / 0.05 end
	return math.max(0, 1 - (t - 0.05) / math.max(0.05, interval * 0.6))
end

local function pose(entry, piece, now, dt)
	local t = now - (entry.fired[piece.slot] or -math.huge)
	local interval = reload(piece.weapon)
	local role = piece.role
	if role == "fire" or role == "drop" then
		-- Gone with the shot; for the last third of the reload it slides back in from behind.
		local back = interval * 0.7
		if t < back then return nil end
		local slide = math.clamp(1 - (t - back) / (interval * 0.3), 0, 1)
		return CFrame.new(0, 0, slide * 0.8 * piece.factor) * piece.rest
	elseif role == "spin" then
		local spin = entry.spin[piece.slot] or { angle = 0, rate = 0 }
		entry.spin[piece.slot] = spin
		if spin.at ~= now then
			spin.at = now
			local target = t < interval * 2 + 0.15 and SPIN_TURNS_PER_SECOND * math.pi * 2 or 0
			spin.rate += (target - spin.rate) * (1 - math.exp(-4 * dt))
			spin.angle = (spin.angle + spin.rate * dt) % (math.pi * 2)
		end
		return CFrame.new(piece.pivot) * CFrame.fromAxisAngle(piece.axis, piece.side * spin.angle) * CFrame.new(-piece.pivot) * piece.rest
	elseif role == "hinge" then
		local angle = math.rad(HINGE_DEGREES) * pulse(t, interval)
		return CFrame.new(piece.pivot) * CFrame.fromAxisAngle(piece.axis, piece.side * angle) * CFrame.new(-piece.pivot) * piece.rest
	elseif role == "slide" then
		return CFrame.new(piece.axis * SLIDE_STUDS * piece.factor * pulse(t, interval)) * piece.rest
	elseif role == "snap" then
		return CFrame.new(0, 0, -SNAP_STUDS * piece.factor * pulse(t, interval)) * piece.rest
	end
	return piece.rest
end

-- A mount fired (this pilot's own click, or another plane's shot from the server).
function Motion.fired(model, slot)
	local entry = model and track(model)
	if entry and slot then entry.fired[slot] = os.clock() end
end

function Motion.start()
	folder = Instance.new("Folder")
	folder.Name = "WeaponMotion"
	folder.Parent = workspace
	local parts, frames = {}, {}
	RunService.RenderStepped:Connect(function(dt)
		local now = os.clock()
		table.clear(parts); table.clear(frames)
		for _, model in ipairs(workspace.Planes:GetChildren()) do
			local body = model:FindFirstChild("Root")
			local entry = body and track(model)
			if not entry then continue end
			local shown = SHOWN[model:GetAttribute("State")] and not Deaths.dying(model)
			for _, piece in ipairs(entry.pieces) do
				-- Drawn by the copy while flying; the welded original shows again in the hangar (its preview copies it).
				local hideOriginal = shown and 1 or (Deaths.dying(model) and 1 or 0)
				if piece.original.LocalTransparencyModifier ~= hideOriginal then piece.original.LocalTransparencyModifier = hideOriginal end
				local relative = shown and pose(entry, piece, now, dt)
				piece.copy.LocalTransparencyModifier = relative and 0 or 1
				if relative then table.insert(parts, piece.copy); table.insert(frames, body.CFrame * relative) end
			end
		end
		workspace:BulkMoveTo(parts, frames, Enum.BulkMoveMode.FireCFrameChanged)
	end)
	workspace.Planes.ChildRemoved:Connect(function(model)
		local entry = planes[model]
		if entry then for _, piece in ipairs(entry.pieces) do piece.copy:Destroy() end end
		planes[model] = nil
	end)
end

return Motion
