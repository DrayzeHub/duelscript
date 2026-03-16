-- EGO Duels - FULL SCRIPT (SAVE SİSTEMİ + ENTEGRE AYARLAR)
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")

local me = Players.LocalPlayer
local getconnections = getconnections or get_signal_cons or getconnects or (syn and syn.get_signal_cons)
local isfile = isfile or function() return false end
local readfile = readfile or function() return "" end
local writefile = writefile or function() end

local CONFIG_FILE = "EgoDuelsConfig.json"

local L1     = Vector3.new(-476.48, -6.28,  92.73)
local LEND   = Vector3.new(-483.12, -4.95,  94.80)
local LFINAL = Vector3.new(-473.38, -8.40,  22.34)
local R1     = Vector3.new(-476.16, -6.52,  25.62)
local REND   = Vector3.new(-483.04, -5.09,  23.14)
local RFINAL = Vector3.new(-476.17, -7.91,  97.91)
local FSPD   = 59
local RSPD   = 30

local aplConn, aprConn = nil, nil
local aplOn, aprOn = false, false
local aplPhase, aprPhase = 1, 1

local batAimbotOn = false
local BAT_MOVE_SPEED = 56.5
local BAT_ENGAGE_RANGE = 20
local BAT_LOOP_TIME = 0.3
local lastEquipTick, lastUseTick = 0, 0
local lookConnection, attachment_bat, alignOrientation_bat = nil, nil, nil
local BAT_LOOK_DISTANCE = 50

local char, hum, hrp = nil, nil, nil

local autoGrabEnabled = false
local isGrabbing = false
local autoGrabConn = nil
local GrabStealData = {}
local GRAB_RADIUS = 20
local GRAB_STEAL_DURATION = 0.2
local ProgressBarFill, ProgressText = nil, nil

local antiRagdollEnabled = false
local antiRagdollConn = nil

local espEnabled = false
local espConnections, espObjects = {}, {}

local optimizerEnabled = false
local xrayEnabled = false
local originalTransparency = {}

local unwalkEnabled = false
local savedAnimate = nil

local btnPositions = {
    AutoPlayLeft = {X = 30, Y = 300},
    AutoPlayRight = {X = 30, Y = 360},
    BatAimbot = {X = 30, Y = 420},
    MenuButton = {X = 30, Y = 500},
}

local keyBinds = {
    AutoPlayLeft = "G",
    AutoPlayRight = "H",
    BatAimbot = "X",
}

local function saveConfig()
    pcall(function()
        local data = {
            FSPD = FSPD, RSPD = RSPD, GRAB_RADIUS = GRAB_RADIUS,
            antiRagdollEnabled = antiRagdollEnabled, espEnabled = espEnabled,
            optimizerEnabled = optimizerEnabled, unwalkEnabled = unwalkEnabled,
            autoGrabEnabled = autoGrabEnabled, btnPositions = btnPositions, keyBinds = keyBinds,
        }
        writefile(CONFIG_FILE, HttpService:JSONEncode(data))
    end)
end

local function loadConfig()
    local ok, result = pcall(function()
        if isfile(CONFIG_FILE) then return HttpService:JSONDecode(readfile(CONFIG_FILE)) end
        return nil
    end)
    if ok and result then
        FSPD = result.FSPD or 59
        RSPD = result.RSPD or 30
        GRAB_RADIUS = result.GRAB_RADIUS or 20
        antiRagdollEnabled = result.antiRagdollEnabled or false
        espEnabled = result.espEnabled or false
        optimizerEnabled = result.optimizerEnabled or false
        unwalkEnabled = result.unwalkEnabled or false
        autoGrabEnabled = result.autoGrabEnabled or false
        if result.btnPositions then btnPositions = result.btnPositions end
        if result.keyBinds then keyBinds = result.keyBinds end
        return true
    end
    return false
end

loadConfig()

local function getHRP() return hrp end
local function getHum() return hum end

local function startAntiRagdoll()
    if antiRagdollConn then return end
    antiRagdollConn = RS.Heartbeat:Connect(function()
        if not antiRagdollEnabled or not char then return end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if humanoid then
            local st = humanoid:GetState()
            if st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown then
                humanoid:ChangeState(Enum.HumanoidStateType.Running)
                workspace.CurrentCamera.CameraSubject = humanoid
                pcall(function()
                    local PM = me.PlayerScripts:FindFirstChild("PlayerModule")
                    if PM then local C = require(PM:FindFirstChild("ControlModule")) if C then C:Enable() end end
                end)
                if root then root.Velocity = Vector3.new(0,0,0) root.RotVelocity = Vector3.new(0,0,0) end
            end
        end
        for _, obj in ipairs(char:GetDescendants()) do
            pcall(function() if obj:IsA("Motor6D") and not obj.Enabled then obj.Enabled = true end end)
        end
    end)
end

local function stopAntiRagdoll()
    if antiRagdollConn then antiRagdollConn:Disconnect() antiRagdollConn = nil end
end

local function createESP(plr)
    if plr == me or not plr.Character then return end
    if plr.Character:FindFirstChild("ScriptESP") then return end
    local charHrp = plr.Character:FindFirstChild("HumanoidRootPart")
    if not charHrp then return end
    local h = plr.Character:FindFirstChildOfClass("Humanoid")
    if h then h.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
    local box = Instance.new("BoxHandleAdornment")
    box.Name = "ScriptESP" box.Adornee = charHrp
    box.Size = Vector3.new(4, 6, 2) box.Color3 = Color3.fromRGB(255, 255, 255)
    box.Transparency = 0.5 box.ZIndex = 10 box.AlwaysOnTop = true box.Parent = plr.Character
    espObjects[plr] = {box = box}
