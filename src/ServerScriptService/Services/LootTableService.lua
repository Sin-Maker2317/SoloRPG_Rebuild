-- ServerScriptService/Services/LootTableService.lua
local LootTableService = {}
LootTableService.__index = LootTableService

function LootTableService:GetLootForMob(mobKey, gateGrade)
	local xp, coins = 10, 15
	if mobKey == "Grunt" then xp, coins = 10, 15 end
	if mobKey == "Runner" then xp, coins = 12, 18 end
	if mobKey == "Brute" then xp, coins = 20, 35 end
	
	-- Grade scaling
	if gateGrade == "D" then
		xp = math.floor(xp * 1.5)
		coins = math.floor(coins * 1.5)
	end
	
	local item = nil
	if math.random() < 0.2 then
		item = "Item_" .. mobKey .. "_Shard"
	end
	
	return xp, coins, item
end

function LootTableService:GetGateReward(gateGrade, gateType)
	local baseXP = 100
	local baseCoins = 150
	
	if gateGrade == "D" then
		baseXP = 150
		baseCoins = 200
	end
	
	return baseXP, baseCoins
end

return LootTableService
