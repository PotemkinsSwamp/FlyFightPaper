local Root=game.ReplicatedStorage.FlyFightPaper
local Server=game.ServerScriptService.FlyFightPaper
local Profile=require(Server.ProfileService)
local Runtime=require(Server.ProfileRuntime)
local Hangar=require(Server.HangarService)
local Schema=require(Root.Shared.ProfileSchema)
local Commerce=require(Root.Shared.CommerceRules)
local Economy=require(Root.Shared.EconomyRules)
local EconomyConfig=require(Root.Generated.Economy)
local Catalog=require(Root.Shared.Catalog)
local Fake=require(script.Parent.Parent.fixtures.FakeProfiles)
local Suite=require(script.Parent.Parent.fixtures.Suite)
local Spec={}
local DAY=86400
local function fixture(options)
 options=options or {}
 local f={now=20000*DAY+100,mono=100}
 f.catalog=Catalog.new(require(Root.Generated.Catalog),require(Root.Generated.Gameplay))
 local data=Schema.defaults(f.catalog)
 if options.setup then options.setup(data) end
 f.profile=Fake.new(data)
 f.service=Profile.new({catalog=f.catalog,mock=options.mock==true,unix=function()return f.now end,monotonic=function()return f.mono end})
 local attached=f.service:attach("user",f.profile,{connected=true,mapLoaded=true})
 assert(attached.status=="ok",attached.code)
 f.player={UserId=123,attributes={}}
 function f.player:SetAttribute(key,value)self.attributes[key]=value end
 f.entry={player=f.player,account="user",loaded=true,lastSavedVersion=0}
 f.runtime=setmetatable({service=f.service,mock=options.mock==true,entries={[f.player]=f.entry}},Runtime)
 f.runtime:update(f.entry)
 function f:apply(input)
  local op=assert(self.service:prepare("user",input))
  local result=self.service:apply("user",op)
  self.runtime:update(self.entry)
  return result,op
 end
 function f:receipt(key,id)
  local offer=assert(Commerce.catalog(require(Root.Generated.Commerce))).byKey[key]
  return self:apply({kind="receipt",receiptId=id or "receipt/"..key,grant=Commerce.operation(assert(offer))})
 end
 function f:claim(day)return self:apply({kind="dailyGift",day=day or math.floor(self.now/DAY)})end
 function f:rejoin()
  assert(self.profile:EndSession());self.service:detach("user")
  self.profile=Fake.new(self.profile.LastSavedData)
  local joined=self.service:attach("user",self.profile,{connected=true,mapLoaded=true})
  assert(joined.status=="ok",joined.code);self.runtime:update(self.entry)
 end
 return f
