-- Scripted looks check, client half (docs/workshop/tools.md, "looks_check"): run in the Play CLIENT with
--   python tools/studio_cli.py execute_luau '{"studio_id":"<id>","datamodel_type":"Client","code":"tools/looks_check/client_sampler.lua"}'
-- after mapReady + join. Flies the player's plane on the loop autopilot (relaunching it), counts frame times while it is
-- FLYING for each step the server half names (workspace attribute ClaudeSeg), and at the end of each step reads what is
-- really on every plane (skin pieces, layers, shape pieces, trail emitters and parts) against the configs. Each step's
-- result is the LocalPlayer attribute ClaudeR<number>. Reads only; needs Studio drawing (screen on, window in front).
local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local Stats = game:GetService("Stats")
local player = Players.LocalPlayer
local Root = game.ReplicatedStorage.FlyFightPaper
if player:GetAttribute("ClaudeSampler") then return "already running" end
player:SetAttribute("ClaudeSampler", true)

local tmp = Instance.new("Folder")
tmp.Name = "ClaudeTmp"
for _, n in { "JSONTypes", "Trails", "SkinShapes", "Looks", "SkinPieces", "SkinPictures", "SkinMotion" } do Root.Generated[n]:Clone().Parent = tmp end
tmp.Parent = game.ReplicatedStorage
local Trails = require(tmp.Trails)
local Shapes = require(tmp.SkinShapes).shapes
local Looks = require(tmp.Looks)
local Pieces = require(tmp.SkinPieces).pieces
local Pictures = require(tmp.SkinPictures).pictures
local Motion = require(tmp.SkinMotion)
local skinById = {}
for _, s in Looks.skins do skinById[s.id] = s end

local PICT = { soft = "rbxasset://textures/particles/smoke_main.dds", spark = "rbxasset://textures/particles/sparkles_main.dds", square = "rbxasset://textures/particles/SquareParticle.png" }
local LIT = { soft = { 0.3, 0.8 }, glow = { 1, 0 }, paper = { 0, 1 }, fire = { 1, 0 } }
local MAT = { foil = "Foil", glow = "Neon", matte = "Fabric", paper = "SmoothPlastic", bright = "SmoothPlastic", glass = "SmoothPlastic" }
local CLEAR = { glass = 0.38 }

local mineName = tostring(player.UserId)
local function myPlane() local p = workspace:FindFirstChild("Planes") return p and p:FindFirstChild(mineName) end
local function idOf(x)
	if typeof(x) == "Content" then x = x.Uri end
	return string.match(tostring(x), "%d+")
end
local function try(f, ...) local ok, v = pcall(f, ...) if ok then return v end return nil end
local function keys(t) local l = {} for k in t do table.insert(l, tostring(k)) end table.sort(l) return table.concat(l, ",") end

local noCopy = {} -- part names with no printed copy (keep their own look under every skin)

