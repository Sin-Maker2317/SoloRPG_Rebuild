-- Shared/Skills.lua
local Skills = {}

Skills.Definitions = {
	["QuickSlash"] = {
		id = "QuickSlash",
		name = "Quick Slash",
		cooldown = 3,
		staminaCost = 25,
		damage = 40,
		type = "active"
	},
	["HeavyStrike"] = {
		id = "HeavyStrike",
		name = "Heavy Strike",
		cooldown = 6,
		staminaCost = 40,
		damage = 80,
		type = "active"
	},
	["ShadowStep"] = {
		id = "ShadowStep",
		name = "Shadow Step",
		cooldown = 8,
		staminaCost = 30,
		damage = 0,
		type = "active"
	}
}

return Skills
