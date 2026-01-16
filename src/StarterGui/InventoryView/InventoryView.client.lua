local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local GetInventory = remotes:WaitForChild("GetInventory")

local gui = Instance.new("ScreenGui")
gui.Name = "InventoryView"
gui.ResetOnSpawn = false
gui.Parent = script.Parent
gui.Enabled = false

local frame = Instance.new("Frame")
frame.Size = UDim2.fromScale(0.3, 0.35)
frame.Position = UDim2.fromScale(0.35, 0.3)
frame.BackgroundTransparency = 0.15
frame.Visible = false
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.fromScale(1, 0.15)
title.BackgroundTransparency = 1
title.TextScaled = true
title.Text = "Inventory (I)"
title.Parent = frame

local list = Instance.new("TextLabel")
list.Size = UDim2.fromScale(1, 0.85)
list.Position = UDim2.fromScale(0, 0.15)
list.BackgroundTransparency = 1
list.TextScaled = false
list.TextWrapped = true
list.TextYAlignment = Enum.TextYAlignment.Top
list.Text = ""
list.Parent = frame

local function refresh()
	local ok, items = pcall(function()
		return GetInventory:InvokeServer()
	end)
	if not ok or type(items) ~= "table" then
		list.Text = "Inventory unavailable."
		return
	end
	if #items == 0 then
		list.Text = "(empty)"
		return
	end
	list.Text = table.concat(items, "\n")
end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.I then
		frame.Visible = not frame.Visible
		if frame.Visible then
			refresh()
		end
	end
end)
