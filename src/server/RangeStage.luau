-- The Hangar Range's stage (docs/plan/TUTORIAL-PLAN.md "The Hangar Range"): a kid-made puppet theatre built from the
-- flat painted pieces in UIAssets.range, each standing at its depth in front of the held plane. Spots and sizes were
-- measured from the concept (assets/references/ui-concepts/range-stage-view-2.png) as seen from the Range camera
-- (15 studs behind the plane, 4.5 up, 72° view). Pieces are lit by their own paint (LightInfluence 0), like the concept.
local Root=game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local Art=require(Root.Shared.UIAssets).range
local Course=require(Root.Shared.TrainingCourse)
local Stage={}

-- Pixel sizes of the uploaded pieces (assets/ui/range/ready/), for shapes and mirrored copies.
local PX={backdrop={1024,576},curtainSide={298,1024},lamp={673,1024},ledge={1024,128},bushes={1024,78},
 townRowA={1024,222},townRowB={1024,229},townRowC={1024,259},townArch={1024,910},townClock={326,1024},
 townStepped={625,1024},townTwin={1024,766},stripGreen={1024,228},stripYellow={1024,227},stripPurple={1024,227},stripRed={1024,225},
 pickerClose={1024,674},pickerMedium={1024,681},pickerLong={1024,638},pickerAll={1024,1012},pickerStand={1024,329}}
-- Row-picker plates: a plane shape per row (green, yellow, purple) and a round one for All, with where the word goes.
-- ponytail: the side board's paper strips stand in until the plate pictures are uploaded (their ids in UIAssets).
local PLATE={close={"pickerClose","stripGreen"},medium={"pickerMedium","stripYellow"},long={"pickerLong","stripPurple"},all={"pickerAll","stripRed"}}

-- Ground rows: flat cardboard rows the target sticks rise from behind (close, middle, far). Heights put each row's lip
-- where the concept has it on screen, so they need not climb like real steps.
local ROWS={{z=-100,top=-55,h=45,w=800},{z=-330,top=-96,h=77,w=1600},{z=-590,top=-59,h=112,w=2400}}
-- The box round the stage: drapes the colour of the curtains, a cardboard floor, a dark ceiling.
local DRAPE,FLOOR,DARK=Color3.fromRGB(214,104,58),Color3.fromRGB(176,124,78),Color3.fromRGB(96,40,32)

local function part(stage,name,size,cf,color,material)
 local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color or DARK
 p.Material=material or Enum.Material.Fabric;p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false
 p.Parent=stage
 return p
end
-- A painted flat piece facing the plane. `tile` repeats it across (rows); `flip` mirrors it.
local function paint(stage,origin,key,x,y,z,w,h,opt)
 opt=opt or {}
 local p=part(stage,key,Vector3.new(w,h,.5),origin*CFrame.new(x,y,z));p.Transparency=1
 local gui=Instance.new("SurfaceGui");gui.Face=Enum.NormalId.Back;gui.LightInfluence=0;gui.MaxDistance=5000
 gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;gui.PixelsPerStud=1;gui.Parent=p
 local img=Instance.new("ImageLabel");img.Size=UDim2.fromScale(1,1);img.BackgroundTransparency=1;img.Image=Art[key];img.Parent=gui
 local px=PX[key]
 if opt.tile then img.ScaleType=Enum.ScaleType.Tile;img.TileSize=UDim2.fromScale(h*px[1]/px[2]/w,1) end
 if opt.flip then img.ImageRectOffset=Vector2.new(px[1],0);img.ImageRectSize=Vector2.new(-px[1],px[2]) end
 return p
end
-- Width from height (or the other way) at the piece's own shape.
local function wide(key,h) return h*PX[key][1]/PX[key][2] end

