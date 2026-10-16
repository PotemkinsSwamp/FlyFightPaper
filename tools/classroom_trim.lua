local decor = workspace.Arena.ClassroomDecor
for _, c in ipairs(decor:GetChildren()) do if c.Name == "Wainscot" or c.Name == "ChairRail" or c.Name == "Baseboard" or c.Name:match("^PlanetSkin") then c:Destroy() end end
-- wall trim: brown baseboard, warm wood wainscot to chair-rail height, white chair rail (window wall keeps its sill)
local function trimRun(name, size, pos) local t = Instance.new("Part"); t.Name = name; t.Anchored = true; t.CanCollide = false; t.CanQuery = false; t.CanTouch = false
  t.Size = size; t.Position = pos; t.TopSurface = Enum.SurfaceType.Smooth; t.Parent = decor; return t end
for _, w in ipairs({{"z", -1100, 1}, {"z", 1100, -1}, {"x", 1400, -1}}) do
  local axis, face, inward = w[1], w[2], w[3]
  for i = -1, 1, 2 do   -- two halves so no part passes 2048
    local len = axis == "z" and 1400 or 1100
    local along = i * len / 2
    local function at(depth, y) if axis == "z" then return Vector3.new(along, y, face + inward * depth) else return Vector3.new(face + inward * depth, y, along) end end
    local function sz(d, h) if axis == "z" then return Vector3.new(len, h, d) else return Vector3.new(d, h, len) end end
    local wain = trimRun("Wainscot", sz(3, 160), at(1.5, 80)); wain.Color = Color3.fromRGB(226, 196, 150); wain.Material = Enum.Material.WoodPlanks
    local rail = trimRun("ChairRail", sz(6, 10), at(3, 163)); rail.Color = Color3.fromRGB(250, 246, 236)
    local base = trimRun("Baseboard", sz(6, 22), at(3, 11)); base.Color = Color3.fromRGB(150, 104, 66); base.Material = Enum.Material.Wood
  end
end
-- the three plain hanging balls (solid, in the classroom file) get planet skins of the same size
for i, spot in ipairs({{"Earth", -950, 535, 600}, {"Jupiter", 600, 535, -700}, {"Earth", 900, 535, 650}}) do
  local m = decor[spot[1]]:Clone(); m.Name = "PlanetSkin" .. i
  local _, s = m:GetBoundingBox(); m:ScaleTo(m:GetScale() * 40 / math.max(s.X, s.Y, s.Z))
  local cf = m:GetBoundingBox(); m:PivotTo(m:GetPivot() + (Vector3.new(spot[2], spot[3], spot[4]) - cf.Position))
  for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then d.CanCollide = false end end
  m.Parent = decor
end
return #decor:GetChildren()