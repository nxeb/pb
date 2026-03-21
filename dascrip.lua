-- evilware by 6vi1 / vamp

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
local walkspeedPropertyConnections = {}
local silentVisionConnection = nil
local silentVisionInputConnections = {}
local silentVisionHolding = false
local silentVisionBarPositionResetDone = false
local activeDribbleTween = nil
local noclipConn = nil
local ovrSpoofLoopConn = nil
local l3FireConnection = nil
local desyncActive = false
local desyncGhostModel = nil
local desyncHeartbeatConnection = nil
local guardSpeedHolding = false

-- Window
local Window = Library:CreateWindow({
	Title = "vampware",
	Footer = "version: 2.0 | 6vi1 / vamp",
	Icon = nil,
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

-- ============================
-- MOVEMENT TAB
-- ============================

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

MovementGroup:AddDivider()

MovementGroup:AddToggle("GuardSpeedEnabled", {
	Text = "Guard Speed",
	Default = false,
	Tooltip = "While holding F (keyboard) or L2 (controller), move at the set speed.",
})

MovementGroup:AddSlider("GuardSpeed", {
	Text = "Guard Speed",
	Default = 24,
	Min = 1,
	Max = 200,
	Rounding = 1,
	Suffix = " studs/s",
})

-- ============================
-- WALKSPEED LOGIC
-- ============================

local function applyWalkspeed(humanoid)
	if not humanoid then return end
	if guardSpeedHolding and Toggles.GuardSpeedEnabled.Value then
		humanoid.WalkSpeed = Options.GuardSpeed.Value
	elseif Toggles.WalkspeedEnabled.Value then
		humanoid.WalkSpeed = Options.Walkspeed.Value
	end
end

local function setupWalkspeedHook(char)
	for _, c in ipairs(walkspeedPropertyConnections) do c:Disconnect() end
	walkspeedPropertyConnections = {}
	local hum = char:FindFirstChild("Humanoid")
	if not hum then return end
	table.insert(walkspeedPropertyConnections, hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
		if Toggles.WalkspeedEnabled.Value and hum.WalkSpeed ~= Options.Walkspeed.Value then
			hum.WalkSpeed = Options.Walkspeed.Value
		end
	end))
	applyWalkspeed(hum)
end

local function startMovementSpeedLoop()
	if walkspeedLoopConnection then walkspeedLoopConnection:Disconnect() end
	walkspeedLoopConnection = RunService.RenderStepped:Connect(function()
		if Library.Unloaded then return end
		local char = LocalPlayer.Character
		local hum = char and char:FindFirstChild("Humanoid")
		if not hum then return end
		if guardSpeedHolding and Toggles.GuardSpeedEnabled.Value then
			hum.WalkSpeed = Options.GuardSpeed.Value
		elseif Toggles.WalkspeedEnabled.Value then
			hum.WalkSpeed = Options.Walkspeed.Value
		end
	end)
end

Toggles.WalkspeedEnabled:OnChanged(function(enabled)
	for _, c in ipairs(walkspeedPropertyConnections) do c:Disconnect() end
	walkspeedPropertyConnections = {}
	if enabled then
		local char = LocalPlayer.Character
		if char then setupWalkspeedHook(char) end
		startMovementSpeedLoop()
	elseif not Toggles.GuardSpeedEnabled.Value then
		if walkspeedLoopConnection then
			walkspeedLoopConnection:Disconnect()
			walkspeedLoopConnection = nil
		end
	end
end)

Toggles.GuardSpeedEnabled:OnChanged(function(enabled)
	if not enabled then guardSpeedHolding = false end
	if enabled then
		startMovementSpeedLoop()
	elseif not Toggles.WalkspeedEnabled.Value then
		if walkspeedLoopConnection then
			walkspeedLoopConnection:Disconnect()
			walkspeedLoopConnection = nil
		end
	end
end)

Options.GuardSpeed:OnChanged(function()
	if guardSpeedHolding and Toggles.GuardSpeedEnabled.Value then
		applyWalkspeed(LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid"))
	end
end)

Options.Walkspeed:OnChanged(function()
	applyWalkspeed(LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid"))
end)

-- Guard speed input
UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe or Library.Unloaded then return end
	if not Toggles.GuardSpeedEnabled.Value then return end
	if input.KeyCode == Enum.KeyCode.F or input.KeyCode == Enum.KeyCode.ButtonL2 then
		guardSpeedHolding = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.F or input.KeyCode == Enum.KeyCode.ButtonL2 then
		guardSpeedHolding = false
	end
end)

-- ============================
-- DRIBBLE LOGIC
-- ============================

local DRIBBLE_COMBO_WINDOW = 0.2
local lastDribbleSide = nil
local lastDribbleBackTime = nil
local lastDribbleSideTime = nil

local dribbleKeys = {
	[Enum.KeyCode.X] = Vector3.new(0, 0, 1),
	[Enum.KeyCode.Z] = Vector3.new(-1, 0, 0),
	[Enum.KeyCode.C] = Vector3.new(1, 0, 0),
}

local dribbleGamepad = {
	[Enum.KeyCode.DPadLeft]  = Vector3.new(-1, 0, 0),
	[Enum.KeyCode.DPadRight] = Vector3.new(1, 0, 0),
	[Enum.KeyCode.DPadDown]  = Vector3.new(0, 0, 1),
}

local function getDribbleInputType(keyCode)
	if keyCode == Enum.KeyCode.X or keyCode == Enum.KeyCode.DPadDown then return "back" end
	if keyCode == Enum.KeyCode.Z or keyCode == Enum.KeyCode.DPadLeft then return "left" end
	if keyCode == Enum.KeyCode.C or keyCode == Enum.KeyCode.DPadRight then return "right" end
	return nil
end

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

	local delay    = Options.DribbleDelay.Value or 0.2
	local duration = math.max(Options.DribbleDuration.Value or 0.5, 0.1)
	local distance = Options.DribbleDistance.Value

	task.delay(delay, function()
		if Library.Unloaded then return end
		root = char:FindFirstChild("HumanoidRootPart")
		if not root then return end
		local endCFrame = CFrame.new(root.Position + direction * distance) * (root.CFrame - root.CFrame.Position)
		activeDribbleTween = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { CFrame = endCFrame })
		activeDribbleTween:Play()
		activeDribbleTween.Completed:Once(function()
			activeDribbleTween = nil
		end)
	end)
end

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe or Library.Unloaded then return end
	local keyDir = dribbleKeys[input.KeyCode] or dribbleGamepad[input.KeyCode]
	if not keyDir then return end

	local inputType = getDribbleInputType(input.KeyCode)
	local now = tick()
	local cam = workspace.CurrentCamera
	if not cam then return end

	local lookVec  = (cam.CFrame.LookVector  * Vector3.new(1, 0, 1)).Unit
	local rightVec = (cam.CFrame.RightVector * Vector3.new(1, 0, 1)).Unit
	local dir = keyDir

	if inputType == "back" then
		if lastDribbleSide and (now - (lastDribbleSideTime or 0)) <= DRIBBLE_COMBO_WINDOW then
			dir = lastDribbleSide == "right" and Vector3.new(-1, 0, 0) or Vector3.new(1, 0, 0)
		end
		lastDribbleBackTime = now
	elseif inputType == "left" or inputType == "right" then
		if lastDribbleBackTime and (now - lastDribbleBackTime) <= DRIBBLE_COMBO_WINDOW then
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

-- ============================
-- CHEATS TAB
-- ============================

local CheatsGroup = Tabs.Cheats:AddLeftGroupbox("Cheats")

CheatsGroup:AddToggle("DesyncEnabled", {
	Text = "Desync",
	Default = false,
	Tooltip = "Enable desync. Turn on then use keybind to toggle desync on/off.",
}):AddKeyPicker("DesyncKeybind", { Default = "G", NoUI = false, Text = "Desync toggle" })

CheatsGroup:AddToggle("SilentVision", {
	Text = "Silent Vision (V1)",
	Default = false,
	Tooltip = "L3=fire shot (controller). Block when bar in green: E (kb) or ButtonX/A (controller)",
})

CheatsGroup:AddInput("UsernameSpoof", {
	Default = "plugged",
	Text = "Username Spoofer",
	Placeholder = "plugged",
	Tooltip = "Type a name to display (default: plugged)",
})

-- ============================
-- USERNAME SPOOF LOGIC
-- ============================

local function findTopRightUsername()
	local children = LocalPlayer.PlayerGui:GetChildren()
	for _, c in ipairs(children) do
		local tr = c:FindFirstChild("TopRight")
		if tr then
			local tr2 = tr:FindFirstChild("TopRight")
			if tr2 then
				local un = tr2:FindFirstChild("Username")
				if un then return un end
			end
		end
	end
	return nil
end

local function applyUsernameSpoof(name)
	if not name or name == "" then name = "plugged" end
	pcall(function()
		local un = findTopRightUsername()
		if un then un.Text = name end
	end)
	pcall(function()
		local char = LocalPlayer.Character
		if not char then return end
		local banner = char:FindFirstChild("PlayerBanner", true)
		if banner and banner:FindFirstChild("Background") then
			local pn = banner.Background:FindFirstChild("PlayerName")
			if pn then pn.Text = name end
		end
	end)
end

CheatsGroup:AddButton({
	Text = "Apply Username Spoof",
	Func = function()
		local name = Options.UsernameSpoof.Value
		applyUsernameSpoof(name)
		Library:Notify("Username spoofed to: " .. (name ~= "" and name or "plugged"))
	end,
})

-- ============================
-- SILENT VISION LOGIC
-- ============================

local function isShootInput(input)
	return input.KeyCode == Enum.KeyCode.E
		or input.KeyCode == Enum.KeyCode.ButtonX
		or input.KeyCode == Enum.KeyCode.ButtonA
end

local function isControllerInput(input)
	return input.UserInputType == Enum.UserInputType.Gamepad1
		or input.UserInputType == Enum.UserInputType.Gamepad2
		or input.UserInputType == Enum.UserInputType.Gamepad3
		or input.UserInputType == Enum.UserInputType.Gamepad4
end

local function fireAction(shoot)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then return end
	local server = remotes:FindFirstChild("Server")
	if not server then return end
	local action = server:FindFirstChild("Action")
	if not action then return end
	if shoot then
		action:FireServer({ Shoot = true, Type = "Shoot", HoldingQ = false, HoldingL1 = false })
	else
		action:FireServer({ Shoot = false, Type = "Shoot" })
	end
end

local function setupL3Fire()
	if l3FireConnection then l3FireConnection:Disconnect() end
	l3FireConnection = UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if isControllerInput(input) and input.KeyCode == Enum.KeyCode.ButtonL3 then
			fireAction(true)
		end
	end)