end

local function removeESP(plr)
    pcall(function()
        if plr.Character then
            local b = plr.Character:FindFirstChild("ScriptESP") if b then b:Destroy() end
            local h = plr.Character:FindFirstChildOfClass("Humanoid")
            if h then h.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Automatic end
        end
        espObjects[plr] = nil
    end)
end

local function enableESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= me then
            if plr.Character then pcall(function() createESP(plr) end) end
            table.insert(espConnections, plr.CharacterAdded:Connect(function()
                task.wait(0.1) if espEnabled then pcall(function() createESP(plr) end) end
            end))
        end
    end
    table.insert(espConnections, Players.PlayerAdded:Connect(function(plr)
        if plr == me then return end
        table.insert(espConnections, plr.CharacterAdded:Connect(function()
            task.wait(0.1) if espEnabled then pcall(function() createESP(plr) end) end
        end))
    end))
end

local function disableESP()
    for _, plr in ipairs(Players:GetPlayers()) do pcall(function() removeESP(plr) end) end
    for _, c in ipairs(espConnections) do if c and c.Connected then c:Disconnect() end end
    espConnections = {} espObjects = {}
end

local function enableOptimizer()
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        Lighting.GlobalShadows = false Lighting.Brightness = 2
        Lighting.FogEnd = 9e9 Lighting.FogStart = 9e9
        for _, fx in ipairs(Lighting:GetChildren()) do if fx:IsA("PostEffect") then fx.Enabled = false end end
    end)
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do pcall(function()
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                obj.Enabled = false obj:Destroy()
            elseif obj:IsA("SelectionBox") then obj:Destroy()
            elseif obj:IsA("BasePart") then
                obj.CastShadow = false obj.Material = Enum.Material.Plastic
                for _, ch in ipairs(obj:GetChildren()) do
                    if ch:IsA("Decal") or ch:IsA("Texture") or ch:IsA("SurfaceAppearance") then ch:Destroy() end
                end
            elseif obj:IsA("Sky") then obj:Destroy() end
        end) end
    end)
    xrayEnabled = true
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Anchored and (obj.Name:lower():find("base") or (obj.Parent and obj.Parent.Name:lower():find("base"))) then
                originalTransparency[obj] = obj.LocalTransparencyModifier
                obj.LocalTransparencyModifier = 0.88
            end
        end
    end)
end

local function disableOptimizer()
    if xrayEnabled then
        for p, v in pairs(originalTransparency) do if p then p.LocalTransparencyModifier = v end end
        originalTransparency = {} xrayEnabled = false
    end
end

local function startUnwalk()
    if not char then return end
    local anim = char:FindFirstChild("Animate")
    if anim then savedAnimate = anim:Clone() anim.Disabled = true task.wait() anim:Destroy() end
    local h2 = char:FindFirstChildOfClass("Humanoid")
    if h2 then for _, t in ipairs(h2:GetPlayingAnimationTracks()) do t:Stop() end end
end

local function stopUnwalk()
    if savedAnimate and char then local na = savedAnimate:Clone() na.Parent = char na.Disabled = false end
end

local function isMyPlot(pn)
    local plots = workspace:FindFirstChild("Plots") if not plots then return false end
    local plot = plots:FindFirstChild(pn) if not plot then return false end
    local sign = plot:FindFirstChild("PlotSign")
    if sign then local yb = sign:FindFirstChild("YourBase")
        if yb and yb:IsA("BillboardGui") then return yb.Enabled == true end
    end
    return false
end

local function findGrabPrompt()
    if not hrp then return nil, nil, nil end
    local plots = workspace:FindFirstChild("Plots") if not plots then return nil, nil, nil end
    local np, nd, nn = nil, math.huge, nil
    for _, plot in ipairs(plots:GetChildren()) do
        if isMyPlot(plot.Name) then continue end
        local podiums = plot:FindFirstChild("AnimalPodiums") if not podiums then continue end
        for _, pod in ipairs(podiums:GetChildren()) do pcall(function()
            local base = pod:FindFirstChild("Base")
            local spawn = base and base:FindFirstChild("Spawn")
            if spawn then
                local dist = (spawn.Position - hrp.Position).Magnitude
                if dist < nd and dist <= GRAB_RADIUS then
                    local att = spawn:FindFirstChild("PromptAttachment")
                    if att then for _, ch in ipairs(att:GetChildren()) do
                        if ch:IsA("ProximityPrompt") then np, nd, nn = ch, dist, pod.Name break end
                    end end
                end
            end
        end) end
    end
    return np, nd, nn
end

