local Root=game.ReplicatedStorage.FlyFightPaper
local Service=require(game.ServerScriptService.FlyFightPaper.ProfileService)
local Schema=require(Root.Shared.ProfileSchema)
local Rules=require(Root.Shared.CommerceRules)
local Catalog=require(Root.Shared.Catalog)
local Fake=require(script.Parent.Parent.fixtures.FakeProfiles)
local Suite=require(script.Parent.Parent.fixtures.Suite)
local Spec={}
local function fixture()
 local f={now=100,unix=20000*86400+100,catalog=Catalog.new(require(Root.Generated.Catalog))}
 f.profile=Fake.new(Schema.defaults(f.catalog));f.profile.Data.paperJarMilli=123456
 f.service=Service.new({catalog=f.catalog,monotonic=function()return f.now end,unix=function()return f.unix end})
 assert(f.service:attach("user",f.profile,{connected=true,mapLoaded=true}).status=="ok")
 function f:apply(input)
  local op=assert(self.service:prepare("user",input));local result=self.service:apply("user",op)
  return result,op
 end
 function f:receive(key,id)return self:apply({kind="giftReceived",giftId=id or "gift/one",from=123,fromName="Alex",key=key})end
 return f
end
function Spec.run()
 local result,test=Suite.new()
 test("all fifteen gift products map only to Paper packs and timed boosts",function()
  local catalog=assert(Rules.catalog(require(Root.Generated.Commerce)));local count=0
  for _,offer in ipairs(catalog.offers) do
   local base=Rules.giftBase(offer.key)
   if base then
    count+=1;assert(Rules.giftable(base) and offer.key=="gift_"..base and offer.kind=="developer_product")
    assert(offer.benefit=="gift" and not offer.enabled and not offer.productID and not offer.approvedPrice)
    assert(Rules.operation(offer).kind=="giftSent" and Rules.resource(offer)==nil)
   else
    local allowed=offer.benefit=="paper_balance" or offer.benefit=="xp_seconds" or offer.benefit=="paper_seconds"
    assert(Rules.giftable(offer.key)==allowed)
    if allowed then assert(catalog.byKey["gift_"..offer.key] and Rules.giftBase("gift_"..offer.key)==offer.key) end
   end
  end
  assert(count==15 and not Rules.giftBase(nil) and not Rules.giftable(nil))
  for _,key in ipairs({false,{},1,"gift_paper_pack_1500","paper_pack_1","starter_pack","paper_jar","match_double_49","part_wings_1","permanent_2x_xp"}) do
   assert(not Rules.giftable(key) and not Rules.giftGrant(key))
  end
 end)
 test("giftSent records one buy and its receipt without using a first buy or giving Paper",function()
  local f=fixture();local before=assert(Schema.copy(f.profile.Data))
  local receipt={kind="receipt",receiptId="paid/gift",grant={kind="giftSent"}}
  local paid,op=f:apply(receipt);assert(paid.status=="ok" and paid.value.type=="GiftSent")
  local p=f.profile.Data
  assert(p.receiptIds[Service.receiptKey(receipt.receiptId)] and p.buysToday.day==20000 and p.buysToday.count==1)
  for _,key in ipairs({"paperMilli","earnedPaperMilli","purchasedPaperMilli","paperJarMilli","firstBuys","giftIds","boosts"}) do
   assert(Schema.canonical(p[key])==Schema.canonical(before[key]),key)
  end
  local after=Schema.canonical(p);assert(f.service:apply("user",op).status=="ok" and Schema.canonical(f.profile.Data)==after)
  assert(f:apply(receipt).value.type=="ReceiptAlreadyGranted" and f.profile.Data.buysToday.count==1)
 end)
 test("every received pack gives its normal amount and leaves first buys jar buys and receipts alone",function()
  for _,amount in ipairs({1500,5000,7500,15000,40000}) do
   local f=fixture();local before=assert(Schema.copy(f.profile.Data));local paid=f:receive("paper_pack_"..amount)
   assert(paid.status=="ok" and paid.value.type=="GiftReceived" and paid.value.from=="Alex")
   local p=f.profile.Data;assert(p.paperMilli==amount*1000 and p.purchasedPaperMilli==amount*1000)
   assert(p.earnedPaperMilli==0 and p.giftIds[1]=="gift/one" and #p.giftIds==1)
   for _,key in ipairs({"firstBuys","paperJarMilli","buysToday","receiptIds","starterPack","xpMilli"}) do
    assert(Schema.canonical(p[key])==Schema.canonical(before[key]),key)
   end
   assert(Rules.starterPackEnds(p,f.unix)>0)
  end
 end)
 test("received timed boosts add verified time, including dormant time for forever owners",function()
  for _,resource in ipairs({"xp","paper"}) do for _,permanent in ipairs({false,true}) do
   local f=fixture();local owned=resource=="xp" and "permanentXP" or "permanentPaper"
   if permanent then assert(f:apply({kind="passGrant",resource=resource}).status=="ok") end
   for _,minutes in ipairs({15,30,60,180,300}) do
    local before=assert(Schema.copy(f.profile.Data));local paid=f:receive(resource.."_boost_"..minutes.."m","gift:"..minutes)
    assert(paid.status=="ok",paid.code)
    local p=f.profile.Data;assert(p.boosts[resource.."Seconds"]==before.boosts[resource.."Seconds"]+minutes*60)
    assert(p.boosts[owned]==permanent and next(p.receiptIds)==nil and p.buysToday.count==0 and next(p.firstBuys)==nil)
   end
   local seconds=f.profile.Data.boosts[resource.."Seconds"];f.now+=10
   assert(f.service:view("user").value.boosts[resource.."Seconds"]==seconds-(permanent and 0 or 10))
  end end
 end)
 test("duplicate gift ids do not grant again across operations and a saved rejoin",function()
  for _,key in ipairs({"paper_pack_5000","xp_boost_30m"}) do
   local f=fixture();assert(f:receive(key).status=="ok")
   local paper,seconds=f.profile.Data.paperMilli,f.profile.Data.boosts.xpSeconds
   assert(f:receive(key).value.type=="GiftAlreadyReceived")
   assert(f.profile:Save());f.service:detach("user")
   f.profile=Fake.new(f.profile.LastSavedData)
   assert(f.service:attach("user",f.profile,{connected=true,mapLoaded=true}).status=="ok")
   assert(f:receive(key).value.type=="GiftAlreadyReceived")
   assert(f.profile.Data.paperMilli==paper and f.profile.Data.boosts.xpSeconds==seconds and #f.profile.Data.giftIds==1)
  end
 end)
 test("gift ids retain the newest 200 in arrival order",function()
  local f=fixture()
  for i=1,202 do assert(f:receive("paper_pack_1500","gift:"..i).status=="ok") end
  local p=f.profile.Data
  assert(#p.giftIds==200 and p.giftIds[1]=="gift:3" and p.giftIds[200]=="gift:202" and p.paperMilli==202*1500000)
  assert(f:receive("paper_pack_1500","gift:100").value.type=="GiftAlreadyReceived" and #f.profile.Data.giftIds==200)
 end)
 test("schema 11 migrates gift ids without mutating an old save or its purchase history",function()
  local f=fixture();local old=assert(Schema.copy(f.profile.Data));old.schemaVersion=11;old.giftIds=nil
  old.receiptIds.old=true;old.firstBuys.paper_pack_5000=true;old.boosts.xpSeconds=17;old.extensions={keep="old"}
  local before=Schema.canonical(old);local expected=assert(Schema.copy(old));expected.schemaVersion=Schema.VERSION;expected.giftIds={}
  assert(Schema.VERSION==13 and Schema.canonical(assert(Schema.migrate(Schema.freeze(old),f.catalog)))==Schema.canonical(expected))
  assert(Schema.canonical(old)==before and not Schema.validate(old,f.catalog))
 end)
 test("gift ids reject missing malformed duplicate sparse and over-cap history",function()
  local f=fixture()
  for _,change in ipairs({function(p)p.giftIds=nil end,function(p)p.giftIds=false end,
   function(p)p.giftIds={""} end,function(p)p.giftIds={7} end,function(p)p.giftIds={"same","same"} end,
   function(p)p.giftIds={[2]="sparse"} end,function(p)p.giftIds={id="map"} end,
   function(p)p.giftIds={string.rep("x",Schema.MAX_OPERATION_ID+1)} end,
   function(p)for i=1,201 do p.giftIds[i]="gift:"..i end end}) do
   local p=assert(Schema.copy(f.profile.Data));change(p);assert(not Schema.validate(p,f.catalog))
  end
 end)
 test("invalid gift messages cannot change a profile",function()
  for _,change in ipairs({function(g)g.giftId=""end,function(g)g.from=0 end,function(g)g.fromName=""end,
   function(g)g.key="starter_pack"end,function(g)g.key="gift_paper_pack_1500"end,function(g)g.key="permanent_2x_xp"end}) do
   local f=fixture();local input={kind="giftReceived",giftId="gift:valid",from=123,fromName="Alex",key="paper_pack_1500"};change(input)
   local before=Schema.canonical(f.profile.Data);assert(f:apply(input).code=="invalid_gift" and Schema.canonical(f.profile.Data)==before)
  end
 end)
 return result
end
return Spec
