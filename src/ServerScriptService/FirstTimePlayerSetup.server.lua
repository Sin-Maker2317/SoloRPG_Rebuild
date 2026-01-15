-- FirstTimePlayerSetup.server.lua
-- Teleport brand-new players to the Tutorial spawn and mark them as seen.
-- Temporary helper for Test Phase only. Non-destructive.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local TUTORIAL_SPAWN_NAME = "_TutorialSpawn"

local function ensureTutorialSpawn()
    local spawn = Workspace:FindFirstChild(TUTORIAL_SPAWN_NAME)
    if spawn and spawn:IsA("Part") then return spawn end

    spawn = Instance.new("Part")
    spawn.Name = TUTORIAL_SPAWN_NAME
    spawn.Size = Vector3.new(6,1,6)
    spawn.Anchored = true
    spawn.CanCollide = false
    spawn.Position = Vector3.new(0, 6, 0)
    spawn.Transparency = 1
    spawn.Parent = Workspace

    -- visual marker (client visuals will highlight)
    local mark = Instance.new("SurfaceGui")
    mark.Face = Enum.NormalId.Top
    mark.Adornee = spawn
    mark.Parent = spawn

    return spawn
end

local function onPlayerAdded(player)
    -- Only act for new players who haven't seen tutorial
    if player:GetAttribute("SeenTutorial") then return end
    local spawn = ensureTutorialSpawn()

    player.CharacterAdded:Connect(function(char)
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        if hrp then
            pcall(function()
                hrp.CFrame = CFrame.new(spawn.Position + Vector3.new(0, 3, 0))
            end)
        end
        -- mark as seen to avoid repeating in same session
        player:SetAttribute("SeenTutorial", true)
    end)
end

for _, p in ipairs(Players:GetPlayers()) do
    onPlayerAdded(p)
end

Players.PlayerAdded:Connect(onPlayerAdded)

print("[FirstTimePlayerSetup] Initialized tutorial spawn helper (temporary).")
