--!strict
local Util=if script then require(script.Parent.Util) else require("./Util")
local Config=if script then require(script.Parent.Config) else require("./Config")
local schemas={Sync={},Power={},Ready={RoundId="string"},Queue={Enabled="boolean"},Lobby={},Loadout={Id="string"},Buy={Id="string"},Equip={Id="string"},Daily={},Quest={Id="string"},Settings={Settings="table"},Tutorial={}}
local Validator={}
function Validator.valid(payload: any): boolean
    if type(payload)~="table" or type(payload.Action)~="string" then return false end
    local schema=schemas[payload.Action]
    if not schema then return false end
    local count=0
    for key,value in payload do
        count+=1;if count>3 or type(key)~="string" then return false end
        if key~="Action" then
            local expected=schema[key]
            if not expected or type(value)~=expected then return false end
            if expected=="string" and (#value<1 or #value>160) then return false end
        end
    end
    for key in schema do if payload[key]==nil then return false end end
    if payload.Settings then
        local n=0
        for key,value in payload.Settings do
            n+=1;local default=Config.Settings[key]
            if n>7 or default==nil or type(value)~=type(default) then return false end
            if type(value)=="number" and (not Util.finite(value) or value<0 or value>1) then return false end
        end
        if n==0 then return false end
    end
    return true
end
return Validator
