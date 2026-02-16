-- evilware by 6vi1 / vamp
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local IMAGE_ID = "109324425658652"
local LOADING_MESSAGES = {
	"Injecting...",
	"Finding pointers...",
	"Bypassing checks...",
	"Loading modules...",
	"Initializing hooks...",
	"Scanning memory...",
	"Establishing connection...",
	"Decrypting assets...",
	"Preparing environment...",
	"Loading UI core...",
	"Verifying integrity...",
	"Almost there...",
}

local function runLoadingScreen()
	local LocalPlayer = Players.LocalPlayer
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")

	-- Disable all CoreGui while loading
	for _, coreType in pairs(Enum.CoreGuiType:GetEnumItems()) do
		pcall(function() StarterGui:SetCoreGuiEnabled(coreType, false) end)
	end

	-- Disable all other ScreenGuis in PlayerGui (we'll add ours then hide the rest)
	local otherGuis = {}
	local gui = Instance.new("ScreenGui")
	gui.Name = "EvilwareLoader"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.IgnoreGuiInset = true
	gui.Parent = playerGui

	for _, child in pairs(playerGui:GetChildren()) do
		if child ~= gui and child:IsA("ScreenGui") and child.Enabled then
			child.Enabled = false
			table.insert(otherGuis, child)
		end
	end

	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.Position = UDim2.new(0, 0, 0, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
	overlay.BorderSizePixel = 0
	overlay.Parent = gui

	local container = Instance.new("Frame")
	container.Name = "Container"
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.Size = UDim2.new(0, 420, 0, 320)
	container.Position = UDim2.new(0.5, 0, 0.5, 0)
	container.BackgroundColor3 = Color3.fromRGB(14, 14, 22)
	container.BorderSizePixel = 0
	container.Parent = overlay

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = container

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(60, 45, 120)
	stroke.Thickness = 1
	stroke.Parent = container

	local img = Instance.new("ImageLabel")
	img.Name = "Logo"
	img.Size = UDim2.new(0, 100, 0, 100)
	img.Position = UDim2.new(0.5, -50, 0, 28)
	img.BackgroundTransparency = 1
	img.Image = "rbxassetid://" .. IMAGE_ID
	img.ScaleType = Enum.ScaleType.Fit
	img.Parent = container

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -40, 0, 32)
	title.Position = UDim2.new(0, 20, 0, 138)
	title.BackgroundTransparency = 1
	title.Text = "evilware"
	title.TextColor3 = Color3.fromRGB(220, 215, 255)
	title.TextSize = 24
	title.Font = Enum.Font.GothamBold
	title.Parent = container

	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.Size = UDim2.new(1, -40, 0, 22)
	status.Position = UDim2.new(0, 20, 0, 178)
	status.BackgroundTransparency = 1
	status.Text = "Initializing..."
	status.TextColor3 = Color3.fromRGB(140, 130, 180)
	status.TextSize = 14
	status.Font = Enum.Font.Gotham
	status.Parent = container

	local barBg = Instance.new("Frame")
	barBg.Name = "BarBg"
	barBg.Size = UDim2.new(1, -40, 0, 8)
	barBg.Position = UDim2.new(0, 20, 0, 218)
	barBg.BackgroundColor3 = Color3.fromRGB(28, 26, 42)
	barBg.BorderSizePixel = 0
	barBg.Parent = container
	local barBgCorner = Instance.new("UICorner")
	barBgCorner.CornerRadius = UDim.new(1, 0)
	barBgCorner.Parent = barBg

	local barFill = Instance.new("Frame")
	barFill.Name = "BarFill"
	barFill.Size = UDim2.new(0, 0, 1, 0)
	barFill.Position = UDim2.new(0, 0, 0, 0)
	barFill.AnchorPoint = Vector2.new(0, 0)
	barFill.BackgroundColor3 = Color3.fromRGB(100, 70, 200)
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg
	local barFillCorner = Instance.new("UICorner")
	barFillCorner.CornerRadius = UDim.new(1, 0)
	barFillCorner.Parent = barFill

	local circleOuter = Instance.new("Frame")
	circleOuter.Name = "CircleOuter"
	circleOuter.AnchorPoint = Vector2.new(0.5, 0.5)
	circleOuter.Size = UDim2.new(0, 44, 0, 44)
	circleOuter.Position = UDim2.new(0.5, -22, 0, 258)
	circleOuter.BackgroundTransparency = 1
	circleOuter.Parent = container
	local circleStroke = Instance.new("UIStroke")
	circleStroke.Color = Color3.fromRGB(50, 40, 90)
	circleStroke.Thickness = 2
	circleStroke.Parent = circleOuter

	local duration = 10 + math.random() * 5
	local startTime = tick()
	local lastMsgTime = 0
	local msgIndex = 1

	local conn = RunService.RenderStepped:Connect(function()
		local elapsed = tick() - startTime
		local t = math.min(elapsed / duration, 1)
		local smooth = 1 - (1 - t) ^ 1.6
		barFill.Size = UDim2.new(smooth, 0, 1, 0)
		if elapsed - lastMsgTime >= 0.9 then
			lastMsgTime = elapsed
			msgIndex = (msgIndex % #LOADING_MESSAGES) + 1
			status.Text = LOADING_MESSAGES[msgIndex]
		end
		circleStroke.Color = Color3.fromRGB(50 + math.floor(80 * smooth), 40, 90 + math.floor(100 * smooth))
		circleOuter.Rotation = (circleOuter.Rotation + 4) % 360
	end)

	task.wait(duration)
	conn:Disconnect()
	status.Text = "Ready."
	barFill.Size = UDim2.new(1, 0, 1, 0)

	task.wait(0.4)
	TweenService:Create(container, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 0, 0, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0),
	}):Play()
	TweenService:Create(overlay, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
	task.wait(0.55)
	gui:Destroy()

	-- Re-enable all CoreGui
	for _, coreType in pairs(Enum.CoreGuiType:GetEnumItems()) do
		pcall(function() StarterGui:SetCoreGuiEnabled(coreType, true) end)
	end

	-- Re-enable other PlayerGui ScreenGuis
	for _, other in pairs(otherGuis) do
		if other.Parent then other.Enabled = true end
	end
end

runLoadingScreen()

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

local Options = Library.Options
local Toggles = Library.Toggles

Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

-- State
local walkspeedLoopConnection = nil
local dribbleDistance = 15
local silentVisionConnection = nil
local silentVisionInputConnections = {}

local Window = Library:CreateWindow({
	Title = "evilware",
	Footer = "version: 1.0 | 6vi1 / vamp",
	Icon = "rbxassetid://" .. IMAGE_ID,
	NotifySide = "Right",
	ShowCustomCursor = true,
})

local Tabs = {
	Movement = Window:AddTab("Movement", "move"),
	Cheats = Window:AddTab("Cheats", "zap"),
	Misc = Window:AddTab("Misc", "sparkles"),
	["OVR Spoof"] = Window:AddTab("OVR Spoof", "award"),
	Credits = Window:AddTab("Credits", "heart"),
	["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

-- Movement Tab
local MovementGroup = Tabs.Movement:AddLeftGroupbox("Movement")

MovementGroup:AddToggle("WalkspeedEnabled", {
	Text = "Walkspeed",
	Default = false,
	Tooltip = "Loops and applies walkspeed every frame",
})

MovementGroup:AddSlider("Walkspeed", {
	Text = "Walkspeed",
	Default = 16,
	Min = 1,
	Max = 200,
	Rounding = 1,
	Suffix = " studs/s",
})

MovementGroup:AddDivider()

MovementGroup:AddToggle("DribbleEnabled", {
	Text = "Dribble",
	Default = false,
	Tooltip = "X=Back | Z=Left | C=Right | DPad: Left/Right/Down",
})

MovementGroup:AddSlider("DribbleDistance", {
	Text = "Dribble Distance",
	Default = 15,
	Min = 1,
	Max = 30,
	Rounding = 1,
	Suffix = " studs",
	Tooltip = "How far you tween in the dribble direction",
})

MovementGroup:AddSlider("DribbleDelay", {
	Text = "Dribble Delay",
	Default = 0.2,
	Min = 0,
	Max = 1,
	Rounding = 2,
	Suffix = "s",
	Tooltip = "Delay before movement (lets animation play first)",
})

MovementGroup:AddSlider("DribbleDuration", {
	Text = "Dribble Duration",
	Default = 0.5,
	Min = 0.35,
	Max = 1.2,
	Rounding = 2,
	Suffix = "s",
	Tooltip = "How long the movement takes (smoother = higher)",
})

-- Walkspeed Loop - use RenderStepped (runs last) so we override game's WalkSpeed, and hook PropertyChanged to force it
local walkspeedPropertyConnections = {}

local function applyWalkspeed(humanoid)
	if humanoid and Toggles.WalkspeedEnabled.Value then
		humanoid.WalkSpeed = Options.Walkspeed.Value
	end
end

local function setupWalkspeedHook(char)
	for _, c in pairs(walkspeedPropertyConnections) do c:Disconnect() end
	walkspeedPropertyConnections = {}
	local hum = char:FindFirstChild("Humanoid")
	if hum then
		table.insert(walkspeedPropertyConnections, hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
			if Toggles.WalkspeedEnabled.Value and hum.WalkSpeed ~= Options.Walkspeed.Value then
				hum.WalkSpeed = Options.Walkspeed.Value
			end
		end))
		applyWalkspeed(hum)
	end
end

Toggles.WalkspeedEnabled:OnChanged(function(enabled)
	if walkspeedLoopConnection then
		walkspeedLoopConnection:Disconnect()
		walkspeedLoopConnection = nil
	end
	for _, c in pairs(walkspeedPropertyConnections) do c:Disconnect() end
	walkspeedPropertyConnections = {}

	if enabled then
		local char = LocalPlayer.Character
		if char then setupWalkspeedHook(char) end

		walkspeedLoopConnection = RunService.RenderStepped:Connect(function()
			if Library.Unloaded then return end
			local char = LocalPlayer.Character
			local hum = char and char:FindFirstChild("Humanoid")
			if hum and hum.WalkSpeed ~= Options.Walkspeed.Value then
				hum.WalkSpeed = Options.Walkspeed.Value
			end
		end)
	end
end)

Options.Walkspeed:OnChanged(function()
	applyWalkspeed(LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid"))
end)

-- Dribble with TweenService (cleaner than Heartbeat loop, no freeze risk)
local activeDribbleTween = nil

local function doDribble(direction)
	if not Toggles.DribbleEnabled.Value then return end
	local char = LocalPlayer.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	if activeDribbleTween then
		activeDribbleTween:Cancel()
		activeDribbleTween = nil
	end

	dribbleDistance = Options.DribbleDistance.Value
	local delay = Options.DribbleDelay and Options.DribbleDelay.Value or 0.2
	local duration = (Options.DribbleDuration and Options.DribbleDuration.Value or 0.5)
	if duration < 0.1 then duration = 0.35 end

	task.delay(delay, function()
		if Library.Unloaded then return end
		root = char:FindFirstChild("HumanoidRootPart")
		if not root then return end

		local startCFrame = root.CFrame
		local endPos = root.Position + direction * dribbleDistance
		local endCFrame = CFrame.new(endPos) * (root.CFrame - root.CFrame.Position)

		activeDribbleTween = TweenService:Create(
			root,
			TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{CFrame = endCFrame}
		)
		activeDribbleTween:Play()
		activeDribbleTween.Completed:Once(function()
			activeDribbleTween = nil
		end)
	end)
end

local dribbleKeys = {
	[Enum.KeyCode.X] = Vector3.new(0, 0, 1),   -- Backwards
	[Enum.KeyCode.Z] = Vector3.new(-1, 0, 0),  -- Left
	[Enum.KeyCode.C] = Vector3.new(1, 0, 0),   -- Right
}

local dribbleGamepad = {
	[Enum.KeyCode.DPadLeft] = Vector3.new(-1, 0, 0),
	[Enum.KeyCode.DPadRight] = Vector3.new(1, 0, 0),
	[Enum.KeyCode.DPadDown] = Vector3.new(0, 0, 1),
}

-- Combo: side + down (or down + side) within 0.2s = behind the back → move to opposite side
local DRIBBLE_COMBO_WINDOW = 0.2
local lastDribbleSide = nil   -- "left" or "right"
local lastDribbleBackTime = nil
local lastDribbleSideTime = nil

local function getDribbleInputType(keyCode)
	if keyCode == Enum.KeyCode.X or keyCode == Enum.KeyCode.DPadDown then return "back" end
	if keyCode == Enum.KeyCode.Z or keyCode == Enum.KeyCode.DPadLeft then return "left" end
	if keyCode == Enum.KeyCode.C or keyCode == Enum.KeyCode.DPadRight then return "right" end
	return nil
end

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe or Library.Unloaded then return end
	local keyDir = dribbleKeys[input.KeyCode] or dribbleGamepad[input.KeyCode]
	if not keyDir then return end

	local inputType = getDribbleInputType(input.KeyCode)
	local now = tick()
	local cam = workspace.CurrentCamera
	if not cam then return end

	local lookVec = (cam.CFrame.LookVector * Vector3.new(1, 0, 1)).Unit
	local rightVec = (cam.CFrame.RightVector * Vector3.new(1, 0, 1)).Unit

	local dir = keyDir
	-- Behind-the-back: right+down or down+right within 0.2s → move left; left+down or down+left → move right
	if inputType == "back" then
		if lastDribbleSide and (now - (lastDribbleSideTime or 0)) <= DRIBBLE_COMBO_WINDOW then
			-- down after side: move to opposite side
			dir = lastDribbleSide == "right" and Vector3.new(-1, 0, 0) or Vector3.new(1, 0, 0)
		end
		lastDribbleBackTime = now
	elseif inputType == "left" or inputType == "right" then
		if lastDribbleBackTime and (now - lastDribbleBackTime) <= DRIBBLE_COMBO_WINDOW then
			-- side after down: move to opposite side
			dir = inputType == "right" and Vector3.new(-1, 0, 0) or Vector3.new(1, 0, 0)
		end
		lastDribbleSide = inputType
		lastDribbleSideTime = now
	end

	local worldDir = (rightVec * dir.X + lookVec * -dir.Z)
	if worldDir.Magnitude > 0.01 then
		worldDir = worldDir.Unit
	end
	doDribble(worldDir)
end)

-- Cheats Tab
local CheatsGroup = Tabs.Cheats:AddLeftGroupbox("Cheats")

CheatsGroup:AddToggle("SilentVision", {
	Text = "Silent Vision (V1)",
	Default = false,
	Tooltip = "L3=fire shot (controller). Block when bar in green: E (kb) or ButtonX/A (controller)",
})

-- Username Spoofer
CheatsGroup:AddInput("UsernameSpoof", {
	Default = "plugged",
	Text = "Username Spoofer",
	Placeholder = "plugged",
	Tooltip = "Type a name to display (default: plugged)",
})

-- Find TopRight.TopRight.Username (path used by game: GetChildren()[8].TopRight.TopRight.Username)
local function findTopRightUsername()
	local gui = LocalPlayer.PlayerGui
	local children = gui:GetChildren()
	-- Try index 8 first (exact path user gave)
	if children[8] then
		local c = children[8]
		if c:FindFirstChild("TopRight") and c.TopRight:FindFirstChild("TopRight") and c.TopRight.TopRight:FindFirstChild("Username") then
			return c.TopRight.TopRight.Username
		end
	end
	-- Fallback: scan all children for TopRight.TopRight.Username
	for _, c in pairs(children) do
		if c:FindFirstChild("TopRight") and c.TopRight:FindFirstChild("TopRight") and c.TopRight.TopRight:FindFirstChild("Username") then
			return c.TopRight.TopRight.Username
		end
	end
	return nil
end

CheatsGroup:AddButton({
	Text = "Apply Username Spoof",
	Func = function()
		local name = Options.UsernameSpoof.Value
		if name == "" then name = "plugged" end

		pcall(function()
			local un = findTopRightUsername()
			if un then un.Text = name end
		end)

		-- Find player banner in LocalPlayer's character
		pcall(function()
			local char = LocalPlayer.Character
			if char then
				local banner = char:FindFirstChild("PlayerBanner", true) -- recursive search
				if banner and banner:FindFirstChild("Background") then
					local pn = banner.Background:FindFirstChild("PlayerName")
					if pn then pn.Text = name end
				end
			end
		end)

		Library:Notify("Username spoofed to: " .. name)
	end,
})

-- Silent Vision logic (track hold via InputBegan/InputEnded for reliable controller support)
local silentVisionHolding = false
local silentVisionInputConnections = {}
local silentVisionBarPositionResetDone = false

local function isShootInput(input)
	return input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonX or input.KeyCode == Enum.KeyCode.ButtonA
end

local function isControllerInput(input)
	return input.UserInputType == Enum.UserInputType.Gamepad1 or input.UserInputType == Enum.UserInputType.Gamepad2 or
		input.UserInputType == Enum.UserInputType.Gamepad3 or input.UserInputType == Enum.UserInputType.Gamepad4
end

local function fireShot()
	local args = {{ Shoot = true, Type = "Shoot", HoldingQ = false, HoldingL1 = false }}
	local action = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Server") and ReplicatedStorage.Remotes.Server:FindFirstChild("Action")
	if action then action:FireServer(unpack(args)) end
end

local function fireShotBlock()
	local args = {{ Shoot = false, Type = "Shoot" }}
	local action = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Server") and ReplicatedStorage.Remotes.Server:FindFirstChild("Action")
	if action then action:FireServer(unpack(args)) end
end

local l3FireConnection = nil

local function setupL3Fire()
	if l3FireConnection then l3FireConnection:Disconnect() end
	l3FireConnection = UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		-- Controller only: L3 fires the shot
		if isControllerInput(input) and input.KeyCode == Enum.KeyCode.ButtonL3 then
			fireShot()
		end
	end)
end
setupL3Fire()

local function setupSilentVisionInputTracking()
	for _, c in pairs(silentVisionInputConnections) do pcall(function() c:Disconnect() end) end
	table.clear(silentVisionInputConnections)

	table.insert(silentVisionInputConnections, UserInputService.InputBegan:Connect(function(input, gpe)
		if not Toggles.SilentVision.Value then return end
		if isShootInput(input) then silentVisionHolding = true end
	end))
	table.insert(silentVisionInputConnections, UserInputService.InputEnded:Connect(function(input)
		if isShootInput(input) then silentVisionHolding = false end
	end))
end

local function setupSilentVision()
	if silentVisionConnection then
		silentVisionConnection:Disconnect()
		silentVisionConnection = nil
	end
	setupSilentVisionInputTracking()

	if not Toggles.SilentVision.Value then
		silentVisionHolding = false
		silentVisionBarPositionResetDone = false
		return
	end

	-- One-time: reset bar position so it doesn't start overlapping (prevents first shot auto-release)
	silentVisionBarPositionResetDone = false

	local lastBlockTime = 0
	local lastHolding = false
	silentVisionConnection = RunService.Heartbeat:Connect(function()
		if Library.Unloaded or not Toggles.SilentVision.Value then return end

		-- Find shot meter in LocalPlayer's character
		local char = LocalPlayer.Character
		if not char then return end

		local shotMeter = char:FindFirstChild("ShotMeterUI", true) -- recursive search
		if not shotMeter or not shotMeter.Enabled then return end

		local newMeter = shotMeter:FindFirstChild("NewMeter")
		if not newMeter then return end

		local greenWindow = newMeter:FindFirstChild("NewMeter")
		-- Bar can be direct child or nested (e.g. inside a Frame)
		local bar = newMeter:FindFirstChild("Bar") or newMeter:FindFirstChild("Bar", true) or shotMeter:FindFirstChild("Bar", true)
		if not greenWindow or not bar then return end

		-- Keep bar at safe position until user has held block (stops first-shot auto-release; game may overwrite each frame)
		if not silentVisionHolding then
			silentVisionBarPositionResetDone = false
			pcall(function()
				if bar:IsA("GuiObject") then
					bar.Position = UDim2.new(0.5, 0, 0.996999979, 0)
				end
			end)
			return
		end
		-- One-time skip of overlap check on first frame we're holding (layout may still be stale)
		if not silentVisionBarPositionResetDone then
			silentVisionBarPositionResetDone = true
			return
		end

		local gwPos = greenWindow.AbsolutePosition
		local gwSize = greenWindow.AbsoluteSize
		local barPos = bar.AbsolutePosition
		local barSize = bar.AbsoluteSize

		-- Check overlap: bar touches or overlaps green window
		local barRight = barPos.X + barSize.X
		local barBottom = barPos.Y + barSize.Y
		local gwRight = gwPos.X + gwSize.X
		local gwBottom = gwPos.Y + gwSize.Y

		local overlaps = not (barRight < gwPos.X or barPos.X > gwRight or barBottom < gwPos.Y or barPos.Y > gwBottom)

		if overlaps and (not lastHolding or tick() - lastBlockTime > 0.15) then
			lastHolding = true
			lastBlockTime = tick()
			fireShotBlock()
		end
	end)
end

Toggles.SilentVision:OnChanged(setupSilentVision)

-- Misc Tab
local MiscGroup = Tabs.Misc:AddLeftGroupbox("Misc Actions")

MiscGroup:AddButton({
	Text = "Reset Character",
	Func = function()
		LocalPlayer.Character:BreakJoints()
		Library:Notify("Character reset")
	end,
})

MiscGroup:AddButton({
	Text = "Refresh Username Spoof",
	Func = function()
		local name = Options.UsernameSpoof.Value
		if name == "" then name = "plugged" end
		pcall(function()
			local un = findTopRightUsername()
			if un then un.Text = name end
		end)
		-- Find player banner in character
		pcall(function()
			local char = LocalPlayer.Character
			if char then
				local banner = char:FindFirstChild("PlayerBanner", true)
				if banner and banner:FindFirstChild("Background") then
					local pn = banner.Background:FindFirstChild("PlayerName")
					if pn then pn.Text = name end
				end
			end
		end)
		Library:Notify("Username spoof refreshed")
	end,
})

MiscGroup:AddToggle("Noclip", {
	Text = "Noclip",
	Default = false,
	Tooltip = "Walk through walls",
})

local noclipConn
Toggles.Noclip:OnChanged(function(enabled)
	if noclipConn then noclipConn:Disconnect() end
	if enabled then
		noclipConn = RunService.Stepped:Connect(function()
			if Library.Unloaded then return end
			local char = LocalPlayer.Character
			if char then
				for _, p in pairs(char:GetDescendants()) do
					if p:IsA("BasePart") then
						p.CanCollide = false
					end
				end
			end
		end)
	else
		local char = LocalPlayer.Character
		if char then
			for _, p in pairs(char:GetDescendants()) do
				if p:IsA("BasePart") then
					p.CanCollide = true
				end
			end
		end
	end
end)

MiscGroup:AddToggle("Infinite Jump", {
	Text = "Infinite Jump",
	Default = false,
})

UserInputService.JumpRequest:Connect(function()
	if Toggles.InfiniteJump and Toggles.InfiniteJump.Value then
		local char = LocalPlayer.Character
		if char and char:FindFirstChild("Humanoid") then
			char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end
end)

-- OVR Spoof Tab (local player character = Workspace "TheLocalCharacter" equivalent)
-- Banner can be under character or in PlayerGui; search both and use recursive find
local function findPlayerBanner()
	local char = LocalPlayer.Character
	if char then
		local banner = char:FindFirstChild("PlayerBanner", true)
		if banner then return banner end
		-- Fallback: find by LegendRep; walk up to ancestor that contains OvrBackground (full banner)
		local legendRep = char:FindFirstChild("LegendRep", true)
		if legendRep then
			local p = legendRep.Parent
			while p and p ~= char do
				if p:FindFirstChild("OvrBackground", true) then return p end
				p = p.Parent
			end
			return legendRep.Parent
		end
		local rookieRep = char:FindFirstChild("RookieRep", true)
		if rookieRep then return rookieRep.Parent end
	end
	for _, gui in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
		if gui.Name == "PlayerBanner" then return gui end
	end
	local inWorkspace = workspace:FindFirstChild(LocalPlayer.Name)
	if inWorkspace then
		local banner = inWorkspace:FindFirstChild("PlayerBanner", true)
		if banner then return banner end
	end
	return nil
end

local function applyOvrSpoof()
	local banner = findPlayerBanner()
	if not banner then return false end
	return pcall(function()
		local legendRep = banner:FindFirstChild("LegendRep") or (function()
			for _, d in pairs(banner:GetDescendants()) do if d.Name == "LegendRep" then return d end end
			return nil
		end)()
		local repNamesToHide = { "RookieRep", "ProRep", "SuperstarRep", "EliteRep" }
		for _, name in pairs(repNamesToHide) do
			local rep = banner:FindFirstChild(name) or (function()
				for _, d in pairs(banner:GetDescendants()) do if d.Name == name then return d end end
				return nil
			end)()
			if rep and rep:IsA("GuiObject") then rep.Visible = false end
		end
		if legendRep and legendRep:IsA("GuiObject") then legendRep.Visible = true end
		local ovrBg = banner:FindFirstChild("OvrBackground") or (function()
			for _, d in pairs(banner:GetDescendants()) do if d.Name == "OvrBackground" then return d end end
			return nil
		end)()
		if ovrBg then
			local ovrStroke = ovrBg:FindFirstChild("OvrStroke") or (function()
				for _, d in pairs(ovrBg:GetDescendants()) do if d.Name == "OvrStroke" then return d end end
				return nil
			end)()
			if ovrStroke then
				local overall = ovrStroke:FindFirstChild("Overall") or (function()
					for _, d in pairs(ovrStroke:GetDescendants()) do if d.Name == "Overall" then return d end end
					return nil
				end)()
				if overall and (overall:IsA("TextLabel") or overall:IsA("TextBox")) then
					overall.Text = "99"
				end
			end
		end
	end)
end

local OvrSpoofGroup = Tabs["OVR Spoof"]:AddLeftGroupbox("Overall Spoof")
OvrSpoofGroup:AddToggle("OvrSpoofEnabled", {
	Text = "OVR Spoof",
	Default = false,
	Tooltip = "Show LegendRep, hide Rookie/Pro/Superstar/Elite Rep, set Overall to 99",
})

-- Retry OVR spoof a few times when enabling (banner may load late)
local function scheduleOvrSpoofRetries()
	if not (Toggles.OvrSpoofEnabled and Toggles.OvrSpoofEnabled.Value) then return end
	for _, delay in pairs({0, 0.5, 1, 2}) do
		task.delay(delay, function()
			if Library.Unloaded or not (Toggles.OvrSpoofEnabled and Toggles.OvrSpoofEnabled.Value) then return end
			applyOvrSpoof()
		end)
	end
end

Toggles.OvrSpoofEnabled:OnChanged(function(enabled)
	if enabled then
		applyOvrSpoof()
		scheduleOvrSpoofRetries()
	end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
	if Toggles.OvrSpoofEnabled and Toggles.OvrSpoofEnabled.Value then
		task.defer(function()
			applyOvrSpoof()
			scheduleOvrSpoofRetries()
		end)
	end
end)

-- Keep OVR spoof applied (game may reset banner visibility/text)
local ovrSpoofLoopConn = nil
local function updateOvrSpoofLoop()
	if ovrSpoofLoopConn then
		ovrSpoofLoopConn:Disconnect()
		ovrSpoofLoopConn = nil
	end
	if Toggles.OvrSpoofEnabled and Toggles.OvrSpoofEnabled.Value then
		ovrSpoofLoopConn = RunService.Heartbeat:Connect(function()
			if Library.Unloaded or not (Toggles.OvrSpoofEnabled and Toggles.OvrSpoofEnabled.Value) then return end
			applyOvrSpoof()
		end)
	end
end
Toggles.OvrSpoofEnabled:OnChanged(function(enabled)
	updateOvrSpoofLoop()
end)

-- Credits Tab
local CreditsGroup = Tabs.Credits:AddLeftGroupbox("evilware Credits")

CreditsGroup:AddLabel("evilware - basketball cheats & movement")
CreditsGroup:AddDivider()
CreditsGroup:AddLabel("Main Dev: 6vi1")
CreditsGroup:AddLabel("Main Dev: vamp")
CreditsGroup:AddLabel("UI: Obsidian (LinoriaLib)")
CreditsGroup:AddLabel("TweenService: Roblox")
CreditsGroup:AddLabel("Inspiration: hoops")
CreditsGroup:AddLabel("Testing: the streets")
CreditsGroup:AddLabel("Vibes: immaculate")
CreditsGroup:AddLabel("Coffee: essential")
CreditsGroup:AddLabel("Code: lua supremacy")
CreditsGroup:AddDivider()
CreditsGroup:AddLabel("Special thanks to everyone who uses this")
CreditsGroup:AddLabel("— 6vi1 / vamp")

-- Character respawn handler
LocalPlayer.CharacterAdded:Connect(function(char)
	Character = char
	Humanoid = char:WaitForChild("Humanoid")
	RootPart = char:WaitForChild("HumanoidRootPart")
	if Toggles.WalkspeedEnabled and Toggles.WalkspeedEnabled.Value then
		setupWalkspeedHook(char)
		Humanoid.WalkSpeed = Options.Walkspeed.Value
	end
end)

Library:OnUnload(function()
	if walkspeedLoopConnection then walkspeedLoopConnection:Disconnect() end
	for _, c in pairs(walkspeedPropertyConnections) do pcall(function() c:Disconnect() end) end
	if silentVisionConnection then silentVisionConnection:Disconnect() end
	for _, c in pairs(silentVisionInputConnections) do pcall(function() c:Disconnect() end) end
	if l3FireConnection then l3FireConnection:Disconnect() end
	if activeDribbleTween then activeDribbleTween:Cancel() end
	if noclipConn then noclipConn:Disconnect() end
	if ovrSpoofLoopConn then ovrSpoofLoopConn:Disconnect() end
end)

-- UI Settings
local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu")
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })
MenuGroup:AddButton("Unload", function() Library:Unload() end)
Library.ToggleKeybind = Options.MenuKeybind

-- SaveManager & ThemeManager
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetFolder("evilware")
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])
SaveManager:LoadAutoloadConfig()
task.defer(updateOvrSpoofLoop) -- apply loop if OVR Spoof was loaded from config

print("evilware loaded | 6vi1 / vamp")
