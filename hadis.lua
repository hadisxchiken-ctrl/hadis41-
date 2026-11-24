--[[────────────────────────────────────────────────────────────
    HADIS // M7 ANTI VC BAN + SELF MUTE
    run: loadstring(game:HttpGet("https://raw.githubusercontent.com/hadisxchiken-ctrl/hadis41-/main/hadis.lua"))()
    APIs verified against Roblox API dump v0.747
────────────────────────────────────────────────────────────]]

local LOADER_URL = "https://raw.githubusercontent.com/hadisxchiken-ctrl/hadis41-/main/hadis.lua"

local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local VCS          = game:GetService("VoiceChatService")
local VIM          = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")

local LP = Players.LocalPlayer

local C = {
    bg      = Color3.fromRGB(13, 14, 17),
    card    = Color3.fromRGB(21, 23, 26),
    border  = Color3.fromRGB(52, 56, 48),
    pill    = Color3.fromRGB(28, 31, 30),
    lime    = Color3.fromRGB(200, 242, 66),
    limeDim = Color3.fromRGB(96, 118, 44),
    white   = Color3.fromRGB(238, 240, 236),
    muted   = Color3.fromRGB(126, 130, 124),
    green   = Color3.fromRGB(62, 163, 74),
    greenBg = Color3.fromRGB(24, 46, 26),
    blue    = Color3.fromRGB(59, 130, 246),
    amber   = Color3.fromRGB(217, 119, 6),
    red     = Color3.fromRGB(232, 110, 110),
    track   = Color3.fromRGB(58, 62, 58),
}

local host = LP:WaitForChild("PlayerGui")
pcall(function() if gethui then host = gethui() end end)

local function mk(class, par, props)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    o.Parent = par
    return o
end

local function round(o, r)
    mk("UICorner", o, { CornerRadius = UDim.new(0, r) })
end

local function outline(o, color, thickness)
    return mk("UIStroke", o, { Color = color, Thickness = thickness or 1 })
end

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
            panel.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

local gui = mk("ScreenGui", host, {
    Name = "M7AntiVCB", ResetOnSpawn = false,
    IgnoreGuiInset = true, DisplayOrder = 999,
})

-- toast
local toasts = mk("Frame", gui, {
    Size = UDim2.fromOffset(240, 0), Position = UDim2.new(0.5, -120, 1, -28),
    BackgroundTransparency = 1, ZIndex = 400,
})
mk("UIListLayout", toasts, {
    Padding = UDim.new(0, 6),
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
})

local function notify(msg)
    local t = mk("TextLabel", toasts, {
        Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = C.bg,
        BackgroundTransparency = 0.1, Font = Enum.Font.GothamMedium,
        TextSize = 11, TextColor3 = C.lime, Text = "  " .. msg,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 401,
    })
    round(t, 7)
    outline(t, C.lime, 1)
    task.delay(2.2, function()
        TweenService:Create(t, TweenInfo.new(0.25), {
            BackgroundTransparency = 1, TextTransparency = 1,
        }):Play()
        task.wait(0.3)
        t:Destroy()
    end)
end

