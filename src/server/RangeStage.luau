-- The Hangar Range's stage (docs/plan/TUTORIAL-PLAN.md "The Hangar Range"): a kid-made puppet theatre built from the
-- flat painted pieces in UIAssets.range, each standing at its depth in front of the held plane. Spots and sizes were
-- measured from the concept (assets/references/ui-concepts/range-stage-view-2.png) as seen from the Range camera
-- (15 studs behind the plane, 4.5 up, 72° view). Pieces are lit by their own paint (LightInfluence 0), like the concept.
local Root=game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local Art=table.clone(require(Root.Shared.UIAssets).range)
Art.plainStrip=require(Root.Shared.UIAssets).trainingboard.stripGreen -- the Training board's green strip: no pin
local Course=require(Root.Shared.TrainingCourse)
local Stage={}

-- Pixel sizes of the uploaded pieces (assets/ui/range/ready/), for shapes and mirrored copies.
local PX={backdrop={1024,576},curtainSide={298,1024},lamp={673,1024},ledge={1024,128},bushes={1024,78},
 townRowA={1024,222},townRowB={1024,229},townRowC={1024,259},townArch={1024,910},townClock={326,1024},
 townStepped={625,1024},townTwin={1024,766},
 pickerClose={1024,674},pickerMedium={1024,681},pickerLong={1024,638},pickerAll={1024,1012},pickerStand={1024,329},
 board={644,1024},plainStrip={1024,308},title={1024,290},scoreCard={1024,569},selected={1024,301},
 stripGreen={1024,225},stripYellow={1024,225},stripRed={1024,225},stripPurple={1024,225},stripBlue={1024,225}}

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
local function flat(stage,origin,name,x,y,z,w,h)
 local p=part(stage,name,Vector3.new(w,h,.5),origin*CFrame.new(x,y,z));p.Transparency=1
 local gui=Instance.new("SurfaceGui");gui.Face=Enum.NormalId.Back;gui.LightInfluence=0;gui.MaxDistance=5000
 gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;gui.PixelsPerStud=1;gui.Parent=p
 return p,gui
end
local function paint(stage,origin,key,x,y,z,w,h,opt)
 opt=opt or {}
 local p,gui=flat(stage,origin,key,x,y,z,w,h)
 local img=Instance.new("ImageLabel");img.Size=UDim2.fromScale(1,1);img.BackgroundTransparency=1;img.Image=Art[key];img.Parent=gui
 local px=PX[key]
 if opt.tile then img.ScaleType=Enum.ScaleType.Tile;img.TileSize=UDim2.fromScale(h*px[1]/px[2]/w,1) end
 if opt.flip then img.ImageRectOffset=Vector2.new(px[1],0);img.ImageRectSize=Vector2.new(-px[1],px[2]) end
 return p
end
-- Width from height (or the other way) at the piece's own shape.
local function wide(key,h) return h*PX[key][1]/PX[key][2] end
local function tall(key,w) return w*PX[key][2]/PX[key][1] end
-- Words in dark ink on a painted piece. Scaled text stops at 100 px, so a small canvas keeps words big.
local function write(p,text,size,pos,align)
 local gui=p.SurfaceGui;gui.PixelsPerStud=6
 local word=Instance.new("TextLabel");word.Size=size;word.Position=pos;word.BackgroundTransparency=1;word.Text=text
 word.TextScaled=true;word.LineHeight=.85;word.TextColor3=Color3.fromRGB(43,38,52);word.TextXAlignment=align or Enum.TextXAlignment.Center
 word.FontFace=Font.new("rbxasset://fonts/families/Kalam.json",Enum.FontWeight.Bold);word.Parent=gui
 return word
end

