local CombatResolve = nil
local StatsService = nil

-- DEV settings: toggle to disable cooldowns and enable auto-target for quick testing
local DEV_NO_COOLDOWNS = true
local DEV_AUTO_TARGET = true

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
    if DEV_NO_COOLDOWNS then return true end
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

    -- Auto-target nearest enemy if none provided (dev mode)
    if DEV_AUTO_TARGET and (not target or not target.Parent) then
        local Workspace = game:GetService("Workspace")
        local enemies = Workspace:FindFirstChild("Enemies")
        if enemies then
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local hrp = char.HumanoidRootPart
                local best, bestDist = nil, math.huge
                for _, e in ipairs(enemies:GetChildren()) do
                    local eHRP = e:FindFirstChild("HumanoidRootPart")
                    if eHRP then
                        local d = (eHRP.Position - hrp.Position).Magnitude
                        if d < bestDist then
                            bestDist = d
                            best = e
                        end
                    end
                end
                if best then target = best end
            end
        end
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
