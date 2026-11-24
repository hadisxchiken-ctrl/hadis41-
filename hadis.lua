--[[
	HADIS  //  kani - zafi
	passkey: hadis

	Host: i-upload ito sa public GitHub repo, tapos gamitin ang raw link.
	Executor: i-paste ang loadstring sa ibaba, o ilagay sa autoexec folder.

	loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/hadis.lua"))()
]]

local LOADER_URL = "https://raw.githubusercontent.com/hadis-hub/main/loader.lua"
local PASSKEY = "hadis"

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LP = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- palette
local PINK       = Color3.fromRGB(255, 194, 221)
local PINK_DEEP  = Color3.fromRGB(255, 159, 198)
local PINK_SOFT  = Color3.fromRGB(255, 215, 231)
local NAVY       = Color3.fromRGB(13, 19, 38)
local NAVY_DEEP  = Color3.fromRGB(8, 10, 20)
local TEXT       = Color3.fromRGB(233, 238, 251)
local SUB        = Color3.fromRGB(159, 176, 208)
local LAV        = Color3.fromRGB(201, 184, 255)
local PEACH      = Color3.fromRGB(255, 207, 158)

local LOGO = "rbxassetid://10669437756353535"

-- state
local binds = {}
local autoOn = false
local mode = "night"
local pawsOn = true
local unlocked = false
local injecting = false
local listening = nil

---------------------------------------------------------------------
-- helpers
---------------------------------------------------------------------
local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do
		o[k] = v
	end
	if parent then o.Parent = parent end
	return o
end

local function corner(o, r)
	new("UICorner", { CornerRadius = UDim.new(0, r or 8) }, o)
	return o
end

local function stroke(o, color, thick, trans)
	new("UIStroke", {
		Color = color or Color3.fromRGB(255, 255, 255),
		Thickness = thick or 1,
		Transparency = trans or 0.85,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, o)
	return o
end

local function grad(o, c1, c2, rot, t1, t2)
	local g = new("UIGradient", { Rotation = rot or 90 }, o)
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, c1),
		ColorSequenceKeypoint.new(1, c2),
	})
	if t1 or t2 then
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, t1 or 0),
			NumberSequenceKeypoint.new(1, t2 or 0),
		})
	end
	return o
end

local function txt(parent, text, size, color, bold)
	return new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham,
		Text = text,
		TextSize = size,
		TextColor3 = color or TEXT,
		TextXAlignment = Enum.TextXAlignment.Left,
		RichText = false,
	}, parent)
end

local function btn(parent, text, size, color)
	local b = new("TextButton", {
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Font = Enum.Font.GothamBold,
		Text = text or "",
		TextSize = size or 10,
		TextColor3 = color or SUB,
	}, parent)
	return b
end

local function roundBtn(parent, glyph, size, color)
	local b = btn(parent, glyph, size or 11, color or SUB)
	b.Size = UDim2.fromOffset(22, 22)
	b.TextColor3 = color or SUB
	new("UIPadding", {}, b)
	corner(b, 6)
	stroke(b, Color3.new(1, 1, 1), 1, 0.93)
	return b
end

---------------------------------------------------------------------
-- gui root
---------------------------------------------------------------------
local gui = new("ScreenGui", {
	Name = "HadisHub",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 20,
}, LP:WaitForChild("PlayerGui"))

local root = new("Frame", {
	Name = "Root",
	Size = UDim2.fromOffset(700, 715),
	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundTransparency = 1,
	ClipsDescendants = true,
}, gui)
corner(root, 18)

local uiscale = new("UIScale", { Scale = 1 }, root)
local function fit()
	local vp = camera.ViewportSize
	uiscale.Scale = math.min(vp.X / 740, vp.Y / 755, 1)
end
fit()
camera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)

---------------------------------------------------------------------
-- toast
---------------------------------------------------------------------
local toast = new("TextLabel", {
	BackgroundColor3 = PINK,
	BackgroundTransparency = 0.06,
	Size = UDim2.fromOffset(180, 26),
	Position = UDim2.new(0.5, -90, 1, -30),
	AnchorPoint = Vector2.new(0, 0),
	Font = Enum.Font.GothamBold,
	Text = "",
	TextSize = 10,
	TextColor3 = NAVY,
	Visible = false,
	ZIndex = 90,
}, root)
corner(toast, 8)

local toastToken = 0
local function notify(message)
	toastToken += 1
	local token = toastToken
	toast.Text = message:lower()
	toast.Visible = true
	toast.TextTransparency = 0
	task.delay(1.6, function()
		if token == toastToken then
			toast.Visible = false
		end
	end)
end

---------------------------------------------------------------------
-- scene
---------------------------------------------------------------------
local scene = new("Frame", {
	Name = "Scene",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	ClipsDescendants = true,
	ZIndex = 1,
}, root)

local sky = new("Frame", { Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, ZIndex = 1 }, scene)
local skyGrad = grad(sky, Color3.fromRGB(4, 5, 12), Color3.fromRGB(77, 56, 100), 90)

local starHolder = new("Frame", { Size = UDim2.fromScale(1, 0.62), BackgroundTransparency = 1, ZIndex = 2 }, scene)
for _ = 1, 70 do
	local s = new("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = math.random(15, 60) / 100,
		Size = UDim2.fromOffset(2, 2),
		Position = UDim2.fromScale(math.random() / 1, math.random() / 1),
		ZIndex = 2,
	}, starHolder)
	corner(s, 2)
end

-- clouds
local cloudHolder = new("Frame", { Size = UDim2.fromScale(1, 0.5), BackgroundTransparency = 1, ZIndex = 2 }, scene)
local function cloud(px, py, w, h, trans)
	local c = new("Frame", {
		BackgroundColor3 = Color3.fromRGB(28, 22, 52),
		BackgroundTransparency = trans,
		Size = UDim2.fromOffset(w, h),
		Position = UDim2.fromScale(px, py),
		ZIndex = 2,
	}, cloudHolder)
	corner(c, h / 2)
	return c
end
cloud(0.02, 0.14, 210, 78, 0.25)
cloud(0.05, 0.34, 180, 70, 0.35)
cloud(0.42, 0.30, 250, 95, 0.45)
cloud(0.78, 0.44, 210, 80, 0.5)

-- moon glow + moon
local glow = new("Frame", {
	BackgroundColor3 = Color3.fromRGB(255, 169, 205),
	BackgroundTransparency = 0.86,
	Size = UDim2.fromOffset(300, 300),
	Position = UDim2.fromOffset(200, 282),
	ZIndex = 2,
}, scene)
corner(glow, 150)

local moon = new("Frame", {
	BackgroundColor3 = Color3.new(1, 1, 1),
	Size = UDim2.fromOffset(184, 184),
	Position = UDim2.fromOffset(258, 340),
	ZIndex = 3,
}, scene)
corner(moon, 92)
local moonGrad = grad(moon, Color3.new(1, 1, 1), Color3.fromRGB(247, 168, 201), 120)

