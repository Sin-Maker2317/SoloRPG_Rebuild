-- ServerScriptService/Services/AwakeningDeathService.lua

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local GameState = require(SharedFolder:WaitForChild("GameState"))

local PlayerStateService = require(script.Parent:WaitForChild("PlayerStateService"))
local DebugService = require(script.Parent:WaitForChild("DebugService"))

local AwakeningDeathService = {}
AwakeningDeathService.__index = AwakeningDeathService

local KILL_DELAY = 20

local function isInAwakening(player)
	return PlayerStateService:Get(player) == GameState.AwakeningDungeon
end

local function setupKillTimer(player, humanoid)
	DebugService:Log("[AwakeningDeath] Starting kill timer for", player.Name)

	task.delay(KILL_DELAY, function()
		if not isInAwakening(player) then
			return
		end
		if humanoid.Health <= 0 then
			return
		end

		DebugService:Warn("[AwakeningDeath] Time expired, killing", player.Name)
		humanoid.Health = 0
	end)
end

local function setupHumanoid(player, character)
	if not isInAwakening(player) then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	setupKillTimer(player, humanoid)

	humanoid.Died:Connect(function()
		DebugService:Log("[AwakeningDeath] Player died in AwakeningDungeon:", player.Name)
		PlayerStateService:Set(player, GameState.HospitalChoice)
	end)
end

function AwakeningDeathService:Init()
	DebugService:Log("[AwakeningDeath] Init")

	-- Optional kill part in the world named "AwakeningKillPart"
	local killPart = Workspace:FindFirstChild("AwakeningKillPart")
	if killPart and killPart:IsA("BasePart") then
		killPart.Touched:Connect(function(hit)
			local character = hit:FindFirstAncestorOfClass("Model")
			if not character then
				return
			end

			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if not humanoid or humanoid.Health <= 0 then
				return
			end

			local player = Players:GetPlayerFromCharacter(character)
			if not player or not isInAwakening(player) then
				return
			end

			DebugService:Warn("[AwakeningDeath] Kill part touched by", player.Name)
			humanoid.Health = 0
		end)
	end

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			setupHumanoid(player, character)
		end)
	end)
end

return AwakeningDeathService

