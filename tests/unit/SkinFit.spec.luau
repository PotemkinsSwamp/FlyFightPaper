-- Shape skins on the server (SkinFit + HitShapes.place + FlightService colliders/wear): under the crane the real wings'
-- hit and crash shapes turn up by the crane's rise about the hinge the screen draws, keep their exact size, the guns'
-- shapes move by the same offsets the screen's fit gives, and the booster's rise or drop straight to the drawn belly. A
-- plane without a shape skin is unchanged.
local Root = game.ReplicatedStorage.FlyFightPaper
local SkinFit = require(Root.Shared.SkinFit)
local Aircraft = require(Root.Shared.Aircraft)
local Catalog = require(Root.Shared.Catalog)
local HitShapes = require(game.ServerScriptService.FlyFightPaper.HitShapes)
local Flight = require(game.ServerScriptService.FlyFightPaper.FlightService)
local Suite = require(script.Parent.Parent.fixtures.Suite)
local Spec = {}
local CRANE = "origami_crane"
local RISE = math.rad(SkinFit.shapes[CRANE].const.RISE)

local function near(a, b, eps) return (a - b).Magnitude < (eps or 1e-3) end
local function same(a, b)
	local _, angle = a:ToObjectSpace(b):ToAxisAngle()
	return near(a.Position, b.Position) and math.abs(angle) < 1e-3
end

