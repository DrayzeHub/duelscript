-- ══════════════════════════════════════════════════════════════
-- NYROX HUB v2.1 + SEMI TP
-- ══════════════════════════════════════════════════════════════

repeat task.wait() until game:IsLoaded()
task.wait(2)

local Players              = game:GetService("Players")
local RunService           = game:GetService("RunService")
local UserInputService     = game:GetService("UserInputService")
local TweenService         = game:GetService("TweenService")
local ReplicatedStorage    = game:GetService("ReplicatedStorage")
local CoreGui              = game:GetService("CoreGui")
local ProximityPromptService = game:GetService("ProximityPromptService")

local LocalPlayer = Players.LocalPlayer
local playerGui   = LocalPlayer:WaitForChild("PlayerGui", 15)
if not playerGui then warn("[NYROX] PlayerGui not found") return end

local nyroxSpeedBox, nyroxJumpBox
local nyroxSlFill, nyroxSlKnob, nyroxSlVal

-- ══════════════════════════════════════════════════════════════
-- THEME
-- ══════════════════════════════════════════════════════════════
local T = {
    BgDark    = Color3.fromRGB(10, 10, 10),
    BgCard    = Color3.fromRGB(22, 22, 22),
    BgCardHov = Color3.fromRGB(35, 35, 35),
    BgSidebar = Color3.fromRGB(13, 13, 13),
    BtnBase   = Color3.fromRGB(40, 40, 40),
    BtnHover  = Color3.fromRGB(60, 60, 60),
    BtnActive = Color3.fromRGB(200, 200, 200),
    BtnActTxt = Color3.fromRGB(10, 10, 10),
    White     = Color3.fromRGB(255, 255, 255),
    LightGray = Color3.fromRGB(185, 185, 185),
    MidGray   = Color3.fromRGB(120, 120, 120),
    DarkGray  = Color3.fromRGB(50,  50,  50),
    Ready     = Color3.fromRGB(220, 220, 220),
    Cooldown  = Color3.fromRGB(90,  90,  90),
    SpeedWarn = Color3.fromRGB(60,  20,  20),
    Gold      = Color3.fromRGB(255, 215, 0),
}

-- ══════════════════════════════════════════════════════════════
-- HELPERS
-- ══════════════════════════════════════════════════════════════
local function tw(obj, props, dur)
    TweenService:Create(obj, TweenInfo.new(dur or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = p
end

local function mkLabel(parent, text, size, color, font, xAlign)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextSize = size or 12
    l.TextColor3 = color or T.White
    l.Font = font or Enum.Font.GothamSemibold
    l.TextXAlignment = xAlign or Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.Parent = parent
    return l
end

local function wGrad(parent)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, T.White),
        ColorSequenceKeypoint.new(1, T.MidGray),
    }
    g.Parent = parent
end

local function divLine(parent, yPos)
    local d = Instance.new("Frame")
    d.Size = UDim2.new(1, -20, 0, 1)
    d.Position = UDim2.new(0, 10, 0, yPos)
    d.BackgroundColor3 = T.DarkGray
    d.BorderSizePixel = 0
    d.Parent = parent
end

local strokeGrads = {}
local function addBWStroke(parent, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = thickness or 2.2
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = Color3.new(1,1,1)
    stroke.Parent = parent
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(0.3, Color3.fromRGB(15, 15, 15)),
        ColorSequenceKeypoint.new(0.7, Color3.fromRGB(15, 15, 15)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(255,255,255)),
    }
    grad.Rotation = 0
    grad.Parent = stroke
    table.insert(strokeGrads, grad)
    return stroke, grad
end

local function makeDraggable(frame)
    local dragging, ds, sp
    frame.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging=true; ds=i.Position; sp=frame.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then dragging=false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - ds
            frame.Position = UDim2.new(sp.X.Scale, sp.X.Offset+d.X, sp.Y.Scale, sp.Y.Offset+d.Y)
        end
    end)
end

-- ══════════════════════════════════════════════════════════════
-- COOLDOWN SYSTEM
-- ══════════════════════════════════════════════════════════════
local commandCooldowns = {
    rocket=120, ragdoll=30, balloon=30,
    inverse=60, nightvision=60, jail=60,
    tiny=60, jumpscare=60, morph=60,
}
local lastCommandUse = {}

local function isOnCD(cmd)
    local t = lastCommandUse[cmd]
    return t and (tick()-t) < (commandCooldowns[cmd] or 0)
end

local function getRemaining(cmd)
    local t = lastCommandUse[cmd]
    if not t then return 0 end
    return math.max(0, (commandCooldowns[cmd] or 0) - (tick()-t))
end

local function findRemote()
    for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
        local n = d.Name:lower()
        if n:find("executecommand") and (d:IsA("RemoteEvent") or d:IsA("RemoteFunction")) then
            return d
        end
    end
end
local remote = findRemote()

local function execCmd(player, cmd)
    if not remote then remote = findRemote() if not remote then return end end
    if isOnCD(cmd) then return end
    local ok = pcall(function() remote:FireServer(player, cmd) end)
    if ok then lastCommandUse[cmd] = tick() end
end

-- ══════════════════════════════════════════════════════════════
-- CONFIG SYSTEM
-- ══════════════════════════════════════════════════════════════
local CFG_FILE = "NyroxHub_v2.json"
local Http     = game:GetService("HttpService")

local CFG = {
    defenseVisible   = false,
    adminVisible     = false,
    flashTPVisible   = false,
    cdVisible        = true,
    boosterEnabled   = false,
    boosterSpeed     = 22.5,
    boosterJump      = 35,
    infJumpEnabled   = false,
    antiRagdoll      = false,
    autoTurret       = false,
    optimizer        = false,
    xray             = false,
    brainrotESP      = false,
    playerESP        = false,
    autoFlashEnabled = false,
    stealThreshold   = 0.83,
    autoGrab         = false,
    grabRadius       = 20,
    autoKick         = false,
    antiBee          = false,
    timerESP         = false,
    friendsESP       = false,
    semiTPEnabled    = false,
    kb_toggleHub        = "U",
    kb_toggleDefense    = "None",
    kb_toggleAdmin      = "None",
    kb_toggleBooster    = "None",
    kb_toggleInfJump    = "None",
    kb_toggleESP        = "None",
    kb_toggleBrainrot   = "None",
    kb_toggleAutoFlash  = "None",
    kb_toggleFlashPanel = "None",
    kb_invisClone       = "None",
    kb_ragdollSelf      = "None",
    kb_rejoin           = "None",
    kb_semiTP           = "G",
}

local savedState = CFG

local _savePending = false
local function saveState()
    if _savePending then return end
    _savePending = true
    task.delay(0.3, function()
        _savePending = false
        pcall(function()
            if writefile then
                writefile(CFG_FILE, Http:JSONEncode(CFG))
            end
        end)
    end)
end

pcall(function()
    if not readfile then return end
    local fileExists = (isfile and isfile(CFG_FILE)) or pcall(readfile, CFG_FILE)
    if not fileExists then return end
    local ok, raw = pcall(readfile, CFG_FILE)
    if not ok or not raw or #raw < 2 then return end
    local ok2, data = pcall(function() return Http:JSONDecode(raw) end)
    if not ok2 or type(data) ~= "table" then return end
    for k, v in pairs(data) do
        if CFG[k] ~= nil then CFG[k] = v end
    end
end)

-- ══════════════════════════════════════════════════════════════
-- SEMI TP CONFIG & STATE
-- ══════════════════════════════════════════════════════════════
local TP_POSITIONS = {
    BASE1 = {
        INFO_POS        = CFrame.new(334.76, 55.334, 99.40),
        TELEPORT_POS    = CFrame.new(-352.98, -7.30, 74.3),
        STAND_HERE_PART = CFrame.new(-334.76, -5.334, 99.40) * CFrame.new(0, 2.6, 0)
    },
    BASE2 = {
        INFO_POS        = CFrame.new(334.76, 55.334, 19.17),
        TELEPORT_POS    = CFrame.new(-352.98, -7.30, 45.76),
        STAND_HERE_PART = CFrame.new(-336.41, -5.34, 19.20) * CFrame.new(0, 2.6, 0)
    }
}

local semiTPEnabled          = false  -- Teleport system açık/kapalı
local semiTPLastTime         = 0
local SEMI_TP_COOLDOWN       = 0.8
local semiMarkerUpdate       = 0
local SEMI_MARKER_INTERVAL   = 0.4
local semiMarker             = nil

-- Desync
local desyncFirstActivation      = true
local desyncPermanentlyActivated = false

local FFlags = {
    GameNetPVHeaderRotationalVelocityZeroCutoffExponent = -5000,
    LargeReplicatorWrite5 = true, LargeReplicatorEnabled9 = true,
    AngularVelociryLimit = 360,
    TimestepArbiterVelocityCriteriaThresholdTwoDt = 2147483646,
    S2PhysicsSenderRate = 15000, DisableDPIScale = true,
    MaxDataPacketPerSend = 2147483647, PhysicsSenderMaxBandwidthBps = 20000,
    TimestepArbiterHumanoidLinearVelThreshold = 21,
    MaxMissedWorldStepsRemembered = -2147483648,
    PlayerHumanoidPropertyUpdateRestrict = true,
    SimDefaultHumanoidTimestepMultiplier = 0,
    StreamJobNOUVolumeLengthCap = 2147483647,
    DebugSendDistInSteps = -2147483648,
    GameNetDontSendRedundantNumTimes = 1,
    CheckPVLinearVelocityIntegrateVsDeltaPositionThresholdPercent = 1,
    CheckPVDifferencesForInterpolationMinVelThresholdStudsPerSecHundredth = 1,
    LargeReplicatorSerializeRead3 = true,
    ReplicationFocusNouExtentsSizeCutoffForPauseStuds = 2147483647,
    CheckPVCachedVelThresholdPercent = 10,
    CheckPVDifferencesForInterpolationMinRotVelThresholdRadsPerSecHundredth = 1,
    GameNetDontSendRedundantDeltaPositionMillionth = 1,
    InterpolationFrameVelocityThresholdMillionth = 5,
    StreamJobNOUVolumeCap = 2147483647,
    InterpolationFrameRotVelocityThresholdMillionth = 5,
    CheckPVCachedRotVelThresholdPercent = 10, WorldStepMax = 30,
    InterpolationFramePositionThresholdMillionth = 5,
    TimestepArbiterHumanoidTurningVelThreshold = 1,
    SimOwnedNOUCountThresholdMillionth = 2147483647,
    GameNetPVHeaderLinearVelocityZeroCutoffExponent = -5000,
    NextGenReplicatorEnabledWrite4 = true, TimestepArbiterOmegaThou = 1073741823,
    MaxAcceptableUpdateDelay = 1, LargeReplicatorSerializeWrite4 = true
}

local function applyFFlags(flags)
    for name, value in pairs(flags) do
        pcall(function() setfflag(tostring(name), tostring(value)) end)
    end
end

local function semiRespawn(plr)
    local char = plr.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Dead) end
        char:ClearAllChildren()
        local newChar = Instance.new("Model")
        newChar.Parent = workspace
        plr.Character = newChar
        task.wait()
        plr.Character = char
        newChar:Destroy()
    end
end

local function applyPermanentDesync()
    applyFFlags(FFlags)
    if desyncFirstActivation then
        semiRespawn(LocalPlayer)
        desyncFirstActivation = false
    end
    desyncPermanentlyActivated = true
end

local function getCurrentBase()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return TP_POSITIONS.BASE1.INFO_POS
    end
    local hrp = LocalPlayer.Character.HumanoidRootPart
    local d1 = (hrp.Position - TP_POSITIONS.BASE1.INFO_POS.Position).Magnitude
    local d2 = (hrp.Position - TP_POSITIONS.BASE2.INFO_POS.Position).Magnitude
    return d1 < d2 and TP_POSITIONS.BASE1.INFO_POS or TP_POSITIONS.BASE2.INFO_POS
end

-- Marker oluştur
local function createSemiMarker()
    local basePos = getCurrentBase()
    local markerPos = basePos * CFrame.new(0, -3.2, 0)
    local part = workspace:FindFirstChild("NyroxSemiMarker") or Instance.new("Part")
    part.Name = "NyroxSemiMarker"
    part.Size = Vector3.new(1,1,1)
    part.CFrame = markerPos
    part.Anchored = true
    part.CanCollide = false
    part.Material = Enum.Material.Neon
    part.Color = Color3.fromRGB(0,255,255)
    part.Transparency = 0.3
    part.Parent = workspace
    return part
end

-- Cosmic indikatörler
local function createCosmicIndicator(name, position, color, text)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = Vector3.new(3.8, 0.3, 3.8)
    part.Material = Enum.Material.Plastic
    part.Color = color
    part.Transparency = 0.57
    part.Anchored = true
    part.CanCollide = false
    part.Position = position
    part.Parent = workspace
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 4, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = part
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1,0,1,0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextColor3 = Color3.fromRGB(255,255,255)
    textLabel.TextStrokeTransparency = 0.3
    textLabel.TextStrokeColor3 = color
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextSize = 18
    textLabel.Parent = billboard
    return part
end

task.spawn(function()
    createCosmicIndicator("NyroxCosmicStand1",    Vector3.new(-334.84,-5.40,101.02), Color3.fromRGB(39,39,39), " STAND HERE (BASE 1) ")
    createCosmicIndicator("NyroxCosmicTP1",       Vector3.new(-352.98,-7.30, 74.3),  Color3.fromRGB(39,39,39), " TELEPORT HERE (BASE 1) ")
    createCosmicIndicator("NyroxCosmicStand2",    Vector3.new(-334.84,-5.40, 19.20), Color3.fromRGB(39,39,39), " STAND HERE (BASE 2) ")
    createCosmicIndicator("NyroxCosmicTP2",       Vector3.new(-352.98,-7.30, 45.76), Color3.fromRGB(39,39,39), " TELEPORT HERE (BASE 2) ")
end)

-- ══════════════════════════════════════════════════════════════
-- SEMI TP AUTO GRAB — sadece G basılınca tetiklenir
-- ══════════════════════════════════════════════════════════════
local getconnections = getconnections or get_signal_cons or getconnects or (syn and syn.get_signal_cons)

local SEMI_AG_RADIUS  = 8
local semiAgGrabbing  = false
local semiAgConn      = nil
local semiAgData      = {}

local function semiAgIsMyPlot(plotName)
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return false end
    local plot = plots:FindFirstChild(plotName)
    if not plot then return false end
    local sign = plot:FindFirstChild("PlotSign")
    if sign then
        local yb = sign:FindFirstChild("YourBase")
        if yb and yb:IsA("BillboardGui") then return yb.Enabled == true end
    end
    return false
end

local function semiAgFindPrompt()
    local c   = LocalPlayer.Character
    local hrp = c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("UpperTorso"))
    if not hrp then return nil end
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end
    local np, nd = nil, math.huge
    for _, plot in ipairs(plots:GetChildren()) do
        if semiAgIsMyPlot(plot.Name) then continue end
        local podiums = plot:FindFirstChild("AnimalPodiums")
        if not podiums then continue end
        for _, pod in ipairs(podiums:GetChildren()) do
            pcall(function()
                local base  = pod:FindFirstChild("Base")
                local spawn = base and base:FindFirstChild("Spawn")
                if spawn then
                    local dist = (spawn.Position - hrp.Position).Magnitude
                    if dist < nd and dist <= SEMI_AG_RADIUS then
                        local att = spawn:FindFirstChild("PromptAttachment")
                        if att then
                            for _, ch in ipairs(att:GetChildren()) do
                                if ch:IsA("ProximityPrompt") then
                                    np, nd = ch, dist
                                    break
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
    return np
end

local function semiAgExecuteGrab(prompt)
    if semiAgGrabbing then return end
    if not semiAgData[prompt] then
        semiAgData[prompt] = {hold={}, trigger={}, ready=true}
        pcall(function()
            if getconnections then
                for _, c in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do
                    if c.Function then table.insert(semiAgData[prompt].hold, c.Function) end
                end
                for _, c in ipairs(getconnections(prompt.Triggered)) do
                    if c.Function then table.insert(semiAgData[prompt].trigger, c.Function) end
                end
            end
        end)
    end
    local data = semiAgData[prompt]
    if not data.ready then return end
    data.ready    = false
    semiAgGrabbing = true
    task.spawn(function()
        for _, f in ipairs(data.hold) do task.spawn(f) end
        task.wait(0.2)
        for _, f in ipairs(data.trigger) do task.spawn(f) end
        data.ready    = true
        semiAgGrabbing = false
        -- Steal bitti → direkt TP
        if not semiTPEnabled then return end
        local character = LocalPlayer.Character
        if not character then return end
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then
            local carpet = backpack:FindFirstChild("Flying Carpet")
            if carpet and character:FindFirstChild("Humanoid") then
                character.Humanoid:EquipTool(carpet)
                task.wait(0.1)
            end
        end
        local base = getCurrentBase()
        if base == TP_POSITIONS.BASE1.INFO_POS then
            hrp.CFrame = TP_POSITIONS.BASE1.TELEPORT_POS
        else
            hrp.CFrame = TP_POSITIONS.BASE2.TELEPORT_POS
        end
        -- Auto grab bağlantısını kapat, bir sonraki G için hazır
        if semiAgConn then semiAgConn:Disconnect() semiAgConn = nil end
        semiAgData = {}
    end)
end

-- Auto grab sadece G basılınca ve Teleport System açıkken başlar
local function semiAgStart()
    if not semiTPEnabled then return end  -- Teleport System kapalıysa çalışma
    if semiAgConn then semiAgConn:Disconnect() end
    semiAgData = {}
    semiAgGrabbing = false
    semiAgConn = RunService.Heartbeat:Connect(function()
        if not semiTPEnabled or semiAgGrabbing then return end
        local p = semiAgFindPrompt()
        if p then semiAgExecuteGrab(p) end
    end)
end

local function semiAgStop()
    if semiAgConn then semiAgConn:Disconnect() semiAgConn = nil end
    semiAgGrabbing = false
    semiAgData = {}
end

-- ══════════════════════════════════════════════════════════════
-- SEMI TP EXECUTE (G tuşu)
-- ══════════════════════════════════════════════════════════════
local function executeSemiTP()
    if not semiTPEnabled then return false end  -- Teleport System kapalıysa çalışma
    if tick() - semiTPLastTime < SEMI_TP_COOLDOWN then return false end
    semiTPLastTime = tick()

    local Character = LocalPlayer.Character
    if not Character then Character = LocalPlayer.CharacterAdded:Wait() end
    local HRP = Character:WaitForChild("HumanoidRootPart")
    local Humanoid = Character:WaitForChild("Humanoid")
    local Carpet = Character:FindFirstChild("Flying Carpet") or LocalPlayer.Backpack:FindFirstChild("Flying Carpet")

    local base = getCurrentBase()
    local isBase1 = base == TP_POSITIONS.BASE1.INFO_POS

    task.spawn(function()
        if Carpet and Humanoid then Humanoid:EquipTool(Carpet) end
        if isBase1 then
            HRP.CFrame = CFrame.new(-351.49, -6.65, 113.72) task.wait(0.15)
            HRP.CFrame = CFrame.new(-378.14, -6.00, 26.43)  task.wait(0.15)
            HRP.CFrame = CFrame.new(-334.80, -5.04, 18.90)
        else
            HRP.CFrame = CFrame.new(-352.54, -6.83, 6.66)   task.wait(0.15)
            HRP.CFrame = CFrame.new(-372.90, -6.20, 102.00) task.wait(0.15)
            HRP.CFrame = CFrame.new(-335.08, -5.10, 101.40)
        end
        -- TP'ye geldikten sonra auto grab başlat
        task.wait(0.15)
        semiAgStart()
    end)

    return true
end

-- Steal prompt → TP (manuel E ile steal yapılınca da çalışsın)
task.spawn(function()
    ProximityPromptService.PromptButtonHoldEnded:Connect(function(prompt, who)
        if who ~= LocalPlayer then return end
        if prompt.Name ~= "Steal" and prompt.ActionText ~= "Steal" and prompt.ObjectText ~= "Steal" then return end
        if not semiTPEnabled then return end
        local character = LocalPlayer.Character
        if not character then return end
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then
            local carpet = backpack:FindFirstChild("Flying Carpet")
            if carpet and character:FindFirstChild("Humanoid") then
                character.Humanoid:EquipTool(carpet)
                task.wait(0.1)
            end
        end
        local base = getCurrentBase()
        if base == TP_POSITIONS.BASE1.INFO_POS then
            hrp.CFrame = TP_POSITIONS.BASE1.TELEPORT_POS
        else
            hrp.CFrame = TP_POSITIONS.BASE2.TELEPORT_POS
        end
    end)
end)

-- Marker heartbeat
RunService.Heartbeat:Connect(function(dt)
    semiMarkerUpdate = semiMarkerUpdate + dt
    if semiMarkerUpdate < SEMI_MARKER_INTERVAL then return end
    semiMarkerUpdate = 0
    local character = LocalPlayer.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local base = getCurrentBase()
    local markerPos = base * CFrame.new(0, -3.2, 0)
    if semiMarker and semiMarker.Parent then
        semiMarker.CFrame = markerPos
        local dist = (hrp.Position - base.Position).Magnitude
        semiMarker.Color = dist < 7 and Color3.fromRGB(0,255,100) or Color3.fromRGB(255,50,50)
    end
end)

-- G tuşu
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.G then
        executeSemiTP()
    end
end)

