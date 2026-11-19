-- Where guns can hang under each whole-shape skin (Alan 2026-11-19: guns floated under the skins' wings and their clips
-- showed from above). For every skin with an even fit, at its uploaded size in its own frame (studs, nose to -z), a grid
-- of the drawn skin's lowest underside seen from below, right half only (guns on the left mirror it): a ray up through
-- every cell centre against the exact drawn triangles (not the hidden hit copy). An empty cell has nothing above it.
-- Stored per skin as columns (x) of cell heights in hundredths, comma-separated, empty = nothing above. SkinFit hangs a
-- gun so its clip sits fully under drawn skin, its top touching the lowest underside over it, tilted to its slope.
-- Run in Studio's Edit (MCP execute_luau or the command bar); set SKINS to measure only a new skin; merge the JSON into
-- config/skin-undersides.json ("skins"; "clips" for every weapon, re-run after a new weapon model), then
-- python tools/generate_config.py. ~30 s.
local SKINS = nil -- e.g. { "dragon" }; nil = every skin with an even fit
local STEP = 0.1
local AssetService = game:GetService("AssetService")
local HttpService = game:GetService("HttpService")
local Root = game.ReplicatedStorage.FlyFightPaper
local copy = Root.Generated.SkinShapes:Clone() -- a clone: Edit mode caches require
copy.Parent = Root.Generated
local shapes = require(copy).shapes
copy:Destroy()
local out = {}
for id, shape in shapes do
	if not shape.even or (SKINS and not table.find(SKINS, id)) then continue end
	local pieces, lo, hi = {}, Vector3.one * math.huge, -Vector3.one * math.huge
	for name, piece in shape.pieces do
		if name == shape.hitPiece then continue end
		local a, b = Vector3.new(table.unpack(piece.min)), Vector3.new(table.unpack(piece.max))
		local em = AssetService:CreateEditableMeshAsync(Content.fromUri("rbxassetid://" .. piece.mesh))
		local mlo, mhi = Vector3.one * math.huge, -Vector3.one * math.huge
		for _, v in em:GetVertices() do local p = em:GetPosition(v); mlo, mhi = mlo:Min(p), mhi:Max(p) end
		-- the mesh fills its box (a, b): mesh point m sits at centre + (m - mesh centre) * box / mesh size
		table.insert(pieces, { em = em, centre = (a + b) / 2, k = (mhi - mlo) / (b - a), c = (mlo + mhi) / 2 })
		lo, hi = lo:Min(a), hi:Max(b)
	end
	local x0, z0 = 0, math.floor(lo.Z / STEP) * STEP
	local rows = {}
	for x = x0 + STEP / 2, hi.X, STEP do
		local cells = {}
		for z = z0 + STEP / 2, hi.Z, STEP do
			local best
			for _, q in pieces do
				local o = (Vector3.new(x, lo.Y - 1, z) - q.centre) * q.k + q.c
				local tri, point = q.em:RaycastLocal(o, Vector3.new(0, (hi.Y - lo.Y + 2) * q.k.Y, 0))
				if tri then
					local y = q.centre.Y + (point.Y - q.c.Y) / q.k.Y
					best = math.min(best or y, y)
				end
			end
			table.insert(cells, best and tostring(math.floor(best * 100 + 0.5)) or "")
		end
		table.insert(rows, table.concat(cells, ","))
		task.wait()
	end
	for _, q in pieces do q.em:Destroy() end
	out[id] = { step = STEP, x0 = x0, z0 = z0, columns = rows }
end
-- Each weapon's clip: the patch of its top within 5% of its height of its highest point, as shares of its launcher's
-- box (u across x, v from the front), widened by half a sample.
local clips = {}
for _, L in Root.Assets.AircraftPieces:GetChildren() do
	local look = string.match(L.Name, "^launcher_(.+)$")
	if not look then continue end
	local parts, lo, hi = {}, Vector3.one * math.huge, -Vector3.one * math.huge
	for _, c in L:GetChildren() do
		if not c:IsA("MeshPart") then continue end
		local em = AssetService:CreateEditableMeshAsync(Content.fromUri(c.MeshId))
		local mlo, mhi = Vector3.one * math.huge, -Vector3.one * math.huge
		for _, v in em:GetVertices() do local q = em:GetPosition(v); mlo, mhi = mlo:Min(q), mhi:Max(q) end
		table.insert(parts, { em = em, cf = c.CFrame, k = (mhi - mlo) / c.Size, c = (mlo + mhi) / 2 })
		for i = 0, 7 do
			local q = c.CFrame:PointToWorldSpace(c.Size / 2 * Vector3.new(i % 2 * 2 - 1, math.floor(i / 2) % 2 * 2 - 1, math.floor(i / 4) * 2 - 1))
			lo, hi = lo:Min(q), hi:Max(q)
		end
	end
	local H, NX, NZ = hi.Y - lo.Y, 48, 120
	local u0, u1, v0, v1 = 1, 0, 1, 0
	for i = 0, NX - 1 do
		for j = 0, NZ - 1 do
			local u, v = (i + 0.5) / NX, (j + 0.5) / NZ
			local from = Vector3.new(lo.X + u * (hi.X - lo.X), hi.Y + 5, lo.Z + v * (hi.Z - lo.Z))
			for _, q in parts do
				local tri, point = q.em:RaycastLocal(q.cf:PointToObjectSpace(from) * q.k + q.c, q.cf:VectorToObjectSpace(Vector3.new(0, -(H + 10), 0)) * q.k)
				if tri and q.cf:PointToWorldSpace((point - q.c) / q.k).Y >= hi.Y - 0.05 * H then
					u0, u1, v0, v1 = math.min(u0, u), math.max(u1, u), math.min(v0, v), math.max(v1, v)
					break
				end
			end
		end
		task.wait()
	end
	for _, q in parts do q.em:Destroy() end
	local function r(x) return math.floor(x * 1000 + 0.5) / 1000 end
	clips[look] = { r(math.max(0, u0 - 0.5 / NX)), r(math.min(1, u1 + 0.5 / NX)), r(math.max(0, v0 - 0.5 / NZ)), r(math.min(1, v1 + 0.5 / NZ)) }
end
return HttpService:JSONEncode({ skins = out, clips = clips })
