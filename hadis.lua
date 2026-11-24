--[[────────────────────────────────────────────────────────────
	HADIS  //  kani - zafi
	passkey: hadis

	host : i-upload ito bilang hadis.lua sa public repo
	run  : loadstring(game:HttpGet(LOADER_URL))()

	walang backdrop pagkatapos ng passkey — transparent na.
────────────────────────────────────────────────────────────]]

local LOADER_URL = "https://raw.githubusercontent.com/hadisxchiken-ctrl/hadis41-/main/hadis.lua"
local PASSKEY    = "hadis"

local Players          = game:GetService("Players")
local UIS              = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local CoreGui          = game:GetService("CoreGui")
local VIM              = game:GetService("VirtualInputManager")
local TeleportService  = game:GetService("TeleportService")
local HttpService      = game:GetService("HttpService")
local Lighting         = game:GetService("Lighting")
local Stats            = game:GetService("Stats")
local VirtualUser      = game:GetService("VirtualUser")

local LP     = Players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse  = LP:GetMouse()

-- ═══ PALETTE ═══
local PINK      = Color3.fromRGB(255, 194, 221)
local PINK_DEEP = Color3.fromRGB(255, 159, 198)
local PINK_SOFT = Color3.fromRGB(255, 215, 231)
local NAVY      = Color3.fromRGB(13, 19, 38)
local NAVY_DEEP = Color3.fromRGB(7, 10, 22)
local TEXT      = Color3.fromRGB(233, 238, 251)
local SUB       = Color3.fromRGB(159, 176, 208)
local LAV       = Color3.fromRGB(201, 184, 255)
local PEACH     = Color3.fromRGB(255, 207, 158)
local RED       = Color3.fromRGB(255, 120, 150)
local LOGO      = "rbxassetid://10669437756353535"

local F_BOLD = Enum.Font.GothamBold
local F_MED  = Enum.Font.GothamMedium
local F_TXT  = Enum.Font.Gotham

-- ═══ STATE ═══
local binds      = {}
local listening  = nil
local pawsOn     = true
local injecting  = false
local antiActive = false
local muteKey    = Enum.KeyCode.V
local micMuted   = false
local unlocked   = false
local currentTab = "voice"
local antiConn, flyConn, noclipConn, espFolder
local aimConn
local saved = {}
local flags = {
	walk = false, jump = false, fly = false, noclip = false, infjump = false,
	bright = false, esp = false, afk = false, fps = false, lowg = false,
	aim = false, xray = false,
}

-- ═══ HELPERS ═══
local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end

local function corner(o, r)
	new("UICorner", { CornerRadius = UDim.new(0, r or 8) }, o)
	return o
end

local function stroke(o, color, thick, trans)
	new("UIStroke", {
		Color = color or PINK, Thickness = thick or 1,
		Transparency = trans or 0.85, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, o)
	return o
end

local function pad(o, p)
	new("UIPadding", {
		PaddingTop = UDim.new(0, p), PaddingBottom = UDim.new(0, p),
		PaddingLeft = UDim.new(0, p), PaddingRight = UDim.new(0, p),
	}, o)
end

local function tween(o, t, props, style)
	return TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function draggable(handle, target, buttons)
	local dragging, startPos, startInput, blocked
	handle.InputBegan:Connect(function(i)
		if blocked then blocked = false return end
		if i.UserInputType ~= Enum.UserInputType.MouseButton1
			and i.UserInputType ~= Enum.UserInputType.Touch then return end
		dragging, startPos, startInput = true, target.Position, i.Position
	end)
	UIS.InputChanged:Connect(function(i)
		if not dragging then return end
		if i.UserInputType ~= Enum.UserInputType.MouseMovement
			and i.UserInputType ~= Enum.UserInputType.Touch then return end
		local d = i.Position - startInput
		target.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + d.X,
			startPos.Y.Scale, startPos.Y.Offset + d.Y
		)
	end)
	UIS.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1
			or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)
	for _, b in ipairs(buttons or {}) do
		b.InputBegan:Connect(function()
			blocked = true
			task.delay(0.25, function() blocked = false end)
		end)
	end
end

-- ═══ HOST ═══
local host = LP:WaitForChild("PlayerGui")
pcall(function()
	local probe = Instance.new("ScreenGui")
	probe.Parent = CoreGui
	probe:Destroy()
	host = CoreGui
end)

local gui = new("ScreenGui", {
	Name = "HADIS", ResetOnSpawn = false,
	IgnoreGuiInset = true, DisplayOrder = 999,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, host)

-- ═══ TOAST ═══
local toastHolder = new("Frame", {
	Size = UDim2.fromOffset(240, 0), Position = UDim2.new(0.5, -120, 1, -28),
	BackgroundTransparency = 1, ZIndex = 400,
}, gui)
new("UIListLayout", {
	SortOrder = Enum.SortOrder.LayoutOrder,
	VerticalAlignment = Enum.VerticalAlignment.Bottom,
	Padding = UDim.new(0, 6),
}, toastHolder)

local function notify(msg)
	local t = new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = NAVY_DEEP,
		BackgroundTransparency = 0.12, Font = F_MED, TextSize = 12,
		TextColor3 = PINK, Text = "  " .. msg, TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 401,
	}, toastHolder)
	corner(t, 8)
	stroke(t, PINK, 1, 0.6)
	tween(t, 0.2, { BackgroundTransparency = 0.12 })
	task.delay(2.4, function()
		tween(t, 0.25, { BackgroundTransparency = 1, TextTransparency = 1 })
		task.wait(0.3)
		t:Destroy()
	end)
end

-- ═══ INTRO SCENE ═══
local intro = new("Frame", {
	Size = UDim2.fromScale(1, 1), BackgroundColor3 = NAVY,
	BorderSizePixel = 0, ZIndex = 100,
}, gui)
new("UIGradient", {
	Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(6, 11, 26)),
		ColorSequenceKeypoint.new(0.55, Color3.fromRGB(24, 30, 58)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(72, 44, 74)),
	},
	Rotation = 90,
}, intro)

-- stars
for i = 1, 46 do
	local s = new("Frame", {
		Size = UDim2.fromOffset(2, 2),
		Position = UDim2.fromScale(math.random() * 100 / 100, math.random() * 58 / 100),
		BackgroundColor3 = PINK_SOFT, BackgroundTransparency = math.random() * 0.4,
		BorderSizePixel = 0, ZIndex = 101,
	}, intro)
	corner(s, 2)
	task.spawn(function()
		while s.Parent do
			tween(s, 1 + math.random(), { BackgroundTransparency = 0.75 }, Enum.EasingStyle.Sine)
			task.wait(1 + math.random())
			tween(s, 1 + math.random(), { BackgroundTransparency = math.random() * 0.3 }, Enum.EasingStyle.Sine)
			task.wait(1 + math.random())
		end
	end)
end

