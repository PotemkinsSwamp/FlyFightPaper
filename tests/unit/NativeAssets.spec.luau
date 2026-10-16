local Assets=require(game.ReplicatedStorage.FlyFightPaper.Shared.NativeAssets)
local Suite=require(script.Parent.Parent.fixtures.Suite)
local Spec={}
function Spec.run()
 local result,test=Suite.new()
 test("runtime avatars cannot make a partly replicated map ready",function()
  local room=Instance.new("Folder");room.Parent=game.ServerStorage
  local part=Instance.new("Part");part.Parent=room
  local decal=Instance.new("Decal");decal.Parent=part
  assert(not Assets.ready(room));Assets.mark(room);assert(Assets.ready(room))
  decal.Parent=nil
  local avatar=Instance.new("Model");avatar.Parent=room
  for _=1,20 do Instance.new("Part",avatar) end
  assert(not Assets.ready(room))
  decal.Parent=part;assert(Assets.ready(room))
  room:Destroy()
 end)
 test("native aircraft library waits for all tagged source parts",function()
  local assets=Instance.new("Folder");assets.Parent=game.ServerStorage
  local body=Instance.new("MeshPart");body.Parent=assets
  local wings=Instance.new("MeshPart");wings.Parent=assets
  Assets.mark(assets);wings.Parent=nil
  Instance.new("Folder",assets)
  assert(not Assets.ready(assets))
  wings.Parent=assets;assert(Assets.ready(assets))
  assets:Destroy()
 end)
 return result
end
return Spec