local function executeGrab(prompt)
    if isGrabbing then return end
    if not GrabStealData[prompt] then
        GrabStealData[prompt] = {hold = {}, trigger = {}, ready = true}
        pcall(function() if getconnections then
            for _, c in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do if c.Function then table.insert(GrabStealData[prompt].hold, c.Function) end end
            for _, c in ipairs(getconnections(prompt.Triggered)) do if c.Function then table.insert(GrabStealData[prompt].trigger, c.Function) end end
        end end)
    end
    local data = GrabStealData[prompt] if not data.ready then return end
    data.ready = false isGrabbing = true
    local gs = tick()
    local gpc = RS.Heartbeat:Connect(function()
        if not isGrabbing then return end
        local prog = math.clamp((tick() - gs) / GRAB_STEAL_DURATION, 0, 1)
        if ProgressBarFill then ProgressBarFill.Size = UDim2.new(prog, 0, 1, 0) end
        if ProgressText then ProgressText.Text = math.floor(prog * 100) .. "%" end
    end)
    task.spawn(function()
        for _, f in ipairs(data.hold) do task.spawn(f) end
        task.wait(GRAB_STEAL_DURATION)
        for _, f in ipairs(data.trigger) do task.spawn(f) end
        gpc:Disconnect()
        if ProgressBarFill then ProgressBarFill.Size = UDim2.new(0, 0, 1, 0) end
        if ProgressText then ProgressText.Text = "0%" end
        data.ready = true isGrabbing = false
    end)
end

local function startAutoGrab()
    if autoGrabConn then autoGrabConn:Disconnect() end
    autoGrabConn = RS.Heartbeat:Connect(function()
        if not autoGrabEnabled or isGrabbing then return end
        local p = findGrabPrompt() if p then executeGrab(p) end
    end)
end

local function stopAutoGrab()
    if autoGrabConn then autoGrabConn:Disconnect() autoGrabConn = nil end
    isGrabbing = false
    if ProgressBarFill then ProgressBarFill.Size = UDim2.new(0, 0, 1, 0) end
    if ProgressText then ProgressText.Text = "0%" end
end

local function equipBat()
    if not hum then return end
    local bt = me.Backpack:FindFirstChild("Bat") or char:FindFirstChild("Bat")
    if bt then hum:EquipTool(bt) end
end

local function nearestPlayer()
    if not hrp then return nil, math.huge end
    local cl, md = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= me and p.Character then
            local th = p.Character:FindFirstChild("HumanoidRootPart")
            local thum = p.Character:FindFirstChildOfClass("Humanoid")
            if th and thum and thum.Health > 0 then
                local d = (th.Position - hrp.Position).Magnitude
                if d < md then md = d cl = th end
            end
        end
    end
    return cl, md
end

local function closestLookTarget()
    if not hrp then return nil end
    local n, s = nil, BAT_LOOK_DISTANCE
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= me and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local d = (hrp.Position - p.Character.HumanoidRootPart.Position).Magnitude
            if d < s then s = d n = p.Character.HumanoidRootPart end
        end
    end
    return n
end

local function startLookAt()
    if not hrp or not hum then return end
    hum.AutoRotate = false
    attachment_bat = Instance.new("Attachment", hrp)
    alignOrientation_bat = Instance.new("AlignOrientation")
    alignOrientation_bat.Attachment0 = attachment_bat
    alignOrientation_bat.Mode = Enum.OrientationAlignmentMode.OneAttachment
    alignOrientation_bat.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    alignOrientation_bat.Responsiveness = 1000
    alignOrientation_bat.RigidityEnabled = true
    alignOrientation_bat.Parent = hrp
    lookConnection = RS.RenderStepped:Connect(function()
        if not hrp or not alignOrientation_bat then return end
        local t = closestLookTarget() if not t then return end
        alignOrientation_bat.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(t.Position.X, hrp.Position.Y, t.Position.Z))
    end)
end

local function stopLookAt()
    if lookConnection then lookConnection:Disconnect() lookConnection = nil end
    if alignOrientation_bat then alignOrientation_bat:Destroy() alignOrientation_bat = nil end
    if attachment_bat then attachment_bat:Destroy() attachment_bat = nil end
    if hum then hum.AutoRotate = true end
end

local function stopBatAimbot()
    batAimbotOn = false stopLookAt()
    if hrp then hrp.AssemblyLinearVelocity = Vector3.zero end
end

local function startBatAimbot()
    stopBatAimbot() batAimbotOn = true
    if not char or not hrp or not hum then return end
    startLookAt()
end

RS.Heartbeat:Connect(function()
    if not batAimbotOn or not char or not hrp or not hum then return end
    hrp.CanCollide = false
    local t, d = nearestPlayer() if not t then return end
    hrp.AssemblyLinearVelocity = (t.Position - hrp.Position).Unit * BAT_MOVE_SPEED
    if d <= BAT_ENGAGE_RANGE then
        if tick() - lastEquipTick >= BAT_LOOP_TIME then equipBat() lastEquipTick = tick() end
        if tick() - lastUseTick >= BAT_LOOP_TIME then
            local bt = char:FindFirstChild("Bat") if bt then bt:Activate() end
            lastUseTick = tick()
        end
    end
end)

local function stopAutoPlayLeft()
    if aplConn then aplConn:Disconnect() aplConn = nil end
    aplPhase = 1 aplOn = false
    if hum then hum:Move(Vector3.zero, false) end
end

