--=====================================================================
--  ANTI VC BAN  v3.6  |  PC build  |  by hadis
--  Auto-starts legacy. Probes the voice API on load and prints results.
--  Hotkeys: V mute · F1 legacy · F2 modern · F3 stop · F4 hide · F5 unload
--=====================================================================

if getgenv().AVCB_Unload then pcall(getgenv().AVCB_Unload) end
getgenv().AVCB_Loaded = true

local VERSION = "3.6"
local Players, VCS, UIS, CoreGui, SG
local LP
local VCI

pcall(function()
    Players = game:GetService("Players")
    VCS     = game:GetService("VoiceChatService")
    UIS     = game:GetService("UserInputService")
    CoreGui = game:GetService("CoreGui")
    SG      = game:GetService("StarterGui")
    LP      = Players.LocalPlayer
end)
pcall(function() VCI = game:GetService("VoiceChatInternal") end)

local State = { running = false, muted = false, joins = 0, lastErr = "-", mode = "legacy" }
local Binds = { mute = Enum.KeyCode.V, legacy = Enum.KeyCode.F1, modern = Enum.KeyCode.F2,
                stop = Enum.KeyCode.F3, hide = Enum.KeyCode.F4, unload = Enum.KeyCode.F5 }
local thread, capturing, reopen

------------------------------------------------------------------ safe access
local function hasMember(obj, name)
    if not obj then return false end
    local ok, v = pcall(function() return obj[name] end)
    return ok and v ~= nil
end

local function tryCall(obj, name, ...)
    if not obj then return false, "no object" end
    local got, fn = pcall(function() return obj[name] end)
    if not got or typeof(fn) ~= "function" then return false, name .. " missing" end
    return pcall(fn, obj, ...)
end

------------------------------------------------------------------ engine
local function joinOnce()
    local ok, err = false, "no candidate"
    for _, c in ipairs({
        { VCS, "JoinVoice" }, { VCS, "JoinVoiceChannel" }, { VCS, "JoinVoiceChat" },
        { VCI, "JoinVoice" }, { VCI, "JoinVoiceChannel" }, { VCI, "JoinVoiceChat" },
    }) do
        ok, err = tryCall(c[1], c[2])
        if ok then break end
    end
    if not ok and hasMember(VCI, "GetVoiceChatId") then
        local got, cid = pcall(function() return VCI:GetVoiceChatId() end)
        if got and cid then ok, err = tryCall(VCS, "JoinVoiceChannel", cid) end
    end
    State.lastErr = ok and "ok" or tostring(err)
    if ok then State.joins = State.joins + 1 end
    return ok
end

local function isJoined()
    if not hasMember(VCI, "GetVoiceChatState") then return nil end
    local ok, st = pcall(function() return VCI:GetVoiceChatState() end)
    if not ok then return nil end
    local n = tostring(st)
    return n:find("Joined") ~= nil or n:find("InChannel") ~= nil
end

local function setMute(s)
    State.muted = s
    local ok = false
    if hasMember(VCI, "SetMicrophoneMute") then ok = pcall(function() VCI:SetMicrophoneMute(s) end) end
    if not ok then pcall(function() VCS:SetMicrophoneMute(s) end) end
    if not ok then joinOnce() end
    if render then render() end
end

local function stopLoop()
    State.running = false
    if thread then pcall(task.cancel, thread) thread = nil end
    if render then render() end
end

local function startLoop(m)
    pcall(stopLoop)
    State.mode, State.running = m, true
    thread = task.spawn(function()
        while State.running do
            if State.mode == "legacy" then
                joinOnce()
                task.wait(0.75)
            else
                if isJoined() ~= true then joinOnce() end
                task.wait(2)
            end
        end
    end)
    if render then render() end
    print("[AVCB] loop started:", m)
end

------------------------------------------------------------------ window
local gui = Instance.new("ScreenGui")
gui.Name = "AVCB"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() gui.Parent = CoreGui end)
if not gui.Parent and LP then gui.Parent = LP:WaitForChild("PlayerGui") end

