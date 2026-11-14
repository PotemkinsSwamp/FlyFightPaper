-- Shape skins on the server (SkinFit + HitShapes.place + FlightService colliders/wear): under the crane the real wings'
-- hit and crash shapes turn up by the crane's rise about the hinge the screen draws, keep their exact size, and the
-- guns' shapes move by the same offsets the screen's fit gives. A plane without a shape skin is unchanged.
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
	-- Two different builds with guns on the body and under a wing: the Fighter, and a slim body on swept wings with a
	-- booster and a crayon under its left wing.
	local swept = catalog:classLoadout("striker", 99)
	swept.wings, swept.weapon_mounts[3] = "wings_4", "crayon"
	local builds = { fighter = catalog:classLoadout("fighter", 99), swept = swept }
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
	return result
end
return Spec
