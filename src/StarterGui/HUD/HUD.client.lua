local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GetRewards = Remotes:WaitForChild("GetRewards")
local GateMessage = Remotes:WaitForChild("GateMessage")

local gui = Instance.new("ScreenGui")
gui.Name = "HUD"
gui.ResetOnSpawn = false
local playerGui = player:WaitForChild("PlayerGui")
gui.Parent = playerGui
-- start hidden until CITY state
gui.Enabled = false

local frame = Instance.new("Frame")
frame.Size = UDim2.fromScale(0.22, 0.12)
frame.Position = UDim2.fromScale(0.76, 0.02)
frame.BackgroundTransparency = 0.25
frame.Parent = gui

local xpLabel = Instance.new("TextLabel")
xpLabel.Size = UDim2.fromScale(1, 0.5)
xpLabel.Position = UDim2.fromScale(0, 0)
xpLabel.BackgroundTransparency = 1
xpLabel.TextScaled = true
xpLabel.Text = "XP: ..."
xpLabel.Parent = frame

local coinsLabel = Instance.new("TextLabel")
coinsLabel.Size = UDim2.fromScale(1, 0.5)
coinsLabel.Position = UDim2.fromScale(0, 0.5)
coinsLabel.BackgroundTransparency = 1
coinsLabel.TextScaled = true
coinsLabel.Text = "Coins: ..."
coinsLabel.Parent = frame

local function refresh()
	local ok, data = pcall(function()
		return GetRewards:InvokeServer()
	end)
	if ok and type(data) == "table" then
		xpLabel.Text = "XP: " .. tostring(data.xp or 0)
		coinsLabel.Text = "Coins: " .. tostring(data.coins or 0)
	end
end

refresh()

GateMessage.OnClientEvent:Connect(function()
	-- After gate clear, refresh HUD
	task.delay(0.1, refresh)
end)

-- Show HUD only in CITY
local se = playerGui:FindFirstChild("UIStateChanged")
if se then
	se.Event:Connect(function(ns)
		if ns == "CITY" then
			gui.Enabled = true
			task.delay(0.1, refresh)
		else
			gui.Enabled = false
		end
	end)
end
local sv = playerGui:FindFirstChild("UIState")
if sv and sv.Value == "CITY" then gui.Enabled = true; task.delay(0.1, refresh) end

