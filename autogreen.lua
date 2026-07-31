-- VisionHub v5 AutoGreen Module | DO NOT OBFUSCATE
-- Loaded at runtime by the main script

return function(deps)
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")

	local Toggles = deps.Toggles
	local Options = deps.Options
	local RegisterPacket = deps.RegisterPacket
	local UnregisterPacket = deps.UnregisterPacket
	local ShootRemote = deps.ShootRemote
	local getCharacterModel = deps.getCharacterModel
	local isPlayerMoving = deps.isPlayerMoving

	local function findMeterGui(char, meterType)
		if not char or not meterType then return nil end
		local guiName = meterType .. "Meter"
		for _, parentName in {"Head", "HumanoidRootPart"} do
			local parent = char:FindFirstChild(parentName)
			if parent then
				local m = parent:FindFirstChild(guiName)
				if m then return m end
			end
		end
		return nil
	end

	local function getGreenZoneStart(meterGui)
		local greenLabel = meterGui:FindFirstChild("Meter_Green")
		if not greenLabel then return nil end
		local gradient = greenLabel:FindFirstChild("UIGradient")
		if not gradient then return nil end
		local ts = gradient.Transparency
		if not ts or typeof(ts) ~= "NumberSequence" then return nil end
		for i, kp in ts.Keypoints do
			if kp.Value >= 0.9 and i > 1 then
				return kp.Time
			end
		end
		return nil
	end

	local function getFillProgress(meterGui)
		local fillLabel = meterGui:FindFirstChild("Meter_Fill")
		if not fillLabel then return 0 end
		local gradient = fillLabel:FindFirstChild("FillGradient")
		if not gradient then return 0 end
		local offset = gradient.Offset
		if typeof(offset) == "Vector2" then return offset.X end
		return 0
	end

	local function rollChance()
		local chanceStr = Options.GreenChance and Options.GreenChance.Value or "100%"
		local cleaned = chanceStr:gsub("%%", "")
		local chance = tonumber(cleaned) or 100
		return math.random(1, 100) <= chance
	end

	-- UI TRACE
	local uiTraceActive = false
	local uiTraceConn = nil

	local function cleanupUITrace()
		uiTraceActive = false
		if uiTraceConn then
			uiTraceConn:Disconnect()
			uiTraceConn = nil
		end
	end

	RegisterPacket.OnClientEvent:Connect(function(character, meterType, gParam)
		if not (Toggles.AutoGreen and Toggles.AutoGreen.Value) then return end

		local char = getCharacterModel()
		if not char or character ~= char then return end
		if not rollChance() then return end

		cleanupUITrace()
		uiTraceActive = true

		local meterGui = findMeterGui(char, meterType)
		if not meterGui then
			task.wait(0.15)
			meterGui = findMeterGui(char, meterType)
		end
		if not meterGui then
			cleanupUITrace()
			return
		end

		uiTraceConn = RunService.Heartbeat:Connect(function()
			if not uiTraceActive then return end
			if not meterGui or not meterGui.Parent then
				cleanupUITrace()
				return
			end

			local greenStart = getGreenZoneStart(meterGui)
			if not greenStart then return end

			local fill = getFillProgress(meterGui)
			local userOffset = Options.GreenOffset and Options.GreenOffset.Value or 0
			local target = greenStart + (userOffset / 1000)

			if fill >= target then
				cleanupUITrace()
				ShootRemote:FireServer({Shoot = false})
			end
		end)

		task.delay(4, function()
			if uiTraceActive then cleanupUITrace() end
		end)
	end)

	UnregisterPacket.OnClientEvent:Connect(function(character)
		local char = getCharacterModel()
		if char and character == char then cleanupUITrace() end
	end)

	-- TIMED RELEASE
	local timedReleaseActive = false

	RegisterPacket.OnClientEvent:Connect(function(character, meterType, gParam)
		if not (Toggles.TimedRelease and Toggles.TimedRelease.Value) then return end
		if Toggles.AutoGreen and Toggles.AutoGreen.Value then return end

		local char = getCharacterModel()
		if not char or character ~= char then return end
		if timedReleaseActive then return end
		if not rollChance() then return end

		timedReleaseActive = true

		local action = char:GetAttribute("Action") or ""
		local isDunk = (action == "Dunking")
		local isMoving = isPlayerMoving()

		local delay
		if isDunk then
			delay = Options.DunkDelay and Options.DunkDelay.Value or 0.4
		elseif isMoving then
			delay = Options.FadeDelay and Options.FadeDelay.Value or 0.45
		else
			delay = Options.ShootDelay and Options.ShootDelay.Value or 0.5
		end

		task.delay(delay, function()
			timedReleaseActive = false
			ShootRemote:FireServer({Shoot = false})
		end)
	end)

	return {
		cleanupUITrace = cleanupUITrace,
	}
end
