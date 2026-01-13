local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local GetPlayerState = remotes:WaitForChild("GetPlayerState")
local StateChanged = remotes:WaitForChild("StateChanged")

local function buildGui()
	local gui = Instance.new("ScreenGui")
	gui.Name = "SystemAwakening"
	gui.ResetOnSpawn = false

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(0.6, 0.25)
	frame.Position = UDim2.fromScale(0.2, 0.15)
	frame.BackgroundTransparency = 0.15
	frame.Parent = gui

	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(1, 0.35)
	title.Position = UDim2.fromScale(0, 0)
	title.BackgroundTransparency = 1
	title.TextScaled = true
	title.Text = "THE SYSTEM"
	title.Parent = frame

	local line1 = Instance.new("TextLabel")
	line1.Size = UDim2.fromScale(1, 0.3)
	line1.Position = UDim2.fromScale(0, 0.35)
	line1.BackgroundTransparency = 1
	line1.TextScaled = true
	line1.Text = "You have been chosen."
	line1.Parent = frame

	local line2 = Instance.new("TextLabel")
	line2.Size = UDim2.fromScale(1, 0.3)
	line2.Position = UDim2.fromScale(0, 0.65)
	line2.BackgroundTransparency = 1
	line2.TextScaled = true
	line2.Text = "The System has awakened."
	line2.Parent = frame

	return gui
end

local gui = buildGui()
gui.Parent = player:WaitForChild("PlayerGui")
gui.Enabled = false

local function setVisible(state)
	gui.Enabled = (state == "AwakeningDungeon")
end

local ok, state = pcall(function()
	return GetPlayerState:InvokeServer()
end)
if ok then
	setVisible(state)
end

StateChanged.OnClientEvent:Connect(function(state)
	setVisible(state)
end)

