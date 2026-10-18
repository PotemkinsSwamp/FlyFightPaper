local Root = game:GetService("ReplicatedStorage").FlyFightPaper
local Rules = require(Root.Shared.FlightRules)
local Suite = require(script.Parent.Parent.fixtures.Suite)
local Spec = {}
function Spec.run()
	local result, test = Suite.new()
	local function fly(turn,aim,seconds,heading)
		local dt,bank,angles=1/60,0,{}
		heading=heading or Vector3.new(0,0,-1)
		for _=1,math.floor(seconds*60) do
			local before=heading
			heading,bank=Rules.autopilot(heading,bank,aim,turn,turn,dt)
			assert(math.acos(math.clamp(before:Dot(heading),-1,1))<=math.rad(turn)*dt+1e-4,"turned faster than the loadout allows")
			table.insert(angles,math.deg(math.acos(math.clamp(heading:Dot(aim),-1,1))))
		end
		return angles,bank
	end
	local function settle(angles,within)
		for i,angle in ipairs(angles) do if angle<within then return i/60 end end
		return math.huge
	end
	local behind=Vector3.new(.02,0,1).Unit
	test("starter reverses in under two seconds and heavy is clearly slower",function()
		local starter=settle(fly(116.9,behind,5),3)
		local heavy=settle(fly(72.45,behind,6),3)
		-- Alan asked for faster turn-arounds than the plan's 2-2.5 s (2026-10-07).
		assert(starter>=1.5 and starter<=1.9,"starter reversal "..starter)
		assert(heavy>=starter*1.4,"heavy reversal "..heavy)
	end)
	test("the nose eases onto the aim without overshoot or wobble",function()
		local aim=Vector3.new(1,.3,-1).Unit
		local angles=fly(116.9,aim,4)
		for i=2,#angles do assert(angles[i]<=angles[i-1]+1e-3,"angle grew at frame "..i) end
		assert(angles[#angles]<.1)
	end)
	test("big turns bank hard; aim near the nose levels the wings",function()
		local _,hard=fly(116.9,Vector3.new(1,0,-.2).Unit,.3)
		assert(hard<-math.rad(40),"right turn should bank right")
		local _,level=fly(116.9,Vector3.new(.03,0,-1).Unit,2)
		assert(math.abs(level)<math.rad(2),"near-nose aim should be wings level")
	end)
	test("server turn and empty-Lift climb checks allow honest flight only",function()
		assert(Rules.turnAllowed(Vector3.zAxis,Vector3.xAxis,1,116.9))
		assert(not Rules.turnAllowed(Vector3.zAxis,-Vector3.zAxis,.25,116.9))
		-- cruise 110 empty at y 100 (up to 1.25x from a dive): speed buys (137.5^2 - 77^2) / 120 = 108 studs;
		-- the sink allowance is 6 per second
		assert(Rules.climbAllowed(200,100,110,1,0), "a zoom climb paid for with dive speed")
		assert(not Rules.climbAllowed(230,100,110,1,0), "higher than the speed could carry")
		assert(not Rules.climbAllowed(100,100,110,30,0), "holding height for 30 s without Lift")
		assert(Rules.climbAllowed(100,100,110,30,80), "a fan updraft lifts the limit")
	end)
	test("empty Lift: diving gains speed, climbing spends it, and a dive buys a climb", function()
		local glide = Rules.glide(nil, Vector3.new(0, -1, 1), 100, 1)
		assert(glide > 100, "starts at cruise and a dive builds past it")
		assert(Rules.glide(100, Vector3.new(0, -1, 0), 100, 10) == 150, "up to 1.5 times cruise")
		local slow = Rules.glide(100, Vector3.zAxis, 100, 1)
		assert(slow < 100 and slow > 70, "level flight slowly bleeds speed")
		assert(Rules.glide(70, Vector3.new(0, 1, 1), 100, 1) == 70, "at stall a climb gains nothing")
		local dived = Rules.glide(70, Vector3.new(0, -1, 1), 100, 1)
		assert(dived > 90, "a steep dive gets the speed back")
		local up = Rules.velocity(Vector3.new(0, 1, 1).Unit, 100, 0, 0, dived, 100)
		assert(up.Y > 0, "and that speed carries a climb")
		assert(Rules.velocity(Vector3.new(0, 1, 1).Unit, 100, 0, 0, 70, 100).Y == -12, "stalled: sink only")
		-- No switch: the turn slowdown (a lower `speed`) must not change the glide, and speed changes it smoothly.
		local level = Vector3.new(0, 0, -1)
		assert(Rules.velocity(level, 100, 0, 0, 72, 100) == Rules.velocity(level, 93, 0, 0, 72, 100), "turning doesn't flip the glide")
		local a, b = Rules.velocity(level, 100, 0, 0, 72, 100), Rules.velocity(level, 100, 0, 0, 72.5, 100)
		assert(a.Y < 0 and math.abs(a.Y - b.Y) < 0.5, "sink changes smoothly near stall")
	end)
	test("with Lift a dive builds bounded speed, level flight eases back and a climb spends it", function()
		local speed
		for _ = 1, 120 do speed = Rules.dive(speed, Vector3.new(0, -1, 1), 100, 1 / 60) end
		assert(speed > 110 and speed <= 125, "two seconds of diving: faster, but at most 1.25x cruise: " .. speed)
		local level = Rules.dive(speed, Vector3.zAxis, 100, 1)
		assert(level < speed and level >= 100, "level flight eases back toward cruise")
		assert(Rules.dive(speed, Vector3.new(0, 1, 1), 100, 2) == 100, "a zoom climb spends it, never below cruise")
		assert(Rules.dive(nil, Vector3.zAxis, 100, 1) == 100, "level from cruise stays at cruise")
	end)
	test("a player can loop: pulling up goes over the top, inverted, and back to level",function()
		local dt,heading,bank,aim=1/60,Vector3.new(0,0,-1),0,CFrame.identity
		local top,backward=-1,-1
		for _=1,math.floor(4.2*60) do
			if _<=3.6*60 then aim=aim*CFrame.Angles(math.rad(100)*dt,0,0) end
			heading,bank=Rules.autopilot(heading,bank,aim.LookVector,116.9,116.9,dt,aim.UpVector)
			top=math.max(top,heading.Y);backward=math.max(backward,heading.Z)
		end
		assert(top>.99,"never pointed straight up "..top)
		assert(backward>.95,"never flew back over the top "..backward)
		assert(heading:Dot(Vector3.new(0,0,-1))>.99,"did not finish the loop")
	end)
	test("the aim rolls back toward the sky after the pilot lets go",function()
		local tilted=CFrame.lookAt(Vector3.zero,Vector3.new(0,0,-1))*CFrame.Angles(0,0,math.rad(60))
		for _=1,60 do tilted=Rules.levelAim(tilted,1/60) end
		assert(tilted.UpVector.Y>.999)
		local vertical=CFrame.lookAt(Vector3.zero,Vector3.yAxis,Vector3.zAxis)
		assert(Rules.levelAim(vertical,1/60)==vertical,"straight up has no sky to level toward")
	end)
	test("scripted pilots without a sky direction keep the eighty-degree pitch limit",function()
		local heading,bank=Vector3.new(0,0,-1),0
		for _=1,180 do heading,bank=Rules.autopilot(heading,bank,Vector3.yAxis,116.9,116.9,1/60) end
		assert(heading.Y<=math.sin(math.rad(80))+1e-6)
	end)
	test("tail sets up/down turning, wings left/right; hard turns cost speed",function()
		local function seconds(aim)
			local heading,bank=Vector3.new(0,0,-1),0
			for frame=1,600 do
				heading,bank=Rules.autopilot(heading,bank,aim,80,200,1/60,Vector3.yAxis)
				if heading:Dot(aim)>math.cos(math.rad(3)) then return frame/60 end
			end
			return math.huge
		end
		local up,side=seconds(Vector3.new(0,1,-.2).Unit),seconds(Vector3.new(1,0,-.2).Unit)
		assert(up*1.8<side,"fast tail should pitch much quicker than slow wings yaw: "..up.." vs "..side)
		local forward=Vector3.new(0,0,-1)
		assert(Rules.turnSpeedFactor(forward,forward,1/60,120)==1)
		local full=Rules.turnDirection(forward,Vector3.xAxis,math.rad(120)/60)
		assert(math.abs(Rules.turnSpeedFactor(forward,full,1/60,120)-.75)<1e-3)
	end)
	test("the pitch limit keeps a forward direction",function()
		for _,vertical in ipairs({Vector3.yAxis,-Vector3.yAxis}) do
			local direction=Rules.limitPitch(vertical)
			assert(math.abs(direction.Magnitude-1)<1e-6 and math.abs(direction.Y)<=math.sin(math.rad(80))+1e-6)
			assert(Vector3.new(direction.X,0,direction.Z).Magnitude>.17)
		end
		assert(Rules.limitPitch(Vector3.zAxis)==Vector3.zAxis)
	end)
	test("Lift drains in elapsed seconds and clamps at empty", function()
		assert(Rules.lift(90, 90, 1.5) == 88.5)
		assert(Rules.lift(0.1, 90, 1) == 0)
		assert(Rules.lift(90, 90, -1) == 90)
	end)
	test("empty Lift retains steering and descends even when aiming up", function()
		local velocity = Rules.velocity(Vector3.new(1, 1, 0).Unit, 100, 0, 0)
		assert(math.abs(velocity.X - 70) < 1e-5 and velocity.Y == -12 and velocity.Z == 0)
	end)
	test("fan can rescue an empty plane without exceeding full Lift", function()
		assert(Rules.fanLift(0, 90, 1) == 15 and Rules.fanLift(85, 90, 1) == 90)
		assert(Rules.velocity(Vector3.zAxis, 100, 0, 18).Y == 6)
	end)
	test("upward aim at empty Lift never produces invalid velocity", function()
		assert(Rules.vector(Rules.velocity(Vector3.yAxis, 100, 0, 0)))
	end)
	test("a fan keeps adding Lift the longer you stay in it, on every pass", function()
		local lift = 0
		for _ = 1, 20 do lift = Rules.fanLift(lift, 90, .1) end
		assert(math.abs(lift - 30) < 1e-9, "two seconds in the gust: 30 Lift")
		assert(Rules.fanLift(lift, 90, .1) > lift, "a second pass adds more")
	end)
	test("speed power-ups catch a plane passing between checks", function()
		local centre, size = Vector3.new(0, 0, 0), Vector3.new(10, 60, 60)
		assert(Rules.segmentHitsBox(centre, size, Vector3.new(-30, 25, 0), Vector3.new(30, 25, 0)), "off-centre pass inside the hole")
		assert(not Rules.segmentHitsBox(centre, size, Vector3.new(-30, 35, 0), Vector3.new(30, 35, 0)), "pass above the hole")
		assert(not Rules.segmentHitsBox(centre, size, Vector3.new(-30, 0, 0), Vector3.new(-10, 0, 0)), "stopped short")
		assert(Rules.segmentHitsBox(centre, size, Vector3.new(0, 0, 0), Vector3.new(0, 0, 0)), "sitting inside")
	end)
	test("speed power-ups add up and restart the timer, capped", function()
		local cfg = { speed_bonus = 0.25, max_bonus = 1, seconds = 5 }
		local bonus, untilTime = Rules.stackPickup(0, 0, 10, cfg)
		assert(bonus == 0.25 and untilTime == 15)
		bonus, untilTime = Rules.stackPickup(bonus, untilTime, 12, cfg)
		assert(bonus == 0.5 and untilTime == 17, "second bolt adds and restarts, time does not add")
		for _ = 1, 5 do bonus, untilTime = Rules.stackPickup(bonus, untilTime, 13, cfg) end
		assert(bonus == 1, "capped")
		bonus = Rules.stackPickup(bonus, untilTime, 30, cfg)
		assert(bonus == 0.25, "expired stack starts over")
	end)
	test("server accepts normal travel with replication slack", function()
		assert(Rules.movementAllowed(Vector3.new(0, 100, 0), Vector3.new(0, 100, -25), Vector3.new(0, 0, -100), 0.25, 100))
	end)
	test("server rejects teleports, impossible speed and invalid positions", function()
		local origin = Vector3.new(0, 100, 0)
		assert(not Rules.movementAllowed(origin, Vector3.new(400, 100, 0), Vector3.zero, 0.25, 100))
		assert(not Rules.movementAllowed(origin, origin, Vector3.new(900, 0, 0), 0.25, 100))
		assert(not Rules.movementAllowed(origin, Vector3.new(0, math.huge, 0), Vector3.zero, 0.25, 100))
		assert(not Rules.movementAllowed(origin, Vector3.new(0, 100, 700), Vector3.zero, 0.25, 100))
		assert(not Rules.vector(Vector3.new(0/0, 0, 0)))
	end)
	test("a head-on hit destroys; a shallow scrape costs health for as long as it lasts", function()
		local function into(degrees, speed) return speed * math.sin(math.rad(degrees)) end
		assert(Rules.collisionDamage(110, 110, false, 120, 1/60) == 120, "nose-dive into the floor")
		assert(Rules.collisionDamage(into(30, 90), 90, false, 300, 1/60) == 300, "30 degrees into a wall crashes")
		assert(Rules.collisionDamage(into(20, 90), 90, false, 300, 1/60) < 300, "a 20 degree wing graze is a scrape")
		assert(Rules.collisionDamage(into(20, 200), 200, false, 300, 1/60) < 300, "a graze at boost speed is still a scrape")
		assert(Rules.collisionDamage(math.huge, 90, false, 300, 1/60) == 300, "the train's front running into you")
		local function slide(seconds)
			local total = 0
			for t = 0, seconds - 1e-9, 1/60 do total += Rules.collisionDamage(8, 100, false, 120, 1/60, t) end
			return total
		end
		assert(slide(0.1) > 0 and slide(0.1) < 6, "a brief wing clip costs a little: "..slide(0.1))
		assert(slide(1) < 120, "a one-second belly slide is survivable: "..slide(1))
		assert(slide(2.5) >= 120, "a long slide destroys the plane: "..slide(2.5))
		assert(Rules.collisionDamage(0, 100, true, 120, 1/60) == 120, "empty Lift on the floor")
	end)
	return result
end
return Spec
