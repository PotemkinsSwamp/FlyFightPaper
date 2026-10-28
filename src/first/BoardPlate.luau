-- A menu board (the 2x2 background tiles) drawn as a picture on a flat card inside the menu's own little 3D window
-- (a ViewportFrame). Same art, same place, but Roblox sends a 3D picture GPU-compressed: a 960x540 cork tile came as
-- 153 KB instead of ~1.15 MB as a menu picture (2026-10-27, docs/plan/LOAD-PLAN.md). The card exists only inside
-- this player's window: it is never in the world, and no one else sees it.
local BoardPlate = {}

-- ponytail: the board is always drawn 16:9 (PaperUI's 1920x1080 pages), so the card and camera are fixed to that.
local W, H = 32, 18 -- studs: four 16x9 tiles
local FOV = 20

-- A ViewportFrame showing the tiles (top-left, top-right, bottom-left, bottom-right) filling it exactly; size and
-- place it like the picture it replaces. Returns the frame and its decals (to preload).
function BoardPlate.new(ids)
	local view = Instance.new("ViewportFrame")
	view.Name, view.BackgroundTransparency = "Board", 1
	-- Flat light: the picture shows its own colours (white ambient, no sun).
	view.Ambient, view.LightColor = Color3.new(1, 1, 1), Color3.new(0, 0, 0)
	local decals = {}
	for i, id in ids do
		local card = Instance.new("Part")
		card.Anchored, card.Transparency, card.Size = true, 1, Vector3.new(W / 2, H / 2, 0.1)
		-- Seen from -Z looking at +Z, so the card's Front face (-Z) faces the camera and +X is screen left.
		card.CFrame = CFrame.new((i % 2 == 1 and 1 or -1) * W / 4, (i <= 2 and 1 or -1) * H / 4, 0)
		local decal = Instance.new("Decal")
		decal.Texture, decal.Face, decal.Parent = id, Enum.NormalId.Front, card
		card.Parent = view
		table.insert(decals, decal)
	end
	local camera = Instance.new("Camera")
	camera.FieldOfView = FOV
	camera.CFrame = CFrame.lookAt(Vector3.new(0, 0, -(H / 2) / math.tan(math.rad(FOV / 2))), Vector3.zero)
	camera.Parent, view.CurrentCamera = view, camera
	return view, decals
end

return BoardPlate
