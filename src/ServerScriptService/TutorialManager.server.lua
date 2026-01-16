-- TutorialManager.server.lua
-- Orchestrates the First Test Phase onboarding and tutorials.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not remotes then
    remotes = Instance.new("Folder")
    remotes.Name = "Remotes"
    remotes.Parent = ReplicatedStorage
end

-- ensure tutorial-related remotes
local choosePath = remotes:FindFirstChild("ChoosePath") or Instance.new("RemoteEvent")
choosePath.Name = "ChoosePath"
choosePath.Parent = remotes

local tutorialInput = remotes:FindFirstChild("TutorialInput") or Instance.new("RemoteEvent")
tutorialInput.Name = "TutorialInput"
tutorialInput.Parent = remotes

local tutorialAction = remotes:FindFirstChild("TutorialAction") or Instance.new("RemoteEvent")
tutorialAction.Name = "TutorialAction"
tutorialAction.Parent = remotes

local questUpdate = remotes:FindFirstChild("QuestUpdate") -- created by QuestService if missing

local CombatEvent = remotes:FindFirstChild("CombatEvent")

local QuestService = require(script.Parent.Services:WaitForChild("QuestService"))

local PLAYER_STATE = {}

local POS = {
    SoloHouse = Vector3.new(10,6,0),
    Hospital = Vector3.new(-10,6,0),
    MovementTrial = Vector3.new(30,6,0),
    CombatTrial = Vector3.new(60,6,0),
    Hub = Vector3.new(0,6,80),
}

local guardState = {}

local function teleportPlayerTo(player, position)
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = CFrame.new(position + Vector3.new(0,3,0))
        -- explicit log for teleport
        local clientLog = remotes:FindFirstChild("ClientLog")
        if clientLog and clientLog:IsA("RemoteEvent") then
            pcall(function() clientLog:FireClient(player, ("Teleported to %s"):format(tostring(position))) end)
        end
        print("[TutorialManager] Teleported", player.Name, "->", position)
    end
end

local function startMovementTrial(player)
    QuestService:AddQuest(player, { id = "movement_trial", title = "Movement Trial", objectives = { "Dodge twice (2nd while holding forward)" } })
    teleportPlayerTo(player, POS.MovementTrial)
    -- notify client UI state for UIRoot
    local stateRem = remotes:FindFirstChild("StateChanged")
    if stateRem and stateRem:IsA("RemoteEvent") then
        pcall(function() stateRem:FireClient(player, "TUTORIAL_MOVEMENT") end)
    end
    PLAYER_STATE[player] = { stage = "movement", dodgeCount = 0 }
end

local function spawnCombatDummy(player)
    local model = Instance.new("Model")
    model.Name = "TutorialDummy"
    local hrp = Instance.new("Part")
    hrp.Name = "HumanoidRootPart"
    hrp.Size = Vector3.new(2,2,1)
    hrp.Position = player.Character and player.Character.HumanoidRootPart.Position + Vector3.new(0,0,-8) or POS.CombatTrial
    hrp.Anchored = false
    hrp.Parent = model
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Shape = Enum.PartType.Ball
    head.Size = Vector3.new(1,1,1)
    head.Position = hrp.Position + Vector3.new(0,1.5,0)
    head.Parent = model
    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = 60
    humanoid.Health = 60
    humanoid.Parent = model
    model.PrimaryPart = hrp
    model.Parent = Workspace:FindFirstChild("Enemies") or Workspace
    return model, humanoid
end

