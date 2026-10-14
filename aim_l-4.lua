-- LocalScript -> StarterPlayer > StarterPlayerScripts
-- Tombol "–" = jadi bulatan mini (klik bulatan untuk membuka lagi)
-- A- / A+ = kecilkan / besarkan UI | RightShift = sembunyikan/tampilkan menu

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local S = {
	Aim = true, Part = "Head",
	Mode = (UIS.TouchEnabled and not UIS.MouseEnabled) and "Always" or "Hold",
	Smooth = 0.5, Prediction = 0.06, AimTeam = true, WallCheck = true, Sticky = true, AimNPC = true,
	ESP = true, Box = true, Names = true, Health = true, Dist = true, Tracers = false, Chams = true,
	ESPTeam = true, ESPNPC = true, MaxDist = 1500,
}

local C = {
	bg = Color3.fromRGB(14, 14, 20), card = Color3.fromRGB(28, 28, 38),
	accent = Color3.fromRGB(120, 100, 255), accent2 = Color3.fromRGB(70, 200, 255),
	text = Color3.fromRGB(235, 235, 245), dim = Color3.fromRGB(150, 150, 170), off = Color3.fromRGB(58, 58, 74),
}
local ENEMY, ALLY = Color3.fromRGB(255, 70, 70), Color3.fromRGB(70, 255, 120)

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end
local function corner(o, r) return new("UICorner", {CornerRadius = UDim.new(0, r or 8)}, o) end
local function outline(o, col, th, tr) return new("UIStroke", {Color = col, Thickness = th, Transparency = tr}, o) end
local function isPress(i) return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch end
local function isMove(i) return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch end

local lastWarn = 0
local function safe(fn, ...)
	local ok, r = pcall(fn, ...)
	if not ok and os.clock() - lastWarn > 3 then
		lastWarn = os.clock()
		warn("[AimPanel] " .. tostring(r))
	end
	return ok and r or nil
end

---------------------------------------------------------------- GUI
local PG = LP:WaitForChild("PlayerGui")
local old = PG:FindFirstChild("AimPanel")
if old then old:Destroy() end

local gui = new("ScreenGui", {Name = "AimPanel", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 50,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, PG)
local espLayer = new("Frame", {Name = "ESPLayer", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0}, gui)

local main = new("Frame", {Name = "Main", Size = UDim2.fromOffset(270, 380), Position = UDim2.fromOffset(20, 80),
	BackgroundColor3 = C.bg, BorderSizePixel = 0, Active = true, ClipsDescendants = true}, gui)
corner(main, 14)
outline(main, C.accent, 1.2, 0.35)
local uiScale = new("UIScale", {Scale = 1}, main)

local bubble = new("TextButton", {Name = "Mini", Size = UDim2.fromOffset(46, 46), Position = UDim2.fromOffset(20, 80),
	BackgroundColor3 = C.bg, Text = "◎", TextColor3 = C.accent2, Font = Enum.Font.GothamBold, TextSize = 24,
	AutoButtonColor = false, Visible = false, BorderSizePixel = 0}, gui)
corner(bubble, 23)
outline(bubble, C.accent, 1.5, 0.2)

local function makeDraggable(handle, target, onClick)
	local down, moved, startIn, startPos = false, false, nil, nil
	handle.InputBegan:Connect(function(i)
		if isPress(i) then down, moved, startIn, startPos = true, false, i.Position, target.Position end
	end)
	UIS.InputChanged:Connect(function(i)
		if down and isMove(i) then
			local d = i.Position - startIn
			if d.Magnitude > 4 then moved = true end
			if moved then
				local sc = target:FindFirstChildOfClass("UIScale")
				local k = sc and sc.Scale or 1
				target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X / k,
					startPos.Y.Scale, startPos.Y.Offset + d.Y / k)
			end
		end
	end)
	UIS.InputEnded:Connect(function(i)
		if down and isPress(i) then
			down = false
			if not moved and onClick then onClick() end
		end
	end)
end