-- moon + halo
local halo = new("Frame", {
	Size = UDim2.fromOffset(300, 300), AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.72, 0.52), BackgroundColor3 = PINK,
	BackgroundTransparency = 0.94, BorderSizePixel = 0, ZIndex = 101,
}, intro)
corner(halo, 150)
local moon = new("Frame", {
	Size = UDim2.fromOffset(132, 132), AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.72, 0.52), BackgroundColor3 = Color3.fromRGB(255, 240, 246),
	BorderSizePixel = 0, ZIndex = 102,
}, intro)
corner(moon, 66)
new("UIGradient", {
	Color = ColorSequence.new(Color3.fromRGB(255, 245, 250), Color3.fromRGB(255, 196, 220)),
	Rotation = 90,
}, moon)
task.spawn(function()
	while moon.Parent do
		tween(halo, 3, { Size = UDim2.fromOffset(340, 340), BackgroundTransparency = 0.9 }, Enum.EasingStyle.Sine)
		task.wait(3)
		tween(halo, 3, { Size = UDim2.fromOffset(280, 280), BackgroundTransparency = 0.95 }, Enum.EasingStyle.Sine)
		task.wait(3)
	end
end)

-- clouds
local cloudSpecs = { {0.1, 0.2, 190}, {0.5, 0.32, 150}, {0.82, 0.14, 220} }
for _, c in ipairs(cloudSpecs) do
	local cl = new("Frame", {
		Size = UDim2.fromOffset(c[3], 26), Position = UDim2.fromScale(c[1], c[2]),
		BackgroundColor3 = Color3.fromRGB(238, 214, 232),
		BackgroundTransparency = 0.72, BorderSizePixel = 0, ZIndex = 102,
	}, intro)
	corner(cl, 13)
	new("UIGradient", { Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	} }, cl)
	task.spawn(function()
		while cl.Parent do
			cl.Position = UDim2.fromScale(-0.2, c[2])
			tween(cl, 26 + math.random(0, 10), { Position = UDim2.fromScale(1.2, c[2]) }, Enum.EasingStyle.Linear)
			task.wait(26)
		end
	end)
end

-- sand
local sand = new("Frame", {
	Size = UDim2.new(1, 0, 0, 96), Position = UDim2.new(0, 0, 1, -96),
	BackgroundColor3 = Color3.fromRGB(122, 96, 118), BorderSizePixel = 0, ZIndex = 106,
}, intro)
new("UIGradient", {
	Color = ColorSequence.new(Color3.fromRGB(146, 112, 134), Color3.fromRGB(86, 66, 88)),
	Rotation = 90,
}, sand)

-- waves
local waveLayers = {}
for l = 1, 4 do
	local layer = new("Frame", {
		Size = UDim2.new(1, 0, 0, 70),
		Position = UDim2.new(0, 0, 1, -84 - (l * 7)),
		BackgroundTransparency = 1, ZIndex = 103 + l,
	}, intro)
	local bars = {}
	for i = 1, 18 do
		local bar = new("Frame", {
			Size = UDim2.new(0.058, 2, 0, 10),
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new((i - 1) / 18, 0, 1, 0),
			BackgroundColor3 = (l % 2 == 0) and PINK or Color3.fromRGB(120, 140, 190),
			BackgroundTransparency = 0.28 + (l * 0.12),
			BorderSizePixel = 0, ZIndex = 103 + l,
		}, layer)
		corner(bar, 3)
		new("UIGradient", {
			Color = ColorSequence.new(PINK_SOFT, Color3.fromRGB(90, 108, 160)),
			Rotation = 90,
		}, bar)
		bars[i] = bar
	end
	waveLayers[l] = { bars = bars, phase = l * 1.4 }
end

RunService.RenderStepped:Connect(function()
	if not intro.Visible then return end
	local t = tick()
	for l, layer in ipairs(waveLayers) do
		for i, bar in ipairs(layer.bars) do
			local h = 8 + math.abs(math.sin((t * 1.1) + (i * 0.42) + layer.phase)) * 22
			bar.Size = UDim2.new(0.058, 2, 0, h)
		end
	end
end)

-- paws
local pawLayer = new("Frame", {
	Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
	ZIndex = 108, ClipsDescendants = true,
}, intro)

local function spawnPaw()
	local p = new("TextLabel", {
		Size = UDim2.fromOffset(26, 26), BackgroundTransparency = 1,
		Font = F_TXT, Text = "🐾", TextSize = 20,
		TextColor3 = PINK, Rotation = math.random(-40, 40),
		Position = UDim2.new(math.random() * 100 / 100, 0, -0.08, 0),
		TextTransparency = 0.15, ZIndex = 108,
	}, pawLayer)
	tween(p, math.random(6, 11), {
		Position = UDim2.new(p.Position.X.Scale, 0, 1.08, 0),
		Rotation = p.Rotation + math.random(-120, 120),
		TextTransparency = 0.9,
	}, Enum.EasingStyle.Linear)
	task.delay(12, function() p:Destroy() end)
end

task.spawn(function()
	while pawLayer.Parent do
		if pawsOn and intro.Visible then spawnPaw() end
		task.wait(0.42)
	end
end)

-- logo
local logo = new("ImageLabel", {
	Size = UDim2.fromOffset(96, 96), AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.3), BackgroundTransparency = 1,
	Image = LOGO, ImageColor3 = Color3.fromRGB(255, 255, 255), ZIndex = 110,
}, intro)
new("UIScale", { Scale = 1 }, logo)

-- slider
local track = new("Frame", {
	Size = UDim2.fromOffset(258, 40), AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.62), BackgroundColor3 = Color3.fromRGB(22, 28, 52),
	BackgroundTransparency = 0.15, BorderSizePixel = 0, ZIndex = 112,
}, intro)
corner(track, 20)
stroke(track, PINK, 1, 0.55)

local fill = new("Frame", {
	Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = PINK_DEEP,
	BorderSizePixel = 0, ZIndex = 113,
}, track)
corner(fill, 20)
new("UIGradient", {
	Color = ColorSequence.new(PINK_SOFT, PINK_DEEP), Rotation = 90,
}, fill)

local trackLabel = new("TextLabel", {
	Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
	Font = F_BOLD, Text = "hadis", TextSize = 14,
	TextColor3 = Color3.fromRGB(120, 132, 164), ZIndex = 114,
}, track)
trackLabel.TextTransparency = 0.25

local knob = new("TextButton", {
	Size = UDim2.fromOffset(44, 44), AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0, 4, 0.5, 0), BackgroundColor3 = Color3.fromRGB(28, 34, 60),
	BorderSizePixel = 0, AutoButtonColor = false,
	Font = F_TXT, Text = "🐾", TextSize = 22, TextColor3 = PINK, ZIndex = 116,
}, track)
corner(knob, 22)
stroke(knob, PINK, 1.5, 0.25)

local progress = 0
local sliding = false

local function setProgress(p)
	progress = math.clamp(p, 0, 1)
	local usable = track.AbsoluteSize.X - 48
	knob.Position = UDim2.new(0, 4 + usable * progress, 0.5, 0)
	fill.Size = UDim2.new(0, 24 + usable * progress, 1, 0)
	knob.TextColor3 = progress > 0.05 and PINK_SOFT or PINK
end

knob.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1
		or i.UserInputType == Enum.UserInputType.Touch then sliding = true end
end)
UIS.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1
		or i.UserInputType == Enum.UserInputType.Touch then
		if sliding and progress < 0.96 then
			sliding = false
			tween(knob, 0.2, { Position = UDim2.new(0, 4, 0.5, 0) })
			tween(fill, 0.2, { Size = UDim2.new(0, 24, 1, 0) })
			progress = 0
		end
		sliding = false
	end
end)
UIS.InputChanged:Connect(function(i)
	if not sliding then return end
	if i.UserInputType ~= Enum.UserInputType.MouseMovement
		and i.UserInputType ~= Enum.UserInputType.Touch then return end
	local rel = (i.Position.X - track.AbsolutePosition.X - 24) / math.max(1, track.AbsoluteSize.X - 48)
	setProgress(rel)
	if progress >= 0.97 then
		sliding = false
		progress = 1
		setProgress(1)
		enterPasskey()
	end
end)

