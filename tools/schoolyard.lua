-- Builds Workspace.Arena.Schoolyard in Studio (run with tools/studio_cli.py execute_luau, Edit mode), then export it to
-- assets/models/schoolyard.rbxm. Playground pieces, fence, trees and houses are town toys (assets/rug/toy-placements.json).
-- Kid scale from the desks (108 studs ~ a 0.65 m school desk): 1 ft = 50 studs. Ground level = classroom floor (y 0).
local old = workspace.Arena:FindFirstChild("Schoolyard"); if old then old:Destroy() end
local yard = Instance.new("Model"); yard.Name = "Schoolyard"; yard.Parent = workspace.Arena
local FT = 50
local function part(name, size, cf, color, mat, parent)
  local p = Instance.new("Part"); p.Name = name; p.Anchored = true; p.CanCollide = false; p.CanTouch = false; p.CanQuery = false
  p.Size = size; p.CFrame = typeof(cf) == "CFrame" and cf or CFrame.new(cf); p.Color = color; p.Material = mat or Enum.Material.SmoothPlastic
  p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth; p.Parent = parent or yard; return p
end
local function area(name, x0, x1, z0, z1, top, color, mat)   -- parts max out at 2048 a side, so big areas are tiled
  local nx, nz = math.ceil((x1 - x0) / 2000), math.ceil((z1 - z0) / 2000)
  local w, d = (x1 - x0) / nx, (z1 - z0) / nz
  for i = 0, nx - 1 do for j = 0, nz - 1 do
    part(name, Vector3.new(w, 4, d), Vector3.new(x0 + (i + .5) * w, top - 2, z0 + (j + .5) * d), color, mat)
  end end
end
-- a painted or chalk stroke from a to b, in a frame (origin + yaw) so drawings can sit at any angle
local function stroke(n, frame, x0, z0, x1, z1, y, c, wid, transp)
  local a, b = frame * Vector3.new(x0, 0, z0), frame * Vector3.new(x1, 0, z1)
  a, b = Vector3.new(a.X, y, a.Z), Vector3.new(b.X, y, b.Z)
  local p = part(n, Vector3.new(wid, 0.3, (b - a).Magnitude + wid), CFrame.lookAt((a + b) / 2, b), c)
  p.Transparency = transp or 0
end
local function arc(n, frame, cx, cz, r, a0, a1, y, c, wid, transp, wobble)
  local k = math.max(8, math.floor(math.rad(math.abs(a1 - a0)) * r / 60))
  local function pt(i) local t = math.rad(a0 + (a1 - a0) * i / k); local rr = r + (wobble or 0) * math.sin(i * 2.7)
    return cx + rr * math.cos(t), cz + rr * math.sin(t) end
  for i = 0, k - 1 do local x0, z0 = pt(i); local x1, z1 = pt(i + 1); stroke(n, frame, x0, z0, x1, z1, y, c, wid, transp) end
end
-- ground all the way to the horizon so the tree line and houses stand on something
area("Grass", -16000, -1408, -12000, 12000, 0, Color3.fromRGB(92, 160, 66), Enum.Material.Grass)
-- elementary full court 60 x 40 ft with a thin concrete border
local cx, cz, L, W, BT = -3500, 1300, 30 * FT, 20 * FT, 0.6
area("Blacktop", cx - L - 100, cx + L + 100, cz - W - 100, cz + W + 100, BT, Color3.fromRGB(72, 74, 80), Enum.Material.Asphalt)
local top, white, court = BT + 0.2, Color3.fromRGB(240, 240, 232), CFrame.new(cx, 0, cz)
local function line(x0, z0, x1, z1) stroke("Court", court, x0, z0, x1, z1, top, white, 9) end
line(-L, -W, L, -W); line(-L, W, L, W); line(-L, -W, -L, W); line(L, -W, L, W); line(0, -W, 0, W)
arc("Court", court, 0, 0, 6 * FT, 0, 360, top, white, 9)
for _, s in ipairs({-1, 1}) do
  local base, basket, ftx, r = s * L, s * (L - 4.5 * FT), s * (L - 15 * FT), 15 * FT
  line(base, -6 * FT, ftx, -6 * FT); line(base, 6 * FT, ftx, 6 * FT); line(ftx, -6 * FT, ftx, 6 * FT)
  part("CourtKeyPaint", Vector3.new(15 * FT, 0.2, 12 * FT), Vector3.new(cx + (base + ftx) / 2, top - 0.05, cz), Color3.fromRGB(178, 58, 52))
  arc("Court", court, ftx, 0, 6 * FT, s > 0 and 90 or -90, s > 0 and 270 or 90, top, white, 9)
  arc("Court", court, basket, 0, r, s > 0 and 90 or -90, s > 0 and 270 or 90, top, white, 9)
  line(base, -r, basket, -r); line(base, r, basket, r)