-- water
local water = new("Frame", {
	BackgroundColor3 = Color3.fromRGB(21, 17, 34),
	Size = UDim2.new(1, 0, 0, 180),
	Position = UDim2.fromOffset(0, 462),
	BorderSizePixel = 0,
	ZIndex = 3,
}, scene)
grad(water, Color3.fromRGB(91, 71, 103), Color3.fromRGB(10, 8, 18), 90)

-- glitter
local glitter = new("Frame", { Size = UDim2.fromScale(1, 0.25), Position = UDim2.fromOffset(0, 470), BackgroundTransparency = 1, ZIndex = 4 }, scene)
for i = 1, 8 do
	local e = new("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 208, 228),
		BackgroundTransparency = 0.45,
		Size = UDim2.fromOffset(20 + i * 5, 2),
		Position = UDim2.fromOffset(300 + (i % 2 == 0 and 18 or -24), i * 18),
		ZIndex = 4,
	}, glitter)
	corner(e, 2)
end

-- wave crests
local waveHolder = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 4 }, scene)
local waves = {}
for i = 1, 6 do
	local w = new("Frame", {
		BackgroundColor3 = Color3.fromRGB(243, 230, 238),
		BackgroundTransparency = 0.55 - i * 0.03,
		Size = UDim2.new(1.06, 0, 0, 5 + i * 2),
		Position = UDim2.fromOffset(-21, 470 + i * 20),
		ZIndex = 4,
	}, waveHolder)
	corner(w, 20)
	table.insert(waves, w)
end

-- shoreline foam
local foam = new("Frame", {
	BackgroundColor3 = Color3.fromRGB(243, 230, 238),
	BackgroundTransparency = 0.5,
	Size = UDim2.new(1.06, 0, 0, 12),
	Position = UDim2.fromOffset(-21, 608),
	ZIndex = 4,
}, scene)
corner(foam, 12)

-- sand
local sand = new("Frame", {
	BackgroundColor3 = Color3.fromRGB(78, 61, 74),
	Size = UDim2.new(1, 0, 0, 115),
	Position = UDim2.fromOffset(0, 600),
	BorderSizePixel = 0,
	ZIndex = 5,
}, scene)
grad(sand, Color3.fromRGB(111, 90, 104), Color3.fromRGB(42, 32, 40), 90)

-- logo
local logo = new("ImageLabel", {
	Image = LOGO,
	ImageColor3 = PINK,
	BackgroundTransparency = 1,
	Size = UDim2.fromOffset(104, 134),
	Position = UDim2.new(0.5, -52, 0, 105),
	ZIndex = 6,
}, scene)

-- slider
local slider = new("Frame", {
	BackgroundColor3 = Color3.fromRGB(20, 14, 30),
	BackgroundTransparency = 0.4,
	Size = UDim2.fromOffset(316, 52),
	Position = UDim2.new(0.5, -158, 1, -162),
	ZIndex = 6,
}, scene)
corner(slider, 26)
stroke(slider, PINK, 1, 0.5)

local sliderFill = new("Frame", {
	BackgroundColor3 = PINK,
	BackgroundTransparency = 0.6,
	Size = UDim2.fromOffset(0, 52),
	ZIndex = 7,
}, slider)
corner(sliderFill, 26)

local sliderLabel = new("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	Font = Enum.Font.GothamBold,
	Text = "hadis",
	TextSize = 13,
	TextColor3 = Color3.new(1, 1, 1),
	ZIndex = 7,
}, slider)

local knob = new("TextButton", {
	BackgroundColor3 = PINK_SOFT,
	AutoButtonColor = false,
	Size = UDim2.fromOffset(40, 40),
	Position = UDim2.fromOffset(6, 6),
	Text = "",
	ZIndex = 8,
}, slider)
corner(knob, 20)
stroke(knob, Color3.new(1, 1, 1), 1, 0.6)
new("ImageLabel", {
	Image = LOGO,
	ImageColor3 = Color3.fromRGB(125, 44, 77),
	BackgroundTransparency = 1,
	Size = UDim2.fromOffset(20, 20),
	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),
	ZIndex = 9,
}, knob)

---------------------------------------------------------------------
-- gate
---------------------------------------------------------------------
local gate = new("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(5, 8, 18),
	BackgroundTransparency = 0.45,
	Visible = false,
	ZIndex = 20,
}, scene)

local gateCard = new("Frame", {
	BackgroundColor3 = NAVY,
	Size = UDim2.fromOffset(300, 150),
	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),
	ZIndex = 21,
}, gate)
corner(gateCard, 16)
stroke(gateCard, PINK, 1, 0.85)

local gateTitle = txt(gateCard, "passkey", 13, PINK, true)
gateTitle.Size = UDim2.new(1, 0, 0, 20)
gateTitle.Position = UDim2.fromOffset(0, 16)
gateTitle.TextXAlignment = Enum.TextXAlignment.Center

local gateSub = txt(gateCard, "enter the key to continue", 10, SUB)
gateSub.Size = UDim2.new(1, 0, 0, 16)
gateSub.Position = UDim2.fromOffset(0, 38)
gateSub.TextXAlignment = Enum.TextXAlignment.Center

local gateInput = new("TextBox", {
	BackgroundColor3 = Color3.fromRGB(10, 16, 32),
	Size = UDim2.new(1, -32, 0, 40),
	Position = UDim2.fromOffset(16, 64),
	Font = Enum.Font.Gotham,
	Text = "",
	PlaceholderText = "• • • • •",
	TextSize = 12,
	TextColor3 = Color3.new(1, 1, 1),
	PlaceholderColor3 = SUB,
	TextXAlignment = Enum.TextXAlignment.Center,
	ClearTextOnFocus = false,
	ZIndex = 22,
}, gateCard)
corner(gateInput, 10)
stroke(gateInput, PINK, 1, 0.85)

local dots = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 10), Position = UDim2.fromOffset(0, 118), ZIndex = 22 }, gateCard)
for i = 1, 5 do
	local d = new("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.8,
		Size = UDim2.fromOffset(6, 6),
		Position = UDim2.new(0.5, -39 + (i - 1) * 16, 0, 0),
		ZIndex = 22,
	}, dots)
	corner(d, 3)
	d.Name = "Dot" .. i
end

local function refreshDots()
	for i = 1, 5 do
		local d = dots:FindFirstChild("Dot" .. i)
		if d then
			d.BackgroundTransparency = (#gateInput.Text >= i) and 0.1 or 0.8
			d.BackgroundColor3 = PINK
		end
	end
end

---------------------------------------------------------------------
-- hub
---------------------------------------------------------------------
local hub = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 10 }, root)

-- dock
local dock = new("Frame", {
	BackgroundColor3 = NAVY,
	BackgroundTransparency = 0.1,
	Size = UDim2.new(1, -32, 0, 42),
	Position = UDim2.fromOffset(16, 12),
	ZIndex = 60,
}, hub)
corner(dock, 12)
stroke(dock, PINK, 1, 0.85)

