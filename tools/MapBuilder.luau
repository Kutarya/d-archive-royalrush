-- Offline authoring: real Roblox Instances serialized by Lune, no running Studio required.
local R=require("@lune/roblox")
local V,C,CF,E,I=R.Vector3,R.Color3,R.CFrame,R.Enum,R.Instance
local Builder={}
local palette={Gold=C.fromRGB(255,201,73),White=C.fromRGB(225,237,255),Blue=C.fromRGB(96,154,226),Dark=C.fromRGB(29,36,55),Purple=C.fromRGB(156,96,247),Red=C.fromRGB(246,80,58),Green=C.fromRGB(75,221,161),Cyan=C.fromRGB(71,216,246)}
local function folder(parent,name)
    local object=I.new("Folder");object.Name=name;object.Parent=parent;return object
end
local function model(parent,name)
    local object=I.new("Model");object.Name=name;object.Parent=parent;return object
end
local function part(parent,name,size,position,color,material,shape)
    local p=I.new("Part");p.Name=name;p.Size=size;p.CFrame=CF.new(position);p.Anchored=true
    p.Color=color or palette.White;p.Material=material or E.Material.SmoothPlastic
    p.TopSurface=E.SurfaceType.Smooth;p.BottomSurface=E.SurfaceType.Smooth
    if shape then p.Shape=shape end
    p.Parent=parent;return p
end
local function text(parent,position,title,subtitle,color)
    local anchor=part(parent,"Sign_"..title,V.new(1,1,1),position,palette.Dark)
    anchor.Transparency=1;anchor.CanCollide=false;anchor.CanQuery=false
    local gui=I.new("BillboardGui");gui.Name="Label";gui.Size=R.UDim2.fromOffset(260,64);gui.StudsOffset=V.new(0,0,0);gui.MaxDistance=85;gui.AlwaysOnTop=false;gui.Parent=anchor
    local label=I.new("TextLabel");label.Size=R.UDim2.fromScale(1,0.65);label.BackgroundTransparency=1;label.Text=title;label.TextColor3=color or palette.Gold;label.TextStrokeTransparency=0.55;label.FontFace=R.Font.new("rbxasset://fonts/families/SourceSansPro.json",E.FontWeight.Bold,E.FontStyle.Normal);label.TextSize=27;label.Parent=gui
    local sub=I.new("TextLabel");sub.Position=R.UDim2.fromScale(0,0.65);sub.Size=R.UDim2.fromScale(1,0.35);sub.BackgroundTransparency=1;sub.Text=subtitle or "";sub.TextColor3=palette.White;sub.FontFace=R.Font.new("rbxasset://fonts/families/SourceSansPro.json",E.FontWeight.Regular,E.FontStyle.Normal);sub.TextSize=16;sub.Parent=gui
    return anchor
end
local function crown(parent,center,scale)
    local m=model(parent,"Crown")
    part(m,"Band",V.new(6,1.2,4)*scale,center,palette.Gold,E.Material.Metal)
    for i=-2,2 do
        local p=I.new("WedgePart");p.Name="Point";p.Size=V.new(1.2,3+(if i==0 then 1 else 0),2)*scale;p.CFrame=CF.new(center+V.new(i*1.2,2,0)*scale);p.Anchored=true;p.CanCollide=false;p.Color=palette.Gold;p.Material=E.Material.Metal;p.Parent=m
    end
    for _,p in m:GetChildren() do if p:IsA("BasePart") then p.CanCollide=false end end
    return m
end
local function architecture(parent,center,theme,height)
    local color=if theme=="NeonCity" then palette.Dark elseif theme=="LavaFactory" then C.fromRGB(61,65,80) else palette.White
    local shaft=part(parent,"Tower",V.new(12,height,12),center+V.new(0,height/2,0),color,E.Material.Concrete)
    shaft.CanCollide=false
    part(parent,"Cornice",V.new(15,2,15),center+V.new(0,height,0),if theme=="NeonCity" then palette.Purple else palette.Gold,E.Material.Metal).CanCollide=false
    if theme=="NeonCity" then
        for y=4,height-3,8 do part(parent,"Window",V.new(12.1,2,12.1),center+V.new(0,y,0),palette.Cyan,E.Material.Neon).CanCollide=false end
    else
        for _,x in {-4,0,4} do part(parent,"Battlement",V.new(2,3,12),center+V.new(x,height+2,0),color,E.Material.Concrete).CanCollide=false end
    end
