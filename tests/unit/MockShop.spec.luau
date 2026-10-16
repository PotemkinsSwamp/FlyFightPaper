local Root=game.ReplicatedStorage.FlyFightPaper
local Hangar=require(game.ServerScriptService.FlyFightPaper.HangarService)
local Catalog=require(Root.Shared.Catalog)
local Schema=require(Root.Shared.ProfileSchema)
local Suite=require(script.Parent.Parent.fixtures.Suite)
local Spec={}
function Spec.run()
 local result,test=Suite.new()
 local function fixture(mock)
  local f={calls=0};local catalog=Catalog.new(require(Root.Generated.Catalog))
  f.player=Instance.new("Folder");f.player.Parent=game.ServerStorage
  local profiles={mock=mock,view=function()return Schema.defaults(catalog)end,enqueue=function(_,player,input)
   assert(player==f.player);f.calls+=1;f.input=input;return true
  end}
  f.hangar=Hangar.new({catalog=catalog},profiles)
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
  assert(f.calls==1 and f.input.kind=="purchasedPaper" and f.input.wholePaper==product.amount)
  f.player:Destroy()
 end)
 test("unknown or malformed mock products grant nothing",function()
  local f=fixture(true)
  f.hangar:handle(f.player,"mockProduct",{key=product.key})
  f.hangar:handle(f.player,"mockProduct","invented")
  assert(f.calls==0);f.player:Destroy()
 end)
 return result
end
return Spec