function Stage.build(origin)
 local stage=Instance.new("Model");stage.Name="RangeStage"
 local function at(x,y,z) return origin*CFrame.new(x,y,z) end
 -- The painted sky cloth and the box round it (floor, ceiling, the wings and the dark hall the plane hangs in).
 paint(stage,origin,"backdrop",0,-144,-820,3000,1688)
 local card=Enum.Material.Cardboard
 part(stage,"Floor",Vector3.new(3000,4,740),at(0,-177,-460),FLOOR,card)
 part(stage,"Ceiling",Vector3.new(3000,4,700),at(0,700,-480))
 for _,s in {-1,1} do
  part(stage,"Wing",Vector3.new(945,1000,4),at(s*727,100,-152),DRAPE)
  part(stage,"HallSide",Vector3.new(4,600,304),at(s*300,100,0),DRAPE)
 end
 part(stage,"Header",Vector3.new(520,480,4),at(0,370,-152),DRAPE)
 part(stage,"HallBack",Vector3.new(604,600,4),at(0,100,152),DRAPE)
 part(stage,"HallFloor",Vector3.new(604,4,252),at(0,-100,25),FLOOR,card)
 part(stage,"HallCeiling",Vector3.new(604,4,304),at(0,300,0))
 -- The cardboard town in three depths: two rows of houses, then the landmarks, with bushes along their feet.
 local function houses(z,bottom,h,order,x)
  local i=0
  while x<1500 do
   local key=order[i%#order+1];local w=wide(key,h)
   paint(stage,origin,key,x+w/2,bottom+h/2,z,w,h);x+=w;i+=1
  end
 end
 houses(-760,-85,210,{"townRowA","townRowB","townRowC"},-1500)
 houses(-730,-80,165,{"townRowC","townRowA","townRowB"},-1400)
 for _,l in {{"townArch",-800,260},{"townStepped",-460,320},{"townTwin",-22,260},{"townClock",330,300},
  {"townArch",800,260,true},{"townStepped",1150,320,true}} do
  local key,h=l[1],l[3]
  paint(stage,origin,key,l[2],-73+h/2,-700,wide(key,h),h,{flip=l[4]})
 end
 paint(stage,origin,"bushes",0,-36,-660,3000,70,{tile=true})
 -- Ground rows with a row of warm bulbs along each lip.
 local bulbs=Instance.new("Folder");bulbs.Name="Bulbs";bulbs.Parent=stage
 for _,r in ROWS do
  paint(stage,origin,"ledge",0,r.top-r.h/2,r.z,r.w,r.h,{tile=true})
  local size=r.h*.11;local step=size*7
  for x=-r.w/2+step/2,r.w/2,step do
   local b=part(bulbs,"Bulb",Vector3.one*size,at(x,r.top-size*.3,r.z+1),Color3.fromRGB(255,214,140))
   b.Shape=Enum.PartType.Ball;b.Material=Enum.Material.Neon
  end
 end
 -- Bulb strips along the hall's sides and the header's edge, so the edges of the view still read as the theatre.
 for _,s in {-1,1} do
  for _,y in {-60,120} do
   for z=-140,140,24 do
    local b=part(bulbs,"Bulb",Vector3.one*4,at(s*297,y,z),Color3.fromRGB(255,214,140));b.Shape=Enum.PartType.Ball;b.Material=Enum.Material.Neon
   end
  end
 end
 for x=-250,250,24 do
  local b=part(bulbs,"Bulb",Vector3.one*4,at(x,134,-149),Color3.fromRGB(255,214,140));b.Shape=Enum.PartType.Ball;b.Material=Enum.Material.Neon
 end
 -- The row picker: knock-down plates standing on the close row's lip, each a word on painted paper. A shot that
 -- hits one picks its rows (RoundRuntime:rangePick); RangeTargets tips the picked one back.
 local lip=ROWS[1]
 for _,pick in Course.RANGE.picks do
  local real=Art[PLATE[pick.row][1]] and PLATE[pick.row][1]
  local key=real or PLATE[pick.row][2];local h=real and pick.w*PX[key][2]/PX[key][1] or pick.w*.4
  local plate=paint(stage,origin,key,pick.x,lip.top+2+h/2,lip.z-3,pick.w,h)
  plate.Name="Pick";plate.CanQuery=true;plate:SetAttribute("RangePick",pick.row)
  local gui=plate.SurfaceGui;gui.PixelsPerStud=40
  local round=pick.row=="all" and real
  local word=Instance.new("TextLabel");word.Size=UDim2.fromScale(round and .6 or .74,round and .26 or .4)
  word.Position=UDim2.fromScale(round and .2 or .16,round and .5 or .2)
  word.BackgroundTransparency=1;word.Text=pick.label;word.TextScaled=true;word.TextColor3=Color3.fromRGB(43,38,52)
  word.FontFace=Font.new("rbxasset://fonts/families/Kalam.json",Enum.FontWeight.Bold);word.Parent=gui
  local edge=Instance.new("UIStroke");edge.Color=Color3.fromRGB(255,248,232);edge.Thickness=3;edge.Parent=word
  if Art.pickerStand then
   local w=pick.w*.5;paint(stage,origin,"pickerStand",pick.x,lip.top+w*329/1024/2,lip.z-2.5,w,w*329/1024).Name="PickFoot"
  else part(stage,"PickFoot",Vector3.new(pick.w*.3,2,2),at(pick.x,lip.top+1,lip.z-3),FLOOR,card) end
 end
 -- The proscenium: curtains tied back at each side, a rail of hanging lamps across the top.
 paint(stage,origin,"curtainSide",-216,0,-150,87,300)
 paint(stage,origin,"curtainSide",216,0,-150,87,300,{flip=true})
 local rail=part(stage,"LampRail",Vector3.new(520,3,3),at(0,128,-149),Color3.fromRGB(70,60,55))
 rail.Shape=Enum.PartType.Cylinder
 -- Each lamp throws a soft warm beam down onto the stage (a Beam: always faces the camera, costs no light).
 for _,x in {-150,-90,-30,30,90,150} do
  local lamp=paint(stage,origin,"lamp",x,107,-148,wide("lamp",42),42)
  local a0=Instance.new("Attachment");a0.Position=Vector3.new(0,-17,0);a0.Parent=lamp
  local a1=Instance.new("Attachment");a1.Parent=lamp;a1.WorldCFrame=at(x*2.2,-60,-520)
  local beam=Instance.new("Beam");beam.Attachment0=a0;beam.Attachment1=a1;beam.Width0=8;beam.Width1=150
  beam.Color=ColorSequence.new(Color3.fromRGB(255,236,190));beam.LightEmission=1;beam.LightInfluence=0;beam.FaceCamera=true
  beam.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.7),NumberSequenceKeypoint.new(.6,.9),NumberSequenceKeypoint.new(1,1)})
  beam.Segments=1;beam.Parent=lamp
 end
 stage.Parent=workspace
 return stage
end

return Stage