-- ═══ PASSKEY ═══
local gate = new("Frame", {
	Size = UDim2.fromScale(1, 1), BackgroundColor3 = NAVY_DEEP,
	BackgroundTransparency = 0.55, BorderSizePixel = 0,
	Visible = false, ZIndex = 130,
}, intro)

local card = new("Frame", {
	Size = UDim2.fromOffset(340, 214), AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = NAVY,
	BorderSizePixel = 0, ZIndex = 131,
}, gate)
corner(card, 14)
stroke(card, PINK, 1, 0.45)

new("TextLabel", {
	Size = UDim2.new(1, -36, 0, 20), Position = UDim2.fromOffset(18, 16),
	BackgroundTransparency = 1, Font = F_BOLD, Text = "ENTER PASSKEY",
	TextSize = 15, TextColor3 = TEXT, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 132,
}, card)

new("TextLabel", {
	Size = UDim2.new(1, -36, 0, 14), Position = UDim2.fromOffset(18, 38),
	BackgroundTransparency = 1, Font = F_TXT, Text = "hint: the hub name",
	TextSize = 10, TextColor3 = SUB, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 132,
}, card)

local input = new("TextBox", {
	Size = UDim2.new(1, -36, 0, 38), Position = UDim2.fromOffset(18, 62),
	BackgroundColor3 = Color3.fromRGB(9, 13, 26), BorderSizePixel = 0,
	Font = F_MED, Text = "", PlaceholderText = "•••••",
	PlaceholderColor3 = Color3.fromRGB(96, 108, 140),
	TextSize = 14, TextColor3 = TEXT, TextXAlignment = Enum.TextXAlignment.Left,
	ClearTextOnFocus = false, ZIndex = 132,
}, card)
corner(input, 9)
stroke(input, PINK, 1, 0.8)
pad(input, 10)

local errLabel = new("TextLabel", {
	Size = UDim2.new(1, -36, 0, 12), Position = UDim2.fromOffset(18, 104),
	BackgroundTransparency = 1, Font = F_MED, Text = "",
	TextSize = 10, TextColor3 = RED, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 132,
}, card)

local submit = new("TextButton", {
	Size = UDim2.new(1, -36, 0, 32), Position = UDim2.fromOffset(18, 122),
	BackgroundColor3 = PINK_DEEP, BorderSizePixel = 0, AutoButtonColor = false,
	Font = F_BOLD, Text = "UNLOCK", TextSize = 12,
	TextColor3 = NAVY_DEEP, ZIndex = 132,
}, card)
corner(submit, 9)

local hintChip = new("TextButton", {
	Size = UDim2.fromOffset(74, 22), Position = UDim2.new(1, -96, 0, 22),
	BackgroundColor3 = PINK, BackgroundTransparency = 0.9,
	BorderSizePixel = 0, AutoButtonColor = false,
	Font = F_MED, Text = "copy hint", TextSize = 9, TextColor3 = PINK, ZIndex = 133,
}, card)
corner(hintChip, 6)
hintChip.MouseButton1Click:Connect(function()
	pcall(function() setclipboard(PASSKEY) end)
	notify("hint copied")
end)

local pasteChip = new("TextButton", {
	Size = UDim2.fromOffset(74, 22), Position = UDim2.new(1, -96, 0, 48),
	BackgroundColor3 = PINK, BackgroundTransparency = 0.9,
	BorderSizePixel = 0, AutoButtonColor = false,
	Font = F_MED, Text = "paste", TextSize = 9, TextColor3 = PINK, ZIndex = 133,
}, card)
corner(pasteChip, 6)
pasteChip.MouseButton1Click:Connect(function()
	pcall(function()
		local ok, val = pcall(getclipboard)
		if ok and val then input.Text = val end
	end)
end)

local function shake()
	local base = card.Position
	for i = 1, 4 do
		card.Position = base + UDim2.fromOffset((i % 2 == 0) and 8 or -8, 0)
		task.wait(0.045)
	end
	card.Position = base
end

local function tryUnlock()
	if input.Text:lower() == PASSKEY then
		input.Text = ""
		errLabel.Text = ""
		tween(card, 0.25, { BackgroundColor3 = PINK_DEEP })
		unlocked = true
		task.wait(0.25)
		gate.Visible = false
		intro.Visible = false
		hub.Visible = true
		notify("unlocked")
	else
		errLabel.Text = "wrong passkey"
		stroke(input, RED, 1, 0.3)
		shake()
		task.delay(1.2, function() stroke(input, PINK, 1, 0.8) end)
	end
end

submit.MouseButton1Click:Connect(tryUnlock)
input.FocusLost:Connect(function(enter)
	if enter then tryUnlock() end
end)

function enterPasskey()
	gate.Visible = true
	task.wait(0.05)
	pcall(function() input:CaptureFocus() end)
end

-- ═══ HUB ═══
local hub = new("Frame", {
	Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
	Visible = false, ZIndex = 10,
}, gui)

local main = new("Frame", {
	Size = UDim2.fromOffset(520, 366), AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = NAVY,
	BackgroundTransparency = 0.06, BorderSizePixel = 0, ZIndex = 20,
}, hub)
corner(main, 12)
stroke(main, PINK, 1, 0.72)

local header = new("Frame", {
	Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = Color3.fromRGB(17, 23, 44),
	BackgroundTransparency = 0.1, BorderSizePixel = 0, ZIndex = 21,
}, main)
corner(header, 12)

new("Frame", {
	Size = UDim2.new(1, -24, 0, 1), Position = UDim2.new(0, 12, 0, 41),
	BackgroundColor3 = PINK, BackgroundTransparency = 0.8, BorderSizePixel = 0, ZIndex = 22,
}, header)

local badge = new("ImageLabel", {
	Size = UDim2.fromOffset(26, 26), Position = UDim2.fromOffset(10, 8),
	BackgroundTransparency = 1, Image = LOGO, ZIndex = 23,
}, header)

new("TextLabel", {
	Size = UDim2.fromOffset(160, 16), Position = UDim2.fromOffset(44, 7),
	BackgroundTransparency = 1, Font = F_BOLD, Text = "kani - zafi",
	TextSize = 13, TextColor3 = TEXT, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 23,
}, header)

new("TextLabel", {
	Size = UDim2.fromOffset(160, 12), Position = UDim2.fromOffset(44, 23),
	BackgroundTransparency = 1, Font = F_TXT, Text = "hadis hub",
	TextSize = 9, TextColor3 = SUB, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 23,
}, header)

local tag = new("TextLabel", {
	Size = UDim2.fromOffset(30, 16), Position = UDim2.new(0, 210, 0, 13),
	BackgroundColor3 = PINK, BackgroundTransparency = 0.88, BorderSizePixel = 0,
	Font = F_BOLD, Text = "41$", TextSize = 9, TextColor3 = PINK, ZIndex = 23,
}, header)
corner(tag, 4)

local function headBtn(txt, x, color)
	local b = new("TextButton", {
		Size = UDim2.fromOffset(24, 24), Position = UDim2.new(1, x, 0, 9),
		BackgroundColor3 = Color3.fromRGB(26, 33, 58), BorderSizePixel = 0,
		AutoButtonColor = false, Font = F_BOLD, Text = txt,
		TextSize = 13, TextColor3 = color or TEXT, ZIndex = 26,
	}, header)
	corner(b, 7)
	return b
