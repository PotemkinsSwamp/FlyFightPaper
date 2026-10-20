local Root=game.ReplicatedStorage.FlyFightPaper
local Course=require(Root.Shared.TrainingCourse)
local Suite=require(script.Parent.Parent.fixtures.Suite)
local Spec={}
function Spec.run()
	local result,test=Suite.new()
	local spec=Course.RANGE.targets[3]
	test("difficulty scales speed and swoop without touching the shared spec",function()
		local slow,fast=Course.difficulty(spec,"noob"),Course.difficulty(spec,"veteran")
		assert(slow.speed<spec.speed and fast.speed>spec.speed,"noob slower, veteran faster")
		assert(Course.difficulty(spec,"maneuvers").speed<=fast.speed,"maneuvers is never faster than veteran")
		assert(Course.difficulty(spec,"challenge").speed==spec.speed,"challenge is the base speed")
		assert(spec.weave==nil and Course.difficulty(spec,"maneuvers").weave==true,"only maneuvers weaves")
		assert(Course.difficulty(spec,nil).speed==slow.speed,"no pick means noob")
	end)
	test("the weave's velocity matches how its position changes",function()
		local drill=Course.difficulty(spec,"maneuvers");local center,face,side=Vector3.zero,Vector3.new(0,0,100),Vector3.xAxis
		for _,t in {0,1.3,4.7} do
			local a,velocity=Course.pose(drill,center,t,face,side);local b=Course.pose(drill,center,t+1e-3,face,side)
			assert(((b.Position-a.Position)/1e-3-velocity).Magnitude<velocity.Magnitude*.01+.5,"velocity off at t="..t)
		end
	end)
	return result
end
return Spec