local function startCombatTrial(player)
    QuestService:AddQuest(player, { id = "combat_trial", title = "Combat Trial", objectives = { "Hit the enemy", "Parry or block an attack", "Defeat the enemy" } })
    teleportPlayerTo(player, POS.CombatTrial)
    local stateRem = remotes:FindFirstChild("StateChanged")
    if stateRem and stateRem:IsA("RemoteEvent") then
        pcall(function() stateRem:FireClient(player, "TUTORIAL_COMBAT") end)
    end
    local model, humanoid = spawnCombatDummy(player)

    -- simple deterministic AI: attack every 2.5s
    spawn(function()
        while humanoid and humanoid.Health > 0 and player.Parent do
            task.wait(2.5)
            if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then break end
            local ppos = player.Character.HumanoidRootPart.Position
            local mpos = model.PrimaryPart.Position
            local dist = (ppos - mpos).Magnitude
            if dist <= 6 then
                -- attack: check guard state
                local guarded = guardState[player]
                if guarded then
                    -- blocked
                    if CombatEvent then pcall(function() CombatEvent:FireClient(player, { type = "Block", position = ppos }) end) end
                else
                    -- deal damage
                    local dmg = 12
                    humanoid:TakeDamage(0) -- no-op on NPC
                    -- apply damage to player
                    local ph = player.Character:FindFirstChildOfClass("Humanoid")
                    if ph then
                        ph:TakeDamage(dmg)
                        if CombatEvent then pcall(function() CombatEvent:FireClient(player, { type = "HitConfirm", position = ppos }) end) end
                    end
                end
            end
            -- exit if NPC died
            if humanoid.Health <= 0 then break end
        end
    end)

    -- listen for player attacks via TutorialAction
    local conn
    conn = tutorialAction.OnServerEvent:Connect(function(p, action)
        if p ~= player then return end
        if action == "attack" and humanoid and humanoid.Health > 0 then
            humanoid:TakeDamage(15)
            if CombatEvent then pcall(function() CombatEvent:FireClient(player, { type = "HitConfirm", position = model.PrimaryPart.Position }) end) end
            if humanoid.Health <= 0 then
                QuestService:CompleteQuest(player, "combat_trial")
                -- reward
                -- teleport out
                teleportPlayerTo(player, POS.Hub)
                if CombatEvent then pcall(function() CombatEvent:FireClient(player, { type = "QuestComplete", id = "combat_trial" }) end) end
                conn:Disconnect()
            end
        end
    end)
end

-- handle TutorialInput (movement trial inputs)
tutorialInput.OnServerEvent:Connect(function(player, payload)
    -- payload: { type = "dodge" | "sprintStart" | "sprintEnd", ts = os.time() }
    local state = PLAYER_STATE[player]
    if not state then return end
    if state.stage == "movement" then
        if payload.type == "dodge" then
            -- payload.forward expected boolean
            local forward = payload.forward and true or false
            if (state.dodgeCount or 0) == 0 then
                state.dodgeCount = 1
                if questUpdate then pcall(function() questUpdate:FireClient(player, { action = "progress", questId = "movement_trial", detail = "first_dodge" }) end) end
            else
                -- second dodge must be with forward held
                if forward then
                    state.dodgeCount = 2
                    if questUpdate then pcall(function() questUpdate:FireClient(player, { action = "progress", questId = "movement_trial", detail = "second_dodge_forward" }) end) end
                    -- complete movement trial and move to combat
                    QuestService:CompleteQuest(player, "movement_trial")
                    task.delay(0.5, function() startCombatTrial(player) end)
                else
                    -- not correct: prompt client (optional)
                    local clientLog = remotes:FindFirstChild("ClientLog")
                    if clientLog and clientLog:IsA("RemoteEvent") then
                        pcall(function() clientLog:FireClient(player, "Second dodge must be performed while holding forward (W).") end)
                    end
                end
            end
        end
    end
end)

-- guard toggles from client
tutorialAction.OnServerEvent:Connect(function(player, action)
    if action == "guard_start" then
        guardState[player] = true
    elseif action == "guard_end" then
        guardState[player] = false
    elseif action == "attack" then
        -- handled in combat trial attack listener
    end
end)

-- handle path choice
choosePath.OnServerEvent:Connect(function(player, path)
    QuestService:CreatePlayer(player)
    if path == "Solo" then
        teleportPlayerTo(player, POS.SoloHouse)
        task.delay(0.8, function() startMovementTrial(player) end)
    else
        -- Guild path: mark guild selection as completed and teleport to hub gate
        teleportPlayerTo(player, POS.Hospital)
        -- in this test phase prompt client to show guild selection (client-side)
        if questUpdate then pcall(function() questUpdate:FireClient(player, { action = "guild_select" }) end) end
    end
end)

-- ensure players created in QuestService
Players.PlayerAdded:Connect(function(player)
    QuestService:CreatePlayer(player)
end)

print("[TutorialManager] Initialized")
