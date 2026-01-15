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
    end
end

local function startMovementTrial(player)
    QuestService:AddQuest(player, { id = "movement_trial", title = "Movement Trial", objectives = { "Dodge twice", "Sprint forward" } })
    teleportPlayerTo(player, POS.MovementTrial)
    PLAYER_STATE[player] = { stage = "movement", dodgeCount = 0, sprintStarts = 0, sprintHeldStart = nil }
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
            state.dodgeCount = (state.dodgeCount or 0) + 1
            if state.dodgeCount >= 2 then
                -- mark dodge objective complete
                -- require sprint next; wait for sprint to complete
                if questUpdate then pcall(function() questUpdate:FireClient(player, { action = "progress", questId = "movement_trial", detail = "dodges" }) end) end
            end
        elseif payload.type == "sprintStart" then
            state.sprintHeldStart = os.clock()
        elseif payload.type == "sprintEnd" then
            if state.sprintHeldStart then
                local dur = os.clock() - state.sprintHeldStart
                state.sprintHeldStart = nil
                if dur >= 1.5 then
                    -- sprint objective satisfied
                    QuestService:CompleteQuest(player, "movement_trial")
                    -- teleport to combat
                    task.delay(0.5, function() startCombatTrial(player) end)
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
