local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local devRemote = remotes:FindFirstChild("DevTools")
if not devRemote then
    devRemote = Instance.new("RemoteEvent")
    devRemote.Name = "DevTools"
    devRemote.Parent = remotes
end

devRemote.OnServerEvent:Connect(function(player, action, ...)
    if action == "SpawnNPC" then
        local ok, EnemyService = pcall(function()
            return require(script.Parent.Services.EnemyService)
        end)
        if ok and EnemyService and EnemyService.SpawnDummyEnemy then
            local pos = nil
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                pos = player.Character.HumanoidRootPart.Position
            else
                pos = Vector3.new(0,5,0)
            end
            pcall(function()
                EnemyService.SpawnDummyEnemy(pos + Vector3.new(0,0,-10))
            end)
        end

    elseif action == "TeleportToNPC" then
        local enemies = Workspace:FindFirstChild("Enemies")
        if enemies and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            local nearest, dist = nil, math.huge
            for _, e in ipairs(enemies:GetChildren()) do
                local eHRP = e:FindFirstChild("HumanoidRootPart")
                if eHRP then
                    local d = (eHRP.Position - hrp.Position).Magnitude
                    if d < dist then
                        dist = d
                        nearest = e
                    end
                end
            end
            if nearest and nearest:FindFirstChild("HumanoidRootPart") then
                hrp.CFrame = nearest.HumanoidRootPart.CFrame + Vector3.new(0,5,0)
            end
        end

    elseif action == "ToggleAI" then
        local enemies = Workspace:FindFirstChild("Enemies")
        if enemies then
            for _, e in ipairs(enemies:GetChildren()) do
                local current = e:GetAttribute("AIEnabled")
                e:SetAttribute("AIEnabled", not current)
            end
        end

    elseif action == "DamageSelf" then
        local amount = ...
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid:TakeDamage(amount or 10)
        end

    elseif action == "HealSelf" then
        local amount = ...
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            local hum = player.Character.Humanoid
            hum.Health = math.min(hum.MaxHealth, hum.Health + (amount or 10))
        end
    end
end)
