-- ChoosePath.client.lua
-- Shows initial modal to pick Solo or Guild. Blocks world interaction until chosen.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local choosePath = remotes:WaitForChild("ChoosePath")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ChoosePathGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = script.Parent
screenGui.Enabled = false

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0,420,0,180)
frame.Position = UDim2.new(0.5, -210, 0.5, -90)
frame.BackgroundColor3 = Color3.fromRGB(24,24,26)
frame.BorderSizePixel = 0
frame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,40)
title.Position = UDim2.new(0,0,0,4)
title.BackgroundTransparency = 1
title.Text = "Choose Your Path"
title.TextColor3 = Color3.fromRGB(230,230,230)
title.Font = Enum.Font.GothamBold
title.TextSize = 22
title.Parent = frame

local function mkBtn(text, y)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.44,0,0,48)
    b.Position = UDim2.new(0.05,0,0,y)
    b.Text = text
    b.Font = Enum.Font.Gotham
    b.TextSize = 18
    b.BackgroundColor3 = Color3.fromRGB(70,70,75)
    b.TextColor3 = Color3.fromRGB(240,240,240)
    b.BorderSizePixel = 0
    b.Parent = frame
    return b
end

local soloBtn = mkBtn("Solo", 0.28)
local guildBtn = mkBtn("Guild", 0.56)

soloBtn.MouseButton1Click:Connect(function()
    choosePath:FireServer("Solo")
    screenGui:Destroy()
end)

guildBtn.MouseButton1Click:Connect(function()
    choosePath:FireServer("Guild")
    screenGui:Destroy()
end)

-- Gate visibility to UIState (UIRoot will manage layers)
local playerGui = player:WaitForChild("PlayerGui")
local se = playerGui:FindFirstChild("UIStateChanged")
if se then
    se.Event:Connect(function(ns)
        screenGui.Enabled = (ns == "CHOOSE_PATH")
    end)
end
local sv = playerGui:FindFirstChild("UIState")
if sv and sv.Value == "CHOOSE_PATH" then
    screenGui.Enabled = true
end