local dockRow = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 61 }, dock)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }, dockRow)
new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, dockRow)

local function dockBtn(glyph, order)
	local b = roundBtn(dockRow, glyph, 11)
	b.Size = UDim2.fromOffset(28, 28)
	b.LayoutOrder = order
	corner(b, 9)
	return b
end

local function dockChip(text, order)
	local c = new("TextLabel", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.95,
		Size = UDim2.fromOffset(52, 22),
		Font = Enum.Font.Gotham,
		Text = text,
		TextSize = 10,
		TextColor3 = SUB,
		LayoutOrder = order,
		ZIndex = 62,
	}, dockRow)
	corner(c, 7)
	return c
end

local btnBack = dockBtn("‹", 1)
btnBack.TextColor3 = PINK
dockChip("3/12", 2)
dockChip("70 ms", 3)
dockChip("-120 fps", 4)

local dockSpacer = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(10, 10), LayoutOrder = 5 }, dockRow)
new("UISizeConstraint", {}, dockSpacer)

local btnPaws = dockBtn("", 6)
local pawsIcon = new("ImageLabel", {
	Image = LOGO,
	ImageColor3 = SUB,
	BackgroundTransparency = 1,
	Size = UDim2.fromOffset(15, 15),
	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),
	ZIndex = 63,
}, btnPaws)

local btnMode = dockBtn("☀", 7)
local btnDrop = dockBtn("▾", 8)
local btnSearch = dockBtn("◎", 9)
local btnRefresh = dockBtn("⟳", 10)

local btnAvatar = dockBtn("", 11)
new("ImageLabel", {
	Image = LOGO,
	ImageColor3 = PINK,
	BackgroundTransparency = 1,
	Size = UDim2.fromOffset(20, 20),
	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),
	ZIndex = 63,
}, btnAvatar)

local btnMenu = dockBtn("≡", 12)

---------------------------------------------------------------------
-- window factory
---------------------------------------------------------------------
local function makeWindow(name, size, pos, z)
	local win = new("Frame", {
		Name = name,
		BackgroundColor3 = Color3.fromRGB(12, 10, 18),
		BackgroundTransparency = 0.06,
		Size = size,
		Position = pos,
		ZIndex = z,
		Visible = false,
	}, hub)
	corner(win, 14)
	stroke(win, PINK, 1, 0.8)

	local header = new("Frame", {
		BackgroundColor3 = PINK,
		BackgroundTransparency = 0.92,
		Size = UDim2.new(1, 0, 0, 38),
		ZIndex = z + 1,
	}, win)
	corner(header, 14)

	local headRow = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = z + 2 }, header)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Center }, headRow)
	new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 8) }, headRow)

	local tag = txt(headRow, "41$", 12, PINK, true)
	tag.Size = UDim2.fromOffset(28, 20)
	tag.LayoutOrder = 1

	local title = txt(headRow, name, 11, TEXT, true)
	title.Size = UDim2.fromOffset(150, 20)
	title.LayoutOrder = 2

	local spacer = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(6, 6), LayoutOrder = 3 }, headRow)

	local bindChip = new("TextButton", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.94,
		Size = UDim2.fromOffset(34, 16),
		Font = Enum.Font.GothamBold,
		Text = "bind",
		TextSize = 8,
		TextColor3 = SUB,
		LayoutOrder = 4,
		ZIndex = z + 3,
	}, headRow)
	corner(bindChip, 5)
	stroke(bindChip, Color3.new(1, 1, 1), 1, 0.9)

	local minBtn = roundBtn(headRow, "–", 11)
	minBtn.Size = UDim2.fromOffset(22, 22)
	minBtn.LayoutOrder = 5
	minBtn.ZIndex = z + 3
	minBtn.BackgroundTransparency = 0.95
	corner(minBtn, 6)

	local closeBtn = roundBtn(headRow, "×", 11)
	closeBtn.Size = UDim2.fromOffset(22, 22)
	closeBtn.LayoutOrder = 6
	closeBtn.ZIndex = z + 3
	closeBtn.BackgroundTransparency = 0.95
	corner(closeBtn, 6)

	local body = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, -38),
		Position = UDim2.fromOffset(0, 38),
		ZIndex = z + 1,
	}, win)

	return { win = win, header = header, body = body, min = minBtn, close = closeBtn, title = title, bind = bindChip }
end

-- main window
local mainWin = new("Frame", {
	Name = "kani - zafi",
	BackgroundColor3 = NAVY,
	BackgroundTransparency = 0.04,
	Size = UDim2.fromOffset(640, 400),
	Position = UDim2.new(0.5, -320, 0, 70),
	ZIndex = 30,
	Visible = false,
}, hub)
corner(mainWin, 14)
stroke(mainWin, PINK, 1, 0.85)

local mainHeader = new("Frame", {
	BackgroundColor3 = PINK,
	BackgroundTransparency = 0.9,
	Size = UDim2.new(1, 0, 0, 40),
	ZIndex = 31,
}, mainWin)
corner(mainHeader, 14)

local mainHeadRow = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 32 }, mainHeader)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 7), VerticalAlignment = Enum.VerticalAlignment.Center }, mainHeadRow)
new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 8) }, mainHeadRow)

local mainLogo = new("ImageLabel", {
	Image = LOGO,
	ImageColor3 = PINK,
	BackgroundTransparency = 1,
	Size = UDim2.fromOffset(22, 22),
	LayoutOrder = 1,
	ZIndex = 33,
}, mainHeadRow)

local mainTitle = txt(mainHeadRow, "kani - zafi", 11, TEXT, true)
mainTitle.Size = UDim2.fromOffset(200, 20)
mainTitle.LayoutOrder = 2

local mainEnd = new("TextButton", {
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 0.95,
	AutoButtonColor = false,
	Size = UDim2.fromOffset(30, 22),
	Font = Enum.Font.GothamBold,
	Text = "end",
	TextSize = 9,
	TextColor3 = SUB,
	LayoutOrder = 3,
	ZIndex = 33,
}, mainHeadRow)
corner(mainEnd, 6)

local mainMin = roundBtn(mainHeadRow, "–", 11)
mainMin.Size = UDim2.fromOffset(22, 22)
mainMin.LayoutOrder = 4
mainMin.ZIndex = 33
mainMin.BackgroundTransparency = 0.95
corner(mainMin, 6)

local mainClose = roundBtn(mainHeadRow, "×", 11)
mainClose.Size = UDim2.fromOffset(22, 22)
mainClose.LayoutOrder = 5
mainClose.ZIndex = 33
mainClose.BackgroundTransparency = 0.95
corner(mainClose, 6)

local tabsRow = new("Frame", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 32),
	Position = UDim2.fromOffset(0, 40),
	ZIndex = 32,
}, mainWin)
local tabsLayout = new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), VerticalAlignment = Enum.VerticalAlignment.Center }, tabsRow)
new("UIPadding", { PaddingLeft = UDim.new(0, 9) }, tabsRow)

