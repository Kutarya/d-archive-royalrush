local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local CAS=game:GetService("ContextActionService")
local UIS=game:GetService("UserInputService")
local Prompts=game:GetService("ProximityPromptService")
local player=Players.LocalPlayer
local Shared=RS:WaitForChild("RoyalRush")
local Config=require(Shared.Config)
local Strings=require(Shared.Strings)
local Util=require(Shared.Util)
local language=if string.sub(player.LocaleId,1,2)=="tr" then Strings.tr else Strings.en
local UI=require(script.Parent.UI)
local Effects=require(script.Parent.Effects)
local Audio=require(script.Parent.Audio)
local Accessibility=require(script.Parent.Accessibility)
require(script.Parent.SurfaceMotion).start()
local refs=UI.build(player:WaitForChild("PlayerGui"))
local network=RS:WaitForChild("RoyalRushRemotes")
local action=network:WaitForChild("Action")
local state={State="Waiting",StateVersion=-1,Status="Lobby",Queued=true,Living={},Data={Ready=false},Cooldown=0}
local settings=Util.copy(Config.Settings)
local CharacterMotion=require(script.Parent.CharacterMotion)
CharacterMotion.start(function() return settings.LowEffects end)
local tab=nil;local modalRevision=-1;local spectating=false;local targetId=nil;local tutorialShown=false;local toastUntil=0;local lastCountdown=-1
local function send(name,extras)
    local payload=extras or {};payload.Action=name;action:FireServer(payload)
end
local function toast(text,color,duration)
    refs.ToastText.Text=tostring(text or "");refs.ToastText.TextColor3=color or UI.Colors.White;refs.Toast.Visible=true;toastUntil=workspace:GetServerTimeNow()+(duration or 2.3)
end
local function resetCamera()
    local camera=workspace.CurrentCamera
    local humanoid=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if camera and humanoid then camera.CameraType=Enum.CameraType.Custom;camera.CameraSubject=humanoid end
    refs.Spectator.Visible=false;targetId=nil
end
local function chooseTarget(direction)
    if #state.Living==0 then spectating=false;resetCamera();return end
    local index=1
    for i,entry in state.Living do if entry.Id==targetId then index=i;break end end
    index=(index-1+(direction or 0))%#state.Living+1
    local entry=state.Living[index]
    if entry.Id==player.UserId and #state.Living>1 then index=index%#state.Living+1;entry=state.Living[index] end
    local target=Players:GetPlayerByUserId(entry.Id)
    local humanoid=target and target.Character and target.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        targetId=entry.Id;workspace.CurrentCamera.CameraType=Enum.CameraType.Custom;workspace.CurrentCamera.CameraSubject=humanoid;refs.Target.Text=entry.Name;refs.Spectator.Visible=true
    else targetId=nil;refs.Target.Text="Loading player...";refs.Spectator.Visible=true end
end
local function canPower()
    local playing=(state.State=="RoundActive" or state.State=="Final") and state.Status=="Active"
    local practice=not spectating and (state.Status=="Lobby" or state.Status=="Eliminated" or state.Status=="Qualified")
    return (playing or practice) and not refs.Modal.Visible
end
local function requestPower()
    if canPower() and not UIS:GetFocusedTextBox() then send("Power") end
end
refs.Power.Activated:Connect(requestPower)
CAS:BindAction("RoyalRushPower",function(_,inputState) if inputState==Enum.UserInputState.Begin and canPower() then requestPower();return Enum.ContextActionResult.Sink end;return Enum.ContextActionResult.Pass end,false,Enum.KeyCode.Q,Enum.KeyCode.ButtonX)
local function closeModal() tab=nil;refs.Modal.Visible=false end
refs.Close.Activated:Connect(closeModal)
local renderModal
local function openModal(name)
    tab=name;modalRevision=-1;refs.Modal.Visible=true;renderModal();Audio.play("Click")
