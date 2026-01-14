local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local EnemyAIService = {}

local DEFAULTS = {
    aggroRange = 40,
    attackRange = 3,
    chaseSpeed = 12,
    idleSpeed = 0,
    attackCooldown = 1.2,
    telegraphTime = 0.35,
}

local function isAlive(hum)
    return hum and hum.Health and hum.Health > 0
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
            -- find nearest player
            local nearestDist = DEFAULTS.aggroRange
            local targetPlayer, targetRoot, targetHum
            for _, plr in ipairs(Players:GetPlayers()) do
                local char = plr.Character
                if char then
                    local hum = char:FindFirstChildWhichIsA("Humanoid")
                    local r = char:FindFirstChild("HumanoidRootPart")
                    if hum and r and hum.Health > 0 then
                        local d = (r.Position - root.Position).Magnitude
                        if d < nearestDist then
                            nearestDist = d
                            targetPlayer = plr
                            targetRoot = r
                            targetHum = hum
                        end
                    end
                end
            end

            if targetPlayer and targetRoot then
                local dist = (targetRoot.Position - root.Position).Magnitude
                if dist <= DEFAULTS.attackRange then
                    -- attack
                    local now = tick()
                    local last = model:GetAttribute("LastAttackTime") or 0
                    if now - last >= DEFAULTS.attackCooldown then
                        -- telegraph
                        wait(DEFAULTS.telegraphTime)
                        -- compute damage via CombatResolveService if available
                        local ok, crs = pcall(function()
                            local s = script.Parent:FindFirstChild("CombatResolveService")
                            if s then return require(s) end
                            return nil
                        end)
                        local damage = 5
                        if ok and crs and type(crs.CalculateDamageFromEnemy) == "function" then
                            local res = crs.CalculateDamageFromEnemy(model, targetPlayer)
                            damage = (res and res.damage) or damage
                        end
                        if targetHum and targetHum.Parent and damage > 0 then
                            targetHum:TakeDamage(damage)
                        end
                        model:SetAttribute("LastAttackTime", now)
                    end
                else
                    -- chase
                    humanoid.WalkSpeed = DEFAULTS.chaseSpeed
                    humanoid:MoveTo(targetRoot.Position)
                end
            else
                humanoid.WalkSpeed = DEFAULTS.idleSpeed
            end

            wait(0.2)
        end
    end)
end

-- attach to existing enemies
spawn(function()
    local enemiesFolder = Workspace:FindFirstChild("Enemies")
    if enemiesFolder then
        for _, m in ipairs(enemiesFolder:GetChildren()) do
            if m.GetAttribute and m:GetAttribute("IsEnemy") then
                pcall(function() EnemyAIService:AttachToEnemy(m) end)
            end
        end
    end
end)

return EnemyAIService
