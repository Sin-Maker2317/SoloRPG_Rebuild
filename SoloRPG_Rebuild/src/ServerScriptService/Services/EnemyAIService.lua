local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local EnemyAIService = {}

-- Simple per-enemy state machine v1
-- States: "Idle", "Chase", "Attack", "Cooldown"

local DEFAULTS = {
    aggroRange = 40,
    attackRange = 3,
    chaseSpeed = 12,
    idleSpeed = 0,
    attackCooldown = 1.2,
    telegraphTime = 0.35,
}

local function isAlive(hum)
    return hum and hum.Health > 0 and hum.Parent
end

function EnemyAIService:AttachToEnemy(model)
    if not model then return end
    local humanoid = model:FindFirstChildWhichIsA("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root then return end

    model:SetAttribute("AIState", "Idle")
    model:SetAttribute("LastAttackTime", 0)

    spawn(function()
        while model.Parent and isAlive(humanoid) do
            local state = model:GetAttribute("AIState") or "Idle"
            local targetPlayer, targetChar, targetHum, targetRoot
            -- find nearest player within aggro range
            local nearestDist = DEFAULTS.aggroRange
            for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
                local char = plr.Character
                local hum = char and char:FindFirstChildWhichIsA("Humanoid")
                local r = char and char:FindFirstChild("HumanoidRootPart")
                if hum and r and hum.Health > 0 then
                    local d = (r.Position - root.Position).Magnitude
                    if d < nearestDist then
                        nearestDist = d
                        targetPlayer = plr
                        targetChar = char
                        targetHum = hum
                        targetRoot = r
                    end
                end
            end

            if targetPlayer then
                local dist = (targetRoot.Position - root.Position).Magnitude
                if dist <= DEFAULTS.attackRange then
                    model:SetAttribute("AIState", "Attack")
                else
                    model:SetAttribute("AIState", "Chase")
                end
            else
                model:SetAttribute("AIState", "Idle")
            end

            state = model:GetAttribute("AIState")

            if state == "Idle" then
                humanoid.WalkSpeed = DEFAULTS.idleSpeed
                wait(0.5)
            elseif state == "Chase" and targetRoot then
                humanoid.WalkSpeed = DEFAULTS.chaseSpeed
                humanoid:MoveTo(targetRoot.Position)
                wait(0.2)
            elseif state == "Attack" and targetRoot then
                local now = tick()
                local last = model:GetAttribute("LastAttackTime") or 0
                if now - last >= DEFAULTS.attackCooldown then
                    -- telegraph
                    model:SetAttribute("AIState", "Attack")
                    -- simple telegraph: wait a short window where player can dodge
                    wait(DEFAULTS.telegraphTime)
                    -- perform attack by applying damage via CombatResolveService if present
                    local success, crs = pcall(function()
                        return require(script.Parent:FindFirstChild("CombatResolveService"))
                    end)
                    local damage = 5
                    if success and type(crs.CalculateDamageFromEnemy) == "function" then
                        local result = crs.CalculateDamageFromEnemy(model, targetPlayer)
                        damage = result.damage or damage
                    end
                    -- apply damage to target humanoid on server
                    if targetHum and targetHum.Parent then
                        targetHum:TakeDamage(damage)
                    end
                    model:SetAttribute("LastAttackTime", now)
                    model:SetAttribute("AIState", "Cooldown")
                end
                wait(0.1)
            elseif state == "Cooldown" then
                wait(DEFAULTS.attackCooldown)
                model:SetAttribute("AIState", "Idle")
            else
                wait(0.2)
            end
        end
    end)
end

-- Attach to existing enemies in Workspace.Enemies
spawn(function()
    local enemiesFolder = Workspace:FindFirstChild("Enemies")
    if enemiesFolder then
        for _, m in ipairs(enemiesFolder:GetChildren()) do
            if m:GetAttribute and m:GetAttribute("IsEnemy") then
                pcall(function() EnemyAIService:AttachToEnemy(m) end)
            end
        end
    end
end)

return EnemyAIService
