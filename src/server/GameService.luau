local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local PhysicsService=game:GetService("PhysicsService")
local HttpService=game:GetService("HttpService")
local Shared=RS:WaitForChild("RoyalRush")
local Config=require(Shared.Config)
local Rules=require(Shared.MatchRules)
local RoundModel=require(Shared.RoundModel)
local Profile=require(Shared.Profile)
local Util=require(Shared.Util)
local RateLimiter=require(Shared.RateLimiter)
local RequestValidation=require(Shared.RequestValidation)
local DataService=require(script.Parent.DataService)
local MapService=require(script.Parent.MapService)
local ChaosService=require(script.Parent.ChaosService)
local Power=require(script.Parent.PowerService)
local Cosmetics=require(script.Parent.CosmeticService)
local LobbyService=require(script.Parent.LobbyService)
local Analytics=require(script.Parent.Analytics)
local Game={};Game.__index=Game
local activeStates={RoundActive=true,Final=true}
local function newRemote(parent,name)
    local event=Instance.new("RemoteEvent");event.Name=name;event.Parent=parent;return event
end
function Game.new()
    local network=Instance.new("Folder");network.Name="RoyalRushRemotes";network.Parent=RS
    local self=setmetatable({Records={},Roster={},State="Waiting",Deadline=0,StateVersion=0,RoundIndex=0,RoundId="",MatchId="",MatchNumber=0,PendingDeaths={},Limiter=RateLimiter.new(),Connections={},NextSnapshot=0,LastSave=0,LastBoard=0,Stopped=false,Result=nil},Game)
    self.Remotes={Action=newRemote(network,"Action"),State=newRemote(network,"State"),Effect=newRemote(network,"Effect")}
    self.Map=MapService.new();self.Lobby=LobbyService.new()
    self.Data=DataService.new(function(player) self:onData(player) end)
    self.Chaos=ChaosService.new(self.Map,self)
    pcall(function() PhysicsService:RegisterCollisionGroup("RoyalPlayers") end)
    PhysicsService:CollisionGroupSetCollidable("RoyalPlayers","RoyalPlayers",false)
    return self
end
function Game:roundToken() return self.RoundId end
function Game:effect(name,data,player)
    if player and player.Parent then self.Remotes.Effect:FireClient(player,name,data)
    elseif not player then self.Remotes.Effect:FireAllClients(name,data) end
end
function Game:toast(player,message) self:effect("Toast",{Text=message},player) end
function Game:onData(player)
    local record=self.Records[player.UserId];local entry=self.Data:get(player)
    if record and entry then
        if not table.find(self.Roster,player.UserId) or self.State=="Waiting" or self.State=="Intermission" or self.State=="Results" then record.LockedPower=entry.Profile.SelectedPower end
        if record.Character and record.Character.Parent then Cosmetics.apply(record.Character,entry.Profile,record.Streak) end
        self.Lobby:publish(player,entry);self:send(player)
    end
end
function Game:state(name,seconds)
    self.State=name;self.StateVersion+=1;self.Deadline=workspace:GetServerTimeNow()+(seconds or 0)
    print("[Royal Rush] "..name.." • round "..self.RoundIndex)
    self:broadcast()