end
local function base(name,theme,mode)
    local map=model(nil,name)
    local origin=part(map,"Origin",V.new(1,1,1),V.zero,palette.Dark)
    origin.Transparency=1;origin.CanCollide=false;origin.CanQuery=false;map.PrimaryPart=origin
    map:SetAttribute("Theme",theme);map:SetAttribute("Mode",mode);map:SetAttribute("MinY",-18);map:SetAttribute("RequiredGates",0)
    for _,name_ in {"Core","Optional","Spawns","Checkpoints","CheckpointSpawns","Obstacles","Decoration","MeteorTargets"} do folder(map,name_) end
    return map
end
local function trigger(parent,name,size,center,index)
    local p=part(parent,name,size,center,palette.Green);p.Transparency=1;p.CanCollide=false
    if index then p:SetAttribute("Index",index) end
    return p
end
local function spawns(map,center,spacing)
    for i=1,16 do
        local x=((i-1)%4-1.5)*(spacing or 5);local z=(math.floor((i-1)/4)-1.5)*4
        local p=trigger(map.Spawns,"Spawn"..i,V.new(1,1,1),center+V.new(x,0,z));p:SetAttribute("Slot",i)
    end
end
local function checkpoint(map,index,center)
    trigger(map.Checkpoints,"Gate"..index,V.new(54,22,12),center+V.new(0,8,0),index)
    trigger(map.CheckpointSpawns,"Checkpoint"..index,V.new(1,1,1),center+V.new(0,4,0),index)
    part(map.Decoration,"CheckpointStripe",V.new(40,0.1,1),center+V.new(0,1.06,0),palette.Green,E.Material.Neon).CanCollide=false
end
local function obstacle(map,kind,center,index,theme)
    local m=model(map.Obstacles,kind..index);m:SetAttribute("ObstacleType",kind);m:SetAttribute("Period",7);m:SetAttribute("Phase",index*0.8);m:SetAttribute("Distance",4)
    local origin=part(m,"Origin",V.new(1,1,1),center,palette.Dark);origin.Transparency=1;origin.CanCollide=false;origin.CanQuery=false;m.PrimaryPart=origin
    local danger=palette.Red
    if kind=="MovingPlatform" then
        local body=part(m,"Body",V.new(36,2,20),center,if theme=="NeonCity" then palette.Cyan else palette.Blue);body:SetAttribute("Carry",true)
    elseif kind=="RotatingBeam" or kind=="Spinner" then
        part(m,"Pedestal",V.new(3,2,3),center,palette.Gold,E.Material.Metal).CanCollide=false
        local beam=part(m,"Body",V.new(26,1.5,2),center+V.new(0,3,0),danger,E.Material.Neon);beam.CanCollide=false;beam:SetAttribute("Knockback",true)
    elseif kind=="DoorTiming" or kind=="LaserGate" then
        for _,x in {-11,11} do part(m,"Post",V.new(2,12,3),center+V.new(x,5,0),palette.Dark,E.Material.Metal).CanCollide=false end
        local door=part(m,"Body",V.new(20,10,1.5),center+V.new(0,5,0),danger,if kind=="LaserGate" then E.Material.Neon else E.Material.Metal)
        door.CanCollide=false;door:SetAttribute(if kind=="LaserGate" then "Eliminate" else "Knockback",true)
    elseif kind=="Conveyor" then
        local body=part(m,"Body",V.new(30,0.15,18),center+V.new(0,1.05,0),palette.Dark,E.Material.Metal);body:SetAttribute("Conveyor",true);m:SetAttribute("BeltSpeed",6)
        for z=-6,6,4 do part(m,"Stripe",V.new(28,0.06,0.6),center+V.new(0,1.15,z),palette.Gold,E.Material.Neon).CanCollide=false end
    elseif kind=="JumpPad" then
        local body=part(m,"Body",V.new(7,0.2,5),center+V.new(-5,1.1,0),palette.Cyan,E.Material.Neon);body:SetAttribute("JumpPad",true)
    elseif kind=="PushWall" or kind=="Crusher" then
        local body=part(m,"Body",V.new(3,8,4),center+V.new(12,5,0),danger,E.Material.Metal);body.CanCollide=false;body:SetAttribute("Knockback",true)
    elseif kind=="SwingHammer" then
        local body=part(m,"Body",V.new(5,5,5),center+V.new(0,6,0),danger,E.Material.Metal);body.CanCollide=false;body:SetAttribute("Knockback",true)
        part(m,"Support",V.new(1,14,1),center+V.new(12,7,0),palette.Gold,E.Material.Metal).CanCollide=false
    elseif kind=="RollingBall" then
        local body=part(m,"Body",V.new(6,6,6),center+V.new(0,4,0),danger,E.Material.Metal,E.PartType.Ball);body.CanCollide=false;body:SetAttribute("Knockback",true)
    elseif kind=="FanWind" then
        local body=part(m,"Body",V.new(9,8,9),center+V.new(7,5,0),palette.Cyan,E.Material.ForceField);body.Transparency=0.8;body.CanCollide=false;body:SetAttribute("Wind",true)
    elseif kind=="Elevator" then
        local body=part(m,"Body",V.new(10,2,10),center+V.new(26,2,0),palette.Gold,E.Material.Metal);body:SetAttribute("Carry",true)
    elseif kind=="ThinBridge" then
        part(m,"Body",V.new(8,1,26),center+V.new(27,1,0),palette.Gold,E.Material.Metal)
    elseif kind=="FallingTile" then
        local body=part(m,"Body",V.new(10,2,12),center+V.new(-28,0,0),palette.Purple);body:SetAttribute("FallingTile",true);body:SetAttribute("EventOptional",true)
    end
    return m
