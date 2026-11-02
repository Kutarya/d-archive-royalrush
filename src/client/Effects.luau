local Debris=game:GetService("Debris")
local TweenService=game:GetService("TweenService")
local Effects={}
local function visual(shape,position,size,color)
    local p=Instance.new("Part");p.Name="RoyalRushLocalFX";p.Shape=shape;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Size=size;p.Position=position;p.Material=Enum.Material.Neon;p.Color=color;p.Transparency=0.35;p.Parent=workspace
    return p
end
function Effects.meteorWarning(data,low)
    local disc=visual(Enum.PartType.Cylinder,data.Position+Vector3.new(0,0.2,0),Vector3.new(0.15,data.Radius*2,data.Radius*2),Color3.fromRGB(255,74,72));disc.CFrame=CFrame.new(disc.Position)*CFrame.Angles(0,0,math.pi/2)
    Debris:AddItem(disc,2.5)
    if not low then
        local meteor=visual(Enum.PartType.Ball,data.Position+Vector3.new(0,55,0),Vector3.new(3,3,3),Color3.fromRGB(255,165,55))
        TweenService:Create(meteor,TweenInfo.new(2.2,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=data.Position}):Play();Debris:AddItem(meteor,2.25)
    end
end
function Effects.meteorHit(data,low)
    if low then return end
    local ball=visual(Enum.PartType.Ball,data.Position,Vector3.new(1,1,1),Color3.fromRGB(255,128,79))
    TweenService:Create(ball,TweenInfo.new(0.35),{Size=Vector3.new(10,5,10),Transparency=1}):Play();Debris:AddItem(ball,0.4)
end
function Effects.shock(data,warning)
    local ring=visual(Enum.PartType.Cylinder,data.Position,Vector3.new(0.1,2,2),Color3.fromRGB(188,111,255));ring.CFrame=CFrame.new(ring.Position)*CFrame.Angles(0,0,math.pi/2)
    TweenService:Create(ring,TweenInfo.new(if warning then 2 else 0.5),{Size=Vector3.new(0.1,110,110),Transparency=1}):Play();Debris:AddItem(ring,if warning then 2.1 else 0.6)
end
function Effects.power(data,low)
    if low then return end
    local color=if data.Id=="Shield" then Color3.fromRGB(105,244,221) else Color3.fromRGB(76,176,255)
    if data.Id=="Dash" then
        local direction=data.Direction or Vector3.zAxis
        for _,side in {-1,1} do
            local streak=visual(Enum.PartType.Block,data.Position,Vector3.new(0.12,0.12,7),color)
            streak.CFrame=CFrame.lookAt(data.Position,data.Position+direction)*CFrame.new(side*1.5,0,2)
            TweenService:Create(streak,TweenInfo.new(0.22),{Transparency=1,Size=Vector3.new(0.05,0.05,2)}):Play();Debris:AddItem(streak,0.25)
        end
    else
        local sphere=visual(Enum.PartType.Ball,data.Position,Vector3.new(2,2,2),color)
        TweenService:Create(sphere,TweenInfo.new(0.3),{Size=Vector3.new(4,4,4),Transparency=1}):Play();Debris:AddItem(sphere,0.35)
    end
end
function Effects.confetti(root,low,color)
    if low then return end
    for index=1,22 do
        local frame=Instance.new("Frame");frame.Name="Confetti";frame.Size=UDim2.fromOffset(6,10);frame.Position=UDim2.fromScale(math.random(),-0.05);frame.Rotation=math.random(0,360);frame.BackgroundColor3=if color and index%2==0 then Color3.fromRGB(unpack(color)) elseif index%2==0 then Color3.fromRGB(255,214,76) else Color3.fromRGB(183,112,255);frame.BorderSizePixel=0;frame.ZIndex=30;frame.Parent=root
        TweenService:Create(frame,TweenInfo.new(2.5+math.random()),{Position=UDim2.fromScale(math.random(),1.1),Rotation=frame.Rotation+180,BackgroundTransparency=1}):Play();Debris:AddItem(frame,4)
    end
end
return Effects
