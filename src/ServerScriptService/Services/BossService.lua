-- ServerScriptService/Services/BossService.lua
local EnemyService = require(script.Parent:WaitForChild("EnemyService"))
local DebugService = require(script.Parent:WaitForChild("DebugService"))

local BossService = {}
BossService.__index = BossService

-- Boss definitions with special mechanics
BossService.Bosses = {
	VeilShadow = {
		id = "VeilShadow",
		name = "Veil Shadow",
		maxHealth = 500,
		size = Vector3.new(4, 4, 2),
		abilities = { "DarkBlast", "Summon", "DarkShell" },
		lootTable = { minXP = 300, maxXP = 500, coins = 250 }
	},
	KatanaLord = {
		id = "KatanaLord",
		name = "Katana Lord",
		maxHealth = 600,
		size = Vector3.new(3, 5, 2),
		abilities = { "SlashCombo", "BladeDance", "LastStand" },
		lootTable = { minXP = 400, maxXP = 600, coins = 300 }
	},
	StoneGolem = {
		id = "StoneGolem",
		name = "Stone Golem",
		maxHealth = 800,
		size = Vector3.new(5, 6, 3),
		abilities = { "GroundSlam", "RockArmor", "Regenerate" },
		lootTable = { minXP = 500, maxXP = 700, coins = 400 }
	}
}

local activeBosses = {} -- [bossModel] = bossDef

function BossService:SpawnBoss(bossId, position, onDied)
	local bossDef = self.Bosses[bossId]
	if not bossDef then
		return nil, "Boss not found"
	end
	
	local bossModel = EnemyService:SpawnEnemy({
		name = bossDef.name,
		maxHealth = bossDef.maxHealth,
		size = bossDef.size
	}, position, function(model)
		activeBosses[model] = nil
		if onDied then onDied(bossId, bossDef, model) end
	end)
	
	activeBosses[bossModel] = bossDef
	DebugService:Log("[BossService] Spawned boss:", bossDef.name)
	
	return bossModel, bossDef
end

function BossService:GetBossDef(bossModel)
	return activeBosses[bossModel]
end

function BossService:IsBoss(model)
	return activeBosses[model] ~= nil
end

function BossService:GetBossAbilities(bossId)
	local bossDef = self.Bosses[bossId]
	return bossDef and bossDef.abilities or {}
end

function BossService:GetBossLoot(bossId)
	local bossDef = self.Bosses[bossId]
	if not bossDef then return { xp = 100, coins = 50 } end
	
	local loot = bossDef.lootTable
	return {
		xp = math.random(loot.minXP, loot.maxXP),
		coins = loot.coins
	}
end

return BossService
