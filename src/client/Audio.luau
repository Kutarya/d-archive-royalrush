local SoundService=game:GetService("SoundService")
local Debris=game:GetService("Debris")
local Config=require(game:GetService("ReplicatedStorage").RoyalRush.Config)
local Audio={Music=nil,Settings=Config.Settings}
-- Built-in Roblox content fallback. Original WAVs are also shipped for later asset import.
-- Built-in character sound paths documented in Roblox/Core-Scripts.
-- Original music/SFX in content/audio can replace these after owner upload.
local fallback={Click="rbxasset://sounds/action_jump_land.mp3",Power="rbxasset://sounds/action_jump.mp3",Warning="rbxasset://sounds/action_jump.mp3",Qualified="rbxasset://sounds/action_get_up.mp3",Eliminated="rbxasset://sounds/impact_water.mp3",Victory="rbxasset://sounds/action_get_up.mp3",Countdown="rbxasset://sounds/action_jump_land.mp3"}
function Audio.configure(settings) Audio.Settings=settings;if Audio.Music then Audio.Music.Volume=settings.Music end end
function Audio.play(id)
    if not Config.Audio.Enabled or Audio.Settings.SFX<=0 then return end
    local asset=Config.Audio.Custom[id] or fallback[id];if not asset or asset=="" then return end
    local sound=Instance.new("Sound");sound.Name="RoyalRushSFX";sound.SoundId=asset;sound.Volume=Audio.Settings.SFX*0.5
    sound.PlaybackSpeed=if id=="Victory" then 0.8 elseif id=="Warning" then 0.9 else 1.1;sound.Parent=SoundService;sound:Play();Debris:AddItem(sound,5)
end
function Audio.music(kind)
    local asset=Config.Audio.Custom[kind]
    if Audio.Music and Audio.Music:GetAttribute("Kind")==kind then return end
    if Audio.Music then Audio.Music:Destroy();Audio.Music=nil end
    if not asset or asset=="" then return end
    local sound=Instance.new("Sound");sound.Name="RoyalRushMusic";sound.SoundId=asset;sound.Volume=Audio.Settings.Music;sound.Looped=true;sound:SetAttribute("Kind",kind);sound.Parent=SoundService;sound:Play();Audio.Music=sound
end
return Audio