end
local obstacleOrder={"RotatingBeam","MovingPlatform","Spinner","DoorTiming","Conveyor","JumpPad","PushWall","FallingTile","ThinBridge","Elevator","SwingHammer","Crusher","LaserGate","RollingBall","FanWind"}
function Builder.race(name,theme,count)
    local map=base(name,theme,"Race")
    map:SetAttribute("BoundsX",120);map:SetAttribute("BoundsZ",count*32+100);map:SetAttribute("StageCount",count)
    part(map.Core,"Start",V.new(56,2,40),V.new(0,1,7),if theme=="NeonCity" then palette.Dark else palette.White)
    spawns(map,V.new(0,5,4))
    text(map.Decoration,V.new(0,16,8),if theme=="NeonCity" then "NEON CITY" else "SKY KINGDOM","REACH THE FINISH",palette.Gold)
    local gate=0;local z=16;local routeIndex=0
    map.Core.Start:SetAttribute("RouteIndex",0)
    local floorColor=if theme=="NeonCity" then palette.Dark else palette.White
    for index=1,count do
        z+=24;routeIndex+=1
        local center=V.new(0,1,z)
        local kind=obstacleOrder[(index-1)%#obstacleOrder+1]
        local routeFloor
        if kind~="MovingPlatform" then routeFloor=part(map.Core,"Platform"..index,V.new(36,2,20),center,floorColor) end
        local built=obstacle(map,kind,center,index,theme)
        if not routeFloor then routeFloor=built.Body end
        routeFloor:SetAttribute("RouteIndex",routeIndex)
        for _,x in {-17,17} do
            part(map.Decoration,"RouteEdge",V.new(0.6,0.08,18),center+V.new(x,1.08,0),if theme=="NeonCity" then palette.Cyan else palette.Gold,E.Material.Neon).CanCollide=false
        end
        if index%3==0 then
            -- Rest deck is deliberately separated from moving/damaging obstacle geometry.
            z+=24;routeIndex+=1;gate+=1
            local rest=part(map.Core,"Rest"..gate,V.new(44,2,20),V.new(0,1,z),floorColor)
            rest:SetAttribute("RouteIndex",routeIndex);rest:SetAttribute("SafeCheckpoint",true)
            checkpoint(map,gate,rest.CFrame.Position)
        end
        -- Optional side route can disappear; mandatory core floor never does.
        local side=part(map.Optional,"Side"..index,V.new(10,2,20),center+V.new(-28,0,0),palette.Blue);side:SetAttribute("EventOptional",true)
        trigger(map.MeteorTargets,"Target"..index,V.new(1,1,1),center+V.new(7,1,0))
        if index%4==0 then architecture(map.Decoration,center+V.new(44,-25,0),theme,38) end
        if theme=="SkyKingdom" and index%3==1 then
            local cloud=part(map.Decoration,"Cloud",V.new(35,10,22),center+V.new(-45,-12,0),C.fromRGB(237,244,255),E.Material.SmoothPlastic,E.PartType.Ball);cloud.CanCollide=false
        elseif theme=="NeonCity" then architecture(map.Decoration,center+V.new(32,-35,0),theme,32) end
    end
    map:SetAttribute("RequiredGates",gate)
    local finishZ=z+26
    local finishDeck=part(map.Core,"FinishDeck",V.new(56,2,28),V.new(0,1,finishZ),palette.Green);finishDeck:SetAttribute("RouteIndex",routeIndex+1)
    trigger(map,"Finish",V.new(58,30,12),V.new(0,12,finishZ+4))
    for _,x in {-23,23} do part(map.Decoration,"FinishPost",V.new(3,18,3),V.new(x,10,finishZ+4),palette.Gold,E.Material.Metal) end
    part(map.Decoration,"FinishArch",V.new(48,3,3),V.new(0,19,finishZ+4),palette.Gold,E.Material.Metal).CanCollide=false
    crown(map.Decoration,V.new(0,23,finishZ+4),1.1)
    text(map.Decoration,V.new(0,15,finishZ+5),"QUALIFY","GREEN = FINISH",palette.Green)
    return map
end
function Builder.arena(name,mode)
    local map=base(name,"LavaFactory",mode)
    map:SetAttribute("BoundsX",120);map:SetAttribute("BoundsZ",150)
    local isSurvival=mode=="Survival"
    if isSurvival then
        for x=-2,2 do for z=-2,2 do
            local center=V.new(x*18,1,z*18)
            local parent=if math.abs(x)==2 or math.abs(z)==2 then map.Optional else map.Core
            local tile=part(parent,"Tile"..x.."_"..z,V.new(16,2,16),center,palette.Dark,E.Material.Metal)
            if parent==map.Optional then tile:SetAttribute("EventOptional",true);tile:SetAttribute("FallingTile",true) end
            if math.abs(x)+math.abs(z)>=2 then trigger(map.MeteorTargets,"Target"..x.."_"..z,V.one,center+V.new(0,1,0)) end
        end end
        spawns(map,V.new(0,5,0),4)
        obstacle(map,"Spinner",V.new(0,1,0),1,"LavaFactory")
        obstacle(map,"SwingHammer",V.new(27,1,-18),2,"LavaFactory")
        text(map.Decoration,V.new(0,16,-50),"LAVA FACTORY","KEEP MOVING. SURVIVE.",palette.Gold)
    else
        local start=part(map.Core,"Start",V.new(40,2,28),V.new(0,1,-55),palette.Dark,E.Material.Metal);start:SetAttribute("RouteIndex",0)
        spawns(map,V.new(0,5,-56))
        local gates=0
        for index=1,12 do
            local angle=-math.pi/2+(index-1)*math.pi/6
            local center=V.new(math.cos(angle)*30,1+index*2.5,math.sin(angle)*30)
            local nextAngle=angle+math.pi/6
            local nextPosition=V.new(math.cos(nextAngle)*30,center.Y,math.sin(nextAngle)*30)
            local cf=CF.lookAt(center,nextPosition)
            local step=part(map.Core,"Step"..index,V.new(18,2,12),center,if index%2==0 then palette.Blue else palette.Dark,E.Material.Metal);step.CFrame=cf;step:SetAttribute("RouteIndex",index)
            local edge=part(map.Decoration,"StepEdge",V.new(17,0.08,0.6),center,palette.Cyan,E.Material.Neon);edge.CFrame=cf*CF.new(0,1.08,-5.5);edge.CanCollide=false
            if index%3==0 then
                gates+=1;local gate=trigger(map.Checkpoints,"Gate"..gates,V.new(18,12,12),center+V.new(0,4,0),gates);gate.CFrame=cf*CF.new(0,4,0)
                trigger(map.CheckpointSpawns,"Checkpoint"..gates,V.one,center+V.new(0,4,0),gates)
            end
        end
        map:SetAttribute("RequiredGates",gates)
        local deck=part(map.Core,"CrownDeck",V.new(28,2,28),V.new(0,33,0),palette.Gold,E.Material.Metal);deck:SetAttribute("RouteIndex",13)
        trigger(map,"Finish",V.new(16,8,16),V.new(0,38,0))
        crown(map.Decoration,V.new(0,38,0),1.3)
        text(map.Decoration,V.new(0,47,0),if mode=="Final" then "CLAIM THE CROWN" else "RISING DANGER",if mode=="Final" then "REACH THE CROWN. DON'T FALL." else "CLIMB ABOVE THE LAVA",palette.Gold)
    end
    local lava=part(map,"Lava",V.new(115,1.2,140),V.new(0,-14,0),palette.Red,E.Material.Neon);lava.CanCollide=false;lava:SetAttribute("Lava",true)
    for _,x in {-62,62} do for _,z in {-55,55} do architecture(map.Decoration,V.new(x,-15,z),"LavaFactory",47) end end
    return map
end
function Builder.lobby()
    local lobby=model(nil,"RoyalRushLobby")
    local origin=part(lobby,"Origin",V.one,V.zero);origin.Transparency=1;origin.CanCollide=false;lobby.PrimaryPart=origin
    part(lobby,"Island",V.new(160,12,140),V.new(0,25,0),palette.Blue,E.Material.Slate)
    part(lobby,"Plaza",V.new(132,3,112),V.new(0,32.5,0),palette.White,E.Material.Marble)
    part(lobby,"RoyalCarpet",V.new(18,0.12,72),V.new(0,34.07,-9),palette.Purple,E.Material.Fabric).CanCollide=false
    local spawn=I.new("SpawnLocation");spawn.Name="LobbySpawn";spawn.Size=V.new(16,1,12);spawn.CFrame=CF.new(0,34,-32);spawn.Anchored=true;spawn.Neutral=true;spawn.Duration=0;spawn.Transparency=1;spawn.CanCollide=false;spawn.Parent=lobby
    for _,x in {-12,12} do part(lobby,"PortalColumn",V.new(3,23,5),V.new(x,45,16),palette.Gold,E.Material.Metal) end
    part(lobby,"PortalArch",V.new(28,3,5),V.new(0,57,16),palette.Gold,E.Material.Metal)
    local portal=part(lobby,"CrownPortal",V.new(22,19,1),V.new(0,44,16),palette.Purple,E.Material.Neon);portal.Transparency=0.55;portal.CanCollide=false
    crown(lobby,V.new(0,61,16),1.7);text(lobby,V.new(0,53,15),"ROYAL RUSH","CHAOS + CROWN",palette.Gold)
    local function station(name,x,z,color,caption)
        local pedestal=part(lobby,name,V.new(14,2,12),V.new(x,35,z),color,E.Material.Metal)
        text(lobby,V.new(x,43,z),name,caption,color)
        local prompt=I.new("ProximityPrompt");prompt.Name=name.."Prompt";prompt.ActionText="Open";prompt.ObjectText=name;prompt.HoldDuration=0;prompt.MaxActivationDistance=10;prompt.RequiresLineOfSight=false;prompt.Parent=pedestal
        return pedestal
    end
    station("LOADOUT",35,-10,palette.Cyan,"FREE POWERS")
    station("SHOP",-35,-10,palette.Gold,"COSMETICS ONLY")
    station("DAILY",-35,24,palette.Green,"RETURN FOR REWARDS")
    local board=station("LEADERBOARD",35,25,palette.Purple,"PUBLIC WINS")
    board:SetAttribute("Leaderboard",true)
    local throne=folder(lobby,"Throne")
    part(throne,"Stage",V.new(22,2,18),V.new(0,35,42),palette.Dark,E.Material.Marble)
    part(throne,"Seat",V.new(8,3,7),V.new(0,38,44),palette.Purple,E.Material.Fabric)
    part(throne,"Back",V.new(9,13,2),V.new(0,43,48),palette.Gold,E.Material.Metal)
    trigger(throne,"KingSpot",V.one,V.new(0,42,44))
    text(lobby,V.new(0,53,46),"KING OF THE SERVER","WIN THE NEXT CROWN",palette.Gold)
    for _,x in {-65,65} do for _,z in {-49,49} do architecture(lobby,V.new(x,34,z),"SkyKingdom",21) end end
    local practice=folder(lobby,"Practice")
    for i=1,7 do
        local center=V.new(-45+i*13,35+(i%3)*1.5,-49)
        part(practice,"Jump"..i,V.new(8,2,8),center,if i%2==0 then palette.Gold else palette.Blue)
    end
    text(lobby,V.new(-39,44,-49),"PRACTICE","JUMP + POWER",palette.Cyan)
    return lobby
end
return Builder