end

local backBtn = headBtn("‹", -84, PINK)
local minBtn  = headBtn("−", -56)
local closeBtn = headBtn("×", -28, RED)

local function backToIntro()
	hub.Visible = false
	unlocked = false
	intro.Visible = true
	progress = 0
	setProgress(0)
	gate.Visible = false
end
backBtn.MouseButton1Click:Connect(backToIntro)
closeBtn.MouseButton1Click:Connect(function()
	hub.Visible = false
end)

-- chips
local chipsRow = new("Frame", {
	Size = UDim2.new(1, -24, 0, 20), Position = UDim2.fromOffset(12, 48),
	BackgroundTransparency = 1, ZIndex = 22,
}, main)
new("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder,
}, chipsRow)

local pingChip, fpsChip, plrChip
local function chip(label)
	local c = new("TextLabel", {
		Size = UDim2.fromOffset(0, 18), AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Color3.fromRGB(24, 31, 55), BorderSizePixel = 0,
		Font = F_MED, Text = "  " .. label .. "  ", TextSize = 9,
		TextColor3 = SUB, ZIndex = 23,
	}, chipsRow)
	corner(c, 5)
	pad(c, 4)
	return c
end
chip("walk 16")
chip("jump 50")
pingChip = chip("ping —")
fpsChip  = chip("fps —")
plrChip  = chip("players —")

task.spawn(function()
	while gui.Parent do
		task.wait(1)
		if hub.Visible then
			local ok, ping = pcall(function()
				return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
			end)
			pingChip.Text = "  ping " .. ((ok and ping) or "—") .. "  "
			fpsChip.Text  = "  fps " .. math.floor(1 / math.max(RunService.RenderStepped:Wait(), 1e-3)) .. "  "
			plrChip.Text  = "  players " .. #Players:GetPlayers() .. "  "
		end
	end
end)

-- tabs
local tabs = { "voice", "social", "movement", "visuals", "external", "anti" }
local tabRow = new("Frame", {
	Size = UDim2.new(1, -24, 0, 22), Position = UDim2.fromOffset(12, 74),
	BackgroundTransparency = 1, ZIndex = 22,
}, main)
new("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder,
}, tabRow)

local tabButtons = {}
local function paintTabs()
	for t, b in pairs(tabButtons) do
		local on = (t == currentTab)
		b.BackgroundTransparency = on and 0.72 or 1
		b.TextColor3 = on and PINK or SUB
		b.Text = on and (t:upper() .. " •") or t:upper()
	end
end

for _, t in ipairs(tabs) do
	local b = new("TextButton", {
		Size = UDim2.fromOffset(0, 22), AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = PINK, BackgroundTransparency = 1, BorderSizePixel = 0,
		AutoButtonColor = false, Font = F_BOLD, Text = t:upper(),
		TextSize = 9, TextColor3 = SUB, ZIndex = 23,
	}, tabRow)
	corner(b, 6)
	pad(b, 7)
	tabButtons[t] = b
	b.MouseButton1Click:Connect(function()
		currentTab = t
		paintTabs()
		renderCards()
	end)
end

-- body
local body = new("ScrollingFrame", {
	Size = UDim2.new(1, -24, 1, -142), Position = UDim2.fromOffset(12, 102),
	BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 3, ScrollBarImageColor3 = PINK,
	CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 22,
}, main)
new("UIListLayout", {
	Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
}, body)

-- exec implementations
local function hum()
	return LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
end

local function clearFly()
	if flyConn then flyConn:Disconnect() flyConn = nil end
	local ch = LP.Character
	if ch then
		for _, v in ipairs(ch:GetDescendants()) do
			if v.Name == "HadisFly" then v:Destroy() end
		end
	end
end

local function setFly(on)
	flags.fly = on
	clearFly()
	if not on then return end
	local ch = LP.Character
	local root = ch and ch:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local bv = new("BodyVelocity", {
		Name = "HadisFly", Velocity = Vector3.zero,
		MaxForce = Vector3.new(1e5, 1e5, 1e5), P = 2000,
	}, root)
	hum().PlatformStand = true
	flyConn = RunService.RenderStepped:Connect(function()
		if not root.Parent then clearFly() return end
		local dir = Vector3.zero
		if UIS:IsKeyDown(Enum.KeyCode.W) then dir += camera.CFrame.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= camera.CFrame.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= camera.CFrame.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.D) then dir += camera.CFrame.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
		if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.yAxis end
		bv.Velocity = dir.Magnitude > 0 and dir.Unit * 58 or Vector3.zero
	end)
end

local function setNoclip(on)
	flags.noclip = on
	if noclipConn then noclipConn:Disconnect() noclipConn = nil end
	if not on then
		local ch = LP.Character
		if ch then
			for _, v in ipairs(ch:GetDescendants()) do
				if v:IsA("BasePart") then v.CanCollide = true end
			end
		end
		return
	end
	noclipConn = RunService.Stepped:Connect(function()
		local ch = LP.Character
		if ch then
			for _, v in ipairs(ch:GetDescendants()) do
				if v:IsA("BasePart") then v.CanCollide = false end
			end
		end
	end)
end

local function setBright(on)
	flags.bright = on
	if on then
		saved.brightness = Lighting.Brightness
		saved.ambient = Lighting.Ambient
		saved.outdoor = Lighting.OutdoorAmbient
		Lighting.Brightness = 3
		Lighting.Ambient = Color3.fromRGB(178, 178, 178)
		Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
	else
		Lighting.Brightness = saved.brightness or 2
		Lighting.Ambient = saved.ambient or Color3.fromRGB(70, 70, 70)
		Lighting.OutdoorAmbient = saved.outdoor or Color3.fromRGB(128, 128, 128)
	end
end

local function clearEsp()
	if espFolder then espFolder:Destroy() espFolder = nil end
end

local function setEsp(on)
	flags.esp = on
	clearEsp()
	if not on then return end
	espFolder = new("Folder", { Name = "HadisEsp", Parent = gui })
	task.spawn(function()
		while flags.esp and espFolder do
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= LP and p.Character then
					local head = p.Character:FindFirstChild("Head")
					if head and not head:FindFirstChild("HadisEsp") then
						local bb = new("BillboardGui", {
							Name = "HadisEsp", Size = UDim2.fromOffset(110, 34),
							StudsOffset = Vector3.new(0, 2.6, 0), AlwaysOnTop = true,
							Parent = head,
						}, head)
						local name = new("TextLabel", {
							Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
							Font = F_BOLD, Text = p.Name, TextSize = 12,
							TextColor3 = PINK, TextStrokeTransparency = 0.35,
						}, bb)
						new("UIStroke", { Color = NAVY_DEEP, Thickness = 1.5, Transparency = 0.4 }, name)
					end
				end
			end
			task.wait(0.75)
		end
	end)
end

local function setXray(on)
	flags.xray = on
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("BasePart") and d.Name ~= "Terrain" then
			if on then
				if d.Transparency < 1 then
					d:SetAttribute("HadisTrans", d.Transparency)
					d.Transparency = 0.86
				end
			elseif d:GetAttribute("HadisTrans") then
				d.Transparency = d:GetAttribute("HadisTrans")
				d:SetAttribute("HadisTrans", nil)
			end
		end
	end
