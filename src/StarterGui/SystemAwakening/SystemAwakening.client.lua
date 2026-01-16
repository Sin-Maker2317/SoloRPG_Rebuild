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
	gui.Parent = script.Parent
	gui.Enabled = false

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
local playerGui = player:WaitForChild("PlayerGui")
gui.Parent = playerGui
gui.Enabled = false

local function setVisibleForState(uistate)
	-- Only show as tutorial overlay during movement/combat tutorial states
	if uistate == "TUTORIAL_MOVEMENT" or uistate == "TUTORIAL_COMBAT" then
		gui.Enabled = true
	else
		gui.Enabled = false
	end
end

-- react to server state changes if needed (keep compatibility)
StateChanged.OnClientEvent:Connect(function(s)
	-- no-op: server-driven states not used for UI gating here
end)

-- react to UI state changes
local se = playerGui:FindFirstChild("UIStateChanged")
if se then
	se.Event:Connect(function(ns) setVisibleForState(ns) end)
end

-- initial read
local sv = playerGui:FindFirstChild("UIState")
if sv then setVisibleForState(sv.Value) end

