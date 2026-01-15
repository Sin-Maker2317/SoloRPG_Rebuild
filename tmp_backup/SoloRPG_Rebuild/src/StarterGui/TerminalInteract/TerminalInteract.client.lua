local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local UseTerminal = remotes:WaitForChild("UseTerminal")

local gui = Instance.new("ScreenGui")
gui.Name = "TerminalInteract"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local hint = Instance.new("TextLabel")
hint.Size = UDim2.fromScale(0.35, 0.06)
hint.Position = UDim2.fromScale(0.325, 0.85)
hint.BackgroundTransparency = 0.25
hint.TextScaled = true
hint.Visible = false
hint.Text = "Press [E] to enter the Gate"
hint.Parent = gui

local function getHRP()
	local char = player.Character
	if not char then return nil end
	return char:FindFirstChild("HumanoidRootPart")
end

local function findNearestTerminal(maxDist)
	local hrp = getHRP()
	if not hrp then return nil end

	local world = Workspace:FindFirstChild("World")
	if not world then return nil end
	local terminals = world:FindFirstChild("Terminals")
	if not terminals then return nil end

	local best, bestD = nil, maxDist
	for _, p in ipairs(terminals:GetChildren()) do
		if p:IsA("BasePart") then
			local d = (p.Position - hrp.Position).Magnitude
			if d < bestD then
				best = p
				bestD = d
			end
		end
	end
	return best
end

local currentTerminal = nil

task.spawn(function()
	while true do
		task.wait(0.15)
		currentTerminal = findNearestTerminal(10)
		hint.Visible = (currentTerminal ~= nil)
	end
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.E then
		if currentTerminal then
			UseTerminal:FireServer(currentTerminal.Name)
		end
	end
end)
