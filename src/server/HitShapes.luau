-- Exact hitboxes. Roblox builds a precise collision shape from every plane part's mesh (body, nose, wings,
-- tail, mounted weapons, booster). Each pilot gets a private copy of their plane in a server-only WorldModel,
-- and a shot is tested by sweeping the projectile's own box through that copy, posed where the target was.
local AssetService=game:GetService("AssetService")
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper").Shared
local Rules=require(Shared.CombatRules)
local SkinFit=require(Shared.SkinFit)
local Shapes={}
local world=Instance.new("WorldModel");world.Name="HitShapes";world.Parent=game:GetService("ServerStorage")
local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include
-- A cast never reports a part it starts touching, so the shot's box is first checked for overlap where it starts
-- (a plane can step onto a shot between server steps: lessons.md "A shapecast never hits a part it starts touching").
local overlap=OverlapParams.new();overlap.FilterType=Enum.RaycastFilterType.Include
local probe=Instance.new("Part");probe.Name="ShotProbe";probe.Anchored=true;probe.CanCollide=false;probe.CanQuery=false;probe.CanTouch=false;probe.Parent=world
local precise={} -- mesh id -> precise MeshPart, false while loading, nil before asked
local copies={} -- pilot id -> {model=plane model it mirrors, folder=Model, complete=bool}

local function shape(mesh)
	if precise[mesh]==nil then
		precise[mesh]=false
		task.spawn(function()
			local ok,part=pcall(AssetService.CreateMeshPartAsync,AssetService,Content.fromUri(mesh),
				{CollisionFidelity=Enum.CollisionFidelity.PreciseConvexDecomposition})
			if ok then precise[mesh]=part else warn("Hit shape failed for "..mesh..": "..tostring(part)) end
		end)
	end
	return precise[mesh] or nil
end
-- Start building every shape at server start so the first fights already use them.
function Shapes.preload(folders)
	for _,folder in ipairs(folders) do for _,part in ipairs(folder:GetDescendants()) do
		if part:IsA("MeshPart") and part.MeshId~="" then shape(part.MeshId) end
	end end
end

-- An exact-shape stand-in for one of a plane's parts (its plain box until the precise shape has loaded).
function Shapes.solid(part)
	local source=shape(part.MeshId)
	local piece=source and source:Clone() or Instance.new("Part")
	piece.Size=part.Size;piece.CanCollide=false;piece.CanTouch=false
	return piece,source~=nil
end

-- A stand-in for every MeshPart in `appearance` (pieces[i] for parts[i]), placed in the plane's own frame (`frame`: its
-- Root's CFrame). Under a shape skin (SkinFit) the wings turn up about the drawn hinge and the guns and booster sit where
-- the skin draws them: shots and crashes meet the plane you see (Alan 2026-11-14, docs/plan/SKINS-PLAN.md "Wing-hitbox tilt").
-- Same sizes either way. A piece still waiting for its precise shape is a plain Part. The crash Colliders
-- (FlightService) and the hit copies use this.
function Shapes.place(appearance,frame,skin)
	local fitted=SkinFit.plane(skin,appearance,frame)
	local pieces,parts={},{}
	for _,part in ipairs(appearance:GetChildren()) do
		if part:IsA("MeshPart") then
			local piece=Shapes.solid(part)
			local move=fitted and (fitted.wings[part] or fitted.guns[part] or fitted.boosters[part]) or CFrame.identity
			piece.Name=part.Name;piece.CFrame=move*frame:ToObjectSpace(part.CFrame)
			table.insert(pieces,piece);table.insert(parts,part)
		end
	end
	return pieces,parts
end

-- The copy sits at the origin in the plane's own frame; rebuilt when the plane's parts or skin change or shapes finish loading.
local function copyOf(p)
	local copy=copies[p.id]
	local appearance=p.model:FindFirstChild("Appearance")
	if not appearance then return nil end
	if copy and copy.appearance==appearance and copy.skin==p.skin and copy.complete then return copy end
	if copy then copy.folder:Destroy() end
	-- ponytail: until the precise shapes arrive (well under a second) each part's own box stands in.
	local pieces,parts=Shapes.place(appearance,p.body.CFrame,p.skin)
	copy={appearance=appearance,skin=p.skin,folder=Instance.new("Model"),complete=true}
	for i,piece in ipairs(pieces) do
		if parts[i].Transparency<1 then -- hidden placeholder stickers are not hit shapes
			copy.complete=copy.complete and piece:IsA("MeshPart")
			piece.Anchored=true;piece.CanQuery=true;piece.Parent=copy.folder
		else piece:Destroy() end
	end
	copy.folder.Parent=world;copies[p.id]=copy
	return copy
end
function Shapes.forget(p)
	if copies[p.id] then copies[p.id].folder:Destroy();copies[p.id]=nil end
end

-- The Range's targets are flat cards facing the stage (RangeTargets draws them 26 by 13.6 studs), and the card is the
-- target itself (CombatService:addCard). The whole picture counts (Alan 2026-10-20: hitting the paper you see is a
-- hit); the stage faces down -Z like the world (TrainingCourse.RANGE has no turn). Returns the fraction of delta
-- travelled before touching, or nil.
local CARD=Vector3.new(26,13.6,2)
function Shapes.card(pose,origin,delta,size)
	if delta.Magnitude<1e-6 then return nil end
	-- Tilted with its heading, as RangeTargets draws it (nose up on a climb, whichever way it faces). Plain box maths,
	-- not a Blockcast: a cast never sees a part it starts touching, and a moving card can step onto a shot between
	-- steps (tests/unit/RangeAccuracy: 1 in 3,709 dead-on shots missed that way).
	-- ponytail: the shot counts as a ball of its thinnest half-width.
	local look=pose.LookVector;local tilt=math.clamp(math.atan2(look.Y,math.abs(look.X)),-.6,.6)
	local frame=CFrame.new(pose.Position)*CFrame.Angles(0,0,look.X>=0 and tilt or -tilt)
	return Rules.segmentBox(origin,delta,frame,CARD/2+Vector3.one*math.min(size.X,size.Y,size.Z)/2)
end
-- Sweep a projectile box (size, drawn with `rotation` around its travel direction) from origin along delta,
-- against target p posed at `pose`. Returns the fraction of delta travelled before touching, or nil.
-- Returns false when the target has no plane model to test (callers fall back to its body box).
function Shapes.cast(p,pose,origin,delta,size,rotation)
	local copy=copyOf(p)
	if not copy then return false end
	local from=pose:PointToObjectSpace(origin);local step=pose:VectorToObjectSpace(delta)
	if step.Magnitude<1e-6 then return nil end
	params.FilterDescendantsInstances={copy.folder}
	local up=pose:VectorToObjectSpace(Vector3.yAxis)
	if math.abs(step.Unit:Dot(up))>.99 then up=pose:VectorToObjectSpace(Vector3.zAxis) end
	local start=CFrame.lookAt(from,from+step,up)*rotation
	probe.Size,probe.CFrame=size,start;overlap.FilterDescendantsInstances={copy.folder}
	if #world:GetPartsInPart(probe,overlap)>0 then return 0 end
	local result=world:Blockcast(start,size,step,params)
	return result and result.Distance/step.Magnitude
end
return Shapes
