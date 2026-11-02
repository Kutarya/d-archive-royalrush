local Debris=game:GetService("Debris")
local Config=require(game:GetService("ReplicatedStorage").RoyalRush.Config)
local Util=require(game:GetService("ReplicatedStorage").RoyalRush.Util)
local Power={}
function Power.velocity(record,value,duration,axis)
    local root=record.Root
    local old=root:FindFirstChild("RoyalImpulse");if old then old:Destroy() end
    local oldAttachment=root:FindFirstChild("RoyalImpulseAttachment");if oldAttachment then oldAttachment:Destroy() end
    local attachment=Instance.new("Attachment");attachment.Name="RoyalImpulseAttachment";attachment.Parent=root
    local constraint=Instance.new("LinearVelocity");constraint.Name="RoyalImpulse";constraint.Attachment0=attachment;constraint.RelativeTo=Enum.ActuatorRelativeTo.World
    if axis then
        constraint.VelocityConstraintMode=Enum.VelocityConstraintMode.Line;constraint.LineDirection=axis;constraint.LineVelocity=value
    else constraint.VelocityConstraintMode=Enum.VelocityConstraintMode.Vector;constraint.VectorVelocity=value end
    constraint.ForceLimitsEnabled=false;constraint.Parent=root
    Debris:AddItem(constraint,duration);Debris:AddItem(attachment,duration+0.05)
end
function Power.clearShield(record)
    record.ShieldUntil=0
    local old=record.Character and record.Character:FindFirstChild("RoyalShield")
    if old then old:Destroy() end
end
function Power.reset(record)
    Power.clearShield(record)
    record.Cooldown=0;record.DoubleUsed=false;record.ShieldUntil=0;record.HitUntil=0
end
function Power.activate(record,now,effect)
    if record.Status~="Active" or not record.Root or not record.Humanoid or record.Humanoid.Health<=0 then return false,"Power unavailable" end
    local id=record.LockedPower or "Dash";local config=Config.Powers[id]
    if not config or now<(record.Cooldown or 0) then return false,"Cooling down" end
    local root=record.Root
    if id=="DoubleJump" then
        if record.DoubleUsed or record.Humanoid.FloorMaterial~=Enum.Material.Air then return false,"Use while airborne" end
        Power.velocity(record,config.Velocity,0.1,Vector3.yAxis)
        record.DoubleUsed=true;record.MovementGrace=now+0.8
    elseif id=="Dash" then
        local look=root.CFrame.LookVector;local direction=Vector3.new(look.X,0,look.Z)
        if not Util.finite(direction.X) or not Util.finite(direction.Z) then return false,"Invalid direction" end
        if direction.Magnitude<0.01 then return false,"No direction" end
        direction=direction.Unit
        local parameters=RaycastParams.new();parameters.FilterType=Enum.RaycastFilterType.Exclude;parameters.FilterDescendantsInstances={record.Character};parameters.RespectCanCollide=true
        -- Sweep the avatar's width, so a clear centre ray cannot dash its shoulder into a wall.
        local hit=workspace:Blockcast(CFrame.new(root.Position),Vector3.new(3,3,3),direction*config.Distance,parameters)
        local distance=if hit then math.max(0,hit.Distance-0.5) else config.Distance
        if distance<1 then return false,"Path blocked" end
        local attachment=Instance.new("Attachment");attachment.Name="RoyalDashAttachment";attachment.Parent=root
        local velocity=Instance.new("LinearVelocity");velocity.Name="RoyalDash";velocity.Attachment0=attachment;velocity.RelativeTo=Enum.ActuatorRelativeTo.World;velocity.VelocityConstraintMode=Enum.VelocityConstraintMode.Plane
        velocity.PrimaryTangentAxis=Vector3.xAxis;velocity.SecondaryTangentAxis=Vector3.zAxis;velocity.PlaneVelocity=Vector2.new(direction.X,direction.Z)*(distance/config.Duration);velocity.ForceLimitsEnabled=false;velocity.Parent=root
        Debris:AddItem(velocity,config.Duration);Debris:AddItem(attachment,config.Duration+0.05);record.MovementGrace=now+0.5
    elseif id=="Shield" then
        Power.clearShield(record);record.ShieldUntil=now+config.Duration
        local aura=Instance.new("Highlight");aura.Name="RoyalShield";aura.Adornee=record.Character;aura.FillColor=Color3.fromRGB(116,243,231);aura.OutlineColor=aura.FillColor;aura.FillTransparency=0.85;aura.OutlineTransparency=0.15;aura.Parent=record.Character;Debris:AddItem(aura,config.Duration)
    end
    record.Cooldown=now+config.Cooldown
    effect("Power",{UserId=record.Player.UserId,Id=id,Position=root.Position,Direction=root.CFrame.LookVector})
    return true,"Power activated"
end
function Power.knock(record,center,now)
    if now<(record.ShieldUntil or 0) then Power.clearShield(record);record.HitUntil=now+1;return false end
    if not record.Root then return false end
    local direction=record.Root.Position-center;direction=Vector3.new(direction.X,0,direction.Z)
    if direction.Magnitude<0.1 then direction=Vector3.new(1,0,0) end
    Power.velocity(record,direction.Unit*25+Vector3.new(0,15,0),0.12)
    record.HitUntil=now+1;record.MovementGrace=now+0.7
    return true
end
return Power