-- ══════════════════════════════════════════════════════════════
-- MAIN GUI
-- ══════════════════════════════════════════════════════════════
local mainGui = Instance.new("ScreenGui")
mainGui.Name = "NyroxHubV2"
mainGui.ResetOnSpawn = false
mainGui.IgnoreGuiInset = true
mainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
mainGui.Parent = playerGui

local window = Instance.new("Frame")
window.Name = "NyroxWindow"
window.Size = UDim2.new(0, 640, 0, 420)
window.Position = UDim2.new(0.5, -320, 0.5, -210)
window.BackgroundColor3 = T.BgDark
window.BorderSizePixel = 0
window.Parent = mainGui
corner(window, 14)
addBWStroke(window, 2.2)
makeDraggable(window)

local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 155, 1, 0)
sidebar.BackgroundColor3 = T.BgSidebar
sidebar.BorderSizePixel = 0
sidebar.Parent = window
corner(sidebar, 14)

local sClip = Instance.new("Frame")
sClip.Size = UDim2.new(0, 16, 1, 0)
sClip.Position = UDim2.new(1, -16, 0, 0)
sClip.BackgroundColor3 = T.BgSidebar
sClip.BorderSizePixel = 0
sClip.Parent = sidebar

local logoBox = Instance.new("Frame")
logoBox.Size = UDim2.new(1, -20, 0, 68)
logoBox.Position = UDim2.new(0, 10, 0, 10)
logoBox.BackgroundColor3 = T.BgCard
logoBox.Parent = sidebar
corner(logoBox, 10)
addBWStroke(logoBox, 1.8)
local logoN = mkLabel(logoBox, "N", 36, T.White, Enum.Font.GothamBlack, Enum.TextXAlignment.Center)
logoN.Size = UDim2.new(1,0,1,0)
wGrad(logoN)

local verLbl = mkLabel(sidebar, "v2.1", 10, T.MidGray, Enum.Font.Gotham, Enum.TextXAlignment.Center)
verLbl.Size = UDim2.new(1,0,0,18)
verLbl.Position = UDim2.new(0,0,0,82)

divLine(sidebar, 104)

local navHolder = Instance.new("Frame")
navHolder.Size = UDim2.new(1,-20,1,-230)
navHolder.Position = UDim2.new(0,10,0,112)
navHolder.BackgroundTransparency = 1
navHolder.Parent = sidebar
Instance.new("UIListLayout", navHolder).Padding = UDim.new(0,5)

local bottomHolder = Instance.new("Frame")
bottomHolder.Size = UDim2.new(1,-20,0,82)
bottomHolder.Position = UDim2.new(0,10,1,-90)
bottomHolder.BackgroundTransparency = 1
bottomHolder.Parent = sidebar
Instance.new("UIListLayout", bottomHolder).Padding = UDim.new(0,6)

local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1,-165,1,-10)
contentArea.Position = UDim2.new(0,160,0,5)
contentArea.BackgroundTransparency = 1
contentArea.Parent = window

local hubTitle = mkLabel(contentArea, "NYROX  ·  General", 18, T.White, Enum.Font.GothamBlack)
hubTitle.Size = UDim2.new(0.65,0,0,32)
hubTitle.Position = UDim2.new(0,4,0,6)
wGrad(hubTitle)

local subLbl = mkLabel(contentArea, "discord.gg/HCntzDTWJV  |  v2.1", 10, T.MidGray, Enum.Font.Gotham)
subLbl.Size = UDim2.new(0.65,0,0,16)
subLbl.Position = UDim2.new(0,5,0,32)

local fpsPill = Instance.new("Frame")
fpsPill.Size = UDim2.new(0,130,0,26)
fpsPill.Position = UDim2.new(1,-135,0,12)
fpsPill.BackgroundColor3 = T.BgCard
fpsPill.Parent = contentArea
corner(fpsPill, 20)
addBWStroke(fpsPill, 1.5)
local fpsLbl = mkLabel(fpsPill, "FPS: -- | --ms", 10, T.White, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
fpsLbl.Size = UDim2.new(1,0,1,0)

divLine(contentArea, 52)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1,-4,1,-60)
scroll.Position = UDim2.new(0,0,0,58)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = T.DarkGray
scroll.CanvasSize = UDim2.new(0,0,0,0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = contentArea

local scrollLL = Instance.new("UIListLayout")
scrollLL.Padding = UDim.new(0,6)
scrollLL.Parent = scroll
local scrollPad = Instance.new("UIPadding")
scrollPad.PaddingRight = UDim.new(0,6)
scrollPad.Parent = scroll

-- ══════════════════════════════════════════════════════════════
-- UI BUILDERS
-- ══════════════════════════════════════════════════════════════
local function clearContent()
    for _, c in ipairs(scroll:GetChildren()) do
        if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
    end
end

local function addSectionHeader(text, color)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1,0,0,26)
    f.BackgroundTransparency = 1
    f.Parent = scroll
    local line = Instance.new("Frame")
    line.Size = UDim2.new(1,-8,0,1)
    line.Position = UDim2.new(0,0,0.5,0)
    line.BackgroundColor3 = color or T.DarkGray
    line.BorderSizePixel = 0
    line.Parent = f
    local tag = Instance.new("TextLabel")
    tag.Size = UDim2.new(0,200,1,0)
    tag.BackgroundColor3 = T.BgDark
    tag.BackgroundTransparency = 0
    tag.Text = "  " .. text .. "  "
    tag.Font = Enum.Font.GothamBold
    tag.TextSize = 11
    tag.TextColor3 = color or T.LightGray
    tag.TextXAlignment = Enum.TextXAlignment.Left
    tag.BorderSizePixel = 0
    tag.Parent = f
    return f
end

local function addToggleRow(labelText, default, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,44)
    row.BackgroundColor3 = T.BgCard
    row.Parent = scroll
    corner(row, 8)
    local l = mkLabel(row, labelText, 12, T.LightGray)
    l.Size = UDim2.new(0.7,0,1,0)
    l.Position = UDim2.new(0,12,0,0)
    local pillBg = Instance.new("Frame")
    pillBg.Size = UDim2.new(0,44,0,22)
    pillBg.Position = UDim2.new(1,-54,0.5,-11)
    pillBg.BackgroundColor3 = default and T.BtnActive or T.BtnBase
    pillBg.Parent = row
    corner(pillBg, 11)
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0,16,0,16)
    dot.Position = UDim2.new(0, default and 24 or 4, 0.5, -8)
    dot.BackgroundColor3 = default and T.BtnActTxt or T.MidGray
    dot.Parent = pillBg
    corner(dot, 8)
    local state = default or false
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,1,0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = row
    btn.MouseButton1Click:Connect(function()
        state = not state
        tw(pillBg, {BackgroundColor3 = state and T.BtnActive or T.BtnBase}, 0.2)
        tw(dot, {Position=UDim2.new(0, state and 24 or 4, 0.5,-8), BackgroundColor3 = state and T.BtnActTxt or T.MidGray}, 0.2)
        if callback then callback(state) end
    end)
    row.MouseEnter:Connect(function() tw(row,{BackgroundColor3=T.BgCardHov},0.15) end)
    row.MouseLeave:Connect(function() tw(row,{BackgroundColor3=T.BgCard},0.15) end)
    return row
end

local function addButtonRow(labelText, btnText, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,44)
    row.BackgroundColor3 = T.BgCard
    row.Parent = scroll
    corner(row, 8)
    local l = mkLabel(row, labelText, 12, T.LightGray)
    l.Size = UDim2.new(0.6,0,1,0)
    l.Position = UDim2.new(0,12,0,0)
    if btnText and callback then
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0,80,0,28)
        btn.Position = UDim2.new(1,-90,0.5,-14)
        btn.BackgroundColor3 = T.BtnBase
        btn.Text = btnText
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 10
        btn.TextColor3 = T.White
        btn.AutoButtonColor = false
        btn.Parent = row
        corner(btn, 6)
        btn.MouseButton1Click:Connect(function()
            tw(btn,{BackgroundTransparency=0.5},0.1)
            task.wait(0.1)
            tw(btn,{BackgroundTransparency=0},0.1)
            callback()
        end)
        btn.MouseEnter:Connect(function() tw(btn,{BackgroundColor3=T.BtnHover},0.15) end)
        btn.MouseLeave:Connect(function() tw(btn,{BackgroundColor3=T.BtnBase},0.15) end)
    end
    row.MouseEnter:Connect(function() tw(row,{BackgroundColor3=T.BgCardHov},0.15) end)
    row.MouseLeave:Connect(function() tw(row,{BackgroundColor3=T.BgCard},0.15) end)
    return row
end

-- ══════════════════════════════════════════════════════════════
-- COOLDOWN PANEL
-- ══════════════════════════════════════════════════════════════
local cdPanel = Instance.new("Frame")
cdPanel.Name = "NyroxCooldowns"
cdPanel.Size = UDim2.new(0,200,0,225)
cdPanel.Position = UDim2.new(1,-220,1,-245)
cdPanel.BackgroundColor3 = T.BgDark
cdPanel.BackgroundTransparency = 0.05
cdPanel.Parent = mainGui
corner(cdPanel, 12)
addBWStroke(cdPanel, 2.2)
makeDraggable(cdPanel)

local cdTitle = mkLabel(cdPanel, "NYROX  ·  Cooldowns", 13, T.White, Enum.Font.GothamBold)
cdTitle.Size = UDim2.new(1,-20,0,30)
cdTitle.Position = UDim2.new(0,10,0,10)
wGrad(cdTitle)

local cdDiv = Instance.new("Frame")
cdDiv.Size = UDim2.new(1,-20,0,1)
cdDiv.Position = UDim2.new(0,10,0,42)
cdDiv.BackgroundColor3 = T.DarkGray
cdDiv.BorderSizePixel = 0
cdDiv.Parent = cdPanel

local cdCommandList = {
    {n="Rocket",c="rocket"},{n="Ragdoll",c="ragdoll"},{n="Balloon",c="balloon"},
    {n="Inverse",c="inverse"},{n="Jail",c="jail"},{n="NightVision",c="nightvision"},
    {n="Tiny",c="tiny"},{n="Morph",c="morph"},
}
local cdLabels = {}
for i, item in ipairs(cdCommandList) do
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,-20,0,16)
    row.Position = UDim2.new(0,10,0,48+(i-1)*19)
    row.BackgroundTransparency = 1
    row.Parent = cdPanel
    local nl = mkLabel(row, item.n..":", 11, T.MidGray, Enum.Font.Gotham)
    nl.Size = UDim2.new(0.6,0,1,0)
    local vl = mkLabel(row, "Ready", 11, T.Ready, Enum.Font.GothamBold, Enum.TextXAlignment.Right)
    vl.Size = UDim2.new(0.4,0,1,0)
    vl.Position = UDim2.new(0.6,0,0,0)
    cdLabels[item.c] = vl
end

task.spawn(function()
    while cdPanel.Parent do
        for cmd, vl in pairs(cdLabels) do
            if vl and vl.Parent then
                if isOnCD(cmd) then
                    vl.Text = math.ceil(getRemaining(cmd)).."s"
                    vl.TextColor3 = T.Cooldown
                else
                    vl.Text = "Ready"
                    vl.TextColor3 = T.Ready
                end
            end
        end
        task.wait(1)
    end
end)

-- ══════════════════════════════════════════════════════════════
-- AUTO DEFENSE PANEL
-- ══════════════════════════════════════════════════════════════
local defensePanel = Instance.new("Frame")
defensePanel.Name = "NyroxDefensePanel"
defensePanel.Size = UDim2.new(0, 280, 0, 380)
defensePanel.Position = UDim2.new(0, 10, 0, 60)
defensePanel.BackgroundColor3 = T.BgDark
defensePanel.BackgroundTransparency = 0.05
defensePanel.Visible = false
defensePanel.Parent = mainGui
corner(defensePanel, 12)
addBWStroke(defensePanel, 2.2)
makeDraggable(defensePanel)

