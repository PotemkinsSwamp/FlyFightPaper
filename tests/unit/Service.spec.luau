local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local Rules = require(Root.Shared.ServiceRules)
local Suite = require(script.Parent.Parent.fixtures.Suite)
local Spec = {}
local function near(a, b) assert(math.abs(a - b) < 1e-7, tostring(a) .. " != " .. tostring(b)) end
function Spec.run()
    local result, test = Suite.new()
    test("hangar safety runs down inside, refills after 120 s out in a row", function()
        local r, out = Rules.hangarSafety(120, 0, true, 120, 120, 120)
        assert(r == 0 and out == 0)
        r, out = Rules.hangarSafety(r, out, false, 60, 120, 120); assert(r == 0 and out == 60)
        r, out = Rules.hangarSafety(r, out, true, 1, 120, 120); assert(r == 0 and out == 0) -- darting back resets the wait
        r, out = Rules.hangarSafety(r, out, false, 119, 120, 120); assert(r == 0)
        r, out = Rules.hangarSafety(r, out, false, 1, 120, 120); assert(r == 120)
    end)
    test("SV04 exact proportional repair and repeated floor", function()
        local p = assert(Rules.repair(120, 120, 30))
        near(p.health, 105); near(p.lifeMaxHealth, 105); near(p.wear, 15); near(p.restored, 75)
        local M = 120
        for _ = 1, 20 do
            p = assert(Rules.repair(120, M, 0)); M = p.lifeMaxHealth
            assert(p.health <= M and M >= 72 and M <= 120)
        end
        near(M, 72)
        p = assert(Rules.repair(120, 72, 20)); near(p.health, 72); near(p.wear, 0)
    end)
    test("SV04 tiny scratch no forced harmful repair and finite bounds", function()
        local p = assert(Rules.repair(120, 120, 119.999))
        near(p.wear, 0.001 / 6)
        assert(p.health > 119.999 and p.lifeMaxHealth <= 120)
        p = assert(Rules.repair(120, 120, 120)); assert(p.health == 120 and p.wear == 0)
        p = assert(Rules.repair(120, 72, 72)); assert(p.health == 72 and p.wear == 0)
        for _, values in ipairs({ { 0, 0, 0 }, { 120, 71, 30 }, { 120, 121, 30 },
            { 120, 120, -1 }, { 120, 120, 121 }, { math.huge, 120, 1 }, { 120, 0/0, 1 } }) do
            assert(Rules.repair(table.unpack(values)) == nil)
        end
    end)
    test("takeoff rolls level from the hangar, then climbs through the ring centre at full speed", function()
        local cfg = { approach_out_studs = 145, approach_up_studs = 15, hangar_back_studs = 69,
            takeoff_liftoff_out_studs = 60, takeoff_exit_studs = 25 }
        local home = CFrame.new(0, 110, -850) * CFrame.Angles(0, math.pi, 0) -- north desk: faces the room (+Z)
        local legs = Rules.takeoff(home, cfg, 100)
        local roll, climb = legs[1], legs[2]
        assert((roll.cframe.Position - Vector3.new(0, 110, -790)).Magnitude < 1e-3, tostring(roll.cframe.Position))
        assert(roll.cframe.LookVector:Dot(Vector3.zAxis) > 0.9999)          -- still level, facing the room
        near(roll.seconds, 2 * 129 / 100)                                    -- 69 back + 60 out, from rest
        local ring = Rules.approach(home, cfg).Position
        local look = climb.cframe.LookVector
        assert(look.Y > 0 and look.Z > 0)                                    -- climbing out over the room
        local back = climb.cframe.Position - look * 25
        assert((back - ring).Magnitude < 1e-3, tostring(back))               -- the line passes the ring centre
        assert(math.abs(climb.seconds - (climb.cframe.Position - roll.cframe.Position).Magnitude / 100) < 1e-6)
    end)
    test("landing needs the ring box and a runway-aligned heading", function()
        local cfg = { approach_out_studs = 145, approach_up_studs = 15, approach_box_studs = { 70, 50, 60 },
            approach_max_angle_degrees = 35, hangar_back_studs = 69 }
        local home = CFrame.new(0, 110, -850) * CFrame.Angles(0, math.pi, 0) -- north desk: faces the room (+Z)
        local ring = Rules.approach(home, cfg).Position
        assert((ring - Vector3.new(0, 125, -705)).Magnitude < 1e-3, tostring(ring))
        assert((Rules.hangar(home, cfg).Position - Vector3.new(0, 110, -919)).Magnitude < 1e-3)
        local inbound = Vector3.new(0, 0, -1)
        assert(Rules.linedUp(home, ring, inbound, cfg))
        assert(Rules.linedUp(home, ring, (inbound + Vector3.new(0.5, -0.2, 0)), cfg)) -- ~27 degrees off: assisted
        assert(not Rules.linedUp(home, ring, Vector3.new(1, 0, 0), cfg))             -- from the side
        assert(not Rules.linedUp(home, ring, -inbound, cfg))                         -- flying away
        assert(not Rules.linedUp(home, ring + Vector3.new(40, 0, 0), inbound, cfg))  -- beside the ring
        assert(not Rules.linedUp(home, ring + Vector3.new(0, 0, 40), inbound, cfg))  -- before it
    end)
    test("menu click budget lets a burst land, then refills", function()
        local tokens, last, landed = nil, nil, 0
        for i = 1, 8 do
            local ok, left = Rules.clickBudget(tokens, last, i * 0.05, 6, 0.25)
            if ok then landed += 1; tokens, last = left, i * 0.05 end
        end
        assert(landed == 7, "quick burst landed " .. landed)
        assert(not Rules.clickBudget(tokens, last, last + 0.1, 6, 0.25), "empty budget should refuse")
        assert(Rules.clickBudget(tokens, last, last + 0.3, 6, 0.25), "a quarter second refills one click")
    end)
    return result
end
return Spec
