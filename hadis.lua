--[[────────────────────────────────────────────────────────────
    HADIS // ANTI VC GUARD  (Solara edition)

    Loader (may cache-bust, palitan ang v= kada update):
    loadstring(game:HttpGet("https://raw.githubusercontent.com/hadisxchiken-ctrl/hadis41-/main/hadis.lua?v=1"))()

    Solara notes:
      - gethui() gamit, hindi CoreGui
      - walang VIM dependency (touch ang drag at buttons)
      - hookfunction / hookmetamethod / getconnections lahat guarded
────────────────────────────────────────────────────────────]]

local LOADER = "https://raw.githubusercontent.com/hadisxchiken-ctrl/hadis41-/main/hadis.lua?v=1"

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UIS              = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local VCS              = game:GetService("VoiceChatService")
local VCI              = game:FindService("VoiceChatInternal")
local LP               = Players.LocalPlayer

if not VCI then
    return warn("[AVG] VoiceChatInternal not found - voice chat unsupported here.")
end

-- host: gethui > CoreGui > PlayerGui
local host
do
    local ok, h = pcall(function() return gethui and gethui() end)
    if ok and h then host = h
    else
        ok, h = pcall(function() return game:GetService("CoreGui") end)
        if ok and h then host = h else host = LP:WaitForChild("PlayerGui") end
    end
end

for _, n in ipairs({ "AntiVCGuard", "M7AntiVCB" }) do
    local old = host:FindFirstChild(n)
    if old then old:Destroy() end
end

-- ════════════════ CONFIG ════════════════
local CONFIG = {
    REJOIN_COOLDOWN  = 1.2,
    DEAD_STATE_LIMIT = 1.5,
    LOOP_INTERVAL    = 0.20,
    BAR_COUNT        = 14,
    LEVEL_BOOST      = 4.0,
    CARD_W           = 244,
}

local C = {
    bg      = Color3.fromRGB(11, 11, 15),
    border  = Color3.fromRGB(34, 34, 44),
    surface = Color3.fromRGB(19, 19, 25),
    off     = Color3.fromRGB(26, 26, 34),
    green   = Color3.fromRGB(45, 215, 105),
    greenBg = Color3.fromRGB(14, 44, 26),
    red     = Color3.fromRGB(240, 60, 60),
    redBg   = Color3.fromRGB(46, 15, 15),
    amber   = Color3.fromRGB(240, 185, 45),
    amberBg = Color3.fromRGB(40, 33, 12),
    text    = Color3.fromRGB(240, 240, 250),
    faint   = Color3.fromRGB(62, 62, 78),
}

local S = {
    enabled = false, hardMuted = false,
    input = nil, analyzer = nil, wire = nil,
    ownConn = nil, disabledConns = {},
    lastState = "Idle", lastJoined = 0, lastJoinTry = 0,
    leavesBlocked = 0, rejoins = 0,
    rawLevel = 0, smoothLevel = 0, bars = {},
    dragging = false, dragStart = nil, dragBase = nil,
}

for i = 1, CONFIG.BAR_COUNT do S.bars[i] = 0 end

local function tw(o, p, t)
    TweenService:Create(o, TweenInfo.new(t or 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), p):Play()
end

-- ════════════════ AUDIO GRAPH ════════════════
local function ensureInput()
    local i = S.input
    if i then
        local ok = pcall(function()
            if i.Parent == nil then i.Parent = LP end
            i.Player = LP
            i.Muted  = false
            i.Active = true
        end)
        if ok and i.Parent then return i end
    end
    local found = LP:FindFirstChildOfClass("AudioDeviceInput")
    if not found then found = Instance.new("AudioDeviceInput") end
    found.Player = LP
    found.Muted  = false
    found.Active = true
    found.Parent = LP
    S.input = found
    return found
end

