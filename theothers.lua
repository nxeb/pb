-- VisionHub v5 Main | Obfuscate THIS, host on GitHub as main.lua
-- Credits: @v9os & @6crm on Discord

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local function isPlayerMoving()
	if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.A)
		or UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.D) then
		return true
	end
	local gamepads = UserInputService:GetConnectedGamepads()
	for _, gp in gamepads do
		local state = UserInputService:GetGamepadState(gp)
		for _, input in state do
			if input.KeyCode == Enum.KeyCode.Thumbstick1 then
				if input.Position.Magnitude > 0.2 then return true end
			end
		end
	end
	return false
end

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

-- ━━━━━━━━━━ GAME REFERENCES ━━━━━━━━━━

local AeroRemotes = ReplicatedStorage:WaitForChild("Aero"):WaitForChild("AeroRemoteServices")
local InputRemotes = AeroRemotes:WaitForChild("InputService")
local ShootRemote = InputRemotes:WaitForChild("Shoot")
local MeterRemotes = AeroRemotes:WaitForChild("MeterService")
local RegisterPacket = MeterRemotes:WaitForChild("RegisterPacket")
local UpdateGreenWindow = MeterRemotes:WaitForChild("UpdateGreenWindow")
local UnregisterPacket = MeterRemotes:WaitForChild("UnregisterPacket")

local function getCharacterModel()
	local chars = workspace:FindFirstChild("Characters")
	if not chars then return nil end
	return chars:FindFirstChild(LocalPlayer.Name)
end

local function getAllCharacterModels()
	local chars = workspace:FindFirstChild("Characters")
	if not chars then return {} end
	local result = {}
	for _, child in chars:GetChildren() do
		if child:IsA("Model") and child.Name ~= "InvisCharacter" then
			table.insert(result, child)
		end
	end
	return result
end

-- R15 joint pairs for skeleton ESP
local BONE_CONNECTIONS = {
	{"Head", "UpperTorso"},
	{"UpperTorso", "LowerTorso"},
	{"UpperTorso", "LeftUpperArm"},
	{"LeftUpperArm", "LeftLowerArm"},
	{"LeftLowerArm", "LeftHand"},
	{"UpperTorso", "RightUpperArm"},
	{"RightUpperArm", "RightLowerArm"},
	{"RightLowerArm", "RightHand"},
	{"LowerTorso", "LeftUpperLeg"},
	{"LeftUpperLeg", "LeftLowerLeg"},
	{"LeftLowerLeg", "LeftFoot"},
	{"LowerTorso", "RightUpperLeg"},
	{"RightUpperLeg", "RightLowerLeg"},
	{"RightLowerLeg", "RightFoot"},
}

-- cleanup registry
local _connections = {}
local _espObjects = {}

-- ━━━━━━━━━━ WINDOW ━━━━━━━━━━

local Window = Library:CreateWindow({
	Title = "VisionHub v5",
	Footer = "@v9os & @6crm",
	Center = true,
	AutoShow = true,
	NotifySide = "Right",
	ShowCustomCursor = true,
})