local bodyScroll = new("ScrollingFrame", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 1, -78),
	Position = UDim2.fromOffset(0, 74),
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 4,
	ScrollBarImageColor3 = PINK,
	ZIndex = 32,
}, mainWin)
new("UIListLayout", { Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder }, bodyScroll)
new("UIPadding", { PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9), PaddingBottom = UDim.new(0, 9) }, bodyScroll)

-- anti window
local anti = makeWindow("ANTI VC BAN", UDim2.fromOffset(404, 366), UDim2.new(1, -418, 0, 78), 40)
local selfWin = makeWindow("SELF MUTE", UDim2.fromOffset(330, 226), UDim2.fromOffset(22, 150), 44)
local discord = makeWindow("DISCORD", UDim2.fromOffset(270, 130), UDim2.new(0.5, -135, 0, 170), 50)

---------------------------------------------------------------------
-- anti body
---------------------------------------------------------------------
local function sectionLabel(parent, text, y)
	local bar = new("Frame", {
		BackgroundColor3 = PINK,
		Size = UDim2.fromOffset(3, 12),
		Position = UDim2.fromOffset(12, y),
		ZIndex = 42,
	}, parent)
	corner(bar, 2)
	local l = txt(parent, text, 8, PINK_SOFT)
	l.Size = UDim2.fromOffset(200, 12)
	l.Position = UDim2.fromOffset(21, y)
	l.ZIndex = 42
	return l
end

sectionLabel(anti.body, "STATUS", 10)

local statusCard = new("Frame", {
	BackgroundColor3 = PINK,
	BackgroundTransparency = 0.94,
	Size = UDim2.new(1, -24, 0, 54),
	Position = UDim2.fromOffset(12, 28),
	ZIndex = 42,
}, anti.body)
corner(statusCard, 10)
stroke(statusCard, PINK, 1, 0.65)

local statusDot = new("Frame", {
	BackgroundColor3 = PINK,
	Size = UDim2.fromOffset(9, 9),
	Position = UDim2.fromOffset(11, 22),
	ZIndex = 43,
}, statusCard)
corner(statusDot, 5)

local statusLabel = txt(statusCard, "IDLE", 10, PINK, true)
statusLabel.Size = UDim2.fromOffset(150, 14)
statusLabel.Position = UDim2.fromOffset(28, 12)
statusLabel.ZIndex = 43

local statusSub = txt(statusCard, "Not injected yet.", 9, SUB)
statusSub.Size = UDim2.fromOffset(200, 14)
statusSub.Position = UDim2.fromOffset(28, 28)
statusSub.ZIndex = 43

local refreshBtn = roundBtn(statusCard, "⟳", 11)
refreshBtn.Size = UDim2.fromOffset(20, 20)
refreshBtn.Position = UDim2.new(1, -30, 0, 17)
refreshBtn.ZIndex = 43
refreshBtn.BackgroundTransparency = 0.94

sectionLabel(anti.body, "METHOD", 92)

local methods = {}
local function makeMethod(y, name, badgeText, badgeColor, tint, desc, order)
	local row = new("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.98,
		Size = UDim2.new(1, -24, 0, 62),
		Position = UDim2.fromOffset(12, y),
		ZIndex = 42,
	}, anti.body)
	corner(row, 10)
	stroke(row, Color3.new(1, 1, 1), 1, 0.93)

	local bar = new("Frame", {
		BackgroundColor3 = tint,
		Size = UDim2.fromOffset(3, 62),
		ZIndex = 43,
	}, row)

	local radio = new("Frame", {
		BackgroundColor3 = Color3.fromRGB(12, 10, 18),
		Size = UDim2.fromOffset(13, 13),
		Position = UDim2.fromOffset(11, 12),
		ZIndex = 43,
	}, row)
	corner(radio, 7)
	stroke(radio, Color3.fromRGB(85, 72, 90), 2, 0)

	local t = txt(row, name, 10, TEXT, true)
	t.Size = UDim2.fromOffset(150, 14)
	t.Position = UDim2.fromOffset(32, 8)
	t.ZIndex = 43

	local badge = new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(80, 10),
		Position = UDim2.fromOffset(32 + math.min(#name * 6, 130), 10),
		Font = Enum.Font.GothamBold,
		Text = badgeText,
		TextSize = 7,
		TextColor3 = badgeColor,
		ZIndex = 43,
	}, row)

	local d = txt(row, desc, 8, Color3.fromRGB(139, 127, 139))
	d.Size = UDim2.new(1, -110, 0, 26)
	d.Position = UDim2.fromOffset(32, 26)
	d.TextWrapped = true
	d.ZIndex = 43

	local sel = new("TextButton", {
		BackgroundColor3 = tint,
		BackgroundTransparency = 0.92,
		AutoButtonColor = false,
		Size = UDim2.fromOffset(76, 28),
		Position = UDim2.new(1, -86, 0, 17),
		Font = Enum.Font.GothamBold,
		Text = "SELECT",
		TextSize = 8,
		TextColor3 = tint,
		ZIndex = 43,
	}, row)
	corner(sel, 8)
	stroke(sel, tint, 1, 0.7)

	local entry = { row = row, radio = radio, sel = sel, tint = tint, name = name }
	table.insert(methods, entry)
	return entry
end

makeMethod(114, "Legacy Anti VC Ban", "RECOMMENDED", PINK, PINK, "This is the newly designed Anti VC Ban. Recommended for all.")
makeMethod(182, "Original Anti VC", "DEFAULT", LAV, LAV, "The original Anti VC Ban. For lower-end devices; less demanding.")
makeMethod(250, "Revised Anti VC Ban", "EXPERIMENTAL", PEACH, PEACH, "Uses Roblox's voice chat muting. Least demanding, yet buggy.")

---------------------------------------------------------------------
-- self mute body
---------------------------------------------------------------------
local micIcon = new("ImageLabel", {
	Image = LOGO,
	ImageColor3 = PINK,
	BackgroundTransparency = 1,
	Size = UDim2.fromOffset(15, 15),
	Position = UDim2.fromOffset(12, 12),
	ZIndex = 46,
}, selfWin.body)

local micLabel = txt(selfWin.body, "click to mute", 11, TEXT)
micLabel.Size = UDim2.fromOffset(140, 16)
micLabel.Position = UDim2.fromOffset(33, 12)
micLabel.ZIndex = 46

local micKey = txt(selfWin.body, "1", 10, PINK)
micKey.Size = UDim2.fromOffset(20, 16)
micKey.Position = UDim2.new(1, -30, 0, 12)
micKey.TextXAlignment = Enum.TextXAlignment.Right
micKey.ZIndex = 46

local keyLabel = txt(selfWin.body, "mute key", 9, SUB)
keyLabel.Size = UDim2.fromOffset(100, 14)
keyLabel.Position = UDim2.fromOffset(12, 36)
keyLabel.ZIndex = 46

