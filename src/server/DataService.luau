local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local HttpService=game:GetService("HttpService")
local DataStoreService=game:GetService("DataStoreService")
local Shared=RS:WaitForChild("RoyalRush")
local Config=require(Shared.Config)
local Profile=require(Shared.Profile)
local Sessions=require(Shared.SessionStore)
local Util=require(Shared.Util)
local Rules=require(Shared.MatchRules)
local Data={};Data.__index=Data
function Data.new(changed)
    local memory=RunService:IsStudio() and not Config.Persistence.StudioCloud
    local store=nil
    if not memory then local ok,value=pcall(function() return DataStoreService:GetDataStore(Config.Persistence.Store) end);if ok then store=value end end
    return setmetatable({Entries={},Memory={},Changed=changed,MemoryMode=memory,Store=store,Closed=false},Data)
end
function Data:_retry(callback)
    local last="Storage unavailable"
    for attempt=1,Config.Persistence.Attempts do
        local ok,result,reason=pcall(callback)
        if ok and result then return result end
        last=if ok then (reason or last) else tostring(result)
        if attempt<Config.Persistence.Attempts then task.wait(0.5*2^(attempt-1)) end
    end
    return nil,last
end
function Data:load(player)
    local entry={Player=player,Queue={},Busy=false,Closing=false,Profile=Profile.new(),Revision=0,Status="Loading",Mutable=false,Dirty=false,Owner=HttpService:GenerateGUID(false)}
    self.Entries[player.UserId]=entry
    if self.MemoryMode then
        entry.Profile=Util.copy(self.Memory[player.UserId] or Profile.new());entry.Status="Studio memory";entry.Mutable=true
    else
        local result,reason=self:_retry(function()
            local abort
            local value=self.Store:UpdateAsync("player:"..player.UserId,function(old)
                local nextValue,message=Sessions.open(old,entry.Owner,os.time(),Config.Persistence.LockSeconds)
                abort=message;return nextValue
            end)
            return value,abort
        end)
        if result then entry.Profile=result.Profile;entry.Status="Saved";entry.Mutable=true
        else entry.Status="Read only: "..tostring(reason);warn("[Royal Rush] Profile unavailable; defaults will NOT overwrite stored data.") end
    end
    entry.Revision+=1
    self:_notify(player)
    if entry.Closing then self:remove(player) end
end
function Data:get(player) return self.Entries[player.UserId] end
function Data:_notify(player)
    local ok,reason=pcall(self.Changed,player)
    if not ok then warn("[Royal Rush] Profile observer failed: "..tostring(reason)) end
end
function Data:_save(entry,candidate,release)
    if self.MemoryMode then self.Memory[entry.Player.UserId]=Util.copy(candidate);return true end
    local value,reason=self:_retry(function()
        local abort
        local result=self.Store:UpdateAsync("player:"..entry.Player.UserId,function(old)
            local nextValue,message=Sessions.save(old,candidate,entry.Owner,os.time(),Config.Persistence.LockSeconds,release==true)
            abort=message;return nextValue
        end)
        return result,abort
    end)
    if not value and reason=="Session ownership lost" then entry.Mutable=false;entry.Status="Read only: session ownership lost" end
    return value~=nil,reason
end
function Data:submit(player,operation,mustSave,completed)
    local entry=self:get(player)
    if not entry or not entry.Mutable or entry.Closing then if completed then completed(false,"Progress is not available") end;return end
    if #entry.Queue>=32 then if completed then completed(false,"Profile is busy; try again shortly") end;return end
    table.insert(entry.Queue,{Operation=operation,Save=mustSave,Completed=completed})
    if entry.Busy then return end
    entry.Busy=true
    task.spawn(function()
        while #entry.Queue>0 do
            local job=table.remove(entry.Queue,1)
            local candidate=Util.copy(entry.Profile)
            local protected,ok,message=true,false,"Progress is not available"
            if entry.Mutable then protected,ok,message=pcall(job.Operation,candidate,math.floor(os.time()/86400)) end
            if not protected then local failure=ok;ok=false;message="Profile operation failed";warn("[Royal Rush] "..tostring(failure)) end
            if ok and job.Save then
                local saved,reason=self:_save(entry,candidate,false)
                if not saved then ok=false;message="Save failed; transaction not committed";if entry.Mutable then entry.Status="Save failed" end;warn("[Royal Rush] "..tostring(reason)) end
            end
            if ok then
                entry.Profile=candidate;entry.Dirty=not job.Save;entry.Revision+=1
                entry.Status=if self.MemoryMode then "Studio memory" elseif job.Save then "Saved" else "Pending save"
                self:_notify(player)
            end
            if job.Completed then local success,err=pcall(job.Completed,ok,message);if not success then warn(err) end end
        end
        entry.Busy=false
    end)
end
function Data:autosave()
    for _,entry in self.Entries do
        if entry.Mutable and not entry.Closing and not entry.Busy then
            self:submit(entry.Player,function(_) return true,"Autosave" end,true)
        end
    end
end
function Data:remove(player)
    local entry=self:get(player)
    if not entry or entry.Removing then return end
    entry.Closing=true
    if entry.Status=="Loading" then return end
    entry.Removing=true
    task.spawn(function()
        local deadline=os.clock()+20
        while entry.Busy and os.clock()<deadline do task.wait(0.1) end
        if entry.Busy then warn("[Royal Rush] Pending profile operations at shutdown; last unsaved changes may be lost.")
        elseif entry.Mutable then
            local ok,reason=self:_save(entry,entry.Profile,true)
            if not ok then warn("[Royal Rush] Final save failed: "..tostring(reason)) end
        end
        if self.Entries[player.UserId]==entry then self.Entries[player.UserId]=nil end
    end)
end
function Data:view(player)
    local entry=self:get(player)
    if not entry then return {Ready=false,SaveStatus="Loading"} end
    local p=entry.Profile
    local quests=Util.copy(p.Quests);local day=math.floor(os.time()/86400)
    if day>quests.Day then quests={Day=day,Counts={},Claimed={}} end
    return {Ready=entry.Status~="Loading",Mutable=entry.Mutable,Persistent=not self.MemoryMode and entry.Mutable,
        SaveStatus=entry.Status,Revision=entry.Revision,Level=Rules.level(p.TotalXP),XP=p.TotalXP,Crowns=p.Crowns,Wins=p.Wins,LocalWins=p.LocalWins,BestStreak=p.BestStreak,
        SelectedPower=p.SelectedPower,OwnedCosmetics=Util.copy(p.OwnedCosmetics),EquippedCosmetics=Util.copy(p.EquippedCosmetics),Settings=Util.copy(p.Settings),
        Quests=quests,Daily=Util.copy(p.Daily),Day=day,TutorialVersion=p.TutorialVersion,Achievements=Util.copy(p.Achievements)}
end
function Data:close()
    self.Closed=true
    for _,entry in self.Entries do self:remove(entry.Player) end
    local untilTime=os.clock()+25
    while next(self.Entries) and os.clock()<untilTime do task.wait(0.1) end
end
return Data