end
renderModal=function()
    if not tab then return end
    local p=state.Data or {};local scroll=refs.Content.CanvasPosition
    UI.clearContent(refs.Content);refs.ModalTitle.Text=language[tab] or string.upper(tab)
    if not p.Ready then UI.row(refs.Content,"Loading","Waiting for server profile",UI.Colors.Muted);return end
    if tab=="Loadout" then
        for _,id in {"Dash","DoubleJump","Shield"} do
            local item=Config.Powers[id]
            local button=UI.row(refs.Content,item.Name,item.Description.." • "..item.Cooldown.."s",Color3.fromRGB(unpack(item.Color)))
            button.Text=if p.SelectedPower==id then language.Selected else language.Select
            button.Activated:Connect(function() send("Loadout",{Id=id}) end)
        end
    elseif tab=="Shop" then
        for _,id in Config.CosmeticOrder do
            local item=Config.Cosmetics[id];local owned=p.OwnedCosmetics and p.OwnedCosmetics[id]
            local equipped=p.EquippedCosmetics and p.EquippedCosmetics[item.Kind]==id
            local button=UI.row(refs.Content,item.Name,item.Kind.." • "..item.Rarity.." • "..item.Price.." Crowns",UI.Colors.Gold)
            button.Text=if equipped then language.Equipped elseif owned then language.Equip else language.Buy
            button.BackgroundColor3=if equipped then Color3.fromRGB(43,103,87) else UI.Colors.Purple
            button.Activated:Connect(function() send(if owned then "Equip" else "Buy",{Id=id}) end)
        end
    elseif tab=="Daily" then
        local claimed=p.Daily.LastDay>=p.Day;local step=p.Daily.Step%7+1
        for index,reward in Config.Daily do
            local detail=if reward.Cosmetic then Config.Cosmetics[reward.Cosmetic].Name elseif reward.XP then "+"..reward.XP.." XP" else "+"..reward.Crowns.." Crowns"
            local button=UI.row(refs.Content,"DAY "..index,detail,if index==step then UI.Colors.Gold else UI.Colors.Muted)
            button.Text=if index==step and not claimed then language.Claim elseif index==p.Daily.Step and claimed then language.Claimed else "—"
            button.Active=index==step and not claimed;button.AutoButtonColor=button.Active
            if button.Active then button.Activated:Connect(function() send("Daily") end) end
        end
        local heading=UI.label(refs.Content,"QuestHeader",language.Quest,UDim2.new(1,-8,0,34),nil,18,UI.Colors.Purple)
        for _,quest in Config.Quests do
            local count=p.Quests.Counts[quest.Id] or 0
            local button=UI.row(refs.Content,quest.Name,count.." / "..quest.Target.." • +"..quest.Crowns.." Crowns",UI.Colors.White)
            button.Text=if p.Quests.Claimed[quest.Id] then language.Claimed else language.Claim
            button.Activated:Connect(function() send("Quest",{Id=quest.Id}) end)
        end
    elseif tab=="Settings" then
        for _,key in {"Music","SFX","ReducedShake","ReducedParticles","ColorAssist","AutoSpectate","LowEffects"} do
            local value=settings[key]
            local button=UI.row(refs.Content,key,if type(value)=="number" then "Tap to cycle volume" else "Tap to toggle",UI.Colors.White)
            button.Text=if type(value)=="number" then tostring(math.floor(value*100)).."%" else (if value then "ON" else "OFF")
            button.Activated:Connect(function()
                local nextValue=if type(value)=="number" then (math.floor(value*4+0.1)+1)%5/4 else not value
                settings[key]=nextValue;Audio.configure(settings);send("Settings",{Settings={[key]=nextValue}});renderModal()
            end)
        end
    elseif tab=="Leaderboard" then
        if #(state.Board or {})==0 then UI.row(refs.Content,"NO RESULTS YET","Earn a Crown to appear",UI.Colors.Gold) end
        for index,entry in state.Board or {} do UI.row(refs.Content,"#"..index.."  "..entry.Name,entry.Wins.." "..(if entry.Local then language.LocalWins else language.Wins),UI.Colors.Gold) end
    end
    refs.Content.CanvasPosition=scroll;modalRevision=tostring(p.Revision or 0)..":"..tostring(p.Day or 0)
