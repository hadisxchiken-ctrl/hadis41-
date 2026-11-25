--=====================================================================
--  ANTI VC BAN  v2  |  Legacy + Modern  |  PC keybind + mobile button
--  by hadis  |  Re-execute safe
--  Best on: Potassium / Velocity / Wave / Madium
--  Does NOT work on: Zeno, Xeno, Solara, Volt
--=====================================================================

if getgenv().AVCB_Unload then pcall(getgenv().AVCB_Unload) end
getgenv().AVCB_Loaded = true

local Players      = game:GetService("Players")
local VCS          = game:GetService("VoiceChatService")
local UIS          = game:GetService("UserInputService")
local LP           = Players.LocalPlayer
local VCI
pcall(function() VCI = game:GetService("VoiceChatInternal") end)

local running, thread, muted = false, nil, false
local muteKey = Enum.KeyCode.V
local mode = "legacy"

------------------------------------------------------------------ helpers
local function notify(msg)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Anti VC Ban v2", Text = msg, Duration = 3
        })
    end)
end

local function joinOnce()
    pcall(function() VCS:JoinVoice() end)
end

local function isJoined()
    if not VCI or not VCI.GetVoiceChatState then return nil end
    local ok, state = pcall(VCI.GetVoiceChatState, VCI)
    if not ok then return nil end
    local n = tostring(state)
    return n:find("Joined") ~= nil or n:find("InChannel") ~= nil
end

local function setMute(state)
    muted = state
    local ok = false
    if VCI and VCI.SetMicrophoneMute then
        ok = pcall(VCI.SetMicrophoneMute, VCI, state)
    end
    if not ok then pcall(function() VCS:SetMicrophoneMute(state) end) end
    if not ok then joinOnce() end
end

local function stopLoop()
    running = false
    if thread then pcall(task.cancel, thread) thread = nil end
end

local function startLoop(m)
    stopLoop()
    mode, running = m, true
    thread = task.spawn(function()
        while running do
            if mode == "legacy" then
                joinOnce()
                task.wait(0.75)
            else
                if isJoined() ~= true then joinOnce() end
                task.wait(2)
            end
        end
    end)
    notify("Active (" .. mode .. ")")
end

------------------------------------------------------------------ gui
local gui = Instance.new("ScreenGui")
gui.Name = "AVCB"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(250, 222)
main.Position = UDim2.new(0, 20, 0.5, -111)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 32)
title.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
title.BorderSizePixel = 0
title.Text = "  ANTI VC BAN   v2"
title.TextColor3 = Color3.fromRGB(120, 220, 160)
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

local hideBtn = Instance.new("TextButton")
hideBtn.Size = UDim2.fromOffset(46, 22)
hideBtn.Position = UDim2.new(1, -54, 0, 5)
hideBtn.BackgroundColor3 = Color3.fromRGB(48, 48, 58)
hideBtn.BorderSizePixel = 0
hideBtn.Text = "hide"
hideBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
hideBtn.Font = Enum.Font.GothamMedium
hideBtn.TextSize = 11
hideBtn.Parent = title
Instance.new("UICorner", hideBtn).CornerRadius = UDim.new(0, 5)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 18)
status.Position = UDim2.new(0, 10, 0, 38)
status.BackgroundTransparency = 1
status.Text = "Idle"
status.TextColor3 = Color3.fromRGB(150, 150, 160)
status.Font = Enum.Font.Gotham
status.TextSize = 11
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = main

local function button(text, y, color, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -20, 0, 30)
    b.Position = UDim2.new(0, 10, 0, y)
    b.BackgroundColor3 = color
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = Color3.fromRGB(235, 235, 240)
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 12
    b.Parent = main
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    if cb then b.MouseButton1Click:Connect(cb) end
    return b
end

button("Anti VC Ban  (Legacy)", 62, Color3.fromRGB(32, 92, 62), function()
    startLoop("legacy")
    status.Text = "Legacy running — VC UI will break, use the key."
    status.TextColor3 = Color3.fromRGB(120, 220, 160)
end)

button("Anti VC Ban  (Modern)", 98, Color3.fromRGB(34, 60, 96), function()
    startLoop("modern")
    status.Text = "Modern running — softer, keeps the VC UI."
    status.TextColor3 = Color3.fromRGB(130, 180, 240)
end)

local muteBtn = button("Mute  (key: V)", 134, Color3.fromRGB(48, 48, 58))
local capturing = false
muteBtn.MouseButton1Click:Connect(function()
    capturing = true
    muteBtn.Text = "Press a key..."
end)

-- mobile / tap mute
local tapMute = button("Tap to Mute Mic", 170, Color3.fromRGB(40, 40, 48), function()
    setMute(not muted)
    muteBtn.Text = "Mute  (key: " .. muteKey.Name .. ")"
    status.Text = muted and "Mic muted" or "Mic live"
    status.TextColor3 = muted and Color3.fromRGB(240, 120, 120) or Color3.fromRGB(120, 220, 160)
end)

local unloadBtn = button("Unload", 206, Color3.fromRGB(80, 34, 34))

------------------------------------------------------------------ input
UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    if capturing and input.KeyCode ~= Enum.KeyCode.Unknown then
        capturing = false
        muteKey = input.KeyCode
        muteBtn.Text = "Mute  (key: " .. muteKey.Name .. ")"
        return
    end
    if input.KeyCode == muteKey then
        setMute(not muted)
        status.Text = muted and "Mic muted" or "Mic live"
        status.TextColor3 = muted and Color3.fromRGB(240, 120, 120) or Color3.fromRGB(120, 220, 160)
    end
end)

------------------------------------------------------------------ hide / unload
local hidden = false
hideBtn.MouseButton1Click:Connect(function()
    hidden = not hidden
    main.Visible = false
    if hidden then
        local reopen = Instance.new("TextButton")
        reopen.Name = "AVCB_Reopen"
        reopen.Size = UDim2.fromOffset(96, 26)
        reopen.Position = UDim2.new(0, 20, 0.5, -13)
        reopen.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
        reopen.BorderSizePixel = 0
        reopen.Text = "Anti VC Ban"
        reopen.TextColor3 = Color3.fromRGB(120, 220, 160)
        reopen.Font = Enum.Font.GothamBold
        reopen.TextSize = 11
        reopen.Parent = gui
        Instance.new("UICorner", reopen).CornerRadius = UDim.new(0, 6)
        reopen.MouseButton1Click:Connect(function()
            reopen:Destroy()
            hidden = false
            main.Visible = true
        end)
    end
end)

local function unload()
    stopLoop()
    pcall(function() if muted then setMute(false) end end)
    gui:Destroy()
    getgenv().AVCB_Loaded = nil
    getgenv().AVCB_Unload = nil
end
getgenv().AVCB_Unload = unload
unloadBtn.MouseButton1Click:Connect(unload)

status.Text = "Pick Legacy or Modern."
notify("Loaded v2 — choose a method")
