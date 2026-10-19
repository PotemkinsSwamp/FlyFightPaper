local Root=game.ReplicatedStorage.FlyFightPaper
local Service=require(game.ServerScriptService.FlyFightPaper.ProfileService)
local Schema=require(Root.Shared.ProfileSchema)
local Economy=require(Root.Shared.EconomyRules)
local EconomyConfig=require(Root.Generated.Economy)
local Gameplay=require(Root.Generated.Gameplay)
local Catalog=require(Root.Shared.Catalog)
local Fake=require(script.Parent.Parent.fixtures.FakeProfiles)
local Suite=require(script.Parent.Parent.fixtures.Suite)
local Spec={}
local function fixture()
 local catalog=Catalog.new(require(Root.Generated.Catalog),Gameplay)
 local data=Schema.defaults(catalog)
 for level=1,EconomyConfig.level_cap-1 do data.xpMilli+=(EconomyConfig.xp_next_level_base+EconomyConfig.xp_next_level_step*(level-1))*1000 end
 data.paperMilli=1234567;data.earnedPaperMilli=2345678;data.purchasedPaperMilli=900000
 data.ownership.staple=true;data.presets[1].name="Keep this name";data.presets[1].loadout.weapon_mounts[1]="staple"
 data.presets[2].name="Legal starter build";data.presets[2].loadout.weapon_mounts[1]=false
 data.boosts={paperSeconds=12.5,xpSeconds=1800,permanentPaper=true,permanentXP=false}
 data.settings.music=0.25;data.settings.crosshairColor="red"
 data.qualification={count=2,history={first=true,second=true}}
 data.statistics={matches=10,wins=3,eliminations=42,deaths=17}
 data.operationSessions={"old"};data.operationIds={old=7};data.receiptIds={receipt=true}
 -- Valid unrelated save data can exceed the economy rules' narrower copy bounds.
 data.extensions={kept={description=string.rep("x",600),nested={a={b={c={d={e={value=true}}}}}}}}
 local profile=Fake.new(data)
 local service=Service.new({catalog=catalog,monotonic=function()return 100 end})
 assert(service:attach("user",profile,{connected=true,mapLoaded=true}).status=="ok")
 return service,profile,catalog
