local RunService=game:GetService("RunService")
local Motion=require(game:GetService("ReplicatedStorage").RoyalRush.ObstacleMotion)
local Surface={Entries={},Arena=nil,Connection=nil,Added=nil}
function Surface:_add(object)
    if not object:IsA("BasePart") or object.Name~="Body" then return end
    local model=object.Parent
    if not model or not model:GetAttribute("ObstacleType") then return end
    self.Entries[object]=model
end
function Surface:_arena(arena)
    if self.Added then self.Added:Disconnect();self.Added=nil end
    self.Entries={};self.Arena=arena
    if not arena then return end
    for _,object in arena:GetDescendants() do self:_add(object) end
    self.Added=arena.DescendantAdded:Connect(function(object) self:_add(object) end)
end
function Surface.start()
    if Surface.Connection then return end
    Surface.Connection=RunService.PreSimulation:Connect(function()
        local arena=workspace:FindFirstChild("RoyalRushArena")
        if arena~=Surface.Arena then Surface:_arena(arena) end
        if not arena then return end
        local start=arena:GetAttribute("RoundStartedAt")
        local elapsed=if start then math.max(0,workspace:GetServerTimeNow()-start) else 0
        for body,model in Surface.Entries do
            if not body.Parent then Surface.Entries[body]=nil;continue end
            local base=body:GetAttribute("MotionBase")
            if not base then continue end
            local kind=model:GetAttribute("ObstacleType")
            local cframe,velocity,inactive=Motion.sample(kind,base,elapsed,model:GetAttribute("Period"),model:GetAttribute("Phase"),model:GetAttribute("Distance"))
            if kind=="Conveyor" then
                -- Anchored surface velocity contributes to contact physics;
                -- never overwrite the player's velocity/input each frame.
                body.AssemblyLinearVelocity=base:VectorToWorldSpace(Vector3.new(0,0,model:GetAttribute("BeltSpeed") or 6))
            else
                body.CFrame=cframe
                if body:GetAttribute("Carry") then body.AssemblyLinearVelocity=velocity end
            end
            if kind=="DoorTiming" or kind=="LaserGate" then body.Transparency=if inactive then 0.88 else 0.15 end
        end
    end)
end
return Surface