do
    local hdr = mkLabel(defensePanel, "NYROX  ·  Auto Defense", 15, T.White, Enum.Font.GothamBold)
    hdr.Size = UDim2.new(1,-20,0,44)
    hdr.Position = UDim2.new(0,15,0,0)
    wGrad(hdr)
    divLine(defensePanel, 45)

    local autoDefenseEnabled = false
    local selectedTarget     = nil
    local statusLbl

    local tRow = Instance.new("Frame")
    tRow.Size = UDim2.new(1,-30,0,40)
    tRow.Position = UDim2.new(0,15,0,52)
    tRow.BackgroundColor3 = T.BgCard
    tRow.Parent = defensePanel
    corner(tRow, 8)
    local tLbl = mkLabel(tRow, "Auto Defense", 12, T.LightGray)
    tLbl.Size = UDim2.new(0.6,0,1,0)
    tLbl.Position = UDim2.new(0,10,0,0)
    local tPill = Instance.new("Frame")
    tPill.Size = UDim2.new(0,44,0,22)
    tPill.Position = UDim2.new(1,-54,0.5,-11)
    tPill.BackgroundColor3 = T.BtnBase
    tPill.Parent = tRow
    corner(tPill, 11)
    local tDot = Instance.new("Frame")
    tDot.Size = UDim2.new(0,16,0,16)
    tDot.Position = UDim2.new(0,4,0.5,-8)
    tDot.BackgroundColor3 = T.MidGray
    tDot.Parent = tPill
    corner(tDot, 8)
    local tBtn = Instance.new("TextButton")
    tBtn.Size = UDim2.new(1,0,1,0)
    tBtn.BackgroundTransparency = 1
    tBtn.Text = ""
    tBtn.Parent = tRow
    tBtn.MouseButton1Click:Connect(function()
        autoDefenseEnabled = not autoDefenseEnabled
        tw(tPill, {BackgroundColor3 = autoDefenseEnabled and T.BtnActive or T.BtnBase}, 0.2)
        tw(tDot, {Position=UDim2.new(0, autoDefenseEnabled and 24 or 4, 0.5,-8), BackgroundColor3 = autoDefenseEnabled and T.BtnActTxt or T.MidGray}, 0.2)
        if statusLbl then statusLbl.Text = autoDefenseEnabled and "Waiting..." or "Inactive" end
    end)

    local sFrame = Instance.new("Frame")
    sFrame.Size = UDim2.new(1,-30,0,32)
    sFrame.Position = UDim2.new(0,15,0,97)
    sFrame.BackgroundColor3 = T.BgCard
    sFrame.Parent = defensePanel
    corner(sFrame, 8)
    statusLbl = mkLabel(sFrame, "Inactive", 11, T.MidGray, Enum.Font.Gotham)
    statusLbl.Size = UDim2.new(1,-16,1,0)
    statusLbl.Position = UDim2.new(0,8,0,0)

    divLine(defensePanel, 135)

    local tHdr = mkLabel(defensePanel, "Target Player", 11, T.MidGray, Enum.Font.GothamBold)
    tHdr.Size = UDim2.new(1,-20,0,26)
    tHdr.Position = UDim2.new(0,15,0,140)

    local pScroll = Instance.new("ScrollingFrame")
    pScroll.Size = UDim2.new(1,-30,0,170)
    pScroll.Position = UDim2.new(0,15,0,165)
    pScroll.BackgroundTransparency = 1
    pScroll.BorderSizePixel = 0
    pScroll.ScrollBarThickness = 3
    pScroll.ScrollBarImageColor3 = T.DarkGray
    pScroll.CanvasSize = UDim2.new(0,0,0,0)
    pScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    pScroll.Parent = defensePanel
    local pLL = Instance.new("UIListLayout")
    pLL.SortOrder = Enum.SortOrder.Name
    pLL.Padding = UDim.new(0,4)
    pLL.Parent = pScroll

    local playerBtns = {}

    local function updateBtns()
        for plr, b in pairs(playerBtns) do
            local sel = (plr == selectedTarget)
            b.BackgroundColor3 = sel and T.BtnActive or T.BtnBase
            b.TextColor3 = sel and T.BtnActTxt or T.White
        end
    end

    local function buildPlayerRow(plr)
        local b = Instance.new("TextButton")
        b.Name = "P_"..plr.Name
        b.Size = UDim2.new(1,0,0,32)
        b.BackgroundColor3 = T.BtnBase
        b.Text = plr.DisplayName.."  (@"..plr.Name..")"
        b.Font = Enum.Font.Gotham
        b.TextSize = 11
        b.TextColor3 = T.White
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.AutoButtonColor = false
        b.Parent = pScroll
        corner(b, 6)
        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0,10)
        pad.Parent = b
        playerBtns[plr] = b
        b.MouseButton1Click:Connect(function()
            selectedTarget = (selectedTarget == plr) and nil or plr
            statusLbl.Text = selectedTarget and ("Hedef: "..selectedTarget.Name) or "Hedef yok"
            updateBtns()
        end)
        b.MouseEnter:Connect(function() if plr ~= selectedTarget then tw(b,{BackgroundColor3=T.BtnHover},0.15) end end)
        b.MouseLeave:Connect(function() if plr ~= selectedTarget then tw(b,{BackgroundColor3=T.BtnBase},0.15) end end)
    end

    local function refreshDefensePlayers()
        for _, c in ipairs(pScroll:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        playerBtns = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then buildPlayerRow(plr) end
        end
        if selectedTarget and not selectedTarget.Parent then
            selectedTarget = nil
            if statusLbl then statusLbl.Text = "Target left" end
        end
        updateBtns()
    end

    Players.PlayerAdded:Connect(refreshDefensePlayers)
    Players.PlayerRemoving:Connect(function(plr)
        if selectedTarget == plr then selectedTarget = nil if statusLbl then statusLbl.Text = "Target left" end end
        refreshDefensePlayers()
    end)

    local lastTrig = 0
    local function triggerDefense()
        if not autoDefenseEnabled or not selectedTarget then return end
        if tick() - lastTrig < 5 then return end
        lastTrig = tick()
        if statusLbl then statusLbl.Text = "Savunuyor → "..selectedTarget.Name end
        task.spawn(function()
            execCmd(selectedTarget, "balloon")
            task.wait(0.3)
            execCmd(selectedTarget, "ragdoll")
        end)
    end

    local function scanStealing(gui)
        for _, obj in ipairs(gui:GetDescendants()) do
            if (obj:IsA("TextLabel") or obj:IsA("TextBox")) and obj.Text:lower():find("stealing") then
                return true
            end
        end
        return false
    end

    task.spawn(function()
        while defensePanel.Parent do
            if autoDefenseEnabled then
                for _, gui in ipairs(playerGui:GetChildren()) do
                    if (gui:IsA("ScreenGui") or gui:IsA("BillboardGui")) and gui.Name ~= "NyroxHubV2" then
                        if scanStealing(gui) then triggerDefense() break end
                    end
                end
                pcall(function()
                    for _, gui in ipairs(CoreGui:GetChildren()) do
                        if gui.Name ~= "NyroxHubV2" and scanStealing(gui) then triggerDefense() end
                    end
                end)
            end
            task.wait(0.2)
        end
    end)

    refreshDefensePlayers()
end

-- ══════════════════════════════════════════════════════════════
-- ADMIN PANEL
-- ══════════════════════════════════════════════════════════════
local adminPanel = Instance.new("Frame")
adminPanel.Name = "NyroxAdminPanel"
adminPanel.Size = UDim2.new(0, 300, 0, 550)
adminPanel.Position = UDim2.new(1, -310, 0, 60)
adminPanel.BackgroundColor3 = T.BgDark
adminPanel.BackgroundTransparency = 0.05
adminPanel.Visible = false
adminPanel.Parent = mainGui
corner(adminPanel, 12)
addBWStroke(adminPanel, 2.2)
makeDraggable(adminPanel)

do
    local allModeEnabled = true
    local commands = {"balloon","jumpscare","morph","inverse","nightvision","tiny"}
    local playerFrames = {}

    local aHdr = mkLabel(adminPanel, "NYROX  ·  Command Center", 15, T.White, Enum.Font.GothamBold)
    aHdr.Size = UDim2.new(1,-20,0,44)
    aHdr.Position = UDim2.new(0,15,0,0)
    wGrad(aHdr)

    local aDivider = Instance.new("Frame")
    aDivider.Size = UDim2.new(1,-30,0,1)
    aDivider.Position = UDim2.new(0,15,0,46)
    aDivider.BackgroundColor3 = T.DarkGray
    aDivider.BorderSizePixel = 0
    aDivider.Parent = adminPanel

    local eaRow = Instance.new("Frame")
    eaRow.Size = UDim2.new(1,-30,0,40)
    eaRow.Position = UDim2.new(0,15,0,54)
    eaRow.BackgroundColor3 = T.BgCard
    eaRow.Parent = adminPanel
    corner(eaRow, 8)
    local eaLbl = mkLabel(eaRow, "Execute All", 12, T.LightGray)
    eaLbl.Size = UDim2.new(0.6,0,1,0)
    eaLbl.Position = UDim2.new(0,10,0,0)
    local eaPill = Instance.new("Frame")
    eaPill.Size = UDim2.new(0,44,0,22)
    eaPill.Position = UDim2.new(1,-54,0.5,-11)
    eaPill.BackgroundColor3 = T.BtnActive
    eaPill.Parent = eaRow
    corner(eaPill, 11)
    local eaDot = Instance.new("Frame")
    eaDot.Size = UDim2.new(0,16,0,16)
    eaDot.Position = UDim2.new(0,24,0.5,-8)
    eaDot.BackgroundColor3 = T.BtnActTxt
    eaDot.Parent = eaPill
    corner(eaDot, 8)
    local eaBtn = Instance.new("TextButton")
    eaBtn.Size = UDim2.new(1,0,1,0)
    eaBtn.BackgroundTransparency = 1
    eaBtn.Text = ""
    eaBtn.Parent = eaRow
    eaBtn.MouseButton1Click:Connect(function()
        allModeEnabled = not allModeEnabled
        tw(eaPill, {BackgroundColor3 = allModeEnabled and T.BtnActive or T.BtnBase}, 0.2)
        tw(eaDot, {Position=UDim2.new(0, allModeEnabled and 24 or 4, 0.5,-8), BackgroundColor3 = allModeEnabled and T.BtnActTxt or T.MidGray}, 0.2)
    end)

    local rsRow = Instance.new("Frame")
    rsRow.Size = UDim2.new(1,-30,0,40)
    rsRow.Position = UDim2.new(0,15,0,99)
    rsRow.BackgroundColor3 = T.BgCard
    rsRow.Parent = adminPanel
    corner(rsRow, 8)
    local rsLbl = mkLabel(rsRow, "Ragdoll Self", 12, T.LightGray)
    rsLbl.Size = UDim2.new(0.6,0,1,0)
    rsLbl.Position = UDim2.new(0,10,0,0)
    local rsBtn = Instance.new("TextButton")
    rsBtn.Size = UDim2.new(0,82,0,28)
    rsBtn.Position = UDim2.new(1,-92,0.5,-14)
    rsBtn.BackgroundColor3 = T.BtnBase
    rsBtn.Text = "RAGDOLL"
    rsBtn.Font = Enum.Font.GothamBold
    rsBtn.TextSize = 10
    rsBtn.TextColor3 = T.White
    rsBtn.AutoButtonColor = false
    rsBtn.Parent = rsRow
    corner(rsBtn, 6)
    rsBtn.MouseButton1Click:Connect(function()
        execCmd(LocalPlayer, "ragdoll")
        tw(rsBtn,{BackgroundTransparency=0.5},0.1) task.wait(0.1) tw(rsBtn,{BackgroundTransparency=0},0.1)
    end)
    rsBtn.MouseEnter:Connect(function() tw(rsBtn,{BackgroundColor3=T.BtnHover},0.15) end)
    rsBtn.MouseLeave:Connect(function() tw(rsBtn,{BackgroundColor3=T.BtnBase},0.15) end)

    local aplScroll = Instance.new("ScrollingFrame")
    aplScroll.Size = UDim2.new(1,-30,1,-150)
    aplScroll.Position = UDim2.new(0,15,0,148)
    aplScroll.BackgroundTransparency = 1
    aplScroll.BorderSizePixel = 0
    aplScroll.ScrollBarThickness = 3
    aplScroll.ScrollBarImageColor3 = T.DarkGray
    aplScroll.CanvasSize = UDim2.new(0,0,0,0)
    aplScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    aplScroll.Parent = adminPanel
    local aplLL = Instance.new("UIListLayout")
    aplLL.SortOrder = Enum.SortOrder.Name
    aplLL.Padding = UDim.new(0,5)
    aplLL.Parent = aplScroll

    local function buildAdminPlayerRow(player)
        local card = Instance.new("Frame")
        card.Name = "P_"..player.Name
        card.Size = UDim2.new(1,0,0,36)
        card.BackgroundColor3 = T.BgCard
        card.Parent = aplScroll
        corner(card, 6)
        playerFrames[player] = card

        local nLbl = Instance.new("TextLabel")
        nLbl.Size = UDim2.new(0.44,-8,1,0)
        nLbl.Position = UDim2.new(0,10,0,0)
        nLbl.BackgroundTransparency = 1
        nLbl.Text = player.DisplayName.."\n@"..player.Name
        nLbl.Font = Enum.Font.Gotham
        nLbl.TextSize = 9
        nLbl.TextColor3 = T.LightGray
        nLbl.TextXAlignment = Enum.TextXAlignment.Left
        nLbl.TextYAlignment = Enum.TextYAlignment.Center
        nLbl.TextWrapped = true
        nLbl.Parent = card

        local bHolder = Instance.new("Frame")
        bHolder.Size = UDim2.new(0.56,-10,1,-8)
        bHolder.Position = UDim2.new(0.44,0,0,4)
        bHolder.BackgroundTransparency = 1
        bHolder.Parent = card
        local bLL = Instance.new("UIListLayout")
        bLL.FillDirection = Enum.FillDirection.Horizontal
        bLL.Padding = UDim.new(0,3)
        bLL.VerticalAlignment = Enum.VerticalAlignment.Center
        bLL.Parent = bHolder

        local btns = {
            {t="JAIL",c="jail"},{t="RAG",c="ragdoll"},
            {t="RKT",c="rocket"},{t="BLN",c="balloon"},
        }
        for _, b in ipairs(btns) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0,33,0,26)
            btn.BackgroundColor3 = T.BtnBase
            btn.Text = b.t
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 8
            btn.TextColor3 = T.White
            btn.AutoButtonColor = false
            btn.Parent = bHolder
            corner(btn, 4)
            btn.MouseButton1Click:Connect(function()
                execCmd(player, b.c)
                tw(btn,{BackgroundTransparency=0.5},0.1) task.wait(0.1) tw(btn,{BackgroundTransparency=0},0.1)
            end)
            btn.MouseEnter:Connect(function() tw(btn,{BackgroundColor3=T.BtnHover},0.15) end)
            btn.MouseLeave:Connect(function() tw(btn,{BackgroundColor3=T.BtnBase},0.15) end)
            task.spawn(function()
                while btn.Parent do
                    local cd = isOnCD(b.c)
                    btn.BackgroundTransparency = cd and 0.6 or 0
                    btn.TextTransparency       = cd and 0.5 or 0
                    task.wait(1)
                end
            end)
        end

        card.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 and allModeEnabled then
                for _, cmd in ipairs(commands) do
                    execCmd(player, cmd)
                    task.wait(0.05)
                end
            end
        end)
        card.MouseEnter:Connect(function() tw(card,{BackgroundColor3=T.BgCardHov},0.18) end)
        card.MouseLeave:Connect(function() tw(card,{BackgroundColor3=T.BgCard},0.18) end)
    end

    local function refreshAdminPlayers()
        for _, c in ipairs(aplScroll:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        playerFrames = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then buildAdminPlayerRow(plr) end
        end
    end

    Players.PlayerAdded:Connect(refreshAdminPlayers)
    Players.PlayerRemoving:Connect(function(plr)
        playerFrames[plr] = nil
        refreshAdminPlayers()
    end)

    task.spawn(function()
        while adminPanel.Parent do
            for plr, frame in pairs(playerFrames) do
                if plr and plr.Parent and frame and frame.Parent then
                    local char = plr.Character
                    if char then
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if hum then
                            frame.BackgroundColor3 = (hum.WalkSpeed > 13 and hum.WalkSpeed < 30) and T.SpeedWarn or T.BgCard
                        end
                    end
                end
            end
            task.wait(0.5)
        end
    end)

    refreshAdminPlayers()
end

-- ══════════════════════════════════════════════════════════════
-- AUTO GRAB (Nyrox Hub original - Helper tab için)
-- ══════════════════════════════════════════════════════════════
local autoGrabEnabled   = CFG.autoGrab
local autoGrabRadius    = CFG.grabRadius
local agIsGrabbing      = false
local agConn            = nil
local agStealData       = {}

local function agIsMyPlot(plotName)
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return false end
    local plot = plots:FindFirstChild(plotName)
    if not plot then return false end
    local sign = plot:FindFirstChild("PlotSign")
    if sign then
        local yb = sign:FindFirstChild("YourBase")
        if yb and yb:IsA("BillboardGui") then return yb.Enabled == true end
    end
    return false
end

local function agFindPrompt()
    local c = LocalPlayer.Character
    local hrp = c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("UpperTorso"))
    if not hrp then return nil end
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end
    local np, nd = nil, math.huge
    for _, plot in ipairs(plots:GetChildren()) do
        if agIsMyPlot(plot.Name) then continue end
        local podiums = plot:FindFirstChild("AnimalPodiums")
        if not podiums then continue end
        for _, pod in ipairs(podiums:GetChildren()) do
            pcall(function()
                local base = pod:FindFirstChild("Base")
                local spawn = base and base:FindFirstChild("Spawn")
                if spawn then
                    local dist = (spawn.Position - hrp.Position).Magnitude
                    if dist < nd and dist <= autoGrabRadius then
                        local att = spawn:FindFirstChild("PromptAttachment")
                        if att then
                            for _, ch in ipairs(att:GetChildren()) do
                                if ch:IsA("ProximityPrompt") then
                                    np, nd = ch, dist
                                    break
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
    return np
end

local function agExecuteGrab(prompt)
    if agIsGrabbing then return end
    if not agStealData[prompt] then
        agStealData[prompt] = {hold = {}, trigger = {}, ready = true}
        pcall(function()
            if getconnections then
                for _, c in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do
                    if c.Function then table.insert(agStealData[prompt].hold, c.Function) end
                end
                for _, c in ipairs(getconnections(prompt.Triggered)) do
                    if c.Function then table.insert(agStealData[prompt].trigger, c.Function) end
                end
            end
        end)
    end
    local data = agStealData[prompt]
    if not data.ready then return end
    data.ready   = false
    agIsGrabbing = true
    task.spawn(function()
        for _, f in ipairs(data.hold) do task.spawn(f) end
        task.wait(0.2)
        for _, f in ipairs(data.trigger) do task.spawn(f) end
        data.ready   = true
        agIsGrabbing = false
    end)
end

local function agStart()
    if agConn then agConn:Disconnect() end
    agConn = RunService.Heartbeat:Connect(function()
        if not autoGrabEnabled or agIsGrabbing then return end
        local p = agFindPrompt()
        if p then agExecuteGrab(p) end
    end)
end

local function agStop()
    if agConn then agConn:Disconnect() agConn = nil end
    agIsGrabbing = false
    agStealData  = {}
end

-- ══════════════════════════════════════════════════════════════
-- AUTO FLASH (InstaGrab)
-- ══════════════════════════════════════════════════════════════
local flashTPEnabled      = CFG.autoFlashEnabled
local flashTPPillRef, flashTPDotRef

local igStealing   = false
local igProgress   = 0
local igThreshold  = CFG.stealThreshold
local igRadius     = 20
local igCache      = {}
local igCircle     = {}

local function syncFlashTPUI()
    CFG.autoFlashEnabled = flashTPEnabled
    saveState()
    if flashTPPillRef and flashTPPillRef.Parent then
        tw(flashTPPillRef, {BackgroundColor3 = flashTPEnabled and T.BtnActive or T.BtnBase}, 0.2)
        tw(flashTPDotRef,  {Position=UDim2.new(0, flashTPEnabled and 24 or 4, 0.5,-8), BackgroundColor3 = flashTPEnabled and T.BtnActTxt or T.MidGray}, 0.2)
    end
end

local function igGetHRP()
    local c = LocalPlayer.Character
    return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("UpperTorso"))
end

local function igIsMyBase(plotName)
    local plots = workspace:FindFirstChild("Plots")
    local plot  = plots and plots:FindFirstChild(plotName)
    if not plot then return false end
    local sign = plot:FindFirstChild("PlotSign")
    local yb   = sign and sign:FindFirstChild("YourBase")
    return yb and yb:IsA("BillboardGui") and yb.Enabled == true
end

local function igClickTool()
    local c = LocalPlayer.Character
    if not c then return end
    local t = c:FindFirstChildOfClass("Tool")
    if t then t:Activate() end
end

