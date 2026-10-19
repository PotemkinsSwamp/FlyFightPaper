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
 return result
end
return Spec
