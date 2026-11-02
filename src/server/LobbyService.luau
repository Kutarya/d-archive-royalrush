local Players=game:GetService("Players")
local DataStoreService=game:GetService("DataStoreService")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local Lobby={};Lobby.__index=Lobby
function Lobby.new()
    local store
    if not RunService:IsStudio() then pcall(function() store=DataStoreService:GetOrderedDataStore("RoyalRush_Wins_v1") end) end
    return setmetatable({Model=workspace:WaitForChild("RoyalRushLobby"),Board={},Store=store,Names={},Published={},King=nil},Lobby)
end
function Lobby:spawn(slot) local p=Vector3.new(((slot or 1)%4-1.5)*5,39,-31+math.floor((slot or 1)/4)*3);return CFrame.lookAt(p,p+Vector3.zAxis) end
function Lobby:clearKing()
    if self.King then self.King:Destroy();self.King=nil end
end
function Lobby:showKing(player)
    self:clearKing()
    local character=player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local archivable=character.Archivable;character.Archivable=true;local clone=character:Clone();character.Archivable=archivable
    clone.Name="ServerKing";clone.Parent=self.Model;clone:PivotTo(self.Model.Throne.KingSpot.CFrame)
    for _,p in clone:GetDescendants() do
        if p:IsA("Script") or p:IsA("LocalScript") or p:IsA("ModuleScript") or p:IsA("Tool") then p:Destroy()
        elseif p:IsA("BasePart") then p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Massless=true end
    end
    clone.HumanoidRootPart.Anchored=true
    local head=clone:FindFirstChild("Head")
    if head then
        local function crownPart(class,size,offset)
            local p=Instance.new(class);p.Name="RoyalCrown";p.Size=size;p.CFrame=head.CFrame*CFrame.new(offset);p.Color=Color3.fromRGB(255,207,76);p.Material=Enum.Material.Metal;p.CanCollide=false;p.CanTouch=false;p.Massless=true;p.Parent=clone
            local weld=Instance.new("WeldConstraint");weld.Part0=head;weld.Part1=p;weld.Parent=p
        end
        crownPart("Part",Vector3.new(2,0.3,2),Vector3.new(0,0.7,0))
        for i=-2,2 do crownPart("WedgePart",Vector3.new(0.4,0.9,0.6),Vector3.new(i*0.4,1.2,0)) end
    end
    local humanoid=clone:FindFirstChildOfClass("Humanoid");if humanoid then humanoid.DisplayName="KING • "..player.DisplayName end
    self.King=clone
    -- Original procedural celebration; no external animation asset is required.
    task.spawn(function()
        local shoulder
        for _,joint in clone:GetDescendants() do if joint:IsA("Motor6D") and (joint.Name=="RightShoulder" or joint.Name=="Right Shoulder") then shoulder=joint;break end end
        if shoulder then
            local start=shoulder.C0
            for i=1,6 do
                if not clone.Parent or not shoulder.Parent then break end
                local tween=TweenService:Create(shoulder,TweenInfo.new(0.3),{C0=start*CFrame.Angles(0,0,math.rad(if i%2==1 then -135 else -100))})
                tween:Play();task.wait(0.35)
            end
            if shoulder.Parent then shoulder.C0=start end
        end
    end)
end
function Lobby:publish(player,entry)
    if not self.Store or not entry.Mutable or entry.Status~="Saved" or entry.Profile.Wins==(self.Published[player.UserId] or -1) then return end
    local wins=entry.Profile.Wins;self.Published[player.UserId]=wins
    task.spawn(function()
        local ok=pcall(function() self.Store:UpdateAsync(tostring(player.UserId),function(old) return math.max(old or 0,wins) end) end)
        if not ok then self.Published[player.UserId]=nil end
    end)
end
function Lobby:refresh(records,data)
    if not self.Store then
        local board={}
        for _,record in records do local entry=data:get(record.Player);if entry then table.insert(board,{Name=record.Player.DisplayName,Wins=entry.Profile.LocalWins,Local=true}) end end
        table.sort(board,function(a,b) return a.Wins>b.Wins end);self.Board=board;return
    end
    task.spawn(function()
        local ok,page=pcall(function() return self.Store:GetSortedAsync(false,10) end)
        if not ok then return end
        local board={}
        for _,entry in page:GetCurrentPage() do
            local id=tonumber(entry.key)
            if id then
                local name=self.Names[id]
                if not name then local success,value=pcall(function() return Players:GetNameFromUserIdAsync(id) end);name=if success then value else "Player";self.Names[id]=name end
                table.insert(board,{Name=name,Wins=entry.value})
            end
        end
        self.Board=board
    end)
end
return Lobby