local Tabs = {
	Player    = Window:AddTab("Player", "user"),
	Character = Window:AddTab("Character", "zap"),
	AutoGreen = Window:AddTab("Auto Green", "target"),
	Visuals   = Window:AddTab("Visuals", "eye"),
	Misc      = Window:AddTab("Misc", "box"),
	Settings  = Window:AddTab("Settings", "settings"),
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TAB: PLAYER
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local PlayerLeft  = Tabs.Player:AddLeftGroupbox("Profile (Player)", "edit")
local PlayerRight = Tabs.Player:AddRightGroupbox("Character Model", "bar-chart")

-- Player attributes (on the Player instance itself)
PlayerLeft:AddInput("BuildNickname", {
	Text = "Build Nickname",
	Default = "",
	Placeholder = "2-Way Slashing Creator",
	Finished = true,
	Callback = function(v)
		LocalPlayer:SetAttribute("BuildNickname", v)
	end,
})

PlayerLeft:AddDropdown("Reputation", {
	Values = {"Starter", "Amateur", "Pro", "Allstar", "Superstar", "Legend"},
	Default = 1,
	Text = "Reputation",
	Callback = function(v)
		LocalPlayer:SetAttribute("Reputation", v)
	end,
})

PlayerLeft:AddInput("Title", {
	Text = "Title",
	Default = "",
	Placeholder = "Legend",
	Finished = true,
	Callback = function(v)
		LocalPlayer:SetAttribute("Title", v)
	end,
})

PlayerLeft:AddInput("BannerImage", {
	Text = "Banner Image",
	Default = "",
	Placeholder = "Default",
	Finished = true,
	Callback = function(v)
		LocalPlayer:SetAttribute("BannerImage", v)
	end,
})

PlayerLeft:AddDivider()

-- Name spoofer — finds and changes all UI TextLabels showing the player name
local spoofedName = ""
local spoofConn = nil

PlayerLeft:AddInput("SpoofName", {
	Text = "Name Spoofer",
	Default = "",
	Placeholder = "FakeName123",
	Finished = true,
	Callback = function(v)
		spoofedName = v
		if v == "" then
			if spoofConn then spoofConn:Disconnect() spoofConn = nil end
			return
		end
		if spoofConn then return end
		spoofConn = RunService.Heartbeat:Connect(function()
			if spoofedName == "" then return end
			local char = getCharacterModel()
			if not char then return end
			local displayName = spoofedName

			local head = char:FindFirstChild("Head")
			if head then
				local nametag = head:FindFirstChild("Nametag")
				if nametag then
					nametag.Enabled = true
					for _, obj in nametag:GetDescendants() do
						if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj.Text ~= displayName then
							obj.Text = displayName
						end
					end
				end
			end

			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then
				local banner = hrp:FindFirstChild("Banner")
				if banner then
					local holder = banner:FindFirstChild("Container")
					if holder then
						for _, obj in holder:GetDescendants() do
							if obj.Name == "PlayerName" and (obj:IsA("TextLabel") or obj:IsA("TextButton")) then
								if obj.Text ~= displayName then obj.Text = displayName end
							end
						end
					end
				end
			end

			local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
			if playerGui then
				for _, gui in playerGui:GetChildren() do
					if gui:IsA("ScreenGui") then
						for _, obj in gui:GetDescendants() do
							if obj.Name == "PlayerName" and (obj:IsA("TextLabel") or obj:IsA("TextButton")) then
								if obj.Text == LocalPlayer.Name or obj.Text == ("@" .. LocalPlayer.Name) then
									obj.Text = obj.Text:find("@") and ("@" .. displayName) or displayName
								end
							end
						end
					end
				end
			end
		end)
	end,
})

-- Character model attributes (on the model in workspace.Characters)
PlayerRight:AddDropdown("Position", {
	Values = {"PG", "SG", "SF", "PF", "C"},
	Default = 1,
	Text = "Position",
	Callback = function(v)
		local char = getCharacterModel()
		if char then char:SetAttribute("Position", v) end
	end,
})

PlayerRight:AddDropdown("Hand", {
	Values = {"R", "L"},
	Default = 1,
	Text = "Dominant Hand",
	Callback = function(v)
		local char = getCharacterModel()
		if char then char:SetAttribute("Hand", v) end
	end,
})

PlayerRight:AddInput("TakeoverType", {
	Text = "Takeover Type",
	Default = "",
	Placeholder = "Fadeaway King",
	Finished = true,
	Callback = function(v)
		local char = getCharacterModel()
		if char then char:SetAttribute("TakeoverType", v) end
	end,
})

PlayerRight:AddSlider("Overall", {
	Text = "Overall",
	Default = 99,
	Min = 1,
	Max = 99,
	Rounding = 0,
	Callback = function(v)
		local char = getCharacterModel()
		if char then char:SetAttribute("Overall", v) end
	end,
})

PlayerRight:AddSlider("Height", {
	Text = "Height (inches)",
	Default = 80,
	Min = 60,
	Max = 96,
	Rounding = 0,
	Callback = function(v)
		local char = getCharacterModel()
		if char then char:SetAttribute("Height", v) end
	end,
})

PlayerRight:AddSlider("Weight", {
	Text = "Weight (lbs)",
	Default = 180,
	Min = 120,
	Max = 300,
	Rounding = 0,
	Callback = function(v)
		local char = getCharacterModel()
		if char then char:SetAttribute("Weight", v) end
	end,
})

PlayerRight:AddSlider("Grade", {
	Text = "Grade",
	Default = 44,
	Min = 0,
	Max = 100,
	Rounding = 0,
	Callback = function(v)
		local char = getCharacterModel()
		if char then char:SetAttribute("Grade", v) end
	end,
})

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TAB: CHARACTER
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local CharLeft  = Tabs.Character:AddLeftGroupbox("Attributes", "shield")
local CharRight = Tabs.Character:AddRightGroupbox("Movement", "gauge")

CharLeft:AddToggle("InfStamina", {
	Text = "Infinite Stamina",
	Default = false,
})

CharLeft:AddToggle("AlwaysTakeover", {
	Text = "Always Takeover",
	Default = false,
})

CharLeft:AddToggle("NeverCold", {
	Text = "Never Cold",
	Default = false,
})

CharLeft:AddToggle("MaxPower", {
	Text = "Max Power",
	Default = false,
})

CharRight:AddToggle("SpeedBoost", {
	Text = "Permanent Speed Boost",
	Default = false,
	Tooltip = "Uses game SpeedBoost/AccelerationBoost attributes (zeros when standing still)",
})

CharRight:AddSlider("SpeedBoostValue", {
	Text = "Speed Amount",
	Default = 3.0,
	Min = 0.5,
	Max = 15.0,
	Rounding = 1,
})

CharRight:AddDivider()

CharRight:AddToggle("DribbleExtender", {
	Text = "Dribble Distance Extender",
	Default = false,
	Tooltip = "Scales ProxyCharacter velocity during dribble animations",
})

CharRight:AddSlider("DribbleBoostAmount", {
	Text = "Dribble Boost",
	Default = 1.5,
	Min = 1.0,
	Max = 5.0,
	Rounding = 1,
	Suffix = "x",
})

-- character attribute loop
task.spawn(function()
	while task.wait(0.1) do
		if Library.Unloaded then break end

		local char = getCharacterModel()
		if not char then continue end

		if Toggles.InfStamina and Toggles.InfStamina.Value then
			char:SetAttribute("Stamina", 100)
		end

		if Toggles.AlwaysTakeover and Toggles.AlwaysTakeover.Value then
			char:SetAttribute("TakeoverFill", 100)
			char:SetAttribute("Takeover", true)
		end

		if Toggles.NeverCold and Toggles.NeverCold.Value then
			char:SetAttribute("Cold", false)
		end

		if Toggles.MaxPower and Toggles.MaxPower.Value then
			char:SetAttribute("Power", 99999)
			char:SetAttribute("Damping", 950)
		end

	end
end)

-- permanent speed boost via game attributes (zeros when standing still)
local speedConn = nil

local function startSpeedBoost()
	if speedConn then return end
	speedConn = RunService.Heartbeat:Connect(function()
		if not (Toggles.SpeedBoost and Toggles.SpeedBoost.Value) then return end

		local char = getCharacterModel()
		if not char then return end

		local moving = isPlayerMoving()
		local boostVal = Options.SpeedBoostValue and Options.SpeedBoostValue.Value or 3

		if moving then
			char:SetAttribute("SpeedBoost", boostVal)
			char:SetAttribute("AccelerationBoost", boostVal)
			char:SetAttribute("SpeedBoostTime", 9999)
		else
			char:SetAttribute("SpeedBoost", 0)
			char:SetAttribute("AccelerationBoost", 0)
			char:SetAttribute("SpeedBoostTime", 0)
		end
	end)
end

local function stopSpeedBoost()
	if speedConn then
		speedConn:Disconnect()
		speedConn = nil
	end
	local char = getCharacterModel()
	if char then
		char:SetAttribute("SpeedBoost", 0)
		char:SetAttribute("AccelerationBoost", 0)
		char:SetAttribute("SpeedBoostTime", 0)
	end
end

-- dribble extender via ProxyCharacter BodyVelocity scaling
local dribbleConn = nil

local function startDribbleExtender()
	if dribbleConn then return end
	dribbleConn = RunService.Heartbeat:Connect(function()
		if not (Toggles.DribbleExtender and Toggles.DribbleExtender.Value) then return end

		local char = getCharacterModel()
		if not char then return end
		local action = char:GetAttribute("Action") or ""
		if action ~= "Dribbling" then return end

		local proxy = workspace:FindFirstChild("ProxyCharacter")
		if not proxy then return end
		local bv = proxy:FindFirstChild("MovementVelocity")
		if not bv or not bv:IsA("BodyVelocity") then return end

		local vel = bv.Velocity
		if vel.Magnitude < 1 then return end

		local mult = Options.DribbleBoostAmount and Options.DribbleBoostAmount.Value or 1.5
		if mult > 1.0 then
			bv.Velocity = vel.Unit * vel.Magnitude * mult
		end
	end)
end

Toggles.SpeedBoost:OnChanged(function(v)
	if v then startSpeedBoost() else stopSpeedBoost() end
end)

Toggles.DribbleExtender:OnChanged(function(v)
	if v then
		startDribbleExtender()
	else
		if dribbleConn then dribbleConn:Disconnect() dribbleConn = nil end
	end
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TAB: AUTO GREEN
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--
-- Meter types live on Head or HumanoidRootPart:
--   Head: RobloxMeter, HoopMeter
--   HRP:  BatMeter, VerticalMeter, RocketMeter
-- Each has: Meter_Fill > FillGradient (UIGradient, Offset tracks needle)
--           Meter_Green > UIGradient (Transparency = green zone)
-- Shot release = ShootRemote:FireServer({Shoot = false})

local GreenLeft  = Tabs.AutoGreen:AddLeftGroupbox("UI Trace (Auto)", "crosshair")
local GreenRight = Tabs.AutoGreen:AddRightGroupbox("Timed Release", "clock")

-- ===== METHOD 1: UI TRACE =====

GreenLeft:AddToggle("AutoGreen", {
	Text = "Auto Green (UI Trace)",
	Default = false,
	Tooltip = "Watches the actual meter UI and releases at the green zone",
})

GreenLeft:AddSlider("GreenOffset", {
	Text = "Green Offset",
	Default = 0,
	Min = -50,
	Max = 50,
	Rounding = 0,
	Suffix = "ms",
})

GreenLeft:AddDropdown("GreenChance", {
	Values = {"100%", "90%", "75%", "50%"},
	Default = 1,
	Text = "Green Chance",
})

-- ===== METHOD 2: TIMED RELEASE =====

GreenRight:AddToggle("TimedRelease", {
	Text = "Timed Release",
	Default = false,
	Tooltip = "Waits for meter to appear, then releases after a set delay",
})

GreenRight:AddSlider("ShootDelay", {
	Text = "Shoot Delay",
	Default = 0.5,
	Min = 0.1,
	Max = 1.0,
	Rounding = 2,
	Suffix = "s",
	Tooltip = "Standing shot (E / ButtonX)",
})

GreenRight:AddSlider("FadeDelay", {
	Text = "Fade Delay",
	Default = 0.45,
	Min = 0.1,
	Max = 1.0,
	Rounding = 2,
	Suffix = "s",
	Tooltip = "Fadeaway / moving shot timing",
})

GreenRight:AddSlider("DunkDelay", {
	Text = "Dunk Delay",
	Default = 0.4,
	Min = 0.1,
	Max = 1.0,
	Rounding = 2,
	Suffix = "s",
	Tooltip = "Dunk (Space / ButtonY)",
})

-- AutoGreen loaded from GitHub (unobfuscated, obfuscator breaks task.delay/FireServer)
local AUTOGREEN_URL = "https://raw.githubusercontent.com/nxeb/pb/refs/heads/main/autogreen.lua"
local agResult = nil

local agOk, agErr = pcall(function()
	local agSrc = game:HttpGet(AUTOGREEN_URL)
	if not agSrc or #agSrc < 10 then
		warn("[VisionHub] AutoGreen: failed to download module (empty response)")
		return
	end
	local agFunc, loadErr = loadstring(agSrc)
	if not agFunc then
		warn("[VisionHub] AutoGreen: loadstring failed:", loadErr)
		return
	end
	local agModule = agFunc()
	if type(agModule) ~= "function" then
		warn("[VisionHub] AutoGreen: module did not return a function, got:", type(agModule))
		return
	end
	agResult = agModule({
		Toggles = Toggles,
		Options = Options,
		RegisterPacket = RegisterPacket,
		UnregisterPacket = UnregisterPacket,
		ShootRemote = ShootRemote,
	})
	warn("[VisionHub] AutoGreen module loaded successfully")
end)

if not agOk then
	warn("[VisionHub] AutoGreen failed to load:", agErr)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TAB: VISUALS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local VisLeft  = Tabs.Visuals:AddLeftGroupbox("ESP", "eye")
local VisRight = Tabs.Visuals:AddRightGroupbox("Client Visual", "palette")

VisLeft:AddToggle("SkeletonESP", {
	Text = "Skeleton ESP",
	Default = false,
	Tooltip = "Draws bone lines on all other players",
})

VisLeft:AddToggle("NameESP", {
	Text = "Name ESP",
	Default = false,
	Tooltip = "Shows player names through walls",
})

VisLeft:AddDivider()

VisLeft:AddToggle("HideOtherNames", {
	Text = "Hide Others' Nametags",
	Default = false,
	Tooltip = "Hides all other players' overhead nametags and banners",
})

VisLeft:AddToggle("SpoofOtherNames", {
	Text = "Spoof Others' Names",
	Default = false,
	Tooltip = "Changes all other players' nametag text",
})

VisLeft:AddInput("SpoofOtherText", {
	Text = "Spoofed Name",
	Default = "dumbass im spoofed",
	Placeholder = "dumbass im spoofed",
	Finished = true,
})

VisLeft:AddToggle("DistanceESP", {
	Text = "Show Distance",
	Default = false,
	Tooltip = "Adds distance (studs) under name ESP",
})

VisLeft:AddSlider("ESPRange", {
	Text = "ESP Range",
	Default = 200,
	Min = 50,
	Max = 500,
	Rounding = 0,
	Suffix = " studs",
})

VisLeft:AddDropdown("ESPTeamColor", {
	Values = {"White", "Green", "Cyan", "Yellow", "Red", "Magenta"},
	Default = 1,
	Text = "ESP Color",
})

local ESP_COLORS = {
	White = Color3.new(1, 1, 1),
	Green = Color3.fromRGB(85, 255, 127),
	Cyan = Color3.fromRGB(85, 255, 255),
	Yellow = Color3.fromRGB(255, 255, 85),
	Red = Color3.fromRGB(255, 85, 85),
	Magenta = Color3.fromRGB(255, 85, 255),
}

-- highlight / glow on self
VisRight:AddToggle("SelfHighlight", {
	Text = "Self Highlight",
	Default = false,
	Tooltip = "Adds a glow highlight to your character",
})

VisRight:AddDropdown("HighlightColor", {
	Values = {"White", "Green", "Cyan", "Yellow", "Red", "Magenta"},
	Default = 2,
	Text = "Highlight Color",
})

VisRight:AddSlider("HighlightTransparency", {
	Text = "Fill Transparency",
	Default = 0.7,
	Min = 0,
	Max = 1,
	Rounding = 2,
})

VisRight:AddDivider()

VisRight:AddToggle("BallTracer", {
	Text = "Ball Tracer",
	Default = false,
	Tooltip = "Draws a line to the nearest basketball",
})

-- ===== STUPID FUN STUFF =====

local FunLeft  = Tabs.Visuals:AddLeftGroupbox("Fun Stuff", "sparkles")
local FunRight = Tabs.Visuals:AddRightGroupbox("More Fun", "flame")

FunLeft:AddToggle("RainbowBody", {
	Text = "Rainbow Body",
	Default = false,
})

FunLeft:AddToggle("TransparentBody", {
	Text = "Ghost Mode",
	Default = false,
})

FunLeft:AddToggle("FireEffect", {
	Text = "Fire Effect",
	Default = false,
})

FunLeft:AddToggle("SparkleEffect", {
	Text = "Sparkle Effect",
	Default = false,
})

FunRight:AddToggle("SmokeEffect", {
	Text = "Smoke Effect",
	Default = false,
})

FunRight:AddToggle("GoldBody", {
	Text = "Gold Body",
	Default = false,
})

FunRight:AddToggle("NeonBody", {
	Text = "Neon Body",
	Default = false,
})

FunRight:AddToggle("TinyPlayer", {
	Text = "Tiny Player",
	Default = false,
	Tooltip = "Shrinks your character (client only)",
})

-- ===== ESP DRAWING =====

local DrawingLib = {}

function DrawingLib.newLine()
	local l = Drawing.new("Line")
	l.Visible = false
	l.Thickness = 1.5
	l.Color = Color3.new(1, 1, 1)
	return l
end

function DrawingLib.newText()
	local t = Drawing.new("Text")
	t.Visible = false
	t.Size = 14
	t.Center = true
	t.Outline = true
	t.OutlineColor = Color3.new(0, 0, 0)
	t.Color = Color3.new(1, 1, 1)
	return t
end

local espCache = {}

local function getOrCreateESP(model)
	if espCache[model] then return espCache[model] end

	local data = {
		bones = {},
		nameLabel = DrawingLib.newText(),
		distLabel = DrawingLib.newText(),
	}

	for i = 1, #BONE_CONNECTIONS do
		data.bones[i] = DrawingLib.newLine()
	end

	espCache[model] = data
	return data
end

local function cleanupESPFor(model)
	local data = espCache[model]
	if not data then return end
	for _, line in data.bones do line:Remove() end
	data.nameLabel:Remove()
	data.distLabel:Remove()
	espCache[model] = nil
end

local function cleanupAllESP()
	for model, _ in pairs(espCache) do
		cleanupESPFor(model)
	end
end

local function getESPColor()
	local name = Options.ESPTeamColor and Options.ESPTeamColor.Value or "White"
	return ESP_COLORS[name] or Color3.new(1, 1, 1)
end

local espConn = nil

local function startESPLoop()
	if espConn then return end

	espConn = RunService.RenderStepped:Connect(function()
		if Library.Unloaded then
			cleanupAllESP()
			if espConn then espConn:Disconnect(); espConn = nil end
			return
		end

		local skeletonOn = Toggles.SkeletonESP and Toggles.SkeletonESP.Value
		local nameOn = Toggles.NameESP and Toggles.NameESP.Value
		local distOn = Toggles.DistanceESP and Toggles.DistanceESP.Value
		local range = Options.ESPRange and Options.ESPRange.Value or 200
		local color = getESPColor()

		if not skeletonOn and not nameOn then
			for _, data in pairs(espCache) do
				for _, line in data.bones do line.Visible = false end
				data.nameLabel.Visible = false
				data.distLabel.Visible = false
			end
			return
		end

		local myChar = getCharacterModel()
		local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
		local targets = getAllCharacterModels()

		local activeModels = {}
		for _, model in targets do
			activeModels[model] = true

			local root = model:FindFirstChild("HumanoidRootPart")
			if not root then continue end

			local dist = myRoot and (myRoot.Position - root.Position).Magnitude or 0
			if dist > range then
				local data = espCache[model]
				if data then
					for _, line in data.bones do line.Visible = false end
					data.nameLabel.Visible = false
					data.distLabel.Visible = false
				end
				continue
			end

			local data = getOrCreateESP(model)

			-- skeleton
			if skeletonOn then
				for i, pair in BONE_CONNECTIONS do
					local partA = model:FindFirstChild(pair[1])
					local partB = model:FindFirstChild(pair[2])
					local line = data.bones[i]

					if partA and partB then
						local screenA, onScreenA = Camera:WorldToViewportPoint(partA.Position)
						local screenB, onScreenB = Camera:WorldToViewportPoint(partB.Position)

						if onScreenA and onScreenB then
							line.From = Vector2.new(screenA.X, screenA.Y)
							line.To = Vector2.new(screenB.X, screenB.Y)
							line.Color = color
							line.Visible = true
						else
							line.Visible = false
						end
					else
						line.Visible = false
					end
				end
			else
				for _, line in data.bones do line.Visible = false end
			end

			-- name ESP
			local head = model:FindFirstChild("Head")
			if nameOn and head then
				local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 2, 0))
				if onScreen then
					data.nameLabel.Text = model.Name
					data.nameLabel.Position = Vector2.new(screenPos.X, screenPos.Y)
					data.nameLabel.Color = color
					data.nameLabel.Visible = true

					if distOn then
						data.distLabel.Text = math.floor(dist) .. " studs"
						data.distLabel.Position = Vector2.new(screenPos.X, screenPos.Y + 16)
						data.distLabel.Color = color
						data.distLabel.Visible = true
					else
						data.distLabel.Visible = false
					end
				else
					data.nameLabel.Visible = false
					data.distLabel.Visible = false
				end
			else
				data.nameLabel.Visible = false
				data.distLabel.Visible = false
			end
		end

		for model, _ in pairs(espCache) do
			if not activeModels[model] then
				cleanupESPFor(model)
			end
		end
	end)
