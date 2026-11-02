--!strict
local Limits={Power={2,2},Sync={1,2},Ready={2,2},Queue={1,2},Lobby={0.5,1},Loadout={1,2},Buy={0.5,2},Equip={1,2},Daily={0.5,1},Quest={0.5,2},Settings={1,2},Tutorial={0.5,1}}
local Limiter={}
Limiter.__index=Limiter
function Limiter.new() return setmetatable({Players={}},Limiter) end
function Limiter:allow(id: number,action: string,now: number): boolean
    local limit=Limits[action]
    if not limit then return false end
    local player=self.Players[id]
    if not player then player={Global={Tokens=12,Time=now},Actions={}};self.Players[id]=player end
    local global=player.Global
    global.Tokens=math.min(12,global.Tokens+math.max(0,now-global.Time)*6);global.Time=now
    local bucket=player.Actions[action] or {Tokens=limit[2],Time=now}
    player.Actions[action]=bucket
    bucket.Tokens=math.min(limit[2],bucket.Tokens+math.max(0,now-bucket.Time)*limit[1]);bucket.Time=now
    if global.Tokens<1 or bucket.Tokens<1 then return false end
    global.Tokens-=1;bucket.Tokens-=1
    return true
end
function Limiter:clear(id: number) self.Players[id]=nil end
return Limiter
