local Root=game.ReplicatedStorage.FlyFightPaper
local Hangar=require(game.ServerScriptService.FlyFightPaper.HangarService)
local Catalog=require(Root.Shared.Catalog)
local Schema=require(Root.Shared.ProfileSchema)
local Profile=require(game.ServerScriptService.FlyFightPaper.ProfileService)
local Fake=require(script.Parent.Parent.fixtures.FakeProfiles)
local Suite=require(script.Parent.Parent.fixtures.Suite)
local Spec={}
function Spec.run()
 local result,test=Suite.new()
 local function fixture(mock)
  local f={calls=0,inputs={},now=20000*86400+100};local catalog=Catalog.new(require(Root.Generated.Catalog))
  f.player=Instance.new("Folder");f.player.Parent=game.ServerStorage
  f.profile=Schema.defaults(catalog);f.profile.starterPack.offeredAt=f.now
  local profiles={mock=mock,view=function()return f.profile end,enqueue=function(_,player,input,source,callback)
   assert(player==f.player and source==nil)
   if f.queueFull then return false end
   f.calls+=1;f.input=input;table.insert(f.inputs,assert(Schema.copy(input)))
   f.callback=callback;f.doubledAtQueue=player:GetAttribute("MatchDoubled");return true
  end}
  profiles.entries={[f.player]={account="mock"}}
  profiles.service={liveBoostView=function()return {status="ok",value={boosts=f.profile.boosts}} end}
  f.profiles=profiles;f.catalog=catalog
  f.hangar=Hangar.new({catalog=catalog},profiles,nil,{unix=function()return f.now end})
  return f
 end
 local product
 for _,p in ipairs(require(Root.Generated.Commerce).products) do if p.benefit=="paper_balance" then product=p;break end end
 test("mock shop refuses a real profile even inside Studio",function()
  local f=fixture(false);f.hangar:handle(f.player,"mockProduct",product.key)
  assert(f.calls==0);f.player:Destroy()
 end)
 test("Studio mock profiles can use simulated Paper products",function()
  local f=fixture(true);f.hangar:handle(f.player,"mockProduct",product.key)
  assert(f.calls==1 and f.input.kind=="purchasedPaper" and f.input.wholePaper==product.amount and f.input.packKey==product.key)
  f.player:Destroy()
 end)
 test("unknown or malformed mock products grant nothing",function()
  local f=fixture(true)
  f.hangar:handle(f.player,"mockProduct",{key=product.key})
  f.hangar:handle(f.player,"mockProduct","invented")
  assert(f.calls==0);f.player:Destroy()
 end)
 test("practice starter products use their bundle grant and refuse expired or previously used offers",function()
  local f=fixture(true);f.hangar:handle(f.player,"mockProduct","starter_pack")
  assert(f.calls==1 and f.input.kind=="starterPack" and f.input.resource==nil and f.input.seconds==nil)
  f.player:Destroy()
  for _,close in ipairs({function(x)x.now+=259200 end,function(x)x.profile.receiptIds.earlier=true end,
   function(x)x.profile.starterPack.bought=true end,function(x)x.profile.boosts.permanentXP=true end}) do
   local closed=fixture(true);close(closed);closed.hangar:handle(closed.player,"mockProduct","starter_pack")
   assert(closed.calls==0 and closed.player:GetAttribute("MenuMessage")=="The starter pack has ended.")
   closed.player:Destroy()
  end
  f=fixture(false);f.hangar:handle(f.player,"mockProduct","starter_pack");assert(f.calls==0);f.player:Destroy()
 end)
 test("mock part products are explicitly refused instead of becoming Paper boosts",function()
  local f=fixture(true);f.hangar:handle(f.player,"mockProduct","part_wings_1")
  assert(f.calls==0 and f.player:GetAttribute("MenuMessage")=="Part checkout is unavailable in the practice shop.")
  f.player:Destroy()
 end)
 test("practice match doubling blocks a second press and queues its saved lock before its key-only payment",function()
  local f=fixture(true);local match={matchId="m1",paper=500,xp=900}
  f.hangar:doubleMatch(f.player,match)
  assert(f.calls==1 and Schema.canonical(f.input)==Schema.canonical({kind="doubleLock",key="match_double_49",matchId="m1",paper=500,xp=900}))
  assert(f.doubledAtQueue=="m1" and f.player:GetAttribute("MatchDoubled")=="m1")
  f.hangar:doubleMatch(f.player,match)
  assert(f.calls==1 and f.player:GetAttribute("MenuMessage")=="You already doubled this match.")
  f.callback(true)
  assert(f.calls==2 and Schema.canonical(f.input)==Schema.canonical({kind="matchDouble",key="match_double_49"}))
  f.hangar:doubleMatch(f.player,match);assert(f.calls==2)
  f.callback(true)
  assert(f.player:GetAttribute("MenuMessage")=="Development simulation complete. No real purchase.")
  f.hangar:doubleMatch(f.player,match)
  f.hangar:doubleMatch(f.player,{matchId="m2",paper=74,xp=900})
  assert(f.calls==2 and f.player:GetAttribute("MatchDoubled")=="m1")
  f.player:Destroy()
 end)
 test("practice match doubling clears failures at either queue or callback so the same match can retry",function()
  for _,failure in ipairs({"lockQueue","lockApply","payQueue","payApply"}) do
   local f=fixture(true);f.queueFull=failure=="lockQueue"
   f.hangar:doubleMatch(f.player,{matchId="m1",paper=500,xp=900})
   if failure=="lockApply" then f.callback(false)
   elseif failure=="payQueue" then f.queueFull=true;f.callback(true)
   elseif failure=="payApply" then f.callback(true);f.callback(false) end
   assert(f.player:GetAttribute("MatchDoubled")==nil and f.player:GetAttribute("MenuMessage")=="Development simulation failed.")
   local calls=f.calls;f.queueFull=false
   f.hangar:doubleMatch(f.player,{matchId="m1",paper=500,xp=900})
   assert(f.calls==calls+1 and f.player:GetAttribute("MatchDoubled")=="m1")
   f.player:Destroy()
  end
 end)
 test("one practice press saves then pays exact locked amounts through the real profile operations",function()
  local f=fixture(true);f.profile.paperJarMilli=123456
  f.profile.boosts.permanentPaper=true;f.profile.boosts.permanentXP=true
  local saved=Fake.new(f.profile)
  local service=Profile.new({catalog=f.catalog,mock=true,monotonic=function()return 100 end,unix=function()return f.now end})
  assert(service:attach("mock",saved,{connected=true,mapLoaded=true}).status=="ok")
  function f.profiles:enqueue(player,input,source,callback)
   assert(player==f.player and source==nil and player:GetAttribute("MatchDoubled")=="m1")
   f.calls+=1;table.insert(f.inputs,assert(Schema.copy(input)))
   local applied=service:apply("mock",assert(service:prepare("mock",input)))
   assert(applied.status=="ok",applied.code)
   if input.kind=="doubleLock" then
    assert(saved.Data.paperMilli==0 and saved.Data.xpMilli==0 and saved.Data.buysToday.count==0 and next(saved.Data.receiptIds)==nil)
    assert(saved.Data.doubleLocks.match_double_49.paper==500 and saved.Data.doubleLocks.match_double_49.xp==900)
   end
   callback(true,applied.value);return true
  end
  local match={matchId="m1",paper=500,xp=900};f.hangar:doubleMatch(f.player,match)
  assert(f.calls==2 and f.inputs[1].kind=="doubleLock" and f.inputs[2].kind=="matchDouble" and f.inputs[2].key=="match_double_49")
  assert(saved.Data.paperMilli==500000 and saved.Data.purchasedPaperMilli==500000 and saved.Data.xpMilli==900000)
  assert(saved.Data.earnedPaperMilli==0 and saved.Data.paperJarMilli==123456 and saved.Data.buysToday.count==1)
  assert(saved.Data.doubleLocks.match_double_49==nil and next(saved.Data.receiptIds)~=nil)
  assert(f.player:GetAttribute("MenuMessage")=="Development simulation complete. No real purchase.")
  local before=Schema.canonical(saved.Data);f.hangar:doubleMatch(f.player,match)
  assert(f.calls==2 and Schema.canonical(saved.Data)==before)
  f.player:Destroy()
 end)
 test("match double practice offers cannot be bought through mockProduct or on real profiles",function()
  local f=fixture(true)
  for _,key in ipairs({"match_double_10","match_double_49","match_double_299","match_double_invented"}) do
   f.hangar:handle(f.player,"mockProduct",key)
  end
  f.hangar:doubleMatch(f.player,{matchId="m1",paper=74,xp=900})
  assert(f.calls==0 and f.player:GetAttribute("MatchDoubled")==nil);f.player:Destroy()
  f=fixture(false);f.hangar:doubleMatch(f.player,{matchId="m1",paper=500,xp=900})
  assert(f.calls==0 and f.player:GetAttribute("MatchDoubled")==nil);f.player:Destroy()
 end)
 test("practice timed and permanent products keep their correct resources and refuse permanent coverage",function()
  local f=fixture(true)
  f.hangar:handle(f.player,"mockProduct","xp_boost_15m")
  assert(f.calls==1 and f.input.kind=="boostIntent" and f.input.resource=="xp" and f.input.action=="duration" and f.input.seconds==900)
  f.hangar:handle(f.player,"mockProduct","permanent_2x_paper")
  assert(f.calls==2 and f.input.resource=="paper" and f.input.action=="permanent" and f.input.seconds==nil)
  f.profile.boosts.permanentXP=true;f.profile.boosts.permanentPaper=true
  for _,key in ipairs({"xp_boost_15m","paper_boost_15m","permanent_2x_xp","permanent_2x_paper"}) do f.hangar:handle(f.player,"mockProduct",key) end
  assert(f.calls==2);f.player:Destroy()
 end)
 return result
end
return Spec