end
-- chalk drawings kids made on the court: wobbly, pastel, a bit see-through, at odd angles
local chalk = {Color3.fromRGB(255, 170, 200), Color3.fromRGB(150, 210, 255), Color3.fromRGB(255, 235, 140), Color3.fromRGB(190, 240, 170), Color3.fromRGB(250, 250, 245)}
local ct, cw, ca = top + 0.15, 7, 0.15
local hop = CFrame.new(cx + 600, 0, cz - 640) * CFrame.Angles(0, math.rad(7), 0)   -- hopscotch along x
local rows = {{0}, {0}, {-1, 1}, {0}, {-1, 1}, {0}, {-1, 1}, {0}}
for i, r in ipairs(rows) do for _, s in ipairs(r) do
  local x, z, h = -(i - 1) * 1.7 * FT, s * 0.85 * FT, 0.85 * FT
  local c = chalk[(i + s) % 4 + 1]
  stroke("Chalk", hop, x - h, z - h, x + h, z - h, ct, c, cw, ca); stroke("Chalk", hop, x - h, z + h, x + h, z + h, ct, c, cw, ca)
  stroke("Chalk", hop, x - h, z - h, x - h, z + h, ct, c, cw, ca); stroke("Chalk", hop, x + h, z - h, x + h, z + h, ct, c, cw, ca)
end end
arc("Chalk", hop, -9 * 1.7 * FT, 0, 0.9 * FT, 90, 270, ct, chalk[1], cw, ca, 4)   -- the half-moon at the end
local four = CFrame.new(cx - 900, 0, cz + 520) * CFrame.Angles(0, math.rad(-11), 0)   -- four-square, 8 ft boxes
for _, k in ipairs({-8, 0, 8}) do
  stroke("Chalk", four, k * FT, -8 * FT, k * FT, 8 * FT, ct, chalk[5], cw, ca); stroke("Chalk", four, -8 * FT, k * FT, 8 * FT, k * FT, ct, chalk[5], cw, ca)
end
local sun = CFrame.new(cx - 150, 0, cz + 650)
arc("Chalk", sun, 0, 0, 2.2 * FT, 0, 360, ct, chalk[3], cw + 2, ca, 6)
for a = 0, 330, 30 do local t = math.rad(a); stroke("Chalk", sun, 2.7 * FT * math.cos(t), 2.7 * FT * math.sin(t), 3.8 * FT * math.cos(t), 3.8 * FT * math.sin(t), ct, chalk[3], cw, ca) end
local star = CFrame.new(cx + 250, 0, cz - 300) * CFrame.Angles(0, math.rad(20), 0)
for i = 0, 4 do local t0, t1 = math.rad(90 + i * 144), math.rad(90 + (i + 1) * 144)
  stroke("Chalk", star, 2 * FT * math.cos(t0), 2 * FT * math.sin(t0), 2 * FT * math.cos(t1), 2 * FT * math.sin(t1), ct, chalk[2], cw, ca) end
-- a bed (wood chips or sand) with timber edging; edges are split so no board passes 2048
local function bed(name, x0, x1, z0, z1, top, color, mat)
  area(name, x0, x1, z0, z1, top, color, mat)
  local timber = Color3.fromRGB(120, 82, 48)
  for _, e in ipairs({{x0, z0, x1, z0}, {x0, z1, x1, z1}, {x0, z0, x0, z1}, {x1, z0, x1, z1}}) do
    local len = math.max(math.abs(e[3] - e[1]), math.abs(e[4] - e[2])); local n = math.ceil(len / 2000)
    for i = 0, n - 1 do
      local a, b = (i + .5) / n, len / n
      local x, z = e[1] + (e[3] - e[1]) * a, e[2] + (e[4] - e[2]) * a
      part(name .. "Edge", e[1] == e[3] and Vector3.new(16, 20, b + 16) or Vector3.new(b + 16, 20, 16), Vector3.new(x, 10, z), timber, Enum.Material.Wood)
    end
  end
