local RunService=game:GetService("RunService")
local Service=game:GetService("AnalyticsService")
local Analytics={Events={},Counts={}}
function Analytics.log(player,event,value)
    Analytics.Counts[event]=(Analytics.Counts[event] or 0)+1
    table.insert(Analytics.Events,{Event=event,Value=value or 1,Time=os.time()})
    if #Analytics.Events>200 then table.remove(Analytics.Events,1) end
    if not RunService:IsStudio() and player and player.Parent then
        task.spawn(function() pcall(function() Service:LogCustomEvent(player,event,value or 1) end) end)
    end
end
return Analytics
