local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local CombatEvent = remotes:WaitForChild("CombatEvent")

-- Placeholder: later you'll set Sound.SoundId to actual assets
local function playLocal(name)
	-- Intentionally empty for now; leaving hook points for future.
	-- Example later:
	-- local s = Instance.new("Sound"); s.SoundId="rbxassetid://..."; s.Parent=workspace; s:Play(); s.Ended:Destroy()
end

CombatEvent.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then return end
	if payload.type == "HitConfirm" then
		playLocal("HitConfirm")
	elseif payload.type == "DodgeApproved" then
		playLocal("Dodge")
	end
end)