local keyChip = new("TextButton", {
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 0.94,
	AutoButtonColor = false,
	Size = UDim2.fromOffset(30, 20),
	Position = UDim2.new(1, -52, 0, 34),
	Font = Enum.Font.GothamBold,
	Text = "V",
	TextSize = 10,
	TextColor3 = TEXT,
	ZIndex = 46,
}, selfWin.body)
corner(keyChip, 6)

local keyClear = btn(selfWin.body, "×", 9, SUB)
keyClear.Size = UDim2.fromOffset(18, 18)
keyClear.Position = UDim2.new(1, -24, 0, 35)
keyClear.ZIndex = 46

local function toggleRow(y, text, store)
	local row = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -24, 0, 30), Position = UDim2.fromOffset(12, y), ZIndex = 46 }, selfWin.body)
	local l = txt(row, text, 10, TEXT)
	l.Size = UDim2.new(1, -40, 0, 30)
	l.ZIndex = 46
	local sw = new("TextButton", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.85,
		AutoButtonColor = false,
		Size = UDim2.fromOffset(30, 16),
		Position = UDim2.new(1, -30, 0, 7),
		Text = "",
		ZIndex = 46,
	}, row)
	corner(sw, 9)
	local knobDot = new("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), Size = UDim2.fromOffset(12, 12), Position = UDim2.fromOffset(2, 2), ZIndex = 47 }, sw)
	corner(knobDot, 6)
	local on = false
	sw.MouseButton1Click:Connect(function()
		on = not on
		sw.BackgroundTransparency = on and 0.1 or 0.85
		sw.BackgroundColor3 = on and PINK_DEEP or Color3.new(1, 1, 1)
		TweenService:Create(knobDot, TweenInfo.new(0.15), { Position = UDim2.fromOffset(on and 16 or 2, 2) }):Play()
	end)
	return sw
end

toggleRow(64, "push to talk (hold to unmute)")
toggleRow(98, "push to mute (hold to mute)")

local foot = txt(selfWin.body, "Getting warnings can be normal. You will not lose voice chat privileges from this by itself. Avoid being reported by players.", 8, Color3.fromRGB(119, 105, 111))
foot.Size = UDim2.new(1, -24, 0, 40)
foot.Position = UDim2.fromOffset(12, 134)
foot.TextWrapped = true
foot.TextYAlignment = Enum.TextYAlignment.Top
foot.ZIndex = 46

-- discord body
local discordRow = new("Frame", { BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.96, Size = UDim2.new(1, -20, 0, 40), Position = UDim2.fromOffset(10, 10), ZIndex = 52 }, discord.body)
corner(discordRow, 8)
local discordText = txt(discordRow, "discord.gg/hadis", 10, TEXT, true)
discordText.Size = UDim2.new(1, -20, 0, 16)
discordText.Position = UDim2.fromOffset(10, 6)
discordText.ZIndex = 53
local discordSub = txt(discordRow, "updates, keys, support", 8, SUB)
discordSub.Size = UDim2.new(1, -20, 0, 14)
discordSub.Position = UDim2.fromOffset(10, 22)
discordSub.ZIndex = 53

local copyDisc = btn(discord.body, "copy invite", 9, PINK)
copyDisc.Size = UDim2.new(1, -20, 0, 26)
copyDisc.Position = UDim2.fromOffset(10, 58)
copyDisc.ZIndex = 52
corner(copyDisc, 7)
stroke(copyDisc, PINK, 1, 0.75)

---------------------------------------------------------------------
-- bubble
---------------------------------------------------------------------
local bubble = new("TextButton", {
	BackgroundColor3 = NAVY,
	BackgroundTransparency = 0.06,
	Size = UDim2.fromOffset(52, 52),
	Position = UDim2.fromOffset(22, 600),
	Text = "",
	Visible = false,
	ZIndex = 70,
}, hub)
corner(bubble, 26)
stroke(bubble, PINK, 1, 0.6)
new("ImageLabel", { Image = LOGO, ImageColor3 = PINK, BackgroundTransparency = 1, Size = UDim2.fromOffset(26, 26), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 71 }, bubble)

---------------------------------------------------------------------
-- drawer
---------------------------------------------------------------------
local drawer = new("Frame", {
	BackgroundColor3 = Color3.fromRGB(10, 15, 30),
	BackgroundTransparency = 0.02,
	Size = UDim2.fromOffset(230, 1),
	Position = UDim2.new(1, 230, 0, 0),
	ZIndex = 80,
}, hub)
new("UIListLayout", { Padding = UDim.new(0, 8) }, drawer)
new("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 14) }, drawer)

local drawerTitle = txt(drawer, "SETTINGS", 10, PINK, true)
drawerTitle.Size = UDim2.new(1, 0, 0, 14)

local function drawerRow(text, callback)
	local row = new("TextButton", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.96,
		AutoButtonColor = false,
		Size = UDim2.new(1, 0, 0, 30),
		Text = "",
		ZIndex = 81,
	}, drawer)
	corner(row, 8)
	local l = txt(row, text, 10, TEXT)
	l.Size = UDim2.new(1, -12, 0, 30)
	l.Position = UDim2.fromOffset(8, 0)
	l.ZIndex = 82
	row.MouseButton1Click:Connect(callback)
	return row
end

local drawerBack = drawerRow("back to intro", function() end)
local drawerClose = drawerRow("close", function() end)

local function toggleDrawer(open)
	TweenService:Create(drawer, TweenInfo.new(0.25), {
		Position = open and UDim2.new(1, -230, 0, 0) or UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0, 230, 1, 0),
	}):Play()
	if open then
		drawer.Size = UDim2.new(0, 230, 1, 0)
		drawer.Position = UDim2.new(1, 230, 0, 0)
		TweenService:Create(drawer, TweenInfo.new(0.25), { Position = UDim2.new(1, -230, 0, 0) }):Play()
	end
end

---------------------------------------------------------------------
-- search overlay
---------------------------------------------------------------------
local overlay = new("Frame", {
	BackgroundColor3 = Color3.fromRGB(5, 8, 18),
	BackgroundTransparency = 0.25,
	Size = UDim2.fromScale(1, 1),
	Visible = false,
	ZIndex = 85,
}, hub)

local searchBox = new("Frame", {
	BackgroundColor3 = NAVY,
	Size = UDim2.fromOffset(420, 330),
	Position = UDim2.new(0.5, -210, 0, 90),
	ZIndex = 86,
}, overlay)
corner(searchBox, 12)
stroke(searchBox, PINK, 1, 0.85)

local searchInput = new("TextBox", {
	BackgroundColor3 = Color3.fromRGB(10, 16, 32),
	Size = UDim2.new(1, 0, 0, 38),
	Font = Enum.Font.Gotham,
	Text = "",
	PlaceholderText = "search scripts...",
	TextSize = 11,
	TextColor3 = TEXT,
	PlaceholderColor3 = SUB,
	TextXAlignment = Enum.TextXAlignment.Left,
	ClearTextOnFocus = false,
	ZIndex = 87,
}, searchBox)
new("UIPadding", { PaddingLeft = UDim.new(0, 12) }, searchInput)

