--[[────────────────────────────────────────────────────────────
    HADIS // M7 ANTI VC BAN + SELF MUTE
    Engine: VoiceChatInternal.PublishPause + StateChanged suppression
    run: loadstring(game:HttpGet("https://raw.githubusercontent.com/hadisxchiken-ctrl/hadis41-/main/hadis.lua"))()
────────────────────────────────────────────────────────────]]

local LOADER_URL = "https://raw.githubusercontent.com/hadisxchiken-ctrl/hadis41-/main/hadis.lua"

local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local VCS          = game:GetService("VoiceChatService")
local VIM          = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local CoreGui      = game:GetService("CoreGui")

local LP = Players.LocalPlayer
local VCI = game:FindService("VoiceChatInternal")

local C = {
    bg = Color3.fromRGB(13, 14, 17), card = Color3.fromRGB(21, 23, 26),
    border = Color3.fromRGB(52, 56, 48), pill = Color3.fromRGB(28, 31, 30),
    lime = Color3.fromRGB(200, 242, 66), limeDim = Color3.fromRGB(96, 118, 44),
    white = Color3.fromRGB(238, 240, 236), muted = Color3.fromRGB(126, 130, 124),
    green = Color3.fromRGB(62, 163, 74), greenBg = Color3.fromRGB(24, 46, 26),
    amber = Color3.fromRGB(217, 119, 6), red = Color3.fromRGB(232, 110, 110),
    track = Color3.fromRGB(58, 62, 58),
}

local host = LP:WaitForChild("PlayerGui")
pcall(function() if gethui then host = gethui() end end)

local function mk(class, par, props)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    o.Parent = par
    return o
end
local function round(o, r) mk("UICorner", o, { CornerRadius = UDim.new(0, r) }) end
local function outline(o, c, t) return mk("UIStroke", o, { Color = c, Thickness = t or 1 }) end

local function draggable(panel, handle)
    local dragging, startPos, startInput
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging, startInput, startPos = true, i.Position, panel.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - startInput
            panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

local gui = mk("ScreenGui", host, {
    Name = "M7AntiVCB", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 999,
})

local toasts = mk("Frame", gui, {
    Size = UDim2.fromOffset(240, 0), Position = UDim2.new(0.5, -120, 1, -28),
    BackgroundTransparency = 1, ZIndex = 400,
})
mk("UIListLayout", toasts, { Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Bottom })

local function notify(msg)
    local t = mk("TextLabel", toasts, {
        Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = C.bg, BackgroundTransparency = 0.1,
        Font = Enum.Font.GothamMedium, TextSize = 11, TextColor3 = C.lime,
        Text = "  " .. msg, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 401,
    })
    round(t, 7)
    outline(t, C.lime, 1)
    task.delay(2.2, function()
        TweenService:Create(t, TweenInfo.new(0.25), { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
        task.wait(0.3)
        t:Destroy()
    end)
end

local function header(par, titleText, order, onMin, onClose)
    local h = mk("Frame", par, { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, LayoutOrder = order })
    mk("TextLabel", h, {
        Size = UDim2.fromOffset(24, 26), BackgroundTransparency = 1, Font = Enum.Font.GothamBold,
        TextSize = 12, TextColor3 = C.lime, Text = "M7", TextXAlignment = Enum.TextXAlignment.Left,
    })
    mk("TextLabel", h, {
        Position = UDim2.fromOffset(24, 0), Size = UDim2.new(1, -140, 0, 26), BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = C.white,
        Text = titleText, TextXAlignment = Enum.TextXAlignment.Left,
    })
    local pill = mk("Frame", h, {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -60, 0, 5),
        Size = UDim2.fromOffset(44, 16), BackgroundColor3 = C.pill, BorderSizePixel = 0,
    })
    round(pill, 4)
    mk("TextLabel", pill, {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.GothamBold,
        TextSize = 8, TextColor3 = C.lime, Text = "Loaded",
    })
    local function hbtn(txt, x, cb)
        local b = mk("TextButton", h, {
            AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, x, 0, 0),
            Size = UDim2.fromOffset(20, 26), BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = C.muted, Text = txt,
        })
        b.MouseButton1Click:Connect(cb)
    end
    hbtn("–", -30, onMin)
    hbtn("×", -8, onClose)
    draggable(par, h)
    return h
end

-- ═══ READ ═══
local function read(name)
    local ok, v = pcall(function() return VCS[name](VCS) end)
    if ok then return v end
end

