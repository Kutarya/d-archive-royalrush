local RS=game:GetService("ReplicatedStorage")
local Config=require(RS.RoyalRush.Config)
local Cosmetics={}
function Cosmetics.apply(character,profile,streak)
    Cosmetics.clearAttachments(character)
    local old=character:FindFirstChild("RoyalCosmetics");if old then old:Destroy() end
    local folder=Instance.new("Folder");folder.Name="RoyalCosmetics";folder.Parent=character
    local root=character:FindFirstChild("HumanoidRootPart");local head=character:FindFirstChild("Head")
    if not root then return end
    for kind,id in profile.EquippedCosmetics do
        local item=Config.Cosmetics[id]
        if item and profile.OwnedCosmetics[id] then
            if kind=="Trail" then
                local a=Instance.new("Attachment");a.Position=Vector3.new(0,0.6,0.8);a.Parent=root
                local b=Instance.new("Attachment");b.Position=Vector3.new(0,-0.6,0.8);b.Parent=root
                a.Name="RoyalTrailA";b.Name="RoyalTrailB"
                local trail=Instance.new("Trail");trail.Attachment0=a;trail.Attachment1=b;trail.Lifetime=0.3;trail.MinLength=0.15;trail.Color=ColorSequence.new(Color3.fromRGB(unpack(item.Color)));trail.Transparency=NumberSequence.new(0.3,1);trail.Parent=folder
            elseif kind=="Aura" then
                local highlight=Instance.new("Highlight");highlight.Adornee=character;highlight.FillTransparency=1;highlight.OutlineTransparency=0.55;highlight.OutlineColor=Color3.fromRGB(unpack(item.Color));highlight.Parent=folder
            elseif kind=="Title" and head then
                local gui=Instance.new("BillboardGui");gui.Size=UDim2.fromOffset(190,30);gui.StudsOffset=Vector3.new(0,2.2,0);gui.Adornee=head;gui.MaxDistance=100;gui.Parent=folder
                local text=Instance.new("TextLabel");text.Size=UDim2.fromScale(1,1);text.BackgroundTransparency=1;text.Text=item.Name..(if streak>0 then "  • "..streak.." STREAK" else "");text.Font=Enum.Font.GothamBold;text.TextSize=13;text.TextColor3=Color3.fromRGB(255,214,88);text.TextStrokeTransparency=0.5;text.Parent=gui
            end
        end
    end
end
function Cosmetics.clearAttachments(character)
    local root=character and character:FindFirstChild("HumanoidRootPart")
    if root then for _,p in root:GetChildren() do if p.Name=="RoyalTrailA" or p.Name=="RoyalTrailB" then p:Destroy() end end end
end
return Cosmetics
