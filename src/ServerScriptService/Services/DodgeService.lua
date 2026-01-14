-- ServerScriptService/Services/DodgeService.lua
-- Server-side dodge validation and state management

local DodgeService = {}
DodgeService.__index = DodgeService

local dodgeStates = {} -- [player] = { dodgeEndTime, staminaUsed }
local DODGE_DURATION = 0.3 -- seconds of invulnerability
local DODGE_STAMINA_COST = 20

function DodgeService:CanDodge(player, currentStamina)
	-- Check if player can dodge (has stamina, not already dodging)
	if not player or not player.Parent then return false end
	if currentStamina < DODGE_STAMINA_COST then return false end
	
	local state = dodgeStates[player]
	if state and state.dodgeEndTime and tick() < state.dodgeEndTime then
		return false -- Already in dodge window
	end
	
	return true
end

function DodgeService:StartDodge(player, staminaCallback)
	-- Initiate dodge; return success and new stamina value
	if not self:CanDodge(player, staminaCallback and staminaCallback() or 100) then
		return false, 0
	end
	
	dodgeStates[player] = {
		dodgeEndTime = tick() + DODGE_DURATION
	}
	
	return true, DODGE_STAMINA_COST
end

function DodgeService:IsInDodgeWindow(player)
	-- Check if player is currently invulnerable
	if not player or not player.Parent then return false end
	
	local state = dodgeStates[player]
	if not state or not state.dodgeEndTime then return false end
	
	if tick() < state.dodgeEndTime then
		return true
	else
		dodgeStates[player] = nil
		return false
	end
end

function DodgeService:GetDodgeDuration()
	return DODGE_DURATION
end

function DodgeService:GetDodgeStaminaCost()
	return DODGE_STAMINA_COST
end

function DodgeService:Clear(player)
	dodgeStates[player] = nil
end

return DodgeService