-- ---------- SKINS: what is really on every plane against its Skin attribute
local function skinCheck()
	local out, issues, planes, fine = {}, {}, 0, 0
	local function issue(s) if #issues < 10 then table.insert(issues, s) end end
	local perSkin = {}
	for _, plane in workspace.Planes:GetChildren() do
		local app = plane:FindFirstChild("Appearance")
		if not app then continue end
		planes += 1
		local id = plane:GetAttribute("Skin")
		local item = id and skinById[id]
		local want = item and item.picture and id or nil
		local shape = id and Shapes[id]
		local layers = want and Motion.skins[id] and #Motion.skins[id].layers or 0
		local exp, dressed, undressed, stale, wrongPic, wrongMesh, badLayers, noLook, stray, hidden, hiddenShown, copies = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		local shapeHave, firstBad = {}, nil
		for _, part in app:GetChildren() do
			if not part:IsA("BasePart") then continue end
			local isPiece = part:GetAttribute("SkinPiece")
			local shapeName = isPiece and string.match(part.Name, "^Skin%-(.+)$")
			if shapeName then
				if shape and shape.pieces[shapeName] then
					shapeHave[shapeName] = (shapeHave[shapeName] or 0) + 1
					if not part:FindFirstChildOfClass("SurfaceAppearance") then noLook += 1 end
				else stray += 1 end
				continue
			end
			if isPiece then if shape then copies += 1 else stray += 1 end end
			if part:GetAttribute("SkinHidden") then
				hidden += 1
				if not shape then stray += 1 elseif part.LocalTransparencyModifier < 1 then hiddenShown += 1 end
			end
			local name = part:IsA("MeshPart") and string.match(part.Name, "^[^-]+%-(.+)$")
			if name and Pieces[name] then
				exp += 1
				local has = part:GetAttribute("Skin")
				if has == want then
					if want then
						dressed += 1
						local sa = part:FindFirstChildOfClass("SurfaceAppearance")
						if not sa or idOf(try(function() return sa.ColorMap end)) ~= tostring(item.picture) then wrongPic += 1 end
						local mesh = idOf(try(function() return part.MeshId end)) or idOf(try(function() return part.MeshContent end))
						if mesh ~= tostring(Pieces[name].mesh) then wrongMesh += 1 end
					end
					local nl = 0
					for _, c in part:GetChildren() do if c.Name == "SkinLayer" then nl += 1 end end
					if nl ~= layers then badLayers += 1; firstBad = firstBad or (part.Name .. " layers " .. nl .. "/" .. layers) end
				elseif want then undressed += 1; firstBad = firstBad or (part.Name .. " not dressed (has " .. tostring(has) .. ")")
				else stale += 1; firstBad = firstBad or (part.Name .. " still wears " .. tostring(has)) end
			elseif part:IsA("MeshPart") and not isPiece then
				noCopy[(string.gsub(part.Name, "%d+$", "#"))] = true
			end
		end
		local shapeMiss = 0
		if shape then for nm in shape.pieces do if shapeHave[nm] ~= 1 then shapeMiss += 1 end end end
		local bad = undressed + stale + wrongPic + wrongMesh + badLayers + noLook + stray + hiddenShown + shapeMiss
		if id and not item then bad += 1; issue(plane.Name .. " unknown skin " .. id) end
		local key = id or "none"
		local s = perSkin[key] or { planes = 0, bad = 0, exp = 0, dressed = 0, hidden = 0, copies = 0, shapePieces = 0 }
		perSkin[key] = s
		s.planes += 1; s.exp += exp; s.dressed += dressed; s.hidden += hidden; s.copies += copies
		for _, n in shapeHave do s.shapePieces += n end
		if bad > 0 then
			s.bad += 1
			issue(("%s[%s %s %s]: undressed %d stale %d wrongPic %d wrongMesh %d badLayers %d shapeMissing %d noLook %d stray %d hiddenShown %d; %s"):format(
				string.sub(plane.Name, 1, 14), key, tostring(plane:GetAttribute("State")), tostring(plane:GetAttribute("Loadout")), undressed, stale, wrongPic, wrongMesh, badLayers, shapeMiss, noLook, stray, hiddenShown, tostring(firstBad)))
		else fine += 1 end
	end
	local rows = {}
	for key, s in perSkin do
		table.insert(rows, ("%s: planes %d bad %d pieces %d/%d%s"):format(key, s.planes, s.bad, s.dressed, s.exp,
			(s.shapePieces + s.hidden + s.copies > 0) and (" shape pieces %d hidden %d moved copies %d"):format(s.shapePieces, s.hidden, s.copies) or ""))
	end
	table.sort(rows)
	return ("SKINS planes %d fine %d | %s%s"):format(planes, fine, table.concat(rows, " ; "), #issues > 0 and (" | ISSUES: " .. table.concat(issues, " // ")) or "")
end

-- ---------- TRAILS: emitters and parts really made against config/trails.json
local function sizeAt(spec, k)
	local grow = Trails.grow_in
	return math.min(k / grow, 1) * (1 + (spec.shrink - 1) * math.max(0, (k - grow) / (1 - grow)) ^ 1.5)
end
local function rgb(c) return math.round(c.R * 255) .. "," .. math.round(c.G * 255) .. "," .. math.round(c.B * 255) end
local function trailCheck()
	local forced = player:GetAttribute("DevTrail")
	local flyingBy, drawn, flying, expEmit, expParts = {}, 0, 0, 0, 0
	local rowsBy = {} -- model -> list of specs worn now (part rows)
	local wornIds = {}
	for _, plane in workspace.Planes:GetChildren() do
		local id = forced or plane:GetAttribute("Trail")
		local trail = id and Trails.trails[id]
		local isFlying = plane:GetAttribute("State") == "FLYING"
		if isFlying then flying += 1 end
		if trail then
			drawn += 1
			wornIds[id] = true
			for _, spec in trail.pieces do
				if PICT[spec.model] then expEmit += spec.rainbow and 1 or #spec.colors
				else
					rowsBy[spec.model] = rowsBy[spec.model] or {}
					if not table.find(rowsBy[spec.model], spec) then table.insert(rowsBy[spec.model], spec) end
					if isFlying then expParts += spec.rate * (spec.life[1] + spec.life[2]) / 2 * (spec.flash and 0.58 or 1) end
				end
			end
		end
	end
	local holders, emitters, emitBad = 0, 0, {}
	for _, a in workspace.Terrain:GetChildren() do
		if a.Name == "Trail" and a:IsA("Attachment") then
			holders += 1
			for _, e in a:GetChildren() do
				if e:IsA("ParticleEmitter") then
					emitters += 1
					local okRow = false
					for id in wornIds do
						for _, spec in Trails.trails[id].pieces do
							local lit = LIT[spec.look]
							if PICT[spec.model] == e.Texture and lit and math.abs(e.LightEmission - lit[1]) < 0.01 and math.abs(e.LightInfluence - lit[2]) < 0.01
								and math.abs(e.Lifetime.Min - spec.life[1]) < 0.01 and math.abs(e.Lifetime.Max - spec.life[2]) < 0.01 then okRow = true end
						end
					end
					if not okRow then emitBad[e.Texture .. " emis " .. e.LightEmission .. " life " .. e.Lifetime.Min .. "-" .. e.Lifetime.Max] = true end
				end
			end
		end
	end
	local by, vis, pool = {}, 0, 0
	local folder = workspace:FindFirstChild("Trails")
	for _, part in (folder and folder:GetChildren() or {}) do
		local model = string.match(part.Name, "^Trail%-(.+)$") or part.Name
		local b = by[model]
		if not b then b = { pool = 0, vis = 0, min = 1e9, max = 0, mats = {}, cols = {}, clear = {}, lights = 0, up = 0, level = 0 }; by[model] = b end
		b.pool += 1; pool += 1
		if part.Position.Y < 5e4 then
			b.vis += 1; vis += 1
			local long = math.max(part.Size.X, part.Size.Y, part.Size.Z)
			b.min, b.max = math.min(b.min, long), math.max(b.max, long)
			b.mats[part.Material.Name] = true
			b.cols[rgb(part.Color)] = true
			b.clear[string.format("%.2f/%.2f", part.Transparency, part.Reflectance)] = true
			if part:FindFirstChildOfClass("PointLight") then b.lights += 1 end
			if part.CFrame.ZVector.Y > 0.9 then b.up += 1 end
			if part.CFrame.YVector.Y > 0.5 then b.level += 1 end
		end
	end
	local rows, problems = {}, {}
	for model, specs in rowsBy do
		local b = by[model]
		if not b then table.insert(problems, model .. ": NO PARTS MADE (model not loaded?)") continue end
		local maxOk, mats, cols, clears, upright, level, light = 0, {}, {}, {}, false, false, false
		for _, spec in specs do
			maxOk = math.max(maxOk, spec.size[2] * math.max(1, spec.shrink) * Trails.fast_growth * 1.1)
			mats[MAT[spec.look] or ("?" .. spec.look)] = true
			for _, c in spec.colors do cols[c[1] .. "," .. c[2] .. "," .. c[3]] = true end
			clears[string.format("%.2f/%.2f", CLEAR[spec.look] or 0, spec.look == "glass" and 0.25 or 0)] = true
			upright = upright or spec.upright; level = level or spec.level; light = light or spec.light
		end
		local row = ("%s vis %d pool %d size %.2f-%.2f(max ok %.1f) %s"):format(model, b.vis, b.pool, b.vis > 0 and b.min or 0, b.max, maxOk, keys(b.mats))
		if b.max > maxOk then table.insert(problems, model .. " too big " .. string.format("%.2f", b.max)) end
		for m in b.mats do if not mats[m] then table.insert(problems, model .. " material " .. m .. " not in config (" .. keys(mats) .. ")") end end
		for c in b.cols do if not cols[c] then table.insert(problems, model .. " colour " .. c .. " not in config") end end
		for c in b.clear do if not clears[c] then table.insert(problems, model .. " see-through/shine " .. c .. " expected " .. keys(clears)) end end
		if upright and b.vis > 0 then row ..= (" upright %d/%d"):format(b.up, b.vis) end
		if level and b.vis > 0 then row ..= (" right-way-up %d/%d"):format(b.level, b.vis) end
		if light then row ..= (" lights %d/%d"):format(b.lights, b.vis) end
		table.insert(rows, row)
	end
	for model, b in by do if not rowsBy[model] and b.vis > 0 then table.insert(problems, model .. ": " .. b.vis .. " parts showing that no worn trail asks for") end end
	for bad in emitBad do table.insert(problems, "emitter not in config: " .. bad) end
	table.sort(rows)
	return ("TRAILS worn %s | flying %d holders %d/%d emitters %d/%d | parts showing %d expect ~%d pool %d | %s%s"):format(keys(wornIds), flying, holders, drawn, emitters, expEmit, vis, expParts, pool,
		table.concat(rows, " ; "), #problems > 0 and (" | ISSUES: " .. table.concat(problems, " // ")) or "")
end

-- ---------- frames
local STAT = { "FrameTime", "HeartbeatTime", "RenderCPUFrameTime", "RenderGPUFrameTime", "PhysicsStepTime", "SceneDrawcallCount", "SceneTriangleCount" }
local seg
local function pickTrack(s)
	local plane = myPlane()
	local app = plane and plane:FindFirstChild("Appearance")
	local best, area
	for _, part in (app and app:GetChildren() or {}) do
		if part:IsA("BasePart") and part:FindFirstChild("SkinLayer") then
			local a = part.Size.X * part.Size.Z
			if not best or a > area then best, area = part, a end
		end
	end
	if not best then return end
	local decals = {}
	for _, c in best:GetChildren() do if c.Name == "SkinLayer" then table.insert(decals, c) end end
	table.sort(decals, function(a, b) return a.ZIndex < b.ZIndex end)
	local t = { part = best, sa = best:FindFirstChildOfClass("SurfaceAppearance"), decals = decals, d = {} }
	for i, d in decals do t.d[i] = { minT = 2, maxT = -1, moved = false, uv = d.UVOffset, rot = d.Rotation, maxE = 0, minE = 1e9 } end
	t.saMin, t.saMax = 1e9, -1
	s.track = t
end
RS.RenderStepped:Connect(function(dt)
	local s = seg
	if not s or s.closed then return end
	local e = os.clock() - s.start
	if e < s.settle then if dt > s.loadMax then s.loadMax = dt end return end
	if s.view ~= "over" then
		local p = myPlane()
		if not (p and p:GetAttribute("State") == "FLYING") then s.skipped += 1 return end
	end
	s.n += 1; s.dts[s.n] = dt
	local t = s.track
	if t and t.part.Parent then
		for i, d in t.decals do
			local r = t.d[i]
			local tr = d.Transparency
			if tr < r.minT then r.minT = tr end
			if tr > r.maxT then r.maxT = tr end
			if d.UVOffset ~= r.uv or d.Rotation ~= r.rot then r.moved = true end
			local em = d.EmissiveStrength
			if em > r.maxE then r.maxE = em end
			if em < r.minE then r.minE = em end
		end
		if t.sa then local em = t.sa.EmissiveStrength; if em < t.saMin then t.saMin = em end; if em > t.saMax then t.saMax = em end end
	end
end)

local function finalize(s)
	local dts, n, sum, o20, o33 = s.dts, s.n, 0, 0, 0
	table.sort(dts)
	for i = 1, n do local d = dts[i]; sum += d; if d > 0.020 then o20 += 1 end; if d > 0.0333 then o33 += 1 end end
	local function pct(p) return n > 0 and dts[math.max(1, math.ceil(n * p))] * 1000 or 0 end
	local st = {}
	for _, k in STAT do table.insert(st, ("%s %.4g"):format(k, s.samples > 0 and (s.stat[k] or 0) / s.samples or -1)) end
	local line = ("R%s|%s|%s|view %s|frames %d fps %.1f p50 %.1f p95 %.1f p99 %.1f max %.1f ms over20ms %.1f%% over33ms %.1f%% loadHitch %.0f ms notFlyingFrames %d|flying %.1f mem %.0f srv %.2f/%.2f %s"):format(
		s.idx, s.name, s.kind, s.view, n, n > 0 and n / sum or 0, pct(0.5), pct(0.95), pct(0.99), n > 0 and dts[n] * 1000 or 0, n > 0 and 100 * o20 / n or 0, n > 0 and 100 * o33 / n or 0,
		s.loadMax * 1000, s.skipped, s.samples > 0 and s.flying / s.samples or 0, try(function() return Stats:GetTotalMemoryUsageMb() end) or -1,
		Root:GetAttribute("ServerFrameMs") or -1, Root:GetAttribute("ServerFrameP95Ms") or -1, table.concat(st, " "))
	local ok1, a = pcall(skinCheck)
	local ok2, b = pcall(trailCheck)
	line ..= "\n   " .. tostring(a) .. "\n   " .. tostring(b)
	local t = s.track
	if t then
		local m = Motion.skins[myPlane() and myPlane():GetAttribute("Skin") or ""]
		local parts = {}
		for i, r in t.d do
			local layer = m and m.layers[i]
			table.insert(parts, ("%s(%s) %s see-through %.2f..%.2f glow %.2f..%.2f"):format(layer and layer.name or "?", layer and layer.kind or "?", r.moved and "MOVED" or "still", r.minT, r.maxT, r.minE, r.maxE))
		end
		line ..= ("\n   MOTION on %s: %s | sheet glow %.2f..%.2f"):format(t.part.Name, table.concat(parts, " ; "), t.saMin, t.saMax)
	end
	player:SetAttribute("ClaudeR" .. s.idx, line)
	player:SetAttribute("ClaudeLast", tonumber(s.idx))
end

local function begin(v)
	if seg and not seg.closed then seg.closed = true; player:SetAttribute("ClaudeR" .. seg.idx, "R" .. seg.idx .. "|" .. seg.name .. "|BROKEN (round ended mid-way; redone later)") end
	if not v or v == "pause" or v == "done" then seg = nil; player:SetAttribute("DevView", 0); return end
	local f = string.split(v, "|")
	seg = { idx = f[1], name = f[2], kind = f[3], settle = tonumber(f[4]), dur = tonumber(f[5]), view = f[6] or "", start = os.clock(), dts = {}, n = 0, loadMax = 0, skipped = 0, samples = 0, flying = 0, stat = {} }
	player:SetAttribute("DevView", seg.view == "over" and 2 or 0)
end
workspace:GetAttributeChangedSignal("ClaudeSeg"):Connect(function() begin(workspace:GetAttribute("ClaudeSeg")) end)

task.spawn(function()
	local lastLaunch = 0
	while player:GetAttribute("ClaudeSampler") do
		task.wait(0.5)
		local ok, err = pcall(function()
			local p = myPlane()
			if p and p:GetAttribute("State") == "DESK" and os.clock() - lastLaunch > 2.5 then lastLaunch = os.clock(); Root.FlightAction:FireServer("launch") end
			-- the loop restarts at its first corner on every takeoff: a respawned plane steering for a far corner flew into the town
			local state = p and p:GetAttribute("State")
			if state == "TAKEOFF" or state == "DESK" then player:SetAttribute("DevAutopilot", nil)
			elseif state == "FLYING" and player:GetAttribute("DevAutopilot") ~= "loop" then player:SetAttribute("DevAutopilot", "loop") end
			local s = seg
			if s and not s.closed then
				local e = os.clock() - s.start
				if e >= s.settle then
					s.samples += 1
					local f = 0
					for _, plane in workspace.Planes:GetChildren() do if plane:GetAttribute("State") == "FLYING" then f += 1 end end
					s.flying += f
					for _, k in STAT do local v = try(function() return Stats[k] end); if type(v) == "number" then s.stat[k] = (s.stat[k] or 0) + v end end
					if not (s.track and s.track.part.Parent) then pickTrack(s) end
				end
				if e >= s.dur - 1.2 then s.closed = true; finalize(s) end
			end
		end)
		if not ok then player:SetAttribute("ClaudeErr", tostring(err)) end
	end
end)

-- self-test now, so a mistake shows at once
local a, b = pcall(skinCheck)
local c, d = pcall(trailCheck)
local cam = workspace.CurrentCamera
return ("sampler on | viewport %s | %s | %s"):format(tostring(cam.ViewportSize), tostring(b), tostring(d))
