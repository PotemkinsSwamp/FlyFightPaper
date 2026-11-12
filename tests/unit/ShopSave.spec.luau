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
  old.schemaVersion=8;old.dailyGift=nil;old.starterPack=nil;old.firstBuys=nil;old.buysToday=nil;old.paperJarMilli=nil
  old.paperMilli=123456;old.receiptIds.old_receipt=true;old.extensions={keep="old data"}
  local before=Schema.canonical(old);local migrated=assert(Schema.migrate(old,f.catalog))
  local expected=assert(Schema.copy(old));expected.schemaVersion=Schema.VERSION
  expected.dailyGift={next=1,lastDay=-1};expected.starterPack={offeredAt=0,bought=false}
  expected.firstBuys={};expected.buysToday={day=-1,count=0};expected.paperJarMilli=0
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
 test("schema 9 migration adds an empty jar and preserves the old save without mutating it",function()
  local f=fixture();assert(Schema.VERSION==10 and f.profile.Data.paperJarMilli==0 and f.player.attributes.PaperJar==0)
  local old=assert(Schema.copy(f.profile.Data));old.schemaVersion=9;old.paperJarMilli=nil
  old.paperMilli=123456;old.firstBuys.paper_pack_1500=true;old.extensions={keep="old data"}
  local before=Schema.canonical(old);local expected=assert(Schema.copy(old))
  expected.schemaVersion=10;expected.paperJarMilli=0
  local migrated=assert(Schema.migrate(Schema.freeze(old),f.catalog))
  assert(Schema.canonical(migrated)==Schema.canonical(expected) and Schema.canonical(old)==before)
  assert(Schema.canonical(assert(Schema.migrate(migrated,f.catalog)))==Schema.canonical(migrated))
  assert(not Schema.validate(old,f.catalog))
 end)
 test("jar saves reject missing fractional negative over-cap and nonnumeric values",function()
  local f=fixture();local cap=EconomyConfig.paper_jar.cap_paper*Economy.MILLI
  for _,value in ipairs({-1,cap+1,1.5,"1000",false}) do
   local data=assert(Schema.copy(f.profile.Data));data.paperJarMilli=value
   assert(not Schema.validate(data,f.catalog) and not Schema.migrate(data,f.catalog))
   data.schemaVersion=9;assert(not Schema.migrate(data,f.catalog),"migration must not hide a corrupt jar")
  end
  local data=assert(Schema.copy(f.profile.Data));data.paperJarMilli=nil;assert(not Schema.validate(data,f.catalog))
  data.paperJarMilli=cap;assert(Schema.validate(data,f.catalog))
 end)
 test("contributions fill an extra quarter of actual credited Paper at 1x and 2x retaining milliunits",function()
  for _,multiplier in ipairs({1,2}) do
   local f=fixture({setup=function(p)p.boosts.paperSeconds=multiplier==2 and 900 or 0 end})
   local capture=f.service:producerCapture("user").value;assert(capture.paper==multiplier)
   local paid=f:apply({kind="contribution",points=101,multipliers=capture})
   local credited=36663*multiplier
   assert(paid.status=="ok" and paid.value.paperMilli==credited,paid.code)
   assert(f.profile.Data.paperMilli==credited and f.profile.Data.earnedPaperMilli==credited and f.profile.Data.purchasedPaperMilli==0)
   assert(f.profile.Data.paperJarMilli==math.floor(credited/4) and f.player.attributes.PaperJar==math.floor(credited/4000))
   f:rejoin();assert(f.profile.Data.paperJarMilli==math.floor(credited/4))
  end
 end)
 test("final bonuses fill from their own boosted credit and XP-only bonuses leave the jar alone",function()
  for _,multiplier in ipairs({1,2}) do
   local f=fixture()
   local paid=f:apply({kind="finalBonus",finalPaper=131,finalXP=3,multipliers={paper=multiplier,xp=1}})
   assert(paid.status=="ok" and f.profile.Data.paperMilli==131000*multiplier)
   assert(f.profile.Data.paperJarMilli==32750*multiplier)
   assert(f:apply({kind="finalBonus",finalPaper=0,finalXP=60,multipliers={paper=multiplier,xp=2}}).status=="ok")
   assert(f.profile.Data.paperJarMilli==32750*multiplier)
  end
 end)
 test("contributions and final bonuses cap the jar without capping normal Paper",function()
  local cap=EconomyConfig.paper_jar.cap_paper*Economy.MILLI;assert(cap==10000000 and EconomyConfig.paper_jar.share==0.25)
  for _,input in ipairs({{kind="contribution",points=100},{kind="finalBonus",finalPaper=90,finalXP=120}}) do
   local f=fixture({setup=function(p)p.paperJarMilli=cap-1 end});input.multipliers={paper=2,xp=1}
   local first=f:apply(input);assert(first.status=="ok" and f.profile.Data.paperJarMilli==cap)
   local second=f:apply(input);assert(second.status=="ok" and f.profile.Data.paperJarMilli==cap and f.player.attributes.PaperJar==10000)
   assert(f.profile.Data.paperMilli==first.value.paperMilli+second.value.paperMilli)
  end
 end)
 test("replayed match operation ids fill the jar only once",function()
  local f=fixture()
  for _,input in ipairs({{kind="contribution",points=100},{kind="finalBonus",finalPaper=90,finalXP=120}}) do
   input.multipliers={paper=2,xp=1};local paid,op=f:apply(input);assert(paid.status=="ok")
   local after=Schema.canonical(f.profile.Data);local replay=f.service:apply("user",op)
   assert(replay.status=="ok" and replay.value.paperMilli==paid.value.paperMilli and Schema.canonical(f.profile.Data)==after)
  end
  assert(f.profile.Data.paperJarMilli==63150)
 end)
 test("daily gifts packs starter Paper and direct purchased Paper never fill the jar",function()
  for _,kind in ipairs({"dailyGift","pack","starter","purchased"}) do
   local f=fixture({mock=true,setup=function(p)p.paperJarMilli=1234 end})
   local paid
   if kind=="dailyGift" then paid=f:claim()
   elseif kind=="pack" then paid=f:receipt("paper_pack_1500")
   elseif kind=="starter" then paid=f:receipt("starter_pack")
   else paid=f:apply({kind="purchasedPaper",wholePaper=100}) end
   assert(paid.status=="ok" and f.profile.Data.paperMilli>0 and f.profile.Data.paperJarMilli==1234)
  end
 end)
 test("breaking a jar buys only its whole Paper retains fractions and never takes a first-buy double",function()
  for _,fraction in ipairs({0,725}) do
   local f=fixture({setup=function(p)p.paperJarMilli=250000+fraction;p.paperMilli=5000;p.earnedPaperMilli=5000;p.boosts.permanentPaper=true end})
   local broken,op=f:receipt("paper_jar")
   assert(broken.status=="ok" and broken.value.type=="PaperJarBroken" and broken.value.paper==250,broken.code)
   assert(f.profile.Data.paperMilli==255000 and f.profile.Data.purchasedPaperMilli==250000 and f.profile.Data.earnedPaperMilli==5000)
   assert(f.profile.Data.paperJarMilli==fraction and f.player.attributes.PaperJar==0 and f.player.attributes.BuysToday==1)
   assert(next(f.profile.Data.firstBuys)==nil and f.profile.Data.receiptIds[Profile.receiptKey("receipt/paper_jar")])
   local after=Schema.canonical(f.profile.Data)
   assert(f.service:apply("user",op).value.paper==250 and Schema.canonical(f.profile.Data)==after)
   f:rejoin();assert(f.profile.Data.paperJarMilli==fraction)
   assert(f:apply({kind="contribution",points=100,multipliers={paper=1,xp=1}}).status=="ok")
   local filled=f.profile.Data.paperJarMilli
   assert(filled==fraction+9075 and f.player.attributes.PaperJar==math.floor(filled/1000))
   assert(f:receipt("paper_jar").value.type=="ReceiptAlreadyGranted" and f.profile.Data.paperJarMilli==filled)
   assert(f.player.attributes.BuysToday==1)
  end
 end)
 test("practice jars under 3,000 Paper refuse but real receipts grant what is there and record a buy",function()
  for _,fraction in ipairs({0,999}) do
   local f=fixture({mock=true,setup=function(p)p.paperJarMilli=fraction;p.paperMilli=Economy.MAX_SAFE_INTEGER end})
   local before=Schema.canonical(f.profile.Data)
   assert(f:apply({kind="paperJar"}).code=="jar_low" and Schema.canonical(f.profile.Data)==before)
   local paid=f:receipt("paper_jar");assert(paid.status=="ok" and paid.value.type=="PaperJarBroken" and paid.value.paper==0)
   assert(f.profile.Data.paperMilli==Economy.MAX_SAFE_INTEGER and f.profile.Data.purchasedPaperMilli==0 and f.profile.Data.paperJarMilli==fraction)
   assert(f.profile.Data.receiptIds[Profile.receiptKey("receipt/paper_jar")] and f.player.attributes.BuysToday==1)
   assert(f:receipt("paper_jar").value.type=="ReceiptAlreadyGranted" and f.player.attributes.BuysToday==1)
  end
 end)
 test("two queued receipts each honour the jar available when they apply including zero",function()
  local f=fixture({setup=function(p)p.paperJarMilli=123456 end})
  local grant=Commerce.operation(assert(Commerce.catalog(require(Root.Generated.Commerce))).byKey.paper_jar)
  local first=assert(f.service:prepare("user",{kind="receipt",receiptId="jar/1",grant=grant}))
  local second=assert(f.service:prepare("user",{kind="receipt",receiptId="jar/2",grant=grant}))
  assert(f.service:apply("user",first).value.paper==123 and f.service:apply("user",second).value.paper==0)
  assert(f.profile.Data.paperMilli==123000 and f.profile.Data.paperJarMilli==456 and f.profile.Data.buysToday.count==2)
  assert(f.profile.Data.receiptIds[Profile.receiptKey("jar/1")] and f.profile.Data.receiptIds[Profile.receiptKey("jar/2")])
 end)
 test("practice jar breaks count once and direct jar grants cannot reach real profiles",function()
  local f=fixture({mock=true,setup=function(p)p.paperJarMilli=3000000 end})
  local paid,op=f:apply({kind="paperJar"});assert(paid.status=="ok" and paid.value.paper==3000)
  assert(f.profile.Data.paperMilli==3000000 and f.profile.Data.paperJarMilli==0 and f.player.attributes.BuysToday==1)
  assert(f.profile.Data.receiptIds[Profile.receiptKey("mock:"..op.id)] and f.player.attributes.StarterPackEnds==0)
  local after=Schema.canonical(f.profile.Data);assert(f.service:apply("user",op).value.paper==3000 and Schema.canonical(f.profile.Data)==after)
  f=fixture({setup=function(p)p.paperJarMilli=3000000 end});after=Schema.canonical(f.profile.Data)
  assert(f:apply({kind="paperJar"}).code=="studio_only" and Schema.canonical(f.profile.Data)==after)
 end)
 test("failed match credits and jar grants roll back the jar money receipt and buy count together",function()
  for _,input in ipairs({{kind="contribution",points=100,multipliers={paper=1,xp=1}},
   {kind="finalBonus",finalPaper=90,finalXP=120,multipliers={paper=1,xp=1}},
   {kind="receipt",receiptId="jar/overflow",grant={kind="paperJar"}}}) do
   local f=fixture({setup=function(p)p.paperMilli=Economy.MAX_SAFE_INTEGER;p.paperJarMilli=1000 end})
   local before=Schema.canonical(f.profile.Data)
   assert(f:apply(input).code=="overflow" and Schema.canonical(f.profile.Data)==before)
  end
 end)
 test("jar receipts accept only the kind with no client amount pack key or boost",function()
  for _,grant in ipairs({{kind="paperJar",wholePaper=999},{kind="paperJar",packKey="paper_pack_1500"},
   {kind="paperJar",paperJarMilli=999999},{kind="paperJar",multipliers={paper=2,xp=1}}}) do
   local f=fixture({setup=function(p)p.paperJarMilli=1000 end});local before=Schema.canonical(f.profile.Data)
   assert(f:apply({kind="receipt",receiptId="bad/jar",grant=grant}).code=="invalid_receipt_grant")
   assert(Schema.canonical(f.profile.Data)==before)
  end
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
 test("Hangar refuses empty jars before prompting and reports a racing commerce refusal",function()
  local f=fixture();local calls=0
  local profiles={view=function()return f.service:view("user").value end}
  local commerce={prompt=function()calls+=1;return false,"jar_low" end}
  local hangar=Hangar.new({catalog=f.catalog},profiles,commerce)
  for _,amount in ipairs({0,999,2999999}) do
   f.profile.Data.paperJarMilli=amount;hangar:handle(f.player,"buyProduct","paper_jar")
   assert(calls==0 and f.player.attributes.MenuMessage=="Your Paper jar breaks at 3,000 Paper. Play a match to fill it.")
  end
  f.profile.Data.paperJarMilli=3000000;hangar:handle(f.player,"buyProduct","paper_jar")
  assert(calls==1 and f.player.attributes.MenuMessage=="Your Paper jar breaks at 3,000 Paper. Play a match to fill it.")
 end)
 test("Hangar practice jars refuse empty and racing buys and enqueue only the jar kind",function()
  local f=fixture({mock=true});local inputs={};local race=false
  local profiles={mock=true,view=function()return f.service:view("user").value end}
  function profiles:enqueue(_,input,_,callback)
   table.insert(inputs,assert(Schema.copy(input)))
   if race then f.profile.Data.paperJarMilli=2999999 end
   local saved=f:apply(input);callback(saved.status=="ok",saved.value or saved.code);return true
  end
  local hangar=Hangar.new({catalog=f.catalog},profiles)
  for _,amount in ipairs({0,999,2999999}) do
   f.profile.Data.paperJarMilli=amount;hangar:handle(f.player,"mockProduct","paper_jar")
   assert(#inputs==0 and f.player.attributes.MenuMessage=="Your Paper jar breaks at 3,000 Paper. Play a match to fill it.")
  end
  f.profile.Data.paperJarMilli=3000000;hangar:handle(f.player,"mockProduct","paper_jar")
  assert(#inputs==1 and Schema.canonical(inputs[1])==Schema.canonical({kind="paperJar"}))
  assert(f.profile.Data.paperMilli==3000000 and f.profile.Data.paperJarMilli==0 and f.player.attributes.BuysToday==1)
  assert(f.player.attributes.MenuMessage=="Development simulation complete. No real purchase.")
  race=true;f.profile.Data.paperJarMilli=3000000;hangar:handle(f.player,"mockProduct","paper_jar")
  assert(#inputs==2 and f.profile.Data.paperMilli==3000000 and f.profile.Data.paperJarMilli==2999999 and f.player.attributes.BuysToday==1)
  assert(f.player.attributes.MenuMessage=="Your Paper jar breaks at 3,000 Paper. Play a match to fill it.")
 end)
 return result
end
return Spec
