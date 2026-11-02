--!strict
local Rules = {}
local quotas = {
    [3] = {2}, [4] = {2}, [5] = {4,2}, [6] = {5,3}, [7] = {6,3},
    [8] = {6,4}, [9] = {7,5,3}, [10] = {8,5,3}, [11] = {9,6,4},
    [12] = {9,6,4}, [13] = {10,7,4}, [14] = {11,7,4}, [15] = {12,8,4}, [16] = {12,8,4},
}
function Rules.plan(count: number, solo: boolean?): {any}
    assert(count % 1 == 0 and count >= 1 and count <= 16, "Invalid roster")
    if count == 1 then
        assert(solo, "Public matches require two players")
        return { {Mode="Race",Quota=1,Duration=90}, {Mode="RisingDanger",Quota=1,Duration=60}, {Mode="Final",Quota=1,Duration=90} }
    end
    local plan = {}
    local durations = if count <= 4 then {75,0,0,75} elseif count <= 8 then {90,75,0,90} else {110,90,100,100}
    local targets = quotas[count] or {}
    for index, quota in targets do
        table.insert(plan, { Mode=({"Race","Survival","RisingDanger"})[index], Quota=quota, Duration=durations[index] })
    end
    table.insert(plan, { Mode="Final", Quota=1, Duration=if count==2 then 70 else durations[4] })
    return plan
end
function Rules.quota(target: number, living: number): number
    if living <= 1 then return living end
    return math.clamp(target, 1, living - 1)
end
function Rules.level(xp: number): number
    local level, threshold = 1, 150
    local remaining = math.max(0, math.min(xp, 100000000))
    while remaining >= threshold do
        remaining -= threshold
        level += 1
        threshold = 150 + (level - 1) * 50
    end
    return level
end
function Rules.xpIntoLevel(xp: number): (number, number)
    local level, remaining, threshold = 1, math.max(0,xp), 150
    while remaining >= threshold do remaining -= threshold; level += 1; threshold = 150 + (level-1)*50 end
    return remaining, threshold
end
return Rules