end

-- start ESP when any toggle turns on
local function checkESP()
	local need = (Toggles.SkeletonESP and Toggles.SkeletonESP.Value) or (Toggles.NameESP and Toggles.NameESP.Value)
	if need then
		startESPLoop()
	else
		if espConn then
			espConn:Disconnect()
			espConn = nil
		end
		cleanupAllESP()
	end
end

Toggles.SkeletonESP:OnChanged(checkESP)
Toggles.NameESP:OnChanged(checkESP)

-- hide / spoof other players' nametags
local otherNameConn = nil

local function startOtherNameLoop()
	if otherNameConn then return end
	otherNameConn = RunService.Heartbeat:Connect(function()
		if Library.Unloaded then
			if otherNameConn then otherNameConn:Disconnect() otherNameConn = nil end
			return
		end

		local hideOn = Toggles.HideOtherNames and Toggles.HideOtherNames.Value
		local spoofOn = Toggles.SpoofOtherNames and Toggles.SpoofOtherNames.Value
		if not hideOn and not spoofOn then return end

		local spoofText = Options.SpoofOtherText and Options.SpoofOtherText.Value or "dumbass im spoofed"
		local myChar = getCharacterModel()
		local targets = getAllCharacterModels()

		for _, model in targets do
			if model == myChar then continue end

			local head = model:FindFirstChild("Head")
			if head then
				local nametag = head:FindFirstChild("Nametag")
				if nametag then
					if hideOn and not spoofOn then
						nametag.Enabled = false
					elseif spoofOn then
						nametag.Enabled = true
						for _, obj in nametag:GetDescendants() do
							if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj.Text ~= spoofText then
								obj.Text = spoofText
							end
						end
					end
				end
			end

			local hrp = model:FindFirstChild("HumanoidRootPart")
			if hrp then
				local banner = hrp:FindFirstChild("Banner")
				if banner then
					if hideOn and not spoofOn then
						banner.Enabled = false
					elseif spoofOn then
						for _, obj in banner:GetDescendants() do
							if obj.Name == "PlayerName" and (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj.Text ~= spoofText then
								obj.Text = spoofText
							end
						end
					end
				end
			end
		end
	end)
end

local function stopOtherNameLoop()
	if otherNameConn then otherNameConn:Disconnect() otherNameConn = nil end
end

local function checkOtherNames()
	local need = (Toggles.HideOtherNames and Toggles.HideOtherNames.Value) or (Toggles.SpoofOtherNames and Toggles.SpoofOtherNames.Value)
	if need then startOtherNameLoop() else stopOtherNameLoop() end
end

Toggles.HideOtherNames:OnChanged(checkOtherNames)
Toggles.SpoofOtherNames:OnChanged(checkOtherNames)

-- self highlight
local selfHighlight = nil

Toggles.SelfHighlight:OnChanged(function()
	if Toggles.SelfHighlight.Value then
		local char = getCharacterModel()
		if not char then return end
		if selfHighlight then selfHighlight:Destroy() end
		selfHighlight = Instance.new("Highlight")
		selfHighlight.Name = "PracticalHighlight"
		selfHighlight.Adornee = char
		local c = ESP_COLORS[Options.HighlightColor and Options.HighlightColor.Value or "Green"] or Color3.fromRGB(85, 255, 127)
		selfHighlight.FillColor = c
		selfHighlight.OutlineColor = c
		selfHighlight.FillTransparency = Options.HighlightTransparency and Options.HighlightTransparency.Value or 0.7
		selfHighlight.OutlineTransparency = 0
		selfHighlight.Parent = char
	else
		if selfHighlight then
			selfHighlight:Destroy()
			selfHighlight = nil
		end
	end
end)

-- ball tracer
local ballTracerLine = nil
local ballTracerConn = nil

Toggles.BallTracer:OnChanged(function()
	if Toggles.BallTracer.Value then
		if not ballTracerLine then
			ballTracerLine = Drawing.new("Line")
			ballTracerLine.Thickness = 2
			ballTracerLine.Color = Color3.fromRGB(255, 165, 0)
		end
		if ballTracerConn then return end
		ballTracerConn = RunService.RenderStepped:Connect(function()
			if not (Toggles.BallTracer and Toggles.BallTracer.Value) then
				ballTracerLine.Visible = false
				return
			end

			local basketballs = workspace:FindFirstChild("Basketballs")
			if not basketballs then ballTracerLine.Visible = false return end

			local nearest = nil
			local nearestDist = math.huge
			local myChar = getCharacterModel()
			local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
			if not myRoot then ballTracerLine.Visible = false return end

			for _, ball in basketballs:GetChildren() do
				if ball:IsA("BasePart") or ball:IsA("Model") then
					local pos = ball:IsA("Model") and ball:GetPivot().Position or ball.Position
					local d = (myRoot.Position - pos).Magnitude
					if d < nearestDist then
						nearestDist = d
						nearest = pos
					end
				end
			end

			if nearest and nearestDist < 200 then
				local screenBall, onScreen = Camera:WorldToViewportPoint(nearest)
				if onScreen then
					local viewportSize = Camera.ViewportSize
					ballTracerLine.From = Vector2.new(viewportSize.X / 2, viewportSize.Y)
					ballTracerLine.To = Vector2.new(screenBall.X, screenBall.Y)
					ballTracerLine.Visible = true
				else
					ballTracerLine.Visible = false
				end
			else
				ballTracerLine.Visible = false
			end
		end)
	else
		if ballTracerConn then
			ballTracerConn:Disconnect()
			ballTracerConn = nil
		end
		if ballTracerLine then
			ballTracerLine.Visible = false
		end
	end
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TAB: MISC
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local MiscLeft  = Tabs.Misc:AddLeftGroupbox("Exploits", "flame")
local MiscRight = Tabs.Misc:AddRightGroupbox("Info", "info")

MiscLeft:AddToggle("AntiAFK", {
	Text = "Anti AFK",
	Default = true,
	Tooltip = "Prevents idle kick",
})

MiscLeft:AddButton({
	Text = "Rejoin Server",
	Func = function()
		game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId)
	end,
	DoubleClick = true,
})

MiscLeft:AddButton({
	Text = "Copy Server Link",
	Func = function()
		local link = "roblox://experiences/start?placeId=" .. game.PlaceId .. "&gameInstanceId=" .. game.JobId
		pcall(function() setclipboard(link) end)
		Library:Notify({ Title = "Copied", Description = "Server link copied to clipboard", Time = 3 })
	end,
})

MiscLeft:AddToggle("NoClip", {
	Text = "No Clip",
	Default = false,
})

MiscLeft:AddToggle("BigHead", {
	Text = "Big Head (others)",
	Default = false,
	Tooltip = "Enlarges other players' heads — client only",
})

-- anti afk
task.spawn(function()
	while task.wait(60) do
		if Library.Unloaded then break end
		if Toggles.AntiAFK and Toggles.AntiAFK.Value then
			pcall(function()
				local VIM = game:GetService("VirtualInputManager")
				VIM:SendKeyEvent(true, Enum.KeyCode.Unknown, false, game)
				VIM:SendKeyEvent(false, Enum.KeyCode.Unknown, false, game)
			end)
		end
	end
end)

-- noclip
local noclipConn = nil

Toggles.NoClip:OnChanged(function()
	if Toggles.NoClip.Value then
		noclipConn = RunService.Stepped:Connect(function()
			local char = getCharacterModel()
			if not char then return end
			for _, part in char:GetDescendants() do
				if part:IsA("BasePart") then
					part.CanCollide = false
				end
			end
		end)
	else
		if noclipConn then
			noclipConn:Disconnect()
			noclipConn = nil
		end
	end
end)

-- big head
local bigHeadConn = nil
local originalHeadSizes = {}

Toggles.BigHead:OnChanged(function()
	if Toggles.BigHead.Value then
		bigHeadConn = RunService.Heartbeat:Connect(function()
			for _, model in getAllCharacterModels() do
				local head = model:FindFirstChild("Head")
				if head and head:IsA("BasePart") then
					if not originalHeadSizes[model] then
						originalHeadSizes[model] = head.Size
					end
					head.Size = Vector3.new(4, 4, 4)
				end
			end
		end)
	else
		if bigHeadConn then
			bigHeadConn:Disconnect()
			bigHeadConn = nil
		end
		for model, origSize in pairs(originalHeadSizes) do
			local head = model:FindFirstChild("Head")
			if head and head:IsA("BasePart") then
				head.Size = origSize
			end
		end
		originalHeadSizes = {}
	end
end)

MiscRight:AddLabel("Game: Practical Basketball")
MiscRight:AddLabel("VisionHub v5 | @v9os & @6crm")
MiscRight:AddLabel("Executor: Xeno Compatible")
MiscRight:AddDivider()
MiscRight:AddLabel("Toggle: RightShift", true)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TAB: SETTINGS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu", "wrench")

MenuGroup:AddToggle("KeybindMenuOpen", {
	Default = Library.KeybindFrame.Visible,
	Text = "Open Keybind Menu",
	Callback = function(value)
		Library.KeybindFrame.Visible = value
	end,
})

MenuGroup:AddToggle("ShowCustomCursor", {
	Text = "Custom Cursor",
	Default = Library.ShowCustomCursor,
	Callback = function(Value)
		Library.ShowCustomCursor = Value
	end,
})

MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu Keybind"):AddKeyPicker("MenuKeybind", {
	Default = "RightShift",
	NoUI = true,
	Text = "Menu keybind",
})

