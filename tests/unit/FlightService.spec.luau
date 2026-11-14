local Flight=require(game.ServerScriptService.FlyFightPaper.FlightService)
local Root=game.ReplicatedStorage.FlyFightPaper
local Looks=require(Root.Shared.LooksRules)
local Suite=require(script.Parent.Parent.fixtures.Suite)
local Spec={}
function Spec.run()
 local result,test=Suite.new()
 local function fixture()
  local f=setmetatable({padReservations={pad="owner",other="owner"},landingQueues={},byId={}},Flight)
  local home=CFrame.new(0,100,0)
  local function pilot(id)
   local m=Instance.new("Folder");m.Parent=game.ServerStorage;m:SetAttribute("State","FLYING")
   local p={id=id,model=m,home=home};f.byId[id]=p;return p
  end
  return f,home,pilot
 end
 local function withAddedPilot(player,options,check)
  local container=Instance.new("Folder");container.Parent=game.ServerStorage
  local template=Instance.new("Model");template.Parent=container
  local body=Instance.new("Part");body.Name="Root";body.Anchored=true;body.Parent=template
  local planes=Instance.new("Folder");planes.Parent=container
  local desk=Instance.new("Part");desk.Name="DeskSouth1";desk.Anchored=true;desk.Parent=container
  -- Keep the real flight builder; absent test parts skip art and mesh requests.
  local catalog={starterLoadout=function()return {body="looks-test-body",nose="looks-test-nose",wings="looks-test-wings",tail="looks-test-tail",weapon_mounts={}} end,
   deriveStats=function()return {health=100,lift=90,speed=100,turn=90,pitch=90,yaw=90} end,get=function()return nil end}
  local f=setmetatable({catalog=catalog,
   template=template,planes=planes,desks={desk},seats={},padReservations={},pilots={},byId={},records={}},Flight)
  local ok,why=pcall(function() check(f,assert(f:add(player,options))) end)
  container:Destroy();assert(ok,why)
 end
 test("a player added with saved looks wears them on the built model and on its replacement",function()
  local player={UserId=12345,DisplayName="Test pilot"}
  withAddedPilot(player,{skin="shark_jet",trail="water_spray"},function(f,p)
   assert(p.kind=="human" and p.skin=="shark_jet" and p.trail=="water_spray")
   assert(p.model:GetAttribute("Skin")=="shark_jet" and p.model:GetAttribute("Trail")=="water_spray")
   local first=p.model;f:replace(p)
   assert(first.Parent==nil and p.model~=first and p.model:GetAttribute("Skin")=="shark_jet" and p.model:GetAttribute("Trail")=="water_spray")
  end)
 end)
 test("players with empty, missing or independent saved looks keep only their selected attributes",function()
  for _,options in ipairs({{skin="",trail=""},{},{skin="shark_jet",trail=""},{skin="",trail="confetti"}}) do
   withAddedPilot({UserId=12345,DisplayName="Test pilot"},options,function(_,p)
    local skin=options.skin~="" and options.skin or nil;local trail=options.trail~="" and options.trail or nil
    assert(p.skin==skin and p.trail==trail and p.model:GetAttribute("Skin")==skin and p.model:GetAttribute("Trail")==trail)
   end)
  end
 end)
 test("bots keep difficulty-based skins and trails even when player look options are supplied",function()
  for _,tier in ipairs({"rookie","regular","experienced","ace"}) do
   withAddedPilot(nil,{id="look-test-bot",name="Test bot",tier=tier,skin="dragon",trail="dragon_embers"},function(f,p)
    local skin=assert(Looks.item(p.skin));local trail=assert(Looks.item(p.trail))
    assert(p.kind=="bot" and skin.tier==Looks.config().bot_tiers[tier] and trail.kind=="trail")
    assert(skin.trail and p.trail==skin.trail or not skin.trail and trail.sold)
    assert(p.model:GetAttribute("Skin")==p.skin and p.model:GetAttribute("Trail")==p.trail)
    local firstSkin,firstTrail=p.skin,p.trail;f:replace(p)
    assert(p.skin==firstSkin and p.trail==firstTrail and p.model:GetAttribute("Skin")==firstSkin and p.model:GetAttribute("Trail")==firstTrail)
   end)
  end
 end)
 test("occupied pads queue approaches in arrival order without stacking",function()
  local f,home,pilot=fixture();local a,b=pilot("a"),pilot("b")
  assert(not f:land(a,home,"pad") and not f:land(b,home,"pad"))
  assert(#f.landingQueues.pad==2 and a.model:GetAttribute("DeskQueuePosition")==1 and b.model:GetAttribute("DeskQueuePosition")==2)
  assert((a.model:GetAttribute("HoldingPosition")-b.model:GetAttribute("HoldingPosition")).Magnitude>=50)
  assert(a.model:GetAttribute("State")=="FLYING" and not f:padAvailable("pad","a"))
  f.padReservations.pad=nil
  assert(f:padAvailable("pad","a") and not f:padAvailable("pad","b"))
  f:clearLandingQueue(a);assert(f:padAvailable("pad","b"));a.model:Destroy();b.model:Destroy()
 end)
 test("changing approach releases the old queue and clears obsolete marker",function()
  local f,home,pilot=fixture();local a=pilot("a")
  f:land(a,home,"pad");f:land(a,home,"other")
  assert(#f.landingQueues.pad==0 and #f.landingQueues.other==1 and a.waitingPad=="other")
  f:clearLandingQueue(a)
  assert(a.waitingPad==nil and a.model:GetAttribute("HoldingPosition")==nil and #f.landingQueues.other==0);a.model:Destroy()
 end)
 test("dead or removed waiting pilots cannot block later arrivals",function()
  local f,home,pilot=fixture();local a,b=pilot("a"),pilot("b")
  f:land(a,home,"pad");f:land(b,home,"pad");f.padReservations.pad=nil
  a.model:SetAttribute("State","DESTROYED");assert(f:padAvailable("pad","b"))
  b.model:Destroy();assert(f:padAvailable("pad","new"));a.model:Destroy()
 end)
 test("a replaced plane goes only after the new one is in, so the screen never has no plane",function()
  local old=Instance.new("Folder");old.Parent=workspace
  local stillThere
  local f=setmetatable({build=function(self,p) stillThere=old.Parent~=nil;p.model=Instance.new("Folder") end},Flight)
  local p={model=old};f:replace(p)
  assert(stillThere and old.Parent==nil and p.model~=old)
  p.model:Destroy()
 end)
 test("a crash the pilot's client felt counts when the plane is really beside that solid part",function()
  local room=Instance.new("Folder");room.Parent=workspace
  local rail=Instance.new("Part");rail.Anchored=true;rail.Size=Vector3.new(200,1,1);rail.Position=Vector3.new(0,5000,0);rail.Parent=room
  local open=rail:Clone();open.CanCollide=false;open.Parent=room
  local outside=rail:Clone();outside.Parent=workspace
  local overlap=OverlapParams.new();overlap.FilterType=Enum.RaycastFilterType.Include;overlap.FilterDescendantsInstances={room};overlap.RespectCanCollide=true
  local destroyed
  local f=setmetatable({room=room,overlap=overlap,destroy=function(_,p,how) destroyed=how end},Flight)
  local m=Instance.new("Folder");m:SetAttribute("State","FLYING");m:SetAttribute("Lift",50)
  local body=Instance.new("Part");body.Anchored=true;body.Position=Vector3.new(0,5003,0);body.Parent=m
  local p={model=m,body=body}
  assert(not f:crashed(p,"rail") and not f:crashed(p,open) and not f:crashed(p,outside),"only a real solid part of the room")
  body.Position=Vector3.new(0,5200,0);assert(not f:crashed(p,rail),"too far from it")
  f.safe=true;body.Position=Vector3.new(0,5003,0);assert(not f:crashed(p,rail),"between rounds walls only bounce");f.safe=nil
  assert(f:crashed(p,rail) and destroyed.kind=="crash" and destroyed.part==rail.Name)
  m:SetAttribute("State","DESTROYED");destroyed=nil;assert(not f:crashed(p,rail) and destroyed==nil,"only a flying plane")
  room:Destroy();outside:Destroy();m:Destroy()
 end)
 test("a ram folds the plane with less health and costs the other that much plus a bit; a brush costs both a little",function()
  local function run(ha,hb,speed)
   local taken={}
   local f=setmetatable({damage=function(_,p,amount) taken[p.id]=(taken[p.id] or 0)+amount end},Flight)
   local function pilot(id,health,z,vz)
    local m=Instance.new("Folder");m:SetAttribute("Health",health)
    return {id=id,model=m,stats={health=120},body={Position=Vector3.new(0,0,z)},previousVelocity=Vector3.new(0,0,vz),lastContact=0}
   end
   f:ram(pilot("a",ha,0,-speed),pilot("b",hb,-10,speed),1)
   return taken.a or 0,taken.b or 0
  end
  local a,b=run(50,80,100);assert(a==50 and b==65,"weaker plane must fold, stronger loses 50 plus the extra: "..a..","..b)
  a,b=run(50,55,100);assert(a==50 and b==54,"the stronger plane always survives: "..a..","..b)
  a,b=run(70,70,100);assert(a==70 and b==70,"equal health: both destroyed")
  a,b=run(50,80,5);assert(a==12 and b==12,"slow brush: both lose a little: "..a..","..b)
 end)
 return result
end
return Spec