local function startAutoPlayLeft()
    if aplConn then aplConn:Disconnect() end
    aplPhase = 1
    aplConn = RS.Heartbeat:Connect(function()
        if not aplOn then return end
        local h, hu = getHRP(), getHum() if not h or not hu then return end
        if aplPhase == 1 then
            local d = Vector3.new(L1.X-h.Position.X,0,L1.Z-h.Position.Z)
            if d.Magnitude<1 then aplPhase=2 return end
            local m=d.Unit hu:Move(m,false) h.AssemblyLinearVelocity=Vector3.new(m.X*FSPD,h.AssemblyLinearVelocity.Y,m.Z*FSPD)
        elseif aplPhase == 2 then
            local d = Vector3.new(LEND.X-h.Position.X,0,LEND.Z-h.Position.Z)
            if d.Magnitude<1 then aplPhase=0 hu:Move(Vector3.zero,false) h.AssemblyLinearVelocity=Vector3.new(0,0,0) task.delay(0.1,function() if aplOn then aplPhase=3 end end) return end
            local m=d.Unit hu:Move(m,false) h.AssemblyLinearVelocity=Vector3.new(m.X*FSPD,h.AssemblyLinearVelocity.Y,m.Z*FSPD)
        elseif aplPhase == 0 then return
        elseif aplPhase == 3 then
            local d = Vector3.new(L1.X-h.Position.X,0,L1.Z-h.Position.Z)
            if d.Magnitude<1 then aplPhase=4 return end
            local m=d.Unit hu:Move(m,false) h.AssemblyLinearVelocity=Vector3.new(m.X*RSPD,h.AssemblyLinearVelocity.Y,m.Z*RSPD)
        elseif aplPhase == 4 then
            local d = Vector3.new(LFINAL.X-h.Position.X,0,LFINAL.Z-h.Position.Z)
            if d.Magnitude<1 then hu:Move(Vector3.zero,false) h.AssemblyLinearVelocity=Vector3.new(0,0,0) stopAutoPlayLeft() return end
            local m=d.Unit hu:Move(m,false) h.AssemblyLinearVelocity=Vector3.new(m.X*RSPD,h.AssemblyLinearVelocity.Y,m.Z*RSPD)
        end
    end)
end

local function stopAutoPlayRight()
    if aprConn then aprConn:Disconnect() aprConn = nil end
    aprPhase = 1 aprOn = false
    if hum then hum:Move(Vector3.zero, false) end
end

local function startAutoPlayRight()
    if aprConn then aprConn:Disconnect() end
    aprPhase = 1
    aprConn = RS.Heartbeat:Connect(function()
        if not aprOn then return end
        local h, hu = getHRP(), getHum() if not h or not hu then return end
        if aprPhase == 1 then
            local d = Vector3.new(R1.X-h.Position.X,0,R1.Z-h.Position.Z)
            if d.Magnitude<1 then aprPhase=2 return end
            local m=d.Unit hu:Move(m,false) h.AssemblyLinearVelocity=Vector3.new(m.X*FSPD,h.AssemblyLinearVelocity.Y,m.Z*FSPD)
        elseif aprPhase == 2 then
            local d = Vector3.new(REND.X-h.Position.X,0,REND.Z-h.Position.Z)
            if d.Magnitude<1 then aprPhase=0 hu:Move(Vector3.zero,false) h.AssemblyLinearVelocity=Vector3.new(0,0,0) task.delay(0.1,function() if aprOn then aprPhase=3 end end) return end
            local m=d.Unit hu:Move(m,false) h.AssemblyLinearVelocity=Vector3.new(m.X*FSPD,h.AssemblyLinearVelocity.Y,m.Z*FSPD)
        elseif aprPhase == 0 then return
        elseif aprPhase == 3 then
            local d = Vector3.new(R1.X-h.Position.X,0,R1.Z-h.Position.Z)
            if d.Magnitude<1 then aprPhase=4 return end
            local m=d.Unit hu:Move(m,false) h.AssemblyLinearVelocity=Vector3.new(m.X*RSPD,h.AssemblyLinearVelocity.Y,m.Z*RSPD)
        elseif aprPhase == 4 then
            local d = Vector3.new(RFINAL.X-h.Position.X,0,RFINAL.Z-h.Position.Z)
            if d.Magnitude<1 then hu:Move(Vector3.zero,false) h.AssemblyLinearVelocity=Vector3.new(0,0,0) stopAutoPlayRight() return end
            local m=d.Unit hu:Move(m,false) h.AssemblyLinearVelocity=Vector3.new(m.X*RSPD,h.AssemblyLinearVelocity.Y,m.Z*RSPD)
        end
    end)
end

local gui = Instance.new("ScreenGui")
gui.Name = "AutoPlayGUI" gui.ResetOnSpawn = false gui.Parent = CoreGui

local keybinds = {}
local waitingForKey = nil
local resetFunctions = {}

local PC = Instance.new("Frame", gui)
PC.Size = UDim2.new(0,400,0,15) PC.AnchorPoint = Vector2.new(0.5,0)
PC.Position = UDim2.new(0.5,0,0.05,0) PC.BackgroundColor3 = Color3.fromRGB(15,15,15)
PC.BorderSizePixel = 0 PC.Visible = false PC.ZIndex = 10
Instance.new("UICorner", PC).CornerRadius = UDim.new(0,8)
Instance.new("UIStroke", PC).Color = Color3.fromRGB(80,80,80)

ProgressBarFill = Instance.new("Frame", PC)
ProgressBarFill.Size = UDim2.new(0,0,1,0) ProgressBarFill.BackgroundColor3 = Color3.fromRGB(255,255,255)
ProgressBarFill.BorderSizePixel = 0 ProgressBarFill.ZIndex = 11
Instance.new("UICorner", ProgressBarFill).CornerRadius = UDim.new(0,8)

ProgressText = Instance.new("TextLabel", PC)
ProgressText.Size = UDim2.new(1,0,1,0) ProgressText.BackgroundTransparency = 1
ProgressText.Text = "0%" ProgressText.TextColor3 = Color3.fromRGB(255,255,255)
ProgressText.Font = Enum.Font.GothamBold ProgressText.TextSize = 12 ProgressText.ZIndex = 12