MenuGroup:AddButton({
	Text = "Unload",
	Func = function() Library:Unload() end,
	DoubleClick = true,
})

Library.ToggleKeybind = Options.MenuKeybind

-- ===== FUN EFFECTS LOGIC =====

local rainbowConn = nil
local fireInstances = {}
local sparkleInstances = {}
local smokeInstances = {}
local originalColors = {}
local originalTransparencies = {}
local originalMaterials = {}
local originalScales = {}

-- rainbow body
Toggles.RainbowBody:OnChanged(function()
	if Toggles.RainbowBody.Value then
		local hue = 0
		rainbowConn = RunService.Heartbeat:Connect(function(dt)
			hue = (hue + dt * 0.5) % 1
			local char = getCharacterModel()
			if not char then return end
			local col = Color3.fromHSV(hue, 1, 1)
			for _, part in char:GetDescendants() do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					part.Color = col
				end
			end
		end)
	else
		if rainbowConn then rainbowConn:Disconnect(); rainbowConn = nil end
	end
end)

-- ghost mode
Toggles.TransparentBody:OnChanged(function()
	local char = getCharacterModel()
	if not char then return end
	if Toggles.TransparentBody.Value then
		for _, part in char:GetDescendants() do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				originalTransparencies[part] = part.Transparency
				part.Transparency = 0.7
			end
		end
	else
		for part, t in pairs(originalTransparencies) do
			if part and part.Parent then part.Transparency = t end
		end
		originalTransparencies = {}
	end
end)