local function igSteal(prompt)
    if igStealing or not prompt or not prompt.Parent then return end
    igStealing = true
    local cbs = {hold={}, trig={}}
    pcall(function()
        local ok1, c1 = pcall(getconnections, prompt.PromptButtonHoldBegan)
        if ok1 then for _, c in ipairs(c1) do table.insert(cbs.hold, c.Function) end end
        local ok2, c2 = pcall(getconnections, prompt.Triggered)
        if ok2 then for _, c in ipairs(c2) do table.insert(cbs.trig, c.Function) end end
    end)
    task.spawn(function()
        task.wait(0.085)
        for _, fn in ipairs(cbs.hold) do task.spawn(fn) end
        local t0 = tick(); local dur = 0.32; local clicked = false
        while tick()-t0 < dur do
            igProgress = 0.6 + ((tick()-t0)/dur)*0.4
            if igProgress >= igThreshold and not clicked then
                clicked = true; igClickTool()
            end
            task.wait(0.005)
        end
        igProgress = 1
        for _, fn in ipairs(cbs.trig) do task.spawn(fn) end
        task.wait(0.1)
        igStealing = false; igProgress = 0
    end)
end

local function igScanPlot(plot)
    if not plot or not plot:IsA("Model") or igIsMyBase(plot.Name) then return end
    local pods = plot:FindFirstChild("AnimalPodiums")
    if not pods then return end
    for _, pod in ipairs(pods:GetChildren()) do
        if pod:IsA("Model") and pod:FindFirstChild("Base") then
            table.insert(igCache, {plot=plot.Name, slot=pod.Name, wp=pod:GetPivot().Position})
        end
    end
end

task.spawn(function()
    local plots = workspace:WaitForChild("Plots", 10)
    if not plots then return end
    for _, p in ipairs(plots:GetChildren()) do igScanPlot(p) end
    plots.ChildAdded:Connect(igScanPlot)
    for i = 1, 65 do
        local p = Instance.new("Part", workspace)
        p.Anchored=true; p.CanCollide=false; p.Transparency=1
        p.Size=Vector3.new(1.5,0.2,0.2)
        p.Color=Color3.fromRGB(0,255,255); p.Material=Enum.Material.Neon
        table.insert(igCircle, p)
    end
end)

RunService.Heartbeat:Connect(function()
    local hrp = igGetHRP()
    if not hrp then return end
    for i, part in ipairs(igCircle) do
        local a = math.rad((i-1)*360/65)
        part.Position = hrp.Position + Vector3.new(math.cos(a),-2.5,math.sin(a))*igRadius
        part.Transparency = flashTPEnabled and 0.4 or 1
    end
    if flashTPEnabled and not igStealing then
        local nearest, md = nil, math.huge
        for _, an in ipairs(igCache) do
            local d = (hrp.Position - an.wp).Magnitude
            if d < md then md=d; nearest=an end
        end
        if nearest and md <= igRadius then
            local plots = workspace:FindFirstChild("Plots")
            local plot  = plots and plots:FindFirstChild(nearest.plot)
            local pods  = plot and plot:FindFirstChild("AnimalPodiums")
            local pod   = pods and pods:FindFirstChild(nearest.slot)
            local base  = pod and pod:FindFirstChild("Base")
            local sp    = base and base:FindFirstChild("Spawn")
            local att   = sp and sp:FindFirstChild("PromptAttachment")
            local prom  = att and att:FindFirstChildOfClass("ProximityPrompt")
            if prom then igSteal(prom) end
        end
    end
end)

-- ══════════════════════════════════════════════════════════════
-- FLASH TP FLOATING PANEL
-- ══════════════════════════════════════════════════════════════
local flashTPPanel = Instance.new("Frame")
flashTPPanel.Name = "NyroxFlashTP"
flashTPPanel.Size = UDim2.new(0, 220, 0, 130)
flashTPPanel.Position = UDim2.new(0, 10, 1, -150)
flashTPPanel.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
flashTPPanel.BackgroundTransparency = 0
flashTPPanel.Visible = false
flashTPPanel.Parent = mainGui
corner(flashTPPanel, 14)
addBWStroke(flashTPPanel, 2.2)
makeDraggable(flashTPPanel)

do
    local discordLbl = Instance.new("TextLabel")
    discordLbl.Size = UDim2.new(1,0,0,22)
    discordLbl.Position = UDim2.new(0,0,0,6)
    discordLbl.BackgroundTransparency = 1
    discordLbl.Text = "discord.gg/HCntzDTWJV"
    discordLbl.Font = Enum.Font.GothamBold
    discordLbl.TextSize = 10
    discordLbl.TextColor3 = T.MidGray
    discordLbl.TextXAlignment = Enum.TextXAlignment.Center
    discordLbl.Parent = flashTPPanel

    local div1 = Instance.new("Frame")
    div1.Size = UDim2.new(1,-20,0,1)
    div1.Position = UDim2.new(0,10,0,30)
    div1.BackgroundColor3 = T.DarkGray
    div1.BorderSizePixel = 0
    div1.Parent = flashTPPanel

    local ftRow = Instance.new("Frame")
    ftRow.Size = UDim2.new(1,-20,0,36)
    ftRow.Position = UDim2.new(0,10,0,36)
    ftRow.BackgroundTransparency = 1
    ftRow.Parent = flashTPPanel

    local ftLbl = mkLabel(ftRow, "Auto Flash", 12, T.White, Enum.Font.GothamSemibold)
    ftLbl.Size = UDim2.new(0.6,0,1,0)

    local ftPill = Instance.new("Frame")
    ftPill.Size = UDim2.new(0,44,0,22)
    ftPill.Position = UDim2.new(1,-44,0.5,-11)
    ftPill.BackgroundColor3 = T.BtnBase
    ftPill.Parent = ftRow
    corner(ftPill, 11)

    local ftDot = Instance.new("Frame")
    ftDot.Size = UDim2.new(0,16,0,16)
    ftDot.Position = UDim2.new(0,4,0.5,-8)
    ftDot.BackgroundColor3 = T.MidGray
    ftDot.Parent = ftPill
    corner(ftDot, 8)

    flashTPPillRef = ftPill
    flashTPDotRef  = ftDot

    local ftBtn = Instance.new("TextButton")
    ftBtn.Size = UDim2.new(1,0,1,0)
    ftBtn.BackgroundTransparency = 1
    ftBtn.Text = ""
    ftBtn.Parent = ftRow
    ftBtn.MouseButton1Click:Connect(function()
        flashTPEnabled = not flashTPEnabled
        syncFlashTPUI()
        saveState()
    end)

    local div2 = Instance.new("Frame")
    div2.Size = UDim2.new(1,-20,0,1)
    div2.Position = UDim2.new(0,10,0,77)
    div2.BackgroundColor3 = T.DarkGray
    div2.BorderSizePixel = 0
    div2.Parent = flashTPPanel

    local slRow = Instance.new("Frame")
    slRow.Size = UDim2.new(1,-20,0,44)
    slRow.Position = UDim2.new(0,10,0,82)
    slRow.BackgroundTransparency = 1
    slRow.Parent = flashTPPanel

    local slLbl = mkLabel(slRow, "Steal Timing", 11, T.MidGray, Enum.Font.GothamSemibold)
    slLbl.Size = UDim2.new(0.58,0,0,18)
    slLbl.Position = UDim2.new(0,0,0,0)

    local slValLbl = mkLabel(slRow, math.floor(igThreshold*100).."%", 11, T.White, Enum.Font.GothamBold, Enum.TextXAlignment.Right)
    slValLbl.Size = UDim2.new(0.38,0,0,18)
    slValLbl.Position = UDim2.new(0.60,0,0,0)

    local slTrack = Instance.new("Frame")
    slTrack.Size = UDim2.new(1,0,0,6)
    slTrack.Position = UDim2.new(0,0,0,26)
    slTrack.BackgroundColor3 = T.BtnBase
    slTrack.Parent = slRow
    corner(slTrack, 3)

    local slFill = Instance.new("Frame")
    slFill.BackgroundColor3 = T.BtnActive
    slFill.Size = UDim2.new((igThreshold-0.70)/0.25, 0, 1, 0)
    slFill.Parent = slTrack
    corner(slFill, 3)

    local slKnob = Instance.new("TextButton")
    slKnob.Size = UDim2.new(0,16,0,16)
    slKnob.Position = UDim2.new((igThreshold-0.70)/0.25, -8, 0.5, -8)
    slKnob.BackgroundColor3 = T.White
    slKnob.Text = ""
    slKnob.AutoButtonColor = false
    slKnob.Parent = slTrack
    corner(slKnob, 8)

    local slDrag = false
    nyroxSlFill = slFill
    nyroxSlKnob = slKnob
    nyroxSlVal  = slValLbl
    slKnob.MouseButton1Down:Connect(function() slDrag = true end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then slDrag = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if slDrag and i.UserInputType == Enum.UserInputType.MouseMovement then
            local rx = math.clamp((UserInputService:GetMouseLocation().X - slTrack.AbsolutePosition.X)/slTrack.AbsoluteSize.X, 0, 1)
            igThreshold = 0.70 + rx*0.25
            CFG.stealThreshold = igThreshold
            slFill.Size = UDim2.new(rx,0,1,0)
            slKnob.Position = UDim2.new(rx,-8,0.5,-8)
            slValLbl.Text = math.floor(igThreshold*100).."%"
            saveState()
        end
    end)
end

-- ══════════════════════════════════════════════════════════════
-- SEMI TP FLOATING PANEL (Flash TP gibi)
-- ══════════════════════════════════════════════════════════════
local semiTPPanel = Instance.new("Frame")
semiTPPanel.Name = "NyroxSemiTP"
semiTPPanel.Size = UDim2.new(0, 220, 0, 160)
semiTPPanel.Position = UDim2.new(0, 240, 1, -150)  -- Flash TP'nin yanında
semiTPPanel.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
semiTPPanel.BackgroundTransparency = 0
semiTPPanel.Visible = false
semiTPPanel.Parent = mainGui
corner(semiTPPanel, 14)
addBWStroke(semiTPPanel, 2.2)
makeDraggable(semiTPPanel)