RS.Heartbeat:Connect(function() PC.Visible = autoGrabEnabled end)

local speedPanel = Instance.new("Frame", gui)
speedPanel.Size = UDim2.new(0,160,0,80)
speedPanel.BackgroundColor3 = Color3.fromRGB(10,10,10) speedPanel.BorderSizePixel = 0
speedPanel.Visible = false
Instance.new("UICorner", speedPanel).CornerRadius = UDim.new(0,8)
Instance.new("UIStroke", speedPanel).Color = Color3.fromRGB(60,60,60)

local fl = Instance.new("TextLabel", speedPanel)
fl.Size = UDim2.new(0,80,0,30) fl.Position = UDim2.new(0,8,0,5)
fl.BackgroundTransparency = 1 fl.Text = "First:" fl.TextColor3 = Color3.fromRGB(200,200,200)
fl.TextSize = 12 fl.Font = Enum.Font.GothamSemibold fl.TextXAlignment = Enum.TextXAlignment.Left

local fi = Instance.new("TextBox", speedPanel)
fi.Size = UDim2.new(0,55,0,22) fi.Position = UDim2.new(0,90,0,9)
fi.BackgroundColor3 = Color3.fromRGB(30,30,30) fi.Text = tostring(FSPD)
fi.TextColor3 = Color3.fromRGB(255,255,255) fi.TextSize = 13 fi.Font = Enum.Font.GothamBold
fi.BorderSizePixel = 0 fi.TextXAlignment = Enum.TextXAlignment.Center fi.ClearTextOnFocus = false
Instance.new("UICorner", fi).CornerRadius = UDim.new(0,4)
fi.FocusLost:Connect(function()
    local n = tonumber(fi.Text) if n then FSPD = math.clamp(math.floor(n),5,100) end
    fi.Text = tostring(FSPD) saveConfig()
end)

local rl2 = Instance.new("TextLabel", speedPanel)
rl2.Size = UDim2.new(0,80,0,30) rl2.Position = UDim2.new(0,8,0,40)
rl2.BackgroundTransparency = 1 rl2.Text = "Return:" rl2.TextColor3 = Color3.fromRGB(200,200,200)
rl2.TextSize = 12 rl2.Font = Enum.Font.GothamSemibold rl2.TextXAlignment = Enum.TextXAlignment.Left

local ri2 = Instance.new("TextBox", speedPanel)
ri2.Size = UDim2.new(0,55,0,22) ri2.Position = UDim2.new(0,90,0,44)
ri2.BackgroundColor3 = Color3.fromRGB(30,30,30) ri2.Text = tostring(RSPD)
ri2.TextColor3 = Color3.fromRGB(255,255,255) ri2.TextSize = 13 ri2.Font = Enum.Font.GothamBold
ri2.BorderSizePixel = 0 ri2.TextXAlignment = Enum.TextXAlignment.Center ri2.ClearTextOnFocus = false
Instance.new("UICorner", ri2).CornerRadius = UDim.new(0,4)
ri2.FocusLost:Connect(function()
    local n = tonumber(ri2.Text) if n then RSPD = math.clamp(math.floor(n),5,100) end
    ri2.Text = tostring(RSPD) saveConfig()
end)

local speedSettingsOpen = false

