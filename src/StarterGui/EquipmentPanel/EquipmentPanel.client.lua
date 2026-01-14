local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local GetEquipmentSnapshot = remotes:WaitForChild("GetEquipmentSnapshot")
local EquipItem = remotes:WaitForChild("EquipItem")

local gui = Instance.new("ScreenGui")
gui.Name = "EquipmentPanel"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

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
title.Text = "Equipment (O)"
title.Parent = frame

local weaponLabel = Instance.new("TextLabel")
weaponLabel.Size = UDim2.fromScale(1, 0.1)
weaponLabel.Position = UDim2.fromScale(0, 0.15)
weaponLabel.BackgroundTransparency = 1
weaponLabel.TextScaled = true
weaponLabel.Text = "Weapon: None"
weaponLabel.Parent = frame

local armorLabel = Instance.new("TextLabel")
armorLabel.Size = UDim2.fromScale(1, 0.1)
armorLabel.Position = UDim2.fromScale(0, 0.25)
armorLabel.BackgroundTransparency = 1
armorLabel.TextScaled = true
armorLabel.Text = "Armor: None"
armorLabel.Parent = frame

local invLabel = Instance.new("TextLabel")
invLabel.Size = UDim2.fromScale(1, 0.6)
invLabel.Position = UDim2.fromScale(0, 0.4)
invLabel.BackgroundTransparency = 1
invLabel.TextWrapped = true
invLabel.TextYAlignment = Enum.TextYAlignment.Top
invLabel.Text = "Inventory:\n(empty)"
invLabel.Parent = frame

local function refresh()
	local ok, data = pcall(function()
		return GetEquipmentSnapshot:InvokeServer()
	end)
	if not ok or type(data) ~= "table" then return end
	
	weaponLabel.Text = "Weapon: " .. (data.weapon or "None")
	armorLabel.Text = "Armor: " .. (data.armor or "None")
	
	if data.inventory and #data.inventory > 0 then
		invLabel.Text = "Inventory:\n" .. table.concat(data.inventory, "\n")
	else
		invLabel.Text = "Inventory:\n(empty)"
	end
end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.O then
		frame.Visible = not frame.Visible
		if frame.Visible then
			refresh()
		end
	end
end)