end

local function setAim(on)
	flags.aim = on
	if aimConn then aimConn:Disconnect() aimConn = nil end
	if not on then return end
	aimConn = RunService.RenderStepped:Connect(function()
		local best, bestDist
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LP and p.Character then
				local head = p.Character:FindFirstChild("Head")
				if head then
					local sp, onScreen = camera:WorldToViewportPoint(head.Position)
					if onScreen then
						local d = (Vector2.new(sp.X, sp.Y) - Vector2.new(mouse.X, mouse.Y)).Magnitude
						if d < 160 and (not bestDist or d < bestDist) then
							best, bestDist = head, d
						end
					end
				end
			end
		end
		if best then camera.CFrame = CFrame.lookAt(camera.CFrame.Position, best.Position) end
	end)
end

local function setFps(on)
	flags.fps = on
	pcall(function() setfpscap(on and 240 or 60) end)
end

local function setLowG(on)
	flags.lowg = on
	pcall(function()
		settings().Rendering.QualityLevel = on and 1 or 8
	end)
end

local function serverHop()
	task.spawn(function()
		local ok, res = pcall(function()
			return HttpService:JSONDecode(game:HttpGet(
				"https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
			))
		end)
		if ok and res and res.data then
			for _, s in ipairs(res.data) do
				if s.playing < s.maxPlayers and s.id ~= game.JobId then
					pcall(function()
						TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LP)
					end)
					return
				end
			end
		end
		notify("walang bakanteng server")
	end)
end

local function rejoin()
	pcall(function()
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
	end)
end

-- card builder
local function makeCard(name, sub, kind, default)
	local cardF = new("Frame", {
		Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Color3.fromRGB(20, 26, 48),
		BackgroundTransparency = 0.12, BorderSizePixel = 0, ZIndex = 23,
	}, body)
	corner(cardF, 8)
	stroke(cardF, PINK, 1, 0.9)

	new("TextLabel", {
		Size = UDim2.new(1, -110, 0, 15), Position = UDim2.fromOffset(10, 6),
		BackgroundTransparency = 1, Font = F_BOLD, Text = name,
		TextSize = 11, TextColor3 = TEXT, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 24,
	}, cardF)

	new("TextLabel", {
		Size = UDim2.new(1, -110, 0, 12), Position = UDim2.fromOffset(10, 21),
		BackgroundTransparency = 1, Font = F_TXT, Text = sub,
		TextSize = 9, TextColor3 = SUB, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 24,
	}, cardF)

	local switch = new("TextButton", {
		Size = UDim2.fromOffset(38, 18), Position = UDim2.new(1, -48, 0, 11),
		BackgroundColor3 = Color3.fromRGB(40, 47, 74), BorderSizePixel = 0,
		AutoButtonColor = false, Font = F_BOLD, Text = "OFF",
		TextSize = 8, TextColor3 = SUB, ZIndex = 25,
	}, cardF)
	corner(switch, 9)

	local bind = new("TextButton", {
		Size = UDim2.fromOffset(30, 18), Position = UDim2.new(1, -84, 0, 11),
		BackgroundColor3 = Color3.fromRGB(40, 47, 74), BackgroundTransparency = 0.2,
		BorderSizePixel = 0, AutoButtonColor = false, Font = F_MED,
		Text = "bind", TextSize = 8, TextColor3 = SUB, ZIndex = 25,
	}, cardF)
	corner(bind, 6)

	local on = default or false

	local function paint()
		switch.Text = on and "ON" or "OFF"
		switch.BackgroundColor3 = on and PINK_DEEP or Color3.fromRGB(40, 47, 74)
		switch.TextColor3 = on and NAVY_DEEP or SUB
		cardF.BackgroundTransparency = on and 0.02 or 0.12
	end

	local function run()
		on = not on
		paint()
		if kind then kind(on) end
	end

	switch.MouseButton1Click:Connect(run)
	cardF.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then run() end
	end)

	bind.MouseButton1Click:Connect(function()
		listening = name
		bind.Text = "..."
		bind.TextColor3 = PINK
		notify("pindutin ang key para sa " .. name)
	end)

	paint()
	return { frame = cardF, set = function(v) on = v paint() if kind then kind(v) end end,
		getBind = function() return bind end }
end

local function label(txt)
	local l = new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1,
		Font = F_BOLD, Text = txt, TextSize = 8,
		TextColor3 = PINK, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 23,
	}, body)
	pad(l, 2)
	return l
end

local cardRefs = {}

local function renderCards()
	for _, c in ipairs(body:GetChildren()) do
		if c:IsA("Frame") or c:IsA("TextLabel") then
			if c ~= nil then c:Destroy() end
		end
	end
	cardRefs = {}

	if currentTab == "voice" then
		label("VOICE")
		table.insert(cardRefs, makeCard("anti vc ban", "gulat sa mic session, hindi sa remote", function(v)
			if v then task.spawn(injectAnti) else
				antiActive = false
				statusLabel.Text = "IDLE"
				statusSub.Text = "Not injected yet."
				statusDot.BackgroundTransparency = 0.7
				anti.win.Visible = false
				selfWin.win.Visible = false
			end
		end))
		table.insert(cardRefs, makeCard("self mute", "synthetic key sa mute bind", function(v)
			setMute(v)
			selfWin.win.Visible = v
		end))
		table.insert(cardRefs, makeCard("push to talk", "hold ang mute key habang nagsasalita", nil))
		table.insert(cardRefs, makeCard("mic status", "live na estado ng mic", nil))

	elseif currentTab == "social" then
		label("PLAYERS")
		table.insert(cardRefs, makeCard("player esp", "billboard name sa bawat player", setEsp))
		table.insert(cardRefs, makeCard("chat spy", "kailangan ng hookfunction", nil))
		label("SESSION")
		table.insert(cardRefs, makeCard("server hop", "lupat sa bakanteng server", nil))
		table.insert(cardRefs, makeCard("rejoin", "balik sa parehong server", nil))
		table.insert(cardRefs, makeCard("respawn", "load character ulit", nil))

	elseif currentTab == "movement" then
		label("MOVEMENT")
		table.insert(cardRefs, makeCard("walk speed", "56 studs/s", function(v)
			local h = hum()
			if h then h.WalkSpeed = v and 56 or 16 end
		end))
		table.insert(cardRefs, makeCard("jump power", "pataasin ang talon", function(v)
			local h = hum()
			if h then h.JumpPower = v and 110 or 50 end
		end))
		table.insert(cardRefs, makeCard("infinite jump", "walang katapusan sa ere", function(v)
			flags.infjump = v
		end))
		table.insert(cardRefs, makeCard("fly", "WASD + space / ctrl", setFly))
		table.insert(cardRefs, makeCard("noclip", "dumaan sa pader", setNoclip))

	elseif currentTab == "visuals" then
		label("VISUALS")
		table.insert(cardRefs, makeCard("full bright", "tanggal dilim", setBright))
		table.insert(cardRefs, makeCard("fov zoom", "lapitan ang camera", function(v)
			camera.FieldOfView = v and 50 or 70
		end))
		table.insert(cardRefs, makeCard("xray", "liwanagin ang mapa", setXray))
		table.insert(cardRefs, makeCard("aimbot", "camera lock sa pinakamalapit", setAim))

	elseif currentTab == "external" then
		label("EXTERNAL")
		table.insert(cardRefs, makeCard("discord", "discord.gg/hadis", nil))
		table.insert(cardRefs, makeCard("save config", "isulat sa clipboard", nil))
		table.insert(cardRefs, makeCard("fps cap 240", "setfpscap", setFps))
		table.insert(cardRefs, makeCard("low graphics", "quality level 1", setLowG))

	elseif currentTab == "anti" then
		label("ANTI")
		table.insert(cardRefs, makeCard("anti afk", "iwas idle kick", function(v)
			flags.afk = v
		end))
		table.insert(cardRefs, makeCard("anti void", "catch bago mahulog", nil))
		table.insert(cardRefs, makeCard("anti vc ban", "buksan ang panel", function()
			task.spawn(injectAnti)
		end))
	end

	-- auto execute card
	local autoRow = new("Frame", {
		Size = UDim2.new(1, 0, 0, 62), BackgroundColor3 = Color3.fromRGB(20, 26, 48),
		BackgroundTransparency = 0.12, BorderSizePixel = 0, ZIndex = 23,
	}, body)
	corner(autoRow, 8)
	stroke(autoRow, PINK, 1, 0.9)

	new("TextLabel", {
		Size = UDim2.new(1, -20, 0, 14), Position = UDim2.fromOffset(10, 5),
		BackgroundTransparency = 1, Font = F_BOLD, Text = "auto execute",
		TextSize = 10, TextColor3 = TEXT, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 24,
	}, autoRow)

	local code = new("TextLabel", {
		Size = UDim2.new(1, -20, 0, 24), Position = UDim2.fromOffset(10, 20),
		BackgroundColor3 = Color3.fromRGB(8, 13, 26), BorderSizePixel = 0,
		Font = Enum.Font.Code, Text = 'loadstring(game:HttpGet("' .. LOADER_URL .. '"))()',
		TextSize = 8, TextColor3 = Color3.fromRGB(159, 230, 196),
		TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 24,
	}, autoRow)
	corner(code, 6)
	pad(code, 5)

	local copyBtn = new("TextButton", {
		Size = UDim2.fromOffset(58, 16), Position = UDim2.new(1, -68, 0, 42),
		BackgroundColor3 = PINK, BackgroundTransparency = 0.85, BorderSizePixel = 0,
		AutoButtonColor = false, Font = F_BOLD, Text = "copy loader",
		TextSize = 8, TextColor3 = PINK, ZIndex = 25,
	}, autoRow)
	corner(copyBtn, 5)
	copyBtn.MouseButton1Click:Connect(function()
		pcall(function() setclipboard('loadstring(game:HttpGet("' .. LOADER_URL .. '"))()') end)
		notify("loader copied")
	end)
