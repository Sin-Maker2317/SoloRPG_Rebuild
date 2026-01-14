-- ServerScriptService/Services/StaminaService.lua
-- Manages stamina per player with recovery ticking

local RunService = game:GetService("RunService")

local StaminaService = {}
StaminaService.__index = StaminaService

local stamina = {} -- [player] = currentStamina
local MAX_STAMINA = 100
local RECOVERY_PER_SECOND = 15 -- stamina points / sec
local RECOVERY_DELAY = 2 -- seconds before recovery starts after use

local recoveryTiming = {} -- [player] = lastUseTime

function StaminaService:Load(player)
	if not stamina[player] then
		stamina[player] = MAX_STAMINA
		recoveryTiming[player] = 0
	end
	return stamina[player]
end

function StaminaService:Get(player)
	return self:Load(player)
end

function StaminaService:Use(player, amount)
	local current = self:Load(player)
	if current < amount then
		return false
	end
	
	stamina[player] = math.max(0, current - amount)
	recoveryTiming[player] = tick()
	return true
end

function StaminaService:GetMax()
	return MAX_STAMINA
end

function StaminaService:Snapshot(player)
	return {
		current = self:Get(player),
		max = MAX_STAMINA,
		recoveryRate = RECOVERY_PER_SECOND
	}
end

function StaminaService:Clear(player)
	stamina[player] = nil
	recoveryTiming[player] = nil
end

-- Auto-recovery ticker
RunService.Heartbeat:Connect(function(deltaTime)
	local now = tick()
	
	for player, currentStamina in pairs(stamina) do
		if not player or not player.Parent then
			-- Player left; clean up
			StaminaService:Clear(player)
		else
			-- Recovery logic
			local lastUse = recoveryTiming[player] or 0
			local timeSinceUse = now - lastUse
			
			if timeSinceUse > RECOVERY_DELAY then
				local recovery = RECOVERY_PER_SECOND * deltaTime
				stamina[player] = math.min(MAX_STAMINA, currentStamina + recovery)
			end
		end
	end
end)

return StaminaService
