-- StarterGui/DebugUI/DebugUI.client.lua
local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- Crea una UI semplicissima per verificare che tutto funzioni
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DebugUI"
screenGui.ResetOnSpawn = false
local parent = player:WaitForChild("PlayerGui")
screenGui.Parent = parent
screenGui.Enabled = false

local label = Instance.new("TextLabel")
label.Size = UDim2.fromOffset(500, 60)
label.Position = UDim2.fromOffset(20, 20)
label.TextScaled = true
label.BackgroundTransparency = 0.3
label.Text = "DebugUI: Dev tools loaded (Rojo + client OK)"
label.Parent = screenGui

-- Only show debug UI when DevEnabled is true
local function update()
	local dev = parent:FindFirstChild("DevEnabled")
	if dev and dev.Value then
		screenGui.Enabled = true
	else
		screenGui.Enabled = false
	end
end
local dev = parent:FindFirstChild("DevEnabled")
if dev then dev.Changed:Connect(update) end
local se = parent:FindFirstChild("UIStateChanged")
if se then se.Event:Connect(update) end
task.spawn(update)
