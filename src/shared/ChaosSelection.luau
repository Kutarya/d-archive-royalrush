--!strict
local Config = if script then require(script.Parent.Config) else require("./Config")
local Selection = {}
function Selection.eligible(mode: string, tags: any, count: number, active: any, budget: number): {string}
    local ids={}
    for id,event in Config.Events do
        local allowed=event.Modes[mode] and count>=(event.MinPlayers or 1) and event.Cost<=budget and not active[id]
        for tag in event.Tags do if not tags[tag] then allowed=false end end
        for other in active do if event.Excludes[other] or (Config.Events[other] and Config.Events[other].Excludes[id]) then allowed=false end end
        if allowed then table.insert(ids,id) end
    end
    table.sort(ids)
    return ids
end
function Selection.choose(mode: string,tags: any,count: number,active: any,budget: number,history: {string},roll: ()->number): string?
    local pool=Selection.eligible(mode,tags,count,active,budget)
    if #pool==0 then return nil end
    local recent={}
    for _,id in history do recent[id]=true end
    local fresh={}
    for _,id in pool do if not recent[id] then table.insert(fresh,id) end end
    if #fresh>0 then pool=fresh end
    local buckets={}
    for _,id in pool do
        local rarity=Config.Events[id].Rarity
        buckets[rarity]=buckets[rarity] or {};table.insert(buckets[rarity],id)
    end
    local total=0
    for rarity in buckets do total+=Config.RarityWeights[rarity] end
    local target=math.clamp(roll(),0,0.999999)*total
    for _,rarity in {"Common","Rare","Epic","Legendary"} do
        if buckets[rarity] then
            target-=Config.RarityWeights[rarity]
            if target<0 then
                local options=buckets[rarity]
                return options[math.floor(math.clamp(roll(),0,0.999999)*#options)+1]
            end
        end
    end
    return nil
end
return Selection
