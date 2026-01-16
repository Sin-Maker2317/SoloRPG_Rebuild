-- TutorialClient.client.lua
-- Sends tutorial inputs (dodge, guard, attack) to server and updates local UI state
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local tutorialInput = remotes:WaitForChild("TutorialInput")
local tutorialAction = remotes:WaitForChild("TutorialAction")
local stateChanged = remotes:FindFirstChild("StateChanged")
local CombatEvent = remotes:FindFirstChild("CombatEvent")

local playerGui = player:WaitForChild("PlayerGui")

local currentState = nil
local forwardHeld = false

local function setClientUIState(state)
    currentState = state
    -- mirror into PlayerGui so UIRoot can pick it up
    local sv = playerGui:FindFirstChild("UIState")
    if sv and sv:IsA("StringValue") then
        sv.Value = state
    end
    local be = playerGui:FindFirstChild("UIStateChanged")
    if be and be:IsA("BindableEvent") then
        pcall(function() be:Fire(state) end)
    end
end

-- Listen for server-driven state changes (tutorial start/stop)
if stateChanged and stateChanged:IsA("RemoteEvent") then
    stateChanged.OnClientEvent:Connect(function(s)
        if type(s) == "string" then
            setClientUIState(s)
        end
    end)
end

-- Input handling
local dodgeDebounce = false
local guardActive = false
local attackDebounce = false

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == Enum.KeyCode.W then
            forwardHeld = true
        elseif input.KeyCode == Enum.KeyCode.Q then
            -- Dodge
            if dodgeDebounce then return end
            dodgeDebounce = true
            task.spawn(function()
                local forward = UserInputService:IsKeyDown(Enum.KeyCode.W)
                pcall(function() tutorialInput:FireServer({ type = "dodge", forward = forward, ts = os.time() }) end)
                task.wait(0.25)
                dodgeDebounce = false
            end)
        elseif input.KeyCode == Enum.KeyCode.F then
            -- Guard start
            if not guardActive then
                guardActive = true
                pcall(function() tutorialAction:FireServer("guard_start") end)
            end
        end
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
        -- Attack
        if attackDebounce then return end
        attackDebounce = true
        pcall(function() tutorialAction:FireServer("attack") end)
        task.delay(0.2, function() attackDebounce = false end)
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == Enum.KeyCode.W then
            forwardHeld = false
        elseif input.KeyCode == Enum.KeyCode.F then
            if guardActive then
                guardActive = false
                pcall(function() tutorialAction:FireServer("guard_end") end)
            end
        end
    end
end)

-- Mirror initial UI state if server already sent one via PlayerGui values
local svInit = playerGui:FindFirstChild("UIState")
if svInit and svInit:IsA("StringValue") then
    currentState = svInit.Value
end

print("[TutorialClient] Initialized")

-- Simple combat feedback UI (shows HitConfirm text briefly)
local feedbackGui = Instance.new("ScreenGui")
feedbackGui.Name = "CombatFeedback"
feedbackGui.ResetOnSpawn = false
feedbackGui.Parent = playerGui

local fbLabel = Instance.new("TextLabel")
fbLabel.Size = UDim2.new(0.3, 0, 0.08, 0)
fbLabel.Position = UDim2.new(0.35, 0, 0.05, 0)
fbLabel.BackgroundTransparency = 0.6
fbLabel.BackgroundColor3 = Color3.fromRGB(0,0,0)
fbLabel.TextColor3 = Color3.fromRGB(255,200,100)
fbLabel.TextScaled = true
fbLabel.Visible = false
fbLabel.Parent = feedbackGui

if CombatEvent and CombatEvent:IsA("RemoteEvent") then
    CombatEvent.OnClientEvent:Connect(function(payload)
        if not payload or type(payload) ~= "table" then return end
        if payload.type == "HitConfirm" then
            fbLabel.Text = ("Hit! -%d"):format(payload.damage or 0)
            fbLabel.Visible = true
            task.delay(0.5, function()
                fbLabel.Visible = false
            end)
        elseif payload.type == "HitFailed" then
            fbLabel.Text = "Miss"
            fbLabel.Visible = true
            task.delay(0.4, function() fbLabel.Visible = false end)
        elseif payload.type == "Block" then
            fbLabel.Text = "Blocked"
            fbLabel.Visible = true
            task.delay(0.6, function() fbLabel.Visible = false end)
        end
    end)
end