function Spec.run()
	local result, test = Suite.new()
	local catalog = Catalog.new(require(Root.Generated.Catalog))
	-- Three different builds with guns on the body and under a wing: the Fighter (no booster), a slim body on swept wings
	-- with the Elastic Booster and a crayon under its left wing, and the Toilet Roll Gunship on swept wings with the Twin.
	local swept = catalog:classLoadout("striker", 99)
	swept.wings, swept.weapon_mounts[3] = "wings_4", "crayon"
	local heavy = catalog:classLoadout("bomber", 99)
	heavy.wings, heavy.utility = "wings_1", "boost_twin"
	local builds = { fighter = catalog:classLoadout("fighter", 99), swept = swept, heavy = heavy }
	test("Holographic covers both faces of a real wing and taking it off restores its team marks", function()
		local looks = require(game.StarterPlayer.StarterPlayerScripts.FlyFightPaper.PlaneLooks)
		local world = Instance.new("WorldModel")
		local model = Instance.new("Model", world)
		local appearance = Instance.new("Model", model)
		appearance.Name = "Appearance"
		local wing = Root.Assets.AircraftPieces.wings_0["wings-paper-L"]:Clone()
		wing.Name, wing.Parent = "wings-wings-paper-L", appearance
		local mark = Root.Assets.AircraftPieces.Stickers["sticker-circle"]:Clone()
		mark:SetAttribute("TeamSticker", true)
		mark.Parent = appearance
		local placeholder = Instance.new("MeshPart")
		placeholder:SetAttribute("Region", "sticker")
		placeholder.Transparency, placeholder.Parent = 1, appearance
		assert(looks.dressPreview(model, "holographic"))
		assert(mark.Transparency == 1 and placeholder.Transparency == 1)
		local top, bottom = {}, {}
		for _, layer in wing:GetChildren() do
			if layer.Name ~= "SkinLayer" then continue end
			local faces = if layer.Face == Enum.NormalId.Top then top else bottom
			assert(layer.Face == Enum.NormalId.Top or layer.Face == Enum.NormalId.Bottom)
			faces[layer.ZIndex] = layer
		end
		for i = 1, 2 do
			local a, b = top[i], bottom[i]
			assert(a and b and a.ColorMapContent.Uri == b.ColorMapContent.Uri)
			assert((b.UVScale - Vector2.new(a.UVScale.X, -a.UVScale.Y)).Magnitude < 1e-5)
			assert((b.UVOffset - a.UVOffset - Vector2.new(0, a.UVScale.Y)).Magnitude < 1e-5)
			assert(a.Rotation == b.Rotation and a.EmissiveStrength == b.EmissiveStrength)
		end
		-- The replacement can arrive already hidden. Taking off the skin still uses the authored
		-- paint state, even for a marker the dresser has never seen before.
		local replacement = mark:Clone()
		mark:Destroy()
		mark = replacement
		mark.Parent = appearance
		assert(looks.dressPreview(model, ""))
		assert(mark.Transparency == 0 and placeholder.Transparency == 1 and not wing:FindFirstChild("SkinLayer"))
		world:Destroy()
	end)
	local function plane(loadout)
		local model = Instance.new("Model")
		local body = Instance.new("Part")
		body.Name, body.Anchored, body.CFrame, body.Parent = "Root", true, CFrame.new(30, 200, -10) * CFrame.Angles(0.3, 1.1, -0.2), model
		assert(Aircraft.build(model, loadout, catalog, true))
		return model, body.CFrame
	end
	for name, loadout in builds do
		local model, frame = plane(loadout)
		local fitted = assert(SkinFit.plane(CRANE, model.Appearance, frame))
		local pieces, parts = HitShapes.place(model.Appearance, frame, CRANE)
		test(name .. ": each wing shape turns up by the crane's rise about the drawn hinge, same size", function()
			local hinge, drawn = fitted.hinge, fitted.placed.wingR
			-- The hinge is where the drawn crane wing's root edge sits (its box starts 0.02 x ks past it).
			local root = drawn[1].Position - drawn[2] / 2
			assert(near(Vector3.new(root.X, root.Y, 0), Vector3.new(hinge.X, hinge.Y, 0), 0.05), tostring(root) .. " vs " .. tostring(hinge))
			local wings = 0
			for i, part in parts do
				if not string.match(part.Name, "^wings") then continue end
				wings += 1
				local before = frame:ToObjectSpace(part.CFrame)
				assert(pieces[i].Size == part.Size, part.Name .. " changed size")
				local turn = pieces[i].CFrame * before:Inverse()
				local axis, angle = turn:ToAxisAngle()
				assert(math.abs(math.abs(axis.Z) - 1) < 1e-4 and math.abs(angle - RISE) < 1e-4, part.Name .. " turned " .. math.deg(angle))
				local side = before.Position.X < 0 and -1 or 1
				local at = hinge * Vector3.new(side, 1, 1)
				for _, z in { -3, 0, 4 } do -- the hinge line, front to back, stays where it was
					local point = at + Vector3.new(0, 0, z)
					assert(near(turn * point, point), part.Name .. " moved its hinge")
				end
				assert((turn * (at + Vector3.new(side, 0, 0))).Y > at.Y + 0.5, part.Name .. " tip went down")
			end
			assert(wings >= 4, "no wings found")
		end)
		test(name .. ": gun shapes move by the screen's offsets and hang under the drawn wing", function()
			local groups = {}
			for i, part in parts do
				local slot = tonumber(string.match(part.Name, "^Mount(%d+)"))
				if not slot then continue end
				assert(pieces[i].Size == part.Size)
				assert(same(pieces[i].CFrame, fitted.guns[part] * frame:ToObjectSpace(part.CFrame)))
				groups[slot] = groups[slot] or {}
				table.insert(groups[slot], i)
			end
			local count = 0
			for slot, list in groups do
				count += 1
				-- The gun's top, measured the way the screen measures it (SkinShapes hangs a gun by its top).
				local lo, hi = Vector3.one * math.huge, -Vector3.one * math.huge
				for _, i in list do
					local p = frame:PointToObjectSpace(parts[i].Position)
					lo, hi = lo:Min(p - parts[i].Size / 2), hi:Max(p + parts[i].Size / 2)
				end
				local top = Vector3.new((lo.X + hi.X) / 2, hi.Y, (lo.Z + hi.Z) / 2)
				local offset = assert(fitted.offsets[slot], "no offset for slot " .. slot)
				local to = fitted.guns[parts[list[1]]] * top
				assert(near(to, top + offset), "slot " .. slot .. " top moved by " .. tostring(to - top) .. " not " .. tostring(offset))
				local wingY = fitted.hinge.Y + (math.abs(to.X) - fitted.hinge.X) * math.tan(RISE)
				assert(to.Y < wingY and to.Y > wingY - 0.2, "slot " .. slot .. " not just under the drawn wing")
			end
			local want = 0
			for _, id in loadout.weapon_mounts do if id then want += 1 end end
			assert(count == want, count .. " guns of " .. want)
		end)
		if loadout.utility then test(name .. ": the booster moves straight up or down as one, same size, until it touches the drawn belly", function()
			-- The belly's middle from where the drawn body piece sits (its box), not from SkinFit's own stretch.
			local drawn, piece = fitted.placed.body, SkinFit.shapes[CRANE].pieces.body
			local refLo, refHi = Vector3.new(table.unpack(piece.min)), Vector3.new(table.unpack(piece.max))
			local keel = {}
			for i, p in SkinFit.shapes[CRANE].ref.keel do
				keel[i] = drawn[1] * ((Vector3.new(0, p[1], p[2]) - (refLo + refHi) / 2) * drawn[2] / (refHi - refLo))
			end
			local function belly(z)
				for i = 1, #keel - 1 do
					local a, b = keel[i], keel[i + 1]
					if z >= a.Z and z <= b.Z then return a.Y + (b.Y - a.Y) * (z - a.Z) / (b.Z - a.Z) end
				end
				return nil
			end
			-- The belly's lowest height between z0 and z1 (at an end or a keel corner: straight between corners).
			local function lowest(z0, z1)
				local zs, low = { z0, z1 }, nil
				for _, k in keel do if k.Z > z0 and k.Z < z1 then table.insert(zs, k.Z) end end
				for _, z in zs do
					local y = belly(z)
					if y then low = math.min(low or y, y) end
				end
				return low
			end
			local plain, plainParts = HitShapes.place(model.Appearance, frame, nil)
			local move, gap, sunk, count = nil, math.huge, 0, 0
			for i, part in parts do
				if not string.match(part.Name, "^Booster") then continue end
				count += 1
				local m = assert(fitted.boosters[part], part.Name .. " not moved")
				move = move or m
				assert(same(m, move), "the booster's parts moved apart")
				assert(same(m, CFrame.new(0, m.Y, 0)), part.Name .. " moved sideways or turned")
				assert(pieces[i].Size == part.Size, part.Name .. " changed size")
				assert(same(pieces[i].CFrame, m * frame:ToObjectSpace(part.CFrame)), part.Name .. " hit shape not on the drawn booster")
				assert(plainParts[i] == part and same(plain[i].CFrame, frame:ToObjectSpace(part.CFrame)), part.Name .. " moved without the skin")
				if string.match(part.Name, "%-tape$") then continue end -- the strap wraps the body: its top tucks inside
				local lo, hi = Vector3.one * math.huge, -Vector3.one * math.huge
				for c = 0, 7 do
					local corner = pieces[i].CFrame * (part.Size / 2 * Vector3.new(c % 2 * 2 - 1, math.floor(c / 2) % 2 * 2 - 1, math.floor(c / 4) * 2 - 1))
					lo, hi = lo:Min(corner), hi:Max(corner)
				end
				-- Its top touches the belly over the middle of its length (the ends round off), and even its box's
				-- square ends sink less than 0.1 into the belly.
				local trim = (hi.Z - lo.Z) * 0.2
				local middle, whole = lowest(lo.Z + trim, hi.Z - trim), lowest(lo.Z, hi.Z)
				if middle then gap = math.min(gap, middle - hi.Y) end
				if whole then sunk = math.max(sunk, hi.Y - whole) end
			end
			for _, piece in plain do piece:Destroy() end
			assert(count >= 5, count .. " booster parts")
			assert(math.abs(gap) < 0.01, "the booster's top is " .. gap .. " below the belly (negative: sunk in)")
			assert(sunk < 0.1, "a booster box sinks " .. sunk .. " into the belly")
		end) end
		test(name .. ": without a shape skin nothing moves", function()
			assert(SkinFit.plane(nil, model.Appearance, frame) == nil and SkinFit.plane("hazard_stripes", model.Appearance, frame) == nil)
			for _, skin in { false, "hazard_stripes" } do
				local plain, plainParts = HitShapes.place(model.Appearance, frame, skin or nil)
				assert(#plain == #pieces)
				for i, part in plainParts do
					assert(plain[i].Size == part.Size and same(plain[i].CFrame, frame:ToObjectSpace(part.CFrame)), part.Name .. " moved")
					plain[i]:Destroy()
				end
			end
		end)
		-- The Fighter's paper wing is flat (0.19 thick), so "just above it" is exact whether its precise shape has loaded or not.
		if name == "fighter" then test(name .. ": a shot just above the flat wing misses it, and hits the crane's turned wing", function()
			local p = { id = "skinfit-spec-" .. name, model = model, body = model.Root }
			local wing
			for _, part in parts do if string.match(part.Name, "^wings.*paper%-R$") then wing = part end end
			local before = frame:ToObjectSpace(assert(wing, "no right paper wing").CFrame)
			local turn = fitted.wings[wing]
			local spot = turn * (before.Position + Vector3.new(wing.Size.X * 0.3, 0, 0))
			local function cast(skin)
				p.skin = skin
				return HitShapes.cast(p, frame, frame * (spot + Vector3.new(0, 0, -30)), frame:VectorToWorldSpace(Vector3.new(0, 0, 60)), Vector3.new(0.5, 0.5, 2), CFrame.identity)
			end
			assert(cast(nil) == nil, "the flat wing was hit")
			assert(cast(CRANE), "the turned wing was missed")
			assert(cast(nil) == nil, "the copy kept the crane's wing")
			HitShapes.forget(p)
		end) end
		test(name .. ": wearing the crane rebuilds the crash shapes turned and the contact box covers them; taking it off flattens them", function()
			local p = { model = model, body = model.Root }
			Flight.colliders(nil, p, model)
			local function check(skin)
				local colliders = model.Colliders:GetChildren()
				assert(#colliders == #parts)
				local expect, expectParts = HitShapes.place(model.Appearance, frame, skin)
				local want = {}
				for i, part in expectParts do want[part.Name] = expect[i] end
				for _, piece in colliders do
					local at = assert(want[piece.Name], piece.Name)
					assert(piece.Size == at.Size and same(piece.CFrame, frame * at.CFrame), piece.Name .. " not where HitShapes.place puts it")
				end
				for _, piece in expect do piece:Destroy() end
				local reach = Aircraft.reach(frame, colliders)
				local box = model:GetAttribute("ContactSize") / 2
				assert(box.X >= reach.X - 1e-3 and box.Y >= reach.Y - 1e-3 and box.Z >= reach.Z - 1e-3, "contact box too small")
			end
			Flight.wear(Flight, p, CRANE, nil)
			assert(p.skin == CRANE and model:GetAttribute("Skin") == CRANE)
			check(CRANE)
			Flight.wear(Flight, p, nil, nil)
			assert(model:GetAttribute("Skin") == nil)
			check(nil)
		end)
		for _, piece in pieces do piece:Destroy() end
		model:Destroy()
	end
	-- The Dragon keeps its proportions and IS the hitbox (Alan 2026-11-15): one size, as big a target as the plane
	-- (config/plane-areas.json), centred on it, wings at the plane's wing height; on the server it replaces the body, nose,
	-- wings and tail as the hit and crash shape. Four builds: the three above and the widest wings on the Heavy Mk2.
	local DRAGON = "dragon"
	local shape = SkinFit.shapes[DRAGON]
	local E, box = shape.even, shape.pieces.whole
	local Areas = require(Root.Generated.PlaneAreas).bodies
	local wide = catalog:classLoadout("bomber", 99)
	wide.body, wide.wings, wide.utility = "body_heavy_mk2", "wings_2", "boost_band"
	builds.wide = wide
	for name, loadout in builds do
		local model, frame = plane(loadout)
		local o = assert(SkinFit.outline(model.Appearance, frame))
		local fitted = assert(SkinFit.plane(DRAGON, model.Appearance, frame))
		local drawn = fitted.placed.whole
		local lo, hi = Vector3.new(table.unpack(box.min)), Vector3.new(table.unpack(box.max))
		local k = drawn[2].Z / (hi - lo).Z
		test(name .. ": the Dragon keeps its proportions, is exactly as big a target as the plane, centred, wings at the wings' height", function()
			assert(near(drawn[2], (hi - lo) * k, 1e-4), "stretched: " .. tostring(drawn[2]))
			local a = Areas[loadout.body]
			local area = a.wings[loadout.wings] + (a.nose[loadout.nose] or 0) + (a.tail[loadout.tail] or 0)
			-- Exactly as big a target as the plane, even where that is shorter or narrower than it (Alan 2026-11-18).
			assert(math.abs(E.area * k * k - area) < 1e-3 * area, "target " .. E.area * k * k .. " vs the plane's " .. area)
			assert(math.abs(drawn[1].Position.Z - (o.zN + o.zT) / 2) < 1e-3, "not centred on the plane")
			local wingY = drawn[1].Position.Y + (E.wing_y - (lo.Y + hi.Y) / 2) * k
			assert(math.abs(wingY - o.wy) < 1e-3, "wings at " .. wingY .. ", the plane's at " .. o.wy)
		end)
		test(name .. ": under the Dragon its shape replaces the body, nose, wings and tail as the hit and crash shape", function()
			local pieces, parts = HitShapes.place(model.Appearance, frame, DRAGON)
			local skins, guns, want = 0, 0, 0
			for i, piece in pieces do
				local slot = parts[i] and string.match(parts[i].Name, "^(%a+)")
				assert(slot ~= "body" and slot ~= "nose" and slot ~= "wings" and slot ~= "tail", tostring(slot) .. " still a hit shape")
				if not parts[i] then
					skins += 1
					assert(piece.Name == "Skin-whole" and near(piece.Size, drawn[2]) and same(piece.CFrame, drawn[1]), "the Dragon's shape is not where it is drawn")
				elseif slot == "Mount" then guns += 1 end
				piece:Destroy()
			end
			for _, part in model.Appearance:GetChildren() do if part:IsA("MeshPart") and string.match(part.Name, "^Mount") then want += 1 end end
			assert(skins == 1 and guns == want, skins .. " Dragon shapes, " .. guns .. " gun shapes of " .. want)
		end)
		test(name .. ": guns hang just under the Dragon's wing, outside its body", function()
			local hinge, count = fitted.hinge, 0
			for slot, offset in fitted.offsets do
				count += 1
				local parts = {}
				for part, move in fitted.guns do if string.match(part.Name, "^Mount" .. slot .. "%f[%D]") then table.insert(parts, part) end end
				local lo2, hi2 = Vector3.one * math.huge, -Vector3.one * math.huge
				for _, part in parts do
					local p = frame:PointToObjectSpace(part.Position)
					lo2, hi2 = lo2:Min(p - part.Size / 2), hi2:Max(p + part.Size / 2)
				end
				local to = Vector3.new((lo2.X + hi2.X) / 2, hi2.Y, (lo2.Z + hi2.Z) / 2) + offset
				local under = hinge.Y + (E.wing.under_y - E.wing_y) * k
				assert(to.Y < under and to.Y > under - 0.1 * k, "slot " .. slot .. " top at " .. to.Y .. ", the wing's underside at " .. under)
				assert(math.abs(to.X) > E.body_x * k and math.abs(to.X) < E.wing.tip_x * k, "slot " .. slot .. " not under the wing")
			end
			local want = 0
			for _, id in loadout.weapon_mounts do if id then want += 1 end end
			assert(count == want, count .. " guns of " .. want)
		end)
		if loadout.utility then test(name .. ": the booster rises or drops straight until its top touches the Dragon's belly", function()
			local top, move = -math.huge, nil
			for part, m in fitted.boosters do
				assert(move == nil or same(m, move), "the booster's parts moved apart"); move = m
				assert(same(m, CFrame.new(0, m.Y, 0)), part.Name .. " moved sideways or turned")
				if string.match(part.Name, "%-tape$") then continue end
				local p = (m * frame:ToObjectSpace(part.CFrame)).Position
				top = math.max(top, p.Y + part.Size.Y / 2)
			end
			assert(move, "the booster did not move")
			local belly = drawn[1].Position.Y + (math.min(E.keel[2][1], E.keel[3][1]) - (lo.Y + hi.Y) / 2) * k
			assert(top < belly + 0.05 and top > belly - 0.3 * k, "the booster's top is at " .. top .. ", the belly at " .. belly)
		end) end
		model:Destroy()
	end
	for _, skin in require(Root.Generated.Looks).skins do
		test(skin.name .. ": the hangar card has installed plane art", function()
			local folder = assert(Root.Assets.SkinLooks:FindFirstChild(skin.id), skin.id)
			if skin.tier == "legendary" or skin.tier == "mythical" then
				assert(SkinFit.has(skin.id) and folder:FindFirstChild("Shape"), skin.id)
			else
				assert(skin.picture and folder:FindFirstChildWhichIsA("SurfaceAppearance"), skin.id)
			end
		end)
	end
	for _, id in {"shark_jet", "hot_rod", "race_car", "stealth"} do
		-- The hidden hit copy: the drawn skin less its spoiler or top fin, tall fins cut where a normal tail fin ends
		-- (Alan 2026-11-18, tools/art/skin_hit_hulls.py): lower than the drawn skin, and the only hit and crash shape.
		test(id .. ": first flight crashes with its trimmed hit copy at the fitted size", function()
			local model, frame = plane(builds.heavy)
			local fit = assert(SkinFit.plane(id, model.Appearance, frame))
			local body = assert(fit.placed.hullHit)
			assert(body[1].Y + body[2].Y / 2 < fit.placed.body[1].Y + fit.placed.body[2].Y / 2, "the hit copy is as tall as the drawn skin")
			Flight.colliders(Flight, {model = model, skin = id}, model)
			assert(not model.Colliders:FindFirstChild("Skin-body"), "the drawn skin is a crash shape")
			local deadline = os.clock() + 15
			while not model.Colliders["Skin-hullHit"]:IsA("MeshPart") and os.clock() < deadline do task.wait(0.1) end
			local hull = model.Colliders["Skin-hullHit"]
			local matches = hull:IsA("MeshPart") and hull.MeshId == "rbxassetid://" .. SkinFit.shapes[id].pieces.hullHit.mesh
				and hull.CollisionFidelity == Enum.CollisionFidelity.PreciseConvexDecomposition
				and near(hull.Size, body[2]) and same(frame:ToObjectSpace(hull.CFrame), body[1])
			model:Destroy()
			assert(matches, id)
		end)
	end
	test("Ninja is centred on its rigid hull and only that hull and equipment can be hit", function()
		local model, frame = plane(builds.swept)
		local outline = assert(SkinFit.outline(model.Appearance, frame))
		local fitted = assert(SkinFit.plane("ninja", model.Appearance, frame))
		local hull = fitted.placed.hullHit
		assert(fitted.covers and hull and fitted.placed.bladeL and fitted.placed.bladeR)
		assert(math.abs(hull[1].Z - (outline.zN + outline.zT) / 2) < 1e-3)
		assert(fitted.placed.body[2].Z > hull[2].Z, "the scarf should extend beyond the hull")
		local pieces, parts = HitShapes.place(model.Appearance, frame, "ninja")
		local hulls, guns = 0, 0
		for index, piece in pieces do
			if parts[index] then
				assert(parts[index].Name:match("^Mount") or parts[index].Name:match("^Booster"))
				if parts[index].Name:match("^Mount") then guns += 1 end
			else
				assert(piece.Name == "Skin-hullHit" and same(piece.CFrame, hull[1]) and near(piece.Size, hull[2]))
				hulls += 1
			end
			piece:Destroy()
		end
		assert(hulls == 1 and guns > 0)
		local pilot = {model = model, skin = "ninja"}
		Flight.colliders(Flight, pilot, model)
		local deadline = os.clock() + 15
		while not model.Colliders["Skin-hullHit"]:IsA("MeshPart") and os.clock() < deadline do task.wait(0.1) end
		local crash = model.Colliders["Skin-hullHit"]
		local exact = crash:IsA("MeshPart") and crash.CollisionFidelity == Enum.CollisionFidelity.PreciseConvexDecomposition
		model:Destroy()
		assert(exact, "the first Ninja life should get its precise crash hull when the mesh loads")
	end)
	return result
end
return Spec