end
function Game:character(record,character)
    if record.CharacterConnection then record.CharacterConnection:Disconnect() end
    record.Character=character;record.Humanoid=character:WaitForChild("Humanoid",10);record.Root=character:WaitForChild("HumanoidRootPart",10)
    if not record.Humanoid or not record.Root then return end
    if not record.Humanoid:FindFirstChildOfClass("Animator") then Instance.new("Animator",record.Humanoid) end
    record.Humanoid.UseJumpPower=false;record.Humanoid.JumpHeight=Config.JumpHeight
    for _,p in character:GetDescendants() do
        if p:IsA("BasePart") then p.CollisionGroup="RoyalPlayers" end
        if p:IsA("NumberValue") and ({BodyHeightScale=true,BodyWidthScale=true,BodyDepthScale=true,HeadScale=true})[p.Name] then p.Value=1 end
    end
    if record.DescendantConnection then record.DescendantConnection:Disconnect() end
    record.DescendantConnection=character.DescendantAdded:Connect(function(p) if p:IsA("BasePart") then p.CollisionGroup="RoyalPlayers" end end)
    record.CharacterConnection=record.Humanoid.Died:Connect(function()
        if record.Status=="Active" then
            if self.Current and self.Current.Mode=="Race" then record.Falls+=1;record.Status="Recovering";record.RecoverAt=workspace:GetServerTimeNow()+Config.RespawnDelay
            else self:queueDeath(record,"Reset / character death") end
        end
    end)
    if record.Status=="Preparing" and self.Map.Model and table.find(self.Roster,record.Player.UserId) then self:teleport(record,self.Map:spawn(table.find(self.Roster,record.Player.UserId)),true)
    elseif record.Status=="Recovering" and self.Map.Model then self:teleport(record,self.Map:checkpoint(record.Checkpoint),false);record.Status="Active"
    else self:toLobby(record) end
    local entry=self.Data:get(record.Player);if entry then Cosmetics.apply(character,entry.Profile,record.Streak) end
end
function Game:add(player)
    if self.Records[player.UserId] then return end
    local record={Player=player,Status="Lobby",Queued=true,Streak=0,Matches=0,Checkpoint=0,Falls=0,ActiveSeconds=0,LastMoved=0,Cooldown=0,DoubleUsed=false,Connections={}}
    self.Records[player.UserId]=record
    table.insert(record.Connections,player.CharacterAdded:Connect(function(character) self:character(record,character) end))
    if player.Character then task.spawn(function() self:character(record,player.Character) end) end
    task.spawn(function() self.Data:load(player) end)
    Analytics.log(player,"new_player_join")
    if self.Map.Model then pcall(function() player:AddReplicationFocus(self.Map.Model.PrimaryPart) end) end
end
function Game:remove(player)
    local record=self.Records[player.UserId]
    if record then
        if record.Status=="Active" or record.Status=="Recovering" or record.Status=="Qualified" then self.PendingDeaths[player.UserId]="Disconnected";Analytics.log(player,"left_during_round") end
        self.Chaos:clearCharacter(record)
        for _,c in record.Connections do c:Disconnect() end
        if record.CharacterConnection then record.CharacterConnection:Disconnect() end
        if record.DescendantConnection then record.DescendantConnection:Disconnect() end
        self.Records[player.UserId]=nil
    end
    self.Limiter:clear(player.UserId);self.Data:remove(player)
end
function Game:teleport(record,cframe,frozen)
    if not record.Root or not record.Root.Parent or not record.Humanoid then return end
    self.Chaos:clearCharacter(record)
    for _,name in {"RoyalDash","RoyalDashAttachment","RoyalImpulse","RoyalImpulseAttachment"} do
        local constraint=record.Root:FindFirstChild(name);if constraint then constraint:Destroy() end
    end
    record.Root.Anchored=frozen==true
    -- Put the root at the spawn even when an avatar uses a different model pivot.
    local rootToPivot=record.Root.CFrame:ToObjectSpace(record.Character:GetPivot())
    record.Character:PivotTo(cframe*rootToPivot)
    record.Root.AssemblyLinearVelocity=Vector3.zero;record.Root.AssemblyAngularVelocity=Vector3.zero
    record.Humanoid.WalkSpeed=if frozen then 0 else Config.WalkSpeed;record.Humanoid.JumpHeight=if frozen then 0 else Config.JumpHeight
    record.Humanoid.AutoRotate=true;record.Humanoid.PlatformStand=false;record.Humanoid.Sit=false
    if not frozen then
        pcall(function() record.Root:SetNetworkOwner(record.Player) end)
        record.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
    record.LastPosition=record.Root.Position;record.LastCFrame=record.Root.CFrame;record.MovementGrace=workspace:GetServerTimeNow()+1.5;record.TravelBudget=12
