local UI={}
UI.Colors={Navy=Color3.fromRGB(18,25,45),Panel=Color3.fromRGB(29,37,62),White=Color3.fromRGB(240,245,255),Muted=Color3.fromRGB(163,180,208),Gold=Color3.fromRGB(255,211,82),Purple=Color3.fromRGB(168,108,250),Blue=Color3.fromRGB(87,186,255),Green=Color3.fromRGB(84,224,166),Red=Color3.fromRGB(255,112,107)}
function UI.create(class,parent,properties)
    local object=Instance.new(class)
    for key,value in properties or {} do object[key]=value end
    object.Parent=parent;return object
end
function UI.round(frame,radius)
    UI.create("UICorner",frame,{CornerRadius=UDim.new(0,radius or 12)})
end
function UI.panel(parent,name,size,position)
    local frame=UI.create("Frame",parent,{Name=name,Size=size,Position=position or UDim2.new(),BackgroundColor3=UI.Colors.Panel,BackgroundTransparency=0.08,BorderSizePixel=0})
    UI.round(frame);UI.create("UIStroke",frame,{Color=UI.Colors.Purple,Transparency=0.72,Thickness=1})
    return frame
end
function UI.label(parent,name,text,size,position,textSize,color)
    return UI.create("TextLabel",parent,{Name=name,Text=text or "",Size=size,Position=position or UDim2.new(),BackgroundTransparency=1,TextColor3=color or UI.Colors.White,TextSize=textSize or 18,FontFace=Font.new("rbxasset://fonts/families/SourceSansPro.json",Enum.FontWeight.Bold,Enum.FontStyle.Normal),TextWrapped=true})
end
function UI.button(parent,name,text,size,position,color)
    local button=UI.create("TextButton",parent,{Name=name,Text=text or "",Size=size,Position=position or UDim2.new(),BackgroundColor3=color or UI.Colors.Purple,TextColor3=UI.Colors.White,TextSize=14,FontFace=Font.new("rbxasset://fonts/families/SourceSansPro.json",Enum.FontWeight.Bold,Enum.FontStyle.Normal),AutoButtonColor=true,BorderSizePixel=0})
    UI.round(button,10);return button
