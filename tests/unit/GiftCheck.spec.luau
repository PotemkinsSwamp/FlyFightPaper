local Root=game.ReplicatedStorage.FlyFightPaper
local Hangar=require(game.ServerScriptService.FlyFightPaper.HangarService)
local Schema=require(Root.Shared.ProfileSchema)
local Catalog=require(Root.Shared.Catalog)
local Fake=require(script.Parent.Parent.fixtures.FakeProfiles)
local Suite=require(script.Parent.Parent.fixtures.Suite)
local Http=game:GetService("HttpService")
local Spec={}
local function fixture()
 local f={now=0,friendCalls=0,inputs={},prompts={},catalog=Catalog.new(require(Root.Generated.Catalog))}
 f.player={UserId=123,DisplayName="Alex",attributes={}}
 function f.player:SetAttribute(key,value)self.attributes[key]=value end
 function f.player:GetAttribute(key)return self.attributes[key]end
 function f.player:IsFriendsWith(id)
  f.friendCalls+=1;assert(id==456 or id==123)
  if f.friendError then error("fake friendship failure") end
  return not f.notFriend
 end
 f.giver=Fake.new(Schema.defaults(f.catalog));f.friend=Fake.new(Schema.defaults(f.catalog))
 f.store=Fake.store({Player_123=f.giver,Player_456=f.friend})
 f.profiles={mock=true,store=f.store}
 function f.profiles:view()return not f.unloaded and f.giver.Data or nil end
 function f.profiles:giftsReady()return not f.notReady end
 function f.profiles:giftSeen(player,n)assert(player==f.player);f.seen=n end
 function f.profiles:enqueue(player,input,source,callback)
  assert(player==f.player and source==nil)
  if f.queueFull then return false end
  table.insert(f.inputs,assert(Schema.copy(input)));if callback then callback(not f.applyFailed) end;return true
 end
 f.users={}
 function f.users:GetUserInfosByUserIdsAsync(ids)
  assert(#ids==1 and (ids[1]==456 or ids[1]==123))
  if f.nameError then error("fake name failure") end
  return {{DisplayName="Sam"}}
 end
 f.commerce={}
 function f.commerce:rememberGift(player,friend,name,key)
  assert(player==f.player);self.gift={friend=friend,friendName=name,key=key,at=f.now}
 end
 function f.commerce:prompt(player,key)assert(player==f.player);table.insert(f.prompts,key);return not f.promptFailed end
 f.hangar=Hangar.new({catalog=f.catalog},f.profiles,f.commerce,{now=function()return f.now end,users=f.users})
 function f:check(id)
  self.hangar:handle(self.player,"giftCheck",id or 456)
  return Http:JSONDecode(self.player.attributes.GiftCheck)
 end
 function f:buy(key,id)self.hangar:handle(self.player,"buyGift",{friend=id or 456,key=key or "paper_pack_5000"})end
 return f
end
local function selfSwitch(enabled,callback)
 local previous=workspace:GetAttribute("DevGiftSelf");workspace:SetAttribute("DevGiftSelf",enabled)
 local ok,why=pcall(callback);workspace:SetAttribute("DevGiftSelf",previous);assert(ok,why)
end
function Spec.run()
 local result,test=Suite.new()
 test("self check refuses without reading friendship or storage",function()
  selfSwitch(false,function()
   local f=fixture();local check=f:check(123)
   assert(check.status=="self" and check.id==123 and check.waiting==0 and not check.ownsXP and not check.ownsPaper)
   assert(f.friendCalls==0 and f.store.reads==0);f:buy(nil,123)
   assert(f.player.attributes.MenuMessage=="You can only send gifts to friends." and f.store.sends==0)
  end)
 end)
 test("nonfriends refuse without a save read and friendship failures report error",function()
  local f=fixture();f.notFriend=true;assert(f:check().status=="not_friend" and f.store.reads==0)
  f:buy();assert(f.player.attributes.MenuMessage=="You can only send gifts to friends." and f.store.sends==0)
  f=fixture();f.friendError=true;assert(f:check().status=="error" and f.store.reads==0)
 end)
 test("a friend with no save reports not played after exactly one read",function()
  local f=fixture();f.store.records.Player_456=nil
  assert(f:check().status=="not_played" and f.store.reads==1)
  f:buy();assert(f.player.attributes.MenuMessage=="Sam hasn't played yet. Invite them first!" and f.store.sends==0)
 end)
 test("ten waiting gift messages are full while rewards do not count",function()
  local f=fixture()
  for i=1,10 do table.insert(f.friend.global_updates,{i,{kind="gift"}}) end
  for i=11,30 do table.insert(f.friend.global_updates,{i,{kind="reward"}}) end
  local check=f:check();assert(check.status=="full" and check.waiting==10 and f.store.reads==1)
  f:buy();assert(f.player.attributes.MenuMessage=="Sam has 10 gifts waiting! Try again after they play.")
  table.remove(f.friend.global_updates,1);f.now=2;check=f:check()
  assert(check.status=="ok" and check.waiting==9 and f.store.reads==2)
 end)
 test("ok returns both saved forever ownership flags with one read",function()
  for _,owned in ipairs({"permanentXP","permanentPaper"}) do
   local f=fixture();f.friend.Data.boosts[owned]=true;assert(f.friend:Save())
   local check=f:check()
   assert(check.status=="ok" and check.id==456 and check.waiting==0 and f.store.reads==1)
   assert(check.ownsXP==(owned=="permanentXP") and check.ownsPaper==(owned=="permanentPaper"))
  end
 end)
 test("a giver can check once per two seconds, across different friends",function()
  local f=fixture();assert(f:check().status=="ok")
  f.now=1.99;assert(f:check(123).status=="busy" and f.store.reads==1)
  f.now=2;assert(f:check().status=="ok" and f.store.reads==2)
 end)
 test("saving unavailable or a concurrent check is busy and failed reads are error",function()
  for _,failure in ipairs({"unloaded","notReady"}) do
   local f=fixture();f[failure]=true
   assert(f:check().status=="busy" and f.store.reads==0);f:buy()
   assert(f.player.attributes.MenuMessage=="Gifts are busy. Try again shortly.")
  end
  local f=fixture();f.store.readError=true;assert(f:check().status=="error" and f.store.reads==1)
  f:buy();assert(f.player.attributes.MenuMessage=="Gifts are busy. Try again shortly.")
  f=fixture();local read=f.store.GetAsync
  function f.store:GetAsync(key)
   assert(f:check(123).status=="busy");return read(self,key)
  end
  assert(f:check().status=="ok" and f.store.reads==1)
 end)
 test("checks reject malformed ids before friendship or storage",function()
  local f=fixture();f.hangar:handle(f.player,"giftCheck",nil)
  for _,id in ipairs({0,-1,1.5,"456",false,{},math.huge,0/0}) do f.hangar:handle(f.player,"giftCheck",id) end
  assert(f.player.attributes.GiftCheck==nil and f.store.reads==0 and f.friendCalls==0)
 end)
 test("buy refreshes missing or expired checks and uses a result for exactly 120 seconds",function()
  local f=fixture();f.profiles.mock=false;f:buy()
  assert(f.store.reads==1 and #f.prompts==1 and f.prompts[1]=="gift_paper_pack_5000")
  local gift=f.commerce.gift;assert(gift.friend==456 and gift.friendName=="Sam" and gift.key=="paper_pack_5000" and gift.at==0)
  f.now=120;f:buy();assert(f.store.reads==1 and #f.prompts==2)
  f.now=120.01;f.store.records.Player_456=nil;f:buy()
  assert(f.store.reads==2 and #f.prompts==2 and f.player.attributes.MenuMessage=="Sam hasn't played yet. Invite them first!")
 end)
 test("forever owners cannot be sent a boost for that resource but can receive Paper",function()
  for _,resource in ipairs({"xp","paper"}) do
   local f=fixture();f.friend.Data.boosts[resource=="xp" and "permanentXP" or "permanentPaper"]=true;assert(f.friend:Save())
   f:check();f:buy(resource.."_boost_15m")
   assert(f.player.attributes.MenuMessage=="Sam already has 2x "..(resource=="xp" and "XP" or "Paper").." forever.")
   assert(f.store.sends==0 and #f.inputs==0);f:buy()
   assert(f.store.sends==1 and #f.inputs==1)
  end
 end)
 test("practice gifts send before recording a mock receipt and never prompt Roblox",function()
  local f=fixture();f:check()
  function f.profiles:enqueue(_,input,_,callback)
   assert(f.store.sends==#f.inputs+1 and #f.store.messages==f.store.sends);table.insert(f.inputs,input);callback(true);return true
  end
  f:buy();local sent=f.store.messages[1];local receipt=f.inputs[1]
  assert(sent.key=="Player_456" and sent.message.kind=="gift" and sent.message.from==123 and sent.message.fromName=="Alex")
  assert(sent.message.key=="paper_pack_5000" and sent.message.giftId:match("^mock:"))
  assert(receipt.kind=="receipt" and receipt.receiptId==sent.message.giftId and receipt.grant.kind=="giftSent")
  assert(#f.prompts==0 and f.player.attributes.MenuMessage=="Sent! (practice gift, no real purchase)")
  f:buy();assert(f.store.messages[2].message.giftId~=sent.message.giftId)
 end)
 test("failed practice sends record nothing and lookup failures use Your friend",function()
  for _,failure in ipairs({"failSend","sendError"}) do
   local f=fixture();f.store[failure]=true;f:buy()
   assert(f.store.sends==1 and #f.inputs==0 and #f.prompts==0 and f.player.attributes.MenuMessage=="Gifts are busy. Try again shortly.")
  end
  local f=fixture();f.nameError=true;f.store.records.Player_456=nil;f:buy()
  assert(f.player.attributes.MenuMessage=="Your friend hasn't played yet. Invite them first!")
 end)
 test("nongiftable and gift-prefixed direct buys cannot reach either checkout path",function()
  local f=fixture()
  for _,key in ipairs({"starter_pack","paper_jar","match_double_49","part_wings_1","permanent_2x_xp","gift_paper_pack_5000"}) do
   f:buy(key);assert(f.player.attributes.MenuMessage=="That can't be gifted.")
  end
  f.hangar:handle(f.player,"mockProduct","gift_paper_pack_5000")
  f.hangar:handle(f.player,"buyProduct","gift_paper_pack_5000")
  assert(f.store.reads==0 and f.store.sends==0 and #f.inputs==0 and #f.prompts==0)
 end)
 test("DevGiftSelf skips friendship only with Studio mock profiles and permits a self message",function()
  selfSwitch(true,function()
   local f=fixture();f.friendError=true;assert(f:check(123).status=="ok")
   assert(f.friendCalls==0 and f.store.reads==1);f:buy(nil,123)
   assert(f.store.messages[1].key=="Player_123" and #f.inputs==1)
   f=fixture();f.profiles.mock=false
   assert(f:check(123).status=="self" and f.store.reads==0 and f.friendCalls==0)
  end)
 end)
 test("turning the self switch off also blocks an already checked self buy",function()
  selfSwitch(true,function()
   local f=fixture();assert(f:check(123).status=="ok");workspace:SetAttribute("DevGiftSelf",false);f:buy(nil,123)
   assert(f.store.sends==0 and #f.inputs==0 and f.player.attributes.MenuMessage=="You can only send gifts to friends.")
  end)
 end)
 test("giftSeen forwards the count to the session inbox",function()
  local f=fixture();f.hangar:handle(f.player,"giftSeen",2);assert(f.seen==2 and #f.inputs==0)
 end)
 return result
end
return Spec
