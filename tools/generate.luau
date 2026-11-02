local fs=require("@lune/fs")
local roblox=require("@lune/roblox")
local serde=require("@lune/serde")
local Builder=require("./MapBuilder")
fs.writeDir("content/generated")
fs.writeDir("evidence")
local maps=roblox.Instance.new("Folder");maps.Name="Maps"
local builds={Builder.race("SkyKingdom","SkyKingdom",12),Builder.race("NeonCity","NeonCity",15),Builder.arena("LavaSurvival","Survival"),Builder.arena("LavaAscent","RisingDanger"),Builder.arena("CrownClimb","Final")}
local report={Maps={},Lobby={},Validation="serialized Roblox Instances, not Studio gameplay"}
for _,map in builds do
    map.Parent=maps
    local obstacles={}
    for _,o in map.Obstacles:GetChildren() do obstacles[o:GetAttribute("ObstacleType")]=true end
    table.insert(report.Maps,{Id=map.Name,Theme=map:GetAttribute("Theme"),Mode=map:GetAttribute("Mode"),Instances=#map:GetDescendants(),Spawns=#map.Spawns:GetChildren(),Gates=map:GetAttribute("RequiredGates"),ObstacleTypes=obstacles})
end
local lobby=Builder.lobby();report.Lobby.Instances=#lobby:GetDescendants()
fs.writeFile("content/generated/Maps.rbxm",roblox.serializeModel({maps}))
fs.writeFile("content/generated/Lobby.rbxm",roblox.serializeModel({lobby}))
fs.writeFile("evidence/map-generation.json",serde.encode("json",report,true))
print("Generated lobby + five layouts in three map themes.")
