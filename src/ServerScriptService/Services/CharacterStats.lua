-- ServerScriptService/Services/CharacterStats.lua
-- Unified character statistics service
-- Consolidates level, XP, stat points, defense, and other character progression

local DataStoreService = game:GetService("DataStoreService")
local store = DataStoreService:GetDataStore("CharacterStats_V1")

local CharacterStats = {}
CharacterStats.__index = CharacterStats

local cache = {} -- [player] = { level, xp, xpNeeded, statPoints, str, agi, vit, int, def }

-- XP scaling: XP needed for each level
local function getXPForLevel(level)
	return 100 * (level - 1) + 50 * (level - 1) ^ 2
end

function CharacterStats:Load(player)
	if cache[player] then return cache[player] end
	
	local data
	local ok = pcall(function()
		data = store:GetAsync("u_" .. player.UserId)
	end)
	
	if ok and data then
		cache[player] = data
	else
		-- New player
		cache[player] = {
			level = 1,
			xp = 0,
			xpNeeded = getXPForLevel(1),
			statPoints = 0,
			str = 1,
			agi = 1,
			vit = 1,
			int = 1,
			def = 0
		}
	end
	
	return cache[player]
end

function CharacterStats:Get(player)
	return self:Load(player)
end

function CharacterStats:Save(player)
	local stats = cache[player]
	if not stats then return end
	pcall(function()
		store:SetAsync("u_" .. player.UserId, stats)
	end)
end

-- Add XP; auto-level up if threshold reached
function CharacterStats:AddXP(player, amount)
	local stats = self:Get(player)
	stats.xp = stats.xp + amount
	
	while stats.xp >= stats.xpNeeded do
		stats.xp = stats.xp - stats.xpNeeded
		stats.level = stats.level + 1
		stats.statPoints = stats.statPoints + 3 -- Grant 3 points per level
		stats.xpNeeded = getXPForLevel(stats.level)
	end
	
	self:Save(player)
	return stats
end

-- Allocate a stat point
function CharacterStats:AllocatePoint(player, field)
	local stats = self:Get(player)
	if stats.statPoints <= 0 then return false end
	if not (field == "str" or field == "agi" or field == "vit" or field == "int" or field == "def") then
		return false
	end
	
	stats[field] = (stats[field] or 0) + 1
	stats.statPoints = stats.statPoints - 1
	self:Save(player)
	return true
end

-- Get defense calculation
function CharacterStats:GetDefense(player)
	local stats = self:Get(player)
	return (stats.def or 0) + (stats.vit or 1) * 0.1 -- Defense = base def + vit scaling
end

-- Snapshot for client
function CharacterStats:GetSnapshot(player)
	local stats = self:Get(player)
	return {
		level = stats.level,
		xp = stats.xp,
		xpToNext = stats.xpNeeded,
		statPoints = stats.statPoints,
		str = stats.str,
		agi = stats.agi,
		vit = stats.vit,
		int = stats.int,
		def = stats.def
	}
end

function CharacterStats:Clear(player)
	self:Save(player)
	cache[player] = nil
end

return CharacterStats