local function snap()
    return {
        session = read("getInternalSessionId") or "",
        channel = read("getInternalChannelId") or "",
    }
end

local function paused()
    if VCI then
        local ok, v = pcall(function() return VCI:IsPublishPaused() end)
        if ok and type(v) == "boolean" then return v end
    end
    return read("isInternalPublishPaused")
end

local function tail(s)
    if s == nil or s == "" then return "—" end
    return #s > 8 and ("…" .. s:sub(-8)) or s
end

local internalsOK = false
do local s = snap() internalsOK = (s.session ~= "") end

local function pressKey(k)
    pcall(function()
        VIM:SendKeyEvent(true, k, false, game)
        task.wait(0.04)
        VIM:SendKeyEvent(false, k, false, game)
    end)
end

local function vcOff()
    local ok, place = pcall(function() return VCS.VoiceChatEnabledForPlaceOnRcc end)
    return ok and place == false
end

-- ═══ MODAL SCAN ═══
local lastDismiss, lastWarn = 0, 0

local function scanModals()
    local warn, susp, mins
    pcall(function()
        for _, g in ipairs({ CoreGui, LP:FindFirstChild("PlayerGui") }) do
            if g then
                for _, d in ipairs(g:GetDescendants()) do
                    if d:IsA("TextLabel") then
                        local t = d.Text
                        if t and #t < 220 then
                            if t:find("lose access to voice", 1, true) then warn = true end
                            local n = t:match("[Ss]uspended for (%d+)")
                            if n then susp, mins = true, tonumber(n) end
                            if t:find("suspended", 1, true) then susp = true end
                        end
                    end
                end
            end
        end
    end)
    return warn, susp, mins
end

local function clickOk()
    if os.clock() - lastDismiss < 3 then return end
    pcall(function()
        for _, d in ipairs(CoreGui:GetDescendants()) do
            if d:IsA("TextButton") and d.Text == "OK" and d.Visible
            and d.AbsoluteSize.X > 40 and d.AbsoluteSize.Y > 20 then
                local p = d.AbsolutePosition + d.AbsoluteSize / 2
                lastDismiss = os.clock()
                VIM:SendMouseButtonEvent(p.X, p.Y, 0, true, game, 0)
                task.wait(0.06)
                VIM:SendMouseButtonEvent(p.X, p.Y, 0, false, game, 0)
                return
            end
        end
    end)
end

-- ═══ PANEL ═══
local panel = mk("Frame", gui, {
    AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 40, 0.5, 0),
    Size = UDim2.fromOffset(330, 0), AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundColor3 = C.bg, BorderSizePixel = 0,
})
round(panel, 10)
outline(panel, C.border, 1)
mk("UIPadding", panel, {
    PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 12),
    PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
})
mk("UIListLayout", panel, {
    Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
})

local body = {}
local function section(text, order)
    local row = mk("Frame", panel, { Size = UDim2.new(1, 0, 0, 15), BackgroundTransparency = 1, LayoutOrder = order })
    mk("Frame", row, { Size = UDim2.fromOffset(3, 10), Position = UDim2.fromOffset(0, 3),
        BackgroundColor3 = C.lime, BorderSizePixel = 0 })
    mk("TextLabel", row, {
        Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -8, 1, 0), BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold, TextSize = 9, TextColor3 = C.lime,
        Text = text, TextXAlignment = Enum.TextXAlignment.Left,
    })
    return row
end

table.insert(body, header(panel, "ANTI VC BAN", 1, function()
    for _, o in ipairs(body) do o.Visible = not o.Visible end
end, function() gui:Destroy() end))

table.insert(body, section("STATUS", 2))

local statusCard = mk("Frame", panel, {
    Size = UDim2.new(1, 0, 0, 54), BackgroundColor3 = C.card, BorderSizePixel = 0, LayoutOrder = 3,
})
round(statusCard, 8)
outline(statusCard, C.limeDim, 1)
table.insert(body, statusCard)

local halo = mk("Frame", statusCard, {
    Position = UDim2.fromOffset(7, 17), Size = UDim2.fromOffset(20, 20),
    BackgroundColor3 = C.muted, BackgroundTransparency = 0.86, BorderSizePixel = 0,
})
round(halo, 10)
local dot = mk("Frame", statusCard, {
    Position = UDim2.fromOffset(12, 22), Size = UDim2.fromOffset(10, 10),
    BackgroundColor3 = C.muted, BorderSizePixel = 0,
})
round(dot, 5)