end
setupL3Fire()

local function setupSilentVisionInputTracking()
	for _, c in ipairs(silentVisionInputConnections) do pcall(function() c:Disconnect() end) end
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

	silentVisionBarPositionResetDone = false
	local lastBlockTime = 0
	local lastHolding = false

	silentVisionConnection = RunService.Heartbeat:Connect(function()
		if Library.Unloaded or not Toggles.SilentVision.Value then return end

		local char = LocalPlayer.Character
		if not char then return end

		local shotMeter = char:FindFirstChild("ShotMeterUI", true)
		if not shotMeter or not shotMeter.Enabled then return end

		local newMeter = shotMeter:FindFirstChild("NewMeter")
		if not newMeter then return end

		local greenWindow = newMeter:FindFirstChild("NewMeter")
		local bar = newMeter:FindFirstChild("Bar") or newMeter:FindFirstChild("Bar", true) or shotMeter:FindFirstChild("Bar", true)
		if not greenWindow or not bar then return end

		if not silentVisionHolding then
			silentVisionBarPositionResetDone = false
			pcall(function()
				if bar:IsA("GuiObject") then
					bar.Position = UDim2.new(0.5, 0, 0.996999979, 0)
				end
			end)
			return
		end

		if not silentVisionBarPositionResetDone then
			silentVisionBarPositionResetDone = true
			return
		end

		local barPos   = bar.AbsolutePosition
		local barSize  = bar.AbsoluteSize
		local gwPos    = greenWindow.AbsolutePosition
		local gwSize   = greenWindow.AbsoluteSize

		local overlaps = not (
			(barPos.X + barSize.X) < gwPos.X or
			barPos.X > (gwPos.X + gwSize.X) or
			(barPos.Y + barSize.Y) < gwPos.Y or
			barPos.Y > (gwPos.Y + gwSize.Y)
		)

		if overlaps and (not lastHolding or tick() - lastBlockTime > 0.15) then
			lastHolding = true
			lastBlockTime = tick()
			fireAction(false)
		end
	end)
