-- TutorialHUD.client.lua
-- Displays current quest objectives and relays player inputs to server for validation.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local tutorialInput = remotes:WaitForChild("TutorialInput")
local tutorialAction = remotes:WaitForChild("TutorialAction")
local questUpdate = remotes:WaitForChild("QuestUpdate")

local playerGui = player:WaitForChild("PlayerGui")
local gui = Instance.new("ScreenGui")
gui.Name = "TutorialHUD"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0,320,0,120)
frame.Position = UDim2.new(0.01,0,0.01,0)
frame.BackgroundTransparency = 0.2
frame.BackgroundColor3 = Color3.fromRGB(18,18,18)
frame.BorderSizePixel = 0
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -12, 0, 28)
title.Position = UDim2.new(0,6,0,6)
title.BackgroundTransparency = 1
title.Text = "Tutorial"
title.TextColor3 = Color3.fromRGB(230,230,230)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Parent = frame

local objLabel = Instance.new("TextLabel")
objLabel.Size = UDim2.new(1, -12, 0, 64)
objLabel.Position = UDim2.new(0,6,0,36)
objLabel.BackgroundTransparency = 1
objLabel.Text = "Objectives:\n- "
objLabel.TextWrapped = true
objLabel.TextColor3 = Color3.fromRGB(220,220,220)
objLabel.Font = Enum.Font.Gotham
objLabel.TextSize = 14
objLabel.Parent = frame

local currentQuest = nil

questUpdate.OnClientEvent:Connect(function(payload)
    if payload.action == "start" and payload.quest then
        currentQuest = payload.quest
        local s = "Objectives:\n"
        for _, o in ipairs(currentQuest.objectives or {}) do
            s = s .. "- " .. o .. "\n"
        end
        objLabel.Text = s
    elseif payload.action == "progress" then
        -- minor visual feedback
        objLabel.Text = objLabel.Text .. "\n(Progress: " .. tostring(payload.detail) .. ")"
    elseif payload.action == "complete" then
        objLabel.Text = "Quest complete: " .. (payload.quest and payload.quest.title or "")
        task.delay(1.2, function() objLabel.Text = "" end)
    elseif payload.action == "guild_select" then
        -- display guild chooser (simple)
        objLabel.Text = "Choose a Guild: Click 1/2/3"
    end
end)

-- map input to tutorial events
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Q then
        pcall(function() tutorialInput:FireServer({ type = "dodge", ts = os.time() }) end)
    elseif input.KeyCode == Enum.KeyCode.W then
        -- sprint start
        pcall(function() tutorialInput:FireServer({ type = "sprintStart", ts = os.time() }) end)
    elseif input.KeyCode == Enum.KeyCode.F then
        pcall(function() tutorialAction:FireServer("guard_start") end)
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
        -- assume basic attack
        pcall(function() tutorialAction:FireServer("attack") end)
    elseif input.KeyCode == Enum.KeyCode.One then
        -- guild select 1
        pcall(function() questUpdate:FireServer({ action = "guild_choice", choice = 1 }) end)
    elseif input.KeyCode == Enum.KeyCode.Two then
        pcall(function() questUpdate:FireServer({ action = "guild_choice", choice = 2 }) end)
    elseif input.KeyCode == Enum.KeyCode.Three then
        pcall(function() questUpdate:FireServer({ action = "guild_choice", choice = 3 }) end)
    end
end)

UserInputService.InputEnded:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.W then
        pcall(function() tutorialInput:FireServer({ type = "sprintEnd", ts = os.time() }) end)
    elseif input.KeyCode == Enum.KeyCode.F then
        pcall(function() tutorialAction:FireServer("guard_end") end)
    end
end)