local function ensureGraph()
    local input = ensureInput()

    if not S.analyzer or S.analyzer.Parent == nil then
        local a = Instance.new("AudioAnalyzer")
        a.Name = "_AVG_Analyzer"
        a.Parent = LP
        S.analyzer = a
    end

    if not S.wire or S.wire.Parent == nil then
        local w = Instance.new("Wire")
        w.Name = "_AVG_Wire"
        w.SourceInstance = input
        w.TargetInstance = S.analyzer
        w.Parent = LP
        S.wire = w
    else
        S.wire.SourceInstance = input
        S.wire.TargetInstance = S.analyzer
    end
end

local function publish(state)
    pcall(function()
        VCI:PublishPause(S.hardMuted and true or (state == nil or state))
    end)
end

-- ════════════════ HOOKS ════════════════
local origNamecall
if type(hookmetamethod) == "function" and type(getnamecallmethod) == "function" then
    pcall(function()
        origNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local m = getnamecallmethod()
            if m == "leaveVoice" and S.enabled and self == VCS then
                S.leavesBlocked += 1
                pcall(updateStats)
                return true
            end
            return origNamecall(self, ...)
        end)
    end)
end

local origPublish
if type(hookfunction) == "function" then
    pcall(function()
        origPublish = hookfunction(VCI.PublishPause, function(self, paused)
            if S.enabled and not S.hardMuted then
                return origPublish(self, false)
            end
            return origPublish(self, paused)
        end)
    end)
end

local function killEngineConns()
    if type(getconnections) ~= "function" then return end
    local ok, conns = pcall(getconnections, VCI.StateChanged)
    if not ok or not conns then return end
    for _, c in ipairs(conns) do
        if pcall(function() c:Disable() end) then
            table.insert(S.disabledConns, c)
        end
    end
end

local function restoreEngineConns()
    for _, c in ipairs(S.disabledConns) do
        pcall(function() c:Enable() end)
    end
    table.clear(S.disabledConns)
end

local function tryRejoin(force)
    local now = os.clock()
    if not force and now - S.lastJoinTry < CONFIG.REJOIN_COOLDOWN then return end
    S.lastJoinTry = now
    S.rejoins += 1
    pcall(updateStats)
    task.spawn(function() pcall(function() VCS:joinVoice() end) end)
end

-- ════════════════ UI ════════════════
local gui = Instance.new("ScreenGui")
gui.Name = "AntiVCGuard"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 1000
gui.Parent = host

local card = Instance.new("Frame")
card.Size = UDim2.fromOffset(CONFIG.CARD_W, 0)
card.Position = UDim2.new(0, 24, 0.35, 0)
card.AutomaticSize = Enum.AutomaticSize.Y
card.BackgroundColor3 = C.bg
card.BorderSizePixel = 0
card.Parent = gui

Instance.new("UICorner", card).CornerRadius = UDim.new(0, 13)
local stroke = Instance.new("UIStroke", card)
stroke.Color = C.border
stroke.Thickness = 1
stroke.Transparency = 0.35

local pad = Instance.new("UIPadding", card)
pad.PaddingTop = UDim.new(0, 14)
pad.PaddingBottom = UDim.new(0, 14)
pad.PaddingLeft = UDim.new(0, 14)
pad.PaddingRight = UDim.new(0, 14)

local layout = Instance.new("UIListLayout", card)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 26)
header.BackgroundTransparency = 1
header.LayoutOrder = 1
header.Parent = card

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0.7, 0, 1, 0)
title.BackgroundTransparency = 1
title.Text = "ANTI VC GUARD"
title.TextColor3 = C.faint
title.TextSize = 10
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local dot = Instance.new("Frame")
dot.Size = UDim2.fromOffset(7, 7)
dot.Position = UDim2.new(1, -34, 0.5, 0)
dot.AnchorPoint = Vector2.new(0, 0.5)
dot.BackgroundColor3 = C.faint
dot.BorderSizePixel = 0
dot.Parent = header
Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

