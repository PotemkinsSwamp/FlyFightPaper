local Root=game.ReplicatedStorage.FlyFightPaper
local Service=require(game.ServerScriptService.FlyFightPaper.ProfileService)
local Schema=require(Root.Shared.ProfileSchema)
local Missions=require(Root.Shared.Missions)
local Economy=require(Root.Shared.EconomyRules)
local Looks=require(Root.Shared.LooksRules)
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
local DAY=86400
local MONDAY=1704067200
local function missionFixture(mock)
 local service,profile=fixture(mock)
 local now=MONDAY
 service.unix=function()return now end
 local function apply(input)
  local op=assert(service:prepare("user",input))
  return service:apply("user",op),op
 end
 local function time(value) now=value end
 local view=service:view("user",true)
 assert(view.status=="ok" and #view.value.missions.daily==3)
 return service,profile,apply,time
end
local function matchSummary(at)
 return {eligible=true,completedAt=at,mode="FFA",folds=1,assists=0,damage=0,paper=0,seconds=0,
  wins=0,top3=0,targets=0,boosts=0,zone_points=0,zone_folds=0,deaths=10,best_life=0,byGear={}}
end
function Spec.run()
 local result,test=Suite.new()
 test("earned chest source spends stock once, including retries and rejoining",function()
  local service,profile=fixture()
  local function apply(input)
   return service:apply("user",assert(service:prepare("user",input)))
  end
  local draw={kind="openChest",chest="trail_sticker",opened=0,source="earned"}
  assert(profile.Data.chests.stock.sticker==0 and apply(draw).code=="no_earned_chest")
  profile.Data.chests.stock.sticker=1
  local balance=profile.Data.paperMilli
  local first=assert(service:prepare("user",draw))
  local result=service:apply("user",first)
  assert(result.status=="ok" and result.value.type=="ChestOpened",result.code)
  local id=result.value.skin
  assert(Looks.item(id).kind=="trail")
  assert(profile.Data.chests.stock.sticker==0 and profile.Data.chests.opened==1 and profile.Data.chests.lastSkin==id)
  assert(profile.Data.chests.lastChest=="trail_sticker" and profile.Data.looks.owned[id] and profile.Data.paperMilli==balance)
  assert(profile.Data.looks.skin=="" and profile.Data.looks.trail=="" and profile.Data.chests.lastRefund==0)
  assert(service:apply("user",first).value.skin==id and apply(draw).code=="stale_chest")
  assert(profile:EndSession());service:detach("user")
  local reopened=Fake.new(profile.LastSavedData)
  assert(service:attach("user",reopened,{connected=true,mapLoaded=true}).status=="ok")
  assert(reopened.Data.chests.lastSkin==id and reopened.Data.looks.owned[id] and apply(draw).code=="stale_chest")
 end)
 test("mission claims pay earned Paper, XP, and each chest tier once",function()
  local service,profile,apply=missionFixture()
  local data=profile.Data
  data.xpMilli=190000
  data.presets[1].loadout=service.catalog:starterLoadout()
  local paper,earned,purchased,xp,version=data.paperMilli,data.earnedPaperMilli,data.purchasedPaperMilli,data.xpMilli,data.version
  local daily=data.missions.daily[2];daily.progress=Missions.goal(daily)
  local weekly=data.missions.weekly[3];weekly.progress=Missions.goal(weekly)
  data.missions.dailiesDone=15
  local claim,op=apply({kind="missionClaim",list="daily",index=2})
  assert(claim.status=="ok" and claim.value.reward.paper==200 and claim.value.reward.xp==250)
  data=profile.Data
  assert(data.missions.daily[2].claimed and data.version==version+1)
  assert(data.paperMilli==paper+200000 and data.earnedPaperMilli==earned+200000 and data.purchasedPaperMilli==purchased)
  assert(data.xpMilli==xp+250000 and Economy.levelForXP(data.xpMilli)>Economy.levelForXP(xp))
  assert(service:apply("user",op).replayed and profile.Data.version==version+1)
  assert(apply({kind="missionClaim",list="daily",index=2}).code=="not_claimable")
  assert(apply({kind="missionClaim",list="weekly",index=3}).status=="ok")
  assert(apply({kind="missionClaim",list="fixed",index=1}).status=="ok")
  data=profile.Data
  assert(data.chests.stock.sticker==1 and data.chests.stock.blue_ribbon==1 and data.missions.fixedClaimed)
  assert(data.paperMilli==paper+2200000 and data.earnedPaperMilli==earned+2200000)
 end)
 test("mission swaps use the saved price and deduct Paper with the replacement",function()
  local service,profile,apply=missionFixture()
  profile.Data.paperMilli=149500
  local before=profile.Data.missions.daily[1].action
  local free=apply({kind="missionSwap",list="daily",index=1})
  assert(free.status=="ok" and free.value.price==0 and profile.Data.paperMilli==149500)
  assert(profile.Data.missions.daily[1].action~=before and profile.Data.missions.dailySwaps==1)
  local snapshot=Schema.canonical(profile.Data)
  local short=apply({kind="missionSwap",list="daily",index=1})
  assert(short.code=="not_enough_paper" and short.value.shortfall==1 and Schema.canonical(profile.Data)==snapshot)
  assert(apply({kind="missionSwap",list="fixed",index=1}).code=="invalid_mission")
  assert(apply({kind="missionSwap",list="daily",index=1,price=0}).code=="invalid_operation")
  profile.Data.paperMilli=150500
  local paid,op=apply({kind="missionSwap",list="daily",index=1})
  assert(paid.status=="ok" and paid.value.price==150 and profile.Data.paperMilli==500)
  assert(profile.Data.missions.dailySwaps==2 and service:apply("user",op).replayed and profile.Data.paperMilli==500)
 end)
 test("refreshing the player view saves rollover rewards once before returning the profile",function()
  local service,profile,_,time=missionFixture()
  local sunday=MONDAY+6*DAY;time(sunday)
  assert(service:view("user",true).status=="ok")
  local data=profile.Data
  local daily,weekly=data.missions.daily[1],data.missions.weekly[2]
  daily.progress=Missions.goal(daily);weekly.progress=Missions.goal(weekly)
  data.missions.dailiesDone=15
  local paper,xp,version=data.paperMilli,data.xpMilli,data.version
  time(sunday+DAY)
  assert(service:view("user").value.missions.day==sunday//DAY)
  local view=service:view("user",true)
  assert(view.status=="ok" and view.value.missions.day==(sunday+DAY)//DAY and view.value.version==version+1)
  assert(view.value.paperMilli==paper+100000 and view.value.xpMilli==xp+150000)
  assert(view.value.chests.stock.sticker==1 and view.value.chests.stock.blue_ribbon==1)
  assert(profile.Data.version==view.value.version and Schema.canonical(profile.Data.missions)==Schema.canonical(view.value.missions))
  time(sunday+DAY-1)
  local stale=service:view("user",true)
  assert(stale.status=="ok" and stale.value.missions.day==view.value.missions.day and stale.value.version==version+1)
  time(sunday+DAY)
  assert(service:view("user",true).value.version==version+1 and profile.Data.chests.stock.sticker==1)
 end)
 test("a refused claim still settles completed cards from the previous UTC day",function()
  local service,profile,apply,time=missionFixture()
  local mission=profile.Data.missions.daily[1];mission.progress=Missions.goal(mission)
  local paper,version=profile.Data.paperMilli,profile.Data.version
  time(MONDAY+DAY)
  local refused,op=apply({kind="missionClaim",list="daily",index=1})
  assert(refused.code=="not_claimable" and profile.Data.missions.day==MONDAY//DAY+1)
  assert(profile.Data.paperMilli==paper+100000 and profile.Data.version==version+1)
  assert(service:apply("user",op).code=="not_claimable" and profile.Data.version==version+1)
 end)
 test("earlier, ineligible and bad mission summaries leave statistics and earned stock intact",function()
  local service,profile,apply=missionFixture()
  profile.Data.chests.stock.sticker=3
  local missions=Schema.canonical(profile.Data.missions)
  local matches=profile.Data.statistics.matches
  local ineligible=matchSummary(MONDAY+DAY);ineligible.eligible=false
  local invalid=matchSummary(MONDAY+DAY);invalid.folds=-1
  local unserializable=matchSummary(MONDAY+DAY);unserializable.folds=0/0
  for _,summary in {matchSummary(MONDAY-DAY),ineligible,invalid,unserializable} do
   local result=apply({kind="statistics",deltas={matches=1},missions=summary})
   assert(result.status=="ok" and #result.value.finishedMissions==0)
   assert(Schema.canonical(profile.Data.missions)==missions and profile.Data.chests.stock.sticker==3)
  end
  assert(profile.Data.statistics.matches==matches+4)
  assert(service.missionWarnings.stale_period and service.missionWarnings.ineligible_match and service.missionWarnings.invalid_match_summary)
 end)
 test("a failed rollover payout leaves all mission rewards pending and still saves match stats",function()
  local _,profile,apply,time=missionFixture()
  local sunday=MONDAY+6*DAY
  time(sunday)
  assert(apply({kind="missionSwap",list="daily",index=1}).status=="ok")
  local data=profile.Data
  local daily,weekly=data.missions.daily[1],data.missions.weekly[2]
  daily.progress=Missions.goal(daily);weekly.progress=Missions.goal(weekly)
  data.chests.stock.sticker=Economy.MAX_SAFE_INTEGER
  local paper,matches=data.paperMilli,data.statistics.matches
  local missions=Schema.canonical(data.missions)
  local settled=apply({kind="statistics",deltas={matches=1},missions=matchSummary(sunday+DAY)})
  assert(settled.status=="ok" and #settled.value.finishedMissions==0 and profile.Data.statistics.matches==matches+1)
  assert(profile.Data.paperMilli==paper and Schema.canonical(profile.Data.missions)==missions)
  assert(profile.Data.chests.stock.sticker==Economy.MAX_SAFE_INTEGER)
 end)
 test("match progress uses its completion day and returns newly finished cards once",function()
  local service,profile,apply,time=missionFixture()
  local day=MONDAY+DAY
  time(day);assert(service:view("user",true).status=="ok")
  profile.Data.missions.daily={
   {tier="easy",kind="total",action="matches",count=1,progress=0,claimed=false},
   {tier="medium",kind="total",action="assists",count=14,progress=0,claimed=false},
   {tier="hard",kind="total",action="folds",count=35,progress=0,claimed=false},
  }
  time(day+DAY)
  local settled,op=apply({kind="statistics",deltas={matches=1},missions=matchSummary(day)})
  assert(settled.status=="ok" and profile.Data.missions.day==day//DAY)
  assert(settled.value.finishedMissions[1].action=="matches" and profile.Data.missions.daily[1].progress==1)
  assert(service:apply("user",op).replayed and profile.Data.missions.dailiesDone>=1)
 end)
 test("refresh retains missions for level-unlocked gear and replaces lost gear",function()
  local service,profile=missionFixture()
  local catalog,data=service.catalog,profile.Data
  local free
  for _,weapon in catalog.weapons do
   if not data.ownership[weapon.id] and weapon.paper_price==0 and weapon.min_level>1 then free=weapon.id;break end
  end
  assert(free,"test catalog needs a free weapon unlocked after level one")
  data.missions.daily={
   {tier="easy",kind="total",action="folds",count=6,progress=1,gear=free,claimed=false},
   {tier="medium",kind="total",action="assists",count=7,progress=1,gear="spitball",claimed=false},
   {tier="hard",kind="total",action="matches",count=3,progress=1,claimed=false},
  }
  assert(not catalog:owns(data.ownership,"spitball",Economy.levelForXP(data.xpMilli)))
  local view=service:view("user",true)
  assert(view.status=="ok" and view.value.missions.daily[1].gear==free and view.value.missions.daily[1].progress==1)
  assert(view.value.missions.daily[2].action~="assists" and view.value.missions.daily[2].progress==0)
 end)
 test("Studio mission finishing respects saved claims and is refused for a live-style profile",function()
  local _,profile,apply=missionFixture(true)
  profile.Data.missions.daily[1].claimed=true
  profile.Data.missions.daily[1].progress=Missions.goal(profile.Data.missions.daily[1])
  assert(apply({kind="devFinishMissions"}).status=="ok")
  assert(profile.Data.missions.dailiesDone==15 and profile.Data.missions.daily[1].claimed)
  for _,list in {"daily","weekly"} do
   for _,mission in profile.Data.missions[list] do assert(mission.progress==Missions.goal(mission)) end
  end
  local _,live,liveApply=missionFixture()
  local before=Schema.canonical(live.Data)
  assert(liveApply({kind="devFinishMissions"}).code=="studio_only" and Schema.canonical(live.Data)==before)
 end)
 test("paid openings require a positive policy response and enough Paper, and duplicates refund once at face value",function()
  local service,profile=fixture();local player={}
  service.policyInfo=function(who) assert(who==player);return {ArePaidRandomItemsRestricted=false} end
  local function apply(op)
   return service:apply("user",assert(service:prepare("user",op)))
  end
  local draw={kind="openChest",chest="golden_star",opened=0,source="paper"}
  assert(apply(draw).code=="chest_paper_unavailable")
  assert(service:chestPaperAllowed("user",player))
  profile.Data.chests.stock.golden_star=1
  assert(apply(draw).code=="insufficient_paper" and profile.Data.chests.stock.golden_star==1)
  local price=Looks.chest(draw.chest).cost*Economy.MILLI
  profile.Data.paperMilli=2*price
  service.random=function(n)return n end
  local grant=apply(draw)
  assert(grant.status=="ok" and grant.value.skin=="origami_crane",grant.code)
  assert(profile.Data.chests.stock.golden_star==1 and profile.Data.looks.owned.folded_petals and profile.Data.paperMilli==price)
  draw.opened=1
  local duplicate=apply(draw)
  assert(duplicate.status=="ok" and duplicate.value.refund==6000,duplicate.code)
  assert(profile.Data.chests.lastRefund==6000 and profile.Data.paperMilli==6000*Economy.MILLI)
  assert(profile.Data.chests.stock.golden_star==1 and apply(draw).code=="stale_chest")
 end)
 test("restricted, missing, or failed policy blocks only the paid opening; client cannot choose a result or permission",function()
  for _,policy in {function() return {ArePaidRandomItemsRestricted=true} end,function() return {} end,function() error("unavailable") end} do
   local service,profile=fixture()
   service.policyInfo=policy
   assert(not service:chestPaperAllowed("user",{}))
   profile.Data.chests.stock.paper=1
   local function apply(op)
    return service:apply("user",assert(service:prepare("user",op)))
   end
   local before=Schema.canonical(profile.Data)
   for _,example in {
    {{kind="openChest",chest="paper",opened=0,source="paper"},"chest_paper_unavailable"},
    {{kind="openChest",chest="paper",opened=0,source="paidStock"},"chest_paper_unavailable"},
    {{kind="openChest",chest="unknown",opened=0,source="earned"},"unknown_chest"},
    {{kind="openChest",chest="paper",opened=0,source="earned",lookID="dragon"},"invalid_operation"},
    {{kind="openChest",chest="paper",opened=0,source="paper",allowed=true},"invalid_operation"},
    {{kind="openChest",chest="paper",opened=-1,source="earned"},"invalid_operation"},
    {{kind="openChest",chest="paper",opened=0},"invalid_operation"},
   } do
    assert(apply(example[1]).code==example[2])
    assert(Schema.canonical(profile.Data)==before)
   end
   assert(apply({kind="openChest",chest="paper",opened=0,source="earned"}).status=="ok")
   assert(profile.Data.chests.stock.paper==0 and profile.Data.looks.owned[profile.Data.chests.lastSkin])
  end
 end)
 test("retired direct cosmetic purchases leave balances and saves untouched",function()
  local service,profile=fixture()
  local before=Schema.canonical(profile.Data)
  for id,code in {water_spray="chest_only",confetti="chest_only",dragon="chest_only",missing="unknown_look",folded_petals="not_sold"} do
   local refused=service:apply("user",assert(service:prepare("user",{kind="lookPurchase",lookID=id})))
   assert(refused.status=="error" and refused.code==code,refused.code)
   assert(Schema.canonical(profile.Data)==before)
  end
 end)
 test("a paid chest receipt is durable before opening and can be redeemed only in its purchased family",function()
  local service,profile=fixture()
  local function apply(input) return service:apply("user",assert(service:prepare("user",input))) end
  local receipt={kind="receipt",receiptId="paid/trail",grant={kind="paidChest",chest="trail_paper"}}
  assert(apply(receipt).status=="ok" and profile.Data.chests.paidStock.trail_paper==1)
  assert(profile.Data.chests.opened==0 and next(profile.Data.looks.owned)==nil)
  assert(profile:EndSession());service:detach("user")
  profile=Fake.new(profile.LastSavedData)
  assert(service:attach("user",profile,{connected=true,mapLoaded=true}).status=="ok")
  assert(apply(receipt).value.type=="ReceiptAlreadyGranted" and profile.Data.chests.paidStock.trail_paper==1)
  local function open(chest,source) return apply({kind="openChest",chest=chest,source=source,opened=0}) end
  assert(open("trail_paper","paidStock").code=="chest_paper_unavailable")
  service.policyInfo=function() return {ArePaidRandomItemsRestricted=false} end
  assert(service:chestPaperAllowed("user",{}))
  assert(open("paper","paidStock").code=="no_paid_chest" and open("trail_paper","earned").code=="no_earned_chest")
  assert(open("trail_paper","paidStock").status=="ok" and profile.Data.chests.paidStock.trail_paper==0)
  assert(Looks.item(profile.Data.chests.lastSkin).kind=="trail" and profile.Data.chests.stock.paper==0)
 end)
 test("wearing owned looks saves both choices, survives rejoining and removes them without removing ownership",function()
  local service,profile=fixture();profile.Data.looks.owned={shark_jet=true,water_spray=true}
  local before=assert(Schema.copy(profile.Data));local op=assert(service:prepare("user",{kind="lookWear",skinID="shark_jet",trailID="water_spray"}))
  local worn=service:apply("user",op)
  assert(worn.status=="ok" and worn.value.type=="LooksWorn",worn.code)
  local expected=assert(Schema.copy(before));expected.looks.skin="shark_jet";expected.looks.trail="water_spray"
  expected.version+=1;expected.operationIds[service.sessions.user.token]=1
  assert(Schema.canonical(profile.Data)==Schema.canonical(expected),"wear changed unrelated saved progress")
  local after=Schema.canonical(profile.Data)
  assert(service:apply("user",op).status=="ok" and Schema.canonical(profile.Data)==after)
  assert(profile:EndSession());service:detach("user")
  profile=Fake.new(profile.LastSavedData)
  assert(service:attach("user",profile,{connected=true,mapLoaded=true}).status=="ok")
  assert(profile.Data.looks.skin=="shark_jet" and profile.Data.looks.trail=="water_spray")
  before=assert(Schema.copy(profile.Data))
  local removed=service:apply("user",assert(service:prepare("user",{kind="lookWear",skinID="",trailID=""})))
  assert(removed.status=="ok",removed.code)
  expected=assert(Schema.copy(before));expected.looks.skin="";expected.looks.trail=""
  expected.version+=1;expected.operationIds[service.sessions.user.token]=1
  assert(Schema.canonical(profile.Data)==Schema.canonical(expected),"taking looks off changed ownership or other progress")
 end)
 test("quick consecutive changes to separate cosmetic slots preserve both saved selections",function()
  local service,profile=fixture()
  profile.Data.looks.owned={shark_jet=true,water_spray=true}
  local skin=assert(service:prepare("user",{kind="lookWear",slot="skin",lookID="shark_jet"}))
  local trail=assert(service:prepare("user",{kind="lookWear",slot="trail",lookID="water_spray"}))
  assert(service:apply("user",skin).status=="ok")
  local result=service:apply("user",trail)
  assert(result.status=="ok" and result.value.skinID=="shark_jet" and result.value.trailID=="water_spray")
  assert(profile.Data.looks.skin=="shark_jet" and profile.Data.looks.trail=="water_spray")
  local clear=assert(service:prepare("user",{kind="lookWear",slot="skin",lookID=""}))
  assert(service:apply("user",clear).status=="ok" and profile.Data.looks.skin=="" and profile.Data.looks.trail=="water_spray")
 end)
 test("unowned or mismatched looks refuse the whole wear operation without advancing the saved operation",function()
  local service,profile=fixture();profile.Data.looks={owned={shark_jet=true,water_spray=true},skin="shark_jet",trail="water_spray"}
  local before=Schema.canonical(profile.Data)
  for _,ids in ipairs({{"dragon","water_spray"},{"shark_jet","confetti"},{"water_spray",""},{"","shark_jet"}}) do
   local refused=service:apply("user",assert(service:prepare("user",{kind="lookWear",skinID=ids[1],trailID=ids[2]})))
   assert(refused.status=="error" and (refused.code=="not_owned" or refused.code=="wrong_kind"),refused.code)
   assert(Schema.canonical(profile.Data)==before,"refused wear partially changed the save")
  end
 end)
 test("look operations reject missing, oversized, non-string or extra fields without changing saved progress",function()
  local service,profile=fixture();local before=Schema.canonical(profile.Data)
  for _,input in ipairs({{kind="lookPurchase"},{kind="lookPurchase",lookID=""},{kind="lookPurchase",lookID=false},
   {kind="lookPurchase",lookID=1},{kind="lookPurchase",lookID=string.rep("x",161)},
   {kind="lookPurchase",lookID="confetti",extra=true},{kind="lookPurchase",lookID="confetti",price=0},
   {kind="lookWear"},{kind="lookWear",skinID=""},{kind="lookWear",trailID=""},
   {kind="lookWear",slot="wrong",lookID=""},{kind="lookWear",slot="skin",lookID="",trailID=""},
   {kind="lookWear",skinID=false,trailID=""},{kind="lookWear",skinID="",trailID=1},
   {kind="lookWear",skinID=string.rep("x",161),trailID=""},{kind="lookWear",skinID="",trailID=string.rep("x",161)},
   {kind="lookWear",skinID="",trailID="",extra=true},{kind="lookWear",skinID="",trailID="",lookID="confetti"}}) do
   local refused=service:apply("user",assert(service:prepare("user",input)))
   assert(refused.status=="error" and refused.code=="invalid_operation",refused.code)
   assert(Schema.canonical(profile.Data)==before,"invalid look operation changed the save")
  end
  local bound=string.rep("x",160)
  local refused=service:apply("user",assert(service:prepare("user",{kind="lookPurchase",lookID=bound})))
  assert(refused.status=="error" and refused.code=="unknown_look" and Schema.canonical(profile.Data)==before,refused.code)
  refused=service:apply("user",assert(service:prepare("user",{kind="lookWear",skinID=bound,trailID=""})))
  assert(refused.status=="error" and refused.code=="not_owned" and Schema.canonical(profile.Data)==before,refused.code)
 end)
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
  profile.Data.emotes={owned={APlus=true,Nap=true},leader="APlus",runnerUp="Nap"}
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
  assert(Schema.canonical(view.emotes)==Schema.canonical(before.emotes),"prestige changed the emotes")
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
