-- ServerScriptService/Services/EquipmentService.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DebugService = require(script.Parent:WaitForChild("DebugService"))

local EquipmentService = {}
EquipmentService.__index = EquipmentService

-- Equipment definitions (stats bonuses)
EquipmentService.Items = {
	-- Armor pieces
	IronHelmet = { id = "IronHelmet", name = "Iron Helmet", slot = "Head", defBonus = 2, vit = 1 },
	IronChest = { id = "IronChest", name = "Iron Chest", slot = "Chest", defBonus = 4, vit = 3 },
	IronLegs = { id = "IronLegs", name = "Iron Legs", slot = "Legs", defBonus = 3, vit = 2 },
	
	-- Weapons
	Sword = { id = "Sword", name = "Iron Sword", slot = "Weapon", str = 3, damage = 10 },
	Dagger = { id = "Dagger", name = "Steel Dagger", slot = "Weapon", str = 2, agi = 2, damage = 8 },
	
	-- Rare equipment
	EliteArmor = { id = "EliteArmor", name = "Elite Armor", slot = "Chest", defBonus = 8, vit = 6, str = 2 },
	LegendaryBlade = { id = "LegendaryBlade", name = "Legendary Blade", slot = "Weapon", str = 8, damage = 25 }
}

local playerEquipment = {} -- [player.UserId] = { [slot] = itemId }

function EquipmentService:Equip(player, itemId)
	local item = self.Items[itemId]
	if not item then
		return false, "Item not found"
	end
	
	playerEquipment[player.UserId] = playerEquipment[player.UserId] or {}
	playerEquipment[player.UserId][item.slot] = itemId
	
	DebugService:Log("[EquipmentService]", player.Name, "equipped", item.name)
	
	-- Save to DataStore
	local ds = game:GetService("DataStoreService"):GetDataStore("PlayerEquipment_V1")
	local success, err = pcall(function()
		ds:SetAsync(player.UserId, playerEquipment[player.UserId])
	end)
	
	if not success then
		DebugService:Log("[EquipmentService] Error saving equipment:", err)
	end
	
	return true, item
end

function EquipmentService:GetEquipped(player)
	return playerEquipment[player.UserId] or {}
end

function EquipmentService:GetItemStats(itemId)
	local item = self.Items[itemId]
	if not item then return {} end
	
	return {
		str = item.str or 0,
		agi = item.agi or 0,
		vit = item.vit or 0,
		defBonus = item.defBonus or 0,
		damage = item.damage or 0
	}
end

function EquipmentService:CalculateTotalBonuses(player)
	local equipped = self:GetEquipped(player)
	local total = { str = 0, agi = 0, vit = 0, defBonus = 0, damage = 0 }
	
	for slot, itemId in pairs(equipped) do
		local stats = self:GetItemStats(itemId)
		for key, val in pairs(stats) do
			total[key] = total[key] + val
		end
	end
	
	return total
end

function EquipmentService:LoadEquipment(player)
	local ds = game:GetService("DataStoreService"):GetDataStore("PlayerEquipment_V1")
	local success, equipment = pcall(function()
		return ds:GetAsync(player.UserId)
	end)
	
	if success and equipment then
		playerEquipment[player.UserId] = equipment
		return equipment
	end
	
	-- New player starts with default weapon
	playerEquipment[player.UserId] = { Weapon = "Sword" }
	return playerEquipment[player.UserId]
end

function EquipmentService:Clear(player)
	playerEquipment[player.UserId] = nil
end

return EquipmentService