local header = new("Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1}, main)
local title = new("TextLabel", {Text = "◎  AIM PANEL", Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -120, 1, 0),
	BackgroundTransparency = 1, TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 15,
	TextXAlignment = Enum.TextXAlignment.Left}, header)
new("UIGradient", {Color = ColorSequence.new(C.accent, C.accent2)}, title)
local line = new("Frame", {Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 0, 2), BorderSizePixel = 0,
	BackgroundColor3 = Color3.new(1, 1, 1)}, main)
new("UIGradient", {Color = ColorSequence.new(C.accent, C.accent2)}, line)

local function hBtn(text, x)
	local b = new("TextButton", {Text = text, Size = UDim2.fromOffset(26, 24), Position = UDim2.new(1, x, 0, 8),
		BackgroundColor3 = C.card, TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 12, AutoButtonColor = false}, header)
	corner(b, 6)
	return b
end
local miniBtn = hBtn("–", -34)
local plusBtn = hBtn("A+", -64)
local minusBtn = hBtn("A-", -94)

local function setScale(v) uiScale.Scale = math.clamp(math.round(v * 10) / 10, 0.6, 1.6) end
plusBtn.MouseButton1Click:Connect(function() setScale(uiScale.Scale + 0.1) end)
minusBtn.MouseButton1Click:Connect(function() setScale(uiScale.Scale - 0.1) end)

local isMini, hiddenUI = false, false
local function applyVis()
	main.Visible = not hiddenUI and not isMini
	bubble.Visible = not hiddenUI and isMini
end
miniBtn.MouseButton1Click:Connect(function()
	bubble.Position = UDim2.fromOffset(main.AbsolutePosition.X, main.AbsolutePosition.Y)
	isMini = true
	applyVis()
end)
makeDraggable(header, main)
makeDraggable(bubble, bubble, function()
	main.Position = UDim2.fromOffset(bubble.AbsolutePosition.X / uiScale.Scale, bubble.AbsolutePosition.Y / uiScale.Scale)
	isMini = false
	applyVis()
end)
UIS.InputBegan:Connect(function(i, gp)
	if not gp and i.KeyCode == Enum.KeyCode.RightShift then hiddenUI = not hiddenUI; applyVis() end
end)

-- tombol cepat ON/OFF (bisa digeser, F5 = sembunyikan)
local quick = new("TextButton", {Name = "QuickToggle", Size = UDim2.fromOffset(92, 32), Position = UDim2.new(0.5, -46, 0, 12),
	BackgroundColor3 = C.bg, Text = "AIM: ON", TextColor3 = ALLY, Font = Enum.Font.GothamBold, TextSize = 13,
	AutoButtonColor = false, BorderSizePixel = 0}, gui)
corner(quick, 16)
outline(quick, C.accent, 1.2, 0.3)
local function paintQuick()
	quick.Text = S.Aim and "AIM: ON" or "AIM: OFF"
	quick.TextColor3 = S.Aim and ALLY or ENEMY
end
makeDraggable(quick, quick, function() S.Aim = not S.Aim; paintQuick() end)
UIS.InputBegan:Connect(function(i, gp)
	if not gp and i.KeyCode == Enum.KeyCode.F5 then quick.Visible = not quick.Visible end
end)

-- nama target yang sedang dikunci
local lockLabel = new("TextLabel", {Size = UDim2.fromOffset(220, 20), AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 52), BackgroundTransparency = 1, TextColor3 = Color3.new(1, 1, 1),
	TextStrokeTransparency = 0, Font = Enum.Font.GothamBold, TextSize = 16, Visible = false}, gui)

local tabs = new("Frame", {Position = UDim2.fromOffset(8, 50), Size = UDim2.new(1, -16, 0, 28), BackgroundTransparency = 1}, main)
local content = new("Frame", {Position = UDim2.fromOffset(8, 86), Size = UDim2.new(1, -16, 1, -114),
	BackgroundTransparency = 1, ClipsDescendants = true}, main)