local statusTitle = mk("TextLabel", statusCard, {
    Position = UDim2.fromOffset(32, 9), Size = UDim2.new(1, -100, 0, 17), BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.muted, Text = "IDLE",
    TextXAlignment = Enum.TextXAlignment.Left,
})
local statusSub = mk("TextLabel", statusCard, {
    Position = UDim2.fromOffset(32, 27), Size = UDim2.new(1, -80, 0, 16), BackgroundTransparency = 1,
    Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = C.muted, Text = "Unmute first, then START.",
    TextXAlignment = Enum.TextXAlignment.Left,
})
local refreshBtn = mk("TextButton", statusCard, {
    AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0),
    Size = UDim2.fromOffset(54, 20), BackgroundColor3 = C.card, BorderSizePixel = 0,
    Font = Enum.Font.GothamBold, TextSize = 8, TextColor3 = C.muted, Text = "REFRESH",
})
round(refreshBtn, 5)
outline(refreshBtn, C.border, 1)

table.insert(body, section("DIAGNOSTICS", 4))

local diagCard = mk("Frame", panel, {
    Size = UDim2.new(1, 0, 0, 76), BackgroundColor3 = C.card, BorderSizePixel = 0, LayoutOrder = 5,
})
round(diagCard, 8)
outline(diagCard, C.border, 1)
table.insert(body, diagCard)

local function diagRow(label, y)
    mk("TextLabel", diagCard, {
        Position = UDim2.fromOffset(10, y), Size = UDim2.fromOffset(90, 12), BackgroundTransparency = 1,
        Font = Enum.Font.Gotham, TextSize = 9, TextColor3 = C.muted,
        Text = label, TextXAlignment = Enum.TextXAlignment.Left,
    })
    return mk("TextLabel", diagCard, {
        Position = UDim2.fromOffset(100, y), Size = UDim2.new(1, -110, 0, 12), BackgroundTransparency = 1,
        Font = Enum.Font.Code, TextSize = 9, TextColor3 = C.white,
        Text = "—", TextXAlignment = Enum.TextXAlignment.Left,
    })
end

local diagSession = diagRow("session", 6)
local diagChannel = diagRow("channel", 18)
local diagMic     = diagRow("mic", 30)
local diagIntern  = diagRow("internals", 42)
local diagVci     = diagRow("vci", 54)
local diagHooks   = diagRow("suppressed", 66)

local btnRow = mk("Frame", panel, { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, LayoutOrder = 6 })
table.insert(body, btnRow)

local startBtn = mk("TextButton", btnRow, {
    Size = UDim2.new(0.62, -3, 1, 0), BackgroundColor3 = C.greenBg, BorderSizePixel = 0,
    Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = C.lime, Text = "START",
})
round(startBtn, 7)
outline(startBtn, C.green, 1)

local unmuteBtn = mk("TextButton", btnRow, {
    Position = UDim2.new(0.62, 3, 0, 0), Size = UDim2.new(0.38, -3, 1, 0),
    BackgroundColor3 = C.card, BorderSizePixel = 0, Font = Enum.Font.GothamBold,
    TextSize = 10, TextColor3 = C.white, Text = "UNMUTE",
})
round(unmuteBtn, 7)
outline(unmuteBtn, C.border, 1)

local footer = mk("TextLabel", panel, {
    Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, Font = Enum.Font.Gotham,
    TextSize = 8, TextColor3 = C.muted, LayoutOrder = 20,
    Text = "Auto 20s · warning = auto-mute · V to mute",
})
table.insert(body, footer)

-- ═══ STATE ═══
local active, injecting = false, false
local muted = false
local muteKey = Enum.KeyCode.V
local listeningKey = false
local selfPanel, inject
local suspendUntil, lastRetry = nil, 0
local suppressed = {}
local ownConn

local function setStatus(title, color, sub)
    statusTitle.Text = title
    statusTitle.TextColor3 = color
    dot.BackgroundColor3 = color
    halo.BackgroundColor3 = color
    if sub then statusSub.Text = sub end
end

local function pulse()
    task.spawn(function()
        while active and dot.Parent do
            TweenService:Create(halo, TweenInfo.new(1.1), {
                Size = UDim2.fromOffset(26, 26), BackgroundTransparency = 0.7 }):Play()
            task.wait(1.1)
            if not active then break end
            TweenService:Create(halo, TweenInfo.new(1.1), {
                Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 0.86 }):Play()
            task.wait(1.1)
        end
    end)
end

-- ═══ MUTE ═══
local function publishPause(state)
    if VCI then
        local ok = pcall(function() VCI:PublishPause(state) end)
        if ok then return true end
    end
    return false
