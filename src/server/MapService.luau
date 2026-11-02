local RS=game:GetService("ReplicatedStorage")
local ServerStorage=game:GetService("ServerStorage")
local Catalog=require(RS.RoyalRush.MapCatalog)
local Util=require(RS.RoyalRush.Util)
local Motion=require(RS.RoyalRush.ObstacleMotion)
local Power=require(script.Parent.PowerService)
local Map={};Map.__index=Map
local ORIGIN=CFrame.new(0,120,700)
function Map.new() return setmetatable({Model=nil,Obstacles={},Optional={},Falls={},Event=nil},Map) end
function Map:load(id)
    self:unload()
    local template=ServerStorage:WaitForChild("RoyalRushMaps"):FindFirstChild(id)
    assert(template and Catalog[id],"Map template missing: "..id)
    self.Model=template:Clone();self.Model.Name="RoyalRushArena";self.Model.Parent=workspace;self.Model:PivotTo(ORIGIN)
    self.Id=id;self.Info=Catalog[id];self.RequiredGates=self.Model:GetAttribute("RequiredGates") or 0
    self.Gates=self.Model.Checkpoints:GetChildren();table.sort(self.Gates,function(a,b) return a:GetAttribute("Index")<b:GetAttribute("Index") end)
    self.Spawns=self.Model.Spawns:GetChildren();table.sort(self.Spawns,function(a,b) return a:GetAttribute("Slot")<b:GetAttribute("Slot") end)
    for _,o in self.Model.Obstacles:GetChildren() do
        local body=o:FindFirstChild("Body")
        if body then
            body:SetAttribute("MotionBase",body.CFrame)
            if body:GetAttribute("Carry") or body:GetAttribute("Conveyor") then body.CustomPhysicalProperties=PhysicalProperties.new(1,0.9,0,100,0) end
            table.insert(self.Obstacles,{Model=o,Body=body,Base=body.CFrame,Kind=o:GetAttribute("ObstacleType"),Period=o:GetAttribute("Period") or 7,Phase=o:GetAttribute("Phase") or 0,Distance=o:GetAttribute("Distance") or 4})
        end
    end
    for _,p in self.Model:GetDescendants() do
        if p:IsA("BasePart") and p:GetAttribute("EventOptional") then
            table.insert(self.Optional,{Part=p,Color=p.Color,Material=p.Material,Transparency=p.Transparency,Collide=p.CanCollide})
        end
    end
    self.Finish=self.Model:FindFirstChild("Finish");self.Lava=self.Model:FindFirstChild("Lava")
    self.LavaHeight=-14
    return self.Info
