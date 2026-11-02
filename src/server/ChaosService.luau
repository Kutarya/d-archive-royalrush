local RS=game:GetService("ReplicatedStorage")
local Config=require(RS.RoyalRush.Config)
local Selection=require(RS.RoyalRush.ChaosSelection)
local Power=require(script.Parent.PowerService)
local Chaos={};Chaos.__index=Chaos
function Chaos.new(map,context)
    return setmetatable({Map=map,Context=context,Current=nil,Pending=nil,Meteors={},History={},Neon={},ForceRoots={}},Chaos)
end
function Chaos:startRound(mode,index,seed,start)
    self:stop();self.Mode=mode;self.Index=index;self.RNG=Random.new(seed);self.Started=start;self.Token=self.Context:roundToken()
    self.NextAt=start+(if index==1 and mode=="Race" then 27 else 20)
    self.Remaining=if mode=="Final" or index==1 then 1 else 2
end
function Chaos:_effect(name,data) self.Context:effect(name,data) end
function Chaos:_modifier(record,active)
    if record.Status~="Active" then active=false end
    if record.Humanoid then record.Humanoid.WalkSpeed=if active and self.Current and self.Current.Id=="SuperSpeed" then Config.WalkSpeed*1.15 else Config.WalkSpeed end
    local root=record.Root
    if root and root.Parent then
        local force=root:FindFirstChild("RoyalLowGravity")
        local enabled=active and self.Current and self.Current.Id=="LowGravity"
        if enabled and not force then
            local attachment=Instance.new("Attachment");attachment.Name="RoyalGravityAttachment";attachment.Parent=root
            force=Instance.new("VectorForce");force.Name="RoyalLowGravity";force.Attachment0=attachment;force.RelativeTo=Enum.ActuatorRelativeTo.World;force.ApplyAtCenterOfMass=true;force.Parent=root;self.ForceRoots[root]=true
        end
        if enabled and force then force.Force=Vector3.new(0,root.AssemblyMass*workspace.Gravity*0.35,0)
        elseif force then force:Destroy();local a=root:FindFirstChild("RoyalGravityAttachment");if a then a:Destroy() end;self.ForceRoots[root]=nil end
    end
end
function Chaos:clearCharacter(record)
    self:_modifier(record,false)
    Power.clearShield(record)
    if record.Root then
        for _,name in {"RoyalDash","RoyalDashAttachment","RoyalLowGravity","RoyalGravityAttachment"} do local p=record.Root:FindFirstChild(name);if p then p:Destroy() end end
    end
end
function Chaos:_begin(id,now)
    local event=Config.Events[id]
    self.Current={Id=id,Name=event.Name,Ends=now+event.Duration,Started=now,NextHazard=now+1}
    table.insert(self.History,id);if #self.History>2 then table.remove(self.History,1) end
    if id=="VanishingPlatforms" or id=="FallingTiles" or id=="WorldBreaking" then self.Map:setEvent(id,now) end
    if id=="NeonMode" then
        for _,p in self.Map.Model.Decoration:GetDescendants() do
            if p:IsA("BasePart") and p.Transparency<1 then self.Neon[p]={Color=p.Color,Material=p.Material};p.Material=Enum.Material.Neon end
        end
    end
    self:_effect("ChaosStart",{Id=id,Name=event.Name,Ends=self.Current.Ends})
end
function Chaos:_end(now)
    local current=self.Current
    if current then
        if now>=current.Ends and Config.Events[current.Id].Cost>0 then
            for _,record in self.Context.Records do
                if record.Status=="Active" and (record.ActiveSeconds or 0)>=3 then self.Context:stat(record,"ChaosSurvived",self.Token..":chaos:"..current.Id..":"..current.Started) end
            end
        end
        self:_effect("ChaosEnd",{Id=current.Id})
    end
    self.Current=nil;self.Meteors={};self.Map:setEvent(nil,now)
    for part,saved in self.Neon do if part.Parent then part.Color=saved.Color;part.Material=saved.Material end end
    self.Neon={}
    for _,record in self.Context.Records do self:_modifier(record,false) end
end
function Chaos:update(now)
    if self.Token~=self.Context:roundToken() then self:stop();return end
    if self.Pending and now>=self.Pending.Starts then local id=self.Pending.Id;self.Pending=nil;self:_begin(id,now) end
    local current=self.Current
    if current and now>=current.Ends then self:_end(now);self.NextAt=now+6;current=nil end
    if not current and not self.Pending and self.Remaining>0 and now>=self.NextAt then
        local id=if self.Index==1 and self.Mode=="Race" and self.Context.MatchNumber==1 then "LowGravity" else Selection.choose(self.Mode,self.Map.Info.Tags,self.Context:activeCount(),{},if self.Mode=="Final" then 1 else 2,self.History,function() return self.RNG:NextNumber() end)
        self.Remaining-=1
        if id then self.Pending={Id=id,Starts=now+3};self:_effect("ChaosWarning",{Name=Config.Events[id].Name,Starts=now+3}) end
    end
    for _,record in self.Context.Records do if record.Status=="Active" then self:_modifier(record,true) end end
    if not current then return end
    if current.Id=="MeteorShower" and now>=current.NextHazard then
        current.NextHazard=now+2.5
        local targets=self.Map:meteorTargets()
        if #targets>0 then
            local position=targets[self.RNG:NextInteger(1,#targets)]
            local meteor={Position=position,Hits=now+2.2,Radius=5}
            table.insert(self.Meteors,meteor);self:_effect("MeteorWarning",meteor)
        end
    elseif current.Id=="Shockwave" and now>=current.NextHazard then
        current.NextHazard=now+5
        local center=self.Map.Model.PrimaryPart.Position+Vector3.new(0,2,0)
        self.Shock={Center=center,Hits=now+2,Warned=true}
        self:_effect("ShockwaveWarning",{Position=center,Hits=now+2,Radius=55})
    end
    for index=#self.Meteors,1,-1 do
        local meteor=self.Meteors[index]
        if now>=meteor.Hits then
            for _,record in self.Context.Records do
                if record.Status=="Active" and record.Root then
                    local delta=record.Root.Position-meteor.Position
                    if Vector2.new(delta.X,delta.Z).Magnitude<=meteor.Radius+1 and math.abs(delta.Y)<=7 then self.Context:queueDeath(record,"Meteor") end
                end
            end
            self:_effect("MeteorHit",meteor);table.remove(self.Meteors,index)
        end
    end
    if self.Shock and now>=self.Shock.Hits then
        for _,record in self.Context.Records do
            if record.Status=="Active" and record.Root and record.Humanoid.FloorMaterial~=Enum.Material.Air and (record.Root.Position-self.Shock.Center).Magnitude<60 then Power.knock(record,self.Shock.Center,now) end
        end
        self:_effect("ShockwaveHit",{Position=self.Shock.Center});self.Shock=nil
    end
end
function Chaos:stop()
    self.Pending=nil;self.Remaining=0;self.Shock=nil;self:_end(workspace:GetServerTimeNow())
    for root in self.ForceRoots do
        if root.Parent then for _,name in {"RoyalLowGravity","RoyalGravityAttachment"} do local p=root:FindFirstChild(name);if p then p:Destroy() end end end
    end
    self.ForceRoots={};self.Token=nil
end
function Chaos:view()
    if self.Pending then return {Name="CHAOS INCOMING",Next=self.Pending.Starts,Id=self.Pending.Id} end
    if self.Current then return {Name=self.Current.Name,Ends=self.Current.Ends,Id=self.Current.Id} end
    return nil
end
return Chaos
