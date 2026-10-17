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
local function signal()
 local event={listeners={}}
 function event:Connect(callback)table.insert(self.listeners,callback)end
 function event:Fire(value)for _,callback in ipairs(self.listeners) do callback(value) end end
 return event
end
local function waitFor(callback)
 local deadline=os.clock()+1
 while not callback() and os.clock()<deadline do task.wait() end
 assert(callback(),"profile worker did not finish")
end
local function savingFixture()
 local catalog=Catalog.new(require(Root.Generated.Catalog));local profile=Fake.new(Schema.defaults(catalog))
 profile.OnSave=signal();profile.OnAfterSave=signal();profile.OnSessionEnd=signal();profile.KeyInfo={Version="autosave"}
 function profile:AddUserId()end
 function profile:EndSession()self.OnSave:Fire();self.active=false;self.OnSessionEnd:Fire()end
 local player={UserId=9990042,Parent=game:GetService("Players"),attributes={}}
 function player:SetAttribute(key,value)self.attributes[key]=value end
 function player:GetAttribute(key)return self.attributes[key]end
 function player:Kick(message)self.kicked=message end
 local store={saved={}}
 function store:StartSessionAsync()return profile end
 function store:GetAsync(key,version)
  assert(key=="Player_"..player.UserId and version==profile.KeyInfo.Version)
  if self.fail then error("injected confirmation failure") end
  return self.saved[version]
 end
 local runtime=setmetatable({catalog=catalog,mock=true,entries={},store=store,service=Service.new({catalog=catalog,mock=true,monotonic=function()return 100 end})},Runtime)
 runtime:load(player);waitFor(function()return runtime.entries[player] and runtime.entries[player].loaded end)
 runtime.mock=false -- Exercise version-specific confirmation through the fake store, without live API access.
 return runtime,player,profile,store
end
function Spec.run()
 local result,test=Suite.new()
 test("an autosave completing after EndSession cannot confirm the final write",function()
  local runtime,player,profile,store=savingFixture();local entry=runtime.entries[player]
  local data=assert(Schema.copy(profile.Data));store.saved.autosave={Data=data,Session={JobId="source"}}
  runtime:release(player);waitFor(function()return entry.closing and not profile:IsActive() end)
  profile.OnAfterSave:Fire(data)
  assert(runtime.entries[player]==entry and runtime.service.sessions[entry.account] and not player.kicked)
  profile.KeyInfo={Version="final"};store.saved.final={Data=data};profile.OnAfterSave:Fire(data)
  assert(runtime.entries[player]==nil and runtime.service.sessions[entry.account]==nil)
 end)
 test("a failed confirmation read releases (no later save would ever retry it)",function()
  local runtime,player,profile,store=savingFixture();local entry=runtime.entries[player]
  runtime:release(player);waitFor(function()return entry.closing and not profile:IsActive() end)
  local data=assert(Schema.copy(profile.Data));profile.KeyInfo={Version="final"};store.saved.final={Data=data};store.fail=true
  profile.OnAfterSave:Fire(data);assert(runtime.entries[player]==nil)
 end)
 test("a cleared lock from another generation cannot release a profile",function()
  local runtime,player,profile,store=savingFixture();local entry=runtime.entries[player]
  runtime:release(player);waitFor(function()return entry.closing and not profile:IsActive() end)
  local data=assert(Schema.copy(profile.Data));profile.KeyInfo={Version="final"}
  store.saved.final={Data=assert(Schema.copy(data))};store.saved.final.Data.generation+=1
  profile.OnAfterSave:Fire(data);assert(runtime.entries[player]==entry)
  store.saved.final={Data=data};profile.OnAfterSave:Fire(data);assert(runtime.entries[player]==nil)
 end)
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