end

Toggles.SilentVision:OnChanged(setupSilentVision)

-- ============================
-- DESYNC LOGIC
-- ============================

local function createDesyncGhost(character)
	if desyncGhostModel then desyncGhostModel:Destroy() end
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end

	local clone = character:Clone()
	clone.Name = "DesyncGhost"

	for _, part in ipairs(clone:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.Transparency = 0.7
			part.CastShadow = false
		elseif part:IsA("Decal") or part:IsA("Texture") then
			part.Transparency = 0.7
		elseif part:IsA("Script") or part:IsA("LocalScript") or part:IsA("ModuleScript") then
			part:Destroy()
		end
	end

	local hum = clone:FindFirstChildOfClass("Humanoid")
	if hum then hum:Destroy() end

	local highlight = Instance.new("Highlight")
	highlight.FillColor = Color3.fromRGB(100, 150, 255)
	highlight.FillTransparency = 0.5
	highlight.OutlineColor = Color3.fromRGB(150, 200, 255)
	highlight.OutlineTransparency = 0
	highlight.Parent = clone

	clone.Parent = workspace
	desyncGhostModel = clone
end

local function updateDesyncGhost(character)
	if not desyncGhostModel or not character then return end
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			local ghostPart = desyncGhostModel:FindFirstChild(part.Name, true)
			if ghostPart and ghostPart:IsA("BasePart") then
				ghostPart.CFrame = part.CFrame
			end
		end
	end
end

local function getDesyncKeyCode()
	local v = Options.DesyncKeybind and Options.DesyncKeybind.Value
	if type(v) == "table" and v.KeyCode then return v.KeyCode end
	if type(v) == "string" then return Enum.KeyCode[v] end
	return v
end

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe or Library.Unloaded then return end
	if not Toggles.DesyncEnabled.Value then return end
	local kc = getDesyncKeyCode()
	if kc and input.KeyCode == kc then
		desyncActive = not desyncActive
		Library:Notify("Desync " .. (desyncActive and "On" or "Off"))
	end
end)