local win = Instance.new("Frame")
win.Size = UDim2.fromOffset(340, 404)
win.Position = UDim2.new(0, 24, 0, 90)
win.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
win.BorderSizePixel = 0
win.Active = true
win.Parent = gui
local winCorner = Instance.new("UICorner") winCorner.CornerRadius = UDim.new(0, 10) winCorner.Parent = win
local stroke = Instance.new("UIStroke") stroke.Color = Color3.fromRGB(44, 44, 54) stroke.Parent = win

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 34)
header.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
header.BorderSizePixel = 0
header.Parent = win
local hc = Instance.new("UICorner") hc.CornerRadius = UDim.new(0, 10) hc.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -110, 1, 0)
title.Position = UDim2.fromOffset(12, 0)
title.BackgroundTransparency = 1
title.Text = "ANTI VC BAN  v" .. VERSION
title.TextColor3 = Color3.fromRGB(120, 220, 160)
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local function headerBtn(text, x, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(26, 22)
    b.Position = UDim2.new(1, x, 0, 6)
    b.BackgroundColor3 = Color3.fromRGB(44, 44, 54)
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = Color3.fromRGB(210, 210, 220)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.Parent = header
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 5) c.Parent = b
    b.MouseButton1Click:Connect(cb)
    return b
end

-- dragging
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

------------------------------------------------------------------ log
local logFrame = Instance.new("Frame")
logFrame.Size = UDim2.new(1, -20, 0, 200)
logFrame.Position = UDim2.fromOffset(10, 42)
logFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
logFrame.BorderSizePixel = 0
logFrame.Parent = win
local lc = Instance.new("UICorner") lc.CornerRadius = UDim.new(0, 6) lc.Parent = logFrame
local pad = Instance.new("UIPadding")
pad.PaddingLeft = UDim.new(0, 8) pad.PaddingTop = UDim.new(0, 6) pad.Parent = logFrame

local list = Instance.new("Frame")
list.Size = UDim2.new(1, 0, 1, 0)
list.BackgroundTransparency = 1
list.Parent = logFrame
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 1)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local logCount = 0
local function log(text, color, alsoPrint)
    logCount = logCount + 1
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 13)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color or Color3.fromRGB(160, 160, 172)
    l.Font = Enum.Font.Code
    l.TextSize = 10
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.LayoutOrder = logCount
    l.Parent = list
    if alsoPrint ~= false then pcall(print, "[AVCB] " .. text) end
    if logCount > 15 and list:FindFirstChildWhichIsA("TextLabel") then
        local first = list:FindFirstChildWhichIsA("TextLabel")
        if first and first.LayoutOrder == logCount - 15 then first:Destroy() end
    end
end

local function probe()
    log("---- probe ----", Color3.fromRGB(120, 220, 160))
    local function check(obj, name)
        local ok, v = pcall(function() return obj and obj[name] end)
        local exists = ok and v ~= nil
        log(name .. " -> " .. (exists and typeof(v) or "MISSING"),
            exists and Color3.fromRGB(120, 220, 160) or Color3.fromRGB(230, 130, 130))
    end
    check(VCS, "VCS.JoinVoice")
    check(VCS, "VCS.JoinVoiceChannel")
    check(VCS, "VCS.JoinVoiceChat")
    check(VCS, "VCS.SetMicrophoneMute")
    log("VCI present -> " .. tostring(VCI ~= nil), VCI and Color3.fromRGB(120, 220, 160) or Color3.fromRGB(230, 130, 130))
    if VCI then
        check(VCI, "VCI.JoinVoice")
        check(VCI, "VCI.JoinVoiceChannel")
        check(VCI, "VCI.GetVoiceChatState")
    end
    log("state -> " .. tostring(select(2, pcall(function() return VCI:GetVoiceChatState() end))))
    log("---- end probe ----", Color3.fromRGB(120, 220, 160))
end