-- The Range's controls (docs/plan/TUTORIAL-PLAN.md "The Hangar Range"; Alan 2026-10-19), clicked with the crosshair
-- (client RangeBoard): the row plates on the floor (one click switches rows), the score card with its Reset strip, and
-- the Range Menu and Hangar notes hanging on strings in the top corners; the menu drops on its strings over the middle of the
-- stage (loadouts, difficulty, Hangar). Each clickable piece carries `RangeBoard` (what it does), the plates
-- `RangePick`; the menu is the `RangeMenu` model, built hanging MENU_LIFT above the view until it drops.
local COLUMNS={
 {head="Loadouts",x=-27,items={{"load1","1   Loadout 1","stripGreen"},{"load2","2   Loadout 2","stripYellow"},{"load3","3   Loadout 3","stripRed"},{"load4","4   Loadout 4","stripPurple"},{"load5","5   Loadout 5","stripBlue"}}},
 {head="Difficulty",x=27,items={{"noob","Noob","stripGreen"},{"challenge","Challenge","stripYellow"},{"veteran","Veteran","stripRed"},{"maneuvers","Maneuvers","stripPurple"},{"hangar","Edit in Hangar","stripBlue"}}},
}
local PLATE={close="pickerClose",medium="pickerMedium",long="pickerLong",all="pickerAll"}
local FLOOR_Y,PICK_Z,MENU_Z,MENU_Y,MENU_LIFT=-56,-72,-60,20,90
local INK_EDGE=Color3.fromRGB(255,248,232)
local function shootable(p,what) p.Name="BoardStrip";p.CanQuery=true;p:SetAttribute("RangeBoard",what) end
local function label(stage,origin,text,x,y,z,w,h)
 local p=flat(stage,origin,"Label",x,y,z,w,h);write(p,text,UDim2.fromScale(1,1),UDim2.fromScale(0,0));return p
end
-- Two strings from `high` down to `low`, just behind a piece at depth z, so they run down behind its paper and hold it
-- (Alan 2026-10-19: strings ending at the top edge looked like the paper floated).
local function strings(stage,origin,x,low,high,w,z)
 for _,s in {-1,1} do
  part(stage,"String",Vector3.new(.25,high-low,.25),origin*CFrame.new(x+s*w*.35,(low+high)/2,z-.3),Color3.fromRGB(60,50,45))
 end
end
-- A piece hanging from above the view, or from `from` (the bottom of the piece above it).
local function hang(stage,origin,key,x,top,w,from)
 local h=tall(key,w);local p=paint(stage,origin,key,x,top-h/2,MENU_Z,w,h)
 strings(stage,origin,x,top-h*.6,from or top+40,w,MENU_Z)
 return p,h
