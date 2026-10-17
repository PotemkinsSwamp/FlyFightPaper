-- Run in Studio (Edit) after tools/save_place.py: turns on exact collision for every solid mesh in the room that
-- loaded as Box. A part marked exact in the file without a saved shape loads as Box (2026-10-16: 453 new buildings
-- were solid boxes, gaps and all); setting it here makes Studio work the shapes out (minutes, Studio busy), then
-- Alan presses Ctrl+S and the next rebuild reuses them. The eraser stays a box (it is one).
local n = 0
for _, p in workspace.Arena:GetDescendants() do
	if p:IsA("MeshPart") and (p.CanCollide or p.CanQuery) and p.Transparency < 1
		and p.CollisionFidelity == Enum.CollisionFidelity.Box and not p:FindFirstAncestor("ChalkEraser") then
		p.CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition
		n += 1
		if n % 10 == 0 then task.wait() end
	end
end
return n .. " parts set to exact collision"
