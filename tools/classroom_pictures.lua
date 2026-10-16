-- Wall pictures and hangar number tags, in ClassroomDecor. Run in Studio (execute_luau), then
-- re-export ClassroomDecor with tools/studio_export.lua. Picture ids: assets/textures/classroom/upload.json.
local decor = workspace.Arena.ClassroomDecor
for _, c in ipairs(decor:GetChildren()) do
  if c.Name:match("^Picture") or c.Name == "HangarNumber" then c:Destroy() end
end
local function part(name, size, cf, color)
  local p = Instance.new("Part"); p.Name = name; p.Anchored = true; p.CanCollide = false; p.CanQuery = false
  p.CanTouch = false; p.CastShadow = false; p.Size = size; p.CFrame = cf; p.Color = color or Color3.new(1, 1, 1)
  p.Material = Enum.Material.SmoothPlastic; p.TopSurface = Enum.SurfaceType.Smooth; p.Parent = decor; return p
end
local function decal(p, id, transparent)
  local d = Instance.new("Decal"); d.Texture = "rbxassetid://" .. id; d.Face = Enum.NormalId.Front; d.Parent = p
  if transparent then p.Transparency = 1 end
end
-- each wall: where a picture sits (along = x on north/south, z on east) and the turn that faces it into the room
local NORTH = {at = function(u, y) return Vector3.new(u, y, -1099) end, turn = CFrame.Angles(0, math.pi, 0)}
local SOUTH = {at = function(u, y) return Vector3.new(u, y, 1099) end, turn = CFrame.identity}
local EAST = {at = function(u, y) return Vector3.new(1399, y, u) end, turn = CFrame.Angles(0, math.pi / 2, 0)}
-- name, image id, wall, along, y, width, height, border colour (nil: paper taped to the wall), tilt (degrees)
local pictures = {
  {"AlphabetBanner", "127851759818215", NORTH, 0, 478, 640, 80, nil, 0},
  {"SolarSystem", "84104908282105", NORTH, -899, 316, 270, 180, Color3.fromRGB(60, 90, 170), 0},
  {"ClassRules", "102479042747277", NORTH, 460, 320, 120, 180, Color3.fromRGB(230, 70, 60), 0},
  {"DrawingPlane", "91318445445422", NORTH, 610, 395, 120, 90, nil, -4},
  {"DrawingHouse", "104933894347970", NORTH, 615, 265, 120, 90, nil, 3},
  {"FoldAPlane", "121582670286424", SOUTH, -1000, 330, 140, 210, Color3.fromRGB(250, 200, 60), 0},
  {"DrawingRocket", "103063732517460", SOUTH, 820, 330, 120, 90, nil, -3},
  {"ReadingCorner", "90551416783810", EAST, -480, 435, 200, 150, Color3.fromRGB(70, 160, 90), 0},
  {"StarPilots", "93471756563757", EAST, 480, 430, 240, 160, Color3.fromRGB(230, 70, 60), 0},
  {"WeatherChart", "72908726121697", EAST, -850, 330, 140, 210, Color3.fromRGB(60, 140, 210), 0},
  {"PlaneGarland", "111285522584071", EAST, 0, 300, 480, 80, nil, 0},
  -- more wall decor for the blank spots (Alan, 2026-10-11; brief .planning/briefs/2026-10-11-wall-decor.md)
  {"HandprintTree", "130841572778853", NORTH, -1220, 330, 200, 250, nil, 0},
  {"DrawingDino", "108481781932152", NORTH, -620, 380, 130, 98, nil, -3},
  {"DrawingRainbow", "84591700418278", NORTH, -470, 265, 130, 98, nil, 4},
  {"Birthdays", "130546354956076", NORTH, 1180, 320, 260, 200, Color3.fromRGB(240, 130, 180), 0},
  {"PaperButterflies", "127896322874131", SOUTH, -1240, 340, 220, 200, nil, 0},
  {"DrawingCat", "71768797420345", SOUTH, -815, 330, 140, 105, nil, 3},
  {"PlaneHallOfFame", "87948201929343", SOUTH, -105, 330, 300, 210, Color3.fromRGB(150, 100, 60), 0},
  {"DrawingBeach", "91203260013602", SOUTH, 620, 340, 150, 112, nil, -2},
  {"Shapes", "95664927538815", SOUTH, 1140, 320, 260, 200, Color3.fromRGB(130, 90, 210), 0},
  {"GiraffeChart", "76959398242348", EAST, -1010, 330, 100, 300, nil, 0},
  {"PlaneParts", "102213806332157", EAST, 850, 340, 270, 180, Color3.fromRGB(60, 150, 90), 0},
}
local cutout = {PlaneGarland = true, HandprintTree = true, PaperButterflies = true, GiraffeChart = true}
for _, p in ipairs(pictures) do
  local cf = CFrame.new(p[3].at(p[4], p[5])) * p[3].turn * CFrame.Angles(0, 0, math.rad(p[9]))
  if p[8] then part("PictureFrame", Vector3.new(p[6] + 12, p[7] + 12, 1), cf, p[8]) end
  decal(part("Picture" .. p[1], Vector3.new(p[6], p[7], 0.4), cf + cf.LookVector * 0.8), p[2], cutout[p[1]])
end
-- chalk drawing on the board (transparent image) and pinned papers on the bulletin board
decal(part("PictureChalkArt", Vector3.new(570, 190, 0.2), CFrame.new(0, 318, -1090.2) * NORTH.turn), "81868224959608", true)
decal(part("PictureBulletinPapers", Vector3.new(320, 225, 0.2), CFrame.new(300, 340, 1091.8)), "112521424302344", true)
-- the wall clock moves from above the chalkboard to the middle of the east wall, above the cubby (Alan)
decor.WallClock:PivotTo(CFrame.new(1389.55, 460, 0))   -- face toward -X, back on the wall
-- the photo world map becomes the kids' map
decor.WorldMap:FindFirstChildWhichIsA("Decal", true).Texture = "rbxassetid://114776983951619"
-- desk runways, rings and lights are toys now: tools/desk_pieces.py
return #decor:GetChildren()
