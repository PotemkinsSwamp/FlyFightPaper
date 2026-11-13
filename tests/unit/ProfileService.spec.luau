local Root=game.ReplicatedStorage.FlyFightPaper
local Service=require(game.ServerScriptService.FlyFightPaper.ProfileService)
local Schema=require(Root.Shared.ProfileSchema)
local Economy=require(Root.Shared.EconomyRules)
local Commerce=require(Root.Shared.CommerceRules)
local EconomyConfig=require(Root.Generated.Economy)
local Gameplay=require(Root.Generated.Gameplay)
local Catalog=require(Root.Shared.Catalog)
local Fake=require(script.Parent.Parent.fixtures.FakeProfiles)
local Suite=require(script.Parent.Parent.fixtures.Suite)
local Spec={}
local function fixture(mock)
 local catalog=Catalog.new(require(Root.Generated.Catalog),Gameplay)
 local data=Schema.defaults(catalog)
 for level=1,EconomyConfig.level_cap-1 do data.xpMilli+=(EconomyConfig.xp_next_level_base+math.floor(EconomyConfig.xp_next_level_step*(level-1)^EconomyConfig.xp_next_level_power))*1000 end
 data.paperMilli=1234567;data.earnedPaperMilli=2345678;data.purchasedPaperMilli=900000
 data.ownership.staple=true;data.presets[1].name="Keep this name";data.presets[1].loadout.weapon_mounts[1]="staple"
 data.presets[2].name="Legal starter build";data.presets[2].loadout.weapon_mounts[1]=false
 data.rangePresets[4].name="Keep this Range build";data.rangePresets[4].loadout.weapon_mounts[1]="eraser";data.rangeSlot=4
 data.boosts={paperSeconds=12.5,xpSeconds=1800,permanentPaper=true,permanentXP=false}
 data.settings.music=0.25;data.settings.crosshairColor="red"
 data.qualification={count=2,history={first=true,second=true}}
 data.statistics={matches=10,wins=3,eliminations=42,deaths=17}
 data.operationSessions={"old"};data.operationIds={old=7};data.receiptIds={receipt=true}
 -- Valid unrelated save data can exceed the economy rules' narrower copy bounds.
 data.extensions={kept={description=string.rep("x",600),nested={a={b={c={d={e={value=true}}}}}}}}
 local profile=Fake.new(data)
 local service=Service.new({catalog=catalog,mock=mock,monotonic=function()return 100 end})
 assert(service:attach("user",profile,{connected=true,mapLoaded=true}).status=="ok")
 return service,profile,catalog