end
for name,button in refs.Buttons do button.Text=language[name] or name;button.Activated:Connect(function() openModal(name) end) end
refs.Queue.Activated:Connect(function() send("Queue",{Enabled=not state.Queued}) end)
refs.Watch.Text=language.Watch;refs.Lobby.Text=language.Lobby
refs.Watch.Activated:Connect(function() spectating=not spectating;if spectating then chooseTarget(0) else resetCamera() end end)
refs.Lobby.Activated:Connect(function() spectating=false;resetCamera();send("Lobby") end)
refs.Previous.Activated:Connect(function() chooseTarget(-1) end);refs.Next.Activated:Connect(function() chooseTarget(1) end)
local gear=UI.button(refs.Root,"ActiveSettings","⚙",UDim2.fromOffset(32,30),UDim2.fromOffset(10,141),UI.Colors.Panel)
gear.Visible=false;gear.Activated:Connect(function() openModal("Settings") end)
Prompts.PromptTriggered:Connect(function(prompt,who)
    if who and who~=player then return end
    local name=prompt.ObjectText
    local tabs={LOADOUT="Loadout",SHOP="Shop",DAILY="Daily",LEADERBOARD="Leaderboard"}
    if tabs[name] then openModal(tabs[name]) end
end)
local function applySnapshot(snapshot)
    if snapshot.StateVersion<state.StateVersion then return end
    local previous=state;state=snapshot
    if state.Data and state.Data.Settings then settings=Util.copy(state.Data.Settings);Audio.configure(settings) end
    local active=state.Status=="Active" or state.Status=="Preparing" or state.Status=="Recovering"
    refs.Toolbar.Visible=not active;refs.Queue.Visible=not active;gear.Visible=active
    refs.Queue.Text=if state.Queued then language.Queue else language.Paused
    refs.Watch.Visible=not active and #state.Living>0;refs.Lobby.Visible=not active and (state.Status=="Eliminated" or state.Status=="Qualified" or spectating)
    if active then
        if spectating or previous.Status~=state.Status or previous.RoundId~=state.RoundId then resetCamera() end
        spectating=false;if previous.RoundId~=state.RoundId then closeModal() end
    end
    if state.Status~=previous.Status and (state.Status=="Eliminated" or state.Status=="Qualified") and settings.AutoSpectate and #state.Living>0 then spectating=true;chooseTarget(0) end
    if spectating then
        local found=false;for _,entry in state.Living do if entry.Id==targetId then found=true end end
        if not found then chooseTarget(0) end
    end
    refs.Stats.Text=if state.Data.Ready then "LV "..state.Data.Level.."   •   "..state.Data.Crowns.." CROWNS" else "Loading profile..."
    refs.Saved.Text=if state.Data.Ready and not state.Data.Persistent then (if state.Data.Mutable then language.Temporary else language.ReadOnly) else (state.Data.SaveStatus or "")
    refs.Saved.TextColor3=if not state.Data.Persistent then UI.Colors.Gold else UI.Colors.Muted
    if state.State=="Waiting" then refs.Name.Text=language.Waiting;refs.Objective.Text="ROYAL RUSH • CHAOS + CROWN";refs.Quota.Text=if state.Solo then "SOLO STUDIO PREVIEW" else "2–16 PLAYERS"
    elseif state.State=="Intermission" then refs.Name.Text=language.Next;refs.Objective.Text=if state.Solo then "SOLO STUDIO PREVIEW" else "ROYAL RUSH";refs.Quota.Text=if state.Competitive then "CROWN TOURNAMENT" else "LOCAL MATCH"
    elseif state.State=="Results" then refs.Name.Text=if state.Result and state.Result.Winner then state.Result.Winner.." WINS!" else language.NoWinner;refs.Objective.Text=state.Result and state.Result.Reason or "";refs.Quota.Text="NEXT MATCH SOON"
    else refs.Name.Text=state.Map;refs.Objective.Text=language[state.Mode] or state.Mode;refs.Quota.Text=if state.Mode=="Race" then "QUALIFIED "..state.Qualified.." / "..state.Quota else "ALIVE "..state.Alive end
    if state.Status=="Lobby" and (state.State=="RoundActive" or state.State=="Final" or state.State=="Transition") then
        refs.Objective.Text=language.NextMatch;refs.Quota.Text="ROUND "..state.RoundIndex.." • "..language.Watch
    end
    refs.Chaos.Visible=state.Chaos~=nil
    if state.Chaos then refs.ChaosText.Text=state.Chaos.Name end
    if tab and modalRevision~=(tostring(state.Data.Revision or 0)..":"..tostring(state.Data.Day or 0)) then renderModal() end
    if state.Data.Ready and state.Data.TutorialVersion==0 and not tutorialShown then
        tutorialShown=true;toast(language.Tutorial,UI.Colors.Gold,6);send("Tutorial")
    end
    if previous.State~=state.State then Audio.music(if state.State=="Final" then "FinalMusic" elseif state.State=="RoundActive" then "RoundMusic" else "LobbyMusic") end
