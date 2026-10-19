local Root=game.ReplicatedStorage.FlyFightPaper
local Server=game.ServerScriptService.FlyFightPaper
local Service=require(Server.ProfileService)
local Schema=require(Root.Shared.ProfileSchema)
local Catalog=require(Root.Shared.Catalog)
local Fake=require(script.Parent.Parent.fixtures.FakeProfiles)
local Suite=require(script.Parent.Parent.fixtures.Suite)
local Spec={}
local function fixture(mock,data)
 local catalog=Catalog.new(require(Root.Generated.Catalog))
 local f={catalog=catalog,now=100}
 f.profile=Fake.new(data or Schema.defaults(catalog))
 f.service=Service.new({catalog=catalog,mock=mock,monotonic=function()return f.now end})
 assert(f.service:attach("user",f.profile,{connected=true,mapLoaded=true}).status=="ok")
 function f:op(input) return assert(self.service:prepare("user",input)) end
 function f:apply(input)
  local result=self.service:apply("user",self:op(input));assert(result.status=="ok",result.code);return result.value
 end
 function f:view()local result=self.service:view("user");assert(result.status=="ok");return result.value end
 return f
end
function Spec.run()
 local result,test=Suite.new()
 test("reward batches make no DataStore calls and retry IDs pay once",function()
  local f=fixture(false);local op=f:op({kind="contribution",points=10,multipliers={paper=1,xp=2}})
  assert(f.service:apply("user",op).status=="ok")
  for _=1,300 do assert(f.service:apply("user",op).status=="ok") end
  assert(f:view().paperMilli==3630 and f:view().xpMilli==13600 and f.profile.writes==0)
  assert(f.profile:Save() and f.profile.writes==1)
  assert(f.profile.LastSavedData.operationIds[f.service.sessions.user.token]==1)
 end)
 test("changed payload cannot reuse an operation ID",function()
  local f=fixture(false);local op=f:op({kind="contribution",points=10,multipliers={paper=1,xp=1}})
  assert(f.service:apply("user",op).status=="ok");op.points=100
  assert(f.service:apply("user",op).code=="operation_id_conflict" and f:view().paperMilli==3630)
 end)
 test("compact operation IDs still reject an old retry after result cache eviction",function()
  local f=fixture(false);local first=f:op({kind="contribution",points=1,multipliers={paper=1,xp=1}})
  assert(f.service:apply("user",first).status=="ok")
  for _=1,require(Root.Generated.Server).profiles.result_cache_limit+1 do f:apply({kind="contribution",points=1,multipliers={paper=1,xp=1}}) end
  local before=f:view().paperMilli
  assert(f.service:apply("user",first).status=="ok" and f:view().paperMilli==before)
 end)
 test("save failure leaves rewards usable and the next save includes them once",function()
  local f=fixture(false);f.profile.failSave=true
  f:apply({kind="contribution",points=10,multipliers={paper=1,xp=1}})
  assert(not f.profile:Save() and f.profile.LastSavedData.paperMilli==0)
  f:apply({kind="contribution",points=5,multipliers={paper=2,xp=1}})
  assert(f:view().paperMilli==7260)
  f.profile.failSave=false;assert(f.profile:Save())
  assert(f.profile.LastSavedData.paperMilli==7260 and f.profile.LastSavedData.xpMilli==10200)
 end)
 test("rejoin keeps ownership settings graduation receipts and balances",function()
  local f=fixture(false)
  f:apply({kind="contribution",points=100,multipliers={paper=1,xp=1}})
  f:apply({kind="settings",settings={music=0.2,sound=0.5,sensitivity=1,reducedShake=true,quality="Low",crosshairColor="red",crosshairSize="Large"}})
  f:apply({kind="qualification",matchId="round",activeSeconds=120,events=3})
  f:apply({kind="lessonDone",lesson="flight"})
  f.profile.Data.receiptIds.verifiedReceipt=true
  assert(f.profile:EndSession());f.service:detach("user")
  local nextProfile=Fake.new(f.profile.LastSavedData)
  assert(f.service:attach("user",nextProfile,{connected=true,mapLoaded=true}).status=="ok")
  local p=f:view();assert(p.paperMilli==36300 and p.settings.reducedShake and p.settings.crosshairColor=="red" and p.settings.crosshairSize=="Large" and p.qualification.count==1 and p.receiptIds.verifiedReceipt)
  assert(p.ownership.pellet and #p.presets==5 and p.lessons.flight==true and p.lessons.combat==nil)
 end)
 test("takeover stops all writes from the previous server",function()
  local f=fixture(false);local stale=f:op({kind="contribution",points=1,multipliers={paper=1,xp=1}})
  f.profile:Save();local nextProfile=f.profile:takeover()
  assert(f.service:apply("user",stale).status=="retry")
  f.service:detach("user");assert(f.service:attach("user",nextProfile,{connected=true,mapLoaded=true}).status=="ok")
  assert(f.service:apply("user",stale).code=="old_session_operation" and f:view().paperMilli==0)
 end)
 test("bad and future profiles are never replaced by defaults",function()
  local catalog=Catalog.new(require(Root.Generated.Catalog));local data=Schema.defaults(catalog)
  data.paperMilli=-1;local profile=Fake.new(data);local service=Service.new({catalog=catalog})
  assert(service:attach("bad",profile,{connected=true,mapLoaded=true}).status=="error" and profile.Data.paperMilli==-1)
  profile.Data.paperMilli=123;profile.Data.schemaVersion=Schema.VERSION+1
  assert(service:attach("bad",profile,{connected=true,mapLoaded=true}).status=="error" and profile.Data.paperMilli==123)
 end)
 test("failed settings and purchases change neither money nor operation IDs",function()
  local f=fixture(false);local before=Schema.canonical(f.profile.Data)
  assert(f.service:apply("user",f:op({kind="settings",settings={music=2}})).status=="error")
  assert(f.service:apply("user",f:op({kind="equipmentPurchase",catalogID="pencil"})).status=="error")
  assert(f.service:apply("user",f:op({kind="lessonDone",lesson="secret"})).status=="error")
  assert(Schema.canonical(f.profile.Data)==before)
 end)
 test("real sessions refuse Paper and boosts from the mock shop",function()
  local f=fixture(false)
  assert(f.service:apply("user",f:op({kind="purchasedPaper",wholePaper=99999})).code=="studio_only")
  assert(f.service:apply("user",f:op({kind="boostIntent",resource="paper",action="duration",seconds=900})).code=="studio_only")
  assert(f:view().paperMilli==0 and f:view().boosts.paperSeconds==0)
 end)
 test("loaded online menus count time and loading and offline gaps pause boosts",function()
  local f=fixture(true);f:apply({kind="boostIntent",resource="paper",action="duration",seconds=900})
  f.now+=20;assert(f:view().boosts.paperSeconds==880)
  f.service:setProducerMapLoaded("user",false);f.now+=50
  assert(f:view().boosts.paperSeconds==880)
  f.service:setProducerMapLoaded("user",true);f.now+=10
  f.service:setProducerConnected("user",false);assert(f:view().boosts.paperSeconds==870)
  f.now+=100;assert(f:view().boosts.paperSeconds==870)
  f.profile:EndSession();f.service:detach("user");f.now+=10000
  assert(f.service:attach("user",Fake.new(f.profile.LastSavedData),{connected=true,mapLoaded=true}).status=="ok")
  assert(f:view().boosts.paperSeconds==870)
 end)
 test("delayed earnings retain the multiplier at occurrence",function()
  local f=fixture(true);f:apply({kind="boostIntent",resource="paper",action="duration",seconds=2})
  f.now+=1;local at=f.now;f:view();f.now+=3
  local capture=f.service:producerCapture("user",at);assert(capture.status=="ok" and capture.value.paper==2)
  f:apply({kind="contribution",points=10,multipliers=capture.value})
  assert(f:view().paperMilli==7260 and f:view().boosts.paperSeconds==0)
 end)
 local function reserve(f)
  f:apply({kind="purchasedPaper",wholePaper=200})
  local p=f:view();local id=f.service:operationID()
  local fence={nonce=p.lease.nonce,generation=p.generation,sessionGeneration=p.generation,actorId="pilot",lifeId="1",matchId="match",participationId="pilot",padId="desk"}
  f:apply({kind="refoldIntent",intentId=id,fence=fence,loadout=p.presets[1].loadout})
  return id
 end
 test("interrupted reserved or delivered refolds refund once on rejoin",function()
  for _,delivered in ipairs({false,true}) do
   local f=fixture(true);local id=reserve(f)
   if delivered then f:apply({kind="refoldDeliver",intentId=id}) end
   assert(f:view().paperMilli==80000);f.profile:EndSession();f.service:detach("user")
   local nextProfile=Fake.new(f.profile.LastSavedData)
   assert(f.service:attach("user",nextProfile,{connected=true,mapLoaded=true}).status=="ok")
   assert(f:view().paperMilli==200000 and next(f:view().refolds)==nil)
   nextProfile:EndSession();f.service:detach("user")
   assert(f.service:attach("user",Fake.new(nextProfile.LastSavedData),{connected=true,mapLoaded=true}).status=="ok")
   assert(f:view().paperMilli==200000)
  end
 end)
 test("applied refold keeps its cost and rejects a second refund",function()
  local f=fixture(true);local id=reserve(f)
  f:apply({kind="refoldDeliver",intentId=id});f:apply({kind="refoldApplied",intentId=id})
  assert(f.service:apply("user",f:op({kind="refoldRefund",intentId=id})).code=="refold_already_applied")
  f.profile:EndSession();f.service:detach("user")
  assert(f.service:attach("user",Fake.new(f.profile.LastSavedData),{connected=true,mapLoaded=true}).status=="ok")
  assert(f:view().paperMilli==80000)
 end)
 test("cancelled refolds refund once and cannot deliver",function()
  local f=fixture(true);local id=reserve(f)
  f:apply({kind="refoldCancel",intentId=id});f:apply({kind="refoldCancel",intentId=id})
  assert(f:view().paperMilli==200000)
  assert(f.service:apply("user",f:op({kind="refoldDeliver",intentId=id})).code=="refold_cancelled")
  f:apply({kind="refoldRetire",intentId=id});assert(next(f:view().refolds)==nil)
 end)
 test("old desk session tokens cannot charge for a refold",function()
  local f=fixture(true);f:apply({kind="purchasedPaper",wholePaper=200});local p=f:view()
  local op=f:op({kind="refoldIntent",intentId="stale",fence={nonce="old",generation=p.generation},loadout=p.presets[1].loadout})
  assert(f.service:apply("user",op).code=="refold_fence_lost" and f:view().paperMilli==200000)
 end)
 test("qualification is idempotent and never exceeds the configured graduation count",function()
  local f=fixture(false)
  for i=1,10 do f:apply({kind="qualification",matchId="match"..i,activeSeconds=120,events=3}) end
  assert(f:view().qualification.count==5)
  f:apply({kind="qualification",matchId="match1",activeSeconds=120,events=3});assert(f:view().qualification.count==5)
 end)
 test("native ProfileStore Mock saves and reopens the same session profile",function()
  local Store=require(Server.Packages.ProfileStore)
  local catalog=Catalog.new(require(Root.Generated.Catalog))
  local store=Store.New("TrackCTest_"..game:GetService("HttpService"):GenerateGUID(false),Schema.defaults(catalog)).Mock
  local profile=assert(store:StartSessionAsync("player"))
  local service=Service.new({catalog=catalog,mock=true})
  assert(service:attach("player",profile,{connected=true,mapLoaded=true}).status=="ok")
  assert(service:apply("player",service:prepare("player",{kind="contribution",points=10,multipliers={paper=1,xp=1}})).status=="ok")
  local runtime=setmetatable({mock=true,entries={},service=service},require(Server.ProfileRuntime))
  local player={UserId=1,SetAttribute=function()end}
  local entry={player=player,account="player",loaded=true,queue={},callbacks={},seen={},lastSavedVersion=0}
  runtime.entries[player]=entry
  assert(runtime:enqueue(player,{kind="contribution",points=5},"last_reward"))
  local flushed=false
  profile.OnSave:Connect(function()flushed=runtime:flush(entry)end)
  local saved=false;profile.OnAfterSave:Connect(function()assert(not profile:IsActive());saved=true end)
  profile:EndSession()
  local deadline=os.clock()+10;repeat task.wait() until saved or os.clock()>deadline
  assert(saved and flushed,"ProfileStore did not flush and confirm final save")
  service:detach("player")
  local reopened=assert(store:StartSessionAsync("player"));assert(reopened.Data.paperMilli==5445)
  reopened:EndSession()
 end)
 return result
end
return Spec
