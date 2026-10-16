local Flight=require(game.ServerScriptService.FlyFightPaper.FlightService)
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
 test("a ram destroys the plane with less health and costs the other that much; a brush costs both a little",function()
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
  local a,b=run(50,80,100);assert(a==50 and b==50,"weaker plane must be destroyed, stronger loses 50: "..a..","..b)
  a,b=run(70,70,100);assert(a==70 and b==70,"equal health: both destroyed")
  a,b=run(50,80,5);assert(a==12 and b==12,"slow brush: both lose a little: "..a..","..b)
 end)
 return result
end
return Spec