local function createButton(name, posKey, defaultKey, toggleCallback, hasSettings)
    local pos = btnPositions[posKey]
    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0, hasSettings and 240 or 200, 0, 50)
    frame.Position = UDim2.new(0, pos.X, 0, pos.Y)
    frame.BackgroundColor3 = Color3.fromRGB(0,0,0)
    frame.BackgroundTransparency = 0.1 frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,8)
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(60,60,60) stroke.Thickness = 1.5

    local db = Instance.new("Frame", frame)
    db.Size = UDim2.new(1,0,0,14) db.BackgroundColor3 = Color3.fromRGB(35,35,35) db.BorderSizePixel = 0
    Instance.new("UICorner", db).CornerRadius = UDim.new(0,8)
    local df = Instance.new("Frame", db) df.Size = UDim2.new(1,0,0,8) df.Position = UDim2.new(0,0,1,-8)
    df.BackgroundColor3 = Color3.fromRGB(35,35,35) df.BorderSizePixel = 0
    local dtl = Instance.new("TextLabel", db) dtl.Size = UDim2.new(1,0,1,0) dtl.BackgroundTransparency = 1
    dtl.Text = "≡" dtl.TextColor3 = Color3.fromRGB(80,80,80) dtl.TextSize = 12 dtl.Font = Enum.Font.GothamBold

    local dragging, dragStart, startPos = false, nil, nil
    db.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true dragStart = input.Position startPos = frame.Position
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            btnPositions[posKey] = {X = frame.Position.X.Offset, Y = frame.Position.Y.Offset}
            saveConfig()
        end
    end)

    local content = Instance.new("Frame", frame)
    content.Size = UDim2.new(1, hasSettings and -40 or 0, 0, 36)
    content.Position = UDim2.new(0,0,0,14) content.BackgroundTransparency = 1

    local keyBox = Instance.new("TextButton", content)
    keyBox.Size = UDim2.new(0,36,0,26) keyBox.Position = UDim2.new(0,8,0.5,-13)
    keyBox.BackgroundColor3 = Color3.fromRGB(25,25,25) keyBox.BorderSizePixel = 0
    keyBox.Text = "["..defaultKey.."]" keyBox.TextColor3 = Color3.fromRGB(255,255,255)
    keyBox.TextSize = 13 keyBox.Font = Enum.Font.GothamBold
    Instance.new("UICorner", keyBox).CornerRadius = UDim.new(0,5)

    local isOn = false
    local currentKey = defaultKey

    local tIcon = Instance.new("TextLabel", content)
    tIcon.Size = UDim2.new(0,24,0,26) tIcon.Position = UDim2.new(0,50,0.5,-13)
    tIcon.BackgroundTransparency = 1 tIcon.Text = "○"
    tIcon.TextColor3 = Color3.fromRGB(140,140,140) tIcon.TextSize = 22 tIcon.Font = Enum.Font.GothamBold

    local lbl = Instance.new("TextLabel", content)
    lbl.Size = UDim2.new(0,110,0,26) lbl.Position = UDim2.new(0,76,0.5,-13)
    lbl.BackgroundTransparency = 1 lbl.Text = name lbl.TextColor3 = Color3.fromRGB(180,180,180)
    lbl.TextSize = 14 lbl.Font = Enum.Font.GothamSemibold lbl.TextXAlignment = Enum.TextXAlignment.Left

    local function reset()
        isOn = false tIcon.Text = "○" tIcon.TextColor3 = Color3.fromRGB(140,140,140)
        lbl.TextColor3 = Color3.fromRGB(180,180,180) stroke.Color = Color3.fromRGB(60,60,60)
    end

    local function toggle()
        isOn = not isOn
        tIcon.Text = isOn and "●" or "○"
        tIcon.TextColor3 = isOn and Color3.fromRGB(255,255,255) or Color3.fromRGB(140,140,140)
        lbl.TextColor3 = isOn and Color3.fromRGB(255,255,255) or Color3.fromRGB(180,180,180)
        stroke.Color = isOn and Color3.fromRGB(100,100,100) or Color3.fromRGB(60,60,60)
        if toggleCallback then toggleCallback(isOn) end
    end

    local hit = Instance.new("TextButton", content)
    hit.Size = UDim2.new(1,-50,1,0) hit.Position = UDim2.new(0,50,0,0)
    hit.BackgroundTransparency = 1 hit.Text = ""
    hit.MouseButton1Click:Connect(toggle)

    keyBox.MouseButton1Click:Connect(function()
        keyBox.Text = "[...]" keyBox.TextColor3 = Color3.fromRGB(255,200,100)
        waitingForKey = function(key)
            currentKey = key keyBox.Text = "["..key.."]" keyBox.TextColor3 = Color3.fromRGB(255,255,255)
            keybinds[name] = {key = key, toggle = toggle}
            keyBinds[posKey] = key saveConfig()
        end
    end)

    keybinds[name] = {key = currentKey, toggle = toggle}
    resetFunctions[name] = reset

    if hasSettings then
        local sb = Instance.new("TextButton", frame)
        sb.Size = UDim2.new(0,36,0,36) sb.Position = UDim2.new(1,-40,0,14)
        sb.BackgroundColor3 = Color3.fromRGB(25,25,25) sb.Text = "⚙"
        sb.TextColor3 = Color3.fromRGB(180,180,180) sb.TextSize = 18
        sb.Font = Enum.Font.GothamBold sb.BorderSizePixel = 0
        Instance.new("UICorner", sb).CornerRadius = UDim.new(0,6)
        sb.MouseButton1Click:Connect(function()
            speedSettingsOpen = not speedSettingsOpen
            speedPanel.Visible = speedSettingsOpen
            if speedSettingsOpen then
                speedPanel.Position = UDim2.new(0, frame.Position.X.Offset + frame.Size.X.Offset + 5, 0, frame.Position.Y.Offset)
            end
            sb.BackgroundColor3 = speedSettingsOpen and Color3.fromRGB(50,50,50) or Color3.fromRGB(25,25,25)
        end)
    end

    return frame, reset
end

local menuOpen = false
local mbPos = btnPositions.MenuButton

local menuButton = Instance.new("TextButton", gui)
menuButton.Size = UDim2.new(0,50,0,50)
menuButton.Position = UDim2.new(0, mbPos.X, 0, mbPos.Y)
menuButton.BackgroundColor3 = Color3.fromRGB(20,20,20) menuButton.Text = "☰"
menuButton.TextColor3 = Color3.fromRGB(255,255,255) menuButton.TextSize = 24
menuButton.Font = Enum.Font.GothamBold menuButton.BorderSizePixel = 0
Instance.new("UICorner", menuButton).CornerRadius = UDim.new(1,0)
local mst = Instance.new("UIStroke", menuButton) mst.Color = Color3.fromRGB(80,80,80) mst.Thickness = 2

local menuPanel = Instance.new("Frame", gui)
menuPanel.Size = UDim2.new(0,220,0,0)
menuPanel.Position = UDim2.new(0, mbPos.X+60, 0, mbPos.Y-20)
menuPanel.BackgroundColor3 = Color3.fromRGB(10,10,10) menuPanel.BorderSizePixel = 0
menuPanel.ClipsDescendants = true menuPanel.Visible = false
Instance.new("UICorner", menuPanel).CornerRadius = UDim.new(0,10)
local mpst = Instance.new("UIStroke", menuPanel) mpst.Color = Color3.fromRGB(60,60,60) mpst.Thickness = 1.5

