-- Small additive poses layered over Roblox's normal walk/jump Animate script.
-- No replacement animation IDs or server-side joint writes.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Motion={}
local bound={};local bursts={}
local function bind(character)
    task.spawn(function()
        local humanoid=character:WaitForChild("Humanoid",10)
        local root=character:WaitForChild("HumanoidRootPart",10)
        if not humanoid or not root or not character.Parent then return end
        local joints={}
        for _,joint in character:GetDescendants() do
            if joint:IsA("Motor6D") and (joint.Name=="Waist" or joint.Name=="RootJoint" or joint.Name=="RightShoulder" or joint.Name=="LeftShoulder") then
                joints[joint.Name]={Joint=joint,Base=joint.C0}
            end
        end
        bound[character]={Humanoid=humanoid,Root=root,Joints=joints,Lean=0}
    end)
end
function Motion.power(data)
    if data.Id=="Dash" or data.Id=="DoubleJump" then bursts[data.UserId]={Id=data.Id,Ends=workspace:GetServerTimeNow()+0.28} end
end
function Motion.start(reduced)
    local function playerAdded(player)
        if player.Character then bind(player.Character) end
        player.CharacterAdded:Connect(bind)
    end
    for _,player in Players:GetPlayers() do playerAdded(player) end
    Players.PlayerAdded:Connect(playerAdded)
    RunService.PreSimulation:Connect(function(dt)
        local now=workspace:GetServerTimeNow()
        for character,entry in bound do
            if not character.Parent or not entry.Root.Parent then bound[character]=nil;continue end
            local player=Players:GetPlayerFromCharacter(character)
            local burst=player and bursts[player.UserId]
            if burst and now>=burst.Ends then bursts[player.UserId]=nil;burst=nil end
            local disabled=reduced and reduced()
            local target=if disabled or entry.Humanoid.Health<=0 then 0 elseif burst and burst.Id=="Dash" then math.rad(-20) elseif burst then math.rad(8) else -math.rad(3)*entry.Humanoid.MoveDirection.Magnitude
            entry.Lean+=(target-entry.Lean)*(1-math.exp(-dt*22))
            for name,pose in entry.Joints do
                if pose.Joint.Parent then
                    local angle=if name=="Waist" or name=="RootJoint" then entry.Lean else (if burst and not disabled then -entry.Lean*1.3 else 0)
                    pose.Joint.C0=pose.Base*CFrame.Angles(angle,0,0)
                end
            end
        end
    end)
end
return Motion
