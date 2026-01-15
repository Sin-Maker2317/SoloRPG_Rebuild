-- Shared/Types.lua
-- Type documentation for table shapes (not enforced, but documented)

return {
	-- Progress: { awakened: boolean, pathChoice: "Solo" | "Guild" | nil, faction: string | nil }
	-- PlayerStats: { level: number, xp: number, xpToNext: number, statPoints: number, str: number, agi: number, vit: number, int: number }
	-- Skill: { id: string, name: string, cooldown: number, staminaCost: number, damage: number, type: "active" | "passive" }
	-- Item: { id: string, name: string, type: "weapon" | "armor" | "consumable", rarity: "common" | "uncommon" | "rare" | "epic" | "legendary", stats: { damage?: number, defense?: number } }
	-- Gate: { id: string, grade: string, type: string, name: string, cooldownEnd: number, reservedBy: Player | nil }
	-- Quest: { id: string, name: string, progress: number, goal: number, completed: boolean }
}