do
    local stDiscord = Instance.new("TextLabel")
    stDiscord.Size = UDim2.new(1,0,0,22)
    stDiscord.Position = UDim2.new(0,0,0,6)
    stDiscord.BackgroundTransparency = 1
    stDiscord.Text = "NYROX  ·  Half TP"
    stDiscord.Font = Enum.Font.GothamBold
    stDiscord.TextSize = 11
    stDiscord.TextColor3 = T.MidGray
    stDiscord.TextXAlignment = Enum.TextXAlignment.Center
    stDiscord.Parent = semiTPPanel

    local stDiv1 = Instance.new("Frame")
    stDiv1.Size = UDim2.new(1,-20,0,1)
    stDiv1.Position = UDim2.new(0,10,0,30)
    stDiv1.BackgroundColor3 = T.DarkGray
    stDiv1.BorderSizePixel = 0
    stDiv1.Parent = semiTPPanel

    -- Teleport System toggle
    local stRow = Instance.new("Frame")
    stRow.Size = UDim2.new(1,-20,0,36)
    stRow.Position = UDim2.new(0,10,0,36)
    stRow.BackgroundTransparency = 1
    stRow.Parent = semiTPPanel

    local stLbl = mkLabel(stRow, "Teleport System", 12, T.White, Enum.Font.GothamSemibold)
    stLbl.Size = UDim2.new(0.62,0,1,0)

    local stPill = Instance.new("Frame")
    stPill.Size = UDim2.new(0,44,0,22)
    stPill.Position = UDim2.new(1,-44,0.5,-11)
    stPill.BackgroundColor3 = T.BtnBase
    stPill.Parent = stRow
    corner(stPill, 11)

    local stDot = Instance.new("Frame")
    stDot.Size = UDim2.new(0,16,0,16)
    stDot.Position = UDim2.new(0,4,0.5,-8)
    stDot.BackgroundColor3 = T.MidGray
    stDot.Parent = stPill
    corner(stDot, 8)

    local stBtn = Instance.new("TextButton")
    stBtn.Size = UDim2.new(1,0,1,0)
    stBtn.BackgroundTransparency = 1
    stBtn.Text = ""
    stBtn.Parent = stRow
    stBtn.MouseButton1Click:Connect(function()
        semiTPEnabled = not semiTPEnabled
        CFG.semiTPEnabled = semiTPEnabled
        tw(stPill, {BackgroundColor3 = semiTPEnabled and T.BtnActive or T.BtnBase}, 0.2)
        tw(stDot,  {Position = UDim2.new(0, semiTPEnabled and 24 or 4, 0.5,-8), BackgroundColor3 = semiTPEnabled and T.BtnActTxt or T.MidGray}, 0.2)
        if semiTPEnabled then
            if not semiMarker or not semiMarker.Parent then semiMarker = createSemiMarker() end
        else
            semiAgStop()
            if semiMarker and semiMarker.Parent then pcall(function() semiMarker:Destroy() end) semiMarker = nil end
        end
        saveState()
    end)

    local stDiv2 = Instance.new("Frame")
    stDiv2.Size = UDim2.new(1,-20,0,1)
    stDiv2.Position = UDim2.new(0,10,0,77)
    stDiv2.BackgroundColor3 = T.DarkGray
    stDiv2.BorderSizePixel = 0
    stDiv2.Parent = semiTPPanel

    -- G tuşu butonu
    local stTpRow = Instance.new("Frame")
    stTpRow.Size = UDim2.new(1,-20,0,36)
    stTpRow.Position = UDim2.new(0,10,0,83)
    stTpRow.BackgroundTransparency = 1
    stTpRow.Parent = semiTPPanel

    local stTpLbl = mkLabel(stTpRow, "Half Teleport", 12, T.White, Enum.Font.GothamSemibold)
    stTpLbl.Size = UDim2.new(0.5,0,1,0)

    local stKeyLbl = mkLabel(stTpRow, "[G]", 11, T.MidGray, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
    stKeyLbl.Size = UDim2.new(0.18,0,1,0)
    stKeyLbl.Position = UDim2.new(0.48,0,0,0)

    local stTpBtn = Instance.new("TextButton")
    stTpBtn.Size = UDim2.new(0,60,0,26)
    stTpBtn.Position = UDim2.new(1,-64,0.5,-13)
    stTpBtn.BackgroundColor3 = T.BtnBase
    stTpBtn.Text = "TP"
    stTpBtn.Font = Enum.Font.GothamBold
    stTpBtn.TextSize = 11
    stTpBtn.TextColor3 = T.White
    stTpBtn.AutoButtonColor = false
    stTpBtn.Parent = stTpRow
    corner(stTpBtn, 6)
    stTpBtn.MouseButton1Click:Connect(function()
        tw(stTpBtn,{BackgroundTransparency=0.5},0.1) task.wait(0.1) tw(stTpBtn,{BackgroundTransparency=0},0.1)
        executeSemiTP()
    end)
    stTpBtn.MouseEnter:Connect(function() tw(stTpBtn,{BackgroundColor3=T.BtnHover},0.15) end)
    stTpBtn.MouseLeave:Connect(function() tw(stTpBtn,{BackgroundColor3=T.BtnBase},0.15) end)

    local stDiv3 = Instance.new("Frame")
    stDiv3.Size = UDim2.new(1,-20,0,1)
    stDiv3.Position = UDim2.new(0,10,0,124)
    stDiv3.BackgroundColor3 = T.DarkGray
    stDiv3.BorderSizePixel = 0
    stDiv3.Parent = semiTPPanel

    -- Cooldown göstergesi
    local stCdLbl = mkLabel(semiTPPanel, "Ready", 11, T.Ready, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
    stCdLbl.Size = UDim2.new(1,-20,0,26)
    stCdLbl.Position = UDim2.new(0,10,0,128)

    task.spawn(function()
        while semiTPPanel.Parent do
            local rem = SEMI_TP_COOLDOWN - (tick() - semiTPLastTime)
            if rem > 0 then
                stCdLbl.Text = "Cooldown: "..math.ceil(rem).."s"
                stCdLbl.TextColor3 = T.Cooldown
            else
                stCdLbl.Text = "Ready"
                stCdLbl.TextColor3 = T.Ready
            end
            task.wait(0.2)
        end
    end)
end
local optimizerEnabled = CFG.optimizer
local xrayEnabled = CFG.xray
local xrayOriginalTransparency = {}
local xrayWatchConn = nil

local function xrayIsBasePart(obj)
    return obj:IsA("BasePart") and obj.Anchored and
        (obj.Name:lower():find("base") or (obj.Parent and obj.Parent.Name:lower():find("base")))
end

local function xrayApply(obj)
    if xrayIsBasePart(obj) then
        if xrayOriginalTransparency[obj] == nil then
            xrayOriginalTransparency[obj] = obj.LocalTransparencyModifier
        end
        pcall(function() obj.LocalTransparencyModifier = 0.85 end)
    end
end

local function xrayStart()
    for _, obj in ipairs(workspace:GetDescendants()) do pcall(function() xrayApply(obj) end) end
    if xrayWatchConn then xrayWatchConn:Disconnect() end
    xrayWatchConn = workspace.DescendantAdded:Connect(function(obj)
        if xrayEnabled then task.wait(0.1) pcall(function() xrayApply(obj) end) end
    end)
end

local function xrayStop()
    if xrayWatchConn then xrayWatchConn:Disconnect() xrayWatchConn = nil end
    for part, val in pairs(xrayOriginalTransparency) do
        pcall(function() if part and part.Parent then part.LocalTransparencyModifier = val end end)
    end
    xrayOriginalTransparency = {}
end

local function enableOptimizer()
    if optimizerEnabled then return end
    optimizerEnabled = true
    pcall(function()
        local Lighting = game:GetService("Lighting")
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        Lighting.GlobalShadows = false
        Lighting.Brightness = 3
        Lighting.FogEnd = 9e9
    end)
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            pcall(function()
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
                    obj:Destroy()
                elseif obj:IsA("BasePart") then
                    obj.CastShadow = false
                    obj.Material = Enum.Material.Plastic
                end
            end)
        end
    end)
end

local function disableOptimizer()
    if not optimizerEnabled then return end
    optimizerEnabled = false
end

-- ══════════════════════════════════════════════════════════════
-- AUTO DESTROY TURRET
-- ══════════════════════════════════════════════════════════════
local autoTurretEnabled   = CFG.autoTurret
local originalBatSize     = nil
local mySentries          = {}
local lastSentryPlaceTime = 0
local lastSentryPlacePos  = nil
local turretConnection    = nil

local function forceBatEquip()
    local char = LocalPlayer.Character
    if not char then return nil, nil end
    local bp = LocalPlayer.Backpack
    if not bp then return nil, nil end
    local bat = bp:FindFirstChild("Bat") or char:FindFirstChild("Bat")
    if not bat then return nil, nil end
    bat.Parent = char
    task.wait(0.05)
    local handle = bat:FindFirstChild("Handle")
    if handle and not originalBatSize then originalBatSize = handle.Size end
    return bat, handle
end

local function restoreBat(bat, handle)
    if bat and handle and originalBatSize then
        handle.Size = originalBatSize
        handle.CanCollide = true
        handle.Transparency = 0
    end
    if bat and LocalPlayer.Backpack then bat.Parent = LocalPlayer.Backpack end
end

local function isMySentry(sentry) return mySentries[sentry] == true end

local function markAsMySentry(sentry)
    if mySentries[sentry] then return end
    mySentries[sentry] = true
    local hl = Instance.new("Highlight")
    hl.Name = "MySentryHighlight"
    hl.FillColor = Color3.fromRGB(0,150,255)
    hl.OutlineColor = Color3.fromRGB(0,255,255)
    hl.FillTransparency = 0.7
    hl.OutlineTransparency = 0
    hl.Parent = sentry
    sentry.AncestryChanged:Connect(function(_, parent)
        if not parent then mySentries[sentry] = nil end
    end)
end

local function getSentryTimer(turret)
    for _, child in pairs(turret:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("TextBox") then
            local n = child.Text:match("(%d+)s!")
            if n then return tonumber(n) end
        end
    end
    return nil
end

local function attackSentry(sentry)
    if not autoTurretEnabled then return end
    if isMySentry(sentry) then return end
    task.spawn(function()
        local bat, handle = forceBatEquip()
        if not bat or not handle then return end
        handle.Size = Vector3.new(99991002, 190, 999922)
        handle.CanCollide = false
        handle.Transparency = 1
        local char = LocalPlayer.Character
        local flip = true
        while sentry and sentry.Parent and autoTurretEnabled and not isMySentry(sentry) do
            if not getSentryTimer(sentry) then task.wait(0.1) continue end
            bat.Parent = flip and char or LocalPlayer.Backpack
            flip = not flip
            if bat.Parent ~= char then bat.Parent = char task.wait(0.02) end
            pcall(function() bat:Activate() end)
            for _, r in pairs(bat:GetDescendants()) do
                if r:IsA("RemoteEvent") then pcall(function() r:FireServer() end) end
            end
            task.wait(0.05)
        end
        restoreBat(bat, handle)
    end)
end

local function setupSentryWatcher()
    local function watchTool(tool)
        if tool.Name == "All Seeing Sentry" then
            tool.Activated:Connect(function()
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    lastSentryPlaceTime = tick()
                    lastSentryPlacePos  = char.HumanoidRootPart.Position
                end
            end)
        end
    end
    for _, t in pairs(LocalPlayer.Backpack:GetChildren()) do watchTool(t) end
    if LocalPlayer.Character then
        for _, t in pairs(LocalPlayer.Character:GetChildren()) do watchTool(t) end
    end
    LocalPlayer.Backpack.ChildAdded:Connect(watchTool)
    LocalPlayer.CharacterAdded:Connect(function(char)
        char.ChildAdded:Connect(watchTool)
        for _, t in pairs(char:GetChildren()) do watchTool(t) end
    end)
end

local function onSentrySpawned(obj)
    if not obj.Name:match("^Sentry_%d+$") then return end
    if not autoTurretEnabled then return end
    local timeSince = tick() - lastSentryPlaceTime
    if timeSince < 2 and lastSentryPlacePos then
        local pp = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        if pp and (pp.Position - lastSentryPlacePos).Magnitude < 20 then
            markAsMySentry(obj)
            lastSentryPlaceTime = 0
            lastSentryPlacePos  = nil
            return
        end
    end
    task.delay(0.1, function()
        if not isMySentry(obj) then attackSentry(obj) end
    end)
end

local function enableAutoTurret()
    if turretConnection then return end
    autoTurretEnabled = true
    setupSentryWatcher()
    turretConnection = workspace.ChildAdded:Connect(onSentrySpawned)
    for _, obj in pairs(workspace:GetChildren()) do
        if obj.Name:match("^Sentry_%d+$") and not isMySentry(obj) then attackSentry(obj) end
    end
end

local function disableAutoTurret()
    autoTurretEnabled = false
    if turretConnection then turretConnection:Disconnect() turretConnection = nil end
end

-- ══════════════════════════════════════════════════════════════
-- BOOSTER PANEL
-- ══════════════════════════════════════════════════════════════
local boosterEnabled  = CFG.boosterEnabled
local boosterSpeedVal = CFG.boosterSpeed
local boosterJumpVal  = CFG.boosterJump
local bpPillRef, bpDotRef

local function syncBoosterUI()
    CFG.boosterEnabled = boosterEnabled
    CFG.boosterSpeed   = boosterSpeedVal
    CFG.boosterJump    = boosterJumpVal
    saveState()
    if not bpPillRef or not bpPillRef.Parent then return end
    tw(bpPillRef, {BackgroundColor3 = boosterEnabled and T.BtnActive or T.BtnBase}, 0.2)
    tw(bpDotRef,  {Position=UDim2.new(0, boosterEnabled and 24 or 4, 0.5,-8), BackgroundColor3 = boosterEnabled and T.BtnActTxt or T.MidGray}, 0.2)
end

RunService.Heartbeat:Connect(function()
    if not boosterEnabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum  = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return end
    if hum.MoveDirection.Magnitude > 0 then
        root.Velocity = Vector3.new(hum.MoveDirection.X*boosterSpeedVal, root.Velocity.Y, hum.MoveDirection.Z*boosterSpeedVal)
    end
    hum.UseJumpPower = true
    hum.JumpPower = boosterJumpVal
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.2)
    if not boosterEnabled then return end
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then hum.UseJumpPower = true; hum.JumpPower = boosterJumpVal end
end)

local boosterPanel = Instance.new("Frame")
boosterPanel.Name = "NyroxBoosterPanel"
boosterPanel.Size = UDim2.new(0, 280, 0, 230)
boosterPanel.Position = UDim2.new(0, 10, 0.5, -115)
boosterPanel.BackgroundColor3 = T.BgDark
boosterPanel.BackgroundTransparency = 0.05
boosterPanel.Visible = false
boosterPanel.Parent = mainGui
corner(boosterPanel, 12)
addBWStroke(boosterPanel, 2.2)
makeDraggable(boosterPanel)

do
    local bpHdr = mkLabel(boosterPanel, "NYROX  ·  Booster", 15, T.White, Enum.Font.GothamBold)
    bpHdr.Size = UDim2.new(1,-20,0,44)
    bpHdr.Position = UDim2.new(0,15,0,0)
    wGrad(bpHdr)
    divLine(boosterPanel, 45)

    local bpTogRow = Instance.new("Frame")
    bpTogRow.Size = UDim2.new(1,-30,0,40)
    bpTogRow.Position = UDim2.new(0,15,0,52)
    bpTogRow.BackgroundColor3 = T.BgCard
    bpTogRow.Parent = boosterPanel
    corner(bpTogRow, 8)
    local bpTogLbl = mkLabel(bpTogRow, "Booster", 12, T.LightGray)
    bpTogLbl.Size = UDim2.new(0.6,0,1,0)
    bpTogLbl.Position = UDim2.new(0,10,0,0)
    local bpPill = Instance.new("Frame")
    bpPill.Size = UDim2.new(0,44,0,22)
    bpPill.Position = UDim2.new(1,-54,0.5,-11)
    bpPill.BackgroundColor3 = T.BtnBase
    bpPill.Parent = bpTogRow
    corner(bpPill, 11)
    local bpDot = Instance.new("Frame")
    bpDot.Size = UDim2.new(0,16,0,16)
    bpDot.Position = UDim2.new(0,4,0.5,-8)
    bpDot.BackgroundColor3 = T.MidGray
    bpDot.Parent = bpPill
    corner(bpDot, 8)
    bpPillRef = bpPill; bpDotRef = bpDot
    local bpTogBtn = Instance.new("TextButton")
    bpTogBtn.Size = UDim2.new(1,0,1,0)
    bpTogBtn.BackgroundTransparency = 1
    bpTogBtn.Text = ""
    bpTogBtn.Parent = bpTogRow
    bpTogBtn.MouseButton1Click:Connect(function()
        boosterEnabled = not boosterEnabled
        syncBoosterUI(); saveState()
    end)
    bpTogRow.MouseEnter:Connect(function() tw(bpTogRow,{BackgroundColor3=T.BgCardHov},0.15) end)
    bpTogRow.MouseLeave:Connect(function() tw(bpTogRow,{BackgroundColor3=T.BgCard},0.15) end)

    local function makeInputRow(labelTxt, defaultTxt, yPos, onConfirm)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1,-30,0,44)
        row.Position = UDim2.new(0,15,0,yPos)
        row.BackgroundColor3 = T.BgCard
        row.Parent = boosterPanel
        corner(row, 8)
        local lbl = mkLabel(row, labelTxt, 12, T.LightGray)
        lbl.Size = UDim2.new(0.5,0,1,0)
        lbl.Position = UDim2.new(0,12,0,0)
        local box = Instance.new("TextBox")
        box.Size = UDim2.new(0,70,0,26)
        box.Position = UDim2.new(1,-82,0.5,-13)
        box.BackgroundColor3 = T.BtnBase
        box.Text = defaultTxt
        box.Font = Enum.Font.GothamBold
        box.TextSize = 12
        box.TextColor3 = T.White
        box.ClearTextOnFocus = false
        box.BorderSizePixel = 0
        box.Parent = row
        corner(box, 6)
        local boxStroke = Instance.new("UIStroke", box)
        boxStroke.Color = T.DarkGray; boxStroke.Thickness = 1.2
        box.FocusLost:Connect(function()
            local n = tonumber(box.Text)
            if n and n > 0 then
                onConfirm(n)
                tw(boxStroke, {Color=T.White}, 0.15)
                task.delay(0.4, function() tw(boxStroke, {Color=T.DarkGray}, 0.2) end)
            else box.Text = defaultTxt end
        end)
        row.MouseEnter:Connect(function() tw(row,{BackgroundColor3=T.BgCardHov},0.15) end)
        row.MouseLeave:Connect(function() tw(row,{BackgroundColor3=T.BgCard},0.15) end)
        return row, box
    end

    local _, speedBox = makeInputRow("Speed", tostring(boosterSpeedVal), 100, function(v)
        boosterSpeedVal = v; CFG.boosterSpeed = v; saveState()
    end)
    local _, jumpBox = makeInputRow("Jump Power", tostring(boosterJumpVal), 150, function(v)
        boosterJumpVal = v; CFG.boosterJump = v; saveState()
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.UseJumpPower = true; hum.JumpPower = v end
        end
    end)
    nyroxSpeedBox = speedBox; nyroxJumpBox = jumpBox
end

-- ══════════════════════════════════════════════════════════════
-- BRAINROT ESP
-- ══════════════════════════════════════════════════════════════
local brainrotESPEnabled = CFG.brainrotESP
local brainrotActive     = false
local brainrotFolder     = nil

local function stopBrainrotESP()
    brainrotActive = false
    if brainrotFolder then brainrotFolder:Destroy() brainrotFolder = nil end
end

local function beParse(text)
    text = tostring(text or ""):gsub("%s","")
    local num, suffix = text:match("([%d%.]+)([KkMmBbTt]?)")
    if not num then return 0 end
    local n = tonumber(num) or 0
    local mult = {K=1e3,M=1e6,B=1e9,T=1e12}
    return n * (mult[(suffix or ""):upper()] or 1)
end

local function startBrainrotESP()
    stopBrainrotESP()
    brainrotActive = true
    brainrotFolder = Instance.new("Folder")
    brainrotFolder.Name = "NyroxBrainrotESP"
    brainrotFolder.Parent = CoreGui
    task.spawn(function()
        while brainrotActive and brainrotESPEnabled do
            for _, b in ipairs(brainrotFolder:GetChildren()) do b:Destroy() end
            local best = {value=-1, part=nil, display="", text=""}
            local debris = workspace:FindFirstChild("Debris")
            if debris then
                for _, template in ipairs(debris:GetChildren()) do
                    if template.Name == "FastOverheadTemplate" then
                        local surfaceGui = template:FindFirstChildOfClass("SurfaceGui")
                        if surfaceGui then
                            local genLabel = surfaceGui:FindFirstChild("Generation", true)
                            if genLabel and genLabel:IsA("TextLabel") then
                                local txt = genLabel.Text or ""
                                if txt ~= "" and (txt:find("/s") or txt:find("K") or txt:find("M") or txt:find("B")) then
                                    local val = beParse(txt)
                                    if val > best.value then
                                        local targetPart = surfaceGui.Adornee
                                        if targetPart and targetPart:IsA("BasePart") then
                                            local displayName = surfaceGui:FindFirstChild("DisplayName", true)
                                            best = {value=val, part=targetPart, display=(displayName and displayName.Text ~= "") and displayName.Text or "Pet", text=txt}
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            if best.part and best.part.Parent then
                local char = LocalPlayer.Character
                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local dist = math.floor((hrp.Position - best.part.Position).Magnitude)
                    local bill = Instance.new("BillboardGui")
                    bill.Adornee = best.part; bill.Size = UDim2.new(0,240,0,66)
                    bill.AlwaysOnTop = true; bill.StudsOffset = Vector3.new(0,3,0)
                    bill.MaxDistance = 1000; bill.Parent = brainrotFolder
                    local bg = Instance.new("Frame", bill)
                    bg.Size = UDim2.new(1,0,1,0); bg.BackgroundColor3 = Color3.fromRGB(10,10,10)
                    bg.BackgroundTransparency = 0.12; bg.BorderSizePixel = 0
                    Instance.new("UICorner", bg).CornerRadius = UDim.new(0,8)
                    local accent = Instance.new("Frame", bg)
                    accent.Size = UDim2.new(0,4,1,0); accent.BackgroundColor3 = Color3.fromRGB(220,220,220)
                    accent.BorderSizePixel = 0; Instance.new("UICorner", accent).CornerRadius = UDim.new(0,4)
                    local nameLbl = Instance.new("TextLabel", bg)
                    nameLbl.Size = UDim2.new(1,-60,0,22); nameLbl.Position = UDim2.new(0,10,0,4)
                    nameLbl.BackgroundTransparency = 1; nameLbl.Text = best.display
                    nameLbl.Font = Enum.Font.GothamBlack; nameLbl.TextSize = 14
                    nameLbl.TextColor3 = T.White; nameLbl.TextXAlignment = Enum.TextXAlignment.Left
                    nameLbl.TextStrokeTransparency = 0.4; nameLbl.TextStrokeColor3 = Color3.fromRGB(0,0,0)
                    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
                    local valueLbl = Instance.new("TextLabel", bg)
                    valueLbl.Size = UDim2.new(0.65,0,0,20); valueLbl.Position = UDim2.new(0,10,0,28)
                    valueLbl.BackgroundTransparency = 1; valueLbl.Text = best.text
                    valueLbl.Font = Enum.Font.GothamBold; valueLbl.TextSize = 12
                    valueLbl.TextColor3 = Color3.fromRGB(185,185,185); valueLbl.TextXAlignment = Enum.TextXAlignment.Left
                    local distLbl = Instance.new("TextLabel", bg)
                    distLbl.Size = UDim2.new(0,50,1,0); distLbl.Position = UDim2.new(1,-54,0,0)
                    distLbl.BackgroundTransparency = 1; distLbl.Text = dist.."m"
                    distLbl.Font = Enum.Font.GothamBold; distLbl.TextSize = 13
                    distLbl.TextColor3 = Color3.fromRGB(170,170,170)
                    distLbl.TextXAlignment = Enum.TextXAlignment.Right; distLbl.TextYAlignment = Enum.TextYAlignment.Center
                end
            end
            task.wait(0.5)
        end
        if brainrotFolder then brainrotFolder:Destroy() brainrotFolder = nil end
    end)
end

-- ══════════════════════════════════════════════════════════════
-- PLAYER ESP
-- ══════════════════════════════════════════════════════════════
local playerESPEnabled = CFG.playerESP
local playerESPFolder  = nil
local playerESPConns   = {}
local playerESPEntries = {}

local function stopPlayerESP()
    for _, c in ipairs(playerESPConns) do pcall(function() c:Disconnect() end) end
    playerESPConns = {}
    for plr, entry in pairs(playerESPEntries) do
        for _, c in ipairs(entry.conns) do pcall(function() c:Disconnect() end) end
    end
    playerESPEntries = {}
    if playerESPFolder then playerESPFolder:Destroy() playerESPFolder = nil end
end

local function removePlayerESPEntry(plr)
    local entry = playerESPEntries[plr]
    if not entry then return end
    for _, c in ipairs(entry.conns) do pcall(function() c:Disconnect() end) end
    if entry.bill and entry.bill.Parent then entry.bill:Destroy() end
    if entry.highlight and entry.highlight.Parent then entry.highlight:Destroy() end
    playerESPEntries[plr] = nil
end

