-- StarterGui/DebugUI/DebugUI.client.lua
local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- Crea una UI semplicissima per verificare che tutto funzioni
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DebugUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Size = UDim2.fromOffset(500, 60)
label.Position = UDim2.fromOffset(20, 20)
label.TextScaled = true
label.BackgroundTransparency = 0.3
label.Text = "DebugUI: OK (Rojo + Client scripts funzionano)"
label.Parent = screenGui