end

-- ═══ WINDOW FACTORY ═══
local function makeWindow(title, size, offset)
	local win = new("Frame", {
		Size = size, Position = UDim2.fromOffset(offset[1], offset[2]),
		BackgroundColor3 = NAVY, BackgroundTransparency = 0.05,
		BorderSizePixel = 0, Visible = false, ZIndex = 60,
	}, hub)
	corner(win, 11)
	stroke(win, PINK, 1, 0.7)

	local head = new("Frame", {
		Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Color3.fromRGB(17, 23, 44),
		BackgroundTransparency = 0.1, BorderSizePixel = 0, ZIndex = 61,
	}, win)
	corner(head, 11)

	new("TextLabel", {
		Size = UDim2.new(1, -100, 0, 15), Position = UDim2.fromOffset(11, 5),
		BackgroundTransparency = 1, Font = F_BOLD, Text = title,
		TextSize = 11, TextColor3 = TEXT, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 62,
	}, head)

	new("TextLabel", {
		Size = UDim2.fromOffset(30, 14), Position = UDim2.new(1, -100, 0, 10),
		BackgroundColor3 = PINK, BackgroundTransparency = 0.88, BorderSizePixel = 0,
		Font = F_BOLD, Text = "41$", TextSize = 8, TextColor3 = PINK, ZIndex = 62,
	}, head)
	corner(head:FindFirstChildOfClass("TextLabel") and head:GetChildren()[2] or head, 4)

	local minB = new("TextButton", {
		Size = UDim2.fromOffset(20, 20), Position = UDim2.new(1, -50, 0, 7),
		BackgroundColor3 = Color3.fromRGB(26, 33, 58), BorderSizePixel = 0,
		AutoButtonColor = false, Font = F_BOLD, Text = "−",
		TextSize = 12, TextColor3 = TEXT, ZIndex = 63,
	}, head)
	corner(minB, 6)

	local closeB = new("TextButton", {
		Size = UDim2.fromOffset(20, 20), Position = UDim2.new(1, -26, 0, 7),
		BackgroundColor3 = Color3.fromRGB(26, 33, 58), BorderSizePixel = 0,
		AutoButtonColor = false, Font = F_BOLD, Text = "×",
		TextSize = 12, TextColor3 = RED, ZIndex = 63,
	}, head)
	corner(closeB, 6)

	local content = new("Frame", {
		Size = UDim2.new(1, -20, 1, -44), Position = UDim2.fromOffset(10, 38),
		BackgroundTransparency = 1, ZIndex = 62,
	}, win)

	draggable(head, win, { minB, closeB })

	local obj = { win = win, head = head, body = content, expanded = true, full = size }

	closeB.MouseButton1Click:Connect(function()
		win.Visible = false
	end)
	minB.MouseButton1Click:Connect(function()
		obj.expanded = not obj.expanded
		if obj.expanded then
			content.Visible = true
			tween(win, 0.15, { Size = obj.full })
		else
			content.Visible = false
			tween(win, 0.15, { Size = UDim2.fromOffset(size.X.Offset, 34) })
		end
	end)

	return obj
end

-- ═══ ANTI VC BAN ═══
local anti = makeWindow("anti vc ban", UDim2.fromOffset(404, 366), { 300, 60 })

local statusRow = new("Frame", {
	Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = Color3.fromRGB(20, 26, 48),
	BackgroundTransparency = 0.1, BorderSizePixel = 0, ZIndex = 63,
}, anti.body)
corner(statusRow, 8)
stroke(statusRow, PINK, 1, 0.85)

local statusDot = new("Frame", {
	Size = UDim2.fromOffset(8, 8), Position = UDim2.fromOffset(11, 10),
	BackgroundColor3 = RED, BackgroundTransparency = 0.7,
	BorderSizePixel = 0, ZIndex = 64,
}, statusRow)
corner(statusDot, 4)

local statusLabel = new("TextLabel", {
	Size = UDim2.new(1, -40, 0, 13), Position = UDim2.fromOffset(24, 7),
	BackgroundTransparency = 1, Font = F_BOLD, Text = "IDLE",
	TextSize = 10, TextColor3 = PINK, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 64,
}, statusRow)

local statusSub = new("TextLabel", {
	Size = UDim2.new(1, -24, 0, 12), Position = UDim2.fromOffset(11, 22),
	BackgroundTransparency = 1, Font = F_TXT, Text = "Not injected yet.",
	TextSize = 9, TextColor3 = SUB, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 64,
}, statusRow)

