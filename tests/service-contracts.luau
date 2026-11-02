-- Executes production MapService/PowerService with explicit engine substitutes.
-- This checks application branches and data types, not physics/replikasyon.
local fs=require("@lune/fs")
local luau=require("@lune/luau")
local serde=require("@lune/serde")
local R=require("@lune/roblox")
local Config=require("../src/shared/Config")
local Catalog=require("../src/shared/MapCatalog")
local Util=require("../src/shared/Util")
local report={Kind="production service logic with fake engine context; NOT Roblox engine playtest",Passed=0,Failed=0,Tests={}}
local function test(name,fn)
    local ok,err=pcall(fn);table.insert(report.Tests,{Name=name,Passed=ok,Error=if ok then nil else tostring(err)})
    if ok then report.Passed+=1 else report.Failed+=1;print("FAIL "..name..": "..tostring(err)) end
end
local Motion=luau.load(fs.readFile("src/shared/ObstacleMotion.luau"),{environment={Vector3=R.Vector3,CFrame=R.CFrame}})()
local services={ReplicatedStorage={RoyalRush={Config=Config,MapCatalog=Catalog,Util=Util,ObstacleMotion=Motion}},ServerStorage={},Debris={AddItem=function() end}}
local impulses={}
local fakeInstances={new=function(class)
    if class=="Attachment" or class=="LinearVelocity" then local obj={Destroy=function() end};if class=="LinearVelocity" then table.insert(impulses,obj) end;return obj end
    return R.Instance.new(class)
end}
local environment={game={GetService=function(_,name) return services[name] end},require=function(module) return module end,Instance=fakeInstances,Vector2=R.Vector2,Vector3=R.Vector3,CFrame=R.CFrame,Color3=R.Color3,Enum=R.Enum}
local Power=luau.load(fs.readFile("src/server/PowerService.luau"),{environment=environment})()
environment.script={Parent={PowerService=Power}}
local Map=luau.load(fs.readFile("src/server/MapService.luau"),{environment=environment})()
local function root(position)
    return {Position=position or R.Vector3.zero,CFrame=R.CFrame.identity,AssemblyLinearVelocity=R.Vector3.zero,FindFirstChild=function() return nil end}
end
local function arena(mode)
    local m=Map.new();m.Info={Mode=mode};m.Lava={Position=R.Vector3.zero}
    m.Model={Core={FindFirstChild=function(_,name) if name=="CrownDeck" then return {Position=R.Vector3.new(0,148,700),Size=R.Vector3.new(28,2,28)} end;return nil end},GetAttribute=function(_,name) if name=="MinY" then return -18 end;return nil end}
    return m
end
test("rising danger overtime preserves a reachable safe top deck",function()
    local m=arena("RisingDanger");m:update(120,0.05,{},120,true)
    assert(m.LavaHeight==27.5 and m.Lava.Position.Y<148)
end)
test("final lava remains rising while nonfinal danger is capped",function()
    local m=arena("Final");m:update(120,0.05,{},120,true);assert(m.LavaHeight>29)
end)
test("swept laser contact catches both endpoints outside trigger",function()
    local m=arena("Race");m.Lava=nil
    local body={CFrame=R.CFrame.new(0,125,715),Size=R.Vector3.new(20,10,1.5),GetAttribute=function(_,name) return name=="Eliminate" end}
    m.Obstacles={{Body=body,Inactive=false}}
    local r={Root={Position=R.Vector3.new(0,125,720)},Humanoid={FloorMaterial=R.Enum.Material.Concrete}}
    assert(m:hazard(r,30,R.Vector3.new(0,125,710))=="Laser Gate")
    m.Obstacles[1].Inactive=true;assert(m:hazard(r,30,R.Vector3.new(0,125,710))==nil)
end)
test("shield blocks one contact and gives time to leave overlapping hazard",function()
    local r={Status="Active",Character=R.Instance.new("Model"),Root=root(R.Vector3.new(0,5,0)),Humanoid={Health=100},LockedPower="Shield",Player={UserId=1}}
    assert(Power.activate(r,100,function() end));assert(r.Character:FindFirstChild("RoyalShield"))
    assert(not Power.knock(r,R.Vector3.zero,100.1));assert(r.ShieldUntil==0 and r.HitUntil==101.1)
    assert(not r.Character:FindFirstChild("RoyalShield"));assert(not Power.activate(r,101,function() end))
    assert(Power.knock(r,R.Vector3.zero,101.2));assert(impulses[#impulses].VectorVelocity.Y==15)
end)
test("double jump requires airborne state and prevents repeated use in same flight",function()
    local r={Status="Active",Root=root(),Humanoid={Health=100,FloorMaterial=R.Enum.Material.Concrete},LockedPower="DoubleJump",Player={UserId=1}}
    assert(not Power.activate(r,100,function() end));r.Humanoid.FloorMaterial=R.Enum.Material.Air
    assert(Power.activate(r,100,function() end));assert(impulses[#impulses].LineVelocity==42 and impulses[#impulses].LineDirection==R.Vector3.yAxis)
    assert(not Power.activate(r,111,function() end))
    r.DoubleUsed=false;assert(Power.activate(r,111,function() end))
end)
test("void cannot be bypassed by shield",function()
    local m=arena("Final");local r={ShieldUntil=999,Root={Position=R.Vector3.new(0,100,700)}}
    assert(m:hazard(r,100)=="Void")
end)
fs.writeFile("evidence/service-contracts.json",serde.encode("json",report,true))
print("Service fake engine context: "..report.Passed.." passed, "..report.Failed.." failed")
assert(report.Failed==0,"Service contract tests failed")
