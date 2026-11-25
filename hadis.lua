--=====================================================================
--  ANTI VC BAN  v3.3  |  PC build  |  by hadis
--  Hotkeys: V mute · F1 legacy · F2 modern · F3 stop · F4 hide · F5 unload
--  Join chain: JoinVoice -> JoinVoiceChannel -> VoiceChatInternal
--  Best on: Velocity / Madium / Wave / Potassium
--  Does NOT work on: Zeno, Xeno, Solara, Volt
--=====================================================================

if getgenv().AVCB_Unload then pcall(getgenv().AVCB_Unload) end
getgenv().AVCB_Loaded = true

local Players  = game:GetService("Players")
local VCS      = game:GetService("VoiceChatService")
local UIS      = game:GetService("UserInputService")
local HS       = game:GetService("HttpService")
local SG       = game:GetService("StarterGui")
local CoreGui  = game:GetService("CoreGui")
local LP       = Players.LocalPlayer
local VCI
pcall(function() VCI = game:GetService("VoiceChatInternal") end)

local VERSION  = "3.3"
local CFG_PATH = "avcb_config.json"

local State = {
    mode = "legacy", autoStart = false, notifyOn = true, hideUi = true,
    interval = 0.75, running = false, muted = false, joins = 0, startedAt = nil,
}
local lastJoin = "-"

local Binds = {
    mute = Enum.KeyCode.V,
    legacy = Enum.KeyCode.F1,
    modern = Enum.KeyCode.F2,
    stop = Enum.KeyCode.F3,
    hide = Enum.KeyCode.F4,
    unload = Enum.KeyCode.F5,
}

local thread, capturing, reopen, hideWin

------------------------------------------------------------------ utils
local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local function notify(text)
    if not State.notifyOn then return end
    pcall(function()
        SG:SetCore("SendNotification", { Title = "Anti VC Ban v" .. VERSION, Text = text, Duration = 3 })
    end)
end

local function saveCfg()
    if not writefile then return end
    local keys = {}
    for a, k in pairs(Binds) do keys[a] = k.Name end
    pcall(function()
        writefile(CFG_PATH, HS:JSONEncode({
            binds = keys, autoStart = State.autoStart, hideUi = State.hideUi,
            notifyOn = State.notifyOn, interval = State.interval,
        }))
    end)
end

local function loadCfg()
    if not (isfile and readfile) or not isfile(CFG_PATH) then return end
    local ok, data = pcall(function() return HS:JSONDecode(readfile(CFG_PATH)) end)
    if not ok or type(data) ~= "table" then return end
    if type(data.binds) == "table" then
        for a, name in pairs(data.binds) do
            if Binds[a] and Enum.KeyCode[name] then Binds[a] = Enum.KeyCode[name] end
        end
    end
    if type(data.autoStart) == "boolean" then State.autoStart = data.autoStart end
    if type(data.hideUi) == "boolean" then State.hideUi = data.hideUi end
    if type(data.notifyOn) == "boolean" then State.notifyOn = data.notifyOn end
    if tonumber(data.interval) then State.interval = math.clamp(tonumber(data.interval), 0.25, 5) end
end
loadCfg()

------------------------------------------------------------------ stock VC ui hiding
local hiddenVc = {}

local function hideVcUi()
    local rg = CoreGui:FindFirstChild("RobloxGui")
    if not rg then return false end
    local bar = rg:FindFirstChild("TopBar") or rg
    local found = false
    local ok = pcall(function()
        for _, d in ipairs(bar:GetDescendants()) do
            if d:IsA("GuiObject") and d.Visible then
                local n = d.Name
                if n:find("Voice") or n:find("Mic") or n:find("Vc") or n:find("VCS") then
                    hiddenVc[d] = true
                    d.Visible = false
                    found = true
                end
            end
        end
    end)
    return ok and found
end

local function showVcUi()
    for obj in pairs(hiddenVc) do
        pcall(function() if obj.Parent then obj.Visible = true end end)
    end
    hiddenVc = {}
end

