-- ServerScriptService/ClearPlayerData.server.lua
-- DEVELOPMENT UTILITY: Clears player data on server startup
-- Remove this script in production

-- ServerScriptService/ClearPlayerData.server.lua
-- DEVELOPMENT UTILITY: Clears player data on server startup
-- This script is intentionally guarded by a flag to avoid accidental data loss during tests.

local ENABLE_CLEAR_ON_START = false -- set to true to enable clearing (developer must explicitly flip)

local function clearPlayerData(userId)
	local id = tonumber(userId) or 198769741 -- default: Marietto_Crg's ID (override by passing userId)

	local datastores = {
		"PlayerRewards_V1",
		"CharacterStats_V1",
		"PlayerGuilds_V1",
		"PlayerEquipment_V1",
		"Leaderboard_Level_V1",
		"Leaderboard_Kills_V1",
		"Leaderboard_Coins_V1",
		"Leaderboard_ArenaWins_V1",
		"Leaderboard_BossesDefeated_V1"
	}

	for _, dsName in ipairs(datastores) do
		local ds = game:GetService("DataStoreService"):GetDataStore(dsName)
		pcall(function()
			ds:RemoveAsync(id)
			print("[ClearPlayerData] Cleared", dsName, "for userId", id)
		end)
	end

	print("[ClearPlayerData] Data reset complete for userId", id)
end

-- Clear on server startup only if the developer explicitly opts in
if ENABLE_CLEAR_ON_START then
	wait(1)
	clearPlayerData(198769741)
else
	print("[ClearPlayerData] Disabled on startup. Set ENABLE_CLEAR_ON_START = true to enable.")
end
