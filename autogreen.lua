-- VisionHub v5 AutoGreen Module | DO NOT OBFUSCATE
-- Loaded at runtime by the main script

return function(deps)
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local LocalPlayer = Players.LocalPlayer

	local Toggles = deps.Toggles
	local Options = deps.Options
	local RegisterPacket = deps.RegisterPacket
	local ShootRemote = deps.ShootRemote

	local function getCharacterModel()
		local chars = workspace:FindFirstChild("Characters")
		if not chars then return nil end
		return chars:FindFirstChild(LocalPlayer.Name)
	end

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

	local function rollChance()
		local chanceStr = Options.GreenChance and Options.GreenChance.Value or "100%"
		local cleaned = chanceStr:gsub("%%", "")
		local chance = tonumber(cleaned) or 100
		return math.random(1, 100) <= chance
	end

	local timedReleaseActive = false

	RegisterPacket.OnClientEvent:Connect(function(character, meterType, gParam)
		if not (Toggles.TimedRelease and Toggles.TimedRelease.Value) then return end

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

	return {}
end
