-- ServerScriptService/Services/GuardService.lua
-- Server-side guard state and damage reduction management

local GuardService = {}
GuardService.__index = GuardService

local guardStates = {} -- [player] = { isGuarding, startTime, staminaDrainRate }
local GUARD_DAMAGE_REDUCTION = 0.5 -- 50% reduction
local GUARD_STAMINA_DRAIN_PER_SEC = 5 -- stamina points per second while guarding

function GuardService:StartGuard(player)
	if not player or not player.Parent then return false end
	
	guardStates[player] = {
		isGuarding = true,
		startTime = tick(),
		staminaDrainRate = GUARD_STAMINA_DRAIN_PER_SEC
	}
	
	return true
end

function GuardService:StopGuard(player)
	if not player or not player.Parent then return end
	guardStates[player] = nil
end

function GuardService:IsGuarding(player)
	if not player or not player.Parent then return false end
	
	local state = guardStates[player]
	return state and state.isGuarding == true
end

function GuardService:CalculateDamageReduction(player, baseDamage)
	if self:IsGuarding(player) then
		return baseDamage * (1 - GUARD_DAMAGE_REDUCTION), true -- (reducedDamage, wasGuarded)
	end
	return baseDamage, false
end

function GuardService:GetGuardDrainRate()
	return GUARD_STAMINA_DRAIN_PER_SEC
end

function GuardService:GetDamageReductionPercent()
	return GUARD_DAMAGE_REDUCTION * 100
end

function GuardService:Clear(player)
	guardStates[player] = nil
end

return GuardService
