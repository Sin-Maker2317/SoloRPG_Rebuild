-- ServerScriptService/Services/ArenaService.lua
local DebugService = require(script.Parent:WaitForChild("DebugService"))

local ArenaService = {}
ArenaService.__index = ArenaService

-- Arena configurations
ArenaService.Arenas = {
	Arena1v1 = {
		id = "Arena1v1",
		name = "1v1 Arena",
		maxPlayers = 2,
		minLevel = 5,
		position = Vector3.new(0, 20, 0),
		size = 80
	},
	ArenaBattle = {
		id = "ArenaBattle",
		name = "Battle Royale",
		maxPlayers = 8,
		minLevel = 15,
		position = Vector3.new(100, 20, 0),
		size = 150
	},
	ArenaTeam = {
		id = "ArenaTeam",
		name = "Team Battle",
		maxPlayers = 6,
		minLevel = 10,
		teamSize = 3,
		position = Vector3.new(200, 20, 0),
		size = 120
	}
}

local activeMatches = {} -- [matchId] = { arena, players, startTime, winner }

function ArenaService:CreateMatch(arenaId, initiatorPlayer, opponents)
	local arenaDef = self.Arenas[arenaId]
	if not arenaDef then
		return false, "Arena not found"
	end
	
	local allPlayers = { initiatorPlayer }
	for _, opponent in ipairs(opponents) do
		table.insert(allPlayers, opponent)
	end
	
	if #allPlayers > arenaDef.maxPlayers then
		return false, "Too many players for this arena"
	end
	
	local matchId = arenaDef.id .. "_" .. tick()
	activeMatches[matchId] = {
		arena = arenaDef,
		players = allPlayers,
		startTime = tick(),
		status = "active",
		winner = nil
	}
	
	DebugService:Log("[ArenaService] Match created:", matchId, "in", arenaDef.name)
	return true, { matchId = matchId, arena = arenaDef }
end

function ArenaService:EndMatch(matchId, winner)
	local match = activeMatches[matchId]
	if not match then return false end
	
	match.status = "finished"
	match.winner = winner
	
	DebugService:Log("[ArenaService] Match ended:", matchId, "Winner:", winner.Name)
	
	-- Award rewards
	local baseReward = 100 + (#match.players * 50)
	return true, { reward = baseReward, winner = winner.Name }
end

function ArenaService:GetMatch(matchId)
	return activeMatches[matchId]
end

function ArenaService:IsPlayerInMatch(player)
	for matchId, match in pairs(activeMatches) do
		for _, p in ipairs(match.players) do
			if p == player then
				return true, matchId, match
			end
		end
	end
	return false
end

function ArenaService:GetArenaStats(player)
	local wins = 0
	local losses = 0
	local totalMatches = 0
	
	for matchId, match in pairs(activeMatches) do
		if match.status == "finished" then
			for _, p in ipairs(match.players) do
				if p == player then
					totalMatches = totalMatches + 1
					if match.winner == player then
						wins = wins + 1
					else
						losses = losses + 1
					end
				end
			end
		end
	end
	
	return {
		wins = wins,
		losses = losses,
		total = totalMatches,
		winrate = totalMatches > 0 and (wins / totalMatches) or 0
	}
end

return ArenaService
