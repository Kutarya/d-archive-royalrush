--!strict
local Round = {}
Round.__index = Round
function Round.new(mode: string, ids: {number}, quota: number, deadline: number, solo: boolean?)
    local self = setmetatable({Mode=mode,Quota=quota,Deadline=deadline,Alive={},Qualified={},Order={},Placements={},Ties={},Done=false,Overtime=false,Reason="",Solo=solo==true,Winner=nil,Draw=false},Round)
    for _, id in ids do self.Alive[id] = true end
    return self
end
function Round:count(): number
    local count = 0
    for _, living in self.Alive do if living then count += 1 end end
    return count
end
function Round:living(): {number}
    local ids = {}
    for id, alive in self.Alive do if alive then table.insert(ids,id) end end
    table.sort(ids)
    return ids
end
function Round:batch(deaths: {number}, finishes: {number}, now: number)
    if self.Done then return end
    -- Resolve a complete server sample before deciding winner; callback order is irrelevant.
    for _, id in deaths do self.Alive[id] = nil end
    local accepted = {}
    if now <= self.Deadline then
        for _, id in finishes do
            if self.Alive[id] and not self.Qualified[id] then self.Qualified[id]=true; table.insert(accepted,id) end
        end
    end
    table.sort(accepted)
    local placement=#self.Order+1
    for _, id in accepted do self.Placements[id]=placement;self.Ties[id]=#accepted>1;table.insert(self.Order,id) end
    if self.Mode == "Final" then
        if #accepted > 1 then self.Done=true; self.Draw=true; self.Reason="Crown tie"
        elseif #accepted == 1 then self.Done=true; self.Winner=accepted[1]; self.Reason="Crown reached"
        elseif self:count() == 0 then self.Done=true; self.Draw=true; self.Reason="Nobody survived"
        elseif self:count() == 1 and not self.Solo then self.Done=true; self.Winner=self:living()[1]; self.Reason="Last survivor" end
    elseif self.Mode == "Race" then
        if #self.Order >= self.Quota then self.Done=true; self.Reason="Quota reached"
        elseif self:count() == 0 then self.Done=true; self.Reason="No participants" end
    elseif self:count() == 0 then self.Done=true; self.Draw=true; self.Reason="Nobody survived"
    elseif self:count() <= self.Quota and not self.Solo then self:qualifyLiving(); self.Done=true; self.Reason="Survived" end
end
function Round:qualifyLiving()
    for _, id in self:living() do
        if not self.Qualified[id] then self.Qualified[id]=true; table.insert(self.Order,id) end
    end
end
function Round:expire(now: number, overtimeSeconds: number): string
    if self.Done or now < self.Deadline then return "None" end
    if self.Mode == "Race" then self.Done=true; self.Reason="Time up"; return "Ended" end
    if not self.Overtime then self.Overtime=true; self.Deadline=now+overtimeSeconds; return "Overtime" end
    self.Done=true
    if self.Mode == "Final" then self.Draw=true; self.Reason="Time up: draw"
    else self:qualifyLiving(); self.Reason="All remaining survived" end
    return "Ended"
end
return Round