local status = new("TextLabel", {Text = "Target terdeteksi: 0", Position = UDim2.new(0, 12, 1, -22), Size = UDim2.new(1, -24, 0, 18),
	BackgroundTransparency = 1, TextColor3 = C.dim, Font = Enum.Font.Gotham, TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left}, main)

local pages, tabBtns = {}, {}
local function show(name)
	for n, pg in pairs(pages) do pg.Visible = (n == name) end
	for n, b in pairs(tabBtns) do
		b.BackgroundColor3 = (n == name) and C.accent or C.card
		b.TextColor3 = (n == name) and Color3.new(1, 1, 1) or C.dim
	end
end
local function addTab(name, idx)
	local pg = new("ScrollingFrame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 3, ScrollBarImageColor3 = C.accent, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false}, content)
	new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, pg)
	new("UIPadding", {PaddingRight = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6)}, pg)
	pages[name] = pg
	local b = new("TextButton", {Text = name, Size = UDim2.new(0.5, -3, 1, 0), Position = UDim2.new((idx - 1) * 0.5, (idx - 1) * 3, 0, 0),
		BackgroundColor3 = C.card, TextColor3 = C.dim, Font = Enum.Font.GothamBold, TextSize = 13, AutoButtonColor = false}, tabs)
	corner(b, 8)
	tabBtns[name] = b
	b.MouseButton1Click:Connect(function() show(name) end)
	return pg
end

local function nextOrder(pg)
	local n = (pg:GetAttribute("n") or 0) + 1
	pg:SetAttribute("n", n)
	return n
end

local function label(parent, text, pos, size, color, font, align, ts)
	return new("TextLabel", {Text = text, Position = pos, Size = size, BackgroundTransparency = 1,
		TextColor3 = color or C.text, Font = font or Enum.Font.Gotham, TextSize = ts or 13,
		TextXAlignment = align or Enum.TextXAlignment.Left}, parent)
end

local function section(pg, text)
	local l = label(pg, text, UDim2.new(), UDim2.new(1, 0, 0, 18), C.accent2, Enum.Font.GothamBold, nil, 11)
	l.LayoutOrder = nextOrder(pg)
end

local function toggle(pg, text, key)
	local r = new("TextButton", {Text = "", Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = C.card,
		AutoButtonColor = false, LayoutOrder = nextOrder(pg)}, pg)
	corner(r, 8)
	label(r, text, UDim2.fromOffset(10, 0), UDim2.new(1, -60, 1, 0))
	local pill = new("Frame", {Size = UDim2.fromOffset(36, 18), Position = UDim2.new(1, -46, 0.5, -9), BackgroundColor3 = C.off}, r)
	corner(pill, 9)
	local knob = new("Frame", {Size = UDim2.fromOffset(14, 14), Position = UDim2.fromOffset(2, 2), BackgroundColor3 = Color3.new(1, 1, 1)}, pill)
	corner(knob, 7)
	local function paint()
		local on = S[key]
		TweenService:Create(pill, TweenInfo.new(0.15), {BackgroundColor3 = on and C.accent or C.off}):Play()
		TweenService:Create(knob, TweenInfo.new(0.15), {Position = on and UDim2.fromOffset(20, 2) or UDim2.fromOffset(2, 2)}):Play()
	end
	paint()
	r.MouseButton1Click:Connect(function() S[key] = not S[key]; paint() end)
end

local function segmented(pg, text, key, opts)
	local r = new("Frame", {Size = UDim2.new(1, 0, 0, 60), BackgroundColor3 = C.card, LayoutOrder = nextOrder(pg)}, pg)
	corner(r, 8)
	label(r, text, UDim2.fromOffset(10, 5), UDim2.new(1, -20, 0, 16))
	local holder = new("Frame", {Position = UDim2.fromOffset(8, 27), Size = UDim2.new(1, -16, 0, 26), BackgroundTransparency = 1}, r)
	local btns, n = {}, #opts
	local function paint()
		for o, b in pairs(btns) do
			b.BackgroundColor3 = (S[key] == o) and C.accent or C.off
			b.TextColor3 = (S[key] == o) and Color3.new(1, 1, 1) or C.dim
		end
	end
	for i, o in ipairs(opts) do
		local b = new("TextButton", {Text = o, Size = UDim2.new(1 / n, -4, 1, 0), Position = UDim2.new((i - 1) / n, 2, 0, 0),
			BackgroundColor3 = C.off, TextColor3 = C.dim, Font = Enum.Font.GothamBold, TextSize = 12, AutoButtonColor = false}, holder)
		corner(b, 6)
		btns[o] = b
		b.MouseButton1Click:Connect(function() S[key] = o; paint() end)
	end
	paint()