local searchResults = new("ScrollingFrame", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 1, -44),
	Position = UDim2.fromOffset(0, 44),
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 3,
	ZIndex = 87,
}, searchBox)
new("UIListLayout", { Padding = UDim.new(0, 3) }, searchResults)
new("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }, searchResults)

---------------------------------------------------------------------
-- data + rendering
---------------------------------------------------------------------
local DATA = {
	all = {},
	main = {
		{ n = "auto execute", k = "auto" },
		{ n = "server hop" },
		{ n = "rejoin" },
		{ n = "respawn" },
	},
	player = {
		{ n = "walk speed" },
		{ n = "jump power" },
		{ n = "fly" },
		{ n = "noclip" },
		{ n = "infinite jump" },
	},
	combat = {
		{ n = "aimbot" },
		{ n = "kill aura" },
		{ n = "hitbox expander" },
		{ n = "auto parry" },
	},
	visual = {
		{ n = "full bright" },
		{ n = "player esp" },
		{ n = "xray" },
		{ n = "fov zoom" },
	},
	voice = {
		{ n = "anti vc ban", k = "anti" },
	},
	misc = {
		{ n = "anti afk" },
		{ n = "fps unlock" },
		{ n = "ping reducer" },
		{ n = "chat spy" },
	},
}

local TABS = { "all", "main", "player", "combat", "visual", "voice", "misc" }
for _, tab in ipairs(TABS) do
	if tab ~= "all" then
		for _, card in ipairs(DATA[tab]) do
			table.insert(DATA.all, { n = card.n, k = card.k, tab = tab })
		end
	end
end

local currentTab = "all"
local tabButtons = {}

local function renderTabs()
	for tab, b in pairs(tabButtons) do
		b.BackgroundTransparency = (tab == currentTab) and 0.82 or 0.97
		b.TextColor3 = (tab == currentTab) and Color3.new(1, 1, 1) or SUB
	end
end

local function setTab(tab)
	currentTab = tab
	renderTabs()
end

local exec

local function bindChipFor(card)
	local chip = new("TextButton", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.94,
		AutoButtonColor = false,
		Size = UDim2.fromOffset(38, 16),
		Font = Enum.Font.GothamBold,
		Text = binds[card.n] and binds[card.n].Name or "bind",
		TextSize = 8,
		TextColor3 = binds[card.n] and PINK or SUB,
		ZIndex = 34,
	}, nil)
	corner(chip, 5)
	return chip
end

local function render()
	bodyScroll:ClearAllChildren()
	new("UIListLayout", { Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder }, bodyScroll)
	new("UIPadding", { PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9), PaddingBottom = UDim.new(0, 9) }, bodyScroll)

	local order = 0
	for _, card in ipairs(DATA[currentTab] or {}) do
		order += 1

		local row = new("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.96,
			Size = UDim2.new(1, -18, 0, card.k == "auto" and 96 or 52),
			LayoutOrder = order,
			ZIndex = 33,
		}, bodyScroll)
		corner(row, 10)
		stroke(row, Color3.new(1, 1, 1), 1, 0.94)

		local dot = new("Frame", { BackgroundColor3 = PINK, Size = UDim2.fromOffset(5, 5), Position = UDim2.fromOffset(9, 11), ZIndex = 34 }, row)
		corner(dot, 3)

		local name = txt(row, card.n, 11, TEXT, true)
		name.Size = UDim2.new(1, -100, 0, 16)
		name.Position = UDim2.fromOffset(20, 6)
		name.ZIndex = 34

		local chip = bindChipFor(card)
		chip.Position = UDim2.new(1, -72, 0, 6)
		chip.Parent = row
		chip.MouseButton1Click:Connect(function()
			listening = card.n
			chip.Text = "press key"
			chip.TextColor3 = NAVY
			chip.BackgroundTransparency = 0.1
			chip.BackgroundColor3 = PINK
		end)

		local switch = new("TextButton", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = (card.k == "auto" and autoOn) and 0.1 or 0.85,
			AutoButtonColor = false,
			Size = UDim2.fromOffset(30, 16),
			Position = UDim2.new(1, -32, 0, 7),
			Text = "",
			ZIndex = 34,
		}, row)
		corner(switch, 9)

		local swDot = new("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), Size = UDim2.fromOffset(12, 12), Position = UDim2.fromOffset((card.k == "auto" and autoOn) and 16 or 2, 2), ZIndex = 35 }, switch)
		corner(swDot, 6)

		switch.MouseButton1Click:Connect(function()
			if card.k == "auto" then
				autoOn = not autoOn
				switch.BackgroundTransparency = autoOn and 0.1 or 0.85
				switch.BackgroundColor3 = autoOn and PINK_DEEP or Color3.new(1, 1, 1)
				TweenService:Create(swDot, TweenInfo.new(0.15), { Position = UDim2.fromOffset(autoOn and 16 or 2, 2) }):Play()
				notify(autoOn and "auto execute enabled" or "auto execute disabled")
			else
				switch.BackgroundTransparency = 0.1
				switch.BackgroundColor3 = PINK_DEEP
			end
		end)

		if card.k == "auto" then
			local codeBox = new("TextLabel", {
				BackgroundColor3 = Color3.fromRGB(8, 13, 26),
				Size = UDim2.new(1, -18, 0, 38),
				Position = UDim2.fromOffset(9, 26),
				Font = Enum.Font.Code,
				Text = 'loadstring(game:HttpGet("' .. LOADER_URL .. '"))()',
				TextSize = 9,
				TextColor3 = Color3.fromRGB(159, 230, 196),
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 34,
			}, row)
			corner(codeBox, 7)
			new("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingTop = UDim.new(0, 4) }, codeBox)

			local copy = btn(row, "copy", 8, SUB)
			copy.Size = UDim2.fromOffset(32, 14)
			copy.Position = UDim2.new(1, -40, 0, 28)
			copy.ZIndex = 35
			corner(copy, 4)
			copy.MouseButton1Click:Connect(function()
				pcall(function() setclipboard('loadstring(game:HttpGet("' .. LOADER_URL .. '"))()') end)
				notify("loader copied")
			end)
		end

		local run = new("TextButton", {
			BackgroundColor3 = PINK,
			BackgroundTransparency = 0.92,
			AutoButtonColor = false,
			Size = UDim2.new(1, -18, 0, 18),
			Position = UDim2.new(0, 9, 1, card.k == "auto" and -24 or -26),
			Font = Enum.Font.GothamBold,
			Text = "EXECUTE",
			TextSize = 8,
			TextColor3 = PINK,
			ZIndex = 34,
		}, row)
		corner(run, 6)
		run.MouseButton1Click:Connect(function()
			exec(card.n, card.k)
		end)
	end
end

for _, tab in ipairs(TABS) do
	local b = new("TextButton", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.97,
		AutoButtonColor = false,
		Size = UDim2.fromOffset(52, 22),
		Font = Enum.Font.Gotham,
		Text = tab,
		TextSize = 10,
		TextColor3 = SUB,
		ZIndex = 33,
	}, tabsRow)
	corner(b, 7)
	tabButtons[tab] = b
	b.MouseButton1Click:Connect(function() setTab(tab) end)
end

---------------------------------------------------------------------
-- anti logic
---------------------------------------------------------------------
local activeMethod = methods[1]

local function paintMethods()
	for _, m in ipairs(methods) do
		local isOn = (m == activeMethod)
		m.row.BackgroundTransparency = isOn and 0.94 or 0.98
		m.radio.BackgroundColor3 = isOn and PINK or Color3.fromRGB(12, 10, 18)
		m.radio.BackgroundTransparency = isOn and 0 or 1
		m.sel.Text = isOn and "ACTIVE" or "SELECT"
	end
end

local function injectAnti()
	if injecting then return end
	injecting = true
	anti.win.Visible = true
	anti.win.Size = UDim2.fromOffset(404, 366)
	statusLabel.Text = "INJECTING"
	statusLabel.TextColor3 = PINK
	statusSub.Text = "Injecting " .. activeMethod.name .. " method..."
	statusDot.BackgroundTransparency = 0.3

	task.wait(1.7)

	statusLabel.Text = "ACTIVE"
	statusSub.Text = "Using " .. activeMethod.name .. " method."
	statusDot.BackgroundTransparency = 0
	selfWin.win.Visible = true
	selfWin.win.Size = UDim2.fromOffset(330, 226)
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

refreshBtn.MouseButton1Click:Connect(function()
	task.spawn(injectAnti)
end)

exec = function(name, kind)
	if kind == "anti" then
		task.spawn(injectAnti)
		return
	end
	notify("executed • " .. name)
end

---------------------------------------------------------------------
-- binds
---------------------------------------------------------------------
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
		render()
		if binds[target] then
			notify("bound " .. target .. " to " .. binds[target].Name)
		end
		return
	end

	if UIS:GetFocusedTextBox() then return end

	for name, key in pairs(binds) do
		if input.KeyCode == key then
			for _, tab in ipairs(TABS) do
				for _, card in ipairs(DATA[tab]) do
					if card.n == name then
						exec(card.n, card.k)
					end
				end
			end
		end
	end
end)

