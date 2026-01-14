-- ServerScriptService/Services/CombatService.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatResolveService = require(script.Parent:WaitForChild("CombatResolveService"))
local DebugService = require(script.Parent:WaitForChild("DebugService"))
local CharacterStats = require(script.Parent:WaitForChild("CharacterStats"))
local DodgeService = require(script.Parent:WaitForChild("DodgeService"))
local GuardService = require(script.Parent:WaitForChild("GuardService"))
local StunService = require(script.Parent:WaitForChild("StunService"))

local CombatService = {}
CombatService.__index = CombatService

CombatService.BASE_DAMAGE = 25

-- Calculate damage with level scaling
function CombatService:CalculatePlayerDamage(playerStats, baseDamage)
	baseDamage = baseDamage or self.BASE_DAMAGE
	local level = playerStats.level or 1
	
	-- Damage = base * (1 + level/10) for level scaling
	local scaledDamage = baseDamage * (1 + (level - 1) / 10)
	
	return math.floor(scaledDamage)
end

function CombatService:DealDamage(targetHumanoid: Humanoid, dealerPlayer)
	if not targetHumanoid or targetHumanoid.Health <= 0 then
		return false
	end

	-- Check if target is in dodge window
	if dealerPlayer and DodgeService:IsInDodgeWindow(dealerPlayer) then
		return false -- Dodge avoided attack
	end

	local damage = self.BASE_DAMAGE
	if dealerPlayer then
		local stats = CharacterStats:GetSnapshot(dealerPlayer)
		damage = self:CalculatePlayerDamage(stats, self.BASE_DAMAGE)
	end

	targetHumanoid:TakeDamage(damage)
	return true
end

function CombatService:PlayerSkillAttack(playerModel, targetEnemy, skillDef)
	if not targetEnemy or not skillDef then return end
	
	local targetHumanoid = targetEnemy:FindFirstChildOfClass("Humanoid")
	if not targetHumanoid or targetHumanoid.Health <= 0 then return end
	
	local playerStats = CharacterStats:GetSnapshot(playerModel.Parent or playerModel)
	
	-- Calculate skill damage with level scaling
	local damage = self:CalculatePlayerDamage(playerStats, skillDef.damage or 0)
	
	-- Apply Guard Break stun mechanic
	if skillDef.id == "GuardBreak" then
		if GuardService:IsGuarding(targetEnemy) then
			StunService:Stun(targetHumanoid, 1.0)
			GuardService:StopGuard(targetEnemy)
			damage = damage * 1.5 -- 50% bonus vs guarding enemy
		end
	end
	
	targetHumanoid:TakeDamage(damage)
	
	return true
end

function CombatService:EnemyAttack(enemyModel, targetPlayer, isElite)
	local character = targetPlayer.Character
	if not character then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end
	
	-- Check dodge window
	if DodgeService:IsInDodgeWindow(targetPlayer) then
		DebugService:Log("[CombatService]", targetPlayer.Name, "dodged enemy attack")
		return
	end
	
	local damage = 15
	if isElite then
		damage = 25
	end
	
	-- Check guard reduction
	local reducedDamage, wasGuarded = GuardService:CalculateDamageReduction(targetPlayer, damage)
	if wasGuarded then
		damage = reducedDamage
		DebugService:Log("[CombatService] Attack blocked by guard, reduced to", damage)
	end
	
	-- Apply defense scaling
	local defense = CombatResolveService:CalculatePlayerDefense(targetPlayer)
	damage = math.max(1, damage - defense * 0.5)
	
	humanoid:TakeDamage(damage)
	
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local combatEvent = remotes:WaitForChild("CombatEvent")
	combatEvent:FireClient(targetPlayer, { type = "HitConfirm", damage = damage })
	
	DebugService:Log("[CombatService] Enemy attack:", damage, "damage to", targetPlayer.Name)
end

return CombatService
