--[[
    DevSpawnHandler - Creates a clean dev environment for testing
    - Safe spawn platform
    - Test dummy NPC with HP bar
    - DevUI auto-load
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Flag to enable dev mode
local DEV_MODE = true

local function createDevPlatform()
    if not DEV_MODE then return end
    
    local devFolder = Instance.new("Folder")
    devFolder.Name = "DevEnvironment"
    devFolder.Parent = Workspace
    
    -- Create safe spawn platform
    local platform = Instance.new("Part")
    platform.Name = "DevPlatform"
    platform.Shape = Enum.PartType.Block
    platform.Size = Vector3.new(40, 1, 40)
    platform.Position = Vector3.new(0, 5, 0)
    platform.Material = Enum.Material.Concrete
    platform.CanCollide = true
    platform.TopSurface = Enum.SurfaceType.Smooth
    platform.BottomSurface = Enum.SurfaceType.Smooth
    platform.Parent = devFolder
    
    -- Add visual grid to platform
    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Face = Enum.NormalId.Top
    surfaceGui.Parent = platform
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(80, 120, 160)
    frame.BorderSizePixel = 0
    frame.Parent = surfaceGui
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "DEV SPAWN AREA"
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 24
    label.Parent = frame
    
    -- Spawn location marker
    local spawnMarker = Instance.new("Part")
    spawnMarker.Name = "SpawnMarker"
    spawnMarker.Shape = Enum.PartType.Ball
    spawnMarker.Size = Vector3.new(2, 2, 2)
    spawnMarker.Position = Vector3.new(0, 6.5, 0)
    spawnMarker.Material = Enum.Material.Neon
    spawnMarker.CanCollide = false
    spawnMarker.Color = Color3.fromRGB(0, 255, 0)
    spawnMarker.Parent = devFolder
    
    return devFolder, platform
end

local function onPlayerAdded(player)
    if not DEV_MODE then return end
    
    player.CharacterAdded:Connect(function(character)
        task.wait(0.1)
        
        local hrp = character:WaitForChild("HumanoidRootPart", 5)
        if not hrp then return end
        
        -- Teleport to dev platform
        hrp.CFrame = CFrame.new(Vector3.new(0, 7, 0))
        
        -- Spawn test enemies continuously (for testing combat)
        local RewardService = require(game:GetService("ServerScriptService"):WaitForChild("Services"):WaitForChild("RewardService"))
        local MobService = require(game:GetService("ServerScriptService"):WaitForChild("Services"):WaitForChild("MobService"))
        
        local spawnActive = true
        character.Humanoid.Died:Connect(function()
            spawnActive = false
        end)
        
        -- Spawn wave of enemies
        spawn(function()
            while spawnActive do
                task.wait(8) -- Spawn every 8 seconds
                
                -- Spawn 1-2 random mobs around the dev area
                for i = 1, math.random(1, 2) do
                    local spawnPos = Vector3.new(math.random(-15, 15), 5, math.random(-15, 15))
                    local mob = MobService:SpawnRandom(spawnPos, function(mobKey, mobConfig, model)
                        -- On mob death: award player XP
                        local baseXP = 50
                        local coinReward = 25
                        RewardService:Add(player, baseXP, coinReward)
                    end)
                    
                    if mob then
                        local mobHum = mob:FindFirstChildOfClass("Humanoid")
                        if mobHum then
                            -- Ensure mob spawns at full health; avoid using mobConfig here (scoped in callback)
                            pcall(function() mobHum.Health = mobHum.MaxHealth end)
                        end
                    end
                end
            end
        end)
    end)
end

-- Initialize dev environment
-- Note: PlayerAdded connect is handled in the init block below.

-- Initialize dev environment
if DEV_MODE then
    createDevPlatform()

    Players.PlayerAdded:Connect(onPlayerAdded)

    -- Handle players already in game
    for _, player in ipairs(Players:GetPlayers()) do
        onPlayerAdded(player)
    end
end
