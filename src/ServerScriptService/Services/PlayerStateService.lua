-- ServerScriptService/Services/PlayerStateService.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local GameState = require(SharedFolder:WaitForChild("GameState"))

local WorldService = require(script.Parent:WaitForChild("WorldService"))
local EnemyService = require(script.Parent:WaitForChild("EnemyService"))
local RewardService = require(script.Parent:WaitForChild("RewardService"))

local PlayerStateService = {}
PlayerStateService.__index = PlayerStateService

local playerState: {[Player]: string} = {}
local activeGateEnemy: {[Player]: boolean} = {}

local function isValidState(state: string): boolean
	for _, v in pairs(GameState) do
		if v == state then
			return true
		end
	end
	return false
end

local function teleportToSpawn(player: Player, spawnName: string)
	local cf = WorldService:GetSpawnCFrame(spawnName)
	if not cf then
		warn("[PlayerStateService] Spawn non trovato:", spawnName)
		return
	end

	local function doTeleport(character: Model)
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		hrp.CFrame = cf + Vector3.new(0, 3, 0)
	end

	if player.Character then
		doTeleport(player.Character)
	else
		local conn
		conn = player.CharacterAdded:Connect(function(char)
			conn:Disconnect()
			doTeleport(char)
		end)
	end
end

local function fireGateMessage(player: Player, msg: string)
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local gateMessage = remotes:WaitForChild("GateMessage")
	gateMessage:FireClient(player, msg)
end

function PlayerStateService:Init()
end

function PlayerStateService:Get(player: Player): string
	return playerState[player] or GameState.HospitalChoice
end

function PlayerStateService:Set(player: Player, state: string)
	if not isValidState(state) then
		warn(("[PlayerStateService] Stato non valido '%s' per %s"):format(tostring(state), player.Name))
		return
	end

	playerState[player] = state

	-- OpenWorld per ora = Town (placeholder)
	if state == GameState.OpenWorld then
		teleportToSpawn(player, "Spawn_Town")
		return
	end

	if state == GameState.SoloGateTutorial then
		teleportToSpawn(player, "Spawn_SoloGate")

		-- Spawn nemico + Gate clear callback (solo se non c'è già uno attivo)
		if not activeGateEnemy[player] then
			activeGateEnemy[player] = true
			EnemyService:SpawnDummyEnemy(Vector3.new(0, 5, -240), function()
				activeGateEnemy[player] = nil
				local r = RewardService:Add(player, 50, 100)
				fireGateMessage(player, ("GATE CLEARED! +50 XP, +100 COINS | Tot: %d XP, %d COINS"):format(r.xp, r.coins))
				playerState[player] = GameState.OpenWorld
				teleportToSpawn(player, "Spawn_Town")
			end)
		end

		return
	end

	if state == GameState.GuildGateTutorial then
		teleportToSpawn(player, "Spawn_GuildHome")
		return
	end
end

function PlayerStateService:OnPlayerAdded(player: Player)
	playerState[player] = GameState.HospitalChoice
end

function PlayerStateService:OnPlayerRemoving(player: Player)
	playerState[player] = nil
	activeGateEnemy[player] = nil
	RewardService:Clear(player)
end

return PlayerStateService
