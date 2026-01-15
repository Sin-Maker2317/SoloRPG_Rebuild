-- ServerScriptService/Services/QuestService.lua
local QuestService = {}
QuestService.__index = QuestService

-- In-memory quests (good for now)
local q = {} -- [player] = { gateClears=0, kills=0, claimedGate=false, claimedKills=false }

function QuestService:Get(player)
	local p = q[player]
	if not p then
		p = { gateClears = 0, kills = 0, claimedGate = false, claimedKills = false }
		q[player] = p
	end
	return p
end

function QuestService:OnGateCleared(player)
	local p = self:Get(player)
	p.gateClears += 1
end

function QuestService:OnKill(player)
	local p = self:Get(player)
	p.kills += 1
end

function QuestService:Snapshot(player)
	local p = self:Get(player)
	return {
		gateClears = p.gateClears,
		kills = p.kills,
		goalGateClears = 3,
		goalKills = 10,
		claimedGate = p.claimedGate,
		claimedKills = p.claimedKills,
	}
end

function QuestService:TryClaim(player, questId)
	local p = self:Get(player)

	if questId == "ClearGates" then
		if p.claimedGate then return false, "Already claimed." end
		if p.gateClears < 3 then return false, "Not complete." end
		p.claimedGate = true
		return true, "Claimed ClearGates."
	end

	if questId == "KillEnemies" then
		if p.claimedKills then return false, "Already claimed." end
		if p.kills < 10 then return false, "Not complete." end
		p.claimedKills = true
		return true, "Claimed KillEnemies."
	end

	return false, "Unknown quest."
end

function QuestService:Clear(player)
	q[player] = nil
end

return QuestService
