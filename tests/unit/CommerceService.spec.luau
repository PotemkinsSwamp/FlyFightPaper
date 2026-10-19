local Root=game.ReplicatedStorage.FlyFightPaper
local Server=game.ServerScriptService.FlyFightPaper
local Commerce=require(Server.CommerceService)
local Profile=require(Server.ProfileService)
local Hangar=require(Server.HangarService)
local Rules=require(Root.Shared.CommerceRules)
local Schema=require(Root.Shared.ProfileSchema)
local Catalog=require(Root.Shared.Catalog)
local Fake=require(script.Parent.Parent.fixtures.FakeProfiles)
local Suite=require(script.Parent.Parent.fixtures.Suite)
local Spec={}
local Decisions=Enum.ProductPurchaseDecision
local function liveConfig()
 local config=assert(Schema.copy(require(Root.Generated.Commerce)))
 config.mode="live";config.live_sales_authorized=true
 for i,offer in ipairs(config.products) do
  offer.roblox_product_id=10000+i;offer.approved_robux_price=10+i;offer.enabled=true
 end
 return config
end
local function signal()
 local s={listeners={},connections=0}
 function s:Connect(fn)
  self.connections+=1;table.insert(self.listeners,fn)
  return {Disconnect=function()end}
 end
 function s:Fire(a,b,c) for _,fn in ipairs(self.listeners) do fn(a,b,c) end end
 return s