end
function Map:spawn(slot) local position=self.Spawns[(slot-1)%#self.Spawns+1].Position;return CFrame.lookAt(position,position+Vector3.zAxis) end
function Map:checkpoint(index)
    for _,p in self.Model.CheckpointSpawns:GetChildren() do if p:GetAttribute("Index")==index then return CFrame.lookAt(p.Position,p.Position+Vector3.zAxis) end end
    return self:spawn(1)
end
function Map:localPosition(position) return ORIGIN:PointToObjectSpace(position) end
function Map:box(part,a,b,padding)
    if not part then return false end
    return Util.sweptBox(part.CFrame:PointToObjectSpace(a),part.CFrame:PointToObjectSpace(b),part.Size/2+(padding or Vector3.new(1,2,1)))
end
function Map:progress(record,previous,position)
    for _,gate in self.Gates do
        local index=gate:GetAttribute("Index")
        if index==record.Checkpoint+1 and self:box(gate,previous,position,Vector3.new(1,1,1)) then record.Checkpoint=index end
    end
    return record.Checkpoint>=self.RequiredGates and self:box(self.Finish,previous,position)
end
function Map:setEvent(id,now)
    self.Event=if id then {Id=id,Started=now} else nil
    self.Falls={}
    for _,entry in self.Optional do
        local p=entry.Part;p.Color=entry.Color;p.Material=entry.Material;p.Transparency=entry.Transparency;p.CanCollide=entry.Collide
    end
end
function Map:_fall(part,now,delay)
    if not self.Falls[part] then self.Falls[part]={Drop=now+delay,Restore=now+delay+5,Color=part.Color,Transparency=part.Transparency} end
end
function Map:update(elapsed,dt,records,now,overtime)
    if not self.Model then return end
    for _,o in self.Obstacles do
        local body=o.Body
        local cframe,velocity,inactive=Motion.sample(o.Kind,o.Base,elapsed,o.Period,o.Phase,o.Distance)
        body.CFrame=cframe
        if o.Kind=="DoorTiming" or o.Kind=="LaserGate" then
            o.Inactive=inactive;body.Transparency=if inactive then 0.88 else 0.15;body:SetAttribute("Inactive",inactive)
        end
        if body:GetAttribute("Carry") then
            body.AssemblyLinearVelocity=velocity
        elseif body:GetAttribute("Conveyor") then
            body.AssemblyLinearVelocity=o.Base:VectorToWorldSpace(Vector3.new(0,0,o.Model:GetAttribute("BeltSpeed") or 6))
        end
        if body:GetAttribute("FallingTile") then
            for _,r in records do if r.Status=="Active" and r.Root and self:box(body,r.Root.Position,r.Root.Position) then self:_fall(body,now,1.5) end end
        end
    end
    local event=self.Event
    for _,entry in self.Optional do
        local p=entry.Part
        if p:GetAttribute("FallingTile") then
            for _,r in records do if r.Status=="Active" and r.Root and self:box(p,r.Root.Position,r.Root.Position) then self:_fall(p,now,1.5) end end
        end
    end
    if event then
        for index,entry in self.Optional do
            local p=entry.Part;local age=now-event.Started
            if event.Id=="VanishingPlatforms" then
                if index%2==0 then
                    p.Color=if age<2 then Color3.fromRGB(255,211,79) else entry.Color
                    p.Transparency=if age<2 then (0.15+0.25*math.abs(math.sin(age*9))) else 0.85;p.CanCollide=age<2
                end
            elseif event.Id=="WorldBreaking" then
                local drop=2.5+(index%5)*2
                p.Color=Color3.fromRGB(186,99,255);p.Transparency=if age<drop then 0.25 else 1;p.CanCollide=age<drop
            elseif event.Id=="FallingTiles" then
                for _,r in records do if r.Status=="Active" and r.Root and self:box(p,r.Root.Position,r.Root.Position) then self:_fall(p,now,1.7) end end
            end
        end
    end
    for part,state in self.Falls do
        if not part.Parent then self.Falls[part]=nil
        elseif now<state.Drop then part.Color=Color3.fromRGB(255,186,62)
        elseif now<state.Restore then part.CanCollide=false;part.Transparency=0.85
        else part.CanCollide=true;part.Color=state.Color;part.Transparency=state.Transparency;self.Falls[part]=nil end
    end
    if self.Lava then
        local speed=if self.Info.Mode=="Survival" then 0.12 elseif self.Info.Mode=="Final" then 0.48 else 0.4
        self.LavaHeight=-14+math.max(0,elapsed-10)*speed+(if overtime then math.max(0,elapsed-75)*0.12 else 0)
        if self.Info.Mode=="RisingDanger" then
            local safeDeck=self.Model.Core:FindFirstChild("CrownDeck")
            if safeDeck then self.LavaHeight=math.min(self.LavaHeight,self:localPosition(safeDeck.Position).Y+safeDeck.Size.Y/2-1.5) end
        end
        self.Lava.Position=ORIGIN.Position+Vector3.new(0,self.LavaHeight-0.6,0)
    end
end
function Map:hazard(record,now,previous)
    local root=record.Root;if not root then return nil end
    local position=root.Position;local localPos=self:localPosition(position)
    if localPos.Y<(self.Model:GetAttribute("MinY") or -18) then return "Void" end
    if math.abs(localPos.X)>(self.Model:GetAttribute("BoundsX") or 140) or localPos.Z>(self.Model:GetAttribute("BoundsZ") or 650) or localPos.Z< -160 then return "Out of arena" end
    if self.Lava and localPos.Y-2.5<=self.LavaHeight then return "Rising Lava" end
    for _,o in self.Obstacles do
        local p=o.Body
        if not o.Inactive and self:box(p,previous or position,position) then
            if p:GetAttribute("Eliminate") then return "Laser Gate" end
            if p:GetAttribute("Knockback") and now>(record.HitUntil or 0) then return nil,p.Position end
            if p:GetAttribute("JumpPad") and now>(record.PadUntil or 0) and record.Humanoid.FloorMaterial~=Enum.Material.Air then
                record.PadUntil=now+2;Power.velocity(record,58,0.1,Vector3.yAxis);record.MovementGrace=now+0.8
            elseif p:GetAttribute("Wind") and now>(record.WindUntil or 0) then
                record.WindUntil=now+0.25
                Power.velocity(record,record.Root.AssemblyLinearVelocity+Vector3.new(-3,0.5,0),0.08);record.MovementGrace=now+0.3
            end
        end
    end
    return nil
end
function Map:meteorTargets()
    local targets={}
    for _,p in self.Model.MeteorTargets:GetChildren() do
        local safe=true
        for _,gate in self.Gates do if (Vector3.new(p.Position.X,0,p.Position.Z)-Vector3.new(gate.Position.X,0,gate.Position.Z)).Magnitude<15 then safe=false end end
        if self.Finish and (p.Position-self.Finish.Position).Magnitude<25 then safe=false end
        if safe then table.insert(targets,p.Position) end
    end
    return targets
end
function Map:unload()
    if self.Model then self.Model:Destroy() end
    self.Model=nil;self.Info=nil;self.Id=nil;self.Finish=nil;self.Lava=nil;self.Obstacles={};self.Optional={};self.Falls={};self.Event=nil
end
return Map