------------------------------------------------------------------ engine
local function joinOnce()
    local ok, err = false, nil
    if typeof(VCS.JoinVoice) == "function" then
        ok, err = pcall(VCS.JoinVoice, VCS)
    end
    if not ok and typeof(VCS.JoinVoiceChannel) == "function" then
        ok, err = pcall(VCS.JoinVoiceChannel, VCS)
    end
    if not ok and VCI and typeof(VCI.JoinVoice) == "function" then
        ok, err = pcall(VCI.JoinVoice, VCI)
    end
    if not ok and typeof(VCS.GetVoiceChatId) == "function" then
        local cid = select(2, pcall(VCS.GetVoiceChatId, VCS))
        if cid then ok, err = pcall(VCS.JoinVoiceChannel, VCS, cid) end
    end
    lastJoin = ok and "ok" or tostring(err)
    if ok then State.joins = State.joins + 1 end
    return ok
end

local function isJoined()
    if not VCI or typeof(VCI.GetVoiceChatState) ~= "function" then return nil end
    local ok, st = pcall(VCI.GetVoiceChatState, VCI)
    if not ok then return nil end
    local n = tostring(st)
    return n:find("Joined") ~= nil or n:find("InChannel") ~= nil
end

local function setMute(s)
    State.muted = s
    local ok = false
    if VCI and typeof(VCI.SetMicrophoneMute) == "function" then
        ok = pcall(VCI.SetMicrophoneMute, VCI, s)
    end
    if not ok then pcall(function() VCS:SetMicrophoneMute(s) end) end
    if not ok then joinOnce() end
end

local function stopLoop()
    State.running = false
    State.startedAt = nil
    if thread then pcall(task.cancel, thread) thread = nil end
    if State.hideUi then showVcUi() end
end

local function startLoop(m)
    stopLoop()
    State.mode, State.running, State.startedAt = m, true, os.clock()
    if m == "legacy" and State.hideUi then
        task.spawn(function()
            for _ = 1, 12 do
                if not State.running then return end
                hideVcUi()
                task.wait(0.5)
            end
        end)
    end
    thread = task.spawn(function()
        while State.running do
            if State.mode == "legacy" then
                joinOnce()
                task.wait(State.interval)
            else
                if isJoined() ~= true then joinOnce() end
                task.wait(math.max(State.interval * 2.5, 1))
            end
        end
    end)
    notify("Active (" .. m .. ")")
end

