--!strict
local Config = if script then require(script.Parent.Config) else require("./Config")
local Util = if script then require(script.Parent.Util) else require("./Util")
local Profile = {}
local stats = {"RoundsPlayed","Qualifications","FinalsReached","Perfects","Clutches","PowerUses","ChaosSurvived"}
function Profile.new(): any
    local statistics = {}
    for _, key in stats do statistics[key]=0 end
    return {
        DataVersion=1,TotalXP=0,Wins=0,LocalWins=0,Crowns=0,BestStreak=0,
        SelectedPower="Dash",OwnedCosmetics={RookieTitle=true},EquippedCosmetics={Title="RookieTitle"},
        Settings=Util.copy(Config.Settings),Statistics=statistics,Achievements={},
        Daily={LastDay=-1,Step=0},Quests={Day=-1,Counts={},Claimed={}},
        Ledger={Keys={},Order={}},TutorialVersion=0,
    }
end
function Profile.migrate(raw: any): (any?, string?)
    if type(raw) ~= "table" then return nil,"Invalid profile" end
    if raw.DataVersion ~= nil and raw.DataVersion ~= 1 then return nil,"Unsupported data version" end
    local result = Profile.new()
    for _, key in {"TotalXP","Wins","LocalWins","Crowns","BestStreak"} do
        if raw[key] ~= nil and not Util.integer(raw[key],0,100000000) then return nil,"Invalid "..key end
        result[key]=raw[key] or 0
    end
    if Config.Powers[raw.SelectedPower] then result.SelectedPower=raw.SelectedPower end
    if type(raw.OwnedCosmetics)=="table" then
        for id,owned in raw.OwnedCosmetics do
            if type(id)=="string" and #id<=64 and owned==true then result.OwnedCosmetics[id]=true end
        end
    end
    if type(raw.EquippedCosmetics)=="table" then
        for kind,id in raw.EquippedCosmetics do
            local item=Config.Cosmetics[id]
            if item and item.Kind==kind and result.OwnedCosmetics[id] then result.EquippedCosmetics[kind]=id end
        end
    end
    if type(raw.Settings)=="table" then Profile.settings(result,raw.Settings) end
    if type(raw.Statistics)=="table" then
        for _,key in stats do if Util.integer(raw.Statistics[key],0,100000000) then result.Statistics[key]=raw.Statistics[key] end end
    end
    if type(raw.Achievements)=="table" then
        for key,value in raw.Achievements do if type(key)=="string" and #key<64 and value==true then result.Achievements[key]=true end end
    end
    if type(raw.Daily)=="table" and Util.integer(raw.Daily.LastDay,-1,1000000) and Util.integer(raw.Daily.Step,0,7) then result.Daily=Util.copy(raw.Daily) end
    if type(raw.Quests)=="table" and Util.integer(raw.Quests.Day,-1,1000000) then
        result.Quests.Day=raw.Quests.Day
        for _,quest in Config.Quests do
            if type(raw.Quests.Counts)=="table" and Util.integer(raw.Quests.Counts[quest.Id],0,1000000) then result.Quests.Counts[quest.Id]=raw.Quests.Counts[quest.Id] end
            if type(raw.Quests.Claimed)=="table" and raw.Quests.Claimed[quest.Id]==true then result.Quests.Claimed[quest.Id]=true end
        end
    end
    if type(raw.Ledger)=="table" and type(raw.Ledger.Order)=="table" then
        for _,id in raw.Ledger.Order do
            if type(id)=="string" and #id<=180 and not result.Ledger.Keys[id] then
                result.Ledger.Keys[id]=true;table.insert(result.Ledger.Order,id)
            end
        end
        while #result.Ledger.Order>256 do result.Ledger.Keys[table.remove(result.Ledger.Order,1)]=nil end
    end
    result.TutorialVersion=if Util.integer(raw.TutorialVersion,0,100) then raw.TutorialVersion else 0
    return result,nil
end
function Profile.settings(profile: any, settings: any): (boolean,string)
    if type(settings)~="table" then return false,"Invalid settings" end
    for key,value in settings do
        local default=Config.Settings[key]
        if default==nil then return false,"Unknown setting" end
        if type(default)=="number" then
            if not Util.finite(value) or value<0 or value>1 then return false,"Invalid volume" end
        elseif type(value)~="boolean" then return false,"Invalid setting" end
    end
    for key,value in settings do profile.Settings[key]=value end
    return true,"Settings saved"
