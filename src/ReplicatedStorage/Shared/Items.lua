-- Shared/Items.lua
local Items = {}

Items.Definitions = {
	["Sword_Basic"] = {
		id = "Sword_Basic",
		name = "Basic Sword",
		type = "weapon",
		rarity = "common",
		stats = { damage = 10 }
	},
	["Armor_Basic"] = {
		id = "Armor_Basic",
		name = "Basic Armor",
		type = "armor",
		rarity = "common",
		stats = { defense = 5 }
	}
}

return Items
