local Root=game.ReplicatedStorage.FlyFightPaper
local Tactics=require(Root.Shared.BotTactics)
local Config=require(Root.Generated.Gameplay)
local Suite=require(script.Parent.Parent.fixtures.Suite)
local Spec={}
local ORDER={"rookie","regular","experienced","ace"}

function Spec.run()
	local result,test=Suite.new()
	test("the trick comes from the build's guns",function()
		assert(Tactics.trick({false,"popper","staple","staple"})=="dart")
		assert(Tactics.trick({"crayon",false,"pellet"})=="standoff")
		assert(Tactics.trick({"rubber","rubber","spitball",false})=="spitball")
		assert(Tactics.trick({"thumbtack","thumbtack","staple"})=="turnfight")
		assert(Tactics.trick({false,false})=="turnfight")
	end)
	test("a perfect approach brakes at 80 studs and holds off at 300",function()
		local profile={trick_reliability=1,trick_error=0}
		local brake,hold=Tactics.approach(profile,function(a,b) return (a+b)/2 end)
		assert(brake==80 and hold==300)
	end)
	test("a fumbled approach doesn't brake; a sloppy one brakes inside its spread",function()
		local fumble=Tactics.approach({trick_reliability=.5,trick_error=.25},function(a,b) return b end)
		assert(fumble==0)
		local early=Tactics.approach({trick_reliability=.5,trick_error=.25},function(a,b) return a==0 and 0 or b end)
		assert(math.abs(early-100)<1e-9,early) -- a veteran: 80-100 studs (Alan)
		local late=Tactics.approach({trick_reliability=.5,trick_error=.25},function(a,b) return a end)
		assert(math.abs(late-74)<1e-9,late)
	end)
	test("stealing: only damaged planes; a good pilot finishes its own and never hops damaged to damaged",function()
		assert(not Tactics.shouldSteal(nil,.8,true))
		assert(Tactics.shouldSteal(nil,.4,true) and Tactics.shouldSteal(nil,.4,false))
		assert(Tactics.shouldSteal(.9,.4,true)) -- leaves a healthy plane for the fold
		assert(not Tactics.shouldSteal(.2,.1,true)) -- finishes the plane about to fold
		assert(not Tactics.shouldSteal(.45,.3,true)) -- never damaged to damaged
		assert(Tactics.shouldSteal(.45,.3,false)) -- a poor pilot hops
		assert(not Tactics.shouldSteal(.2,.3,false))
	end)
	test("better bots fly tricks more often and more exactly, steal and judge switches better (Alan 2026-11-08)",function()
		local previous
		for _,tier in ipairs(ORDER) do
			local p=assert(Config.bots.profiles[tier],tier)
			if previous then
				assert(p.trick_reliability>previous.trick_reliability and p.trick_error<previous.trick_error,tier)
				assert(p.steal_notice>previous.steal_notice and p.steal_bonus>previous.steal_bonus,tier)
				assert(p.switch_judgment>previous.switch_judgment,tier)
				assert(p.turn_factor>previous.turn_factor and p.aim_error_deg[2]<previous.aim_error_deg[2],tier)
				assert(p.reaction_seconds[2]<previous.reaction_seconds[2],tier)
			end
			previous=p
		end
		-- An Ace brakes at about 80 studs almost exactly, a veteran at 80-100 (Alan).
		assert(80*(1+Config.bots.profiles.ace.trick_error)<=85 and math.abs(80*(1+Config.bots.profiles.experienced.trick_error)-100)<1e-9)
	end)
	return result
end
return Spec
