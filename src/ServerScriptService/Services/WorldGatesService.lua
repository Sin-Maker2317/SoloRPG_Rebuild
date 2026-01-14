-- ServerScriptService/Services/WorldGatesService.lua
local BossService = require(script.Parent:WaitForChild("BossService"))
local AbilityService = require(script.Parent:WaitForChild("AbilityService"))
local DebugService = require(script.Parent:WaitForChild("DebugService"))

local WorldGatesService = {}
WorldGatesService.__index = WorldGatesService

-- Gate definitions (dungeon encounters)
WorldGatesService.Gates = {
	Gate1 = {
		id = "Gate1",
		name = "Shadow Lair",
		bossId = "VeilShadow",
		recommended_level = 10,
		reward_xp = 500,
		reward_coins = 250
	},
	Gate2 = {
		id = "Gate2",
		name = "Sword Master's Dojo",
		bossId = "KatanaLord",
		recommended_level = 20,
		reward_xp = 800,
		reward_coins = 400
	},
	Gate3 = {
		id = "Gate3",
		name = "Stone Mountain",
		bossId = "StoneGolem",
		recommended_level = 30,
		reward_xp = 1200,
		reward_coins = 600
	}
}

local activeGates = {} -- [gateId] = { boss, players, startTime }

function WorldGatesService:StartGate(gateId, player)
	local gateDef = self.Gates[gateId]
	if not gateDef then
		return false, "Gate not found"
	end
	
	local bossModel, bossDef = BossService:SpawnBoss(gateDef.bossId, Vector3.new(0, 20, 0), function(bossId, def, model)
		-- Boss died callback
		DebugService:Log("[WorldGatesService]", player.Name, "defeated boss", def.name)
		self:CompleteGate(gateId, player)
	end)
	
	if not bossModel then
		return false, "Failed to spawn boss"
	end
	
	activeGates[gateId] = {
		boss = bossModel,
		players = { player },
		startTime = tick(),
		gateDef = gateDef
	}
	
	DebugService:Log("[WorldGatesService]", player.Name, "started", gateDef.name)
	return true, gateDef
end

function WorldGatesService:CompleteGate(gateId, player)
	local gateData = activeGates[gateId]
	if not gateData then return end
	
	local duration = tick() - gateData.startTime
	local gateDef = gateData.gateDef
	
	DebugService:Log("[WorldGatesService] Gate complete:", gateId, "in", math.floor(duration), "seconds")
	
	-- Clean up boss
	if gateData.boss and gateData.boss.Parent then
		gateData.boss:Destroy()
	end
	
	activeGates[gateId] = nil
end

function WorldGatesService:GetGateStatus(gateId)
	return activeGates[gateId] or nil
end

function WorldGatesService:GetAllGates()
	return self.Gates
end

function WorldGatesService:IsPlayerInGate(player, gateId)
	local gateData = activeGates[gateId]
	if not gateData then return false end
	
	for _, p in ipairs(gateData.players) do
		if p == player then return true end
	end
	return false
end

return WorldGatesService