local mll = Instance.new("UIListLayout", menuPanel) mll.Padding = UDim.new(0,5) mll.SortOrder = Enum.SortOrder.LayoutOrder
local mpad = Instance.new("UIPadding", menuPanel) mpad.PaddingTop = UDim.new(0,10) mpad.PaddingLeft = UDim.new(0,10) mpad.PaddingRight = UDim.new(0,10) mpad.PaddingBottom = UDim.new(0,10)

local rRow = Instance.new("Frame", menuPanel)
rRow.Size = UDim2.new(1,0,0,36) rRow.BackgroundColor3 = Color3.fromRGB(25,25,25) rRow.BorderSizePixel = 0 rRow.LayoutOrder = 2 rRow.Visible = autoGrabEnabled
Instance.new("UICorner", rRow).CornerRadius = UDim.new(0,6)

local rlbl = Instance.new("TextLabel", rRow)
rlbl.Size = UDim2.new(0,60,1,0) rlbl.Position = UDim2.new(0,10,0,0) rlbl.BackgroundTransparency = 1
rlbl.Text = "Radius:" rlbl.TextColor3 = Color3.fromRGB(200,200,200) rlbl.TextSize = 13
rlbl.Font = Enum.Font.GothamSemibold rlbl.TextXAlignment = Enum.TextXAlignment.Left

local rmb = Instance.new("TextButton", rRow)
rmb.Size = UDim2.new(0,28,0,24) rmb.Position = UDim2.new(0,75,0.5,-12)
rmb.BackgroundColor3 = Color3.fromRGB(40,40,40) rmb.Text = "-" rmb.TextColor3 = Color3.fromRGB(255,255,255)
rmb.TextSize = 18 rmb.Font = Enum.Font.GothamBold rmb.BorderSizePixel = 0
Instance.new("UICorner", rmb).CornerRadius = UDim.new(0,4)

local rib = Instance.new("TextBox", rRow)
rib.Size = UDim2.new(0,50,0,24) rib.Position = UDim2.new(0,108,0.5,-12)
rib.BackgroundColor3 = Color3.fromRGB(30,30,30) rib.Text = tostring(GRAB_RADIUS)
rib.TextColor3 = Color3.fromRGB(255,255,255) rib.TextSize = 14 rib.Font = Enum.Font.GothamBold
rib.BorderSizePixel = 0 rib.TextXAlignment = Enum.TextXAlignment.Center rib.ClearTextOnFocus = false
Instance.new("UICorner", rib).CornerRadius = UDim.new(0,4)

local rpb = Instance.new("TextButton", rRow)
rpb.Size = UDim2.new(0,28,0,24) rpb.Position = UDim2.new(0,163,0.5,-12)
rpb.BackgroundColor3 = Color3.fromRGB(40,40,40) rpb.Text = "+" rpb.TextColor3 = Color3.fromRGB(255,255,255)
rpb.TextSize = 18 rpb.Font = Enum.Font.GothamBold rpb.BorderSizePixel = 0
Instance.new("UICorner", rpb).CornerRadius = UDim.new(0,4)

rmb.MouseButton1Click:Connect(function() GRAB_RADIUS = math.max(5,GRAB_RADIUS-1) rib.Text = tostring(GRAB_RADIUS) saveConfig() end)
rpb.MouseButton1Click:Connect(function() GRAB_RADIUS = math.min(200,GRAB_RADIUS+1) rib.Text = tostring(GRAB_RADIUS) saveConfig() end)
rib.FocusLost:Connect(function()
    local n = tonumber(rib.Text) if n then GRAB_RADIUS = math.clamp(math.floor(n),5,200) end
    rib.Text = tostring(GRAB_RADIUS) saveConfig()
end)

local function createMenuToggle(name, defaultState, callback, order)
    local row = Instance.new("Frame", menuPanel)
    row.Size = UDim2.new(1,0,0,36) row.BackgroundColor3 = Color3.fromRGB(25,25,25) row.BorderSizePixel = 0 row.LayoutOrder = order
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,6)
    local l = Instance.new("TextLabel", row)
    l.Size = UDim2.new(0.65,0,1,0) l.Position = UDim2.new(0,10,0,0) l.BackgroundTransparency = 1
    l.Text = name l.TextColor3 = Color3.fromRGB(200,200,200) l.TextSize = 13
    l.Font = Enum.Font.GothamSemibold l.TextXAlignment = Enum.TextXAlignment.Left
    local bg = Instance.new("Frame", row)
    bg.Size = UDim2.new(0,40,0,22) bg.Position = UDim2.new(1,-50,0.5,-11)
    bg.BackgroundColor3 = defaultState and Color3.fromRGB(100,100,100) or Color3.fromRGB(50,50,50) bg.BorderSizePixel = 0
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1,0)
    local dot = Instance.new("Frame", bg)
    dot.Size = UDim2.new(0,16,0,16)
    dot.Position = defaultState and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)
    dot.BackgroundColor3 = Color3.fromRGB(255,255,255) dot.BorderSizePixel = 0
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)
    local isOn = defaultState or false
    local function upd()
        bg.BackgroundColor3 = isOn and Color3.fromRGB(100,100,100) or Color3.fromRGB(50,50,50)
        dot.Position = isOn and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)
        l.TextColor3 = isOn and Color3.fromRGB(255,255,255) or Color3.fromRGB(200,200,200)
    end
    local btn = Instance.new("TextButton", row) btn.Size = UDim2.new(1,0,1,0) btn.BackgroundTransparency = 1 btn.Text = ""
    btn.MouseButton1Click:Connect(function() isOn = not isOn upd() if callback then callback(isOn) end saveConfig() end)
    return row
