-- ServerScriptService/Services/MobService.lua
local EnemyService = require(script.Parent:WaitForChild("EnemyService"))

local MobService = {}
MobService.__index = MobService

MobService.Mobs = {
	Grunt = { name = "Grunt", maxHealth = 70, size = Vector3.new(2, 2, 1), isElite = false },
	Brute = { name = "Brute", maxHealth = 140, size = Vector3.new(3, 3, 2), isElite = false },
	Runner = { name = "Runner", maxHealth = 90, size = Vector3.new(2, 2, 1), isElite = false },
	Grunt_Elite = { name = "Grunt Elite", maxHealth = 140, size = Vector3.new(2, 2, 1), isElite = true },
	Brute_Elite = { name = "Brute Elite", maxHealth = 280, size = Vector3.new(3, 3, 2), isElite = true },
	Runner_Elite = { name = "Runner Elite", maxHealth = 180, size = Vector3.new(2, 2, 1), isElite = true },
}

function MobService:RandomMobKey()
	local keys = { "Grunt", "Brute", "Runner" }
	return keys[math.random(1, #keys)]
end

function MobService:SpawnRandom(position, onDied, eliteChance)
	local key = self:RandomMobKey()
	
	-- 20% chance to spawn elite variant if not specified
	if eliteChance == nil then eliteChance = 0.20 end
	if math.random() < eliteChance then
		key = key .. "_Elite"
	end
	
	local cfg = self.Mobs[key] or self.Mobs.Grunt
	return EnemyService:SpawnEnemy(cfg, position, function(model)
		if onDied then onDied(key, cfg, model) end
	end)
end

return MobService
