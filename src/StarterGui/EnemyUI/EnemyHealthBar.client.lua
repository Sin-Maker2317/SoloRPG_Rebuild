--[[
    EnemyHealthBar - Displays HP bars above enemies
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Cache for enemy healthbars
local enemyHealthbars = {}

local function createHealthbar(enemy)
    if enemyHealthbars[enemy] then
        return
    end
    
    local humanoid = enemy:FindFirstChild("Humanoid")
    local hrp = enemy:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not hrp then return end
    
    -- Create billboard GUI
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(4, 0, 1.5, 0)
    billboard.MaxDistance = 100
    billboard.Parent = hrp
    
    -- Background
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bg.BackgroundTransparency = 0.5
    bg.BorderSizePixel = 1
    bg.BorderColor3 = Color3.fromRGB(255, 255, 255)
    bg.Parent = billboard
    
    -- Health bar (red)
    local healthBar = Instance.new("Frame")
    healthBar.Name = "HealthBar"
    healthBar.Size = UDim2.new(1, -4, 0.5, -2)
    healthBar.Position = UDim2.new(0, 2, 0, 2)
    healthBar.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
    healthBar.BorderSizePixel = 0
    healthBar.Parent = bg
    
    -- Health text
    local healthText = Instance.new("TextLabel")
    healthText.Name = "HealthText"
    healthText.Size = UDim2.new(1, -4, 0.4, -2)
    healthText.Position = UDim2.new(0, 2, 0.55, 2)
    healthText.BackgroundTransparency = 1
    healthText.TextColor3 = Color3.fromRGB(255, 255, 255)
    healthText.TextSize = 12
    healthText.Parent = bg
    
    enemyHealthbars[enemy] = {
        billboard = billboard,
        healthBar = healthBar,
        healthText = healthText,
        humanoid = humanoid,
        maxHealth = humanoid.MaxHealth
    }
    
    -- Remove from cache when enemy dies
    humanoid.Died:Connect(function()
        if enemyHealthbars[enemy] then
            billboard:Destroy()
            enemyHealthbars[enemy] = nil
        end
    end)
end

-- Monitor for new enemies
local function setupEnemyTracking()
    local enemiesFolder = Workspace:FindFirstChild("Enemies")
    
    if enemiesFolder then
        enemiesFolder.ChildAdded:Connect(function(child)
            task.wait(0.1)
            createHealthbar(child)
        end)
        
        -- Setup existing enemies
        for _, enemy in ipairs(enemiesFolder:GetChildren()) do
            createHealthbar(enemy)
        end
    end
end

-- Update healthbars every frame
RunService.RenderStepped:Connect(function()
    for enemy, data in pairs(enemyHealthbars) do
        if enemy and enemy.Parent and data.humanoid then
            local health = data.humanoid.Health
            local maxHealth = data.maxHealth
            local healthPercent = math.max(0, math.min(1, health / maxHealth))
            
            data.healthBar.Size = UDim2.new(healthPercent, -4, 0.5, -2)
            data.healthText.Text = string.format("%.0f / %.0f", health, maxHealth)
        else
            enemyHealthbars[enemy] = nil
        end
    end
end)

-- Start tracking
setupEnemyTracking()
