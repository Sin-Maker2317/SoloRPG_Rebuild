-- ServerScriptService/Services/SkillService.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Skills = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Skills"))
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local DebugService = require(script.Parent:WaitForChild("DebugService"))

local SkillService = {}
SkillService.__index = SkillService

local cooldowns = {} -- [player] = { [skillId] = cooldownEnd }
local stamina = {} -- [player] = currentStamina

function SkillService:GetCooldown(player, skillId)
	cooldowns[player] = cooldowns[player] or {}
	return cooldowns[player][skillId] or 0
end

function SkillService:UseSkill(player, skillId)
	local skillDef = Skills.Definitions[skillId]
	if not skillDef then
		return false, "Invalid skill"
	end
	
	local now = tick()
	if self:GetCooldown(player, skillId) > now then
		return false, "Skill on cooldown"
	end
	
	stamina[player] = stamina[player] or 100
	if stamina[player] < skillDef.staminaCost then
		return false, "Not enough stamina"
	end
	
	stamina[player] = stamina[player] - skillDef.staminaCost
	cooldowns[player][skillId] = now + skillDef.cooldown
	
	DebugService:Log("[SkillService]", player.Name, "used", skillDef.name)
	return true, skillDef
end

function SkillService:Clear(player)
	cooldowns[player] = nil
	stamina[player] = nil
end

return SkillService