------------------------------------------------------------------ window
local gui = new("ScreenGui", { Name = "AVCB", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
pcall(function() gui.Parent = CoreGui end)
if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

local win = new("Frame", {
    Size = UDim2.fromOffset(384, 306),
    Position = UDim2.new(0, 24, 0.5, -153),
    BackgroundColor3 = Color3.fromRGB(16, 16, 20),
    BorderSizePixel = 0, Active = true,
}, gui)
new("UICorner", { CornerRadius = UDim.new(0, 10) }, win)
new("UIStroke", { Color = Color3.fromRGB(44, 44, 54), Thickness = 1 }, win)

local header = new("Frame", {
    Size = UDim2.new(1, 0, 0, 34),
    BackgroundColor3 = Color3.fromRGB(26, 26, 32), BorderSizePixel = 0,
}, win)
new("UICorner", { CornerRadius = UDim.new(0, 10) }, header)

new("TextLabel", {
    Size = UDim2.new(1, -120, 1, 0), Position = UDim2.fromOffset(12, 0),
    BackgroundTransparency = 1, Text = "ANTI VC BAN",
    TextColor3 = Color3.fromRGB(120, 220, 160), Font = Enum.Font.GothamBold,
    TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
}, header)

new("TextLabel", {
    Size = UDim2.fromOffset(40, 34), Position = UDim2.new(1, -114, 0, 0),
    BackgroundTransparency = 1, Text = "v" .. VERSION,
    TextColor3 = Color3.fromRGB(110, 110, 124), Font = Enum.Font.Gotham, TextSize = 10,
}, header)

local function headerBtn(text, x, cb)
    local b = new("TextButton", {
        Size = UDim2.fromOffset(26, 22), Position = UDim2.new(1, x, 0, 6),
        BackgroundColor3 = Color3.fromRGB(44, 44, 54), BorderSizePixel = 0,
        Text = text, TextColor3 = Color3.fromRGB(210, 210, 220),
        Font = Enum.Font.GothamBold, TextSize = 12,
    }, header)
    new("UICorner", { CornerRadius = UDim.new(0, 5) }, b)
    b.MouseButton1Click:Connect(cb)
    return b
end

------------------------------------------------------------------ dragging
local dragging, dragStart, startPos
header.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging, dragStart, startPos = true, i.Position, win.Position
    end
end)
UIS.InputChanged:Connect(function(i)
    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = i.Position - dragStart
        win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

------------------------------------------------------------------ tabs
local tabBar = new("Frame", { Size = UDim2.new(1, -20, 0, 26), Position = UDim2.fromOffset(10, 42), BackgroundTransparency = 1 }, win)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, tabBar)

local content = new("Frame", { Size = UDim2.new(1, -20, 1, -102), Position = UDim2.fromOffset(10, 74), BackgroundTransparency = 1 }, win)

local pages, tabButtons = {}, {}

local function makePage(name, order)
    local p = new("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, LayoutOrder = order }, content)
    pages[name] = p
    local b = new("TextButton", {
        Size = UDim2.fromOffset(64, 26), BackgroundColor3 = Color3.fromRGB(26, 26, 32),
        BorderSizePixel = 0, Text = name, TextColor3 = Color3.fromRGB(140, 140, 152),
        Font = Enum.Font.GothamMedium, TextSize = 11, LayoutOrder = order,
    }, tabBar)
    new("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
    tabButtons[name] = b
end

local function selectTab(name)
    for n, p in pairs(pages) do p.Visible = (n == name) end
    for n, b in pairs(tabButtons) do
        local on = (n == name)
        b.BackgroundColor3 = on and Color3.fromRGB(38, 74, 56) or Color3.fromRGB(26, 26, 32)
        b.TextColor3 = on and Color3.fromRGB(160, 240, 190) or Color3.fromRGB(140, 140, 152)
    end
end

for i, n in ipairs({ "Main", "Hotkeys", "Settings", "Info", "Credits" }) do
    makePage(n, i)
    tabButtons[n].MouseButton1Click:Connect(function() selectTab(n) end)
end

------------------------------------------------------------------ helpers
local function label(parent, text, y, color, size)
    return new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16), Position = UDim2.fromOffset(0, y),
        BackgroundTransparency = 1, Text = text,
        TextColor3 = color or Color3.fromRGB(130, 130, 142),
        Font = Enum.Font.Gotham, TextSize = size or 11,
        TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
    }, parent)
end

