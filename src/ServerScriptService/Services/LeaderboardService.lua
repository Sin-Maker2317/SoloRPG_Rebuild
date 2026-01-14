-- ServerScriptService/Services/LeaderboardService.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DebugService = require(script.Parent:WaitForChild("DebugService"))

local LeaderboardService = {}
LeaderboardService.__index = LeaderboardService

-- Leaderboard types
LeaderboardService.Types = {
	LEVEL = "Level",
	KILLS = "Kills",
	COINS = "Coins",
	ARENA_WINS = "ArenaWins",
	BOSSES_DEFEATED = "BossesDefeated"
}

local leaderboardData = {} -- [leaderboardType] = { [userId] = score }

function LeaderboardService:UpdateScore(leaderboardType, userId, score)
	leaderboardData[leaderboardType] = leaderboardData[leaderboardType] or {}
	leaderboardData[leaderboardType][userId] = score
	
	-- Save to DataStore
	local ds = game:GetService("DataStoreService"):GetDataStore("Leaderboard_" .. leaderboardType .. "_V1")
	local success, err = pcall(function()
		ds:SetAsync(userId, score)
	end)
	
	if not success then
		DebugService:Log("[LeaderboardService] Error updating leaderboard:", err)
	end
	
	return true
end

function LeaderboardService:IncrementScore(leaderboardType, userId, increment)
	leaderboardData[leaderboardType] = leaderboardData[leaderboardType] or {}
	leaderboardData[leaderboardType][userId] = (leaderboardData[leaderboardType][userId] or 0) + increment
	
	self:UpdateScore(leaderboardType, userId, leaderboardData[leaderboardType][userId])
end

function LeaderboardService:GetTopPlayers(leaderboardType, limit)
	limit = limit or 10
	
	local scoreList = {}
	if leaderboardData[leaderboardType] then
		for userId, score in pairs(leaderboardData[leaderboardType]) do
			table.insert(scoreList, { userId = userId, score = score })
		end
	end
	
	-- Sort by score descending
	table.sort(scoreList, function(a, b)
		return a.score > b.score
	end)
	
	-- Return top N
	local top = {}
	for i = 1, math.min(limit, #scoreList) do
		table.insert(top, scoreList[i])
	end
	
	return top
end

function LeaderboardService:GetPlayerRank(leaderboardType, userId)
	local topPlayers = self:GetTopPlayers(leaderboardType, 1000)
	
	for rank, entry in ipairs(topPlayers) do
		if entry.userId == userId then
			return rank
		end
	end
	
	return nil
end

function LeaderboardService:LoadLeaderboards()
	for _, lbType in pairs(self.Types) do
		local ds = game:GetService("DataStoreService"):GetDataStore("Leaderboard_" .. lbType .. "_V1")
		
		-- Try to get all keys (limited approach)
		leaderboardData[lbType] = leaderboardData[lbType] or {}
		DebugService:Log("[LeaderboardService] Loaded leaderboard:", lbType)
	end
end

function LeaderboardService:Clear()
	leaderboardData = {}
end

return LeaderboardService
