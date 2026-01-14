-- Shared/Skills.lua
local Skills = {}

Skills.Definitions = {
	["QuickSlash"] = {
		id = "QuickSlash",
		name = "Quick Slash",
		cooldown = 3,
		staminaCost = 25,
		damage = 40,
		type = "active",
		description = "Fast melee attack"
	},
	["HeavyStrike"] = {
		id = "HeavyStrike",
		name = "Heavy Strike",
		cooldown = 6,
		staminaCost = 40,
		damage = 80,
		type = "active",
		description = "Powerful slow attack"
	},
	["ShadowStep"] = {
		id = "ShadowStep",
		name = "Shadow Step",
		cooldown = 8,
		staminaCost = 30,
		damage = 0,
		type = "utility",
		description = "Teleport short distance, ignore next attack"
	},
	["GuardBreak"] = {
		id = "GuardBreak",
		name = "Guard Break",
		cooldown = 10,
		staminaCost = 35,
		damage = 20,
		type = "active",
		description = "Break enemy guard, stun for 1 second"
	},
	["Whirlwind"] = {
		id = "Whirlwind",
		name = "Whirlwind",
		cooldown = 12,
		staminaCost = 50,
		damage = 60,
		type = "active",
		description = "Spin attack hitting all nearby enemies"
	},
	["Riposte"] = {
		id = "Riposte",
		name = "Riposte",
		cooldown = 7,
		staminaCost = 20,
		damage = 55,
		type = "active",
		description = "Counter attack after dodge"
	}
}

return Skills
