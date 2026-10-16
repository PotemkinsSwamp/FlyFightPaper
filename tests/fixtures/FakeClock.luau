--!strict
local FakeClock = {}
FakeClock.__index = FakeClock
local function finite(value: number): boolean
    return value == value and value > -math.huge and value < math.huge
end
function FakeClock.new(start: number?)
    local value = start or 0
    assert(finite(value) and value >= 0, "Invalid clock start")
    return setmetatable({ time = value, failures = {} }, FakeClock)
end
function FakeClock:failNext(message: string?)
    table.insert(self.failures, message or "injected_clock_failure")
end
function FakeClock:now(): number
    if #self.failures > 0 then error(table.remove(self.failures, 1)) end
    return self.time
end
function FakeClock:advance(seconds: number): number
    assert(finite(seconds) and seconds >= 0 and finite(self.time + seconds), "Clock cannot move backwards/nonfinite")
    self.time += seconds
    return self.time
end
return FakeClock