local function makePlayerBill(plr)
    if plr == LocalPlayer then return end
    if not playerESPFolder then return end
    if playerESPEntries[plr] then removePlayerESPEntry(plr) end
    local entry = {bill=nil, highlight=nil, conns={}}
    playerESPEntries[plr] = entry
    local bill = Instance.new("BillboardGui")
    bill.Name = "ESP_"..plr.Name; bill.Size = UDim2.new(0,180,0,30)
    bill.AlwaysOnTop = true; bill.ExtentsOffset = Vector3.new(0,3.4,0)
    bill.LightInfluence = 0; bill.Parent = playerESPFolder
    entry.bill = bill
    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(1,0,1,0); nameLbl.BackgroundTransparency = 1
    nameLbl.Text = plr.DisplayName; nameLbl.Font = Enum.Font.GothamBlack
    nameLbl.TextSize = 16; nameLbl.TextColor3 = Color3.fromRGB(255,255,255)
    nameLbl.TextXAlignment = Enum.TextXAlignment.Center; nameLbl.TextYAlignment = Enum.TextYAlignment.Center
    nameLbl.TextStrokeTransparency = 0; nameLbl.TextStrokeColor3 = Color3.fromRGB(0,0,0)
    nameLbl.Parent = bill
    local hl = Instance.new("Highlight")
    hl.Name = "ESP_HL_"..plr.Name; hl.FillColor = Color3.fromRGB(255,255,255)
    hl.FillTransparency = 0.88; hl.OutlineColor = Color3.fromRGB(255,255,255)
    hl.OutlineTransparency = 0; hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled = false; hl.Parent = playerESPFolder
    entry.highlight = hl
    local function bindChar(char)
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        if hrp then bill.Adornee = hrp; hl.Adornee = char; hl.Enabled = true end
    end
    if plr.Character then bindChar(plr.Character) end
    local cc = plr.CharacterAdded:Connect(bindChar)
    table.insert(entry.conns, cc)
    local cr = plr.CharacterRemoving:Connect(function() hl.Enabled = false; bill.Enabled = false end)
    table.insert(entry.conns, cr)
    local dc = RunService.Heartbeat:Connect(function()
        if not bill.Parent or not playerESPEnabled then return end
        local myChar = LocalPlayer.Character
        if myChar and myChar:FindFirstChild("HumanoidRootPart") and bill.Adornee and bill.Adornee.Parent then
            local d = math.floor((myChar.HumanoidRootPart.Position - bill.Adornee.Position).Magnitude)
            nameLbl.Text = plr.DisplayName.."  "..d.."m"
            local visible = d <= 500; bill.Enabled = visible; hl.Enabled = visible
        else bill.Enabled = false; hl.Enabled = false end
    end)
    table.insert(entry.conns, dc)
end

local function startPlayerESP()
    stopPlayerESP()
    playerESPFolder = Instance.new("Folder")
    playerESPFolder.Name = "NyroxPlayerESP"
    playerESPFolder.Parent = CoreGui
    for _, plr in ipairs(Players:GetPlayers()) do makePlayerBill(plr) end
    local pa = Players.PlayerAdded:Connect(function(plr)
        task.wait(1); if playerESPEnabled then makePlayerBill(plr) end
    end)
    table.insert(playerESPConns, pa)
    local pr = Players.PlayerRemoving:Connect(function(plr) removePlayerESPEntry(plr) end)
    table.insert(playerESPConns, pr)
end

-- ══════════════════════════════════════════════════════════════
-- AUTO KICK
-- ══════════════════════════════════════════════════════════════
local autoKickEnabled = CFG.autoKick

local function akHasKeyword(text)
    if typeof(text) ~= "string" then return false end
    return string.find(string.lower(text), "you stole") ~= nil
end

local function akDoKick() pcall(function() LocalPlayer:Kick("You stole brainrot!") end) end

local function akWatchGui(gui)
    gui.DescendantAdded:Connect(function(desc)
        if not autoKickEnabled then return end
        if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
            if akHasKeyword(desc.Text) then akDoKick() end
            desc:GetPropertyChangedSignal("Text"):Connect(function()
                if autoKickEnabled and akHasKeyword(desc.Text) then akDoKick() end
            end)
        end
    end)
end

local function akScanAll(parent)
    for _, obj in ipairs(parent:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            if akHasKeyword(obj.Text) then akDoKick() return end
            obj:GetPropertyChangedSignal("Text"):Connect(function()
                if autoKickEnabled and akHasKeyword(obj.Text) then akDoKick() end
            end)
        end
    end
end

local akStarted = false
local function startAutoKick()
    if akStarted then return end
    akStarted = true
    local pg = LocalPlayer:WaitForChild("PlayerGui", 10)
    if not pg then return end
    for _, gui in ipairs(pg:GetChildren()) do akWatchGui(gui) end
    pg.ChildAdded:Connect(function(gui)
        if autoKickEnabled then akWatchGui(gui); akScanAll(gui) end
    end)
    akScanAll(pg)
end

-- ══════════════════════════════════════════════════════════════
-- ANTI BEE
-- ══════════════════════════════════════════════════════════════
local antiBeeEnabled = CFG.antiBee
local antiBeeConn    = nil
local Lighting       = game:GetService("Lighting")
local FOV_LOCK       = 70

local abBlacklist = {"BlurEffect","ColorCorrectionEffect","BloomEffect","SunRaysEffect","DepthOfFieldEffect","Atmosphere","Sky","Smoke","ParticleEmitter","Beam","Trail","Highlight","PostEffect","SurfaceAppearance","Fire","Sparkles","Explosion","PointLight","SpotLight","SurfaceLight"}

local function abIsBlacklisted(obj)
    for _, name in ipairs(abBlacklist) do if obj:IsA(name) then return true end end
    return false
end

local function abClearEffects()
    for _, v in pairs(Lighting:GetDescendants()) do
        if abIsBlacklisted(v) then pcall(function() v:Destroy() end) end
    end
end

local abLightingConn = nil

local function startAntiBee()
    if antiBeeConn then return end
    abClearEffects()
    abLightingConn = Lighting.DescendantAdded:Connect(function(obj)
        if antiBeeEnabled then task.wait() if abIsBlacklisted(obj) then pcall(function() obj:Destroy() end) end end
    end)
    antiBeeConn = RunService.RenderStepped:Connect(function()
        if not antiBeeEnabled then return end
        local cam = workspace.CurrentCamera
        if cam and cam.FieldOfView ~= FOV_LOCK then cam.FieldOfView = FOV_LOCK end
    end)
end

local function stopAntiBee()
    if antiBeeConn then antiBeeConn:Disconnect() antiBeeConn = nil end
    if abLightingConn then abLightingConn:Disconnect() abLightingConn = nil end
end

-- ══════════════════════════════════════════════════════════════
-- TIMER ESP
-- ══════════════════════════════════════════════════════════════
local timerESPEnabled   = CFG.timerESP
local timerESPInstances = {}
local timerESPConn      = nil

local function teCreateBillboard(plot, mainPart)
    if timerESPInstances[plot.Name] then timerESPInstances[plot.Name]:Destroy() end
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "NyroxTimer_"..plot.Name; billboard.Size = UDim2.new(0,50,0,25)
    billboard.StudsOffset = Vector3.new(0,5,0); billboard.AlwaysOnTop = true
    billboard.Adornee = mainPart; billboard.MaxDistance = 1000; billboard.Parent = plot
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,0,1,0); label.BackgroundTransparency = 1
    label.TextScaled = true; label.Font = Enum.Font.GothamBold
    label.TextColor3 = Color3.fromRGB(220,220,220); label.TextStrokeTransparency = 0.3
    label.TextStrokeColor3 = Color3.new(0,0,0); label.Parent = billboard
    timerESPInstances[plot.Name] = billboard
    return billboard
end

local function teUpdateAll()
    local plotsFolder = workspace:FindFirstChild("Plots")
    if not plotsFolder then return end
    for _, plot in ipairs(plotsFolder:GetChildren()) do
        local purchases = plot:FindFirstChild("Purchases")
        local plotBlock = purchases and purchases:FindFirstChild("PlotBlock")
        local mainPart  = plotBlock and plotBlock:FindFirstChild("Main")
        local billboard = timerESPInstances[plot.Name]
        local timeLabel = mainPart and mainPart:FindFirstChild("BillboardGui") and mainPart.BillboardGui:FindFirstChild("RemainingTime")
        if timeLabel and mainPart then
            billboard = billboard or teCreateBillboard(plot, mainPart)
            local label = billboard:FindFirstChildWhichIsA("TextLabel")
            if label then label.Text = timeLabel.Text end
        elseif billboard then billboard:Destroy(); timerESPInstances[plot.Name] = nil end
    end
end

local function teDestroyAll()
    for _, bill in pairs(timerESPInstances) do pcall(function() bill:Destroy() end) end
    timerESPInstances = {}
end

local function startTimerESP()
    if timerESPConn then return end
    timerESPConn = RunService.RenderStepped:Connect(function()
        if not timerESPEnabled then return end; teUpdateAll()
    end)
end

local function stopTimerESP()
    if timerESPConn then timerESPConn:Disconnect() timerESPConn = nil end; teDestroyAll()
end

-- ══════════════════════════════════════════════════════════════
-- FRIENDS ESP
-- ══════════════════════════════════════════════════════════════
local friendsESPEnabled   = CFG.friendsESP
local friendsESPInstances = {}
local friendsESPConn      = nil

local function feGetMainPart(plot)
    local purchases = plot:FindFirstChild("Purchases")
    local plotBlock = purchases and purchases:FindFirstChild("PlotBlock")
    local main = plotBlock and plotBlock:FindFirstChild("Main")
    if main and main:IsA("BasePart") then return main end
    local sign = plot:FindFirstChild("PlotSign")
    if sign then for _, v in ipairs(sign:GetDescendants()) do if v:IsA("BasePart") then return v end end end
    for _, v in ipairs(plot:GetDescendants()) do if v:IsA("BasePart") and v.Anchored then return v end end
    return nil
end

local function feGetStatus(plot)
    for _, desc in ipairs(plot:GetDescendants()) do
        if desc:IsA("ProximityPrompt") then
            local t = desc.ObjectText:lower()
            if t:find("disallow friends") then return true
            elseif t:find("allow friends") then return false end
        end
        if desc:IsA("TextButton") or desc:IsA("TextLabel") then
            local t = desc.Text:lower()
            if t:find("disallow friends") then return true
            elseif t:find("allow friends") then return false end
        end
    end
    return nil
end

local function feApplyStatus(lbl, status)
    if status == true then lbl.Text = "✔ Allowed"; lbl.TextColor3 = Color3.fromRGB(120,220,120)
    elseif status == false then lbl.Text = "✘ Closed"; lbl.TextColor3 = Color3.fromRGB(220,100,100)
    else lbl.Text = "? Unknown"; lbl.TextColor3 = Color3.fromRGB(160,160,160) end
end

local function feCreateBillboard(plot, mainPart, status)
    if friendsESPInstances[plot.Name] then pcall(function() friendsESPInstances[plot.Name]:Destroy() end) end
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "NyroxFriendsESP_"..plot.Name; billboard.Size = UDim2.new(0,100,0,26)
    billboard.StudsOffset = Vector3.new(0,8,0); billboard.AlwaysOnTop = true
    billboard.Adornee = mainPart; billboard.MaxDistance = 1000; billboard.Parent = plot
    local bg = Instance.new("Frame", billboard)
    bg.Size = UDim2.new(1,0,1,0); bg.BackgroundColor3 = Color3.fromRGB(10,10,10)
    bg.BackgroundTransparency = 0.2; bg.BorderSizePixel = 0
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0,6)
    local lbl = Instance.new("TextLabel", bg)
    lbl.Name = "StatusLabel"; lbl.Size = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamBold
    lbl.TextScaled = true; lbl.TextStrokeTransparency = 0.4
    lbl.TextStrokeColor3 = Color3.fromRGB(0,0,0); feApplyStatus(lbl, status)
    friendsESPInstances[plot.Name] = billboard
    return billboard
end

local function feDestroyAll()
    for _, bill in pairs(friendsESPInstances) do pcall(function() bill:Destroy() end) end
    friendsESPInstances = {}
end

local function startFriendsESP()
    if friendsESPConn then return end
    friendsESPConn = RunService.RenderStepped:Connect(function()
        if not friendsESPEnabled then return end
        local plotsFolder = workspace:FindFirstChild("Plots")
        if not plotsFolder then return end
        for _, plot in ipairs(plotsFolder:GetChildren()) do
            local mainPart = feGetMainPart(plot)
            if not mainPart then continue end
            local status    = feGetStatus(plot)
            local billboard = friendsESPInstances[plot.Name]
            if not billboard or not billboard.Parent then
                feCreateBillboard(plot, mainPart, status)
            else
                local bg  = billboard:FindFirstChildOfClass("Frame")
                local lbl = bg and bg:FindFirstChild("StatusLabel")
                if lbl then feApplyStatus(lbl, status) end
            end
        end
    end)
end

local function stopFriendsESP()
    if friendsESPConn then friendsESPConn:Disconnect() friendsESPConn = nil end; feDestroyAll()
end

-- ══════════════════════════════════════════════════════════════
-- ANTI RAGDOLL
-- ══════════════════════════════════════════════════════════════
local antiRagdollEnabled = CFG.antiRagdoll
local antiRagdollConn = nil

local function startAntiRagdoll()
    if antiRagdollConn then return end
    antiRagdollConn = RunService.Heartbeat:Connect(function()
        if not antiRagdollEnabled then return end
        local char = LocalPlayer.Character
        if not char then return end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if humanoid then
            local st = humanoid:GetState()
            if st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown then
                humanoid:ChangeState(Enum.HumanoidStateType.Running)
                workspace.CurrentCamera.CameraSubject = humanoid
                pcall(function()
                    local PM = LocalPlayer.PlayerScripts:FindFirstChild("PlayerModule")
                    if PM then local C = require(PM:FindFirstChild("ControlModule")) if C then C:Enable() end end
                end)
                if root then root.Velocity = Vector3.new(0,0,0); root.RotVelocity = Vector3.new(0,0,0) end
            end
        end
        for _, obj in ipairs(char:GetDescendants()) do
            pcall(function() if obj:IsA("Motor6D") and obj.Enabled == false then obj.Enabled = true end end)
        end
    end)
end

local function stopAntiRagdoll()
    if antiRagdollConn then antiRagdollConn:Disconnect() antiRagdollConn = nil end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    if antiRagdollEnabled then stopAntiRagdoll(); startAntiRagdoll() end
end)

-- ══════════════════════════════════════════════════════════════
-- INF JUMP
-- ══════════════════════════════════════════════════════════════
local infJumpEnabled = CFG.infJumpEnabled
local infJumpForce   = 55
local ijPillRef, ijDotRef

local function syncInfJumpUI()
    CFG.infJumpEnabled = infJumpEnabled; saveState()
    if not ijPillRef or not ijPillRef.Parent then return end
    tw(ijPillRef, {BackgroundColor3 = infJumpEnabled and T.BtnActive or T.BtnBase}, 0.2)
    tw(ijDotRef,  {Position=UDim2.new(0, infJumpEnabled and 24 or 4, 0.5,-8), BackgroundColor3 = infJumpEnabled and T.BtnActTxt or T.MidGray}, 0.2)
end

UserInputService.JumpRequest:Connect(function()
    if not infJumpEnabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local vel = hrp.AssemblyLinearVelocity
    hrp.AssemblyLinearVelocity = Vector3.new(vel.X, infJumpForce, vel.Z)
end)

-- ══════════════════════════════════════════════════════════════
-- NAV BUTTON BUILDER
-- ══════════════════════════════════════════════════════════════
local activeBtn = nil
local navSetters = {}

local function makeNavBtn(parent, text, icon, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,0,36); btn.BackgroundColor3 = T.BtnBase
    btn.AutoButtonColor = false; btn.Text = ""; btn.LayoutOrder = order
    btn.Parent = parent; corner(btn, 8)
    local iconL = mkLabel(btn, icon or "◆", 14, T.MidGray, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
    iconL.Size = UDim2.new(0,28,1,0); iconL.Position = UDim2.new(0,6,0,0)
    local textL = mkLabel(btn, text, 12, T.MidGray, Enum.Font.GothamSemibold)
    textL.Size = UDim2.new(1,-40,1,0); textL.Position = UDim2.new(0,36,0,0)
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0,3,0.6,0); bar.Position = UDim2.new(0,0,0.2,0)
    bar.BackgroundColor3 = T.White; bar.BorderSizePixel = 0; bar.Visible = false
    bar.Parent = btn; corner(bar, 2)
    local function setActive(v)
        if v then
            btn.BackgroundColor3 = T.BgCard; iconL.TextColor3 = T.White
            textL.TextColor3 = T.White; textL.Font = Enum.Font.GothamBold; bar.Visible = true
        else
            btn.BackgroundColor3 = T.BtnBase; iconL.TextColor3 = T.MidGray
            textL.TextColor3 = T.MidGray; textL.Font = Enum.Font.GothamSemibold; bar.Visible = false
        end
    end
    btn.MouseEnter:Connect(function() if activeBtn ~= btn then tw(btn,{BackgroundColor3=T.BtnHover},0.15) end end)
    btn.MouseLeave:Connect(function() if activeBtn ~= btn then tw(btn,{BackgroundColor3=T.BtnBase},0.15) end end)
    return btn, setActive
end

local function switchNav(btn, setter, pageFn)
    if activeBtn then
        local prev = navSetters[activeBtn]
        if prev then prev(false) end
        tw(activeBtn,{BackgroundColor3=T.BtnBase},0.15)
    end
    activeBtn = btn; navSetters[btn] = setter; setter(true)
    tw(btn,{BackgroundColor3=T.BgCard},0.15)
    if pageFn then pageFn() end
end

-- ══════════════════════════════════════════════════════════════
-- SAYFALAR
-- ══════════════════════════════════════════════════════════════

local function showGeneral()
    clearContent()
    hubTitle.Text = "NYROX  ·  General"
    addSectionHeader("Panels", T.LightGray)
    addToggleRow("Auto Defense", defensePanel.Visible, function(v)
        defensePanel.Visible = v; CFG.defenseVisible = v; saveState()
    end)
    addToggleRow("Admin Panel", adminPanel.Visible, function(v)
        adminPanel.Visible = v; CFG.adminVisible = v; saveState()
    end)
    addToggleRow("Flash TP Panel", flashTPPanel.Visible, function(v)
        flashTPPanel.Visible = v; CFG.flashTPVisible = v; saveState()
    end)
end