end
function Profile.day(profile: any, day: number)
    if day>profile.Quests.Day then profile.Quests={Day=day,Counts={},Claimed={}} end
end
function Profile.remember(profile: any, id: string): boolean
    if profile.Ledger.Keys[id] then return false end
    profile.Ledger.Keys[id]=true;table.insert(profile.Ledger.Order,id)
    if #profile.Ledger.Order>256 then profile.Ledger.Keys[table.remove(profile.Ledger.Order,1)]=nil end
    return true
end
function Profile.grant(profile: any, id: string, xp: number, crowns: number, increments: any?, day: number): (boolean,string)
    if not Util.integer(xp,0,100000) or not Util.integer(crowns,0,100000) then return false,"Invalid reward" end
    if not Profile.remember(profile,id) then return false,"Duplicate" end
    Profile.day(profile,day)
    profile.TotalXP=math.min(100000000,profile.TotalXP+xp)
    profile.Crowns=math.min(100000000,profile.Crowns+crowns)
    for key,amount in increments or {} do
        if profile.Statistics[key]~=nil and Util.integer(amount,0,1000) then
            profile.Statistics[key]+=amount
            for _,quest in Config.Quests do
                if quest.Statistic==key then profile.Quests.Counts[quest.Id]=math.min(quest.Target,(profile.Quests.Counts[quest.Id] or 0)+amount) end
            end
        end
    end
    if profile.Statistics.Qualifications>0 then profile.Achievements.FirstQualification=true end
    if profile.Statistics.FinalsReached>0 then profile.Achievements.FirstFinal=true end
    if profile.Statistics.Perfects>0 then profile.Achievements.Perfect=true end
    if profile.Statistics.Clutches>0 then profile.Achievements.Clutch=true end
    return true,"Reward granted"
end
function Profile.win(profile: any, id: string, competitive: boolean, streak: number, day: number): (boolean,string)
    local ok,reason=Profile.grant(profile,id,if competitive then 250 else 100,if competitive then 60 else 20,nil,day)
    if not ok then return ok,reason end
    if competitive then
        profile.Wins+=1;profile.BestStreak=math.max(profile.BestStreak,streak)
        if profile.Wins>=10 then profile.Achievements.TenWins=true end
        if streak>=5 then profile.Achievements.FiveStreak=true end
    else profile.LocalWins+=1 end
    profile.Achievements.FirstCrown=true
    return true,"Crown won"
end
function Profile.buy(profile: any, id: string): (boolean,string)
    local item=Config.Cosmetics[id]
    if not item then return false,"Unknown cosmetic" end
    if profile.OwnedCosmetics[id] then return false,"Already owned" end
    if profile.Crowns<item.Price then return false,"Not enough Crowns" end
    profile.Crowns-=item.Price;profile.OwnedCosmetics[id]=true;profile.EquippedCosmetics[item.Kind]=id
    return true,"Purchased "..item.Name
end
function Profile.equip(profile: any, id: string): (boolean,string)
    local item=Config.Cosmetics[id]
    if not item or not profile.OwnedCosmetics[id] then return false,"Not owned" end
    profile.EquippedCosmetics[item.Kind]=id
    return true,"Equipped "..item.Name
end
function Profile.claimDaily(profile: any, day: number): (boolean,string)
    if day<=profile.Daily.LastDay then return false,"Already claimed today" end
    local step=profile.Daily.Step%7+1
    local reward=Config.Daily[step]
    local crowns=reward.Crowns or 0
    if reward.Cosmetic then
        if profile.OwnedCosmetics[reward.Cosmetic] then crowns+=30 else profile.OwnedCosmetics[reward.Cosmetic]=true end
    end
    profile.Crowns+=crowns;profile.TotalXP+=reward.XP or 0
    profile.Daily={LastDay=day,Step=step}
    return true,"Day "..step.." reward claimed"
end
function Profile.claimQuest(profile: any, id: string, day: number): (boolean,string)
    Profile.day(profile,day)
    for _,quest in Config.Quests do
        if quest.Id==id then
            if profile.Quests.Claimed[id] then return false,"Already claimed" end
            if (profile.Quests.Counts[id] or 0)<quest.Target then return false,"Quest incomplete" end
            profile.Quests.Claimed[id]=true
            profile.TotalXP+=quest.XP;profile.Crowns+=quest.Crowns
            return true,"Quest reward claimed"
        end
    end
    return false,"Unknown quest"
end
return Profile