local hState = Instance.new("TextLabel")
hState.Size = UDim2.fromOffset(26, 26)
hState.Position = UDim2.new(1, -26, 0, 0)
hState.BackgroundTransparency = 1
hState.Text = "OFF"
hState.TextColor3 = C.faint
hState.TextSize = 9
hState.Font = Enum.Font.GothamBold
hState.TextXAlignment = Enum.TextXAlignment.Right
hState.Parent = header

local function spacer(h, o)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, h)
    f.BackgroundTransparency = 1
    f.LayoutOrder = o
    f.Parent = card
end
spacer(12, 2)

local statusBox = Instance.new("Frame")
statusBox.Size = UDim2.new(1, 0, 0, 26)
statusBox.BackgroundColor3 = C.amberBg
statusBox.BorderSizePixel = 0
statusBox.LayoutOrder = 3
statusBox.Parent = card
Instance.new("UICorner", statusBox).CornerRadius = UDim.new(0, 6)

local sbPad = Instance.new("UIPadding", statusBox)
sbPad.PaddingLeft = UDim.new(0, 9)
sbPad.PaddingRight = UDim.new(0, 9)

local statusText = Instance.new("TextLabel")
statusText.Size = UDim2.new(1, 0, 1, 0)
statusText.BackgroundTransparency = 1
statusText.Text = "Join voice chat first"
statusText.TextColor3 = C.amber
statusText.TextSize = 9
statusText.Font = Enum.Font.GothamMedium
statusText.TextXAlignment = Enum.TextXAlignment.Left
statusText.TextTruncate = Enum.TextTruncate.AtEnd
statusText.Parent = statusBox

local function setStatus(t, col, bg)
    statusText.Text = t
    statusText.TextColor3 = col
    tw(statusBox, { BackgroundColor3 = bg }, 0.25)
end

spacer(10, 4)

local meter = Instance.new("Frame")
meter.Size = UDim2.new(1, 0, 0, 24)
meter.BackgroundColor3 = C.surface
meter.BorderSizePixel = 0
meter.ClipsDescendants = true
meter.LayoutOrder = 5
meter.Parent = card
Instance.new("UICorner", meter).CornerRadius = UDim.new(0, 6)

local mPad = Instance.new("UIPadding", meter)
mPad.PaddingLeft = UDim.new(0, 3)
mPad.PaddingRight = UDim.new(0, 3)
mPad.PaddingTop = UDim.new(0, 3)
mPad.PaddingBottom = UDim.new(0, 3)

local mLayout = Instance.new("UIListLayout", meter)
mLayout.FillDirection = Enum.FillDirection.Horizontal
mLayout.Padding = UDim.new(0, 2)
mLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom

local barW = (CONFIG.CARD_W - 28 - 6 - (CONFIG.BAR_COUNT - 1) * 2) / CONFIG.BAR_COUNT
local barFrames = {}
for i = 1, CONFIG.BAR_COUNT do
    local b = Instance.new("Frame")
    b.Size = UDim2.new(0, math.max(barW, 3), 0, 2)
    b.BackgroundColor3 = C.off
    b.BorderSizePixel = 0
    b.LayoutOrder = i
    b.Parent = meter
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 2)
    barFrames[i] = b
end

spacer(10, 6)

local statsLabel = Instance.new("TextLabel")
statsLabel.Size = UDim2.new(1, 0, 0, 11)
statsLabel.BackgroundTransparency = 1
statsLabel.Text = "leaves blocked: 0  |  rejoins: 0"
statsLabel.TextColor3 = C.faint
statsLabel.TextSize = 8
statsLabel.Font = Enum.Font.Gotham
statsLabel.TextXAlignment = Enum.TextXAlignment.Left
statsLabel.LayoutOrder = 7
statsLabel.Parent = card

function updateStats()
    statsLabel.Text = ("leaves blocked: %d  |  rejoins: %d"):format(S.leavesBlocked, S.rejoins)
end

spacer(10, 8)

