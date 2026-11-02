--!strict
local Util = {}
function Util.copy(value: any): any
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in value do result[key] = Util.copy(child) end
    return result
end
function Util.finite(value: any): boolean
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end
function Util.integer(value: any, minimum: number, maximum: number): boolean
    return Util.finite(value) and value % 1 == 0 and value >= minimum and value <= maximum
end
function Util.count(value: any): number
    local n = 0
    for _ in value do n += 1 end
    return n
end
function Util.sortedKeys(value: any): {any}
    local keys = {}
    for key in value do table.insert(keys, key) end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    return keys
end
function Util.inside(point: any, center: any, half: any): boolean
    return math.abs(point.X - center.X) <= half.X and math.abs(point.Y - center.Y) <= half.Y and math.abs(point.Z - center.Z) <= half.Z
end
function Util.sweptBox(a: any, b: any, half: any): boolean
    local low, high = 0, 1
    for _, axis in { "X", "Y", "Z" } do
        local delta = b[axis] - a[axis]
        if math.abs(delta) < 0.00001 then
            if math.abs(a[axis]) > half[axis] then return false end
        else
            local near = (-half[axis] - a[axis]) / delta
            local far = (half[axis] - a[axis]) / delta
            if near > far then near, far = far, near end
            low, high = math.max(low, near), math.min(high, far)
            if low > high then return false end
        end
    end
    return true
end
return Util
