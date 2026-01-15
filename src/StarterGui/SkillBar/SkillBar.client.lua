local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local UseSkill = remotes:WaitForChild("UseSkill")
local CombatEvent = remotes:WaitForChild("CombatEvent")

local gui = Instance.new("ScreenGui")
gui.Name = "SkillBar"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")
local playerGui = player:WaitForChild("PlayerGui")
gui.Parent = playerGui
gui.Enabled = false

local frame = Instance.new("Frame")
frame.Size = UDim2.fromScale(0.3, 0.08)
frame.Position = UDim2.fromScale(0.35, 0.9)
frame.BackgroundTransparency = 0.3
frame.Parent = gui

local function createSkillButton(x, key, skillId)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromScale(0.28, 0.8)
	btn.Position = UDim2.fromScale(x, 0.1)
	btn.TextScaled = true
	btn.Text = key
	btn.MouseButton1Click:Connect(function()
		UseSkill:FireServer(skillId)
	end)
	btn.Parent = frame
	
	local cdLabel = Instance.new("TextLabel")
	cdLabel.Size = UDim2.fromScale(1, 1)
	cdLabel.BackgroundTransparency = 0.5
	cdLabel.TextScaled = true
	cdLabel.Text = ""
	cdLabel.Visible = false
	cdLabel.Name = "Cooldown"
	cdLabel.Parent = btn
	
	return btn
end

local btn1 = createSkillButton(0.02, "1", "QuickSlash")
local btn2 = createSkillButton(0.35, "2", "HeavyStrike")
local btn3 = createSkillButton(0.68, "3", "ShadowStep")

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.One then
		UseSkill:FireServer("QuickSlash")
	elseif input.KeyCode == Enum.KeyCode.Two then
		UseSkill:FireServer("HeavyStrike")
	elseif input.KeyCode == Enum.KeyCode.Three then
		UseSkill:FireServer("ShadowStep")
	end
end)

CombatEvent.OnClientEvent:Connect(function(payload)
	if payload.type == "SkillUsed" then
		-- TODO: Visual feedback
	elseif payload.type == "SkillDenied" then
		-- TODO: Error feedback
	end
end)

-- Toggle visibility based on UIState
local se = playerGui:FindFirstChild("UIStateChanged")
if se then
	se.Event:Connect(function(ns)
		if ns == "TUTORIAL_COMBAT" or ns == "CITY" then
			gui.Enabled = true
		else
			gui.Enabled = false
		end
	end)
end
local sv = playerGui:FindFirstChild("UIState")
if sv and (sv.Value == "TUTORIAL_COMBAT" or sv.Value == "CITY") then gui.Enabled = true end
