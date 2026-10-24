local AimHelp=require(game.ReplicatedStorage.FlyFightPaper.Shared.AimHelp)
local Combat=require(game.ReplicatedStorage.FlyFightPaper.Generated.Gameplay).combat
local Suite=require(script.Parent.Parent.fixtures.Suite)
local Spec={}
function Spec.run()
 local result,test=Suite.new()
 test("mouse players keep the plain hard-edged gun assist",function()
  assert(AimHelp.bend(Combat,Combat.gun_assist_deg-.1,300)==1)
  assert(AimHelp.bend(Combat,Combat.gun_assist_deg+.1,300)==0)
 end)
 test("touch bends fully near the marker, fades to nothing at the cone's edge, and never far away",function()
  local cone=Combat.touch_gun_assist_deg
  assert(AimHelp.bend(Combat,0,300,true)==1)
  local mid=AimHelp.bend(Combat,cone*(1+Combat.touch_assist_inner_fraction)/2,300,true)
  assert(mid>.4 and mid<.6)
  assert(AimHelp.bend(Combat,cone,300,true)==0)
  assert(AimHelp.bend(Combat,0,Combat.touch_assist_max_range_studs+1,true)==0)
  assert(cone>Combat.gun_assist_deg)
 end)
 test("the server's aim check leaves room for the widest touch bend",function()
  assert(Combat.touch_gun_assist_deg<Combat.input_aim_slack_deg)
 end)
 test("the slowdown eases in over an enemy and lets go outside its cone or when leaving",function()
  local cone=Combat.touch_slowdown_cone_deg
  assert(AimHelp.slowdown(Combat,1,0,false)==1)
  assert(math.abs(AimHelp.slowdown(Combat,1,10,false)-Combat.touch_slowdown_scale)<1e-6)
  assert(AimHelp.slowdown(Combat,cone+.1,10,false)==1)
  assert(AimHelp.slowdown(Combat,cone*.75,10,true)==1)
  assert(AimHelp.slowdown(Combat,cone*.25,10,true)<1)
 end)
 return result
end
return Spec