end

local function slider(pg, text, key, min, max, step)
	local r = new("Frame", {Size = UDim2.new(1, 0, 0, 48), BackgroundColor3 = C.card, Active = true, LayoutOrder = nextOrder(pg)}, pg)
	corner(r, 8)
	label(r, text, UDim2.fromOffset(10, 5), UDim2.new(1, -70, 0, 16))
	local val = label(r, "", UDim2.new(1, -62, 0, 5), UDim2.fromOffset(52, 16), C.accent2, Enum.Font.GothamBold, Enum.TextXAlignment.Right)
	local track = new("Frame", {Position = UDim2.fromOffset(10, 31), Size = UDim2.new(1, -20, 0, 8), BackgroundColor3 = C.off}, r)
	corner(track, 4)
	local fill = new("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.accent}, track)
	corner(fill, 4)
	new("UIGradient", {Color = ColorSequence.new(C.accent, C.accent2)}, fill)
	local function set(v)
		v = math.clamp(math.round(v / step) * step, min, max)
		S[key] = v
		fill.Size = UDim2.fromScale((v - min) / (max - min), 1)
		val.Text = tostring(math.round(v * 1000) / 1000)
	end
	set(S[key])
	local drag = false
	local function upd(x) set(min + (max - min) * math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)) end
	r.InputBegan:Connect(function(i)
		if isPress(i) then drag = true; pg.ScrollingEnabled = false; upd(i.Position.X) end
	end)
	UIS.InputChanged:Connect(function(i) if drag and isMove(i) then upd(i.Position.X) end end)
	UIS.InputEnded:Connect(function(i)
		if drag and isPress(i) then drag = false; pg.ScrollingEnabled = true end
	end)
end

local aimPage = addTab("AIMBOT", 1)
section(aimPage, "AIMBOT")
toggle(aimPage, "Aimbot", "Aim")
segmented(aimPage, "Target", "Part", {"Head", "Neck", "Body"})
segmented(aimPage, "Mode (klik kanan)", "Mode", {"Hold", "Always"})
slider(aimPage, "Nempel Aim", "Smooth", 0.05, 1, 0.01)
slider(aimPage, "Prediksi", "Prediction", 0, 0.3, 0.005)
section(aimPage, "FILTER")
toggle(aimPage, "Abaikan Satu Tim", "AimTeam")
toggle(aimPage, "Termasuk NPC / Dummy", "AimNPC")
toggle(aimPage, "Wall Check", "WallCheck")
toggle(aimPage, "Sticky Lock", "Sticky")

local espPage = addTab("ESP", 2)
section(espPage, "ESP PLAYER")
toggle(espPage, "ESP", "ESP")
toggle(espPage, "Box", "Box")
toggle(espPage, "Nama", "Names")
toggle(espPage, "Health Bar", "Health")
toggle(espPage, "Jarak", "Dist")
toggle(espPage, "Tracer", "Tracers")
toggle(espPage, "Chams (tembus tembok)", "Chams")
section(espPage, "FILTER")
toggle(espPage, "Sembunyikan Satu Tim", "ESPTeam")
toggle(espPage, "Termasuk NPC / Dummy", "ESPNPC")
slider(espPage, "Jarak Maks", "MaxDist", 100, 3000, 50)
show("AIMBOT")