end
function Game:toLobby(record)
    self:teleport(record,self.Lobby:spawn(record.Player.UserId%16+1),false)
    if record.Status~="Qualified" and record.Status~="Eliminated" and record.Status~="Recovering" then record.Status="Lobby" end
end
function Game:ready()
    local result={}
    for _,record in self.Records do
        local entry=self.Data:get(record.Player)
        if record.Queued and record.Root and record.Root.Parent and record.Humanoid and record.Humanoid.Health>0 and entry and entry.Status~="Loading" then table.insert(result,record) end
    end
    table.sort(result,function(a,b) return a.Player.UserId<b.Player.UserId end)
    while #result>Config.MaxPlayers do table.remove(result) end
    return result
end
function Game:activeCount()
    local count=0;for _,r in self.Records do if r.Status=="Active" then count+=1 end end;return count
end
function Game:queueDeath(record,reason)
    if record.Status=="Active" then self.PendingDeaths[record.Player.UserId]=reason end
end
function Game:grant(record,id,xp,crowns,statistics)
    self.Data:submit(record.Player,function(p,day) return Profile.grant(p,id,xp,crowns,statistics,day) end,false)
end
function Game:stat(record,key,id) self:grant(record,id,0,0,{[key]=1}) end
function Game:beginMatch(records)
    self.MatchNumber+=1;self.MatchId=HttpService:GenerateGUID(false);self.RoundIndex=0;self.Result=nil;self.RetryUsed=false
    self.Solo=#records==1 and RunService:IsStudio() and Config.StudioSolo
    self.Competitive=#records>=4 and game.PrivateServerId=="" and not RunService:IsStudio()
    self.StartCount=#records;self.Plan=Rules.plan(#records,self.Solo);self.Roster={}
    self.Lobby:clearKing()
    for _,r in records do
        r.Status="Preparing";r.LockedPower=self.Data:get(r.Player).Profile.SelectedPower;r.ActiveSeconds=0;r.Matches+=1;r.MatchId=self.MatchId;r.ParticipationGranted=false
        table.insert(self.Roster,r.Player.UserId)
        Analytics.log(r.Player,if r.Matches==1 then "first_round_start" else "second_match_started")
    end
    self:nextRound()
