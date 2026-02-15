-- evilware by 6vi1 / vamp
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
	Icon = 95816097006870,
	NotifySide = "Right",
	ShowCustomCursor = true,
})

local Tabs = {
	Movement = Window:AddTab("Movement", "move"),
	Cheats = Window:AddTab("Cheats", "zap"),
	Misc = Window:AddTab("Misc", "sparkles"),
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

local lastDribbleInput = {}
UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe or Library.Unloaded then return end
	local dir = dribbleKeys[input.KeyCode] or dribbleGamepad[input.KeyCode]
	if dir then
		local cam = workspace.CurrentCamera
		if cam then
			local lookVec = (cam.CFrame.LookVector * Vector3.new(1, 0, 1)).Unit
			local rightVec = (cam.CFrame.RightVector * Vector3.new(1, 0, 1)).Unit
			local worldDir = (rightVec * dir.X + lookVec * -dir.Z)
			if worldDir.Magnitude > 0.01 then
				worldDir = worldDir.Unit
			end
			doDribble(worldDir)
		end
	end
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

CheatsGroup:AddButton({
	Text = "Apply Username Spoof",
	Func = function()
		local name = Options.UsernameSpoof.Value
		if name == "" then name = "plugged" end

		pcall(function()
			local main = LocalPlayer.PlayerGui:FindFirstChild("Main")
			if main and main:FindFirstChild("TopRight") then
				local tr = main.TopRight
				if tr:FindFirstChild("TopRight") and tr.TopRight:FindFirstChild("Username") then
					tr.TopRight.Username.Text = name
				end
			end
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
		return
	end

	local lastBlockTime = 0
	local lastHolding = false
	silentVisionConnection = RunService.Heartbeat:Connect(function()
		if Library.Unloaded or not Toggles.SilentVision.Value then return end

		if not silentVisionHolding then
			lastHolding = false
			return
		end

		-- Find shot meter in LocalPlayer's character
		local char = LocalPlayer.Character
		if not char then return end
		
		local shotMeter = char:FindFirstChild("ShotMeterUI", true) -- recursive search
		if not shotMeter or not shotMeter.Enabled then return end

		local newMeter = shotMeter:FindFirstChild("NewMeter")
		if not newMeter then return end

		local greenWindow = newMeter:FindFirstChild("NewMeter")
		local bar = newMeter:FindFirstChild("Bar")
		if not greenWindow or not bar then return end

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
			local main = LocalPlayer.PlayerGui:FindFirstChild("Main")
			if main and main:FindFirstChild("TopRight") and main.TopRight:FindFirstChild("TopRight") then
				local un = main.TopRight.TopRight:FindFirstChild("Username")
				if un then un.Text = name end
			end
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

print("evilware loaded | 6vi1 / vamp")
