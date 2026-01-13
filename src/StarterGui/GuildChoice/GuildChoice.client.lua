local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local GetPlayerState = remotes:WaitForChild("GetPlayerState")
local StateChanged = remotes:WaitForChild("StateChanged")
local GetProgress = remotes:WaitForChild("GetProgress")

local SetGuildFaction = remotes:WaitForChild("SetGuildFaction")

local function build()
	local gui = Instance.new("ScreenGui")
	gui.Name = "GuildChoiceUI"
	gui.ResetOnSpawn = false

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(0.5, 0.38)
	frame.Position = UDim2.fromScale(0.25, 0.3)
	frame.BackgroundTransparency = 0.12
	frame.Parent = gui

	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(1, 0.2)
	title.BackgroundTransparency = 1
	title.TextScaled = true
	title.Text = "Choose a Guild"
	title.Parent = frame

	local function button(text, y, faction)
		local b = Instance.new("TextButton")
		b.Size = UDim2.fromScale(0.8, 0.18)
		b.Position = UDim2.fromScale(0.1, y)
		b.TextScaled = true
		b.Text = text
		b.Parent = frame

		b.MouseButton1Click:Connect(function()
			SetGuildFaction:FireServer(faction)
			gui.Enabled = false
		end)
	end

	button("Hunters Guild", 0.26, "Hunters")
	button("White Tiger Guild", 0.48, "WhiteTiger")
	button("Choi Association", 0.70, "ChoiAssoc")

	return gui
end

local gui = build()
gui.Parent = player:WaitForChild("PlayerGui")
gui.Enabled = false

local function shouldShow()
	local okProg, prog = pcall(function()
		return GetProgress:InvokeServer()
	end)
	if okProg and type(prog) == "table" then
		if prog.pathChoice == "Guild" and (prog.faction == nil) then
			return true
		end
	end
	return false
end

local function refresh()
	-- Only show after awakening (HospitalChoice / Town), if player chose Guild and has no faction yet.
	gui.Enabled = shouldShow()
end

refresh()
StateChanged.OnClientEvent:Connect(function()
	task.delay(0.1, refresh)
end)