local function showESP()
    clearContent()
    hubTitle.Text = "NYROX  ·  ESP"
    addSectionHeader("Brainrot ESP", T.LightGray)
    addToggleRow("Brainrot ESP (Best Pet)", CFG.brainrotESP, function(v)
        brainrotESPEnabled = v; CFG.brainrotESP = v
        if v then startBrainrotESP() else stopBrainrotESP() end; saveState()
    end)
    addSectionHeader("Player ESP", T.LightGray)
    addToggleRow("Player ESP (Name + Distance + Highlight)", CFG.playerESP, function(v)
        playerESPEnabled = v; CFG.playerESP = v
        if v then startPlayerESP() else stopPlayerESP() end; saveState()
    end)
    addSectionHeader("Timer ESP", T.LightGray)
    addToggleRow("Timer ESP (Base Süreleri)", CFG.timerESP, function(v)
        timerESPEnabled = v; CFG.timerESP = v
        if v then startTimerESP() else stopTimerESP() end; saveState()
    end)
    addSectionHeader("Friends ESP", T.LightGray)
    addToggleRow("Friends ESP (Allow/Disallow)", CFG.friendsESP, function(v)
        friendsESPEnabled = v; CFG.friendsESP = v
        if v then startFriendsESP() else stopFriendsESP() end; saveState()
    end)
end

local function showHelper()
    clearContent()
    hubTitle.Text = "NYROX  ·  Helper"
    addSectionHeader("Movement", T.LightGray)

    local bstRow = Instance.new("Frame")
    bstRow.Size = UDim2.new(1,0,0,44); bstRow.BackgroundColor3 = T.BgCard
    bstRow.Parent = scroll; corner(bstRow, 8)
    local bstLbl = mkLabel(bstRow, "Booster Panel", 12, T.LightGray)
    bstLbl.Size = UDim2.new(0.7,0,1,0); bstLbl.Position = UDim2.new(0,12,0,0)
    local bstPill = Instance.new("Frame")
    bstPill.Size = UDim2.new(0,44,0,22); bstPill.Position = UDim2.new(1,-54,0.5,-11)
    bstPill.BackgroundColor3 = boosterPanel.Visible and T.BtnActive or T.BtnBase; bstPill.Parent = bstRow; corner(bstPill, 11)
    local bstDot = Instance.new("Frame")
    bstDot.Size = UDim2.new(0,16,0,16); bstDot.Position = UDim2.new(0, boosterPanel.Visible and 24 or 4, 0.5,-8)
    bstDot.BackgroundColor3 = boosterPanel.Visible and T.BtnActTxt or T.MidGray; bstDot.Parent = bstPill; corner(bstDot, 8)
    local bstBtn = Instance.new("TextButton"); bstBtn.Size = UDim2.new(1,0,1,0)
    bstBtn.BackgroundTransparency = 1; bstBtn.Text = ""; bstBtn.Parent = bstRow
    bstBtn.MouseButton1Click:Connect(function()
        boosterPanel.Visible = not boosterPanel.Visible
        local v = boosterPanel.Visible
        tw(bstPill, {BackgroundColor3 = v and T.BtnActive or T.BtnBase}, 0.2)
        tw(bstDot, {Position=UDim2.new(0, v and 24 or 4, 0.5,-8), BackgroundColor3 = v and T.BtnActTxt or T.MidGray}, 0.2)
    end)
    bstRow.MouseEnter:Connect(function() tw(bstRow,{BackgroundColor3=T.BgCardHov},0.15) end)
    bstRow.MouseLeave:Connect(function() tw(bstRow,{BackgroundColor3=T.BgCard},0.15) end)

    local ijRow = Instance.new("Frame"); ijRow.Size = UDim2.new(1,0,0,44)
    ijRow.BackgroundColor3 = T.BgCard; ijRow.Parent = scroll; corner(ijRow, 8)
    local ijLbl = mkLabel(ijRow, "Infinite Jump", 12, T.LightGray)
    ijLbl.Size = UDim2.new(0.7,0,1,0); ijLbl.Position = UDim2.new(0,12,0,0)
    local ijPill = Instance.new("Frame"); ijPill.Size = UDim2.new(0,44,0,22)
    ijPill.Position = UDim2.new(1,-54,0.5,-11); ijPill.BackgroundColor3 = infJumpEnabled and T.BtnActive or T.BtnBase
    ijPill.Parent = ijRow; corner(ijPill, 11)
    local ijDot = Instance.new("Frame"); ijDot.Size = UDim2.new(0,16,0,16)
    ijDot.Position = UDim2.new(0, infJumpEnabled and 24 or 4, 0.5,-8)
    ijDot.BackgroundColor3 = infJumpEnabled and T.BtnActTxt or T.MidGray; ijDot.Parent = ijPill; corner(ijDot, 8)
    ijPillRef = ijPill; ijDotRef = ijDot
    local ijBtn = Instance.new("TextButton"); ijBtn.Size = UDim2.new(1,0,1,0)
    ijBtn.BackgroundTransparency = 1; ijBtn.Text = ""; ijBtn.Parent = ijRow
    ijBtn.MouseButton1Click:Connect(function() infJumpEnabled = not infJumpEnabled; syncInfJumpUI(); saveState() end)
    ijRow.MouseEnter:Connect(function() tw(ijRow,{BackgroundColor3=T.BgCardHov},0.15) end)
    ijRow.MouseLeave:Connect(function() tw(ijRow,{BackgroundColor3=T.BgCard},0.15) end)

    addSectionHeader("Combat", T.LightGray)
    addToggleRow("Anti Ragdoll", antiRagdollEnabled, function(v)
        antiRagdollEnabled = v; CFG.antiRagdoll = v
        if v then startAntiRagdoll() else stopAntiRagdoll() end; saveState()
    end)
    addToggleRow("Auto Grab", autoGrabEnabled, function(v)
        autoGrabEnabled = v; CFG.autoGrab = v
        if v then agStart() else agStop() end; saveState()
    end)

    local agRadiusRow = Instance.new("Frame"); agRadiusRow.Size = UDim2.new(1,0,0,44)
    agRadiusRow.BackgroundColor3 = T.BgCard; agRadiusRow.Parent = scroll; corner(agRadiusRow, 8)
    local agRadLbl = mkLabel(agRadiusRow, "Grab Radius", 12, T.LightGray)
    agRadLbl.Size = UDim2.new(0.45,0,1,0); agRadLbl.Position = UDim2.new(0,12,0,0)
    local agMinus = Instance.new("TextButton"); agMinus.Size = UDim2.new(0,28,0,28)
    agMinus.Position = UDim2.new(1,-130,0.5,-14); agMinus.BackgroundColor3 = T.BtnBase
    agMinus.Text = "-"; agMinus.Font = Enum.Font.GothamBold; agMinus.TextSize = 16
    agMinus.TextColor3 = T.White; agMinus.AutoButtonColor = false; agMinus.BorderSizePixel = 0
    agMinus.Parent = agRadiusRow; corner(agMinus, 6)
    local agRadBox = Instance.new("TextBox"); agRadBox.Size = UDim2.new(0,54,0,28)
    agRadBox.Position = UDim2.new(1,-98,0.5,-14); agRadBox.BackgroundColor3 = T.BtnBase
    agRadBox.Text = tostring(autoGrabRadius); agRadBox.Font = Enum.Font.GothamBold
    agRadBox.TextSize = 12; agRadBox.TextColor3 = T.White; agRadBox.ClearTextOnFocus = false
    agRadBox.TextXAlignment = Enum.TextXAlignment.Center; agRadBox.BorderSizePixel = 0
    agRadBox.Parent = agRadiusRow; corner(agRadBox, 6); Instance.new("UIStroke", agRadBox).Color = T.DarkGray
    local agPlus = Instance.new("TextButton"); agPlus.Size = UDim2.new(0,28,0,28)
    agPlus.Position = UDim2.new(1,-40,0.5,-14); agPlus.BackgroundColor3 = T.BtnBase
    agPlus.Text = "+"; agPlus.Font = Enum.Font.GothamBold; agPlus.TextSize = 16
    agPlus.TextColor3 = T.White; agPlus.AutoButtonColor = false; agPlus.BorderSizePixel = 0
    agPlus.Parent = agRadiusRow; corner(agPlus, 6)
    agMinus.MouseButton1Click:Connect(function()
        autoGrabRadius = math.max(5, autoGrabRadius-1); agRadBox.Text = tostring(autoGrabRadius)
        CFG.grabRadius = autoGrabRadius; saveState()
    end)
    agPlus.MouseButton1Click:Connect(function()
        autoGrabRadius = math.min(200, autoGrabRadius+1); agRadBox.Text = tostring(autoGrabRadius)
        CFG.grabRadius = autoGrabRadius; saveState()
    end)
    agRadBox.FocusLost:Connect(function()
        local n = tonumber(agRadBox.Text)
        if n then autoGrabRadius = math.clamp(math.floor(n), 5, 200) end
        agRadBox.Text = tostring(autoGrabRadius); CFG.grabRadius = autoGrabRadius; saveState()
    end)
    for _, btn in ipairs({agMinus, agPlus}) do
        btn.MouseEnter:Connect(function() tw(btn,{BackgroundColor3=T.BtnHover},0.15) end)
        btn.MouseLeave:Connect(function() tw(btn,{BackgroundColor3=T.BtnBase},0.15) end)
    end
    agRadiusRow.MouseEnter:Connect(function() tw(agRadiusRow,{BackgroundColor3=T.BgCardHov},0.15) end)
    agRadiusRow.MouseLeave:Connect(function() tw(agRadiusRow,{BackgroundColor3=T.BgCard},0.15) end)

    addSectionHeader("Utilities", T.LightGray)
    addToggleRow("Optimizer", optimizerEnabled, function(v)
        optimizerEnabled = v; CFG.optimizer = v
        if v then enableOptimizer() else disableOptimizer() end; saveState()
    end)
    addToggleRow("XRay", xrayEnabled, function(v)
        xrayEnabled = v; CFG.xray = v
        if v then pcall(xrayStart) else pcall(xrayStop) end; saveState()
    end)
    addToggleRow("Auto Destroy Turret", autoTurretEnabled, function(v)
        autoTurretEnabled = v; CFG.autoTurret = v
        if v then enableAutoTurret() else disableAutoTurret() end; saveState()
    end)

    addSectionHeader("Misc", T.LightGray)
    addToggleRow("Auto Kick (Steal)", autoKickEnabled, function(v)
        autoKickEnabled = v; CFG.autoKick = v; if v then startAutoKick() end; saveState()
    end)
    addToggleRow("Anti Bee", antiBeeEnabled, function(v)
        antiBeeEnabled = v; CFG.antiBee = v
        if v then startAntiBee() else stopAntiBee() end; saveState()
    end)
    addButtonRow("Rejoin", "REJOIN", function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
    end)
end

local function showFlashTP()
    clearContent()
    hubTitle.Text = "NYROX  ·  Flash TP"
    addSectionHeader("Flash Teleport", T.LightGray)
    local fpRow = Instance.new("Frame"); fpRow.Size = UDim2.new(1,0,0,44)
    fpRow.BackgroundColor3 = T.BgCard; fpRow.Parent = scroll; corner(fpRow, 8)
    local fpLbl = mkLabel(fpRow, "Flash TP Panel", 12, T.LightGray)
    fpLbl.Size = UDim2.new(0.7,0,1,0); fpLbl.Position = UDim2.new(0,12,0,0)
    local fpPill = Instance.new("Frame"); fpPill.Size = UDim2.new(0,44,0,22)
    fpPill.Position = UDim2.new(1,-54,0.5,-11)
    fpPill.BackgroundColor3 = flashTPPanel.Visible and T.BtnActive or T.BtnBase
    fpPill.Parent = fpRow; corner(fpPill, 11)
    local fpDot = Instance.new("Frame"); fpDot.Size = UDim2.new(0,16,0,16)
    fpDot.Position = UDim2.new(0, flashTPPanel.Visible and 24 or 4, 0.5,-8)
    fpDot.BackgroundColor3 = flashTPPanel.Visible and T.BtnActTxt or T.MidGray
    fpDot.Parent = fpPill; corner(fpDot, 8)
    local fpBtn = Instance.new("TextButton"); fpBtn.Size = UDim2.new(1,0,1,0)
    fpBtn.BackgroundTransparency = 1; fpBtn.Text = ""; fpBtn.Parent = fpRow
    fpBtn.MouseButton1Click:Connect(function()
        flashTPPanel.Visible = not flashTPPanel.Visible
        local v = flashTPPanel.Visible
        tw(fpPill, {BackgroundColor3 = v and T.BtnActive or T.BtnBase}, 0.2)
        tw(fpDot,  {Position=UDim2.new(0, v and 24 or 4, 0.5,-8), BackgroundColor3 = v and T.BtnActTxt or T.MidGray}, 0.2)
        CFG.flashTPVisible = v; saveState()
    end)
    fpRow.MouseEnter:Connect(function() tw(fpRow,{BackgroundColor3=T.BgCardHov},0.15) end)
    fpRow.MouseLeave:Connect(function() tw(fpRow,{BackgroundColor3=T.BgCard},0.15) end)
end

-- ══════════════════════════════════════════════════════════════
-- HALF TP SAYFASI — Semi TP entegre
-- ══════════════════════════════════════════════════════════════
local function showHalfTP()
    clearContent()
    hubTitle.Text = "NYROX  ·  Half TP"

    addSectionHeader("Panels", T.LightGray)

    -- Semi TP Panel toggle
    local spRow = Instance.new("Frame")
    spRow.Size = UDim2.new(1,0,0,44)
    spRow.BackgroundColor3 = T.BgCard
    spRow.Parent = scroll
    corner(spRow, 8)
    local spLbl = mkLabel(spRow, "Half TP Panel", 12, T.LightGray)
    spLbl.Size = UDim2.new(0.7,0,1,0); spLbl.Position = UDim2.new(0,12,0,0)
    local spPill = Instance.new("Frame")
    spPill.Size = UDim2.new(0,44,0,22); spPill.Position = UDim2.new(1,-54,0.5,-11)
    spPill.BackgroundColor3 = semiTPPanel.Visible and T.BtnActive or T.BtnBase
    spPill.Parent = spRow; corner(spPill, 11)
    local spDot = Instance.new("Frame")
    spDot.Size = UDim2.new(0,16,0,16)
    spDot.Position = UDim2.new(0, semiTPPanel.Visible and 24 or 4, 0.5,-8)
    spDot.BackgroundColor3 = semiTPPanel.Visible and T.BtnActTxt or T.MidGray
    spDot.Parent = spPill; corner(spDot, 8)
    local spBtn = Instance.new("TextButton")
    spBtn.Size = UDim2.new(1,0,1,0); spBtn.BackgroundTransparency = 1
    spBtn.Text = ""; spBtn.Parent = spRow
    spBtn.MouseButton1Click:Connect(function()
        semiTPPanel.Visible = not semiTPPanel.Visible
        local v = semiTPPanel.Visible
        tw(spPill, {BackgroundColor3 = v and T.BtnActive or T.BtnBase}, 0.2)
        tw(spDot,  {Position=UDim2.new(0, v and 24 or 4, 0.5,-8), BackgroundColor3 = v and T.BtnActTxt or T.MidGray}, 0.2)
        saveState()
    end)
    spRow.MouseEnter:Connect(function() tw(spRow,{BackgroundColor3=T.BgCardHov},0.15) end)
    spRow.MouseLeave:Connect(function() tw(spRow,{BackgroundColor3=T.BgCard},0.15) end)

    addSectionHeader("Teleport System", T.LightGray)

    -- Teleport System toggle
    addToggleRow("Teleport System", semiTPEnabled, function(v)
        semiTPEnabled = v
        CFG.semiTPEnabled = v
        if v then
            -- Marker oluştur
            if not semiMarker or not semiMarker.Parent then
                semiMarker = createSemiMarker()
            end
        else
            -- Marker'ı kaldır, auto grab durdur
            semiAgStop()
            if semiMarker and semiMarker.Parent then
                pcall(function() semiMarker:Destroy() end)
                semiMarker = nil
            end
        end
        saveState()
    end)

    addSectionHeader("Desync", T.LightGray)

    -- Activate To Work (Desync) toggle
    local desyncRow = Instance.new("Frame")
    desyncRow.Size = UDim2.new(1,0,0,44)
    desyncRow.BackgroundColor3 = T.BgCard
    desyncRow.Parent = scroll
    corner(desyncRow, 8)

    local desyncLbl = mkLabel(desyncRow, "Activate To Work", 12, T.LightGray)
    desyncLbl.Size = UDim2.new(0.7,0,1,0)
    desyncLbl.Position = UDim2.new(0,12,0,0)

    local dPill = Instance.new("Frame")
    dPill.Size = UDim2.new(0,44,0,22)
    dPill.Position = UDim2.new(1,-54,0.5,-11)
    dPill.BackgroundColor3 = desyncPermanentlyActivated and T.BtnActive or T.BtnBase
    dPill.Parent = desyncRow
    corner(dPill, 11)

    local dDot = Instance.new("Frame")
    dDot.Size = UDim2.new(0,16,0,16)
    dDot.Position = UDim2.new(0, desyncPermanentlyActivated and 24 or 4, 0.5,-8)
    dDot.BackgroundColor3 = desyncPermanentlyActivated and T.BtnActTxt or T.MidGray
    dDot.Parent = dPill
    corner(dDot, 8)

    local dBtn = Instance.new("TextButton")
    dBtn.Size = UDim2.new(1,0,1,0)
    dBtn.BackgroundTransparency = 1
    dBtn.Text = ""
    dBtn.Parent = desyncRow

    desyncRow.MouseEnter:Connect(function() tw(desyncRow,{BackgroundColor3=T.BgCardHov},0.15) end)
    desyncRow.MouseLeave:Connect(function() tw(desyncRow,{BackgroundColor3=T.BgCard},0.15) end)

    dBtn.MouseButton1Click:Connect(function()
        if desyncPermanentlyActivated then return end
        dBtn.Active = false
        task.spawn(function()
            desyncLbl.Text = "Preparing..."
            if desyncFirstActivation then
                semiRespawn(LocalPlayer)
                desyncFirstActivation = false
                applyPermanentDesync()
            end
            task.wait(1.5)
            desyncLbl.Text = "Almost done..."
            task.wait(2)
            desyncLbl.Text = "Done! ✓"
            desyncPermanentlyActivated = true
            tw(dPill, {BackgroundColor3 = T.BtnActive}, 0.2)
            tw(dDot,  {Position = UDim2.new(0, 24, 0.5,-8), BackgroundColor3 = T.BtnActTxt}, 0.2)
            task.wait(1)
            desyncLbl.Text = "Desync Active"
        end)
    end)

    addSectionHeader("Half Teleport  [G]", T.LightGray)

    -- G tuşu bilgi satırı
    local infoRow = Instance.new("Frame")
    infoRow.Size = UDim2.new(1,0,0,44)
    infoRow.BackgroundColor3 = T.BgCard
    infoRow.Parent = scroll
    corner(infoRow, 8)

    local infoLbl = mkLabel(infoRow, "Teleport to other base", 12, T.LightGray)
    infoLbl.Size = UDim2.new(0.6,0,1,0)
    infoLbl.Position = UDim2.new(0,12,0,0)

    local keyLbl = mkLabel(infoRow, "[G]", 12, T.MidGray, Enum.Font.GothamBold, Enum.TextXAlignment.Right)
    keyLbl.Size = UDim2.new(0.15,0,1,0)
    keyLbl.Position = UDim2.new(0.6,0,0,0)

    local tpBtn = Instance.new("TextButton")
    tpBtn.Size = UDim2.new(0,80,0,28)
    tpBtn.Position = UDim2.new(1,-90,0.5,-14)
    tpBtn.BackgroundColor3 = T.BtnBase
    tpBtn.Text = "TELEPORT"
    tpBtn.Font = Enum.Font.GothamBold
    tpBtn.TextSize = 10
    tpBtn.TextColor3 = T.White
    tpBtn.AutoButtonColor = false
    tpBtn.Parent = infoRow
    corner(tpBtn, 6)
    tpBtn.MouseButton1Click:Connect(function()
        tw(tpBtn,{BackgroundTransparency=0.5},0.1) task.wait(0.1) tw(tpBtn,{BackgroundTransparency=0},0.1)
        executeSemiTP()
    end)
    tpBtn.MouseEnter:Connect(function() tw(tpBtn,{BackgroundColor3=T.BtnHover},0.15) end)
    tpBtn.MouseLeave:Connect(function() tw(tpBtn,{BackgroundColor3=T.BtnBase},0.15) end)
    infoRow.MouseEnter:Connect(function() tw(infoRow,{BackgroundColor3=T.BgCardHov},0.15) end)
    infoRow.MouseLeave:Connect(function() tw(infoRow,{BackgroundColor3=T.BgCard},0.15) end)