-- fire
Toggles.FireEffect:OnChanged(function()
	local char = getCharacterModel()
	if not char then return end
	if Toggles.FireEffect.Value then
		local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso")
		if hrp then
			local f = Instance.new("Fire")
			f.Size = 5
			f.Heat = 10
			f.Color = Color3.fromRGB(255, 100, 0)
			f.SecondaryColor = Color3.fromRGB(255, 200, 0)
			f.Parent = hrp
			table.insert(fireInstances, f)
		end
	else
		for _, f in fireInstances do f:Destroy() end
		fireInstances = {}
	end
end)

-- sparkle
Toggles.SparkleEffect:OnChanged(function()
	local char = getCharacterModel()
	if not char then return end
	if Toggles.SparkleEffect.Value then
		local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso")
		if hrp then
			local s = Instance.new("Sparkles")
			s.SparkleColor = Color3.fromRGB(255, 255, 100)
			s.Parent = hrp
			table.insert(sparkleInstances, s)
		end
	else
		for _, s in sparkleInstances do s:Destroy() end
		sparkleInstances = {}
	end
end)

-- smoke
Toggles.SmokeEffect:OnChanged(function()
	local char = getCharacterModel()
	if not char then return end
	if Toggles.SmokeEffect.Value then
		local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso")
		if hrp then
			local s = Instance.new("Smoke")
			s.Size = 2
			s.Opacity = 0.3
			s.Color = Color3.new(0.3, 0.3, 0.3)
			s.RiseVelocity = 4
			s.Parent = hrp
			table.insert(smokeInstances, s)
		end
	else
		for _, s in smokeInstances do s:Destroy() end
		smokeInstances = {}
	end
end)