end

local function getMenuH()
    local h = 280
    if autoGrabEnabled then h = h + 46 end
    return h
end

local function toggleMenu()
    menuOpen = not menuOpen
    if menuOpen then
        menuPanel.Visible = true menuPanel.Size = UDim2.new(0,220,0,getMenuH())
        menuButton.Text = "✕" menuButton.BackgroundColor3 = Color3.fromRGB(40,40,40)
    else
        menuPanel.Size = UDim2.new(0,220,0,0) task.wait(0.1)
        menuPanel.Visible = false menuButton.Text = "☰" menuButton.BackgroundColor3 = Color3.fromRGB(20,20,20)
    end
end

menuButton.MouseButton1Click:Connect(toggleMenu)

local mdr,mds2,msp2 = false,nil,nil
menuButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        mdr = true mds2 = input.Position msp2 = menuButton.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if mdr and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - mds2
        if d.Magnitude > 5 then
            menuButton.Position = UDim2.new(msp2.X.Scale, msp2.X.Offset+d.X, msp2.Y.Scale, msp2.Y.Offset+d.Y)
            menuPanel.Position = UDim2.new(0, menuButton.Position.X.Offset+60, 0, menuButton.Position.Y.Offset-20)
        end
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        mdr = false
        btnPositions.MenuButton = {X = menuButton.Position.X.Offset, Y = menuButton.Position.Y.Offset}
        saveConfig()
    end
end)

createMenuToggle("Auto Grab", autoGrabEnabled, function(on)
    autoGrabEnabled = on rRow.Visible = on
    if menuOpen then menuPanel.Size = UDim2.new(0,220,0,getMenuH()) end
    if on then startAutoGrab() else stopAutoGrab() end
end, 1)

createMenuToggle("Anti Ragdoll", antiRagdollEnabled, function(on)
    antiRagdollEnabled = on
    if on then startAntiRagdoll() else stopAntiRagdoll() end
end, 3)

createMenuToggle("Player ESP", espEnabled, function(on)
    espEnabled = on
    if on then enableESP() else disableESP() end
end, 4)

createMenuToggle("Optimizer+XRay", optimizerEnabled, function(on)
    optimizerEnabled = on
    if on then enableOptimizer() else disableOptimizer() end
end, 5)

createMenuToggle("Unwalk", unwalkEnabled, function(on)
    unwalkEnabled = on
    if on then startUnwalk() else stopUnwalk() end
end, 6)

UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if waitingForKey and input.UserInputType == Enum.UserInputType.Keyboard then
        local kn = input.KeyCode.Name
        waitingForKey(#kn == 1 and kn:upper() or kn)
        waitingForKey = nil return
    end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local p = input.KeyCode.Name:upper()
        for _, d in pairs(keybinds) do if d.key:upper() == p then d.toggle() end end
    end
end)

createButton("Auto Play Left", "AutoPlayLeft", keyBinds.AutoPlayLeft or "G", function(on)
    aplOn = on
    if on then
        if aprOn then aprOn = false stopAutoPlayRight() resetFunctions["Auto Play Right"]() end
        if batAimbotOn then stopBatAimbot() resetFunctions["Bat Aimbot"]() end
        startAutoPlayLeft()
    else stopAutoPlayLeft() end
end, true)

createButton("Auto Play Right", "AutoPlayRight", keyBinds.AutoPlayRight or "H", function(on)
    aprOn = on
    if on then
        if aplOn then aplOn = false stopAutoPlayLeft() resetFunctions["Auto Play Left"]() end
        if batAimbotOn then stopBatAimbot() resetFunctions["Bat Aimbot"]() end
        startAutoPlayRight()
    else stopAutoPlayRight() end
end, true)

createButton("Bat Aimbot", "BatAimbot", keyBinds.BatAimbot or "X", function(on)
    batAimbotOn = on
    if on then
        if aplOn then aplOn = false stopAutoPlayLeft() resetFunctions["Auto Play Left"]() end
        if aprOn then aprOn = false stopAutoPlayRight() resetFunctions["Auto Play Right"]() end
        startBatAimbot()
    else stopBatAimbot() end
end, false)

local function setupChar(c)
    char = c
    hum = char:WaitForChild("Humanoid", 5)
    hrp = char:WaitForChild("HumanoidRootPart", 5)
    task.wait(0.5)
    if batAimbotOn then stopBatAimbot() task.wait(0.1) startBatAimbot() end
    if antiRagdollEnabled then stopAntiRagdoll() startAntiRagdoll() end
    if unwalkEnabled then startUnwalk() end
    if espEnabled then enableESP() end
end

if me.Character then setupChar(me.Character) end
me.CharacterAdded:Connect(setupChar)

task.spawn(function()
    task.wait(1)
    if antiRagdollEnabled then startAntiRagdoll() end
    if espEnabled then enableESP() end
    if optimizerEnabled then enableOptimizer() end
    if unwalkEnabled and char then startUnwalk() end
    if autoGrabEnabled then startAutoGrab() rRow.Visible = true end
end)

print("FULL SCRIPT LOADED! - SAVE SYSTEM ACTIVE")