-- shared header
local function header(par, titleText, order, onMin, onClose)
    local h = mk("Frame", par, {
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundTransparency = 1, LayoutOrder = order,
    })
    mk("TextLabel", h, {
        Size = UDim2.fromOffset(24, 26), BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.lime,
        Text = "M7", TextXAlignment = Enum.TextXAlignment.Left,
    })
    mk("TextLabel", h, {
        Position = UDim2.fromOffset(24, 0), Size = UDim2.new(1, -140, 0, 26),
        BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 11,
        TextColor3 = C.white, Text = titleText, TextXAlignment = Enum.TextXAlignment.Left,
    })
    local pill = mk("Frame", h, {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -60, 0, 5),
        Size = UDim2.fromOffset(44, 16), BackgroundColor3 = C.pill, BorderSizePixel = 0,
    })
    round(pill, 4)
    mk("TextLabel", pill, {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold, TextSize = 8, TextColor3 = C.lime, Text = "Loaded",
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

-- ═══ MAIN PANEL ═══
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
    local row = mk("Frame", panel, {
        Size = UDim2.new(1, 0, 0, 15), BackgroundTransparency = 1, LayoutOrder = order,
    })
    mk("Frame", row, {
        Size = UDim2.fromOffset(3, 10), Position = UDim2.fromOffset(0, 3),
        BackgroundColor3 = C.lime, BorderSizePixel = 0,
    })
    mk("TextLabel", row, {
        Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -8, 1, 0),
        BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 9,
        TextColor3 = C.lime, Text = text, TextXAlignment = Enum.TextXAlignment.Left,
    })
    return row
end

table.insert(body, header(panel, "ANTI VC BAN", 1, function()
    for _, o in ipairs(body) do o.Visible = not o.Visible end
end, function() gui:Destroy() end))

table.insert(body, section("STATUS", 2))

local statusCard = mk("Frame", panel, {
    Size = UDim2.new(1, 0, 0, 54), BackgroundColor3 = C.card,
    BorderSizePixel = 0, LayoutOrder = 3,
})
round(statusCard, 8)
outline(statusCard, C.limeDim, 1)
table.insert(body, statusCard)

local halo = mk("Frame", statusCard, {
    Position = UDim2.fromOffset(7, 17), Size = UDim2.fromOffset(20, 20),
    BackgroundColor3 = C.lime, BackgroundTransparency = 0.86, BorderSizePixel = 0,
})
round(halo, 10)

local dot = mk("Frame", statusCard, {
    Position = UDim2.fromOffset(12, 22), Size = UDim2.fromOffset(10, 10),
    BackgroundColor3 = C.muted, BorderSizePixel = 0,
})
round(dot, 5)

local statusTitle = mk("TextLabel", statusCard, {
    Position = UDim2.fromOffset(32, 9), Size = UDim2.new(1, -60, 0, 17),
    BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12,
    TextColor3 = C.muted, Text = "IDLE", TextXAlignment = Enum.TextXAlignment.Left,
})

local statusSub = mk("TextLabel", statusCard, {
    Position = UDim2.fromOffset(32, 27), Size = UDim2.new(1, -54, 0, 16),
    BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 10,
    TextColor3 = C.muted, Text = "Not injected yet.",
    TextXAlignment = Enum.TextXAlignment.Left,
})

local refreshBtn = mk("TextButton", statusCard, {
    AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0),
    Size = UDim2.fromOffset(24, 24), BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = C.muted, Text = "⟳",
})

table.insert(body, section("METHOD", 4))

local METHODS = {
    {
        name = "Legacy Anti VC Ban", short = "Legacy",
        tag = "RECOMMENDED", edge = C.green, titleColor = C.white,
        desc = "This is the newly designed Anti VC Ban. Recommended for all.",
        fn = function() pcall(function() VCS:rejoinVoice() end) end,
    },
    {
        name = "Original Anti VC", short = "Original",
        tag = "DEFAULT", edge = C.blue, titleColor = C.white,
        desc = "This is the original Anti VC Ban. Recommended for lower-end devices, less demanding.",
        fn = function()
            pcall(function() VCS:leaveVoice() end)
            task.wait(0.35)
            pcall(function() VCS:joinVoice() end)
        end,
    },
    {
        name = "Revised Anti VC Ban", short = "Revised",
        tag = "EXPERIMENTAL", edge = C.amber, titleColor = C.amber,
        desc = "Uses Roblox's voice chat muting systems. Least demanding, yet buggy at times.",
        fn = function()
            local sid
            pcall(function() sid = VCS:getInternalSessionId() end)
            if not sid then return end
            pcall(function() VCS:PublishStateChange(Enum.MuteState.Muted, sid) end)
            task.wait(0.15)
            pcall(function() VCS:PublishStateChange(Enum.MuteState.Unmuted, sid) end)
        end,
    },
}

local cards, selected = {}, 1

local function paint()
    for i, c in ipairs(cards) do
        local on = (i == selected)
        c.inner.Visible = on
        c.cardStroke.Color = on and C.lime or c.data.edge
        if on then
            c.btn.BackgroundColor3 = C.greenBg
            c.btn.TextColor3 = C.lime
            c.btn.Text = "ACTIVE"
        else
            c.btn.BackgroundColor3 = C.card
            c.btn.TextColor3 = c.data.edge
            c.btn.Text = "SELECT"
        end
    end
    if statusTitle.Text == "ACTIVE" then
        statusSub.Text = "Using " .. METHODS[selected].short .. " method."
    end