local function actionBtn(parent, text, y, color, height, cb)
    local b = new("TextButton", {
        Size = UDim2.new(1, 0, 0, height or 32), Position = UDim2.fromOffset(0, y),
        BackgroundColor3 = color, BorderSizePixel = 0, Text = text,
        TextColor3 = Color3.fromRGB(235, 235, 240), Font = Enum.Font.GothamMedium,
        TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
    }, parent)
    new("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
    new("UIPadding", { PaddingLeft = UDim.new(0, 12) }, b)
    if cb then b.MouseButton1Click:Connect(cb) end
    return b
end

local function toggleRow(parent, text, y, get, set)
    local row = new("Frame", { Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromOffset(0, y), BackgroundColor3 = Color3.fromRGB(22, 22, 28), BorderSizePixel = 0 }, parent)
    new("UICorner", { CornerRadius = UDim.new(0, 6) }, row)
    new("TextLabel", {
        Size = UDim2.new(1, -60, 1, 0), Position = UDim2.fromOffset(10, 0),
        BackgroundTransparency = 1, Text = text, TextColor3 = Color3.fromRGB(200, 200, 210),
        Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local pill = new("TextButton", { Size = UDim2.fromOffset(42, 20), Position = UDim2.new(1, -52, 0, 5), BackgroundColor3 = Color3.fromRGB(44, 44, 54), BorderSizePixel = 0, Text = "" }, row)
    new("UICorner", { CornerRadius = UDim.new(1, 0) }, pill)
    local knob = new("Frame", { Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(2, 2), BackgroundColor3 = Color3.fromRGB(150, 150, 162), BorderSizePixel = 0 }, pill)
    new("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)
    local function render()
        local on = get()
        pill.BackgroundColor3 = on and Color3.fromRGB(38, 96, 64) or Color3.fromRGB(44, 44, 54)
        knob.Position = on and UDim2.new(1, -18, 0, 2) or UDim2.fromOffset(2, 2)
        knob.BackgroundColor3 = on and Color3.fromRGB(150, 240, 190) or Color3.fromRGB(150, 150, 162)
    end
    pill.MouseButton1Click:Connect(function() set(not get()) render() end)
    render()
    return row
end

------------------------------------------------------------------ MAIN
local mainP = pages.Main
actionBtn(mainP, "Anti VC Ban  —  Legacy      [F1]", 0, Color3.fromRGB(32, 92, 62), 34, function() startLoop("legacy") end)
actionBtn(mainP, "Anti VC Ban  —  Modern     [F2]", 40, Color3.fromRGB(34, 60, 96), 34, function() startLoop("modern") end)
actionBtn(mainP, "Stop      [F3]", 80, Color3.fromRGB(48, 48, 58), 28, function() stopLoop() notify("Stopped") end)

local stateBox = new("Frame", { Size = UDim2.new(1, 0, 0, 40), Position = UDim2.fromOffset(0, 114), BackgroundColor3 = Color3.fromRGB(22, 22, 28), BorderSizePixel = 0 }, mainP)
new("UICorner", { CornerRadius = UDim.new(0, 6) }, stateBox)
new("TextLabel", { Size = UDim2.new(1, -20, 0, 12), Position = UDim2.fromOffset(10, 5), BackgroundTransparency = 1, Text = "STATE", TextColor3 = Color3.fromRGB(110, 110, 122), Font = Enum.Font.GothamBold, TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left }, stateBox)
local stateLbl = new("TextLabel", { Size = UDim2.new(1, -20, 0, 16), Position = UDim2.fromOffset(10, 18), BackgroundTransparency = 1, Text = "idle · mic live", TextColor3 = Color3.fromRGB(200, 200, 210), Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left }, stateBox)

label(mainP, "Legacy hides the stock VC UI on purpose. Mute is a hotkey, not a button.", 160, Color3.fromRGB(110, 110, 122), 10)

------------------------------------------------------------------ HOTKEYS
local hkP = pages.Hotkeys
local bindBtns = {}

local function bindRow(action, text, y)
    local row = new("Frame", { Size = UDim2.new(1, 0, 0, 26), Position = UDim2.fromOffset(0, y), BackgroundColor3 = Color3.fromRGB(22, 22, 28), BorderSizePixel = 0 }, hkP)
    new("UICorner", { CornerRadius = UDim.new(0, 6) }, row)
    new("TextLabel", { Size = UDim2.new(1, -60, 1, 0), Position = UDim2.fromOffset(10, 0), BackgroundTransparency = 1, Text = text, TextColor3 = Color3.fromRGB(200, 200, 210), Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left }, row)
    local k = new("TextButton", { Size = UDim2.fromOffset(40, 18), Position = UDim2.new(1, -48, 0, 4), BackgroundColor3 = Color3.fromRGB(44, 44, 54), BorderSizePixel = 0, Text = Binds[action].Name, TextColor3 = Color3.fromRGB(216, 216, 226), Font = Enum.Font.GothamBold, TextSize = 9 }, row)
    new("UICorner", { CornerRadius = UDim.new(0, 4) }, k)
    bindBtns[action] = k
    k.MouseButton1Click:Connect(function()
        capturing = action
        for _, b in pairs(bindBtns) do b.TextColor3 = Color3.fromRGB(216, 216, 226) end
        k.Text = "..."
        k.TextColor3 = Color3.fromRGB(160, 240, 190)
    end)
end

bindRow("mute", "Mute mic", 0)
bindRow("legacy", "Start legacy", 30)
bindRow("modern", "Start modern", 60)
bindRow("stop", "Stop", 90)
bindRow("hide", "Hide UI", 120)
bindRow("unload", "Unload", 150)

------------------------------------------------------------------ SETTINGS
local setP = pages.Settings
toggleRow(setP, "Auto-start on execute", 0, function() return State.autoStart end, function(v) State.autoStart = v saveCfg() end)
toggleRow(setP, "Notifications", 34, function() return State.notifyOn end, function(v) State.notifyOn = v saveCfg() end)
toggleRow(setP, "Hide stock VC UI (legacy)", 68, function() return State.hideUi end, function(v)
    State.hideUi = v
    if v and State.running then hideVcUi() elseif not v then showVcUi() end
    saveCfg()
end)

local intervalLabel = label(setP, "", 104, Color3.fromRGB(200, 200, 210), 11)
local function renderInterval() intervalLabel.Text = string.format("Rejoin interval:  %.2fs", State.interval) end
renderInterval()

local minusBtn = actionBtn(setP, "-", 122, Color3.fromRGB(34, 34, 42), 26, function()
    State.interval = math.clamp(State.interval - 0.25, 0.25, 5) renderInterval() saveCfg()
end)
minusBtn.Size = UDim2.new(0.48, 0, 0, 26)
minusBtn.TextXAlignment = Enum.TextXAlignment.Center

local plusBtn = actionBtn(setP, "+", 122, Color3.fromRGB(34, 34, 42), 26, function()
    State.interval = math.clamp(State.interval + 0.25, 0.25, 5) renderInterval() saveCfg()
end)
plusBtn.Size = UDim2.new(0.48, 0, 0, 26)
plusBtn.Position = UDim2.new(0.52, 0, 0, 122)
plusBtn.TextXAlignment = Enum.TextXAlignment.Center

actionBtn(setP, "Reset all settings", 156, Color3.fromRGB(60, 40, 40), 26, function()
    State.autoStart, State.notifyOn, State.hideUi, State.interval = false, true, true, 0.75
    for a, k in pairs({ mute = "V", legacy = "F1", modern = "F2", stop = "F3", hide = "F4", unload = "F5" }) do
        Binds[a] = Enum.KeyCode[k]
        if bindBtns[a] then bindBtns[a].Text = k end
    end
    renderInterval() saveCfg()
end)

------------------------------------------------------------------ INFO
local infoP = pages.Info
local rows = {
    { "Status", "idle" }, { "Method", "-" }, { "VC state", "nil" },
    { "Mic", "live" }, { "Joins sent", "0" }, { "Last join", "-" },
    { "Uptime", "-" }, { "JoinVoice", typeof(VCS.JoinVoice) },
    { "JoinVoiceChannel", typeof(VCS.JoinVoiceChannel) },
    { "VoiceChatInternal", VCI and "present" or "missing" },
    { "Executor mute API", (VCI and VCI.SetMicrophoneMute) and "yes" or "fallback" },
}
local infoLbls = {}
for i, r in ipairs(rows) do
    local l = label(infoP, r[1] .. ":  " .. r[2], (i - 1) * 15, Color3.fromRGB(190, 190, 200), 10)
    infoLbls[r[1]] = l
end

------------------------------------------------------------------ CREDITS
local credP = pages.Credits
label(credP, "ANTI VC BAN  v" .. VERSION, 0, Color3.fromRGB(160, 240, 190), 14)
label(credP, "by hadis", 22, Color3.fromRGB(200, 200, 210), 12)
label(credP, "PC build. Legacy + Modern rejoin engine.", 48)
label(credP, "Use an alt if you care about the account.", 68)
label(credP, "Not affiliated with Roblox or Mois7.", 88)

------------------------------------------------------------------ footer
local footer = new("TextLabel", {
    Size = UDim2.new(1, -20, 0, 18), Position = UDim2.new(0, 10, 1, -26),
    BackgroundTransparency = 1, Text = "idle", TextColor3 = Color3.fromRGB(110, 110, 122),
    Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
}, win)

task.spawn(function()
    while gui.Parent do
        if State.running then
            footer.Text = "running · " .. State.mode .. " · mic " .. (State.muted and "muted" or "live")
            footer.TextColor3 = Color3.fromRGB(120, 220, 160)
        else
            footer.Text = "idle · mic " .. (State.muted and "muted" or "live")
            footer.TextColor3 = Color3.fromRGB(110, 110, 122)
        end
        stateLbl.Text = (State.running and (State.mode .. " running") or "idle") .. " · mic " .. (State.muted and "muted" or "live")
        infoLbls["Status"].Text = "Status:  " .. (State.running and "RUNNING" or "idle")
        infoLbls["Method"].Text = "Method:  " .. (State.running and State.mode or "-")
        infoLbls["VC state"].Text = "VC state:  " .. tostring(isJoined())
        infoLbls["Mic"].Text = "Mic:  " .. (State.muted and "muted" or "live")
        infoLbls["Joins sent"].Text = "Joins sent:  " .. State.joins
        infoLbls["Last join"].Text = "Last join:  " .. lastJoin
        infoLbls["Uptime"].Text = "Uptime:  " .. (State.startedAt and string.format("%.0fs", os.clock() - State.startedAt) or "-")
        task.wait(0.4)
    end
end)

------------------------------------------------------------------ actions
local function doAction(a)
    if a == "mute" then setMute(not State.muted)
    elseif a == "legacy" then startLoop("legacy")
    elseif a == "modern" then startLoop("modern")
    elseif a == "stop" then stopLoop() notify("Stopped")
    elseif a == "hide" and hideWin then hideWin()
    end
end

UIS.InputBegan:Connect(function(input, processed)
    if processed or input.KeyCode == Enum.KeyCode.Unknown then return end
    if capturing then
        Binds[capturing] = input.KeyCode
        if bindBtns[capturing] then
            bindBtns[capturing].Text = input.KeyCode.Name
            bindBtns[capturing].TextColor3 = Color3.fromRGB(216, 216, 226)
        end
        capturing = nil
        saveCfg()
        return
    end
    for a, key in pairs(Binds) do
        if input.KeyCode == key then
            if a == "unload" then
                if getgenv().AVCB_Unload then getgenv().AVCB_Unload() end
            else
                doAction(a)
            end
            return
        end
    end
end)

------------------------------------------------------------------ hide / close
function hideWin()
    win.Visible = false
    if reopen then reopen:Destroy() end
    reopen = new("TextButton", {
        Size = UDim2.fromOffset(104, 28), Position = UDim2.fromOffset(24, 300),
        BackgroundColor3 = Color3.fromRGB(26, 26, 32), BorderSizePixel = 0,
        Text = "Anti VC Ban v" .. VERSION, TextColor3 = Color3.fromRGB(120, 220, 160),
        Font = Enum.Font.GothamBold, TextSize = 10,
    }, gui)
    new("UICorner", { CornerRadius = UDim.new(0, 6) }, reopen)
    reopen.MouseButton1Click:Connect(function()
        reopen:Destroy() reopen = nil
        win.Visible = true
    end)
end

local function unload()
    stopLoop()
    pcall(function() if State.muted then setMute(false) end end)
    gui:Destroy()
    getgenv().AVCB_Loaded = nil
    getgenv().AVCB_Unload = nil
end
getgenv().AVCB_Unload = unload

headerBtn("–", -62, hideWin)
headerBtn("X", -32, unload)

------------------------------------------------------------------ boot
selectTab("Main")
if State.autoStart then task.delay(0.4, function() startLoop(State.mode) end) end
notify("Loaded v" .. VERSION .. " · F1 legacy")