end
function Game:nextRound(retry)
    if not retry then self.RoundIndex+=1 end
    local stage=self.Plan[self.RoundIndex]
    if not stage then self:results(nil,"Tournament complete");return end
    local roster={}
    for _,id in self.Roster do local r=self.Records[id];if r and r.Queued then table.insert(roster,id) end end
    self.Roster=roster
    if #roster==0 then self:results(nil,"No participants");return end
    if #roster==1 and not self.Solo then self:results(roster[1],"Last remaining player");return end
    if not retry and #roster<=2 and not self.Solo and stage.Mode~="Final" and self.RoundIndex>1 then self.RoundIndex=#self.Plan;stage=self.Plan[self.RoundIndex] end
    self.RoundId=self.MatchId..":"..self.RoundIndex..(if retry then ":retry" else "")
    self.PendingDeaths={};self.Chaos:stop()
    local id=if stage.Mode=="Race" then (if self.MatchNumber%2==1 then "SkyKingdom" else "NeonCity") elseif stage.Mode=="Survival" then "LavaSurvival" elseif stage.Mode=="RisingDanger" then "LavaAscent" else "CrownClimb"
    if self.Map.Model then for _,r in self.Records do pcall(function() r.Player:RemoveReplicationFocus(self.Map.Model.PrimaryPart) end) end end
    local ok,err=pcall(function() self.Map:load(id) end)
    if not ok then warn(err);self:results(nil,"Map could not load");return end
    self.Current={Mode=stage.Mode,Quota=if self.Solo then 1 elseif stage.Mode=="Final" then 1 else Rules.quota(stage.Quota,#roster),Duration=if retry then 60 else stage.Duration,Retry=retry==true}
    self.Round=nil;self.Started=0
    for _,r in self.Records do pcall(function() r.Player:AddReplicationFocus(self.Map.Model.PrimaryPart) end) end
    for slot,playerId in roster do
        local r=self.Records[playerId];r.Status="Preparing";r.Checkpoint=0;r.Falls=0;r.Moved=0;r.RoundActiveSeconds=0;r.RecoverAt=nil;r.StreamReady=false;Power.reset(r)
        self:teleport(r,self.Map:spawn(slot),true)
        self:effect("Prepare",{Position=self.Map:spawn(slot).Position,RoundId=self.RoundId},r.Player)
    end
    self:state("Preparing",6)
end
function Game:activate()
    local ids={}
    local now=workspace:GetServerTimeNow()
    for _,id in self.Roster do
        local r=self.Records[id]
        if r and r.Queued and r.Status=="Preparing" and r.StreamReady and r.Root and r.Root.Parent and r.Humanoid and r.Humanoid.Health>0 then table.insert(ids,id)
        elseif r then r.Status="Lobby";self:toLobby(r);self:toast(r.Player,"Map not ready. You are queued for the next match.") end
    end
    if #ids==0 or (#ids<2 and not self.Solo) then self:results(nil,"Not enough ready players");return end
    if not self.Solo and self.Current.Mode~="Final" then self.Current.Quota=Rules.quota(self.Current.Quota,#ids) end
    for _,id in ids do
        local r=self.Records[id]
        r.Status="Active";r.Root.Anchored=false;r.Humanoid.WalkSpeed=Config.WalkSpeed;r.Humanoid.JumpHeight=Config.JumpHeight;r.Humanoid.PlatformStand=false;r.Humanoid.Sit=false;r.LastPosition=r.Root.Position;r.LastCFrame=r.Root.CFrame;r.StartedAt=now;r.TravelBudget=12
        pcall(function() r.Root:SetNetworkOwner(r.Player) end)
        self:stat(r,"RoundsPlayed",self.RoundId..":played:"..id)
        if self.Current.Mode=="Final" then self:grant(r,self.MatchId..":final:"..id,75,20,{FinalsReached=1});Analytics.log(r.Player,"final_reached") end
    end
    self.Roster=ids;self.Started=now;self.Map.Model:SetAttribute("RoundStartedAt",now)
    self:state(if self.Current.Mode=="Final" then "Final" else "RoundActive",self.Current.Duration)
    self.Round=RoundModel.new(self.Current.Mode,ids,self.Current.Quota,self.Deadline,self.Solo)
    local seed=Random.new():NextInteger(1,2147483646);self.Seed=seed
    if not self.Current.Retry then self.Chaos:startRound(self.Current.Mode,self.RoundIndex,seed,now) end
end
function Game:movement(record,dt,now)
    local root=record.Root;local previous=record.LastPosition or root.Position;local delta=root.Position-previous
    if not Util.finite(root.Position.X) or not Util.finite(root.Position.Y) or not Util.finite(root.Position.Z) then
        root.CFrame=record.LastCFrame or self.Map:checkpoint(record.Checkpoint);root.AssemblyLinearVelocity=Vector3.zero
        return previous,root.Position,false
    end
    local horizontal=Vector2.new(delta.X,delta.Z).Magnitude
    local ping=0;pcall(function() ping=math.clamp(record.Player:GetNetworkPing(),0,0.5) end)
    local speed=record.Humanoid.WalkSpeed+8
    if now<(record.MovementGrace or 0) then speed=80 end
    local burst=16+ping*32
    record.TravelBudget=math.min(burst+math.max(0,dt-0.25)*speed,(record.TravelBudget or burst)+speed*dt)
    local invalid=horizontal>record.TravelBudget+0.1 or delta.Y>math.max(12,75*dt+ping*30)
    if invalid then
        root.CFrame=record.LastCFrame or root.CFrame;root.AssemblyLinearVelocity=Vector3.zero;record.TravelBudget=burst;record.MovementGrace=now+0.25
        record.Corrections=(record.Corrections or 0)+1
        if record.Corrections%5==1 then Analytics.log(record.Player,"movement_corrected") end
        return previous,previous,false
    end
    record.TravelBudget=math.max(0,record.TravelBudget-horizontal)
    if horizontal>0.15 and now>(record.MovementGrace or 0) then record.Moved=(record.Moved or 0)+horizontal;record.ActiveSeconds+=dt;record.RoundActiveSeconds+=dt end
    record.LastPosition=root.Position;record.LastCFrame=root.CFrame
    return previous,root.Position,true
end
function Game:tickRound(now,dt)
    if not self.Round or self.Round.Done then return end
    self.Map:update(now-self.Started,dt,self.Records,now,self.Round.Overtime)
    if not self.Current.Retry then self.Chaos:update(now) end
    local finishes={}
    for _,id in self.Roster do
        local r=self.Records[id]
        if r and r.Status=="Recovering" and now>=(r.RecoverAt or 0) then
            if r.Humanoid and r.Humanoid.Health>0 then self:teleport(r,self.Map:checkpoint(r.Checkpoint),false);r.Status="Active"
            elseif not r.LoadingCharacter then r.LoadingCharacter=true;task.spawn(function() pcall(function() r.Player:LoadCharacterAsync() end);r.LoadingCharacter=false end) end
        elseif r and r.Status=="Active" and r.Root and r.Root.Parent then
            local before,position,valid=self:movement(r,dt,now)
            if r.Humanoid.FloorMaterial~=Enum.Material.Air then r.DoubleUsed=false end
            local hazard,knock=self.Map:hazard(r,now,before)
            if hazard then
                if self.Current.Mode=="Race" then
                    r.Falls+=1;r.Status="Recovering";r.RecoverAt=now+Config.RespawnDelay
                    self:teleport(r,self.Map:checkpoint(r.Checkpoint),true);self:effect("Recovered",{Reason=hazard},r.Player)
                else self:queueDeath(r,hazard) end
            elseif knock then Power.knock(r,knock,now) end
            if valid and r.Status=="Active" and not self.PendingDeaths[id] and self.Map:progress(r,before,position) and (self.Current.Mode=="Race" or self.Current.Mode=="Final") then table.insert(finishes,id) end
            if not self.Solo and now-r.StartedAt>Config.AFKSeconds and (r.Moved or 0)<3 then r.Queued=false;self:queueDeath(r,"AFK: queue paused") end
            if r.ActiveSeconds>=20 and not r.ParticipationGranted then r.ParticipationGranted=true;self:grant(r,self.MatchId..":participation:"..id,40,5,nil) end
        end
    end
    local deaths={}
    for id in self.PendingDeaths do table.insert(deaths,id) end
    table.sort(deaths)
    self.Round:batch(deaths,finishes,now)
    for _,id in deaths do
        local r=self.Records[id]
        if r and r.Status~="Eliminated" then
            r.Status="Eliminated";r.Streak=0;self:toLobby(r);self:effect("Eliminated",{Reason=self.PendingDeaths[id]},r.Player);Analytics.log(r.Player,"eliminated")
        end
    end
    self.PendingDeaths={}
    local expired=self.Round:expire(now,Config.Overtime)
    if expired=="Overtime" then self.Deadline=self.Round.Deadline;self:effect("Overtime",{Ends=self.Deadline}) end
    for _,id in self.Round.Order do
        local r=self.Records[id]
        if r and r.Status=="Active" and self.Current.Mode~="Final" then
            r.Status="Qualified";self:toLobby(r)
            local perfect=self.Current.Mode=="Race" and r.Falls==0;local clutch=self.Current.Mode=="Race" and now<=self.Round.Deadline and self.Round.Deadline-now<=1
            local increments={Qualifications=1};if perfect then increments.Perfects=1 end;if clutch then increments.Clutches=1 end
            self:grant(r,self.RoundId..":qualified:"..id,50+(if perfect then 10 else 0),15,increments)
            self:effect("Qualified",{Placement=if self.Current.Mode=="Race" then self.Round.Placements[id] else nil,Tie=self.Round.Ties[id],Perfect=perfect,Clutch=clutch,XP=50+(if perfect then 10 else 0)},r.Player);Analytics.log(r.Player,"qualified")
            if not r.FirstFinished then r.FirstFinished=true;Analytics.log(r.Player,"first_round_finish") end
        end
    end
    if self.Round.Done then self:endRound() end
end
function Game:endRound()
    self.Chaos:stop()
    if self.Current.Mode=="Final" then self:results(self.Round.Winner,self.Round.Reason);return end
    local survivors={}
    for _,id in self.Round.Order do local r=self.Records[id];if r and r.Queued then table.insert(survivors,id) end end
    if #survivors==0 and self.Current.Mode=="Race" and not self.RetryUsed and #self.Roster>=2 then
        self.RetryUsed=true;self:toastAll("No finishers. Easier retry: Chaos disabled.");self:nextRound(true);return
    end
    if #survivors<=1 and not self.Solo then self:results(survivors[1],if #survivors==0 then "No qualifiers" else "Last qualifier");return end
    if #survivors==0 then self:results(nil,"No qualifiers");return end
    for _,id in self.Roster do local r=self.Records[id];if r and not table.find(survivors,id) and r.Status~="Eliminated" then r.Status="Eliminated";r.Streak=0;self:toLobby(r);self:effect("Eliminated",{Reason="Qualification time ended"},r.Player) end end
    self.Roster=survivors;self:state("Transition",Config.Transition)
end
function Game:toastAll(message) self:effect("Toast",{Text=message}) end
function Game:results(winnerId,reason)
    self.Chaos:stop()
    local winner=winnerId and self.Records[winnerId]
    local competitive=self.Competitive
    local activeCompetitors=0;for _,r in self.Records do if r.MatchId==self.MatchId and r.ActiveSeconds>=20 then activeCompetitors+=1 end end
    competitive=competitive and activeCompetitors>=2
    for _,r in self.Records do
        if r.Matches>0 and r.Player.UserId~=winnerId and table.find(self.Roster,r.Player.UserId) then r.Streak=0 end
        r.Status="Lobby";self:toLobby(r)
    end
    if winner then
        winner.Streak+=1
        self.Data:submit(winner.Player,function(p,day) return Profile.win(p,self.MatchId..":win",competitive,winner.Streak,day) end,false)
        local displayed,displayError=pcall(function() self.Lobby:showKing(winner.Player) end)
        if not displayed then warn("[Royal Rush] Victory display: "..tostring(displayError)) end
        Analytics.log(winner.Player,"match_win")
    end
    self.Result={WinnerId=winnerId,Winner=if winner then winner.Player.DisplayName else nil,Reason=reason,Streak=if winner then winner.Streak else 0,Competitive=competitive}
    if winner then
        local entry=self.Data:get(winner.Player)
        self.Result.RewardXP=if entry and entry.Mutable then (if competitive then 250 else 100) else 0
        self.Result.RewardCrowns=if entry and entry.Mutable then (if competitive then 60 else 20) else 0
    end
    if winner then
        local entry=self.Data:get(winner.Player)
        local id=entry and entry.Profile.EquippedCosmetics.Victory
        local cosmetic=id and Config.Cosmetics[id]
        if cosmetic and entry.Profile.OwnedCosmetics[id] then self.Result.VictoryColor=cosmetic.Color end
    end
    self:effect("Results",self.Result)
    if self.Map.Model then for _,r in self.Records do pcall(function() r.Player:RemoveReplicationFocus(self.Map.Model.PrimaryPart) end) end end
    self.Map:unload();self:state("Results",Config.Results)
    self.Data:autosave()
end
function Game:send(player)
    local r=self.Records[player.UserId];if not r or not player.Parent then return end
    local living={}
    for _,record in self.Records do if record.Status=="Active" then table.insert(living,{Id=record.Player.UserId,Name=record.Player.DisplayName}) end end
    table.sort(living,function(a,b) return a.Id<b.Id end)
    self.Remotes.State:FireClient(player,{Version=Config.Version,State=self.State,StateVersion=self.StateVersion,Deadline=self.Deadline,ServerNow=workspace:GetServerTimeNow(),MatchId=self.MatchId,RoundId=self.RoundId,RoundIndex=self.RoundIndex,
        Mode=self.Current and self.Current.Mode or "Lobby",Map=self.Map.Info and self.Map.Info.Name or "ROYAL RUSH",Quota=self.Current and self.Current.Quota or 0,Qualified=self.Round and #self.Round.Order or 0,Alive=#living,Living=living,
        Status=r.Status,Queued=r.Queued,Power=r.LockedPower or "Dash",Cooldown=r.Cooldown or 0,Chaos=self.Chaos:view(),Data=self.Data:view(player),Result=self.Result,Board=self.Lobby.Board,Solo=self.Solo==true,Competitive=self.Competitive==true})
end
function Game:broadcast() for _,r in self.Records do self:send(r.Player) end end
function Game:action(player,payload)
    if not RequestValidation.valid(payload) then return end
    local now=workspace:GetServerTimeNow();local action=payload.Action
    if not self.Limiter:allow(player.UserId,action,now) then return end
    local r=self.Records[player.UserId];if not r then return end
    local function done(ok,message) if player.Parent then self:toast(player,message);self:send(player) end end
    if action=="Sync" then self:send(player)
    elseif action=="Ready" then if payload.RoundId==self.RoundId and r.Status=="Preparing" then r.StreamReady=true end
    elseif action=="Power" then
        if activeStates[self.State] and r.Status=="Active" then local ok,message=Power.activate(r,now,function(name,data) self:effect(name,data) end);if ok then self:stat(r,"PowerUses",self.RoundId..":power:"..now..":"..player.UserId) else self:toast(player,message) end;self:send(player)
        elseif r.Status=="Lobby" or r.Status=="Eliminated" or r.Status=="Qualified" then
            local status=r.Status;local entry=self.Data:get(player)
            r.LockedPower=entry and entry.Profile.SelectedPower or "Dash";r.Status="Active"
            local ok,message=Power.activate(r,now,function(name,data) self:effect(name,data) end);r.Status=status
            if not ok then self:toast(player,message) end;self:send(player)
        end
    elseif action=="Queue" then
        if r.Status=="Active" or r.Status=="Preparing" then self:toast(player,"Leave the round first")
        elseif type(payload.Enabled)=="boolean" then r.Queued=payload.Enabled;self:send(player) end
    elseif action=="Lobby" then
        if r.Status=="Active" then r.Queued=false;self:queueDeath(r,"Returned to lobby")
        elseif r.Status=="Preparing" then r.Queued=false;r.Status="Eliminated";self:toLobby(r);self:send(player)
        else self:toLobby(r);self:send(player) end
    elseif action=="Loadout" then
        if type(payload.Id)~="string" or not Config.Powers[payload.Id] then return end
        if table.find(self.Roster,player.UserId) and self.State~="Waiting" and self.State~="Intermission" and self.State~="Results" then self:toast(player,"Loadout locked until this match ends");return end
        self.Data:submit(player,function(p) p.SelectedPower=payload.Id;return true,"Selected "..Config.Powers[payload.Id].Name end,false,done)
    elseif action=="Buy" or action=="Equip" then
        if type(payload.Id)~="string" or #payload.Id>64 then return end
        if r.Status=="Active" or r.Status=="Preparing" then self:toast(player,"Use the shop in the lobby");return end
        self.Data:submit(player,function(p) if action=="Buy" then return Profile.buy(p,payload.Id) else return Profile.equip(p,payload.Id) end end,true,function(ok,message) if ok and action=="Buy" then Analytics.log(player,"purchase") end;done(ok,message) end)
    elseif action=="Daily" then self.Data:submit(player,function(p,day) return Profile.claimDaily(p,day) end,true,function(ok,message) if ok then Analytics.log(player,"daily_claimed") end;done(ok,message) end)
    elseif action=="Quest" then if type(payload.Id)=="string" and #payload.Id<64 then self.Data:submit(player,function(p,day) return Profile.claimQuest(p,payload.Id,day) end,true,done) end
    elseif action=="Settings" then
        if type(payload.Settings)~="table" then return end
        self.Data:submit(player,function(p) return Profile.settings(p,payload.Settings) end,false,done)
    elseif action=="Tutorial" then self.Data:submit(player,function(p) p.TutorialVersion=1;return true,"Ready for the Crown" end,false);Analytics.log(player,"tutorial_complete") end
end
function Game:tick(dt)
    if self.Stopped then return end
    local now=workspace:GetServerTimeNow();local ready=self:ready()
    local minimum=if RunService:IsStudio() and Config.StudioSolo then 1 else Config.MinPlayers
    if self.State=="Waiting" and #ready>=minimum then self.Current=nil;self.Round=nil;self.Solo=#ready==1 and minimum==1;self:state("Intermission",Config.Intermission)
    elseif self.State=="Intermission" then
        if #ready<minimum then self:state("Waiting",0)
        elseif now>=self.Deadline then self:beginMatch(ready) end
    elseif self.State=="Preparing" then
        local allReady=true
        for _,id in self.Roster do local r=self.Records[id];if not r or not r.StreamReady then allReady=false end end
        if allReady or now>=self.Deadline then self:state("RoundIntro",Config.Intro) end
    elseif self.State=="RoundIntro" and now>=self.Deadline then self:activate()
    elseif activeStates[self.State] then self:tickRound(now,dt)
    elseif self.State=="Transition" and now>=self.Deadline then self:nextRound()
    elseif self.State=="Results" and now>=self.Deadline then self.Roster={};self.Round=nil;self.Current=nil;self:state("Waiting",0) end
    if now>=self.NextSnapshot then self.NextSnapshot=now+0.5;self:broadcast() end
    if now-self.LastSave>=Config.Persistence.Autosave then self.LastSave=now;self.Data:autosave() end
    if now-self.LastBoard>=60 then self.LastBoard=now;self.Lobby:refresh(self.Records,self.Data) end
end
function Game:start()
    table.insert(self.Connections,self.Remotes.Action.OnServerEvent:Connect(function(player,payload) local ok,err=pcall(function() self:action(player,payload) end);if not ok then warn("[Royal Rush] Action failed: "..tostring(err)) end end))
    table.insert(self.Connections,Players.PlayerAdded:Connect(function(player) self:add(player) end))
    table.insert(self.Connections,Players.PlayerRemoving:Connect(function(player) self:remove(player) end))
    for _,player in Players:GetPlayers() do self:add(player) end
    local accumulated=0
    table.insert(self.Connections,RunService.Heartbeat:Connect(function(dt)
        accumulated+=dt
        if accumulated>=Config.Tick then local elapsed=accumulated;accumulated=0;local ok,err=pcall(function() self:tick(elapsed) end);if not ok then warn("[Royal Rush] Server tick: "..tostring(err)) end end
    end))
    game:BindToClose(function() self.Stopped=true;self.Chaos:stop();self.Data:close() end)
    print("[Royal Rush] "..Config.Version.." • standard movement + server result validation")
end
return Game