end

-- ══════════════════════════════════════════════════════════════
-- INVIS CLONE
-- ══════════════════════════════════════════════════════════════
local invisCloneRunning = false

local function runInvisClone()
    if invisCloneRunning then return end
    local char = LocalPlayer.Character
    local bp   = LocalPlayer:FindFirstChild("Backpack")
    if not char or not bp then return end
    local hum    = char:FindFirstChildOfClass("Humanoid")
    local cloak  = bp:FindFirstChild("Invisibility Cloak") or char:FindFirstChild("Invisibility Cloak")
    local cloner = bp:FindFirstChild("Quantum Cloner")     or char:FindFirstChild("Quantum Cloner")
    if not hum or not cloak or not cloner then return end
    invisCloneRunning = true
    task.spawn(function()
        hum:UnequipTools(); task.wait(0.05)
        hum:EquipTool(cloak); task.wait(0.05)
        cloak:Activate(); task.wait(1)
        hum:EquipTool(cloner)
        task.spawn(function() cloner:Activate() end); task.wait(0.1)
        task.spawn(function() cloner:Activate() end); task.wait(0.1)
        task.spawn(function() cloner:Activate() end); task.wait(0.1)
        task.wait(1.5)
        invisCloneRunning = false
    end)
end

-- ══════════════════════════════════════════════════════════════
-- KEYBIND SYSTEM
-- ══════════════════════════════════════════════════════════════
local keybindDefs = {
    {id="toggleHub",        label="Toggle Hub"},
    {id="toggleDefense",    label="Auto Defense"},
    {id="toggleAdmin",      label="Admin Panel"},
    {id="toggleBooster",    label="Booster (toggle)"},
    {id="toggleInfJump",    label="Infinite Jump"},
    {id="toggleESP",        label="Player ESP"},
    {id="toggleBrainrot",   label="Brainrot ESP"},
    {id="toggleAutoFlash",  label="Auto Flash (toggle)"},
    {id="toggleFlashPanel", label="Flash TP Panel"},
    {id="invisClone",       label="Invis Clone"},
    {id="ragdollSelf",      label="Ragdoll Self"},
    {id="rejoin",           label="Rejoin Server"},
    {id="semiTP",           label="Half TP (Semi)"},
}

local keybindActions = {
    toggleHub       = function() window.Visible = not window.Visible end,
    toggleDefense   = function() defensePanel.Visible = not defensePanel.Visible; saveState() end,
    toggleAdmin     = function() adminPanel.Visible = not adminPanel.Visible; saveState() end,
    toggleBooster   = function() boosterEnabled = not boosterEnabled; syncBoosterUI() end,
    toggleInfJump   = function() infJumpEnabled = not infJumpEnabled; syncInfJumpUI() end,
    toggleESP       = function()
        playerESPEnabled = not playerESPEnabled
        if playerESPEnabled then startPlayerESP() else stopPlayerESP() end
    end,
    toggleBrainrot  = function()
        brainrotESPEnabled = not brainrotESPEnabled
        if brainrotESPEnabled then startBrainrotESP() else stopBrainrotESP() end
    end,
    toggleAutoFlash = function() flashTPEnabled = not flashTPEnabled; syncFlashTPUI() end,
    toggleFlashPanel = function()
        flashTPPanel.Visible = not flashTPPanel.Visible
        CFG.flashTPVisible = flashTPPanel.Visible; saveState()
    end,
    invisClone      = function() runInvisClone() end,
    ragdollSelf     = function() execCmd(LocalPlayer, "ragdoll") end,
    rejoin          = function() game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer) end,
    semiTP          = function() executeSemiTP() end,
}

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    local key = input.KeyCode.Name
    -- G tuşu zaten doğrudan bağlı, keybind sisteminden de çalışsın
    for id, _ in pairs(keybindActions) do
        local bound = CFG["kb_"..id]
        if bound and bound == key then
            local action = keybindActions[id]
            if action then pcall(action) end
        end
    end
end)

-- ══════════════════════════════════════════════════════════════
-- SETTINGS PAGE
-- ══════════════════════════════════════════════════════════════
local bindingTarget = nil

local function showSettings()
    clearContent()
    hubTitle.Text = "NYROX  ·  Settings"
    addSectionHeader("Hub", T.LightGray)
    addToggleRow("Cooldown Panel", cdPanel.Visible, function(v)
        cdPanel.Visible = v; CFG.cdVisible = v; saveState()
    end)
    addSectionHeader("Keybinds", T.LightGray)

    for _, def in ipairs(keybindDefs) do
        local row = Instance.new("Frame"); row.Size = UDim2.new(1,0,0,44)
        row.BackgroundColor3 = T.BgCard; row.Parent = scroll; corner(row, 8)
        local lbl = mkLabel(row, def.label, 12, T.LightGray)
        lbl.Size = UDim2.new(0.6,0,1,0); lbl.Position = UDim2.new(0,12,0,0)
        local keyBtn = Instance.new("TextButton"); keyBtn.Size = UDim2.new(0,80,0,28)
        keyBtn.Position = UDim2.new(1,-90,0.5,-14); keyBtn.BackgroundColor3 = T.BtnBase
        keyBtn.Text = CFG["kb_"..def.id] or "None"; keyBtn.Font = Enum.Font.GothamBold
        keyBtn.TextSize = 11; keyBtn.TextColor3 = T.White; keyBtn.AutoButtonColor = false
        keyBtn.Parent = row; corner(keyBtn, 6)
        local id = def.id
        keyBtn.MouseButton1Click:Connect(function()
            bindingTarget = id; keyBtn.Text = "..."; keyBtn.TextColor3 = T.Gold
            tw(keyBtn, {BackgroundColor3 = T.DarkGray}, 0.15)
            local conn
            conn = UserInputService.InputBegan:Connect(function(input, gpe)
                if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
                conn:Disconnect(); bindingTarget = nil
                local keyName = input.KeyCode.Name
                if keyName == "Escape" then CFG["kb_"..id] = "None"; keyBtn.Text = "None"
                else CFG["kb_"..id] = keyName; keyBtn.Text = keyName end
                keyBtn.TextColor3 = T.White; tw(keyBtn, {BackgroundColor3 = T.BtnBase}, 0.15); saveState()
            end)
        end)
        keyBtn.MouseEnter:Connect(function() tw(keyBtn,{BackgroundColor3=T.BtnHover},0.15) end)
        keyBtn.MouseLeave:Connect(function() tw(keyBtn,{BackgroundColor3=T.BtnBase},0.15) end)
        row.MouseEnter:Connect(function() tw(row,{BackgroundColor3=T.BgCardHov},0.15) end)
        row.MouseLeave:Connect(function() tw(row,{BackgroundColor3=T.BgCard},0.15) end)
    end
end

-- ══════════════════════════════════════════════════════════════
-- CREDITS
-- ══════════════════════════════════════════════════════════════
local function showCredits()
    clearContent()
    hubTitle.Text = "NYROX  ·  Credits"
    local titleRow = Instance.new("Frame"); titleRow.Size = UDim2.new(1,0,0,60)
    titleRow.BackgroundTransparency = 1; titleRow.Parent = scroll
    local titleLbl = mkLabel(titleRow, "NYROX Hub v2.1", 26, T.White, Enum.Font.GothamBlack, Enum.TextXAlignment.Center)
    titleLbl.Size = UDim2.new(1,0,1,0); wGrad(titleLbl)

    local creatorBox = Instance.new("Frame"); creatorBox.Size = UDim2.new(1,0,0,64)
    creatorBox.BackgroundColor3 = T.BgCard; creatorBox.Parent = scroll; corner(creatorBox, 10); addBWStroke(creatorBox, 1.5)
    local creatorTop = mkLabel(creatorBox, "Created by", 11, T.MidGray, Enum.Font.Gotham, Enum.TextXAlignment.Center)
    creatorTop.Size = UDim2.new(1,0,0,26); creatorTop.Position = UDim2.new(0,0,0,6)
    local creatorName = mkLabel(creatorBox, "Memedika  (@Memedika_)", 14, T.White, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
    creatorName.Size = UDim2.new(1,0,0,26); creatorName.Position = UDim2.new(0,0,0,32); wGrad(creatorName)

    local discordBox = Instance.new("Frame"); discordBox.Size = UDim2.new(1,0,0,64)
    discordBox.BackgroundColor3 = T.BgCard; discordBox.Parent = scroll; corner(discordBox, 10); addBWStroke(discordBox, 1.5)
    local discordTop = mkLabel(discordBox, "Discord Server", 11, T.MidGray, Enum.Font.Gotham, Enum.TextXAlignment.Center)
    discordTop.Size = UDim2.new(1,0,0,26); discordTop.Position = UDim2.new(0,0,0,6)
    local discordLink = mkLabel(discordBox, "discord.gg/HCntzDTWJV", 14, T.White, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
    discordLink.Size = UDim2.new(1,0,0,26); discordLink.Position = UDim2.new(0,0,0,32)

    local thanksBox = Instance.new("Frame"); thanksBox.Size = UDim2.new(1,0,0,80)
    thanksBox.BackgroundColor3 = T.BgCard; thanksBox.Parent = scroll; corner(thanksBox, 10); addBWStroke(thanksBox, 1.5)
    local thanksTitl = mkLabel(thanksBox, "Special Thanks", 13, T.White, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
    thanksTitl.Size = UDim2.new(1,0,0,28); thanksTitl.Position = UDim2.new(0,0,0,8)
    local thanksMsg = mkLabel(thanksBox, "Thanks to everyone using the script!\nYour support means a lot :)", 11, T.MidGray, Enum.Font.Gotham, Enum.TextXAlignment.Center)
    thanksMsg.Size = UDim2.new(1,-20,0,38); thanksMsg.Position = UDim2.new(0,10,0,36)
    thanksMsg.TextWrapped = true; thanksMsg.TextYAlignment = Enum.TextYAlignment.Top

    local resetBtn = Instance.new("TextButton"); resetBtn.Size = UDim2.new(1,0,0,44)
    resetBtn.BackgroundColor3 = T.BtnBase; resetBtn.Text = "Reset All Settings"
    resetBtn.Font = Enum.Font.GothamBold; resetBtn.TextSize = 13; resetBtn.TextColor3 = T.White
    resetBtn.AutoButtonColor = false; resetBtn.Parent = scroll; corner(resetBtn, 10); addBWStroke(resetBtn, 1.5)
    resetBtn.MouseButton1Click:Connect(function()
        CFG.kb_toggleHub="U"; CFG.kb_toggleDefense="None"; CFG.kb_toggleAdmin="None"
        CFG.kb_toggleBooster="None"; CFG.kb_toggleInfJump="None"
        CFG.kb_toggleESP="None"; CFG.kb_toggleBrainrot="None"
        CFG.kb_toggleAutoFlash="None"; CFG.kb_toggleFlashPanel="None"
        CFG.kb_invisClone="None"; CFG.kb_ragdollSelf="None"; CFG.kb_rejoin="None"
        CFG.kb_semiTP="G"
        CFG.defenseVisible=false; CFG.adminVisible=false; CFG.flashTPVisible=false; CFG.cdVisible=true
        saveState()
        defensePanel.Visible=false; adminPanel.Visible=false; flashTPPanel.Visible=false; cdPanel.Visible=true
        showCredits()
    end)
    resetBtn.MouseEnter:Connect(function() tw(resetBtn,{BackgroundColor3=T.BtnHover},0.15) end)
    resetBtn.MouseLeave:Connect(function() tw(resetBtn,{BackgroundColor3=T.BtnBase},0.15) end)
end

-- ══════════════════════════════════════════════════════════════
-- NAV BUTTONS
-- ══════════════════════════════════════════════════════════════
local navDefs = {
    {text="General",  icon="⊞", order=1, fn=showGeneral},
    {text="ESP",      icon="◈", order=2, fn=showESP},
    {text="Helper",   icon="✦", order=3, fn=showHelper},
    {text="Flash TP", icon="⚡", order=4, fn=showFlashTP},
    {text="Half TP",  icon="◑", order=5, fn=showHalfTP},
}
local bottomDefs = {
    {text="Settings", icon="⚙", order=1, fn=showSettings},
    {text="Credits",  icon="♡", order=2, fn=showCredits},
}

for _, def in ipairs(navDefs) do
    local btn, setter = makeNavBtn(navHolder, def.text, def.icon, def.order)
    local fn = def.fn
    btn.MouseButton1Click:Connect(function() switchNav(btn, setter, fn) end)
    if def.order == 1 then task.defer(function() switchNav(btn, setter, fn) end) end
end

for _, def in ipairs(bottomDefs) do
    local btn, setter = makeNavBtn(bottomHolder, def.text, def.icon, def.order)
    local fn = def.fn
    btn.MouseButton1Click:Connect(function() switchNav(btn, setter, fn) end)
end

-- ══════════════════════════════════════════════════════════════
-- FPS COUNTER
-- ══════════════════════════════════════════════════════════════
local lastT = tick()
local frames = 0
RunService.RenderStepped:Connect(function()
    frames += 1
    local now = tick()
    if now - lastT >= 1 then
        local ms = math.round((now-lastT-1)*1000 + (1000/math.max(frames,1)))
        fpsLbl.Text = "FPS: "..frames.." | "..ms.."ms"
        frames = 0; lastT = now
    end
end)

-- B&W ROTATING STROKE
RunService.RenderStepped:Connect(function()
    for _, g in ipairs(strokeGrads) do g.Rotation = (g.Rotation+3)%360 end
end)

-- DOUBLE CLICK minimize
local lastClick = 0
hubTitle.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        local now = tick()
        if now - lastClick < 0.35 then window.Visible = not window.Visible end
        lastClick = now
    end
end)

-- ══════════════════════════════════════════════════════════════
-- STARTUP
-- ══════════════════════════════════════════════════════════════
task.spawn(function()
    task.wait(0.1)

    if nyroxSpeedBox and nyroxSpeedBox.Parent then nyroxSpeedBox.Text = tostring(boosterSpeedVal) end
    if nyroxJumpBox  and nyroxJumpBox.Parent  then nyroxJumpBox.Text  = tostring(boosterJumpVal)  end

    local rx = math.clamp((igThreshold-0.70)/0.25, 0, 1)
    if nyroxSlFill and nyroxSlFill.Parent then nyroxSlFill.Size = UDim2.new(rx,0,1,0) end
    if nyroxSlKnob and nyroxSlKnob.Parent then nyroxSlKnob.Position = UDim2.new(rx,-8,0.5,-8) end
    if nyroxSlVal  and nyroxSlVal.Parent  then nyroxSlVal.Text = math.floor(igThreshold*100).."%" end

    if boosterEnabled     then syncBoosterUI() end
    if infJumpEnabled     then syncInfJumpUI() end
    if antiRagdollEnabled then pcall(startAntiRagdoll) end
    if autoGrabEnabled    then pcall(agStart) end
    if autoKickEnabled    then pcall(startAutoKick) end
    if antiBeeEnabled     then pcall(startAntiBee) end
    if timerESPEnabled    then pcall(startTimerESP) end
    if friendsESPEnabled  then pcall(startFriendsESP) end
    if autoTurretEnabled  then pcall(enableAutoTurret) end
    if optimizerEnabled   then pcall(enableOptimizer) end
    if xrayEnabled        then pcall(xrayStart) end
    if brainrotESPEnabled then startBrainrotESP() end
    if playerESPEnabled   then startPlayerESP() end
    if flashTPEnabled     then syncFlashTPUI() end

    -- Semi TP başlat
    if CFG.semiTPEnabled then
        semiTPEnabled = true
        semiMarker = createSemiMarker()
    end

    defensePanel.Visible  = CFG.defenseVisible
    adminPanel.Visible    = CFG.adminVisible
    flashTPPanel.Visible  = CFG.flashTPVisible
    cdPanel.Visible       = CFG.cdVisible

    window.Position       = UDim2.new(0.5,-320,0.5,-210)
    defensePanel.Position = UDim2.new(0,10,0,60)
    adminPanel.Position   = UDim2.new(1,-310,0,60)
    flashTPPanel.Position = UDim2.new(0,10,1,-150)
    cdPanel.Position      = UDim2.new(1,-220,1,-245)
end)
