local CombatResolveService = {}

-- v1 enhanced combat resolution
-- Concepts implemented:
--  - Perfect dodge window (i-frames) using `LastDodgeTime` attribute on character
--  - Parry window using `LastParryTime` attribute on character
--  - Simple damage formula using StatsService:GetDefense

local StatsService

local function safeRequire(name)
    local ok, mod = pcall(function()
        return require(script.Parent:FindFirstChild(name))
    end)
    return ok and mod or nil
end

local function init()
    if StatsService then return end
    StatsService = safeRequire("StatsService") or safeRequire("PlayerStatsService")
end

local function isInWindow(character, attrName, window)
    if not character or not character.GetAttribute then return false end
    local t = character:GetAttribute(attrName)
    if not t then return false end
    return (tick() - t) <= window
end

function CombatResolveService.CalculateDamageFromEnemy(enemyModel, player)
    init()
    local base = 6
    local defense = 0
    if StatsService and type(StatsService.GetDefense) == "function" then
        defense = StatsService:GetDefense(player) or 0
    end

    local char = player and player.Character
    -- perfect dodge window (i-frames)
    if isInWindow(char, "LastDodgeTime", 0.3) then
        return { damage = 0, dodge = true }
    end

    -- parry (reflect) window
    if isInWindow(char, "LastParryTime", 0.15) then
        -- small stamina/guard consequence handled elsewhere
        return { damage = 0, parry = true, reflect = math.max(1, math.floor(base * 0.6)) }
    end

    local dmg = math.max(1, math.floor(base - (defense * 0.1)))
    return { damage = dmg }
end

function CombatResolveService.ResolvePlayerAttack(attackerPlayer, targetModel, attackData)
    init()
    local base = attackData and attackData.baseDamage or 8

    if targetModel and targetModel.GetAttribute and targetModel:GetAttribute("IsEnemy") then
        -- enemy target: simple defense attribute support
        local enemyDef = targetModel:GetAttribute("Defense") or 0
        local dmg = math.max(1, math.floor(base - (enemyDef * 0.1)))
        return { damage = dmg, hit = true }
    end

    -- target is player
    local targetChar = targetModel and targetModel.Parent
    if isInWindow(targetChar, "LastDodgeTime", 0.3) then
        return { damage = 0, dodge = true }
    end
    if isInWindow(targetChar, "LastParryTime", 0.15) then
        return { damage = 0, parry = true, reflect = math.max(1, math.floor(base * 0.6)) }
    end

    local defense = 0
    if StatsService and type(StatsService.GetDefense) == "function" then
        defense = StatsService:GetDefense(targetModel and targetModel.Parent) or 0
    end
    local dmg = math.max(0, math.floor(base - (defense * 0.1)))
    return { damage = dmg, hit = dmg > 0 }
end

return CombatResolveService