-- row: mute + toggle (malaking tap target para sa mobile)
local row = Instance.new("Frame")
row.Size = UDim2.new(1, 0, 0, 40)
row.BackgroundTransparency = 1
row.LayoutOrder = 9
row.Parent = card

local muteBtn = Instance.new("TextButton")
muteBtn.Size = UDim2.new(0.36, -3, 1, 0)
muteBtn.BackgroundColor3 = C.surface
muteBtn.BorderSizePixel = 0
muteBtn.Text = "MUTE"
muteBtn.TextColor3 = C.text
muteBtn.TextSize = 11
muteBtn.Font = Enum.Font.GothamBold
muteBtn.AutoButtonColor = false
muteBtn.Parent = row
Instance.new("UICorner", muteBtn).CornerRadius = UDim.new(0, 8)
local muteStroke = Instance.new("UIStroke", muteBtn)
muteStroke.Color = C.border
muteStroke.Thickness = 1

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0.64, -3, 1, 0)
toggleBtn.Position = UDim2.new(0.36, 3, 0, 0)
toggleBtn.BackgroundColor3 = C.green
toggleBtn.BorderSizePixel = 0
toggleBtn.Text = "ENABLE GUARD"
toggleBtn.TextColor3 = Color3.fromRGB(8, 8, 8)
toggleBtn.TextSize = 11
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.AutoButtonColor = false
toggleBtn.Parent = row
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 8)

spacer(8, 10)

local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(1, 0, 0, 12)
hint.BackgroundTransparency = 1
hint.Text = "drag the header to move"
hint.TextColor3 = C.faint
hint.TextSize = 8
hint.Font = Enum.Font.Gotham
hint.LayoutOrder = 11
hint.Parent = card

-- drag: touch + mouse
local function beginDrag(i)
    S.dragging = true
    S.dragStart = i.Position
    S.dragBase = UDim2.fromOffset(card.AbsolutePosition.X, card.AbsolutePosition.Y)
    i.Changed:Connect(function()
        if i.UserInputState == Enum.UserInputState.End then S.dragging = false end
    end)
end

header.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
    or i.UserInputType == Enum.UserInputType.Touch then
        beginDrag(i)
    end
end)

UIS.InputChanged:Connect(function(i)
    if not S.dragging or not S.dragStart then return end
    if i.UserInputType ~= Enum.UserInputType.MouseMovement
    and i.UserInputType ~= Enum.UserInputType.Touch then return end
    local d = i.Position - S.dragStart
    card.Position = UDim2.new(0, S.dragBase.X.Offset + d.X, 0, S.dragBase.Y.Offset + d.Y)
end)

-- ════════════════ CORE ════════════════
local function enable()
    if S.enabled then return end
    S.enabled = true
    S.hardMuted = false

    ensureGraph()
    killEngineConns()
    publish(false)

    if S.ownConn then S.ownConn:Disconnect() end
    S.ownConn = VCI.StateChanged:Connect(function(_, new)
        local n = tostring(new)
        S.lastState = n
        if n:find("Joined") then
            S.lastJoined = os.clock()
            publish(false)
        elseif n:find("Disconnected") or n:find("Error") then
            publish(false)
            task.delay(0.35, function()
                if S.enabled and not tostring(S.lastState):find("Joined") then
                    tryRejoin(true)
                end
            end)
        end
    end)

    toggleBtn.Text = "DISABLE GUARD"
    tw(toggleBtn, { BackgroundColor3 = C.red }, 0.2)
    toggleBtn.TextColor3 = C.text
    tw(dot, { BackgroundColor3 = C.green }, 0.25)
    hState.Text = "ON"
    hState.TextColor3 = C.green
    setStatus("Guard active | blocking kicks", C.green, C.greenBg)
end

