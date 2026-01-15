local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local GetQuests = remotes:WaitForChild("GetQuests")
local ClaimQuest = remotes:WaitForChild("ClaimQuest")
local GateMessage = remotes:WaitForChild("GateMessage")

local gui = Instance.new("ScreenGui")
gui.Name = "QuestHUD"
gui.ResetOnSpawn = false
local playerGui = player:WaitForChild("PlayerGui")
gui.Parent = playerGui
gui.Enabled = false

local frame = Instance.new("Frame")
frame.Size = UDim2.fromScale(0.28, 0.18)
frame.Position = UDim2.fromScale(0.02, 0.78)
frame.BackgroundTransparency = 0.25
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.fromScale(1, 0.25)
title.BackgroundTransparency = 1
title.TextScaled = true
title.Text = "Daily Objectives"
title.Parent = frame

local l1 = Instance.new("TextLabel")
l1.Size = UDim2.fromScale(1, 0.25)
l1.Position = UDim2.fromScale(0, 0.25)
l1.BackgroundTransparency = 1
l1.TextScaled = true
l1.Text = "Clear Gates: ..."
l1.Parent = frame

local l2 = Instance.new("TextLabel")
l2.Size = UDim2.fromScale(1, 0.25)
l2.Position = UDim2.fromScale(0, 0.50)
l2.BackgroundTransparency = 1
l2.TextScaled = true
l2.Text = "Kill Enemies: ..."
l2.Parent = frame

local hint = Instance.new("TextLabel")
hint.Size = UDim2.fromScale(1, 0.25)
hint.Position = UDim2.fromScale(0, 0.75)
hint.BackgroundTransparency = 1
hint.TextScaled = true
hint.Text = "Press [J] to claim completed"
hint.Parent = frame

local function refresh()
	local ok, data = pcall(function()
		return GetQuests:InvokeServer()
	end)
	if not ok or type(data) ~= "table" then return end

	l1.Text = ("Clear Gates: %d/%d %s"):format(data.gateClears or 0, data.goalGateClears or 3, (data.claimedGate and "[CLAIMED]") or "")
	l2.Text = ("Kill Enemies: %d/%d %s"):format(data.kills or 0, data.goalKills or 10, (data.claimedKills and "[CLAIMED]") or "")
end

-- react to UI state changes
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

-- initial
local sv = playerGui:FindFirstChild("UIState")
if sv and sv.Value == "CITY" then gui.Enabled = true; task.delay(0.1, refresh) end
GateMessage.OnClientEvent:Connect(function()
	task.delay(0.1, refresh)
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.J then
		-- try claim both; server will respond with messages
		ClaimQuest:FireServer("ClearGates")
		ClaimQuest:FireServer("KillEnemies")
		task.delay(0.2, refresh)
	end
end)
