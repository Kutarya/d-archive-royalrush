-- Executes the production DataService with an explicitly fake DataStore transport.
-- Verifies application transaction behavior, not Roblox's cloud/network runtime.
local fs=require("@lune/fs")
local luau=require("@lune/luau")
local serde=require("@lune/serde")
local task=require("@lune/task")
local Config=require("../src/shared/Config")
local Profile=require("../src/shared/Profile")
local Util=require("../src/shared/Util")
local Sessions=require("../src/shared/SessionStore")
local Rules=require("../src/shared/MatchRules")
local report={Kind="production DataService executed with fake transport/task scheduler; NOT live Roblox DataStore",Passed=0,Failed=0,Tests={}}
local function test(name,fn)
    local ok,err=pcall(fn);table.insert(report.Tests,{Name=name,Passed=ok,Error=if ok then nil else tostring(err)})
    if ok then report.Passed+=1 else report.Failed+=1;print("FAIL "..name..": "..tostring(err)) end
end
local function idle(data,player)
    local deadline=os.clock()+8
    repeat task.wait(0.01);assert(os.clock()<deadline,"Profile queue timed out") until not data:get(player).Busy
end
local function create(stored,memory)
    local transport={Record=stored,Failures=0,Writes=0,Calls=0}
    function transport:UpdateAsync(_,transform)
        self.Calls+=1
        if self.Failures>0 then self.Failures-=1;error("Injected transport failure") end
        local nextValue=transform(Util.copy(self.Record))
        if nextValue then self.Record=Util.copy(nextValue);self.Writes+=1;return Util.copy(nextValue) end
        return nil
    end
    local sequence=0
    local services={ReplicatedStorage={RoyalRush={Config=Config,Profile=Profile,SessionStore=Sessions,Util=Util,MatchRules=Rules}},RunService={IsStudio=function() return memory==true end},HttpService={GenerateGUID=function() sequence+=1;return "test-owner-"..sequence end},DataStoreService={GetDataStore=function() return transport end}}
    function services.ReplicatedStorage:WaitForChild(name) return self[name] end
    local fakeGame={GetService=function(_,name) assert(services[name]);return services[name] end}
    local warnings={};local changes=0
    local module=luau.load(fs.readFile("src/server/DataService.luau"),{environment={game=fakeGame,require=function(value) return value end,task=task,warn=function(message) table.insert(warnings,message) end},debugName="DataService fake-transport tests"})()
    local data=module.new(function() changes+=1 end);local player={UserId=123,Parent=true}
    return data,player,transport,warnings,function() return changes end
end
test("atomic load preserves stored progression and obtains lock",function()
    local p=Profile.new();p.Crowns=725;local d,player,t=create({Profile=p,Revision=5});d:load(player)
    assert(d:get(player).Mutable and d:get(player).Profile.Crowns==725 and t.Record.Lock.Owner==d:get(player).Owner)
end)
test("load failure read-only cannot overwrite existing record",function()
    local p=Profile.new();p.Crowns=900;local d,player,t=create({Profile=p});t.Failures=3;d:load(player)
    assert(not d:get(player).Mutable and t.Record.Profile.Crowns==900 and t.Writes==0)
    local ok;d:submit(player,function(profile) profile.Crowns=0;return true end,true,function(success) ok=success end)
    assert(ok==false and t.Writes==0)
end)
test("future schema rejected without write",function()
    local d,player,t=create({Profile={DataVersion=99,Crowns=5000}});d:load(player)
    assert(not d:get(player).Mutable and t.Writes==0 and t.Record.Profile.DataVersion==99)
end)
test("critical purchase failure rolls back both money and ownership",function()
    local p=Profile.new();p.Crowns=100;local d,player,t=create({Profile=p});d:load(player);t.Failures=3
    local ok;d:submit(player,function(candidate) return Profile.buy(candidate,"CloudTrail") end,true,function(success) ok=success end);idle(d,player)
    assert(ok==false and d:get(player).Profile.Crowns==100 and not d:get(player).Profile.OwnedCosmetics.CloudTrail)
    assert(t.Record.Profile.Crowns==100 and not t.Record.Profile.OwnedCosmetics.CloudTrail)
end)
test("queued operations serialize and retry successful commit",function()
    local d,player,t=create(nil);d:load(player);t.Failures=2
    for i=1,4 do d:submit(player,function(candidate) return Profile.grant(candidate,"batch"..i,1,1,nil,100) end,i==4) end
    idle(d,player);assert(d:get(player).Profile.Crowns==4 and t.Record.Profile.Crowns==4 and d:get(player).Status=="Saved")
end)
test("lost session makes profile read-only and rejects subsequent queued mutations",function()
    local p=Profile.new();p.Crowns=100;local d,player,t=create({Profile=p});d:load(player);t.Record.Lock.Owner="new-server"
    d:submit(player,function(candidate) return Profile.buy(candidate,"CloudTrail") end,true)
    d:submit(player,function(candidate) candidate.Crowns=99999;return true end,false)
    idle(d,player);assert(not d:get(player).Mutable and d:get(player).Profile.Crowns==100 and t.Record.Profile.Crowns==100)
end)
test("final removal flushes dirty profile and releases its lock",function()
    local d,player,t=create(nil);d:load(player)
    d:submit(player,function(p) return Profile.grant(p,"qualified",50,15,nil,100) end,false);idle(d,player)
    assert(d:get(player).Dirty);d:remove(player)
    local deadline=os.clock()+5;while d:get(player) do task.wait(0.01);assert(os.clock()<deadline) end
    assert(t.Record.Profile.Crowns==15 and t.Record.Lock==nil)
end)
test("Studio default uses memory without cloud calls",function()
    local d,player,t=create(nil,true);d:load(player)
    d:submit(player,function(p) return Profile.grant(p,"practice",20,5,nil,100) end,true);idle(d,player)
    assert(t.Calls==0 and not d:view(player).Persistent and d:view(player).Mutable and d:view(player).Crowns==5)
end)
test("observer error does not trap profile queue or lose committed progress",function()
    local d,player,t=create(nil);d.Changed=function() error("Injected cosmetic observer failure") end;d:load(player)
    for i=1,2 do d:submit(player,function(p) return Profile.grant(p,"observer"..i,5,5,nil,100) end,true) end
    idle(d,player);assert(d:get(player).Profile.Crowns==10 and t.Record.Profile.Crowns==10 and not d:get(player).Busy)
end)
fs.writeFile("evidence/data-service-tests.json",serde.encode("json",report,true))
print("DataService fake transport: "..report.Passed.." passed, "..report.Failed.." failed")
assert(report.Failed==0,"Data service tests failed")
