local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GateMessage = Remotes:WaitForChild("GateMessage")

local gui = Instance.new("ScreenGui")
gui.Name = "SystemMessages"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Size = UDim2.fromScale(0.6, 0.12)
label.Position = UDim2.fromScale(0.2, 0.1)
label.TextScaled = true
label.BackgroundTransparency = 0.25
label.Visible = false
label.Parent = gui

GateMessage.OnClientEvent:Connect(function(msg)
	label.Text = tostring(msg)
	label.Visible = true
	task.delay(2.5, function()
		label.Visible = false
	end)
end)