local function disable()
    if not S.enabled then return end
    S.enabled = false
    S.hardMuted = false

    if S.ownConn then S.ownConn:Disconnect(); S.ownConn = nil end
    restoreEngineConns()

    toggleBtn.Text = "ENABLE GUARD"
    tw(toggleBtn, { BackgroundColor3 = C.green }, 0.2)
    toggleBtn.TextColor3 = Color3.fromRGB(8, 8, 8)
    tw(dot, { BackgroundColor3 = C.faint }, 0.25)
    hState.Text = "OFF"
    hState.TextColor3 = C.faint
    setStatus("Guard off | normal voice", C.amber, C.amberBg)

    S.smoothLevel = 0
    S.rawLevel = 0
    for i = 1, CONFIG.BAR_COUNT do
        S.bars[i] = 0
        barFrames[i].Size = UDim2.new(0, barW, 0, 2)
        barFrames[i].BackgroundColor3 = C.off
    end
end

local function toggleMute()
    if not S.enabled then return end
    S.hardMuted = not S.hardMuted
    publish(S.hardMuted)
    if S.hardMuted then
        muteBtn.Text = "UNMUTE"
        muteBtn.TextColor3 = C.red
        tw(muteStroke, { Color = C.red }, 0.15)
        setStatus("Hard muted | tap unmute", C.red, C.redBg)
    else
        muteBtn.Text = "MUTE"
        muteBtn.TextColor3 = C.text
        tw(muteStroke, { Color = C.border }, 0.15)
        setStatus("Guard active | blocking kicks", C.green, C.greenBg)
    end
end

toggleBtn.MouseButton1Click:Connect(function()
    if S.enabled then disable() else enable() end
end)

muteBtn.MouseButton1Click:Connect(toggleMute)

-- keybind pa rin, kung may keyboard
UIS.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.F6 then
        if S.enabled then disable() else enable() end
    elseif i.KeyCode == Enum.KeyCode.F7 then
        toggleMute()
    end
end)

-- keep-alive + watchdog
task.spawn(function()
    while gui.Parent do
        if S.enabled then
            pcall(ensureGraph)
            pcall(publish, S.hardMuted)
            if not S.lastState:find("Joined")
            and os.clock() - S.lastJoined > CONFIG.DEAD_STATE_LIMIT then
                tryRejoin(false)
            end
        end
        task.wait(CONFIG.LOOP_INTERVAL)
    end
end)

-- render
RunService.RenderStepped:Connect(function(dt)
    if S.enabled and S.analyzer and not S.hardMuted then
        local rms  = S.analyzer.RmsLevel or 0
        local peak = S.analyzer.PeakLevel or 0
        local c = math.max(rms * CONFIG.LEVEL_BOOST, peak * CONFIG.LEVEL_BOOST * 0.7)
        if c > 0.01 then S.rawLevel = math.clamp(c, 0, 1) end
    end

    S.rawLevel = math.max(0, S.rawLevel - dt * 2.6)
    S.smoothLevel += (S.rawLevel - S.smoothLevel) * math.min(1, dt * 12)

    local lvl = (S.enabled and not S.hardMuted) and S.smoothLevel or 0

    for i = 1, CONFIG.BAR_COUNT do
        local cd = math.abs((i / CONFIG.BAR_COUNT) - 0.5) * 2
        local n  = math.sin(os.clock() * 8 + i * 1.6) * 0.15
        local target = math.clamp(lvl * (1.15 - cd * 0.45) + n * lvl, 0, 1)
        S.bars[i] += (target - S.bars[i]) * math.min(1, dt * 16)

        local v = S.bars[i]
        barFrames[i].Size = UDim2.new(0, barW, 0, math.max(2, v * 16))
        barFrames[i].BackgroundColor3 = v < 0.01 and C.off
            or (v < 0.6 and C.green or C.red)
    end
end)

if type(queue_on_teleport) == "function" then
    pcall(function()
        queue_on_teleport(('loadstring(game:HttpGet("%s"))()'):format(LOADER))
    end)
end

setStatus("Join voice chat first", C.amber, C.amberBg)
