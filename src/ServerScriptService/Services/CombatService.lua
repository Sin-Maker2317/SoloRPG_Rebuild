-- ServerScriptService/Services/CombatService.lua

local CombatService = {}
CombatService.__index = CombatService

-- Danni base per ora (placeholder)
CombatService.BASE_DAMAGE = 25

function CombatService:DealDamage(targetHumanoid: Humanoid)
	if not targetHumanoid or targetHumanoid.Health <= 0 then
		return
	end

	targetHumanoid:TakeDamage(self.BASE_DAMAGE)
end

return CombatService