---------------------------------------------------------------------
-- gate + slider
---------------------------------------------------------------------
local sliderPos = 0
local sliderDragging = false
local SLIDER_MAX = 316 - 40 - 12

local function openGate()
	gate.Visible = true
	gateInput.Text = ""
	refreshDots()
	task.defer(function() gateInput:CaptureFocus() end)
end

local function unlock()
	gate.Visible = false
	scene.Visible = true
	hub.Visible = true
	mainWin.Visible = true
	unlocked = true
	render()
	notify("welcome, kani")
end

gateInput:GetPropertyChangedSignal("Text"):Connect(refreshDots)
gateInput.FocusLost:Connect(function(enter)
	if not enter then return end
	if gateInput.Text:lower() == PASSKEY then
		unlock()
	else
		gateInput.Text = ""
		refreshDots()
		notify("wrong passkey")
	end
end)

knob.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		sliderDragging = true
	end
end)

UIS.InputChanged:Connect(function(input)
	if not sliderDragging then return end
	if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
	local abs = slider.AbsolutePosition
	local x = input.Position.X - abs.X - 26
	sliderPos = math.clamp(x, 0, SLIDER_MAX)
	knob.Position = UDim2.fromOffset(6 + sliderPos, 6)
	sliderFill.Size = UDim2.fromOffset(sliderPos + 6, 52)
end)

UIS.InputEnded:Connect(function(input)
	if not sliderDragging then return end
	sliderDragging = false
	if sliderPos >= SLIDER_MAX - 8 then
		openGate()
	else
		sliderPos = 0
		knob.Position = UDim2.fromOffset(6, 6)
		sliderFill.Size = UDim2.fromOffset(0, 52)
	end
end)

---------------------------------------------------------------------
-- dragging
---------------------------------------------------------------------
local function makeDraggable(frame, handle)
	local dragging = false
	local startPos, startInput

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			startPos = frame.Position
			startInput = input.Position
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
		local delta = input.Position - startInput
		frame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end)

	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end

makeDraggable(mainWin, mainHeader)
makeDraggable(anti.win, anti.header)
makeDraggable(selfWin.win, selfWin.header)
makeDraggable(discord.win, discord.header)
makeDraggable(bubble, bubble)

---------------------------------------------------------------------
-- minimize / close
---------------------------------------------------------------------
local function collapse(win, body, minButton)
	local isMini = win:GetAttribute("Mini")
	isMini = not isMini
	win:SetAttribute("Mini", isMini)
	body.Visible = not isMini
	minButton.Text = isMini and "+" or "–"
	if win == anti.win then
		win.Size = isMini and UDim2.fromOffset(404, 38) or UDim2.fromOffset(404, 366)
	elseif win == selfWin.win then
		win.Size = isMini and UDim2.fromOffset(330, 38) or UDim2.fromOffset(330, 226)
	elseif win == discord.win then
		win.Size = isMini and UDim2.fromOffset(270, 38) or UDim2.fromOffset(270, 130)
	elseif win == mainWin then
		win.Size = isMini and UDim2.fromOffset(640, 40) or UDim2.fromOffset(640, 400)
		tabsRow.Visible = not isMini
		bodyScroll.Visible = not isMini
	end
end

anti.min.MouseButton1Click:Connect(function() collapse(anti.win, anti.body, anti.min) end)
selfWin.min.MouseButton1Click:Connect(function() collapse(selfWin.win, selfWin.body, selfWin.min) end)
discord.min.MouseButton1Click:Connect(function() collapse(discord.win, discord.body, discord.min) end)

anti.close.MouseButton1Click:Connect(function() anti.win.Visible = false end)
selfWin.close.MouseButton1Click:Connect(function() selfWin.win.Visible = false end)
discord.close.MouseButton1Click:Connect(function() discord.win.Visible = false end)

mainMin.MouseButton1Click:Connect(function()
	if mainWin:GetAttribute("Mini") then
		mainWin.Visible = false
		dock.Visible = false
		bubble.Visible = true
	else
		collapse(mainWin, bodyScroll, mainMin)
	end
end)

bubble.MouseButton1Click:Connect(function()
	bubble.Visible = false
	mainWin.Visible = true
	mainWin:SetAttribute("Mini", false)
	mainWin.Size = UDim2.fromOffset(640, 400)
	mainMin.Text = "–"
	tabsRow.Visible = true
	bodyScroll.Visible = true
	dock.Visible = true
end)

