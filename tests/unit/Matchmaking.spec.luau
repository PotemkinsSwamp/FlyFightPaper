local Matching=require(game.ServerScriptService.FlyFightPaper.Matchmaking)
local Suite=require(script.Parent.Parent.fixtures.Suite)
local Spec={}
function Spec.run()
 local result,test=Suite.new()
 local function player(count)
  local p=Instance.new("Folder");p.Parent=game.ServerStorage
  return p,{qualification={count=count}}
 end
 test("only five qualifying matches graduate; XP and client flags do not",function()
  assert(Matching.classFor({qualification={count=4},xpMilli=999999999})=="rookie")
  assert(Matching.classFor({qualification={count=5}})=="regular")
 end)
 test("Studio isolates a trusted beginner room from graduated profiles",function()
  local a,pa=player(0);local b,pb=player(5)
  b:SetAttribute("Graduated",false)
  local profiles={view=function(_,p)return p==a and pa or pb end}
  local rooms=Matching.new(profiles,{mock=true})
  assert(rooms:admit(a) and rooms.class=="rookie")
  assert(not rooms:admit(b) and rooms.class=="rookie")
  a:Destroy();b:Destroy()
 end)
 test("graduated solo players get a regular room",function()
  local p,profile=player(5)
  local rooms=Matching.new({view=function()return profile end},{mock=true})
  assert(rooms:admit(p) and rooms.class=="regular");p:Destroy()
 end)
 test("unloaded profiles cannot choose a room",function()
  local p=player(0);p:SetAttribute("Graduated",true)
  local rooms=Matching.new({view=function()return nil end},{mock=true})
  assert(not rooms:admit(p) and rooms.class==nil);p:Destroy()
 end)
 test("live transfer releases the profile before sending and blocks repeat joins",function()
  local p,profile=player(5);local disconnected=false;local sent=false;local order={}
  local entry={account="test"};local profiles={entries={[p]=entry},view=function()return profile end,
   release=function(_,who)assert(who==p);entry.leaving=true;entry.releaseAt=0;disconnected=true;table.insert(order,"pause")end}
  local platform={destination=function()return {class="regular"}end,send=function()
   assert(profiles.entries[p]==nil and disconnected);sent=true;table.insert(order,"send")
  end}
  local rooms=setmetatable({profiles=profiles,platform=platform,mock=false,class="rookie",transfers={}},Matching)
  assert(not rooms:admit(p));assert(not rooms:admit(p))
  task.wait(.05);assert(entry.leaving and entry.releaseAt==0 and disconnected and not sent)
  profiles.entries[p]=nil;task.wait(.15)
  assert(sent and order[1]=="pause" and order[2]=="send");p:Destroy()
 end)
 test("a failed destination keeps the loaded profile and permits retry",function()
  local p,profile=player(5);local entry={account="test"}
  local profiles={entries={[p]=entry},view=function()return profile end}
  local rooms=setmetatable({profiles=profiles,mock=false,class="rookie",transfers={},platform={destination=function()error("unavailable")end}},Matching)
  assert(not rooms:admit(p));task.wait()
  assert(not rooms.transfers[p] and not entry.leaving and profiles.entries[p]==entry and not p:GetAttribute("Routing"));p:Destroy()
 end)
 test("a failed send reloads the released profile instead of creating defaults",function()
  local p=player(5);local reloaded=false
  local profiles={entries={},load=function(_,who)assert(who==p);reloaded=true end}
  local rooms=setmetatable({profiles=profiles,transfers={[p]=true}},Matching)
  rooms:failed(p);assert(reloaded and not p:GetAttribute("Routing"));p:Destroy()
 end)
 return result
end
return Spec