local function setupDesyncLoop()
	if desyncHeartbeatConnection then
		desyncHeartbeatConnection:Disconnect()
		desyncHeartbeatConnection = nil
	end
	if not Toggles.DesyncEnabled.Value then
		if desyncGhostModel then desyncGhostModel:Destroy() desyncGhostModel = nil end
		desyncActive = false
		return
	end
	desyncHeartbeatConnection = RunService.Heartbeat:Connect(function()
		if not Toggles.DesyncEnabled.Value then return end
		local char = LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		if desyncActive then
			if not desyncGhostModel or not desyncGhostModel.Parent then
				createDesyncGhost(char)
			end
			updateDesyncGhost(char)
			local savedVelocity = hrp.AssemblyLinearVelocity
			hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(0.0001), 0)
			hrp.AssemblyLinearVelocity = Vector3.new(math.random(2000, 4000), math.random(2000, 4000), math.random(2000, 4000))
			RunService.RenderStepped:Wait()
			hrp.AssemblyLinearVelocity = savedVelocity
		else
			if desyncGhostModel then desyncGhostModel:Destroy() desyncGhostModel = nil end
		end
	end)
end

Toggles.DesyncEnabled:OnChanged(setupDesyncLoop)
setupDesyncLoop()

-- ============================
-- MISC TAB
-- ============================