-- gold body
Toggles.GoldBody:OnChanged(function()
	local char = getCharacterModel()
	if not char then return end
	if Toggles.GoldBody.Value then
		for _, part in char:GetDescendants() do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				originalColors[part] = part.Color
				originalMaterials[part] = part.Material
				part.Color = Color3.fromRGB(255, 200, 50)
				part.Material = Enum.Material.Foil
				part.Reflectance = 0.5
			end
		end
	else
		for part, col in pairs(originalColors) do
			if part and part.Parent then
				part.Color = col
				part.Material = originalMaterials[part] or Enum.Material.Plastic
				part.Reflectance = 0
			end
		end
		originalColors = {}
		originalMaterials = {}
	end
end)

-- neon body
Toggles.NeonBody:OnChanged(function()
	local char = getCharacterModel()
	if not char then return end
	if Toggles.NeonBody.Value then
		for _, part in char:GetDescendants() do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				if not originalMaterials[part] then
					originalMaterials[part] = part.Material
				end
				part.Material = Enum.Material.Neon
			end
		end
	else
		for part, mat in pairs(originalMaterials) do
			if part and part.Parent then part.Material = mat end
		end
		originalMaterials = {}
	end
end)

-- tiny player
Toggles.TinyPlayer:OnChanged(function()
	local char = getCharacterModel()
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	if Toggles.TinyPlayer.Value then
		for _, scale in hum:GetChildren() do
			if scale:IsA("NumberValue") and scale.Name:find("Scale") then
				originalScales[scale] = scale.Value
				scale.Value = scale.Value * 0.5
			end
		end
	else
		for scale, v in pairs(originalScales) do
			if scale and scale.Parent then scale.Value = v end
		end
		originalScales = {}
	end
end)

