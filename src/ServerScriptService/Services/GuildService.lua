-- ServerScriptService/Services/GuildService.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local DebugService = require(script.Parent:WaitForChild("DebugService"))

local GuildService = {}
GuildService.__index = GuildService

-- Guild definitions with faction bonuses
GuildService.Guilds = {
	Hunters = {
		id = "Hunters",
		name = "Hunters Guild",
		description = "General adventurers, balanced progression",
		strBonus = 1.0,
		agiBonus = 1.0,
		vitBonus = 1.0,
		intBonus = 1.0,
		defBonus = 1.0,
		color = Color3.fromRGB(100, 100, 255)
	},
	WhiteTiger = {
		id = "WhiteTiger",
		name = "White Tiger Guild",
		description = "Agile assassins and scouts, speed focused",
		strBonus = 0.9,
		agiBonus = 1.3,
		vitBonus = 0.8,
		intBonus = 1.0,
		defBonus = 0.7,
		color = Color3.fromRGB(200, 200, 255)
	},
	ChoiAssoc = {
		id = "ChoiAssoc",
		name = "Choi Association",
		description = "Tanky fighters with heavy armor",
		strBonus = 1.2,
		agiBonus = 0.8,
		vitBonus = 1.3,
		intBonus = 0.8,
		defBonus = 1.3,
		color = Color3.fromRGB(255, 100, 100)
	}
}

local playerGuilds = {} -- [player.UserId] = guildId

function GuildService:SetGuild(player, guildId)
	if not self.Guilds[guildId] then
		return false, "Invalid guild"
	end
	
	playerGuilds[player.UserId] = guildId
	DebugService:Log("[GuildService]", player.Name, "joined", self.Guilds[guildId].name)
	
	-- Save to DataStore
	local ds = game:GetService("DataStoreService"):GetDataStore("PlayerGuilds_V1")
	local success, err = pcall(function()
		ds:SetAsync(player.UserId, guildId)
	end)
	
	if not success then
		DebugService:Log("[GuildService] Error saving guild:", err)
	end
	
	return true, self.Guilds[guildId]
end

function GuildService:GetGuild(player)
	return playerGuilds[player.UserId] or "Hunters" -- Default to Hunters
end

function GuildService:LoadGuild(player)
	local ds = game:GetService("DataStoreService"):GetDataStore("PlayerGuilds_V1")
	local success, guildId = pcall(function()
		return ds:GetAsync(player.UserId)
	end)
	
	if success and guildId then
		playerGuilds[player.UserId] = guildId
		return guildId
	end
	
	-- New player defaults to Hunters
	playerGuilds[player.UserId] = "Hunters"
	return "Hunters"
end

function GuildService:GetGuildDef(guildId)
	return self.Guilds[guildId] or self.Guilds.Hunters
end

function GuildService:ApplyGuildBonuses(baseStats, guildId)
	local guild = self:GetGuildDef(guildId)
	
	return {
		str = baseStats.str * guild.strBonus,
		agi = baseStats.agi * guild.agiBonus,
		vit = baseStats.vit * guild.vitBonus,
		int = baseStats.int * guild.intBonus,
		def = baseStats.def * guild.defBonus
	}
end

function GuildService:Clear(player)
	playerGuilds[player.UserId] = nil
end

return GuildService
