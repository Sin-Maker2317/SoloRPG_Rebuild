local CombatResolve = nil
local StatsService = nil

local SkillService = {}

-- Basic skill definitions (v1)
local SKILLS = {
    -- id, name, baseDamage, cooldown
    ["Slash"] = { name = "Slash", base = 10, cd = 1.0 },
    ["Heavy"] = { name = "Heavy", base = 20, cd = 3.0 },
    ["PowerStrike"] = { name = "PowerStrike", base = 35, cd = 6.0 },
}

local playerCooldowns = {}

local function safeRequire(name)
    local ok, mod = pcall(function()
        return require(script.Parent:FindFirstChild(name))
    end)
    return ok and mod or nil
end

function SkillService:Init()
    CombatResolve = safeRequire("CombatResolveService") or nil
    StatsService = safeRequire("StatsService") or safeRequire("PlayerStatsService")
end

function SkillService:CanUse(player, skillId)
    local skill = SKILLS[skillId]
    if not skill then return false, "Unknown skill" end
    local last = playerCooldowns[player.UserId] and playerCooldowns[player.UserId][skillId]
    if last and tick() - last < skill.cd then
        return false, "Cooldown"
    end
    return true
end

function SkillService:UseSkill(player, skillId, target)
    local ok, reason = self:CanUse(player, skillId)
    if not ok then return { success = false, reason = reason } end
    local skill = SKILLS[skillId]
    playerCooldowns[player.UserId] = playerCooldowns[player.UserId] or {}
    playerCooldowns[player.UserId][skillId] = tick()

    -- Resolve damage: if target is enemy model, apply damage directly
    local damage = skill.base
    if CombatResolve and type(CombatResolve.ResolvePlayerAttack) == "function" then
        local res = CombatResolve.ResolvePlayerAttack(player, target, { baseDamage = skill.base })
        damage = (res and res.damage) or damage
    end

    if target and target.FindFirstChildWhichIsA and target:FindFirstChildWhichIsA("Humanoid") then
        local hum = target:FindFirstChildWhichIsA("Humanoid")
        if hum and damage > 0 then
            hum:TakeDamage(damage)
        end
    end

    return { success = true, damage = damage }
end

function SkillService:GetCooldown(player, skillId)
    local skill = SKILLS[skillId]
    if not skill then return 0 end
    local last = playerCooldowns[player.UserId] and playerCooldowns[player.UserId][skillId]
    if not last then return 0 end
    local rem = skill.cd - (tick() - last)
    return math.max(0, rem)
end

return SkillService