end
function UI.build(playerGui)
    local old=playerGui:FindFirstChild("RoyalRushHUD");if old then old:Destroy() end
    local gui=UI.create("ScreenGui",playerGui,{Name="RoyalRushHUD",ResetOnSpawn=false,IgnoreGuiInset=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=10})
    pcall(function() gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets end)
    local root=UI.create("Frame",gui,{Name="SafeRoot",Size=UDim2.fromScale(1,1),BackgroundTransparency=1})
    local header=UI.panel(root,"RoundHeader",UDim2.new(0.70,0,0,80),UDim2.new(0.5,0,0,8));header.AnchorPoint=Vector2.new(0.5,0)
    UI.create("UISizeConstraint",header,{MinSize=Vector2.new(220,80),MaxSize=Vector2.new(540,80)})
    local name=UI.label(header,"RoundName","ROYAL RUSH",UDim2.new(1,-18,0,27),UDim2.fromOffset(9,6),20,UI.Colors.Gold)
    local objective=UI.label(header,"Objective","CHAOS + CROWN",UDim2.new(1,-18,0,20),UDim2.fromOffset(9,35),14,UI.Colors.White)
    local quota=UI.label(header,"Quota","",UDim2.new(1,-18,0,17),UDim2.fromOffset(9,58),13,UI.Colors.Muted)
    local timer=UI.label(root,"Timer","00:00",UDim2.fromOffset(80,38),UDim2.new(1,-84,0,94),25,UI.Colors.Gold)
    local stats=UI.label(root,"Progress","",UDim2.new(1,-105,0,36),UDim2.fromOffset(8,96),13,UI.Colors.White);stats.TextXAlignment=Enum.TextXAlignment.Left
    local saved=UI.label(root,"SaveStatus","",UDim2.new(1,-20,0,18),UDim2.new(0,10,1,-22),11,UI.Colors.Muted)
    local chaos=UI.panel(root,"Chaos",UDim2.new(0.70,0,0,36),UDim2.new(0.5,0,0,140));chaos.AnchorPoint=Vector2.new(0.5,0);chaos.Visible=false
    UI.create("UISizeConstraint",chaos,{MaxSize=Vector2.new(470,36),MinSize=Vector2.new(220,36)})
    local chaosText=UI.label(chaos,"Event","",UDim2.fromScale(1,1),nil,16,UI.Colors.Purple)
    local toolbar=UI.create("Frame",root,{Name="LobbyToolbar",Size=UDim2.new(1,-20,0,36),Position=UDim2.fromOffset(10,187),BackgroundTransparency=1})
    local buttons={}
    for index,tab in {"Loadout","Shop","Daily","Settings"} do buttons[tab]=UI.button(toolbar,tab,string.upper(tab),UDim2.new(0.24,0,1,0),UDim2.new((index-1)*0.253,0,0,0),if tab=="Shop" then Color3.fromRGB(119,91,39) else UI.Colors.Panel) end
    local queue=UI.button(root,"Queue","AUTO QUEUE",UDim2.fromOffset(150,34),UDim2.fromOffset(10,234),UI.Colors.Panel)
    local power=UI.button(root,"Power","Q\nDASH",UDim2.fromOffset(74,74),UDim2.fromScale(0.86,0.62),UI.Colors.Blue);power.AnchorPoint=Vector2.new(0.5,0.5);UI.round(power,37);power.Visible=false
    local powerLabel=UI.label(root,"PowerHint","",UDim2.fromOffset(88,20),UDim2.fromScale(0.86,0.62),12,UI.Colors.White);powerLabel.AnchorPoint=Vector2.new(0.5,-2.2);powerLabel.Visible=false
    local watch=UI.button(root,"Watch","SPECTATE",UDim2.fromOffset(112,38),UDim2.new(0.5,-116,1,-96),UI.Colors.Purple);watch.Visible=false
    local lobby=UI.button(root,"Lobby","LOBBY",UDim2.fromOffset(112,38),UDim2.new(0.5,4,1,-96),UI.Colors.Panel);lobby.Visible=false
    local spectator=UI.panel(root,"Spectator",UDim2.fromOffset(230,40),UDim2.new(0.5,0,1,-145));spectator.AnchorPoint=Vector2.new(0.5,0);spectator.Visible=false
    local previous=UI.button(spectator,"Previous","<",UDim2.fromOffset(35,32),UDim2.fromOffset(4,4),UI.Colors.Panel)
    local next_=UI.button(spectator,"Next",">",UDim2.fromOffset(35,32),UDim2.new(1,-39,0,4),UI.Colors.Panel)
    local target=UI.label(spectator,"Target","",UDim2.new(1,-80,1,0),UDim2.fromOffset(40,0),13,UI.Colors.White)
    local toast=UI.panel(root,"Toast",UDim2.new(0.88,0,0,54),UDim2.new(0.5,0,0.40,0));toast.AnchorPoint=Vector2.new(0.5,0.5);toast.Visible=false
    UI.create("UISizeConstraint",toast,{MaxSize=Vector2.new(560,80),MinSize=Vector2.new(240,54)})
    local toastText=UI.label(toast,"Message","",UDim2.new(1,-20,1,0),UDim2.fromOffset(10,0),19,UI.Colors.White)
    local modal=UI.panel(root,"Modal",UDim2.fromScale(0.92,0.70),UDim2.fromScale(0.5,0.5));modal.AnchorPoint=Vector2.new(0.5,0.5);modal.Visible=false;modal.ZIndex=20
    UI.create("UISizeConstraint",modal,{MinSize=Vector2.new(260,260),MaxSize=Vector2.new(620,580)})
    local modalTitle=UI.label(modal,"Title","",UDim2.new(1,-96,0,40),UDim2.fromOffset(14,8),23,UI.Colors.Gold);modalTitle.TextXAlignment=Enum.TextXAlignment.Left
    local close=UI.button(modal,"Close","X",UDim2.fromOffset(40,34),UDim2.new(1,-50,0,10),UI.Colors.Panel)
    local content=UI.create("ScrollingFrame",modal,{Name="Content",Size=UDim2.new(1,-24,1,-68),Position=UDim2.fromOffset(12,56),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=5,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y})
    UI.create("UIListLayout",content,{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder})
    return {Gui=gui,Root=root,Name=name,Objective=objective,Quota=quota,Timer=timer,Stats=stats,Saved=saved,Chaos=chaos,ChaosText=chaosText,Toolbar=toolbar,Buttons=buttons,Queue=queue,Power=power,PowerHint=powerLabel,Watch=watch,Lobby=lobby,Spectator=spectator,Previous=previous,Next=next_,Target=target,Toast=toast,ToastText=toastText,Modal=modal,ModalTitle=modalTitle,Close=close,Content=content}
end
function UI.clearContent(content)
    for _,child in content:GetChildren() do if child:IsA("GuiObject") then child:Destroy() end end
end
function UI.row(content,title,detail,color)
    local row=UI.panel(content,"Card",UDim2.new(1,-8,0,96));row.BackgroundColor3=UI.Colors.Navy
    local label=UI.label(row,"Title",title,UDim2.new(1,-120,0,30),UDim2.fromOffset(10,7),15,color or UI.Colors.White);label.TextXAlignment=Enum.TextXAlignment.Left
    local description=UI.label(row,"Detail",detail,UDim2.new(1,-120,0,50),UDim2.fromOffset(10,35),13,UI.Colors.Muted);description.TextXAlignment=Enum.TextXAlignment.Left
    local action=UI.button(row,"Action","",UDim2.fromOffset(96,34),UDim2.new(1,-105,0.5,-17),UI.Colors.Purple)
    return action,row
end
return UI