-- ━━━━━━━━━━ CLEANUP ON UNLOAD ━━━━━━━━━━

Library:OnUnload(function()
	cleanupAllESP()

	if speedConn then speedConn:Disconnect() end
	if dribbleConn then dribbleConn:Disconnect() end
	if spoofConn then spoofConn:Disconnect() end
	stopSpeedBoost()
	if espConn then espConn:Disconnect() end
	if otherNameConn then otherNameConn:Disconnect() end
	if noclipConn then noclipConn:Disconnect() end
	if bigHeadConn then bigHeadConn:Disconnect() end
	if ballTracerConn then ballTracerConn:Disconnect() end
	if agResult and agResult.cleanupUITrace then agResult.cleanupUITrace() end
	if rainbowConn then rainbowConn:Disconnect() end
	if selfHighlight then selfHighlight:Destroy() end
	if ballTracerLine then ballTracerLine:Remove() end

	for _, f in fireInstances do f:Destroy() end
	for _, s in sparkleInstances do s:Destroy() end
	for _, s in smokeInstances do s:Destroy() end

	for part, t in pairs(originalTransparencies) do
		if part and part.Parent then part.Transparency = t end
	end
	for part, col in pairs(originalColors) do
		if part and part.Parent then part.Color = col; part.Reflectance = 0 end
	end
	for part, mat in pairs(originalMaterials) do
		if part and part.Parent then part.Material = mat end
	end
	for scale, v in pairs(originalScales) do
		if scale and scale.Parent then scale.Value = v end
	end
	for model, origSize in pairs(originalHeadSizes) do
		local head = model:FindFirstChild("Head")
		if head and head:IsA("BasePart") then head.Size = origSize end
	end
end)

-- ━━━━━━━━━━ SAVE/THEME ━━━━━━━━━━

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("PracticalBasketball")
SaveManager:SetFolder("PracticalBasketball/config")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

Library:Notify({
	Title = "VisionHub v5",
	Description = "Loaded — @v9os & @6crm",
	Time = 4,
})
