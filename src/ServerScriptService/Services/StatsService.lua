-- ServerScriptService/Services/StatsService.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local RewardService = require(script.Parent:WaitForChild("RewardService"))
local ProgressService = require(script.Parent:WaitForChild("ProgressService"))
local DebugService = require(script.Parent:WaitForChild("DebugService"))

local StatsService = {}
StatsService.__index = StatsService

local statsCache = {} -- [player] = { level, xp, statPoints, str, agi, vit, int }

function StatsService:GetXPForLevel(level)
	return level * Constants.XP_BASE_PER_LEVEL
end

function StatsService:Get(player)
	if not statsCache[player] then
		local prog = ProgressService:Get(player)
		local reward = RewardService:Get(player)
		
		local level = 1
		local xp = reward.xp or 0
		
		-- Calculate level from XP
		while level < Constants.MAX_LEVEL and xp >= self:GetXPForLevel(level) do
			xp = xp - self:GetXPForLevel(level)
			level = level + 1
		end
		
		statsCache[player] = {
			level = level,
			xp = xp,
			statPoints = 0,
			str = 10,
			agi = 10,
			vit = 10,
			int = 10
		}
	end
	return statsCache[player]
end

function StatsService:CheckLevelUp(player)
	local stats = self:Get(player)
	local xpNeeded = self:GetXPForLevel(stats.level)
	
	while stats.xp >= xpNeeded and stats.level < Constants.MAX_LEVEL do
		stats.xp = stats.xp - xpNeeded
		stats.level = stats.level + 1
		stats.statPoints = stats.statPoints + Constants.BASE_STAT_POINTS_PER_LEVEL
		xpNeeded = self:GetXPForLevel(stats.level)
		
		local remotes = ReplicatedStorage:WaitForChild("Remotes")
		local gateMessage = remotes:WaitForChild("GateMessage")
		gateMessage:FireClient(player, ("LEVEL UP! Now Level %d. +%d Stat Points."):format(stats.level, Constants.BASE_STAT_POINTS_PER_LEVEL))
	end
end

function StatsService:AllocateStatPoint(player, statName)
	local stats = self:Get(player)
	if stats.statPoints <= 0 then
		return false, "No stat points available"
	end
	
	if statName == "str" then
		stats.str = stats.str + 1
	elseif statName == "agi" then
		stats.agi = stats.agi + 1
	elseif statName == "vit" then
		stats.vit = stats.vit + 1
	elseif statName == "int" then
		stats.int = stats.int + 1
	else
		return false, "Invalid stat name"
	end
	
	stats.statPoints = stats.statPoints - 1
	return true, "Stat allocated"
end

function StatsService:Snapshot(player)
	local stats = self:Get(player)
	local xpNeeded = self:GetXPForLevel(stats.level)
	return {
		level = stats.level,
		xp = stats.xp,
		xpToNext = xpNeeded,
		statPoints = stats.statPoints,
		str = stats.str,
		agi = stats.agi,
		vit = stats.vit,
		int = stats.int
	}
end

function StatsService:Clear(player)
	statsCache[player] = nil
end

-- Hook into RewardService XP gain
local originalAdd = RewardService.Add
RewardService.Add = function(self, player, xp, coins)
	local result = originalAdd(self, player, xp, coins)
	StatsService:CheckLevelUp(player)
	return result
end

return StatsService
