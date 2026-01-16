-- RespawnService.lua
-- Central respawn handling: track last safe spawn per-player, handle deaths, and provide a KillPlane for instant void respawn.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local WorldService = require(script.Parent:WaitForChild("WorldService"))

local RespawnService = {}
RespawnService.__index = RespawnService

local lastSafe = {}      -- map player -> { spawnName = string, type = "City"|"Gate" }
local respawning = {}    -- debounce map

local function safePrint(...)
    print("[Respawn]", ...)
end

function RespawnService:SetLastSafeSpawn(player, spawnName)
    if not player then return end
    lastSafe[player] = { spawnName = spawnName or "Spawn_Town", type = (tostring(spawnName):find("SoloGate") and "Gate") or "City" }
end

function RespawnService:GetLastSafeSpawn(player)
    local v = lastSafe[player]
    if v then return v.spawnName, v.type end
    return "Spawn_Town", "City"
end

function RespawnService:RespawnPlayer(player, reason)
    if not player or not player.Parent then return end
    if respawning[player] then return end
    respawning[player] = true
    task.defer(function()
        local spawnName, spawnType = self:GetLastSafeSpawn(player)
        safePrint("Reason:", reason or "Unknown", "-> Using spawn:", spawnName)

        local spawnCF = WorldService:GetSpawnCFrame(spawnName) or WorldService:GetSpawnCFrame("Spawn_Town")

        -- Force a fresh character load to avoid stuck states
        pcall(function()
            player:LoadCharacter()
        end)

        local char = player.Character
        if not char then
            char = player.CharacterAdded:Wait()
        end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hrp and spawnCF then
            hrp.CFrame = spawnCF + Vector3.new(0,3,0)
        end
        if hum then
            hum.Health = hum.MaxHealth or 100
        end

        task.wait(0.25)
        respawning[player] = nil
    end)
end

-- internal death handler
local function onHumanoidDied(player, humanoid)
    -- decide reason
    local spawnName, spawnType = RespawnService:GetLastSafeSpawn(player)
    local reason = "Normal"
    if spawnType == "Gate" then reason = "GateDeath" end
    safePrint("Player died:", player and player.Name or "<unknown>", "reason determined:", reason)
    RespawnService:RespawnPlayer(player, reason)
end

function RespawnService:Init()
    -- ensure World exists and create a KillPlane far below
    local world = Workspace:FindFirstChild("World") or Instance.new("Folder")
    if not world.Parent then
        world.Name = "World"
        world.Parent = Workspace
    end

    -- KillPlane part
    local kp = world:FindFirstChild("KillPlane")
    if not kp then
        kp = Instance.new("Part")
        kp.Name = "KillPlane"
        kp.Anchored = true
        kp.CanCollide = false
        kp.Transparency = 1
        kp.Size = Vector3.new(3000, 4, 3000)
        kp.Position = Vector3.new(0, -500, 0)
        kp.Parent = world
    end
    kp.Touched:Connect(function(part)
        local char = part:FindFirstAncestorOfClass("Model")
        if not char then return end
        local player = Players:GetPlayerFromCharacter(char)
        if not player then return end
        safePrint(player.Name, "touched KillPlane -> respawning (Void)")
        RespawnService:RespawnPlayer(player, "Void")
    end)

    -- Player added hooks
    Players.PlayerAdded:Connect(function(player)
        -- default safe spawn: town
        self:SetLastSafeSpawn(player, "Spawn_Town")

        player.CharacterAdded:Connect(function(character)
            -- connect humanoid died
            local hum = character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.Died:Connect(function() onHumanoidDied(player, hum) end)
            else
                character:WaitForChild("Humanoid").Died:Connect(function() onHumanoidDied(player, hum) end)
            end
        end)
    end)
end

return RespawnService
