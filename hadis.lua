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
new("
