local CombatResolveService = {}

-- Minimal combat resolution for v1
-- Exposes:
-- CalculateDamageFromEnemy(enemyModel, player) -> { damage = number }
-- ResolvePlayerAttack(attackerPlayer, targetModel, attackData) -> { damage = number, hit = boolean }

local StatsService

local function safeRequire(name)
    local ok, mod = pcall(function()
        return require(script.Parent:FindFirstChild(name))
    end)
    return ok and mod or nil
end

local function init()
    StatsService = safeRequire("StatsService") or safeRequire("PlayerStatsService")
end

function CombatResolveService.CalculateDamageFromEnemy(enemyModel, player)
    init()
    local base = 6
    local defense = 0
    if StatsService and type(StatsService.GetDefense) == "function" then
        defense = StatsService:GetDefense(player) or 0
    end
    local dmg = math.max(1, math.floor(base - (defense * 0.1)))
    return { damage = dmg }
end

function CombatResolveService.ResolvePlayerAttack(attackerPlayer, targetModel, attackData)
    init()
    local base = attackData and attackData.baseDamage or 8
    local targetPlayer
    -- if targetModel has attribute IsEnemy, treat as enemy
    if targetModel and targetModel:GetAttribute and targetModel:GetAttribute("IsEnemy") then
        -- simple enemy defense
        local defense = 0
        local dmg = math.max(1, math.floor(base - (defense * 0.1)))
        return { damage = dmg, hit = true }
    else
        -- target is player
        if type(StatsService.GetDefense) == "function" then
            local def = StatsService:GetDefense(targetModel and targetModel.Parent)
            local dmg = math.max(0, math.floor(base - (def * 0.1)))
            return { damage = dmg, hit = dmg > 0 }
        end
        return { damage = base, hit = true }
    end
end

return CombatResolveService