end
network:WaitForChild("State").OnClientEvent:Connect(applySnapshot)
network:WaitForChild("Effect").OnClientEvent:Connect(function(name,data)
    local low=settings.LowEffects or settings.ReducedParticles
    if name=="Prepare" then
        spectating=false;resetCamera();closeModal()
        local position=data.Position
        workspace.CurrentCamera.CFrame=CFrame.lookAt(position+Vector3.new(0,8,-16),position+Vector3.new(0,2,4))
        task.spawn(function()
            local ok=pcall(function() player:RequestStreamAroundAsync(data.Position,3) end)
            if ok then send("Ready",{RoundId=data.RoundId}) else toast("Map streaming failed. Waiting for next match.",UI.Colors.Gold,4) end
        end)
    elseif name=="Toast" then toast(data.Text)
    elseif name=="Qualified" then toast(language.Qualified..(if data.Placement then "  #"..data.Placement..(if data.Tie then " TIE" else "") else "")..(if data.Clutch then "  CLUTCH!" elseif data.Perfect then "  PERFECT!" else "")..(if state.Data.Mutable and data.XP then "  +"..data.XP.." XP" else ""),UI.Colors.Green,3);Audio.play("Qualified")
    elseif name=="Eliminated" then toast(language.Eliminated.." • "..tostring(data.Reason),UI.Colors.Red,3);Audio.play("Eliminated")
    elseif name=="Recovered" then toast("CHECKPOINT • "..data.Reason,UI.Colors.Blue,1)
    elseif name=="ChaosWarning" then toast(language.Chaos,UI.Colors.Purple,2.5);Audio.play("Warning")
    elseif name=="ChaosStart" then toast(data.Name,UI.Colors.Purple,2);Audio.play("Warning")
    elseif name=="MeteorWarning" then Effects.meteorWarning(data,low)
    elseif name=="MeteorHit" then Effects.meteorHit(data,low)
    elseif name=="ShockwaveWarning" then Effects.shock(data,true)
    elseif name=="ShockwaveHit" then Effects.shock(data,false)
    elseif name=="Power" then CharacterMotion.power(data);Effects.power(data,low);if data.UserId==player.UserId then Audio.play("Power") end
    elseif name=="Overtime" then toast("OVERTIME!",UI.Colors.Gold,3)
    elseif name=="Results" then
        spectating=false;resetCamera();closeModal()
        local reward=if data.WinnerId==player.UserId then "  +"..(data.RewardXP or 0).." XP / +"..(data.RewardCrowns or 0).." CROWNS" else ""
        toast(if data.Winner then data.Winner.." WINS THE CROWN!"..reward else language.NoWinner,UI.Colors.Gold,5)
        if data.Winner then Effects.confetti(refs.Root,low,data.VictoryColor);Audio.play("Victory") end
    end
end)
player.CharacterAdded:Connect(function() task.defer(function() if not spectating then resetCamera() end end) end)
local lastEffects=0
RunService.RenderStepped:Connect(function()
    local now=workspace:GetServerTimeNow();local remaining=math.max(0,(state.Deadline or 0)-now)
    refs.Timer.Text=if state.State=="Waiting" then "—" else string.format("%02d:%02d",math.floor(remaining/60),math.floor(remaining%60))
    if state.State=="RoundIntro" then
        local count=math.max(1,math.ceil(remaining));refs.Quota.Text=tostring(count).."..."
        if count~=lastCountdown then lastCountdown=count;Audio.play("Countdown") end
    else lastCountdown=-1 end
    if state.Chaos and state.Chaos.Next then refs.ChaosText.Text=language.Chaos.." "..math.max(0,math.ceil(state.Chaos.Next-now)) end
    refs.Power.Visible=canPower();refs.PowerHint.Visible=refs.Power.Visible
    local cd=math.max(0,(state.Cooldown or 0)-now)
    local power=Config.Powers[state.Power or "Dash"]
    refs.Power.Text=if cd>0 then tostring(math.ceil(cd)) else (if UIS.TouchEnabled then language.Power else "Q")
    refs.PowerHint.Text=power and power.Name or "Dash";refs.Power.BackgroundColor3=if cd>0 then UI.Colors.Panel else UI.Colors.Blue
    local smallHeight=refs.Root.AbsoluteSize.Y<450
    refs.Power.Position=UDim2.fromScale(0.86,if smallHeight then 0.48 else 0.62);refs.PowerHint.Position=refs.Power.Position
    if now>=toastUntil then refs.Toast.Visible=false end
    if now-lastEffects>1 then
        lastEffects=now
        Accessibility.update(workspace:FindFirstChild("RoyalRushArena"),settings.ColorAssist)
        for _,object in workspace:GetDescendants() do
            if object:IsA("Trail") and object.Parent and object.Parent.Name=="RoyalCosmetics" then object.Enabled=not settings.ReducedParticles and not settings.LowEffects end
        end
    end
end)
send("Sync")
print("[Royal Rush client] "..Config.Version.." • Q or touch POWER")
