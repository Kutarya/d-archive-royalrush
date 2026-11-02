-- Audits actual serialized instances and API property schemas. No Roblox simulation.
local fs=require("@lune/fs")
local serde=require("@lune/serde")
local luau=require("@lune/luau")
local R=require("@lune/roblox")
local Config=require("../src/shared/Config")
local Catalog=require("../src/shared/MapCatalog")
local report={Kind="offline serialized-place, route geometry and GUI audit; NOT Studio physics/rendering",Passed=0,Failed=0,Checks={},Maps={},UI={}}
local function check(name,fn)
    local ok,err=pcall(fn);table.insert(report.Checks,{Name=name,Passed=ok,Error=if ok then nil else tostring(err)})
    if ok then report.Passed+=1 else report.Failed+=1;print("FAIL "..name..": "..tostring(err)) end
end
local function need(parent,name,class)
    local found=parent:FindFirstChild(name);assert(found,"Missing "..name);assert(not class or found:IsA(class),"Incorrect class for "..name);return found
end
local place=R.deserializePlace(fs.readFile("RoyalRush.rbxl"))
local xml=R.deserializePlace(fs.readFile("RoyalRush.rbxlx"))
local world=need(place,"Workspace","Workspace")
local maps=need(need(place,"ServerStorage"),"RoyalRushMaps","Folder")
local shared=need(need(place,"ReplicatedStorage"),"RoyalRush","Folder")
local server=need(need(place,"ServerScriptService"),"RoyalRushServer","Folder")
local client=need(need(need(place,"StarterPlayer"),"StarterPlayerScripts"),"RoyalRushClient","Folder")
check("binary/XML same instance count",function() assert(#place:GetDescendants()==#xml:GetDescendants()) end)
check("streaming configuration",function() assert(world.StreamingEnabled and world.StreamingMinRadius==128 and world.StreamingTargetRadius==512) end)
check("lobby contains spawn/portal/throne/practice/stations",function()
    local lobby=need(world,"RoyalRushLobby","Model")
    need(lobby,"LobbySpawn","SpawnLocation");need(lobby,"CrownPortal","Part");need(lobby,"Throne");need(lobby,"Practice")
    for _,name in {"LOADOUT","SHOP","DAILY","LEADERBOARD"} do assert(need(lobby,name):FindFirstChildOfClass("ProximityPrompt")) end
end)
local sourceCount=0
for _,entry in {{Path="src/shared",Parent=shared},{Path="src/server",Parent=server},{Path="src/client",Parent=client}} do
    for _,file in fs.readDir(entry.Path) do
        if string.match(file,"%.luau$") then
            local name=string.gsub(file,"%.luau$","");local class="ModuleScript"
            if string.match(name,"%.server$") then name=string.gsub(name,"%.server$","");class="Script"
            elseif string.match(name,"%.client$") then name=string.gsub(name,"%.client$","");class="LocalScript" end
            check("embedded source "..entry.Path.."/"..file,function()
                local embedded=need(entry.Parent,name,class);local source=fs.readFile(entry.Path.."/"..file)
                assert(embedded.Source==source,"Build contains stale source");luau.compile(embedded.Source)
                assert(not string.match(source,"require%s*%(%s*%d"),"Unexpected external asset module")
                if class~="ModuleScript" then assert(not embedded.Disabled) end
            end)
            sourceCount+=1
        end
    end
end
report.ScriptCount=sourceCount;report.TotalInstances=#place:GetDescendants()
local obstacleTypes={};local themes={}
local function corners(p)
    local result={}
    for _,v in {{-1,-1},{1,-1},{1,1},{-1,1}} do
        local world=p.CFrame:PointToWorldSpace(R.Vector3.new(v[1]*p.Size.X/2,0,v[2]*p.Size.Z/2))
        table.insert(result,R.Vector2.new(world.X,world.Z))
    end
    return result
end
local function pointSegment(p,a,b)
    local ab=b-a;local t=math.clamp((p-a):Dot(ab)/ab:Dot(ab),0,1)
    return (p-(a+ab*t)).Magnitude
end
local function horizontalGap(a,b)
    -- Separating axes detect overlap; edge distances handle rotated climb decks.
    local ca,cb=corners(a),corners(b);local separated=false
    for _,cf in {a.CFrame,b.CFrame} do
        for _,vector in {cf.RightVector,cf.LookVector} do
            local axis=R.Vector2.new(vector.X,vector.Z)
            local minA,maxA,minB,maxB=math.huge,-math.huge,math.huge,-math.huge
            for _,v in ca do local d=v:Dot(axis);minA=math.min(minA,d);maxA=math.max(maxA,d) end
            for _,v in cb do local d=v:Dot(axis);minB=math.min(minB,d);maxB=math.max(maxB,d) end
            if maxA<minB or maxB<minA then separated=true end
        end
    end
    if not separated then return 0 end
    local gap=math.huge
    for i=1,4 do for j=1,4 do
        gap=math.min(gap,pointSegment(ca[i],cb[j],cb[j%4+1]),pointSegment(cb[i],ca[j],ca[j%4+1]))
    end end
    return gap
end
for _,map in maps:GetChildren() do
    local id=map.Name;local info=Catalog[id];assert(info,"Unknown map "..id)
    themes[info.Theme]=true
    local route={}
    if info.Mode~="Survival" then
        for _,p in map:GetDescendants() do
            if p:IsA("BasePart") and p:GetAttribute("RouteIndex") then table.insert(route,p) end
        end
        table.sort(route,function(a,b) return a:GetAttribute("RouteIndex")<b:GetAttribute("RouteIndex") end)
        assert(#route>=14,"Missing ordered mandatory route")
    end
    local maxGap=0;local maxRise=0
    for index=2,#route do
        local a,b=route[index-1],route[index]
        local ap,bp=a.CFrame.Position,b.CFrame.Position
        local gap=horizontalGap(a,b)
        local rise=(bp.Y+b.Size.Y/2)-(ap.Y+a.Size.Y/2)
        maxGap=math.max(maxGap,gap);maxRise=math.max(maxRise,rise)
        check(id.." route link "..index-1,function() assert(gap<=8.5 and rise<=4,"Route gap/rise exceeds static mobile design bound") end)
    end
    check(id.." primary part, 16 unique spawns and checkpoints",function()
        assert(map:IsA("Model") and map.PrimaryPart and map.PrimaryPart.Name=="Origin")
        assert(#map.Spawns:GetChildren()==16)
        local slots={};for _,p in map.Spawns:GetChildren() do local slot=p:GetAttribute("Slot");assert(slot and not slots[slot]);slots[slot]=true end
        assert(#map.Checkpoints:GetChildren()==map:GetAttribute("RequiredGates"));assert(#map.CheckpointSpawns:GetChildren()==map:GetAttribute("RequiredGates"))
        if info.Mode~="Survival" then need(map,"Finish","BasePart") end
    end)
    check(id.." anchored parts and optional floor isolation",function()
        for _,p in map:GetDescendants() do
            if p:IsA("BasePart") then assert(p.Anchored,"Unanchored authored part");assert(not (p:IsDescendantOf(map.Core) and p:GetAttribute("EventOptional")),"Mandatory core can disappear") end
        end
    end)
    check(id.." spawn points have floor support and no solid head trap",function()
        for _,group in {map.Spawns,map.CheckpointSpawns} do for _,spawn in group:GetChildren() do
            local supported=false
            for _,floor in map:GetDescendants() do if floor:IsA("BasePart") and floor.CanCollide then
                local localPoint=floor.CFrame:PointToObjectSpace(spawn.CFrame.Position)
                if math.abs(localPoint.X)<=floor.Size.X/2-1.5 and math.abs(localPoint.Z)<=floor.Size.Z/2-1.5 then
                    local clearance=localPoint.Y-floor.Size.Y/2
                    if clearance>=2.5 and clearance<=5 then supported=true end
                    assert(not (clearance<2.5 and localPoint.Y+2.5> -floor.Size.Y/2),"Spawn intersects "..floor.Name)
                end
            end end
            assert(supported,"Unsupported spawn "..spawn.Name)
        end end
    end)
    if info.Mode=="Race" then check(id.." checkpoint respawns separated from damaging obstacles",function()
        for _,spawn in map.CheckpointSpawns:GetChildren() do for _,obstacle in map.Obstacles:GetChildren() do
            local body=obstacle:FindFirstChild("Body")
            if body and (body:GetAttribute("Knockback") or body:GetAttribute("Eliminate")) then
                assert(math.abs(body.CFrame.Position.Z-spawn.CFrame.Position.Z)>16,"Respawn inside obstacle sweep")
            end
        end end
    end) end
    for _,o in map.Obstacles:GetChildren() do obstacleTypes[o:GetAttribute("ObstacleType")]=true end
    table.insert(report.Maps,{Id=id,Theme=info.Theme,Mode=info.Mode,Instances=#map:GetDescendants(),StaticMaximumGap=maxGap,StaticMaximumRise=maxRise})
end
check("five layouts, three themes, 15 obstacle types, eight events, three powers",function()
    local function count(t) local n=0;for _ in t do n+=1 end;return n end
    assert(#report.Maps==5 and count(themes)==3 and count(obstacleTypes)==15 and count(Config.Events)==8 and count(Config.Powers)==3)
end)
check("dash constraint properties in offline Roblox schema",function()
    local velocity=R.Instance.new("LinearVelocity");velocity.RelativeTo=R.Enum.ActuatorRelativeTo.World;velocity.VelocityConstraintMode=R.Enum.VelocityConstraintMode.Plane
    velocity.PrimaryTangentAxis=R.Vector3.xAxis;velocity.SecondaryTangentAxis=R.Vector3.zAxis;velocity.PlaneVelocity=R.Vector2.new(60,0);velocity.ForceLimitsEnabled=false
    assert(velocity.PlaneVelocity.X==60)
end)
local environment={Instance=R.Instance,Color3=R.Color3,Vector2=R.Vector2,Vector3=R.Vector3,UDim2=R.UDim2,UDim=R.UDim,Enum=R.Enum,Font=R.Font}
local UI=luau.load(fs.readFile("src/client/UI.luau"),{environment=environment,debugName="UI schema audit"})()
local refs=UI.build(R.Instance.new("PlayerGui"))
UI.row(refs.Content,"Double Jump","One extra boost while airborne. 10 seconds",UI.Colors.Blue)
check("HUD constructs and serializes real GUI instances",function()
    local data=R.serializeModel({refs.Gui});fs.writeFile("evidence/HUD-audit.rbxm",data)
    local reopened=R.deserializeModel(data)[1]
    assert(reopened.Name=="RoyalRushHUD" and #reopened:GetDescendants()==#refs.Gui:GetDescendants())
    need(reopened,"SafeRoot");need(refs.Modal,"Content","ScrollingFrame")
    report.GUIInstances=#refs.Gui:GetDescendants()
end)
local function bounds(object,parent)
    local size=object.Size;local width=parent.W*size.X.Scale+size.X.Offset;local height=parent.H*size.Y.Scale+size.Y.Offset
    local constraint=object:FindFirstChildOfClass("UISizeConstraint")
    if constraint then width=math.clamp(width,constraint.MinSize.X,constraint.MaxSize.X);height=math.clamp(height,constraint.MinSize.Y,constraint.MaxSize.Y) end
    return {X=parent.X+parent.W*object.Position.X.Scale+object.Position.X.Offset-width*object.AnchorPoint.X,Y=parent.Y+parent.H*object.Position.Y.Scale+object.Position.Y.Offset-height*object.AnchorPoint.Y,W=width,H=height}
end
for _,viewport in {{320,568},{390,844},{844,390},{1280,720}} do
    local rect={X=0,Y=0,W=viewport[1],H=viewport[2]};local items={}
    refs.Power.Position=R.UDim2.fromScale(0.86,if rect.H<450 then 0.48 else 0.62)
    refs.PowerHint.Position=refs.Power.Position
    for _,key in {"Name","Timer","Stats","Chaos","Toolbar","Queue","Power","PowerHint","Watch","Lobby","Spectator","Toast","Modal"} do
        local object=refs[key];local container=if object.Parent==refs.Root then rect else bounds(object.Parent,rect)
        items[key]=bounds(object,container)
        check("HUD "..rect.W.."x"..rect.H.." bounds "..key,function()
            local b=items[key];assert(b.X>=-0.01 and b.Y>=-0.01 and b.X+b.W<=rect.W+0.01 and b.Y+b.H<=rect.H+0.01,"UI outside assumed safe rectangle")
        end)
    end
    check("HUD "..rect.W.."x"..rect.H.." stats/timer separation",function() assert(items.Stats.X+items.Stats.W<items.Timer.X) end)
    table.insert(report.UI,{Width=rect.W,Height=rect.H,Bounds=items})
end
fs.writeFile("evidence/place-audit.json",serde.encode("json",report,true))
print("Serialized place / GUI / geometry: "..report.Passed.." passed, "..report.Failed.." failed; "..report.ScriptCount.." embedded scripts.")
assert(report.Failed==0,"Offline place audit failed")