local methods = {}
local function addMethod(name, note)
	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Color3.fromRGB(20, 26, 48),
		BackgroundTransparency = 0.98, BorderSizePixel = 0, ZIndex = 63,
	}, anti.body)
	corner(row, 7)

	local radio = new("Frame", {
		Size = UDim2.fromOffset(9, 9), Position = UDim2.fromOffset(10, 12),
		BackgroundColor3 = PINK, BackgroundTransparency = 1,
		BorderSizePixel = 0, ZIndex = 64,
	}, row)
	corner(radio, 5)
	stroke(radio, PINK, 1, 0.4)

	new("TextLabel", {
		Size = UDim2.new(1, -80, 0, 12), Position = UDim2.fromOffset(26, 5),
		BackgroundTransparency = 1, Font = F_BOLD, Text = name,
		TextSize = 9, TextColor3 = TEXT, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 64,
	}, row)

	new("TextLabel", {
		Size = UDim2.new(1, -80, 0, 11), Position = UDim2.fromOffset(26, 18),
		BackgroundTransparency = 1, Font = F_TXT, Text = note,
		TextSize = 8, TextColor3 = SUB, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 64,
	}, row)

	local sel = new("TextButton", {
		Size = UDim2.fromOffset(48, 16), Position = UDim2.new(1, -58, 0, 9),
		BackgroundColor3 = PINK, BackgroundTransparency = 0.85, BorderSizePixel = 0,
		AutoButtonColor = false, Font = F_BOLD, Text = "SELECT",
		TextSize = 7, TextColor3 = PINK, ZIndex = 65,
	}, row)
	corner(sel, 5)

	local m = { name = name, row = row, radio = radio, sel = sel }
	table.insert(methods, m)
	return m
end

addMethod("key refresh", "synthetic na pindot sa mute key tuwing 2.5s")
addMethod("mic keepalive", "patuloy na toggle para hindi mag-drop")
addMethod("channel lock", "pinipigilan ang rejoin sa voice")

local activeMethod = methods[1]

local function paintMethods()
	for _, m in ipairs(methods) do
		local on = (m == activeMethod)
		m.row.BackgroundTransparency = on and 0.94 or 0.98
		m.radio.BackgroundTransparency = on and 0 or 1
		m.sel.Text = on and "ACTIVE" or "SELECT"
	end
end

local refreshBtn = new("TextButton", {
	Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = PINK, BackgroundTransparency = 0.86,
	BorderSizePixel = 0, AutoButtonColor = false, Font = F_BOLD,
	Text = "REFRESH SESSION", TextSize = 9, TextColor3 = PINK, ZIndex = 63,
}, anti.body)
corner(refreshBtn, 7)

local noteLbl = new("TextLabel", {
	Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1,
	Font = F_TXT, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
	Text = "Walang public mic API ang Roblox, kaya synthetic key press sa mute bind ang gamit. Kung iba ang mute key mo, palitan sa self mute window.",
	TextSize = 8, TextColor3 = SUB, ZIndex = 63,
}, anti.body)

new("UIListLayout", {
	Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
}, anti.body)
pad(anti.body, 2)

local function pressKey(k)
	pcall(function()
		VIM:SendKeyEvent(true, k, false, game)
		task.wait(0.04)
		VIM:SendKeyEvent(false, k, false, game)
	end)
end

local function setMute(state)
	if state == micMuted then return end
	micMuted = state
	pressKey(muteKey)
end

local function injectAnti()
	if injecting then return end
	injecting = true
	anti.win.Visible = true
	anti.expanded = true
	anti.body.Visible = true
	anti.win.Size = anti.full
	antiActive = false
	statusLabel.Text = "INJECTING"
	statusSub.Text = "Injecting " .. activeMethod.name .. " method..."
	statusDot.BackgroundTransparency = 0.3

	task.wait(1.7)

	statusLabel.Text = "ACTIVE"
	statusSub.Text = "Using " .. activeMethod.name .. " method."
	statusDot.BackgroundTransparency = 0
	antiActive = true
	selfWin.win.Visible = true
	selfWin.expanded = true
	selfWin.body.Visible = true
	selfWin.win.Size = selfWin.full
	notify("anti vc ban injected")
	injecting = false
end

for _, m in ipairs(methods) do
	m.sel.MouseButton1Click:Connect(function()
		activeMethod = m
		paintMethods()
		task.spawn(injectAnti)
	end)
end
paintMethods()

refreshBtn.MouseButton1Click:Connect(function() task.spawn(injectAnti) end)

task.spawn(function()
	while true do
		task.wait(2.5)
		if antiActive then
			pressKey(muteKey)
			task.wait(0.09)
			pressKey(muteKey)
		end
	end
end)

-- ═══ SELF MUTE ═══
local selfWin = makeWindow("self mute", UDim2.fromOffset(330, 226), { 640, 150 })

local micRow = new("Frame", {
	Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = Color3.fromRGB(20, 26, 48),
	BackgroundTransparency = 0.1, BorderSizePixel = 0, ZIndex = 63,
}, selfWin.body)
corner(micRow, 8)
stroke(micRow, PINK, 1, 0.85)

local micIcon = new("TextLabel", {
	Size = UDim2.fromOffset(26, 26), Position = UDim2.fromOffset(9, 10),
	BackgroundColor3 = PINK, BackgroundTransparency = 0.88, BorderSizePixel = 0,
	Font = F_TXT, Text = "🎙", TextSize = 13, TextColor3 = PINK, ZIndex = 64,
}, micRow)
corner(micIcon, 8)

local micLabel = new("TextLabel", {
	Size = UDim2.new(1, -110, 0, 13), Position = UDim2.fromOffset(44, 9),
	BackgroundTransparency = 1, Font = F_BOLD, Text = "click to mute",
	TextSize = 10, TextColor3 = TEXT, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 64,
}, micRow)

local micSub = new("TextLabel", {
	Size = UDim2.new(1, -110, 0, 11), Position = UDim2.fromOffset(44, 23),
	BackgroundTransparency = 1, Font = F_TXT, Text = "synthetic key press",
	TextSize = 8, TextColor3 = SUB, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 64,
}, micRow)

local keyChip = new("TextButton", {
	Size = UDim2.fromOffset(34, 20), Position = UDim2.new(1, -46, 0, 13),
	BackgroundColor3 = PINK, BackgroundTransparency = 0.88, BorderSizePixel = 0,
	AutoButtonColor = false, Font = F_BOLD, Text = "V",
	TextSize = 9, TextColor3 = PINK, ZIndex = 65,
}, micRow)
corner(keyChip, 6)

micRow.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then
		setMute(not micMuted)
		micLabel.Text = micMuted and "muted" or "click to mute"
		micIcon.TextColor3 = micMuted and RED or PINK
	end
end)

keyChip.MouseButton1Click:Connect(function()
	keyChip.Text = "..."
	local conn
	conn = UIS.InputBegan:Connect(function(input)
		if input.KeyCode ~= Enum.KeyCode.Unknown then
			muteKey = input.KeyCode
			keyChip.Text = input.KeyCode.Name
			conn:Disconnect()
			notify("mute key: " .. input.KeyCode.Name)
		end
	end)
end)

local ptt = new("TextButton", {
	Size = UDim2.new(0.5, -3, 0, 24), BackgroundColor3 = Color3.fromRGB(40, 47, 74),
	BorderSizePixel = 0, AutoButtonColor = false, Font = F_BOLD,
	Text = "push to talk", TextSize = 8, TextColor3 = SUB, ZIndex = 63,
}, selfWin.body)
corner(ptt, 7)

