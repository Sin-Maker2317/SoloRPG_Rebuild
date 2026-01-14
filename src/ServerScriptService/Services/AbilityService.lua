-- ServerScriptService/Services/AbilityService.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local DebugService = require(script.Parent:WaitForChild("DebugService"))
local CombatService = require(script.Parent:WaitForChild("CombatService"))

local AbilityService = {}
AbilityService.__index = AbilityService

-- Boss ability definitions
AbilityService.Abilities = {
	-- Veil Shadow abilities
	DarkBlast = {
		name = "Dark Blast",
		cooldown = 5,
		range = 60,
		damage = 50,
		execute = function(boss, targetPlayers)
			DebugService:Log("[DarkBlast] Veil Shadow casts Dark Blast on", #targetPlayers, "players")
			for _, player in ipairs(targetPlayers) do
				local char = player.Character
				if char then
					local humanoid = char:FindFirstChildOfClass("Humanoid")
					if humanoid then
						humanoid:TakeDamage(50)
					end
				end
			end
		end
	},
	
	DarkShell = {
		name = "Dark Shell",
		cooldown = 10,
		duration = 3,
		execute = function(boss)
			DebugService:Log("[DarkShell] Veil Shadow gains damage reduction")
			-- 30% damage reduction for 3 seconds
		end
	},
	
	-- Katana Lord abilities
	SlashCombo = {
		name = "Slash Combo",
		cooldown = 4,
		range = 40,
		damage = 60,
		hits = 3,
		execute = function(boss, targetPlayers)
			DebugService:Log("[SlashCombo] Katana Lord attacks with 3-hit combo")
			for _, player in ipairs(targetPlayers) do
				local char = player.Character
				if char then
					local humanoid = char:FindFirstChildOfClass("Humanoid")
					if humanoid then
						humanoid:TakeDamage(60)
					end
				end
			end
		end
	},
	
	BladeDance = {
		name = "Blade Dance",
		cooldown = 6,
		range = 50,
		damage = 40,
		execute = function(boss, targetPlayers)
			DebugService:Log("[BladeDance] Katana Lord dances around, hitting all nearby")
			for _, player in ipairs(targetPlayers) do
				local char = player.Character
				if char then
					local humanoid = char:FindFirstChildOfClass("Humanoid")
					if humanoid then
						humanoid:TakeDamage(40)
					end
				end
			end
		end
	},
	
	-- Stone Golem abilities
	GroundSlam = {
		name = "Ground Slam",
		cooldown = 7,
		range = 80,
		damage = 80,
		stun = 1.5,
		execute = function(boss, targetPlayers)
			DebugService:Log("[GroundSlam] Stone Golem slams ground, stunning all nearby")
			for _, player in ipairs(targetPlayers) do
				local char = player.Character
				if char then
					local humanoid = char:FindFirstChildOfClass("Humanoid")
					if humanoid then
						humanoid:TakeDamage(80)
					end
				end
			end
		end
	},
	
	RockArmor = {
		name = "Rock Armor",
		cooldown = 12,
		duration = 4,
		damageReduction = 0.5,
		execute = function(boss)
			DebugService:Log("[RockArmor] Stone Golem hardens, reducing damage")
			-- 50% damage reduction for 4 seconds
		end
	},
	
	Regenerate = {
		name = "Regenerate",
		cooldown = 8,
		healAmount = 100,
		execute = function(boss)
			DebugService:Log("[Regenerate] Stone Golem regenerates 100 HP")
			local humanoid = boss:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.Health = math.min(humanoid.Health + 100, humanoid.MaxHealth)
			end
		end
	},
	
	-- Summon (Veil Shadow)
	Summon = {
		name = "Shadow Summon",
		cooldown = 15,
		minionCount = 3,
		execute = function(boss, targetPlayers)
			DebugService:Log("[Summon] Veil Shadow summons 3 shadow minions")
			-- Spawn 3 minion enemies near the boss
		end
	},
	
	-- Last Stand (Katana Lord)
	LastStand = {
		name = "Last Stand",
		cooldown = 20,
		duration = 5,
		damageReduction = 0.7,
		counter = true,
		execute = function(boss)
			DebugService:Log("[LastStand] Katana Lord enters defensive stance, countering all attacks")
			-- 70% damage reduction + reflect 30% damage to attacker
		end
	}
}

function AbilityService:GetAbility(abilityName)
	return self.Abilities[abilityName]
end

function AbilityService:ExecuteAbility(abilityName, boss, targetPlayers)
	local ability = self:GetAbility(abilityName)
	if not ability then return false end
	
	if ability.execute then
		ability.execute(boss, targetPlayers)
	end
	
	return true
end

function AbilityService:GetNearbyPlayers(bossPosition, range)
	local nearbyPlayers = {}
	
	for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
		if player.Character then
			local char = player.Character
			local rootPart = char:FindFirstChild("HumanoidRootPart")
			if rootPart then
				local distance = (rootPart.Position - bossPosition).Magnitude
				if distance <= range then
					table.insert(nearbyPlayers, player)
				end
			end
		end
	end
	
	return nearbyPlayers
end

return AbilityService
