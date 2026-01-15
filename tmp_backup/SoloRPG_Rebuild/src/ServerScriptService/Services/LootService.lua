-- ServerScriptService/Services/LootService.lua
local RewardService = require(script.Parent:WaitForChild("RewardService"))
local InventoryService = require(script.Parent:WaitForChild("InventoryService"))

local LootService = {}
LootService.__index = LootService

local function rollItem(mobKey)
	-- placeholder item tokens
	local roll = math.random()
	if roll < 0.10 then
		return "Item_" .. mobKey .. "_RareShard"
	elseif roll < 0.35 then
		return "Item_" .. mobKey .. "_Shard"
	end
	return nil
end

function LootService:AwardKill(player, mobKey)
	-- simple tuning
	local xp, coins = 10, 15
	if mobKey == "Grunt" then xp, coins = 10, 15 end
	if mobKey == "Runner" then xp, coins = 12, 18 end
	if mobKey == "Brute" then xp, coins = 20, 35 end

	local r = RewardService:Add(player, xp, coins)

	local item = rollItem(mobKey)
	if item then
		InventoryService:AddItem(player, item)
	end

	return r, item, xp, coins
end

return LootService