local MiscGroup = Tabs.Misc:AddLeftGroupbox("Misc Actions")

MiscGroup:AddButton({
	Text = "Reset Character",
	Func = function()
		local char = LocalPlayer.Character
		if char then char:BreakJoints() end
		Library:Notify("Character reset")
	end,
})

MiscGroup:AddButton({
	Text = "Refresh Username Spoof",
	Func = function()
		applyUsernameSpoof(Options.UsernameSpoof.Value)
		Library:Notify("Username spoof refreshed")
	end,
})

MiscGroup:AddToggle("Noclip", {
	Text = "Noclip",
	Default = false,
	Tooltip = "Walk through walls",
})

Toggles.Noclip:OnChanged(function(enabled)
	if noclipConn then noclipConn:Disconnect() noclipConn = nil end
	if enabled then
		noclipConn = RunService.Stepped:Connect(function()
			if Library.Unloaded then return end
			local char = LocalPlayer.Character
			if not char then return end
			for _, p in ipairs(char:GetDescendants()) do
				if p:IsA("BasePart") then p.CanCollide = false end
			end
		end)
	else
		local char = LocalPlayer.Character
		if char then
			for _, p in ipairs(char:GetDescendants()) do
				if p:IsA("BasePart") then p.CanCollide = true end
			end
		end
	end
end)

MiscGroup:AddToggle("InfiniteJump", {
	Text = "Infinite Jump",
	Default = false,
})

UserInputService.JumpRequest:Connect(function()
	if Toggles.InfiniteJump and Toggles.InfiniteJump.Value then
		local char = LocalPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
	end
end)

-- ============================
-- OVR SPOOF TAB
-- ============================

local function findPlayerBanner()
	local char = LocalPlayer.Character
	if char then
		local banner = char:FindFirstChild("PlayerBanner", true)
		if banner then return banner end

		for _, child in ipairs({ "LegendRep", "RookieRep" }) do
			local rep = char:FindFirstChild(child, true)
			if rep then
				local p = rep.Parent
				while p and p ~= char do
					if p:FindFirstChild("OvrBackground", true) then return p end
					p = p.Parent
				end
				return rep.Parent
			end
		end
	end

	for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
		if gui.Name == "PlayerBanner" then return gui end
	end

	local inWorkspace = workspace:FindFirstChild(LocalPlayer.Name)
	if inWorkspace then
		return inWorkspace:FindFirstChild("PlayerBanner", true)
	end

	return nil
end

local repNamesToHide = { "RookieRep", "ProRep", "SuperstarRep", "EliteRep" }

local function deepFind(parent, name)
	for _, d in ipairs(parent:GetDescendants()) do
		if d.Name == name then return d end
	end
	return nil
end

