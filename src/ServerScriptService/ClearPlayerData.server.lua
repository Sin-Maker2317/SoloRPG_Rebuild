-- ServerScriptService/ClearPlayerData.server.lua
-- DEVELOPMENT UTILITY: Clears player data on server startup
-- Remove this script in production

local function clearPlayerData(userId)
	local userId = 198769741 -- Marietto_Crg's ID
	
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
			ds:RemoveAsync(userId)
			print("[ClearPlayerData] Cleared", dsName, "for userId", userId)
		end)
	end
	
	print("[ClearPlayerData] Data reset complete for Marietto_Crg")
end

-- Clear on server startup
wait(1)
clearPlayerData(198769741)