---------------------------------------------------------------------
-- back to intro
---------------------------------------------------------------------
local function backToIntro()
	for _, win in ipairs({ anti.win, selfWin.win, discord.win }) do
		win.Visible = false
		win:SetAttribute("Mini", false)
		win.Size = UDim2.fromOffset(win == anti.win and 404 or (win == selfWin.win and 330 or 270), 38)
	end
	anti.win.Size = UDim2.fromOffset(404, 366)
	selfWin.win.Size = UDim2.fromOffset(330, 226)
	discord.win.Size = UDim2.fromOffset(270, 130)
	anti.min.Text = "–"
	selfWin.min.Text = "–"
	discord.min.Text = "–"
	anti.body.Visible = true
	selfWin.body.Visible = true
	discord.body.Visible = true

	overlay.Visible = false
	toggleDrawer(false)
	bubble.Visible = false
	hub.Visible = false
	dock.Visible = true
	mainWin:SetAttribute("Mini", false)
	mainWin.Size = UDim2.fromOffset(640, 400)
	mainMin.Text = "–"
	tabsRow.Visible = true
	bodyScroll.Visible = true
	gate.Visible = false
	gateInput.Text = ""
	refreshDots()
	sliderPos = 0
	knob.Position = UDim2.fromOffset(6, 6)
	sliderFill.Size = UDim2.fromOffset(0, 52)
	notify("back to intro")
end

btnBack.MouseButton1Click:Connect(backToIntro)
mainEnd.MouseButton1Click:Connect(backToIntro)
mainClose.MouseButton1Click:Connect(backToIntro)
drawerBack.MouseButton1Click:Connect(backToIntro)
drawerClose.MouseButton1Click:Connect(function() toggleDrawer(false) end)

---------------------------------------------------------------------
-- dock actions
---------------------------------------------------------------------
local dockFolded = false
btnDrop.MouseButton1Click:Connect(function()
	dockFolded = not dockFolded
	btnDrop.Text = dockFolded and "▴" or "▾"
	for _, child in ipairs(dockRow:GetChildren()) do
		if child:IsA("GuiObject") and child ~= btnDrop then
			child.Visible = not dockFolded
		end
	end
	dock.Size = dockFolded and UDim2.fromOffset(42, 42) or UDim2.new(1, -32, 0, 42)
end)

local function setMode(m)
	mode = m
	if m == "night" then
		skyGrad.Color = ColorSequence.new(Color3.fromRGB(4, 5, 12), Color3.fromRGB(77, 56, 100))
		moonGrad.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(247, 168, 201))
		sand.BackgroundColor3 = Color3.fromRGB(78, 61, 74)
		starHolder.Visible = true
		btnMode.Text = "☀"
	else
		skyGrad.Color = ColorSequence.new(Color3.fromRGB(255, 227, 239), Color3.fromRGB(43, 53, 96))
		moonGrad.Color = ColorSequence.new(Color3.fromRGB(255, 248, 221), Color3.fromRGB(255, 181, 107))
		sand.BackgroundColor3 = Color3.fromRGB(32, 48, 92)
		starHolder.Visible = false
		btnMode.Text = "☾"
	end
end
setMode("night")
btnMode.MouseButton1Click:Connect(function() setMode(mode == "night" and "day" or "night") end)

local function setPaws(on)
	pawsOn = on
	pawsIcon.ImageColor3 = on and PINK or SUB
	btnPaws.BackgroundColor3 = on and PINK or Color3.fromRGB(255, 255, 255)
	btnPaws.BackgroundTransparency = on and 0.1 or 0.95
	notify(on and "paws on" or "paws off")
end
setPaws(true)
btnPaws.MouseButton1Click:Connect(function() setPaws(not pawsOn) end)

btnRefresh.MouseButton1Click:Connect(function()
	render()
	notify("refreshed")
end)

btnMenu.MouseButton1Click:Connect(function() toggleDrawer(true) end)
btnAvatar.MouseButton1Click:Connect(function() discord.win.Visible = true end)

local function runSearch(query)
	searchResults:ClearAllChildren()
	new("UIListLayout", { Padding = UDim.new(0, 3) }, searchResults)
	new("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }, searchResults)

	local seen = {}
	for _, card in ipairs(DATA.all) do
		if not seen[card.n] and (query == "" or card.n:lower():find(query:lower(), 1, true)) then
			seen[card.n] = true
			local item = new("TextButton", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.96,
				AutoButtonColor = false,
				Size = UDim2.new(1, -12, 0, 26),
				Font = Enum.Font.Gotham,
				Text = card.n .. "   ·   " .. (card.tab or ""),
				TextSize = 10,
				TextColor3 = SUB,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 88,
			}, searchResults)
			corner(item, 6)
			item.MouseButton1Click:Connect(function()
				overlay.Visible = false
				exec(card.n, card.k)
			end)
		end
	end
end

btnSearch.MouseButton1Click:Connect(function()
	overlay.Visible = true
	searchInput.Text = ""
	runSearch("")
	task.defer(function() searchInput:CaptureFocus() end)
end)

searchInput:GetPropertyChangedSignal("Text"):Connect(function()
	runSearch(searchInput.Text)
end)

overlay.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		overlay.Visible = false
	end
end)

---------------------------------------------------------------------
-- self mute + discord
---------------------------------------------------------------------
keyChip.MouseButton1Click:Connect(function()
	keyChip.Text = "key"
	local conn
	conn = UIS.InputBegan:Connect(function(input)
		if input.KeyCode ~= Enum.KeyCode.Unknown then
			keyChip.Text = input.KeyCode.Name
			conn:Disconnect()
		end
	end)
end)

keyClear.MouseButton1Click:Connect(function() keyChip.Text = "V" end)

copyDisc.MouseButton1Click:Connect(function()
	pcall(function() setclipboard("discord.gg/hadis") end)
	notify("invite copied")
end)

---------------------------------------------------------------------
-- paws (falling)
---------------------------------------------------------------------
local pawFolder = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 8 }, scene)

task.spawn(function()
	while true do
		task.wait(0.45)
		if pawsOn then
			local p = new("ImageLabel", {
				Image = LOGO,
				ImageColor3 = PINK,
				ImageTransparency = 0.35,
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(math.random(11, 22), math.random(11, 22)),
				Position = UDim2.fromScale(math.random(), -0.05),
				Rotation = math.random(0, 360),
				ZIndex = 8,
			}, pawFolder)

			local size = p.AbsoluteSize.X
			p.Size = UDim2.fromOffset(size, size)

			local duration = math.random(70, 130) / 10
			local target = math.random(110, 150) / 100

			local tween = TweenService:Create(p, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
				Position = UDim2.fromScale(p.Position.X.Scale, target),
				Rotation = p.Rotation + math.random(160, 320),
			})
			tween:Play()
			tween.Completed:Connect(function()
				p:Destroy()
			end)
		end
	end
end)

---------------------------------------------------------------------
-- start
---------------------------------------------------------------------
render()
task.delay(0.2, function()
	notify("slide to continue")
end)

if queue_on_teleport then
	pcall(function()
		queue_on_teleport('loadstring(game:HttpGet("' .. LOADER_URL .. '"))()')
	end)
end