end
local function fixture(options)
 options=options or {}
 local f={time=0,waits=0,inputs={},sources={},outcomes={},saveTimes={},unloaded=options.unloaded==true}
 f.catalog=Catalog.new(require(Root.Generated.Catalog),require(Root.Generated.Gameplay))
 local data=Schema.defaults(f.catalog)
 f.profile=Fake.new(data)
 f.players={PlayerAdded=signal(),list={}}
 f.player={UserId=123,Parent=f.players,attributes={}}
 function f.player:SetAttribute(key,value)self.attributes[key]=value end
 function f.players:GetPlayers()return self.list end
 function f.players:GetPlayerByUserId(id)
  if id==f.player.UserId and f.player.Parent==self then return f.player end
 end
 f.marketplace={calls={},owned=options.owned or {},PromptGamePassPurchaseFinished=signal()}
 function f.marketplace:UserOwnsGamePassAsync(userId,id)
  table.insert(self.calls,{kind="owns",userId=userId,id=id})
  if self.ownershipError then error("fake ownership failure") end
  return self.owned[id]==true
 end
 function f.marketplace:PromptProductPurchase(player,id)
  table.insert(self.calls,{kind="product",player=player,id=id})
  if self.promptError then error("fake prompt failure") end
 end
 function f.marketplace:PromptGamePassPurchase(player,id)
  table.insert(self.calls,{kind="pass",player=player,id=id})
  if self.promptError then error("fake prompt failure") end
 end
 f.service=Profile.new({catalog=f.catalog,monotonic=function()return f.time end})
 assert(f.service:attach("user",f.profile,{connected=true,mapLoaded=false}).status=="ok")
 local entry={profile=f.profile,account="user"}
 f.profiles={entries={[f.player]=entry}}
 function f.profiles:view(player)
  if f.unloaded or player~=f.player or self.entries[player]~=entry then return nil end
  local view=f.service:view("user")
  return view.status=="ok" and view.value or nil
 end
 function f.profiles:enqueue(player,input,source,callback)
  assert(player==f.player)
  if f.queueFull then return false end
  table.insert(f.inputs,assert(Schema.copy(input)));f.sources[#f.inputs]=source or false
  local function apply()
   local op=assert(f.service:prepare("user",input));local result=f.service:apply("user",op)
   table.insert(f.outcomes,result)
   if callback and not f.dropCallback then callback(result.status=="ok",result.value or result.code) end
  end
  if f.deferGrant then f.pending=apply else apply() end
  return true
 end
 local save=f.profile.Save
 function f.profile:Save()
  table.insert(f.saveTimes,f.time)
  return save(self)
 end
 f.config=options.config or liveConfig()
 f.deps={marketplace=f.marketplace,players=f.players,config=f.config,timeoutSeconds=options.timeoutSeconds or 3,
  now=function()return f.time end,wait=function(seconds)
   f.time+=seconds;f.waits+=1
   if f.onWait then f.onWait() end
  end}
 if options.existing then f.players.list={f.player} end
 f.commerce=Commerce.new(f.profiles,f.deps)
 f.players.list={f.player}
 function f:offer(key)return assert(self.commerce.catalog.byKey[key])end
 function f:receipt(key,id)
  return {ProductId=self:offer(key).productID,PlayerId=self.player.UserId,PurchaseId=id or "receipt/"..key}
 end
 return f
end
function Spec.run()
 local result,test=Suite.new()
 test("real mock config binds nothing and every public Roblox method refuses without marketplace calls",function()
  local f=fixture({config=require(Root.Generated.Commerce)})
  assert(f.commerce.live==false and f.marketplace.ProcessReceipt==nil)
  assert(f.marketplace.PromptGamePassPurchaseFinished.connections==0 and f.players.PlayerAdded.connections==0)
  local ok,why=f.commerce:prompt(f.player,"paper_pack_1000");assert(not ok and why=="off")
  ok,why=f.commerce:checkPasses(f.player);assert(not ok and why=="off")
  assert(f.commerce:processReceipt({})==Decisions.NotProcessedYet)
  assert(#f.marketplace.calls==0 and #f.inputs==0 and f.waits==0)
 end)
 test("invalid or partially authorized configs stay off without reading the marketplace dependency",function()
  local configs={liveConfig(),liveConfig(),liveConfig()}
  configs[1].mode="mock";configs[2].live_sales_authorized=false;configs[3].products[1].amount=1
  for _,config in ipairs(configs) do
   local marketplace=setmetatable({},{__index=function()error("off adapter touched marketplace")end,
    __newindex=function()error("off adapter bound marketplace")end})
   local service=Commerce.new({}, {config=config,marketplace=marketplace,players={}})
   assert(service.live==false and not service:prompt({},"paper_pack_1000") and not service:checkPasses({}))
   assert(service:processReceipt({})==Decisions.NotProcessedYet)
  end
 end)
 test("live adapter binds its receipt callback and both purchase and player signals",function()
  local f=fixture()
  assert(f.commerce.live and type(f.marketplace.ProcessReceipt)=="function")
  assert(f.marketplace.PromptGamePassPurchaseFinished.connections==1 and f.players.PlayerAdded.connections==1)
  assert(f.marketplace.ProcessReceipt(f:receipt("paper_pack_1000"))==Decisions.PurchaseGranted)
 end)
 test("Paper receipts grant once under different operation ids and save their receipt and balance together",function()
  local f=fixture();local info=f:receipt("paper_pack_1000");local key=Profile.receiptKey(info.PurchaseId)
  assert(f.commerce:processReceipt(info)==Decisions.PurchaseGranted)
  assert(f.profile.Data.paperMilli==1000000 and f.profile.Data.purchasedPaperMilli==1000000 and f.profile.Data.earnedPaperMilli==0)
  assert(f.profile.LastSavedData.receiptIds[key] and f.profile.LastSavedData.paperMilli==1000000)
  assert(f.commerce:processReceipt(info)==Decisions.PurchaseGranted)
  assert(f.profile.Data.paperMilli==1000000 and f.profile.Data.purchasedPaperMilli==1000000 and #f.inputs==2)
  assert(f.outcomes[1].value.operationID~=f.outcomes[2].value.operationID and f.outcomes[2].value.type=="ReceiptAlreadyGranted")
  assert(f.sources[1]==false and f.sources[2]==false,"source dedupe would suppress a replay's callback")
 end)
 test("failed save remains pending and redelivery saves without granting Paper twice",function()
  local f=fixture({timeoutSeconds=4.5});f.profile.failSave=true
  local info=f:receipt("paper_pack_3500");local key=Profile.receiptKey(info.PurchaseId)
  assert(f.commerce:processReceipt(info)==Decisions.NotProcessedYet)
  assert(f.profile.Data.paperMilli==3500000 and f.profile.Data.receiptIds[key] and not f.profile.LastSavedData.receiptIds[key])
  assert(#f.saveTimes>=2 and #f.saveTimes<=3)
  for i=2,#f.saveTimes do assert(f.saveTimes[i]-f.saveTimes[i-1]>=2) end
  f.profile.failSave=false
  assert(f.commerce:processReceipt(info)==Decisions.PurchaseGranted)
  assert(f.profile.Data.paperMilli==3500000 and f.profile.LastSavedData.paperMilli==3500000 and f.profile.LastSavedData.receiptIds[key])
 end)
 test("a queued asynchronous save is not mistaken for a durable receipt",function()
  local f=fixture();local pending
  function f.profile:Save()self.writes+=1;pending=assert(Schema.copy(self.Data))end
  f.onWait=function()
   assert(not f.profile.LastSavedData.receiptIds[Profile.receiptKey("async/save")])
   if f.time>=0.3 then f.profile.LastSavedData=pending;f.onWait=nil end
  end
  assert(f.commerce:processReceipt(f:receipt("paper_pack_1000","async/save"))==Decisions.PurchaseGranted)
  assert(f.time>=0.3 and f.profile.writes==1 and f.profile.LastSavedData.paperMilli==1000000)
 end)
 test("unknown products, pass ids, absent players and profiles that never load grant nothing",function()
  for _,case in ipairs({"unknown","pass","absent","unloaded"}) do
   local f=fixture();local info=f:receipt("paper_pack_1000")
   if case=="unknown" then info.ProductId=999999
   elseif case=="pass" then info.ProductId=f:offer("permanent_2x_xp").productID
   elseif case=="absent" then info.PlayerId=999
   else f.unloaded=true end
   assert(f.commerce:processReceipt(info)==Decisions.NotProcessedYet,case)
   assert(f.profile.Data.paperMilli==0 and #f.inputs==0 and f.profile.writes==0,case)
  end
 end)
 test("receipt waits for a delayed profile load and a delayed operation callback",function()
  local f=fixture();f.unloaded=true;f.deferGrant=true
  f.onWait=function()
   if f.time>=0.2 then f.unloaded=false end
   if f.time>=0.4 and f.pending then local apply=f.pending;f.pending=nil;apply() end
  end
  assert(f.commerce:processReceipt(f:receipt("paper_pack_1000"))==Decisions.PurchaseGranted)
  assert(f.time>=0.4 and f.profile.LastSavedData.paperMilli==1000000)
 end)
 test("queue refusal, callback failure and callback timeout all leave receipts pending",function()
  for _,case in ipairs({"queue","failure","callback"}) do
   local f=fixture()
   if case=="queue" then f.queueFull=true
   elseif case=="failure" then f.profile.Data.paperMilli=9007199254740991
   else f.dropCallback=true end
   assert(f.commerce:processReceipt(f:receipt("paper_pack_1000"))==Decisions.NotProcessedYet,case)
   assert(f.profile.writes==0 and next(f.profile.LastSavedData.receiptIds)==nil,case)
   if case=="failure" then assert(f.outcomes[1].status=="error") end
   if case=="callback" then
    f.dropCallback=false
    assert(f.commerce:processReceipt(f:receipt("paper_pack_1000"))==Decisions.PurchaseGranted)
    assert(f.profile.LastSavedData.paperMilli==1000000)
   end
  end
 end)
 test("disabled mapped boosts still deliver their paid seconds once",function()
  local config=liveConfig();config.products[1].enabled=false
  local f=fixture({config=config});local info=f:receipt("xp_boost_15m")
  assert(f.commerce:processReceipt(info)==Decisions.PurchaseGranted and f.profile.Data.boosts.xpSeconds==900)
  assert(f.profile.LastSavedData.boosts.xpSeconds==900)
  assert(f.commerce:processReceipt(info)==Decisions.PurchaseGranted and f.profile.Data.boosts.xpSeconds==900)
 end)
 test("all thirteen developer products use their catalog benefits",function()
  local f=fixture();local paper,xpSeconds,paperSeconds,n=0,0,0,0
  for _,offer in ipairs(f.commerce.catalog.offers) do
   if offer.kind=="developer_product" then
    n+=1
    assert(f.commerce:processReceipt(f:receipt(offer.key))==Decisions.PurchaseGranted,offer.key)
    if offer.benefit=="paper_balance" then paper+=offer.amount*1000
    elseif offer.benefit=="xp_seconds" then xpSeconds+=offer.amount
    else paperSeconds+=offer.amount end
   end
  end
  assert(n==13 and f.profile.LastSavedData.paperMilli==paper and f.profile.LastSavedData.purchasedPaperMilli==paper)
  assert(f.profile.LastSavedData.boosts.xpSeconds==xpSeconds and f.profile.LastSavedData.boosts.paperSeconds==paperSeconds)
  for i=2,#f.saveTimes do assert(f.saveTimes[i]-f.saveTimes[i-1]>=2,"receipts must share the save cooldown") end
 end)
 test("overlapping deliveries of the same unsaved receipt both acknowledge one durable grant",function()
  local f=fixture();local info=f:receipt("paper_pack_1000","overlapping/receipt");local second
  f.profile.failSave=true
  f.onWait=function()
   f.onWait=nil;f.profile.failSave=false
   second=f.commerce:processReceipt(info)
  end
  assert(f.commerce:processReceipt(info)==Decisions.PurchaseGranted and second==Decisions.PurchaseGranted)
  assert(#f.inputs==2 and f.outcomes[2].value.type=="ReceiptAlreadyGranted")
  assert(f.profile.LastSavedData.paperMilli==1000000 and f.profile.LastSavedData.receiptIds[Profile.receiptKey(info.PurchaseId)])
  assert(#f.saveTimes==2 and f.saveTimes[2]-f.saveTimes[1]>=2)
 end)
 test("in-flight timed receipts still grant dormant seconds after a permanent upgrade",function()
  local f=fixture()
  assert(f.profiles:enqueue(f.player,{kind="passGrant",resource="paper"}))
  assert(f.commerce:processReceipt(f:receipt("paper_boost_30m"))==Decisions.PurchaseGranted)
  assert(f.profile.Data.boosts.permanentPaper and f.profile.Data.boosts.paperSeconds==1800)
  assert(f.service:setProducerMapLoaded("user",true).status=="ok");f.time+=10
  assert(f.profiles:view(f.player).boosts.paperSeconds==1800)
 end)
 test("session loss while waiting for a save leaves the receipt pending",function()
  local f=fixture();f.profile.failSave=true
  f.onWait=function()f.profile.active=false end
  local info=f:receipt("paper_pack_1000")
  assert(f.commerce:processReceipt(info)==Decisions.NotProcessedYet)
  assert(f.profile.Data.paperMilli==1000000 and not f.profile.LastSavedData.receiptIds[Profile.receiptKey(info.PurchaseId)])
 end)
 test("player leaving during profile loading stops the wait without granting",function()
  local f=fixture();f.unloaded=true;f.onWait=function()f.player.Parent=nil end
  assert(f.commerce:processReceipt(f:receipt("paper_pack_1000"))==Decisions.NotProcessedYet)
  assert(f.waits==1 and #f.inputs==0)
 end)
 test("unexpected receipt and save errors never escape ProcessReceipt",function()
  local f=fixture()
  assert(f.commerce:processReceipt(nil)==Decisions.NotProcessedYet)
  assert(f.commerce:processReceipt({})==Decisions.NotProcessedYet)
  local bad=f:receipt("paper_pack_1000");bad.PurchaseId=false
  assert(f.commerce:processReceipt(bad)==Decisions.NotProcessedYet and #f.inputs==0)
  function f.profile:Save()error("fake save error")end
  assert(f.commerce:processReceipt(f:receipt("paper_pack_1000"))==Decisions.NotProcessedYet)
 end)
 test("owned passes grant permanent boosts once and a second check queues nothing",function()
  local f=fixture()
  f.marketplace.owned[f:offer("permanent_2x_xp").productID]=true
  f.marketplace.owned[f:offer("permanent_2x_paper").productID]=true
  assert(f.commerce:checkPasses(f.player) and #f.inputs==2)
  assert(f.profile.Data.boosts.permanentXP and f.profile.Data.boosts.permanentPaper)
  local version=f.profile.Data.version
  assert(f.commerce:checkPasses(f.player) and #f.inputs==2 and f.profile.Data.version==version)
  for _,input in ipairs(f.inputs) do assert(input.kind=="passGrant") end
  for _,call in ipairs(f.marketplace.calls) do assert(call.kind=="owns" and call.userId==f.player.UserId) end
 end)
 test("ownership errors and unowned passes never grant permanent boosts",function()
  for _,errors in ipairs({true,false}) do
   local f=fixture();f.marketplace.ownershipError=errors
   local ok=f.commerce:checkPasses(f.player)
   assert(ok==(not errors) and #f.inputs==0 and #f.marketplace.calls==2)
   assert(not f.profile.Data.boosts.permanentXP and not f.profile.Data.boosts.permanentPaper)
  end
 end)
 test("disabled mapped passes still restore verified ownership",function()
  local config=liveConfig()
  for _,offer in ipairs(config.products) do if offer.kind=="pass" then offer.enabled=false end end
  local f=fixture({config=config});f.marketplace.owned[f:offer("permanent_2x_xp").productID]=true
  assert(f.commerce:checkPasses(f.player) and f.profile.Data.boosts.permanentXP and #f.inputs==1)
 end)
 test("existing players and new players get authoritative ownership checks after loading",function()
  local config=liveConfig();local catalog=assert(Rules.catalog(config));local id=catalog.byKey.permanent_2x_xp.productID
  local existing=fixture({config=config,existing=true,owned={[id]=true}})
  assert(existing.profile.Data.boosts.permanentXP and #existing.inputs==1)
  local joining=fixture({unloaded=true});joining.marketplace.owned[joining:offer("permanent_2x_paper").productID]=true
  joining.onWait=function()joining.unloaded=false end
  joining.players.PlayerAdded:Fire(joining.player)
  assert(joining.waits==1 and joining.profile.Data.boosts.permanentPaper and #joining.inputs==1)
 end)
 test("join checks stop at a profile timeout or when the player leaves",function()
  for _,leaves in ipairs({true,false}) do
   local f=fixture({unloaded=true})
   if leaves then f.onWait=function()f.player.Parent=nil end end
   f.players.PlayerAdded:Fire(f.player)
   assert(#f.marketplace.calls==0 and #f.inputs==0 and f.waits>0)
   assert(leaves or f.time>=f.commerce.timeoutSeconds)
  end
 end)
 test("purchase-finished never grants from the event claim and rechecks Roblox ownership",function()
  local f=fixture();local id=f:offer("permanent_2x_xp").productID
  f.marketplace.PromptGamePassPurchaseFinished:Fire(f.player,id,false)
  assert(#f.marketplace.calls==0)
  f.marketplace.PromptGamePassPurchaseFinished:Fire(f.player,id,true)
  assert(#f.inputs==0 and not f.profile.Data.boosts.permanentXP)
  f.marketplace.owned[id]=true
  f.marketplace.PromptGamePassPurchaseFinished:Fire(f.player,id,true)
  assert(#f.inputs==1 and f.profile.Data.boosts.permanentXP)
 end)
 test("prompts refuse an owned pass and redundant temporary boost without marketplace calls",function()
  local f=fixture();assert(f.profiles:enqueue(f.player,{kind="passGrant",resource="xp"}))
  local ok,why=f.commerce:prompt(f.player,"permanent_2x_xp");assert(not ok and why=="owned")
  ok,why=f.commerce:prompt(f.player,"xp_boost_15m");assert(not ok and why=="permanent_owned")
  assert(#f.marketplace.calls==0)
 end)
 test("prompts call the matching Roblox checkout with the right ids and grant nothing",function()
  local f=fixture()
  for _,key in ipairs({"paper_pack_10000","xp_boost_60m","permanent_2x_paper"}) do
   local offer=f:offer(key);local ok,why=f.commerce:prompt(f.player,key)
   assert(ok and why=="prompted")
   local call=f.marketplace.calls[#f.marketplace.calls]
   assert(call.player==f.player and call.id==offer.productID and call.kind==(offer.kind=="pass" and "pass" or "product"))
  end
  assert(#f.inputs==0 and f.profile.Data.paperMilli==0 and not f.profile.Data.boosts.permanentPaper)
 end)
 test("unknown, disabled, unmapped and unavailable-profile prompts refuse without calling Roblox",function()
  local config=liveConfig();config.products[1].enabled=false
  local null=require(Root.Generated.JSONTypes).Null
  config.products[2].enabled=false;config.products[2].roblox_product_id=null;config.products[2].approved_robux_price=null
  local f=fixture({config=config})
  for _,key in ipairs({"unknown","xp_boost_15m","xp_boost_30m"}) do assert(not f.commerce:prompt(f.player,key)) end
  assert(not f.commerce:prompt(f.player,{}))
  f.unloaded=true;local ok,why=f.commerce:prompt(f.player,"paper_pack_1000")
  assert(not ok and why=="profile_unavailable" and #f.marketplace.calls==0 and #f.inputs==0)
 end)
 test("failed checkout calls return refusal and grant nothing",function()
  local f=fixture();f.marketplace.promptError=true
  for _,key in ipairs({"paper_pack_1000","permanent_2x_xp"}) do
   local ok,why=f.commerce:prompt(f.player,key);assert(not ok and why=="marketplace_error")
  end
  assert(#f.inputs==0)
 end)
 test("hangar forwards buyProduct keys and reports a closed shop when checkout refuses",function()
  local f=fixture();local hangar=Hangar.new({catalog=f.catalog},f.profiles,f.commerce)
  hangar:handle(f.player,"buyProduct","paper_pack_1000")
  assert(#f.marketplace.calls==1 and f.marketplace.calls[1].kind=="product" and #f.inputs==0)
  hangar:handle(f.player,"buyProduct",{})
  assert(#f.marketplace.calls==1)
  hangar:handle(f.player,"buyProduct","unknown")
  assert(f.player.attributes.MenuMessage=="Shop is closed for now.")
  local oldSignature=Hangar.new({catalog=f.catalog},f.profiles)
  oldSignature:handle(f.player,"buyProduct","paper_pack_1000")
  assert(#f.marketplace.calls==1)
 end)
 return result
end
return Spec