---------------------------------------------------------------- TARGET LIST
-- semua karakter (pemain + NPC) yang punya Humanoid dikumpulkan di sini
local ents = {}

local function addEnt(char)
	if not char or ents[char] or not char:IsA("Model") then return end
	ents[char] = {char = char, player = Players:GetPlayerFromCharacter(char)}
end

for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("Humanoid") then addEnt(d.Parent) end
end
workspace.DescendantAdded:Connect(function(d)
	if d:IsA("Humanoid") then task.defer(addEnt, d.Parent) end
end)

local function sameTeam(e)
	return e.player ~= nil and LP.Team ~= nil and e.player.Team == LP.Team
end

local function destroyUI(e)
	local u = e.ui
	if not u then return end
	for _, o in pairs(u) do pcall(function() o:Destroy() end) end
	e.ui = nil
end

---------------------------------------------------------------- ESP
local function buildUI(e)
	local u = {}
	u.box = new("Frame", {BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false}, espLayer)
	u.stroke = new("UIStroke", {Thickness = 1.5, Color = ENEMY}, u.box)
	u.hpBack = new("Frame", {BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Visible = false}, espLayer)
	u.hpFill = new("Frame", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 1),
		BorderSizePixel = 0, BackgroundColor3 = ALLY}, u.hpBack)
	u.name = new("TextLabel", {Size = UDim2.fromOffset(140, 14), BackgroundTransparency = 1, TextColor3 = Color3.new(1, 1, 1),
		TextStrokeTransparency = 0, Font = Enum.Font.GothamBold, TextSize = 13, Visible = false}, espLayer)
	u.dist = new("TextLabel", {Size = UDim2.fromOffset(140, 14), BackgroundTransparency = 1, TextColor3 = C.text,
		TextStrokeTransparency = 0.3, Font = Enum.Font.Gotham, TextSize = 12, Visible = false}, espLayer)
	u.tracer = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, BackgroundColor3 = ENEMY, Visible = false}, espLayer)
	u.hl = new("Highlight", {FillTransparency = 0.55, OutlineTransparency = 0, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
		FillColor = ENEMY, OutlineColor = Color3.new(1, 1, 1), Enabled = false}, e.char)
	e.ui = u
end

local function hideUI(e)
	local u = e.ui
	if not u then return end
	u.box.Visible, u.hpBack.Visible, u.name.Visible, u.dist.Visible, u.tracer.Visible = false, false, false, false, false
	u.hl.Enabled = false
end

local function updateESP(e)
	local char = e.char
	local hum = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
	local head = char:FindFirstChild("Head")
	local allowed = e.player ~= nil or S.ESPNPC
	local dist = root and (root.Position - Camera.CFrame.Position).Magnitude or math.huge

	if not (S.ESP and allowed and hum and root and head and hum.Health > 0 and dist <= S.MaxDist
		and not (S.ESPTeam and sameTeam(e))) then
		hideUI(e)
		return
	end
	if not e.ui then buildUI(e) end
	local u = e.ui

	local top = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.8, 0))
	local bot = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
	if top.Z <= 0 or bot.Z <= 0 then hideUI(e); return end

	local col = sameTeam(e) and ALLY or ENEMY
	local h = math.max(math.abs(bot.Y - top.Y), 8)
	local w = h * 0.55
	local cx = (top.X + bot.X) / 2
	local ty = math.min(top.Y, bot.Y)

	u.hl.Enabled = S.Chams
	u.hl.FillColor = col

	u.box.Visible = S.Box
	u.stroke.Color = col
	u.box.Position = UDim2.fromOffset(cx - w / 2, ty)
	u.box.Size = UDim2.fromOffset(w, h)

	local frac = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
	u.hpBack.Visible = S.Health
	u.hpBack.Position = UDim2.fromOffset(cx - w / 2 - 6, ty)
	u.hpBack.Size = UDim2.fromOffset(3, h)
	u.hpFill.Size = UDim2.fromScale(1, frac)
	u.hpFill.BackgroundColor3 = ENEMY:Lerp(ALLY, frac)

	u.name.Visible = S.Names
	u.name.Text = e.player and e.player.DisplayName or char.Name
	u.name.Position = UDim2.fromOffset(cx - 70, ty - 16)

	u.dist.Visible = S.Dist
	u.dist.Text = string.format("%dm", math.floor(dist))
	u.dist.Position = UDim2.fromOffset(cx - 70, ty + h + 1)

	if S.Tracers then
		local vp = Camera.ViewportSize
		local from, to = Vector2.new(vp.X / 2, vp.Y), Vector2.new(cx, ty + h)
		local d = to - from
		u.tracer.Visible = true
		u.tracer.BackgroundColor3 = col
		u.tracer.Size = UDim2.fromOffset(d.Magnitude, 1.5)
		u.tracer.Position = UDim2.fromOffset((from.X + to.X) / 2, (from.Y + to.Y) / 2)
		u.tracer.Rotation = math.deg(math.atan2(d.Y, d.X))
	else
		u.tracer.Visible = false
	end
