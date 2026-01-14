local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local CombatEvent = remotes:WaitForChild("CombatEvent")

local shakeActive = false
local shakeEndTime = 0
local baseCFrame = nil

RunService.RenderStepped:Connect(function()
	local currentTime = tick()
	if shakeActive and currentTime < shakeEndTime then
		if not baseCFrame then
			baseCFrame = camera.CFrame
		end
		local offset = CFrame.Angles(
			math.rad(math.random(-0.8, 0.8)),
			math.rad(math.random(-0.8, 0.8)),
			0
		)
		camera.CFrame = baseCFrame * offset
	else
		if shakeActive then
			shakeActive = false
			baseCFrame = nil
		end
	end
end)

CombatEvent.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then return end
	
	if payload.type == "HitConfirm" then
		shakeActive = true
		shakeEndTime = tick() + 0.08
	end
end)