end

local function forceUnmute()
    muted = false
    if not publishPause(false) then pressKey(muteKey) end
end

local function setMute(want)
    muted = want
    if not publishPause(want) then
        pressKey(muteKey)
        return true, "key"
    end
    task.wait(0.15)
    local p = paused()
    if p == nil then return true, "vci sent" end
    if p == want then return true, "vci verified" end
    return false, "vci no change"
end

-- ═══ SUPPRESSION ═══
local function suppress()
    if not VCI or not getconnections then return false end
    suppressed = {}
    pcall(function()
        for _, conn in pairs(getconnections(VCI.StateChanged)) do
            local ok = pcall(function() conn:Disable() end)
            if ok then table.insert(suppressed, conn) end
        end
    end)
    return #suppressed > 0
end

local function restore()
    for _, conn in pairs(suppressed) do pcall(function() conn:Enable() end) end
    suppressed = {}
    if ownConn then pcall(function() ownConn:Disconnect() end) ownConn = nil end
end

-- ═══ THE METHOD ═══
local function bypass()
    if not VCI then return false, "VoiceChatInternal missing" end
    local before = snap()
    local confirmed = false

    publishPause(false)
    task.wait(3.5)

    pcall(function() VCS:leaveVoice() end)
    task.wait(2)

    suppress()

    ownConn = VCI.StateChanged:Connect(function(_, new)
        if tostring(new):find("Joined") then confirmed = true end
        if not muted then publishPause(false) end
    end)

    pcall(function() VCS:joinVoice() end)
    task.wait(3)

    local after = snap()
    if after.session == "" then
        restore()
        return false, "rejoin did not take"
    end
    local kept = (before.session ~= "" and after.session ~= before.session)
    if not confirmed and not kept then
        return true, "joined, unconfirmed", false
    end
    return true, confirmed and "join confirmed" or "session rebuilt", true
end

-- ═══ SELF MUTE PANEL ═══
local selfMicText, selfMicBody, selfMicBar, selfMicStem, selfCount, selfTier