end
function Spec.run()
 local result,test=Suite.new()
 test("Range preset saves accept unowned parts and apply once without changing match builds",function()
  local service,profile,catalog=fixture();profile.Data.xpMilli=0
  local loadout=catalog:starterLoadout();loadout.nose="nose_5";loadout.weapon_mounts[1]="eraser";loadout.utility="boost_twin"
  assert(not profile.Data.ownership.eraser and catalog:get("eraser").min_level>Economy.levelForXP(profile.Data.xpMilli))
  local before=assert(Schema.copy(profile.Data))
  local op=assert(service:prepare("user",{kind="rangePreset",slot=5,name="Try all parts",loadout=loadout}))
  local applied=service:apply("user",op)
  assert(applied.status=="ok",applied.code)
  assert(applied.value.type=="RangePresetSaved" and applied.value.slot==5 and applied.value.operationID==op.id)
  local expected=assert(Schema.copy(before));expected.rangePresets[5]={name=op.name,loadout=loadout}
  expected.version+=1;expected.operationIds[service.sessions.user.token]=1
  assert(Schema.canonical(profile.Data)==Schema.canonical(expected),"Range save changed unrelated progress")
  local after=Schema.canonical(profile.Data);local retry=service:apply("user",op)
  assert(retry.status=="ok" and retry.value.type=="RangePresetSaved" and Schema.canonical(profile.Data)==after)
  local newer=assert(service:prepare("user",{kind="rangePreset",slot=5,name="Newer build",loadout=catalog:starterLoadout()}))
  assert(service:apply("user",newer).status=="ok");after=Schema.canonical(profile.Data)
  assert(service:apply("user",op).status=="ok" and Schema.canonical(profile.Data)==after,"retry overwrote the newer build")
  op.name="Conflicting retry"
  assert(service:apply("user",op).code=="operation_id_conflict" and Schema.canonical(profile.Data)==after)
 end)
 test("Range slot saves apply once and survive a save and rejoin with the Range builds",function()
  local service,profile=fixture();local before=assert(Schema.copy(profile.Data))
  local op=assert(service:prepare("user",{kind="rangeSlot",slot=1}));local applied=service:apply("user",op)
  assert(applied.status=="ok",applied.code)
  assert(applied.value.type=="RangeSlotSaved" and applied.value.slot==1 and applied.value.operationID==op.id)
  local expected=assert(Schema.copy(before));expected.rangeSlot=1;expected.version+=1
  expected.operationIds[service.sessions.user.token]=1
  assert(Schema.canonical(profile.Data)==Schema.canonical(expected),"Range selection changed unrelated progress")
  local after=Schema.canonical(profile.Data);local retry=service:apply("user",op)
  assert(retry.status=="ok" and retry.value.type=="RangeSlotSaved" and Schema.canonical(profile.Data)==after)
  assert(service:apply("user",assert(service:prepare("user",{kind="rangeSlot",slot=5}))).status=="ok")
  after=Schema.canonical(profile.Data)
  assert(service:apply("user",op).status=="ok" and Schema.canonical(profile.Data)==after,"retry changed the newer selection")
  op.slot=2
  assert(service:apply("user",op).code=="operation_id_conflict" and Schema.canonical(profile.Data)==after)
  assert(profile:EndSession());service:detach("user")
  local reopened=Fake.new(profile.LastSavedData)
  assert(service:attach("user",reopened,{connected=true,mapLoaded=true}).status=="ok")
  assert(reopened.Data.rangeSlot==5 and Schema.canonical(reopened.Data.rangePresets)==Schema.canonical(before.rangePresets))
 end)
 test("Range operations reject invalid slots without changing saved progress or the operation watermark",function()
  for _,kind in ipairs({"rangePreset","rangeSlot"}) do
   for _,slot in ipairs({0,6,-1,1.5,"1",false}) do
    local service,profile,catalog=fixture();local before=Schema.canonical(profile.Data)
    local applied=service:apply("user",assert(service:prepare("user",{kind=kind,slot=slot,name="Invalid slot",loadout=catalog:starterLoadout()})))
    assert(applied.status=="error" and applied.code=="invalid_slot",applied.code)
    assert(Schema.canonical(profile.Data)==before,"invalid Range slot changed saved progress")
   end
  end
 end)
 test("Range preset saves revalidate names and loadouts before changing any saved data",function()
  local service,profile,catalog=fixture();local before=Schema.canonical(profile.Data)
  local overloaded=catalog:starterLoadout();overloaded.weapon_mounts={"eraser",false,"rubber","rubber"}
  for _,input in ipairs({{name="",loadout=catalog:starterLoadout()},{name="bad\nname",loadout=catalog:starterLoadout()},
   {name="Over capacity",loadout=overloaded},{name="Missing loadout"},{loadout=catalog:starterLoadout()}}) do
   input.kind="rangePreset";input.slot=1
   local applied=service:apply("user",assert(service:prepare("user",input)))
   assert(applied.status=="error")
   assert(Schema.canonical(profile.Data)==before,"invalid Range build changed saved progress")
  end
 end)
 test("seen unlocks raise once, keep higher seen levels and survive a save and rejoin",function()
  local service,profile=fixture();assert(profile.Data.unlocksSeen<3)
  local before=assert(Schema.copy(profile.Data));local op=assert(service:prepare("user",{kind="unlocksSeen",level=3}))
  local applied=service:apply("user",op);assert(applied.status=="ok",applied.code)
  assert(applied.value.type=="UnlocksSeen" and applied.value.level==3 and applied.value.operationID==op.id)
  local expected=assert(Schema.copy(before));expected.unlocksSeen=3;expected.version+=1
  expected.operationIds[service.sessions.user.token]=1
  assert(Schema.canonical(profile.Data)==Schema.canonical(expected),"seen unlocks changed unrelated saved progress")
  for _,level in ipairs({2,3}) do
   local lower=service:apply("user",assert(service:prepare("user",{kind="unlocksSeen",level=level})))
   assert(lower.status=="ok" and lower.value.level==3 and profile.Data.unlocksSeen==3,lower.code)
  end
  local after=Schema.canonical(profile.Data)
  assert(service:apply("user",op).status=="ok" and Schema.canonical(profile.Data)==after)
  assert(profile:EndSession());service:detach("user")
  local reopened=Fake.new(profile.LastSavedData)
  assert(service:attach("user",reopened,{connected=true,mapLoaded=true}).status=="ok")
  assert(service:view("user").value.unlocksSeen==3)
 end)
 test("seen unlocks clamp new levels to current XP without lowering an already higher seen level",function()
  local service,profile=fixture();profile.Data.xpMilli=EconomyConfig.xp_next_level_base*1000
  local level=assert(Economy.levelForXP(profile.Data.xpMilli));assert(level>profile.Data.unlocksSeen)
  local applied=service:apply("user",assert(service:prepare("user",{kind="unlocksSeen",level=EconomyConfig.level_cap+1})))
  assert(applied.status=="ok" and applied.value.type=="UnlocksSeen" and applied.value.level==level,applied.code)
  assert(profile.Data.unlocksSeen==level)
  profile.Data.xpMilli=0
  applied=service:apply("user",assert(service:prepare("user",{kind="unlocksSeen",level=EconomyConfig.level_cap+1})))
  assert(applied.status=="ok" and applied.value.level==level and profile.Data.unlocksSeen==level,applied.code)
 end)
 test("seen unlocks reject invalid levels without changing saved progress or the operation watermark",function()
  local service,profile=fixture();local before=Schema.canonical(profile.Data)
  for _,input in ipairs({{level=0},{level=-1},{level=1.5},{level="3"},{level=false},{}}) do
   input.kind="unlocksSeen"
   local applied=service:apply("user",assert(service:prepare("user",input)))
   assert(applied.status=="error" and applied.code=="invalid_level",applied.code)
   assert(Schema.canonical(profile.Data)==before,"invalid seen level changed saved progress")
  end
 end)
 test("prestige resets seen unlocks to the new level and preserves all unrelated saved progress",function()
  local service,profile,catalog=fixture()
  profile.Data.unlocksSeen=EconomyConfig.level_cap
  assert(service:view("user").value.prestige==0)
  local before=assert(Schema.copy(profile.Data));local op=assert(service:prepare("user",{kind="prestige"}))
  local applied=service:apply("user",op)
  assert(applied.status=="ok",applied.code)
  assert(applied.value.type=="Prestiged" and applied.value.prestige==1 and applied.value.operationID==op.id)
  local expected=assert(Schema.copy(before));expected.prestige=1;expected.xpMilli=EconomyConfig.initial_total_xp*1000
  expected.unlocksSeen=assert(Economy.levelForXP(expected.xpMilli))
  expected.ownership=assert(Schema.copy(assert(Economy.starterOwnership(catalog))))
  expected.presets[1].loadout=catalog:starterLoadout();expected.version+=1
  expected.operationIds[service.sessions.user.token]=1
  assert(Schema.canonical(profile.Data)==Schema.canonical(expected),"prestige changed unrelated saved progress")
  local view=service:view("user").value
  assert(view.prestige==1 and table.isfrozen(view) and profile.writes==0)
  assert(view.unlocksSeen==Economy.levelForXP(view.xpMilli) and view.unlocksSeen<before.unlocksSeen)
  assert(view.rangeSlot==4 and Schema.canonical(view.rangePresets)==Schema.canonical(before.rangePresets),"prestige changed the Range builds")
 end)
 test("retrying a prestige operation applies it once even after earning back the level cap",function()
  local service,profile=fixture();local op=assert(service:prepare("user",{kind="prestige"}))
  local first=service:apply("user",op);assert(first.status=="ok",first.code)
  local after=Schema.canonical(profile.Data)
  local retry=service:apply("user",op)
  assert(retry.status=="ok" and retry.value.prestige==1 and Schema.canonical(profile.Data)==after)
  local reward=assert(service:prepare("user",{kind="contribution",points=300000,multipliers={paper=1,xp=1}}))
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
 test("doubleLock changes only its saved lock and operation bookkeeping in live and practice profiles",function()
  for _,mock in ipairs({false,true}) do
   local service,profile=fixture(mock);local before=assert(Schema.copy(profile.Data))
   local op=assert(service:prepare("user",{kind="doubleLock",key="match_double_49",matchId="m1",paper=500,xp=900}))
   local locked=service:apply("user",op)
   assert(locked.status=="ok" and locked.value.type=="DoubleLocked" and locked.value.key=="match_double_49",locked.code)
   local expected=assert(Schema.copy(before));expected.doubleLocks.match_double_49={matchId="m1",paper=500,xp=900}
   expected.version+=1;expected.operationIds[service.sessions.user.token]=1
   assert(Schema.canonical(profile.Data)==Schema.canonical(expected),"lock paid or changed unrelated progress")
   local newer=service:apply("user",assert(service:prepare("user",{kind="doubleLock",key="match_double_49",matchId="m2",paper=501,xp=901})))
   assert(newer.status=="ok",newer.code)
   expected.doubleLocks.match_double_49={matchId="m2",paper=501,xp=901}
   expected.version+=1;expected.operationIds[service.sessions.user.token]=2
   assert(Schema.canonical(profile.Data)==Schema.canonical(expected))
   assert(service:apply("user",op).status=="ok" and Schema.canonical(profile.Data)==Schema.canonical(expected))
  end
 end)
 test("doubleLock rejects malformed locks without paying or changing the operation watermark",function()
  local service,profile=fixture();local before=Schema.canonical(profile.Data)
  for _,change in ipairs({function(op)op.key="match_double_50" end,function(op)op.key=nil end,
   function(op)op.paper=0 end,function(op)op.paper=-1 end,function(op)op.paper=1.5 end,function(op)op.paper=nil end,
   function(op)op.xp=-1 end,function(op)op.xp=1.5 end,function(op)op.xp=nil end,
   function(op)op.matchId=nil end,function(op)op.matchId="" end,function(op)op.matchId=1 end,
   function(op)op.matchId=string.rep("m",121) end,function(op)op.extra=true end}) do
   local input={kind="doubleLock",key="match_double_49",matchId="m1",paper=500,xp=900};change(input)
   local rejected=service:apply("user",assert(service:prepare("user",input)))
   assert(rejected.status=="error" and rejected.code=="invalid_double_lock",rejected.code)
   assert(Schema.canonical(profile.Data)==before)
  end
 end)
 test("match doubling pays a saved lock after rejoining once without boosts or a jar share",function()
  local service,profile=fixture();local day=math.floor(service.unix()/86400)
  profile.Data.paperJarMilli=123456;profile.Data.buysToday={day=day,count=2}
  local locked=service:apply("user",assert(service:prepare("user",{kind="doubleLock",key="match_double_49",matchId="m1",paper=500,xp=900})))
  assert(locked.status=="ok",locked.code)
  assert(profile:EndSession());service:detach("user")
  profile=Fake.new(profile.LastSavedData)
  assert(service:attach("user",profile,{connected=true,mapLoaded=true}).status=="ok")
  local before=assert(Schema.copy(profile.Data))
  local input={kind="receipt",receiptId="double/m1",grant={kind="matchDouble",key="match_double_49"}}
  local first=service:apply("user",assert(service:prepare("user",input)))
  assert(first.status=="ok" and first.value.type=="MatchDoubled" and first.value.paper==500 and first.value.xp==900 and first.value.matchId=="m1",first.code)
  local expected=assert(Schema.copy(before))
  expected.paperMilli+=500000;expected.purchasedPaperMilli+=500000;expected.xpMilli+=900000
  expected.doubleLocks.match_double_49=nil
  expected.buysToday.count+=1;expected.receiptIds[Service.receiptKey(input.receiptId)]=true
  expected.version+=1;expected.operationIds[service.sessions.user.token]=1
  assert(Schema.canonical(profile.Data)==Schema.canonical(expected),"double changed unrelated progress or applied boosts")
  local again=service:apply("user",assert(service:prepare("user",input)))
  assert(again.status=="ok" and again.value.type=="ReceiptAlreadyGranted",again.code)
  expected.version+=1;expected.operationIds[service.sessions.user.token]=2
  assert(Schema.canonical(profile.Data)==Schema.canonical(expected),"duplicate receipt changed its payout or buy count")
  assert(profile:EndSession());service:detach("user")
  local reopened=Fake.new(profile.LastSavedData)
  assert(service:attach("user",reopened,{connected=true,mapLoaded=true}).status=="ok")
  local replay=service:apply("user",assert(service:prepare("user",input)))
  assert(replay.status=="ok" and replay.value.type=="ReceiptAlreadyGranted",replay.code)
  assert(reopened.Data.paperMilli==expected.paperMilli and reopened.Data.purchasedPaperMilli==expected.purchasedPaperMilli)
  assert(reopened.Data.xpMilli==expected.xpMilli and reopened.Data.paperJarMilli==before.paperJarMilli and reopened.Data.buysToday.count==3)
  local fallback=service:apply("user",assert(service:prepare("user",{kind="receipt",receiptId="double/second",grant=input.grant})))
  local xp=math.round(490*EconomyConfig.xp_per_point/EconomyConfig.paper_per_point)
  assert(fallback.status=="ok" and fallback.value.paper==490 and fallback.value.xp==xp and fallback.value.matchId==nil,fallback.code)
  assert(reopened.Data.paperMilli==expected.paperMilli+490000 and reopened.Data.xpMilli==expected.xpMilli+xp*1000)
  assert(reopened.Data.buysToday.count==4 and reopened.Data.paperJarMilli==before.paperJarMilli)
 end)
 test("each match double fallback uses its own price step without consuming another key's lock",function()
  local service,profile=fixture()
  assert(service:apply("user",assert(service:prepare("user",{kind="doubleLock",key="match_double_49",matchId="m1",paper=500,xp=900}))).status=="ok")
  for _,step in ipairs(Commerce.MATCH_DOUBLE_STEPS) do
   if step~=49 then
    local before=assert(Schema.copy(profile.Data));local paper=step*10
    local xp=math.round(paper*EconomyConfig.xp_per_point/EconomyConfig.paper_per_point)
    local paid=service:apply("user",assert(service:prepare("user",{kind="receipt",receiptId="double/fallback/"..step,
     grant={kind="matchDouble",key="match_double_"..step}})))
    assert(paid.status=="ok" and paid.value.paper==paper and paid.value.xp==xp and paid.value.matchId==nil,paid.code)
    assert(profile.Data.paperMilli==before.paperMilli+paper*1000 and profile.Data.xpMilli==before.xpMilli+xp*1000)
    assert(profile.Data.paperJarMilli==before.paperJarMilli and profile.Data.buysToday.count==before.buysToday.count+1)
    assert(Schema.canonical(profile.Data.doubleLocks)==Schema.canonical(before.doubleLocks))
   end
  end
 end)
 test("match doubling accepts zero XP and rolls back Paper and receipt on XP overflow",function()
  local service,profile=fixture();local before=profile.Data.xpMilli
  assert(service:apply("user",assert(service:prepare("user",{kind="doubleLock",key="match_double_10",matchId="zero",paper=1,xp=0}))).status=="ok")
  local paid=service:apply("user",assert(service:prepare("user",{kind="receipt",receiptId="double/zero",
   grant={kind="matchDouble",key="match_double_10"}})))
  assert(paid.status=="ok" and paid.value.xp==0 and profile.Data.xpMilli==before,paid.code)
  for _,overflow in ipairs({function()profile.Data.xpMilli=Economy.MAX_SAFE_INTEGER-999 end,
   function()profile.Data.xpMilli=0 end}) do
   overflow()
   local xp=profile.Data.xpMilli==0 and Economy.MAX_SAFE_INTEGER or 1
   assert(service:apply("user",assert(service:prepare("user",{kind="doubleLock",key="match_double_49",matchId="overflow",paper=500,xp=xp}))).status=="ok")
   local snapshot=Schema.canonical(profile.Data)
   local refused=service:apply("user",assert(service:prepare("user",{kind="receipt",receiptId="double/overflow",
    grant={kind="matchDouble",key="match_double_49"}})))
   assert(refused.status=="error" and refused.code=="overflow",refused.code)
   assert(Schema.canonical(profile.Data)==snapshot,"failed double left a partial grant")
  end
 end)
 test("practice match doubling counts a buy and respects the same receipt ceiling",function()
  local service,profile=fixture(true);local jar=profile.Data.paperJarMilli
  assert(service:apply("user",assert(service:prepare("user",{kind="doubleLock",key="match_double_49",matchId="practice",paper=500,xp=900}))).status=="ok")
  local op=assert(service:prepare("user",{kind="matchDouble",key="match_double_49"}))
  local before=assert(Schema.copy(profile.Data));local paid=service:apply("user",op)
  assert(paid.status=="ok" and paid.value.type=="MatchDoubled" and paid.value.matchId=="practice",paid.code)
  assert(profile.Data.paperMilli==before.paperMilli+500000 and profile.Data.purchasedPaperMilli==before.purchasedPaperMilli+500000)
  assert(profile.Data.xpMilli==before.xpMilli+900000 and profile.Data.paperJarMilli==jar and profile.Data.buysToday.count==1)
  assert(profile.Data.receiptIds[Service.receiptKey("mock:"..op.id)])
  profile.Data.receiptIds={}
  for i=1,require(Root.Generated.Server).schema.max_receipts do profile.Data.receiptIds[Service.receiptKey("saved_"..i)]=true end
  assert(service:apply("user",assert(service:prepare("user",{kind="doubleLock",key="match_double_49",matchId="at-cap",paper=500,xp=900}))).status=="ok")
  local snapshot=Schema.canonical(profile.Data)
  local refused=service:apply("user",assert(service:prepare("user",{kind="matchDouble",key="match_double_49"})))
  assert(refused.status=="error" and refused.code=="receipt_cap" and Schema.canonical(profile.Data)==snapshot,refused.code)
 end)
 test("practice match doubling rejects supplied amounts or invalid keys without consuming a lock",function()
  local service,profile=fixture(true)
  assert(service:apply("user",assert(service:prepare("user",{kind="doubleLock",key="match_double_49",matchId="m1",paper=500,xp=900}))).status=="ok")
  local before=Schema.canonical(profile.Data)
  for _,input in ipairs({{kind="matchDouble"},{kind="matchDouble",key="match_double_50"},
   {kind="matchDouble",key="match_double_49",paper=500},{kind="matchDouble",key="match_double_49",xp=900},
   {kind="matchDouble",key="match_double_49",extra=true}}) do
   assert(service:apply("user",assert(service:prepare("user",input))).status=="error")
   assert(Schema.canonical(profile.Data)==before)
  end
 end)
 test("part receipts unlock each part category at level one without Paper or XP changes",function()
  for _,id in ipairs({"nose_5","eraser","boost_twin"}) do
   local service,profile=fixture();profile.Data.xpMilli=0
   local before=assert(Schema.copy(profile.Data))
   local paperPurchase=service:apply("user",assert(service:prepare("user",{kind="equipmentPurchase",catalogID=id})))
   assert(paperPurchase.status=="error" and paperPurchase.code=="level_locked",paperPurchase.code)
   assert(Schema.canonical(profile.Data)==Schema.canonical(before))
   local input={kind="receipt",receiptId="part/"..id,grant={kind="partUnlock",catalogID=id}}
   local op=assert(service:prepare("user",input));local first=service:apply("user",op)
   assert(first.status=="ok" and first.value.type=="PartUnlocked" and first.value.catalogID==id,first.code)
   local expected=assert(Schema.copy(before));expected.ownership[id]=true;expected.receiptIds[Service.receiptKey(input.receiptId)]=true
   expected.buysToday={day=math.floor(service.unix()/86400),count=1}
   expected.version+=1;expected.operationIds[service.sessions.user.token]=2
   assert(Schema.canonical(profile.Data)==Schema.canonical(expected),"part unlock changed unrelated progress")
   local after=Schema.canonical(profile.Data)
   assert(service:apply("user",op).status=="ok" and Schema.canonical(profile.Data)==after)
   assert(profile:EndSession());service:detach("user")
   local reopened=Fake.new(profile.LastSavedData)
   assert(service:attach("user",reopened,{connected=true,mapLoaded=true}).status=="ok")
   local replay=service:apply("user",assert(service:prepare("user",input)))
   assert(replay.status=="ok" and replay.value.type=="ReceiptAlreadyGranted",replay.code)
   assert(reopened.Data.ownership[id] and reopened.Data.paperMilli==before.paperMilli and reopened.Data.xpMilli==0)
   assert(reopened.Data.purchasedPaperMilli==before.purchasedPaperMilli and reopened.Data.earnedPaperMilli==before.earnedPaperMilli)
  end
 end)
 test("an already owned part still records its racing receipt and replays as granted",function()
  local service,profile=fixture();local before=assert(Schema.copy(profile.Data))
  local input={kind="receipt",receiptId="owned/part",grant={kind="partUnlock",catalogID="staple"}}
  local first=service:apply("user",assert(service:prepare("user",input)))
  assert(first.status=="ok" and first.value.type=="PartAlreadyOwned",first.code)
  local expected=assert(Schema.copy(before));expected.receiptIds[Service.receiptKey(input.receiptId)]=true
  expected.buysToday={day=math.floor(service.unix()/86400),count=1}
  expected.version+=1;expected.operationIds[service.sessions.user.token]=1
  assert(Schema.canonical(profile.Data)==Schema.canonical(expected))
  local replay=service:apply("user",assert(service:prepare("user",input)))
  assert(replay.status=="ok" and replay.value.type=="ReceiptAlreadyGranted",replay.code)
 end)
 test("unknown part receipts fail without recording a receipt or advancing the saved operation",function()
  local service,profile=fixture();local before=Schema.canonical(profile.Data)
  local refused=service:apply("user",assert(service:prepare("user",{kind="receipt",receiptId="missing/part",
   grant={kind="partUnlock",catalogID="missing_part"}})))
  assert(refused.status=="error" and refused.code=="unknown_part",refused.code)
  assert(Schema.canonical(profile.Data)==before)
 end)
 test("a receipt-owned high-level part can be saved in a level one preset and reloaded",function()
  local service,profile,catalog=fixture();profile.Data.xpMilli=0
  local granted=service:apply("user",assert(service:prepare("user",{kind="receipt",receiptId="preset/part",
   grant={kind="partUnlock",catalogID="eraser"}})))
  assert(granted.status=="ok",granted.code)
  local loadout=catalog:starterLoadout();loadout.weapon_mounts[1]="eraser"
  local saved=service:apply("user",assert(service:prepare("user",{kind="preset",slot=1,name="Early eraser",loadout=loadout})))
  assert(saved.status=="ok" and saved.value.type=="PresetSaved",saved.code)
  assert(Schema.validate(profile.Data,catalog) and Economy.levelForXP(profile.Data.xpMilli)==1)
  assert(profile:EndSession());service:detach("user")
  local reopened=Fake.new(profile.LastSavedData)
  assert(service:attach("user",reopened,{connected=true,mapLoaded=true}).status=="ok")
  assert(Schema.validate(reopened.Data,catalog) and reopened.Data.presets[1].loadout.weapon_mounts[1]=="eraser")
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
   {kind="boostIntent",resource="xp",action="duration",seconds=1,wholePaper=10},{kind="statistics",deltas={wins=1}},
   {kind="partUnlock"},{kind="partUnlock",catalogID=""},{kind="partUnlock",catalogID=1},
   {kind="partUnlock",catalogID="eraser",wholePaper=1},{kind="partUnlock",catalogID="eraser",extra=true},
   {kind="matchDouble"},{kind="matchDouble",key=false},{kind="matchDouble",key="match_double_50"},
   {kind="matchDouble",key="paper_pack_1500"},{kind="matchDouble",key="match_double_049"},
   {kind="matchDouble",paper=500,xp=900},{kind="matchDouble",key="match_double_49",paper=500},
   {kind="matchDouble",key="match_double_49",xp=900},{kind="matchDouble",key="match_double_49",matchId="m1"},
   {kind="matchDouble",key="match_double_49",extra=true},
   {kind="doubleLock",key="match_double_49",matchId="m1",paper=500,xp=900}}
  for _,grant in ipairs(grants) do
   local refused=service:apply("user",assert(service:prepare("user",{kind="receipt",receiptId="invalid",grant=grant})))
   assert(refused.status=="error" and refused.code=="invalid_receipt_grant",refused.code)
   assert(Schema.canonical(profile.Data)==before)
  end
  for _,input in ipairs({{kind="receipt",receiptId="",grant={kind="purchasedPaper",wholePaper=1}},
   {kind="receipt",receiptId=42,grant={kind="purchasedPaper",wholePaper=1}},{kind="passGrant",resource="other"},
   {kind="partUnlock",catalogID="eraser"}}) do
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
  for _,input in ipairs({{kind="purchasedPaper",wholePaper=1000},{kind="boostIntent",resource="xp",action="permanent"},
   {kind="matchDouble",key="match_double_49"}}) do
   local refused=service:apply("user",assert(service:prepare("user",input)))
   assert(refused.status=="error" and refused.code=="studio_only" and Schema.canonical(profile.Data)==before)
  end
 end)
 return result
end
return Spec