end

for i, data in ipairs(METHODS) do
    local card = mk("Frame", panel, {
        Size = UDim2.new(1, 0, 0, 76), BackgroundColor3 = C.card,
        BorderSizePixel = 0, LayoutOrder = 4 + i,
    })
    round(card, 8)
    local cardStroke = outline(card, data.edge, 1)
    table.insert(body, card)

    mk("Frame", card, {
        Size = UDim2.fromOffset(3, 76), BackgroundColor3 = data.edge, BorderSizePixel = 0,
    })

    local radio = mk("Frame", card, {
        Position = UDim2.fromOffset(13, 14), Size = UDim2.fromOffset(14, 14),
        BackgroundTransparency = 1, BorderSizePixel = 0,
    })
    round(radio, 7)
    outline(radio, data.edge, 2)
    local inner = mk("Frame", radio, {
        Size = UDim2.fromOffset(6, 6), Position = UDim2.fromOffset(4, 4),
        BackgroundColor3 = C.lime, BorderSizePixel = 0, Visible = false,
    })
    round(inner, 3)

    mk("TextLabel", card, {
        Position = UDim2.fromOffset(35, 9), Size = UDim2.new(1, -140, 0, 15),
        BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 11,
        TextColor3 = data.titleColor, Text = data.name,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local badge = mk("Frame", card, {
        Position = UDim2.fromOffset(35, 26),
        Size = UDim2.fromOffset(#data.tag * 5 + 12, 14),
        BackgroundColor3 = C.pill, BorderSizePixel = 0,
    })
    round(badge, 4)
    mk("TextLabel", badge, {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold, TextSize = 8, TextColor3 = data.edge, Text = data.tag,
    })

    mk("TextLabel", card, {
        Position = UDim2.fromOffset(35, 44), Size = UDim2.new(1, -110, 0, 24),
        BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 9,
        TextColor3 = C.muted, Text = data.desc, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
    })

    local btn = mk("TextButton", card, {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 14),
        Size = UDim2.fromOffset(60, 28), BackgroundColor3 = C.card,
        BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 10,
        TextColor3 = data.edge, Text = "SELECT",
    })
    round(btn, 6)
    outline(btn, data.edge, 1)

    table.insert(cards, { cardStroke = cardStroke, inner = inner, btn = btn, data = data })

    btn.MouseButton1Click:Connect(function()
        selected = i
        paint()
        if statusTitle.Text == "ACTIVE" then
            statusSub.Text = "Switching to " .. METHODS[i].short .. "..."
            task.spawn(METHODS[i].fn)
        end
    end)
end

local footer = mk("TextLabel", panel, {
    Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1,
    Font = Enum.Font.Gotham, TextSize = 8, TextColor3 = C.muted,
    Text = "Auto refresh every 20s  ·  press V to mute", LayoutOrder = 20,
})
table.insert(body, footer)

paint()

-- ═══ STATE ═══
local active = false
local injecting = false
local muted = false
local pushTalk, pushMute = false, false
local muteKey = Enum.KeyCode.V
local listeningKey = false
local sessionId
local selfPanel

local function pulse()
    task.spawn(function()
        while active and dot.Parent do
            TweenService:Create(halo, TweenInfo.new(1.1), {
                Size = UDim2.fromOffset(26, 26), BackgroundTransparency = 0.7,
            }):Play()
            task.wait(1.1)
            if not active then break end
            TweenService:Create(halo, TweenInfo.new(1.1), {
                Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 0.86,
            }):Play()
            task.wait(1.1)
        end
    end)
end

local function pressKey(k)
    pcall(function()
        VIM:SendKeyEvent(true, k, false, game)
        task.wait(0.04)
        VIM:SendKeyEvent(false, k, false, game)
    end)
end

local function applyMute(state)
    local ok = pcall(function()
        if not sessionId then error("no session") end
        VCS:PublishStateChange(
            state and Enum.MuteState.Muted or Enum.MuteState.Unmuted, sessionId)
    end)
    if not ok then pressKey(muteKey) end
end

local function vcOff()
    local ok, place = pcall(function() return VCS.VoiceChatEnabledForPlaceOnRcc end)
    return ok and place == false
end

-- ═══ SELF MUTE PANEL ═══
local function buildSelf()
    if selfPanel then
        selfPanel.Visible = true
        return
    end

    local m = mk("Frame", gui, {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 40, 0.5, 210),
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

    local micRow = mk("Frame", m, {
        Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, LayoutOrder = 2,
    })
    table.insert(mbody, micRow)

    local micBody = mk("Frame", micRow, {
        Position = UDim2.fromOffset(2, 2), Size = UDim2.fromOffset(8, 12),
        BackgroundColor3 = C.green, BorderSizePixel = 0,
    })
    round(micBody, 4)
    local micBar = mk("Frame", micRow, {
        Position = UDim2.fromOffset(1, 13), Size = UDim2.fromOffset(10, 2),
        BackgroundColor3 = C.green, BorderSizePixel = 0,
    })
    local micStem = mk("Frame", micRow, {
        Position = UDim2.fromOffset(5, 14), Size = UDim2.fromOffset(2, 5),
        BackgroundColor3 = C.green, BorderSizePixel = 0,
    })

    local micText = mk("TextLabel", micRow, {
        Position = UDim2.fromOffset(20, 0), Size = UDim2.new(1, -60, 1, 0),
        BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 11,
        TextColor3 = C.white, Text = "click to mute", TextXAlignment = Enum.TextXAlignment.Left,
    })

    local countLabel = mk("TextLabel", micRow, {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.fromOffset(28, 24), BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = C.green, Text = "—",
    })

    local clickArea = mk("TextButton", micRow, {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "",
    })

    local keyRow = mk("Frame", m, {
        Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, LayoutOrder = 3,
    })
    table.insert(mbody, keyRow)
    mk("TextLabel", keyRow, {
        Size = UDim2.new(1, -80, 1, 0), BackgroundTransparency = 1,
        Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = C.muted,
        Text = "mute key", TextXAlignment = Enum.TextXAlignment.Left,
    })
    local keyBox = mk("TextButton", keyRow, {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.fromOffset(64, 22), BackgroundColor3 = C.card,
        BorderSizePixel = 0, Text = "",
    })
    round(keyBox, 5)
    outline(keyBox, C.border, 1)
    local keyLabel = mk("TextLabel", keyBox, {
        Position = UDim2.fromOffset(8, 0), Size = UDim2.fromOffset(28, 22),
        BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 11,
        TextColor3 = C.lime, Text = "V", TextXAlignment = Enum.TextXAlignment.Left,
    })

    mk("Frame", m, {
        Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.border,
        BackgroundTransparency = 0.5, BorderSizePixel = 0, LayoutOrder = 4,
    })

    local function toggleRow(text, order, cb)
        local row = mk("Frame", m, {
            Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, LayoutOrder = order,
        })
        table.insert(mbody, row)
        mk("TextLabel", row, {
            Size = UDim2.new(1, -50, 1, 0), BackgroundTransparency = 1,
            Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = C.white,
            Text = text, TextXAlignment = Enum.TextXAlignment.Left,
        })
        local track = mk("TextButton", row, {
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.fromOffset(34, 18), BackgroundColor3 = C.track,
            BorderSizePixel = 0, Text = "",
        })
        round(track, 9)
        local knob = mk("Frame", track, {
            Position = UDim2.fromOffset(2, 2), Size = UDim2.fromOffset(14, 14),
            BackgroundColor3 = C.white, BorderSizePixel = 0,
        })
        round(knob, 7)
        local on = false
        track.MouseButton1Click:Connect(function()
            on = not on
            cb(on)
            TweenService:Create(knob, TweenInfo.new(0.12), {
                Position = on and UDim2.fromOffset(18, 2) or UDim2.fromOffset(2, 2),
            }):Play()
            TweenService:Create(track, TweenInfo.new(0.12), {
                BackgroundColor3 = on and C.green or C.track,
            }):Play()
        end)
    end

    toggleRow("push to talk (hold to unmute)", 5, function(on)
        pushTalk = on
        if on then pushMute = false end
    end)
    toggleRow("push to mute (hold to mute)", 6, function(on)
        pushMute = on
        if on then pushTalk = false end
    end)

    mk("Frame", m, {
        Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.border,
        BackgroundTransparency = 0.5, BorderSizePixel = 0, LayoutOrder = 7,
    })

    table.insert(mbody, mk("TextLabel", m, {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 9,
        TextColor3 = C.muted, TextWrapped = true, LayoutOrder = 8,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
        Text = "Getting warnings can be normal. You will not lose voice chat privileges from this by itself. Avoid being reported by players.",
    }))

    local function setMute(state)
        muted = state
        applyMute(state)
        local col = state and C.muted or C.green
        micBody.BackgroundColor3 = col
        micBar.BackgroundColor3 = col
        micStem.BackgroundColor3 = col
        micText.Text = state and "click to unmute" or "click to mute"
        countLabel.Text = state and "10" or "—"
        if state then
            task.spawn(function()
                for i = 10, 0, -1 do
                    if not muted or not m.Visible then return end
                    countLabel.Text = tostring(i)
                    task.wait(1)
                end
            end)
        end
    end

    clickArea.MouseButton1Click:Connect(function() setMute(not muted) end)

    keyBox.MouseButton1Click:Connect(function()
        listeningKey = true
        keyLabel.Text = "..."
        keyLabel.TextColor3 = C.muted
    end)

    TweenService:Create(m, TweenInfo.new(0.25), { BackgroundTransparency = 0.02 }):Play()
    TweenService:Create(mStroke, TweenInfo.new(0.25), { Transparency = 0 }):Play()

    selfPanel = m
end

-- ═══ INJECT ═══
local function inject()
    if injecting then return end
    injecting = true

    statusTitle.Text = "INJECTING"
    statusTitle.TextColor3 = C.amber
    statusSub.Text = "Injecting " .. METHODS[selected].short .. " method..."
    dot.BackgroundColor3 = C.amber
    halo.BackgroundColor3 = C.amber

    pcall(function() sessionId = VCS:getInternalSessionId() end)
    task.spawn(METHODS[selected].fn)

    task.wait(1.5)

    if vcOff() then
        statusTitle.Text = "NO VOICE"
        statusTitle.TextColor3 = C.red
        statusSub.Text = "Voice chat is off in this game."
        dot.BackgroundColor3 = C.red
        injecting = false
        return
    end

    active = true
    statusTitle.Text = "ACTIVE"
    statusTitle.TextColor3 = C.lime
    statusSub.Text = "Using " .. METHODS[selected].short .. " method."
    dot.BackgroundColor3 = C.lime
    halo.BackgroundColor3 = C.lime
    pulse()
    notify("anti vc ban injected")

    task.wait(0.9)
    buildSelf()
    injecting = false
end

refreshBtn.MouseButton1Click:Connect(function() task.spawn(inject) end)

-- ═══ KEYBINDS ═══
UIS.InputBegan:Connect(function(i, processed)
    if listeningKey and i.KeyCode ~= Enum.KeyCode.Unknown then
        muteKey = i.KeyCode
        local lbl = selfPanel and selfPanel:FindFirstChildWhichIsA("Frame")
        listeningKey = false
        notify("mute key: " .. i.KeyCode.Name)
        for _, d in ipairs(selfPanel:GetDescendants()) do
            if d:IsA("TextLabel") and d.Text == "..." then
                d.Text = i.KeyCode.Name:sub(1, 3)
                d.TextColor3 = C.lime
            end
        end
        return
    end
    if processed or i.KeyCode ~= muteKey then return end
    if pushTalk then applyMute(false)
    elseif pushMute then applyMute(true)
    else
        muted = not muted
        applyMute(muted)
    end
end)

UIS.InputEnded:Connect(function(i)
    if i.KeyCode ~= muteKey then return end
    if pushTalk then applyMute(true)
    elseif pushMute then applyMute(false) end
end)

-- ═══ AUTO LOOP ═══
task.spawn(function()
    while gui.Parent do
        task.wait(20)
        if active then
            if vcOff() then
                statusSub.Text = "Voice chat is off in this game."
            else
                pcall(function() sessionId = VCS:getInternalSessionId() end)
                task.spawn(METHODS[selected].fn)
            end
        end
    end
end)

-- ═══ START ═══
if queue_on_teleport then
    pcall(function()
        queue_on_teleport('loadstring(game:HttpGet("' .. LOADER_URL .. '"))()')
    end)
end

task.delay(0.4, function() notify("select a method, then press ⟳") end)