end
-- wood-chip play area (far half) and a sand volleyball pit (near half) beside the court
bed("Mulch", -5000, -3500, -2300, -200, 1.5, Color3.fromRGB(140, 98, 62), Enum.Material.Ground)
local vx0, vx1, vz0, vz1 = -3400, -2050, -2300, -200
bed("Sand", vx0, vx1, vz0, vz1, 3, Color3.fromRGB(228, 205, 152), Enum.Material.Sand)
local vc, vn = (vx0 + vx1) / 2, (vz0 + vz1) / 2
local rope = Color3.fromRGB(40, 110, 200)
for _, l in ipairs({{-550, -900, 550, -900}, {-550, 900, 550, 900}, {-550, -900, -550, 900}, {550, -900, 550, 900}}) do
  stroke("CourtRope", CFrame.new(vc, 0, vn), l[1], l[2], l[3], l[4], 3.3, rope, 8)
end
for _, s in ipairs({-1, 1}) do   -- net posts just outside the side lines, across the middle
  local post = part("NetPost", Vector3.new(330, 14, 14), CFrame.new(vc + s * 640, 165, vn) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(205, 210, 215), Enum.Material.Metal)
  post.Shape = Enum.PartType.Cylinder
  part("NetPostBase", Vector3.new(40, 6, 40), Vector3.new(vc + s * 640, 3, vn), Color3.fromRGB(90, 90, 95), Enum.Material.Metal)
end
part("Net", Vector3.new(1270, 140, 1), Vector3.new(vc, 245, vn), Color3.fromRGB(30, 30, 34), Enum.Material.Fabric).Transparency = 0.45
part("NetTape", Vector3.new(1270, 10, 3), Vector3.new(vc, 318, vn), Color3.fromRGB(245, 245, 240), Enum.Material.Fabric)
part("NetTape", Vector3.new(1270, 6, 3), Vector3.new(vc, 176, vn), Color3.fromRGB(245, 245, 240), Enum.Material.Fabric)
local ball = part("Volleyball", Vector3.new(36, 36, 36), Vector3.new(vc + 260, 21, vn + 420), Color3.fromRGB(250, 235, 120), Enum.Material.SmoothPlastic)
ball.Shape = Enum.PartType.Ball
-- U-shaped school: two brick wings (two floors), windows facing the yard; the classroom's building runs between them
local brick, frame, glassC = Color3.fromRGB(176, 92, 66), Color3.fromRGB(245, 242, 232), Color3.fromRGB(88, 128, 168)
local WX = -6200
for _, side in ipairs({-1, 1}) do
  local w = Instance.new("Model"); w.Name = side < 0 and "WingNorth" or "WingSouth"; w.Parent = yard
  local face = side * 3000; local zc = face + side * 600
  for x0 = -1408, WX + 1, -2000 do
    local x1 = math.max(x0 - 2000, WX)
    part("Wall", Vector3.new(x0 - x1, 1300, 1200), Vector3.new((x0 + x1) / 2, 650, zc), brick, Enum.Material.Brick, w)
    part("Roof", Vector3.new(x0 - x1, 40, 1260), Vector3.new((x0 + x1) / 2, 1320, zc), Color3.fromRGB(88, 88, 94), Enum.Material.Concrete, w)
  end
  for floor = 0, 1 do for x = -1900, WX + 300, -450 do
    local y, f = 380 + floor * 600, face - side * 3
    part("Window", Vector3.new(260, 300, 2), Vector3.new(x, y, face - side * 1), glassC, Enum.Material.Glass, w).Reflectance = 0.25
    part("Frame", Vector3.new(276, 14, 6), Vector3.new(x, y + 157, f), frame, nil, w); part("Frame", Vector3.new(276, 14, 6), Vector3.new(x, y - 157, f), frame, nil, w)
    part("Frame", Vector3.new(14, 328, 6), Vector3.new(x - 136, y, f), frame, nil, w); part("Frame", Vector3.new(14, 328, 6), Vector3.new(x + 136, y, f), frame, nil, w)
    part("Frame", Vector3.new(8, 328, 6), Vector3.new(x, y, f), frame, nil, w)
  end end
  part("MainBuilding", Vector3.new(400, 1300, 1890), Vector3.new(-1210, 650, side * (1110 + 945)), brick, Enum.Material.Brick)
end
return #yard:GetDescendants()
