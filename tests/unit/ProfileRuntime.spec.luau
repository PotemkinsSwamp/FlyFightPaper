local Root=game.ReplicatedStorage.FlyFightPaper
local Server=game.ServerScriptService.FlyFightPaper
local Runtime=require(Server.ProfileRuntime)
local Service=require(Server.ProfileService)
local Schema=require(Root.Shared.ProfileSchema)
local Catalog=require(Root.Shared.Catalog)
local Fake=require(script.Parent.Parent.fixtures.FakeProfiles)
local Suite=require(script.Parent.Parent.fixtures.Suite)
local Spec={}
local function fixture()
 local catalog=Catalog.new(require(Root.Generated.Catalog))
 local runtime=setmetatable({mock=true,entries={},service=Service.new({catalog=catalog,mock=true,monotonic=function()return 100 end})},Runtime)
 local players={}
 for i=1,2 do
  local player={UserId=i,attributes={}}
  function player:SetAttribute(key,value)self.attributes[key]=value end
  local account=tostring(i);local profile=Fake.new(Schema.defaults(catalog))
  assert(runtime.service:attach(account,profile,{connected=true,mapLoaded=true}).status=="ok")
  runtime.entries[player]={player=player,account=account,queue={},seen={},callbacks={},loaded=true,lastSavedVersion=0}
  players[i]=player
 end
 return runtime,players
end
function Spec.run()
 local result,test=Suite.new()
 test("joining recovers over-capacity or three-type presets and pending refolds without losing Paper",function()
  local catalog=Catalog.new(require(Root.Generated.Catalog))
  for _,mounts in ipairs({{"eraser",false,"rubber","rubber"},{"pellet","staple","rubber",false}}) do
  for _,state in ipairs({"reserved","delivered","applied","cancelled"}) do
   local data=Schema.defaults(catalog);data.xpMilli=60000000;data.paperMilli=1234567;data.ownership.eraser=true;data.ownership.rubber=true;data.ownership.staple=true
   data.presets[1].name="Saved guided build";data.presets[1].loadout.weapon_mounts=table.clone(mounts)
   local cost=require(Root.Generated.Gameplay).service.full_refold_paper*1000
   data.refolds={pending={state=state,costMilli=cost,loadout=assert(Schema.copy(data.presets[1].loadout)),
    fence={nonce="old",generation=1,sessionGeneration=1,actorId="pilot",lifeId="1",matchId="match",participationId="pilot",padId="desk"}}}
   local profile=Fake.new(data);local service=Service.new({catalog=catalog,monotonic=function()return 100 end})
   assert(service:attach("saved",profile,{connected=true,mapLoaded=true}).status=="ok")
   local view=service:view("saved").value
   assert(view.paperMilli==1234567+((state=="reserved" or state=="delivered") and cost or 0))
   assert(view.xpMilli==60000000 and view.ownership.eraser and view.ownership.rubber and view.presets[1].name=="Saved guided build")
   assert(Schema.canonical(view.presets[1].loadout)==Schema.canonical(catalog:starterLoadout()) and next(view.refolds)==nil)
   local balance=view.paperMilli;service:detach("saved")
   assert(service:attach("saved",profile,{connected=true,mapLoaded=true}).status=="ok" and service:view("saved").value.paperMilli==balance)
  end end
 end)
 test("one failing profile worker does not stop a healthy worker",function()
  local runtime,players=fixture()
  for _,p in ipairs(players)do assert(runtime:enqueue(p,{kind="contribution",points=10},"reward"))end
  local original=runtime.service.apply
  runtime.service.apply=function(self,account,input)if account=="1"then error("injected worker failure")end;return original(self,account,input)end
  assert(not runtime:process(runtime.entries[players[1]]))
  assert(runtime:process(runtime.entries[players[2]]) and players[2].attributes.Paper==3)
  assert(#runtime.entries[players[1]].queue==1)
  runtime.service.apply=original
  assert(runtime:flush(runtime.entries[players[1]]) and players[1].attributes.Paper==3)
 end)
 test("source retries enqueue once and a closing session rejects new work",function()
  local runtime,players=fixture();local p=players[1];local e=runtime.entries[p]
  assert(runtime:enqueue(p,{kind="contribution",points=10},"same"))
  assert(runtime:enqueue(p,{kind="contribution",points=10},"same") and #e.queue==1)
  assert(runtime:flush(e) and p.attributes.Paper==3)
  e.closing=true;assert(not runtime:enqueue(p,{kind="contribution",points=10},"late"))
 end)
 test("save handoff drains pending operations in order without storage writes",function()
  local runtime,players=fixture();local p=players[1];local e=runtime.entries[p]
  for i=1,10 do assert(runtime:enqueue(p,{kind="contribution",points=i},"reward"..i))end
  assert(runtime:flush(e) and #e.queue==0 and p.attributes.Paper==19)
  local profile=runtime.service.sessions[e.account].profile
  assert(profile.writes==0 and profile.Data.operationIds[runtime.service.sessions[e.account].token]==10)
 end)
 return result
end
return Spec
