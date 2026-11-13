local Root=game.ReplicatedStorage.FlyFightPaper
local Hangar=require(game.ServerScriptService.FlyFightPaper.HangarService)
local Catalog=require(Root.Shared.Catalog)
local Schema=require(Root.Shared.ProfileSchema)
local Suite=require(script.Parent.Parent.fixtures.Suite)
local Spec={}
function Spec.run()
 local result,test=Suite.new()
 local function fixture(mock)
  local f={calls=0,now=20000*86400+100};local catalog=Catalog.new(require(Root.Generated.Catalog))
  f.player=Instance.new("Folder");f.player.Parent=game.ServerStorage
  f.profile=Schema.defaults(catalog);f.profile.starterPack.offeredAt=f.now
  local profiles={mock=mock,view=function()return f.profile end,enqueue=function(_,player,input,source,callback)
   assert(player==f.player and source==nil)
   if f.queueFull then return false end
   f.calls+=1;f.input=input;f.callback=callback;f.doubledAtQueue=player:GetAttribute("MatchDoubled");return true
  end}
  profiles.entries={[f.player]={account="mock"}}
  profiles.service={liveBoostView=function()return {status="ok",value={boosts=f.profile.boosts}} end}
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
 test("practice match doubling locks before saving and enqueues exactly the match once",function()
  local f=fixture(true);local match={matchId="m1",paper=500,xp=900}
  f.hangar:doubleMatch(f.player,match)
  assert(f.calls==1 and Schema.canonical(f.input)==Schema.canonical({kind="matchDouble",paper=500,xp=900}))
  assert(f.doubledAtQueue=="m1" and f.player:GetAttribute("MatchDoubled")=="m1")
  f.hangar:doubleMatch(f.player,match)
  assert(f.calls==1 and f.player:GetAttribute("MenuMessage")=="You already doubled this match.")
  f.callback(true)
  assert(f.player:GetAttribute("MenuMessage")=="Development simulation complete. No real purchase.")
  f.hangar:doubleMatch(f.player,match)
  f.hangar:doubleMatch(f.player,{matchId="m2",paper=74,xp=900})
  assert(f.calls==1 and f.player:GetAttribute("MatchDoubled")=="m1")
  f.player:Destroy()
 end)
 test("practice match doubling clears a failed save or queue refusal so the same match can retry",function()
  for _,queueFull in ipairs({false,true}) do
   local f=fixture(true);f.queueFull=queueFull
   f.hangar:doubleMatch(f.player,{matchId="m1",paper=500,xp=900})
   if not queueFull then f.callback(false) end
   assert(f.player:GetAttribute("MatchDoubled")==nil and f.player:GetAttribute("MenuMessage")=="Development simulation failed.")
   local calls=f.calls;f.queueFull=false
   f.hangar:doubleMatch(f.player,{matchId="m1",paper=500,xp=900})
   assert(f.calls==calls+1 and f.player:GetAttribute("MatchDoubled")=="m1")
   f.player:Destroy()
  end
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
