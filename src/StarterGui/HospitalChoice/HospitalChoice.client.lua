local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GetPlayerState = Remotes:WaitForChild("GetPlayerState")
local ChoosePath = Remotes:WaitForChild("ChoosePath")

-- Chiediamo lo stato al server
local state = GetPlayerState:InvokeServer()

-- Mostra UI SOLO se siamo nello stato HospitalChoice
if state ~= "HospitalChoice" then
	return
end

local gui = Instance.new("ScreenGui")
gui.Name = "HospitalChoiceUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromScale(0.4, 0.3)
frame.Position = UDim2.fromScale(0.3, 0.35)
frame.BackgroundTransparency = 0.1
frame.Parent = gui

local function makeButton(text, pos, choice)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromScale(0.8, 0.3)
	btn.Position = pos
	btn.TextScaled = true
	btn.Text = text
	btn.Parent = frame

	btn.MouseButton1Click:Connect(function()
		ChoosePath:FireServer(choice)
		gui:Destroy()
	end)
end

makeButton("Solitario", UDim2.fromScale(0.1, 0.15), "Solo")
makeButton("Gilda", UDim2.fromScale(0.1, 0.55), "Guild")
