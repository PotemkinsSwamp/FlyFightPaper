local Root=game.ReplicatedStorage.FlyFightPaper
local Rules=require(Root.Shared.CombatRules)
local Suite=require(script.Parent.Parent.fixtures.Suite)
local Spec={}
local RANGES={pellet=750,staple=900,rubber=1050,paperclip=1400,pencil=1800}
local ORDER={"pellet","staple","rubber","paperclip","pencil"}
function Spec.run()
	local result,test=Suite.new()
	local catalog=require(Root.Shared.Catalog).new(require(Root.Generated.Catalog),require(Root.Generated.Gameplay))
	test("each gun reaches its design range and ranges grow from pellet to pencil",function()
		local previous=0
		for _,id in ipairs(ORDER) do
			local weapon=catalog:get(id);local range=Rules.shotRange(weapon)
			assert(math.abs(range-RANGES[id])<=RANGES[id]*.02,id.." range "..range)
			assert(range>previous,id.." must out-range the one before");previous=range
		end
	end)
	test("travel time inverts distance and is infinite beyond range",function()
		for _,id in ipairs(ORDER) do
			local weapon=catalog:get(id)
			for _,t in ipairs({.1,.5}) do assert(math.abs(Rules.travelTime(weapon,Rules.shotDistance(weapon,t))-t)<1e-6,id) end
			assert(Rules.travelTime(weapon,Rules.shotRange(weapon)+1)==math.huge,id)
		end
		local eraser=catalog:get("eraser") -- no drag: plain distance over speed
		assert(math.abs(Rules.travelTime(eraser,400)-2)<1e-9 and Rules.travelTime(eraser,eraser.projectile_speed*eraser.lifetime+1)==math.huge)
	end)
	test("shots keep between half and three quarters of their speed at the end of flight",function()
		for _,id in ipairs(ORDER) do
			local weapon=catalog:get(id)
			local ratio=Rules.shotSpeed(weapon,weapon.lifetime)/weapon.projectile_speed
			assert(ratio>.5 and ratio<.75,id.." ratio "..ratio)
			assert(Rules.shotSpeed(weapon,0)==weapon.projectile_speed)
		end
	end)
	test("a shot falls by exactly half g t squared below its straight line",function()
		local direction=Vector3.new(0,0,-1)
		for _,id in ipairs(ORDER) do
			local weapon=catalog:get(id);local t=.4
			local offset=Rules.shotOffset(weapon,direction,t)
			local line=direction*Rules.shotDistance(weapon,t)
			-- Vector3 holds 32-bit floats, so compare to a thousandth of a stud.
			assert(math.abs((line-offset).Y-.5*weapon.drop*t*t)<1e-3 and (offset-Vector3.new(0,offset.Y,0)-line).Magnitude<1e-3,id)
		end
	end)
	return result
end
return Spec