local function buildSelf()
    if selfPanel then selfPanel.Visible = true return end

    local m = mk("Frame", gui, {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 40, 0.5, 214),
        Size = UDim2.fromOffset(320, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = C.bg, BorderSizePixel = 0, BackgroundTransparency = 1,
    })
    round(m, 10)
    local mStroke = outline(m, C.border, 1)
    mStroke.Transparency = 1
    mk("UIPadding", m, {
        PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
    })
    mk("UIListLayout", m, { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })

    local mbody = {}
    table.insert(mbody, header(m, "SELF MUTE", 1, function()
        for _, o in ipairs(mbody) do o.Visible = not o.Visible end
    end, function() m.Visible = false end))

    local micRow = mk("Frame", m, { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, LayoutOrder = 2 })
    table.insert(mbody, micRow)

    selfMicBody = mk("Frame", micRow, { Position = UDim2.fromOffset(2, 2),
        Size = UDim2.fromOffset(8, 12), BackgroundColor3 = C.green, BorderSizePixel = 0 })
    round(selfMicBody, 4)
    selfMicBar = mk("Frame", micRow, { Position = UDim2.fromOffset(1, 13),
        Size = UDim2.fromOffset(10, 2), BackgroundColor3 = C.green, BorderSizePixel = 0 })
    selfMicStem = mk("Frame", micRow, { Position = UDim2.fromOffset(5, 14),
        Size = UDim2.fromOffset(2, 5), BackgroundColor3 = C.green, BorderSizePixel = 0 })

    selfMicText = mk("TextLabel", micRow, {
        Position = UDim2.fromOffset(20, 0), Size = UDim2.new(1, -60, 0, 13), BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium, TextSize = 11, TextColor3 = C.white,
        Text = "click to mute", TextXAlignment = Enum.TextXAlignment.Left })
    selfTier = mk("TextLabel", micRow, {
        Position = UDim2.fromOffset(20, 14), Size = UDim2.new(1, -60, 0, 11), BackgroundTransparency = 1,
        Font = Enum.Font.Code, TextSize = 7, TextColor3 = C.muted, Text = "via PublishPause" })
    selfCount = mk("TextLabel", micRow, {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 2), Size = UDim2.fromOffset(28, 24),
        BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 11,
        TextColor3 = C.green, Text = "—" })
    local micBtn = mk("TextButton", micRow, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "" })

    local keyRow = mk("Frame", m, { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, LayoutOrder = 3 })
    table.insert(mbody, keyRow)
    mk("TextLabel", keyRow, {
        Size = UDim2.new(1, -80, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.Gotham,
        TextSize = 10, TextColor3 = C.muted, Text = "mute key", TextXAlignment = Enum.TextXAlignment.Left })
    local keyBox = mk("TextButton", keyRow, {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.fromOffset(64, 22), BackgroundColor3 = C.card, BorderSizePixel = 0, Text = "" })
    round(keyBox, 5)
    outline(keyBox, C.border, 1)
    local keyLabel = mk("TextLabel", keyBox, {
        Position = UDim2.fromOffset(8, 0), Size = UDim2.fromOffset(28, 22), BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = C.lime,
        Text = muteKey.Name:sub(1, 3), TextXAlignment = Enum.TextXAlignment.Left })

    mk("Frame", m, { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.border,
        BackgroundTransparency = 0.5, BorderSizePixel = 0, LayoutOrder = 4 })

    local function toggleRow(text, order, cb)
        local row = mk("Frame", m, { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, LayoutOrder = order })
        table.insert(mbody, row)
        mk("TextLabel", row, {
            Size = UDim2.new(1, -50, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.Gotham,
            TextSize = 10, TextColor3 = C.white, Text = text, TextXAlignment = Enum.TextXAlignment.Left })
        local track = mk("TextButton", row, {
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.fromOffset(34, 18), BackgroundColor3 = C.track, BorderSizePixel = 0, Text = "" })
        round(track, 9)
        local knob = mk("Frame", track, { Position = UDim2.fromOffset(2, 2),
            Size = UDim2.fromOffset(14, 14), BackgroundColor3 = C.white, BorderSizePixel = 0 })
        round(knob, 7)
        local on = false
        track.MouseButton1Click:Connect(function()
            on = not on
            cb(on)
            TweenService:Create(knob, TweenInfo.new(0.12), {
                Position = on and UDim2.fromOffset(18, 2) or UDim2.fromOffset(2, 2) }):Play()
            TweenService:Create(track, TweenInfo.new(0.12), {
                BackgroundColor3 = on and C.green or C.track }):Play()
        end)
    end

    local pushTalk, pushMute = false, false
    toggleRow("push to talk (hold to unmute)", 5, function(on) pushTalk = on if on then pushMute = false end end)
    toggleRow("push to mute (hold to mute)", 6, function(on) pushMute = on if on then pushTalk = false end end)

    mk("Frame", m, { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.border,
        BackgroundTransparency = 0.5, BorderSizePixel = 0, LayoutOrder = 7 })

    table.insert(mbody, mk("TextLabel", m, {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
        Font = Enum.Font.Gotham, TextSize = 9, TextColor3 = C.muted, TextWrapped = true, LayoutOrder = 8,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
        Text = "Getting warnings can be normal. You will not lose voice chat privileges from this by itself. Avoid being reported by players.",
    }))

    local function refreshMic()
        local col = muted and C.muted or C.green
        selfMicBody.BackgroundColor3 = col
        selfMicBar.BackgroundColor3 = col
        selfMicStem.BackgroundColor3 = col
        selfMicText.Text = muted and "click to unmute" or "click to mute"
    end

    local function doMute(want)
        local ok, why = setMute(want)
        refreshMic()
        selfTier.Text = "via " .. why
        selfCount.Text = muted and "10" or "—"
        if not ok then selfCount.Text = "!" notify("mute failed: " .. why) end
        if muted then
            task.spawn(function()
                for i = 10, 0, -1 do
                    if not muted or not m.Visible then return end
                    selfCount.Text = tostring(i)
                    task.wait(1)
                end
            end)
        end
    end

    micBtn.MouseButton1Click:Connect(function() doMute(not muted) end)
    keyBox.MouseButton1Click:Connect(function()
        listeningKey = true
        keyLabel.Text = "..."
        keyLabel.TextColor3 = C.muted
    end)

    TweenService:Create(m, TweenInfo.new(0.25), { BackgroundTransparency = 0.02 }):Play()
    TweenService:Create(mStroke, TweenInfo.new(0.25), { Transparency = 0 }):Play()

    selfPanel = m

    m:SetAttribute("pushTalk", false)
    m:SetAttribute("pushMute", false)
    return m
end

-- ═══ INJECT ═══
inject = function()
    if injecting then return end
    injecting = true
    setStatus("TESTING", C.amber, "Preparing bypass...")

    if vcOff() then
        injecting = false
        setStatus("NO VOICE", C.red, "Voice chat is off in this game.")
        return
    end

    local ok, detail, verified = pcall(bypass)
    injecting = false

    if not ok then
        active = false
        setStatus("FAILED", C.red, tostring(detail):sub(1, 44))
        notify("bypass failed")
        return
    end

    active = true
    if verified then
        setStatus("ACTIVE", C.lime, "Verified · " .. tostring(detail))
        pulse()
        notify("bypass active")
    else
        setStatus("UNVERIFIED", C.amber, "Ran, but " .. tostring(detail))
    end

    task.wait(0.6)
    buildSelf()
end

startBtn.MouseButton1Click:Connect(function() task.spawn(function() inject() end) end)
refreshBtn.MouseButton1Click:Connect(function() task.spawn(function() inject() end) end)
unmuteBtn.MouseButton1Click:Connect(function()
    forceUnmute()
    task.wait(0.25)
    local p = paused()
    local live = (p == false)
    setStatus(live and "ACTIVE" or "UNVERIFIED", live and C.lime or C.amber,
        live and "Forced unmute" or "Still paused — try V")
    notify(live and "unmuted" or "unmute failed")
end)

-- ═══ WATCHER ═══
task.spawn(function()
    while gui.Parent do
        task.wait(2)
        local warn, susp, mins = scanModals()

        if susp then
            clickOk()
            if mins and not suspendUntil then suspendUntil = os.clock() + mins * 60 end
            active = false
            local left = suspendUntil and math.max(0, math.ceil(suspendUntil - os.clock()))
            setStatus("SUSPENDED", C.red,
                left and ("lifts in " .. left .. "s — auto rejoin armed") or "suspended — retrying")
            if os.clock() - lastRetry > 8 then
                lastRetry = os.clock()
                local ok = pcall(function() VCS:rejoinVoice() end)
                if ok and snap().session ~= "" then
                    suspendUntil = nil
                    restore()
                    forceUnmute()
                    setStatus("ACTIVE", C.lime, "Recovered — rejoined")
                    notify("voice recovered")
                end
            end
        elseif warn then
            clickOk()
            if os.clock() - lastWarn > 5 then
                lastWarn = os.clock()
                setMute(true)
                setStatus("WARNING", C.amber, "Auto-muted to stop escalation")
                notify("warning — auto-muted")
            end
        elseif suspendUntil then
            suspendUntil = nil
        end
    end
end)

-- ═══ DIAG ═══
task.spawn(function()
    while gui.Parent do
        local s = snap()
        diagSession.Text = tail(s.session)
        diagChannel.Text = tail(s.channel)
        local p = paused()
        diagMic.Text = p == nil and "blocked" or (p and "paused" or "live")
        diagMic.TextColor3 = p == nil and C.muted or (p and C.amber or C.green)
        diagIntern.Text = internalsOK and "readable" or "blocked"
        diagIntern.TextColor3 = internalsOK and C.green or C.red
        diagVci.Text = VCI and "found" or "missing"
        diagVci.TextColor3 = VCI and C.green or C.red
        diagHooks.Text = tostring(#suppressed)
        diagHooks.TextColor3 = #suppressed > 0 and C.green or C.muted
        task.wait(2)
    end
end)

-- ═══ KEYS ═══
UIS.InputBegan:Connect(function(i, processed)
    if listeningKey and i.KeyCode ~= Enum.KeyCode.Unknown then
        muteKey = i.KeyCode
        listeningKey = false
        notify("mute key: " .. i.KeyCode.Name)
        if selfPanel then
            for _, d in ipairs(selfPanel:GetDescendants()) do
                if d:IsA("TextLabel") and d.Text == "..." then
                    d.Text = i.KeyCode.Name:sub(1, 3)
                    d.TextColor3 = C.lime
                end
            end
        end
        return
    end
    if processed or i.KeyCode ~= muteKey then return end
    muted = not muted
    setMute(muted)
end)

-- ═══ AUTO ═══
task.spawn(function()
    while gui.Parent do
        task.wait(20)
        if active and not suspendUntil then
            if vcOff() then statusSub.Text = "Voice chat is off in this game."
            elseif not muted then publishPause(false) end
        end
    end
end)

if queue_on_teleport then
    pcall(function()
        queue_on_teleport('loadstring(game:HttpGet("' .. LOADER_URL .. '"))()')
    end)
end

task.delay(0.6, function()
    notify(VCI and "VCI found — unmute first, then START" or "VCI missing on this executor")
end)