local function applyOvrSpoof()
	local banner = findPlayerBanner()
	if not banner then return end
	pcall(function()
		local legendRep = banner:FindFirstChild("LegendRep") or deepFind(banner, "LegendRep")
		for _, name in ipairs(repNamesToHide) do
			local rep = banner:FindFirstChild(name) or deepFind(banner, name)
			if rep and rep:IsA("GuiObject") then rep.Visible = false end
		end
		if legendRep and legendRep:IsA("GuiObject") then legendRep.Visible = true end

		local ovrBg = banner:FindFirstChild("OvrBackground") or deepFind(banner, "OvrBackground")
		if ovrBg then
			local ovrStroke = ovrBg:FindFirstChild("OvrStroke") or deepFind(ovrBg, "OvrStroke")
			if ovrStroke then
				local overall = ovrStroke:FindFirstChild("Overall") or deepFind(ovrStroke, "Overall")
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

local function updateOvrSpoofLoop()
	if ovrSpoofLoopConn then ovrSpoofLoopConn:Disconnect() ovrSpoofLoopConn = nil end
	if Toggles.OvrSpoofEnabled and Toggles.OvrSpoofEnabled.Value then
		ovrSpoofLoopConn = RunService.Heartbeat:Connect(function()
			if Library.Unloaded or not Toggles.OvrSpoofEnabled.Value then return end
			applyOvrSpoof()
		end)
	end
end

local function scheduleOvrSpoofRetries()
	if not (Toggles.OvrSpoofEnabled and Toggles.OvrSpoofEnabled.Value) then return end
	for _, delay in ipairs({ 0, 0.5, 1, 2 }) do
		task.delay(delay, function()
			if Library.Unloaded or not Toggles.OvrSpoofEnabled.Value then return end
			applyOvrSpoof()
		end)
	end
end

Toggles.OvrSpoofEnabled:OnChanged(function(enabled)
	if enabled then
		applyOvrSpoof()
		scheduleOvrSpoofRetries()
	end
	updateOvrSpoofLoop()
end)

-- ============================
-- CREDITS TAB
-- ============================

local CreditsGroup = Tabs.Credits:AddLeftGroupbox("evilware Credits")
CreditsGroup:AddLabel("evilware - basketball cheats & movement")
CreditsGroup:AddDivider()
CreditsGroup:AddLabel("Main Dev: 6vi1")
CreditsGroup:AddLabel("Main Dev: vamp")
CreditsGroup:AddLabel("UI: Obsidian (LinoriaLib)")
CreditsGroup:AddLabel("Inspiration: hoops")
CreditsGroup:AddLabel("Testing: the streets")
CreditsGroup:AddLabel("Vibes: immaculate")
CreditsGroup:AddDivider()
CreditsGroup:AddLabel("Special thanks to everyone who uses this")
CreditsGroup:AddLabel("— 6vi1 / vamp")

-- ============================
-- CHARACTER RESPAWN HANDLER
-- ============================

LocalPlayer.CharacterAdded:Connect(function(char)
	Character = char
	Humanoid = char:WaitForChild("Humanoid")
	RootPart = char:WaitForChild("HumanoidRootPart")

	if Toggles.WalkspeedEnabled and Toggles.WalkspeedEnabled.Value then
		setupWalkspeedHook(char)
		Humanoid.WalkSpeed = Options.Walkspeed.Value
	end

	if Toggles.OvrSpoofEnabled and Toggles.OvrSpoofEnabled.Value then
		task.defer(function()
			applyOvrSpoof()
			scheduleOvrSpoofRetries()
		end)
	end

	if desyncGhostModel then desyncGhostModel:Destroy() desyncGhostModel = nil end
end)

-- ============================
-- UNLOAD HANDLER
-- ============================

Library:OnUnload(function()
	if walkspeedLoopConnection then walkspeedLoopConnection:Disconnect() end
	for _, c in ipairs(walkspeedPropertyConnections) do pcall(function() c:Disconnect() end) end
	if silentVisionConnection then silentVisionConnection:Disconnect() end
	for _, c in ipairs(silentVisionInputConnections) do pcall(function() c:Disconnect() end) end
	if l3FireConnection then l3FireConnection:Disconnect() end
	if activeDribbleTween then activeDribbleTween:Cancel() end
	if noclipConn then noclipConn:Disconnect() end
	if ovrSpoofLoopConn then ovrSpoofLoopConn:Disconnect() end
	if desyncHeartbeatConnection then desyncHeartbeatConnection:Disconnect() end
	if desyncGhostModel then desyncGhostModel:Destroy() end
end)

-- ============================
-- UI SETTINGS
-- ============================

local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu")
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })
MenuGroup:AddButton("Unload", function() Library:Unload() end)
Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetFolder("evilware")
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])
SaveManager:LoadAutoloadConfig()

task.defer(updateOvrSpoofLoop)

print("evilware loaded | 6vi1 / vamp")
