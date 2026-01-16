local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local GetStatsSnapshot = remotes:WaitForChild("GetStatsSnapshot")
local AllocateStatPoint = remotes:WaitForChild("AllocateStatPoint")
local GetPlayerState = remotes:WaitForChild("GetPlayerState")

local gui = Instance.new("ScreenGui")
gui.Name = "StatsPanel"
gui.ResetOnSpawn = false
gui.Parent = script.Parent
gui.Enabled = false

local frame = Instance.new("Frame")
frame.Size = UDim2.fromScale(0.35, 0.5)
frame.Position = UDim2.fromScale(0.325, 0.25)
frame.BackgroundTransparency = 0.15
frame.Visible = false
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.fromScale(1, 0.1)
title.BackgroundTransparency = 1
title.TextScaled = true
title.Text = "Stats (K)"
title.Parent = frame

local levelLabel = Instance.new("TextLabel")
levelLabel.Size = UDim2.fromScale(1, 0.08)
levelLabel.Position = UDim2.fromScale(0, 0.1)
levelLabel.BackgroundTransparency = 1
levelLabel.TextScaled = true
levelLabel.Text = "Level: 1"
levelLabel.Parent = frame

local xpLabel = Instance.new("TextLabel")
xpLabel.Size = UDim2.fromScale(1, 0.08)
xpLabel.Position = UDim2.fromScale(0, 0.18)
xpLabel.BackgroundTransparency = 1
xpLabel.TextScaled = true
xpLabel.Text = "XP: 0/100"
xpLabel.Parent = frame

local pointsLabel = Instance.new("TextLabel")
pointsLabel.Size = UDim2.fromScale(1, 0.08)
pointsLabel.Position = UDim2.fromScale(0, 0.26)
pointsLabel.BackgroundTransparency = 1
pointsLabel.TextScaled = true
pointsLabel.Text = "Stat Points: 0"
pointsLabel.Parent = frame

local function createStatRow(y, name, label)
	local row = Instance.new("Frame")
	row.Size = UDim2.fromScale(1, 0.12)
	row.Position = UDim2.fromScale(0, y)
	row.BackgroundTransparency = 1
	row.Parent = frame
	
	local statLabel = Instance.new("TextLabel")
	statLabel.Size = UDim2.fromScale(0.6, 1)
	statLabel.BackgroundTransparency = 1
	statLabel.TextScaled = true
	statLabel.Text = label
	statLabel.Parent = row
	
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.fromScale(0.2, 1)
	valueLabel.Position = UDim2.fromScale(0.6, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.TextScaled = true
	valueLabel.Text = "0"
	valueLabel.Name = "Value"
	valueLabel.Parent = row
	
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromScale(0.15, 0.8)
	btn.Position = UDim2.fromScale(0.82, 0.1)
	btn.TextScaled = true
	btn.Text = "+1"
	btn.MouseButton1Click:Connect(function()
		AllocateStatPoint:FireServer(name)
		task.wait(0.1)
		refresh()
	end)
	btn.Parent = row
	
	return valueLabel
end

local strValue = createStatRow(0.34, "str", "STR:")
local agiValue = createStatRow(0.46, "agi", "AGI:")
local vitValue = createStatRow(0.58, "vit", "VIT:")
local intValue = createStatRow(0.70, "int", "INT:")

local function refresh()
	local ok, data = pcall(function()
		return GetStatsSnapshot:InvokeServer()
	end)
	if not ok or type(data) ~= "table" then return end
	
	levelLabel.Text = "Level: " .. tostring(data.level or 1)
	xpLabel.Text = ("XP: %d/%d"):format(data.xp or 0, data.xpToNext or 100)
	pointsLabel.Text = "Stat Points: " .. tostring(data.statPoints or 0)
	strValue.Text = tostring(data.str or 10)
	agiValue.Text = tostring(data.agi or 10)
	vitValue.Text = tostring(data.vit or 10)
	intValue.Text = tostring(data.int or 10)
end

local function checkState()
	local ok, state = pcall(function()
		return GetPlayerState:InvokeServer()
	end)
	if ok and state == "AwakeningDungeon" then
		frame.Visible = false
		return false
	end
	return true
end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.K then
		if not checkState() then return end
		frame.Visible = not frame.Visible
		if frame.Visible then
			refresh()
		end
	end
end)

refresh()
task.spawn(function()
	while true do
		task.wait(2)
		if frame.Visible and checkState() then
			refresh()
		end
	end
end)
