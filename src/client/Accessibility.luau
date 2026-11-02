-- Symbols supplement colors; these are local, anchored UI, not server physics.
local Accessibility={Icons={}}
function Accessibility.update(arena,enabled)
    for part,icon in Accessibility.Icons do
        if not enabled or not part.Parent or not arena or not part:IsDescendantOf(arena) then
            icon:Destroy();Accessibility.Icons[part]=nil
        end
    end
    if not enabled or not arena then return end
    for _,part in arena:GetDescendants() do
        if part:IsA("BasePart") and not Accessibility.Icons[part] then
            local symbol=if part.Name=="Finish" then "GO" elseif part:GetAttribute("JumpPad") then "↑" elseif part:GetAttribute("Lava") or part:GetAttribute("Eliminate") or part:GetAttribute("Knockback") then "!" elseif part:GetAttribute("EventOptional") then "?" else nil
            if symbol then
                local gui=Instance.new("BillboardGui");gui.Name="RoyalColorAssist";gui.Adornee=part;gui.Size=UDim2.fromOffset(38,30);gui.StudsOffset=Vector3.new(0,part.Size.Y/2+1.5,0);gui.MaxDistance=90;gui.AlwaysOnTop=false;gui.Parent=part
                local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundColor3=Color3.fromRGB(15,19,30);label.BackgroundTransparency=0.2;label.BorderSizePixel=0;label.Text=symbol;label.TextColor3=Color3.new(1,1,1);label.TextSize=22;label.Font=Enum.Font.GothamBold;label.Parent=gui
                Accessibility.Icons[part]=gui
            end
        end
    end
end
return Accessibility
