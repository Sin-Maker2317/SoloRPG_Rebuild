local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- Ensure a safe SpawnLocation exists and place players there on character spawn
local function ensureSpawnLocation()
    local spawn = Workspace:FindFirstChild("__AutoSpawnLocation")
    if spawn and spawn:IsA("SpawnLocation") then
        return spawn
    end

    -- create a safe spawn location at origin
    spawn = Instance.new("SpawnLocation")
    spawn.Name = "__AutoSpawnLocation"
    spawn.Size = Vector3.new(6,1,6)
    spawn.Position = Vector3.new(0, 5, 0)
    spawn.Anchored = true
    spawn.CanCollide = true
    spawn.Parent = Workspace
    return spawn
end

local spawnLocation = ensureSpawnLocation()

local function onCharacterAdded(player, character)
    local hrp = character:WaitForChild("HumanoidRootPart", 5)
    if hrp then
        -- move slightly above spawn to avoid clipping
        hrp.CFrame = spawnLocation.CFrame + Vector3.new(0, 3, 0)
    end
    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    if humanoid then
        humanoid.Died:Connect(function()
            -- optional: ensure respawn position on death (handled by Roblox), but keep safe
            wait(1)
            local newChar = player.Character
            if newChar then
                local newHrp = newChar:FindFirstChild("HumanoidRootPart")
                if newHrp then
                    newHrp.CFrame = spawnLocation.CFrame + Vector3.new(0, 3, 0)
                end
            end
        end)
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char) onCharacterAdded(player, char) end)
    -- if character already present (rare), move it
    if player.Character then
        onCharacterAdded(player, player.Character)
    end
end)

return nil
