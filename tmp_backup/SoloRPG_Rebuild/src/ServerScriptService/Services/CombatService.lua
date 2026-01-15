-- ServerScriptService/Services/CombatService.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatResolveService = require(script.Parent:WaitForChild("CombatResolveService"))
local DebugService = require(script.Parent:WaitForChild("DebugService"))

local CombatService = {}
CombatService.__index = CombatService

CombatService.BASE_DAMAGE = 25

function CombatService:DealDamage(targetHumanoid: Humanoid)
	if not targetHumanoid or targetHumanoid.Health <= 0 then
		return
	end

	targetHumanoid:TakeDamage(self.BASE_DAMAGE)
end

function CombatService:EnemyAttack(enemyModel, targetPlayer, isElite)
	local character = targetPlayer.Character
	if not character then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end
	
	local damage = 15
	if isElite then
		damage = 25
	end
	
	-- TODO: Check Guard/Dodge states from client
	-- For v1, just apply damage
	local defense = CombatResolveService:CalculatePlayerDefense(targetPlayer)
	damage = math.max(1, damage - defense * 0.5)
	
	humanoid:TakeDamage(damage)
	
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local combatEvent = remotes:WaitForChild("CombatEvent")
	combatEvent:FireClient(targetPlayer, { type = "HitConfirm", damage = damage })
	
	DebugService:Log("[CombatService] Enemy attack:", damage, "damage to", targetPlayer.Name)
end

return CombatService
