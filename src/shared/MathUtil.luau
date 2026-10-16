--!strict
local MathUtil = {}
function MathUtil.isFinite(value: any): boolean
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end
function MathUtil.isInteger(value: any, minimum: number, maximum: number): boolean
    return MathUtil.isFinite(value) and value % 1 == 0 and value >= minimum and value <= maximum
end
function MathUtil.isFiniteVector(value: any, componentLimit: number?): boolean
    if typeof(value) ~= "Vector3" then return false end
    local limit = componentLimit or math.huge
    return MathUtil.isFinite(value.X) and MathUtil.isFinite(value.Y) and MathUtil.isFinite(value.Z)
        and math.abs(value.X) <= limit and math.abs(value.Y) <= limit and math.abs(value.Z) <= limit
end
function MathUtil.unitDirection(value: any): Vector3?
    if not MathUtil.isFiniteVector(value, 1) then return nil end
    local length = value.Magnitude
    if length < 0.001 or length > 1.001 then return nil end
    return value / length
end
function MathUtil.copy(value: any): any
    if type(value) ~= "table" then return value end
    local seen = {}
    local function clone(item: any): any
        if type(item) ~= "table" then return item end
        if seen[item] then return seen[item] end
        local output = {}
        seen[item] = output
        for key, child in pairs(item) do output[clone(key)] = clone(child) end
        return output
    end
    return clone(value)
end
return table.freeze(MathUtil)
