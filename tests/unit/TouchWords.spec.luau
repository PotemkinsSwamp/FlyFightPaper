local Words=require(game.ReplicatedStorage.FlyFightPaper.Shared.TouchWords)
local Suite=require(script.Parent.Parent.fixtures.Suite)
local Spec={}
local function pcOnly(text)
 local lower=text:lower()
 for _,word in Words.PC_ONLY do if lower:find(word) then return word end end
end
function Spec.run()
 local result,test=Suite.new()
 test("PC words become touch words on a phone and stay as they are on a PC",function()
  assert(Words.say("Too hot! Let go of left click to cool down.",true)=="Too hot! Let go of FIRE to cool down.")
  assert(Words.say("Hold right click and keep a target inside the big circle.",true)=="Hold 2 and keep a target inside the big circle.")
  assert(Words.say("Click a cubby to pick that plane.",true)=="Tap a cubby to pick that plane.")
  assert(Words.say("Got it  [Space]",true)=="Got it")
  assert(Words.say("Locking 40%: Bot  (hold right-click)",true)=="Locking 40%: Bot  (hold 2)")
  assert(Words.say("Click LAUNCH to take off!",false)=="Click LAUNCH to take off!")
  assert(Words.key("Left click",true)=="FIRE" and Words.key("Left click",false)=="Left click")
 end)
 test("no lesson tells a phone player to click, use the mouse or press a key",function()
  local Lessons=require(game.StarterPlayer.StarterPlayerScripts.FlyFightPaper.TutorialLessons)
  local left={}
  local function scan(value,seen)
   if type(value)=="string" then
    local word=pcOnly(Words.say(value,true))
    if word then table.insert(left,word..": "..Words.say(value,true)) end
   elseif type(value)=="table" and not seen[value] then
    seen[value]=true
    for key,inner in value do if key=="key" then assert(Words.key(inner,true)~=inner,"key badge "..tostring(inner)) else scan(inner,seen) end end
   end
  end
  scan(Lessons,{})
  assert(#left==0,table.concat(left," | "))
 end)
 return result
end
return Spec