end
local function controls(stage,origin)
 -- Row plates: a word on painted paper on a stick fixed to the hinge on its cardboard foot. The picked one tips back
 -- on the hinge, stick and all (RangeTargets, `Hinge`).
 for _,pick in Course.RANGE.picks do
  local key=PLATE[pick.row];local h=tall(key,pick.w)
  local foot=pick.w*.6;local footH=tall("pickerStand",foot);local hinge=FLOOR_Y+footH*.77;local stick=h*.35
  local plate=paint(stage,origin,key,pick.x,hinge+stick+h/2,PICK_Z,pick.w,h)
  plate.Name="Pick";plate.CanQuery=true;plate:SetAttribute("RangePick",pick.row)
  plate:SetAttribute("Hinge",(origin*CFrame.new(pick.x,hinge,PICK_Z)).Position)
  -- Kalam pads its letters a lot, so the boxes are bigger than the words look.
  local round,two=pick.row=="all",pick.label:find("\n")~=nil
  local word=write(plate,pick.label,round and UDim2.fromScale(.7,.36) or two and UDim2.fromScale(.9,1) or UDim2.fromScale(.8,.62),
   round and UDim2.fromScale(.15,.44) or two and UDim2.fromScale(.06,0) or UDim2.fromScale(.12,.1))
  local edge=Instance.new("UIStroke");edge.Color=INK_EDGE;edge.Thickness=3;edge.Parent=word
  -- The stick stands on the hinge's top leaf, in front of the foot and behind the plate.
  local length=stick+h*.25
  local rod=part(stage,"PickStick",Vector3.new(length,pick.w*.035,pick.w*.035),origin*CFrame.new(pick.x,hinge+length/2,PICK_Z-.5)*CFrame.Angles(0,0,math.rad(90)),Color3.fromRGB(205,165,110),Enum.Material.Wood)
  rod.Shape=Enum.PartType.Cylinder;rod:SetAttribute("StickOf",pick.row)
  paint(stage,origin,"pickerStand",pick.x,FLOOR_Y+footH/2,PICK_Z-1,foot,footH).Name="PickFoot"
 end
 -- Top right: the score card, its Reset strip just under it.
 local card,ch=hang(stage,origin,"scoreCard",72,50,24);card.Name="ScoreCard"
 for i,line in {"Hits  0","Shots  0","0%"} do
  write(card,line,UDim2.fromScale(.75,.29),UDim2.fromScale(.15,.08+(i-1)*.29),Enum.TextXAlignment.Left).Name="Line"..i
 end
 local rh=tall("stripBlue",20)
 local reset=paint(stage,origin,"stripBlue",74,50-ch-.4-rh/2,MENU_Z,20,rh);shootable(reset,"reset")
 write(reset,"Reset",UDim2.fromScale(.75,.8),UDim2.fromScale(.17,.1))
 -- At the left edge, level with the score card (the pair's middle on the card's), out of the targets' way and of a long
 -- lead ring's: Range Menu (click it again to fold the menu), and the Hangar strip hanging from it (Alan 2026-10-20).
 -- Plain strips, no pins: the strings hold them.
 local NOTE_X,NOTE_W=-84,22
 local NOTE_TOP=50-ch/2+tall("plainStrip",NOTE_W)+1.5
 local tab,tabH=hang(stage,origin,"plainStrip",NOTE_X,NOTE_TOP,NOTE_W);shootable(tab,"menu")
 write(tab,"Range Menu",UDim2.fromScale(.84,.8),UDim2.fromScale(.08,.1))
 local hangar=hang(stage,origin,"plainStrip",NOTE_X,NOTE_TOP-tabH-3,NOTE_W,NOTE_TOP-tabH*.3);shootable(hangar,"hangar")
 write(hangar,"Hangar",UDim2.fromScale(.84,.8),UDim2.fromScale(.08,.1))
 -- The menu: the board piece turned on its side at its own shape, the title and Back to range, two columns of strips.
 local sheet=Instance.new("Model");sheet.Name="RangeMenu";sheet.Parent=stage
 local W=118;local H=W*PX.board[1]/PX.board[2]
 local back=paint(sheet,origin,"board",0,MENU_Y,MENU_Z-3,W,H);back.Name="Sheet"
 local img=back.SurfaceGui.ImageLabel;img.AnchorPoint=Vector2.new(.5,.5);img.Position=UDim2.fromScale(.5,.5)
 img.Size=UDim2.fromScale(H/W,W/H);img.Rotation=90;sheet.PrimaryPart=back
 strings(sheet,origin,0,MENU_Y+H*.2,MENU_Y+H/2+120,W*1.2,MENU_Z-3)
 local top=MENU_Y+H/2-3
 local th=tall("title",38);paint(sheet,origin,"title",0,top-th/2,MENU_Z,38,th)
 local bh=tall("stripRed",30);local close=paint(sheet,origin,"stripRed",38,top-th/2,MENU_Z,30,bh);shootable(close,"close-menu")
 write(close,"Back to range",UDim2.fromScale(.8,.8),UDim2.fromScale(.12,.1))
 for _,c in COLUMNS do
  local y=top-th-1
  label(sheet,origin,c.head,c.x,y-3,MENU_Z,40,6);y-=7
  for _,item in c.items do
   local h=tall(item[3],42);local p=paint(sheet,origin,item[3],c.x,y-h/2,MENU_Z,42,h);shootable(p,item[1])
   write(p,item[2],UDim2.fromScale(.8,.8),UDim2.fromScale(.12,.1));y-=h+.6
  end
 end
 -- The red ring round the picked loadout and difficulty; RangeBoard moves them.
 for i,what in {"load1","noob"} do
  for _,p in sheet:GetChildren() do
   if p:GetAttribute("RangeBoard")==what then
    local ring=paint(sheet,origin,"selected",0,0,0,46,tall("selected",46));ring.CFrame=p.CFrame*CFrame.new(0,0,1);ring.Name="Ring"..i
   end
  end
 end
 sheet:PivotTo(sheet:GetPivot()+origin.UpVector*MENU_LIFT)
end

function Stage.build(origin)
 local stage=Instance.new("Model");stage.Name="RangeStage"
 stage.ModelStreamingMode=Enum.ModelStreamingMode.Atomic -- arrives whole, so RangeTargets finds every plate and stick
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
 part(stage,"Apron",Vector3.new(604,4,254),at(0,FLOOR_Y-2,25),FLOOR,card) -- the stage floor from the close row back under the plane to the hall's back wall
 -- The proscenium: curtains tied back at each side, a rail of hanging lamps across the top.
 paint(stage,origin,"curtainSide",-216,0,-150,87,300)
 paint(stage,origin,"curtainSide",216,0,-150,87,300,{flip=true})
 controls(stage,origin)
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