end
function Spec.run()
 local result,test=Suite.new()
 test("schema 8 migration adds shop defaults and preserves the entire old save without mutating it",function()
  local f=fixture();local old=assert(Schema.copy(f.profile.Data))
  old.schemaVersion=8;old.dailyGift=nil;old.starterPack=nil;old.firstBuys=nil;old.buysToday=nil
  old.paperMilli=123456;old.receiptIds.old_receipt=true;old.extensions={keep="old data"}
  local before=Schema.canonical(old);local migrated=assert(Schema.migrate(old,f.catalog))
  local expected=assert(Schema.copy(old));expected.schemaVersion=Schema.VERSION
  expected.dailyGift={next=1,lastDay=-1};expected.starterPack={offeredAt=0,bought=false}
  expected.firstBuys={};expected.buysToday={day=-1,count=0}
  assert(Schema.canonical(migrated)==Schema.canonical(expected) and Schema.canonical(old)==before)
  assert(not Schema.validate(old,f.catalog),"validation must not silently migrate")
 end)
 test("shop schema fields reject missing unknown malformed and out-of-range values",function()
  local f=fixture()
  local changes={
   function(p)p.dailyGift=nil end,function(p)p.dailyGift.next=0 end,function(p)p.dailyGift.next=8 end,
   function(p)p.dailyGift.next=1.5 end,function(p)p.dailyGift.lastDay=-2 end,function(p)p.dailyGift.lastDay=1.5 end,
   function(p)p.dailyGift.extra=true end,function(p)p.dailyGift.next="1" end,
   function(p)p.starterPack=nil end,function(p)p.starterPack.offeredAt=-1 end,function(p)p.starterPack.offeredAt=1.5 end,
   function(p)p.starterPack.bought=1 end,function(p)p.starterPack.extra=true end,
   function(p)p.firstBuys=nil end,function(p)p.firstBuys.paper_pack_1500=false end,
   function(p)p.firstBuys.paper_pack_999=true end,function(p)p.firstBuys.starter_pack=true end,
   function(p)p.buysToday=nil end,function(p)p.buysToday.day=-2 end,function(p)p.buysToday.day=1.5 end,
   function(p)p.buysToday.count=-1 end,function(p)p.buysToday.count=1.5 end,
   function(p)p.buysToday.count="1" end,function(p)p.buysToday.extra=true end}
  for _,change in ipairs(changes) do
   local p=assert(Schema.copy(f.profile.Data));change(p);assert(not Schema.validate(p,f.catalog))
  end
  local copy=assert(Schema.copy(f.profile.Data));copy.dailyGift.next=7;copy.firstBuys.paper_pack_40000=true
  assert(f.profile.Data.dailyGift.next==1 and not f.profile.Data.firstBuys.paper_pack_40000)
  assert(Schema.validate(copy,f.catalog))
 end)
 test("daily gift claims pay once per UTC day and a repeated operation returns its original result",function()
  local f=fixture();local first,op=f:claim()
  assert(first.status=="ok" and first.value.type=="DailyGiftClaimed" and first.value.paper==100,first.code)
  local after=Schema.canonical(f.profile.Data)
  local retry=f.service:apply("user",op)
  assert(retry.status=="ok" and retry.value.paper==100 and Schema.canonical(f.profile.Data)==after)
  local again=f:claim()
  assert(again.status=="error" and again.code=="daily_gift_claimed" and Schema.canonical(f.profile.Data)==after)
  assert(f.profile.Data.dailyGift.next==2 and f.profile.Data.dailyGift.lastDay==20000)
  assert(f.profile.Data.paperMilli==100000 and f.profile.Data.earnedPaperMilli==100000 and f.profile.Data.purchasedPaperMilli==0)
  assert(f.player.attributes.DailyGiftNext==2 and not f.player.attributes.DailyGiftReady)
  assert(f.player.attributes.DailyGiftSecondsLeft==DAY-100 and f.player.attributes.BuysToday==0)
 end)
 test("the next UTC day is claimable at midnight and missed days never reset the row",function()
  local f=fixture();assert(f:claim().status=="ok")
  f.now=20001*DAY;f.runtime:update(f.entry)
  assert(f.player.attributes.DailyGiftReady and f.player.attributes.DailyGiftSecondsLeft==0 and f.player.attributes.DailyGiftNext==2)
  assert(f:claim().value.paper==150 and f.profile.Data.dailyGift.next==3)
  f.now+=20*DAY
  assert(f:claim().value.resource=="xp" and f.profile.Data.dailyGift.next==4)
  assert(f.profile.Data.boosts.xpSeconds==900)
 end)
 test("all seven daily rewards wrap to day one without creating purchase history",function()
  local f=fixture()
  for n=1,7 do
   local claimed=f:claim();assert(claimed.status=="ok",claimed.code)
   assert(f.profile.Data.dailyGift.next==n%7+1);f.now+=DAY
  end
  assert(f.profile.Data.paperMilli==1800000 and f.profile.Data.earnedPaperMilli==1800000)
  assert(f.profile.Data.boosts.xpSeconds==900 and f.profile.Data.boosts.paperSeconds==900)
  assert(next(f.profile.Data.receiptIds)==nil and f.player.attributes.BuysToday==0)
  f:rejoin();assert(f:claim().value.paper==100 and f.profile.Data.dailyGift.next==2)
 end)
 test("daily Paper is earned Paper at a fixed amount despite active or permanent boosts",function()
  for _,permanent in ipairs({false,true}) do
   local f=fixture({setup=function(p)p.boosts.paperSeconds=900;p.boosts.permanentPaper=permanent end})
   assert(f:claim().status=="ok")
   assert(f.profile.Data.paperMilli==100000 and f.profile.Data.earnedPaperMilli==100000 and f.profile.Data.purchasedPaperMilli==0)
   assert(f.profile.Data.boosts.paperSeconds==900)
  end
 end)
 test("daily timed gifts extend the shared clock and permanent coverage gives 250 earned Paper instead",function()
  for _,resource in ipairs({"xp","paper"}) do
   for _,permanent in ipairs({false,true}) do
    local field=resource=="xp" and "xpSeconds" or "paperSeconds"
    local flag=resource=="xp" and "permanentXP" or "permanentPaper"
    local f=fixture({setup=function(p)p.dailyGift.next=resource=="xp" and 3 or 6;p.boosts[field]=25;p.boosts[flag]=permanent end})
    local claimed=f:claim();assert(claimed.status=="ok",claimed.code)
    if permanent then
     assert(claimed.value.paper==250 and claimed.value.seconds==nil)
     assert(f.profile.Data.paperMilli==250000 and f.profile.Data.earnedPaperMilli==250000 and f.profile.Data.boosts[field]==25)
    else
     assert(claimed.value.resource==resource and claimed.value.seconds==900 and f.profile.Data.boosts[field]==925)
     assert(f.service:liveBoostView("user").value.boosts[field]==925)
     f.mono+=10;assert(f.service:liveBoostView("user").value.boosts[field]==915)
    end
    assert(f.profile.Data.purchasedPaperMilli==0 and f.player.attributes.BuysToday==0)
   end
  end
 end)
 test("invalid or earlier gift days cannot advance the row or the operation watermark",function()
  local f=fixture();assert(f:claim().status=="ok");local before=Schema.canonical(f.profile.Data)
  for _,day in ipairs({-1,1.5,"20001",19999}) do
   assert(f:claim(day).status=="error" and Schema.canonical(f.profile.Data)==before)
  end
 end)
 test("starter pack opens on first profile load and never restarts on another session",function()
  local f=fixture();local started=f.now;local ends=started+259200
  assert(f.profile.Data.starterPack.offeredAt==started and f.player.attributes.StarterPackEnds==ends)
  f.now+=DAY;f:rejoin()
  assert(f.profile.Data.starterPack.offeredAt==started and f.player.attributes.StarterPackEnds==ends)
  f.now=ends-1;f.runtime:update(f.entry);assert(f.player.attributes.StarterPackEnds==ends)
  f.now=ends;f.runtime:update(f.entry);assert(f.player.attributes.StarterPackEnds==0)
  f.now+=DAY;f:rejoin();assert(f.player.attributes.StarterPackEnds==0 and f.profile.Data.starterPack.offeredAt==started)
 end)
 test("starter pack is unavailable after any saved receipt permanent pass or starter purchase",function()
  for _,setup in ipairs({function(p)p.receiptIds.old=true end,function(p)p.boosts.permanentXP=true end,
   function(p)p.boosts.permanentPaper=true end,function(p)p.starterPack.bought=true end}) do
   local f=fixture({setup=setup});assert(f.player.attributes.StarterPackEnds==0)
  end
  local f=fixture();assert(f:receipt("xp_boost_15m").status=="ok" and f.player.attributes.StarterPackEnds==0)
 end)
 test("starter receipts atomically grant wings purchased Paper and XP time exactly once across sessions",function()
  local f=fixture();local first,op=f:receipt("starter_pack")
  assert(first.status=="ok" and first.value.type=="StarterPackGranted",first.code)
  assert(f.profile.Data.ownership.wings_1 and f.profile.Data.paperMilli==1500000 and f.profile.Data.purchasedPaperMilli==1500000)
  assert(f.profile.Data.earnedPaperMilli==0 and f.profile.Data.xpMilli==0 and f.profile.Data.boosts.xpSeconds==3600)
  assert(f.profile.Data.starterPack.bought and f.player.attributes.StarterPackEnds==0 and f.player.attributes.BuysToday==1)
  assert(next(f.profile.Data.firstBuys)==nil,"bundle Paper is not a first-buy pack")
  local after=Schema.canonical(f.profile.Data)
  assert(f.service:apply("user",op).status=="ok" and Schema.canonical(f.profile.Data)==after)
  f:rejoin();local replay=f:receipt("starter_pack")
  assert(replay.status=="ok" and replay.value.type=="ReceiptAlreadyGranted")
  assert(f.profile.Data.paperMilli==1500000 and f.profile.Data.boosts.xpSeconds==3600 and f.player.attributes.BuysToday==1)
 end)
 test("late starter receipts grant even after expiry a previous buy or a racing starter purchase",function()
  for _,reason in ipairs({"expired","previous","bought","permanent"}) do
   local f=fixture({setup=function(p)
    p.ownership.wings_1=true
    if reason=="previous" then p.receiptIds.old=true end
    if reason=="bought" then p.starterPack.bought=true end
    if reason=="permanent" then p.boosts.permanentXP=true;p.boosts.xpSeconds=25 end
   end})
   if reason=="expired" then f.now+=259200 end
   assert(Commerce.starterPackEnds(f.profile.Data,f.now)==0)
   assert(f:receipt("starter_pack").status=="ok")
   assert(f.profile.Data.paperMilli==1500000 and f.profile.Data.purchasedPaperMilli==1500000 and f.profile.Data.boosts.xpSeconds==3600+(reason=="permanent" and 25 or 0))
   f.mono+=10;local boosts=f.service:liveBoostView("user").value.boosts
   assert(boosts.xpSeconds==(reason=="permanent" and 3625 or 3590))
  end
 end)
 test("first-buy Paper doubling is per pack at apply time and duplicate receipts never spend it again",function()
  local f=fixture()
  for _,amount in ipairs({1500,5000,7500,15000,40000}) do
   local key="paper_pack_"..amount;local before=f.profile.Data.paperMilli
   assert(f:receipt(key,"first/"..key).status=="ok")
   assert(f.profile.Data.firstBuys[key] and f.profile.Data.paperMilli==before+amount*2000)
   assert(f:receipt(key,"first/"..key).value.type=="ReceiptAlreadyGranted")
   assert(f.profile.Data.paperMilli==before+amount*2000)
   assert(f:receipt(key,"second/"..key).status=="ok" and f.profile.Data.paperMilli==before+amount*3000)
  end
  assert(f.profile.Data.earnedPaperMilli==0 and f.profile.Data.purchasedPaperMilli==f.profile.Data.paperMilli)
  assert(f.player.attributes.BuysToday==10)
  f:rejoin();local before=f.profile.Data.paperMilli
  assert(f:receipt("paper_pack_1500","third").status=="ok" and f.profile.Data.paperMilli==before+1500000)
 end)
 test("receipt pack keys cannot name unknown packs or mismatch their immutable amount",function()
  for _,grant in ipairs({{kind="purchasedPaper",wholePaper=1500,packKey="paper_pack_5000"},
   {kind="purchasedPaper",wholePaper=1500,packKey="paper_pack_999"},{kind="starterPack",wholePaper=1}}) do
   local f=fixture();local before=Schema.canonical(f.profile.Data)
   local refused=f:apply({kind="receipt",receiptId="bad",grant=grant})
   assert(refused.code=="invalid_receipt_grant" and Schema.canonical(f.profile.Data)==before)
  end
 end)
 test("two queued pack grants decide the first-buy bonus when each operation applies",function()
  local f=fixture();local grant=Commerce.operation(assert(Commerce.catalog(require(Root.Generated.Commerce))).byKey.paper_pack_1500)
  local first=assert(f.service:prepare("user",{kind="receipt",receiptId="queued/1",grant=grant}))
  local second=assert(f.service:prepare("user",{kind="receipt",receiptId="queued/2",grant=grant}))
  assert(not f.profile.Data.firstBuys.paper_pack_1500)
  assert(f.service:apply("user",first).status=="ok" and f.profile.Data.paperMilli==3000000)
  assert(f.service:apply("user",second).status=="ok" and f.profile.Data.paperMilli==4500000)
  assert(f.profile.Data.firstBuys.paper_pack_1500 and f.profile.Data.buysToday.count==2)
 end)
 test("failed grants roll back the entire bundle first-buy flag receipt count and boost preview",function()
  for _,kind in ipairs({"starterPack","purchasedPaper","dailyGift"}) do
   local f=fixture({setup=function(p)p.paperMilli=Economy.MAX_SAFE_INTEGER end})
   local input=kind=="dailyGift" and {kind=kind,day=20000} or {kind="receipt",receiptId="overflow",grant=kind=="starterPack" and {kind=kind} or {kind=kind,wholePaper=1500,packKey="paper_pack_1500"}}
   local before=Schema.canonical(f.profile.Data);local clock=f.service.sessions.user.clock
   assert(f:apply(input).status=="error" and Schema.canonical(f.profile.Data)==before)
   assert(f.service.sessions.user.clock==clock and clock.state.xpSeconds==0 and clock.revision==0)
  end
  local f=fixture({setup=function(p)p.dailyGift.next=3;p.boosts.xpSeconds=Economy.MAX_SAFE_INTEGER end})
  local before=Schema.canonical(f.profile.Data)
  assert(f:claim().code=="overflow" and Schema.canonical(f.profile.Data)==before)
 end)
 test("buys today counts each receipt once resets at UTC midnight and does not block checkout",function()
  local f=fixture()
  for n=1,4 do assert(f:receipt("xp_boost_15m","buy/"..n).status=="ok" and f.player.attributes.BuysToday==n) end
  f.now=20001*DAY;f.runtime:update(f.entry);assert(f.player.attributes.BuysToday==0)
  assert(f:receipt("xp_boost_15m","buy/1").value.type=="ReceiptAlreadyGranted" and f.player.attributes.BuysToday==0)
  assert(f:receipt("xp_boost_15m","new_day").status=="ok")
  assert(f.profile.Data.buysToday.day==20001 and f.profile.Data.buysToday.count==1 and f.player.attributes.BuysToday==1)
 end)
 test("Player attributes follow claims buys passes first-buy keys and starter expiry",function()
  local f=fixture()
  assert(f.player.attributes.DailyGiftNext==1 and f.player.attributes.DailyGiftReady and f.player.attributes.DailyGiftSecondsLeft==0)
  assert(f.player.attributes.FirstBuysUsed=="" and f.player.attributes.BuysToday==0)
  assert(f:receipt("paper_pack_5000").status=="ok" and f:receipt("paper_pack_1500").status=="ok")
  assert(f.player.attributes.FirstBuysUsed=="paper_pack_1500,paper_pack_5000" and f.player.attributes.StarterPackEnds==0)
  local pass=fixture();assert(pass:apply({kind="passGrant",resource="xp"}).status=="ok" and pass.player.attributes.StarterPackEnds==0)
 end)
 test("practice grants use first-buy doubling count once and permanently close the starter offer",function()
  local f=fixture({mock=true});assert(f.service.mock,"run this suite in Studio")
  local first,op=f:apply({kind="purchasedPaper",wholePaper=1500,packKey="paper_pack_1500"})
  assert(first.status=="ok" and f.profile.Data.paperMilli==3000000 and f.player.attributes.BuysToday==1)
  assert(f.service:apply("user",op).status=="ok" and f.profile.Data.paperMilli==3000000 and f.profile.Data.buysToday.count==1)
  assert(f:apply({kind="purchasedPaper",wholePaper=1500,packKey="paper_pack_1500"}).status=="ok")
  assert(f.profile.Data.paperMilli==4500000 and f.player.attributes.BuysToday==2 and f.player.attributes.StarterPackEnds==0)
  f.now+=DAY;f:rejoin();assert(f.player.attributes.StarterPackEnds==0 and f.player.attributes.BuysToday==0)
  assert(f:apply({kind="boostIntent",resource="paper",action="duration",seconds=900}).status=="ok" and f.player.attributes.BuysToday==1)
 end)
 test("practice starter bundle is one buy and direct practice grants cannot reach real profiles",function()
  local f=fixture({mock=true});assert(f:apply({kind="starterPack"}).status=="ok")
  assert(f.profile.Data.paperMilli==1500000 and f.profile.Data.ownership.wings_1 and f.profile.Data.boosts.xpSeconds==3600)
  local before=Schema.canonical(f.profile.Data)
  assert(f:apply({kind="starterPack"}).code=="starter_pack_ended" and Schema.canonical(f.profile.Data)==before)
  f=fixture();before=Schema.canonical(f.profile.Data)
  for _,input in ipairs({{kind="starterPack"},{kind="purchasedPaper",wholePaper=1500,packKey="paper_pack_1500"},
   {kind="boostIntent",resource="xp",action="duration",seconds=900}}) do
   assert(f:apply(input).code=="studio_only" and Schema.canonical(f.profile.Data)==before)
  end
 end)
 test("Hangar daily claims use server time ignore client reward data and report actual grants",function()
  local f=fixture();local inputs={}
  local profiles={view=function()return f.service:view("user").value end}
  function profiles:enqueue(_,input,_,callback)
   table.insert(inputs,assert(Schema.copy(input)));local saved=f:apply(input)
   callback(saved.status=="ok",saved.value or saved.code);return true
  end
  local hangar=Hangar.new({catalog=f.catalog},profiles,nil,{unix=function()return f.now end})
  hangar:handle(f.player,"claimDailyGift",{day=999999,paper=999999})
  assert(inputs[1].kind=="dailyGift" and inputs[1].day==20000 and inputs[1].paper==nil)
  assert(f.player.attributes.MenuMessage=="Gift claimed: +100 Paper.")
  hangar:handle(f.player,"claimDailyGift");assert(f.player.attributes.MenuMessage=="Already claimed today. Come back tomorrow.")
  f.now+=DAY;hangar:handle(f.player,"claimDailyGift")
  f.now+=DAY;hangar:handle(f.player,"claimDailyGift")
  assert(f.player.attributes.MenuMessage=="Gift claimed: 15 minutes of 2x XP.")
 end)
 test("Hangar blocks unavailable starter prompts without asking commerce",function()
  local f=fixture();local calls=0
  local profiles={view=function()return f.service:view("user").value end}
  local commerce={prompt=function()calls+=1;return true end}
  local hangar=Hangar.new({catalog=f.catalog},profiles,commerce,{unix=function()return f.now end})
  hangar:handle(f.player,"buyProduct","starter_pack");assert(calls==1)
  f.now+=259200;hangar:handle(f.player,"buyProduct","starter_pack")
  assert(calls==1 and f.player.attributes.MenuMessage=="The starter pack has ended.")
 end)
 return result
end
return Spec