end
function Spec.run()
 local result,test=Suite.new()
 test("prestige exposes its rank in the view and preserves all unrelated saved progress",function()
  local service,profile,catalog=fixture()
  assert(service:view("user").value.prestige==0)
  local before=assert(Schema.copy(profile.Data));local op=assert(service:prepare("user",{kind="prestige"}))
  local applied=service:apply("user",op)
  assert(applied.status=="ok",applied.code)
  assert(applied.value.type=="Prestiged" and applied.value.prestige==1 and applied.value.operationID==op.id)
  local expected=assert(Schema.copy(before));expected.prestige=1;expected.xpMilli=EconomyConfig.initial_total_xp*1000
  expected.ownership=assert(Schema.copy(assert(Economy.starterOwnership(catalog))))
  expected.presets[1].loadout=catalog:starterLoadout();expected.version+=1
  expected.operationIds[service.sessions.user.token]=1
  assert(Schema.canonical(profile.Data)==Schema.canonical(expected),"prestige changed unrelated saved progress")
  local view=service:view("user").value
  assert(view.prestige==1 and table.isfrozen(view) and profile.writes==0)
 end)
 test("retrying a prestige operation applies it once even after earning back the level cap",function()
  local service,profile=fixture();local op=assert(service:prepare("user",{kind="prestige"}))
  local first=service:apply("user",op);assert(first.status=="ok",first.code)
  local after=Schema.canonical(profile.Data)
  local retry=service:apply("user",op)
  assert(retry.status=="ok" and retry.value.prestige==1 and Schema.canonical(profile.Data)==after)
  local reward=assert(service:prepare("user",{kind="contribution",points=100000,multipliers={paper=1,xp=1}}))
  assert(service:apply("user",reward).status=="ok" and Economy.levelForXP(profile.Data.xpMilli)==EconomyConfig.level_cap)
  local purchase=assert(service:prepare("user",{kind="equipmentPurchase",catalogID="staple"}))
  assert(service:apply("user",purchase).status=="ok")
  after=Schema.canonical(profile.Data)
  retry=service:apply("user",op)
  assert(retry.status=="ok" and retry.value.prestige==1 and Schema.canonical(profile.Data)==after)
  assert(profile.Data.ownership.staple and profile.Data.operationIds[service.sessions.user.token]==3)
 end)
 test("prestige rejects a reused operation id with a different payload",function()
  local service,profile=fixture();local op=assert(service:prepare("user",{kind="prestige"}))
  assert(service:apply("user",op).status=="ok");local after=Schema.canonical(profile.Data)
  op.kind="equipmentPurchase";op.catalogID="staple"
  assert(service:apply("user",op).code=="operation_id_conflict" and Schema.canonical(profile.Data)==after)
 end)
 test("prestige failure codes leave saved data and the operation watermark unchanged",function()
  for _,code in ipairs({"not_at_level_cap","prestige_max","refold_pending"}) do
   local service,profile,catalog=fixture()
   if code=="not_at_level_cap" then
    profile.Data.xpMilli-=1
   elseif code=="prestige_max" then
    profile.Data.prestige=EconomyConfig.prestige_max
   else
    local session=service.sessions.user
    local reserve=assert(service:prepare("user",{kind="refoldIntent",intentId="pending",loadout=catalog:starterLoadout(),
     fence={nonce=session.token,generation=profile.Data.generation,sessionGeneration=1,actorId="pilot",lifeId="1",matchId="match",participationId="pilot",padId="desk"}}))
    local reserved=service:apply("user",reserve);assert(reserved.status=="ok",reserved.code)
   end
   local before=Schema.canonical(profile.Data)
   local applied=service:apply("user",assert(service:prepare("user",{kind="prestige"})))
   assert(applied.status=="error" and applied.code==code,applied.code)
   assert(Schema.canonical(profile.Data)==before,"rejected prestige changed saved data")
  end
 end)
 test("prestige rank survives a save and rejoin",function()
  local service,profile=fixture()
  local applied=service:apply("user",assert(service:prepare("user",{kind="prestige"})))
  assert(applied.status=="ok",applied.code)
  assert(profile:EndSession());service:detach("user")
  local reopened=Fake.new(profile.LastSavedData)
  assert(service:attach("user",reopened,{connected=true,mapLoaded=true}).status=="ok")
  local view=service:view("user").value
  assert(view.prestige==1 and view.xpMilli==EconomyConfig.initial_total_xp*1000 and view.qualification.count==2)
 end)
 test("receipt keys are deterministic schema-safe keys for raw Roblox purchase ids",function()
  assert(Service.receiptKey("safe-ID:123")=="r_safe-ID:123")
  for _,raw in ipairs({"", "purchase/id.with spaces",utf8.char(0x2603),string.rep("x",1024),string.char(0,255)}) do
   local key=Service.receiptKey(raw)
   assert(Schema.id(key) and key==Service.receiptKey(raw))
   if not Schema.id("r_"..raw) then assert(key:match("^h_%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x$")) end
  end
  assert(Service.receiptKey("a/b")~=Service.receiptKey("a?b"))
  assert(Service.receiptKey("a/b")=="h_e620c3190468cf61","64-bit FNV-1a reference vector")
  assert(Service.receiptKey("h_123")~=Service.receiptKey("/123"))
 end)
 test("receipt replay in another profile session grants no Paper and still advances its operation watermark",function()
  local service,profile=fixture();local raw="Roblox/purchase.1"
  local before=assert(Schema.copy(profile.Data))
  local input={kind="receipt",receiptId=raw,grant={kind="purchasedPaper",wholePaper=1000}}
  local first=assert(service:prepare("user",input));local applied=service:apply("user",first)
  assert(applied.status=="ok",applied.code)
  assert(profile.Data.paperMilli==before.paperMilli+1000000 and profile.Data.purchasedPaperMilli==before.purchasedPaperMilli+1000000)
  assert(profile.Data.earnedPaperMilli==before.earnedPaperMilli and profile.Data.receiptIds[Service.receiptKey(raw)]==true)
  assert(profile:EndSession());service:detach("user")
  local reopened=Fake.new(profile.LastSavedData)
  assert(service:attach("user",reopened,{connected=true,mapLoaded=true}).status=="ok")
  local replay=assert(service:prepare("user",input));assert(first.id~=replay.id)
  local version=reopened.Data.version;local again=service:apply("user",replay)
  assert(again.status=="ok" and again.value.type=="ReceiptAlreadyGranted",again.code)
  assert(reopened.Data.paperMilli==before.paperMilli+1000000 and reopened.Data.purchasedPaperMilli==before.purchasedPaperMilli+1000000)
  assert(reopened.Data.version==version+1 and reopened.Data.operationIds[service.sessions.user.token]==1)
 end)
 test("receipt ceiling refuses new grants atomically but still accepts an existing receipt",function()
  local service,profile=fixture();local cap=require(Root.Generated.Server).schema.max_receipts
  profile.Data.receiptIds={}
  for i=1,cap do profile.Data.receiptIds[Service.receiptKey("saved_"..i)]=true end
  assert(Schema.validate(profile.Data,service.catalog))
  local before=Schema.canonical(profile.Data)
  local refused=service:apply("user",assert(service:prepare("user",{kind="receipt",receiptId="new_receipt",grant={kind="purchasedPaper",wholePaper=1000}})))
  assert(refused.status=="error" and refused.code=="receipt_cap",refused.code)
  assert(Schema.canonical(profile.Data)==before)
  local replay=service:apply("user",assert(service:prepare("user",{kind="receipt",receiptId="saved_1",grant={kind="purchasedPaper",wholePaper=1000}})))
  assert(replay.status=="ok" and replay.value.type=="ReceiptAlreadyGranted" and profile.Data.paperMilli==1234567)
 end)
 test("verified timed receipts share the boost clock and preserve dormant permanent-resource time",function()
  for _,resource in ipairs({"xp","paper"}) do
   local service,profile=fixture();local field=resource=="xp" and "xpSeconds" or "paperSeconds"
   local before=profile.Data.boosts[field]
   local input={kind="receipt",receiptId="timed/"..resource,grant={kind="boostIntent",resource=resource,action="duration",seconds=900}}
   local granted=service:apply("user",assert(service:prepare("user",input)))
   assert(granted.status=="ok",granted.code)
   assert(profile.Data.boosts[field]==before+900 and service:liveBoostView("user").value.boosts[field]==before+900)
   local replay=service:apply("user",assert(service:prepare("user",input)))
   assert(replay.status=="ok" and replay.value.type=="ReceiptAlreadyGranted" and profile.Data.boosts[field]==before+900)
   assert(profile.Data.receiptIds[Service.receiptKey(input.receiptId)]==true)
  end
 end)
 test("verified pass grants use the boost clock and repeated grants are successful no-ops",function()
  local service,profile=fixture();local seconds=profile.Data.boosts.xpSeconds
  local first=service:apply("user",assert(service:prepare("user",{kind="passGrant",resource="xp"})))
  assert(first.status=="ok" and first.value.type=="BoostIntentApplied",first.code)
  assert(profile.Data.boosts.permanentXP and profile.Data.boosts.xpSeconds==seconds)
  local revision=service.sessions.user.clock.revision
  for _,resource in ipairs({"xp","paper"}) do
   local again=service:apply("user",assert(service:prepare("user",{kind="passGrant",resource=resource})))
   assert(again.status=="ok" and again.value.type=="PassAlreadyGranted",again.code)
  end
  assert(service.sessions.user.clock.revision==revision and service:liveBoostView("user").value.boosts.permanentXP)
 end)
 test("malformed receipt grants and pass resources cannot change a profile",function()
  local service,profile=fixture();local before=Schema.canonical(profile.Data)
  local grants={{kind="purchasedPaper",wholePaper=0},{kind="purchasedPaper",wholePaper=-1},
   {kind="purchasedPaper",wholePaper=1.5},{kind="purchasedPaper",wholePaper=1,extra=true},
   {kind="boostIntent",resource="xp",action="permanent"},{kind="boostIntent",resource="other",action="duration",seconds=1},
   {kind="boostIntent",resource="xp",action="duration",seconds=0},{kind="boostIntent",resource="xp",action="duration",seconds=1.5},
   {kind="boostIntent",resource="xp",action="duration",seconds=1,wholePaper=10},{kind="statistics",deltas={wins=1}}}
  for _,grant in ipairs(grants) do
   local refused=service:apply("user",assert(service:prepare("user",{kind="receipt",receiptId="invalid",grant=grant})))
   assert(refused.status=="error" and refused.code=="invalid_receipt_grant",refused.code)
   assert(Schema.canonical(profile.Data)==before)
  end
  for _,input in ipairs({{kind="receipt",receiptId="",grant={kind="purchasedPaper",wholePaper=1}},
   {kind="receipt",receiptId=42,grant={kind="purchasedPaper",wholePaper=1}},{kind="passGrant",resource="other"}}) do
   assert(service:apply("user",assert(service:prepare("user",input))).status=="error")
   assert(Schema.canonical(profile.Data)==before)
  end
 end)
 test("a refused boost receipt rolls back its preview and does not record its receipt",function()
  local service,profile=fixture();local clock=service.sessions.user.clock
  clock.state.xpSeconds=Economy.MAX_SAFE_INTEGER;profile.Data.boosts.xpSeconds=Economy.MAX_SAFE_INTEGER
  local before=Schema.canonical(profile.Data);local revision=clock.revision
  local refused=service:apply("user",assert(service:prepare("user",{kind="receipt",receiptId="overflow",grant={kind="boostIntent",resource="xp",action="duration",seconds=1}})))
  assert(refused.status=="error" and refused.code=="overflow",refused.code)
  assert(Schema.canonical(profile.Data)==before and service.sessions.user.clock==clock and clock.revision==revision)
 end)
 test("plain practice grants still refuse non-mock profiles",function()
  local service,profile=fixture();local before=Schema.canonical(profile.Data)
  for _,input in ipairs({{kind="purchasedPaper",wholePaper=1000},{kind="boostIntent",resource="xp",action="permanent"}}) do
   local refused=service:apply("user",assert(service:prepare("user",input)))
   assert(refused.status=="error" and refused.code=="studio_only" and Schema.canonical(profile.Data)==before)
  end
 end)
 return result
end
return Spec