end

---------------------------------------------------------------- AIM
local current
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.RespectCanCollide = true

local function aimPoint(char)
	local head = char:FindFirstChild("Head")
	local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
	if S.Part == "Head" then return head and head.Position
	elseif S.Part == "Neck" then
		return head and (head.Position - head.CFrame.UpVector * head.Size.Y * 0.5)
	end
	return torso and torso.Position
end

local function lineClear(pos, char)
	if not S.WallCheck then return true end
	rayParams.FilterDescendantsInstances = {LP.Character, char}
	return workspace:Raycast(Camera.CFrame.Position, pos - Camera.CFrame.Position, rayParams) == nil
end

local function check(e)
	local char = e.char
	local hum = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
	if not (hum and root and hum.Health > 0) then return end
	if char == LP.Character then return end
	if not e.player and not S.AimNPC then return end
	if S.AimTeam and sameTeam(e) then return end
	local pos = aimPoint(char)
	if not pos then return end
	pos = pos + root.AssemblyLinearVelocity * S.Prediction
	local sp, on = Camera:WorldToViewportPoint(pos)
	if not on then return end
	if not lineClear(pos, char) then return end
	return pos, (Vector2.new(sp.X, sp.Y) - Camera.ViewportSize / 2).Magnitude
end

local function getTarget()
	if S.Sticky and current and ents[current.char] then
		local pos = check(current)
		if pos then return pos end
	end
	current = nil
	local bestPos, bestD = nil, math.huge
	for _, e in pairs(ents) do
		local pos, d = check(e)
		if pos and d < bestD then current, bestPos, bestD = e, pos, d end
	end
	return bestPos
end

local function holding()
	return S.Mode == "Always" or UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
end

---------------------------------------------------------------- LOOP
local statusT = 0
RunService:BindToRenderStep("AimPanelLoop", Enum.RenderPriority.Camera.Value + 1, function(dt)
	Camera = workspace.CurrentCamera

	local count = 0
	for char, e in pairs(ents) do
		if not char:IsDescendantOf(workspace) or char == LP.Character then
			destroyUI(e)
			if char ~= LP.Character then ents[char] = nil end
		else
			count += 1
			safe(updateESP, e)
		end
	end

	statusT += dt
	if statusT > 0.5 then
		statusT = 0
		status.Text = "Target terdeteksi: " .. count
	end

	paintQuick()
	local locked = false
	if S.Aim and holding() then
		local pos = safe(getTarget)
		if pos then
			locked = true
			local goal = CFrame.lookAt(Camera.CFrame.Position, pos)
			local alpha = S.Smooth >= 1 and 1 or math.clamp(1 - (1 - S.Smooth) ^ (dt * 60), 0, 1)
			Camera.CFrame = Camera.CFrame:Lerp(goal, alpha)
			if current then
				lockLabel.Text = "🎯 " .. (current.player and current.player.DisplayName or current.char.Name)
			end
		end
	else
		current = nil
	end
	lockLabel.Visible = locked and current ~= nil
end)