local ptm = new("TextButton", {
	Size = UDim2.new(0.5, -3, 0, 24), Position = UDim2.new(0.5, 3, 0, 0),
	BackgroundColor3 = Color3.fromRGB(40, 47, 74), BorderSizePixel = 0,
	AutoButtonColor = false, Font = F_BOLD, Text = "push to mute",
	TextSize = 8, TextColor3 = SUB, ZIndex = 63,
}, selfWin.body)
corner(ptm, 7)

local function paintMode(which)
	ptt.BackgroundColor3 = which == "talk" and PINK_DEEP or Color3.fromRGB(40, 47, 74)
	ptt.TextColor3 = which == "talk" and NAVY_DEEP or SUB
	ptm.BackgroundColor3 = which == "mute" and PINK_DEEP or Color3.fromRGB(40, 47, 74)
	ptm.TextColor3 = which == "mute" and NAVY_DEEP or SUB
end
ptt.MouseButton1Click:Connect(function() paintMode("talk") end)
ptm.MouseButton1Click:Connect(function() paintMode("mute") end)
paintMode("talk")

local selfNote = new("TextLabel", {
	Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, Font = F_TXT,
	TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
	Text = "Kapag naka-ACTIVE ang anti, awtomatikong pinipindot ito para hindi mag-drop ang mic session.",
	TextSize = 8, TextColor3 = SUB, ZIndex = 63,
}, selfWin.body)

new("UIListLayout", {
	Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
}, selfWin.body)
pad(selfWin.body, 2)

-- ═══ DOCK ═══
local dock = new("Frame", {
	Size = UDim2.fromOffset(150, 34), Position = UDim2.new(0.5, -75, 1, -46),
	BackgroundColor3 = NAVY, BackgroundTransparency = 0.08, BorderSizePixel = 0, ZIndex = 40,
}, hub)
corner(dock, 17)
stroke(dock, PINK, 1, 0.65)

local function dockBtn(txt, x)
	local b = new("TextButton", {
		Size = UDim2.fromOffset(24, 24), Position = UDim2.fromOffset(x, 5),
		BackgroundColor3 = Color3.fromRGB(26, 33, 58), BorderSizePixel = 0,
		AutoButtonColor = false, Font = F_TXT, Text = txt,
		TextSize = 12, TextColor3 = PINK, ZIndex = 41,
	}, dock)
	corner(b, 8)
	return b
end

local pawBtn = dockBtn("🐾", 8)
local gearBtn = dockBtn("⚙", 38)
local menuBtn = dockBtn("≡", 68)
local hideBtn = dockBtn("▾", 98)

local function paintPaw()
	pawBtn.BackgroundColor3 = pawsOn and PINK_DEEP or Color3.fromRGB(26, 33, 58)
	pawBtn.TextColor3 = pawsOn and NAVY_DEEP or PINK
end
pawBtn.MouseButton1Click:Connect(function()
	pawsOn = not pawsOn
	paintPaw()
	notify("paws " .. (pawsOn and "on" or "off"))
end)
paintPaw()

gearBtn.MouseButton1Click:Connect(function()
	drawer.Visible = not drawer.Visible
end)
menuBtn.MouseButton1Click:Connect(function()
	main.Visible = not main.Visible
end)
hideBtn.MouseButton1Click:Connect(function()
	main.Visible = false
	dock.Position = UDim2.new(0.5, -75, 1, -46)
end)

-- ═══ SETTINGS DRAWER ═══
local drawer = new("Frame", {
	Size = UDim2.fromOffset(200, 96), Position = UDim2.new(1, -212, 0, 96),
	BackgroundColor3 = NAVY, BackgroundTransparency = 0.05,
	BorderSizePixel = 0, Visible = false, ZIndex = 50,
}, hub)
corner(drawer, 10)
stroke(drawer, PINK, 1, 0.7)
pad(drawer, 8)
new("UIListLayout", { Padding = UDim.new(0, 6) }, drawer)

local function drawerRow(txt, default)
	local r = new("Frame", {
		Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = Color3.fromRGB(20, 26, 48),
		BackgroundTransparency = 0.1, BorderSizePixel = 0, ZIndex = 51,
	}, drawer)
	corner(r, 7)
	new("TextLabel", {
		Size = UDim2.new(1, -46, 1, 0), Position = UDim2.fromOffset(8, 0),
		BackgroundTransparency = 1, Font = F_MED, Text = txt,
		TextSize = 9, TextColor3 = TEXT, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 52,
	}, r)
	local sw = new("TextButton", {
		Size = UDim2.fromOffset(32, 16), Position = UDim2.new(1, -38, 0, 5),
		BackgroundColor3 = default and PINK_DEEP or Color3.fromRGB(40, 47, 74),
		BorderSizePixel = 0, AutoButtonColor = false, Font = F_BOLD,
		Text = default and "ON" or "OFF", TextSize = 8,
		TextColor3 = default and NAVY_DEEP or SUB, ZIndex = 52,
	}, r)
	corner(sw, 8)
	local state = default
	sw.MouseButton1Click:Connect(function()
		state = not state
		sw.Text = state and "ON" or "OFF"
		sw.BackgroundColor3 = state and PINK_DEEP or Color3.fromRGB(40, 47, 74)
		sw.TextColor3 = state and NAVY_DEEP or SUB
	end)
	return { set = function(v) state = v sw.Text = v and "ON" or "OFF" end }
end

local pawsRow = drawerRow("falling paws", true)
pawsRow.set(pawsOn)

drawerRow("chips visible", true)

local resetBtn = new("TextButton", {
	Size = UDim2.new(1, 0, 0, 22), BackgroundColor3 = PINK, BackgroundTransparency = 0.86,
	BorderSizePixel = 0, AutoButtonColor = false, Font = F_BOLD,
	Text = "reset binds", TextSize = 8, TextColor3 = PINK, ZIndex = 51,
}, drawer)
corner(resetBtn, 6)
resetBtn.MouseButton1Click:Connect(function()
	binds = {}
	notify("binds cleared")
end)

-- ═══ BIND LISTENER ═══
UIS.InputBegan:Connect(function(input, processed)
	if processed then return end

	if listening then
		if input.KeyCode == Enum.KeyCode.Escape then
			binds[listening] = nil
		else
			binds[listening] = input.KeyCode
		end
		local target = listening
		listening = nil
		for _, c in ipairs(cardRefs) do
			local b = c.getBind()
			if b then
				if binds[c and ""] then end
			end
		end
		renderCards()
		if binds[target] then notify("bound " .. target .. " to " .. binds[target].Name) end
		return
	end

	for name, key in pairs(binds) do
		if input.KeyCode == key then
			for _, c in ipairs(cardRefs) do
				if c.frame:GetAttribute("name") == name then
					-- fallback handled by switch click
				end
			end
		end
	end
end)

-- ═══ GLOBAL HANDLERS ═══
UIS.JumpRequest:Connect(function()
	if flags.infjump and hum() then hum():ChangeState(Enum.HumanoidStateType.Jumping) end
end)

LP.CharacterAdded:Connect(function()
	task.wait(1)
	if flags.noclip then setNoclip(true) end
end)

LP.Idled:Connect(function()
	if not flags.afk then return end
	VirtualUser:CaptureController()
	VirtualUser:ClickButton2(Vector2.new())
end)

-- ═══ START ═══
paintTabs()
renderCards()
setProgress(0)

task.delay(0.3, function() notify("slide to continue") end)

if queue_on_teleport then
	pcall(function()
		queue_on_teleport('loadstring(game:HttpGet("' .. LOADER_URL .. '"))()')
	end)
end
