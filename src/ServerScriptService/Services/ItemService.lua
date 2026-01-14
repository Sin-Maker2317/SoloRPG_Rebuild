-- ServerScriptService/Services/ItemService.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Items"))
local InventoryService = require(script.Parent:WaitForChild("InventoryService"))
local DebugService = require(script.Parent:WaitForChild("DebugService"))

local ItemService = {}
ItemService.__index = ItemService

local equipped = {} -- [player] = { weapon = itemId, armor = itemId }

function ItemService:GiveItem(player, itemId)
	InventoryService:AddItem(player, itemId)
end

function ItemService:EquipItem(player, itemId)
	local itemDef = Items.Definitions[itemId]
	if not itemDef then
		return false, "Invalid item"
	end
	
	equipped[player] = equipped[player] or {}
	
	if itemDef.type == "weapon" then
		equipped[player].weapon = itemId
	elseif itemDef.type == "armor" then
		equipped[player].armor = itemId
	end
	
	DebugService:Log("[ItemService]", player.Name, "equipped", itemId)
	return true
end

function ItemService:GetEquipment(player)
	equipped[player] = equipped[player] or {}
	return equipped[player]
end

function ItemService:Snapshot(player)
	local eq = self:GetEquipment(player)
	return {
		weapon = eq.weapon,
		armor = eq.armor,
		inventory = InventoryService:List(player)
	}
end

function ItemService:Clear(player)
	equipped[player] = nil
end

return ItemService