------------------------------------------------------------------ buttons
local function actBtn(text, y, color, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -20, 0, 28)
    b.Position = UDim2.fromOffset(10, y)
    b.BackgroundColor3 = color
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = Color3.fromRGB(235, 235, 240)
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 11
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.Parent = win
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = b
    local p = Instance.new("UIPadding") p.PaddingLeft = UDim.new(0, 10) p.Parent = b
    b.MouseButton1Click:Connect(function()
        log("click: " .. text)
        local ok, err = pcall(cb)
        if not ok then log("ERR: " .. tostring(err), Color3.fromRGB(230, 130, 130)) end
    end)
    return b
end

actBtn("Legacy  (F1)", 250, Color3.fromRGB(32, 92, 62), function() startLoop("legacy") end)
actBtn("Modern  (F2)", 282, Color3.fromRGB(34, 60, 96), function() startLoop("modern") end)
actBtn("Stop  (F3)", 314, Color3.fromRGB(48, 48, 58), function() stopLoop() end)
actBtn("Test join  (1x)", 346, Color3.fromRGB(40, 40, 48), function()
    local ok = joinOnce()
    log("test -> " .. State.lastErr, ok and Color3.fromRGB(120, 220, 160) or Color3.fromRGB(230, 130, 130))
end)
actBtn("Unload  (F5)", 378, Color3.fromRGB(60, 34, 34), function()
    if getgenv().AVCB_Unload then getgenv().AVCB_Unload() end
end)

------------------------------------------------------------------ footer
local footer = Instance.new("TextLabel")
footer.Size = UDim2.new(1, -20, 0, 16)
footer.Position = UDim2.new(0, 10, 1, -20)
footer.BackgroundTransparency = 1
footer.Text = "idle"
footer.TextColor3 = Color3.fromRGB(110, 110, 122)
footer.Font = Enum.Font.Gotham
footer.TextSize = 10
footer.TextXAlignment = Enum.TextXAlignment.Left
footer.Parent = win

function render()
    pcall(function()
        footer.Text = string.format("%s · mic %s · joins %d · last %s",
            State.running and (State.mode .. " running") or "idle",
            State.muted and "muted" or "live", State.joins, State.lastErr)
        footer.TextColor3 = State.running and Color3.fromRGB(120, 220, 160) or Color3.fromRGB(110, 110, 122)
    end)
end

task.spawn(function()
    while gui.Parent do
        render()
        task.wait(0.5)
    end
end)

------------------------------------------------------------------ input
local function doAction(a)
    if a == "mute" then setMute(not State.muted)
    elseif a == "legacy" then startLoop("legacy")
    elseif a == "modern" then startLoop("modern")
    elseif a == "stop" then stopLoop()
    elseif a == "hide" and hideWin then hideWin()
    end
end

UIS.InputBegan:Connect(function(input, processed)
    if processed or input.KeyCode == Enum.KeyCode.Unknown then return end
    if capturing then
        Binds[capturing] = input.KeyCode
        capturing = nil
        log("bind -> " .. input.KeyCode.Name)
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
    reopen = Instance.new("TextButton")
    reopen.Size = UDim2.fromOffset(104, 26)
    reopen.Position = UDim2.fromOffset(24, 90)
    reopen.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
    reopen.BorderSizePixel = 0
    reopen.Text = "Anti VC Ban v" .. VERSION
    reopen.TextColor3 = Color3.fromRGB(120, 220, 160)
    reopen.Font = Enum.Font.GothamBold
    reopen.TextSize = 10
    reopen.Parent = gui
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = reopen
    reopen.MouseButton1Click:Connect(function()
        reopen:Destroy() reopen = nil
        win.Visible = true
    end)
end

function getgenv().AVCB_Unload()
    pcall(stopLoop)
    pcall(function() if State.muted then setMute(false) end end)
    gui:Destroy()
    getgenv().AVCB_Loaded = nil
    getgenv().AVCB_Unload = nil
    pcall(print, "[AVCB] unloaded")
end

headerBtn("–", -62, hideWin)
headerBtn("X", -32, function() getgenv().AVCB_Unload() end)

------------------------------------------------------------------ boot
print("[AVCB] v" .. VERSION .. " loaded")
probe()
render()
task.delay(1, function()
    if gui.Parent then
        log("auto-starting legacy...")
        startLoop("legacy")
    end
end)
