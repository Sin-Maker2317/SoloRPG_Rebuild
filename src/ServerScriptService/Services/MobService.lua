-- ServerScriptService/Services/MobService.lua
local EnemyService = require(script.Parent:WaitForChild("EnemyService"))

local MobService = {}
MobService.__index = MobService

MobService.Mobs = {
	Grunt = { name = "Grunt", maxHealth = 70, size = Vector3.new(2, 2, 1) },
	Brute = { name = "Brute", maxHealth = 140, size = Vector3.new(3, 3, 2) },
	Runner = { name = "Runner", maxHealth = 90, size = Vector3.new(2, 2, 1) },
}

function MobService:RandomMobKey()
	local keys = { "Grunt", "Brute", "Runner" }
	return keys[math.random(1, #keys)]
end

function MobService:SpawnRandom(position, onDied)
	local key = self:RandomMobKey()
	local cfg = self.Mobs[key]
	return EnemyService:SpawnEnemy(cfg, position, function(model)
		if onDied then onDied(key, cfg, model) end
	end)
end

function MobService:SpawnByKey(key, position, onDied)
	local cfg = self.Mobs[key] or self.Mobs.Grunt
	return EnemyService:SpawnEnemy(cfg, position, function(model)
		if onDied then onDied(key, cfg, model) end
	end)
end

return MobService
